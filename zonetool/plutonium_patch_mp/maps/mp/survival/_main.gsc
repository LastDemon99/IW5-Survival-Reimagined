#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\survival\_utility;

main()
{
	precachemenu("ui_display");
	precacheMenu("client_cmd");
	precacheMenu("scoreboard");
	precacheMenu("muteplayer");
	precacheMenu("popup_leavegame");
	precacheMenu("shop_menu");
	precacheMenu("custom_options");

	setModeDvars();
}

init()
{	
	maps\mp\lethalbeats\_dynamic_menu::loadMenuData("custom_options", "main_options");
	maps\mp\lethalbeats\_dynamic_menu::loadMenuData("shop_menu", "weapon_shop");
	maps\mp\lethalbeats\_dynamic_menu::loadMenuData("shop_menu", "equipment_shop");
	maps\mp\lethalbeats\_dynamic_menu::loadMenuData("shop_menu", "support_shop");

	maps\mp\survival\_dev::init();
	maps\mp\survival\_shops::init();
	maps\mp\survival\_survivors::init();
	maps\mp\survival\_bots::init();
	maps\mp\survival\_air_drop::init();
	maps\mp\survival\_chopper::init();
	maps\mp\survival\_sentry::init();
	maps\mp\survival\_patch::init();
	thread maps\mp\survival\_uav::init();
	
	setDefaultLoadout();
	clearScoreInfo();	
		
	level.wave_num = 0;
	level.timerSkip = 0;
	level.axisTarget = undefined;
	
	level.bots_connected = 0;
	level.bots_size = 18 - getDvarInt("max_survivors");
	level.bots_count = 0;
	level.bots_awaits = 0;
	level.bots_death = 0;	
	level.sentry = 0;
	level.score_base = 0;
	level.game_ended = 0;
	
	level.notifyHostiles = spawnStruct();
	level.notifyHostiles.titleText = "Hostiles Inbound!";
	level.notifyHostiles.glowColor = (0, 0, 1);
	level.notifyHostiles.duration = 1;
	level.notifyHostiles.sound = "mp_obj_returned";
	
	level.notifyHostiles2 = spawnStruct();
	level.notifyHostiles2.sound = "survival_wave_start_splash";
	
	level.notifyDialog = spawnStruct();
	
	level.waveEndMsg = spawnStruct();
	level.waveEndMsg.titleText = "Wave 1 Cleared!";
	level.waveEndMsg.glowColor = (0, 0, 1);
	level.waveEndMsg.duration = 2;
	level.waveEndMsg.sound = "survival_wave_end_splash";
	
	level.waveHud = createServerFontString("hudsmall", 1);
	level.waveHud setPoint("TOP LEFT", "TOP LEFT", 5, 105);
	level.waveHud setText("Wave 1");
	level.waveHud.sort = 1001;
	level.waveHud.foreground = true;
	level.waveHud.hidewheninmenu = false;
	level.waveHud.alpha = 0;
	
	level.maxPerPlayerExplosives = 10;
	level.healthRegenDisabled = 0;
	
	level.chopperStartGoal = [(-660, 205, -355), (-280, 1645, -230), (540, 1085, -250), (1203, 780, -270), (1185, -25, -340), (775, -425, -333), (715, 235, -340), (-95, 640, -295), (115, 1050, -240), (14, 2085, -230)];
	level.challenges = ["Headshot Kill", "Kill Streak", "Knife Kill", "Grenade Kill", "Pistol Kill", "Shotgun Kill", "Machine Pistol Kill", "Smg Kill", "Assault Kill", "Lmg Kill", "Sniper Kill", "Launcher Kill", "Double Kill", "Triple Kill", "Multi Kill"];
	level.dialog = [1, 1, 1, 1, 1];
	
	level thread onWaveEnd();
	level thread onEndLevel();
}

onEndLevel()
{
	level waittill("all_survivors_death", delay);
	
	wait delay;
	
	cmdexec("load_dsr survival");
	wait 3;
	cmdexec("map mp_dome");
}

onWaveEnd()
{
	level endon("game_ended");
	
	for(;;)
	{
		level waittill("wave_end");
		
		if (!level.wave_num) 
		{
			level notify("callback_init");
			level.waveHud.alpha = 1;
			level.notifyDialog.sound = survivorsCount() == 1 ? "so_hq_mission_intro_sp" : "so_hq_mission_intro";
			array_thread(level.players, maps\mp\gametypes\_hud_message::notifyMessage, level.notifyDialog);
			wait 6;
		}
		else 
		{
			level.waveEndMsg.titleText = "Wave " + level.wave_num + " Cleared!";
			array_thread(level.players, maps\mp\gametypes\_hud_message::notifyMessage, level.waveEndMsg);
			
			openArmoryDialog();
			
			level.notifyDialog.sound = "SO_HQ_wave_over_flavor";
			array_thread(level.players, maps\mp\gametypes\_hud_message::notifyMessage, level.notifyDialog);
			
			wait 8;
			onIntermission();
			startedWaveTimer();
		}
		
		level.wave_num++;
		
		if (isLastWave()) return;
		
		level.wave_bots = botsData();
		level.bots_count = level.wave_bots.size;
		level.bots_awaits = level.bots_count;
		level.bots_index = level.bots_count;
		level.bots_death = 0;
		
		print("TotalCount: " + level.wave_bots.size);
		
		thread botTypeDialog();
		
		level.waveHud setText("Wave " + level.wave_num);
		array_thread(level.players, maps\mp\gametypes\_hud_message::notifyMessage, level.notifyHostiles);
		array_thread(level.players, maps\mp\gametypes\_hud_message::notifyMessage, level.notifyHostiles2);
		
		level notify("wave_start");
		
		level.score_base = 0;
		level.waveStartTime = gettime();
		
		foreach(player in level.players) player setClientDvar("ui_wave", level.wave_num);
	}
}

onIntermission()
{
	level endon("intermission_end");
	level notify("intermission");
	
	level.timerSkip = 0;
	
	timer = createServerFontString("hudsmall", 0.8);
	timer setPoint("TOP RIGHT", "TOP RIGHT", -120, 150);
	timer.sort = 1001;
	timer.foreground = true;
	timer.hidewheninmenu = false;
	timer.alpha = 0;	
	timer fadeOverTime(0.8);
	timer.alpha = 1;	
	timer maps\mp\gametypes\_hud::fontPulseInit();
	level.timerHud = timer;
	
	offset = 0;
	countTime = 30;	
	while (countTime > 0)
	{
		if(level.timerSkip == survivorsCount()) break;		
		if(!offset && countTime < 10)
		{
			offset = 1;
			timer setPoint("TOP RIGHT", "TOP RIGHT", -125, 150);
		}
		
		wait (timer.inFrames * 0.066);
		timer setValue(countTime);
		countTime--;
		wait (1 - (timer.inFrames * 0.066));
	}
	
	level notify("intermission_skip", 1);
	timer destroy();
	level.timerHud = undefined;
}

isLastWave() //this mod is under development, so there are still some things to be implemented :c
{
	if (level.wave_num < 21) return 0;
	
	foreach(player in level.players)
	{
		player _unsetPerk("specialty_finalstand");
		player setClientDvar("ui_self_revive", 0);
	}
	level.players[14] maps\mp\killstreaks\_nuke::tryUseNuke(0);
	return 1;
}

startedWaveTimer()
{
	timer = createServerFontString("hudbig", 1);
	timer setPoint("CENTER", "CENTER", 0, 0);
	timer.sort = 1001;
	timer.foreground = true;
	timer.hidewheninmenu = false;	

	timer maps\mp\gametypes\_hud::fontPulseInit();

	countTime = 5;	
	while (countTime > 0)
	{
		playSoundOnPlayers("ui_mp_timer_countdown");
		timer thread maps\mp\gametypes\_hud::fontPulse(level);
		wait (timer.inFrames * 0.066);
		timer setValue(countTime);
		countTime--;
		wait (1 - (timer.inFrames * 0.066));
	}
	timer destroyElem();
}

botsData()
{
	print("Wave: " + level.wave_num);
	
	bots = [];
	for(i = 1; i < 20; i++)
	{
		if (!(i % 2)) continue;
		
		botCount = tableLookup("mp/survival_waves.csv", 0, level.wave_num, i + 1);
		if(botCount == "") break;		
		bot = tableLookup("mp/survival_waves.csv", 0, level.wave_num, i);
		botCount = int(botCount);		
		for(j = 0; j < botCount; j++) bots[bots.size] = bot;
		
		print("BotType: " + bot + " BotCount: " + botCount);
	}	
	return bots;
}

botTypeCount(type)
{
	count = 0;
	foreach(bot in level.wave_bots)
		if(isSubstr(bot, type)) count++;
	return count;
}

openArmoryDialog()
{
	armory = "";
	if (level.wave_num == 2) armory = "weapon";
	else if (level.wave_num == 4) armory = "equipment";
	else if (level.wave_num == 6) armory = "airstrike";
	
	if (armory != "")
	{
		level.notifyDialog.sound = "SO_HQ_armory_open_" + armory;
		array_thread(level.players, maps\mp\gametypes\_hud_message::notifyMessage, level.notifyDialog);
	}
}

botTypeDialog()
{
	botType = ["generic"];
	chopper = botTypeCount("chopper");
	jugger = botTypeCount("jugg");
	
	if(chopper) botType = chopper == 1 ? ["chopper"] : ["chopper_many"];
	else if(jugger) botType = jugger == 1 ? ["boss_transport"] : ["boss_transport_many"];
	else
	{
		botType = checkBotTypeDialogIndex(botType, "dog_reg", 4);
		botType = checkBotTypeDialogIndex(botType, "dog_splode", 3);
		botType = checkBotTypeDialogIndex(botType, "martyrdom", 2);
		botType = checkBotTypeDialogIndex(botType, "claymore", 1);
		botType = checkBotTypeDialogIndex(botType, "chemical", 0);
	}
	
	level.notifyDialog.sound = "SO_HQ_enemy_intel_" + random(botType);
	array_thread(level.players, maps\mp\gametypes\_hud_message::notifyMessage, level.notifyDialog);
		
	if (chopper) playSoundOnPlayers("so_survival_boss_music_01");
	else if (jugger) playSoundOnPlayers("so_survival_boss_music_02");
	
	level waittill("wave_end");
	playSoundOnPlayers("survival_wave_end_splash");
}

checkBotTypeDialogIndex(var, type, index)
{
	if (botTypeCount(type))
	{
		botType = [];
		if (level.dialog[index]) 
		{
			botType = [type];
			level.dialog[index] = 0;
		}
		else botType[botType.size] = type;
		return botType;
	}
	else return var;
}

clearScoreInfo()
{
	maps\mp\gametypes\_rank::registerScoreInfo( "kill", 0 );
    maps\mp\gametypes\_rank::registerScoreInfo( "assist", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "suicide", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "teamkill", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "headshot", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "execution", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "avenger", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "defender", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "posthumous", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "revenge", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "double", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "triple", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "multi", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "buzzkill", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "firstblood", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "comeback", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "longshot", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "assistedsuicide", 0);
    maps\mp\gametypes\_rank::registerScoreInfo( "knifethrow", 0 );
}

setModeDvars()
{
	makeDvarServerInfo("cg_drawCrosshairNames", 0);	
	setDvarIfUninitialized("max_survivors", 4);
	
	setDvar("ui_start_time", gettime());
	setDvar("sv_cheats", 1);	
	setDvar("cg_drawCrosshair", 1);
	setDvar("cg_drawCrosshairNames", 0);
	setDvar("bots_manage_add", 18 - getDvarInt("max_survivors"));
	setDvar("bots_main_chat", 0);
	setDvar("bots_main_menu", 0);
	setDvar("scr_war_timeLimit", 0);	
	setDvar("scr_war_scorelimit", 0);	
	setDvar("scr_war_numLives", 0);	
	setDvar("scr_player_maxhealth", 100);
	setDvar("scr_player_healthregentime", 5);	
	setDvar("scr_war_winlimit", 0);	
    setDvar("scr_war_roundlimit", 0);	
	setDvar("scr_war_roundswitch", 0);	
    setDvar("scr_war_halftime", 0);	
    setDvar("scr_war_promode", 0);	
	setDvar("scr_war_playerrespawndelay", 0);
	setDvar("scr_war_waverespawndelay", 0);	
	setDvar("scr_game_graceperiod", 0);
	setDvar("scr_game_playerwaittime", 0);
	setDvar("scr_game_matchstarttime", 0);
	setDvar("scr_game_spectatetype", 1);
	setDvar("scr_game_allowkillcam", 0);
	setDvar("scr_game_forceuav", 0);
	setDvar("scr_game_hardpoints",0);
	setDvar("scr_game_perks", 0);
	setDvar("scr_game_onlyheadshots",0);	
	setDvar("scr_thirdPerson", 0);
	setDvar("scr_player_forcerespawn", 0);
	setDvar("scr_deleteexplosivesonspawn", 0);
	setDvar("scr_diehard", 0);
	setDvar("camera_thirdPerson", 0);
	setDvar("sv_cheats", 0);
}

setDefaultLoadout()
{
	level.survivalLoadout["loadoutPrimary"] = "iw5_fnfiveseven";
    level.survivalLoadout["loadoutPrimaryAttachment"] = "none";
    level.survivalLoadout["loadoutPrimaryAttachment2"] = "none";
    level.survivalLoadout["loadoutPrimaryBuff"] = "specialty_null";
    level.survivalLoadout["loadoutPrimaryCamo"] = "none";
    level.survivalLoadout["loadoutPrimaryReticle"] = "none";
    level.survivalLoadout["loadoutSecondary"] = "none";
    level.survivalLoadout["loadoutSecondaryAttachment"] = "none";
    level.survivalLoadout["loadoutSecondaryAttachment2"] = "none";
    level.survivalLoadout["loadoutSecondaryBuff"] = "specialty_null";
    level.survivalLoadout["loadoutSecondaryCamo"] = "none";
    level.survivalLoadout["loadoutSecondaryReticle"] = "none";
    level.survivalLoadout["loadoutEquipment"] = "frag_grenade_mp";
    level.survivalLoadout["loadoutOffhand"] = "flash_grenade_mp";
    level.survivalLoadout["loadoutPerk1"] = "specialty_null";
    level.survivalLoadout["loadoutPerk2"] = "specialty_null";
    level.survivalLoadout["loadoutPerk3"] = "specialty_null";
	level.survivalLoadout["loadoutStreakType"] = "specialty_null";
	level.survivalLoadout["loadoutKillstreak1"] = "none";
	level.survivalLoadout["loadoutKillstreak2"] = "none";
	level.survivalLoadout["loadoutKillstreak3"] = "none";
    level.survivalLoadout["loadoutDeathstreak"] = "specialty_null";
    level.survivalLoadout["loadoutJuggernaut"] = false;	
}
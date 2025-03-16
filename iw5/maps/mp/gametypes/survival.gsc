#include lethalbeats\survival\utility;
#include lethalbeats\array;
#include lethalbeats\string;
#include lethalbeats\hud;

#define NOTIFY_HOSTILES 0
#define NOTIFY_HOSTILES_2 1
#define NOTIFY_DIALOG 2
#define NOTIFY_WAVE_END 3

main()
{
	cmdexec("exec survival_config");

    maps\mp\gametypes\_globallogic::init();
    maps\mp\gametypes\_callbacksetup::setupcallbacks();
    maps\mp\gametypes\_globallogic::setupcallbacks();

    maps\mp\_utility::registerroundswitchdvar(level.gametype, 0, 0, 9);
	maps\mp\_utility::registertimelimitdvar(level.gametype, 10);
	maps\mp\_utility::registerscorelimitdvar(level.gametype, 500);
	maps\mp\_utility::registerroundlimitdvar(level.gametype, 1);
	maps\mp\_utility::registerwinlimitdvar(level.gametype, 1);
	maps\mp\_utility::registernumlivesdvar(level.gametype, 0);
	maps\mp\_utility::registerhalftimedvar(level.gametype, 0);

    level.matchrules_damagemultiplier = 0;
    level.matchrules_vampirism = 0;
    level.teambased = 1;
	level.rankedmatch = 0;
    level.onstartgametype = ::onstartgametype;
    level.getspawnpoint = ::getspawnpoint;
    level.onNormalDeath = ::onNormalDeath;

    makeDvarServerInfo("cg_drawCrosshairNames", 0);	
	setDvarIfUninitialized("survival_survivors_limit", 4);
	setDvarIfUninitialized("survival_dev_mode", 0);
	setDvarIfUninitialized("survival_wait_shops", 1);
	setDvarIfUninitialized("survival_wave_start", 1);
	setDvarIfUninitialized("survival_wait_respawn", 0);
	setDvarIfUninitialized("survival_start_armor", 250);
	setDvarIfUninitialized("survival_start_money", 500);

	setDvar("ui_start_time", gettime());
	setDvar("sv_cheats", 1);	
	setDvar("cg_drawCrosshair", 1);
	setDvar("cg_drawCrosshairNames", 0);
	setDvar("bots_manage_add", 18 - getDvarInt("survival_survivors_limit"));
	setDvar("bots_main_chat", 0);
	setDvar("bots_main_menu", 0);
	setDvar("scr_survival_timeLimit", 0);
	setDvar("scr_survival_scorelimit", 0);	
	setDvar("scr_survival_numLives", 0);	
	setDvar("scr_player_maxhealth", 100);
	setDvar("scr_player_healthregentime", 5);	
	setDvar("scr_survival_winlimit", 0);	
    setDvar("scr_survival_roundlimit", 0);	
	setDvar("scr_survival_roundswitch", 0);	
    setDvar("scr_survival_halftime", 0);	
    setDvar("scr_survival_promode", 0);	
	setDvar("scr_survival_playerrespawndelay", 0);
	setDvar("scr_survival_waverespawndelay", 0);	
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

	precachemenu("ui_display");
	precacheMenu("scoreboard");
	precacheMenu("muteplayer");
	precacheMenu("popup_leavegame");
	precacheMenu("custom_options");

	if (getDvarInt("survival_dev_mode")) lethalbeats\Survival\_dev::init();
	lethalbeats\Survival\patch\globallogic::init();
}

initializematchrules()
{
    maps\mp\_utility::setcommonrulesfrommatchrulesdata();
    setdynamicdvar("scr_war_roundswitch", 0);
    maps\mp\_utility::registerroundswitchdvar("survival", 0, 0, 9);
    setdynamicdvar("scr_war_roundlimit", 1);
    maps\mp\_utility::registerroundlimitdvar("survival", 1);
    setdynamicdvar("scr_war_winlimit", 1);
    maps\mp\_utility::registerwinlimitdvar("survival", 1);
    setdynamicdvar("scr_war_halftime", 0);
    maps\mp\_utility::registerhalftimedvar("survival", 0);
    setdynamicdvar("scr_war_promode", 0);
}

onStartGametype()
{
    setclientnamemode("auto_change");

    game["switchedsides"] = 0;

    maps\mp\_utility::setobjectivetext("allies", &"SURVIVAL_OBJECTIVE");
    maps\mp\_utility::setobjectivetext("axis", &"OBJECTIVES_WAR");

    maps\mp\_utility::setobjectivescoretext("allies", &"SURVIVAL_OBJECTIVE");
	maps\mp\_utility::setobjectivescoretext("axis", &"OBJECTIVES_WAR_SCORE");

    maps\mp\_utility::setobjectivehinttext("allies", &"SURVIVAL_OBJECTIVE");
    maps\mp\_utility::setobjectivehinttext("axis", &"OBJECTIVES_WAR_HINT");
	
    level.spawnmins = (0, 0, 0);
    level.spawnmaxs = (0, 0, 0);
	
    maps\mp\gametypes\_spawnlogic::placespawnpoints("mp_tdm_spawn_allies_start");
    maps\mp\gametypes\_spawnlogic::placespawnpoints("mp_tdm_spawn_axis_start");
    maps\mp\gametypes\_spawnlogic::addspawnpoints("allies", "mp_tdm_spawn");
    maps\mp\gametypes\_spawnlogic::addspawnpoints("axis", "mp_tdm_spawn");
	
    level.mapcenter = maps\mp\gametypes\_spawnlogic::findboxcenter(level.spawnmins, level.spawnmaxs);
    setmapcenter(level.mapcenter);
	
    allowed[0] = level.gametype;
    allowed[1] = "airdrop_pallet";
	
    maps\mp\gametypes\_gameobjects::main(allowed);

	level.setMoney = ::survivor_set_score; // `level.setMoney` for dynamic shop
    level thread lethalbeats\dynamicmenus\dynamic_shop::init();
	lethalbeats\Survival\armories\_armories::init();

    lethalbeats\survival\killstreaks\_airdrop::init();
    lethalbeats\Survival\abilities\_chopper::init();
    lethalbeats\survival\killstreaks\_sentry::init();
    level thread lethalbeats\survival\killstreaks\_uav::init();

    lethalbeats\survival\abilities\_chemical::init();
    lethalbeats\survival\abilities\_dog::init();
    lethalbeats\survival\abilities\_juggernaut::init();
    lethalbeats\survival\abilities\_martyrdom::init();
	lethalbeats\Survival\abilities\_pavelow::init();
	lethalbeats\Survival\abilities\_tank::init();
	lethalbeats\Survival\abilities\_reaper::init();
	maps\mp\killstreaks\_airstrike::init();

    lethalbeats\weapon::weapon_init();
	lethalbeats\utility::clear_score_info();
	
	level.defaultLoadout = get_default_loadout();
	level.wave_num = 0;
	level.axisTarget = undefined;
	
	level.bots_slots = 18 - getDvarInt("survival_survivors_limit");
	level.bots_connected = 0;
	level.bots_wave = [];
	level.bots_total_count = 0;
	level.bots_deaths = 0;
	level.bots_awaits = 0;
	level.bots_weapons_data = [];
	level.sentry = 0;
	level.score_base = 0;
	level.game_ended = 0;	
	level.maxPerPlayerExplosives = 10;
	level.healthRegenDisabled = 0;
	level.inGracePeriod = 0;
		
	lethalbeats\Survival\patch\globallogic::patch_callbacks();

	if (!getDvarInt("survival_wave_start")) return;

	level thread onWaveStart();
	level thread onWaveEnd();
	level thread onEndLevel();
	level thread onWaitPlayers();
	level thread botsGiveAmmo();
}

onWaitPlayers()
{
	level endon("game_ended");
	level waittill("bots_connected");

	for(;;) 
	{ 
		if (survivors(true).size) break; // test
		wait 0.35;
	}

	wait 0.7;

	level notify("callback_init");
	notifyMessage(NOTIFY_DIALOG, get_intro_dialog());

	wait 6;

	level notify("wave_start");
	setDvar("ui_start_time", getTime());
}

onWaveStart()
{
	level endon("game_ended");

	for(;;)
	{
		level waittill("wave_start");

		if (!level.wave_num) level.wave_num = getDvarInt("survival_wave_start");
		else level.wave_num++;

		print("Wave: " + level.wave_num);
		survivors_call(::survivor_wave_init);

		level.bots_wave = array_shuffle(get_botsTypes());
		level.bots_total_count = level.bots_wave.size;
		level.bots_awaits = level.bots_total_count;
		level.bots_deaths = 0;
		level.score_base = 0;
		level.waveStartTime = gettime();

		level notify("release_bots");
		print("TotalCount: " + level.bots_wave.size);
		
		intel_dialog = get_intel_dialog(level.bots_wave);
		bg_music = get_music_from_dialog(intel_dialog);

		lethalbeats\player::players_play_sound(bg_music);
		notifyMessage(NOTIFY_DIALOG, intel_dialog);
		notifyMessage(NOTIFY_HOSTILES);
		notifyMessage(NOTIFY_HOSTILES_2);
	}
}

onWaveEnd()
{
	level endon("game_ended");

	for(;;)
	{
		level waittill("wave_end");

		survivors_call(::survivor_display_summary);
		lethalbeats\player::players_play_sound("survival_wave_end_splash");	
		notifyMessage(NOTIFY_WAVE_END, "Wave " + level.wave_num + " Cleared!");
		
		armoryUnlock = get_armory_unlock(level.wave_num);
		if (isDefined(armoryUnlock))
			notifyMessage(NOTIFY_DIALOG, "SO_HQ_armory_open_" + armoryUnlock);
		notifyMessage(NOTIFY_DIALOG, "SO_HQ_wave_over_flavor");
		wait 8;
		
		waitIntermission();
		onIntermissionEnd();
	}
}

onIntermissionEnd()
{
	level notify("intermission_end");	
	if (isDefined(level.timerHud)) level.timerHud destroy();
	survivors_call(::survivor_skip_hud_clear);
	hud_create_countdown_center("allies", 5);
	bot_clear_corpses();
	level notify("wave_start");
}

waitIntermission()
{
	level endon("intermission_end");
	level.skip_intermission = 0;
	level.timerHud = hud_create_string("allies", "", "hudsmall", 0.8, "TOP RIGHT", "TOP RIGHT", -120, 150);
	survivors_thread(::watchSurvivorSkip);
	level.timerHud hud_set_countdown(30);
}

watchSurvivorSkip()
{
	level endon("intermission_end");
	self endon("disconnect");

	self survivor_display_hud("bind_skip_intermission");

	timerLabel = hud_create_string(self, "Press ^3[{skip}] ^7to ready up: ", "hudsmall", 0.8, "TOP RIGHT", "TOP RIGHT", -135, 150);
	self.skipLabel = timerLabel;
	
	self notifyonplayercommand("skip_intermission", "skip");
	
	self waittill("skip_intermission");
	
	level.skip_intermission++;
	if(level.skip_intermission == survivors(true).size) level notify("intermission_end");
	level notify("skip_intermission");

	for(;;)
	{
		timerLabel setText("     Waiting other players ^3" + level.skip_intermission + "^7/" + survivors(true).size + ": ");
		level waittill("skip_intermission");
	}
}

onEndLevel()
{
	level waittill("all_survivors_death", delay);	
	maps = getArrayKeys(level.shopZones);
	maps = lethalbeats\array::array_filter(maps, lethalbeats\array::filter_not_equal, getDvar("mapname"));
	map = lethalbeats\array::array_random(maps);
	print("NextMap:", map);
	wait delay;
	setDvar("sv_maprotation", "dsr survival map " + map);
	cmdexec("load_dsr survival; wait; wait; start_map_rotate");
}

onNormalDeath(victim, attacker, lifeId)
{
	score = maps\mp\gametypes\_rank::getScoreInfoValue("kill");
	attacker maps\mp\gametypes\_gamescore::giveTeamScoreForObjective(attacker.pers["team"], score);
	
	if (game["state"] == "postgame" && game["teamScores"][attacker.team] > game["teamScores"][level.otherTeam[attacker.team]])
		attacker.finalKill = true;
}

onAddBot()
{
	bot = addTestClient();
	
	bot.pers["isBot"] = true;
	bot.pers["isBotWarfare"] = true;
	bot.pers["score"] = 0;
	bot.pers["team"] = "axis";	
	bot.sessionteam = "axis";
	bot.botType = "easy";
	
	bot thread maps\mp\bots\_bot::added();
	bot thread lethalbeats\Survival\botHandler::onBotSpawn();

	level.bots_connected++;
	if (level.bots_connected == level.bots_slots)
	{
		level notify("bots_connected");
		level.bots_connected = undefined;
	}
}

onAddSurvivor()
{
	waittillframeend;
    if (!isdefined(self) || self isTestClient()) return;
		
	self maps\mp\gametypes\_menus::addToTeam("allies", 1);
	self waittill("begin");
	self.pers["score"] = 0;
	
	level notify("connecting", self);

	self allowSpectateTeam("allies", 1);
	self allowSpectateTeam("axis", 0);
	self allowSpectateTeam("none", 0);
	self allowSpectateTeam("freelook", 0);	
	self survivor_wave_init();

	self thread lethalbeats\Survival\survivorHandler::onPlayerSpawn();
}

getSpawnPoint()
{	
	if(!isDefined(self.firstSpawn))
	{
		self.pers["gamemodeLoadout"] = level.defaultLoadout;
		self.pers["class"] = "gamemode";
		self.pers["lastClass"] = "";
		self.class = self.pers["class"];
		self.lastClass = self.pers["lastClass"];
		self.firstSpawn = 1;
	}
	
	team = isDefined(self.pers["isBot"]) ? "axis" : "allies";	
	maps\mp\gametypes\_menus::addToTeam(team, 1);
	
	if (!level.wave_num && team == "allies")
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray("mp_tdm_spawn_allies_start");
		return maps\mp\gametypes\_spawnlogic::getSpawnpoint_random(array_filter(spawnPoints, ::_spawnPointFilter));
	}
	
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints(team);
	return maps\mp\gametypes\_spawnlogic::getSpawnpoint_nearTeam(array_filter(spawnPoints, ::_spawnPointFilter));
}

_spawnPointFilter(i)
{
	shopZones = level.shopZones[getDvar("mapname")];
	return distance(shopZones[0], i.origin) > 200 && distance(shopZones[2], i.origin) > 200 && distance(shopZones[4], i.origin) > 200;
}

notifyMessage(type, sound, titleText)
{
	notifyData = spawnStruct();
	switch(type)
	{
		case NOTIFY_HOSTILES:
			notifyData.titleText = "Hostiles Inbound!";
			notifyData.glowColor = (0, 0, 1);
			notifyData.duration = 1;
			notifyData.sound = "mp_obj_returned";
			break;
		case NOTIFY_HOSTILES_2:
			notifyData.sound = "survival_wave_start_splash";
			break;
		case NOTIFY_DIALOG:
			break;
		case NOTIFY_WAVE_END:
			notifyData.titleText = "Wave " + level.wave_num + " Cleared!";
			notifyData.glowColor = (0, 0, 1);
			notifyData.duration = 2;
			notifyData.sound = "survival_wave_end_splash";
			break;
		default:
			return;
	}
	if (isDefined(sound)) notifyData.sound = sound;
	if (isDefined(titleText)) notifyData.titleText = titleText;
	notify_message(notifyData);
}

botsGiveAmmo()
{
	level endon("game_ended");
    self endon("disconnect");

    for (;;)
    {
		wait randomIntRange(5, 20);
		foreach(bot in bots(undefined, true))
		{
			if (bot bot_is_dog()) continue;
			weapon = bot getCurrentWeapon();
			weaponClass = lethalbeats\weapon::weapon_get_class(weapon);
			if(isDefined(weapon) && weaponClass != "riot" && weaponClass != "grenade")
				bot lethalbeats\player::player_give_max_ammo(weapon);
		}
    }
}

#include lethalbeats\survival\utility;
#include lethalbeats\array;
#include lethalbeats\string;
#include lethalbeats\hud;

#define NOTIFY_HOSTILES 0
#define NOTIFY_HOSTILES_2 1
#define NOTIFY_DIALOG 2
#define NOTIFY_WAVE_END 3

#define INTERMISSION_TIME 25

main()
{
    maps\mp\gametypes\_globallogic::init();
    maps\mp\gametypes\_callbacksetup::setupCallbacks();
    maps\mp\gametypes\_globallogic::setupCallbacks();

    maps\mp\_utility::registerRoundSwitchDvar(level.gametype, 0, 0, 9);
	maps\mp\_utility::registerTimeLimitDvar(level.gametype, 10);
	maps\mp\_utility::registerScoreLimitDvar(level.gametype, 500);
	maps\mp\_utility::registerRoundLimitDvar(level.gametype, 1);
	maps\mp\_utility::registerWinLimitDvar(level.gametype, 1);
	maps\mp\_utility::registerNumLivesDvar(level.gametype, 0);
	maps\mp\_utility::registerHalfTimeDvar(level.gametype, 0);

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
	setDvarIfUninitialized("survival_save_state", 0);

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
	precacheShader("screen_blood_directional_center");

	lethalbeats\survival\patch\globallogic::init();

	if (!getDvarInt("survival_dev_mode")) return;

	lethalbeats\survival\dev\test::init();
	if (getDvarInt("survival_dev_mode") > 1) lethalbeats\survival\dev\mapedit::init();

	entities = getentarray("trigger_multiple", "classname");
	foreach(entity in entities) entity delete();

	entities = getentarray("trigger_once", "classname");
	foreach(entity in entities) entity delete();

	entities = getentarray("trigger_use", "classname");
	foreach(entity in entities) entity delete();

    entities = getentarray("trigger_radius", "classname");
    foreach(entity in entities) entity delete();

	entities = getentarray("trigger_lookat", "classname");
	foreach(entity in entities) entity delete();

	entities = getentarray("trigger_damage", "classname");
	foreach(entity in entities) entity delete();

	entities = getentarray("trigger_multiple_softlanding", "targetname");
	foreach(entity in entities) entity delete();

	entities = getentarray("destructible_toy", "targetname");
	foreach(entity in entities) entity delete();

	entities = getentarray("light_destructible", "targetname");
	foreach(entity in entities) entity delete();

	entities = getentarray("destructable", "targetname");
	foreach(entity in entities) entity delete();
}

initializematchrules()
{
    maps\mp\_utility::setCommonRulesFromMatchRulesData();
    setdynamicdvar("scr_war_roundswitch", 0);
    maps\mp\_utility::registerRoundSwitchDvar("survival", 0, 0, 9);
    setdynamicdvar("scr_war_roundlimit", 1);
    maps\mp\_utility::registerRoundLimitDvar("survival", 1);
    setdynamicdvar("scr_war_winlimit", 1);
    maps\mp\_utility::registerWinLimitDvar("survival", 1);
    setdynamicdvar("scr_war_halftime", 0);
    maps\mp\_utility::registerHalfTimeDvar("survival", 0);
    setdynamicdvar("scr_war_promode", 0);
}

onStartGametype()
{
    setclientnamemode("auto_change");

    maps\mp\_utility::setObjectiveText("allies", &"SURVIVAL_OBJECTIVE");
    maps\mp\_utility::setObjectiveText("axis", &"OBJECTIVES_WAR");

    maps\mp\_utility::setObjectiveScoreText("allies", &"SURVIVAL_OBJECTIVE");
	maps\mp\_utility::setObjectiveScoreText("axis", &"OBJECTIVES_WAR_SCORE");

    maps\mp\_utility::setObjectiveHintText("allies", &"SURVIVAL_OBJECTIVE");
    maps\mp\_utility::setObjectiveHintText("axis", &"OBJECTIVES_WAR_HINT");
	
    level.spawnmins = (0, 0, 0);
    level.spawnmaxs = (0, 0, 0);
	
    maps\mp\gametypes\_spawnlogic::placeSpawnPoints("mp_tdm_spawn_allies_start");
    maps\mp\gametypes\_spawnlogic::placeSpawnPoints("mp_tdm_spawn_axis_start");
    maps\mp\gametypes\_spawnlogic::addSpawnPoints("allies", "mp_tdm_spawn");
    maps\mp\gametypes\_spawnlogic::addSpawnPoints("axis", "mp_tdm_spawn");
		
	minimapCorner = getEntArray("minimap_corner", "targetname");
	level.mapcenter = minimapCorner.size ? maps\mp\gametypes\_spawnlogic::findBoxCenter(minimapCorner[0].origin, minimapCorner[1].origin) : (0, 0, 0);
	level.mapcenter = (level.mapcenter[0], level.mapcenter[1], 0);
	
	level.mapRadius = minimapCorner.size ? distance(minimapCorner[0].origin, minimapCorner[1].origin) : 3000;
	level.mapRadius = int(level.mapRadius / 2);

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
	level_load_state();
	
	level.startTime = gettime();
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
	level.survivors_deaths = [];
	level.survivors_bleedout = [];
	level.sentry = 0;
	level.score_base = 0;
	level.game_ended = 0;
	level.maxPerPlayerExplosives = 10;
	level.healthRegenDisabled = 0;
	level.inGracePeriod = 0;
	level.c4s = [];
	level.claymores = [];
	level.droppedWeapons = [];
		
	lethalbeats\survival\patch\globallogic::patch_callbacks();

	if (!getDvarInt("survival_wave_start")) return;
	
	level thread onWaveStart();
	level thread onWaveEnd();
	level thread onEndLevel();
	level thread waitPlayers();
	level thread level_vehicle_monitor();
	level thread level_bots_give_ammo();
}

onWaveStart()
{
	level endon("game_ended");

	for(;;)
	{
		level waittill("wave_start");

		if(!level.wave_num) level.wave_num = level_get_wave();
		else level.wave_num++;

		bot_clear_models();

		print("Wave: " + level.wave_num);
		survivors_call(::survivor_wave_init);
		
		level.bots_wave = array_shuffle(get_botsTypes());
		level.bots_total_count = level.bots_wave.size;
		level.bots_awaits = level.bots_total_count;
		level.bots_deaths = 0;
		level.score_base = 0;
		level.waveStartTime = gettime();
		level.bots_maxknifedistance -= level.bots_maxknifedistance / 4;

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

		level.survivors_deaths = [];
		level.survivors_bleedout = [];

		survivors_call(::survivor_display_summary);
		lethalbeats\player::players_play_sound("survival_wave_end_splash");	
		notifyMessage(NOTIFY_WAVE_END, "Wave " + level.wave_num + " Cleared!");
		
		armoryUnlock = get_armory_unlock(level.wave_num);
		if (isDefined(armoryUnlock))
			notifyMessage(NOTIFY_DIALOG, "SO_HQ_armory_open_" + armoryUnlock);
		notifyMessage(NOTIFY_DIALOG, "SO_HQ_wave_over_flavor");
		wait 8;
		
		waitIntermission(30);
		onIntermissionEnd();
	}
}

onIntermissionEnd()
{
	level notify("intermission_end");
	if (isDefined(level.timerHud)) level.timerHud destroy();
	survivors_call(::survivor_skip_hud_clear);
	hud_create_countdown_center("allies", 5);
	level notify("wave_start");
}

onSurvivorSkipWaitPlayers()
{
	level endon("game_ended");
	level endon("waiting_players_skip");
	self endon("disconnect");

	self survivor_wait_skip();
	level notify("waiting_players_skip");
}

onSurvivorSkipIntermission()
{
	level endon("intermission_end");
	self endon("disconnect");

	timerLabel = hud_create_string(self, "Press ^3[{skip}] ^7to ready up: ", "hudsmall", 0.8, "TOP RIGHT", "TOP RIGHT", -135, 150);
	self.skipLabel = timerLabel;

	self survivor_wait_skip();

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
	setDvar("survival_save_state", 0);
	level_rotate_map(delay);
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

	level.bots_connected++;
	if (level.bots_connected <= level.bots_slots)
	{
		bot.pers["team"] = "axis";
		bot.sessionteam = "axis";
		bot.botType = "easy";
		bot thread lethalbeats\Survival\botHandler::onBotSpawn();

		if (level.bots_connected == level.bots_slots)
		{
			level notify("bots_connected");
			//setDvar("bots_manage_add", 4); // add allies bots // dev test
		}
	}
	//else bot lethalbeats\survival\dev\test::onAddAllyBot(); // dev test

	bot thread maps\mp\bots\_bot::added();
}

onAddSurvivor()
{
	waittillframeend;
    if (!isdefined(self) || self isTestClient()) return;
	if (isDefined(level.waitingLabel)) self thread onSurvivorSkipWaitPlayers();
	if (isDefined(level.timerHud)) self thread onSurvivorSkipIntermission();
	self survivor_wave_init();
		
	self setClientDvar("ui_start_time", level.startTime);
	self maps\mp\gametypes\_menus::addToTeam("allies", 1);
	self waittill("begin");
	self.pers["score"] = 0;
	
	level notify("connecting", self);

	self allowSpectateTeam("allies", 1);
	self allowSpectateTeam("axis", 0);
	self allowSpectateTeam("none", 0);
	self allowSpectateTeam("freelook", 0);
	self survivor_wave_init();

	self thread lethalbeats\Survival\survivorHandler::onPlayerDisconnect();
	self thread lethalbeats\Survival\survivorHandler::onPlayerSpawn();
}

waitPlayers()
{
	level endon("game_ended");
	level waittill("bots_connected");

	for(;;) 
	{ 
		if (survivors(true).size) break;
		wait 0.35;
	}

	level notify("callback_init");
	notifyMessage(NOTIFY_DIALOG, get_intro_dialog());

	if (!getDvarInt("survival_save_state"))
	{
		level.skip_intermission = 0;
		level.waitingLabel = hud_create_string("allies", "Press ^3[{skip}] ^7to skip waiting for players", "hudsmall", 0.8, "TOP RIGHT", "TOP RIGHT", -30, 150);
		survivors_thread(::onSurvivorSkipWaitPlayers);
		level waittill("waiting_players_skip");
		level.waitingLabel destroy();
	}
	level.waitingLabel = undefined;

	level.startTime = getTime();
	foreach(player in level.players) player setClientDvar("ui_start_time", level.startTime);

	hud_create_countdown_center("allies", 5);

	level notify("wave_start");
}

waitIntermission(waitTime)
{
	level endon("intermission_end");
	level.skip_intermission = 0;
	level.timerHud = hud_create_string("allies", "", "hudsmall", 0.8, "TOP RIGHT", "TOP RIGHT", -120, 150);
	survivors_thread(::onSurvivorSkipIntermission);
	level.timerHud hud_set_countdown(waitTime);
	level.timerHud = undefined;
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
		return array_random(array_filter(spawnPoints, ::_spawnPointFilter));
	}
	
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints(team);
	return maps\mp\gametypes\_spawnlogic::getSpawnpoint_nearTeam(array_filter(spawnPoints, ::_spawnPointFilter));
}

_spawnPointFilter(i)
{
	return !is_shop_near(i.origin);
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
	hud_notify_message(notifyData);
}

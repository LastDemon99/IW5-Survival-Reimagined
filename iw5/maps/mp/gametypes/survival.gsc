#include lethalbeats\survival\utility;
#include lethalbeats\botactor\utility;
#include lethalbeats\array;
#include lethalbeats\string;
#include lethalbeats\hud;

#define NOTIFY_HOSTILES 0
#define NOTIFY_HOSTILES_2 1
#define NOTIFY_DIALOG 2
#define NOTIFY_WAVE_END 3
#define NOTIFY_SKIP_CASH_BONUS 5

#define SCRIPT_MOVE 3
#define CHASE_TARGET 22
#define SKILL_CHASE_DIST_MIN 76

#define INTERMISSION_TIME 25
#define MAX_CLIENT_SLOTS 18

main()
{
    maps\mp\gametypes\_globallogic::init();
    maps\mp\gametypes\_callbacksetup::setupCallbacks();
    maps\mp\gametypes\_globallogic::setupCallbacks();

	level.initializeMatchRules = ::initializeMatchRules;
	[[level.initializeMatchRules]]();

	level.teambalance = 0;
	level.objectivebased = 1;
    level.teambased = 1;
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
	setDvarIfUninitialized("survival_enemy_multiplier", 1);
	setDvarIfUninitialized("survival_enemy_difficulty", 1);
	setDvarIfUninitialized("survival_dropped_weapons_limit", 15);
	setDvarIfUninitialized("survival_corpses_limit", 10);
	setDvarIfUninitialized("survival_bot_sentry_limit", 8);
	setDvarIfUninitialized("survival_bot_ims_limit", 4);
	setDvarIfUninitialized("survival_bot_mines_limit", 20);
	setDvarIfUninitialized("survival_scavenger_bags_limit", 15);
	setDvarIfUninitialized("survival_scavenger_ratio", 20);
	setDvarIfUninitialized("survival_blindeye_target_ratio", 40);
	setDvarIfUninitialized("survival_blindeye_windup_mult", 1.5);
	setDvarIfUninitialized("survival_wave_cleanup_interval", 30);
	setDvarIfUninitialized("sv_mapRotation", "dsr survival map mp_dome map mp_mogadishu map mp_bootleg map mp_lambeth map mp_hardhat map mp_interchange map mp_alpha map mp_bravo map mp_plaza2 map mp_exchange map mp_carbon map mp_paris map mp_radar map mp_seatown map mp_underground map mp_village map mp_favela map mp_highrise map mp_nightshift map mp_nuked map mp_rust");

	setDvar("sv_cheats", 1);	
	setDvar("cg_drawCrosshair", 1);
	setDvar("cg_drawCrosshairNames", 0);
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
}

initializematchrules()
{
    dvarPrefix = "scr_" + level.gameType;

    setDynamicDvar(dvarPrefix + "_timeLimit", 0);
	maps\mp\_utility::registerTimeLimitDvar(level.gameType, 0);
	
	setDynamicDvar(dvarPrefix + "_scorelimit", 6);
	maps\mp\_utility::registerScoreLimitDvar(level.gameType, 6);
	
	setDynamicDvar(dvarPrefix + "_numLives", 0);
	maps\mp\_utility::registerNumLivesDvar(level.gameType,  0);
	
	setDynamicDvar("scr_player_maxhealth", 100);
	setDynamicDvar("scr_player_healthregentime", 5);
	
	setDynamicDvar(dvarPrefix + "_winlimit", 6);
    maps\mp\_utility::registerWinLimitDvar(level.gameType, 6);
	
    setDynamicDvar(dvarPrefix + "_roundlimit", 0);
    maps\mp\_utility::registerRoundLimitDvar(level.gameType, 0);
	
	setDynamicDvar(dvarPrefix + "_roundswitch", 1);
    maps\mp\_utility::registerRoundSwitchDvar(level.gameType, 1, 0, 9);
	
    setDynamicDvar(dvarPrefix + "_halftime", 0);
    maps\mp\_utility::registerHalfTimeDvar(level.gameType, 0);
	
    setDynamicDvar(dvarPrefix + "_promode", 0);
	maps\mp\_utility::registerNumLivesDvar(level.gameType, 0);	
	
	setDynamicDvar(dvarPrefix + "_playerrespawndelay", 0);
	setDynamicDvar(dvarPrefix + "_waverespawndelay", 0);
	
	setDynamicDvar("scr_game_spectatetype", 1);
	setDynamicDvar("scr_game_allowkillcam", 1);
	setDynamicDvar("scr_game_forceuav", 0);
	setDynamicDvar("scr_game_hardpoints",0);
	setDynamicDvar("scr_game_perks", 0);
	setDynamicDvar("scr_game_onlyheadshots",0);
	setDynamicDvar("scr_teambalance", 0);
	
	setDynamicDvar("scr_thirdPerson", 0);
	setDynamicDvar("scr_player_forcerespawn", 0);
	setDynamicDvar("camera_thirdPerson", 0);
	setDynamicDvar("g_hardcore", 0);

	setDynamicDvar("disable_challenges", 1);
}

onStartGametype()
{
	level_load_state();
    setclientnamemode("auto_change");

	/*
    maps\mp\_utility::setObjectiveText("allies", &"SURVIVAL_OBJECTIVE");
    maps\mp\_utility::setObjectiveText("axis", &"OBJECTIVES_WAR");

    maps\mp\_utility::setObjectiveScoreText("allies", &"SURVIVAL_OBJECTIVE");
	maps\mp\_utility::setObjectiveScoreText("axis", &"OBJECTIVES_WAR_SCORE");

    maps\mp\_utility::setObjectiveHintText("allies", &"SURVIVAL_OBJECTIVE");
    maps\mp\_utility::setObjectiveHintText("axis", &"OBJECTIVES_WAR_HINT");*/
	
    level.spawnmins = (0, 0, 0);
    level.spawnmaxs = (0, 0, 0);
	
    maps\mp\gametypes\_spawnlogic::placeSpawnPoints("mp_tdm_spawn_allies_start");
    maps\mp\gametypes\_spawnlogic::placeSpawnPoints("mp_tdm_spawn_axis_start");
    maps\mp\gametypes\_spawnlogic::addSpawnPoints("allies", "mp_dm_spawn");
    maps\mp\gametypes\_spawnlogic::addSpawnPoints("axis", "mp_dm_spawn");
		
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
	lethalbeats\survival\killstreaks\_ims::init();
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
	assault = ["acog", "reflex", "eotech", "thermal", "silencer", "heartbeat", "xmags"];
	lethalbeats\weapon::weapon_custom_add("assault", "iw5_iw4fal", "FAL", "weapon_fn_fal", assault);
	lethalbeats\weapon::weapon_custom_add("assault", "iw5_iw4famas", "FAMAS", "weapon_famas", assault);
	lethalbeats\weapon::weapon_custom_add("assault", "iw5_iw4fn2000", "F2000", "weapon_fn2000", assault);
	lethalbeats\weapon::weapon_custom_add("assault", "iw5_iw4tavor", "TAR-21", "weapon_tavor", assault);

	smg = ["acogsmg", "reflexsmg", "eotechsmg", "thermalsmg", "silencer", "xmags", "rof", "akimbo"];
	lethalbeats\weapon::weapon_custom_add("smg", "iw5_iw4mp5k", "MP5K", "weapon_mp5k", smg);
	lethalbeats\weapon::weapon_custom_add("smg", "iw5_iw4uzi", "Mini-Uzi", "weapon_mini_uzi", smg);
	lethalbeats\weapon::weapon_custom_add("smg", "iw5_iw4kriss", "Vector", "weapon_kriss", smg);

	lmg = ["acog", "reflexlmg", "eotechlmg", "thermal", "grip", "silencer", "heartbeat", "xmags"];
	lethalbeats\weapon::weapon_custom_add("lmg", "iw5_iw4m240", "M240", "weapon_m240", ["acog", "reflexlmg", "eotechlmg", "thermal", "hybrid", "silencer", "heartbeat", "xmags"]);
	lethalbeats\weapon::weapon_custom_add("lmg", "iw5_iw4aug", "AUG HBAR", "weapon_steyr_lmg", lmg);
	lethalbeats\weapon::weapon_custom_add("lmg", "iw5_iw4rpd", "RPD", "weapon_rpd", lmg);

	lethalbeats\weapon::weapon_custom_add("shotgun", "iw5_iw4m1014", "M1014", "weapon_benelli_super_90", ["reflex", "eotech", "grip", "silencer03", "xmags"]);
	lethalbeats\weapon::weapon_custom_add("shotgun", "iw5_iw4ranger", "Ranger", "weapon_sawed_off_double_barrel", ["akimbo"], 1);

	machinePistol = ["reflexsmg", "eotechsmg", "silencer02", "xmags", "akimbo"];
	lethalbeats\weapon::weapon_custom_add("machine_pistol", "iw5_iw4beretta393", "M93 Raffica", "weapon_beretta_393", machinePistol);
	lethalbeats\weapon::weapon_custom_add("machine_pistol", "iw5_iw4pp2000", "PP2000", "weapon_pp2000", machinePistol);

	lethalbeats\weapon::weapon_custom_add("pistol", "iw5_iw4beretta", "M9", "weapon_beretta", ["silencer02", "xmags", "akimbo"], 2);

	lethalbeats\weapon::weapon_custom_add("shotgun", "iw5_1887", "Model 1887", "weapon_model1887", ["akimbo"], 1);

	smg = array_append(smg, "hamrhybrid");
	lethalbeats\weapon::weapon_custom_add("smg", "iw5_ump45", "UMP45", "weapon_ump45_iw5", smg);
	lethalbeats\weapon::weapon_custom_add("smg", "iw5_p90", "P90", "weapon_p90_iw5", smg);

	lethalbeats\utility::clear_score_info();
	
	level.startTime = gettime();
	level.defaultLoadout = lethalbeats\utility::get_loadout_blank("iw5_fnfiveseven");
	level.wave_num = 0;
	level.axisTarget = undefined;
	
	level.bots_slots = getBotSlotsTarget();
	level.bots_wave = [];
	level.bots_total_count = 0;
	level.bots_deaths = 0;
	level.bots_awaits = 0;
	level.bots_weapons_data = [];
	level.survivors_deaths = [];
	level.survivors_bleedout = [];
	level.survivors_sentry_count = 0;
	level.score_base = 0;
	level.game_ended = 0;
	level.maxPerPlayerExplosives = 10;
	level.healthRegenDisabled = 0;
	level.inGracePeriod = 0;
	level.c4s = [];
	level.claymores = [];
	level.droppedWeapons = [];
	level.corpses = [];
	level.botsIMS = [];
	level.botsSentry = [];
	level.rankedmatch = 0;
	level.bots_maxknifedistance = 128 * 128;
	level.blockWeaponDrops = 1;
	level.scavengerBags = [];

	regenTime = maps\mp\gametypes\_tweakables::getTweakableValue("player", "healthregentime");
	if (isDefined(regenTime)) regenTime = 5;
	level.healthoverlaycutoff = 0.55;
    level.playerhealth_regularregendelay = regenTime * 1000;
    level.healthregendisabled = level.playerhealth_regularregendelay <= 0;
	
	level.difficulty = getDvarInt("survival_enemy_difficulty");
		
	lethalbeats\survival\patch\globallogic::patch_callbacks();
	lethalbeats\botactor\utility::bot_init();

	lethalbeats\botactor\config::bot_config_set("grenade_flee", 1);
	lethalbeats\botactor\config::bot_config_set("grenade_radius", 700);
	lethalbeats\botactor\config::bot_config_set("grenade_windup_min_ms", 0);
	lethalbeats\botactor\config::bot_config_set("grenade_windup_max_ms", 0);
	lethalbeats\botactor\config::bot_config_set("path_searches_per_tick", 8);

	if (!getDvarInt("survival_wave_start")) return;

	level thread waitPlayers();
	level thread addBots();
	
	level thread onWaveStart();
	level thread onWaveEnd();
	level thread onEndLevel();

	level thread level_vehicle_monitor();
	level thread level_bots_give_ammo();

	lethalbeats\botactor\ai_hunter::bot_hunter_start(::getBots, ::gettSurvivors);
}

getBots() { return bots(undefined, true); }
gettSurvivors() { return array_filter(level.players, ::survivor_filter); }

onWaveStart()
{
	level endon("game_ended");

	for(;;)
	{
		level waittill("wave_start");
		
		if(!level.wave_num) level.wave_num = level_get_wave();
		else
		{
			level.wave_num++;

			cleanupInterval = getDvarInt("survival_wave_cleanup_interval");
			if (cleanupInterval && (level.wave_num - 1) % cleanupInterval == 0)
			{
				foreach(player in level.players) if (player isTestClient()) kick(player getEntityNumber());
				level_save_state();
				map_restart(1);
				return;
			}
		}

		print("Wave: " + level.wave_num);
		survivors_call(::survivor_wave_init);
		
		level.bots_wave = array_shuffle(get_botsTypes());
		level.bots_total_count = level.bots_wave.size;
		level.bots_awaits = level.bots_total_count;
		level.bots_deaths = 0;
		level.score_base = 0;
		level.waveStartTime = gettime();

		foreach(bot in bots()) bot notify("release_bot");
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

		foreach(uav in level.uavmodels["axis"])
		{
			if (uav.uavtype == "counter") 
			{
				playFx(level.uav_fx["explode"], uav.origin, anglesToRight(uav.angles) * 200);
				uav notify("death");
			}
		}

		level.bots_wave = [];
		level.bots_total_count = 0;
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
	if(level.skip_intermission == survivors(true).size) 
	{
		notifyMessage(NOTIFY_SKIP_CASH_BONUS);
		survivors_call(::survivor_give_score, undefined, get_skip_intermission_bonus());
		level notify("intermission_end");
	}
	
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
	level_rotate_map(delay);
}

onNormalDeath(victim, attacker, lifeId)
{
	score = maps\mp\gametypes\_rank::getScoreInfoValue("kill");
	attacker maps\mp\gametypes\_gamescore::giveTeamScoreForObjective(attacker.pers["team"], score);
	
	if (game["state"] == "postgame" && game["teamScores"][attacker.team] > game["teamScores"][level.otherTeam[attacker.team]])
		attacker.finalKill = true;
}

addBots()
{
	level endon("game_ended");
	level waittill("player_spawned");
	botSlotsUpdate();
	level notify("bots_connected");
}

botSlotsUpdate(player)
{
	if (isDefined(level.bots_slot_syncing) && level.bots_slot_syncing) return;
	level.bots_slot_syncing = true;

	targetSlots = getBotSlotsTarget();
	level.bots_slots = targetSlots;

	slotBots = bots();
	while (slotBots.size > targetSlots)
	{
		bot = getBotSlotKickCandidate(slotBots, player);
		if (!isDefined(bot)) break;

		if (isDefined(bot) && isAlive(bot) && isDefined(bot.botType) && isDefined(level.bots_total_count) && level.bots_total_count > level.bots_deaths)
		{
			level.bots_total_count--;
			if (level.bots_total_count == level.bots_deaths) level notify("wave_end");
		}

		bot lethalbeats\botactor\utility::bot_kick();
		waittillframeend;

		slotBots = bots();
	}

	slotBots = bots();
	while (slotBots.size < targetSlots)
	{
		bot = lethalbeats\botactor\utility::bot_add("axis");
		if (!isDefined(bot)) break;

		bot.pers["isBot"] = true;
		bot.pers["score"] = 0;

		bot thread lethalbeats\Survival\botHandler::onBotSpawn();
		bot thread lethalbeats\Survival\botHandler::botWaitRespawn();

		if (level.wave_num && level.bots_awaits)
			bot notify("release_bot");

		waittillframeend;
		slotBots = bots();
	}

	level.bots_slot_syncing = false;
}

getBotSlotsTarget()
{
	survivorLimit = getDvarInt("survival_survivors_limit");
	if (survivorLimit < 1) survivorLimit = 1;
	if (survivorLimit > MAX_CLIENT_SLOTS) survivorLimit = MAX_CLIENT_SLOTS;

	realPlayers = lethalbeats\utility::get_players("allies", undefined, 1).size;
	if (realPlayers > survivorLimit) realPlayers = survivorLimit;
	if (realPlayers > MAX_CLIENT_SLOTS) realPlayers = MAX_CLIENT_SLOTS;

	return MAX_CLIENT_SLOTS - realPlayers;
}

getBotSlotKickCandidate(slotBots, player)
{
	foreach (bot in slotBots)
	{
		if (!isDefined(bot)) continue;
		if (!isAlive(bot)) return bot;
	}

	if (isDefined(player) && isDefined(player.origin))
	{
		slotBots = sortByDistance(slotBots, player.origin);
		if (slotBots.size) return slotBots[slotBots.size - 1];
	}

	if (slotBots.size) return slotBots[slotBots.size - 1];
	return undefined;
}

getAxisActorSpawnPoint()
{
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints("axis");
	if (!isDefined(spawnPoints) || !spawnPoints.size) return undefined;

	filtered = array_filter(spawnPoints, ::_spawnPointFilter);
	if (!isDefined(filtered) || !filtered.size) filtered = spawnPoints;

	return maps\mp\gametypes\_spawnlogic::getSpawnpoint_nearTeam(filtered);
}

onAddSurvivor()
{
	level notify("survivor_connected");
	waittillframeend;
    if (!isdefined(self) || self isTestClient()) return;

	level thread botSlotsUpdate(self);

	if (isDefined(level.waitingLabel)) self thread onSurvivorSkipWaitPlayers();
	if (isDefined(level.timerHud)) self thread onSurvivorSkipIntermission();
	self survivor_wave_init();
	
	self setClientDvar("ui_start_time", level.startTime);
	self maps\mp\gametypes\_menus::addToTeam("allies", 1);
	
	if (!isDefined(game["saveState"])) self waittill("begin");
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

	if (!isDefined(game["saveState"]))
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

get_skip_intermission_bonus()
{
	remainingSeconds = level.timerHud.value;
	if (!isDefined(remainingSeconds)) remainingSeconds = 0;

	wave = level.wave_num;
	if (!isDefined(wave) || wave < 1) wave = 1;

	waveStep = int((wave - 1) / 5);
	multiplier = min(35, 15 + (waveStep * 5));

	return int(remainingSeconds * multiplier);
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
	
	team = self isTestClient() ? "axis" : "allies";
	maps\mp\gametypes\_menus::addToTeam(team, 1);
	
	if (team == "allies")
	{
		if (!level.wave_num) spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray("mp_tdm_spawn_allies_start");
		else spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints(team);
		return array_random(array_filter(spawnPoints, ::_spawnPointFilter));
	}
	
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints(team);
	return _getAxisSpawnpoint(spawnPoints);
}

_getAxisSpawnpoint(spawnPoints)
{
	if (!isDefined(spawnPoints) || !spawnPoints.size) return undefined;
	if (!isDefined(level.axisSpawnSectorLastUse)) level.axisSpawnSectorLastUse = [];

	minSpawnDistSq = 1200 * 1200; 
	anchors = [];
	center = (0, 0, 0);

	foreach (survivor in survivors(true))
	{
		if (!isDefined(survivor)) continue;
		anchors[anchors.size] = survivor;
		center += survivor.origin;
	}

	if (anchors.size) center = (center[0] / anchors.size, center[1] / anchors.size, center[2] / anchors.size);
	else if (isDefined(level.mapcenter)) center = level.mapcenter;

	strictUnseenCandidates = [];
	strictCandidates = [];
	relaxedCandidates = [];

	foreach (spawnPoint in spawnPoints)
	{
		if (!isDefined(spawnPoint)) continue;
		if (is_shop_near(spawnPoint.origin)) continue;

		minDistSq = minSpawnDistSq;
		isVisible = false;

		if (anchors.size)
		{
			minDistSq = 999999999;
			foreach (survivor in anchors)
			{
				distSq = distanceSquared(spawnPoint.origin, survivor.origin);
				if (distSq < minDistSq) minDistSq = distSq;
				if (!isVisible) isVisible = SightTracePassed(survivor getEye(), spawnPoint.origin + (0, 0, 40), false, survivor);
			}
		}

		candidate = spawnStruct();
		candidate.spawnPoint = spawnPoint;
		candidate.minDistSq = minDistSq;
		candidate.sector = _getAxisSpawnSector(spawnPoint.origin, center);
		
		relaxedCandidates[relaxedCandidates.size] = candidate;

		if (minDistSq >= minSpawnDistSq)
		{
			strictCandidates[strictCandidates.size] = candidate;
			if (!isVisible) strictUnseenCandidates[strictUnseenCandidates.size] = candidate;
		}
	}

	candidates = [];
	if (strictUnseenCandidates.size > 0) candidates = strictUnseenCandidates;
	else if (strictCandidates.size > 0) candidates = strictCandidates;
	else
	{
		if (relaxedCandidates.size > 0 && anchors.size > 0)
		{
			bestRelaxed = [];
			highestMinDistSq = 0;
			
			foreach (candidate in relaxedCandidates)
			{
				if (candidate.minDistSq > highestMinDistSq)
					highestMinDistSq = candidate.minDistSq;
			}
			
			marginDist = highestMinDistSq * 0.8; 
			foreach (candidate in relaxedCandidates)
			{
				if (candidate.minDistSq >= marginDist)
					bestRelaxed[bestRelaxed.size] = candidate;
			}
			candidates = bestRelaxed;
		}
		else 
		{
			candidates = relaxedCandidates;
		}
	}

	if (!candidates.size) return array_random(spawnPoints);

	freeCandidates = [];
	foreach (candidate in candidates)
	{
		if (!positionwouldtelefrag(candidate.spawnPoint.origin))
			freeCandidates[freeCandidates.size] = candidate;
	}
	if (freeCandidates.size) candidates = freeCandidates;

	sectorCandidates = [];
	bestSectorTime = undefined;
	foreach (candidate in candidates)
	{
		sectorTime = 0;
		if (isDefined(level.axisSpawnSectorLastUse[candidate.sector]))
			sectorTime = level.axisSpawnSectorLastUse[candidate.sector];

		if (!isDefined(bestSectorTime) || sectorTime < bestSectorTime)
		{
			bestSectorTime = sectorTime;
			sectorCandidates = [];
			sectorCandidates[sectorCandidates.size] = candidate;
		}
		else if (sectorTime == bestSectorTime)
			sectorCandidates[sectorCandidates.size] = candidate;
	}
	if (sectorCandidates.size) candidates = sectorCandidates;

	bestCandidates = [];
	oldestUseTime = undefined;
	foreach (candidate in candidates)
	{
		useTime = 0;
		if (isDefined(candidate.spawnPoint.lastspawntime))
			useTime = candidate.spawnPoint.lastspawntime;

		if (!isDefined(oldestUseTime) || useTime < oldestUseTime)
		{
			oldestUseTime = useTime;
			bestCandidates = [];
			bestCandidates[bestCandidates.size] = candidate;
		}
		else if (useTime == oldestUseTime)
			bestCandidates[bestCandidates.size] = candidate;
	}

	if (!bestCandidates.size) bestCandidates = candidates;
	pick = bestCandidates[randomInt(bestCandidates.size)];

	if (!isDefined(pick) || !isDefined(pick.spawnPoint))
	{
		pick = candidates[randomInt(candidates.size)];
		if (!isDefined(pick) || !isDefined(pick.spawnPoint))
			return array_random(spawnPoints);
	}

	level.axisSpawnSectorLastUse[pick.sector] = gettime();
	return pick.spawnPoint;
}

_getAxisSpawnSector(origin, center)
{
	dir = origin - center;
	dir = (dir[0], dir[1], 0);

	if (abs(dir[0]) < 1 && abs(dir[1]) < 1)
		return 0;

	yaw = vectorToAngles(dir)[1];
	if (yaw < 0) yaw += 360;

	sector = int((yaw + 22.5) / 45);
	if (sector >= 8) sector = 0;

	return sector;
}

_spawnPointFilter(i)
{
	return !is_shop_near(i.origin);
}

_botTargetFindCountSurvivor(aliveSurvivors, assignCount, minCount)
{
	best = undefined;
	bestCount = undefined;

	foreach (survivor in aliveSurvivors)
	{
		count = assignCount[survivor.guid];
		if (!isDefined(best) || (minCount && count < bestCount) || (!minCount && count > bestCount))
		{
			best = survivor;
			bestCount = count;
		}
	}

	return best;
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
		case NOTIFY_SKIP_CASH_BONUS:
			notifyData.titleText = "Skip Intermission $ " + get_skip_intermission_bonus();
			notifyData.glowColor = (1, 0.49, 0);
			notifyData.duration = 1;
			notifyData.sound = "survival_bonus_splash";
			break;
		default:
			return;
	}
	if (isDefined(sound)) notifyData.sound = sound;
	if (isDefined(titleText)) notifyData.titleText = titleText;
	hud_notify_message(notifyData);
}

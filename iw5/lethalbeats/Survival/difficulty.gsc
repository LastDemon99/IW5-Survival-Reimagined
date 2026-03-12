#define DIFFICULTY_EASY 1
#define DIFFICULTY_NORMAL 2
#define DIFFICULTY_HARD 3

#define WAVES_TABLE_EASY "mp/survival_wave_easy.csv"
#define WAVES_TABLE_NORMAL "mp/survival_wave_normal.csv"
#define WAVES_TABLE_HARD "mp/survival_wave_hard.csv"

//////////////////////////////////////////
//	           BOTS SETTINGS   	        //
//////////////////////////////////////////

_difficulty_get_bot_profile_easy()
{
	settings = [];

	// Target Acquisition And Tracking (BotWarfare)
	settings["aim_time"] = 0.95; // botwarfare: how long it takes for a bot to aim to a location (s).
	settings["reaction_time"] = 3000; // botwarfare: reaction time of the bot for initial/reoccurring targets (ms).
	settings["remember_time"] = 0; // botwarfare: how long a bot remembers a target without sight (ms).
	settings["no_trace_ads_time"] = 0; // botwarfare: how long a bot ADSes when it cannot see the target (ms).
	settings["help_dist"] = 500; // botwarfare: how far a bot has awareness
	settings["fov"] = 0.65; // botwarfare: bot FOV, -1 is 360 and 1 is 0 (cone dot).

	// Aim Correction And Post-LOS Behavior (BotWarfare)
	settings["semi_time"] = 1; // botwarfare: how fast a bot shoots semiauto (s).
	settings["shoot_after_time"] = 1.65; // botwarfare: how long a bot shoots after target dies/cannot be seen (s).
	settings["aim_offset_time"] = 2; // botwarfare: how long a bot corrects aim after targeting (s).
	settings["aim_offset_amount"] = 5.25; // botwarfare: how far a bot's incorrect aim is.
	settings["bone_update_interval"] = 2.6; // botwarfare: how often a bot changes target bone (s).

	// Human Bot Behavior (BotWarfare)
	settings["behaviorInitSwitch"] = 0; // botwarfare: percentage of how often the bot switches weapons on spawn.
	settings["behaviorStrafe"] = 20; // botwarfare: percentage of how often the bot strafes a target.
	settings["behaviorNade"] = 30; // botwarfare: percentage of how often the bot throws grenades.
	settings["behaviorSprint"] = 30; // botwarfare: percentage of how often the bot sprints.
	settings["behaviorCamp"] = 0; // botwarfare: percentage of how often the bot camps.
	settings["behaviorFollow"] = 100; // botwarfare: percentage of how often the bot follows.
	settings["behaviorCrouch"] = 0; // botwarfare: percentage of how often the bot crouches.
	settings["behaviorSwitch"] = 0; // botwarfare: percentage of how often the bot switches weapons.
	settings["behaviorClass"] = 0; // botwarfare: percentage of how often the bot changes classes.
	settings["behaviorJump"] = 5; // botwarfare: percentage of how often the bot jumpshots/dropshots.
	settings["behaviorQuickscope"] = 0; // botwarfare: quickscope behavior toggle.

	// Fire Cycle (Survival)
	settings["fireTime"] = 0.35; // survival: duration per fire pulse in the unified fire cycle (s).
	settings["minShots"] = 10; // survival: minimum shots per continuous fire cycle.
	settings["maxShots"] = 15; // survival: maximum shots per continuous fire cycle.
	settings["minPause"] = 3; // survival: minimum pause between fire cycles (s).
	settings["maxPause"] = 5; // survival: maximum pause between fire cycles (s).
	settings["windUpTime"] = 0.8; // survival: prep time before first shot after LOS/target reacquire (s).

	// Survivability And Spawn (Survival)
	settings["survivorDamageScale"] = 0.8; // survival: damage taken scale for survivors.
	settings["botHealthMultiplier"] = 1; // survival: bot health multiplier.
	settings["botSpeedMultiplier"] = 0.85; // survival: bot speed multiplier.
	settings["botRespawnDelayMin"] = 3; // survival: minimum bot respawn delay (s).
	settings["botRespawnDelayMax"] = 6; // survival: maximum bot respawn delay (s).

	weaponClass = lethalbeats\weapon::weapon_get_class(self.pers["gamemodeLoadout"]["loadoutPrimary"]);
	if (weaponClass == "sniper") settings["semi_time"] = 4; // botwarfare: how fast a bot shoots semiauto (s).

	return settings;
}

_difficulty_get_bot_profile_normal()
{
	settings = [];

	// Target Acquisition And Tracking (BotWarfare)
	settings["aim_time"] = 0.75; // botwarfare: how long it takes for a bot to aim to a location (s).
	settings["reaction_time"] = 1800; // botwarfare: reaction time of the bot for initial/reoccurring targets (ms).
	settings["remember_time"] = 400; // botwarfare: how long a bot remembers a target without sight (ms).
	settings["no_trace_ads_time"] = 350; // botwarfare: how long a bot ADSes when it cannot see the target (ms).
	settings["help_dist"] = 800; // botwarfare: how far a bot has awareness
	settings["fov"] = 0.6; // botwarfare: bot FOV, -1 is 360 and 1 is 0 (cone dot).

	// Aim Correction And Post-LOS Behavior (BotWarfare)
	settings["semi_time"] = 0.85; // botwarfare: how fast a bot shoots semiauto (s).
	settings["shoot_after_time"] = 1.2; // botwarfare: how long a bot shoots after target dies/cannot be seen (s).
	settings["aim_offset_time"] = 1.5; // botwarfare: how long a bot corrects aim after targeting (s).
	settings["aim_offset_amount"] = 4; // botwarfare: how far a bot's incorrect aim is.
	settings["bone_update_interval"] = 2; // botwarfare: how often a bot changes target bone (s).

	// Human Bot Behavior (BotWarfare)
	settings["behaviorInitSwitch"] = 0; // botwarfare: percentage of how often the bot switches weapons on spawn.
	settings["behaviorStrafe"] = 35; // botwarfare: percentage of how often the bot strafes a target.
	settings["behaviorNade"] = 45; // botwarfare: percentage of how often the bot throws grenades.
	settings["behaviorSprint"] = 45; // botwarfare: percentage of how often the bot sprints.
	settings["behaviorCamp"] = 0; // botwarfare: percentage of how often the bot camps.
	settings["behaviorFollow"] = 100; // botwarfare: percentage of how often the bot follows.
	settings["behaviorCrouch"] = 0; // botwarfare: percentage of how often the bot crouches.
	settings["behaviorSwitch"] = 0; // botwarfare: percentage of how often the bot switches weapons.
	settings["behaviorClass"] = 0; // botwarfare: percentage of how often the bot changes classes.
	settings["behaviorJump"] = 12; // botwarfare: percentage of how often the bot jumpshots/dropshots.
	settings["behaviorQuickscope"] = 0; // botwarfare: quickscope behavior toggle.

	// Fire Cycle (Survival)
	settings["fireTime"] = 0.22; // survival: duration per fire pulse in the unified fire cycle (s).
	settings["minShots"] = 16; // survival: minimum shots per continuous fire cycle.
	settings["maxShots"] = 26; // survival: maximum shots per continuous fire cycle.
	settings["minPause"] = 2; // survival: minimum pause between fire cycles (s).
	settings["maxPause"] = 3.5; // survival: maximum pause between fire cycles (s).
	settings["windUpTime"] = 0.55; // survival: prep time before first shot after LOS/target reacquire (s).

	// Survivability And Spawn (Survival)
	settings["survivorDamageScale"] = 1; // survival: damage taken scale for survivors.
	settings["botHealthMultiplier"] = 1.1; // survival: bot health multiplier.
	settings["botSpeedMultiplier"] = 1; // survival: bot speed multiplier.
	settings["botRespawnDelayMin"] = 1; // survival: minimum bot respawn delay (s).
	settings["botRespawnDelayMax"] = 3; // survival: maximum bot respawn delay (s).

	weaponClass = lethalbeats\weapon::weapon_get_class(self.pers["gamemodeLoadout"]["loadoutPrimary"]);
	if (weaponClass == "sniper") settings["semi_time"] = 2.4; // botwarfare: how fast a bot shoots semiauto (s).

	return settings;
}

_difficulty_get_bot_profile_hard()
{
	settings = [];

	// Target Acquisition And Tracking (BotWarfare)
	settings["aim_time"] = 0.45; // botwarfare: how long it takes for a bot to aim to a location (s).
	settings["reaction_time"] = 900; // botwarfare: reaction time of the bot for initial/reoccurring targets (ms).
	settings["remember_time"] = 900; // botwarfare: how long a bot remembers a target without sight (ms).
	settings["no_trace_ads_time"] = 700; // botwarfare: how long a bot ADSes when it cannot see the target (ms).
	settings["help_dist"] = 1200; // botwarfare: how far a bot has awareness
	settings["fov"] = 0.5; // botwarfare: bot FOV, -1 is 360 and 1 is 0 (cone dot).

	// Aim Correction And Post-LOS Behavior (BotWarfare)
	settings["semi_time"] = 0.55; // botwarfare: how fast a bot shoots semiauto (s).
	settings["shoot_after_time"] = 0.8; // botwarfare: how long a bot shoots after target dies/cannot be seen (s).
	settings["aim_offset_time"] = 0.9; // botwarfare: how long a bot corrects aim after targeting (s).
	settings["aim_offset_amount"] = 2.75; // botwarfare: how far a bot's incorrect aim is.
	settings["bone_update_interval"] = 1.2; // botwarfare: how often a bot changes target bone (s).

	// Fire Cycle (Survival)
	settings["fireTime"] = 0.12; // survival: duration per fire pulse in the unified fire cycle (s).
	settings["minShots"] = 28; // survival: minimum shots per continuous fire cycle.
	settings["maxShots"] = 45; // survival: maximum shots per continuous fire cycle.
	settings["minPause"] = 1; // survival: minimum pause between fire cycles (s).
	settings["maxPause"] = 2; // survival: maximum pause between fire cycles (s).
	settings["windUpTime"] = 0.25; // survival: prep time before first shot after LOS/target reacquire (s).

	// Survivability And Spawn (Survival)
	settings["botHealthMultiplier"] = 1.35; // survival: bot health multiplier.
	settings["botSpeedMultiplier"] = 1.2; // survival: bot speed multiplier.
	settings["botRespawnDelayMin"] = 0; // survival: minimum bot respawn delay (s).
	settings["botRespawnDelayMax"] = 1; // survival: maximum bot respawn delay (s).

	// Human Bot Behavior (BotWarfare)
	settings["behaviorInitSwitch"] = 0; // botwarfare: percentage of how often the bot switches weapons on spawn.
	settings["behaviorStrafe"] = 50; // botwarfare: percentage of how often the bot strafes a target.
	settings["behaviorNade"] = 70; // botwarfare: percentage of how often the bot throws grenades.
	settings["behaviorSprint"] = 60; // botwarfare: percentage of how often the bot sprints.
	settings["behaviorCamp"] = 0; // botwarfare: percentage of how often the bot camps.
	settings["behaviorFollow"] = 100; // botwarfare: percentage of how often the bot follows.
	settings["behaviorCrouch"] = 0; // botwarfare: percentage of how often the bot crouches.
	settings["behaviorSwitch"] = 0; // botwarfare: percentage of how often the bot switches weapons.
	settings["behaviorClass"] = 0; // botwarfare: percentage of how often the bot changes classes.
	settings["behaviorJump"] = 20; // botwarfare: percentage of how often the bot jumpshots/dropshots.
	settings["behaviorQuickscope"] = 0; // botwarfare: quickscope behavior toggle.

	weaponClass = lethalbeats\weapon::weapon_get_class(self.pers["gamemodeLoadout"]["loadoutPrimary"]);
	if (weaponClass == "sniper") settings["semi_time"] = 1.4; // botwarfare: how fast a bot shoots semiauto (s).

	return settings;
}

//////////////////////////////////////////
//	          VEHICLE SETTINGS   	    //
//////////////////////////////////////////

difficulty_get_h6_burst_settings()
{
	settings = [];

	switch(difficulty_get_level())
	{
		case DIFFICULTY_HARD:
			settings["fireTime"] = 0.05;
			settings["minShots"] = 80;
			settings["maxShots"] = 80;
			settings["minPause"] = 0.5;
			settings["maxPause"] = 1;
			settings["windUpTime"] = 0;
			return settings;

		case DIFFICULTY_NORMAL:
			settings["fireTime"] = 0.1;
			settings["minShots"] = 40;
			settings["maxShots"] = 80;
			settings["minPause"] = 2;
			settings["maxPause"] = 3;
			settings["windUpTime"] = 1;
			return settings;

		default:
			settings["fireTime"] = 0.15;
			settings["minShots"] = 40;
			settings["maxShots"] = 80;
			settings["minPause"] = 2;
			settings["maxPause"] = 3;
			settings["windUpTime"] = 1.75;
			return settings;
	};
}

difficulty_get_pavelow_burst_settings()
{
	settings = [];

	switch(difficulty_get_level())
	{
		case DIFFICULTY_HARD:
			settings["fireTime"] = 0.035;
			settings["minShots"] = 120;
			settings["maxShots"] = 120;
			settings["minPause"] = 0.25;
			settings["maxPause"] = 0.5;
			settings["windUpTime"] = 0;
			return settings;

		case DIFFICULTY_NORMAL:
			settings["fireTime"] = 0.08;
			settings["minShots"] = 60;
			settings["maxShots"] = 100;
			settings["minPause"] = 1;
			settings["maxPause"] = 2;
			settings["windUpTime"] = 0.5;
			return settings;

		default:
			settings["fireTime"] = 0.12;
			settings["minShots"] = 40;
			settings["maxShots"] = 80;
			settings["minPause"] = 1.5;
			settings["maxPause"] = 2.5;
			settings["windUpTime"] = 1;
			return settings;
	};
}

difficulty_get_reaper_burst_settings()
{
	settings = [];

	switch(difficulty_get_level())
	{
		case DIFFICULTY_HARD:
			settings["fireTime"] = 2.2;
			settings["windUpTime"] = 0;
			return settings;

		case DIFFICULTY_NORMAL:
			settings["fireTime"] = 4.5;
			settings["windUpTime"] = 0.75;
			return settings;

		default:
			settings["fireTime"] = 5;
			settings["windUpTime"] = 1;
			return settings;
	};
}

//////////////////////////////////////////
//	             UTILITY        	    //
//////////////////////////////////////////

difficulty_get_level()
{
	if (!isDefined(level.difficulty)) return DIFFICULTY_NORMAL;
	return int(max(DIFFICULTY_EASY, min(DIFFICULTY_HARD, level.difficulty)));
}

difficulty_is_easy()
{
	return difficulty_get_level() == DIFFICULTY_EASY;
}

difficulty_is_normal()
{
	return difficulty_get_level() == DIFFICULTY_NORMAL;
}

difficulty_is_hard()
{
	return difficulty_get_level() == DIFFICULTY_HARD;
}

difficulty_get_wave_loop_growth()
{
	switch(difficulty_get_level())
	{
		case DIFFICULTY_EASY: return 1.02;
		case DIFFICULTY_HARD: return 1.06;
		default: return 1.05;
	}
}

difficulty_get_waves_table()
{
	switch(difficulty_get_level())
	{
		case DIFFICULTY_NORMAL: return WAVES_TABLE_NORMAL;
		case DIFFICULTY_HARD: return WAVES_TABLE_HARD;
		default: return WAVES_TABLE_EASY;
	}
}

difficulty_get_bot_settings()
{
	switch(difficulty_get_level())
	{
		case DIFFICULTY_HARD: return self _difficulty_get_bot_profile_hard();
		case DIFFICULTY_NORMAL: return self _difficulty_get_bot_profile_normal();
		default: return self _difficulty_get_bot_profile_easy();
	}
}

#define DIFFICULTY_EASY 1
#define DIFFICULTY_NORMAL 2
#define DIFFICULTY_HARD 3

#define WAVES_TABLE_EASY "mp/survival_wave_easy.csv"
#define WAVES_TABLE_NORMAL "mp/survival_wave_normal.csv"
#define WAVES_TABLE_HARD "mp/survival_wave_hard.csv"

#define SKILL_AIM_TIME 60
#define SKILL_INIT_REACT_TIME 61
#define SKILL_REACTION_TIME 62
#define SKILL_NO_TRACE_ADS_TIME 63
#define SKILL_NO_TRACE_LOOK_TIME 64
#define SKILL_REMEMBER_TIME 65
#define SKILL_FOV 67
#define SKILL_DIST_MAX 68
#define SKILL_SEMI_TIME 79
#define SKILL_SHOOT_AFTER_TIME 69
#define SKILL_AIM_OFFSET_TIME 70
#define SKILL_AIM_OFFSET_AMOUNT 71
#define SKILL_BONE_UPDATE_INTERVAL 72
#define SKILL_BONES 73
#define SKILL_ADS_FOV_MULTI 74
#define SKILL_ADS_AIMSPEED_MULTI 75

#define BEHAVIOR_STRAFE 100
#define BEHAVIOR_NADE 101
#define BEHAVIOR_SPRINT 102
#define BEHAVIOR_CROUCH 103
#define BEHAVIOR_JUMP 104
#define BEHAVIOR_QUICKSCOPE 105

#define FIRE_TIME 110
#define MIN_SHOTS 111
#define MAX_SHOTS 112
#define MIN_PAUSE 113
#define MAX_PAUSE 114
#define WIND_UP_TIME 115

#define SURVIVOR_DAMAGE_SCALE 160
#define BOT_HEALTH_MULTIPLIER 161
#define BOT_SPEED_MULTIPLIER 162
#define BOT_RESPAWN_DELAY_MIN 163
#define BOT_RESPAWN_DELAY_MAX 164

//////////////////////////////////////////
//	           BOTS SETTINGS   	        //
//////////////////////////////////////////

_difficulty_get_bot_profile_easy()
{
	settings = [];

	// Target acquisition and tracking (botActor).
	settings[SKILL_AIM_TIME] = 0.5;
	settings[SKILL_INIT_REACT_TIME] = 1.0;
	settings[SKILL_REACTION_TIME] = 1.0;
	settings[SKILL_REMEMBER_TIME] = undefined;
	settings[SKILL_NO_TRACE_ADS_TIME] = 0;
	settings[SKILL_NO_TRACE_LOOK_TIME] = 0;
	settings[SKILL_FOV] = 0.65;

	// Aim correction / post-LOS (botActor).
	settings[SKILL_SEMI_TIME] = 1;
	settings[SKILL_SHOOT_AFTER_TIME] = 1.65;
	settings[SKILL_AIM_OFFSET_TIME] = 2;
	settings[SKILL_AIM_OFFSET_AMOUNT] = 5.25;
	settings[SKILL_BONE_UPDATE_INTERVAL] = 0.5;

	// Human behavior (botActor).
	settings[BEHAVIOR_STRAFE] = 20;
	settings[BEHAVIOR_NADE] = 30;
	settings[BEHAVIOR_SPRINT] = 30;
	settings[BEHAVIOR_CROUCH] = 0;
	settings[BEHAVIOR_JUMP] = 5;
	settings[BEHAVIOR_QUICKSCOPE] = 0;

	// Fire cycle (botActor).
	settings[FIRE_TIME] = 0.35;
	settings[MIN_SHOTS] = 10;
	settings[MAX_SHOTS] = 15;
	settings[MIN_PAUSE] = 3;
	settings[MAX_PAUSE] = 5;
	settings[WIND_UP_TIME] = 0.8;

	// Survival multipliers.
	settings[SURVIVOR_DAMAGE_SCALE] = 0.8;
	settings[BOT_HEALTH_MULTIPLIER] = 1;
	settings[BOT_SPEED_MULTIPLIER] = 0.85;
	settings[BOT_RESPAWN_DELAY_MIN] = 3;
	settings[BOT_RESPAWN_DELAY_MAX] = 6;

	weaponClass = lethalbeats\weapon::weapon_get_class(self.pers["gamemodeLoadout"]["loadoutPrimary"]);
	if (weaponClass == "sniper") settings[SKILL_SEMI_TIME] = 4;

	return settings;
}

_difficulty_get_bot_profile_normal()
{
	settings = [];

	// Target acquisition and tracking (botActor).
	settings[SKILL_AIM_TIME] = 0.35;
	settings[SKILL_INIT_REACT_TIME] = 0.8;
	settings[SKILL_REACTION_TIME] = 0.8;
	settings[SKILL_REMEMBER_TIME] = undefined;
	settings[SKILL_NO_TRACE_ADS_TIME] = 0.35;
	settings[SKILL_NO_TRACE_LOOK_TIME] = 0.35;
	settings[SKILL_FOV] = 0.6;

	// Aim correction / post-LOS (botActor).
	settings[SKILL_SEMI_TIME] = 0.85;
	settings[SKILL_SHOOT_AFTER_TIME] = 1.2;
	settings[SKILL_AIM_OFFSET_TIME] = 1.5;
	settings[SKILL_AIM_OFFSET_AMOUNT] = 4;
	settings[SKILL_BONE_UPDATE_INTERVAL] = 0.3;

	// Human behavior (botActor).
	settings[BEHAVIOR_STRAFE] = 35;
	settings[BEHAVIOR_NADE] = 45;
	settings[BEHAVIOR_SPRINT] = 45;
	settings[BEHAVIOR_CROUCH] = 0;
	settings[BEHAVIOR_JUMP] = 12;
	settings[BEHAVIOR_QUICKSCOPE] = 0;

	// Fire cycle (botActor).
	settings[FIRE_TIME] = 0.22;
	settings[MIN_SHOTS] = 16;
	settings[MAX_SHOTS] = 26;
	settings[MIN_PAUSE] = 2;
	settings[MAX_PAUSE] = 3.5;
	settings[WIND_UP_TIME] = 0.55;

	// Survival multipliers.
	settings[SURVIVOR_DAMAGE_SCALE] = 1;
	settings[BOT_HEALTH_MULTIPLIER] = 1.1;
	settings[BOT_SPEED_MULTIPLIER] = 1;
	settings[BOT_RESPAWN_DELAY_MIN] = 1;
	settings[BOT_RESPAWN_DELAY_MAX] = 3;

	weaponClass = lethalbeats\weapon::weapon_get_class(self.pers["gamemodeLoadout"]["loadoutPrimary"]);
	if (weaponClass == "sniper") settings[SKILL_SEMI_TIME] = 2.4;

	return settings;
}

_difficulty_get_bot_profile_hard()
{
	settings = [];

	// Target acquisition and tracking (botActor).
	settings[SKILL_AIM_TIME] = 0.1;
	settings[SKILL_INIT_REACT_TIME] = 0.4;
	settings[SKILL_REACTION_TIME] = 0.4;
	settings[SKILL_REMEMBER_TIME] = undefined;
	settings[SKILL_NO_TRACE_ADS_TIME] = 0.7;
	settings[SKILL_NO_TRACE_LOOK_TIME] = 0.7;
	settings[SKILL_FOV] = 0.5;

	// Aim correction / post-LOS (botActor).
	settings[SKILL_SEMI_TIME] = 0.55;
	settings[SKILL_SHOOT_AFTER_TIME] = 0.8;
	settings[SKILL_AIM_OFFSET_TIME] = 0.9;
	settings[SKILL_AIM_OFFSET_AMOUNT] = 2.75;
	settings[SKILL_BONE_UPDATE_INTERVAL] = 0.1;

	// Human behavior (botActor).
	settings[BEHAVIOR_STRAFE] = 50;
	settings[BEHAVIOR_NADE] = 70;
	settings[BEHAVIOR_SPRINT] = 60;
	settings[BEHAVIOR_CROUCH] = 0;
	settings[BEHAVIOR_JUMP] = 20;
	settings[BEHAVIOR_QUICKSCOPE] = 0;

	// Fire cycle (botActor).
	settings[FIRE_TIME] = 0.12;
	settings[MIN_SHOTS] = 28;
	settings[MAX_SHOTS] = 45;
	settings[MIN_PAUSE] = 1;
	settings[MAX_PAUSE] = 2;
	settings[WIND_UP_TIME] = 0.25;

	// Survival multipliers.
	settings[SURVIVOR_DAMAGE_SCALE] = 1;
	settings[BOT_HEALTH_MULTIPLIER] = 1.35;
	settings[BOT_SPEED_MULTIPLIER] = 1.2;
	settings[BOT_RESPAWN_DELAY_MIN] = 0;
	settings[BOT_RESPAWN_DELAY_MAX] = 1;

	weaponClass = lethalbeats\weapon::weapon_get_class(self.pers["gamemodeLoadout"]["loadoutPrimary"]);
	if (weaponClass == "sniper") settings[SKILL_SEMI_TIME] = 1.4;

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

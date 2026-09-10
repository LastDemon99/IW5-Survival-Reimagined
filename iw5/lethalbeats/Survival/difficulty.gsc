#define DIFFICULTY_EASY 1
#define DIFFICULTY_NORMAL 2
#define DIFFICULTY_HARD 3


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

#define BOT_RESPAWN_DELAY_MIN 163
#define BOT_RESPAWN_DELAY_MAX 164

//////////////////////////////////////////
//	           BOTS SETTINGS   	        //
//////////////////////////////////////////

_difficulty_get_bot_profile_easy()
{
	settings = [];

	settings[SKILL_AIM_TIME] = 0.9;
	settings[SKILL_INIT_REACT_TIME] = 1.5;
	settings[SKILL_REACTION_TIME] = 1.5;
	settings[SKILL_REMEMBER_TIME] = undefined;
	settings[SKILL_NO_TRACE_ADS_TIME] = 0;
	settings[SKILL_NO_TRACE_LOOK_TIME] = 0;
	settings[SKILL_FOV] = 0.70;

	settings[SKILL_SEMI_TIME] = 1.5;
	settings[SKILL_SHOOT_AFTER_TIME] = 2.0;
	settings[SKILL_AIM_OFFSET_TIME] = 2.5;
	settings[SKILL_AIM_OFFSET_AMOUNT] = 7.50;
	settings[SKILL_BONE_UPDATE_INTERVAL] = 0.6;

	settings[BEHAVIOR_STRAFE] = 10;
	settings[BEHAVIOR_NADE] = 10;
	settings[BEHAVIOR_SPRINT] = 15;
	settings[BEHAVIOR_CROUCH] = 0;
	settings[BEHAVIOR_JUMP] = 0;
	settings[BEHAVIOR_QUICKSCOPE] = 0;

	settings[FIRE_TIME] = 0.45;
	settings[MIN_SHOTS] = 4;
	settings[MAX_SHOTS] = 6;
	settings[MIN_PAUSE] = 4.0;
	settings[MAX_PAUSE] = 6.0;
	settings[WIND_UP_TIME] = 1.30;

	settings[SURVIVOR_DAMAGE_SCALE] = 0.65;
	settings[BOT_RESPAWN_DELAY_MIN] = 4;
	settings[BOT_RESPAWN_DELAY_MAX] = 8;

	weaponClass = lethalbeats\weapon::weapon_get_class(self.pers["gamemodeLoadout"]["loadoutPrimary"]);
	if (weaponClass == "sniper") settings[SKILL_SEMI_TIME] = 4.5;

	return settings;
}

_difficulty_get_bot_profile_normal()
{
	settings = [];

	settings[SKILL_AIM_TIME] = 0.50;
	settings[SKILL_INIT_REACT_TIME] = 1.00;
	settings[SKILL_REACTION_TIME] = 1.00;
	settings[SKILL_REMEMBER_TIME] = undefined;
	settings[SKILL_NO_TRACE_ADS_TIME] = 0.25;
	settings[SKILL_NO_TRACE_LOOK_TIME] = 0.25;
	settings[SKILL_FOV] = 0.62;

	settings[SKILL_SEMI_TIME] = 1.00;
	settings[SKILL_SHOOT_AFTER_TIME] = 1.50;
	settings[SKILL_AIM_OFFSET_TIME] = 1.80;
	settings[SKILL_AIM_OFFSET_AMOUNT] = 5.00;
	settings[SKILL_BONE_UPDATE_INTERVAL] = 0.4;

	settings[BEHAVIOR_STRAFE] = 25;
	settings[BEHAVIOR_NADE] = 30;
	settings[BEHAVIOR_SPRINT] = 35;
	settings[BEHAVIOR_CROUCH] = 0;
	settings[BEHAVIOR_JUMP] = 5;
	settings[BEHAVIOR_QUICKSCOPE] = 0;

	settings[FIRE_TIME] = 0.28;
	settings[MIN_SHOTS] = 10;
	settings[MAX_SHOTS] = 16;
	settings[MIN_PAUSE] = 2.5;
	settings[MAX_PAUSE] = 4.0;
	settings[WIND_UP_TIME] = 0.75;

	settings[SURVIVOR_DAMAGE_SCALE] = 0.90;
	settings[BOT_RESPAWN_DELAY_MIN] = 2;
	settings[BOT_RESPAWN_DELAY_MAX] = 4;

	weaponClass = lethalbeats\weapon::weapon_get_class(self.pers["gamemodeLoadout"]["loadoutPrimary"]);
	if (weaponClass == "sniper") settings[SKILL_SEMI_TIME] = 2.8;

	return settings;
}

_difficulty_get_bot_profile_hard()
{
	settings = [];

	settings[SKILL_AIM_TIME] = 0.30;
	settings[SKILL_INIT_REACT_TIME] = 0.60;
	settings[SKILL_REACTION_TIME] = 0.60;
	settings[SKILL_REMEMBER_TIME] = undefined;
	settings[SKILL_NO_TRACE_ADS_TIME] = 0.50;
	settings[SKILL_NO_TRACE_LOOK_TIME] = 0.50;
	settings[SKILL_FOV] = 0.55;

	settings[SKILL_SEMI_TIME] = 0.70;
	settings[SKILL_SHOOT_AFTER_TIME] = 1.00;
	settings[SKILL_AIM_OFFSET_TIME] = 1.30;
	settings[SKILL_AIM_OFFSET_AMOUNT] = 3.80;
	settings[SKILL_BONE_UPDATE_INTERVAL] = 0.2;

	settings[BEHAVIOR_STRAFE] = 40;
	settings[BEHAVIOR_NADE] = 50;
	settings[BEHAVIOR_SPRINT] = 50;
	settings[BEHAVIOR_CROUCH] = 0;
	settings[BEHAVIOR_JUMP] = 15;
	settings[BEHAVIOR_QUICKSCOPE] = 0;

	settings[FIRE_TIME] = 0.18;
	settings[MIN_SHOTS] = 16;
	settings[MAX_SHOTS] = 26;
	settings[MIN_PAUSE] = 1.8;
	settings[MAX_PAUSE] = 3.0;
	settings[WIND_UP_TIME] = 0.45;

	settings[SURVIVOR_DAMAGE_SCALE] = 1;
	settings[BOT_RESPAWN_DELAY_MIN] = 0;
	settings[BOT_RESPAWN_DELAY_MAX] = 1;

	weaponClass = lethalbeats\weapon::weapon_get_class(self.pers["gamemodeLoadout"]["loadoutPrimary"]);
	if (weaponClass == "sniper") settings[SKILL_SEMI_TIME] = 1.6;

	return settings;
}

difficulty_parse_skill_profile(profileStr, settings)
{
	tokens = strTok(profileStr, ",");
	if (tokens.size == 0) return settings;

	if (tokens.size > 0 && tokens[0] != "") settings[SKILL_AIM_TIME] = float(tokens[0]);
	if (tokens.size > 1 && tokens[1] != "")
	{
		settings[SKILL_REACTION_TIME] = float(tokens[1]);
		settings[SKILL_INIT_REACT_TIME] = float(tokens[1]);
	}
	if (tokens.size > 2 && tokens[2] != "") settings[WIND_UP_TIME] = float(tokens[2]);
	if (tokens.size > 3 && tokens[3] != "") settings[FIRE_TIME] = float(tokens[3]);
	if (tokens.size > 4 && tokens[4] != "") settings[MIN_SHOTS] = int(tokens[4]);
	if (tokens.size > 5 && tokens[5] != "") settings[MAX_SHOTS] = int(tokens[5]);
	if (tokens.size > 6 && tokens[6] != "") settings[MIN_PAUSE] = float(tokens[6]);
	if (tokens.size > 7 && tokens[7] != "") settings[MAX_PAUSE] = float(tokens[7]);
	if (tokens.size > 8 && tokens[8] != "") settings[SKILL_AIM_OFFSET_AMOUNT] = float(tokens[8]);
	if (tokens.size > 9 && tokens[9] != "") settings[SKILL_AIM_OFFSET_TIME] = float(tokens[9]);
	if (tokens.size > 10 && tokens[10] != "") settings[SURVIVOR_DAMAGE_SCALE] = float(tokens[10]);
	if (tokens.size > 11 && tokens[11] != "") settings[BEHAVIOR_STRAFE] = int(tokens[11]);
	if (tokens.size > 12 && tokens[12] != "") settings[BEHAVIOR_NADE] = int(tokens[12]);
	if (tokens.size > 13 && tokens[13] != "") settings[BEHAVIOR_SPRINT] = int(tokens[13]);
	if (tokens.size > 14 && tokens[14] != "") settings[BEHAVIOR_JUMP] = int(tokens[14]);

	return settings;
}

//////////////////////////////////////////
//	          VEHICLE SETTINGS   	    //
//////////////////////////////////////////

difficulty_get_h6_burst_settings()
{
	dvarVal = getDvar("heli_skill_burst");
	if (dvarVal != "")
	{
		tokens = strTok(dvarVal, ",");
		if (tokens.size >= 6)
		{
			settings = [];
			settings["fireTime"] = float(tokens[0]);
			settings["minShots"] = int(tokens[1]);
			settings["maxShots"] = int(tokens[2]);
			settings["minPause"] = float(tokens[3]);
			settings["maxPause"] = float(tokens[4]);
			settings["windUpTime"] = float(tokens[5]);
			return settings;
		}
	}

	settings = [];
	switch(difficulty_get_level())
	{
		case DIFFICULTY_HARD:
			settings["fireTime"] = 0.05;
			settings["minShots"] = 80;
			settings["maxShots"] = 80;
			settings["minPause"] = 0.5;
			settings["maxPause"] = 1;
			settings["windUpTime"] = 0.5;
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
	dvarVal = getDvar("pavelow_skill_burst");
	if (dvarVal != "")
	{
		tokens = strTok(dvarVal, ",");
		if (tokens.size >= 6)
		{
			settings = [];
			settings["fireTime"] = float(tokens[0]);
			settings["minShots"] = int(tokens[1]);
			settings["maxShots"] = int(tokens[2]);
			settings["minPause"] = float(tokens[3]);
			settings["maxPause"] = float(tokens[4]);
			settings["windUpTime"] = float(tokens[5]);
			return settings;
		}
	}

	settings = [];
	switch(difficulty_get_level())
	{
		case DIFFICULTY_HARD:
			settings["fireTime"] = 0.035;
			settings["minShots"] = 120;
			settings["maxShots"] = 120;
			settings["minPause"] = 0.25;
			settings["maxPause"] = 0.5;
			settings["windUpTime"] = 0.25;
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
	dvarVal = getDvar("reaper_skill_burst");
	if (dvarVal != "")
	{
		tokens = strTok(dvarVal, ",");
		if (tokens.size >= 3)
		{
			settings = [];
			settings["fireTime"] = float(tokens[0]);
			settings["windUpTime"] = float(tokens[1]);
			settings["trackingFactor"] = float(tokens[2]);
			return settings;
		}
	}

	settings = [];
	switch(difficulty_get_level())
	{
		case DIFFICULTY_HARD:
			settings["fireTime"] = 2.2;
			settings["windUpTime"] = 0.35;
			settings["trackingFactor"] = 0.45;
			return settings;

		case DIFFICULTY_NORMAL:
			settings["fireTime"] = 4.5;
			settings["windUpTime"] = 0.75;
			settings["trackingFactor"] = 0.25;
			return settings;

		default:
			settings["fireTime"] = 5;
			settings["windUpTime"] = 1;
			settings["trackingFactor"] = 0.15;
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

difficulty_get_bot_settings()
{
	settings = [];
	switch(difficulty_get_level())
	{
		case DIFFICULTY_HARD: settings = self _difficulty_get_bot_profile_hard(); break;
		case DIFFICULTY_NORMAL: settings = self _difficulty_get_bot_profile_normal(); break;
		default: settings = self _difficulty_get_bot_profile_easy(); break;
	}

	profileStr = "";
	if (isDefined(self.botType))
	{
		profileStr = getDvar("bot_skill_" + self.botType);
		if (profileStr == "" && isSubStr(self.botType, "_"))
		{
			tier = strTok(self.botType, "_")[0];
			profileStr = getDvar("bot_skill_" + tier);
		}
	}

	if (profileStr == "")
	{
		profileStr = getDvar("bot_skill_global");
		if (profileStr == "") profileStr = getDvar("bot_skill_default");
	}

	if (profileStr != "")
	{
		settings = difficulty_parse_skill_profile(profileStr, settings);
	}

	if (getDvar("bot_skill_aim_time") != "") settings[SKILL_AIM_TIME] = getDvarFloat("bot_skill_aim_time");
	if (getDvar("bot_skill_reaction_time") != "")
	{
		settings[SKILL_REACTION_TIME] = getDvarFloat("bot_skill_reaction_time");
		settings[SKILL_INIT_REACT_TIME] = getDvarFloat("bot_skill_reaction_time");
	}
	if (getDvar("bot_skill_wind_up_time") != "") settings[WIND_UP_TIME] = getDvarFloat("bot_skill_wind_up_time");
	if (getDvar("bot_skill_fire_time") != "") settings[FIRE_TIME] = getDvarFloat("bot_skill_fire_time");
	if (getDvar("bot_skill_min_shots") != "") settings[MIN_SHOTS] = getDvarInt("bot_skill_min_shots");
	if (getDvar("bot_skill_max_shots") != "") settings[MAX_SHOTS] = getDvarInt("bot_skill_max_shots");
	if (getDvar("bot_skill_min_pause") != "") settings[MIN_PAUSE] = getDvarFloat("bot_skill_min_pause");
	if (getDvar("bot_skill_max_pause") != "") settings[MAX_PAUSE] = getDvarFloat("bot_skill_max_pause");
	if (getDvar("bot_skill_aim_offset_amount") != "") settings[SKILL_AIM_OFFSET_AMOUNT] = getDvarFloat("bot_skill_aim_offset_amount");
	if (getDvar("bot_skill_aim_offset_time") != "") settings[SKILL_AIM_OFFSET_TIME] = getDvarFloat("bot_skill_aim_offset_time");
	if (getDvar("bot_skill_damage_scale") != "") settings[SURVIVOR_DAMAGE_SCALE] = getDvarFloat("bot_skill_damage_scale");
	if (getDvar("bot_behavior_strafe") != "") settings[BEHAVIOR_STRAFE] = getDvarInt("bot_behavior_strafe");
	if (getDvar("bot_behavior_nade") != "") settings[BEHAVIOR_NADE] = getDvarInt("bot_behavior_nade");
	if (getDvar("bot_behavior_sprint") != "") settings[BEHAVIOR_SPRINT] = getDvarInt("bot_behavior_sprint");
	if (getDvar("bot_behavior_jump") != "") settings[BEHAVIOR_JUMP] = getDvarInt("bot_behavior_jump");
	if (getDvar("bot_respawn_delay_min") != "") settings[BOT_RESPAWN_DELAY_MIN] = getDvarFloat("bot_respawn_delay_min");
	if (getDvar("bot_respawn_delay_max") != "") settings[BOT_RESPAWN_DELAY_MAX] = getDvarFloat("bot_respawn_delay_max");

	if (isDefined(self.pers) && isDefined(self.pers["gamemodeLoadout"]) && isDefined(self.pers["gamemodeLoadout"]["loadoutPrimary"]))
	{
		weaponClass = lethalbeats\weapon::weapon_get_class(self.pers["gamemodeLoadout"]["loadoutPrimary"]);
		if (weaponClass == "sniper")
		{
			if (isDefined(settings[FIRE_TIME])) settings[SKILL_SEMI_TIME] = max(1.0, settings[FIRE_TIME] * 8);
		}
	}

	return settings;
}

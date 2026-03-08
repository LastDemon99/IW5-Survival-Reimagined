#define DIFFICULTY_EASY 1
#define DIFFICULTY_NORMAL 2
#define DIFFICULTY_HARD 3

#define WAVES_TABLE_EASY "mp/survival_wave_easy.csv"
#define WAVES_TABLE_NORMAL "mp/survival_wave_normal.csv"
#define WAVES_TABLE_HARD "mp/survival_wave_hard.csv"

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

difficulty_get_survivor_damage_scale()
{
	if (difficulty_is_easy()) return 0.8;
	return 1.0;
}

difficulty_get_bot_health_multiplier()
{
	if (difficulty_is_hard()) return 1.5;
	return 1.0;
}

difficulty_get_bot_speed_multiplier()
{
	if (difficulty_is_easy()) return 0.85;
	if (difficulty_is_hard()) return 1.3;
	return 1.0;
}

difficulty_get_bot_respawn_delay_range()
{
	if (difficulty_is_hard()) return [0, 0];
	if (difficulty_is_normal()) return [1, 3];
	return [3, 6];
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

difficulty_get_connected_survivor_multiplier()
{
	connected = lethalbeats\player::players_get_list("allies").size;
	connected = int(max(1, min(4, connected)));
	return 0.45 + (0.55 * (connected / 4.0));
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

difficulty_scale_progress(init_value, end_value, scale_rate, wave)
{
	progress = min(1.0, max(0.0, (wave - 1) * scale_rate));

	if (difficulty_is_easy())
		ease = progress * progress * progress;
	else if (difficulty_is_normal())
		ease = progress * progress * (3 - (2 * progress));
	else
		ease = 1 - ((1 - progress) * (1 - progress));

	current_value = init_value + (end_value - init_value) * ease;
	if (init_value > end_value) return max(end_value, current_value);
	return min(end_value, current_value);
}

difficulty_get_smg_range_scale(wave_progress)
{
	if (difficulty_is_hard()) return 0.4;
	return 0.28 + (0.12 * wave_progress);
}

difficulty_get_tactical_action_settings(baseJumpChance, isHumanTarget, botSettings)
{
	if (!isDefined(botSettings)) botSettings = difficulty_get_bot_settings();

	settings = [];
	settings["jumpChance"] = baseJumpChance;
	settings["dropshotDuration"] = max(1.25, (botSettings["windUpTime"] * 0.75) + (botSettings["fireTime"] * 8));
	settings["jumpCooldown"] = int((botSettings["windUpTime"] + botSettings["minPause"]) * 1000);

	switch(difficulty_get_level())
	{
		case DIFFICULTY_EASY:
			settings["jumpChance"] = int(settings["jumpChance"] * 0.85);
			break;
		case DIFFICULTY_HARD:
			settings["jumpChance"] = int(settings["jumpChance"] * 1.25);
			settings["dropshotDuration"] *= 0.85;
			break;
	}

	if (isDefined(isHumanTarget) && isHumanTarget)
	{
		settings["jumpChance"] = int(settings["jumpChance"] * 1.35);
		settings["jumpCooldown"] = int(settings["jumpCooldown"] * 0.7);
		settings["dropshotDuration"] *= 0.9;
	}

	settings["jumpChance"] = int(min(100, max(0, settings["jumpChance"])));
	settings["jumpCooldown"] = int(max(250, settings["jumpCooldown"]));
	settings["dropshotDuration"] = max(0.75, settings["dropshotDuration"]);
	return settings;
}

difficulty_get_vehicle_burst_settings()
{
	easy = _difficulty_get_vehicle_profile_easy();
	normal = _difficulty_get_vehicle_profile_normal();
	hard = _difficulty_get_vehicle_profile_hard();

	tier = difficulty_get_level();
	settings = [];
	if (tier == DIFFICULTY_HARD)
	{
		settings["fireTime"] = _difficulty_vary_float(hard["fireTime"], normal["fireTime"], tier);
		settings["minShots"] = _difficulty_vary_int(hard["minShots"], normal["minShots"], tier);
		settings["maxShots"] = _difficulty_vary_int(hard["maxShots"], normal["maxShots"], tier);
		settings["minPause"] = _difficulty_vary_float(hard["minPause"], normal["minPause"], tier);
		settings["maxPause"] = _difficulty_vary_float(hard["maxPause"], normal["maxPause"], tier);
		settings["windUpTime"] = _difficulty_vary_float(hard["windUpTime"], normal["windUpTime"], tier);
	}
	else if (tier == DIFFICULTY_NORMAL)
	{
		settings["fireTime"] = _difficulty_vary_float(normal["fireTime"], easy["fireTime"], tier);
		settings["minShots"] = _difficulty_vary_int(normal["minShots"], easy["minShots"], tier);
		settings["maxShots"] = _difficulty_vary_int(normal["maxShots"], easy["maxShots"], tier);
		settings["minPause"] = _difficulty_vary_float(normal["minPause"], easy["minPause"], tier);
		settings["maxPause"] = _difficulty_vary_float(normal["maxPause"], easy["maxPause"], tier);
		settings["windUpTime"] = _difficulty_vary_float(normal["windUpTime"], easy["windUpTime"], tier);
	}
	else
	{
		settings["fireTime"] = _difficulty_vary_float(easy["fireTime"], normal["fireTime"], tier);
		settings["minShots"] = _difficulty_vary_int(easy["minShots"], normal["minShots"], tier);
		settings["maxShots"] = _difficulty_vary_int(easy["maxShots"], normal["maxShots"], tier);
		settings["minPause"] = _difficulty_vary_float(easy["minPause"], normal["minPause"], tier);
		settings["maxPause"] = _difficulty_vary_float(easy["maxPause"], normal["maxPause"], tier);
		settings["windUpTime"] = _difficulty_vary_float(easy["windUpTime"], normal["windUpTime"], tier);
	}

	settings["maxShots"] = int(max(settings["minShots"] + 5, settings["maxShots"]));
	settings["maxPause"] = max(settings["minPause"], settings["maxPause"]);
	return settings;
}

difficulty_get_bot_settings()
{
	easy = _difficulty_get_bot_profile_easy();
	normal = _difficulty_get_bot_profile_normal();
	hard = _difficulty_get_bot_profile_hard();
	tier = difficulty_get_level();
	settings = [];

	if (tier == DIFFICULTY_HARD)
	{
		settings["scale_rate"] = _difficulty_vary_float(hard["scale_rate"], normal["scale_rate"], tier);
		settings["aim_time_init"] = _difficulty_vary_float(hard["aim_time_init"], normal["aim_time_init"], tier);
		settings["aim_time_end"] = _difficulty_vary_float(hard["aim_time_end"], normal["aim_time_end"], tier);
		settings["reaction_time_init"] = _difficulty_vary_int(hard["reaction_time_init"], normal["reaction_time_init"], tier);
		settings["reaction_time_end"] = _difficulty_vary_int(hard["reaction_time_end"], normal["reaction_time_end"], tier);
		settings["remember_time_init"] = _difficulty_vary_int(hard["remember_time_init"], normal["remember_time_init"], tier);
		settings["remember_time_end"] = _difficulty_vary_int(hard["remember_time_end"], normal["remember_time_end"], tier);
		settings["no_trace_ads_init"] = _difficulty_vary_int(hard["no_trace_ads_init"], normal["no_trace_ads_init"], tier);
		settings["no_trace_ads_end"] = _difficulty_vary_int(hard["no_trace_ads_end"], normal["no_trace_ads_end"], tier);
		settings["fov_init"] = _difficulty_vary_float(hard["fov_init"], normal["fov_init"], tier);
		settings["fov_end"] = _difficulty_vary_float(hard["fov_end"], normal["fov_end"], tier);
		settings["fov_max_wave"] = _difficulty_vary_int(hard["fov_max_wave"], normal["fov_max_wave"], tier);
		settings["dist_start_init"] = _difficulty_vary_int(hard["dist_start_init"], normal["dist_start_init"], tier);
		settings["dist_start_end"] = _difficulty_vary_int(hard["dist_start_end"], normal["dist_start_end"], tier);
		settings["dist_max_init"] = _difficulty_vary_int(hard["dist_max_init"], normal["dist_max_init"], tier);
		settings["dist_max_end"] = _difficulty_vary_int(hard["dist_max_end"], normal["dist_max_end"], tier);
		settings["semi_time_init"] = _difficulty_vary_float(hard["semi_time_init"], normal["semi_time_init"], tier);
		settings["semi_time_end"] = _difficulty_vary_float(hard["semi_time_end"], normal["semi_time_end"], tier);
		settings["shoot_after_init"] = _difficulty_vary_float(hard["shoot_after_init"], normal["shoot_after_init"], tier);
		settings["shoot_after_end"] = _difficulty_vary_float(hard["shoot_after_end"], normal["shoot_after_end"], tier);
		settings["aim_offset_time_init"] = _difficulty_vary_float(hard["aim_offset_time_init"], normal["aim_offset_time_init"], tier);
		settings["aim_offset_time_end"] = _difficulty_vary_float(hard["aim_offset_time_end"], normal["aim_offset_time_end"], tier);
		settings["aim_offset_amount_init"] = _difficulty_vary_float(hard["aim_offset_amount_init"], normal["aim_offset_amount_init"], tier);
		settings["aim_offset_amount_end"] = _difficulty_vary_float(hard["aim_offset_amount_end"], normal["aim_offset_amount_end"], tier);
		settings["bone_update_init"] = _difficulty_vary_float(hard["bone_update_init"], normal["bone_update_init"], tier);
		settings["bone_update_end"] = _difficulty_vary_float(hard["bone_update_end"], normal["bone_update_end"], tier);
		settings["fireTime"] = _difficulty_vary_float(hard["fireTime"], normal["fireTime"], tier);
		settings["minShots"] = _difficulty_vary_int(hard["minShots"], normal["minShots"], tier);
		settings["maxShots"] = _difficulty_vary_int(hard["maxShots"], normal["maxShots"], tier);
		settings["minPause"] = _difficulty_vary_float(hard["minPause"], normal["minPause"], tier);
		settings["maxPause"] = _difficulty_vary_float(hard["maxPause"], normal["maxPause"], tier);
		settings["windUpTime"] = _difficulty_vary_float(hard["windUpTime"], normal["windUpTime"], tier);
	}
	else if (tier == DIFFICULTY_NORMAL)
	{
		settings["scale_rate"] = _difficulty_vary_float(normal["scale_rate"], easy["scale_rate"], tier);
		settings["aim_time_init"] = _difficulty_vary_float(normal["aim_time_init"], easy["aim_time_init"], tier);
		settings["aim_time_end"] = _difficulty_vary_float(normal["aim_time_end"], easy["aim_time_end"], tier);
		settings["reaction_time_init"] = _difficulty_vary_int(normal["reaction_time_init"], easy["reaction_time_init"], tier);
		settings["reaction_time_end"] = _difficulty_vary_int(normal["reaction_time_end"], easy["reaction_time_end"], tier);
		settings["remember_time_init"] = _difficulty_vary_int(normal["remember_time_init"], easy["remember_time_init"], tier);
		settings["remember_time_end"] = _difficulty_vary_int(normal["remember_time_end"], easy["remember_time_end"], tier);
		settings["no_trace_ads_init"] = _difficulty_vary_int(normal["no_trace_ads_init"], easy["no_trace_ads_init"], tier);
		settings["no_trace_ads_end"] = _difficulty_vary_int(normal["no_trace_ads_end"], easy["no_trace_ads_end"], tier);
		settings["fov_init"] = _difficulty_vary_float(normal["fov_init"], easy["fov_init"], tier);
		settings["fov_end"] = _difficulty_vary_float(normal["fov_end"], easy["fov_end"], tier);
		settings["fov_max_wave"] = _difficulty_vary_int(normal["fov_max_wave"], easy["fov_max_wave"], tier);
		settings["dist_start_init"] = _difficulty_vary_int(normal["dist_start_init"], easy["dist_start_init"], tier);
		settings["dist_start_end"] = _difficulty_vary_int(normal["dist_start_end"], easy["dist_start_end"], tier);
		settings["dist_max_init"] = _difficulty_vary_int(normal["dist_max_init"], easy["dist_max_init"], tier);
		settings["dist_max_end"] = _difficulty_vary_int(normal["dist_max_end"], easy["dist_max_end"], tier);
		settings["semi_time_init"] = _difficulty_vary_float(normal["semi_time_init"], easy["semi_time_init"], tier);
		settings["semi_time_end"] = _difficulty_vary_float(normal["semi_time_end"], easy["semi_time_end"], tier);
		settings["shoot_after_init"] = _difficulty_vary_float(normal["shoot_after_init"], easy["shoot_after_init"], tier);
		settings["shoot_after_end"] = _difficulty_vary_float(normal["shoot_after_end"], easy["shoot_after_end"], tier);
		settings["aim_offset_time_init"] = _difficulty_vary_float(normal["aim_offset_time_init"], easy["aim_offset_time_init"], tier);
		settings["aim_offset_time_end"] = _difficulty_vary_float(normal["aim_offset_time_end"], easy["aim_offset_time_end"], tier);
		settings["aim_offset_amount_init"] = _difficulty_vary_float(normal["aim_offset_amount_init"], easy["aim_offset_amount_init"], tier);
		settings["aim_offset_amount_end"] = _difficulty_vary_float(normal["aim_offset_amount_end"], easy["aim_offset_amount_end"], tier);
		settings["bone_update_init"] = _difficulty_vary_float(normal["bone_update_init"], easy["bone_update_init"], tier);
		settings["bone_update_end"] = _difficulty_vary_float(normal["bone_update_end"], easy["bone_update_end"], tier);
		settings["fireTime"] = _difficulty_vary_float(normal["fireTime"], easy["fireTime"], tier);
		settings["minShots"] = _difficulty_vary_int(normal["minShots"], easy["minShots"], tier);
		settings["maxShots"] = _difficulty_vary_int(normal["maxShots"], easy["maxShots"], tier);
		settings["minPause"] = _difficulty_vary_float(normal["minPause"], easy["minPause"], tier);
		settings["maxPause"] = _difficulty_vary_float(normal["maxPause"], easy["maxPause"], tier);
		settings["windUpTime"] = _difficulty_vary_float(normal["windUpTime"], easy["windUpTime"], tier);
	}
	else
	{
		settings["scale_rate"] = _difficulty_vary_float(easy["scale_rate"], normal["scale_rate"], tier);
		settings["aim_time_init"] = _difficulty_vary_float(easy["aim_time_init"], normal["aim_time_init"], tier);
		settings["aim_time_end"] = _difficulty_vary_float(easy["aim_time_end"], normal["aim_time_end"], tier);
		settings["reaction_time_init"] = _difficulty_vary_int(easy["reaction_time_init"], normal["reaction_time_init"], tier);
		settings["reaction_time_end"] = _difficulty_vary_int(easy["reaction_time_end"], normal["reaction_time_end"], tier);
		settings["remember_time_init"] = _difficulty_vary_int(easy["remember_time_init"], normal["remember_time_init"], tier);
		settings["remember_time_end"] = _difficulty_vary_int(easy["remember_time_end"], normal["remember_time_end"], tier);
		settings["no_trace_ads_init"] = _difficulty_vary_int(easy["no_trace_ads_init"], normal["no_trace_ads_init"], tier);
		settings["no_trace_ads_end"] = _difficulty_vary_int(easy["no_trace_ads_end"], normal["no_trace_ads_end"], tier);
		settings["fov_init"] = _difficulty_vary_float(easy["fov_init"], normal["fov_init"], tier);
		settings["fov_end"] = _difficulty_vary_float(easy["fov_end"], normal["fov_end"], tier);
		settings["fov_max_wave"] = _difficulty_vary_int(easy["fov_max_wave"], normal["fov_max_wave"], tier);
		settings["dist_start_init"] = _difficulty_vary_int(easy["dist_start_init"], normal["dist_start_init"], tier);
		settings["dist_start_end"] = _difficulty_vary_int(easy["dist_start_end"], normal["dist_start_end"], tier);
		settings["dist_max_init"] = _difficulty_vary_int(easy["dist_max_init"], normal["dist_max_init"], tier);
		settings["dist_max_end"] = _difficulty_vary_int(easy["dist_max_end"], normal["dist_max_end"], tier);
		settings["semi_time_init"] = _difficulty_vary_float(easy["semi_time_init"], normal["semi_time_init"], tier);
		settings["semi_time_end"] = _difficulty_vary_float(easy["semi_time_end"], normal["semi_time_end"], tier);
		settings["shoot_after_init"] = _difficulty_vary_float(easy["shoot_after_init"], normal["shoot_after_init"], tier);
		settings["shoot_after_end"] = _difficulty_vary_float(easy["shoot_after_end"], normal["shoot_after_end"], tier);
		settings["aim_offset_time_init"] = _difficulty_vary_float(easy["aim_offset_time_init"], normal["aim_offset_time_init"], tier);
		settings["aim_offset_time_end"] = _difficulty_vary_float(easy["aim_offset_time_end"], normal["aim_offset_time_end"], tier);
		settings["aim_offset_amount_init"] = _difficulty_vary_float(easy["aim_offset_amount_init"], normal["aim_offset_amount_init"], tier);
		settings["aim_offset_amount_end"] = _difficulty_vary_float(easy["aim_offset_amount_end"], normal["aim_offset_amount_end"], tier);
		settings["bone_update_init"] = _difficulty_vary_float(easy["bone_update_init"], normal["bone_update_init"], tier);
		settings["bone_update_end"] = _difficulty_vary_float(easy["bone_update_end"], normal["bone_update_end"], tier);
		settings["fireTime"] = _difficulty_vary_float(easy["fireTime"], normal["fireTime"], tier);
		settings["minShots"] = _difficulty_vary_int(easy["minShots"], normal["minShots"], tier);
		settings["maxShots"] = _difficulty_vary_int(easy["maxShots"], normal["maxShots"], tier);
		settings["minPause"] = _difficulty_vary_float(easy["minPause"], normal["minPause"], tier);
		settings["maxPause"] = _difficulty_vary_float(easy["maxPause"], normal["maxPause"], tier);
		settings["windUpTime"] = _difficulty_vary_float(easy["windUpTime"], normal["windUpTime"], tier);
	}

	settings["fov_init"] = min(0.95, max(0.2, settings["fov_init"]));
	settings["fov_end"] = min(0.95, max(0.2, settings["fov_end"]));
	settings["maxShots"] = int(max(settings["minShots"] + 5, settings["maxShots"]));
	settings["maxPause"] = max(settings["minPause"], settings["maxPause"]);
	settings = _difficulty_apply_connected_survivor_multiplier(settings);
	settings = _difficulty_enforce_bot_burst_guardrails(settings);
	return settings;
}

_difficulty_apply_connected_survivor_multiplier(settings)
{
	mult = difficulty_get_connected_survivor_multiplier();
	if (mult >= 1.0) return settings;

	inverse = 1.0 / mult;
	settings["scale_rate"] *= mult;

	settings["aim_time_init"] *= inverse;
	settings["aim_time_end"] *= inverse;
	settings["reaction_time_init"] *= inverse;
	settings["reaction_time_end"] *= inverse;
	settings["no_trace_ads_init"] *= inverse;
	settings["no_trace_ads_end"] *= inverse;
	settings["semi_time_init"] *= inverse;
	settings["semi_time_end"] *= inverse;
	settings["shoot_after_init"] *= inverse;
	settings["shoot_after_end"] *= inverse;
	settings["aim_offset_time_init"] *= inverse;
	settings["aim_offset_time_end"] *= inverse;
	settings["aim_offset_amount_init"] *= inverse;
	settings["aim_offset_amount_end"] *= inverse;
	settings["bone_update_init"] *= inverse;
	settings["bone_update_end"] *= inverse;

	settings["remember_time_init"] *= mult;
	settings["remember_time_end"] *= mult;
	settings["dist_start_init"] *= mult;
	settings["dist_start_end"] *= mult;
	settings["dist_max_init"] *= mult;
	settings["dist_max_end"] *= mult;
	settings["fov_init"] = min(0.95, settings["fov_init"] * inverse);
	settings["fov_end"] = min(0.95, settings["fov_end"] * inverse);

	settings["fireTime"] *= inverse;
	settings["minShots"] = int(max(8, settings["minShots"] * mult));
	settings["maxShots"] = int(max(settings["minShots"] + 5, settings["maxShots"] * mult));
	settings["minPause"] *= inverse;
	settings["maxPause"] *= inverse;
	settings["windUpTime"] *= inverse;
	return settings;
}

_difficulty_enforce_bot_burst_guardrails(settings)
{
	tier = difficulty_get_level();

	minFireTime = 0.1;
	minWindUp = 0.6;
	minShotsFloor = 18;

	if (tier == DIFFICULTY_EASY)
	{
		minFireTime = 0.17;
		minWindUp = 1.35;
		minShotsFloor = 12;
	}
	else if (tier == DIFFICULTY_NORMAL)
	{
		minFireTime = 0.13;
		minWindUp = 0.95;
		minShotsFloor = 16;
	}

	settings["fireTime"] = max(minFireTime, settings["fireTime"]);
	settings["windUpTime"] = max(minWindUp, settings["windUpTime"]);
	settings["minShots"] = int(max(minShotsFloor, settings["minShots"]));
	settings["maxShots"] = int(max(settings["minShots"] + 5, settings["maxShots"]));
	settings["maxPause"] = max(settings["minPause"], settings["maxPause"]);
	return settings;
}

_difficulty_vary_float(currentValue, adjacentValue, tier)
{
	if (tier == DIFFICULTY_HARD) return _difficulty_lerp(currentValue, adjacentValue, randomFloatRange(0.0, 0.35));
	if (tier == DIFFICULTY_NORMAL) return _difficulty_lerp(currentValue, adjacentValue, randomFloatRange(0.0, 0.6));
	return currentValue + ((currentValue - adjacentValue) * randomFloatRange(0.08, 0.22));
}

_difficulty_vary_int(currentValue, adjacentValue, tier)
{
	return int(_difficulty_vary_float(currentValue, adjacentValue, tier));
}

_difficulty_lerp(startValue, endValue, amount)
{
	return startValue + ((endValue - startValue) * amount);
}

_difficulty_get_vehicle_profile_easy()
{
	settings = [];
	settings["fireTime"] = 0.15;
	settings["minShots"] = 20;
	settings["maxShots"] = 40;
	settings["minPause"] = 2.0;
	settings["maxPause"] = 4.0;
	settings["windUpTime"] = 2.0;
	return settings;
}

_difficulty_get_vehicle_profile_normal()
{
	settings = [];
	settings["fireTime"] = 0.12;
	settings["minShots"] = 30;
	settings["maxShots"] = 60;
	settings["minPause"] = 1.5;
	settings["maxPause"] = 3.0;
	settings["windUpTime"] = 1.75;
	return settings;
}

_difficulty_get_vehicle_profile_hard()
{
	settings = [];
	settings["fireTime"] = 0.1;
	settings["minShots"] = 40;
	settings["maxShots"] = 80;
	settings["minPause"] = 1.0;
	settings["maxPause"] = 2.0;
	settings["windUpTime"] = 0.8;
	return settings;
}

_difficulty_get_bot_profile_easy()
{
	settings = [];
	settings["scale_rate"] = 0.02;
	settings["aim_time_init"] = 0.95;
	settings["aim_time_end"] = 0.6;
	settings["reaction_time_init"] = 2200;
	settings["reaction_time_end"] = 850;
	settings["remember_time_init"] = 500;
	settings["remember_time_end"] = 2200;
	settings["no_trace_ads_init"] = 700;
	settings["no_trace_ads_end"] = 1500;
	settings["fov_init"] = 0.82;
	settings["fov_end"] = 0.68;
	settings["fov_max_wave"] = 35;
	settings["dist_start_init"] = 750;
	settings["dist_start_end"] = 2400;
	settings["dist_max_init"] = 1800;
	settings["dist_max_end"] = 3800;
	settings["semi_time_init"] = 1.15;
	settings["semi_time_end"] = 0.75;
	settings["shoot_after_init"] = 1.45;
	settings["shoot_after_end"] = 1.0;
	settings["aim_offset_time_init"] = 2.0;
	settings["aim_offset_time_end"] = 1.1;
	settings["aim_offset_amount_init"] = 5.25;
	settings["aim_offset_amount_end"] = 3.0;
	settings["bone_update_init"] = 2.6;
	settings["bone_update_end"] = 1.25;
	settings["fireTime"] = 0.15;
	settings["minShots"] = 20;
	settings["maxShots"] = 40;
	settings["minPause"] = 2.0;
	settings["maxPause"] = 4.0;
	settings["windUpTime"] = 3.0;
	return settings;
}

_difficulty_get_bot_profile_normal()
{
	settings = [];
	settings["scale_rate"] = 0.025;
	settings["aim_time_init"] = 0.75;
	settings["aim_time_end"] = 0.45;
	settings["reaction_time_init"] = 1800;
	settings["reaction_time_end"] = 600;
	settings["remember_time_init"] = 750;
	settings["remember_time_end"] = 3000;
	settings["no_trace_ads_init"] = 800;
	settings["no_trace_ads_end"] = 1800;
	settings["fov_init"] = 0.75;
	settings["fov_end"] = 0.6;
	settings["fov_max_wave"] = 30;
	settings["dist_start_init"] = 900;
	settings["dist_start_end"] = 3000;
	settings["dist_max_init"] = 2200;
	settings["dist_max_end"] = 4500;
	settings["semi_time_init"] = 1.0;
	settings["semi_time_end"] = 0.6;
	settings["shoot_after_init"] = 1.25;
	settings["shoot_after_end"] = 0.8;
	settings["aim_offset_time_init"] = 1.75;
	settings["aim_offset_time_end"] = 0.8;
	settings["aim_offset_amount_init"] = 4.5;
	settings["aim_offset_amount_end"] = 2.25;
	settings["bone_update_init"] = 2.25;
	settings["bone_update_end"] = 1.0;
	settings["fireTime"] = 0.12;
	settings["minShots"] = 30;
	settings["maxShots"] = 60;
	settings["minPause"] = 1.5;
	settings["maxPause"] = 3.0;
	settings["windUpTime"] = 2.0;
	return settings;
}

_difficulty_get_bot_profile_hard()
{
	settings = [];
	settings["scale_rate"] = 0.05;
	settings["aim_time_init"] = 0.4;
	settings["aim_time_end"] = 0.2;
	settings["reaction_time_init"] = 750;
	settings["reaction_time_end"] = 150;
	settings["remember_time_init"] = 2000;
	settings["remember_time_end"] = 5000;
	settings["no_trace_ads_init"] = 1000;
	settings["no_trace_ads_end"] = 2500;
	settings["fov_init"] = 0.6;
	settings["fov_end"] = 0.45;
	settings["fov_max_wave"] = 20;
	settings["dist_start_init"] = 2250;
	settings["dist_start_end"] = 7500;
	settings["dist_max_init"] = 4000;
	settings["dist_max_end"] = 10000;
	settings["semi_time_init"] = 0.65;
	settings["semi_time_end"] = 0.25;
	settings["shoot_after_init"] = 0.65;
	settings["shoot_after_end"] = 0.25;
	settings["aim_offset_time_init"] = 0.75;
	settings["aim_offset_time_end"] = 0.25;
	settings["aim_offset_amount_init"] = 2.5;
	settings["aim_offset_amount_end"] = 1.0;
	settings["bone_update_init"] = 1.0;
	settings["bone_update_end"] = 0.25;
	settings["fireTime"] = 0.1;
	settings["minShots"] = 40;
	settings["maxShots"] = 80;
	settings["minPause"] = 1.0;
	settings["maxPause"] = 2.0;
	settings["windUpTime"] = 0.8;
	return settings;
}

#include common_scripts\utility;
#include maps\mp\_utility;
#include lethalbeats\survival\utility;

// VOTE ITEM INDEX
#define ITEM_NAME 0
#define ITEM_TITLE 1

// VOTE WINNER INDEX
#define WINNER_INDEX 0
#define WINNER_NAME 1
#define WINNER_TITLE 2

// DVARS
#define DVAR_VOTE_PHASE "ui_vote_phase"
#define DVAR_VOTE_TIMER "ui_vote_timer"
#define DVAR_VOTE_PROGRESS "ui_vote_progress"
#define DVAR_VOTE_MAP_PREFIX "ui_vote_map_"
#define DVAR_VOTE_DIFF_PREFIX "ui_vote_diff_"
#define DVAR_PLAYER_VOTE_MAP "ui_player_vote_map"
#define DVAR_PLAYER_VOTE_DIFF "ui_player_vote_diff"
#define DVAR_VOTE_WINNING_MAP "ui_vote_winning_map"
#define DVAR_VOTE_WINNING_MAP_IDX "ui_vote_winning_map_idx"
#define DVAR_VOTE_WINNING_MAP_TITLE "ui_vote_winning_map_title"
#define DVAR_VOTE_WINNING_DIFF "ui_vote_winning_diff"
#define DVAR_VOTE_WINNING_DIFF_IDX "ui_vote_winning_diff_idx"
#define DVAR_VOTE_WINNING_DIFF_TITLE "ui_vote_winning_diff_title"
#define DVAR_CURRENT_DSR "current_dsr"
#define DVAR_VOTE_MAP_TIME "survival_vote_map_time"
#define DVAR_VOTE_DIFF_TIME "survival_vote_difficulty_time"

// MENUS
#define MENU_SURVIVAL_MAP_VOTE "survival_map_vote"

set_cached_client_dvar(dvar_name, val)
{
	if (!isDefined(self.vote_dvar_cache)) self.vote_dvar_cache = [];
	val_str = "" + val;
	if (isDefined(self.vote_dvar_cache[dvar_name]) && self.vote_dvar_cache[dvar_name] == val_str)
		return;
	self.vote_dvar_cache[dvar_name] = val_str;
	self setClientDvar(dvar_name, val);
}

vote_broadcast_dvar(dvar_name, val)
{
	setDvar(dvar_name, val);
	foreach (player in survivors())
	{
		if (isDefined(player))
			player set_cached_client_dvar(dvar_name, val);
	}
}

vote_sync_player(player)
{
	if (!isDefined(player) || !isDefined(level.vote_in_progress) || !level.vote_in_progress)
		return;

	player set_cached_client_dvar(DVAR_VOTE_MAP_TIME, isDefined(level.vote_map_time) ? level.vote_map_time : getDvarInt(DVAR_VOTE_MAP_TIME));
	player set_cached_client_dvar(DVAR_VOTE_DIFF_TIME, isDefined(level.vote_diff_time) ? level.vote_diff_time : getDvarInt(DVAR_VOTE_DIFF_TIME));
	player set_cached_client_dvar(DVAR_VOTE_PHASE, level.vote_phase);
	player set_cached_client_dvar(DVAR_VOTE_TIMER, level.vote_timer);
	player set_cached_client_dvar(DVAR_VOTE_PROGRESS, level.vote_progress);

	for (i = 0; i < level.vote_maps.size; i++)
		player set_cached_client_dvar(DVAR_VOTE_MAP_PREFIX + i, level.vote_map_counts[i]);

	for (i = 0; i < level.vote_diffs.size; i++)
		player set_cached_client_dvar(DVAR_VOTE_DIFF_PREFIX + i, level.vote_diff_counts[i]);

	player set_cached_client_dvar(DVAR_PLAYER_VOTE_MAP, isDefined(player.vote_map_idx) ? player.vote_map_idx : -1);
	player set_cached_client_dvar(DVAR_PLAYER_VOTE_DIFF, isDefined(player.vote_diff_idx) ? player.vote_diff_idx : -1);

	player set_cached_client_dvar(DVAR_VOTE_WINNING_MAP, isDefined(level.winning_map) ? level.winning_map : "");
	player set_cached_client_dvar(DVAR_VOTE_WINNING_MAP_IDX, isDefined(level.winning_map_idx) ? level.winning_map_idx : -1);
	player set_cached_client_dvar(DVAR_VOTE_WINNING_MAP_TITLE, isDefined(level.winning_map_title) ? level.winning_map_title : "");

	player set_cached_client_dvar(DVAR_VOTE_WINNING_DIFF, isDefined(level.winning_diff) ? level.winning_diff : "");
	player set_cached_client_dvar(DVAR_VOTE_WINNING_DIFF_IDX, isDefined(level.winning_diff_idx) ? level.winning_diff_idx : -1);
	player set_cached_client_dvar(DVAR_VOTE_WINNING_DIFF_TITLE, isDefined(level.winning_diff_title) ? level.winning_diff_title : "");
}

init_vote_data()
{
	map_time = getDvarInt(DVAR_VOTE_MAP_TIME);
	if (map_time <= 0)
	{
		map_time = 25;
		setDvar(DVAR_VOTE_MAP_TIME, map_time);
	}

	diff_time = getDvarInt(DVAR_VOTE_DIFF_TIME);
	if (diff_time <= 0)
	{
		diff_time = 10;
		setDvar(DVAR_VOTE_DIFF_TIME, diff_time);
	}

	level.vote_map_time = map_time;
	level.vote_diff_time = diff_time;

	level.vote_maps = [];
	level.vote_maps[0] = create_vote_item("mp_seatown", "SEATOWN");
	level.vote_maps[1] = create_vote_item("mp_dome", "DOME");
	level.vote_maps[2] = create_vote_item("mp_plaza2", "ARKADEN");
	level.vote_maps[3] = create_vote_item("mp_mogadishu", "BAKAARA");
	level.vote_maps[4] = create_vote_item("mp_paris", "RESISTANCE");
	level.vote_maps[5] = create_vote_item("mp_exchange", "DOWNTURN");
	level.vote_maps[6] = create_vote_item("mp_bootleg", "BOOTLEG");
	level.vote_maps[7] = create_vote_item("mp_carbon", "CARBON");
	level.vote_maps[8] = create_vote_item("mp_hardhat", "HARDHAT");
	level.vote_maps[9] = create_vote_item("mp_alpha", "LOCKDOWN");
	level.vote_maps[10] = create_vote_item("mp_village", "VILLAGE");
	level.vote_maps[11] = create_vote_item("mp_lambeth", "FALLEN");
	level.vote_maps[12] = create_vote_item("mp_radar", "OUTPOST");
	level.vote_maps[13] = create_vote_item("mp_interchange", "INTERCHANGE");
	level.vote_maps[14] = create_vote_item("mp_underground", "UNDERGROUND");
	level.vote_maps[15] = create_vote_item("mp_bravo", "MISSION");
	level.vote_maps[16] = create_vote_item("mp_italy", "PIAZZA");
	level.vote_maps[17] = create_vote_item("mp_park", "LIBERATION");
	level.vote_maps[18] = create_vote_item("mp_overwatch", "OVERWATCH");
	level.vote_maps[19] = create_vote_item("mp_morningwood", "BLACK BOX");
	level.vote_maps[20] = create_vote_item("mp_meteora", "SANCTUARY");
	level.vote_maps[21] = create_vote_item("mp_cement", "FOUNDATION");
	level.vote_maps[22] = create_vote_item("mp_qadeem", "OASIS");
	level.vote_maps[23] = create_vote_item("mp_restrepo_ss", "LOOKOUT");
	level.vote_maps[24] = create_vote_item("mp_hillside_ss", "GETAWAY");
	level.vote_maps[25] = create_vote_item("mp_courtyard_ss", "EROSION");
	level.vote_maps[26] = create_vote_item("mp_aground_ss", "AGROUND");
	level.vote_maps[27] = create_vote_item("mp_terminal_cls", "TERMINAL");
	level.vote_maps[28] = create_vote_item("mp_six_ss", "VORTEX");
	level.vote_maps[29] = create_vote_item("mp_burn_ss", "U-TURN");
	level.vote_maps[30] = create_vote_item("mp_crosswalk_ss", "INTERSECTION");
	level.vote_maps[31] = create_vote_item("mp_shipbreaker", "DECOMMISSION");
	level.vote_maps[32] = create_vote_item("mp_roughneck", "OFF SHORE");
	level.vote_maps[33] = create_vote_item("mp_moab", "GULCH");
	level.vote_maps[34] = create_vote_item("mp_boardwalk", "BOARDWALK");
	level.vote_maps[35] = create_vote_item("mp_nola", "PARISH");
	level.vote_maps[36] = create_vote_item("mp_favela", "FAVELA");
	level.vote_maps[37] = create_vote_item("mp_highrise", "HIGHRISE");
	level.vote_maps[38] = create_vote_item("mp_nightshift", "SKIDROW");
	level.vote_maps[39] = create_vote_item("mp_nuked", "NUKETOWN");
	level.vote_maps[40] = create_vote_item("mp_rust", "RUST");

	level.vote_diffs = [];
	level.vote_diffs[0] = create_vote_item("survival_easy", get_localized_string("MENU_RECRUIT_CAPS", "RECRUIT"));
	level.vote_diffs[1] = create_vote_item("survival_normal", get_localized_string("MENU_REGULAR_CAPS", "REGULAR"));
	level.vote_diffs[2] = create_vote_item("survival_hard", get_localized_string("MENU_HARDENED_CAPS", "HARDENED"));
	level.vote_diffs[3] = create_vote_item("survival_insane", get_localized_string("MENU_VETERAN_CAPS", "VETERAN"));

	level.vote_phase = 1;
	level.vote_timer = map_time;
	level.vote_progress = 1.0;
	level.winning_map = "";
	level.winning_map_idx = -1;
	level.winning_map_title = "";
	level.winning_diff = "";
	level.winning_diff_idx = -1;
	level.winning_diff_title = "";

	level.vote_map_counts = [];
	for (i = 0; i < level.vote_maps.size; i++)
	{
		level.vote_map_counts[i] = 0;
		vote_broadcast_dvar(DVAR_VOTE_MAP_PREFIX + i, 0);
	}

	level.vote_diff_counts = [];
	for (i = 0; i < level.vote_diffs.size; i++)
	{
		level.vote_diff_counts[i] = 0;
		vote_broadcast_dvar(DVAR_VOTE_DIFF_PREFIX + i, 0);
	}

	vote_broadcast_dvar(DVAR_VOTE_MAP_TIME, map_time);
	vote_broadcast_dvar(DVAR_VOTE_DIFF_TIME, diff_time);
	vote_broadcast_dvar(DVAR_VOTE_PHASE, 1);
	vote_broadcast_dvar(DVAR_VOTE_TIMER, map_time);
	vote_broadcast_dvar(DVAR_VOTE_PROGRESS, 1.0);
	vote_broadcast_dvar(DVAR_VOTE_WINNING_MAP, "");
	vote_broadcast_dvar(DVAR_VOTE_WINNING_MAP_IDX, -1);
	vote_broadcast_dvar(DVAR_VOTE_WINNING_MAP_TITLE, "");
	vote_broadcast_dvar(DVAR_VOTE_WINNING_DIFF, "");
	vote_broadcast_dvar(DVAR_VOTE_WINNING_DIFF_IDX, -1);
	vote_broadcast_dvar(DVAR_VOTE_WINNING_DIFF_TITLE, "");
}

create_vote_item(name, title)
{
	item = [];
	item[ITEM_NAME] = name;
	item[ITEM_TITLE] = title;
	return item;
}

vote_start()
{
	level endon("game_ended");
	level notify("vote_started");
	level.vote_in_progress = true;

	init_vote_data();

	foreach (player in survivors())
	{
		player.vote_dvar_cache = [];
		player.vote_map_idx = undefined;
		player.vote_diff_idx = undefined;
		vote_sync_player(player);
		player openpopupmenu(MENU_SURVIVAL_MAP_VOTE);
		player thread player_vote_listener();
		player thread player_disconnect_vote_cleanup();
	}

	level.vote_phase = 1;
	vote_broadcast_dvar(DVAR_VOTE_PHASE, 1);
	map_time = isDefined(level.vote_map_time) ? level.vote_map_time : getDvarInt(DVAR_VOTE_MAP_TIME);
	if (map_time <= 0) map_time = 25;
	total_ticks = int(map_time * 10);
	for (t = total_ticks; t >= 0; t--)
	{
		level.vote_timer = int(ceil(t / 10.0));
		level.vote_progress = total_ticks > 0 ? (float(t) / float(total_ticks)) : 0.0;
		vote_broadcast_dvar(DVAR_VOTE_TIMER, level.vote_timer);
		vote_broadcast_dvar(DVAR_VOTE_PROGRESS, level.vote_progress);
		wait 0.1;
	}

	winMap = calculate_winner(level.vote_maps, level.vote_map_counts);
	level.winning_map = winMap[WINNER_NAME];
	level.winning_map_idx = winMap[WINNER_INDEX];
	level.winning_map_title = winMap[WINNER_TITLE];
	vote_broadcast_dvar(DVAR_VOTE_WINNING_MAP, winMap[WINNER_NAME]);
	vote_broadcast_dvar(DVAR_VOTE_WINNING_MAP_IDX, winMap[WINNER_INDEX]);
	vote_broadcast_dvar(DVAR_VOTE_WINNING_MAP_TITLE, winMap[WINNER_TITLE]);

	level.vote_phase = 2;
	diff_time = isDefined(level.vote_diff_time) ? level.vote_diff_time : getDvarInt(DVAR_VOTE_DIFF_TIME);
	if (diff_time <= 0) diff_time = 10;
	level.vote_timer = diff_time;
	level.vote_progress = 1.0;
	vote_broadcast_dvar(DVAR_VOTE_PHASE, 2);
	vote_broadcast_dvar(DVAR_VOTE_TIMER, diff_time);
	vote_broadcast_dvar(DVAR_VOTE_PROGRESS, 1.0);

	foreach (player in survivors())
	{
		player closepopupmenu(MENU_SURVIVAL_MAP_VOTE);
		player openpopupmenu(MENU_SURVIVAL_MAP_VOTE);
	}

	total_ticks = int(diff_time * 10);
	for (t = total_ticks; t >= 0; t--)
	{
		level.vote_timer = int(ceil(t / 10.0));
		level.vote_progress = total_ticks > 0 ? (float(t) / float(total_ticks)) : 0.0;
		vote_broadcast_dvar(DVAR_VOTE_TIMER, level.vote_timer);
		vote_broadcast_dvar(DVAR_VOTE_PROGRESS, level.vote_progress);
		wait 0.1;
	}

	winDiff = calculate_winner(level.vote_diffs, level.vote_diff_counts);
	level.winning_diff = winDiff[WINNER_NAME];
	level.winning_diff_idx = winDiff[WINNER_INDEX];
	level.winning_diff_title = winDiff[WINNER_TITLE];
	vote_broadcast_dvar(DVAR_VOTE_WINNING_DIFF, winDiff[WINNER_NAME]);
	vote_broadcast_dvar(DVAR_VOTE_WINNING_DIFF_IDX, winDiff[WINNER_INDEX]);
	vote_broadcast_dvar(DVAR_VOTE_WINNING_DIFF_TITLE, winDiff[WINNER_TITLE]);

	level.vote_phase = 3;
	vote_broadcast_dvar(DVAR_VOTE_PHASE, 3);
	level notify("vote_ended");
	wait 3;

	setDvar(DVAR_CURRENT_DSR, winDiff[WINNER_NAME]);
	cmdexec("load_dsr " + winDiff[WINNER_NAME]);
	wait 0.5;
	cmdexec("map " + winMap[WINNER_NAME]);
}

calculate_winner(items, counts)
{
	maxVotes = 0;
	for (i = 0; i < items.size; i++)
	{
		if (counts[i] > maxVotes)
			maxVotes = counts[i];
	}

	candidates = [];
	if (maxVotes == 0)
	{
		for (i = 0; i < items.size; i++)
			candidates[candidates.size] = i;
	}
	else
	{
		for (i = 0; i < items.size; i++)
		{
			if (counts[i] == maxVotes)
				candidates[candidates.size] = i;
		}
	}

	winnerIdx = candidates[randomIntRange(0, candidates.size)];
	res = [];
	res[WINNER_INDEX] = winnerIdx;
	res[WINNER_NAME] = items[winnerIdx][ITEM_NAME];
	res[WINNER_TITLE] = items[winnerIdx][ITEM_TITLE];
	return res;
}

player_vote_listener()
{
	level endon("vote_ended");
	self endon("disconnect");

	for (;;)
	{
		self waittill("menuresponse", menu, response);
		if (menu != MENU_SURVIVAL_MAP_VOTE) continue;

		if (issubstr(response, "vote_map_"))
		{
			if (level.vote_phase != 1) continue;
			idx = int(getsubstr(response, 9));
			if (idx < 0 || idx >= level.vote_maps.size) continue;

			if (isDefined(self.vote_map_idx))
			{
				oldIdx = self.vote_map_idx;
				if (oldIdx == idx) continue;
				level.vote_map_counts[oldIdx]--;
				vote_broadcast_dvar(DVAR_VOTE_MAP_PREFIX + oldIdx, level.vote_map_counts[oldIdx]);
			}
			self.vote_map_idx = idx;
			level.vote_map_counts[idx]++;
			vote_broadcast_dvar(DVAR_VOTE_MAP_PREFIX + idx, level.vote_map_counts[idx]);
			self set_cached_client_dvar(DVAR_PLAYER_VOTE_MAP, idx);
		}
		else if (issubstr(response, "vote_diff_"))
		{
			if (level.vote_phase != 2) continue;
			idx = int(getsubstr(response, 10));
			if (idx < 0 || idx >= level.vote_diffs.size) continue;

			if (isDefined(self.vote_diff_idx))
			{
				oldIdx = self.vote_diff_idx;
				if (oldIdx == idx) continue;
				level.vote_diff_counts[oldIdx]--;
				vote_broadcast_dvar(DVAR_VOTE_DIFF_PREFIX + oldIdx, level.vote_diff_counts[oldIdx]);
			}
			self.vote_diff_idx = idx;
			level.vote_diff_counts[idx]++;
			vote_broadcast_dvar(DVAR_VOTE_DIFF_PREFIX + idx, level.vote_diff_counts[idx]);
			self set_cached_client_dvar(DVAR_PLAYER_VOTE_DIFF, idx);
		}
	}
}

player_disconnect_vote_cleanup()
{
	level endon("vote_ended");
	self waittill("disconnect");

	if (isDefined(self.vote_map_idx) && level.vote_phase == 1)
	{
		level.vote_map_counts[self.vote_map_idx]--;
		vote_broadcast_dvar(DVAR_VOTE_MAP_PREFIX + self.vote_map_idx, level.vote_map_counts[self.vote_map_idx]);
	}
	if (isDefined(self.vote_diff_idx) && level.vote_phase == 2)
	{
		level.vote_diff_counts[self.vote_diff_idx]--;
		vote_broadcast_dvar(DVAR_VOTE_DIFF_PREFIX + self.vote_diff_idx, level.vote_diff_counts[self.vote_diff_idx]);
	}
}

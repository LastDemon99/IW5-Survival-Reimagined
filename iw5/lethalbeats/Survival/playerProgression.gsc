#include maps\mp\_utility;
#include common_scripts\utility;
#include lethalbeats\survival\utility;
#include lethalbeats\player;

// PAGE INDICES
#define PAGE_ID 0
#define PAGE_DISPLAY 1
#define PAGE_DESC 2
#define PAGE_ITEMS 3
#define PAGE_MENU 4

// ITEM INDICES
#define ITEM_VALUE 0
#define ITEM_PRICE 1
#define ITEM_LABEL 2
#define ITEM_DESC 3
#define ITEM_IMAGE_RECT 4
#define ITEM_IMAGE_SQUARE 5
#define ITEM_UNLOCK_LEVEL 6

init()
{
    level thread playersTelemetry();
    level thread scoreboardMonitor();
}

survivor_init_match_summary()
{
    self.match_summary = [];
    self.match_summary["kills"] = 0;
	self.match_summary["deaths"] = 0;
	self.match_summary["revives"] = 0;
	self.match_summary["downs"] = 0;
    self.match_summary["money_earned"] = 0;
	self.match_summary["headshots"] = 0;
	self.match_summary["shots"] = 0;
	self.match_summary["hits"] = 0;
	print("TELEMETRY_IDENT;xuid=" + self getguid() + ";name=" + self.name + "\n");
}

survivor_progression_monitor()
{
    self endon("disconnect");
    level endon("game_ended");

    if (!getDvarInt("survival_ladder")) return;

    print("[PROGRESSION]: Tracking started for player: " + self.name);

    self setClientDvar("ui_unlock_name", "");
    self setClientDvar("ui_unlock_cat", "");
    self setClientDvar("ui_unlock_icon", "");
    self setClientDvar("ui_unlock_square", 0);

    for (i = 0; i < 20; i++)
    {
        self sync_level_from_dvar();
        if (isDefined(self.survival_level) && self.survival_level > 0) break;
        wait 0.5;
    }

    if (!isDefined(self.survival_level) || self.survival_level < 1)
        self.survival_level = 1;

    self.last_notified_level = self.survival_level;
    print("[PROGRESSION]: Initial level for " + self.name + " set to " + self.survival_level);

    for (;;)
    {
        wait 1;

        guid = self.guid;
        if (isDefined(guid) && guid != "")
        {
            dvar_lvl = getDvarInt("player_lvl_" + guid);
            if (dvar_lvl > 0 && dvar_lvl != self.survival_level)
            {
                if (dvar_lvl > self.survival_level && (!isDefined(self.is_leveling_up) || !self.is_leveling_up))
                    self thread process_level_up(dvar_lvl);
                else if (dvar_lvl < self.survival_level)
                {
                    self.survival_level = dvar_lvl;
                    self.last_notified_level = dvar_lvl;
                }
            }
        }

        if (self isHost())
        {
            p_lvl = getDvarInt("p_lvl");
            if (p_lvl > self.survival_level && (!isDefined(self.is_leveling_up) || !self.is_leveling_up))
                self thread process_level_up(p_lvl);
        }
    }
}

playersTelemetry()
{
    level endon("game_ended");
    for(;;)
    {
        result = lethalbeats\utility::waittill_any_return("wave_end", "all_survivors_death", "game_ended");
        isFinal = (result == "all_survivors_death" || result == "game_ended");
        if (result == "wave_end") wait 1;

        survivor_list = lethalbeats\survival\utility::survivors();
        teamSize = survivor_list.size;
        isTeam = (teamSize > 1);

        team_members = [];
        team_score = 0;
        team_kills = 0;
        if (isTeam)
        {
            foreach (s in survivor_list)
            {
                if (!isDefined(s) || !isPlayer(s) || s isTestClient()) continue;
                m = [];
                m["guid"] = s.guid;
                m["name"] = s.name;
                m["level"] = isDefined(s.survival_level) ? s.survival_level : 1;
                m["kills"] = (isDefined(s.pers) && isDefined(s.pers["kills"])) ? s.pers["kills"] : 0;
                m["score"] = isDefined(s.score) ? s.score : 0;
                m["deaths"] = (isDefined(s.pers) && isDefined(s.pers["deaths"])) ? s.pers["deaths"] : 0;
                m["downs"] = (isDefined(s.pers) && isDefined(s.pers["downs"])) ? s.pers["downs"] : 0;
                m["revives"] = (isDefined(s.pers) && isDefined(s.pers["revives"])) ? s.pers["revives"] : 0;
                m["headshots"] = (isDefined(s.match_summary) && isDefined(s.match_summary["headshots"])) ? s.match_summary["headshots"] : 0;
                team_members[team_members.size] = m;
                team_score += m["score"];
                team_kills += m["kills"];
            }
        }

        foreach (player in level.players)
        {
            if (!isDefined(player) || !isPlayer(player) || player isTestClient()) continue;
            if (!isDefined(player.pers) || !isDefined(player.match_summary) || !isDefined(player.wave_summary)) continue;

            player.match_summary["kills"] = player.pers["kills"];
            player.match_summary["deaths"] = player.pers["deaths"];
            player.match_summary["revives"] = player.pers["revives"];
            player.match_summary["downs"] = player.pers["downs"];
            player.match_summary["money_earned"] = player.pers["money_earned"];

            player.match_summary["headshots"] += player.wave_summary["headshots"];
            player.match_summary["shots"] += player.wave_summary["totalshots"];
            player.match_summary["hits"] += player.wave_summary["hits"];

            duration = isDefined(level.startTime) ? int((getTime() - level.startTime) / 1000) : 0;
            mapName = getDvar("mapname");
            diff = getDvar("survival_enemy_difficulty");
            if (diff == "") diff = "1";

            data = [];
            data["xuid"] = player.guid;
            data["name"] = player.name;
            data["map"] = mapName;
            data["difficulty"] = diff;
            data["mode"] = isTeam ? "team" : "solo";
            data["team_size"] = teamSize;
            data["duration"] = duration;
            data["wave"] = level_get_wave();
            data["final"] = isFinal ? 1 : 0;
            data["stats"] = player.match_summary;
            if (isTeam)
            {
                data["team_members"] = team_members;
                data["team_score"] = team_score;
                data["team_kills"] = team_kills;
            }

            jsonStr = lethalbeats\json::json_serialize(data);
            print("MATCH_TELEMETRY=" + jsonStr + "\n");
            logprint("MATCH_TELEMETRY=" + jsonStr + "\n");
        }

        if (isFinal) break;
    }
}

sync_level_from_dvar()
{
    guid = self.guid;
    if (isDefined(guid) && guid != "")
    {
        lvl = getDvarInt("player_lvl_" + guid);
        if (lvl > 0)
        {
            self.survival_level = lvl;
            return;
        }
    }

    if (self isHost())
    {
        plvl = getDvarInt("p_lvl");
        if (plvl > 0) self.survival_level = plvl;
    }
}

get_player_card_icon()
{
    if (!isPlayer(self) || self isTestClient()) return "cardicon_default";
    iconIndex = self getplayerdata("cardIcon");
    if (!isDefined(iconIndex) || iconIndex < 0) return "cardicon_default";
    icon = tablelookupbyrow("mp/cardicontable.csv", iconIndex, 0);
    if (!isDefined(icon) || icon == "") return "cardicon_default";
    return icon;
}

process_level_up(new_level)
{
    self endon("disconnect");

    if (isDefined(self.is_leveling_up) && self.is_leveling_up)
        return;

    self.is_leveling_up = true;

    if (new_level > 50)
        new_level = 50;

    if (!isDefined(self.last_notified_level))
        self.last_notified_level = 1;

    if (new_level <= self.last_notified_level)
    {
        self.is_leveling_up = false;
        return;
    }

    print("[PROGRESSION]: Processing level up for " + self.name + " (" + self.last_notified_level + " -> " + new_level + ")");

    start_lvl = self.last_notified_level + 1;
    for (lvl = start_lvl; lvl <= new_level; lvl++)
    {
        self.survival_level = lvl;
        self.last_notified_level = lvl;

        // sync client dvars for promotion
        rnk_name = get_rank_name_by_level(lvl);
        rnk_icon = get_rank_icon_by_level(lvl);

        self setClientDvar("p_lvl", lvl);
        self setClientDvar("p_rnk", rnk_name);
        self setClientDvar("p_ico", rnk_icon);

        if (isDefined(self.guid) && self.guid != "")
            setDvar("player_lvl_" + self.guid, lvl);

        waittillframeend;

        // dispatch promotion to demo_playercard_hd menu
        self playLocalSound("mp_level_up");
        self lethalbeats\survival\utility::survivor_display_hud("level_up_card");
        wait 4.2;

        // dispatch unlocks for this level
        unlocked_items = get_unlocked_items_for_level(lvl);
        if (unlocked_items.size > 0)
        {
            foreach (item_id in unlocked_items)
            {
                info = get_item_metadata(item_id);
                if (info.name == "")
                    continue;

                self setClientDvar("ui_unlock_name", info.name);
                self setClientDvar("ui_unlock_cat", info.cat);
                self setClientDvar("ui_unlock_icon", info.icon);
                self setClientDvar("ui_unlock_square", info.is_square);

                waittillframeend;

                self playLocalSound("mp_level_up");
                self lethalbeats\survival\utility::survivor_display_hud("unlock_item_card");
                wait 4.0;
                self setClientDvar("ui_unlock_name", "");
                self setClientDvar("ui_unlock_cat", "");
                self setClientDvar("ui_unlock_icon", "");
                self setClientDvar("ui_unlock_square", 0);
                wait 0.2;
            }
        }
    }

    self setClientDvar("ui_unlock_name", "");
    self setClientDvar("ui_unlock_cat", "");
    self setClientDvar("ui_unlock_icon", "");
    self setClientDvar("ui_unlock_square", 0);
    self.is_leveling_up = false;
}

scoreboardMonitor()
{
    level endon("game_ended");

    for (i = 0; i < 6; i++)
    {
        setDvar("sb_p" + i + "_name", "");
        setDvar("sb_p" + i + "_icon", "cardicon_default");
        setDvar("sb_p" + i + "_lvl", 1);
        setDvar("sb_p" + i + "_money", 0);
        setDvar("sb_p" + i + "_kills", 0);
        setDvar("sb_p" + i + "_downs", 0);
        setDvar("sb_p" + i + "_revives", 0);
        setDvar("sb_p" + i + "_deaths", 0);
        setDvar("sb_p" + i + "_ping", 0);
        setDvar("sb_p" + i + "_down", 0);
        setDvar("sb_p" + i + "_status", 0);
    }
    setDvar("ui_match_time", "0:00");

    for (;;)
    {
        wait 0.3;

        start_t = isDefined(level.startTime) ? level.startTime : (isDefined(level.matchStartTime) ? level.matchStartTime : 0);
        if (start_t > 0)
        {
            elapsed = int((getTime() - start_t) / 1000);
            if (elapsed < 0) elapsed = 0;
            mins = int(elapsed / 60);
            secs = elapsed % 60;
            sec_str = "" + secs;
            if (secs < 10) sec_str = "0" + secs;
            setDvar("ui_match_time", mins + ":" + sec_str);
        }

        players = get_sorted_scoreboard();
        for (slot = 0; slot < 6; slot++)
        {
            if (slot < players.size)
            {
                p = players[slot];
                if (!isDefined(p)) continue;

                p_name = isDefined(p.name) ? p.name : "";
                p_lvl = getDvarInt("survival_ladder") ? (isDefined(p.survival_level) ? p.survival_level : 1) : 0;
                p_icon = p get_player_card_icon();
                p_money = isDefined(p.score) ? p.score : 0;
                p_kills = (isDefined(p.pers) && isDefined(p.pers["kills"])) ? p.pers["kills"] : 0;
                p_downs = (isDefined(p.pers) && isDefined(p.pers["downs"])) ? p.pers["downs"] : 0;
                p_revives = (isDefined(p.pers) && isDefined(p.pers["revives"])) ? p.pers["revives"] : 0;
                p_deaths = (isDefined(p.pers) && isDefined(p.pers["deaths"])) ? p.pers["deaths"] : 0;
                p_ping = isDefined(p.ping) ? p.ping : 0;
                is_dead = (!isAlive(p) || p.sessionstate != "playing" || isDefined(level.survivors_deaths[p.guid]));
                is_reviving = (!is_dead && ((isDefined(p.is_being_revived) && p.is_being_revived) || (isDefined(level.survivors_bleedout[p.guid]) && isDefined(level.survivors_bleedout[p.guid][2])) || isDefined(p.reviveSpot)));
                is_laststand = (!is_dead && !is_reviving && (p.inLastStand || isDefined(level.survivors_bleedout[p.guid]) || (isDefined(p.isBleeding) && p.isBleeding)));

                p_status = 0; // 0 = alive (green)
                if (is_dead) p_status = 2; // 2 = dead (red)
                else if (is_reviving) p_status = 3; // 3 = reviving (cyan)
                else if (is_laststand) p_status = 1; // 1 = down (yellow)
                p_down = (p_status == 1 || p_status == 3) ? 1 : 0;

                setDvar("sb_p" + slot + "_name", p_name);
                setDvar("sb_p" + slot + "_icon", p_icon);
                setDvar("sb_p" + slot + "_lvl", p_lvl);
                setDvar("sb_p" + slot + "_money", p_money);
                setDvar("sb_p" + slot + "_kills", p_kills);
                setDvar("sb_p" + slot + "_downs", p_downs);
                setDvar("sb_p" + slot + "_revives", p_revives);
                setDvar("sb_p" + slot + "_deaths", p_deaths);
                setDvar("sb_p" + slot + "_ping", p_ping);
                setDvar("sb_p" + slot + "_down", p_down);
                setDvar("sb_p" + slot + "_status", p_status);

                foreach(player in players)
                {
                    if (!isDefined(player) || !isPlayer(player) || player isTestClient()) continue;
                    if (!isDefined(player.pers) || !isDefined(player.sessionstate) || player.sessionstate != "playing") continue;
                    if (!isDefined(player.sb_cache)) player.sb_cache = [];

                    is_local = (player == p) ? 1 : 0;
                    cache_key = p_name + "|" + p_icon + "|" + p_lvl + "|" + p_money + "|" + p_kills + "|" + p_downs + "|" + p_revives + "|" + p_deaths + "|" + p_ping + "|" + p_down + "|" + p_status + "|" + is_local;

                    if (!isDefined(player.sb_cache[slot]) || player.sb_cache[slot] != cache_key)
                    {
                        player.sb_cache[slot] = cache_key;
                        player setClientDvar("sb_p" + slot + "_name", p_name);
                        player setClientDvar("sb_p" + slot + "_icon", p_icon);
                        player setClientDvar("sb_p" + slot + "_lvl", p_lvl);
                        player setClientDvar("sb_p" + slot + "_money", p_money);
                        player setClientDvar("sb_p" + slot + "_kills", p_kills);
                        player setClientDvar("sb_p" + slot + "_downs", p_downs);
                        player setClientDvar("sb_p" + slot + "_revives", p_revives);
                        player setClientDvar("sb_p" + slot + "_deaths", p_deaths);
                        player setClientDvar("sb_p" + slot + "_ping", p_ping);
                        player setClientDvar("sb_p" + slot + "_down", p_down);
                        player setClientDvar("sb_p" + slot + "_status", p_status);
                        player setClientDvar("sb_p" + slot + "_local", is_local);
                    }
                }
            }
            else if (getDvar("sb_p" + slot + "_name") != "")
            {
                setDvar("sb_p" + slot + "_name", "");
                setDvar("sb_p" + slot + "_icon", "cardicon_default");
                setDvar("sb_p" + slot + "_lvl", 1);
                setDvar("sb_p" + slot + "_money", 0);
                setDvar("sb_p" + slot + "_kills", 0);
                setDvar("sb_p" + slot + "_downs", 0);
                setDvar("sb_p" + slot + "_revives", 0);
                setDvar("sb_p" + slot + "_deaths", 0);
                setDvar("sb_p" + slot + "_ping", 0);
                setDvar("sb_p" + slot + "_down", 0);
                setDvar("sb_p" + slot + "_status", 0);

                foreach(player in players)
                {
                    if (!isDefined(player) || !isPlayer(player) || player isTestClient()) continue;
                    if (!isDefined(player.pers) || !isDefined(player.sessionstate) || player.sessionstate != "playing") continue;

                    if (isDefined(player.sb_cache) && isDefined(player.sb_cache[slot]) && player.sb_cache[slot] != "")
                    {
                        player.sb_cache[slot] = "";
                        player setClientDvar("sb_p" + slot + "_name", "");
                        player setClientDvar("sb_p" + slot + "_icon", "cardicon_default");
                        player setClientDvar("sb_p" + slot + "_status", 0);
                        player setClientDvar("sb_p" + slot + "_local", 0);
                    }
                }
            }
        }
    }
}

get_sorted_scoreboard()
{
    survivors = lethalbeats\survival\utility::survivors();
    for (i = 0; i < survivors.size - 1; i++)
    {
        for (j = i + 1; j < survivors.size; j++)
        {
            p1 = survivors[i];
            p2 = survivors[j];

            score1 = p1.score;
            score2 = p2.score;

            if (score2 > score1 || (score2 == score1 && p2.pers["kills"] > p1.pers["kills"]))
            {
                survivors[i] = p2;
                survivors[j] = p1;
            }
        }
    }
    return survivors;
}

get_rank_icon_by_level(lvl)
{
    idx = lvl - 1;
    if (idx < 0) idx = 0;
    else if (idx > 49) idx = 49;
    icon = tablelookup("mp/rankicontable.csv", 0, idx, 1);
    return icon == "" ? "rank_pvt1" : icon;
}

get_rank_name_by_level(lvl)
{
    idx = lvl - 1;
    if (idx < 0) idx = 0;
    else if (idx > 49) idx = 49;
    rnk = tablelookup("mp/ranktable.csv", 0, idx, 4);
    return rnk == "" ? "RANK_PVT" : rnk;
}

get_unlocked_items_for_level(target_lvl)
{
    if (!isDefined(level.dynamicShopPages)) return [];

    unlocked = [];
    page_keys = getArrayKeys(level.dynamicShopPages);
    for (p = 0; p < page_keys.size; p++)
    {
        pageData = level.dynamicShopPages[page_keys[p]];
        items = pageData[PAGE_ITEMS];
        if (!isDefined(items)) continue;

        for (i = 0; i < items.size; i++)
        {
            item = items[i];
            if (isDefined(item[ITEM_UNLOCK_LEVEL]) && item[ITEM_UNLOCK_LEVEL] == target_lvl)
                unlocked[unlocked.size] = item[ITEM_VALUE];
        }
    }

    return unlocked;
}

get_item_metadata(item_id)
{
    info = spawnStruct();
    info.name = "";
    info.cat = "ARMORY ITEM";
    info.icon = "";
    info.is_square = 0;

    if (isDefined(level.dynamicShopPages))
    {
        page_keys = getArrayKeys(level.dynamicShopPages);
        for (p = 0; p < page_keys.size; p++)
        {
            page = level.dynamicShopPages[page_keys[p]];
            items = page[PAGE_ITEMS];
            if (!isDefined(items))
                continue;

            for (i = 0; i < items.size; i++)
            {
                item = items[i];
                if (isDefined(item[ITEM_VALUE]) && item[ITEM_VALUE] == item_id)
                {
                    if (isDefined(item[ITEM_LABEL]) && item[ITEM_LABEL] != "")
                        info.name = item[ITEM_LABEL];

                    if (isDefined(page[PAGE_DISPLAY]) && page[PAGE_DISPLAY] != "")
                        info.cat = page[PAGE_DISPLAY];

                    if (isDefined(item[ITEM_IMAGE_SQUARE]) && item[ITEM_IMAGE_SQUARE] != "")
                    {
                        info.icon = item[ITEM_IMAGE_SQUARE];
                        info.is_square = 1;
                    }
                    else if (isDefined(item[ITEM_IMAGE_RECT]) && item[ITEM_IMAGE_RECT] != "")
                    {
                        info.icon = item[ITEM_IMAGE_RECT];
                        info.is_square = 0;
                    }

                    return info;
                }
            }
        }
    }

    info.name = item_id;
    return info;
}

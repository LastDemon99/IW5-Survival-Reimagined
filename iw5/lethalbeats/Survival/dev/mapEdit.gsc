#include lethalbeats\survival\armories\_spawn;
#include lethalbeats\survival\utility;
#include lethalbeats\player;
#include lethalbeats\trigger;

#define JUGG_ICON "iw5_cardicon_juggernaut_b"
#define TOOL "iw5_usp45_mp"

init()
{
	precacheShader(JUGG_ICON);

	level.positionFx = loadFx("misc/ui_flagbase_gold");
	level.laserFx = loadfx("misc/laser_glow");
	mapName = getDvar("mapname");

	self thread onPlayerConnect();
	wait 2;

	level.survivalEdits = [];

	if (isDefined(level.juggDrop[mapName]))
        foreach(armory in level.juggDrop[mapName])
            setEdit("jugger", armory);
	
    if (isDefined(level.armories[mapName]))
        foreach(armory in level.armories[mapName])
            setEdit(armory[0], armory[1], armory[2]);
}

onPlayerConnect()
{
    level endon("game_ended");

    for (;;)
    {
        level waittill("connected", player);
		if (player isTestClient()) continue;

		player thread lethalbeats\player::player_refill_ammo();
		player thread onPlayerSpawn();
		player thread onWeaponFired();
		player thread watchMissileUsage();
		player thread juggerCall();
	}
}

onPlayerSpawn()
{
	level endon("game_ended");
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");

		wait 2;

		self survivor_give_perk("specialty_quickdraw");
		self survivor_give_perk("specialty_fastreload");
		self survivor_give_perk("specialty_longersprint");

		self player_clear_nades();
		self takeWeapon("iw5_fnfiveseven_mp");
		self player_give_weapon(TOOL, true);
		self player_give_weapon("rpg_mp");
		self player_give_weapon("killstreak_uav_mp");
		self player_give_weapon("killstreak_remote_tank_laptop_mp");
		self maps\mp\_utility::_setActionSlot(4, "weapon", "killstreak_uav_mp");
		self maps\mp\_utility::_setActionSlot(6, "weapon", "killstreak_remote_tank_laptop_mp");
		self maps\mp\_utility::_setActionSlot(7, "weapon", "killstreak_uav_mp");

		self setplayerdata("killstreaksState", "isSpecialist", 0);
		self setplayerdata("killstreaksState", "icons", 0, 20);
		self setplayerdata("killstreaksState", "icons", 1, 23);
		self setplayerdata("killstreaksState", "icons", 2, 26);
		self setplayerdata("killstreaksState", "icons", 3, 27);
		self allowSlotStreak(true);

		self thread onActionSlot();

		self survivor_set_body_armor(9999999);
		self survivor_set_score(9999999);
	}
}

onActionSlot()
{
	self endon("death");
    self endon("disconnect");

	self notifyonplayercommand("switchTool", "+actionslot 4");
	self notifyonplayercommand("fly", "+actionslot 5");
	self notifyonplayercommand("tp", "+actionslot 6");
	self notifyonplayercommand("save", "+actionslot 7");

	self.current_tool = 0;

	for (;;)
	{
		result = self lethalbeats\utility::waittill_any_return("switchTool", "fly", "tp", "save");

		if (result == "fly")
		{
			if (self.sessionstate != "spectator") 
			{
				self allowSlotStreak(false);
				self setplayerdata("killstreaksState", "hasStreak", 1, 1);
			}
			else self allowSlotStreak(true);

			self lethalbeats\survival\dev\test::fly();
			continue;
		}
		
		if (result == "tp")
		{
			self allowSlotStreak(false);
			self setplayerdata("killstreaksState", "hasStreak", 2, 1);
			self tpLocationSelection();
			self switchToWeaponImmediate(TOOL);
			self allowSlotStreak(true);
			continue;
		}

		if (result == "save")
		{
			saveEdits();
			self allowSlotStreak(false);
			self waittill("weapon_change", weapon);
			self switchToWeaponImmediate(TOOL);
			self allowSlotStreak(true);
			continue;
		}

		if (self.sessionstate == "spectator") continue;

		self allowSlotStreak(false);
		self waittill("weapon_change", weapon);
		self switchToWeaponImmediate(TOOL);
		
		self.current_tool++;
		switch(self.current_tool)
		{
			case 0:
				self notifyData("Switch Tool: Weapon Armory");
				self setplayerdata("killstreaksState", "icons", 0, 20);
				break;
			case 1:
				self notifyData("Switch Tool: Equipment Armory");
				self setplayerdata("killstreaksState", "icons", 0, 2);
				break;
			case 2:
				self notifyData("Switch Tool: Air Support Armory");
				self setplayerdata("killstreaksState", "icons", 0, 16);
				break;
			case 3:
				self notifyData("Switch Tool: Jugger Passenger");
				self setplayerdata("killstreaksState", "icons", 0, 52);
				break;
			case 4:
				self notifyData("Switch Tool: Weapon Armory");
				self.current_tool = 0;
				self setplayerdata("killstreaksState", "icons", 0, 20);
				break;
		}

		wait 1;
		self allowSlotStreak(true);
	}
}

onWeaponFired()
{
    level endon("game_ended");
    self endon("disconnected");

    for (;;)
    {
		self waittill("weapon_fired", weapon);
		if (weapon == TOOL) 
            if (self.current_tool < 3) self armoryTool();
            else self juggerTool();
	}
}

watchMissileUsage()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("missile_fire", missile, weaponName);
		if (weaponName == "rpg_mp") missile thread deleteEdit();
	}
}

armoryTool()
{
    types = ["weapon", "equipment", "support"];
    armory = types[self.current_tool];

	endDistance = 1000;

	start = self getEye();
    forward = anglesToForward(self getPlayerAngles());
    end = start + (forward * endDistance);
	eyeTrace = BulletTrace(start, end, false, self);

	if (!isDefined(eyeTrace["surfacetype"]) || eyeTrace["surfacetype"] == "none") return;

	world_up = lethalbeats\vector::vector_up();
	position = eyeTrace["position"];
	normal = eyeTrace["normal"];
	dot = vectorDot(normal, world_up);
	upOffset = world_up * 15;
	
	if (abs(dot) < 0.1) // wall
	{
		angles = vectorToAngles(normal) - (0, 90, 0);
		newStart = position + (normal * 17);
		newEnd = newStart + (lethalbeats\vector::vector_down() * endDistance);
		trace = bullettrace(newStart, newEnd, false, self);
		angles = lethalbeats\vector::vector_angles_orient_to_normal(trace["normal"], angles[1]);
        setEdit(armory, trace["position"] + upOffset, angles);
	}
	//else if (dot < -0.9) // ceiling
	else //if (dot > 0.9) // floor
	{
		angles = lethalbeats\vector::vector_angles_orient_to_normal(normal, self.angles[1] + 90);
        setEdit(armory, position + upOffset, angles);
	}
	// else // slope
}

juggerTool()
{
	endDistance = 1000;
	start = self getEye();
	forward = anglesToForward(self getPlayerAngles());
	end = start + (forward * endDistance);
	eyeTrace = BulletTrace(start, end, false, self);
	if (!isDefined(eyeTrace["surfacetype"]) || eyeTrace["surfacetype"] == "none") return;
	origin = eyeTrace["position"];
	setEdit("jugger", origin);
}

spawnJugger(origin)
{
	upOffset = (0, 0, 1);
	originFx = spawnFx(level.positionFx, origin, anglesToUp(upOffset), anglesToRight(upOffset));
	triggerFx(originFx);

	juggerModel = spawn("script_model", origin);
	juggerModel setModel("fullbody_juggernaut_novisor_b");
	juggerModel.angles = (0, 90, 0);
	juggerModel lethalbeats\hud::hud_create_2d_objective("allies", JUGG_ICON);

	trigger = trigger_create(origin, 55);
	trigger trigger_set_use("Press ^3[{+activate}] ^7to call jugger");
	trigger.tag = "jugger";

	return [juggerModel, trigger, originFx];
}

setEdit(type, origin, angles)
{
	wayPoint = undefined;
	origin = lethalbeats\vector::vector_truncate(origin, 3);
	angles = isDefined(angles) ? lethalbeats\vector::vector_truncate(angles, 3) : undefined;

    edit = [type, origin, angles];
    switch(type)
    {
        case "weapon":
			wayPoint = "specops_ui_weaponstore";
        case "equipment":
			if (!isDefined(wayPoint)) wayPoint = "specops_ui_equipmentstore";
        case "support":
			if (!isDefined(wayPoint)) wayPoint = "specops_ui_airsupport";
			armory = level spawnShop(type, origin, angles);
			armory[0] lethalbeats\hud::hud_create_2d_objective("allies", wayPoint);
            edit = [type, origin, angles, armory];
            break;
        case "jugger":
            edit = [type, origin, undefined, spawnJugger(origin)];
            break;
    }
    level.survivalEdits[level.survivalEdits.size] = edit;
}

deleteEdit()
{
	self endon("end_explode");
    self waittill("explode", position);

	newEdits = [];
	foreach(edit in level.survivalEdits)
	{
		if (distanceSquared(position, edit[1]) < (200 * 200))
		{
            editDisplays = edit[3];
			foreach(display in editDisplays)
			{
				display lethalbeats\hud::hud_delete_objective();
				if (isDefined(display.type)) display trigger_delete();
				else display delete();
			}
		}
		else newEdits[newEdits.size] = edit;
	}
	level.survivalEdits = newEdits;
}

juggerCall()
{
	level endon("game_ended");
	self endon("disconnect");

	for (;;)
	{
		self waittill("trigger_use", trigger);

		if (trigger.tag != "jugger") continue;

		trigger trigger_disable();
		bots()[0] lethalbeats\survival\abilities\_juggernaut::_doFlyBy(self, trigger.origin, randomFloat(360), 825);
		trigger thread callJuggerDelay();
	}
}

callJuggerDelay()
{
	wait 22;
	self trigger_enable();
}

saveEdits()
{
    mapName = getDvar("mapname");

    _armories = [];
    _juggDrop = [];

    foreach(edit in level.survivalEdits)
    {
        if (edit[0] == "jugger") _juggDrop[_juggDrop.size] = edit[1];
        else _armories[_armories.size] = [edit[0], edit[1], edit[2]];
    }

    level.armories[mapName] = _armories;
	level.juggDrop[mapName] = _juggDrop;

	print("MAP_EDIT:: ==================================\n");
    print("level.armories[\"" + mapName + "\"] =", lethalbeats\json::json_serialize(_armories) + ";");
	print("level.juggDrop[\"" + mapName + "\"] =", lethalbeats\json::json_serialize(_juggDrop) + ";\n");
    print("MAP_EDIT:: ==================================");

	self notifyData("Map Saved Check Console or Log", "mp_killconfirm_tags_pickup");
}

allowSlotStreak(allow)
{
	self setplayerdata("killstreaksState", "hasStreak", 0, int(allow));
	self setplayerdata("killstreaksState", "hasStreak", 1, int(allow));
	self setplayerdata("killstreaksState", "hasStreak", 2, int(allow));
	self setplayerdata("killstreaksState", "hasStreak", 3, int(allow));
	self setplayerdata("killstreaksState", "hasStreak", 4, int(allow));
}

tpLocationSelection()
{
	self waittill("weapon_change", weapon);
	self endon("stop_location_selection");

	self maps\mp\_utility::_beginLocationSelection("airstrike", "map_artillery_selector", 0, 500);
	self waittill("confirm_location", location, locationYaw);
	location = (location[0], location[1], self maps\mp\killstreaks\_airdrop::getFlyHeightOffset(location));
	trace = BulletTrace(location, location - (0, 0, 10000), false, self);

	if (!isDefined(trace["surfacetype"]) || trace["surfacetype"] == "none") self setOrigin(location);
	else self setOrigin(trace["position"] + (0, 0, 50));
}

notifyData(title, sound)
{
	if (!isDefined(sound)) sound = "ammo_crate_use";

	notifyData = spawnStruct();
	notifyData.glowColor = (0, 0, 1);
	notifyData.duration = 2;
	notifyData.sound = sound;
	notifyData.titleText = title;
	self lethalbeats\hud::hud_notify_message(notifyData);
}

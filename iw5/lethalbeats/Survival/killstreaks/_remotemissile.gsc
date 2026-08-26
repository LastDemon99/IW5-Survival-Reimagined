#include maps\mp\_utility;
#include common_scripts\utility;

init()
{
	precacheShader("remotemissile_target_hostile");
	precacheMenu("missilecam_hud_hd");
	replacefunc(maps\mp\killstreaks\_remotemissile::tryusepredatormissile, ::_tryusepredatormissile);
}

_tryusepredatormissile(lifeId)
{
	if (isdefined(level.civilianjetflyby))
	{
		self iprintlnbold(&"MP_CIVILIAN_AIR_TRAFFIC");
		return 0;
	}

	maps\mp\_utility::setusingremote("remotemissile");
	result = maps\mp\killstreaks\_killstreaks::initridekillstreak();

	if (result != "success")
	{
		if (result != "disconnect") maps\mp\_utility::clearusingremote();
		return 0;
	}

	level thread survivor_uav_drone_sequence(lifeId, self);
	return 1;
}

get_allied_uav_model()
{
	if (isdefined(level.uavmodels) && isdefined(level.uavmodels["allies"]) && level.uavmodels["allies"].size > 0)
	{
		foreach (uav in level.uavmodels["allies"])
			if (isdefined(uav)) return uav;
	}
	return undefined;
}

survivor_uav_drone_sequence(lifeId, player)
{
	player endon("disconnect");
	player endon("joined_team");
	player endon("joined_spectators");

	uav = get_allied_uav_model();

	if (isdefined(uav)) uavOrigin = uav.origin;
	else if (isdefined(level.uavrig)) uavOrigin = level.uavrig.origin + (0, -4000, 5000);
	else uavOrigin = player.origin + (0, -3500, 4500);

	
	cameraRig = spawn("script_model", uavOrigin);
	cameraRig setmodel("vehicle_predator_b");
	cameraRig hide();

	aimTarget = isdefined(level.mapcenter) ? level.mapcenter : (0, 0, 0);
	tagOrigin = cameraRig gettagorigin("tag_player");
	lookAngles = vectortoangles(aimTarget - tagOrigin);
	cameraRig.angles = (0, lookAngles[1], 0);
	if (isdefined(uav)) cameraRig thread follow_uav_pos(uav);

	player visionsetmissilecamforplayer("black_bw", 0.0);
	player visionsetmissilecamforplayer("missilecam", 1.0);
	player thermalvisionon();
	player thread delayed_fof_overlay();
	player openMenu("missilecam_hud_hd");
	if (getdvarint("camera_thirdPerson")) player maps\mp\_utility::setthirdpersondof(0);

	player playerlinkweaponviewtodelta(cameraRig, "tag_player", 1.0, 89, 89, 70, 89);
	wait 0.05;
	player setplayerangles(lookAngles);

	action = player wait_player_actions();

	if (action == "fire")
	{
		playerAngles = player getplayerangles();
		forward = anglestoforward(playerAngles);
		startPos = cameraRig.origin + (forward * 150);
		targetPos = startPos + (forward * 20000);

		player unlink();
		if (isdefined(cameraRig))
		{
			cameraRig lethalbeats\hud::hud_delete_2d_objective();
			cameraRig delete();
		}

		rocket = magicbullet("remotemissile_projectile_mp", startPos, targetPos, player);

		if (!isdefined(rocket))
		{
			player thermalvisionoff();
			player thermalvisionfofoverlayoff();
			player visionsetnakedforplayer("", 0.5);
			if (getdvarint("camera_thirdPerson")) player maps\mp\_utility::setthirdpersondof(1);
			player maps\mp\_utility::clearusingremote();
			player maps\mp\killstreaks\_killstreaks::givekillstreak("predator_missile", false, false, player, true);
			player closeMenu("missilecam_hud_hd");
			return;
		}

		rocket.lifeid = lifeId;
		rocket.type = "remote";
		rocket thread maps\mp\gametypes\_weapons::addmissiletosighttraces(player.team);
		rocket thread maps\mp\killstreaks\_remotemissile::handledamage();
		maps\mp\killstreaks\_remotemissile::missileeyes(player, rocket);
		rocket waittill("death");
		player closeMenu("missilecam_hud_hd");
	}
	else
	{
		player unlink();
		if (isdefined(cameraRig))
		{
			cameraRig lethalbeats\hud::hud_delete_2d_objective();
			cameraRig delete();
		}
		player thermalvisionoff();
		player thermalvisionfofoverlayoff();
		player visionsetnakedforplayer("", 0.5);
		player closeMenu("missilecam_hud_hd");

		if (getdvarint("camera_thirdPerson")) player maps\mp\_utility::setthirdpersondof(1);
		player maps\mp\_utility::clearusingremote();

		if (isalive(player))
		{
			player maps\mp\killstreaks\_killstreaks::givekillstreak("predator_missile", false, false, player, true);
			prevWep = isdefined(player.prevWeapon) ? player.prevWeapon : player lethalbeats\player::player_get_primary();
			if (isdefined(prevWep) && player hasweapon(prevWep)) player switchtoweapon(prevWep);
		}
	}
}

follow_uav_pos(uav)
{
	self endon("death");
	uav endon("death");
	for (;;)
	{
		self.origin = uav.origin;
		wait 0.05;
	}
}

delayed_fof_overlay()
{
	self endon("death");
	self endon("disconnect");
	level endon("game_ended");
	wait 0.15;
	self thermalvisionfofoverlayon();
}

wait_player_actions()
{
	self endon("disconnect");
	self endon("joined_team");
	self endon("joined_spectators");

	self notifyonplayercommand("predator_fire", "+attack");
	self notifyonplayercommand("predator_fire", "+attack_akimbo_accessible");
	self notifyonplayercommand("predator_abort", "weapnext");
	self notifyonplayercommand("predator_abort", "+stance");
	self notifyonplayercommand("predator_abort", "+gostand");
	self notifyonplayercommand("predator_abort", "togglecrouch");

	self thread wait_player_command("predator_fire", "fire");
	self thread wait_player_command("predator_abort", "abort");
	self thread wait_player_damage();

	self waittill("predator_action", action);
	return action;
}

wait_player_command(notifyName, action)
{
	self endon("predator_action");
	self waittill(notifyName);
	self notify("predator_action", action);
}

wait_player_damage()
{
	self endon("predator_action");
	self waittill_any("damage", "death");
	self notify("predator_action", "abort");
	self closeMenu("missilecam_hud_hd");
}

giveStreak(streak)
{
    self [[level.killStreakFuncs[streak]]]();
}

giveSentry()
{
    self endon("death");
    for(;;)
    {
        if (level.botsSentry.size < getDvarInt("survival_bot_sentry_limit"))
        {
            self giveStreak("sentry");
            self waittill("placed_sentry");
        }
        wait 30;
    }
}

giveIMS()
{
    self endon("death");
    for(;;)
    {
        if (level.botsIMS.size < getDvarInt("survival_bot_ims_limit"))
        {
            self giveStreak("ims");
            self waittill("placed_ims");
        }
        wait 30;
    }
}

giveEmp()
{
	self [[level.killStreakFuncs["emp"]]]();
	self lethalbeats\survival\utility::bot_kill();
}

giveCounterUAV()
{
	level endon("wave_end");

	self lethalbeats\survival\utility::bot_kill(); 
	
	while(level.radarStrength == -3) wait 10;

	level thread maps\mp\killstreaks\_uav::launchUAV(undefined, "axis", 9999, "counter_uav");
	level.radarStrength = -3;
	maps\mp\killstreaks\_uav::updateTeamUAVStatus("allies");
	lethalbeats\player::players_play_sound("mp_killstreak_counteruav", "allies");
	lethalbeats\player::players_play_sound("US_1mc_enemy_jamuav", "allies");
}

giveAirstrike()
{
	lethalbeats\Survival\utility::level_wait_vehicle_limit();
	self lethalbeats\survival\utility::bot_kill();
	location = lethalbeats\array::array_random(lethalbeats\survival\utility::survivors(true)).origin;
	thread maps\mp\killstreaks\_airstrike::doAirstrike(undefined, location, 94, self, self.team, "super_airstrike");
	lethalbeats\player::players_play_sound("US_1mc_enemy_airstrike", "allies");
}

givePredator()
{
	lethalbeats\Survival\utility::level_wait_vehicle_limit();
    lethalbeats\player::players_play_sound("US_1mc_enemy_predator", "allies");
	self lethalbeats\survival\utility::bot_kill();

    survivors = lethalbeats\survival\utility::survivors(true);
	if (!survivors.size) return;

	exposed_survivors = [];
	foreach (survivor in survivors)
	{
		if (!isdefined(survivor) || !isalive(survivor)) continue;
		headPos = survivor getTagOrigin("j_head");
		if (!isdefined(headPos)) headPos = survivor.origin + (0, 0, 60);

		if (bullettracepassed(headPos, headPos + (0, 0, 2500), false, survivor))
			exposed_survivors[exposed_survivors.size] = survivor;
	}

	target = exposed_survivors.size > 0 ? lethalbeats\array::array_random(exposed_survivors) : lethalbeats\array::array_random(survivors);
	if (!isdefined(target)) return;

	targetPos = target.origin;

	remoteMissileSpawnArray = getentarray("remoteMissileSpawn", "targetname");
	foreach (spawn in remoteMissileSpawnArray)
	{
		if (isdefined(spawn.target))
			spawn.targetent = getent(spawn.target, "targetname");
	}

	bestDist = 99999999;
	bestSpawn = undefined;
	foreach (spawn in remoteMissileSpawnArray)
	{
		if (!isdefined(spawn.targetent)) continue;
		dist = distance2d(spawn.targetent.origin, targetPos);
		if (dist < bestDist)
		{
			bestDist = dist;
			bestSpawn = spawn;
		}
	}

	if (isdefined(bestSpawn))
	{
		startpos = bestSpawn.origin;
		spawnTarget = bestSpawn.targetent.origin;
		vector = vectornormalize(startpos - spawnTarget);
		startpos = vector * 14000 + targetPos;
	}
	else
	{
		vert = isdefined(level.missileremotelaunchvert) ? level.missileremotelaunchvert : 14000;
		horz = isdefined(level.missileremotelaunchhorz) ? level.missileremotelaunchhorz : 7000;
		angle = randomint(360);
		xOffset = cos(angle) * horz;
		yOffset = sin(angle) * horz;
		startpos = targetPos + (xOffset, yOffset, vert);
	}

	rocket = magicbullet("remote_mortar_missile_mp", startpos, targetPos, self);
	if (!isdefined(rocket)) return;

	rocket thread maps\mp\gametypes\_weapons::addmissiletosighttraces(self.team);
	rocket thread maps\mp\killstreaks\_remotemissile::handledamage();
	rocket missile_settargetent(target);
	rocket missile_setflightmodedirect();
	rocket lethalbeats\hud::hud_create_2d_objective("allies", "remotemissile_target_hostile");
	rocket waittill("death");
	rocket lethalbeats\hud::hud_delete_2d_objective();
}

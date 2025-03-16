giveEmp()
{
	self [[level.killStreakFuncs["emp"]]]();
	self lethalbeats\survival\utility::bot_kill();
}

giveCounterUAV()
{
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
	self lethalbeats\survival\utility::bot_kill();
	lethalbeats\Survival\utility::waitVehicleLimit();
	location = lethalbeats\array::array_random(lethalbeats\survival\utility::survivors(true)).origin;
	thread maps\mp\killstreaks\_airstrike::doAirstrike(undefined, location, 94, self, self.team, "super_airstrike");
	lethalbeats\player::players_play_sound("US_1mc_enemy_airstrike", "allies");
}

givePredator()
{
	self hide();
	self setOrigin(level.airDropCrateCollision.origin);
	self [[level.killStreakFuncs["predator_missile"]]]();
	lethalbeats\player::players_play_sound("US_1mc_enemy_predator", "allies");
}

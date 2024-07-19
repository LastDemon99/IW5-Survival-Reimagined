#include maps\mp\_utility;
#include common_scripts\utility;

init()
{
	level endon("game_ended");
	
	replacefunc(maps\mp\killstreaks\_uav::updateUAVModelVisibility, ::updateUAVModelVisibility);
	replacefunc(maps\mp\killstreaks\_uav::damageTracker, ::damageTracker);
	replacefunc(maps\mp\killstreaks\_uav::_getRadarStrength, ::_getRadarStrength);
	
	level.radarStrength = 2;
	level thread maps\mp\killstreaks\_uav::launchUAV(undefined, "axis", 9999, "uav");
	
	level.radarStrength = 0;
	level thread maps\mp\killstreaks\_uav::launchUAV(undefined, "allies", 9999, "uav");
	
	for(;;)
	{
		level waittill("wave_start");
		wait 0.4;
		level.radarStrength = 2;
		maps\mp\killstreaks\_uav::updateTeamUAVStatus("allies");
		
		level waittill("wave_end");
		level.radarStrength = 0;
		maps\mp\killstreaks\_uav::updateTeamUAVStatus("allies");
	}
}

_getRadarStrength(team)
{
	return level.radarStrength;
}

updateUAVModelVisibility()
{
	if (self.team == "axis") self hide();
}

damageTracker(isCounterUAV, isAdvanced) 
{
	level endon ("game_ended");	
	level waittill("disable_uav");
	self notify("death");
}
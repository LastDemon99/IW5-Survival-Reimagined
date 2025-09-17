#include common_scripts\utility;
#include maps\mp\_utility;

init()
{
	waittillframeend;
	if (getDvarInt("survival_dev_mode") == 2) return;
	map = getDvar("mapname");
	if (isDefined(level.armories[map]))
	{
		foreach(armory in level.armories[map])
			level thread spawnShop(armory[0], armory[1], armory[2]);
	}
}

spawnShop(type, origin, angles)
{
	level endon("game_ended");
	
	shopModel = spawnShopModel(origin, angles);
	
	hintString = "";
	wayPoint = "";
	waveTarget = 0;
	
	switch(type)
	{
		case "weapon": 
			hintString = "Weapon Armory";
			wayPoint = "specops_ui_weaponstore";
			waveTarget = 2;
			break;
		case "equipment": 
			hintString = "Equipment Armory";
			wayPoint = "specops_ui_equipmentstore";
			waveTarget = 4;
			break;
		case "support": 
			hintString = "Air Support";
			wayPoint = "specops_ui_airsupport";
			waveTarget = 6;
			break;
	}
	
	if (getDvarInt("survival_wait_shops") && lethalbeats\survival\utility::level_get_wave() < waveTarget)
	{
		for(;;)
		{
			level waittill("wave_end");
			if (level.wave_num >= waveTarget) break;
		}
	}
	
	shopModel[0] lethalbeats\hud::hud_create_3d_objective("allies", wayPoint, 12, 12);
	shopModel[1] setModel("com_laptop_2_open");
	trigger = lethalbeats\trigger::trigger_create(origin, 55);
	trigger lethalbeats\trigger::trigger_set_use("Press ^3[{+activate}] ^7to use " + hintString);
	trigger lethalbeats\trigger::trigger_set_enable_condition(lethalbeats\survival\utility::survivor_trigger_filter);
	trigger.tag = type;

	return [shopModel[0], shopModel[1], trigger];
}

spawnShopModel(origin, angles)
{
	if (!isDefined(angles)) angles = (0, 0, 0);
	
	crate = spawn("script_model", (0, 0, 0));
	crate setModel("com_plasticcase_friendly");
	crate CloneBrushmodelToScriptmodel(level.airDropCrateCollision);
	crate.angles = (0, 0, 0);
	
	laptop = spawn("script_model", (0, 0, 14));
	laptop setModel("com_laptop_2_close");
	laptop.angles = (0, 90, 0);
	laptop linkTo(crate);

	crate.origin = origin - (0, 0, 2);
	crate.angles = angles;
	return [crate, laptop];
}

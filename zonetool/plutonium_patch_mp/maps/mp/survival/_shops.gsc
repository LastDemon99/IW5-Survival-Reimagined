#include common_scripts\utility;
#include maps\mp\_utility;

init()
{	
	precacheShader("specialty_self_revive");
	precacheShader("specops_ui_equipmentstore");
	precacheShader("specops_ui_weaponstore");
	precacheShader("specops_ui_airsupport");
	
	level.shopZones = [];	//[weapon_origin, weapon_angles, equipment_origin, equipment_angles, support_origin, support_angles]
	level.shopZones["mp_dome"] = [(75, -365, -376), 24, (-1478, 1087, -413), -66, (435, 2470, -240), -95];
	
	map = getDvar("mapname");	
	if (isDefined(level.shopZones[map]))
	{
		zones = level.shopZones[map];
		level thread spawnShop(zones[0], zones[1], "weapon");
		level thread spawnShop(zones[2], zones[3], "equipment");
		level thread spawnShop(zones[4], zones[5], "support");
			
	}
}

spawnShop(origin, yrot, type)
{
	level endon("game_ended");
	
	shopModel = spawnShopModel(origin, yrot);
	
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
	
	if (getDvarInt("await_shops"))
	{
		for(;;)
		{
			level waittill("wave_end");		
			if (level.wave_num + 1 >= waveTarget) break;
		}
	}
	
	shopModel[1] setModel("com_laptop_2_open");
	
	trigger = maps\mp\lethalbeats\_trigger::createTrigger(type + "_shop", origin, 0, 55, 55, "Hold ^3[{+activate}] ^7to use " + hintString, "allies");
	trigger maps\mp\lethalbeats\_trigger::set3DIcon("allies", wayPoint, 12, 12, shopModel[0]);
}

spawnShopModel(origin, yRot)
{
	if (!isDefined(yRot)) yRot = 0;
	
	crate = spawn("script_model", origin);
	crate setModel("com_plasticcase_friendly");
	crate CloneBrushmodelToScriptmodel(level.airDropCrateCollision);
	crate.angles = (0, yRot, 0);
	
	laptop = spawn("script_model", origin + (0, 0, 14));
	laptop.angles = (0, yRot + 90, 0);
	laptop setModel("com_laptop_2_close");
	return [crate, laptop];
}
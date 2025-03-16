#include common_scripts\utility;
#include maps\mp\_utility;

init()
{
	level.shopZones = [];	//[weapon_origin, weapon_angles, equipment_origin, equipment_angles, air_support_origin, air_support_angles]
	level.shopZones["mp_dome"] = [(75, -365, -376), (0, 24, 0), (-1478, 1087, -413), (0, -66, 0), (435, 2470, -240), (0, -95, 0)];
	level.shopZones["mp_mogadishu"] = [(1825, 1785, 21), (0, 110, -5), (-510, -485, -30), (-4, 0, 4), (-285, 2595, 100), (0, 170, 0)];
	level.shopZones["mp_bootleg"] = [(-400, 172, -55), (0, 180, 0), (-253, 1630, -82), (0, 90, 0), (-202, -1333, -51), (-1, -90, 0)];
	level.shopZones["mp_lambeth"] = [(857, 2590, -263), (0, -90, 0), (335, 30, -227), (0, 90, 0), (2575, 565, -281), (0, -90, 0)];
	level.shopZones["mp_hardhat"] = [(1660, 460, 197), (0, 90, 0), (-244, 630, 391.5), (0, -25, -8), (1008, -830, 320), (0, 90, -5)];
	level.shopZones["mp_interchange"] = [(1925, -1668, 94), (0, -40, 0), (890, 445, 76), (-5, 3, 0), (-380, 532, 80), (0, -140, 0)];
	level.shopZones["mp_alpha"] = [(107, 1375, 5), (-2, 110, 0), (-1904, 1660, 13), (0, -90, 0), (-352, -370, 14), (0, 0, 0)];
	level.shopZones["mp_bravo"] = [(-1468, -245, 970), (7, 135, 0), (55, -340, 971), (-6, 180, 0), (1313, 1180, 1235), (0, 180, 0)];
	level.shopZones["mp_plaza2"] = [(-616, -95, 813), (0, 90, 0), (158, 1598, 622), (0, -134, 0), (-230, -1491, 622), (0, 0, 0)];
	level.shopZones["mp_exchange"] = [(-249, -1970, 50), (0, 360, 0), (2375, 496, 88), (0, 180, 0), (-415, 420, 243), (0, 180, 0)];
	level.shopZones["mp_carbon"] = [(-1080, -4040, 3802), (5, 180, 0), (-3928, -3122, 3630), (0, 180, 0), (765, -3380, 3963), (0, 107, 0)];
	level.shopZones["mp_paris"] = [(1540, 645, -2), (0, -90, 0), (576, 1946, -16), (0, -87, 0), (-788, 62, 70), (0, 180, 0)];
	level.shopZones["mp_radar"] = [(-3785, 2098, 1177), (0, 180, 0), (-4570, 4540, 1222), (0, 180, 0), (-7467, 3520, 1375), (0, -90, 0)];
	level.shopZones["mp_seatown"] = [(-455, 490, 180), (0, 90, 0), (67, -1507, 222), (0, 0, 0), (896, 233, 221), (0, 225, 0)];
	level.shopZones["mp_underground"] = [(525, 57, -116), (0, 90, 0), (-520, 3330, -114), (0, 135, 0), (33, -1429, 31), (0, 0, 0)];
	level.shopZones["mp_village"] = [(1267, 450, 301), (0, 110, 0), (35, 910, 278), (0, -50, 0), (-242, -1469, 210), (0, -10, 0)];
	//level.shopZones["mp_terminal_cls"] = [(2430, 4908, 206), (0, 0, 0), (440, 6016, 206), (0, 90, 0), (), ()];

	//level.shopZones[""] = [(), (), (), (), (), ()];

	level.juggDrop["mp_dome"] = [(-230, 1590, -282), (-553, 164, -408), (838, -416, -387), (117, 1037, -294), (-563, 1132, -307)];
	level.juggDrop["mp_mogadishu"] = [(-165, 3150, 90), (1630, -270, -45), (1527, -1200, -37), (-100, -1000, -35), (-850, -320, -30), (808, 524, -35)];
	level.juggDrop["mp_bootleg"] = [(85, -1180, -65), (900, -1170, -60), (-350, -2130, 8), (-1725, -1390, 10), (-570, 1480, -95)];
	level.juggDrop["mp_lambeth"] = [(-928, -953, -187), (-718, 1479, -249), (1301, 2493, -264), (774, 261, -337), (1848, 832, -315)];
	level.juggDrop["mp_hardhat"] = [(15, 1058, 384), (-659, -257, 202), (1919, -944, 299), (1199, 1265, 326), (-190, 778, 384)];
	level.juggDrop["mp_interchange"] = [(1130, -2788, 128), (424, -2142, 168), (2440, -298, 95), (774, 1755, 62), (-1105, 950, -28)];
	level.juggDrop["mp_alpha"] = [(-260, 1342, 0), (42, 2229, 0), (-1420, 2630, 126), (655, -306, 0)];
	level.juggDrop["mp_bravo"] = [(-29, -129, 1229), (1549, -541, 1177), (-733, 1285, 1217), (1833, -169, 1109), (-802, 766, 1220)];
	level.juggDrop["mp_plaza2"] = [(840, -1877, 616), (-311, 2084, 788), (-1357, 1196, 783), (-34, 1487, 616)];
	level.juggDrop["mp_exchange"] = [(666, -1277, 35), (-666, 1227, 64), (142, 1225, 91), (2545, 1253, 88), (976, 1272, 69)];
	level.juggDrop["mp_carbon"] = [(-195, -4565, 3923), (-1722, -4673, 3761), (-2615, -4639, 3724), (-3727, -3688, 3577), (-3317, -2782, 3754), (-138, -2920, 3938)];
	level.juggDrop["mp_paris"] = [(-2079, 1519, 265), (1646, 629, -7), (-1589, 17, 198), (-1521, 1609, 256)];
	level.juggDrop["mp_radar"] = [(-7136, 4583, 1318), (-7348, 2929, 1302), (-3352, 1030, 1170), (-3328, 213, 1171), (-5663, 4340, 1315), (-4205, 4071, 1216)];
	level.juggDrop["mp_seatown"] = [(-525, -817, 208), (-2286, -273, 196), (-2407, 433, 196), (-1104, 1417, 244), (-1309, -1491, 152)];
	level.juggDrop["mp_underground"] = [(142, -691, 8), (-286, -685, 8), (-1533, 1275, -247), (-631, 3151, -119), (703, 2250, -95)];
	level.juggDrop["mp_village"] = [(45, 1437, 272), (-572, 1932, 263), (622, 2269, 293), (628, 1615, 288), (1721, -505, 237), (1039, -774, 294), (-758, -635, 340)];

	map = getDvar("mapname");	
	if (isDefined(level.shopZones[map]))
	{
		zones = level.shopZones[map];
		level thread spawnShop(zones[0], zones[1], "weapon");
		level thread spawnShop(zones[2], zones[3], "equipment");
		level thread spawnShop(zones[4], zones[5], "support");
	}
}

spawnShop(origin, angles, type)
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
	
	if (getDvarInt("survival_wait_shops"))
	{
		for(;;)
		{
			level waittill("wave_end");		
			if (level.wave_num + 1 >= waveTarget) break;
		}
	}
	
	shopModel[1] setModel("com_laptop_2_open");
	
	trigger = lethalbeats\_trigger::createTrigger(type + "_shop", origin, 0, 55, 55, "Hold ^3[{+activate}] ^7to use " + hintString, "allies");
	trigger lethalbeats\_trigger::set3DIcon("allies", wayPoint, 12, 12, shopModel[0]);
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

	crate.origin = origin;
	crate.angles = angles;
	return [crate, laptop];
}

#include maps\mp\_utility;
#include lethalbeats\survival\_utility;

init()
{
    game["menu_team"] = "custom_options";
    game["menu_class_axis"] = "custom_options";
    game["menu_class_allies"] = "custom_options";
}

shopTrigger()
{
	self endon("disconnect");
	level endon("game_ended");
	self endon("death");
	
	for (;;)
	{
		self waittill("trigger_use", trigger);
		if (isDefined(self.currMenu)) continue;
		if (trigger.tag == "weapon_shop") self lethalbeats\DynamicMenus\dynamic_shop::openShop("weapon_armory");
		else if (trigger.tag == "equipment_shop") self lethalbeats\DynamicMenus\dynamic_shop::openShop("equipment_armory");
		else if (trigger.tag == "support_shop") self lethalbeats\DynamicMenus\dynamic_shop::openShop("air_support_armory");
	}
}

initHudMessage()
{
	precacheString(&"MP_FIRSTPLACE_NAME");
	precacheString(&"MP_SECONDPLACE_NAME");
	precacheString(&"MP_THIRDPLACE_NAME");
	precacheString(&"MP_MATCH_BONUS_IS");

    precachemenu("perk_display");
    precachemenu("perk_hide");
    precachemenu("killedby_card_hide");

	game["menu_endgameupdate"] = "endgameupdate";
	precacheMenu(game["menu_endgameupdate"]);

	game["strings"]["draw"] = &"MP_DRAW";
	game["strings"]["round_draw"] = &"MP_ROUND_DRAW";
	game["strings"]["round_win"] = &"MP_ROUND_WIN";
	game["strings"]["round_loss"] = &"MP_ROUND_LOSS";
	game["strings"]["victory"] = &"MP_VICTORY";
	game["strings"]["defeat"] = &"MP_DEFEAT";
	game["strings"]["halftime"] = &"MP_HALFTIME";
	game["strings"]["overtime"] = &"MP_OVERTIME";
	game["strings"]["roundend"] = &"MP_ROUNDEND";
	game["strings"]["intermission"] = &"MP_INTERMISSION";
	game["strings"]["side_switch"] = &"MP_SWITCHING_SIDES";
	game["strings"]["match_bonus"] = &"MP_MATCH_BONUS_IS";
	
	level thread maps\mp\gametypes\_hud_message::onPlayerConnect();
}

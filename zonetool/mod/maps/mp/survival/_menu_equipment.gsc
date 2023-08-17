#include maps\mp\_utility;
#include maps\mp\dynamic_menu_utility;
#include maps\mp\survival\_utility;

onMenuResponse()
{
    level endon("game_ended");
    self endon("disconnect");
	self endon("death");

    for (;;)
    {
        self waittill("menuresponse",  menu, response);
		
		if (menu != "shop_menu" || !isDefined(self.currMenu)) continue;
		if (self.currMenu != "equipment_shop") continue;
		
		page_data = self getPageData();		
		currPage = page_data[3];		
		
		if (str(response) == "back")
		{
			self _popPage();
			continue;
		}
		
		response = int(response);
		selected = tableLookupByRow("mp/equipment_shop.csv", response + page_data[1], 2);
		cost = int(tableLookupByRow("mp/equipment_shop.csv", response + page_data[1], 3));
		
		if(currPage == "main" && self hasMoney(cost, response))
		{
			if(response < 6)
			{
				self addNades(selected, 5);				
				if(!(self hasWeapon(selected)))
				{
					self giveweapon(selected);
					self _setActionSlot(response == 4 ? 1 : 5, "weapon", selected);
				}
			}
			else if(response == 6)
			{
				self giveweapon(selected);
				self _setActionSlot(4, "weapon", selected);
				self setClientDvar("ui_streak", "hud_icon_trophy");
				level.sentry++;
			}
			else if (response == 7)
			{
				self.bodyArmor = 250;
				self setClientDvar("ui_body_armor", 1);
			}
			else if (response == 8)
			{
				self.hasRevive = 1;
				self setClientDvar("ui_self_revive", 1);
				self givePerk("specialty_finalstand", false);
			}
			
			self setScore(self.score - cost);
			self checkOwnedEquipment();
			self playLocalSound("mp_ingame_summary");
		}
	}
}

checkOwnedEquipment()
{
	self loadItemCost();
	for(i = 0; i < self getPageData()[2]; i++) self hasMoney(int(tableLookupByRow("mp/equipment_shop.csv", i + 1, 3)), i);
	for(i = 0; i < 6; i++)
	{
		nade = tableLookupByRow("mp/equipment_shop.csv", i + 1, 2);
		if (self.grenades[nade] == getNadeMaxAmmmo(nade)) self setOwned(i);
	}
	if (self.bodyArmor == 250) self setOwned(7);
	if (self.hasRevive) self setOwned(8);
	if (level.sentry >= 3 || self.pers["killstreaks"].size == 6 || self hasWeapon("trophy_mp")) self setDisabled(6);
}
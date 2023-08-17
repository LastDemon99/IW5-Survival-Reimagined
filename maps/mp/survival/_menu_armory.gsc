#include maps\mp\_utility;
#include maps\mp\lethalbeats\_dynamic_menu;
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
		if (self.currMenu != "weapon_shop") continue;
		
		page_data = self getPageData();	
		currPage = page_data[3];
		
		if (str(response) == "back")
		{
			self _popPage();
			if (isSubStr(currPage, "_buff")) self checkOwnedWeapon();
			continue;
		}
		
		response = int(response);
		
		if(currPage == "main")
		{		
			pages_name = getarraykeys(level.dynamicMenu["weapon_shop"]);			
			self _pushPage(pages_name[response + 3]);
			
			if(response) self checkOwnedWeapon();
			else self checkOwnedAmmo();
			continue;
		}
		
		if(currPage == "ammo")
		{
			weapon = self getWeaponsListPrimaries()[response];
			self setScore(self.score - int(tableLookup("mp/weapon_shop.csv", 2, getWeaponClass(weapon), 3)));
			self giveMaxAmmo(weapon);
			self setWeaponAmmoClip(weapon, weaponClipSize(weapon));
			self checkOwnedAmmo();
			self playLocalSound("mp_ingame_summary");
			continue;
		}
		
		selected = tableLookupByRow("mp/weapon_shop.csv", response + page_data[1], 2);
		
		if (isSubStr(currPage, "weapon_"))
		{	
			wepList = self getWeaponsListPrimaries();
			
			baseWeapon0 = getBaseWeaponName(wepList[0]);
			baseWeapon1 = isDefined(wepList[1]) ? getBaseWeaponName(wepList[1]) : "none";
			
			if(baseWeapon0 != selected && baseWeapon1 != selected)
			{
				if(baseWeapon1 != "none") self takeWeapon(self getCurrentWeapon());
				
				weapon = maps\mp\gametypes\_class::buildWeaponName(selected, "none", "none", 0, 0);
				
				self setScore(self.score - int(tableLookupByRow("mp/weapon_shop.csv", response + page_data[1], 3)));
				self _giveWeapon(weapon);
				self switchToWeaponImmediate(weapon);
				self checkOwnedWeapon();
				self playLocalSound("mp_ingame_summary");
			}
			continue;
		}
	}
}

checkOwnedAmmo()
{
	wepList = self getWeaponsListPrimaries();	
	checkAmmoCost(0, wepList[0]);	
	if(!isDefined(wepList[1]))
	{
		self setClientDvar("optionType1", 0);
		return;
	}	
	checkAmmoCost(1, wepList[1]);
}

checkAmmoCost(option, weapon)
{
	table = "mp/weapon_shop.csv";
	weapon_base = getBaseWeaponName(weapon);
	weapon_class = getWeaponClass(weapon_base);
	cost = int(tableLookup(table, 2, weapon_class, 3));
	
	self hasMoney(cost, option);	
	self setClientDvar("menu_option" + (option + 10), cost);	
	self setClientDvar("menu_option" + option, tableLookup(table, 2, weapon_base, 1));
	
	if(weapon_class == "weapon_riot" || (self getFractionMaxAmmo(weapon) == 1 && self getWeaponAmmoClip(weapon) == weaponClipSize(weapon))) self setOwned(option);
}

checkOwnedWeapon()
{
	wepList = self getWeaponsListPrimaries();
	page_data = self getPageData();
	table = "mp/weapon_shop.csv";
	
	wepList[0] = getBaseWeaponName(wepList[0]);
	wepList[1] = isDefined(wepList[1]) ? getBaseWeaponName(wepList[1]) : "none";
	
	for(i = 0; i < page_data[2]; i++)
	{
		if (!self hasMoney(int(tableLookupByRow(table, i + page_data[1], 3)), i)) continue;
		
		target = tableLookupByRow(table, i + page_data[1], 2);
		
		if (wepList[0] == target || wepList[1] == target) self setOwned(i);
		else self clearBuy(i);
	}
}
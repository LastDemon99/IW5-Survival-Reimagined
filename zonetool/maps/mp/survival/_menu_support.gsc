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
		if (self.currMenu != "support_shop") continue;
		
		page_data = self getPageData();		
		currPage = page_data[3];
		
		if (str(response) == "back")
		{
			self _popPage();
			if (currPage != "main") self checkAllowedSupport();
			continue;
		}
		
		response = int(response);
		selected = tableLookupByRow("mp/support_shop.csv", response + page_data[1], 2);
		cost = int(tableLookupByRow("mp/support_shop.csv", response + page_data[1], 3));
		
		if(currPage == "main" && self hasMoney(cost, response))
		{
			if (selected == "perks" || selected == "remove_perks")
			{
				self _pushPage(selected);
				self checkAllowedSupport();
				continue;
			}
			else
			{
				if (response == 5) level notify("survivor_respawn");
				if (response > 2)
				{
					self thread [[level.giveAirdrop]](selected);
					level.sentry++;
				}
				else 
				{
					self maps\mp\killstreaks\_killstreaks::giveKillstreak(selected);
					if (selected == "precision_airstrike") self thread onConfirmLocation();
				}					
				self setClientDvar("ui_streak", tableLookupByRow("mp/support_shop.csv", response + page_data[1], 7));
			}
			
			self setScore(self.score - cost);
			self checkAllowedSupport();
			self setOwned(response);
			self playLocalSound("mp_ingame_summary");
			continue;
		}
		
		if(currPage == "perks" && self hasMoney(cost, response))
		{
			self thread [[level.giveAirdrop]](selected);
			self setClientDvar("ui_streak", "dpad_killstreak_carepackage");
			
			self setScore(self.score - cost);
			self checkAllowedSupport();
			self setOwned(response);
			self playLocalSound("mp_ingame_summary");
			continue;
		}
		
		if(currPage == "remove_perks" && self hasMoney(cost, response))
		{
			self removeSurvivalPerk(selected);
			self setScore(self.score - cost);
			self checkAllowedSupport();
			self setDisabled(response);
			self playLocalSound("mp_ingame_summary");
		}
	}
}

onConfirmLocation()
{
	self waittill("confirm_location");
	self setClientDvar("ui_streak", "");
}

checkAllowedSupport()
{
	self loadItemCost();
	
	table = "mp/support_shop.csv";
	page_data = self getPageData();
	startIndex = page_data[1];
	range = page_data[2];
	page = page_data[3];
	
	for(i = 0; i < range; i++) 
	{
		row = i + startIndex;
		self hasMoney(int(tableLookupByRow(table, row, 3)), i);
		if (page == "remove_perks" && !(self _hasPerk(tableLookupByRow(table, row, 2)))) self setDisabled(i);
		else if ((tableLookupByRow(table, row, 2) == "minigun_turret" || tableLookupByRow(table, row, 2) == "gl_turret") && level.sentry >= 3) self setDisabled(i);
		else if (tableLookupByRow(table, row, 2) == "revive_players" && !hasSurvivorDeath()) self setDisabled(i);
		else if (self hasStreak() && tableLookupByRow(table, row, 6) != "") self setDisabled(i);
	}
}

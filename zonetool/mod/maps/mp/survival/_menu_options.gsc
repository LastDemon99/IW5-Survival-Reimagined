#include maps\mp\_utility;
#include maps\mp\dynamic_menu_utility;
#include maps\mp\survival\_utility;

onMenuResponse()
{
    level endon("game_ended");
    self endon("disconnect");

    for (;;)
    {
        self waittill("menuresponse",  menu, response);
		
		if (menu == "survival_hud" && response == "back")
		{
			self openDynamicMenu("main_options");
			self notify("hide_hud");
			continue;
		}
		
		if (menu != "custom_options" || !isDefined(self.currMenu)) continue;
		if (self.currMenu != "main_options") continue;
		
		page_data = self getPageData();		
		currPage = page_data[3];		
		
		if (str(response) == "back")
		{
			if (self.pers["menu_pages"].size == 1)
			{
				self closeDynamicMenu();
				waitmenu();
				self _openMenu("survival_hud");
				self notify("show_hud");
				continue;
			}
			self _popPage();
			continue;
		}
		
		response = int(response);
		
		if(currPage == "main")
		{
			if (response == 2) self _openMenu("pc_options_video_ingame");
			else if (response == 3) self _openMenu("muteplayer");
			else if (response == 6) self _openMenu("popup_leavegame");
			else
			{
				selected = tableLookupByRow("mp/main_options.csv", response + page_data[1], 2);
				if(selected != "") self _pushPage(selected, response);
			}
		}
	}
}
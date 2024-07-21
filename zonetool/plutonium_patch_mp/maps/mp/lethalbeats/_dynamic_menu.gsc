#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\survival\_utility;

openDynamicMenu(menu)
{
	self setClientDvar("ui_startIndex", -1);
	self.currMenu = menu;
	self.pers["menu_pages"] = [];
	self pushPage("main");
	self _openMenu(level.dynamicMenu[self.currMenu]["_menu_"]);
}

closeDynamicMenu()
{
	self _closeMenu(level.dynamicMenu[self.currMenu]["_menu_"]);
	self.currMenu = undefined;
	self.prevResponse = undefined;
	self.pers["menu_pages"] = [];
}

getPage(count)
{
	count = isDefined(count) ? count + 1 : 1;
	return self.pers["menu_pages"][self.pers["menu_pages"].size - count];
}

getPageData(count)
{
	return level.dynamicMenu[self.currMenu][self getPage(count)];
}

pushPage(page, selected)
{
	if(isDefined(selected)) self.prevResponse = selected;
	else self.prevResponse = undefined;
	
	self.pers["menu_pages"][self.pers["menu_pages"].size] = page;	
	self setPage(page);
}

popPage()
{
	if (self.pers["menu_pages"].size == 1)
	{
		self closeDynamicMenu();
		return;
	}
	if (!isDefined(self.pers["menu_pages"]) || self.pers["menu_pages"].size < 1) return;
	
	newMenuPages = [];	
	for (i = 0; i < self.pers["menu_pages"].size - 1; i++)
		newMenuPages[i] = self.pers["menu_pages"][i];
	
	self.pers["menu_pages"] = newMenuPages;	
	self setPage(self getPage());
}

setPage(page)
{
	pages = level.dynamicMenu[self.currMenu];
	page_data = pages[page];
	table = "mp/" + self.currMenu + ".csv";
	start_index = page_data[1];
	range = page_data[2];
	
	self setClientDvar("menu_title", "@" + page_data[0]);
	self setClientDvar("menu_table", table);
	self setClientDvar("menu_options_start", start_index);
	self setClientDvar("menu_options_range", range);
	
	for(i = 0; i < 20; i++)
	{
		self setClientDvar("optionType" + i, 4);
		if(i < range) self setClientDvar("menu_option" + i, "@" + tableLookupByRow(table, i + start_index, 1));
		else self setClientDvar("menu_option" + i, "");
	}
	
	/*
	if (isDefined(self.prevResponse))
	{
		prevOption = tableLookupByRow(table, self.prevResponse + start_index, 1);
		print(prevOption);
		
		if (prevOption == "" || prevOption == "-" || range <= self.prevResponse)
			self setClientDvar("ui_index", -1);
	}*/
}

loadMenuData(menu, table)
{
	menu_data = [];
	menu_data["_menu_"] = menu;
	menu_data["_table_"] = table;	
	
	table = "mp/" + table + ".csv";
	page = tableLookupByRow(table, 0, 2);
	menu_data[page] = [tableLookupByRow(table, 0, 1), 1];
	
	for (row = 0; tableLookupByRow(table, row, 0) != ""; row++)
		if(tableLookupByRow(table, row, 1) == "")
		{
			menu_data[page][2] = row - menu_data[page][1];
			menu_data[page][3] = page;
			
			if(tableLookupByRow(table, row + 1, 1) != "")
			{
				page = tableLookupByRow(table, row + 1, 2);
				menu_data[page] = [tableLookupByRow(table, row + 1, 1), row + 2];
			}
		}
		
	level.dynamicMenu[menu_data["_table_"]] = menu_data;
}
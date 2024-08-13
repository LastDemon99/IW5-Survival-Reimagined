
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\lethalbeats\utility;
#include maps\lethalbeats\weapons;
#include maps\lethalbeats\DynamicMenus\dynamic_shop;

#define TABLE "mp/survival_armories.csv"
#define WEAPON_PAGES ["pistols", "shotguns", "machine_pistols", "smgs", "assaults", "lmgs", "snipers", "projectiles", "riots"]

#define NULL_PAGE 0
#define WEAPON_ARMORY 1
#define WEAPON_SELECT 2
#define WEAPON_PISTOLS 3
#define WEAPON_ATTACHS 4

init()
{
    level.onOpenShop = ::onOpenShop;
    level.getShopStock = ::getShopStock;
    level.isUpgradeAvailable = ::isUpgradeAvailable;
    level.getUpgradeMenu = ::getUpgradeMenu;
    level.isOwnedItem = ::isOwnedItem;
    level.isDisabledItem = ::isDisabledItem;
    level.onBuy = ::onBuy;

    maps\lethalbeats\weapons::init();
}

onOpenShop(menu)
{
    self maps\mp\survival\_utility::setScore(100000);

    if (menu == "weapon_armory")
    {
        self maps\mp\survival\_weapon_armory::init(menu);
        return;
    }

    if (!isDefined(self.shop)) self.shop = spawnstruct();

    if (array_contain(WEAPON_PAGES, menu)) self.shop.page = WEAPON_SELECT;
    else if (string_end_with(menu, "attach")) self.shop.page = WEAPON_ATTACHS;
}

onBuy(page, item, price)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            self.shop maps\mp\survival\_weapon_armory::onBuy(item);
            break;
    }    
    buyItem(price);
}

isDisabledItem(page, item)
{
    return false;
}

isOwnedItem(page, item)
{
    return false;
}

isUpgradeAvailable(page, item)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            return self.shop maps\mp\survival\_weapon_armory::isUpgradeAvailable(item);
        default:
            return false;
    }
}

getShopStock(page)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            return self.shop maps\mp\survival\_weapon_armory::getShopStock();
        default:
            return 0;
    }
}

getUpgradeMenu(page, item)
{
    if (self.shop.menu == WEAPON_ARMORY)
        return self.shop maps\mp\survival\_weapon_armory::getUpgradeMenu(item);
    return "";
}

buyItem(price)
{
	self maps\mp\survival\_utility::setScore(self.score - price);
}

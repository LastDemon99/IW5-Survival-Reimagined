
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\lethalbeats\DynamicMenus\dynamic_shop;

// OPTION TYPE
#define OPTION_BUY -5
#define OPTION_DISABLE -4
#define OPTION_OWNED -3
#define OPTION_UPGRADE -2
#define OPTION_SCRIPTRESPONSE -1

// ARMORY MENUS
#define PAGE_NULL -1
#define WEAPON_ARMORY 0
#define WEAPON_EQUIPMENT 1
#define WEAPON_AIR_SUPPORT 2

init()
{
    level.onOpenPage = ::onOpenPage;
    level.onSelectOption = ::onSelectOption;
    level.onUpdateOption = ::onUpdateOption;
    level.isUpgradeOption = ::isUpgradeOption;
    level.isOwnedOption = ::isOwnedOption;
    level.isDisabledOption = ::isDisabledOption;

    maps\lethalbeats\weapons::init();
}

onOpenPage(menu)
{
    self maps\mp\survival\_utility::setScore(100000);

    if (menu == "weapon_armory")
    {
        self shopInit(WEAPON_ARMORY);
        self.shop maps\mp\survival\_armory_weapons::onInit();
        return;
    }

    if (!isDefined(self.shop.menu)) return;

    if (self.shop.menu == WEAPON_ARMORY)
    {
        self.shop maps\mp\survival\_armory_weapons::onOpenPage(menu);
        return;
    }
}

onSelectOption(page, item, price, option_type)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            self.shop maps\mp\survival\_armory_weapons::onSelectOption(page, item, price, option_type);
            break;
    }
}

onUpdateOption(index, item, option_label, price_label)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            self.shop maps\mp\survival\_armory_weapons::onUpdateOption(index, item, option_label, price_label);
            break;
    }
}

isDisabledOption(page, item)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            return self.shop maps\mp\survival\_armory_weapons::isDisabledOption(item);
        default:
            return false;
    }
}

isOwnedOption(page, item)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            return self.shop maps\mp\survival\_armory_weapons::isOwnedOption(item);
        default:
            return false;
    }
}

isUpgradeOption(page, item)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            return self.shop maps\mp\survival\_armory_weapons::isUpgradeOption(item);
        default:
            return false;
    }
}

#include common_scripts\utility;
#include maps\mp\_utility;
#include lethalbeats\DynamicMenus\dynamic_shop;

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

    lethalbeats\weapons::init();
    lethalbeats\survival\armory\_spawn::init();
}

//////////////////////////////////////////
//	            HANDLERS   		        //
//////////////////////////////////////////

onOpenPage(menu)
{
    self lethalbeats\survival\_utility::setScore(100000);

    if (menu == "weapon_armory")
    {
        self shopInit(WEAPON_ARMORY);
        self.shop lethalbeats\survival\armory\weapons::onInit();
        return;
    }

    if (menu == "equipment_armory")
    {
        self shopInit(WEAPON_EQUIPMENT);
        return;
    }

    if (menu == "air_support_armory")
    {
        self shopInit(WEAPON_AIR_SUPPORT);
        self.shop lethalbeats\survival\armory\air_support::onInit();
        return;
    }

    if (!isDefined(self.shop.menu)) return;

    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            self.shop lethalbeats\survival\armory\weapons::onOpenPage(menu);
            break;
        case WEAPON_AIR_SUPPORT:
            self.shop lethalbeats\survival\armory\air_support::onOpenPage(menu);
            break;
    }
}

onSelectOption(page, item, price, option_type)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            self.shop lethalbeats\survival\armory\weapons::onSelectOption(page, item, price, option_type);
            break;
        case WEAPON_EQUIPMENT:
            self lethalbeats\survival\armory\equipment::onBuy(item, price);
            break;
        case WEAPON_AIR_SUPPORT:
            self.shop lethalbeats\survival\armory\air_support::onSelectOption(page, item, price, option_type);
            break;
    }
}

onUpdateOption(index, item, option_label, price_label)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            self.shop lethalbeats\survival\armory\weapons::onUpdateOption(index, item, option_label, price_label);
            break;
        case WEAPON_EQUIPMENT:
            self updateOption(index, item, option_label, price_label);
            break;
        case WEAPON_AIR_SUPPORT:
            self.shop lethalbeats\survival\armory\air_support::onUpdateOption(index, item, option_label, price_label);
            break;
    }
}

//////////////////////////////////////////
//	           OPTION STATES  		    //
//////////////////////////////////////////

isOwnedOption(page, item)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            return self.shop lethalbeats\survival\armory\weapons::isOwnedOption(item);
        case WEAPON_EQUIPMENT:
            return self lethalbeats\survival\armory\equipment::isOwnedOption(item);
        case WEAPON_AIR_SUPPORT:
            return self.shop lethalbeats\survival\armory\air_support::isOwnedOption(item);
        default:
            return false;
    }
}

isDisabledOption(page, item)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            return self.shop lethalbeats\survival\armory\weapons::isDisabledOption(item);
        case WEAPON_AIR_SUPPORT:
            return self.shop lethalbeats\survival\armory\air_support::isDisabledOption(item);
        default:
            return false;
    }
}

isUpgradeOption(page, item)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            return self.shop lethalbeats\survival\armory\weapons::isUpgradeOption(item);
        default:
            return false;
    }
}

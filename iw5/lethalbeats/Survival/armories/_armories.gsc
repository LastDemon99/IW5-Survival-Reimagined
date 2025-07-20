#include common_scripts\utility;
#include maps\mp\_utility;
#include lethalbeats\dynamicmenus\dynamic_shop;

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

//////////////////////////////////////////
//	            HANDLERS   		        //
//////////////////////////////////////////

init()
{
	precacheShader("specialty_self_revive");
	precacheShader("specops_ui_equipmentstore");
	precacheShader("specops_ui_weaponstore");
	precacheShader("specops_ui_airsupport");

    level.onOpenPage = ::onOpenPage;
    level.onSelectOption = ::onSelectOption;
    level.onUpdateOption = ::onUpdateOption;
    level.isUpgradeOption = ::isUpgradeOption;
    level.isOwnedOption = ::isOwnedOption;
    level.isDisabledOption = ::isDisabledOption;
    
    thread lethalbeats\Survival\armories\_spawn::init();
}

onOpenPage(menu)
{
    if (menu == "weapon_armory")
    {
        self shopInit(WEAPON_ARMORY);
        self.shop lethalbeats\survival\armories\weapons::onInit();
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
        self.shop lethalbeats\survival\armories\air_support::onInit();
        return;
    }

    if (!isDefined(self.shop.menu)) return;

    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            self.shop lethalbeats\survival\armories\weapons::onOpenPage(menu);
            break;
        case WEAPON_AIR_SUPPORT:
            self.shop lethalbeats\survival\armories\air_support::onOpenPage(menu);
            break;
    }
}

onSelectOption(page, item, price, option_type, index)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            self.shop lethalbeats\survival\armories\weapons::onSelectOption(page, item, price, option_type, index);
            break;
        case WEAPON_EQUIPMENT:
            self lethalbeats\survival\armories\equipment::onBuy(item, price, index);
            break;
        case WEAPON_AIR_SUPPORT:
            self.shop lethalbeats\survival\armories\air_support::onSelectOption(page, item, price, option_type, index);
            break;
    }
}

onUpdateOption(index, item, option_label, price_label)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            self.shop lethalbeats\survival\armories\weapons::onUpdateOption(index, item, option_label, price_label);
            break;
        case WEAPON_EQUIPMENT:
            self updateOption(index, item, option_label, price_label);
            break;
        case WEAPON_AIR_SUPPORT:
            self.shop lethalbeats\survival\armories\air_support::onUpdateOption(index, item, option_label, price_label);
            break;
    }
}

//////////////////////////////////////////
//	           OPTION STATES  		    //
//////////////////////////////////////////

isOwnedOption(page, item, index)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            return self.shop lethalbeats\survival\armories\weapons::isOwnedOption(item);
        case WEAPON_EQUIPMENT:
            return self lethalbeats\survival\armories\equipment::isOwnedOption(item, index);
        case WEAPON_AIR_SUPPORT:
            return self.shop lethalbeats\survival\armories\air_support::isOwnedOption(item);
        default:
            return false;
    }
}

isDisabledOption(page, item, index)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            return self.shop lethalbeats\survival\armories\weapons::isDisabledOption(item, index);
        case WEAPON_AIR_SUPPORT:
            return self.shop lethalbeats\survival\armories\air_support::isDisabledOption(item, index);
        default:
            return false;
    }
}

isUpgradeOption(page, item, index)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            return self.shop lethalbeats\survival\armories\weapons::isUpgradeOption(item);
        default:
            return false;
    }
}

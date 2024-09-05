#include common_scripts\utility;
#include maps\mp\_utility;
#include lethalbeats\survival\_utility;
#include lethalbeats\DynamicMenus\dynamic_shop;

// OPTION TYPE
#define OPTION_BUY -5
#define OPTION_DISABLE -4
#define OPTION_OWNED -3
#define OPTION_UPGRADE -2
#define OPTION_SCRIPTRESPONSE -1

// AIR SUPPORT ARMORY PAGE
#define PAGE_NULL -1
#define AIR_SUPPORT_MAIN 0
#define AIR_SUPPORT_PERKS 1
#define AIR_SUPPORT_REMOVE_PERKS 2

// OPTIONS INDEX
#define PREDATOR_MISSILE 1
#define PRECISION_AIRSTRIKE 2
#define MINIGUN_TURRET 3
#define GL_TURRET 4

#define QUICK_DRAW 0
#define BULLET_ACCURACY 1
#define STALKER 2
#define LONGER_SPRINT 3
#define FAST_RELOAD 4
#define BLAST_SHIELD 5

// self -> shop
// self.owner -> player

//////////////////////////////////////////
//	            HANDLERS   		        //
//////////////////////////////////////////

onInit()
{
    self.removeItem = false;
    self.page = AIR_SUPPORT_MAIN;
}

onOpenPage(page)
{
    removeItem = self.removeItem;
    self.removeItem = false;
    switch(page)
    {
        case "air_support_armory": self.page = AIR_SUPPORT_MAIN; break;
        case "perks_care_package":
            if (removeItem) self.page = AIR_SUPPORT_REMOVE_PERKS;
            else self.page = AIR_SUPPORT_PERKS;
            break;
    }
}

onSelectOption(page, item, price, option_type, index)
{
    if (option_type == OPTION_BUY) 
        self onBuy(item, price, index);
    else if (option_type == OPTION_SCRIPTRESPONSE)
        self onResponse(item);
}

onBuy(item, price, index)
{
    if (self.page == AIR_SUPPORT_REMOVE_PERKS)
    {
        self.owner removeSurvivalPerk(getPerkFromKsPerk(item));
        self.owner buyItem(price);
        return;
    }

    if (self.page == AIR_SUPPORT_MAIN)
    {
        if (index == MINIGUN_TURRET || index == GL_TURRET)
        {
            self.owner lethalbeats\survival\killstreaks\_airdrop::giveAirDrop(item);
            level.sentry++;
        }
        else self.owner maps\mp\killstreaks\_killstreaks::giveKillstreak(item);
        self.owner buyItem(price);
        return;
    }

    switch(index)
    {
        case QUICK_DRAW:
            self.owner lethalbeats\survival\killstreaks\_airdrop::giveAirDrop("perk_quickdraw");
            break;
        case BULLET_ACCURACY:
            self.owner lethalbeats\survival\killstreaks\_airdrop::giveAirDrop("perk_bulletaccuracy");
            break;
        case STALKER:
            self.owner lethalbeats\survival\killstreaks\_airdrop::giveAirDrop("perk_stalker");
            break;
        case LONGER_SPRINT:
            self.owner lethalbeats\survival\killstreaks\_airdrop::giveAirDrop("perk_longersprint");
            break;
        case FAST_RELOAD:
            self.owner lethalbeats\survival\killstreaks\_airdrop::giveAirDrop("perk_fastreload");
            break;
        case BLAST_SHIELD:
            self.owner lethalbeats\survival\killstreaks\_airdrop::giveAirDrop("perk_blastshield");
            break;
    }
    self.owner buyItem(price);
}

onResponse(item)
{
    if (item == "remove_perks") self.removeItem = true;
    self.owner openShop("perks_care_package");
    self.owner playLocalSound("mouse_click");
}

onUpdateOption(index, item, option_label, price_label)
{
    if (price_label == OPTION_BUY) 
    {
        price_label = getPrice(item);
        if (self.page == AIR_SUPPORT_REMOVE_PERKS) price_label *= getPrice("remove_perk_multiplier");
    }

    self.owner setOption(index, option_label);
    self.owner setPrice(index, price_label);
}

//////////////////////////////////////////
//	           OPTION STATES  		    //
//////////////////////////////////////////

isOwnedOption(item)
{
    if (self.page != AIR_SUPPORT_PERKS) return false;
    return self.owner _hasPerk(item);
}

isDisabledOption(item, index)
{
    switch(self.page)
    {
        case AIR_SUPPORT_MAIN:
            if (index == PREDATOR_MISSILE || index == PRECISION_AIRSTRIKE) return self.owner.pers["killstreaks"].size == 6;
            if (index == MINIGUN_TURRET || index == GL_TURRET) return level.sentry >= 3 || self.owner.pers["killstreaks"].size == 6;
            break;
        case AIR_SUPPORT_PERKS:
            return self.owner.pers["killstreaks"].size == 6;
        case AIR_SUPPORT_REMOVE_PERKS:
            return !(self.owner _hasPerk(getPerkFromKsPerk(item)));
    }
    return false;
}

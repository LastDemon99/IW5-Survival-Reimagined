#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\survival\_utility;
#include maps\lethalbeats\DynamicMenus\dynamic_shop;

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

// self -> shop
// self.owner -> player

/*
=========================
	HANDLERS
=========================
*/

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

onSelectOption(page, item, price, option_type)
{
    if (option_type == OPTION_BUY) 
        self onBuy(item, price);
    else if (option_type == OPTION_SCRIPTRESPONSE)
        self onResponse(page, item);
}

onBuy(item, price)
{
    if (self.page == AIR_SUPPORT_REMOVE_PERKS)
    {
        self.owner removeSurvivalPerk(getPerkFromKsPerk(item));
        self.owner buyItem(price);
        return;
    }

    switch(item)
    {
        case "specialty_quickdraw_ks":
            self.owner maps\mp\survival\_airdrop::giveAirDrop("perk_quickdraw");
            break;
        case "specialty_bulletaccuracy_ks":
            self.owner maps\mp\survival\_airdrop::giveAirDrop("perk_bulletaccuracy");
            break;
        case "specialty_stalker_ks":
            self.owner maps\mp\survival\_airdrop::giveAirDrop("perk_stalker");
            break;
        case "specialty_longersprint_ks":
            self.owner maps\mp\survival\_airdrop::giveAirDrop("perk_longersprint");
            break;
        case "specialty_fastreload_ks":
            self.owner maps\mp\survival\_airdrop::giveAirDrop("perk_fastreload");
            break;
        case "_specialty_blastshield_ks":
            self.owner maps\mp\survival\_airdrop::giveAirDrop("perk_blastshield");
            break;
        case "minigun_turret":
        case "gl_turret":
            self.owner maps\mp\survival\_airdrop::giveAirDrop(item);
            level.sentry++;
            break;
        default:
            self.owner maps\mp\killstreaks\_killstreaks::giveKillstreak(item);
            break;
    }
    self.owner buyItem(price);
}

onResponse(page, item)
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

/*
=========================
	OPTION STATES
=========================
*/

isOwnedOption(item)
{
    if (self.page != AIR_SUPPORT_PERKS) return false;
    return self.owner _hasPerk(item);
}

isDisabledOption(item)
{
    switch(self.page)
    {
        case AIR_SUPPORT_MAIN:
            if (item == "predator_missile" || item == "precision_airstrike") return self.owner.pers["killstreaks"].size == 6;
            if (item == "minigun_turret" || item == "gl_turret") return level.sentry >= 3 || self.owner.pers["killstreaks"].size == 6;
            break;
        case AIR_SUPPORT_PERKS:
            return self.owner.pers["killstreaks"].size == 6;
        case AIR_SUPPORT_REMOVE_PERKS:
            return !(self.owner _hasPerk(getPerkFromKsPerk(item)));
    }
    return false;
}

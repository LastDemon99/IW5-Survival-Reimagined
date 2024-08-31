

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\survival\_utility;
#include maps\lethalbeats\utility;
#include maps\lethalbeats\DynamicMenus\dynamic_shop;

// self -> player

onBuy(item, price)
{
    switch(item)
    {
        case "frag_grenade_mp":
        case "flash_grenade_mp":
        case "throwingknife_mp":
        case "concussion_grenade_mp":
            self addNades(item, 4);
            break;
        case "claymore_mp":
            self addNades(item, 5);
            self _setActionSlot(1, "weapon", item);
            break;
        case "c4_mp":
            self addNades(item, 5);
            self _setActionSlot(5, "weapon", item);
            break;
        case "trophy_mp":
            self giveweapon(item);
            self _setActionSlot(4, "weapon", item);
            self setClientDvar("ui_streak", "hud_icon_trophy");
            level.sentry++;
            break;
        case "body_armor":
            self.bodyArmor = 250;
			self setClientDvar("ui_body_armor", 1);
            break;
        case "self_revive":
            self.hasRevive = 1;
            self setClientDvar("ui_self_revive", 1);
            self givePerk("specialty_finalstand", false);
            break;
    }
    self buyItem(price);
}

isOwnedOption(item)
{
    switch(item)
    {
        case "frag_grenade_mp":
        case "flash_grenade_mp":
        case "throwingknife_mp":
        case "concussion_grenade_mp":
        case "claymore_mp":
        case "c4_mp":
		    return self.grenades[item] == getNadeMaxAmmmo(item);
        case "trophy_mp":
            return self hasWeapon("trophy_mp");
        case "body_armor":
            return self.bodyArmor == 250;
        case "self_revive":
            return self.hasRevive;
    }
    return false;
}

isDisabledOption(item)
{
    if (item == "trophy_mp") return level.sentry >= 3 || self.pers["killstreaks"].size == 6;
    return false;
}

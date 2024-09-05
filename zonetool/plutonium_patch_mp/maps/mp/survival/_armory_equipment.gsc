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
        case "body_armor":
            return self.bodyArmor == 250;
        case "self_revive":
            return self.hasRevive;
    }
    return false;
}

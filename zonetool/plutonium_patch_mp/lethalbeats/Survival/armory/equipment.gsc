#include maps\mp\_utility;
#include lethalbeats\survival\_utility;
#include lethalbeats\DynamicMenus\dynamic_shop;

// OPTIONS INDEX
#define CLAYMORE 4
#define C4 5
#define BODY_ARMOR 6
#define SELF_REVIVE 7

// self -> player

onBuy(item, price, index)
{
    switch(index)
    {
        case CLAYMORE:
            self addNades(item, 5);
            self _setActionSlot(1, "weapon", item);
            break;
        case C4:
            self addNades(item, 5);
            self _setActionSlot(5, "weapon", item);
            break;
        case BODY_ARMOR:
            self.bodyArmor = 250;
			self setClientDvar("ui_body_armor", 1);
            break;
        case SELF_REVIVE:
            self.hasRevive = 1;
            self setClientDvar("ui_self_revive", 1);
            self givePerk("specialty_finalstand", false);
            break;
        default:
            self addNades(item, 4);
            break;
    }
    self buyItem(price);
}

isOwnedOption(item, index)
{
    if (index == BODY_ARMOR)
        return self.bodyArmor == 250;

    if (index == SELF_REVIVE)
        return self.hasRevive;

    return self.grenades[item] == getNadeMaxAmmmo(item);
}

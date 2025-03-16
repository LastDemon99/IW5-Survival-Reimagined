#include maps\mp\_utility;
#include lethalbeats\survival\utility;
#include lethalbeats\dynamicmenus\dynamic_shop;

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
            self player_add_nades(item, 5);
            self _setActionSlot(1, "weapon", item);
            break;
        case C4:
            self player_add_nades(item, 5);
            self _setActionSlot(5, "weapon", item);
            break;
        case BODY_ARMOR:
            self survivor_set_body_armor(250);
            break;
        case SELF_REVIVE:
            self.hasRevive = 1;
            self setClientDvar("ui_self_revive", 1);
            self givePerk("specialty_finalstand", false);
            break;
        default:
            self player_add_nades(item, 4);
            break;
    }
    self buyItem(price);
}

isOwnedOption(item, index)
{
    if (index == BODY_ARMOR)
        return self.bodyArmor == get_max_armor();

    if (index == SELF_REVIVE)
        return self.hasRevive;

    return self.grenades[item] == player_get_max_nades(item);
}

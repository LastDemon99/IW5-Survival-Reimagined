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
            self lethalbeats\player::player_set_action_slot(1, "weapon", item);
            break;
        case C4:
            self player_add_nades(item, 5);
            self lethalbeats\player::player_set_action_slot(5, "weapon", item);
            break;
        case BODY_ARMOR:
            self survivor_set_body_armor(250);
            break;
        case SELF_REVIVE:
            self survivor_give_last_stand();
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

#include lethalbeats\dynamicmenus\dynamic_shop;
#include lethalbeats\player;
#include lethalbeats\weapon;
#include lethalbeats\attach;
#include lethalbeats\array;

#define NULL ""
#define WEAPON_MENUS ["select_pistol", "select_shotgun", "select_machine_pistol", "select_smg", "select_assault", "select_lmg", "select_sniper", "select_projectile", "select_riot"]

// OPTION TYPE
#define OPTION_BUY -5
#define OPTION_DISABLE -4
#define OPTION_OWNED -3
#define OPTION_UPGRADE -2
#define OPTION_SCRIPTRESPONSE -1

// WEAPON ARMORY PAGE
#define PAGE_NULL -1
#define WEAPON_SELECT 0
#define WEAPON_ATTACHS 1
#define WEAPON_BUFFS 2
#define WEAPON_UPGRADES 3
#define WEAPON_REMOVE_ATTACHS 4
#define WEAPON_REMOVE_BUFFS 5
#define WEAPON_CAMOS 6
#define WEAPON_AMMO 7
#define WEAPON_LAUNCHERS 8
#define WEAPON_RIOTS 9

// UPGRADE OPTIONS INDEX
#define INDEX_ADD_ATTACH 0
#define INDEX_ADD_BUFF 1
#define INDEX_ATTACH_SLOT 3
#define INDEX_BUFF_SLOT 4
#define INDEX_REMOVE_ATTACH 5
#define INDEX_REMOVE_BUFF 6

// TABLE DATA
#define SHOP_TABLE "mp/dynamic_shop.csv"
#define SHOP_ITEM_COLUMN 6
#define SHOP_DISPLAY_COLUMN 2

// WEAPON DATA INDEX
#define BUILD_NAME 0
#define BASENAME 1
#define ATTACHS 2
#define BUFFS 3
#define CAMO 4
#define ATTACH_SLOTS 5
#define BUFF_SLOTS 6
#define MAX_ATTACHS 7
#define ALLOWED_ATTACHS 8
#define IS_PRIMARY 9
#define IS_PRIMARY_CLASS 10
#define CLASS 11

// self -> shop
// self.owner -> player

//////////////////////////////////////////
//	            HANDLERS   		        //
//////////////////////////////////////////

onInit()
{
    player = self.owner;
    weapon = player getCurrentWeapon();
    self.weaponData = player getWeaponData(weapon);
    if (weapon != "none") self.weaponData[IS_PRIMARY] = player player_is_weapon_primary(self.weaponData[BUILD_NAME]);
}

onOpenPage(page)
{
    removeItem = self.removeItem;
    self.removeItem = false;
    switch(page)
    {
        case "ammo": self.page = WEAPON_AMMO; break;
        case "weapon_camo": self.page = WEAPON_CAMOS; break;
        case "select_riot": self.page = WEAPON_RIOTS; break;
        case "select_projectile": self.page = WEAPON_LAUNCHERS; break;
        case "upgrade_weapon": self.page = WEAPON_UPGRADES; break;
        default:
            if (isEndStr(page, "buff"))
            {
                if (removeItem) self.page = WEAPON_REMOVE_BUFFS;
                else self.page = WEAPON_BUFFS;
            }
            else if (isEndStr(page, "attach"))
            {
                if (removeItem) self.page = WEAPON_REMOVE_ATTACHS;
                else self.page = WEAPON_ATTACHS;
            }
            else if (array_contains(WEAPON_MENUS, page)) self.page = WEAPON_SELECT;
            break;
    }
}

onSelectOption(page, item, price, option_type, index)
{
    if (option_type == OPTION_BUY)
        self onBuy(page, item, price, index);
    else if (option_type == OPTION_UPGRADE)
        self onUpgrade(item, index);
    else if (option_type == OPTION_SCRIPTRESPONSE)
        self onResponse(page, item, index);
}

onBuy(page, item, price, index)
{
    player = self.owner;

    switch(self.page)
    {
        case WEAPON_SELECT:
        case WEAPON_LAUNCHERS:
        case WEAPON_RIOTS:
            if (!(2 - player player_get_weapons().size))
            {
                player takeWeapon(player getCurrentWeapon());
                self.weaponData = player newWeaponData(weapon_build(item));
            }
            else
            {
                weapon = player player_get_build_weapon(item);
                if (!isDefined(weapon)) self.weaponData = player newWeaponData(weapon_build(item));
                else self.weaponData = player getWeaponData(weapon);
            }
            break;        
        case WEAPON_ATTACHS:
            self.weaponData[ATTACHS] = array_append(self.weaponData[ATTACHS], item);
            break;
        case WEAPON_REMOVE_ATTACHS:
            self.weaponData[ATTACHS] = array_remove(self.weaponData[ATTACHS], item);
            break;
        case WEAPON_BUFFS:
            self.weaponData[BUFFS] = array_append(self.weaponData[BUFFS], item);
            break;
        case WEAPON_REMOVE_BUFFS:
            self.weaponData[BUFFS] = array_remove(self.weaponData[BUFFS], item);
            break;
        case WEAPON_CAMOS:
            self.weaponData[CAMO] = attach_get_camo_index(item);
            break;
        case WEAPON_UPGRADES:
            if (index == INDEX_ATTACH_SLOT)
            {
                player buyItem(self getAttachSlotPrice(price));
                self.weaponData[ATTACH_SLOTS]++;
            }
            else if (index == INDEX_BUFF_SLOT)
            {
                player buyItem(self getBuffSlotPrice(price));
                self.weaponData[BUFF_SLOTS]++;
            }

            player setWeaponData(self.weaponData[BASENAME], self.weaponData);
            player updateLabels(page);
            return;
    }

    hasWeapon = player hasWeapon(self.weaponData[BUILD_NAME]);
    if (hasWeapon) player player_save_ammo(self.weaponData[BUILD_NAME], "selected");

    player takeWeapon(self.weaponData[BUILD_NAME]);
    self.weaponData[BUILD_NAME] = weapon_build(self.weaponData[BASENAME], self.weaponData[ATTACHS], self.weaponData[CAMO]);

    player player_give_weapon(self.weaponData[BUILD_NAME]);
    player switchToWeaponImmediate(self.weaponData[BUILD_NAME]);

    if (hasWeapon) player player_restore_ammo(self.weaponData[BUILD_NAME], "selected");

    player setWeaponData(self.weaponData[BUILD_NAME], self.weaponData);
    player buyItem(price);
}

onResponse(page, item, index)
{
    player = self.owner;

    if (self.page == WEAPON_AMMO)
    {
        weapon = player player_get_weapons()[int(item)];
        player buyItem(player getAmmoPrice(weapon));
        player player_give_max_ammo(weapon);
        player updateLabels(page);
        return;
    }
    
    if (self.page == WEAPON_UPGRADES)
    {
        switch(index)
        {
            case INDEX_REMOVE_ATTACH: self.removeItem = true;
            case INDEX_ADD_ATTACH:
                item = self.weaponData[CLASS] + "_attach";
                break;
            case INDEX_REMOVE_BUFF: self.removeItem = true;
            case INDEX_ADD_BUFF:
                item = self.weaponData[CLASS] + "_buff";
                break;
        }
    }

    player openShop(item);
    player playLocalSound("mouse_click");
}

onUpgrade(item, index)
{
    weapon = self.owner player_get_build_weapon(item);
    self.weaponData = self.owner getWeaponData(weapon);
    self.owner openShop("upgrade_weapon");
}

onUpdateOption(index, item, option_label, price_label)
{
    if (price_label == OPTION_BUY) price_label = getPrice(item);
    
    player = self.owner;
    player setOption(index, option_label);
    player setPrice(index, price_label);

    if (self.page == WEAPON_AMMO)
    {
        if (index > 1) return;
        wepList = player player_get_weapons();
        if (index == wepList.size)
        {
            player setOption(index, NULL);
            return;
        }
        weapon = wepList[index];
        player setOption(index, tablelookup(SHOP_TABLE, SHOP_ITEM_COLUMN, weapon_get_baseName(weapon), SHOP_DISPLAY_COLUMN));
        if (price_label != OPTION_DISABLE) price_label = player getAmmoPrice(weapon);
        player setPrice(index, price_label);
        return;
    }

    if (price_label == OPTION_DISABLE) return;

    switch(self.page)
    {
        case WEAPON_UPGRADES:
            if (index == INDEX_ATTACH_SLOT) price_label = self getAttachSlotPrice(price_label);
            else if (index == INDEX_BUFF_SLOT) price_label = self getBuffSlotPrice(price_label);
            break;
        case WEAPON_REMOVE_ATTACHS: 
            price_label *= getPrice("remove_attach_multiplier");
            break;
        case WEAPON_REMOVE_BUFFS:
            price_label *= getPrice("remove_buff_multiplier");
            break;
    }
    player setPrice(index, price_label);
}

//////////////////////////////////////////
//	           OPTION STATES  		    //
//////////////////////////////////////////

isUpgradeOption(item)
{
    if (self.page != WEAPON_SELECT && self.page != WEAPON_RIOTS) return false;
    return isDefined(self.owner player_get_build_weapon(item));
}

isOwnedOption(item)
{
    switch(self.page)
    {
        case WEAPON_LAUNCHERS:
            return self.owner player_has_weapon(item, true);
        case WEAPON_ATTACHS:
            return array_contains(self.weaponData[ATTACHS], item);
        case WEAPON_BUFFS:
            return array_contains(self.weaponData[BUFFS], item);
        case WEAPON_CAMOS:
            return self.weaponData[CAMO] == attach_get_camo_index(item);
    }
    return false;
}

isDisabledOption(item, index)
{
    weapon = self.weaponData;

    if (self.page == -1) return index == 0 && weapon[BASENAME] == "none";

    switch(self.page)
    {
        /* switch ignore -1?? ( •̀_•́ )??
        case PAGE_NULL:
            return index == 0 && weapon[BASENAME] == "none";*/
        case WEAPON_AMMO:
            index = int(item);
            wepList = self.owner player_get_weapons();
            if (index > 1 || index == wepList.size) return false; 
            return self.owner player_has_max_ammo(wepList[index]);
        case WEAPON_UPGRADES:
            if (!weapon[IS_PRIMARY_CLASS] && (index != INDEX_ADD_ATTACH && index != INDEX_ATTACH_SLOT && index != INDEX_REMOVE_ATTACH)) return true;
            if (!weapon[ATTACHS].size && index == INDEX_REMOVE_ATTACH) return true;
            if (!weapon[BUFFS].size && index == INDEX_REMOVE_BUFF) return true;
            if (weapon[CLASS] == "riot" && (index != INDEX_ADD_BUFF && index != INDEX_BUFF_SLOT)) return true;
            if (index == INDEX_ATTACH_SLOT)
            {
                if (weapon[BASENAME] == "iw5_mp412" || weapon[BASENAME] == "iw5_44magnum" || weapon[BASENAME] == "iw5_1887") return true;
                return weapon[ATTACH_SLOTS] == weapon[MAX_ATTACHS];
            }
            if (index == INDEX_BUFF_SLOT)
            {
                return weapon[BUFF_SLOTS] == (weapon[CLASS] == "riot" ? 2 : 3);
            }
            return index == INDEX_ADD_ATTACH && weapon[BASENAME] == "iw5_1887";
        case WEAPON_ATTACHS:
            if (!(weapon[ATTACH_SLOTS] - weapon[ATTACHS].size)) return true;
            item = attach_build(item, weapon[BASENAME]);
            if (!array_contains(weapon[ALLOWED_ATTACHS], item)) return true;
            return !attach_is_combo(item, weapon[ATTACHS]);
        case WEAPON_BUFFS:
            return !(weapon[BUFF_SLOTS] - weapon[BUFFS].size);
        case WEAPON_REMOVE_ATTACHS:
            return !array_contains(weapon[ATTACHS], item);
        case WEAPON_REMOVE_BUFFS:
            return !array_contains(weapon[BUFFS], item);
    }
    return false;
}

//////////////////////////////////////////
//	            UTILITIES  		        //
//////////////////////////////////////////

newWeaponData(weapon, buffs)
{
    if (weapon == "none")
    {
        data = [];
        data[BUILD_NAME] = weapon;
        data[BASENAME] = weapon;
        data[ATTACHS] = [];        
        data[BUFFS] = [];        
        data[CAMO] = 0;
        data[ATTACH_SLOTS] = 1;
        data[BUFF_SLOTS] = 1;
        data[MAX_ATTACHS] = 0;
        data[ALLOWED_ATTACHS] = [];
        data[IS_PRIMARY] = true;
        data[IS_PRIMARY_CLASS] = false;
        data[CLASS] = weapon;
        return data;
    }

    data = [];
    data[BUILD_NAME] = weapon;
    data[BASENAME] = weapon_get_baseName(weapon);
    data[ATTACHS] = weapon_get_current_attachs(weapon);
    
    if (isDefined(buffs)) data[BUFFS] = buffs;
    else data[BUFFS] = self hasWeapon(weapon) ? self player_get_weapons_buffs() : [];
    
    data[CAMO] = 0;
    data[ATTACH_SLOTS] = !data[ATTACHS].size ? 1 : data[ATTACHS].size;
    data[BUFF_SLOTS] = !data[BUFFS].size ? 1 : data[BUFFS].size;
    data[MAX_ATTACHS] = weapon_get_max_attachs(data[BASENAME]);
    data[ALLOWED_ATTACHS] = weapon_get_attachs(data[BASENAME]);
    data[IS_PRIMARY] = self player_is_weapon_primary(weapon);
    data[IS_PRIMARY_CLASS] = weapon_is_primary_class(data[BASENAME]);
    data[CLASS] = weapon_get_class(data[BASENAME]);
    return data;
}

setWeaponData(weapon, data) // self -> player
{
    self.weaponData[int(self player_is_weapon_secondary(weapon))] = data;
}

getWeaponData(weapon) // self -> player
{
    weaponIndex = weapon == "none" ? 0 : int(self player_is_weapon_secondary(weapon));
    weaponData = self.weaponData[weaponIndex];
    if (!isDefined(weaponData) || weaponData[BUILD_NAME] != weapon)
    {
        if (array_contains_key(level.bots_weapons_data, weapon))
            weaponData = level.bots_weapons_data[weapon];
        else
            weaponData = self newWeaponData(weapon, []);

        self setWeaponData(weapon, weaponData);
    }
    return weaponData;
}

getAmmoPrice(weapon) // self -> player
{
    price = getPrice("ammo_" + weapon_get_class(weapon));
    foreach(attach in weapon_get_current_attachs(weapon))
    {
        if (attach_is_gl(attach)) price += getPrice("ammo_gl");
        else if (attach == "xmags") price += getPrice("ammo_xmags");
        else if (attach == "shotgun") price += getPrice("ammo_shotgun_alt");
    }
    price -= price * self player_get_fraction_ammo(weapon);
    return price;
}

getAttachSlotPrice(price_base)
{
    return price_base * (getPrice("attach_slot_multiplier") * self.weaponData[ATTACH_SLOTS]);
}

getBuffSlotPrice(price_base)
{
    return price_base * (getPrice("buff_slot_multiplier") * self.weaponData[BUFF_SLOTS]);
}

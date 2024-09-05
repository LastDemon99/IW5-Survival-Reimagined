#include common_scripts\utility;
#include maps\mp\_utility;
#include lethalbeats\utility;
#include lethalbeats\weapons;
#include lethalbeats\DynamicMenus\dynamic_shop;

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

// self -> shop
// self.owner -> player

//////////////////////////////////////////
//	            HANDLERS   		        //
//////////////////////////////////////////

onInit()
{
    self.hasStock = 1;

    if (isDefined(self.owner.primaryAttachSlots)) return;

    player = self.owner;
    player.primaryAttachSlots = 1;
    player.primaryBuffSlots = 1;
    player.secondaryAttachSlots = 1;
    player.secondaryBuffSlots = 1;
    player.primaryBuffs = [];
    player.secondaryBuffs = [];
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
            if (string_end_with(page, "buff"))
            {
                if (removeItem) self.page = WEAPON_REMOVE_BUFFS;
                else self.page = WEAPON_BUFFS;
            }
            else if (string_end_with(page, "attach")) 
            {
                if (removeItem) self.page = WEAPON_REMOVE_ATTACHS;
                else self.page = WEAPON_ATTACHS;
            }
            else if (array_contains(WEAPON_MENUS, page)) self.page = WEAPON_SELECT;
            break;
    }
    self checkStock();
}

onSelectOption(page, item, price, option_type)
{
    if (option_type == OPTION_BUY) 
        self onBuy(item, price);
    else if (option_type == OPTION_UPGRADE)
        self onUpgrade(item);
    else if (option_type == OPTION_SCRIPTRESPONSE)
        self onResponse(page, item);
}

onBuy(item, price)
{
    player = self.owner;
    isReplaceWeapon = false;

    switch(self.page)
    {
        case WEAPON_SELECT:
        case WEAPON_LAUNCHERS:
        case WEAPON_RIOTS:
            if (!self.hasStock)
            {
                player takeWeapon(player getCurrentWeapon());
                isReplaceWeapon = true;
            }
            self.selectedWeapon = item;
            self.selectedAttachs = [];
            self.selectedBuffs = [];
            self.selectedCamo = 0;
            self.selectedBuildedWeapon = build_weapon(item);
            break;        
        case WEAPON_ATTACHS:
            self.selectedAttachs[self.selectedAttachs.size] = item;
            break;
        case WEAPON_BUFFS:
            self.selectedBuffs[self.selectedBuffs.size] = item;
            if (self isPrimarySelected()) player.primaryBuffs = self.selectedBuffs;
            else player.secondaryBuffs = self.selectedBuffs;
            break;
        case WEAPON_REMOVE_ATTACHS:
            self.selectedAttachs = array_remove(self.selectedAttachs, item);
            break;
        case WEAPON_REMOVE_BUFFS:
            self.selectedBuffs = array_remove(self.selectedBuffs, item);
            break;
        case WEAPON_CAMOS:
            self.selectedCamo = get_camo_index(item);
            break;
        case WEAPON_UPGRADES:
            if (item == "attach_slot")
            {
                if (self isPrimarySelected()) self.owner.primaryAttachSlots++;
                else self.owner.secondaryAttachSlots++;
            }
            else if (item == "buff_slot")
            {
                if (self isPrimarySelected()) self.owner.primaryBuffSlots++;
                else self.owner.secondaryBuffSlots++;
            }
            break;
    }

    isNewWeapon = player hasWeapon(self.selectedBuildedWeapon);
    if (isNewWeapon) player saveAmmo(self.selectedBuildedWeapon, "selected");

    player takeWeapon(self.selectedBuildedWeapon);
    self.selectedBuildedWeapon = build_weapon(self.selectedWeapon, self.selectedAttachs, self.selectedCamo);
    
    player _giveWeapon(self.selectedBuildedWeapon);
    player switchToWeaponImmediate(self.selectedBuildedWeapon);
    
    if (isNewWeapon) player restoreAmmo(self.selectedBuildedWeapon, "selected");
    if (isReplaceWeapon) clearBuffs();

    self checkStock();
    player buyItem(price);
}

onUpgrade(item)
{
    if (!isDefined(self.selectedWeapon))
    {
        ownedWeapon = self.owner get_player_weapon(item);
        self.selectedWeapon = getBaseWeaponName(ownedWeapon);
        self.selectedBuildedWeapon = ownedWeapon;
        self.selectedAttachs = get_current_attachs(self.selectedBuildedWeapon);
        self.selectedBuffs = self isPrimarySelected() ? self.owner.primaryBuffs : self.owner.secondaryBuffs;
        self.selectedCamo = get_camo_index(get_current_camo(self.selectedBuildedWeapon));
    }
    self.owner openShop("upgrade_weapon");
}

onResponse(page, item)
{
    player = self.owner;

    if (self.page == WEAPON_AMMO)
    {
        weapon = player _getWeaponsListPrimaries()[int(item)];
        player takeWeapon(weapon);
        player _giveWeapon(weapon); // fill clip
        player giveMaxAmmo(weapon); // fill only stock
        if (hasAltAttach(weapon))  player giveMaxAmmo("alt_" + weapon);
        player buyItem(getPrice(item));
        return;
    }
    
    switch(item)
    {
        case "remove_attach": self.removeItem = true;
        case "add_attach":
            item = get_weapon_class(self.selectedWeapon) + "_attach";
            break;
        case "remove_buff": self.removeItem = true;
        case "add_buff":
            item = get_weapon_class(self.selectedWeapon) + "_buff";
            break;
    }

    player openShop(item);
    player playLocalSound("mouse_click");
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
        wepList = player _getWeaponsListPrimaries();
        if (index == wepList.size)
        {
            player setOption(index, NULL);
            return;
        }
        player setOption(index, tablelookup("mp/dynamic_shop.csv", 6, getBaseWeaponName(wepList[index]), 2));
        if (price_label != OPTION_DISABLE)
        {
            weapon = wepList[index];
            price_label = getPrice("ammo_" + get_weapon_class(weapon));
            foreach(attach in get_current_attachs(weapon))
            {
                if (attach == "gl" || attach == "m320" || attach == "gp25") price_label += getPrice("ammo_gl");
                else if (attach == "xmags") price_label += getPrice("ammo_xmags");
                else if (attach == "shotgun") price_label += getPrice("ammo_shotgun_alt");
            }
        }
        player setPrice(index, price_label);
        return;
    }

    if (price_label == OPTION_DISABLE) return;

    switch(self.page)
    {
        case WEAPON_UPGRADES:
            if (item == "attach_slot") 
            {
                slotsCount = self isPrimarySelected() ?  player.primaryAttachSlots :  player.secondaryAttachSlots;
                price_label *= (getPrice("attach_slot_multiplier") * slotsCount);
            }
            else if (item == "buff_slot") 
            {
                slotsCount = self isPrimarySelected() ?   player.primaryBuffSlots :  player.secondaryBuffSlots;
                price_label *= (getPrice("buff_slot_multiplier") * slotsCount);
            }
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
    if (self.owner hasWeapon_ByBaseName(item)) return true;
    return false;
}

isOwnedOption(item)
{
    switch(self.page)
    {
        case WEAPON_LAUNCHERS:
            return self.owner hasWeapon_ByBaseName(item);
        case WEAPON_ATTACHS:
            return array_contains(self.selectedAttachs, item);
        case WEAPON_BUFFS:
            return array_contains(self.selectedBuffs, item);
        case WEAPON_CAMOS:
            return self.selectedCamo == get_camo_index(item);
    }
    return false;
}

isDisabledOption(item)
{
    switch(self.page)
    {
        case WEAPON_AMMO:
            index = int(item);
            wepList = self.owner _getWeaponsListPrimaries();
            if (index > 1 || index == wepList.size) return false;
            return self.owner hasMaxAmmo(wepList[index]);
        case WEAPON_UPGRADES:
            if (is_secondary_class(self.selectedWeapon) && (item != "add_attach" && item != "attach_slot" && item != "remove_attach")) return true;
            if (!self.selectedAttachs.size && item == "remove_attach") return true;
            if (!self.selectedBuffs.size && item == "remove_buff") return true;
            if (get_weapon_class(self.selectedWeapon) == "riot" && (item != "add_buff" && item != "buff_slot")) return true;
            if (item == "attach_slot")
            {
                if (self.selectedWeapon == "iw5_mp412" || self.selectedWeapon == "iw5_44magnum") return true;
                slotsCount = self isPrimarySelected() ?  self.owner.primaryAttachSlots : self.owner.secondaryAttachSlots;
                return slotsCount == get_max_attachs_count(self.selectedWeapon);
            }
            if (item == "buff_slot")
            {
                slotsCount = self isPrimarySelected() ?  self.owner.primaryBuffSlots : self.owner.secondaryBuffSlots;
                return slotsCount == (get_weapon_class(self.selectedWeapon) == "riot" ? 2 : 3);
            }
            break;
        case WEAPON_ATTACHS:
            if (!self.hasStock) return true;
            if (item == "gl") item = build_gl(self.selectedWeapon); // formats -> gl, gp25, 320
            else if (item == "silencer") item = build_silencer(get_weapon_class(self.selectedWeapon)); // formats -> silencer, silencer02, silencer03
            if (!array_contains(get_weapon_attachs(self.selectedWeapon), item)) return true;
            return !is_combo_attach(self.selectedAttachs, item);
        case WEAPON_BUFFS:
            return !self.hasStock;
        case WEAPON_REMOVE_ATTACHS:
            return !array_contains(self.selectedAttachs, item);
        case WEAPON_REMOVE_BUFFS:
            return !array_contains(self.selectedBuffs, item);
    }
    return false;
}

//////////////////////////////////////////
//	            UTILITIES  		        //
//////////////////////////////////////////

isPrimarySelected()
{
    weapons = self.owner _getWeaponsListPrimaries();
    return self.selectedWeapon == getBaseWeaponName(weapons[0]);
}

clearBuffs()
{
    player = self.owner;
    buffs = [];    
    if (self isPrimarySelected())
    {
        player.primaryAttachSlots = 1;
        player.primaryBuffSlots = 1;
        buffs = player.primaryBuffs;
        player.primaryBuffs = [];
    }        
    else
    {
        player.secondaryAttachSlots = 1;
        player.secondaryBuffSlots = 1;
        buffs = player.secondaryBuffs;
        player.secondaryBuffs = [];
    }

    foreach(buff in buffs)
        if (player _hasperk(buff)) player _unsetPerk(buff);
    return [];
}

checkStock()
{
    switch(self.page)
    {
        case WEAPON_SELECT:
        case WEAPON_LAUNCHERS:
            weapons = self.owner _getWeaponsListPrimaries();
            self.hasStock = 2 - weapons.size > 0;
            break;
        case WEAPON_ATTACHS:
            slots = self isPrimarySelected() ? self.owner.primaryAttachSlots : self.owner.secondaryAttachSlots;
            self.hasStock = slots - self.selectedAttachs.size > 0;
            break;
        case WEAPON_BUFFS:
            slots = self isPrimarySelected() ? self.owner.primaryBuffSlots : self.owner.secondaryBuffSlots;
            self.hasStock = slots - self.selectedBuffs.size > 0;
            break;
    }
}

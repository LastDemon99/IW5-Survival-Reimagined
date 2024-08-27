
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\lethalbeats\utility;
#include maps\lethalbeats\weapons;
#include maps\mp\survival\_armory;
#include maps\lethalbeats\DynamicMenus\dynamic_shop;

#define NULL ""

#define WEAPON_MENUS ["select_pistol", "select_shotgun", "select_machine_pistol", "select_smg", "select_assault", "select_lmg", "select_sniper", "select_projectile", "select_riot"]

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

// WEAPON ARMORY PAGE TYPES
#define WEAPON_SELECT 3
#define WEAPON_ATTACHS 4
#define WEAPON_BUFFS 5
#define WEAPON_UPGRADES 6
#define WEAPON_REMOVE_ATTACHS 7
#define WEAPON_REMOVE_BUFFS 8
#define WEAPON_CAMOS 9
#define WEAPON_AMMO 10

// self -> shop
// self.owner -> player

onOpenPage(menu)
{
    if (!isDefined(self.owner.primaryAttachSlots))
    {
        player = self.owner;
        player.primaryAttachSlots = 1;
        player.primaryBuffSlots = 1;
        player.secondaryAttachSlots = 1;
        player.secondaryBuffSlots = 1;
        player.primaryBuffs = [];
        player.secondaryBuffs = [];
    }

    if (menu == "upgrade_weapon") 
        self.page = WEAPON_UPGRADES;
    else if (string_end_with(menu, "buff") && self.page != WEAPON_REMOVE_BUFFS)
        self.page = WEAPON_BUFFS;
    else if (string_end_with(menu, "attach") && self.page != WEAPON_REMOVE_ATTACHS)
        self.page = WEAPON_ATTACHS;
    else
    {
        foreach(wep_menu in WEAPON_MENUS)
            if (menu == wep_menu)
            {
                self.page = WEAPON_SELECT;                
                break;
            }
    }
    self checkStock();
}

onBuyItem(item, price)
{
    player = self.owner;
    isReplaceWeapon = false;

    switch(self.page)
    {
        case WEAPON_SELECT:
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
            if (self is_primary_selected()) player.primaryBuffs = self.selectedBuffs;
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
                if (self is_primary_selected()) self.owner.primaryAttachSlots++;
                else self.owner.secondaryAttachSlots++;
            }
            else if (item == "buff_slot")
            {
                if (self is_primary_selected()) self.owner.primaryBuffSlots++;
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
    player buyItem(price);
    self checkStock();

    if (isNewWeapon) player restoreAmmo(self.selectedBuildedWeapon, "selected");

    if (!isReplaceWeapon) return;
    if (self is_primary_selected())
    {
        player.primaryAttachSlots = 1;
        player.primaryBuffSlots = 1;
        player.primaryBuffs = clear_buffs(player.primaryBuffs);
        return;
    }
    
    player.secondaryAttachSlots = 1;
    player.secondaryBuffSlots = 1;
    player.secondaryBuffs = clear_buffs(player.secondaryBuffs);
}

onUpgradeItem()
{
    if (self.page == WEAPON_SELECT)
        self.owner openShop("upgrade_weapon");
}

onResponseItem(page, item)
{
    player = self.owner;
    if (self.page == WEAPON_AMMO)
    {
        player buyItem(getPrice(item));
        player playLocalSound("arcademode_checkpoint");

        weapon = player getWeaponsListPrimaries()[int(item)];
        player takeWeapon(weapon); // fill clip stop
        player _giveWeapon(weapon);
        player giveMaxAmmo(weapon); // fill only stock
        return;
    }

    if (self.page != WEAPON_UPGRADES)
    {
        if (item == "ammo") self.page = WEAPON_AMMO;
        player openShop(item);
        return;
    }

    if (item == "weapon_camo") 
    {
        self.page = WEAPON_CAMOS;
        player openShop(item);
        return;
    }
    
    weapon_class = get_weapon_class(self.selectedWeapon);
    switch(item)
    {
        case "remove_attach":
            self.page = WEAPON_REMOVE_ATTACHS;
        case "add_attach":            
            player openShop(weapon_class + "_attach");
            break;
        case "remove_buff":
            self.page = WEAPON_REMOVE_BUFFS;
        case "add_buff":
            player openShop(weapon_class + "_buff");
            break;
    }
}

updateLabels(index, item, option_label, price_label)
{
    player = self.owner;

    if (self.page == WEAPON_AMMO)
    {
        wepList = player getWeaponsListPrimaries();
        if (index == 0) weapon = getBaseWeaponName(wepList[0]);
        else if (index == 1) 
        {
            if  (wepList.size < 2)
            {
                player setOption(index, NULL);
                player setPrice(index, NULL);
                return;
            }
            weapon = getBaseWeaponName(wepList[1]);
        }
        else return;

        player setOption(index, tablelookup("mp/dynamic_shop.csv", 6, weapon, 2));
        player setPrice(index, getPrice(getWeaponClass(weapon)));
        return;
    }

    player setOption(index, option_label);

    if (price_label != OPTION_BUY)
    {
        player setPrice(index, price_label);
        return;
    }

    price = getPrice(item);
    switch(self.page)
    {
        case WEAPON_UPGRADES:
            if (item == "attach_slot") 
            {
                slotsCount = self is_primary_selected() ?  player.primaryAttachSlots : player.secondaryAttachSlots;
                price *= (getPrice("attach_slot_multiplier") * slotsCount);
            }
            else if (item == "buff_slot") 
            {
                slotsCount = self is_primary_selected() ?  player.primaryBuffSlots : player.secondaryBuffSlots;
                price *= (getPrice("buff_slot_multiplier") * slotsCount);
            }
            break;
        case WEAPON_REMOVE_ATTACHS: 
            price *= getPrice("remove_attach_multiplier");
            break;
        case WEAPON_REMOVE_BUFFS:
            price *= getPrice("remove_buff_multiplier");
            break;
    }
    player setPrice(index, price);
}

isUpgradeOption(item)
{
    if (self.page != WEAPON_SELECT) return false;
    ownedWeapon = self.owner get_player_weapon(item);
    if (!isDefined(ownedWeapon)) return false;
    self.selectedWeapon = getBaseWeaponName(ownedWeapon);
    self.selectedBuildedWeapon = ownedWeapon;
    self.selectedAttachs = get_current_attachs(self.selectedBuildedWeapon);
    self.selectedBuffs = self is_primary_selected() ? self.owner.primaryBuffs : self.owner.secondaryBuffs;
    self.selectedCamo = get_camo_index(get_current_camo(self.selectedBuildedWeapon));
    return true;
}

isOwnedOption(item)
{
    switch(self.page)
    {
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
        //case WEAPON_AMMO:
            //wepList = self.owner getWeaponsListPrimaries();
            //wepIndex = int(item);
            //if (wepIndex == 1 && wepList.size == 1) return false;
            //return int(self.owner getFractionMaxAmmo(wepList[wepIndex])) == 0;
        case WEAPON_UPGRADES:
            if (is_secondary_class(self.selectedWeapon) && (item != "add_attach" && item != "attach_slot")) return true;        
            if (!self.selectedAttachs.size && item == "remove_attach") return true;
            if (!self.selectedBuffs.size && item == "remove_buff") return true;            
            if (get_weapon_class(self.selectedWeapon) == "riot" && (item != "add_buff" && item != "buff_slot")) return true;
            if (item == "attach_slot")
            {
                if (self.selectedWeapon == "iw5_mp412" || self.selectedWeapon == "iw5_44magnum") return true;
                slotsCount = self is_primary_selected() ?  self.owner.primaryAttachSlots : self.owner.secondaryAttachSlots;
                return slotsCount == get_max_attachs_count(self.selectedWeapon);
            }
            if (item == "buff_slot")
            {
                slotsCount = self is_primary_selected() ?  self.owner.primaryBuffSlots : self.owner.secondaryBuffSlots;
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

checkStock()
{
    player = self.owner;
    switch(self.page)
    {
        case WEAPON_SELECT:
            weapons = self.owner getWeaponsListPrimaries();
            self.hasStock = 2 - weapons.size > 0;
            break;
        case WEAPON_ATTACHS:
            slots = self is_primary_selected() ? self.owner.primaryAttachSlots : self.owner.secondaryAttachSlots;
            self.hasStock = slots - self.selectedAttachs.size > 0;
            break;
        case WEAPON_BUFFS:
            slots = self is_primary_selected() ? self.owner.primaryBuffSlots : self.owner.secondaryBuffSlots;
            self.hasStock = slots - self.selectedBuffs.size > 0;
            break;
    }
}

is_primary_selected()
{
    weapons = self.owner getWeaponsListPrimaries();
    return self.selectedWeapon == getBaseWeaponName(weapons[0]);
}

clear_buffs(buffs) // self -> player
{
    if (!isDefined(buffs)) return [];
    foreach(buff in buffs)
        if (self _hasperk(buff)) self _unsetPerk(buff);
    return [];
}

#include lethalbeats\survival\utility;
#include lethalbeats\player;
#include lethalbeats\hud;

#define FRAG "frag_grenade_mp"
#define FLASH "flash_grenade_mp"
#define UI_USE_SLOT "ui_use_slot"

#define CH_HEADSHOT 0
#define CH_KILL 1
#define CH_KNIFE 2
#define CH_GRENADE 3

#define BLAST_SHIELD "_specialty_blastshield"

#define MOD_MULTIPLIER ["MOD_EXPLOSIVE", "MOD_GRENADE", "MOD_GRENADE_SPLASH", "MOD_PROJECTILE", "MOD_PROJECTILE_SPLASH", "MOD_RIFLE_BULLET"]

onPlayerSpawn()
{
	level endon("game_ended");
	self endon("disconnect");
	
	for(;;)
	{
		self waittill("spawned_player");

		self survivor_init_summary();

		self.prevWeapon = self getCurrentWeapon();
		self.weaponData = [self player_new_weapon_data(self.prevWeapon), undefined];
		self.survivalPerks = [];
		self.grenades = [];
		self.onTrigger = undefined;
		self.currMenu = undefined;
		self.isCarryObject = 0;
		
		self setClientDvar(UI_USE_SLOT, "none");
		self setClientDvar("client_cmd", "");
		
		self openMenu("perk_hide");
		self survivor_zoom_effect();
		self survivor_init_challenge();
		self survivor_clear_perks();
		self survivor_set_score(getDvarInt("survival_start_money"));
		self survivor_give_body_armor();
		self survivor_give_last_stand();
		
		self player_clear_nades();
		self player_set_nades(FLASH, 2);
		self player_set_nades(FRAG, 2);

		self player_give_perk("specialty_finalstand", false);
		self thread player_refill_nades();
		self thread onWeaponFire();
		self thread onChangeWeapons();
		self thread onUseShop();
		self thread onHideScore();
		self thread dropWeaponMonitor();
	}
}

onPlayerRespawnDealy()
{	
	level endon("game_ended");
	self endon("disconnect");

	self survivor_destroy_hud();

	if(!getDvarInt("survival_wait_respawn")) return;
	if(!level.game_ended && !survivors(true).size)
	{
		rotate_wait = 15;
		foreach(player in survivors()) 
		{
			player hud_clear_lower_message("spawn_info");
			player hud_set_lower_message("spawn_info", "All survivors death waiting to rotate map", rotate_wait, 1, 1);
		}
		level notify("all_survivors_death", rotate_wait);
	}
	else self thread hud_set_lower_message("spawn_info", "Waiting for the wave end");

	level waittill("wave_end");
	self.forceSpawnNearTeammates = true;
	self hud_clear_lower_message("spawn_info");
}

onPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
	if (lethalbeats\array::array_contains(MOD_MULTIPLIER, sMeansOfDeath)) iDamage *= 4;
	if (lethalbeats\array::array_contains(self lethalbeats\player::player_get_perks(), BLAST_SHIELD) || (isDefined(eAttacker) && eAttacker == self)) iDamage /= 2;
	if (isDefined(eAttacker))
	{
		if (eAttacker bot_is_dog()) eAttacker lethalbeats\Survival\abilities\_dog::onDogPlayerDamage(self);
		if (isDefined(eAttacker.owner)) eAttacker = eAttacker.owner;
	}

	iDamage /= 20;
	self.summary["damagetaken"] += iDamage;
	
	if(isDefined(self.lastStand) && self.barFrac > 0)
	{
		self.lastStandBar hud_update_bar((self.barFrac - 6) / 20, 0);
		return;
	}
	
	if(self.bodyArmor > 0)
	{
		armor = int(self.bodyArmor - iDamage);
		if (armor < 0) self survivor_take_body_armor();
		else
		{
			if (armor == 0) self survivor_take_body_armor();
			else self survivor_set_body_armor(armor);
			self [[level.prevCallbackPlayerDamage]](eInflictor, eAttacker, 1, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
			self.health++;
			return;
		}
	}

	self [[level.prevCallbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
}

onPlayerKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	if (isDefined(self.currMenu)) self closeMenu("dynamic_shop");
	self player_clear_last_stand();
	self survivor_take_body_armor();
	
	self [[level.prevCallbackPlayerKilled]](eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
}

onPlayerBotKilled(bot, damage, meansOfDeath, weapon)
{
	if (isDefined(self.laststand)) self survivor_last_stand_revive();
	self survivor_update_challenge(CH_KILL);	
	
	if (meansOfDeath == "MOD_MELEE") self survivor_update_challenge(CH_KNIFE);	
	else if (meansOfDeath == "MOD_GRENADE" || meansOfDeath == "MOD_GRENADE_SPLASH" || weaponClass(weapon) == "grenade") self survivor_update_challenge(CH_GRENADE);
	else
	{
		if (meansOfDeath == "MOD_HEAD_SHOT")
		{
			self survivor_update_challenge(CH_HEADSHOT);
			self.summary["headshots"]++;
		}

		ch_index = get_ch_index_byWeapon(weapon);
		if (isDefined(ch_index)) self survivor_update_challenge(ch_index);
	}
}

onPlayerLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if (isDefined(self.currMenu)) self closeMenu("dynamic_shop");

	self.removeLastStandWep = true;
	self.inLastStand = true;
	self.lastStand = true;
	self.hasRevive = false;
	self.health = self.maxhealth;
	self setClientDvar("ui_self_revive", 0);
	weapon = "iw5_fnfiveseven_mp";
	
	if (isdefined(level.ac130player) && isdefined(attacker) && level.ac130player == attacker) level notify("ai_crawling", self);

	self common_scripts\utility::_disableusability();
	self thread maps\mp\gametypes\_damage::enablelaststandweapons();
	
	notifyData = spawnstruct();
	notifyData.titletext = "Self Revive";
	notifyData.iconname = "specialty_finalstand";
	notifyData.glowcolor = (1.0, 0.0, 0.0);
	notifyData.sound = "mp_last_stand";
	notifyData.duration = 2.0;	
	self thread maps\mp\gametypes\_hud_message::notifymessage(notifyData);
	notifyData = undefined;
	
	lastStandBar = self maps\mp\gametypes\_hud_util::createPrimaryProgressBar();
	lastStandBar hud_set_point("CENTER", "BOTTOM", 0, -70);
	lastStandBar.useTime = 20;
	lastStandBar.overlay = self hud_fullscreen_overlay("combathigh_overlay");
	lastStandBar.icon = hud_create_icon(self, "specialty_self_revive", "CENTER", "BOTTOM", -100, -70, 30, 30);
	self.lastStandBar = lastStandBar;

	reviveEnt = spawn("script_model", self.origin);
	reviveEnt setModel("tag_origin");
	reviveEnt setCursorHint("HINT_NOICON");
	reviveEnt setHintString(&"PLATFORM_REVIVE");
	reviveEnt maps\mp\gametypes\_damage::reviveSetup(self);

	reviveIcon = newTeamHudElem(self.team);
	reviveIcon lethalbeats\hud::hud_set_shader("waypoint_revive", 8, 8);
	reviveIcon setWaypoint(true, true);
	reviveIcon setTargetEnt(self);
	reviveIcon thread maps\mp\gametypes\_damage::destroyOnReviveEntDeath(reviveEnt);
	reviveIcon.color = (0.33, 0.75, 0.24);

	self.reviveEnt = reviveEnt;

	self playSound("generic_death_american_" + randomIntRange(1, 8));
	self disableweaponswitch();
	self disableoffhandweapons();

	if (self hasWeapon(weapon)) self.removeLastStandWep = false;
	else self player_give_weapon(weapon);

	self switchtoweapon(weapon);
	self giveMaxAmmo(weapon);
	
	self thread maps\mp\gametypes\_damage::lastStandKeepOverlay();
	self thread survivor_watch_last_stand();
	self thread survivor_watch_last_stand_revive();
	self thread survivor_watch_last_stand_death();
}

onUseShop()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	
	for (;;)
	{
		self waittill("trigger_use", trigger);
		if (isDefined(self.currMenu) || !isAlive(self)) continue;
		if (trigger.tag == "weapon_shop") self lethalbeats\DynamicMenus\dynamic_shop::openShop("weapon_armory");
		else if (trigger.tag == "equipment_shop") self lethalbeats\DynamicMenus\dynamic_shop::openShop("equipment_armory");
		else if (trigger.tag == "support_shop") self lethalbeats\DynamicMenus\dynamic_shop::openShop("air_support_armory");
	}
}

onChangeWeapons()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");

	for(;;)
	{
		self waittill("weapon_change", newWeapon);

		if (!isDefined(newWeapon) || newWeapon == "none" || weaponClass(newWeapon) == "none") continue;

		if (weaponClass(newWeapon) != "grenade")
		{
			self player_take_all_weapon_buffs();
			weaponData = self lethalbeats\Survival\armories\weapons::getWeaponData(newWeapon);
			foreach(buff in weaponData[3]) self player_give_perk(buff, true);
		}
		
		self setClientDvar(UI_USE_SLOT, "none");
		if (player_has_nades(newWeapon)) self setClientDvar(UI_USE_SLOT, strtok(newWeapon, "_")[0]);
		else if(newWeapon != "none" && !isDefined(self.lastStand)) self.prevWeapon = newWeapon;
	}
}

onWeaponFire()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	
	for (;;)
	{	
		self waittill("weapon_fired", weaponName);
		if (!isAlive(self)) continue;
		switch (weaponClass(weaponName))
		{
			case "rifle":
			case "pistol":
			case "mg":
			case "smg":
			case "spread":
				self.summary["totalshots"]++;
				break;
		}
	}
}

onHideScore()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");

	show_score = "show_score";
	hide_score = "hide_score";

	self notifyOnPlayerCommand(show_score, "+scores");
	self notifyOnPlayerCommand(hide_score, "-scores");
	
	for(;;)
	{
		result = self lethalbeats\utility::waittill_any_return(show_score, hide_score);
		if (!isAlive(self)) continue;
		if (result == hide_score) self survivor_display_hud("show_armor");
	}
}

dropWeaponMonitor()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");

	self survivor_display_hud("bind_weapon_drop");
	self notifyOnPlayerCommand("drop_weapon", "pause");
	
	for (;;)
	{
		self waittill("drop_weapon");

		if (!self player_get_weapons().size) continue;

		weapon = self getCurrentWeapon();
		if (!isDefined(weapon)) weapon = "none";
		if (weapon != "none") self player_take_all_weapon_buffs();

		self.droppeddeathweapon = undefined;
		self.lastdroppableweapon = weapon;
		self maps\mp\gametypes\_weapons::dropWeaponForDeath(self);
		self playSound("ammo_crate_use");

		weapons = lethalbeats\player::player_get_weapons();
		if (weapons.size) self switchToWeaponImmediate(weapons[0]);
	}
}

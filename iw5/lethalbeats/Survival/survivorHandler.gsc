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

#define MOD_MULTIPLIER ["MOD_EXPLOSIVE", "MOD_GRENADE", "MOD_GRENADE_SPLASH", "MOD_PROJECTILE", "MOD_PROJECTILE_SPLASH", "MOD_RIFLE_BULLET"]

onPlayerDisconnect()
{
	for (;;)
    {
        self waittill("disconnect");

		bleedoutObjects = level.survivors_bleedout[self.guid];
		if (isDefined(bleedoutObjects))
		{
			bleedoutObjects[0] lethalbeats\trigger::trigger_delete();
			bleedoutObjects[1] hud_destroy();
			if (isDefined(bleedoutObjects[2])) bleedoutObjects[2] delete();
		}

		if (!survivors(true).size) kill_all_survivors();
    }
}

onPlayerSpawn()
{
	level endon("game_ended");
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");

		self survivor_init_summary();
		self.survivalPerks = [];
		self.grenades = [];
		self.turrets = [];
		self.airdrops = [];
		self.inLastStand = false;
		self.currMenu = undefined;
		self.iscarrying = false;
		self.dropWeapon = true;
		self.enableUse = true;
		self.dogKnockdown = false;

		if (!self survivor_load_state())
		{
			self.prevWeapon = self getCurrentWeapon();
			self.weaponData = [self player_create_weapon_data(self.prevWeapon), undefined];
			self survivor_clear_perks();
			self survivor_set_score(getDvarInt("survival_start_money"));
			self survivor_give_body_armor();
			self survivor_give_last_stand();
			self player_clear_nades();
			self player_set_nades(FLASH, 2);
			self player_set_nades(FRAG, 2);

			if (getDvarInt("survival_wait_respawn") && (isDefined(level.survivors_deaths[self.guid]) || isDefined(level.survivors_bleedout[self.guid])))
			{
				self player_clear_last_stand();
				self thread player_black_screen();
				self suicide();
				continue;
			}
			else self thread survivor_zoom_effect();
		}
		
		self setClientDvar(UI_USE_SLOT, "none");
		self setClientDvar("client_cmd", "");
		
		self openMenu("perk_hide");
		self survivor_init_challenge();

		self thread player_refill_nades();
		self thread onWeaponFire();
		self thread onWeaponSwitchStarted();
		self thread onWeaponChange();
		self thread onOffhandEnd();
		self thread onUseShop();
		self thread onHideScore();
		self thread dropWeaponMonitor();
		self thread onPlayerMelee();
		self thread onHoldBreath();

		self notify("weapon_change", self getCurrentWeapon());
		if (self isTestClient()) self survivor_take_last_stand();
 	}
}

playerWaitRespawn()
{	
	level endon("game_ended");
	self endon("disconnect");

	self survivor_destroy_hud();
	if (!getDvarInt("survival_wait_respawn")) return;

	// (つ◉益◉)つ previously, I iterated through level.players and checked with isAlive, but for some fcking reason, isAlive now returns true in this respawndelay section, wtf pluto r4906!!!
	if (!survivors(true).size)
	{
		rotate_wait = 15;
		foreach(player in survivors())
		{
			player suicide();
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

onPlayerMelee()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	
	self notifyOnPlayerCommand("melee", "+melee_zoom");

	for(;;)
	{
		self waittill("melee");

		angleDeg = 95;
		eyePos = self getEye();
		angles = self.angles;
		pos = self.origin;
		lastDistance = undefined;
		target = undefined;

		foreach(dog in bots("dog", true))
		{
			dogOrigin = dog.origin;
			if (lethalbeats\collider::pointInCone(dogOrigin, eyePos, angles, angleDeg, 80))
			{
				dogDistance = distanceSquared(pos, dogOrigin);
				if (!isDefined(lastDistance) || lastDistance > dogDistance)
				{
					lastDistance = dogDistance;
					target = dog;
				}
			}
		}

		if (isDefined(target))
		{
			newAngle = vectorToAngles(target.origin - eyePos);
			self setPlayerAngles(newAngle);
			wait 0.05;
			self setPlayerAngles(newAngle);
			wait 0.05;
		}
	}
}

onPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
	if (isDefined(self.dogKnockdown) && self.dogKnockdown) return;
	if (isDefined(eAttacker) && isDefined(eAttacker.team) && eAttacker.team == "allies" && eAttacker != self) return;
	if (lethalbeats\array::array_contains(MOD_MULTIPLIER, sMeansOfDeath))
	{
		iDamage *= 4;
		if ((sMeansOfDeath != "MOD_RIFLE_BULLET" && self player_has_perk("_specialty_blastshield")) || (isDefined(eAttacker) && eAttacker == self)) 
			iDamage /= 2;
	}
	else
	{
		if (isDefined(eAttacker) && eAttacker == self) iDamage /= 2;
		else if (self player_has_weapon("riotshield_mp")) iDamage /= 3;
	}

	if (isDefined(sHitLoc) && sHitLoc == "shield") return;
	if (isDefined(eAttacker))
	{
		if (eAttacker bot_is_dog()) eAttacker lethalbeats\Survival\abilities\_dog::onDogPlayerDamage(self);
		if (isDefined(eAttacker.owner)) eAttacker = eAttacker.owner;
	}

	iDamage /= 20;
	self.summary["damagetaken"] += iDamage;
	
	if (self.inLastStand)
	{
		if (self.lastStandBar.type == "revive")
		{
			self.lastStandBar.frac -= 0.15;
			self.lastStandBar.frac = max(0, self.lastStandBar.frac);
			self.lastStandBar hud_update_bar(self.lastStandBar.frac, 0);
			self.lastStandBar.bar.color = (1, self.lastStandBar.frac, 0);
		}
		return;
	}

	if (level.difficulty == 1) iDamage *= 0.8;
	
	if(self.bodyArmor > 0 && sMeansOfDeath != "MOD_TRIGGER_HURT")
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
	if (!isDefined(level.survivors_deaths[self.guid]))
	{
		if (getDvarInt("survival_wait_respawn")) level.survivors_deaths[self.guid] = 1;
		if (isDefined(self.currMenu)) self closeMenu("dynamic_shop");
		self survivor_take_body_armor();
	}
	
	self [[level.prevCallbackPlayerKilled]](eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
}

onPlayerBotKilled(bot, damage, meansOfDeath, weapon)
{
	if (self.inLastStand && isDefined(self.lastStandBar.type) && self.lastStandBar.type == "revive") 
	{
		self notify("auto_revive");
		self survivor_revive();
	}
	
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

	self.inLastStand = true;
	self.lastStand = true;
	self.health = self.maxhealth;
	self.prevWeapon = self getCurrentWeapon();

	self playSound("generic_death_american_" + randomIntRange(1, 8));
	self player_give_laststand_weapon("iw5_fnfiveseven_mp");

	lastStandBar = hud_create_bar(self, 130, 12);
	lastStandBar hud_set_point("CENTER", "BOTTOM", 0, -70);

	if (self.hasRevive)
	{
		notifyData = spawnstruct();
		notifyData.titletext = "Self Revive";
		notifyData.iconname = "specialty_self_revive";
		notifyData.glowcolor = (1.0, 0.0, 0.0);
		notifyData.sound = "mp_last_stand";
		notifyData.duration = 2.0;
		self thread hud_notify_message(notifyData);
		notifyData = undefined;

		overlay = self hud_fullscreen_overlay("combathigh_overlay");
		overlay hud_set_parent(lastStandBar);

		icon = self hud_create_icon(self, "specialty_self_revive", "CENTER", "BOTTOM", -100, -70, 30, 30);
		icon hud_set_parent(lastStandBar);

		lastStandBar hud_create_3d_objective("allies", "specialty_self_revive", 8, 8, self);
		lastStandBar.type = "revive";
		self.lastStandBar = lastStandBar;

		self thread lastStandMonitor();
	}
	else
	{
		overlay = self hud_fullscreen_overlay("screen_blood_directional_center");
		overlay hud_set_parent(lastStandBar);

		icon = self hud_create_icon(self, "waypoint_revive", "CENTER", "BOTTOM", -100, -70, 30, 30);
		icon hud_set_parent(lastStandBar);

		lastStandBar hud_create_3d_objective("allies", "waypoint_revive", 8, 8, self);
		lastStandBar.objective.color = (0.33, 0.75, 0.24);
		lastStandBar.type = "death";

		trigger = lethalbeats\trigger::trigger_create(self.origin, 60);
		trigger lethalbeats\trigger::trigger_set_use_hold(10, "Hold ^3[{+activate}] ^7to revive the player", true, false);
		trigger lethalbeats\trigger::trigger_set_enable_condition(::survivor_trigger_filter);
		trigger lethalbeats\trigger::trigger_link_to(self);
		trigger.tag = "revive";

		lastStandBar.trigger = trigger;
		self.lastStandBar = lastStandBar;

		if (getDvarInt("survival_wait_respawn"))
			level.survivors_bleedout[self.guid] = [trigger, lastStandBar, undefined];

		trigger thread reviveMonitor(self);
		self thread deathMonitor(30, trigger);

		if (!survivors(true).size)
		{
			kill_all_survivors();
			return;
		}
	}

	self survivor_take_last_stand();
	self thread maps\mp\gametypes\_damage::lastStandKeepOverlay();
}

lastStandMonitor()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
    self endon("auto_revive");

    useTime = 10;
	self.lastStandBar.frac = 0;
    for (i = 0; i < useTime; i++)
    {
        self.lastStandBar.frac = i / useTime;
        self.lastStandBar hud_update_bar(self.lastStandBar.frac, 0);
        self.lastStandBar.bar.color = (1, self.lastStandBar.frac, 0);
        wait 1;
    }
	self survivor_revive();
}

deathMonitor(lifeTime, trigger)
{
    level endon("game_ended");
	self endon("disconnect");
	self endon("death");
    self endon("revive");

	barFrac = 0;
    for (i = lifeTime; i > 0; i--)
    {
        barFrac = i / lifeTime;
        self.lastStandBar hud_update_bar(barFrac, 0);
        self.lastStandBar.bar.color = (1, barFrac, barFrac);

		if (isString(trigger lethalbeats\utility::waittill_any_return(1, "trigger_use_hold"))) 
			trigger waittill("trigger_hold_interrump");
    }
	waittillframeend;

	self maps\mp\_utility::playDeathSound();
	self player_clear_last_stand();
    self suicide();
}

reviveMonitor(player)
{
	level endon("game_ended");
    self endon("death");
    player endon("disconnect");
    player endon("death");

	for(;;)
	{
		self waittill("trigger_use_hold", savior);

		reviveSpot = spawn("script_origin", self.origin);
		reviveSpot.angles = player.angles;
		reviveSpot hide();
		level.survivors_bleedout[player.guid][2] = reviveSpot;

		player playerLinkTo(reviveSpot);
		player playerLinkedOffsetEnable();
		player.reviveSpot = reviveSpot;

		result = savior lethalbeats\utility::waittill_any_return("trigger_hold_interrump", "trigger_hold_complete");
		
		player unlink();
		reviveSpot delete();
		level.survivors_bleedout[player.guid][2] = undefined;

		if (result == "trigger_hold_interrump") continue;

		savior playLocalSound("mp_killconfirm_tags_pickup");
		player survivor_revive();
		break;
	}
}

onUseShop()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	
	for (;;)
	{
		self waittill("trigger_use", trigger);
		if (isDefined(self.currMenu)) continue;
		if (trigger.tag == "weapon") self lethalbeats\DynamicMenus\dynamic_shop::openShop("weapon_armory");
		else if (trigger.tag == "equipment") self lethalbeats\DynamicMenus\dynamic_shop::openShop("equipment_armory");
		else if (trigger.tag == "support") self lethalbeats\DynamicMenus\dynamic_shop::openShop("air_support_armory");
	}
}

onWeaponSwitchStarted()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");

	for(;;)
	{
		self waittill("weapon_switch_started", newWeapon);

		self.enableUse = false;
		if(newWeapon != "none" && !isDefined(self.lastStand))
			self.prevWeapon = self getCurrentWeapon();

		self thread _forceNotifyUpdate();
	}
}

_forceNotifyUpdate()
{
	self endon("weapon_switch_started");
	self endon("weapon_change");
	wait 2;
	waittillframeend;
	self notify("weapon_change", self.prevWeapon);
}

onWeaponChange()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");

	for(;;)
	{
		self waittill("weapon_change", newWeapon);

		isGrenade = weaponClass(newWeapon) == "grenade";
		if (isGrenade || self maps\mp\_utility::isKillstreakWeapon(newWeapon)) self.enableUse = false;
		else
		{
			weapon = lethalbeats\weapon::weapon_get_baseName(newWeapon) + "_mp";
			self.enableUse = maps\mp\gametypes\_class::isValidWeapon(weapon);
		}

		if (!isDefined(newWeapon) || newWeapon == "none" || weaponClass(newWeapon) == "none") continue;
		if (!isGrenade)
		{
			self player_take_all_weapon_buffs();
			weaponData = self player_get_weapon_data(newWeapon);
			foreach(buff in weaponData[3]) self player_give_perk(buff, true);
		}
		
		self setClientDvar(UI_USE_SLOT, "none");
		if (player_has_nades(newWeapon)) self setClientDvar(UI_USE_SLOT, strtok(newWeapon, "_")[0]);
	}
}

onOffhandEnd()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");

	for(;;)
	{
		self lethalbeats\utility::waittill_any("grenade_fire", "offhand_end");
		waittillframeend;
		self notify("weapon_change", self getCurrentWeapon());
	}
}

onWeaponFire()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");

	self.blindeyeActive = false;

	for (;;)
	{
		self waittill("weapon_fired", weaponName);

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

		if (lethalbeats\weapon::weapon_has_silencer(weaponName))
		{
			if (self.blindeyeActive) self notify("cancel_unset_blindeye");
			else
			{
				self.blindeyeActive = true;
				self player_give_perk("specialty_blindeye");
			}
			self thread unsetBlindEye();
		}
	}
}

unsetBlindEye()
{
	self endon("disconnect");
	self endon("death");
	self endon("cancel_unset_blindeye");

	wait 2;

	self player_unset_Perk("specialty_blindeye");
	self.blindeyeActive = false;
}

onHoldBreath()
{
    level endon("game_ended");
	self endon("disconnect");
	self endon("death");

	self notifyonplayercommand("hold_breath", "+breath_sprint");
	self notifyonplayercommand("hold_breath", "+melee_breath");
	self notifyonplayercommand("release_breath", "-breath_sprint");
	self notifyonplayercommand("release_breath", "-melee_breath");

    for (;;)
    {
        self waittill("hold_breath");
		self maps\mp\_utility::setRecoilScale(0, 40);

        self waittill("release_breath");

		weapClass = maps\mp\_utility::getWeaponClass(self getCurrentPrimaryWeapon());

        if (self.stance == "prone")
        {
            if (weapClass == "weapon_lmg") self maps\mp\_utility::setRecoilScale(0, 40);
            else if (weapClass == "weapon_sniper") self maps\mp\_utility::setRecoilScale(0, 60);
            else self maps\mp\_utility::setRecoilScale();
			continue;
        }

        if (self.stance == "crouch")
        {
            if (weapClass == "weapon_lmg") self maps\mp\_utility::setRecoilScale(0, 10);
            else if (weapClass == "weapon_sniper") self maps\mp\_utility::setRecoilScale(0, 30);
            else self maps\mp\_utility::setRecoilScale();
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

	lbDiscord = hud_create_string(self, "^4Discord^7: https://discord.gg/PrpYznV33s", "hudsmall", 0.8, "TOP CENTER", "TOP CENTER", 0, 10);
	lbDiscord.alpha = 0;
	lbDiscord.hideWhenInMenu = false;
	
	for(;;)
	{
		result = self lethalbeats\utility::waittill_any_return(show_score, hide_score);
		if (!isAlive(self)) continue;
		if (result == hide_score)
		{
			lbDiscord.alpha = 0;
			self survivor_display_hud("show_armor");
		}
		else lbDiscord.alpha = 1;
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

		if (self player_get_weapons().size < 2 || self.inLastStand) continue;
		if (is_shop_near(self.origin))
		{
			self hud_set_lower_message("fail_drop_weapon", "You cannot drop a weapon while near the terminals.", 2, 1);
			wait 2;
			self hud_clear_lower_message("fail_drop_weapon");
			continue;
		}

		self player_drop_weapon();
		self playSound("ammo_crate_use");

		weapons = lethalbeats\player::player_get_weapons();
		if (weapons.size) self survivor_switch_to_weapon(weapons[0]);
	}
}

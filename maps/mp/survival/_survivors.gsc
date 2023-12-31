#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\survival\_utility;

init()
{
	level thread onPlayerConnecting();
}

onPlayerConnecting()
{
	level endon("game_ended");
	
	for (;;)
	{
		level waittill("connecting", player);
		
		if(player isTestClient()) continue;
		
		player thread maps\mp\survival\_menu_options::onMenuResponse();
		
		player maps\mp\gametypes\_menus::addToTeam("allies", 1);
		player waittill("begin");
		player.pers["score"] = 0;
		
		player thread onPlayerSpawn();
		player thread onChangeWeapons();
		player thread onIntermission();
	}
}

onPlayerSpawn()
{
	self endon("disconnect");
	
	for(;;)
	{
		self waittill("spawned_player");
		
		self.survivalPerks = [];
		self.grenades = [];
		
		self setNades("claymore_mp", 0);
		self setNades("c4_mp", 0);
		self setNades("throwingknife_mp", 0);
		self setNades("concussion_grenade_mp", 0);
		self setNades("flash_grenade_mp", 2);
		self setNades("frag_grenade_mp", 2);
		
		self setClientDvar("ui_streak", "");
		self setClientDvar("ui_body_armor", 1);
		self setClientDvar("ui_self_revive", 1);
		self setClientDvar("ui_use_slot", "none");
		self setClientDvar("client_cmd", "");
		
		self.bodyArmor = 250;
		self.hasRevive = 1;
		self.onTrigger = undefined;
		self.currMenu = undefined;
		self.isCarryObject = 0;
		
		self clearSurvivalPerks();
		self notifyHideInMenu(0);
		self openMenu("perk_hide");
		self cameraEffect();
		self hudInit();	
		self summaryInit();
		self setScore(500);

		self.prevWeapon = self getCurrentWeapon();		
		self givePerk("specialty_finalstand", false);
		
		self thread triggerUseHandle();
		self thread watchTotalShots();
		self thread summaryMonitor();		
		self thread onStartGame();
		self thread refillNades();
		
		self thread maps\mp\survival\_menu_armory::onMenuResponse();
		self thread maps\mp\survival\_menu_equipment::onMenuResponse();
		self thread maps\mp\survival\_menu_support::onMenuResponse();
	}
}

onPlayerDeath()
{
	if(getDvarInt("survival_dev_mode")) return;
	
	self clearLowerMessage("spawn_info");
	
	if(!level.game_ended && survivorsCount() == 1 || allSurvivorsDeath()) 
	{
		level.game_ended = 1;
		level notify("all_survivors_death", 17); //load dsr & change map have 3sec delay
		
		foreach(player in level.players)
			if(player.team == "allies")
			{
				self setLowerMessage("spawn_info", "All survivors death waiting to map restart", 20, 1, 1);
				self.lowerMessage.alpha = 1;
			}
	}
	else self setLowerMessage("spawn_info", "Waiting for other players revive you on support shop");
	
	self thread maps\mp\gametypes\_playerlogic::spawnSpectator(self.origin - (0, 0, 60), self.angles);
	
	self allowSpectateTeam("allies", 1);
	self allowSpectateTeam("axis", 0);
	self allowSpectateTeam("freelook", 0);
	self allowSpectateTeam("none", 0);
	
	self destroySurvivalHuds();
	
	level waittill("survivor_respawn");
	self maps\mp\gametypes\_playerlogic::waitAndSpawnClient();
}

onPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
	iDamage /= 20;
	self.summary["damagetaken"] += iDamage;
	
	if (isDefined(eAttacker) && eAttacker is_dog()) eAttacker notify("dog_attack", self);
	if(self.bodyArmor > 0)
	{
		self onDamageArmor(iDamage);
		return 0;
	}
	else if(isDefined(self.lastStand) && self.barFrac > 0)
	{
		self.lastStandBar updateBar((self.barFrac - 6) / 20, 0);
		return 0;
	}

	self [[level.prevCallbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
}

onPlayerBotDamage(bot, damage, meansOfDeath, weapon)
{
	if (!contains(weapon, self getWeaponsListPrimaries())) return;
	
	wep_class = weaponClass(weapon);
	if(isDefined(wep_class))
	{
		switch(wep_class)
		{
			case "rifle":
			case "pistol":
			case "mg":
			case "smg":
			case "spread": self.summary["hits"]++; break;
		}
		
		if (self.summary["hits"] <= self.summary["totalshots"]) self.summary["accuracy"] = clamp(self.summary["hits"] / self.summary["totalshots"], 0.0, 1.0) * 100;
	}
}

onPlayerKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	self clearLastStand();
	if (isDefined(self.currMenu)) self maps\mp\lethalbeats\_dynamic_menu::closeDynamicMenu();
	self hideArmorHud();
	
	self [[level.prevCallbackPlayerKilled]](eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
}

onPlayerBotKilled(bot, damage, meansOfDeath, weapon)
{
	self.summary["kills"]++;
	
	if (isDefined(self.laststand)) self notify("lastStandKill");

	self checkChallenge("kill");	
	
	if (meansOfDeath == "MOD_MELEE") self checkChallenge("knife");	
	else if (meansOfDeath == "MOD_GRENADE" || meansOfDeath == "MOD_GRENADE_SPLASH" || weaponClass(weapon) == "grenade") self checkChallenge("grenade");
	else
	{
		if (meansOfDeath == "MOD_HEAD_SHOT")
		{
			self checkChallenge("headshot");
			self.summary["headshots"]++;
		}
		
		wepClass = strTok(getWeaponClass(weapon), "_")[1];
		if (isDefined(wepClass))
		{
			if (wepClass == "projectile") wepClass = "launcher";
			self checkChallenge(wepClass);
		}
	}
}

onPlayerLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self.lastStand = 1;	
	
	if (isDefined(self.currMenu)) self maps\mp\lethalbeats\_dynamic_menu::closeDynamicMenu();
	self hideArmorHud();
	
	lastStandParams = spawnstruct();
    lastStandParams.einflictor = eInflictor;
    lastStandParams.attacker = attacker;
    lastStandParams.idamage = iDamage;
    lastStandParams.attackerposition = attacker.origin;

    if (attacker == self) lastStandParams.smeansofdeath = "MOD_SUICIDE";
    else lastStandParams.smeansofdeath = sMeansOfDeath;

    lastStandParams.sweapon = sWeapon;

    if (isdefined(attacker) && isplayer(attacker) && attacker getcurrentprimaryweapon() != "none") lastStandParams.sprimaryweapon = attacker getcurrentprimaryweapon();
    else lastStandParams.sprimaryweapon = undefined;

    lastStandParams.vdir = vDir;
    lastStandParams.shitloc = sHitLoc;
    lastStandParams.laststandstarttime = gettime();
    lastStandParams = true;

	if (isdefined(level.ac130player) && isdefined(attacker) && level.ac130player == attacker) level notify("ai_crawling", self);

	self.laststandparams = lastStandParams;
	self common_scripts\utility::_disableusability();
	self thread maps\mp\gametypes\_damage::enablelaststandweapons();
	
	notifyData = spawnstruct();
	notifyData.titletext = "Self Revive";
	notifyData.iconname = "specialty_finalstand";
	notifyData.glowcolor = (1.0, 0.0, 0.0);
	notifyData.sound = "mp_last_stand";
	notifyData.duration = 2.0;
	
	self thread maps\mp\gametypes\_hud_message::notifymessage(notifyData);
	
	self.health = self.maxhealth;
	self.hasRevive = 0;
	self setClientDvar("ui_self_revive", 0);
	
	weapon = "iw5_fnfiveseven_mp";
	
	if (self hasWeapon(weapon)) self.lastStandWeapon = undefined;
	else self.lastStandWeapon = 1;
	
	self _giveweapon(weapon);
	self givemaxammo(weapon);
	
	self disableweaponswitch();
	self disableoffhandweapons();
	self switchtoweapon(weapon);
	self thread lastStandTimer();
}

lastStandTimer()
{
	self endon("death");
    self endon("disconnect");
    self endon("revive");
    level endon("game_ended");
	
	self thread onlastStandKill();
	self thread maps\mp\gametypes\_damage::lastStandKeepOverlay();
	
	overlay = newClientHudElem(self);
	overlay.x = 0;
	overlay.y = 0;
	overlay.alignX = "left";
	overlay.alignY = "top";
	overlay.horzAlign = "fullscreen";
	overlay.vertAlign = "fullscreen";
	overlay setshader ("combathigh_overlay", 640, 480);
	overlay.sort = -10;
	overlay.archived = true;
	
	icon = self createIcon("specialty_self_revive", 30, 30);
	icon setpoint("CENTER", "BOTTOM", -100, -70);
	
	lastStandBar = self createPrimaryProgressBar();
	lastStandBar setPoint("CENTER", "BOTTOM", 0, -70);
	lastStandBar.useTime = 20;
	lastStandBar.overlay = overlay;
	lastStandBar.icon = icon;
	self.lastStandBar = lastStandBar;
	
    self.barFrac = 10;
    while (self.barFrac < 20)
    {
        self.lastStandBar updateBar(self.barFrac / 20, 0);
		self.lastStandBar.bar.color = (1, self.barFrac / 20, 0);
		self.barFrac++;
        wait 1;
    }
	self _revive();
}

onlastStandKill()
{
	self endon("revive");
    self endon("death");
	
	self waittill("lastStandKill");
	self _revive();
}

onStartGame()
{
	if (getDvarInt("disable_waves")) return;
	
	level endon("wave_end");
	
	if (level.wave_num) return;
	else level waittill("bots_connected");
	
	wait 0.7;
	level notify("wave_end");
}

summaryMonitor()
{
	level endon("game_ended");
	self endon("death");
	self endon("disconnect");
	
	level waittill("wave_end"); //wait first waves init
	
	for(;;)
	{
		result = level waittill_any_return("wave_end", "intermission");
		
		if (result == "wave_end")
		{
			time = int(int((gettime() - level.waveStartTime) / 1000) + "." + int(int((gettime() - level.waveStartTime) / 100) % 10));
			
			self setClientDvar("ui_wave_time", time);
			self setClientDvar("ui_wave_time_bonus", int(level.score_base / time));
			self setClientDvar("ui_wave_kills", self.summary["kills"]);
			self setClientDvar("ui_wave_headshots", self.summary["headshots"]);
			self setClientDvar("ui_wave_accuracy", self.summary["accuracy"]);
			self setClientDvar("ui_wave_damagetaken", self.summary["damagetaken"]);
			
			self _openMenu("wave_summary");
			self giveScore(int(level.score_base / time) + (level.wave_num * 30) + (self.summary["kills"] * 10) + (self.summary["headshots"] * 20) + (self.summary["accuracy"] * 3));
			continue;
		}
		
		self _closeMenu("wave_summary");
		self summaryInit();
	}
}

onIntermission()
{
	level endon("game_ended");
	self endon("death");
	self endon("disconnect");
	
	for(;;)
	{
		level waittill("intermission");
		
		self waveChallengesHudInit();
		self thread watchGlobalSkip();
		self thread watchSkipResponse();
	}
}

watchSkipResponse()
{
	level endon("wave_start");
	level endon("game_ended");
	self endon("death");
	self endon("disconnect");
	
	for(;;)
	{
		self waittill("menuresponse", menu, response);
		
		if (menu != "survival_hud") continue;
		if (response != "skip_timer") continue;
		
		level.timerSkip++;
		level notify("intermission_skip", survivorsCount() == 1);
		break;
	}
}

watchGlobalSkip()
{
	level endon("game_ended");
	self endon("death");
	self endon("disconnect");
	
	timerLabel = self createFontString("hudsmall", 0.8);
	timerLabel setPoint("TOP RIGHT", "TOP RIGHT", -135, 150);
	timerLabel setText("Press ^3F5 ^7to ready up: ");
	timerLabel.sort = 1001;
	timerLabel.foreground = true;
	timerLabel.hidewheninmenu = false;
	timerLabel.alpha = 0;	
	timerLabel fadeOverTime(0.8);
	timerLabel.alpha = 1;
	
	for(;;)
	{
		level waittill("intermission_skip", globalSkip);
		
		if (globalSkip)
		{
			timerLabel destroy();
			destroyIntermissionTimer();
			level notify("intermission_end");
			break;
		}
		else if (survivorsCount() < 2) timerLabel setText("Waiting other players ^3" + level.timerSkip + "^7/" + survivorsCount() + ": ");
	}
}

triggerUseHandle()
{
	self endon("disconnect");
	level endon("game_ended");
	self endon("death");
	
	for (;;)
	{
		self waittill("trigger_use", trigger);
		
		//shops		
		if (!isDefined(self.currMenu) && (trigger.tag == "weapon_shop" || trigger.tag == "equipment_shop" || trigger.tag == "support_shop"))
		{			
			self maps\mp\lethalbeats\_dynamic_menu::openDynamicMenu(trigger.tag);
			self loadItemCost();
			self notify("hide_hud");
			
			if (trigger.tag == "equipment_shop") self maps\mp\survival\_menu_equipment::checkOwnedEquipment();
			else if (trigger.tag == "support_shop") self maps\mp\survival\_menu_support::checkAllowedSupport();
			continue;
		}
		
		if (self.isCarryObject) continue;
		
		//sentry
		if (trigger.tag == "sentry_move")
		{
			self.isCarryObject = 1;
			
			trigger.sentry SetMode("sentry_offline");
			self thread maps\mp\killstreaks\_autosentry::setCarryingSentry(trigger.sentry, false);
			self thread maps\mp\killstreaks\_autosentry::updateSentryPlacement(trigger.sentry);
			trigger notify("delete");
			continue;
		}
		
		if (self hasStreak()) continue;
		
		//trophy
		if (trigger.tag == "trophy_pickup" && !(self hasStreak()))
		{			
			self setClientDvar("ui_streak", "hud_icon_trophy");
			self playLocalSound("scavenger_pack_pickup");
			self giveweapon("trophy_mp");
			self _setActionSlot(4, "weapon", "trophy_mp");
			
			trigger notify("delete");
			if(isDefined(trigger.trophy)) trigger.trophy delete();
			trigger.trophy notify("death");
			continue;
		}
	}
}

onChangeWeapons()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill ("weapon_change", newWeapon);
		
		if (newWeapon == "killstreak_predator_missile_mp") self setClientDvar("ui_streak", "");
		self.isCarrySentry = newWeapon == "trophy_mp" ? 1 : undefined;
		
		self setClientDvar("ui_use_slot", "none");
		if (contains(newWeapon, getarraykeys(self.grenades))) self setClientDvar("ui_use_slot", strtok(newWeapon, "_")[0]);
		else if(!isDefined(self.lastStand)) self.prevWeapon = newWeapon;
	}
}

cameraEffect()
{
	self allowAds(0);
	self freezeControls(1);
	self disableWeapons();
	
	angles = self GetPlayerAngles();	
	camera = spawn("script_model", self.origin + (0, 0, 3000));
	camera setModel("c130_zoomrig");
	camera notSolid(0);
	camera hide();
	camera showToPlayer(self);
	camera.angles = (90, angles[1], 0);
	
	self cameraLinkTo(camera, "tag_origin");	
	
	self visionSetNakedForPlayer("blacktest", 0);
	wait 0.5;
	self visionSetNakedForPlayer("", 2);
	
	self playLocalSound("survival_slamzoom");
	
	camera moveTo(self.origin + (0, 0, 180), 1.5);
	
	wait 1.5;
	self visionSetNakedForPlayer("coup_sunblind", 0);
	self cameraUnlink();
	self visionSetNakedForPlayer("", 0.5);
	
	self allowAds(1);
	self freezeControls(0);
	self enableWeapons();
	
	camera delete();
}

watchTotalShots()
{
	level endon("game_ended");
	self endon("death");
	self endon("disconnect");
	
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
	}
}

hudInit()
{
	self _openMenu("survival_hud");
		
	self armorHudInit();
	self waveChallengesHudInit();
	self thread onOpenMenu();
	self thread onCloseMenu();
	self maps\mp\lethalbeats\_trigger::clearCustomHintString();
}

armorHudInit()
{
	if (isDefined(self.armorHuds)) return;
	
	armorText = self createFontString("default", 1.5);
	armorText setPoint("CENTER", "BOTTOM", -35, -55);
	armorText setText("Armor");
	armorText.alpha = 0.8;
	armorText.glowColor = (0.71, 0.65, 0.26);
	armorText fadeOverTime(0.5);
	
	armorAmount = self createFontString("default", 1.5);
	armorAmount setPoint("CENTER", "BOTTOM", 35, -55);
	armorAmount.alpha = 0.8;
	armorAmount.glowColor = (0.71, 0.65, 0.26);
	armorAmount fadeOverTime(0.5);
	
	self.armorHuds = [armorText, armorAmount];	
	self thread onDamageArmorHud();
}

waveChallengesHudInit()
{
	ch1 = random(level.challenges);
	ch2 = random(level.challenges);
	
	while(ch2 == ch1)
		ch2 = random(level.challenges);
	
	if (isDefined(self.ch1))
	{
		self updateChallenge(0, ch1);
		self updateChallenge(1, ch2);
		return;
	}
	
	self.ch1["type"] = ch1;
	self.ch1["amount"] = 0;
	self.ch1["huds"] = createChallengeHud(-34, ch1, 500);
	
	self.ch2["type"] = ch2;
	self.ch2["amount"] = 0;
	self.ch2["huds"] = createChallengeHud(-60, ch2, 500);
}

summaryInit()
{
	self.summary = [];
	self.summary["kills"] = 0;
	self.summary["headshots"] = 0;
	self.summary["accuracy"] = 0;
	self.summary["damagetaken"] = 0;
	self.summary["totalshots"] = 0;
	self.summary["hits"] = 0;
}

onOpenMenu()
{
	self notifyOnPlayerCommand("hide_hud", "+scores");
	self.hudHide = false;
	
	for(;;)
	{
		self waittill("hide_hud");
		
		if(self.hudHide) continue;
		
		foreach(hud in self.armorHuds) hud.alpha = 0;
		foreach(hud in self.ch1["huds"]) hud.alpha = 0;
		foreach(hud in self.ch2["huds"]) hud.alpha = 0;
		self.ch1["huds"][0].bar.alpha = 0;
		self.ch2["huds"][0].bar.alpha = 0;
		self.hudHide = true;
		
		if (isDefined(self.hintString)) self.hintString.alpha = 0;
	}
}

onCloseMenu()
{
	self notifyOnPlayerCommand("show_hud", "-scores");
	self.hudHide = false;
	
	for(;;)
	{
		self waittill("show_hud");
		
		if(!self.hudHide || isDefined(self.currMenu)) continue;
		
		if(self.bodyArmor > 0)
		{
			foreach(hud in self.armorHuds) hud.alpha = 0.8;
			self notify("armor_damage");
			self thread onDamageArmorHud();
		}
		
		foreach(hud in self.ch1["huds"]) hud.alpha = 0.8;
		foreach(hud in self.ch2["huds"]) hud.alpha = 0.8;
		self.ch1["huds"][0].alpha = 0.5;
		self.ch2["huds"][0].alpha = 0.5;
		self.ch1["huds"][0].bar.alpha = 1;
		self.ch2["huds"][0].bar.alpha = 1;
		self.hudHide = false;
		
		if (isDefined(self.hintString)) self.hintString.alpha = 1;
	}
}

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
		
		player maps\mp\gametypes\_menus::addToTeam("allies", 1);
		player waittill("begin");
		player.pers["score"] = 0;
		
		player thread onPlayerSpawn();
		player thread onChangeWeapons();
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
		
		self setClientDvar("ui_body_armor", 250);
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
				
		self thread watchTotalShots();
		self thread summaryMonitor();		
		self thread onStartGame();
		self thread refillNades();

		self thread maps\mp\survival\_menus::shopTrigger();
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
	if (isDefined(self.currMenu)) self closeMenu("dynamic_shop");
	self setClientDvar("ui_body_armor", 0);
	
	self [[level.prevCallbackPlayerKilled]](eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
}

onPlayerBotKilled(bot, damage, meansOfDeath, weapon)
{
	self giveScore(bot.botPrice);
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
	
	if (isDefined(self.currMenu)) self closeMenu("dynamic_shop");
	self setClientDvar("ui_body_armor", 0);
	
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
			self hudDisplay("wave_summary");
			self giveScore(int(level.score_base / time) + (level.wave_num * 30) + (self.summary["kills"] * 10) + (self.summary["headshots"] * 20) + (self.summary["accuracy"] * 3));
			continue;
		}
		self summaryInit();
	}
}

watchSkipResponse()
{
	level endon("intermission_end");
	self endon("disconnect");

	self hudDisplay("bind_skip_intermission");

	timerLabel = self createFontString("hudsmall", 0.8);
	timerLabel setPoint("TOP RIGHT", "TOP RIGHT", -135, 150);
	timerLabel setText("Press ^3[{skip}] ^7to ready up: ");	
	timerLabel.sort = 1001;
	timerLabel.foreground = true;
	timerLabel.hidewheninmenu = false;
	timerLabel.alpha = 0;	
	timerLabel fadeOverTime(0.8);
	timerLabel.alpha = 1;
	self.skipLabel = timerLabel;
	
	self notifyonplayercommand("skip_intermission", "skip");
	self waittill("skip_intermission");
		
	level.skip_intermission++;
	if (level.skip_intermission == survivorsCount())
	{
		if (survivorsCount() > 1) timerLabel setText("     Waiting other players ^3" + level.skip_intermission + "^7/" + survivorsCount() + ": ");
		level.timerHud destroy();
		level notify("intermission_end");
	}
}

onChangeWeapons()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill ("weapon_change", newWeapon);

		if (isDefined(self.primaryBuffs))
		{
			is_primary = newWeapon == self getWeaponsListPrimaries()[0];
			if(is_primary)
			{
				foreach(buff in self.secondaryBuffs)
					if (_hasperk(buff)) self _unsetPerk(buff);

				foreach(buff in self.primaryBuffs)
					self givePerk(buff, true);
			}
			else
			{
				foreach(buff in self.primaryBuffs)
					if (_hasperk(buff)) self _unsetPerk(buff);

				foreach(buff in self.secondaryBuffs)
					self givePerk(buff, true);
			}
		}
		
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
	self waveChallengesHudInit();
	self maps\lethalbeats\_trigger::clearCustomHintString();
}

waveChallengesHudInit()
{
	foreach(player in level.players)
		if(!(player isTestClient()))
		{
			ch0 = random(level.challenges);
			ch1 = random(level.challenges);
			
			while(ch1 == ch0)
				ch1 = random(level.challenges);

			player setChallenge(0, ch0, 5);
			player setChallenge(1, ch1, 5);
		}
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

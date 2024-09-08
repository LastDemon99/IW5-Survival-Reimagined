#include common_scripts\utility;
#include maps\mp\_utility;
#include lethalbeats\survival\_utility;

addBot()
{
	bot = addTestClient();
	
	bot.pers["isBot"] = true;
	bot.pers["isBotWarfare"] = true;
	bot.pers["score"] = 0;
	bot.pers["team"] = "axis";	
	bot.sessionteam = "axis";
	bot.botType = "easy";
	
	bot thread maps\mp\bots\_bot::added();
	bot thread onBotSpawn();

	level.bots_connected++;
	if (level.bots_connected == level.bots_size) level notify("bots_connected");
}

onBotSpawn()
{
	level endon("game_ended");
	self endon("disconnect");
	
	for(;;)
	{
		self waittill("spawned_player");
		
		if(!level.wave_num)
		{
			self suicide();
			continue;
		}
		
		self.hitsData = [];		
		self.grenades = [];
	
		self setNades("semtex_mp", 0);
		self setNades("concussion_grenade_mp", 0);
		self setNades("frag_grenade_mp", 0);
		self setNades("flash_grenade_mp", 0);
		self setNades("claymore_mp", 0);
		self setNades("c4_mp", 0);
		self setNades("throwingknife_mp", 0);
		
		self disableWeaponPickup();
		self setBotLoadout();
		
		switch(self.botType)
		{
			case "martyrdom": 
				self lethalbeats\survival\abilities\_martyrdom::giveAbility();
				continue;
			case "chemical": 
				self lethalbeats\survival\abilities\_chemical::giveAbility();
				continue;
			case "chopper":
				self [[level.killStreakFuncs["littlebird_survival"]]]();
				self suicide();
				continue;
			case "jugg_regular":
			case "jugg_riotshield":
			case "jugg_explosive":
			case "jugg_minigun":
				self lethalbeats\survival\abilities\_juggernaut::giveAbility();
				continue;
			case "dog_reg":
			case "dog_splode":
				self lethalbeats\survival\abilities\_dog::giveAbility();
				continue;
		}
		
		self checkBadSpawn();		
		self thread onChangePrimary();
		self thread refillNades();
		self thread refillAmmo();
		self thread refillSingleCountAmmo();
	}
}

onBotDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
	if(!isSubStr(self.botType, "dog_") && !isSubStr(self.botType, "jugg_") && !contains(sMeansOfDeath, ["MOD_HEAD_SHOT", "MOD_MELEE", "MOD_EXPLOSIVE", "MOD_GRENADE", "MOD_GRENADE_SPLASH"]))
	{
		self.hitsData[self.hitsData.size] = [iDamage, getTime()];		
		if(iDamage >= self.health && self.hitsData.size > 1)
		{
			dsd = standard_deviation(self.hitsData[0]);
			tsd = standard_deviation(self.hitsData[1]);
			diff = (tsd - dsd) / 10000;
			
			self.hitsData = [];
			
			if (diff > 0.05) self givePerk("specialty_finalstand", false);
		}
	}
	
	self maps\mp\bots\_bot_internal::onDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
	self maps\mp\bots\_bot_script::onDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
	
	self [[level.prevCallbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
}

onBotPlayerDamage(player, damage, meansOfDeath, weapon)
{
	if(isSubStr(self.botType, "dog_"))
	{
		player shellshock("dog_bite", 1.5);
		self thread lethalbeats\survival\abilities\_dog::setDogAnim("german_shepherd_attack_player", 1.5, 1);
	}
}

onBotKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	if(level.wave_num)
	{
		if (self.botType != "chopper") level.bots_death++;
		if (level.bots_death == level.bots_count) level notify("wave_end");
		
		if (self.botType == "martyrdom" || self.botType == "chemical") self notify("detonate");
		else if (self.botType == "dog_splode") self.dogModel notify("detonate");
	}

	self maps\mp\bots\_bot_internal::onKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
	self maps\mp\bots\_bot_script::onKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
	
	self [[level.prevCallbackPlayerKilled]](eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
}

onBotLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self notify("on_last_stand");
		
	self.health = 40;
	
	self disableoffhandweapons();
	
	if(isDefined(self.secondaryWeapon))
	{
		self _giveweapon(self.secondaryWeapon);
		self disableweaponswitch();
		self switchtoweapon(self.secondaryWeapon);
	}
	
	self thread botLastStandSuicide(attacker);		
	if (self.botType == "martyrdom" || self.botType == "chemical") self notify("detonate");
}

botLastStandSuicide(attacker) //this simple shit kept me busy for a long time, for some reason suicide gives a lot of errors when the bot is in the last stand, so we force damage and fixed it, suck it fucking shitty errors.
{
	self endon("death");
	
	wait 10;
	self.health = 1;
	radiusDamage(self.origin, 10, 5, 5, attacker);
	self clearLastStand();
}

respawnDealy()
{	
	if(level.bots_awaits)
	{
		level.bots_awaits--;
		return;
	}
	
	for(;;)
	{
		level waittill("wave_start"); 
		if(level.bots_awaits) 
		{
			level.bots_awaits--;
			return;
		}
	}
}

checkBadSpawn()
{
	shopZones = level.shopZones[getDvar("mapname")];
	shopOrigin = undefined;
	
	if(distance(shopZones[0], self.origin) < 300) shopOrigin = shopZones[0];
	else if(distance(shopZones[2], self.origin) < 300) shopOrigin = shopZones[2];
	else if(distance(shopZones[4], self.origin) < 300) shopOrigin = shopZones[4];
	
	if (isDefined(shopOrigin)) self.origin = shopOrigin + (0, 0, 60);
}

onChangePrimary()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("on_last_stand");
	self endon("death");
	
	for (;;)
	{
		self waittill("weapon_change", newWeapon);
		if(newWeapon == self.secondaryWeapon) self switchToWeapon(self.primaryWeapon);
	}
}

setBotLoadout()
{
	level.bots_index--;	
    self.botType = level.wave_bots[level.bots_index];
	
	table = "mp/survival_bots.csv";
	botType = self.botType;
	
	if(!isDefined(botType))	return;
	if(!isDefined(tableLookup(table, 0, botType, 1))) return;
	
    self.pers["gamemodeLoadout"]["loadoutPrimary"] = tableLookup(table, 0, botType, 1);
    self.pers["gamemodeLoadout"]["loadoutPrimaryAttachment"] = tableLookup(table, 0, botType, 2);
    self.pers["gamemodeLoadout"]["loadoutPrimaryAttachment2"] = tableLookup(table, 0, botType, 3);
    self.pers["gamemodeLoadout"]["loadoutPrimaryBuff"] = tableLookup(table, 0, botType, 4);
    self.pers["gamemodeLoadout"]["loadoutPrimaryCamo"] = "none";
    self.pers["gamemodeLoadout"]["loadoutPrimaryReticle"] = "none";
    self.pers["gamemodeLoadout"]["loadoutSecondary"] = tableLookup(table, 0, botType, 5);
    self.pers["gamemodeLoadout"]["loadoutSecondaryAttachment"] = tableLookup(table, 0, botType, 6);
    self.pers["gamemodeLoadout"]["loadoutSecondaryAttachment2"] = tableLookup(table, 0, botType, 7);
    self.pers["gamemodeLoadout"]["loadoutSecondaryBuff"] = tableLookup(table, 0, botType, 8);
    self.pers["gamemodeLoadout"]["loadoutSecondaryCamo"] = "none";
    self.pers["gamemodeLoadout"]["loadoutSecondaryReticle"] = "none";
    self.pers["gamemodeLoadout"]["loadoutEquipment"] = tableLookup(table, 0, botType, 9);
    self.pers["gamemodeLoadout"]["loadoutOffhand"] = tableLookup(table, 0, botType, 10);
    self.pers["gamemodeLoadout"]["loadoutPerk1"] = tableLookup(table, 0, botType, 11);
    self.pers["gamemodeLoadout"]["loadoutPerk2"] = tableLookup(table, 0, botType, 12);
    self.pers["gamemodeLoadout"]["loadoutPerk3"] = tableLookup(table, 0, botType, 13);
	self.pers["gamemodeLoadout"]["loadoutStreakType"] = "specialty_null";
	self.pers["gamemodeLoadout"]["loadoutKillstreak1"] = "none";
	self.pers["gamemodeLoadout"]["loadoutKillstreak2"] = "none";
	self.pers["gamemodeLoadout"]["loadoutKillstreak3"] = "none";
    self.pers["gamemodeLoadout"]["loadoutDeathstreak"] = "specialty_null";
    self.pers["gamemodeLoadout"]["loadoutJuggernaut"] = 0;
	
	lethal = self.pers["gamemodeLoadout"]["loadoutEquipment"];
	if (isDefined(lethal) && lethal != "none" && lethal != "specialty_null")
	{
		self checkNadeClass(lethal);
		self setNades(lethal, 4);
	}
	
	tactical = self.pers["gamemodeLoadout"]["loadoutOffhand"];
	if (isDefined(tactical) && tactical != "none" && tactical != "specialty_null")
	{
		self checkNadeClass(tactical);
		self setNades(tactical, 4);
	}
	
	health = int(tableLookup(table, 0, botType, 14));
	self.maxhealth = health;
	self.health = health;
	
	self.moveSpeedScaler = float(tableLookup(table, 0, botType, 15));
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
	
	self maps\mp\bots\_bot_utility::botGiveLoadout(self.team, "gamemode", false, true);
	self maps\mp\killstreaks\_killstreaks::clearKillstreaks();
	
	self setDifficulty(int(tableLookup(table, 0, botType, 16)));
	
	self.botPrice = int(tableLookup(table, 0, botType, 17));
	
	level.score_base += self.botPrice;
	
	body_model = tableLookup(table, 0, botType, 18);
	head_model = tableLookup(table, 0, botType, 19);
	
	if (head_model == "" || body_model == "") return;
	
	self detachall();
	
	if (isSubStr(head_model, " ")) self attach(random(strtok(head_model, " ")), "", true);
	else self attach(head_model, "", true);
	
	if (isSubStr(body_model, " ")) self setmodel(random(strtok(body_model, " ")));
	else self setmodel(body_model);
}

setDifficulty(difficulty)
{	
	self.pers["bots"]["skill"]["base"] = randomIntRange(5, 7);
	self.pers["bots"]["skill"]["aim_time"] = 0.3;
	self.pers["bots"]["skill"]["init_react_time"] = 100;
	self.pers["bots"]["skill"]["reaction_time"] = 50;
	self.pers["bots"]["skill"]["remember_time"] = 7500;
	self.pers["bots"]["skill"]["no_trace_ads_time"] = 2500;
	self.pers["bots"]["skill"]["no_trace_look_time"] = 4000;
	self.pers["bots"]["skill"]["fov"] = -1;
	self.pers["bots"]["skill"]["dist_start"] = 15000;
	self.pers["bots"]["skill"]["dist_max"] = 10000;
	self.pers["bots"]["skill"]["spawn_time"] = 0.05;
	self.pers["bots"]["skill"]["help_dist"] = 3000;
	self.pers["bots"]["skill"]["semi_time"] = 0.1;
	self.pers["bots"]["skill"]["shoot_after_time"] = 0;
	self.pers["bots"]["skill"]["aim_offset_time"] = 0;
	self.pers["bots"]["skill"]["aim_offset_amount"] = 0;
	self.pers["bots"]["skill"]["bone_update_interval"] = 0.05;
	self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_ankle_le,j_ankle_ri";
	self.pers["bots"]["skill"]["ads_fov_multi"] = 0.5;
	self.pers["bots"]["skill"]["ads_aimspeed_multi"] = 0.5;
	
	self.pers["bots"]["behavior"]["strafe"] = 50;
	self.pers["bots"]["behavior"]["nade"] = 70;
	self.pers["bots"]["behavior"]["sprint"] = 60;
	self.pers["bots"]["behavior"]["camp"] = 0;
	self.pers["bots"]["behavior"]["follow"] = 100;
	self.pers["bots"]["behavior"]["crouch"] = 0;
	self.pers["bots"]["behavior"]["switch"] = 0;
	self.pers["bots"]["behavior"]["class"] = 0;
	self.pers["bots"]["behavior"]["jump"] = 20;
	self.pers["bots"]["behavior"]["quickscope"] = 0;

	switch (difficulty)
	{
		case 0: //dogs
			self.pers["bots"]["skill"]["aim_time"] = 0;
			self.pers["bots"]["behavior"]["strafe"] = 35;
			self.pers["bots"]["behavior"]["sprint"] = 100;
			self.pers["bots"]["behavior"]["jump"] = 35;
			break;
		case 1: self.pers["bots"]["skill"]["aim_time"] = 0.4; break;
		case 2: self.pers["bots"]["skill"]["aim_time"] = 0.3; break;
		case 3: self.pers["bots"]["skill"]["aim_time"] = 0.2; break;
	}
}
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\survival\_utility;

init()
{
	preCacheMpAnim("german_shepherd_run");
	preCacheMpAnim("german_shepherd_death_front");
	preCacheMpAnim("german_shepherd_run_jump_40");
	preCacheMpAnim("german_shepherd_attack_player");
	preCacheMpAnim("german_shepherd_run_pain");
	
	precacheShellShock("radiation_low");
	precacheShellShock("dog_bite");
	
	level._effect["chemical_tank_explosion"] = loadfx("smoke/so_chemical_explode_smoke");
	level._effect["chemical_tank_smoke"] = loadfx("smoke/so_chemical_stream_smoke");
	level._effect["chemical_mine_spew"] = loadfx("smoke/so_chemical_mine_spew");
	level._effect["martyrdom_c4_explosion"] = loadfx("explosions/grenadeExp_metal");
}

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
			case "martyrdom": self martyrdomAbility(); continue;
			case "chemical": self thread chemicalAbility(); continue;
			case "chopper": self chopperAbility(); continue;
			case "jugg_regular":
			case "jugg_riotshield":
			case "jugg_explosive":
			case "jugg_minigun": self juggAbility(); continue;
			case "dog_reg":
			case "dog_splode":	self dogAbility(); continue;
		}
		
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
		self thread _setDogAnim("german_shepherd_attack_player", 1.5, 1);
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

chopperAbility()
{
	self thread [[level.killStreakFuncs["littlebird_survival"]]]();
	self suicide();
}

juggAbility()
{
	self thread maps\mp\killstreaks\_airdrop::doFlyBy(self, random(level.chopperStartGoal), randomFloat(360), "jugger", undefined, undefined, undefined, "pavelow_mp");
	self.isJuggernaut = true;
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
	self thread maps\mp\killstreaks\_juggernaut::juggernautSounds();
	self setPerk("specialty_radarjuggernaut", true, false);
}

martyrdomAbility()
{
	self thread attachC4("j_spine4", (0,6,0), (0,0,-90));
	self thread attachC4("tag_stowed_back", (0,1,5), (80,90,0));
	self thread martyrdomDetonate();
}

martyrdomDetonate()
{
	self waittill("detonate");
	
	c4_array = self.c4_attachments;		
	c4_array[0] playSound("semtex_warning");
	
	traceStart = c4_array[0].origin + (0,0,32);
	traceEnd = c4_array[0].origin + (0,0,-32);
	trace = bulletTrace(traceStart, traceEnd, false, undefined);
	
	upangles = vectorToAngles(trace["normal"]);
	forward = anglesToForward(upangles);
	right = anglesToRight(upangles);
	
	wait 0.25;
	fxEnt = SpawnFx(level._effect["laserTarget"], getGroundPosition(c4_array[0].origin, 12, 0, 32), forward, right);
	triggerFx(fxEnt);
	wait 0.25;
	fxEnt2 = SpawnFx(level._effect["laserTarget"], getGroundPosition(c4_array[0].origin, 12, 0, 32), forward, right);
	triggerFx(fxEnt2);
	
	wait 1.5;
	for (i = 0; i < c4_array.size; i++)
	{
		
		playfx(level._effect["martyrdom_c4_explosion"], c4_array[i].origin);
		playSoundAtPos(c4_array[i].origin, "detpack_explo_main");
		earthquake(0.4, 0.8, c4_array[i].origin, 600);
		
		c4_array[i] radiusdamage(c4_array[i].origin, 192, 100, 50, undefined, "MOD_EXPLOSIVE");
		c4_array[i] unlink();
		c4_array[i] delete();		
		wait 0.5;
	}
	
	self.c4_attachments = [];
	
	wait 1.5;
	fxEnt delete();
	fxEnt2 delete();
}

attachC4(tag, origin_offset, angles_offset, isDog)
{
	c4_model = spawn("script_model", self gettagorigin(tag) + origin_offset);
	c4_model setmodel("weapon_c4");
	c4_model linkto(self, tag, origin_offset, angles_offset);
	
	wait 0.15;
	playFXOnTag(level.mine_beacon["enemy"], c4_model, "tag_origin");
	
	if (!isdefined(self.c4_attachments)) self.c4_attachments = [];
	self.c4_attachments[self.c4_attachments.size] = c4_model;
}

chemicalAbility()
{
	self thread attachChemicalTank();
	self thread chemicalDetonate();
}

attachChemicalTank()
{
	level endon("game_ended");
	self endon("death");
	
	tank = spawn("script_model", self gettagorigin("tag_shield_back"));
	tank setmodel("gas_canisters_backpack");
	tank.health = 99999;
	tank setcandamage(true);
	tank linkto(self, "tag_shield_back", (0,0,0), (0,0,0));
	self.tankAttach = tank;
	self.chemical = 1;
	
	for(;;)
	{
		wait 0.05;
		playFXOnTag(level._effect["chemical_tank_smoke"], self, "tag_shield_back");
	}
}

chemicalDetonate()
{	
	self waittill("detonate");
	self notify("tank_detonated");
	explode_origin = self.origin;
	self.tankAttach playsound("detpack_explo_main");
	earthquake(0.2, 0.4, explode_origin, 600);
	playfx(level._effect["chemical_tank_explosion"], explode_origin);
	self.tankAttach unlink();
	wait 0.05;
	self.tankAttach delete();
	
	trigger = spawn("trigger_radius", explode_origin, 0, 70, 70 * 2);
	self thread onGasHandle(trigger);
	
	wait(7);
	self notify("gas_done");
}

onGasHandle(trigger)
{
	level endon("game_ended");	
	self endon("gas_done");
	
	for(;;)
	{
		foreach(player in level.players) 
			if (player isTouching(trigger))
			{
				player shellshock("radiation_low", 0.45);
				player viewKick(3, self.origin);
			}
			
		radiusdamage(trigger.origin, 70, 10, 5, self, "MOD_EXPLOSIVE");
		wait 0.5;
	}
}

dogAbility()
{
	self.dogAnim = 0;
	self.lastDroppableWeapon = "none";
	weapon = "iw5_dog_mp";
	
	self takeAllWeapons();	
	self _giveWeapon(weapon);
	self setSpawnWeapon(weapon);
	self disableweaponswitch();
	self disableoffhandweapons();
	
	self.pers["primaryWeapon"] = weapon;

	dogModel = spawn("script_model", self.origin);
	dogModel.angles = (0, self.angles[1], 0);
	dogModel setModel("german_sheperd_dog");
	dogModel scriptModelPlayAnim("german_shepherd_run");
	dogModel linkto(self);
	
	if(self.botType == "dog_splode")
	{
		dogModel thread attachC4("j_hip_base_ri", (6,6,-3), (0,0,0));
		dogModel thread attachC4("j_hip_base_le", (-6,-6,3), (0,0,0));
		dogModel thread martyrdomDetonate();
	}	
	
	tail_pos = self.origin - (vectornormalize(anglestoforward(self getPlayerAngles())) * 20);	
	hitBox = Spawn("script_model", tail_pos + (0, 0, 25));
	hitBox.angles = (0, self.angles[1], 0);
	hitBox SetModel("com_plasticcase_dummy");
	hitBox hide();

	hitBox setcandamage(1);
	hitBox setCanRadiusDamage(1);
	hitBox.health = self.health; 
	hitBox.maxHealth = self.maxHealth;
	hitBox.damageTaken = 0;
	hitBox linkto(self);
	
	dogModel.hitBox = hitBox;	
	self.dogModel = dogModel;
	
	self thread onDogDeath();
	self thread onDogDamage();
	self thread dogSounds();
	self thread dogTest();
}

onDogDamage()
{
	level endon("game_ended");
	self endon("killed_player");
	self endon("disconnect");
	
	hitBox = self.dogModel.hitBox;	
	painFase = hitBox.maxHealth / 3;
	currFase = 0;

	for(;;)
	{
		hitBox waittill("damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags, weapon);
		
		attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback("");	
		if (isDefined(attacker.team) && attacker.team == "axis" && type != "MOD_EXPLOSIVE") continue;
		
		radiusDamage(hitBox.origin, 10, damage, damage, attacker, type);
		hitBox.damageTaken += damage;
		
		if ((!currFase && hitBox.damageTaken >= painFase) || (currFase == 1 && hitBox.damageTaken >= painFase * 2))
		{
			self thread _setDogAnim("german_shepherd_run_pain", 1.5, 1);
			self playSound("anml_dog_neckbreak_pain");
			currFase++;
		}
	}
}

onDogDeath()
{
	self waittill("killed_player");	
	self notify("end_anim");

	self freezeControls(0);
	dog_model = self.dogModel;
	dog_model.hitBox delete();
	self.dogModel = undefined;

	wait 0.25;
	
	dog_model scriptModelPlayAnim("german_shepherd_death_front");	
	dog_model.origin = bulletTrace(self.origin, self.origin - (0, 0, 60), false, self)["position"];	
	dog_model unLink();
	
	wait randomIntRange(2, 6);
	
	dog_model delete();
}

dogSounds()
{
	level endon("game_ended");
	self endon("death");
	self endon("disconnect");

	interval = randomIntRange(3, 5);

	for (;;)
	{
		wait interval;
		playsoundatpos(self.origin, "anml_dog_bark");
	}
}

dogTest()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	
	self.dogAnim = 0;
	dirAngle = self getPlayerAngles();
	
	for(;;)
	{
		wait 0.35;
		if (self.dogAnim) continue;
		dirAngle = vectortoangles(vectornormalize(self getVelocity()));		
		if(vectordot(anglestoforward(self getPlayerAngles()), dirAngle) < 0) self setPlayerAngles((dirAngle[0], dirAngle[1], self getPlayerAngles()[2]));
	}
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
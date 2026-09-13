#include lethalbeats\survival\utility;
#include lethalbeats\array;
#include lethalbeats\player;

#define GAME_MODE_LOADOUT "gamemodeLoadout"
#define LOADOUT_PRIMARY_BUFF "loadoutPrimaryBuff"
#define LOADOUT_SECONDARY_BUFF "loadoutSecondaryBuff"
#define LOADOUT_PERK1 "loadoutPerk1"
#define LOADOUT_PERK2 "loadoutPerk2"
#define LOADOUT_PERK3 "loadoutPerk3"
#define SPECIALTY_NULL "specialty_null"

#define INSTAKILL ["MOD_HEAD_SHOT", "MOD_MELEE", "MOD_RIFLE_BULLET"]
#define SHIELD_BULLET_DAMAGE ["MOD_PISTOL_BULLET", "MOD_RIFLE_BULLET", "MOD_EXPLOSIVE_BULLET"]

#define DOG 0
#define MARTYRDOM 1
#define CHEMICAL 2
#define CHOPPER 3
#define JUGGER 4
#define PAVE_LOW 5
#define REAPER 6
#define REMOTE_TANK 7
#define AIRSTRIKE 8
#define PREDATOR 9
#define COUNTER_UAV 10
#define EMP 11
#define IMS 12
#define SENTRY 13
#define RIOT_SHIELD 14

#define BOT_RESPAWN_DELAY_MIN 163
#define BOT_RESPAWN_DELAY_MAX 164


onBotSpawn()
{
	level endon("game_ended");
	self endon("disconnect");

	self.hasriotshieldequipped = false;
	self.perks = [];
	self.grenades = [];

	for(;;)
	{
		self waittill("spawned_player");		
		waittillframeend;
	
		self show();
		self setContents(100);
		self player_clear_nades();
		self player_disable_usability();
		self disableWeaponPickup();
		self bot_set_loadout();
		self bot_set_health();
		self bot_set_speed();

		self.primaryweapon = self player_get_primary();
		self.currentweaponatspawn = self.primaryweapon;
		self.prevWeapon = self.currentweaponatspawn;
		self.saved_lastweapon = self.prevWeapon;

		self.targetGuid = undefined;
		self.isHuman = true;
		self.deathtime = 0;
		self.lastkilltime = 0;
		self.spawntime = gettime();
		abilities = self bot_get_abilities(true);

		foreach(ability in abilities)
		{
			switch(ability)
			{
				case DOG:
					self lethalbeats\survival\abilities\_dog::giveAbility();
					self.isHuman = false;
					break;
				case MARTYRDOM:
					self lethalbeats\survival\abilities\_martyrdom::giveAbility();
					break;
				case CHEMICAL:
					self thread lethalbeats\survival\abilities\_chemical::giveAbility();
					break;
				case CHOPPER:
					self.isHuman = false;
					self thread lethalbeats\Survival\abilities\_chopper::giveAbility();
					break;
				case JUGGER:
					self freezeControls(true);
					self thread lethalbeats\survival\abilities\_juggernaut::giveAbility();
					break;
				case PAVE_LOW:
					self.isHuman = false;
					self thread lethalbeats\Survival\abilities\_pavelow::giveAbility();
					break;
				case REAPER:
					self thread lethalbeats\Survival\abilities\_reaper::giveAbility();
					self.isHuman = false;
					break;
				case REMOTE_TANK:
					self.isHuman = false;
					self thread lethalbeats\Survival\abilities\_tank::giveAbility();
					break;
				case AIRSTRIKE:
					self.isHuman = false;
					self thread lethalbeats\Survival\abilities\_killstreaks::giveAirstrike();
					break;
				case PREDATOR:
					self.isHuman = false;
					self thread lethalbeats\Survival\abilities\_killstreaks::givePredator();
					break;
				case COUNTER_UAV:
					self.isHuman = false;
					self thread lethalbeats\Survival\abilities\_killstreaks::giveCounterUAV();
					break;
				case EMP:
					self.isHuman = false;
					self thread lethalbeats\Survival\abilities\_killstreaks::giveEmp();
					break;
				case IMS:
					self thread lethalbeats\survival\abilities\_killstreaks::giveIMS();
					break;
				case SENTRY:
					self thread lethalbeats\survival\abilities\_killstreaks::giveSentry();
					break;
			}
		}

		if (!self.isHuman) 
		{
			self.damageData = undefined;
			self.dropWeapon = false;
			continue;
		}

		self.stuned = false;
		self.stunEndTime = 0;
		if (isDefined(self.bot)) self.bot.fireCycleData = undefined;
		self.dropWeapon = !self bot_is_jugger();
		self.damageData = [];
		self takeWeapon(self.secondaryWeapon);
		self thread onChangeWeapons();
		self thread onSprint();
		self player_unset_Perk("specialty_finalstand");

		mines = 0;
		foreach(bot in bots()) mines += array_get_values(bot.mines).size;
		if (mines >= getDvarInt("survival_bot_mines_limit")) self player_clear_nades();

		factionPrefix = maps\mp\gametypes\_teams::getTeamVoicePrefix(self.team);

        if (!isdefined(self.pers["voiceIndex"]) || factionPrefix != "RU_" && self.pers["voiceNum"] >= 3)
        {
            if (factionPrefix == "RU_") self.pers["voiceNum"] = randomintrange(0, 4);
            else self.pers["voiceNum"] = randomintrange(0, 2);
            self.pers["voicePrefix"] = factionPrefix + self.pers["voiceNum"] + "_";
        }

        self thread maps\mp\gametypes\_battlechatter_mp::claymoreTracking();
        self thread maps\mp\gametypes\_battlechatter_mp::reloadTracking();
        self thread maps\mp\gametypes\_battlechatter_mp::grenadeTracking();
        self thread maps\mp\gametypes\_battlechatter_mp::grenadeProximityTracking();
        self thread maps\mp\gametypes\_battlechatter_mp::suppressingFireTracking();
		
		self thread lethalbeats\survival\patch\mines::grenadeWatchUsage();
		self maps\mp\_utility::setRecoilScale(0, 100);
		if (self.primaryweapon == "riotshield_mp")
		{
			self lethalbeats\botactor\utility::bot_hold_melee_charge();
			self thread maps\mp\gametypes\_class::trackRiotShield();
		}

		self lethalbeats\botactor\behavior::bot_set_engagement("free");
		hunt = lethalbeats\botactor\behavior::bot_task_custom(lethalbeats\botactor\ai_hunter::bot_hunter_run);
		self lethalbeats\botactor\behavior::bot_set_standing_task(hunt);
		self lethalbeats\botactor\behavior::bot_do(hunt);
	}
}

botWaitRespawn()
{
	level endon("game_ended");
	self endon("disconnect");

	for(;;)
	{
		self lethalbeats\utility::waittill_any("release_bot", "bot_wait_respawn");
		if (!level.bots_awaits) self waittill("release_bot");
		if (level.bots_awaits)
		{
			level.bots_awaits--;

			popData = array_pop(level.bots_wave);
			level.bots_wave = popData[0];
			self.botType = popData[1];
			self bot_set_difficulty();

			if (isDefined(self.actor)) self.actor[65] = undefined; // SKILL_REMEMBER_TIME

			delay = 0;
			delayMin = int(self.actor[BOT_RESPAWN_DELAY_MIN]);
			delayMax = int(self.actor[BOT_RESPAWN_DELAY_MAX]);

			if ((delayMin < delayMax) && (delayMin >= 0)) delay = randomIntRange(delayMin, delayMax + 1);
			if (delay > 0) wait delay;

			self lethalbeats\botactor\utility::bot_spawn();
		}
	}
}

onBotDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
	if (!self.isHuman) return;
	if (self bot_is_jugger() && !self.isDropped) return;

	self.bleedData = undefined;
	isExplosiveDamage = is_explosive_damage(sMeansOfDeath);

	if (isDefined(eAttacker) && eAttacker player_is_survivor())
	{
		if (isDefined(sWeapon))
		{
			eAttacker.wave_summary["hits"]++;
			if (eAttacker.wave_summary["hits"] <= eAttacker.wave_summary["totalshots"]) eAttacker.wave_summary["accuracy"] = clamp(eAttacker.wave_summary["hits"] / eAttacker.wave_summary["totalshots"], 0.0, 1.0) * 100;
			iDamage += self bot_modified_damage(iDamage, eAttacker, sWeapon, sMeansOfDeath);

			if (isDefined(sHitLoc) && sHitLoc == "shield" && array_contains(SHIELD_BULLET_DAMAGE, sMeansOfDeath) && eAttacker player_has_perk("specialty_bulletpenetration"))
				sHitLoc = "torso_upper";
		}

		if(isDefined(self.damageData) && !self.inLastStand && !isExplosiveDamage && !array_contains(INSTAKILL, sMeansOfDeath))
		{
			if (!self.damageData.size) self thread onRecover();
			self.damageData[self.damageData.size] = [iDamage, getTime()];
			if(iDamage >= self.health && self.damageData.size > 1)
			{
				dsd = lethalbeats\math::math_std(self.damageData[0]);
				tsd = lethalbeats\math::math_std(self.damageData[1]);
				diff = (tsd - dsd) / 1000;			
				self.damageData = [];
				
				if (diff > 0.3)
				{
					self player_give_perk("specialty_finalstand", false);
					self.bleedData = [eInflictor, eAttacker, iDFlags, sMeansOfDeath, sWeapon, sHitLoc];
				}
			}
		}

		self thread onStun(sWeapon, sMeansOfDeath);
	}

	if (self bot_is_explosive() && isExplosiveDamage) self notify("detonate", eAttacker);
	
	self [[level.prevCallbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
}

onBotKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	self.damageData = [];

	if (isDefined(self.isjuggernaut) && self.isjuggernaut) self.isjuggernaut = false;
	if (self.inLastStand) self.inLastStand = false;
	if(level.wave_num)
	{
		if (self bot_is_jugger()) self unsetPerk("specialty_radarjuggernaut", true);
		if (self bot_is_explosive()) self notify("detonate", eAttacker);
		if (!self bot_is_killstreak() && !(self bot_is_jugger() && !self.isDropped) && !bot_is_dog()) self bot_kill(eAttacker);
	}

	if (self.dropWeapon) self thread player_drop_weapon();

	if (isDefined(eAttacker) && eAttacker player_is_survivor() && eAttacker player_has_perk("specialty_scavenger"))
	{
		scavenger_ratio = getDvarInt("survival_scavenger_ratio");
		if (scavenger_ratio < 0) scavenger_ratio = 0;
		else if (scavenger_ratio > 100) scavenger_ratio = 100;
		
		if (lethalbeats\math::math_chance(scavenger_ratio))
			self thread lethalbeats\survival\killstreaks\_perks::scavenger_drop();
	}
	
	self [[level.prevCallbackPlayerKilled]](eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
}

onBotLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self notify("on_last_stand");
	
	self.inLastStand = true;
	self.health = 40;	
	self takeWeapon(self.primaryWeapon);
	self player_disable_offhand_weapons();
	
	if(isDefined(self.secondaryWeapon))
	{
		self player_give_weapon(self.secondaryWeapon);
		self player_disable_weapon_switch();
		self switchtoweapon(self.secondaryWeapon);
	}
	
	self thread bot_lastStand_suicide(attacker);	
	if (self bot_is_explosive()) self notify("detonate", attacker);
}

onChangeWeapons()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	
	self.lastDroppableWeapon = self.currentWeaponAtSpawn;

	// for some reason the perks are not load properly from loadout... this fixes it (^▽^)👍
	foreach(perks in self player_get_perks())
		self player_unset_Perk(perks);

	self.loadoutPrimaryBuff = self.pers[GAME_MODE_LOADOUT][LOADOUT_PRIMARY_BUFF];
	self.loadoutSecondaryBuff = self.pers[GAME_MODE_LOADOUT][LOADOUT_SECONDARY_BUFF];

	if (self.pers[GAME_MODE_LOADOUT][LOADOUT_PERK1] != SPECIALTY_NULL) self player_give_perk(self.pers[GAME_MODE_LOADOUT][LOADOUT_PERK1]);
	if (self.pers[GAME_MODE_LOADOUT][LOADOUT_PERK2] != SPECIALTY_NULL) self player_give_perk(self.pers[GAME_MODE_LOADOUT][LOADOUT_PERK2]);
	if (self.pers[GAME_MODE_LOADOUT][LOADOUT_PERK3] != SPECIALTY_NULL) self player_give_perk(self.pers[GAME_MODE_LOADOUT][LOADOUT_PERK3]);

	for(;;)
	{
		self waittill("weapon_change", weaponName);
		
		if(weaponName == "none" || maps\mp\_utility::isKillstreakWeapon(weaponName))
			continue;
		
		if(isDefined(self.loadoutPrimaryBuff) && self.loadoutPrimaryBuff != SPECIALTY_NULL)
		{
			if(weaponName == self.primaryWeapon && !self player_has_perk(self.loadoutPrimaryBuff))
				self player_give_perk(self.loadoutPrimaryBuff, true);
			if(weaponName != self.primaryWeapon && self player_has_perk(self.loadoutPrimaryBuff))
				self player_unset_Perk(self.loadoutPrimaryBuff);
		}

		if(isDefined(self.loadoutSecondaryBuff) && self.loadoutSecondaryBuff != SPECIALTY_NULL)
		{
			if(weaponName == self.secondaryWeapon && !self player_has_perk(self.loadoutSecondaryBuff))
				self player_give_perk(self.loadoutSecondaryBuff, true);
			if(weaponName != self.secondaryWeapon && self player_has_perk(self.loadoutSecondaryBuff))
				self player_unset_Perk(self.loadoutSecondaryBuff);
		}
	}
}

onRecover()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	
	for(;;)
	{
		wait 10;
		if (self.health == self.maxHealth)
		{
			self.damageData = [];
			return;
		}
	}
}

onSprint()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");

	moveSpeed = self.moveSpeedScaler;

    for (;;)
    {
        self waittill("sprint_begin");
		self.moveSpeedScaler = 1;
		self maps\mp\gametypes\_weapons::updateMoveSpeedScale();

		self waittill("sprint_end");
		self.moveSpeedScaler = moveSpeed;
		self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
    }
}

onStun(weapon, meansOfDeath)
{
	stunTime = 0;

	if (is_explosive_damage(meansOfDeath)) stunTime = 2;
	else if (isDefined(weapon))
	{
		switch(weapon)
		{
			case "artillery_mp":
			case "flash_grenade_mp": stunTime = 4; break;
			case "concussion_grenade_mp": stunTime = 5; break;
		}
	}

	if (!self bot_is_jugger() && isDefined(self.damageData) && self.damageData.size > 0)
	{
		totalDamage = 0;
		currentTime = getTime();
		for (i = self.damageData.size - 1; i >= 0; i--)
		{
			if (currentTime - self.damageData[i][1] <= 500)
				totalDamage += self.damageData[i][0];
			else
				break;
		}

		if (totalDamage >= self.maxHealth * 0.35)
			stunTime = 3;
	}

	if (!stunTime) return;

	newStunEnd = getTime() + int(stunTime * 1000);
	if (!isDefined(self.stunEndTime) || self.stunEndTime < newStunEnd)
		self.stunEndTime = newStunEnd;

	remainingStun = float(self.stunEndTime - getTime()) / 1000.0;
	if (remainingStun < 0.05) remainingStun = 0.05;

	self shellShock("concussion_grenade_mp", remainingStun);

	// Force a fresh windup after stun, prevents carrying an in-progress fire cycle.
	if (isDefined(self.bot)) self.bot.fireCycleData = undefined;

	if (isDefined(self.stuned) && self.stuned)
		return;

	self.stuned = true;
	self thread onStunWatcher();
}

onStunWatcher()
{
	self endon("disconnect");
	self endon("death");

	for (;;)
	{
		if (!isDefined(self.stunEndTime) || getTime() >= self.stunEndTime)
			break;

		wait 0.05;
	}

	self.stuned = false;
}

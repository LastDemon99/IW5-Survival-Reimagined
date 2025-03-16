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
#define EXPLOSIVE_DAMAGE ["MOD_EXPLOSIVE", "MOD_GRENADE", "MOD_GRENADE_SPLASH", "MOD_PROJECTILE", "MOD_PROJECTILE_SPLASH"]

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

onBotSpawn()
{
	level endon("game_ended");
	self endon("disconnect");
	
	for(;;)
	{
		self waittill("spawned_player");
		
		if(!level.wave_num)
		{
			self takeAllWeapons();
			self suicide();
			continue;
		}
	
		self.grenades = [];
	
		self show();
		self setContents(100);
		self player_clear_nades();
		self disableUsability();
		self bot_set_loadout();

		isHuman = true;
		abilities = self bot_get_abilities(true);

		foreach(ability in abilities)
		{
			switch(ability)
			{
				case DOG:
					self lethalbeats\survival\abilities\_dog::giveAbility();
					isHuman = false;
					break;
				case MARTYRDOM:
					self lethalbeats\survival\abilities\_martyrdom::giveAbility();
					break;
				case CHEMICAL:
					self lethalbeats\survival\abilities\_chemical::giveAbility();
					break;
				case CHOPPER:
					self thread lethalbeats\Survival\abilities\_chopper::giveAbility();
					isHuman = false;
					break;
				case JUGGER:
					if (self bot_has_ability("explosive")) self thread lethalbeats\survival\abilities\_juggernaut::giveAbilityExplosive();
					else self thread lethalbeats\survival\abilities\_juggernaut::giveAbility();
					break;
				case PAVE_LOW:
					self thread lethalbeats\Survival\abilities\_pavelow::giveAbility();
					isHuman = false;
					break;
				case REAPER:
					self thread lethalbeats\Survival\abilities\_reaper::giveAbility();
					isHuman = false;
					break;
				case REMOTE_TANK:
					self thread lethalbeats\Survival\abilities\_tank::giveAbility();
					isHuman = false;
					break;
				case AIRSTRIKE:
					self thread lethalbeats\Survival\abilities\_killstreaks::giveAirstrike();
					isHuman = false;
					break;
				case PREDATOR:
					self thread lethalbeats\Survival\abilities\_killstreaks::givePredator();
					isHuman = false;
					break;
				case COUNTER_UAV:
					self thread lethalbeats\Survival\abilities\_killstreaks::giveCounterUAV();
					isHuman = false;
					break;
				case EMP:
					self thread lethalbeats\Survival\abilities\_killstreaks::giveEmp();
					isHuman = false;
					break;
				case IMS:
					self [[level.killStreakFuncs["ims"]]]();
					break;
				case SENTRY:
					self [[level.killStreakFuncs["sentry"]]]();
					break;
			}
		}

		if (!isHuman) 
		{
			self.damageData = undefined;
			continue;
		}

		self.damageData = [];
		self takeWeapon(self.secondaryWeapon);
		self thread player_refill_nades();
		self thread onChangeWeapons();
	}
}

onBotRespawnDealy()
{
	level endon("game_ended");
	self endon("disconnect");

	for(;;) 
	{
		if (!level.bots_awaits) level waittill("release_bots");
		if (level.bots_awaits)
		{
			level.bots_awaits--;
			delay = randomIntRange(1, 3);
			wait randomFloatRange(delay - 0.5, delay + 0.5);
			break;
		}
	}
}

onBotDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
	if (sWeapon == "artillery_mp" || sMeansOfDeath == "MOD_RIFLE_BULLET") iDamage *= 4;

	self.bleedData = undefined;

	if (isDefined(self.isJuggernaut) && (self.isJuggernaut && !self.isDropped)) return;

	if (isDefined(sWeapon) && isDefined(eAttacker) && eAttacker player_is_survivor())
	{
		weapons = eAttacker player_get_weapons();
		weaponBase = array_contains(weapons, sWeapon) ? lethalbeats\weapon::weapon_get_baseName(sWeapon) : undefined;

		if (isDefined(weaponBase) && weaponBase != "projectile" && weaponBase != "riot")
		{
			eAttacker.summary["hits"]++;
			if (eAttacker.summary["hits"] <= eAttacker.summary["totalshots"]) eAttacker.summary["accuracy"] = clamp(eAttacker.summary["hits"] / eAttacker.summary["totalshots"], 0.0, 1.0) * 100;
		}
	}

	if (self bot_is_explosive() && array_contains(EXPLOSIVE_DAMAGE, sMeansOfDeath)) self notify("detonate", eAttacker);

	if(isDefined(self.damageData) && !self.inLastStand && !array_contains(array_combine(INSTAKILL, EXPLOSIVE_DAMAGE), sMeansOfDeath))
	{
		if (!self.damageData.size) self thread onRecover();
		self.damageData[self.damageData.size] = [iDamage, getTime()];
		if(iDamage >= self.health && self.damageData.size > 1)
		{
			dsd = lethalbeats\math::math_std(self.damageData[0]);
			tsd = lethalbeats\math::math_std(self.damageData[1]);
			diff = (tsd - dsd) / 1000;			
			self.damageData = [];
			
			if (diff > 0.5)
			{
				self player_give_perk("specialty_finalstand", false);
				self.bleedData = [eInflictor, eAttacker, iDFlags, sMeansOfDeath, sWeapon, sHitLoc];
			}
		}
	}
	
	self maps\mp\bots\_bot_internal::onDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
	self maps\mp\bots\_bot_script::onDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
	
	self [[level.prevCallbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
}

onBotKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	if (self.inLastStand) self.inLastStand = false;
	if(level.wave_num)
	{
		if (self bot_is_jugger()) self unsetPerk("specialty_radarjuggernaut", true);
		if (!self bot_is_killstreak() && !(self.isJuggernaut && !self.isDropped)) self bot_kill(eAttacker);
		if (self bot_is_explosive()) self notify("detonate", eAttacker);
	}

	self maps\mp\bots\_bot_internal::onKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
	self maps\mp\bots\_bot_script::onKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
	
	self [[level.prevCallbackPlayerKilled]](eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
}

onBotLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self notify("on_last_stand");
	
	self.inLastStand = true;
	self.health = 40;	
	self takeWeapon(self.primaryWeapon);
	self disableoffhandweapons();
	
	if(isDefined(self.secondaryWeapon))
	{
		self player_give_weapon(self.secondaryWeapon);
		self disableweaponswitch();
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

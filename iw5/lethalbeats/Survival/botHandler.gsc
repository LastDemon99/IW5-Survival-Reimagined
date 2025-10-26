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
#define RIOT_SHIELD 14

onBotSpawn()
{
	level endon("game_ended");
	self endon("disconnect");
	
	for(;;)
	{
		self waittill("spawned_player");		
		waittillframeend;

		if (!level.bots_total_count)
		{
			self.dropWeapon = false;
			self suicide();
			continue;
		}
	
		self.grenades = [];
	
		self show();
		self setContents(100);
		self player_clear_nades();
		self player_disable_usability();
		self disableWeaponPickup();
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
					self thread lethalbeats\survival\abilities\_chemical::giveAbility();
					break;
				case CHOPPER:
					self thread lethalbeats\Survival\abilities\_chopper::giveAbility();
					isHuman = false;
					break;
				case JUGGER:
					self thread lethalbeats\survival\abilities\_juggernaut::giveAbility();
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
					if (level.ims.size < 4) self thread lethalbeats\survival\abilities\_killstreaks::giveStreak("ims");
					break;
				case SENTRY:
					if (level.turrets.size < 6) self thread lethalbeats\survival\abilities\_killstreaks::giveStreak("sentry");
					break;
			}
		}

		if (!isHuman) 
		{
			self.damageData = undefined;
			self.dropWeapon = false;
			continue;
		}

		self.dropWeapon = true;
		self.damageData = [];
		self takeWeapon(self.secondaryWeapon);
		self thread onChangeWeapons();
		self thread player_refill_ammo(true);
		self thread onSprint();
		self player_unset_Perk("specialty_finalstand");

		mines = 0;
		foreach(player in level.players) mines += array_get_values(player.mines).size;
		if (mines >= 30) self player_clear_nades();
	}
}

botWaitRespawn()
{
	level endon("game_ended");
	self endon("disconnect");

	for(;;) 
	{
		if (!level.bots_awaits) level waittill("release_bots");
		if (level.bots_awaits)
		{
			level.bots_awaits--;
			if (level.difficulty == 3) break;
			else if (level.difficulty == 2)
			{
				delay = randomIntRange(1, 3);
				wait randomFloatRange(delay - 0.5, delay + 0.5);
			}
			else
			{
				delay = randomIntRange(3, 6);
				wait randomFloatRange(delay - 0.5, delay + 0.5);
			}
			break;
		}
	}
}

onBotDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
	if (isDefined(sHitLoc) && sHitLoc == "shield") return;
	if (self bot_is_jugger() && (isDefined(self.isDropped) && !self.isDropped)) return;

	self.bleedData = undefined;

	if (isDefined(eAttacker) && eAttacker player_is_survivor())
	{
		if (isDefined(sWeapon))
		{
			if (sWeapon == "artillery_mp" || array_contains(EXPLOSIVE_DAMAGE, sMeansOfDeath)) iDamage *= 4;
			weaponClass = lethalbeats\weapon::weapon_get_class(sWeapon);
			if (weaponClass == "sniper") iDamage *= 4;
			if (weaponClass != "projectile" && weaponClass != "riot")
			{
				if (lethalbeats\string::string_starts_with(sWeapon, "alt_") && isSubStr(sWeapon, "shotgun")) iDamage *= 4;
				else
				{
					weaponBase = lethalbeats\weapon::weapon_get_baseName(sWeapon);
					if (weaponBase == "iw5_deserteagle" || weaponBase == "iw5_44magnum") iDamage *= 4;
					else if (weaponBase == "iw5_mp412" || weaponBase == "iw5_ksg") iDamage *= 2.5;
					else if (weaponBase == "iw5_mk14") iDamage *= 2;
				}
				eAttacker.summary["hits"]++;
				if (eAttacker.summary["hits"] <= eAttacker.summary["totalshots"]) eAttacker.summary["accuracy"] = clamp(eAttacker.summary["hits"] / eAttacker.summary["totalshots"], 0.0, 1.0) * 100;
			}
		}

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
				
				if (diff > 0.3)
				{
					self player_give_perk("specialty_finalstand", false);
					self.bleedData = [eInflictor, eAttacker, iDFlags, sMeansOfDeath, sWeapon, sHitLoc];
				}
			}
		}
	}

	if (self bot_is_explosive() && array_contains(EXPLOSIVE_DAMAGE, sMeansOfDeath)) self notify("detonate", eAttacker);
	
	self maps\mp\bots\_bot_internal::onDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
	self maps\mp\bots\_bot_script::onDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
	
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
		if (!self bot_is_killstreak() && !(self bot_is_jugger() && !self.isDropped)) self bot_kill(eAttacker);
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

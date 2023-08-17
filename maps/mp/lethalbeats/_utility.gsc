#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

_init()
{
	setDvarIfUninitialized("gamemode_class", 0);
	setDvarIfUninitialized("refill_ammo", 0);
	setDvarIfUninitialized("perk_streak", 0);
	setDvarIfUninitialized("hide_perk_menu", 0);
	setDvarIfUninitialized("disable_weapon_pickup", 0);
	setDvarIfUninitialized("fall_damage", 1);
	
	if (getDvarInt("perk_streak")) level.mode_perks = ["specialty_quickdraw", "specialty_bulletaccuracy", "specialty_stalker", "specialty_longersprint", "specialty_fastreload", "specialty_quieter", "specialty_autospot"];
	if (getDvarInt("gamemode_class")) setGameModeClass();
		
	level.prevCallbackPlayerKilled = isDefined(level.onPlayerKilled) ? level.onPlayerKilled : maps\mp\gametypes\_damage::Callback_PlayerKilled;
	level.onPlayerKilled = ::_onPlayerKilled;
	
	level.prevCallbackPlayerDamage = isDefined(level.callbackPlayerDamage) ? level.callbackPlayerDamage : maps\mp\gametypes\_damage::Callback_PlayerDamage;
	level.callbackPlayerDamage = ::_onPlayerDamage;
	
	level.onPlayerConnect = ::blank;
	level.onPlayerSpawn = ::blank;
	level.onPlayerKill = ::blank;
	level.onPlayerDamage = ::blank;
	
	level thread _onPlayerConnect();
}

_onPlayerConnect()
{
	level endon("game_ended");
	for (;;)
	{
		level waittill("connected", player);
		
		if (getDvarInt("refill_ammo")) player thread refillAmmo();

		player thread [[level.onPlayerConnect]]();
		player thread _onPlayerSpawn();
	}
}

_onPlayerSpawn()
{
	level endon("game_ended");
	self endon("disconnect");
	
	for(;;)
	{
		self waittill("spawned_player");
		
		if (getDvarInt("perk_streak")) self.currentPerk = 0;
		if (getDvarInt("hide_perk_menu")) self openMenu("perk_hide");
		if (getDvarInt("disable_weapon_pickup")) self disableWeaponPickup();
		
		self thread [[level.onPlayerSpawn]]();
	}
}

_onPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
	if (!getDvarInt("fall_damage") && isDefined(sMeansOfDeath) && sMeansOfDeath == "MOD_FALLING") return;
	
	damaged = self [[level.onPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
	if(isDefined(damaged) && damaged) return;
	
	if (self isTestClient())
	{
		self maps\mp\bots\_bot_internal::onDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
		self maps\mp\bots\_bot_script::onDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
	}
	
	self [[level.prevCallbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
}

_onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration, lifeId)
{
	if (isDefined(level.mode_perks)) attacker givePerkOnStreak();
	
	self [[level.onPlayerKill]](eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration, lifeId);
	
	if (self isTestClient())
	{
		self maps\mp\bots\_bot_internal::onKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
		self maps\mp\bots\_bot_script::onKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
	}
	
	self [[level.prevCallbackPlayerKilled]](eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
}

_onSpawnPlayer()
{
	if (isDefined(self.loadout)) self.pers["gamemodeLoadout"] = self.loadout;
	else if (isDefined(level.mode_loadout)) self.pers["gamemodeLoadout"] = level.mode_loadout;
	else self.pers["gamemodeLoadout"] = level.mode_loadouts[self.pers["team"]];	
	[[level.prevCallbackOnSpawnPlayer]]();
}

_getSpawnPoint()
{
	self.pers["class"] = "gamemode";
	self.pers["lastClass"] = "";
	self.class = self.pers["class"];
	self.lastClass = self.pers["lastClass"];
	
	return [[level.prevCallbackGetSpawnPoint]]();
}

setGameModeClass()
{
	level.prevCallbackGetSpawnPoint = level.getSpawnPoint;
	level.getSpawnPoint = ::_getSpawnPoint;
	
	level.prevCallbackOnSpawnPlayer = level.onSpawnPlayer;
	level.onSpawnPlayer = ::_onSpawnPlayer;
}

setGameModeLoadout(loadout, team)
{
	if(isDefined(team)) level.mode_loadouts[team] = loadout;
	else level.mode_loadout = loadout;
}

setNotifyModeName(name)
{
	game["strings"]["axis_name"] = name;
	game["strings"]["allies_name"] = name;
	game["colors"]["axis"] = game["colors"]["blue"];
	game["colors"]["allies"] = game["colors"]["blue"];
	game["icons"]["axis"] = undefined;
	game["icons"]["allies"] = undefined;
}

refillAmmo()
{
	level endon("game_ended");
	self endon("disconnect");
	
	self thread maps\mp\gametypes\gun::refillSingleCountAmmo();
	
	for(;;)
	{
		self waittill("reload");
		self playLocalSound("scavenger_pack_pickup");
		self giveStartAmmo(self getCurrentWeapon());
	}	
}

givePerkOnStreak()
{
	if (isPlayer(self) && self.currentPerk < 6)
	{
		self.currentPerk++;
		perk = level.mode_perks[self.currentPerk];
		self thread maps\mp\gametypes\_hud_message::killstreakSplashNotify(perk + "_ks_pro", self.currentPerk);
		self _setPerk(perk, 1);
	}
}

getComboAttach()
{
		
}

getRandomAttach(weapon)
{	
	attachs = getAttachs(weapon);
	return isDefined(attachs) ? random(attachs) : "none";
}

getAttachs(weapon)
{
	if(tablelookup("mp/statstable.csv", 4, weapon, 11) == "") return undefined;
	
	table = "mp/statstable.csv";
	wepIndex = int(tablelookup(table, 4, weapon, 0));
	attachs = [];
	
	attach = "none";
	for (column = 11; attach != ""; column++)
	{
		attachs[attachs.size] = tableLookupByRow(table, wepIndex, column);
		attach = tableLookupByRow(table, wepIndex, column + 1);
	}
	
	return attachs;
}

getRandomCamo(weapon)
{
	if (weapon == "riotshield" || weapon == "iw5_riotshieldjugg") return "none";
	return getWeaponClass(weapon) == "primary" ? tableLookupByRow("mp/camotable.csv", randomInt(13), 1) : "none";
}

getRandomWeapon()
{
	table = "mp/statstable.csv";
	except = ["", "c2", "weapon_explosive", "weapon_other", "weapon_grenade", "feature"];
	index = randomInt(200);
	result = tableLookupByRow(table, index, 2);
	
	while(!isDefined(result) || contains(result, except))
	{
		index = randomInt(200);
		result = tableLookupByRow(table, index, 2);
	}
	
	return tableLookupByRow(table, index, 4);
}

getWeaponClass(weapon)
{
	table = "mp/challengefilters.csv";
	type = tablelookup(table, 0, weapon + "_base", 1);
	return strtok(tablelookup(table, 0, type, 1), "_")[0];
}

randomNum(size, min, max)
{
	uniqueArray = [size];
	random = 0;

	for (i = 0; i < size; i++)
	{
		random = randomIntRange(min, max);
		for (j = i; j >= 0; j--)
			if (isDefined(uniqueArray[j]) && uniqueArray[j] == random)
			{
				random = randomIntRange(min, max);
				j = i;
			}
		uniqueArray[i] = random;
	}
	return uniqueArray;
}

arraysUnion(arrays)
{
	data = [];
	foreach(array in arrays)
		foreach(item in array)
			data[data.size] = item;
	return data;
}

contains(target, array)
{
	foreach(i in array)
		if(i == target) return true;
	return false;
}

sum(array)
{
	sum = 0;
	foreach(i in array) sum += i;
	return sum;
}

replace(string, target)
{
	if(!isSubstr(string, target)) return string;
	
	newString = "";
	index = 0;
	
	for(;;)
	{
		if (string.size - (index + 1) < target.size) break;		
		_target = "";		
		for(i = index; i < string.size; i++) _target += string[i];
		if (string_starts_with(_target, target)) break;
		index++;
	}
	
	for(i = 0; i < string.size; i++)
		if (i < index || i > index + target.size - 1) newString += string[i];
	
	return newString;
}

blank(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
{
}
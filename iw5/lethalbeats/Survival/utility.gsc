#include lethalbeats\array;
#include lethalbeats\hud;
#include lethalbeats\player;
#include lethalbeats\string;
#include lethalbeats\weapon;

#define AFRICA_MILITIA_CLASS ["SMG", "ASSAULT", "LMG", "RIOT", "SHOTGUN"]

#define LOADOUT_PRIMARY "loadoutPrimary"
#define LOADOUT_PRIMARY_ATTACHMENT "loadoutPrimaryAttachment"
#define LOADOUT_PRIMARY_ATTACHMENT2 "loadoutPrimaryAttachment2"
#define LOADOUT_PRIMARY_BUFF "loadoutPrimaryBuff"
#define LOADOUT_PRIMARY_CAMO "loadoutPrimaryCamo"
#define LOADOUT_PRIMARY_RETICLE "loadoutPrimaryReticle"
#define LOADOUT_SECONDARY "loadoutSecondary"
#define LOADOUT_SECONDARY_ATTACHMENT "loadoutSecondaryAttachment"
#define LOADOUT_SECONDARY_ATTACHMENT2 "loadoutSecondaryAttachment2"
#define LOADOUT_SECONDARY_BUFF "loadoutSecondaryBuff"
#define LOADOUT_SECONDARY_CAMO "loadoutSecondaryCamo"
#define LOADOUT_SECONDARY_RETICLE "loadoutSecondaryReticle"
#define LOADOUT_LETHAL "loadoutEquipment"
#define LOADOUT_TACTICAL "loadoutOffhand"
#define LOADOUT_PERK1 "loadoutPerk1"
#define LOADOUT_PERK2 "loadoutPerk2"
#define LOADOUT_PERK3 "loadoutPerk3"
#define LOADOUT_STREAK_TYPE "loadoutStreakType"
#define LOADOUT_KILLSTREAK1 "loadoutKillstreak1"
#define LOADOUT_KILLSTREAK2 "loadoutKillstreak2"
#define LOADOUT_KILLSTREAK3 "loadoutKillstreak3"
#define LOADOUT_DEATHSTREAK "loadoutDeathstreak"
#define LOADOUT_JUGGERNAUT "loadoutJuggernaut"

#define GAME_MODE_LOADOUT "gamemodeLoadout"
#define SPECIALTY_NULL "specialty_null"
#define NONE "none"

#define SEMTEX "semtex_mp"
#define CONCUSSION "concussion_grenade_mp"
#define FRAG "frag_grenade_mp"
#define FLASH "flash_grenade_mp"
#define CLAYMORE "claymore_mp"
#define C4 "c4_mp"
#define THROWING_KNIFE "throwingknife_mp"
#define BOUNCINGBETTY "bouncingbetty_mp"
#define SMOKE "smoke_grenade_mp"

#define UI_LETHAL "ui_lethal"
#define UI_TACTICAL "ui_tactical"

#define BOTS_ABILITIES ["dog", "martyrdom", "chemical", "chopper", "jugger", "pavelow", "reaper", "tank", "airstrike", "predator", "counteruav", "emp", "ims", "sentry", "riotshield"]
#define BOTS_ABILITIES_KS ["chopper", "pavelow", "reaper", "tank", "airstrike", "predator", "counteruav", "emp"]
#define TABLE "mp/survival_bots.csv"

#define CHOPPER "chopper"
#define JUGGER "jugger"
#define CHEMICAL "chemical"
#define MARTYRDOM "martyrdom"
#define DOG_REG "dog_reg"
#define DOG_SPLODE "dog_splode"
#define GENERIC "generic"

#define WAVES_TABLE "mp/survival_waves.csv"
#define INTEL_DIALOG ["boss_transport_many", "boss_transport", "chopper_many", "chopper", "chemical", "claymore", "dog_splode", "martyrdom", "dog_reg", "generic"]

#define CHALLENGES ["Headshot Kill", "Kill Streak", "Knife Kill", "Grenade Kill", "Pistol Kill", "Shotgun Kill", "Machine Pistol Kill", "Smg Kill", "Assault Kill", "Lmg Kill", "Sniper Kill", "Launcher Kill", "Double Kill", "Triple Kill", "Multi Kill"]

#define WAVE_LOOP 26

// LOADOUTS COLUMNS
#define PRIMARY 1
#define PRIMARY_ATTACH 2
#define PRIMARY_ATTACH_2 3
#define PRIMARY_BUFF 4
#define SECONDARY 5
#define SECONDARY_ATTACH 6
#define SECONDARY_ATTACH_2 7
#define SECONDARY_BUFF 8
#define LETHAL 9
#define TACTICAL 10
#define PERK1 11
#define PERK2 12
#define PERK3 13
#define HEALTH 14
#define SPEED 15
#define PRICE 16
#define BODY_MODEL 17
#define HEAD_MODEL 18

//////////////////////////////////////////
//	             PLAYER   		        //
//////////////////////////////////////////

/*
///DocStringBegin
detail: <Player> player_is_bot(): <Bool>
summary: Returns true if the player is a survival bot. `botType` is defined only for bots.
///DocStringEnd
*/
player_is_bot()
{
	return isPlayer(self) && isDefined(self.botType);
}

/*
///DocStringBegin
detail: <Player> player_is_survivor(): <Bool>
summary: Returns true if the player is a survivor.
///DocStringEnd
*/
player_is_survivor()
{
	return isPlayer(self) && self.team == "allies";
}

/*
///DocStringBegin
detail: <Player> player_set_nades(nade: <String>, value: <Int>): <Void>
summary: Allow equip grenades regardless of their class and set stock, maximum capacity according to survival stock, C4 & Claymore `10`, others `4`.
///DocStringEnd
*/
player_set_nades(nade, value)
{
	switch(nade)
	{
		case FRAG:
			ui_dvar = UI_LETHAL;
			self setOffhandPrimaryClass("frag");
			self _player_take_nades(THROWING_KNIFE);
			break;
		case THROWING_KNIFE:
			ui_dvar = UI_LETHAL;
			self setOffhandPrimaryClass("throwingknife");
			self _player_take_nades(FRAG);
			break;
		case FLASH:
			ui_dvar = UI_TACTICAL;
			self setOffhandSecondaryClass("flash");
			self _player_take_nades(CONCUSSION);
			break;
		case CONCUSSION:
			ui_dvar = UI_TACTICAL;
			self setOffhandSecondaryClass("smoke");
			self _player_take_nades(FLASH);
			break;
		default:
			ui_dvar = "ui_" + strTok(nade, "_")[0];
			break;
	}

	self giveWeapon(nade);
	maxAmmo = player_get_max_nades(nade);	
	self.grenades[nade] = int(min(value, maxAmmo));
	self setClientDvar(ui_dvar, self.grenades[nade]);
	self setWeaponAmmoStock(nade, int(self.grenades[nade]));
}

/*
///DocStringBegin
detail: <Player> player_add_nades(nade: <String>, value: <Int>): <Void>
summary: Refill current nade stock, maximum capacity according to survival stock, C4 & Claymore `10`, others `4`.
///DocStringEnd
*/
player_add_nades(nade, value)
{
	if(!(self hasWeapon(nade))) self giveweapon(nade);
	self player_set_nades(nade, self.grenades[nade] + value);
}

/*
///DocStringBegin
detail: <Player> player_clear_nades(): <Void>
summary: Takes away all types of grenades from the player.
///DocStringEnd
*/
player_clear_nades()
{
	self _player_take_nades(SEMTEX);
	self _player_take_nades(CONCUSSION);
	self _player_take_nades(FRAG);
	self _player_take_nades(FLASH);
	self _player_take_nades(CLAYMORE);
	self _player_take_nades(C4);
	self _player_take_nades(THROWING_KNIFE);
}

/*
///DocStringBegin
detail: player_get_max_nades(nade: <String>): <Int>
summary: Returns survival nades max stock, C4 & Claymore `10`, others `4`.
///DocStringEnd
*/
player_get_max_nades(nade)
{
	switch(nade)
	{
		case FRAG:
		case THROWING_KNIFE:
		case FLASH:
		case SEMTEX:
		case CONCUSSION: 
		case SMOKE: return 4;
		case BOUNCINGBETTY:
		case CLAYMORE:
		case C4: return 10;
	}
}

/*
///DocStringBegin
detail: <Player> player_has_nades(nade: <String>): <Bool>
summary: Checks if the player has a specific grenade type defined, regardless of the ammo count.
///DocStringEnd
*/
player_has_nades(nade)
{
	return array_contains_key(self.grenades, nade);
}

/*
///DocStringBegin
detail: <Player> player_has_nade_stock(nade?: <String>): <Bool>
summary: Checks if the player has stock for a specific nade. If no nade is specified, it checks if any nade has stock.
///DocStringEnd
*/
player_has_nade_stock(nade)
{
	if (!isDefined(nade))
	{
		foreach(nade, count in self.grenades)
			if (count) return true;
		return false;
	}

	if (!array_contains_key(self.grenades, nade)) return false;
	return self.grenades[nade] > 0;
}

/*
///DocStringBegin
detail: <Player> _player_take_nades(nade: <String>): <Void>
summary: Internal function to remove a specific grenade, taking the weapon and resetting UI Dvar and ammo count.
///DocStringEnd
*/
_player_take_nades(nade)
{
	switch(nade)
	{
		case FRAG:
			ui_dvar = UI_LETHAL;
			break;
		case THROWING_KNIFE:
			ui_dvar = UI_LETHAL;
			break;
		case FLASH:
			ui_dvar = UI_TACTICAL;
			break;
		case CONCUSSION:
			ui_dvar = UI_TACTICAL;
			break;
		default:
			ui_dvar = "ui_" + strTok(nade, "_")[0];
			break;
	}

	self setClientDvar(ui_dvar, 0);
	self takeweapon(nade);
	self.grenades[nade] = 0;
}

/*
///DocStringBegin
detail: <Player> player_clear_last_stand(): <Void>
summary: Clears the player's last stand state, restoring health, controls, weapons, and cleaning up HUD elements.
///DocStringEnd
*/
player_clear_last_stand()
{
	level.survivors_bleedout = array_remove_key(level.survivors_bleedout, self.guid);

	self player_give_perk("specialty_finalstand", false);

	self.health = self.maxhealth;
	self.inFinalStand = false;
	self.lastStand = undefined;
	
	self maps\mp\_utility::clearLowerMessage("last_stand");

	self player_enable_usability();
	self player_enable_weapon_switch();
	self player_enable_offhand_weapons();
	self player_enable_weapon_pickup();

	if (isDefined(self.reviveSpot))
	{
		self unlink();
		self.reviveSpot delete();
	}

	if (isDefined(self.lastStandBar))
	{
		trigger = self.lastStandBar.trigger; // delete trigger end this thread
		self.lastStandBar hud_destroy();
		if (isDefined(trigger)) trigger lethalbeats\trigger::trigger_delete();
	}
}

/*
///DocStringBegin
detail: <Player> player_refill_nades(): <Void>
summary: A looped thread that decrements grenade count when fired. Breaks for bots if they run out of nades.
///DocStringEnd
*/
player_refill_nades()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");

	for (;;)
    {
		if (self player_is_bot() && !self player_has_nade_stock()) break;

		self waittill("grenade_fire", grenade, weaponName);

		if(!isDefined(grenade) || !self player_has_nades(weaponName) || !isAlive(self)) continue;
		if(self.grenades[weaponName])
		{
			self player_add_nades(weaponName, -1);
			if(weaponName == CLAYMORE && self.grenades[weaponName]) self switchToWeapon(weaponName);
		}
	}
}

/*
///DocStringBegin
detail: <Player> player_client_cmd(cmd: <String>): <Void>
summary: Sends a command to the player's client by setting a DVar and opening a specific menu.
///DocStringEnd
*/
player_client_cmd(cmd)
{
	self setClientDvar("client_cmd", cmd);
	self openMenu("client_cmd");
}

/*
///DocStringBegin
detail: <Player> player_do_damage(eInflictor?: <Entity>, eAttacker?: <Entity>, iDamage?: <Int>, iDFlags?: <Int>, sMeansOfDeath?: <String>, sWeapon?: <String>, vPoint?: <Vector3>, vDir?: <Vector3>, sHitLoc?: <String>, timeOffset?: <Int>): <Void>
summary: Wrapper function to apply damage to the player by calling the level's damage callback with default parameters.
///DocStringEnd
*/
player_do_damage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
	if (!isDefined(timeOffset)) timeOffset = 0;
	if (!isDefined(sHitLoc)) sHitLoc = "none";
	if (!isDefined(vDir)) vDir = (0, 0, 0);
	if (!isDefined(vPoint)) vPoint = (0, 0, 0);
	if (!isDefined(sWeapon)) sWeapon = "frag_grenade_mp";
	if (!isDefined(sMeansOfDeath)) sMeansOfDeath = "MOD_SUICIDE";
	if (!isDefined(iDFlags)) iDFlags = 0;
	if (!isDefined(iDamage)) iDamage = 1;
	if (!isDefined(eAttacker)) eAttacker = self;
	if (!isDefined(eInflictor)) eInflictor = self;
	self thread [[level.callbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
}

/*
///DocStringBegin
detail: <Player> player_create_weapon_data(weapon: <String>, buffs: <String[]>): <WeaponData>
summary: Creates a new weapon data structure using the `lethalbeats\survival\armories\weapons` library.
///DocStringEnd
*/
player_create_weapon_data(weapon, buffs)
{
	return lethalbeats\survival\armories\weapons::newWeaponData(weapon, buffs);
}

/*
///DocStringBegin
detail: <Player> player_set_weapon_data(weapon: <String>, data: <Struct>): <Void>
summary: Sets the custom weapon data for the player's primary or secondary slot.
///DocStringEnd
*/
player_set_weapon_data(weapon, data)
{
    lethalbeats\survival\armories\weapons::setWeaponData(weapon, data);
}

/*
///DocStringBegin
detail: <Player> player_get_weapon_data(weapon: <String>): <Struct>
summary: Retrieves custom weapon data. It checks the player's cache, then a global bot weapon cache, or creates new data if none exists.
///DocStringEnd
*/
player_get_weapon_data(weapon)
{
    return self lethalbeats\survival\armories\weapons::getWeaponData(weapon);
}

player_drop_weapon()
{
	weapon = self getCurrentWeapon();
	if (!isDefined(weapon)) weapon = "none";
	if (weapon != "none") self player_take_all_weapon_buffs();

	self.lastdroppableweapon = weapon;
	self lethalbeats\survival\patch\globallogic::patch_dropWeaponForDeath(self);
}

player_give_random_ammo(weapon, minClips, maxClips)
{
	if (!isDefined(weapon)) weapon = self getCurrentWeapon();
	if (!isDefined(minClips)) minClips = 2;
	if (!isDefined(maxClips)) maxClips = 4;

	if (minClips > maxClips) minClips = maxClips;

	clipSize = weaponClipSize(weapon);
	maxStock = weaponMaxAmmo(weapon);

	if (clipSize == 0 || maxStock == 0)
	{
		self player_give_max_ammo(weapon);
		return;
	}

	numClipsToGive = randomIntRange(minClips, maxClips + 1);
	randomAmmo = numClipsToGive * clipSize;
	newStockAmmo = int(min(randomAmmo, maxStock));

	self setWeaponAmmoStock(weapon, newStockAmmo);
	self setWeaponAmmoClip(weapon, clipSize);
	
	if (string_starts_with(weapon, "alt_")) return;

	if (weapon_has_attach_akimbo(weapon)) self setWeaponAmmoClip(weapon, clipSize, "left");

	if (weapon_has_attach_alt(weapon))
	{
		altWeapon = "alt_" + weapon;
		self giveMaxAmmo(altWeapon);
		self setWeaponAmmoClip(altWeapon, weaponClipSize(altWeapon));
	}
}

//////////////////////////////////////////
//	              BOT   		        //
//////////////////////////////////////////

/*
///DocStringBegin
detail: bot_get_abilities_list(): <String[]>
summary: Returns an array of all bot abilities.
///DocStringEnd
*/
bot_get_abilities_list()
{
	return BOTS_ABILITIES;
}

/*
///DocStringBegin
detail: <Player> bot_has_ability(ability: <String>): <Bool>
summary:  Return true if the bot has the ability. `jugg`, `chopper`, `dogChemical`, `chemical`, `dogMartyrdom`, `martyrdom`, `dog`.
///DocStringEnd
*/
bot_has_ability(ability)
{
	if (!isDefined(self.botType)) return false;
	if (self.botType == ability) return true;
	if (isSubStr(self.botType, "_")) return array_contains(strTok(self.botType, "_"), ability);
	return false;
}

/*
///DocStringBegin
detail: <Player> bot_is_dog(): <Bool>
summary: Returns true if the bot has dog ability.
///DocStringEnd
*/
bot_is_dog()
{
	return self bot_has_ability("dog");
}

/*
///DocStringBegin
detail: <Player> bot_is_jugger(): <Bool>
summary: Returns true if the bot has juggernaut boss ability.
///DocStringEnd
*/
bot_is_jugger()
{
	return self bot_has_ability(JUGGER);
}

/*
///DocStringBegin
detail: <Player> bot_is_chemical(): <Bool>
summary: Returns true if the bot has any chemical ability.
///DocStringEnd
*/
bot_is_chemical()
{
	return self bot_has_ability(CHEMICAL);
}

/*
///DocStringBegin
detail: <Player> bot_is_martyrdom(): <Bool>
summary: Returns true if the bot has any martyrdom ability.
///DocStringEnd
*/
bot_is_martyrdom()
{
	return self bot_has_ability(MARTYRDOM);
}

/*
///DocStringBegin
detail: <Player> bot_is_chopper(): <Bool>
summary: Returns true if the bot has littlebird heli boss ability.
///DocStringEnd
*/
bot_is_chopper()
{
	return self bot_has_ability(CHOPPER);
}

/*
///DocStringBegin
detail: <Player> bot_is_explosive(): <Bool>
summary: Returns true if the bot has any martyrdom or chemical ability.
///DocStringEnd
*/
bot_is_explosive()
{
	return self bot_is_martyrdom() ||  self bot_is_chemical();
}

/*
///DocStringBegin
detail: <Entity> bot_is_killstreak(): <Bool>
summary: Returns true if the bot is a killstreak or a vehicle
///DocStringEnd
*/
bot_is_killstreak()
{
	if (!isDefined(self.botType)) return false;
	return array_contains(BOTS_ABILITIES_KS, self.botType);
}

/*
///DocStringBegin
detail: <Player> bot_get_abilities(getAsIndex?: <Bool> = false): <String[]> | <Int[]>
summary: Returns an array of abilities from bot type.
///DocStringEnd
*/
bot_get_abilities(getAsIndex)
{
	if (!isDefined(self.botType)) return [];
	if (!isDefined(getAsIndex)) getAsIndex = false;
	if (isSubStr(self.botType, "_")) target = strTok(self.botType, "_");
	else target = [self.botType];

	result = [];
	index = 0;
	foreach(ability in BOTS_ABILITIES)
	{
		if (array_contains(target, ability)) result[result.size] = getAsIndex ? index : ability;
		index++;
	}
	return result;
}

/*
///DocStringBegin
detail: bots(ability?: <String | Undefined>, alives?: <Bool | Undefined>): <PLayer[]>
summary: Returns array of bots, optionally can be filtered by ability or alives. Bots pool are ignored.
///DocStringEnd
*/
bots(ability, alives)
{
	bots = isDefined(alives) ? players_get_list("axis", alives) : players_get_list("axis");
	if (isDefined(ability)) return array_filter_ent(bots, ::bot_has_ability, ability);
	return bots;
}

/*
///DocStringBegin
detail: bot_get_count(ability?: <String>): <Int>
summary: Returns count of bots, optionally can be filtered by ability.
///DocStringEnd
*/
bot_get_count(ability)
{
	return bots(ability, true).size;
}

/*
///DocStringBegin
detail: <Player> bot_set_loadout(): <Void>
summary: Sets the bot's loadout based on the current wave's bot pool, assigning weapons, perks, model, speed, health, and other properties.
///DocStringEnd
*/
bot_set_loadout()
{
	popData = array_pop(level.bots_wave);
	level.bots_wave = popData[0];
    self.botType = popData[1];
	
	if(!isDefined(self.botType)) return;
	if(!isDefined(self bot_get_loadout(PRIMARY))) return;

    self.pers[GAME_MODE_LOADOUT][LOADOUT_PRIMARY] = self bot_get_loadout(PRIMARY);
    self.pers[GAME_MODE_LOADOUT][LOADOUT_PRIMARY_ATTACHMENT] =  self bot_get_loadout(PRIMARY_ATTACH);
    self.pers[GAME_MODE_LOADOUT][LOADOUT_PRIMARY_ATTACHMENT2] = self bot_get_loadout(PRIMARY_ATTACH_2);
    self.pers[GAME_MODE_LOADOUT][LOADOUT_PRIMARY_BUFF] = self bot_get_loadout(PRIMARY_BUFF);
    self.pers[GAME_MODE_LOADOUT][LOADOUT_SECONDARY] = self bot_get_loadout(SECONDARY);
    self.pers[GAME_MODE_LOADOUT][LOADOUT_SECONDARY_ATTACHMENT] = self bot_get_loadout(SECONDARY_ATTACH);
    self.pers[GAME_MODE_LOADOUT][LOADOUT_SECONDARY_ATTACHMENT2] = self bot_get_loadout(SECONDARY_ATTACH_2);
    self.pers[GAME_MODE_LOADOUT][LOADOUT_SECONDARY_BUFF] = self bot_get_loadout(SECONDARY_BUFF);
    self.pers[GAME_MODE_LOADOUT][LOADOUT_LETHAL] = self bot_get_loadout(LETHAL);
    self.pers[GAME_MODE_LOADOUT][LOADOUT_TACTICAL] = self bot_get_loadout(TACTICAL);
    self.pers[GAME_MODE_LOADOUT][LOADOUT_PERK1] = self bot_get_loadout(PERK1);
    self.pers[GAME_MODE_LOADOUT][LOADOUT_PERK2] = self bot_get_loadout(PERK2);
    self.pers[GAME_MODE_LOADOUT][LOADOUT_PERK3] = self bot_get_loadout(PERK3);
	
	lethal = self.pers[GAME_MODE_LOADOUT][LOADOUT_LETHAL];
	if (isDefined(lethal) && lethal != NONE && lethal != SPECIALTY_NULL)
	 	self player_set_nades(lethal, 4);
	
	tactical = self.pers[GAME_MODE_LOADOUT][LOADOUT_TACTICAL];
	if (isDefined(tactical) && tactical != NONE && tactical != SPECIALTY_NULL)
		self player_set_nades(tactical, 4);
	
	self.moveSpeedScaler = float(self bot_get_loadout(SPEED));
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
	
	self maps\mp\bots\_bot_utility::botGiveLoadout(self.team, "gamemode", false, true);
	self maps\mp\killstreaks\_killstreaks::clearKillstreaks();
	
	self.botPrice = int(self bot_get_loadout(PRICE));
	
	level.score_base += self.botPrice;
	
	if (self.botType == "jugger_riotshield") // for some reason when changing the model the riotshield's ricochet stops working ᕙ(⇀‸↼‵‵)ᕗ
	{
		bodyModel = "";
		headModel = "";
		self [[game["axis_model"]["JUGGERNAUT"]]]();
	}
	else
	{
		bodyModel = self bot_get_loadout(BODY_MODEL);
		headModel = self bot_get_loadout(HEAD_MODEL);
	}

	if (!array_contains_key(level.bots_weapons_data, self.botType))
	{
		level.bots_weapons_data[self.botType] = true;		
		loadout = self.pers[GAME_MODE_LOADOUT];

		if (loadout[LOADOUT_PRIMARY] != "none")
		{
			primaryWep = weapon_build(loadout[LOADOUT_PRIMARY], [loadout[LOADOUT_PRIMARY_ATTACHMENT], loadout[LOADOUT_PRIMARY_ATTACHMENT2]]);
			primaryBuff = loadout[LOADOUT_PRIMARY_BUFF] == SPECIALTY_NULL ? [] : [loadout[LOADOUT_PRIMARY_BUFF]];
			level.bots_weapons_data[primaryWep] = self player_create_weapon_data(primaryWep, primaryBuff);
		}

		if (loadout[LOADOUT_SECONDARY] != "none")
		{
			secondaryWep = weapon_build(loadout[LOADOUT_SECONDARY], [loadout[LOADOUT_SECONDARY_ATTACHMENT], loadout[LOADOUT_SECONDARY_ATTACHMENT2]]);
			secondaryBuff = loadout[LOADOUT_SECONDARY_BUFF] == SPECIALTY_NULL ? [] : [loadout[LOADOUT_SECONDARY_BUFF]];
			level.bots_weapons_data[secondaryWep] = self player_create_weapon_data(secondaryWep, secondaryBuff);
		}
	}
	
	self bot_set_difficulty();

	if (game[self.team] == "opforce_africa" && self bot_has_ability("easy"))
	{
		self [[game[self.team + "_model"][array_random(AFRICA_MILITIA_CLASS)]]]();
		return;
	}

	if (headModel == "" || bodyModel == "") return;

	self.pers["voicePrefix"] = "RU_" + randomIntRange(0, 4) + "_";
	self detachall();
	self attach(isSubStr(headModel, " ") ? array_random(strtok(headModel, " ")) : headModel, "", true);
	self setmodel(isSubStr(bodyModel, " ") ? array_random(strtok(bodyModel, " ")) : bodyModel);
}

/*
///DocStringBegin
detail: <Player> bot_get_loadout(column: <Int>): <Any>
summary: Retrieves a specific piece of loadout data for the bot from a `mp/survival_bots.csv` table based on its type.
///DocStringEnd
*/
bot_get_loadout(column)
{
	return tableLookup(TABLE, 0, self.botType, column);
}

/*
///DocStringBegin
detail: <Player> bot_set_difficulty(): <Void>
summary: Adjusts the bot's AI skill and behavior settings based on the current wave number.
///DocStringEnd
*/
bot_set_difficulty()
{
	wave = sqrt(level.wave_num);

	self.pers["bots"]["skill"]["spawn_time"] = 0;
    self.pers["bots"]["skill"]["aim_time"] = _bot_wave_scale(0.6, 0, 0.1, wave);
    self.pers["bots"]["skill"]["init_react_time"] = self.pers["bots"]["skill"]["aim_time"];
    self.pers["bots"]["skill"]["reaction_time"] = _bot_wave_scale(2500, 0, 0.1, wave);
    self.pers["bots"]["skill"]["remember_time"] = _bot_wave_scale(500, 7500, 1, wave);
    self.pers["bots"]["skill"]["no_trace_ads_time"] = _bot_wave_scale(500, 2500, 0.2, wave);
    self.pers["bots"]["skill"]["no_trace_look_time"] = self.pers["bots"]["skill"]["no_trace_ads_time"];
    self.pers["bots"]["skill"]["fov"] = wave > 15 ? -1 : _bot_wave_scale(0.7, 0, 0.2, wave);
    self.pers["bots"]["skill"]["dist_start"] = _bot_wave_scale(1000, 10000, 0.5, wave);
    self.pers["bots"]["skill"]["dist_max"] =_bot_wave_scale(1200, 15000, 0.8, wave);
    self.pers["bots"]["skill"]["help_dist"] = 3000;
    self.pers["bots"]["skill"]["semi_time"] = _bot_wave_scale(0.9, 0.05, 0.3, wave);
    self.pers["bots"]["skill"]["shoot_after_time"] = _bot_wave_scale(1, 0, 0.25, wave);
    self.pers["bots"]["skill"]["aim_offset_time"] = _bot_wave_scale(1.8, 0, 0.25, wave);
    self.pers["bots"]["skill"]["aim_offset_amount"] = _bot_wave_scale(4, 0, 0.25, wave);
    self.pers["bots"]["skill"]["bone_update_interval"] = _bot_wave_scale(2.5, 0.25, 0.25, wave);
    self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_ankle_le,j_ankle_ri,j_ankle_le,j_ankle_ri";
    self.pers["bots"]["skill"]["ads_fov_multi"] = 0.5;
    self.pers["bots"]["skill"]["ads_aimspeed_multi"] = 0.5;

    self.pers["bots"]["behavior"]["initswitch"] = 0;
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

	health = int(self bot_get_loadout(HEALTH));
	if (level.wave_num > WAVE_LOOP) health = int(health * lethalbeats\math::math_pow(1.05, level.wave_num - WAVE_LOOP));
	self.maxhealth = health;
	self.health = health;

    if (self bot_is_dog())
    {
        self.pers["bots"]["skill"]["aim_time"] = 0;
        self.pers["bots"]["behavior"]["strafe"] = 35;
        self.pers["bots"]["behavior"]["sprint"] = 100;
        self.pers["bots"]["behavior"]["jump"] = 35;
		return;
    }
	
	if (self bot_is_jugger())
	{
		self.pers["bots"]["behavior"]["sprint"] = 0;
		self.pers["bots"]["behavior"]["jump"] = 0;
		self.pers["bots"]["behavior"]["strafe"] = 0;
	}

	if (self.pers[GAME_MODE_LOADOUT][LOADOUT_PRIMARY] == "rpg" || weapon_get_class(self.pers[GAME_MODE_LOADOUT][LOADOUT_PRIMARY]) == "sniper")
	{
		self.pers["bots"]["skill"]["dist_max"] = 15000;
		self.pers["bots"]["skill"]["dist_start"] = 10000;
	}
}

/*
///DocStringBegin
detail: _bot_wave_scale(init_value: <Float>, end_value: <Float>, scale: <Float>, wave: <Float>): <Float>
summary: Calculates a scaled value based on the wave number, used for adjusting bot difficulty over time.
///DocStringEnd
*/
_bot_wave_scale(init_value, end_value, scale, wave)
{
	scale_factor = 1 + scale * wave;
	return init_value > end_value ? max(end_value, init_value / scale_factor) : min(end_value, init_value * scale_factor);
}

/*
///DocStringBegin
detail: <Player> bot_lastStand_suicide(attacker: <Entity>): <Void>
summary: Forces a bot to die after a delay in last stand, bypassing potential engine errors with standard suicide.
///DocStringEnd
*/
bot_lastStand_suicide(attacker) //this simple shit kept me busy for a long time, for some reason suicide gives a lot of errors when the bot is in the last stand, so we force damage and fixed it, suck it fucking shitty errors.
{
	self endon("death");	
	wait 4.5;
	self.health = 1;
	radiusDamage(self getTagOrigin("j_spine4"), 5, 10000, 10000, attacker);
}

/*
///DocStringBegin
detail: <Player> bot_kill(attacker?: <Entity>): <Void>
summary: Handles bot kill logic, awarding score, incrementing death counter, and notifying wave progress.
///DocStringEnd
*/
bot_kill(attacker)
{
	if (isDefined(attacker) && isDefined(attacker.team) && attacker.team == "allies")
	{
		if (isDefined(attacker.owner))
		{
			attacker.owner.summary["kills"]++;
			attacker.owner survivor_give_score(int(self.botPrice / 2));

			if (self bot_is_killstreak())
			{
				attacker.owner.pers["kills"]++;
				attacker.owner.kills++;
			}
		}
		else if (isPlayer(attacker))
		{
			attacker.summary["kills"]++;
			attacker survivor_give_score(self.botPrice);

			if (self bot_is_killstreak())
			{
				attacker.pers["kills"]++;
				attacker.kills++;
			}
		}
	}
	if (isPlayer(self)) 
	{
		self suicide();
		self thread bot_delete_AfterAWhile();
	}
	level.bots_deaths++;
	if (level.bots_total_count == level.bots_deaths) level notify("wave_end");
	if (level.bots_deaths % 15 == 0) thread bot_clear_models();
}

bot_delete_AfterAWhile()
{
	waittillframeend;
	body = self.body;
	if (level.wave_num < 13) wait randomIntRange(5, 10);
	else if (level.wave_num < 22) wait randomIntRange(3, 6);
	else wait randomFloatRange(2, 3);
	if (isDefined(body)) body delete();
}

bot_clear_models()
{
	level endon("wave_start");

	survivors = survivors();

	foreach(bot in bots())
	{
		if (isDefined(bot.body) && !array_any_ent(survivors, lethalbeats\player::player_can_see, bot.body.origin))
			bot.body delete();
	}

	foreach(weapons in level.droppedWeapons)
	{
		if (isDefined(weapons[0]) && !array_any_ent(survivors, lethalbeats\player::player_can_see, weapons[0].origin))
		{
			if (isDefined(weapons[1]) && weapons[1].owner player_is_survivor()) continue;
			if (isDefined(weapons[0])) weapons[0] delete();
			if (isDefined(weapons[1])) weapons[1] delete();
		}
	}
	level.droppedWeapons = [];
}

//////////////////////////////////////////
//	             SURVIVOR   	        //
//////////////////////////////////////////

/*
///DocStringBegin
detail: survivors(alives?: <Boolean | Undefined>): <Entity[]>
summary: Returns an array of survivors optionally filtered by alive status.
///DocStringEnd
*/
survivors(alives)
{
	survivors = players_get_list("allies");
	if (!isDefined(alives)) return survivors;

	result = [];
	foreach(player in survivors)
	{
		isDeath = isDefined(level.survivors_deaths[player.guid]) || isDefined(level.survivors_bleedout[player.guid]);
		if (alives == !isDeath) result[result.size] = player;
	}

	return result;
}

/*
///DocStringBegin
detail: survivors_thread(function: <Function>, alives?: <Bool>): <Void>
summary: A utility function to execute a function as a thread for each survivor.
///DocStringEnd
*/
survivors_thread(function, alives)
{
	if (isDefined(alives)) array_thread_ent(survivors(alives), function);
	else array_thread_ent(survivors(), function);
}

/*
///DocStringBegin
detail: survivors_call(function: <Function>, alives?: <Bool>): <Void>
summary: A utility function to call a function for each survivor.
///DocStringEnd
*/
survivors_call(function, alives)
{
	if (isDefined(alives)) array_call_ent(survivors(alives), function);
	else array_call_ent(survivors(), function);
}

/*
///DocStringBegin
detail: <Player> survivor_set_score(score: <Int>): <Void>
summary: Sets the survivor's score and updates the corresponding UI DVar.
///DocStringEnd
*/
survivor_set_score(score)
{
	self.pers["score"] = score;
	self.score = self.pers["score"];
	self setClientDvar("ui_money", self.pers["score"]);
}

/*
///DocStringBegin
detail: <Player> survivor_give_score(score: <Int>, type?: <String>): <Void>
summary: Gives score to the survivor using the gametype's score-giving function.
///DocStringEnd
*/
survivor_give_score(score, type)
{
	if (!isDefined(type)) type = undefined;
	maps\mp\gametypes\_gamescore::givePlayerScore("survival", self, undefined, int(score), type);
}

/*
///DocStringBegin
detail: <Player> survivor_clear_perks(): <Void>
summary: Removes all custom survival perks from the player.
///DocStringEnd
*/
survivor_clear_perks()
{
	foreach(perk in self.survivalPerks) self player_unset_Perk(perk);
	self.survivalPerks = [];
	self _survivor_update_perks();
}

/*
///DocStringBegin
detail: <Player> survivor_give_perk(perk: <String>): <Void>
summary: Gives a survival perk to the player if they don't already have it and have a free slot (max 3).
///DocStringEnd
*/
survivor_give_perk(perk)
{
	if (self player_has_perk(perk)) return;	
	if(self.survivalPerks.size == 3) return;
	
	self player_give_perk(perk, false);
	
	if(perk == "specialty_bulletaccuracy") perk = "specialty_steadyaim";
	else if(perk == "_specialty_blastshield") perk = "specialty_blastshield";
	else if(perk == "specialty_detectexplosive") perk = "specialty_bombsquad";
	
	self.survivalPerks[self.survivalPerks.size] = perk;
	self _survivor_update_perks();
}

/*
///DocStringBegin
detail: <Player> survivor_remove_perk(perk: <String>): <Void>
summary: Removes a specific survival perk from the player.
///DocStringEnd
*/
survivor_remove_perk(perk)
{
	if (!isDefined(self.perks[perk])) return;
	
	self player_unset_Perk(perk);
	
	if(perk == "specialty_bulletaccuracy") perk = "specialty_steadyaim";
	else if(perk == "_specialty_blastshield") perk = "specialty_blastshield";
	else if (perk == "specialty_detectexplosive") perk = "specialty_bombsquad";
	
	perks = [];
	foreach(i in self.survivalPerks)
	{
		if (i == perk) continue;
		perks[perks.size] = i;
	}
	
	self.survivalPerks = perks;
	self _survivor_update_perks();
}

/*
///DocStringBegin
detail: <Player> _survivor_update_perks(): <Void>
summary: Updates the perk UI DVars to reflect the player's current survival perks.
///DocStringEnd
*/
_survivor_update_perks()
{
	self setClientDvar("ui_perk1", "");
	self setClientDvar("ui_perk2", "");
	self setClientDvar("ui_perk3", "");
	
	if (self.survivalPerks.size < 1) return;
	self setClientDvar("ui_perk1", self.survivalPerks[0]);
	
	if (self.survivalPerks.size < 2) return;
	self setClientDvar("ui_perk2", self.survivalPerks[1]);
	
	if (self.survivalPerks.size < 3) return;
	self setClientDvar("ui_perk3", self.survivalPerks[2]);
}

/*
///DocStringBegin
detail: <Player> survivor_hud_notify_hide(hide: <Bool>): <Void>
summary: Sets whether the main notification HUD elements should be hidden when a menu is open.
///DocStringEnd
*/
survivor_hud_notify_hide(hide)
{
	self.notifyTitle.hideWhenInMenu = hide;
	self.notifyText.hideWhenInMenu = hide;
	self.notifyText2.hideWhenInMenu = hide;
	self.notifyIcon.hideWhenInMenu = hide;
	self.notifyOverlay.hideWhenInMenu = hide;
}

/*
///DocStringBegin
detail: <Player> survivor_display_hud(hud: <String>): <Void>
summary: Displays a specific UI menu/screen by setting a DVar and opening the `ui_display` menu.
///DocStringEnd
*/
survivor_display_hud(hud)
{
	self setClientDvar("ui_display", hud);
	self OpenMenu("ui_display");
}

/*
///DocStringBegin
detail: <Player> survivor_destroy_hud(): <Void>
summary: Destroys and resets all custom survival HUD elements for the player.
///DocStringEnd
*/
survivor_destroy_hud()
{
	if (isDefined(self.hintString)) 
	{
		self.hintString destroy();
		self.hintString = undefined;
	}
	
	self.currMenu = undefined;
	
	self setClientDvar("ui_body_armor", 0);
	self setClientDvar("ui_self_revive", 0);
	self setClientDvar("ui_use_slot", NONE);
	self setClientDvar("client_cmd", "");	
	
	ch = self.ch1;
	if (isDefined(ch))
	{
		ch["huds"][0] hud_destroy();
		ch["huds"][1] destroy();
		ch["huds"][2] destroy();
		self.ch1 = undefined;
	}
	
	ch = self.ch2;
	if (isDefined(ch))
	{
		ch["huds"][0] hud_destroy();
		ch["huds"][1] destroy();
		ch["huds"][2] destroy();
		self.ch2 = undefined;
	}

	self player_clear_last_stand();
}

/*
///DocStringBegin
detail: <Player> survivor_init_challenge(): <Void>
summary: Initializes two new random challenges for the player.
///DocStringEnd
*/
survivor_init_challenge()
{
	self.challenges = [];
	choices = array_random_choices(array_range(0, 15), 2, undefined, true);
	self _survivor_set_challenge(0, choices[0], 5);
	self _survivor_set_challenge(1, choices[1], 5);
}

/*
///DocStringBegin
detail: <Player> survivor_update_challenge(ch_index: <Int>): <Void>
summary: Updates a challenge's progress. If completed, it awards score and sets a new, harder goal.
///DocStringEnd
*/
survivor_update_challenge(ch_index)
{
	if (!isDefined(self.challenges) || !self.challenges.size) return;
	if (self.challenges[0]["ch"] == ch_index) index = 0;
	else if (self.challenges[1]["ch"] == ch_index) index = 1;
	else return;

	if (self.challenges[index]["step"] == self.challenges[index]["max_step"] - 1)
	{
		award = int(500 * (((self.challenges[index]["max_step"] - 5) / 2) + 1));

		notifyData = spawnStruct();
		notifyData.titleText = self.challenges[index]["label"] + " $ " + award;
		notifyData.glowColor = (1, 0.49, 0);
		notifyData.sound = "survival_bonus_splash";
		notifyData.foreground = true;
		notifyData.hidewheninmenu = true;

		self survivor_give_score(award);
		self hud_notify_message(notifyData);

		self.challenges[index]["step"] = 0;
		self.challenges[index]["max_step"] += 2;
		self setClientDvar("ui_ch_maxstep_" + index, self.challenges[index]["max_step"]);
	}
	else self.challenges[index]["step"]++;

	self setClientDvar("ui_ch_step_" + index, self.challenges[index]["step"]);
}

/*
///DocStringBegin
detail: <Player> _survivor_set_challenge(index: <Int>, ch_index: <Int>, steps: <Int>): <Void>
summary: Sets up a specific challenge's data and updates the corresponding UI DVars.
///DocStringEnd
*/
_survivor_set_challenge(index, ch_index, steps)
{
	ch = CHALLENGES;
	challenge = [];
	challenge["label"] = ch[ch_index];
	challenge["ch"] = ch_index;
	challenge["step"] = 0;
	challenge["max_step"] = steps;	
	self.challenges[index] = challenge;

	self setClientDvar("ui_ch_label_" + index, challenge["label"]);
	self setClientDvar("ui_ch_step_" + index, 0);
	self setClientDvar("ui_ch_maxstep_" + index, steps);
}

/*
///DocStringBegin
detail: get_ch_index_byWeapon(weapon: <String>): <Int>
summary: Gets the challenge index corresponding to a weapon's class (e.g., "Assault Rifle Kills").
///DocStringEnd
*/
get_ch_index_byWeapon(weapon)
{
	wepClass = weapon_get_class(weapon);
	if (wepClass == "machine_pistol") wepClass = "machine pistol";
	else if (wepClass == "projectile") wepClass = "launcher";
	return array_index(CHALLENGES, ::filter_starts_with, wepClass, true);
}

/*
///DocStringBegin
detail: <Player> survivor_init_summary(): <Void>
summary: Resets the player's end-of-wave summary stats.
///DocStringEnd
*/
survivor_init_summary()
{
	self.summary = [];
	self.summary["kills"] = 0;
	self.summary["headshots"] = 0;
	self.summary["accuracy"] = 0;
	self.summary["damagetaken"] = 0;
	self.summary["totalshots"] = 0;
	self.summary["hits"] = 0;
}

/*
///DocStringBegin
detail: <Player> survivor_display_summary(): <Void>
summary: Displays the end-of-wave summary screen, calculates bonus score, and initializes new challenges.
///DocStringEnd
*/
survivor_display_summary()
{
	time = int(int((gettime() - level.waveStartTime) / 1000) + "." + int(int((gettime() - level.waveStartTime) / 100) % 10));			
	self setClientDvar("ui_wave_time", time);
	self setClientDvar("ui_wave_time_bonus", int(level.score_base / time));
	self setClientDvar("ui_wave_kills", self.summary["kills"]);
	self setClientDvar("ui_wave_headshots", self.summary["headshots"]);
	self setClientDvar("ui_wave_accuracy", self.summary["accuracy"]);
	self setClientDvar("ui_wave_damagetaken", self.summary["damagetaken"]);			
	self survivor_display_hud("wave_summary");
	self survivor_give_score(int(level.score_base / time) + (level.wave_num * 30) + (self.summary["kills"] * 10) + (self.summary["headshots"] * 20) + (self.summary["accuracy"] * 3));
	self thread survivor_init_challenge();
}

/*
///DocStringBegin
detail: <Player> survivor_skip_hud_clear(): <Void>
summary: Clears the "skip" label HUD element.
///DocStringEnd
*/
survivor_skip_hud_clear()
{
	if (isDefined(self.skipLabel)) self.skipLabel destroy();
}

/*
///DocStringBegin
detail: <Player> survivor_wave_init(): <Void>
summary: Initializes wave settings, like clearing the skip HUD and resetting summary stats.
///DocStringEnd
*/
survivor_wave_init()
{
	self survivor_skip_hud_clear();
	self setClientDvar("ui_wave", level_get_wave());
	self survivor_init_summary();
}

/*
///DocStringBegin
detail: <Player> survivor_zoom_effect(): <Void>
summary: Plays a cinematic camera "zoom down" effect for the player, typically at the start of a match.
///DocStringEnd
*/
survivor_zoom_effect()
{
	self setClientDvar("hide_hud", true);
	self survivor_hud_notify_hide(true);
	self allowAds(0);
	self freezeControls(1);
	
	angles = self GetPlayerAngles();	
	camera = spawn("script_model", self.origin + (0, 0, 3000));
	camera setModel("c130_zoomrig");
	camera notSolid(0);
	camera hide();
	camera showToPlayer(self);
	camera.angles = (90, angles[1], 0);
	
	self cameraLinkTo(camera, "tag_origin");	
	self player_black_screen();	
	self playLocalSound("survival_slamzoom");
	
	camera moveTo(self.origin + (0, 0, 180), 1.5);
	
	wait 1.5;
	self visionSetNakedForPlayer("coup_sunblind", 0);
	self cameraUnlink();
	self visionSetNakedForPlayer("", 0.5);
	
	self allowAds(1);
	self freezeControls(0);
	self survivor_hud_notify_hide(false);
	self setClientDvar("hide_hud", false);
	
	camera delete();
}

/*
///DocStringBegin
detail: <Player> survivor_set_body_armor(armor: <Int>, damageAnim?: <Bool> = true): <Void>
summary: Sets the player's body armor value and updates the HUD, optionally playing a damage/hit animation.
///DocStringEnd
*/
survivor_set_body_armor(armor, damageAnim)
{
	if (!isDefined(damageAnim)) damageAnim = true;

	self.bodyArmor = armor;
	self setClientDvar("ui_body_armor", armor);

	if (damageAnim) self survivor_display_hud("armor_damage");
	else self survivor_display_hud("show_armor");
}

/*
///DocStringBegin
detail: <Player> survivor_give_body_armor(): <Void>
summary: Fills the player's body armor to the maximum value.
///DocStringEnd
*/
survivor_give_body_armor()
{
	self survivor_set_body_armor(get_max_armor(), false);
}

/*
///DocStringBegin
detail: <Player> survivor_take_body_armor(): <Void>
summary: Removes all body armor from the player.
///DocStringEnd
*/
survivor_take_body_armor()
{
	self.bodyArmor = 0;
	self setClientDvar("ui_body_armor", 0);
}

/*
///DocStringBegin
detail: <Player> survivor_give_last_stand(): <Void>
summary: Gives the player a self-revive charge and the final stand perk.
///DocStringEnd
*/
survivor_give_last_stand()
{
	self.hasRevive = true;
	self setClientDvar("ui_self_revive", 1);
	self player_give_perk("specialty_finalstand", false);
}

/*
///DocStringBegin
detail: <Player> survivor_take_last_stand(): <Void>
summary: Removes the player's self-revive.
///DocStringEnd
*/
survivor_take_last_stand()
{
	self.hasRevive = false;
	self setClientDvar("ui_self_revive", 0);
	self player_unset_Perk("specialty_finalstand");
}

/*
///DocStringBegin
detail: <Player> survivor_revive(): <Void>
summary: Revives the player from a downed or last stand state, restoring controls, health, and cleaning up the state.
///DocStringEnd
*/
survivor_revive()
{
	self notify("revive");
	if (self.removeLastStandWeapon) self player_take_weapon(self.lastStandWeapon);
	else self player_restore_ammo(self.lastStandWeapon, "onlaststand");
	
	self laststandrevive();
	self player_enable_usability();
	self player_enable_weapon_switch();
	self player_enable_offhand_weapons();

	waittillframeend;
	self survivor_switch_to_weapon(self.prevWeapon);

    if (self player_has_perk("specialty_finalstand") && !level.diehardmode)
        self player_unset_Perk("specialty_finalstand");

    if (level.diehardmode)
		self.headicon = "";

    self setstance("crouch");
    self.revived = true;
	self.inLastStand = false;
	self.lastStand = undefined;

    if (isdefined(self.standardmaxhealth))
        self.maxhealth = self.standardmaxhealth;
    self.health = self.maxhealth;

	if (game["state"] == "postgame")
        maps\mp\gametypes\_gamelogic::freezePlayerForRoundEnd();

	self player_clear_last_stand();
}

/*
///DocStringBegin
detail: <Player> survivor_switch_to_weapon(weapon: <String>): <Void>
summary: Switches the player's weapon and applies any associated weapon buffs.
///DocStringEnd
*/
survivor_switch_to_weapon(weapon)
{
	self switchToWeapon(weapon);
	self player_take_all_weapon_buffs();
	weaponData = self player_get_weapon_data(weapon);
	if (!isDefined(weaponData)) return;
	foreach(buff in weaponData[3]) self player_give_perk(buff, true);
}

/*
///DocStringBegin
detail: survivor_delete_state(): <Void>
summary: Deletes a player's saved state data from the global save state array.
///DocStringEnd
*/
survivor_delete_state()
{
	if (isDefined(level.saveState[self.guid])) 
		level.saveState = lethalbeats\array::array_remove_key(level.saveState, self.guid);
}

survivor_wait_skip()
{
	self survivor_display_hud("bind_skip_intermission");
	self notifyonplayercommand("skip_intermission", "skip");	
	self waittill("skip_intermission");
}

survivor_trigger_filter(survivor)
{
	return survivor player_is_survivor() && isAlive(survivor) && !survivor.inLastStand;
}

/*
///DocStringBegin
detail: <Player> survivor_load_state(): <Bool>
summary: Loads the player's saved state from a previous session, restoring score, weapons, perks, etc. Returns true on success.
///DocStringEnd
*/
survivor_load_state()
{
	if (!getDvarInt("survival_save_state") || !array_contains_key(level.saveState, self.guid) || !isDefined(level.saveState[self.guid])) return false;
	playerData = level.saveState[self.guid];

	self player_black_screen();

	self setOrigin(playerData["origin"]);
	self setPlayerAngles(playerData["angles"]);
	self setStance(playerData["stance"]);

	self.pers["kills"] = playerData["kills"];
	self.score = self.pers["kills"];

	self.pers["deaths"] = playerData["deaths"];
	self.score = self.pers["deaths"];

	self.pers["assists"] = playerData["assists"];
	self.score = self.pers["assists"];

	self survivor_set_score(playerData["score"]);
	self survivor_set_body_armor(playerData["armor"]);

	if (playerData["hasRevive"]) self survivor_give_last_stand();
	else
	{
		self.hasRevive = false;
		self setClientDvar("ui_self_revive", 0);
		self player_give_perk("specialty_finalstand", false);
	}

	self.prevWeapon = playerData["prevWeapon"];

	foreach(perk in playerData["perks"])
		self survivor_give_perk(perk);

	self player_clear_nades();
	foreach(grenade, ammount in playerData["grenades"])
	{
		if (ammount) self player_set_nades(grenade, ammount);
		if (grenade == "claymore_mp") self player_set_action_slot(1, "weapon", grenade);
		else if (grenade == "c4_mp") self player_set_action_slot(5, "weapon", grenade);
	}

	foreach(sentryId, turret in playerData["turrets"])
	{
		sentry = lethalbeats\survival\killstreaks\_sentry::spawnSentryAtLocation(turret["type"], turret["origin"], turret["angles"], self);
		level.sentry++;
	}

	if (string_starts_with(playerData["killstreak"], "airdrop_"))
		self lethalbeats\survival\killstreaks\_airdrop::giveAirDrop(string_slice(playerData["killstreak"], 8));
	else
		self maps\mp\killstreaks\_killstreaks::giveKillstreak(playerData["killstreak"]);

	self.restoreWeaponClipAmmo = playerData["ammo"]["clip"];
	self.restoreWeaponStockAmmo = playerData["ammo"]["stock"];

	self player_take_all_weapons();
	foreach(weaponData in playerData["weaponData"])
	{
		weapon = weaponData[0];
		self player_give_weapon(weapon);
		self player_set_weapon_data(weapon, weaponData);
		self player_restore_ammo(weapon, undefined, true);
		if (self.prevweapon != weapon) self survivor_switch_to_weapon(weapon);
	}

	level.saveState[self.guid] = undefined;

	return true;
}

survivor_enable_weapons()
{
	self player_enable_weapons();
	weapons = lethalbeats\player::player_get_weapons();
	if (weapons.size) self survivor_switch_to_weapon(weapons[0]);
}

//////////////////////////////////////////
//	             LEVEL   		        //
//////////////////////////////////////////

kill_all_survivors()
{
	foreach(player in survivors())
		player suicide();
}

level_vehicle_monitor()
{
    level endon("game_ended");

   	level.vehicleWaiting = [];

    for (;;)
    {
        wait 0.5;
        waittillframeend;

        if (!level.vehicleWaiting.size) continue;
		if (level_airspace_is_crowded()) continue;

		level.vehicleWaiting[0] notify("vehicle_release");
		level.vehicleWaiting = array_remove_index(level.vehicleWaiting, 0);
    }
}

level_get_wave()
{
	return level.wave_num ? level.wave_num : getDvarInt("survival_wave_start");
}

/*
///DocStringBegin
detail: level_save_state(): <Void>
summary: Saves the game state for all players, including stats, inventory, and location, then prints it as a JSON string.
///DocStringEnd
*/
level_save_state()
{
	setDvar("survival_save_state", 1);

	saveState = [];
	saveState["map"] = getDvar("mapname");
	saveState["wave"] = level.wave_num;

	for(i = 0; i < level.players.size; i++)
	{
		player = level.players[i];
		if (player isTestClient()) continue;
		playerData["origin"] = lethalbeats\vector::vector_truncate(player.origin, 3);
		playerData["angles"] = lethalbeats\vector::vector_truncate(player.angles, 3);
		playerData["stance"] = player getStance();
		playerData["kills"] = player.pers["kills"];
		playerData["deaths"] = player.pers["deaths"];
		playerData["assists"] = player.pers["assists"];
		playerData["score"] = player.pers["score"];
		playerData["armor"] = player.bodyArmor;
		playerData["hasRevive"] = player.hasRevive;
		playerData["prevWeapon"] = player.prevWeapon;
		playerData["perks"] = player.survivalPerks;
		playerData["grenades"] = player.grenades;
		playerData["turrets"] = player.turrets;
		playerData["killstreak"] = "";

		if (isDefined(player.pers["killstreaks"]) && isDefined(player.pers["killstreaks"][0]) && isDefined(player.pers["killstreaks"][0].streakname))
			playerData["killstreak"] = player.pers["killstreaks"][0].streakname;

		if (string_starts_with(playerData["killstreak"], "airdrop_"))
			playerData["killstreak"] = "airdrop_" + self.airdropType;

		playerData["weaponData"] = [];

		primary = player player_get_primary();
		if (isDefined(primary))
		{
			player player_save_ammo(primary);
			playerData["weaponData"]["primary"] = player player_get_weapon_data(primary);
		}

		secondary = player player_get_secondary();
		if (isDefined(secondary))
		{
			player player_save_ammo(secondary);
			playerData["weaponData"]["secondary"] = player player_get_weapon_data(secondary);
		}

		ammoInfo = [];
		ammoInfo["clip"] = player.restoreWeaponClipAmmo;
		ammoInfo["stock"] = player.restoreWeaponStockAmmo;
		playerData["ammo"] = ammoInfo;

		saveState[player.guid] = playerData;
	}
	print("SAVE_STATE", lethalbeats\json::json_serialize(saveState));
}

level_load_state()
{
	if (!getDvarInt("survival_save_state")) return;
	lethalbeats\survival\dev\savestate::init();
	if (level.saveState["map"] != getDvar("mapname"))
		cmdExec("map " + level.saveState["map"]);
}

/*
///DocStringBegin
detail: level_rotate_map(delay?: <Int> = 1): <Void>
summary: Rotates to a new random survival map from the available list after a short delay.
///DocStringEnd
*/
level_rotate_map(delay)
{
	if (!isDefined(delay)) delay = 1;
	maps = getArrayKeys(level.armories);
	maps = lethalbeats\array::array_filter(maps, lethalbeats\array::filter_not_equal, getDvar("mapname"));
	map = lethalbeats\array::array_random(maps);
	print("NextMap:", map);
	wait delay;
	setDvar("sv_maprotation", "dsr survival map " + map);
	cmdexec("load_dsr survival; wait; wait; start_map_rotate");
}

/*
///DocStringBegin
detail: <Entity> level_wait_vehicle_limit(stay?: <Bool>): <Void>
summary: Pauses execution until the number of active vehicles drops below the limit. Hides the entity during the wait.
///DocStringEnd
*/
level_wait_vehicle_limit(stay)
{
	self hide();
	if (!isDefined(stay)) self setOrigin(level.airDropCrateCollision.origin);
	level.vehicleWaiting[level.vehicleWaiting.size] = self;
	self waittill("vehicle_release");
}

level_airspace_is_crowded()
{
	limit = 4;
	if ((level.littlebirds.size >= limit || maps\mp\_utility::currentActiveVehicleCount() >= limit || level.fauxvehiclecount >= limit)) return true;
	if (isdefined(level.civilianjetflyby)) return true;
	return false;
}

level_bots_give_ammo()
{
	level endon("game_ended");
    self endon("disconnect");

    for (;;)
    {
		wait randomIntRange(5, 20);
		foreach(bot in bots(undefined, true))
		{
			if (bot bot_is_dog()) continue;
			weapon = bot getCurrentWeapon();
			weaponClass = weapon_get_class(weapon);
			if(isDefined(weapon) && weaponClass != "riot" && weaponClass != "grenade")
				bot player_give_max_ammo(weapon);
		}
    }
}

/*
///DocStringBegin
detail: <Vehicle> heli_modified_damage(damage: <Int>, attacker: <Entity>, weapon: <String>, meansOfDeath: <String>): <Int>
summary: A damage callback for helicopters. Modifies incoming damage based on the weapon type to balance combat.
///DocStringEnd
*/
heli_modified_damage(damage, attacker, weapon, meansOfDeath)
{
	if (isDefined(weapon))
	{
		littlebird = self.helitype == "littlebird" || self.helitype == "helicopter";
		switch (weapon)
		{
			case "rpg_mp":
			case "iw5_smaw_mp":
				return littlebird ? self.customHealth : self.maxHealth / 4;
			case "stinger_mp":
				return littlebird ? self.customHealth : self.maxHealth / 2;
			case "m320_mp":
			case "xm25_mp":
				return littlebird ? self.customHealth / 4 : self.maxHealth / 8;
			case "ac130_105mm_mp":
			case "ac130_40mm_mp":
			case "remotemissile_projectile_mp":
			case "remote_mortar_missile_mp":
			case "javelin_mp":
				self.largeprojectiledamage = 1;
				return self.maxhealth;
			case "sam_projectile_mp":
				self.largeprojectiledamage = 1;
				return littlebird ? self.customHealth * 0.09 : self.maxHealth / 0.07;
			case "emp_grenade_mp":
				self thread maps\mp\killstreaks\_helicopter::heli_empgrenaded();
				return self.maxHealth;
			case "osprey_player_minigun_mp":
				self.largeprojectiledamage = 0;
				return damage * 2;
		}
	}

	if (!isDefined(weapon) || !isDefined(attacker) || !isPlayer(attacker)) return damage;
	if (weapon_has_attach_gl(weapon)) return damage * 2;
	if (attacker maps\mp\_utility::_hasPerk("specialty_armorpiercing") || weapon_get_class(weapon) == "sniper") return damage * 2;
	return damage;
}

/*
///DocStringBegin
detail: <Entity> equipmen_modified_damage(damage: <Int>, attacker: <Entity>, weapon: <String>, meansOfDeath: <String>): <Int>
summary: A damage callback for equipment. Modifies incoming damage, making them immune to most damage but weak to explosives and melee.
///DocStringEnd
*/
equipmen_modified_damage(damage, attacker, weapon, meansOfDeath)
{
	if (!isDefined(attacker) || !isPlayer(attacker) || self.team == attacker.team) return 0;
	if (meansOfDeath == "MOD_MELEE") return self.maxHealth;
	if (isDefined(weapon))
	{
		weapon_class = weapon_get_class(weapon);
		if (weapon_class == "projectile" || weapon_has_attach_gl(weapon)) return self.maxHealth;
		if (attacker maps\mp\_utility::_hasPerk("specialty_armorpiercing") || weapon_class == "sniper") return damage * 2;

		switch (weapon)
		{
			case "ac130_105mm_mp":
			case "ac130_40mm_mp":
			case "remotemissile_projectile_mp":
			case "remote_mortar_missile_mp":
			case "artillery_mp":
			case "stealth_bomb_mp":
			case "emp_grenade_mp":
			case "bomb_site_mp":
				return self.maxHealth;
		}
	}
	return 0;
}

/*
///DocStringBegin
detail: is_shop_near(origin: <Vector3>, min_distance?: <Int> = 200): <Bool>
summary: Checks if a given location is within a certain distance of any armory/shop location on the current map.
///DocStringEnd
*/
is_shop_near(origin, min_distance)
{
	if (!isDefined(min_distance)) min_distance = 200;
	if (!isDefined(level.armories[getDvar("mapname")])) return false;
	armories = level.armories[getDvar("mapname")];
	foreach(armory in armories)
		if (distance(armory[1], origin) <= min_distance) return true;
	return false;
}

/*
///DocStringBegin
detail: get_max_armor(): <Int>
summary: Returns the maximum armor value, read from a DVar.
///DocStringEnd
*/
get_max_armor()
{
	return getDvarInt("survival_start_armor");
}

/*
///DocStringBegin
detail: get_default_loadout(): <Array>
summary: Returns a default loadout structure, used for players when they first join.
///DocStringEnd
*/
get_default_loadout()
{
	// temporal
	loadout[LOADOUT_PRIMARY] = "iw5_fnfiveseven";
	loadout[LOADOUT_PRIMARY_ATTACHMENT] = NONE;
	loadout[LOADOUT_PRIMARY_ATTACHMENT2] = NONE;
	loadout[LOADOUT_PRIMARY_BUFF] = SPECIALTY_NULL;
	loadout[LOADOUT_PRIMARY_CAMO] = NONE;
	loadout[LOADOUT_PRIMARY_RETICLE] = NONE;
	loadout[LOADOUT_SECONDARY] = NONE;
	loadout[LOADOUT_SECONDARY_ATTACHMENT] = NONE;
	loadout[LOADOUT_SECONDARY_ATTACHMENT2] = NONE;
	loadout[LOADOUT_SECONDARY_BUFF] = SPECIALTY_NULL;
	loadout[LOADOUT_SECONDARY_CAMO] = NONE;
	loadout[LOADOUT_SECONDARY_RETICLE] = NONE;
	loadout[LOADOUT_LETHAL] = FRAG;
	loadout[LOADOUT_TACTICAL] = FLASH;
	loadout[LOADOUT_PERK1] = SPECIALTY_NULL;
	loadout[LOADOUT_PERK2] = SPECIALTY_NULL;
	loadout[LOADOUT_PERK3] = SPECIALTY_NULL;
	loadout[LOADOUT_STREAK_TYPE] = SPECIALTY_NULL;
	loadout[LOADOUT_KILLSTREAK1] = NONE;
	loadout[LOADOUT_KILLSTREAK2] = NONE;
	loadout[LOADOUT_KILLSTREAK3] = NONE;
	loadout[LOADOUT_DEATHSTREAK] = SPECIALTY_NULL;
	loadout[LOADOUT_JUGGERNAUT] = false;
	return loadout;
}

/*
///DocStringBegin
detail: get_botsTypes(): <String[]>
summary: Return the types and amount of bots from the csv wave tables.
///DocStringEnd
*/
get_botsTypes()
{
	bots = [];
	totalCount = 0;
	wave_num = min(level.wave_num, WAVE_LOOP);
	scalePlayer = min(players_get_list("allies").size, 4);
	scaleFactor = int(max(1, scalePlayer / 1.5));
	scaleFactor = int(max(1, 4 / 1.5)); // dev test
	isWaveLoop = level.wave_num > WAVE_LOOP;

	for (i = 1; true; i++)
	{
		if (!(i % 2)) continue;

		botCount = tableLookup(WAVES_TABLE, 0, wave_num, i + 1);
		if (botCount == "") break;

		bot = tableLookup(WAVES_TABLE, 0, wave_num, i);
		bot = string_remove(bot, " ");
		botCount = int(int(botCount) * scaleFactor);
		totalCount += botCount;

		if (isWaveLoop)
		{
			if (!array_contains_key(bots, bot)) bots[bot] = 0;
			bots[bot] += botCount;
		}
		else for (j = 0; j < botCount; j++) bots[bots.size] = bot;
	}

	if (!isWaveLoop) return bots;

	foreach (type, count in bots)
		bots[type] = count / totalCount;

	newTotalCount = totalCount * lethalbeats\math::math_pow(1.05, level.wave_num - WAVE_LOOP) * scaleFactor;
	newBots = [];

	foreach (type, percent in bots)
	{
		newCount = ceil(newTotalCount * percent);
		for (j = 0; j < newCount; j++) newBots[newBots.size] = type;
	}

	//if (level.wave_num % 5 == 0)  newBots[newBots.size] = "emp";
	//else if (level.wave_num % 3 == 0)  newBots[newBots.size] = "counter_uav";

	return newBots;
}

/*
///DocStringBegin
detail: get_armory_unlock(wave_num: <Int>): <String | Undefined>
summary: Returns the name of the armory category that should be unlocked at a specific wave number.
///DocStringEnd
*/
get_armory_unlock(wave_num)
{
	// temporal
	if (wave_num == 2) return "weapon";
	else if (wave_num == 4) return "equipment";
	else if (wave_num == 6) return "airstrike";
	return undefined;
}

/*
///DocStringBegin
detail: get_intro_dialog(): <String>
summary: Checks the number of players and based on that returns an introduction sound dialog.
///DocStringEnd
*/
get_intro_dialog()
{
	return player_count("allies") == 1 ? "so_hq_mission_intro_sp" : "so_hq_mission_intro";
}

/*
///DocStringBegin
detail: get_intel_dialog(botTypes: <String[]>): <String>
summary: Checks the bots abilities and based on that returns an start wave sound dialog.
///DocStringEnd
*/
get_intel_dialog(botTypes)
{
	soundPrefix = "SO_HQ_enemy_intel_";
	abilities = BOTS_ABILITIES;
	abilities = array_to_dictionary(abilities, array_zeros(abilities.size));
	abilities[GENERIC] = 0;
	abilities[DOG_SPLODE] = 0;
	abilities[DOG_REG] = 0;

	dummy = spawnStruct();
	foreach(type in botTypes)
	{
		dummy.botType = type;
		if (dummy bot_is_dog())
		{
			if (dummy bot_is_explosive()) abilities[DOG_SPLODE]++;
			else abilities[DOG_REG]++;
		}
		else
		{
			bot_abilities = dummy bot_get_abilities();
			if (!bot_abilities.size) abilities[GENERIC]++;
			else foreach(ability in bot_abilities) abilities[ability]++;
		}
	}

	if (abilities[JUGGER] > 1) return soundPrefix + "boss_transport_many";
	if (abilities[JUGGER]) return soundPrefix + "boss_transport";
	if (abilities[CHOPPER] > 1) return soundPrefix + "chopper_many";
	if (abilities[CHOPPER]) return soundPrefix + CHOPPER;
	if (abilities[CHEMICAL]) return soundPrefix + CHEMICAL;
	if (abilities[DOG_SPLODE]) return soundPrefix + DOG_SPLODE;
	if (abilities[DOG_REG]) return soundPrefix + DOG_REG;
	return soundPrefix + GENERIC;
}

/*
///DocStringBegin
detail: get_music_from_dialog(sound_dialog: <String>): <String>
summary: Checks the bots abilities in sound dialog and returns bg music.
///DocStringEnd
*/
get_music_from_dialog(sound_dialog)
{
	if (isSubStr(sound_dialog, CHOPPER)) return "so_survival_boss_music_01";
	else if (isSubStr(sound_dialog, "boss")) return "so_survival_boss_music_02";
	else if (array_any_ent(bots(), ::_is_regular_bot)) return "so_survival_regular_music";
	return "so_survival_easy_music";
}

/*
///DocStringBegin
detail: _is_regular_bot(): <Bool>
summary: Internal function to check if a bot is of 'regular' difficulty based on its aim time.
///DocStringEnd
*/
_is_regular_bot()
{
	return self.pers["bots"]["skill"]["aim_time"] == 0.3;
}

/*
///DocStringBegin
detail: getPerkFromKsPerk(killstreak_perk: <String>): <String>
summary: Return a perk format from a killstreak perk format. `specialty_quickdraw_ks` -> `specialty_quickdraw`
///DocStringEnd
*/
getPerkFromKsPerk(killstreak_perk)
{
	return string_remove_suffix(killstreak_perk, "_ks");
}

/*
///DocStringBegin
detail: blank(arg1?: <Any>, arg2?: <Any>, arg3?: <Any>, arg4?: <Any>, arg5?: <Any>, arg6?: <Any>, arg7?: <Any>, arg8?: <Any>): <Void>
summary: By modifying the game logic, certain functions give errors, replace with blank. Now it has no errors. ٩(•̀ᴗ•́)۶
///DocStringEnd
*/
blank(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8) { }

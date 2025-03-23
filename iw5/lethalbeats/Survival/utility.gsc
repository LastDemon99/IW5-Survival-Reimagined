#include lethalbeats\array;
#include lethalbeats\hud;
#include lethalbeats\player;

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

#define BOTS_ABILITIES ["dog", "martyrdom", "chemical", "chopper", "jugger", "pavelow", "reaper", "tank", "airstrike", "predator", "counteruav", "emp", "ims", "sentry"]
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

player_has_nades(nade)
{
	return array_contains_key(self.grenades, nade);
}

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

player_clear_last_stand()
{	
	self player_unset_Perk("specialty_finalstand");

	if (isDefined(self.reviveEnt)) self.reviveEnt delete();
	if(isDefined(self.lastStandBar))
	{
		self.lastStandBar.overlay destroy();
		self.lastStandBar.icon destroy();
		self.lastStandBar hud_destroy_elem();
	}
	
	self.headicon = "";
	self.health = self.maxhealth;
	self.laststand = undefined;
	self.inFinalStand = false;
	self.barFrac = undefined;
	self.disabledUsability = 0;
	
	self maps\mp\_utility::clearlowermessage("last_stand");

	self enableusability();
	self enableWeaponSwitch();
	self enableOffhandWeapons();
	self enableWeaponPickup();
}

player_refill_nades()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");

	for (;;)
    {
		self waittill("grenade_fire", grenade, weaponName);

		if(!isDefined(grenade) || !self player_has_nades(weaponName) || !isAlive(self)) continue;
		if(self.grenades[weaponName])
		{
			self player_add_nades(weaponName, -1);
			if(weaponName == CLAYMORE && self.grenades[weaponName]) self switchToWeapon(weaponName);
		}

		if (self player_is_bot())
		{
			hasNade = false;
			foreach(nade, count in self.grenades)
				if (self.grenades[nade]) hasNade = true;
			if (!hasNade) break;
		}
	}
}

player_client_cmd(cmd)
{
	self setClientDvar("client_cmd", cmd);
	self openMenu("client_cmd");
}

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

player_new_weapon_data(weapon, buffs)
{
	return self lethalbeats\Survival\armories\weapons::newWeaponData(weapon, buffs);
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
	bots = isDefined(alives) ? player_get_list("axis", alives) : player_get_list("axis");
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

	if (self bot_is_jugger())
	{
		self thread maps\mp\killstreaks\_juggernaut::juggernautSounds();
		self setPerk("specialty_radarjuggernaut", true, false);
	}
	else self.isJuggernaut = false;
	
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
	
	bodyModel = self bot_get_loadout(BODY_MODEL);
	headModel = self bot_get_loadout(HEAD_MODEL);

	if (!array_contains_key(level.bots_weapons_data, self.botType))
	{
		level.bots_weapons_data[self.botType] = true;		
		loadout = self.pers[GAME_MODE_LOADOUT];

		if (loadout[LOADOUT_PRIMARY] != "none")
		{
			primaryWep = lethalbeats\weapon::weapon_build(loadout[LOADOUT_PRIMARY], [loadout[LOADOUT_PRIMARY_ATTACHMENT], loadout[LOADOUT_PRIMARY_ATTACHMENT2]]);
			primaryBuff = loadout[LOADOUT_PRIMARY_BUFF] == SPECIALTY_NULL ? [] : [loadout[LOADOUT_PRIMARY_BUFF]];
			level.bots_weapons_data[primaryWep] = self player_new_weapon_data(primaryWep, primaryBuff);
		}

		if (loadout[LOADOUT_SECONDARY] != "none")
		{
			secondaryWep = lethalbeats\weapon::weapon_build(loadout[LOADOUT_SECONDARY], [loadout[LOADOUT_SECONDARY_ATTACHMENT], loadout[LOADOUT_SECONDARY_ATTACHMENT2]]);
			secondaryBuff = loadout[LOADOUT_SECONDARY_BUFF] == SPECIALTY_NULL ? [] : [loadout[LOADOUT_SECONDARY_BUFF]];
			level.bots_weapons_data[secondaryWep] = self player_new_weapon_data(secondaryWep, secondaryBuff);
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

bot_get_loadout(column)
{
	return tableLookup(TABLE, 0, self.botType, column);
}

bot_set_difficulty()
{
	wave = sqrt(level.wave_num);

	self.pers["bots"]["skill"]["spawn_time"] = 0;
    self.pers["bots"]["skill"]["aim_time"] = _wave_scale(0.6, 0, 0.1, wave);
    self.pers["bots"]["skill"]["init_react_time"] = self.pers["bots"]["skill"]["aim_time"];
    self.pers["bots"]["skill"]["reaction_time"] = _wave_scale(2500, 0, 0.1, wave);
    self.pers["bots"]["skill"]["remember_time"] = _wave_scale(500, 7500, 1, wave);
    self.pers["bots"]["skill"]["no_trace_ads_time"] = _wave_scale(500, 2500, 0.2, wave);
    self.pers["bots"]["skill"]["no_trace_look_time"] = self.pers["bots"]["skill"]["no_trace_ads_time"];
    self.pers["bots"]["skill"]["fov"] = wave > 15 ? -1 : _wave_scale(0.7, 0, 0.2, wave);
    self.pers["bots"]["skill"]["dist_start"] = _wave_scale(1000, 10000, 0.5, wave);
    self.pers["bots"]["skill"]["dist_max"] =_wave_scale(1200, 15000, 0.8, wave);
    self.pers["bots"]["skill"]["help_dist"] = 3000;
    self.pers["bots"]["skill"]["semi_time"] = _wave_scale(0.9, 0.05, 0.3, wave);
    self.pers["bots"]["skill"]["shoot_after_time"] = _wave_scale(1, 0, 0.25, wave);
    self.pers["bots"]["skill"]["aim_offset_time"] = _wave_scale(1.8, 0, 0.25, wave);
    self.pers["bots"]["skill"]["aim_offset_amount"] = _wave_scale(4, 0, 0.25, wave);
    self.pers["bots"]["skill"]["bone_update_interval"] = _wave_scale(2.5, 0.25, 0.25, wave);
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

	if (self.pers[GAME_MODE_LOADOUT][LOADOUT_PRIMARY] == "rpg" || lethalbeats\weapon::weapon_get_class(self.pers[GAME_MODE_LOADOUT][LOADOUT_PRIMARY]) == "sniper")
	{
		self.pers["bots"]["skill"]["dist_max"] = 15000;
		self.pers["bots"]["skill"]["dist_start"] = 10000;
	}
}

_wave_scale(init_value, end_value, scale, wave)
{
	scale_factor = 1 + scale * wave;
	return init_value > end_value ? max(end_value, init_value / scale_factor) : min(end_value, init_value * scale_factor);
}

bot_lastStand_suicide(attacker) //this simple shit kept me busy for a long time, for some reason suicide gives a lot of errors when the bot is in the last stand, so we force damage and fixed it, suck it fucking shitty errors.
{
	self endon("death");	
	wait 4.5;
	self.health = 1;
	radiusDamage(self getTagOrigin("j_spine4"), 5, 10000, 10000, attacker);
	self player_clear_last_stand();
}

bot_clear_corpses()
{
	foreach(bot in bots())
	{
		if (isDefined(self.detonate)) continue;
		if (!isDefined(bot.body) || array_any_ent(survivors(), ::_canSeeCorpse, bot.body)) continue;
		bot.body delete();
	}
}

_canSeeCorpse(body)
{
	return body sightConeTrace(self getEye(), self) > 0.7;
}

bot_kill(attacker)
{
	if (!isDefined(level.botTest)) level.botTest = [];
	level.botTest[level.botTest.size] = self.botType;

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
	if (isPlayer(self)) self suicide();
	level.bots_deaths++;
	if (level.bots_deaths % 5 != 0) bot_clear_corpses();
	if(level.bots_total_count == level.bots_deaths) level notify("wave_end");
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
	if (isDefined(alives)) return player_get_list("allies", alives);
	return player_get_list("allies");
}

survivors_thread(function, alives)
{
	if (isDefined(alives)) array_ent_thread(survivors(alives), function);
	else array_ent_thread(survivors(), function);
}

survivors_call(function, alives)
{
	if (isDefined(alives)) array_ent_call(survivors(alives), function);
	else array_ent_call(survivors(), function);
}

survivor_set_score(score)
{
	self.pers["score"] = score;
	self.score = self.pers["score"];
	self setClientDvar("ui_money", self.pers["score"]);
}

survivor_give_score(score, type)
{
	if (!isDefined(type)) type = undefined;
	maps\mp\gametypes\_gamescore::giveplayerscore("survival", self, undefined, int(score), type);
}

survivor_clear_perks()
{
	foreach(perk in self.survivalPerks) self player_unset_Perk(perk);
	self.survivalPerks = [];
	self _survivor_update_perks();
}

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

survivor_hud_notify_hide(hide)
{
	self.notifyTitle.hideWhenInMenu = hide;
	self.notifyText.hideWhenInMenu = hide;
	self.notifyText2.hideWhenInMenu = hide;
	self.notifyIcon.hideWhenInMenu = hide;
	self.notifyOverlay.hideWhenInMenu = hide;
}

survivor_display_hud(hud)
{
	self setClientDvar("ui_display", hud);
	self OpenMenu("ui_display");
}

survivor_destroy_hud()
{
	if (isDefined(self.hintString)) 
	{
		self.hintString destroy();
		self.hintString = undefined;
	}
	
	self.onTrigger = undefined;
	
	self setClientDvar("ui_body_armor", 0);
	self setClientDvar("ui_self_revive", 0);
	self setClientDvar("ui_use_slot", NONE);
	self setClientDvar("client_cmd", "");	
	
	ch = self.ch1;
	if (isDefined(ch))
	{
		ch["huds"][0] hud_destroy_elem();
		ch["huds"][1] destroy();
		ch["huds"][2] destroy();
		self.ch1 = undefined;
	}
	
	ch = self.ch2;
	if (isDefined(ch))
	{
		ch["huds"][0] hud_destroy_elem();
		ch["huds"][1] destroy();
		ch["huds"][2] destroy();
		self.ch2 = undefined;
	}
}

survivor_init_challenge()
{
	choices = array_random_choices(array_range(0, 15), 2, undefined, true);
	self _survivor_set_challenge(0, choices[0], 5);
	self _survivor_set_challenge(1, choices[1], 5);
}

survivor_update_challenge(ch_index)
{
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
		self maps\mp\gametypes\_hud_message::notifyMessage(notifyData);

		self.challenges[index]["step"] = 0;
		self.challenges[index]["max_step"] += 2;
		self setClientDvar("ui_ch_maxstep_" + index, self.challenges[index]["max_step"]);
	}
	else self.challenges[index]["step"]++;

	self setClientDvar("ui_ch_step_" + index, self.challenges[index]["step"]);
}

_survivor_set_challenge(index, ch_index, steps)
{
	ch = CHALLENGES;
	challenge["label"] = ch[ch_index];
	challenge["ch"] = ch_index;
	challenge["step"] = 0;
	challenge["max_step"] = steps;	
	self.challenges[index] = challenge;

	self setClientDvar("ui_ch_label_" + index, challenge["label"]);
	self setClientDvar("ui_ch_step_" + index, 0);
	self setClientDvar("ui_ch_maxstep_" + index, steps);
}

get_ch_index_byWeapon(weapon)
{
	wepClass = lethalbeats\weapon::weapon_get_class(weapon);
	if (wepClass == "machine_pistol") wepClass = "machine pistol";
	else if (wepClass == "projectile") wepClass = "launcher";
	return array_index(CHALLENGES, ::filter_starts_with, wepClass, true);
}

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

survivor_skip_hud_clear()
{
	if (isDefined(self.skipLabel)) self.skipLabel destroy();
}

survivor_wave_init()
{
	self survivor_skip_hud_clear();
	self setClientDvar("ui_wave", level.wave_num);
	self survivor_init_summary();
}

survivor_zoom_effect()
{
	self setClientDvar("hide_hud", true);
	self survivor_hud_notify_hide(true);
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
	self survivor_hud_notify_hide(false);
	self setClientDvar("hide_hud", false);
	
	camera delete();
}

survivor_watch_last_stand()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
    self endon("revive");
	self.barFrac = 10;
	
    while (self.barFrac < 20)
    {
        self.lastStandBar maps\mp\gametypes\_hud_util::updateBar(self.barFrac / 20, 0);
		self.lastStandBar.bar.color = (1, self.barFrac / 20, 0);
		self.barFrac++;
        wait 1;
    }
	self survivor_last_stand_revive();
}

survivor_watch_last_stand_revive()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	self waittill("revive");
	self survivor_last_stand_revive();
}

survivor_watch_last_stand_death()
{
	level endon("game_ended");
	self endon("disconnect");
    self endon("revive");
	self waittill("death");
	self player_clear_last_stand();
	self.revived = false;
}

survivor_last_stand_revive()
{
	if (self.removeLastStandWep) self player_take_weapon("iw5_fnfiveseven_mp");
	self switchToWeaponImmediate(self.prevWeapon);
	self maps\mp\gametypes\_playerlogic::laststandrespawnplayer();
	self player_clear_last_stand();
}

survivor_set_body_armor(armor, damageAnim)
{
	if (!isDefined(damageAnim)) damageAnim = true;

	self.bodyArmor = armor;
	self setClientDvar("ui_body_armor", armor);

	if (damageAnim) self survivor_display_hud("armor_damage");
	else self survivor_display_hud("show_armor");
}

survivor_give_body_armor()
{
	self survivor_set_body_armor(get_max_armor(), false);
}

survivor_take_body_armor()
{
	self.bodyArmor = 0;
	self setClientDvar("ui_body_armor", 0);
}

survivor_give_last_stand()
{
	self.hasRevive = 1;
	self setClientDvar("ui_self_revive", 1);
}

//////////////////////////////////////////
//	             LEVEL   		        //
//////////////////////////////////////////

rotateMap()
{
	maps = getArrayKeys(level.shopZones);
	maps = lethalbeats\array::array_filter(maps, lethalbeats\array::filter_not_equal, getDvar("mapname"));
	map = lethalbeats\array::array_random(maps);
	print("NextMap:", map);
	wait 15;
	setDvar("sv_maprotation", "dsr survival map " + map);
	cmdexec("load_dsr survival; wait; wait; start_map_rotate");
}

waitVehicleLimit(stay)
{
	self hide();
	if (!isDefined(stay)) self setOrigin(level.airDropCrateCollision.origin);
	waittillframeend;
	while (maps\mp\_utility::currentActiveVehicleCount() >= 5)
		wait 1;
}

playerClone()
{
	body = spawn("script_model", self.origin);
	body.angles = (0, self.angles[1], 0);
	body setModel(self.model);

	head = spawn("script_model", self.origin);
	head setModel(self.headmodel);
	head linkto(body, "j_spine4", (0, 0, 0), (0, 0, 0));

	return body;
}

fakeGravity(gravity)
{
	if (!isDefined(gravity)) gravity = 800;
	groundTrace = bulletTrace(self.origin, self.origin + (0, 0, -10000), false, self);
	travelDistance = distance(self.origin, groundTrace["position"]);
	travelTime = travelDistance / gravity;

	if (groundTrace["position"][2] < self.origin[2])
		self moveTo(groundTrace["position"], travelTime);
}

get_max_armor()
{
	return getDvarInt("survival_start_armor");
}

/*
///DocStringBegin
detail: notify_message(notifyData: <Struct>): <Void>
summary: Sends a notify message to all players. The message must a struct where their properties are specified.
///DocStringEnd
*/
notify_message(notifyData) 
{
	array_ent_thread(survivors(), maps\mp\gametypes\_hud_message::notifyMessage, notifyData);
}

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
	scaleFactor = int(max(1, player_get_list("allies").size / 1.5));
	isWaveLoop = level.wave_num > WAVE_LOOP;

	for (i = 1; true; i++)
	{
		if (!(i % 2)) continue;

		botCount = tableLookup(WAVES_TABLE, 0, wave_num, i + 1);
		if (botCount == "") break;

		bot = tableLookup(WAVES_TABLE, 0, wave_num, i);
		bot = lethalbeats\string::string_remove(bot, " ");
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
	return lethalbeats\string::string_remove_suffix(killstreak_perk, "_ks");
}

/*
///DocStringBegin
detail: blank(arg1?: <Any>, arg2?: <Any>, arg3?: <Any>, arg4?: <Any>, arg5?: <Any>, arg6?: <Any>, arg7?: <Any>, arg8?: <Any>): <Void>
summary: By modifying the game logic, certain functions give errors, replace with blank. Now it has no errors. ٩(•̀ᴗ•́)۶
///DocStringEnd
*/
blank(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8) { }

/*
///DocStringBegin
detail: intsPack(array: <Int[]>): <String>
summary: Packs an array of up to three integer indices (each less than 100000) into a string.
///DocStringEnd
*/
intsPack(array)
{
	packed = "";
    foreach(num in array)
    {
		str_num = num + "";
		packed += lethalbeats\string::string_pad_left(str_num, 5 - str_num.size, "0");
    }
    return packed;
}

/*
///DocStringBegin
detail: intsUnpack(packed_ints: <String>, array_length: <Int>): <Int[]>
summary: Unpacks a string containing up to three numbers (each less than 100000) into an array.
///DocStringEnd
*/
intsUnpack(packed_ints, array_length)
{
	result = [];
    for (i = 0; i < array_length; i++)
    {
		chunk = lethalbeats\string::string_slice(packed_ints, i * 5, (i + 1) * 5);
		result[result.size] = int(chunk);
    }
    return result;
}

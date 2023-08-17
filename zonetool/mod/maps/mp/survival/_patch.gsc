#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\survival\_utility;
#include maps\mp\bots\_bot_utility;
#include maps\mp\bots\_bot_internal;
#include maps\mp\gametypes\_weapons;
#include maps\mp\gametypes\_hud_util;

init()
{
	setDvarIfUninitialized("survival_init", 0);
	
	if(!getDvarInt("survival_init"))
	{
		setDvar("survival_init", 1);
		cmdexec("map mp_dome");
	}
	
	if(!getDvarInt("survival_dev_mode") && getDvar("mapname") != "mp_dome")
		cmdexec("map mp_dome");
	
	patch_replacefun();
	player_patch_replacefunc();
	bots_patch_replacefunc();
	action_slots_replacefunc();
	
	level.onRespawnDelay = ::getRespawnDelay;
	level thread hook_callbacks();
}

//////////////////////////////////////////
//	Random Stuffs 				        //
//////////////////////////////////////////

patch_replacefun()
{
	replacefunc(maps\mp\gametypes\_hud_message::notifyMessage, ::notifyMessage);
	replacefunc(maps\mp\gametypes\_weapons::watchweaponusage, ::_watchweaponusage);
	replacefunc(maps\mp\gametypes\_missions::playerKilled, ::blank);
	replacefunc(maps\mp\bots\_bot_chat::bot_chat_death_watch, ::blank);
	replacefunc(maps\mp\gametypes\_quickmessages::init, ::blank);
	replacefunc(maps\mp\bots\_bot_chat::doquickmessage, ::blank);
	replacefunc(maps\mp\_utility::updateMainMenu, ::updateMainMenu);
	replacefunc(maps\mp\gametypes\_deathicons::adddeathicon, ::blank);
	replacefunc(maps\mp\_events::multiKill, ::multiKill);
	replacefunc(maps\mp\gametypes\_shellshock::init, ::_shellshock_init);
	replacefunc(maps\mp\gametypes\_shellshock::dirtEffect, ::blank);
	replacefunc(maps\mp\gametypes\_shellshock::bloodEffect, ::blank);
	replacefunc(maps\mp\gametypes\_playerlogic::initClientDvars, ::initClientDvars);
}

updateMainMenu()
{
	self setClientDvar("client_cmd", "");
	self setClientDvar("g_scriptMainMenu", "client_cmd");
}

notifyMessage(notifyData) //disabled team splash msg on start
{
	self endon ("death");
	self endon ("disconnect");
	
	if(isDefined(notifyData.iconName) && (notifyData.iconName == game["icons"]["axis"] || notifyData.iconName == game["icons"]["allies"])) return;
	
	if (!isDefined(notifyData.slot)) notifyData.slot = 0;
	
	slot = notifyData.slot;

	if (!isDefined(notifyData.type)) notifyData.type = "";
	
	if (!isDefined(self.doingSplash[slot]))
	{
		self thread maps\mp\gametypes\_hud_message::showNotifyMessage(notifyData);
		return;
	}	
	self.splashQueue[slot][self.splashQueue[slot].size] = notifyData;
}

_watchweaponusage(var_0) //removed lines with last stand error, now no errors :) 
{
    self endon("death");
    self endon("disconnect");
    self endon("faux_spawn");
    level endon("game_ended");

    for (;;)
    {
        self waittill("weapon_fired", var_1);
        self.hasdonecombat = 1;
		
        if (!isprimaryweapon(var_1) && !issidearm(var_1))
            continue;
		
        if (isdefined(self.hitsthismag[var_1]))
            thread updatemagshots(var_1);
		
        var_2 = maps\mp\gametypes\_persistence::statgetbuffered("totalShots") + 1;
        var_3 = maps\mp\gametypes\_persistence::statgetbuffered("hits");
        var_4 = clamp(float(var_3) / float(var_2), 0.0, 1.0) * 10000.0;
        maps\mp\gametypes\_persistence::statsetbuffered("totalShots", var_2);
        maps\mp\gametypes\_persistence::statsetbuffered("accuracy", int(var_4));
        maps\mp\gametypes\_persistence::statsetbuffered("misses", int(var_2 - var_3));
		
        var_5 = 1;
        setweaponstat(var_1, var_5, "shots");
        setweaponstat(var_1, self.hits, "hits");
        self.hits = 0;
    }
}

multiKill(killId, killCount) //check wave challenges [ double, triple, multi ]
{
	if (killCount == 2)
	{
		self thread maps\mp\gametypes\_rank::xpEventPopup(&"SPLASHES_DOUBLEKILL");		
		self maps\mp\killstreaks\_killstreaks::giveAdrenaline("double");
		self checkChallenge("double");
	}
	else if (killCount == 3)
	{
		self thread maps\mp\gametypes\_rank::xpEventPopup(&"SPLASHES_TRIPLEKILL");		
		self maps\mp\killstreaks\_killstreaks::giveAdrenaline("triple");
		thread teamPlayerCardSplash("callout_3xkill", self);
		self checkChallenge("triple");
	}
	else
	{
		self thread maps\mp\gametypes\_rank::xpEventPopup(&"SPLASHES_MULTIKILL");		
		self maps\mp\killstreaks\_killstreaks::giveAdrenaline("multi");
		thread teamPlayerCardSplash("callout_3xpluskill", self);
		self checkChallenge("multi");
	}
	
	self thread maps\mp\_matchdata::logMultiKill(killId, killCount);
	self setPlayerStatIfGreater("multikill", killCount);
	self incPlayerStat("mostmultikills", 1);
}

_shellshock_init() //removed dirt menu effect, gives bug with survival huds
{
    precacheshellshock("frag_grenade_mp");
    precacheshellshock("damage_mp");
    precacherumble("artillery_rumble");
    precacherumble("grenade_rumble");
}

initClientDvars()
{
	makeDvarServerInfo("cg_drawTalk", 1);
	makeDvarServerInfo("cg_drawCrosshair", 1);
	makeDvarServerInfo("cg_drawCrosshairNames", 0);
	makeDvarServerInfo("cg_hudGrenadeIconMaxRangeFrag", 250);

	setDvar("cg_drawCrosshairNames", 0);

	self setclientdvars("cg_drawSpectatorMessages", 1, "g_compassShowEnemies", getdvar("scr_game_forceuav"), "cg_scoreboardPingGraph", 1);
    maps\mp\gametypes\_playerlogic::initclientdvarssplitscreenspecific();

    if (getgametypenumlives()) self setclientdvars("cg_deadChatWithDead", 1, "cg_deadChatWithTeam", 0, "cg_deadHearTeamLiving", 0, "cg_deadHearAllLiving", 0);
    else self setclientdvars("cg_deadChatWithDead", 0, "cg_deadChatWithTeam", 1, "cg_deadHearTeamLiving", 1, "cg_deadHearAllLiving", 0);

    if (level.teambased) self setclientdvars("cg_everyonehearseveryone", 0);

    self setclientdvar("ui_altscene", 0);

    if (getdvarint("scr_hitloc_debug"))
    {
        for (var_0 = 0; var_0 < 6; var_0++)
            self setclientdvar("ui_hitloc_" + var_0, "");
        self.hitlocinited = 1;
    }
}

blank(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8) {} //some func give errors with certain modifications, replace with blank func... it has no errors >:)

//////////////////////////////////////////
//	Player 								//
//////////////////////////////////////////

player_patch_replacefunc()
{
	replacefunc(maps\mp\gametypes\_music_and_dialog::onPlayerSpawned, ::blank);
	replacefunc(maps\mp\gametypes\war::getSpawnPoint, ::getSpawnPoint);
	replacefunc(maps\mp\_utility::playDeathSound, ::_playDeathSound);
	replacefunc(maps\mp\_utility::waitForTimeOrNotify, ::_respawnDealy);
	replacefunc(maps\mp\gametypes\_spawnlogic::getallotherplayers, ::getSurvivorsAlive);
}

getSpawnPoint()
{	
	if(!isDefined(self.firstSpawn))
	{
		self.pers["gamemodeLoadout"] = level.survivalLoadout;
	
		self.pers["class"] = "gamemode";
		self.pers["lastClass"] = "";
		self.class = self.pers["class"];
		self.lastClass = self.pers["lastClass"];
		self.firstSpawn = 1;
	}
	
	team = isDefined(self.pers["isBot"]) ? "axis" : "allies";	
	maps\mp\gametypes\_menus::addToTeam(team, 1);
	
	if (!level.wave_num && team == "allies")
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray("mp_tdm_spawn_allies_start");
		return maps\mp\gametypes\_spawnlogic::getSpawnpoint_random(spawnPoints);
	}
	
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints(team);
	return maps\mp\gametypes\_spawnlogic::getSpawnpoint_nearTeam(spawnPoints);
}

hook_callbacks()
{
	level endon("game_ended");
	
	level waittill_any("wave_end", "callback_init");
	
	setDvar("ui_start_time", gettime());
		
	level.prevCallbackPlayerDamage = maps\mp\gametypes\_damage::Callback_PlayerDamage;
	level.callbackPlayerDamage = ::onPlayerDamage;
	
	level.prevCallbackPlayerKilled = maps\mp\gametypes\_damage::Callback_PlayerKilled;
	level.callbackPlayerKilled = ::onPlayerKilled;
	
	level.callbackPlayerLastStand = ::onPlayerLastStand;
}

onPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{	
	if(self is_bot())
	{	
		if(iDamage >= self.health && !isSubStr(self.botType, "dog_") && !contains(sMeansOfDeath, ["MOD_HEAD_SHOT", "MOD_MELEE", "MOD_EXPLOSIVE", "MOD_GRENADE", "MOD_GRENADE_SPLASH"]) && isDefined(vPoint) && distance(vPoint, self getTagOrigin("j_head")) < 10)
			self.headshotPatch = true;
		else 
			self.headshotPatch = false;
		
		if (self.headshotPatch) sMeansOfDeath = "MOD_HEAD_SHOT"; //simple fix head shoot return torso_upper hitloc, model port bug maybe... if i don't forget, i will check it... maybe
			
		if (isDefined(eAttacker) && eAttacker is_survivor()) eAttacker maps\mp\survival\_survivors::onPlayerBotDamage(self, iDamage, sMeansOfDeath, sWeapon);
		self maps\mp\survival\_bots::onBotDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
		return;
	}
	else if (isPlayer(self))
	{
		if (isDefined(eAttacker) && eAttacker is_bot()) eAttacker maps\mp\survival\_bots::onBotPlayerDamage(self, iDamage, sMeansOfDeath, sWeapon);
		self maps\mp\survival\_survivors::onPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
		return;
	}
	
	self [[level.prevCallbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
}

onPlayerKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	if(self is_bot())
	{
		if(eAttacker is_survivor()) eAttacker maps\mp\survival\_survivors::onPlayerBotKilled(self, iDamage, sMeansOfDeath, sWeapon);		
		self maps\mp\survival\_bots::onBotKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
		return;
	}
	else if (isPlayer(self))
	{
		self maps\mp\survival\_survivors::onPlayerKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
		return;
	}
	
	self [[level.prevCallbackPlayerKilled]](eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
}

onPlayerLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if(self isTestClient()) self maps\mp\survival\_bots::onBotLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
	else self maps\mp\survival\_survivors::onPlayerLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
}

_respawnDealy(time, notifyname)
{
	if(self.team == "allies") self maps\mp\survival\_survivors::onPlayerDeath();
	else self maps\mp\survival\_bots::respawnDealy();
}

getRespawnDelay() { return 3; }

_playDeathSound()
{
	if (!level.wave_num) return;
	if (isDefined(self.botType))
	{
		if (self.botType == "chopper") return;
		if (self.botType == "dog_splode" || self.botType == "dog_reg")
		{
			self PlaySound("anml_dog_neckbreak_pain");
			return;
		}
	}
	self playSound((self.team == "axis" ? "generic_death_russian_" : "generic_death_american_") + randomIntRange(1, 8));
}

//////////////////////////////////////////
//	Bots [ Death - Respawn - Dog Jump ] //
//////////////////////////////////////////

bots_patch_replacefunc()
{
	replacefunc(maps\mp\bots\_bot::add_bot, maps\mp\survival\_bots::addBot);
	replacefunc(maps\mp\bots\_bot_internal::doBotMovement_loop, ::_doBotMovement_loop);
	replacefunc(maps\mp\bots\_bot_internal::jump, ::_jump);
}

_doBotMovement_loop(data) //define surfaceInFront to _jump()
{
	if (isDefined(self.remoteUAV))
		self.bot.moveOrigin = self.remoteUAV.origin - (0, 0, 50);
	else if (isDefined(self.remoteTank))
		self.bot.moveOrigin = self.remoteTank.origin;
	else
		self.bot.moveOrigin = self.origin;

	waittillframeend;
	move_To = self.bot.moveTo;
	angles = self GetPlayerAngles();
	dir = (0, 0, 0);

	if (DistanceSquared(self.bot.moveOrigin, move_To) >= 49)
	{
		cosa = cos(0 - angles[1]);
		sina = sin(0 - angles[1]);

		// get the direction
		dir = move_To - self.bot.moveOrigin;

		// rotate our direction according to our angles
		dir = (dir[0] * cosa - dir[1] * sina,
		        dir[0] * sina + dir[1] * cosa,
		        0);

		// make the length 127
		dir = VectorNormalize(dir) * 127;

		// invert the second component as the engine requires this
		dir = (dir[0], 0 - dir[1], 0);
	}

	// climb through windows
	if (self isMantling())
	{
		data.wasMantling = true;
		self crouch();
	}
	else if (data.wasMantling)
	{
		data.wasMantling = false;
		self stand();
	}

	startPos = self.origin + (0, 0, 50);
	startPosForward = startPos + anglesToForward((0, angles[1], 0)) * 25;
	bt = bulletTrace(startPos, startPosForward, false, self);

	if (bt["fraction"] >= 1)
	{
		// check if need to jump
		bt = bulletTrace(startPosForward, startPosForward - (0, 0, 40), false, self);

		if (bt["fraction"] < 1 && bt["normal"][2] > 0.9 && data.i > 1.5 && !self isOnLadder())
		{
			data.i = 0;
			self thread jump(1);
		}
	}
	// check if need to knife glass
	else if (bt["surfacetype"] == "glass")
	{
		if (data.i > 1.5)
		{
			data.i = 0;
			self thread knife();
		}
	}
	else
	{
		// check if need to crouch
		if (bulletTracePassed(startPos - (0, 0, 25), startPosForward - (0, 0, 25), false, self) && !self.bot.climbing)
			self crouch();
	}

	// move!
	if (self.bot.wantsprint && self.bot.issprinting)
		dir = (127, dir[1], 0);

	self botMovement(int(dir[0]), int(dir[1]));

	if (isDefined(self.remoteUAV))
	{
		if (abs(move_To[2] - self.bot.moveOrigin[2]) > 12)
		{
			if (move_To[2] > self.bot.moveOrigin[2])
				self thread gostand();
			else
				self thread sprint();
		}
	}
}

_jump(surfaceInFront) //dog jump anim move the origin, real jump if has surface in front
{
	self endon("death");
	self endon("disconnect");
	self notify("bot_jump");
	self endon("bot_jump");

	if (self IsUsingRemote())
		return;

	if (self getStance() != "stand")
	{
		self stand();
		wait 1;
	}
	
	if (isSubStr(self.botType, "dog_")) 
	{	
		if(isdefined(surfaceInFront))
		{
			self botAction("+gostand");
			wait 0.05;
			self botAction("-gostand");
		}
		else self _setDogAnim("german_shepherd_run_jump_40", 0.65);
	}
	else
	{
		self botAction("+gostand");
		wait 0.05;
		self botAction("-gostand");
	}
}

//////////////////////////////////////////////////////
//	Action slots [ claymore - c4 - throwingknife ]	//
//////////////////////////////////////////////////////

action_slots_replacefunc()
{
	replacefunc(maps\mp\_utility::iskillstreakweapon, ::_iskillstreakweapon);
	replacefunc(maps\mp\gametypes\_weapons::equipmentWatchUse, ::_equipmentWatchUse);
}

_iskillstreakweapon(weapon) //return true for grenades, killstreak weapon alllows action slot
{
    if (!isdefined(weapon)) return 0;
    if (weapon == "none") return 0;
	
	if (weapon == "claymore_mp" || weapon == "c4_mp" || weapon == "throwingknife_mp" || weapon == "trophy_mp") return 1;

    tokens = strtok(weapon, "_");
    foundSuffix = 0;

    if (weapon != "destructible_car" && weapon != "barrel_mp")
    {
        foreach (token in tokens)
			if (token == "mp")
            {
                foundSuffix = 1;
                break;
            }

        if (!foundSuffix) weapon += "_mp";
    }

    if (issubstr(weapon, "destructible")) return 0;
    if (issubstr(weapon, "killstreak")) return 1;
    if (maps\mp\killstreaks\_airdrop::isairdropmarker(weapon)) return 1;
    if (isdefined(level.killstreakweildweapons[weapon])) return 1;
    if (isdefined(weaponinventorytype(weapon)) && weaponinventorytype(weapon) == "exclusive" && (weapon != "destructible_car" && weapon != "barrel_mp")) return 1;
    return 0;
}

_equipmentWatchUse(owner) //on pickup grenades updated self var & action slot
{
	self endon("spawned_player");
	self endon("disconnect");
	
	self.trigger setCursorHint("HINT_NOICON");
	
	if (self.weaponname == "c4_mp") self.trigger setHintString(&"MP_PICKUP_C4");
	else if (self.weaponname == "claymore_mp") self.trigger setHintString(&"MP_PICKUP_CLAYMORE");
	else if (self.weaponname == "bouncingbetty_mp") self.trigger setHintString(&"MP_PICKUP_BOUNCING_BETTY");
	
	self.trigger setSelfUsable(owner);
	self.trigger thread notUsableForJoiningPlayers(self);

	for (;;)
	{
		self.trigger waittill ("trigger", owner);
		
		if(owner isTestClient()) owner SetWeaponAmmoStock(self.weaponname, owner GetWeaponAmmoStock(self.weaponname) + 1);
		else
		{
			owner addNades(self.weaponname, 1);
			if(!(owner hasWeapon(self.weaponname)))
			{
				owner giveweapon(self.weaponname);
				if (self.weaponname == "claymore_mp") owner _setActionSlot(1, "weapon", self.weaponname);
				else owner _setActionSlot(5, "weapon", self.weaponname);
			}
		}
		
		owner playLocalSound("scavenger_pack_pickup");

		self.trigger delete();
		self delete();
		self notify("death");
	}
}

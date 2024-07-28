#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\survival\_utility;
#include maps\mp\bots\_bot_utility;
#include maps\mp\bots\_bot_internal;
#include maps\mp\bots\_bot_script;
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
	scorePopUpReplacefunc();
	
	level.onRespawnDelay = ::getRespawnDelay;
	level thread hook_callbacks();
}

//////////////////////////////////////////
//	Random Stuffs 				        //
//////////////////////////////////////////

patch_replacefun()
{
	replacefunc(maps\mp\gametypes\_menus::init, ::blank);
	replacefunc(maps\mp\gametypes\_hud_message::init, ::initHudMessage);
	replacefunc(maps\mp\gametypes\_hud_message::notifyMessage, ::notifyMessage);
	replacefunc(maps\mp\gametypes\_weapons::watchweaponusage, ::_watchweaponusage);
	replacefunc(maps\mp\gametypes\_missions::playerKilled, ::blank);
	replacefunc(maps\mp\gametypes\_quickmessages::init, ::blank);
	replacefunc(maps\mp\bots\_bot_chat::bot_chat_death_watch, ::blank);
	replacefunc(maps\mp\bots\_bot_chat::doquickmessage, ::blank);
	replacefunc(maps\mp\gametypes\_deathicons::adddeathicon, ::blank);
	replacefunc(maps\mp\_events::multiKill, ::multiKill);
	replacefunc(maps\mp\gametypes\_playerlogic::initClientDvars, ::initClientDvars);
	replacefunc(maps\mp\killstreaks\_remotemissile::missileEyes, maps\mp\killstreaks\_aamissile::missileEyes);
	replacefunc(maps\mp\gametypes\_damage::playerkilled_internal, maps\mp\survival\_damage::playerkilled_internal);
	replacefunc(maps\mp\gametypes\_damage::handlenormaldeath, maps\mp\survival\_damage::handlenormaldeath);
	replacefunc(maps\mp\gametypes\_damage::callback_playerlaststand, maps\mp\survival\_damage::callback_playerlaststand);
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

initHudMessage() // removed unnecessary menus precache
{
	precacheString( &"MP_FIRSTPLACE_NAME" );
	precacheString( &"MP_SECONDPLACE_NAME" );
	precacheString( &"MP_THIRDPLACE_NAME" );
	precacheString( &"MP_MATCH_BONUS_IS" );

    precachemenu( "perk_display" );
    precachemenu( "perk_hide" );
    precachemenu( "killedby_card_hide" );

	game["menu_endgameupdate"] = "endgameupdate";
	precacheMenu(game["menu_endgameupdate"]);

	game["strings"]["draw"] = &"MP_DRAW";
	game["strings"]["round_draw"] = &"MP_ROUND_DRAW";
	game["strings"]["round_win"] = &"MP_ROUND_WIN";
	game["strings"]["round_loss"] = &"MP_ROUND_LOSS";
	game["strings"]["victory"] = &"MP_VICTORY";
	game["strings"]["defeat"] = &"MP_DEFEAT";
	game["strings"]["halftime"] = &"MP_HALFTIME";
	game["strings"]["overtime"] = &"MP_OVERTIME";
	game["strings"]["roundend"] = &"MP_ROUNDEND";
	game["strings"]["intermission"] = &"MP_INTERMISSION";
	game["strings"]["side_switch"] = &"MP_SWITCHING_SIDES";
	game["strings"]["match_bonus"] = &"MP_MATCH_BONUS_IS";
	
	level thread maps\mp\gametypes\_hud_message::onPlayerConnect();
}

blank(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8) {} //some func give errors with certain modifications, replace with blank func... it has no errors >:)

//////////////////////////////////////////
//	Player 								//
//////////////////////////////////////////

player_patch_replacefunc()
{
	replacefunc(maps\mp\gametypes\_music_and_dialog::onPlayerSpawned, ::blank);
	replacefunc(maps\mp\_utility::playDeathSound, ::_playDeathSound);
	replacefunc(maps\mp\_utility::waitForTimeOrNotify, ::_respawnDealy);
	replacefunc(maps\mp\gametypes\_spawnlogic::getallotherplayers, ::getSurvivorsAlive);
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
	replacefunc(maps\mp\bots\_bot_internal::crouch, ::_crouch);
	replacefunc(maps\mp\bots\_bot_internal::prone, ::_prone);
	replacefunc(maps\mp\bots\_bot_internal::jump, ::_jump);
	replacefunc(maps\mp\bots\_bot_internal::doBotMovement_loop, ::_doBotMovement_loop);
	replacefunc(maps\mp\bots\_bot_script::start_bot_threads, ::_start_bot_threads);
}

_crouch()
{
	if (self isusingremote() || self is_dog())
		return;
	
	self BotBuiltinBotAction( "+gocrouch" );
	self BotBuiltinBotAction( "-goprone" );
}

_prone()
{
	if (self isusingremote() || self is_dog())
		return;
	
	self BotBuiltinBotAction( "-gocrouch" );
	self BotBuiltinBotAction( "+goprone" );
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
	
	if (self is_dog() && !isDefined(surfaceInFront))
	{
		self thread _setDogAnim("german_shepherd_run_jump_40", 0.65);
		return;
	}

	self botAction("+gostand");
	wait 0.05;
	self botAction("-gostand");
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

	if (self is_dog()) self.dogModel.angles = (0, dir[1], 0);
}

_start_bot_threads()
{
	self endon("disconnect");
	level endon("game_ended");
	self endon("death");
	
	gameflagwait("prematch_done");
	
	self thread bot_weapon_think();
	self thread doReloadCancel();
	
	// script targeting
	if (getdvarint("bots_play_target_other") && !(self is_dog()))
	{
		self thread bot_target_vehicle();
		self thread bot_equipment_kill_think();
	}
	
	// awareness
	self thread bot_uav_think();
	self thread bot_listen_to_steps();
	self thread follow_target();
	
	// camp and follow
	if (getdvarint("bots_play_camp") && !(self is_dog()))
	{
		self thread bot_think_follow();
		self thread bot_think_camp();
	}
	
	// nades
	if (getdvarint("bots_play_nade") && !(self is_dog()))
	{
		self thread bot_jav_loc_think();
		self thread bot_use_tube_think();
		self thread bot_use_grenade_think();
		self thread bot_use_equipment_think();
		self thread bot_watch_riot_weapons();
		self thread bot_watch_think_mw2(); // bots play mw2
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
	
	self.trigger delete();
	
	hintString = "";	
	if (self.weaponname == "c4_mp") hintString = &"MP_PICKUP_C4";
	else if (self.weaponname == "claymore_mp") hintString = &"MP_PICKUP_CLAYMORE";
	else if (self.weaponname == "bouncingbetty_mp") hintString = &"MP_PICKUP_BOUNCING_BETTY";
	
	trigger = maps\mp\lethalbeats\_trigger::createTrigger("equipment", self.origin, 0, 32, 32, hintString, owner);
	self thread equipmentPickupHandle(trigger);
	self thread onEquipmentDeath(trigger);
}

equipmentPickupHandle(trigger)
{
	for (;;)
	{
		trigger waittill("trigger_use", owner);
		
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
		self delete();
		self notify("death");
	}
}

onEquipmentDeath(trigger)
{
	self waittill("death");
	trigger notify("delete");
}

//////////////////////////////////////////////////////
//	Money menu hud									//
//////////////////////////////////////////////////////

scorePopUpReplacefunc()
{
	replacefunc(maps\mp\gametypes\_gamescore::giveplayerscore, ::giveplayerscore); // giveplayerscore set cdvar old_money for money animation
	replacefunc(maps\mp\gametypes\_rank::xpeventpopupfinalize, ::xpeventpopupfinalize); // money animation moveOverTime left_down
	replacefunc(maps\mp\gametypes\_rank::xppointspopup, ::xppointspopup); // money animation moveOverTime left_down
}

giveplayerscore(type, player, victim, custom_amount, var_4)
{
	if (type != "survival") return;

	score = player.pers["score"];
	player setClientDvar("ui_old_money", score);
    player.pers["score"] += custom_amount;
	player.score = player.pers["score"];

	player thread maps\mp\gametypes\_rank::xppointspopup(custom_amount, 0, undefined, 0);
    player maps\mp\gametypes\_persistence::statadd("score", custom_amount);
    player maps\mp\gametypes\_persistence::statsetchild("round", "score", player.score);
}

xpeventpopupfinalize(event, hudColor, glowAlpha)
{
    self endon("disconnect");
    self endon("joined_team");
    self endon("joined_spectators");
    self notify("xpEventPopup");
    self endon("xpEventPopup");

    if (level.hardcoremode) return;

    wait 0.05;

	self.hud_xpEventPopup.x = 55;
	self.hud_xpEventPopup.y = -35;
	
    self.hud_xpeventpopup.color = (0.7, 1, 0.7);
    self.hud_xpeventpopup.glowcolor = (0.7, 1, 0.7);
    self.hud_xpeventpopup.glowalpha = 0;
    self.hud_xpeventpopup settext(event);
    self.hud_xpeventpopup.alpha = 0.85;
    wait 1.0;

    if (!isdefined(self)) return;

	self.hud_xpeventpopup moveOverTime(0.5);
	score_str = "" + self.pers["score"];
	self.hud_xpeventpopup.x -= 400 - score_str.size * 20;
	self.hud_xpeventpopup.y += 270;
	
    self.hud_xpeventpopup fadeovertime(0.45);
	self.hud_xpeventpopup.alpha = 0;
    
	self notify("PopComplete");
}

xppointspopup(amount, bonus, hudColor, glowAlpha)
{
	self thread xppointspopupfinalize(amount, bonus, hudColor, glowAlpha);
    self thread xppointspopupterminate();
}

xppointspopupfinalize(amount, bonus, hudColor, glowAlpha)
{
    self endon("disconnect");
    self endon("joined_team");
    self endon("joined_spectators");

    if (amount == 0) return;
    if (!isdefined(self)) return;
	
	self.hud_xpPointsPopup.x = 30;
	self.hud_xpPointsPopup.y = -50;

    self notify("xpPointsPopup");
    self endon("xpPointsPopup");
    self.xpupdatetotal += amount;
    self.bonusupdatetotal += bonus;
    wait 0.05;

    if (self.xpupdatetotal < 0) self.hud_xppointspopup.label = &"";
    else self.hud_xppointspopup.label = &"MP_PLUS";

    self.hud_xppointspopup.color = (0.7, 1, 0.7);
    self.hud_xppointspopup.glowcolor = (0.7, 1, 0.7);
    self.hud_xppointspopup.glowalpha = 0;
    self.hud_xppointspopup setvalue(self.xpupdatetotal);
    self.hud_xppointspopup.alpha = 0.85;
    self.hud_xppointspopup thread maps\mp\gametypes\_hud::fontpulse(self);
    
	increment = max(int(self.bonusupdatetotal / 20), 1);

    if (self.bonusupdatetotal)
    {
        while (self.bonusupdatetotal > 0)
        {
            self.xpupdatetotal += min(self.bonusupdatetotal, increment);
            self.bonusupdatetotal -= min(self.bonusupdatetotal, increment);
            self.hud_xppointspopup setvalue(self.xpupdatetotal);
            wait 0.05;
        }
    }
    else wait 1.0;

	self.hud_xpPointsPopup moveOverTime(0.5);
	score_str = "" + self.pers["score"];
	self.hud_xpPointsPopup.x -= 400 - score_str.size * 20;
	self.hud_xpPointsPopup.y += 275;
    self.xpupdatetotal = 0;
	
	wait 0.75;
	self.hud_xppointspopup fadeovertime(0.75);
    self.hud_xppointspopup.alpha = 0;
	self setClientDvar("ui_money", self.pers["score"]);
	self hudDisplay("animate_money");
	
	self notify("ScorePopComplete");
}

xppointspopupterminate()
{
    self endon("ScorePopComplete");
    common_scripts\utility::waittill_any("joined_team", "joined_spectators");
    self.hud_xppointspopup fadeovertime(0.05);
    self.hud_xppointspopup.alpha = 0;
}

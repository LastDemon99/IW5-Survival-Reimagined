#include common_scripts\utility;
#include maps\mp\_utility;
#include lethalbeats\survival\_utility;
#include maps\mp\gametypes\_weapons;
#include maps\mp\gametypes\_hud_util;

//////////////////////////////////////////
//	Random Stuffs 				        //
//////////////////////////////////////////

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

blank(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8) {} //some func give errors with certain modifications, replace with blank func... it has no errors >:)

//////////////////////////////////////////
//	Player 								//
//////////////////////////////////////////

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
			
		if (isDefined(eAttacker) && eAttacker is_survivor()) eAttacker lethalbeats\survival\_survivors::onPlayerBotDamage(self, iDamage, sMeansOfDeath, sWeapon);
		self lethalbeats\survival\_bots::onBotDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
		return;
	}
	else if (isPlayer(self))
	{
		if (isDefined(eAttacker) && eAttacker is_bot()) eAttacker lethalbeats\survival\_bots::onBotPlayerDamage(self, iDamage, sMeansOfDeath, sWeapon);
		self lethalbeats\survival\_survivors::onPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
		return;
	}
	
	self [[level.prevCallbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
}

onPlayerKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	if(self is_bot())
	{
		if(eAttacker is_survivor()) eAttacker lethalbeats\survival\_survivors::onPlayerBotKilled(self, iDamage, sMeansOfDeath, sWeapon);		
		self lethalbeats\survival\_bots::onBotKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
		return;
	}
	else if (isPlayer(self))
	{
		self lethalbeats\survival\_survivors::onPlayerKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
		return;
	}
	
	self [[level.prevCallbackPlayerKilled]](eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
}

onPlayerLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if(self isTestClient()) self lethalbeats\survival\_bots::onBotLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
	else self lethalbeats\survival\_survivors::onPlayerLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
}

_respawnDealy(time, notifyname)
{
	if(self.team == "allies") self lethalbeats\survival\_survivors::onPlayerDeath();
	else self lethalbeats\survival\_bots::respawnDealy();
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

//////////////////////////////////////////////////////
//	Action slots [ claymore - c4 - throwingknife ]	//
//////////////////////////////////////////////////////

_iskillstreakweapon(weapon) //return true for grenades, killstreak weapon alllows action slot
{
    if (!isdefined(weapon)) return 0;
    if (weapon == "none") return 0;
	
	if (weapon == "claymore_mp" || weapon == "c4_mp" || weapon == "throwingknife_mp") return 1;

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

_equipmentWatchUse(owner) // on pickup grenades updated self var & action slot
{
	self endon("spawned_player");
	self endon("disconnect");
	
	self.trigger setCursorHint("HINT_NOICON");
	
	if (self.weaponname == "c4_mp")
		self.trigger setHintString(&"MP_PICKUP_C4");
	else if (self.weaponname == "claymore_mp")
		self.trigger setHintString(&"MP_PICKUP_CLAYMORE");
	else if (self.weaponname == "bouncingbetty_mp")
		self.trigger setHintString(&"MP_PICKUP_BOUNCING_BETTY");
	
	self.trigger setSelfUsable(owner);
	self.trigger thread notUsableForJoiningPlayers(self);

	for (;;)
	{
		self.trigger waittill ("trigger", owner);
		
		owner playLocalSound("scavenger_pack_pickup");
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

		self.trigger delete();
		self delete();
		self notify("death");
	}
}

//////////////////////////////////////////////////////
//	Money menu hud									//
//////////////////////////////////////////////////////

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

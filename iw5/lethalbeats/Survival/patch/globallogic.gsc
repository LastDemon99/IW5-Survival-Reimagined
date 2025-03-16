#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_weapons;
#include maps\mp\gametypes\_hud_util;
#include lethalbeats\survival\utility;
#include maps\mp\bots\_bot_internal;
#include maps\mp\bots\_bot_utility;

#define INSTAKILL ["MOD_HEAD_SHOT", "MOD_MELEE", "MOD_EXPLOSIVE", "MOD_GRENADE", "MOD_GRENADE_SPLASH"]

#define CLAYMORE "claymore_mp"
#define C4 "c4_mp"
#define THROWING_KNIFE "throwingknife_mp"

#define CH_DOUBLE 12
#define CH_TRIPLE 13
#define CH_MULTI 14

init()
{
	// UI
	replacefunc(maps\mp\gametypes\_menus::init, ::menuInit); // remove unnecessary menus & set armories trigger menu handle
    replacefunc(maps\mp\gametypes\_hud_message::init,  ::initHudMessage); // remove unnecessary menus
    replacefunc(maps\mp\gametypes\_hud_message::notifyMessage, ::patch_notifyMessage); // disable team splash welcome msg
    replacefunc(maps\mp\gametypes\_rank::xpeventpopupfinalize, ::patch_xpeventpopupfinalize); // event animation moveOverTime left_down
    replacefunc(maps\mp\gametypes\_rank::xppointspopup, ::patch_xppointspopupfinalize); // score animation moveOverTime left_down
	replacefunc(maps\mp\gametypes\_quickmessages::init, ::blank); // remove unnecessary menus

    // PLAYER
    replacefunc(maps\mp\gametypes\_playerlogic::initClientDvars, ::patch_initClientDvars); // cg_drawCrosshairNames set to 0
	replacefunc(maps\mp\gametypes\_gamescore::giveplayerscore, ::patch_giveplayerscore); // update money animation hud

    replacefunc(maps\mp\bots\_bot_internal::jump, ::_jump); // disable for juggers
    replacefunc(maps\mp\bots\_bot_internal::prone, ::_prone); // disable for juggers
    replacefunc(maps\mp\bots\_bot_internal::crouch, ::_crouch); // disable for dogs
    replacefunc(maps\mp\bots\_bot_internal::sprint, ::_sprint); // disable for dogs & juggers
    replacefunc(maps\mp\bots\_bot_internal::canFire, ::_canFire); // disable for dogs
    replacefunc(maps\mp\bots\_bot_internal::canAds, ::_canAds); // disable for dogs
    replacefunc(maps\mp\bots\_bot_internal::isInRange, ::_isInRange); // false for dogs
	replacefunc(maps\mp\bots\_bot_chat::doquickmessage, ::blank); // disable quickmessage
	replacefunc(maps\mp\bots\_bot_chat::bot_chat_death_watch, ::blank); // disable bot chat
    replacefunc(maps\mp\gametypes\_playerlogic::waitrespawnbutton, ::blank); // disable use button pressed to spawn
	replacefunc(maps\mp\bots\_bot::add_bot,  maps\mp\gametypes\survival::onAddBot); // skip obituary, notify all bots are ready and bot spawn handler
    replacefunc(maps\mp\gametypes\_playerlogic::notifyconnecting,  maps\mp\gametypes\survival::onAddSurvivor); // skip obituary, notify players ready, and player spawn handler

    // GAME
    replacefunc(maps\mp\_events::multiKill, ::patch_multiKill); // update challenges, double, triple, multi
    replacefunc(maps\mp\_utility::playDeathSound, ::patch_playDeathSound); // modifies deaths sound
    replacefunc(maps\mp\_utility::waitForTimeOrNotify, ::patch_respawnDealy); // set custom wait respawn
    replacefunc(maps\mp\_utility::iskillstreakweapon, ::patch_iskillstreakweapon); // enable c4 & claymore action slot
    replacefunc(maps\mp\gametypes\_weapons::equipmentWatchUse, ::patch_equipmentWatchUse); // wacth custom equipment stock
    replacefunc(maps\mp\gametypes\_weapons::watchweaponusage, ::patch_watchWeaponUsage); // fix last stand
    replacefunc(maps\mp\gametypes\_weapons::watchc4, ::_watchc4); // fix explosive issues
    replacefunc(maps\mp\gametypes\_weapons::watchclaymores, ::_watchclaymores); // fix explosive issues
	replacefunc(maps\mp\gametypes\_spawnlogic::getallotherplayers, ::_survivor_alives); // get spawnpoints dm will check getallotherplayers, now where the survivors are
    replacefunc(maps\mp\gametypes\_weapons::dropweaponfordeath, ::patch_dropweaponfordeath); // allows pick up ammunition regardless of the weapon attachs
    replacefunc(maps\mp\gametypes\_weapons::watchpickup, ::patch_watchpickup); // when picking up a weapon the data is recovered for the weapon shop
    replacefunc(maps\mp\gametypes\_weapons::deletePickupAfterAWhile, ::patch_deletePickupAfterAWhile); // wait till wave start of delete survivor's dropped weapons
	replacefunc(maps\mp\gametypes\_missions::playerKilled, ::blank); // disables challenge splash?... I don't remember
	replacefunc(maps\mp\gametypes\_music_and_dialog::onPlayerSpawned, ::blank); // disable default mp music and on start match
    replacefunc(maps\mp\gametypes\_deathicons::adddeathicon, ::blank); // disable death icon
	replacefunc(maps\mp\gametypes\_damage::playerkilled_internal,  lethalbeats\survival\patch\damage::playerkilled_internal); // disable death obituary & disable death corpses on first bot death
    replacefunc(maps\mp\gametypes\_damage::handlenormaldeath,  lethalbeats\survival\patch\damage::handlenormaldeath); // disable nuke streak
    replacefunc(maps\mp\gametypes\_damage::handlesuicidedeath,  lethalbeats\survival\patch\damage::handlesuicidedeath); // kill card display
    replacefunc(maps\mp\bots\_bot_utility::MissileEyesFix, ::patch_missileeyes); // wait predator death to manage the bot count
    replacefunc(maps\mp\gametypes\_spawnlogic::avoidweapondamage, ::blank);
    replacefunc(maps\mp\gametypes\_battlechatter_mp::saylocalsound, ::patch_saylocalsound);
    replacefunc(maps\mp\gametypes\_gamelogic::threadedSetWeaponStatByName, ::patch_threadedSetWeaponStatByName);

    level.onRespawnDelay = ::patch_getRespawnDelay; // although it is not used, it is required to return a value to avoid errors
}

_survivor_alives() { return survivors(true); }

//////////////////////////////////////////
//	               UI   		        //
//////////////////////////////////////////

menuInit()
{
    game["menu_team"] = "class";
    game["menu_class_axis"] = "class";
    game["menu_class_allies"] = "class";
	precacheMenu("class");
}

initHudMessage()
{
	precacheString(&"MP_FIRSTPLACE_NAME");
	precacheString(&"MP_SECONDPLACE_NAME");
	precacheString(&"MP_THIRDPLACE_NAME");
	precacheString(&"MP_MATCH_BONUS_IS");

    precachemenu("perk_display");
    precachemenu("perk_hide");
    precachemenu("killedby_card_hide");
	precacheMenu("client_cmd");

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

/*
///DocStringBegin
detail: patch_notifyMessage()
summary: Disable team splash hudElement on start, welcome msg.
///DocStringEnd
*/
patch_notifyMessage(notifyData) //disabled team splash msg on start
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

/*
///DocStringBegin
detail: patch_xpeventpopupfinalize()
summary: Change event popup to survival animation, move over time left & down.
///DocStringEnd
*/
patch_xpeventpopupfinalize(event, hudColor, glowAlpha)
{
    self endon("disconnect");
    self endon("joined_team");
    self endon("joined_spectators");
    self notify("xpEventPopup");
    self endon("xpEventPopup");

    if (level.hardcoremode || !isPlayer(self)) return;
	if (!isDefined(self.hud_xpEventPopup)) self.hud_xpEventPopup = maps\mp\gametypes\_rank::createXpEventPopup();

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

/*
///DocStringBegin
detail: patch_xppointspopupfinalize()
summary: Change score popup to survival money animation, move over time left & down.
///DocStringEnd
*/
patch_xppointspopupfinalize(amount, bonus, hudColor, glowAlpha)
{
    self endon("disconnect");
    self endon("joined_team");
    self endon("joined_spectators");

    if (amount == 0) return;
    if (!isdefined(self) || !isPlayer(self)) return;
	if (!isDefined(self.hud_xpPointsPopup)) self.hud_xpPointsPopupself = maps\mp\gametypes\_rank::createXpPointsPopup();
	
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
	self survivor_display_hud("animate_money");
	
	self notify("ScorePopComplete");
}

//////////////////////////////////////////
//	              PLAYER    	        //
//////////////////////////////////////////

/*
///DocStringBegin
detail: patch_initClientDvars()
summary: Overwrite default multiplayer client dvars, `cg_drawCrosshairNames` set to `0`.
///DocStringEnd
*/
patch_initClientDvars()
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

/*
///DocStringBegin
detail: patch_giveplayerscore()
summary: Update money hud animation on player score.
///DocStringEnd
*/
patch_giveplayerscore(type, player, victim, custom_amount, var_4)
{
	if (type != "survival" || !isPlayer(player) || player.team != "allies") return;

    score = player.pers["score"];
	player setClientDvar("ui_old_money", score);
    player.pers["score"] += custom_amount;
	player.score = player.pers["score"];

	player thread maps\mp\gametypes\_rank::xppointspopup(custom_amount, 0, undefined, 0);
    player maps\mp\gametypes\_persistence::statadd("score", custom_amount);
    player maps\mp\gametypes\_persistence::statsetchild("round", "score", player.score);
}

_crouch()
{
    if (self bot_is_jugger() && !self bot_has_ability("riot")) return;
    if (self bot_is_dog() || isDefined(self.usingRemote)) return;
	self maps\mp\bots\_bot_utility::BotBuiltinBotAction("+gocrouch");
	self maps\mp\bots\_bot_utility::BotBuiltinBotAction("-goprone");
}

_sprint()
{
	self endon("death");
	self endon("disconnect");
	self notify("bot_sprint");
	self endon("bot_sprint");

    if (self bot_is_jugger()) return;
	
	self maps\mp\bots\_bot_utility::BotBuiltinBotAction("+sprint");
	if (self bot_is_dog()) return;

	wait 0.05;
	self maps\mp\bots\_bot_utility::BotBuiltinBotAction("-sprint");
}

_jump()
{
	self endon("death");
	self endon("disconnect");
	self notify("bot_jump");
	self endon("bot_jump");
	
	if (self isusingremote() || self bot_is_jugger()) return;
	
	if (self getstance() != "stand")
	{
		self stand();
		wait 1;
	}
	
	self BotBuiltinBotAction("+gostand");
	wait 0.05;
	self BotBuiltinBotAction("-gostand");
}

_prone()
{
    if (self bot_is_jugger()) return;
	if (self isusingremote() || self.hasriotshieldequipped) return;	
	self BotBuiltinBotAction("-gocrouch");
	self BotBuiltinBotAction("+goprone");
}

_canFire(curweap)
{
	if (curweap == "none" || curweap == "riotshield_mp" || curweap == "iw5_dog_mp") return false;
	if (isdefined(self.usingremote) || curweap == "c4death_mp") return true;
	return self getweaponammoclip(curweap);
}

_canAds(dist, curweap)
{
	if (curweap == "c4_mp") return randomint(2);
	if (isdefined(self.usingremote) || curweap == "none" || curweap == "c4death_mp" || !getdvarint("bots_play_ads")) return false;
	
	far = level.bots_noadsdistance;
	if (self lethalbeats\player::player_has_perk("specialty_bulletaccuracy")) far *= 1.4;
	if (dist < far) return false;
	
	weapclass = (weaponclass(curweap));
	if (weapclass == "spread" || weapclass == "grenade" || curweap == "riotshield_mp" || curweap == "iw5_dog_mp" || self.bot.is_cur_akimbo) return false;
	
	return true;
}

_isInRange(dist, curweap)
{
	if (curweap == "none") return false;
	if (isdefined(self.usingremote)) return true;
	weapclass = weaponclass(curweap);
	if ((weapclass == "spread" || self.bot.is_cur_akimbo || curweap == "c4death_mp") && dist > level.bots_maxshotgundistance) return false;
	if ((curweap == "riotshield_mp" || curweap == "iw5_dog_mp") && dist > level.bots_maxknifedistance) return false;
	return true;
}

/*
///DocStringBegin
detail: patch_callbacks()
summary: Redefine game callbacks `onPlayerDamage`, `onPlayerKilled` and `onPlayerLastStand` based it is a bot or survivor.
///DocStringEnd
*/
patch_callbacks()
{
	level.prevCallbackPlayerDamage = maps\mp\gametypes\_damage::Callback_PlayerDamage;
	level.callbackPlayerDamage = ::patch_onPlayerDamage;
	
	level.prevCallbackPlayerKilled = maps\mp\gametypes\_damage::Callback_PlayerKilled;
	level.callbackPlayerKilled = ::patch_onPlayerKilled;
	
	level.callbackPlayerLastStand = ::patch_onPlayerLastStand;
}

patch_onPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
	if(self player_is_bot())
	{
		headshotPatch = iDamage >= self.health && !bot_is_dog() && !lethalbeats\array::array_contains(INSTAKILL, sMeansOfDeath) && isDefined(vPoint) && distance(vPoint, self getTagOrigin("j_head")) < 10;
		if (headshotPatch) sMeansOfDeath = "MOD_HEAD_SHOT"; //simple fix head shoot return torso_upper hitloc, model port bug maybe... if i don't forget, i will check it... maybe
		self lethalbeats\Survival\botHandler::onBotDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
		return;
	}
	
	if (self player_is_survivor())
	{
		self lethalbeats\Survival\survivorHandler::onPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
		return;
	}
	
	self [[level.prevCallbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
}

patch_onPlayerKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	if(self player_is_bot())
	{
		if(eAttacker player_is_survivor()) eAttacker  lethalbeats\Survival\survivorHandler::onPlayerBotKilled(self, iDamage, sMeansOfDeath, sWeapon);		
		self lethalbeats\Survival\botHandler::onBotKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
		return;
	}
	else if (isPlayer(self))
	{
		self lethalbeats\Survival\survivorHandler::onPlayerKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
		return;
	}
	
	self [[level.prevCallbackPlayerKilled]](eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
}

patch_onPlayerLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if(self isTestClient()) self lethalbeats\Survival\botHandler::onBotLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
	else self lethalbeats\Survival\survivorHandler::onPlayerLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
}

//////////////////////////////////////////
//	               GAME      	        //
//////////////////////////////////////////

/*
///DocStringBegin
detail: patch_multiKill()
summary: Update kills challenges, double, triple and multi
///DocStringEnd
*/
patch_multiKill(killId, killCount)
{
	if (killCount == 2)
	{
		self thread maps\mp\gametypes\_rank::xpEventPopup(&"SPLASHES_DOUBLEKILL");		
		self maps\mp\killstreaks\_killstreaks::giveAdrenaline("double");
		self survivor_update_challenge(CH_DOUBLE);
	}
	else if (killCount == 3)
	{
		self thread maps\mp\gametypes\_rank::xpEventPopup(&"SPLASHES_TRIPLEKILL");		
		self maps\mp\killstreaks\_killstreaks::giveAdrenaline("triple");
		thread teamPlayerCardSplash("callout_3xkill", self);
		self survivor_update_challenge(CH_TRIPLE);
	}
	else
	{
		self thread maps\mp\gametypes\_rank::xpEventPopup(&"SPLASHES_MULTIKILL");		
		self maps\mp\killstreaks\_killstreaks::giveAdrenaline("multi");
		thread teamPlayerCardSplash("callout_3xpluskill", self);
		self survivor_update_challenge(CH_MULTI);
	}
	
	self thread maps\mp\_matchdata::logMultiKill(killId, killCount);
	self setPlayerStatIfGreater("multikill", killCount);
	self incPlayerStat("mostmultikills", 1);
}

/*
///DocStringBegin
detail: patch_playDeathSound()
summary: Disable for bots death sound on first death & chopper streak owners, play custom sound for dogs.
///DocStringEnd
*/
patch_playDeathSound()
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

/*
///DocStringBegin
detail: patch_respawnDealy()
summary: When a player dies, the spawn wait is redirected to a handler for bots and another for survivors.
///DocStringEnd
*/
patch_respawnDealy(time, notifyname)
{
	if(self.team == "allies") self lethalbeats\Survival\survivorHandler::onPlayerRespawnDealy();
	else self lethalbeats\Survival\botHandler::onBotRespawnDealy();
}

patch_getRespawnDelay() { return 3; }

/*
///DocStringBegin
detail: patch_iskillstreakweapon(weapon: <String>): <Bool>
summary: Returns true for `claymore`, `C4` and `throwingKnife`, allows action slot button fo survival explosives `+actionslot 1`, `+actionslot 5`.
///DocStringEnd
*/
patch_iskillstreakweapon(weapon)
{
    if (!isdefined(weapon)) return 0;
    if (weapon == "none") return 0;
	
	if (weapon == CLAYMORE || weapon == C4 || weapon == THROWING_KNIFE) return 1;

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

/*
///DocStringBegin
detail: patch_equipmentWatchUse(owner: <Player>)
summary: Update `C4` & `Claymore` action slot and sotck on pickup for survival hud.
///DocStringEnd
*/
patch_equipmentWatchUse(owner)
{
	self endon("spawned_player");
	self endon("disconnect");
	
	self.trigger setCursorHint("HINT_NOICON");
	
	if (self.weaponname == C4)
		self.trigger setHintString(&"MP_PICKUP_C4");
	else if (self.weaponname == CLAYMORE)
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
			owner player_add_nades(self.weaponname, 1);
			if(!(owner hasWeapon(self.weaponname)))
			{
				owner giveweapon(self.weaponname);
				if (self.weaponname == CLAYMORE) owner _setActionSlot(1, "weapon", self.weaponname);
				else owner _setActionSlot(5, "weapon", self.weaponname);
			}
		}

		self.trigger delete();
		self delete();
		self notify("death");
	}
}

/*
///DocStringBegin
detail: patch_watchweaponusage(var_0)
summary: Fix last stand error, eliminating some lines, now no errors. ٩(•̀ᴗ•́)۶
///DocStringEnd
*/
patch_watchWeaponUsage(var_0)
{
    self endon("death");
    self endon("disconnect");
    self endon("faux_spawn");
    level endon("game_ended");

    for (;;)
    {
        self waittill("weapon_fired", weapon);
        self.hasdonecombat = 1;
		
        if (!isprimaryweapon(weapon) && !issidearm(weapon))
            continue;
		
        if (isdefined(self.hitsthismag[weapon]))
            thread updatemagshots(weapon);
		
        team = maps\mp\gametypes\_persistence::statgetbuffered("totalShots") + 1;
        hits = maps\mp\gametypes\_persistence::statgetbuffered("hits");
        accuracy = clamp(float(hits) / float(team), 0.0, 1.0) * 10000.0;
        maps\mp\gametypes\_persistence::statsetbuffered("totalShots", team);
        maps\mp\gametypes\_persistence::statsetbuffered("accuracy", int(accuracy));
        maps\mp\gametypes\_persistence::statsetbuffered("misses", int(team - hits));

        setweaponstat(weapon, 1, "shots");
        setweaponstat(weapon, self.hits, "hits");
        self.hits = 0;
    }
}

_watchc4()
{
    self endon("spawned_player");
    self endon("disconnect");

    for (;;)
    {
        self waittill("grenade_fire", item, weapname);
        if (weapname == "c4" || weapname == C4)
        {
            if (!isDefined(self.c4array)) self.c4array = [];
            if (!self.c4array.size) self thread watchc4altdetonate();
            if (self.c4array.size)
            {
                self.c4array = common_scripts\utility::array_removeundefined(self.c4array);
                if (self.c4array.size >= level.maxperplayerexplosives) self.c4array[0] detonate();
            }
            self.c4array[self.c4array.size] = item;
            item.owner = self;
            item.team = self.team;
            item.activated = 0;
            item.weaponname = weapname;
            item thread maps\mp\gametypes\_shellshock::c4_earthquake();
            item thread c4activate();
            item thread c4damage();
            item thread c4empdamage();
            item thread c4empkillstreakwait();
            item thread _c4OnStuck(self);
        }
    }
}

_c4OnStuck(owner)
{
    self waittill("missile_stuck");
    self.trigger = spawn("script_origin", self.origin);
    self equipmentwatchuse(owner);
}

_watchclaymores()
{
    self endon("spawned_player");
    self endon("disconnect");
    self.claymorearray = [];

    for (;;)
    {
        self waittill("grenade_fire", claymore, weapname);

        if (weapname == "claymore" || weapname == "claymore_mp")
        {
            if (!isalive(self))
            {
                claymore delete();
                return;
            }

            claymore hide();
            claymore thread _claymoreOnStuck(self, weapname);
        }
    }
}

_claymoreOnStuck(owner, weapname)
{
    self waittill("missile_stuck");
    distanceZ = 40;

    if (distanceZ * distanceZ < distancesquared(self.origin, owner.origin))
    {
        secTrace = bullettrace(owner.origin, owner.origin - (0, 0, distanceZ), 0, owner);
        if (!isDefined(secTrace["fraction"]) || secTrace["fraction"] == 1)
        {
            self delete();
            owner setweaponammostock("claymore_mp", owner getweaponammostock("claymore_mp") + 1);
            return;
        }
        self.origin = secTrace["position"];
    }

    self show();
    if (!isDefined(owner.selfarray)) owner.selfarray = [];
    owner.selfarray = common_scripts\utility::array_removeundefined(owner.selfarray);

    if (owner.selfarray.size >= level.maxperplayerexplosives)
        owner.selfarray[0] detonate();

    owner.selfarray[owner.selfarray.size] = self;
    self.owner = owner;
    self.team = owner.team;
    self.weaponname = weapname;
    self.trigger = spawn("script_origin", self.origin);
    level.mines[level.mines.size] = self;
    self thread c4damage();
    self thread c4empdamage();
    self thread c4empkillstreakwait();
    self thread claymoredetonation();
    self thread equipmentwatchuse(owner);
    self thread setclaymoreteamheadicon(owner.pers["team"]);
    owner.changingweapon = undefined;
}

/*
///DocStringBegin
detail: patch_dropweaponfordeath(attacker: <Entity>): <Void>
summary: Allows pick up ammunition regardless of the weapon attachs.
///DocStringEnd
*/
patch_dropweaponfordeath(attacker)
{
    if (isdefined(level.blockweapondrops) || isdefined(self.droppeddeathweapon) || level.ingraceperiod)
        return;

    weapon = self.lastdroppableweapon;

    if (!isdefined(weapon) || weapon == "none" || !self hasweapon(weapon) || maps\mp\_utility::isjuggernaut())
        return;

    tokens = strtok(weapon, "_");

    if (tokens[0] == "alt")
    {
        for (i = 0; i < tokens.size; i++)
        {
            if (i > 0 && i < 2)
            {
                weapon += tokens[i];
                continue;
            }

            if (i > 0)
            {
                weapon += ("_" + tokens[i]);
                continue;
            }

            weapon = "";
        }
    }

    if (weapon != "riotshield_mp")
    {
        if (!self anyammoforweaponmodes(weapon))
            return;

        clipAmmoR = self getweaponammoclip(weapon, "right");
        clipAmmoL = self getweaponammoclip(weapon, "left");

        if (!clipAmmoR && !clipAmmoL)
            return;

        stockAmmo = self getweaponammostock(weapon);
        stockMax = weaponmaxammo(weapon);

        if (stockAmmo > stockMax)
            stockAmmo = stockMax;

        item = self dropitem(weapon);

        if (!isdefined(item))
            return;

        item itemweaponsetammo(clipAmmoR, stockAmmo, clipAmmoL);
        
        trigger = spawn("trigger_radius", item.origin, 0, 32, 32);
	    trigger thread _watchAmmoPickup(item);
    }
    else
    {
        item = self dropitem(weapon);
        item itemweaponsetammo(1, 1, 0);
    }

    if (self player_is_survivor())
    {
        if (self.weaponData[0][0] == weapon) item.data = self.weaponData[0];
        else if (self.weaponData[1][0] == weapon) item.data = self.weaponData[1];
    }

    self.droppeddeathweapon = 1;
    item.owner = self;
    item.ownersattacker = attacker;
    item thread watchpickup();
    item thread deletePickupAfterAWhile();
}

/*
///DocStringBegin
detail: _watchpickup(): <Void>
summary: When picking up a weapon the data is recovered for the weapon shop.
///DocStringEnd
*/
patch_watchpickup()
{
    self endon("death");
    weapname = getitemweaponname();

    for (;;)
    {
        self waittill("trigger", player, droppedItem);

        if (isdefined(droppedItem))
        {
            if (isDefined(droppedItem.data))
                player lethalbeats\Survival\armories\weapons::setWeaponData(weapname, droppedItem.data);
            break;
        }
    }

    droppedWeaponName = droppedItem getitemweaponname();

    if (isdefined(player.tookweaponfrom[droppedWeaponName]))
    {
        droppedItem.owner = player.tookweaponfrom[droppedWeaponName];
        droppedItem.ownersattacker = player;
        player.tookweaponfrom[droppedWeaponName] = undefined;
    }

    droppedItem thread watchpickup();

    if (isdefined(self.ownersattacker) && self.ownersattacker == player)
        player.tookweaponfrom[weapname] = self.owner;
    else
        player.tookweaponfrom[weapname] = undefined;
}

/*
///DocStringBegin
detail: _deletePickupAfterAWhile(): <Void>
summary: Wait till wave start of delete survivor's dropped weapons.
///DocStringEnd
*/
patch_deletePickupAfterAWhile()
{
	self endon("death");

    if (self.owner player_is_survivor()) level waittill("wave_start");
    else wait 60;

	if (!isDefined(self)) return;

	self delete();
}

_watchAmmoPickup(item)
{
    self endon("death");

	weapon = item maps\mp\gametypes\_weapons::getItemWeaponName();
	weapon = lethalbeats\weapon::weapon_get_baseName(weapon);
	
	for(;;)
	{
		self waittill("trigger", player);        
        if (player isTestClient()) continue;
		targetWeapon = player lethalbeats\player::player_get_build_weapon(weapon);
        	
        if (!isDefined(targetWeapon)) continue;
        currentStock = player getWeaponAmmoStock(targetWeapon);
        maxAmmo = weaponMaxAmmo(targetWeapon);
        
        if (currentStock >= maxAmmo) continue;
        break;
	}

	dropStock = int(maxAmmo * lethalbeats\array::array_random_choices([0.1, 0.2, 0.3])[0]);
	player setWeaponAmmoStock(targetWeapon, currentStock + dropStock);
	player playLocalSound("weap_ammo_pickup");

	if (isDefined(item)) item delete();
	self delete();
}

_teamPlayerCardSplash(splash, owner, team)
{
    if (level.hardCoreMode) return;

    if (splash == "callout_destroyed_helicopter_flares")

	foreach(player in level.players)
	{
		if (isDefined(team) && player.team != team) continue;			
		player thread maps\mp\gametypes\_hud_message::playerCardSplashNotify(splash, owner);
	}
}

patch_missileeyes(player, rocket)
{
    player endon("joined_team");
    player endon("joined_spectators");

    rocket thread maps\mp\killstreaks\_remotemissile::rocket_cleanupondeath();
    player thread maps\mp\killstreaks\_remotemissile::player_cleanupongameended(rocket);
    player thread maps\mp\killstreaks\_remotemissile::player_cleanuponteamchange(rocket);

    player visionsetmissilecamforplayer("black_bw", 0);
    player endon("disconnect");

    if (isdefined(rocket))
    {
        player visionsetmissilecamforplayer(game["thermal_vision"], 1.0);
        //player thermalvisionon();
        player thread maps\mp\killstreaks\_remotemissile::delayedfofoverlay();
        player cameralinkto(rocket, "tag_origin");
        player controlslinkto(rocket);

        // _bot_utility.gsc additions
        player.rocket = rocket;
		rocket.owner = player;

        if (getdvarint("camera_thirdPerson"))
            player maps\mp\_utility::setthirdpersondof(0);

        rocket waittill("death");
        //player thermalvisionoff();

        // is defined check required because remote missile doesnt handle lifetime explosion gracefully
		// instantly deletes its self after an explode and death notify
        if (isdefined(rocket))
            player maps\mp\_matchdata::logkillstreakevent("predator_missile", rocket.origin);

        player controlsunlink();
        player maps\mp\_utility::freezecontrolswrapper(1);
        player.rocket = undefined; // _bot_utility.gsc additions

        // If a player gets the final kill with a hellfire, level.gameEnded will already be true at this point
        if (!level.gameended || isdefined(player.finalkill))
            player thread maps\mp\killstreaks\_remotemissile::staticeffect(0.5);

        wait 0.5;
        player thermalvisionfofoverlayoff();
        player cameraunlink();

        if (getdvarint("camera_thirdPerson"))
            player maps\mp\_utility::setthirdpersondof(1);

        if (player lethalbeats\survival\utility::player_is_bot())
            player lethalbeats\survival\utility::bot_kill();
    }

    player maps\mp\_utility::clearusingremote();
}

patch_saylocalsound(player, soundType)
{
    if (player.team == "allies" || player.team == "spectator" || player bot_is_dog() || (!isEndStr(soundType, "incoming") && randomInt(100) >= 65)) return;
    player playSound(player.pers["voicePrefix"] + level.bcSounds[soundType]);
}

patch_threadedSetWeaponStatByName( name, incValue, statName )
{
    if (self.team == "axis")
        return;

	self endon("disconnect");
	waittillframeend;
	
	setWeaponStat( name, incValue, statName );
}

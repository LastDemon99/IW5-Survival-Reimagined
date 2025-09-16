#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_weapons;
#include maps\mp\gametypes\_hud_util;
#include lethalbeats\survival\utility;
#include maps\mp\bots\_bot_internal;
#include maps\mp\bots\_bot_utility;
#include lethalbeats\player;

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
    replacefunc(maps\mp\gametypes\_rank::xpEventPopupFinalize, ::patch_xpeventpopupfinalize); // event animation moveOverTime left_down
    replacefunc(maps\mp\gametypes\_rank::xpPointsPopup, ::patch_xppointspopupfinalize); // score animation moveOverTime left_down
	replacefunc(maps\mp\gametypes\_quickmessages::init, ::blank); // remove unnecessary menus

    // PLAYER
    replacefunc(maps\mp\gametypes\_playerlogic::initClientDvars, ::patch_initClientDvars); // cg_drawCrosshairNames set to 0
	replacefunc(maps\mp\gametypes\_gamescore::givePlayerScore, ::patch_giveplayerscore); // update money animation hud

    replacefunc(maps\mp\bots\_bot_internal::jump, ::_jump); // disable for juggers
    replacefunc(maps\mp\bots\_bot_internal::prone, ::_prone); // disable for juggers
    replacefunc(maps\mp\bots\_bot_internal::crouch, ::_crouch); // disable for dogs
    replacefunc(maps\mp\bots\_bot_internal::sprint, ::_sprint); // disable for dogs & juggers
    replacefunc(maps\mp\bots\_bot_internal::canFire, ::_canFire); // disable for dogs
    replacefunc(maps\mp\bots\_bot_internal::canAds, ::_canAds); // disable for dogs
    replacefunc(maps\mp\bots\_bot_internal::isInRange, ::_isInRange); // false for dogs
	replacefunc(maps\mp\bots\_bot_chat::doquickmessage, ::blank); // disable quickmessage
	replacefunc(maps\mp\bots\_bot_chat::init, ::blank); // disable bot chat
    replacefunc(maps\mp\gametypes\_playerlogic::waitRespawnButton, ::blank); // disable use button pressed to spawn
	replacefunc(maps\mp\bots\_bot::add_bot,  maps\mp\gametypes\survival::onAddBot); // skip obituary, notify all bots are ready and bot spawn handler
    replacefunc(maps\mp\gametypes\_playerlogic::notifyConnecting,  maps\mp\gametypes\survival::onAddSurvivor); // skip obituary, notify players ready, and player spawn handler
    replacefunc(maps\mp\bots\_bot::add_bot,  maps\mp\gametypes\survival::onAddBot);

    // GAME
    replacefunc(maps\mp\_events::multiKill, ::patch_multiKill); // update challenges, double, triple, multi
    replacefunc(maps\mp\_utility::playDeathSound, ::patch_playDeathSound); // modifies deaths sound
    replacefunc(maps\mp\_utility::waitForTimeOrNotify, ::patch_respawnDealy); // set custom wait respawn
    replacefunc(maps\mp\_utility::isKillstreakWeapon, ::patch_iskillstreakweapon); // enable c4 & claymore action slot
    replacefunc(maps\mp\gametypes\_weapons::equipmentWatchUse, ::patch_equipmentWatchUse); // wacth custom equipment stock
    replacefunc(maps\mp\gametypes\_weapons::watchWeaponUsage, ::patch_watchWeaponUsage); // fix last stand
    replacefunc(maps\mp\gametypes\_weapons::watchC4, ::_watchc4); // fix explosive issues
    replacefunc(maps\mp\gametypes\_weapons::watchClaymores, ::_watchclaymores); // fix explosive issues
    replacefunc(maps\mp\gametypes\_weapons::spawnMine, ::_spawnMine);
	replacefunc(maps\mp\gametypes\_spawnlogic::getAllOtherPlayers, ::_survivor_alives); // get spawnpoints dm will check getallotherplayers, now where the survivors are
    replacefunc(maps\mp\gametypes\_weapons::dropWeaponForDeath, ::patch_dropweaponfordeath); // allows pick up ammunition regardless of the weapon attachs
	replacefunc(maps\mp\gametypes\_missions::playerKilled, ::blank); // disables challenge splash?... I don't remember
	replacefunc(maps\mp\gametypes\_music_and_dialog::onPlayerSpawned, ::blank); // disable default mp music and on start match
    replacefunc(maps\mp\gametypes\_deathicons::addDeathIcon, ::blank); // disable death icon
	replacefunc(maps\mp\gametypes\_damage::playerKilled_internal,  lethalbeats\survival\patch\damage::playerkilled_internal); // disable death obituary & disable death corpses on first bot death
    replacefunc(maps\mp\gametypes\_damage::handleNormalDeath,  lethalbeats\survival\patch\damage::handlenormaldeath); // disable nuke streak
    replacefunc(maps\mp\gametypes\_damage::handleSuicideDeath,  lethalbeats\survival\patch\damage::handlesuicidedeath); // kill card display
    replacefunc(maps\mp\bots\_bot_utility::MissileEyesFix, ::patch_missileeyes); // wait predator death to manage the bot count
    replacefunc(maps\mp\gametypes\_spawnlogic::avoidWeaponDamage, ::blank);
    replacefunc(maps\mp\gametypes\_battlechatter_mp::sayLocalSound, ::patch_saylocalsound);
    replacefunc(maps\mp\gametypes\_gamelogic::threadedSetWeaponStatByName, ::patch_threadedSetWeaponStatByName);
    replaceFunc(maps\mp\gametypes\_weapons::getDamageableEnts, ::patch_getDamageableEnts);
    replaceFunc(maps\mp\killstreaks\_airstrike::airstrikedamageentsthread, ::patch_airstrikedamageentsthread);
    replaceFunc(maps\mp\_utility::maxVehiclesAllowed, ::patch_maxVehiclesAllowed);
    replaceFunc(maps\mp\killstreaks\_killstreaks::enablekillstreakactionslots, ::patch_enablekillstreakactionslots);

    // CLEAN
    replaceFunc(maps\mp\_awards::onPlayerSpawned, ::blank);
    replaceFunc(maps\mp\_awards::monitorPositionCamping, ::blank);
    replaceFunc(maps\mp\_animatedmodels::animateModel, ::patch_animateModel);
    replaceFunc(common_scripts\_dynamic_world::playerTouchTriggerThink, ::patch_playerTouchTriggerThink);
    replaceFunc(common_scripts\_destructible::play_sound, ::patch_play_sound);
    replaceFunc(maps\mp\gametypes\_class::init, ::blank);
    replaceFunc(maps\mp\gametypes\_missions::init, ::blank);
    replaceFunc(maps\mp\gametypes\_missions::vehicleKilled, ::blank);
    replaceFunc(maps\mp\gametypes\_persistence::updateBufferedStats, ::blank);
    replaceFunc(maps\mp\gametypes\_missions::buildChallegeInfo, ::blank);
    
    replaceFunc(maps\mp\gametypes\_damage::logPrintPlayerDeath, ::blank);
    replaceFunc(maps\mp\gametypes\_damage::callback_playerDamage_internal, lethalbeats\survival\patch\damage::callback_playerDamage_internal);
    level.breakables_fx["barrel"]["explode"] = loadfx("props/barrelExp");
    level.breakables_fx["barrel"]["burn_start"] = loadfx("props/barrel_fire_top");
    level.breakables_fx["barrel"]["burn"] = loadfx("props/barrel_fire_top");

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
    precacheMenu("team_marinesopfor");
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
    self.hud_xppointspopup thread maps\mp\gametypes\_hud::fontPulse(self);
    
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
    maps\mp\gametypes\_playerlogic::initClientDvarsSplitScreenSpecific();

    if (getGametypeNumLives()) self setclientdvars("cg_deadChatWithDead", 1, "cg_deadChatWithTeam", 0, "cg_deadHearTeamLiving", 0, "cg_deadHearAllLiving", 0);
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

	player thread maps\mp\gametypes\_rank::xpPointsPopup(custom_amount, 0, undefined, 0);
    player maps\mp\gametypes\_persistence::statAdd("score", custom_amount);
    player maps\mp\gametypes\_persistence::statSetChild("round", "score", player.score);
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
	
	if (self isUsingRemote() || self bot_is_jugger()) return;
	
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
	if (self isUsingRemote() || self.hasriotshieldequipped) return;	
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
	level.prevCallbackPlayerDamage = maps\mp\gametypes\_damage::callback_playerDamage;
	level.callbackPlayerDamage = ::patch_onPlayerDamage;
	
	level.prevCallbackPlayerKilled = maps\mp\gametypes\_damage::callback_playerKilled;
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
	self initPlayerStat("mostmultikills", 1);
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
                self.c4array = array_removeUndefined(self.c4array);
                if (self.c4array.size >= level.maxperplayerexplosives) self.c4array[0] detonate();
            }

            self.c4array[self.c4array.size] = item;
            level.c4s[level.c4s.size] = item;

            item.owner = self;
            item.team = self.team;
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
    
    if (!isDefined(owner.claymorearray)) owner.claymorearray = [];
    if (owner.claymorearray.size)
    {
        owner.claymorearray = array_removeUndefined(owner.claymorearray);
        if (owner.claymorearray.size >= level.maxperplayerexplosives) owner.claymorearray[0] detonate();
    }
    owner.claymorearray[owner.claymorearray.size] = self;
    level.claymores[level.claymores.size] = self;

    self.owner = owner;
    self.team = owner.team;
    self.weaponname = weapname;
    self.trigger = spawn("script_origin", self.origin);

    self thread c4damage();
    self thread c4empdamage();
    self thread c4empkillstreakwait();
    self thread claymoredetonation();
    self thread equipmentwatchuse(owner);
    self thread setclaymoreteamheadicon(owner.pers["team"]);
    owner.changingweapon = undefined;
}

_spawnMine(origin, owner, type, angles)
{
    if (!isdefined(angles))
        angles = (0, randomfloat(360), 0);

    model = "projectile_bouncing_betty_grenade";
    mine = spawn("script_model", origin);
    mine.angles = angles;
    mine setmodel(model);
    mine.owner = owner;
    mine.weaponname = "bouncingbetty_mp";
    mine.killcamoffset = (0, 0, 4);
    mine.killcament = spawn("script_model", mine.origin + mine.killcamoffset);
    mine.killcament setscriptmoverkillcam("explosive");

    if (!isdefined(type) || type == "equipment")
    {
        if (!isDefined(owner.equipmentmines)) owner.equipmentmines = [];
        if (owner.equipmentmines.size)
        {
            owner.equipmentmines = array_removeUndefined(owner.equipmentmines);
            if (owner.equipmentmines.size >= level.maxperplayerexplosives) owner.equipmentmines[0] detonate();
        }
        owner.equipmentmines[owner.equipmentmines.size] = mine;
        level.mines[level.mines.size] = mine;
    }
    else
    {
        owner.killstreakmines[owner.killstreakmines.size] = mine;
        level.mines[level.mines.size] = mine;
    }

    mine thread createBombSquadModel("projectile_bouncing_betty_grenade_bombsquad", "tag_origin", level.otherteam[owner.team], owner);
    mine thread mineBeacon();
    mine thread setClaymoreTeamHeadIcon(owner.pers["team"]);
    mine thread mineDamageMonitor();
    mine thread mineProximityTrigger();
    return mine;
}

/*
///DocStringBegin
detail: <Entity> patch_dropweaponfordeath(attacker: <Entity>): <Void>
summary: Allows pick up ammunition regardless of the weapon attachs.
///DocStringEnd
*/
patch_dropWeaponForDeath(attacker)
{
    if (!self.dropWeapon || is_shop_near(self.origin)) return;

    weapon = self.lastdroppableweapon;
    if (!isdefined(weapon) || weapon == "none" || !self hasweapon(weapon)) return;
    if (isStrStart(weapon, "alt_")) weapon = getSubStr(weapon, 4, weapon.size);

    if (self player_is_survivor())
    {
        if (!self.enableUse) return;
        weaponData = self player_get_weapon_data(weapon);
        ammoData = self player_get_ammo_data(weapon);
    }
    else
    {
        weaponData = undefined;
        ammoData = undefined;
    }

    item = self dropitem(weapon);
    if (!isdefined(item)) return;
    
    item.owner = self;
    item.ownersattacker = attacker;

    weaponOrigin = item.origin;
    weaponModel = item.model;
    weaponName = item getItemWeaponName();
    item delete();

    self thread dropModelFromPlayer(weaponName, weaponModel, weaponData, ammoData);
}

dropModelFromPlayer(weaponName, weaponModel, weaponData, ammoData)
{ 
    forward = anglesToForward(self getPlayerAngles());
    start = self getEye() + (forward * 10);
    forwardPush = (forward[0] * 60, forward[1] * 60, 0);
    endOrigin_Air = self.origin + forwardPush + (self getVelocity() * 2.5);
    trace = bullettrace(endOrigin_Air, endOrigin_Air - (0, 0, 1000), false, self);
    moveVector = trace["position"] - start;
    randomRotation = (randomIntRange(-350, 350), randomIntRange(-350, 350), randomIntRange(-350, 350));

    obj = lethalbeats\utility::spawn_model(start, weaponModel);
    obj rotateVelocity(randomRotation, 1.2, 0.1);
    obj moveGravity(moveVector, 1.2);

    result = obj waitDropWeapon();
    obj delete();

    weaponModel = lethalbeats\utility::spawn_model(result[0], weaponModel);
    weaponModel.angles = result[1];
    weaponModel.owner = self;

    displayName = lethalbeats\weapon::weapon_get_display_name(weaponName);
    trigger = lethalbeats\trigger::trigger_create(weaponModel.origin, 64, 64);
    trigger lethalbeats\trigger::trigger_set_use("Press ^3[{+activate}] ^7to pick up " + displayName);
    trigger.showFilter = ::_weapon_trigger_filter;
    trigger.hintStringAlpha = 0.8;

    droppedIndex = level.droppedWeapons.size;
    level.droppedWeapons[droppedIndex] = [trigger, weaponModel];

    trigger thread _watchWeaponPickup(weaponName, weaponModel, weaponData, ammoData, droppedIndex);
    trigger thread _watchAmmoPickup(weaponName, weaponModel, ammoData, droppedIndex);
    trigger thread _deletePickupAfterAWhile(self player_is_survivor(), weaponModel, droppedIndex);
}

_weapon_trigger_filter(survivor)
{
    foreach(player in survivors())
        if (player.inLastStand && 1600 < distanceSquared(self.origin, player.origin))
            return false;
    return self survivor_trigger_filter(survivor);
}

waitDropWeapon()
{
    self endon("death");
    for(i = 0; i < 100; i++)
    {
        trace = bullettrace(self.origin, self.origin - (0, 0, 35), false, self);
        if (isDefined(trace["entity"]) || !isDefined(trace["surfacetype"]) || trace["surfacetype"] == "none")
        {
            wait 0.05;
            continue;
        }

        angles = lethalbeats\angles::angles_orient_to_normal(trace["normal"], self.angles[1]);
        return [trace["position"] + (0, 0, 0.5), angles + (0, 0, 90)];
    }
    return [self.origin, self.angles];
}

_watchWeaponPickup(weaponName, weaponModel, weaponData, ammoData, droppedIndex)
{
    self endon("death");

    for (;;)
    {
        self waittill("trigger_use", player);

        if (!player.enableUse || isDefined(player.changingweapon)) continue;

        weaponModel delete();

        if (player player_get_weapons().size >= 2) player player_drop_weapon();
        waittillframeend;
        player player_give_weapon(weaponName);
        
        if (!isDefined(weaponData)) weaponData = level player_get_weapon_data(weaponName);
        player player_set_weapon_data(weaponName, weaponData);

        if (!isDefined(ammoData)) ammoData = lethalbeats\weapon::weapon_get_random_ammo_data(weaponName);
        player player_set_ammo_from_data(weaponName, ammoData);

        player survivor_switch_to_weapon(weaponName);
        player playLocalSound("weap_ammo_pickup");

        level.droppedWeapons = lethalbeats\array::array_remove_index(level.droppedWeapons, droppedIndex);
        self delete();
    }
}

_watchAmmoPickup(weaponName, weaponModel, ammoData, droppedIndex)
{
    self endon("death");

    for (;;)
    {
        self waittill("trigger_radius", player);

        if (weaponModel.owner player_is_survivor()) continue;
        targetWeapon = player lethalbeats\player::player_get_build_weapon(weaponName);
        if (!isDefined(targetWeapon) || player player_has_max_ammo(targetWeapon)) continue;

        weaponModel delete();

        if (!isDefined(ammoData)) ammoData = lethalbeats\weapon::weapon_get_random_ammo_data(weaponName);
        player player_add_ammo_from_data(targetWeapon, ammoData);
	    player playLocalSound("weap_ammo_pickup");

        level.droppedWeapons = lethalbeats\array::array_remove_index(level.droppedWeapons, droppedIndex);
        self delete();
    }
}

_deletePickupAfterAWhile(waitWaveStart, weaponModel, droppedIndex)
{
    self endon("death");
    wait randomIntRange(10, 20);
    if (!isdefined(self)) return;
    level.droppedWeapons = lethalbeats\array::array_remove_index(level.droppedWeapons, droppedIndex);
    weaponModel delete();
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
            player maps\mp\_utility::setThirdPersonDOF(0);

        rocket waittill("death");
        //player thermalvisionoff();

        // is defined check required because remote missile doesnt handle lifetime explosion gracefully
		// instantly deletes its self after an explode and death notify
        if (isdefined(rocket))
            player maps\mp\_matchdata::logKillstreakEvent("predator_missile", rocket.origin);

        player controlsunlink();
        player maps\mp\_utility::freezeControlsWrapper(1);
        player.rocket = undefined; // _bot_utility.gsc additions

        // If a player gets the final kill with a hellfire, level.gameEnded will already be true at this point
        if (!level.gameended || isdefined(player.finalkill))
            player thread maps\mp\killstreaks\_remotemissile::staticeffect(0.5);

        wait 0.5;
        player thermalvisionfofoverlayoff();
        player cameraunlink();

        if (getdvarint("camera_thirdPerson"))
            player maps\mp\_utility::setThirdPersonDOF(1);

        if (player lethalbeats\survival\utility::player_is_bot())
            player lethalbeats\survival\utility::bot_kill();
    }

    player maps\mp\_utility::clearUsingRemote();
}

patch_saylocalsound(player, soundType)
{
    if (player.team == "allies" || player.team == "spectator" || player bot_is_dog() || (!isEndStr(soundType, "incoming") && randomInt(100) >= 65)) return;
    player playSound(player.pers["voicePrefix"] + level.bcSounds[soundType]);
}

patch_threadedSetWeaponStatByName(name, incValue, statName)
{
    if (self.team == "axis")
        return;

	self endon("disconnect");
	waittillframeend;
	
	setWeaponStat(name, incValue, statName);
}

patch_animateModel()
{
    if (isdefined(self.animation)) animation = self.animation;
    else if (isDefined(level.anim_prop_models) && isDefined(level.anim_prop_models[self.model]))
    {
        keys = getarraykeys(level.anim_prop_models[self.model]);
        if (isDefined(keys) && keys.size)
        {
            animKey = keys[randomint(keys.size)];
            animation = level.anim_prop_models[self.model][animKey];
            self scriptModelPlayAnim(animation);
            self willNeverChange();
        }
    }
}

patch_playerTouchTriggerThink(trigger, enterFunc, exitFunc)
{
    trigger endon("death");
	self endon("death");

    if (!isplayer(self)) self endon("death");

    if (!common_scripts\utility::isSp())
        touchName = self.guid;
    else
        touchName = "player" + gettime();

    trigger.touchlist[touchName] = self;

    if (isdefined(self.movetracker))
    {
        if (!isdefined(self.movetrackers)) self.movetrackers = 0;
        self.movetrackers++;
    }

    trigger notify("trigger_enter", self);
    self notify("trigger_enter", trigger);

    if (isdefined(enterFunc)) self thread [[ enterFunc ]](trigger);

    self.touchtriggers[trigger.entnum] = trigger;

    while (isalive(self) && self istouching(trigger) && (common_scripts\utility::isSp() || !level.gameended))
        wait 0.05;

    if (isdefined(self))
    {
        self.touchtriggers[trigger.entnum] = undefined;

        if (isdefined(trigger.movetracker))
        {
            if (isdefined(self.movetrackers))
                self.movetrackers--;
        }

        self notify("trigger_leave", trigger);
        if (isdefined(exitFunc)) self thread [[ exitFunc ]](trigger);
    }

    if (!common_scripts\utility::isSp() && level.gameended)
        return;

    trigger.touchlist[touchName] = undefined;
    trigger notify("trigger_leave", self);

    if (!common_scripts\_dynamic_world::anythingtouchingtrigger(trigger))
        trigger notify("trigger_empty");
}

patch_play_sound(alias, tag)
{
    if (!isDefined(self) || !isDefined(alias) || !isString(alias)) return;

    if (isDefined(tag) && isDefined(self getTagOrigin(tag)))
    {
        org = spawn("script_origin", self getTagOrigin(tag));
        org hide();
        org linkTo(self, tag, (0, 0, 0), (0, 0, 0));
    }
    else
    {
        org = spawn("script_origin", (0, 0, 0));
        org hide();
        org.origin = self.origin;
        org.angles = self.angles;
        org linkTo(self);
    }

    if (isDefined(org)) org playsound(alias);
    wait 5.0;
    if (isDefined(org)) org delete();
}

patch_getDamageableEnts(pos, radius, doLOS, startRadius)
{
    ents = [];

    if (!isdefined(doLOS))
        doLOS = 0;

    if (!isdefined(startRadius))
        startRadius = 0;

    radiusSq = radius * radius;
    players = level.players;

    for (i = 0; i < players.size; i++)
    {
        if (!isalive(players[i]) || players[i].sessionstate != "playing")
            continue;

        playerPos = maps\mp\_utility::get_damageable_player_pos(players[i]);
        distSq = distancesquared(pos, playerPos);

        if (distSq < radiusSq && (!doLOS || weaponDamageTracePassed(pos, playerPos, startRadius, players[i])))
            ents[ents.size] = maps\mp\_utility::get_damageable_player(players[i], playerPos);
    }

    grenades = getentarray("grenade", "classname");

    for (i = 0; i < grenades.size; i++)
    {
        entPos = maps\mp\_utility::get_damageable_grenade_pos(grenades[i]);
        distSq = distancesquared(pos, entPos);

        if (distSq < radiusSq && (!doLOS || weaponDamageTracePassed(pos, entPos, startRadius, grenades[i])))
            ents[ents.size] = maps\mp\_utility::get_damageable_grenade(grenades[i], entPos);
    }

    destructibles = getentarray("destructible", "targetname");

    for (i = 0; i < destructibles.size; i++)
    {
        entPos = destructibles[i].origin;
        distSq = distancesquared(pos, entPos);

        if (distSq < radiusSq && (!doLOS || weaponDamageTracePassed(pos, entPos, startRadius, destructibles[i])))
        {
            newEnt = spawnstruct();
            newEnt.isplayer = 0;
            newEnt.isadestructable = 0;
            newEnt.entity = destructibles[i];
            newEnt.damagecenter = entPos;
            ents[ents.size] = newEnt;
        }
    }

    destructables = getentarray("destructable", "targetname");

    for (i = 0; i < destructables.size; i++)
    {
        entPos = destructables[i].origin;
        distSq = distancesquared(pos, entPos);

        if (distSq < radiusSq && (!doLOS || weaponDamageTracePassed(pos, entPos, startRadius, destructables[i])))
        {
            newEnt = spawnstruct();
            newEnt.isplayer = 0;
            newEnt.isadestructable = 1;
            newEnt.entity = destructables[i];
            newEnt.damagecenter = entPos;
            ents[ents.size] = newEnt;
        }
    }

    sentries = getentarray("misc_turret", "classname");

    foreach (sentry in sentries)
    {
        entPos = sentry.origin + (0, 0, 32);
        distSq = distancesquared(pos, entPos);

        if (distSq < radiusSq && (!doLOS || weaponDamageTracePassed(pos, entPos, startRadius, sentry)))
        {
            switch (sentry.model)
            {
                case "vehicle_ugv_talon_gun_mp":
                case "mp_remote_turret":
                case "mp_sam_turret":
                case "sentry_minigun_weak":
                    ents[ents.size] = maps\mp\_utility::get_damageable_sentry(sentry, entPos);
                    break;
            }
        }
    }

    mines = getentarray("script_model", "classname");

    foreach (mine in mines)
    {
        if (mine.model != "projectile_bouncing_betty_grenade" && mine.model != "ims_scorpion_body")
            continue;

        entPos = mine.origin + (0, 0, 32);
        distSq = distancesquared(pos, entPos);

        if (distSq < radiusSq && (!doLOS || weaponDamageTracePassed(pos, entPos, startRadius, mine)))
            ents[ents.size] = maps\mp\_utility::get_damageable_mine(mine, entPos);
    }

    vehicles = getentarray("script_vehicle", "classname");
    foreach (vehicle in vehicles)
    {
        entPos = vehicle.origin;
        distSq = distancesquared(pos, entPos);

        if (distSq < radiusSq && (!doLOS || weaponDamageTracePassed(pos, entPos, startRadius, vehicle)))
        {
            newEnt = spawnstruct();
            newEnt.entity = vehicle;
            newEnt.damagecenter = entPos;
            newEnt.isplayer = 0;
            ents[ents.size] = newEnt;
        }
    }

    return ents;
}

patch_airstrikedamageentsthread(sWeapon)
{
    self notify("airstrikeDamageEntsThread");
    self endon("airstrikeDamageEntsThread");

    while (level.airstrikedamagedentsindex < level.airstrikedamagedentscount)
    {
        if (!isdefined(level.airstrikedamagedents[level.airstrikedamagedentsindex]))
        {
        }
        else
        {
            ent = level.airstrikedamagedents[level.airstrikedamagedentsindex];

            if (!isdefined(ent.entity))
            {
            }
            else if (isdefined(ent.entity.classname) && ent.entity.classname == "script_vehicle")
            {
                ent.entity notify("damage", ent.entity.maxhealth, ent.damageowner, vectornormalize(ent.damagecenter - ent.pos), ent.pos, "MOD_PROJECTILE_SPLASH", undefined, undefined, undefined, undefined, sWeapon);
            }
            else if (!ent.isplayer || isalive(ent.entity))
            {
                ent maps\mp\gametypes\_weapons::damageEnt(ent.einflictor, ent.damageowner, ent.damage, "MOD_PROJECTILE_SPLASH", sWeapon, ent.pos, vectornormalize(ent.damagecenter - ent.pos));
                
                level.airstrikedamagedents[level.airstrikedamagedentsindex] = undefined;

                if (ent.isplayer)
                    wait 0.05;
            }
            else
            {
                level.airstrikedamagedents[level.airstrikedamagedentsindex] = undefined;
            }
        }

        level.airstrikedamagedentsindex++;
    }
}

patch_maxVehiclesAllowed() { return 4; }

patch_enablekillstreakactionslots()
{
    for (i = 0; i < 4; i++)
    {
        slotID = i + 4;
        if (slotID == 1)
        {
            self maps\mp\_utility::_setactionslot(slotID, "weapon", "claymore_mp");
            self.actionslotenabled[i] = true;
            continue;
        }
        if (slotID == 5)
        {
            self maps\mp\_utility::_setactionslot(slotID, "weapon", "c4_mp");
            self.actionslotenabled[i] = true;
            continue;
        }
        if (self.pers["killstreaks"][i].available)
        {
            weapon = maps\mp\killstreaks\_killstreaks::getkillstreakweapon(self.pers["killstreaks"][i].streakname);
            self maps\mp\_utility::_setactionslot(slotID, "weapon", weapon);
        }
        else self maps\mp\_utility::_setactionslot(slotID, "");
        self.actionslotenabled[i] = true;
    }
}

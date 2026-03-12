#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_weapons;
#include maps\mp\gametypes\_hud_util;
#include lethalbeats\survival\utility;
#include maps\mp\bots\_bot_internal;
#include maps\mp\bots\_bot_utility;
#include lethalbeats\player;

#define INSTAKILL ["MOD_HEAD_SHOT", "MOD_MELEE", "MOD_EXPLOSIVE", "MOD_GRENADE", "MOD_GRENADE_SPLASH"]

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
    replacefunc(maps\mp\bots\_bot_internal::botFire, ::patch_botFire); // add wind up + burst fire behavior by difficulty
    replacefunc(maps\mp\bots\_bot_internal::target_loop, ::patch_target_loop);
    replacefunc(maps\mp\bots\_bot_internal::targetObjUpdateTraced, ::patch_targetObjUpdateTraced);
    replacefunc(maps\mp\bots\_bot_internal::targetObjUpdateNoTrace, ::patch_targetObjUpdateNoTrace);
    replacefunc(maps\mp\bots\_bot_internal::watchToLook, ::patch_watchToLook);
    replaceFunc(maps\mp\gametypes\_healthoverlay::init, ::blank);
    replaceFunc(maps\mp\perks\_perks::cac_modified_damage, ::patch_cac_modified_damage);
    replaceFunc(maps\mp\_stinger::stingerUsageLoop, ::patch_stingerUsageLoop);
    
    // GAME
    replacefunc(maps\mp\_events::multiKill, ::patch_multiKill); // update challenges, double, triple, multi
    replacefunc(maps\mp\_utility::playDeathSound, ::patch_playDeathSound); // modifies deaths sound
    replacefunc(maps\mp\_utility::waitForTimeOrNotify, ::patch_waitRespawn); // set custom wait respawn
    replacefunc(maps\mp\_utility::isKillstreakWeapon, ::patch_iskillstreakweapon); // enable c4 & claymore action slot
    replacefunc(maps\mp\gametypes\_weapons::watchWeaponUsage, ::patch_watchWeaponUsage); // fix last stand
	replacefunc(maps\mp\gametypes\_spawnlogic::getAllOtherPlayers, ::_survivor_alives); // get spawnpoints dm will check getallotherplayers, now where the survivors are
    replacefunc(maps\mp\gametypes\_weapons::dropWeaponForDeath, ::patch_dropweaponfordeath); // allows pick up ammunition regardless of the weapon attachs
	replacefunc(maps\mp\gametypes\_missions::playerKilled, ::blank); // disables challenge splash?... I don't remember
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
    replaceFunc(maps\mp\gametypes\_gamelogic::matchStartTimer, ::blank);
    replaceFunc(maps\mp\gametypes\_gamelogic::waitForPlayers, ::blank);
    replaceFunc(maps\mp\gametypes\_weapons::bombSquadWaiter, ::blank);
    replaceFunc(maps\mp\_load::hurtplayersthink, ::patch_hurtPlayersThink);

    // CLEAN
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
    replaceFunc(maps\mp\gametypes\_missions::updatechallenges, ::_updatechallenges);
    replaceFunc(maps\mp\_utility::updateobjectivetext, ::blank);
    replaceFunc(maps\mp\_utility::getObjectiveHintText, ::_textBlank);    
    replaceFunc(maps\mp\_areas::init, ::blank);
    replaceFunc(maps\mp\_awards::init, ::blank);
    replaceFunc(maps\mp\_utility::incPlayerStat, ::blank);
    replaceFunc(maps\mp\_utility::incPersStat, ::blank);
    replaceFunc(maps\mp\_utility::setPlayerStat, ::blank);
    replaceFunc(maps\mp\_utility::setPlayerStatIfGreater, ::blank);
    replaceFunc(maps\mp\_utility::setPlayerStatIfLower, ::blank);
    replaceFunc(maps\mp\_utility::initPlayerStat, ::blank);
    replaceFunc(maps\mp\_utility::getNextLifeId, ::_getNextLifeId);
    replaceFunc(maps\mp\gametypes\_weapons::setWeaponStat, ::blank);
    replaceFunc(maps\mp\gametypes\_rank::init, ::blank);
    replaceFunc(maps\mp\gametypes\_gamelogic::fixranktable, ::blank);
    replaceFunc(maps\mp\gametypes\_gamelogic::setWeaponStat, ::blank);
    replaceFunc(maps\mp\gametypes\_rank::getrankforxp, ::_getRankForXp);
    replaceFunc(maps\mp\gametypes\_rank::getWeaponRank, ::_getRankForXp);
    replaceFunc(maps\mp\gametypes\_rank::getrankinfominxp, ::_getRankForXp);
    replaceFunc(maps\mp\_events::checkmatchdatakills, ::blank);
    replaceFunc(maps\mp\_crib::init, ::blank);
    replaceFunc(maps\mp\_defcon::init, ::blank);
    replaceFunc(maps\mp\_empgrenade::init, ::blank);
    replaceFunc(maps\mp\_radiation::radiation, ::blank);
    replaceFunc(maps\mp\_skill::init, ::blank);
    replaceFunc(maps\mp\gametypes\_battlechatter_mp::onPlayerConnect, ::blank);
    replaceFunc(maps\mp\gametypes\_damagefeedback::onPlayerConnect, ::blank);
    replaceFunc(maps\mp\gametypes\_damagefeedback::updateDamageFeedback, ::patch_updateDamageFeedback);
    replaceFunc(maps\mp\gametypes\_deathicons::init, ::blank);
    replaceFunc(maps\mp\gametypes\_friendicons::init, ::blank);
    replaceFunc(maps\mp\gametypes\_gameobjects::init, ::blank);
    replaceFunc(maps\mp\gametypes\_hud_message::init, ::blank);
    replaceFunc(maps\mp\gametypes\_missions::init, ::blank);
    replaceFunc(maps\mp\gametypes\_music_and_dialog::init, ::blank);
    replaceFunc(maps\mp\gametypes\_playercards::init, ::blank);
    //replaceFunc(maps\mp\gametypes\_spectating::init, ::blank);
    replaceFunc(maps\mp\gametypes\_teams::init, ::patch_teamsInit);
    replaceFunc(maps\mp\gametypes\_weapons::sniperDustWatcher, ::blank);
    replaceFunc(maps\mp\gametypes\_weapons::onPlayerConnect, ::blank);
    replaceFunc(maps\mp\killstreaks\_ac130::onPlayerConnect, ::blank);
    replaceFunc(maps\mp\killstreaks\_autoshotgun::init, ::blank);
    replaceFunc(maps\mp\killstreaks\_deployablebox::init, ::blank);
    replaceFunc(maps\mp\killstreaks\_emp::init, ::blank);
    replaceFunc(maps\mp\killstreaks\_nuke::init, ::blank);
    replaceFunc(maps\mp\perks\_perks::onPlayerConnect, ::blank);
    replaceFunc(maps\mp\killstreaks\_uav::onPlayerConnect, ::blank);
    replaceFunc(maps\mp\_utility::isEMPed, ::_isEMPed);

    precacheShader("waypoint_revive");

    level.maxrank = int(tablelookup("mp/rankTable.csv", 0, "maxrank", 1));
    level.maxprestige = int(tablelookup("mp/rankIconTable.csv", 0, "maxprestige", 1));

    level.breakables_fx["barrel"]["explode"] = loadfx("props/barrelExp");
    level.breakables_fx["barrel"]["burn_start"] = loadfx("props/barrel_fire_top");
    level.breakables_fx["barrel"]["burn"] = loadfx("props/barrel_fire_top");

    level.teamemped["allies"] = 0;
    level.teamemped["axis"] = 0;

    level.numgametypereservedobjectives = 0;

    level.onRespawnDelay = ::patch_getRespawnDelay; // although it is not used, it is required to return a value to avoid errors

    level thread lethalbeats\survival\patch\mines::mineBombSquadVisibilityUpdater();

    level waittill("prematch_done");
    game["voice"]["allies"] = maps\mp\gametypes\_teams::getTeamVoicePrefix("allies") + "1mc_";
    game["voice"]["axis"] = maps\mp\gametypes\_teams::getTeamVoicePrefix("axis") + "1mc_";
    game["dialog"]["lbguard_destroyed"] = "lbguard_destroyed";
    game["dialog"]["remote_sentry_destroyed"] = "remote_sentry_destroyed";
    game["dialog"]["sentry_destroyed"] = "sentry_destroyed";
    game["dialog"]["ims_destroyed"] = "ims_destroyed";
    game["strings"]["target_destroyed"] = &"MP_TARGET_DESTROYED";
}

_isEMPed() { return false; }

_getNextLifeId() { return 1; }
_getRankForXp(xpVal) { return 0; }

_updatechallenges() { self.challengedata = []; }

_textBlank(arg) { return ""; }

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
    if (self.team == "axis") return;

    self endon("disconnect");
    self endon("joined_team");
    self endon("joined_spectators");

    if (amount == 0) return;
    if (!isdefined(self) || !isPlayer(self)) return;
	if (!isDefined(self.hud_xpPointsPopup))
    {
        self.hud_xpPointsPopup = self maps\mp\gametypes\_rank::createXpPointsPopup();
        self.xpupdatetotal = 0;
        self.bonusupdatetotal = 0;
    }
	
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

patch_botFire(curweap)
{
    if (isDefined(self.isHuman) && !self.isHuman) return;

    self.bot.last_fire_time = gettime();
    settings = self lethalbeats\survival\difficulty::difficulty_get_bot_settings();
    isSemiAuto = weaponIsSemiAuto(curweap);
    targetId = -1;
    if (isdefined(self.bot.target) && isdefined(self.bot.target.entity)) targetId = self.bot.target.entity getentitynumber();

    now = gettime();
    windUpTime = settings["windUpTime"];

    fireTime = settings["fireTime"];
    minShots = int(settings["minShots"]);
    maxShots = int(max(minShots + 5, settings["maxShots"]));
    minPause = settings["minPause"];
    maxPause = max(minPause, settings["maxPause"]);

    if (targetId < 0)
    {
        if (isdefined(self.bot.fireCycleData))
        {
            self.bot.fireCycleData.targetId = -1;
            self.bot.fireCycleData.hadVision = false;
            self.bot.fireCycleData.wasVisibleLastTick = false;
            self.bot.fireCycleData.shotsLeft = 0;
            self.bot.fireCycleData.nextShotTime = 0;
            self.bot.fireCycleData.pauseUntil = 0;
            self.bot.fireCycleData.windUpUntil = 0;
        }
        return;
    }

    if (!isdefined(self.bot.fireCycleData))
    {
        self.bot.fireCycleData = spawnstruct();
        self.bot.fireCycleData.targetId = -1;
        self.bot.fireCycleData.hadVision = false;
        self.bot.fireCycleData.wasVisibleLastTick = false;
        self.bot.fireCycleData.shotsLeft = 0;
        self.bot.fireCycleData.nextShotTime = 0;
        self.bot.fireCycleData.pauseUntil = 0;
        self.bot.fireCycleData.windUpUntil = 0;
    }

    if (self.bot.fireCycleData.targetId != targetId)
    {
        self.bot.fireCycleData.targetId = targetId;
        self.bot.fireCycleData.hadVision = false;
        self.bot.fireCycleData.wasVisibleLastTick = false;
        self.bot.fireCycleData.shotsLeft = 0;
        self.bot.fireCycleData.nextShotTime = 0;
        self.bot.fireCycleData.pauseUntil = 0;
        self.bot.fireCycleData.windUpUntil = 0;
    }

    canShootTarget = false;
    if (isdefined(self.bot.target) && isdefined(self.bot.target.trace_time) && isdefined(self.bot.target.no_trace_time))
        canShootTarget = (self.bot.target.trace_time > 0 && self.bot.target.no_trace_time <= 0);

    if (!canShootTarget)
    {
        self.bot.fireCycleData.hadVision = false;
        self.bot.fireCycleData.wasVisibleLastTick = false;
        self.bot.fireCycleData.shotsLeft = 0;
        self.bot.fireCycleData.nextShotTime = 0;
        self.bot.fireCycleData.pauseUntil = 0;
        self.bot.fireCycleData.windUpUntil = 0;
        return;
    }

    // Force windup every time visibility is reacquired (no-vision -> vision).
    if (!self.bot.fireCycleData.wasVisibleLastTick)
    {
        self.bot.fireCycleData.hadVision = true;
        self.bot.fireCycleData.wasVisibleLastTick = true;
        self.bot.fireCycleData.shotsLeft = 0;
        self.bot.fireCycleData.nextShotTime = 0;
        self.bot.fireCycleData.windUpUntil = now + int(windUpTime * 1000);
    }

    if (now < self.bot.fireCycleData.pauseUntil || now < self.bot.fireCycleData.windUpUntil || now < self.bot.fireCycleData.nextShotTime) return;

    if (self.bot.fireCycleData.shotsLeft <= 0)
        self.bot.fireCycleData.shotsLeft = randomIntRange(minShots, maxShots + 1);

    if (isSemiAuto && !self.bot.is_cur_full_auto)
    {
        if (self.bot.semi_time) return;

        self thread maps\mp\bots\_bot_internal::pressFire();
        if (self.bot.is_cur_akimbo) self thread maps\mp\bots\_bot_internal::pressADS();
        self thread maps\mp\bots\_bot_internal::doSemiTime();
    }
    else
    {
        self thread maps\mp\bots\_bot_internal::pressFire(fireTime);
        if (self.bot.is_cur_akimbo) self thread maps\mp\bots\_bot_internal::pressADS(fireTime);
    }

    self.bot.fireCycleData.shotsLeft--;
    if (self.bot.fireCycleData.shotsLeft <= 0)
    {
        self.bot.fireCycleData.pauseUntil = now + int(randomfloatrange(minPause, maxPause) * 1000);
        self.bot.fireCycleData.windUpUntil = self.bot.fireCycleData.pauseUntil + int(windUpTime * 1000);
        self.bot.fireCycleData.nextShotTime = 0;
    }
    else self.bot.fireCycleData.nextShotTime = now + int(fireTime * 1000);
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
		headshotPatch = iDamage >= self.health && !bot_is_dog() && !lethalbeats\array::array_contains(INSTAKILL, sMeansOfDeath) && isDefined(vPoint) && distanceSquared(vPoint, self getTagOrigin("j_head")) < 100;
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

_releaseSurvivorTargetSlot(targetObj)
{
    if (!isDefined(targetObj) || !isDefined(targetObj.entity)) return;

    targetEnt = targetObj.entity;
    targetCount = 0;
    if (isDefined(targetEnt.survival_target_count)) targetCount = int(targetEnt.survival_target_count);
    targetEnt.survival_target_count = max(0, targetCount - 1);
}

/*
///DocStringBegin
detail: patch_target_loop(): <Void>
summary: Bots Pursuit Improvement.
///DocStringEnd
*/
patch_target_loop()
{
    if (isDefined(self.isHuman) && !self.isHuman) return;

	myEye = self geteye();	
	if (isdefined(self.remoteuav)) myEye = self.remoteuav gettagorigin("tag_origin");
	
	theTime = gettime();
	myAngles = self getplayerangles();
	myFov = self.pers["bots"]["skill"]["fov"];
    if (!isDefined(myFov)) myFov = 0.75;
	bestTargets = [];
	bestTime = 2147483647;
	rememberTime = self.pers["bots"]["skill"]["remember_time"];
    if (!isDefined(rememberTime)) rememberTime = 1000;
	initReactTime = self.pers["bots"]["skill"]["init_react_time"];
    if (!isDefined(initReactTime)) initReactTime = 1000;
	hasTarget = isdefined(self.bot.target);
	usingRemote = self isusingremote();
	ignoreSmoke = issubstr(self getcurrentweapon(), "_thermal");
	vehEnt = undefined;
	adsAmount = self playerads();
    if (!isDefined(adsAmount)) adsAmount = 0;
	adsFovFact = self.pers["bots"]["skill"]["ads_fov_multi"];
    if (!isDefined(adsFovFact)) adsFovFact = 0.5;
	
	if (usingRemote)
	{
		if (isdefined(level.ac130player) && level.ac130player == self)
			vehEnt = level.ac130.planemodel;
		
		if (isdefined(level.chopper) && isdefined(level.chopper.gunner) && level.chopper.gunner == self)
			vehEnt = level.chopper;
	}
	
	// reduce fov if ads'ing
	if (adsAmount > 0) myFov *= 1 - adsFovFact * adsAmount;

    if (isDefined(self.stuned) && self.stuned)
        return;

    survivorsAlives = survivors(true);

    // Purge stale survivor targets that are no longer alive.
    if (!isDefined(self.bot.targets)) self.bot.targets = [];
    targetKeys = getarraykeys(self.bot.targets);
    foreach (targetKey in targetKeys)
    {
        targetObj = self.bot.targets[targetKey];
        if (!isDefined(targetObj) || !isDefined(targetObj.entity))
        {
            self.bot.targets[targetKey] = undefined;
            continue;
        }

        targetEnt = targetObj.entity;
        if (targetEnt player_is_survivor() && !targetEnt player_is_valid_target())
        {
            if (hasTarget && isDefined(self.bot.target) && isDefined(self.bot.target.entity) && self.bot.target.entity == targetEnt)
            {
                self _releaseSurvivorTargetSlot(self.bot.target);
                self.bot.target = undefined;
                hasTarget = false;
            }

            self.bot.targets[targetKey] = undefined;
        }
    }

    if (isDefined(self.bot.script_target))
    {
        ent = self.bot.script_target;
        if (isDefined(ent) && ent player_is_survivor() && !ent player_is_valid_target())
        {
            self.bot.script_target = undefined;
            self.bot.script_target_offset = undefined;
        }

        if (lethalbeats\array::array_contains(survivorsAlives, ent))
        {
            if (isDefined(ent))
            {
                key = ent getentitynumber() + "";
                self.bot.targets[key] = undefined;
            }

            if (hasTarget && isDefined(self.bot.target) && isDefined(self.bot.target.entity) && self.bot.target.entity == ent)
            {
                self _releaseSurvivorTargetSlot(self.bot.target);
                self.bot.target = undefined;
                hasTarget = false;
            }

            self.bot.script_target = undefined;
            self.bot.script_target_offset = undefined;
        }
    }

    if (!isDefined(survivorsAlives) || !survivorsAlives.size)
    {
        if (hasTarget && isDefined(self.bot.target) && isDefined(self.bot.target.entity))
        {
            self _releaseSurvivorTargetSlot(self.bot.target);
            self.bot.target = undefined;
            self notify("new_enemy");
        }
        return;
    }

	if (hasTarget && !isdefined(self.bot.target.entity))
	{
        self _releaseSurvivorTargetSlot(self.bot.target);
		self.bot.target = undefined;
		hasTarget = false;
	}

    foreach (survivor in survivorsAlives)
    {
        if (!isDefined(survivor) || !survivor player_is_valid_target()) continue;

        key = survivor getentitynumber() + "";
        obj = self.bot.targets[key];
        isObjDef = isdefined(obj);
        daDist = distancesquared(self.origin, survivor.origin);

        if (usingRemote) daDist = 0;

        canTargetPlayer = false;
        if (usingRemote)
        {
            canTargetPlayer = (bullettracepassed(myEye, survivor gettagorigin("j_head"), false, vehEnt)
                            && !survivor _hasperk("specialty_blindeye"));
        }
        else
        {
            hasLineOfSight = (survivor checkTraceForBone(myEye, "j_head") ||
                            survivor checkTraceForBone(myEye, "j_spineupper") ||
                            survivor checkTraceForBone(myEye, "j_ankle_le") ||
                            survivor checkTraceForBone(myEye, "j_ankle_ri"));

            smokeCheck = (ignoreSmoke ||
                        SmokeTrace(myEye, survivor.origin, level.smokeradius) ||
                        daDist < level.bots_maxknifedistance * 8);

            fovCheck = (getConeDot(survivor.origin, self.origin, myAngles) >= (myFov * 0.5) ||
                        (isObjDef && isdefined(obj.trace_time)) ||
                        daDist < level.bots_maxknifedistance * 6);

            canTargetPlayer = (hasLineOfSight && smokeCheck && fovCheck);
            if (!canTargetPlayer && daDist < level.bots_maxknifedistance * 3)
                canTargetPlayer = hasLineOfSight;
        }

        if (isdefined(self.bot.target_this_frame) && self.bot.target_this_frame == survivor)
        {
            self.bot.target_this_frame = undefined;
            canTargetPlayer = true;
        }

        if (isdefined(self.remoteuav) && isdefined(survivor.uavremotemarkedby))
            canTargetPlayer = false;

        if (canTargetPlayer)
        {
            if (!isObjDef)
            {
                obj = self createTargetObj(survivor, theTime);
                obj.is_human_player = true;
                obj.is_survivor_target = true;
                self.bot.targets[key] = obj;
            }

            self targetObjUpdateTraced(obj, daDist, survivor, theTime, false, usingRemote);
        }
        else
        {
            if (!isObjDef) continue;

            self targetObjUpdateNoTrace(obj);

            currentRememberTime = rememberTime * 3;
            if (obj.no_trace_time > currentRememberTime)
            {
                self.bot.targets[key] = undefined;
                continue;
            }
        }

        if (!isdefined(obj)) continue;
        if (theTime - obj.time < initReactTime) continue;

        timeDiff = int((theTime - obj.trace_time_time) * 0.1);
        if (timeDiff < bestTime)
        {
            bestTargets = [];
            bestTime = timeDiff;
        }

        if (timeDiff == bestTime) bestTargets[key] = obj;
    }

    beforeTargetID = -1;
    newTargetID = -1;
    toBeTarget = undefined;

    if (hasTarget && isDefined(self.bot.target) && isdefined(self.bot.target.entity))
        beforeTargetID = self.bot.target.entity getentitynumber();

    bestKeys = getarraykeys(bestTargets);
    if (bestKeys.size)
    {
        minTargetCount = 2147483647;
        closest = 2147483647;

        foreach (k in bestKeys)
        {
            targetObj = bestTargets[k];
            if (!isDefined(targetObj) || !isDefined(targetObj.entity)) continue;

            targetEnt = targetObj.entity;
            targetCount = 0;
            if (isDefined(targetEnt.survival_target_count)) targetCount = int(targetEnt.survival_target_count);

            if (targetCount < minTargetCount)
            {
                minTargetCount = targetCount;
                closest = targetObj.dist;
                toBeTarget = targetObj;
                continue;
            }

            if (targetCount == minTargetCount && targetObj.dist < closest)
            {
                closest = targetObj.dist;
                toBeTarget = targetObj;
            }
        }
    }

    if (isdefined(toBeTarget) && isdefined(toBeTarget.entity))
        newTargetID = toBeTarget.entity getentitynumber();

	if (beforeTargetID != newTargetID)
	{
        if (hasTarget && isDefined(self.bot.target) && isdefined(self.bot.target.entity))
            self _releaseSurvivorTargetSlot(self.bot.target);

        if (isdefined(toBeTarget) && isdefined(toBeTarget.entity))
        {
            targetEnt = toBeTarget.entity;
            targetCount = 0;
            if (isDefined(targetEnt.survival_target_count)) targetCount = int(targetEnt.survival_target_count);
            targetEnt.survival_target_count = targetCount + 1;
        }

		self.bot.target = toBeTarget;
		self notify("new_enemy");
	}
}

patch_targetObjUpdateTraced(obj, daDist, ent, theTime, isScriptObj, usingRemote)
{
	distClose = self.pers["bots"]["skill"]["dist_start"];
    if (!isDefined(distClose)) distClose = 750;
    weapDistMulti = 1;
    if (isDefined(self.bot.cur_weap_dist_multi)) weapDistMulti = self.bot.cur_weap_dist_multi;
    distClose *= weapDistMulti;
	distClose *= distClose;
	
	distMax = self.pers["bots"]["skill"]["dist_max"];
    if (!isDefined(distMax)) distMax = 2000;
    distMax *= weapDistMulti;
	distMax *= distMax;
    if (distMax <= distClose) distMax = distClose + 1;
	
	timeMulti = 1;
	
    targetIsSurvivor = (isDefined(obj.is_survivor_target) && obj.is_survivor_target)
        || (isDefined(obj.entity) && (obj.entity player_is_survivor()));
    targetIsAliveSurvivor = isDefined(obj.entity) && (obj.entity player_is_survivor()) && obj.entity player_is_valid_target();

    // ignore max distance & increase track multiplier if target is survivor
	if (!usingRemote && !isScriptObj && !targetIsSurvivor)
	{
		if (daDist > distMax) timeMulti = 0;
		else if (daDist > distClose) timeMulti = 1 - ((daDist - distClose) / (distMax - distClose));
	}
    if (targetIsSurvivor && targetIsAliveSurvivor) timeMulti = 1.5;
	
	obj.no_trace_time = 0;
	obj.trace_time += int(50 * timeMulti);
	obj.dist = daDist;
	obj.last_seen_pos = ent.origin;
	obj.trace_time_time = theTime;
	
	self updateAimOffset(obj, theTime);
}

patch_targetObjUpdateNoTrace(obj)
{
	incrementAmount = 50;	
    targetIsSurvivor = (isDefined(obj.is_survivor_target) && obj.is_survivor_target)
        || (isDefined(obj.entity) && (obj.entity player_is_survivor()));
    targetIsAliveSurvivor = isDefined(obj.entity) && (obj.entity player_is_survivor()) && obj.entity player_is_valid_target();
	
    // increase no_trace if target is survivor
    if (targetIsSurvivor && targetIsAliveSurvivor) incrementAmount = 25;	
	
    obj.no_trace_time += incrementAmount;
	obj.trace_time = 0;

    // If we lose LOS on the active target, require windup again on reacquisition.
    if (isDefined(self.bot) && isDefined(self.bot.fireCycleData) && isDefined(self.bot.target) && isDefined(self.bot.target.entity)
        && isDefined(obj.entity) && self.bot.target.entity == obj.entity)
    {
        self.bot.fireCycleData.shotsLeft = 0;
        self.bot.fireCycleData.nextShotTime = 0;
        self.bot.fireCycleData.pauseUntil = 0;
        self.bot.fireCycleData.windUpUntil = 0;
    }

    // do not reset didlook for survivor target
    if (!targetIsSurvivor || !targetIsAliveSurvivor) obj.didlook = false;
}

/*
///DocStringBegin
detail: patch_watchToLook(): <Void>
summary: Bots Aggression Strategy.
///DocStringEnd
*/
patch_watchToLook()
{
    if (isDefined(self.isHuman) && !self.isHuman) return;

	self endon("disconnect");
	self endon("death");
	self endon("new_enemy");
	
	for (;;)
	{
		while (isdefined(self.bot.target) && self.bot.target.didlook)
		{
			wait 0.05;
		}
		
		while (isdefined(self.bot.target) && self.bot.target.no_trace_time)
		{
			wait 0.05;
		}
		
		if (!isdefined(self.bot.target))
		{
			break;
		}
		
		self.bot.target.didlook = true;
		
		if (self.bot.isfrozen)
		{
			continue;
		}
		
        // SURVIVAL MODE: Extend tactical actions against the human player
		maxDistForAction = level.bots_maxshotgundistance * 2;
		if (isdefined(self.bot.target.is_human_player) && self.bot.target.is_human_player)
		{
            maxDistForAction = level.bots_maxshotgundistance * 3;
		}
		
		if (self.bot.target.dist > maxDistForAction)
		{
			continue;
		}
		
		if (self.bot.target.dist <= level.bots_maxknifedistance)
		{
			continue;
		}
		
		if (!self canFire(self getcurrentweapon()))
		{
			continue;
		}
		
		if (!self isInRange(self.bot.target.dist, self getcurrentweapon()))
		{
			continue;
		}
		
		if (self.bot.is_cur_sniper)
		{
			continue;
		}
		
        settings = self lethalbeats\survival\difficulty::difficulty_get_bot_settings();
        jumpChance = self.pers["bots"]["behavior"]["jump"];
        jumpCooldown = isDefined(settings["tacticalJumpCooldown"]) ? settings["tacticalJumpCooldown"] : 2500;
        dropshotDuration = isDefined(settings["tacticalDropshotDuration"]) ? settings["tacticalDropshotDuration"] : 1.25;
		
		if (randomint(100) > jumpChance)
		{
			continue;
		}
		
		if (!getdvarint("bots_play_jumpdrop"))
		{
			continue;
		}
		
		if (isdefined(self.bot.jump_time) && gettime() - self.bot.jump_time <= jumpCooldown)
		{
			continue;
		}
		
		if (self.bot.target.rand <= self.pers["bots"]["behavior"]["strafe"])
		{
			if (self getstance() != "stand")
			{
				continue;
			}
			
			self.bot.jump_time = gettime();
			self thread lethalbeats\Survival\patch\globallogic::_jump();
		}
		else
		{
			if (getConeDot(self.bot.target.last_seen_pos, self.origin, self getplayerangles()) < 0.8 || self.bot.target.dist <= level.bots_noadsdistance)
			{
				continue;
			}
			
			self.bot.jump_time = gettime();
			self lethalbeats\Survival\patch\globallogic::_prone();
			self notify("kill_goal");
            wait dropshotDuration;
			self lethalbeats\Survival\patch\globallogic::_crouch();
		}
	}
}

patch_stingerUsageLoop()
{
    self endon("death");
    self endon("disconnect");
    self endon("faux_spawn");

    LOCK_LENGTH = 1000;
    self maps\mp\_stinger::initStingerUsage();

    for (;;)
    {
        wait 0.05;
        weapon = self getcurrentweapon();

        if (weapon != "stinger_mp")
        {
            self maps\mp\_stinger::resetStingerLocking();
            continue;
        }

        if (self playerads() < 0.95)
        {
            self maps\mp\_stinger::resetStingerLocking();
            continue;
        }

        self.stingeruseentered = 1;

        if (!isdefined(self.stingerstage))
            self.stingerstage = 0;

        maps\mp\_stinger::stingerDebugDraw(self.stingertarget);

        if (self.stingerstage == 0)
        {
            targets = maps\mp\_stinger::getTargetList();

            if (targets.size == 0)
                continue;

            targetsInReticle = [];

            foreach (target in targets)
            {
                if (!isdefined(target))
                    continue;

                insideReticle = self worldpointinreticle_circle(target.origin, 65, 75);

                if (insideReticle)
                    targetsInReticle[targetsInReticle.size] = target;
            }

            if (targetsInReticle.size == 0)
                continue;

            sortedTargets = sortbydistance(targetsInReticle, self.origin);

            if (!self maps\mp\_stinger::lockSightTest(sortedTargets[0]))
                continue;

            self thread maps\mp\_stinger::loopStingerLockingFeedback();
            self.stingertarget = sortedTargets[0];
            self.stingerlockstarttime = gettime();
            self.stingerstage = 1;
            self.stingerlostsightlinetime = 0;
        }

        if (self.stingerstage == 1)
        {
            if (!maps\mp\_stinger::stillValidStingerLock(self.stingertarget))
            {
                self maps\mp\_stinger::resetStingerLocking();
                continue;
            }

            passed = self maps\mp\_stinger::softSightTest();

            if (!passed)
                continue;

            timePassed = gettime() - self.stingerlockstarttime;

            if (maps\mp\_utility::_hasPerk("specialty_fasterlockon"))
            {
                if (timePassed < LOCK_LENGTH * 0.5)
                    continue;
            }
            else if (timePassed < LOCK_LENGTH)
                continue;

            self notify("stop_javelin_locking_feedback");
            self thread maps\mp\_stinger::loopStingerLockedFeedback();

            if (self.stingertarget.model == "vehicle_av8b_harrier_jet_opfor_mp" || self.stingertarget.model == "vehicle_av8b_harrier_jet_mp" || self.stingertarget.model == "vehicle_little_bird_armed" || self.stingertarget.model == "vehicle_ugv_talon_mp")
                self weaponlockfinalize(self.stingertarget);
            else if (isplayer(self.stingertarget))
                self weaponlockfinalize(self.stingertarget, (100, 0, 64));
            else
                self weaponlockfinalize(self.stingertarget, (100, 0, -32));

            self.stingerstage = 2;
        }

        if (self.stingerstage == 2)
        {
            passed = self maps\mp\_stinger::softSightTest();

            if (!passed)
                continue;

            if (!maps\mp\_stinger::stillValidStingerLock(self.stingertarget))
            {
                self maps\mp\_stinger::resetStingerLocking();
                continue;
            }
        }
    }
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
	if (self bot_is_dog() || self bot_is_killstreak()) return;
	self playSound((self.team == "axis" ? "generic_death_russian_" : "generic_death_american_") + randomIntRange(1, 8));
}

/*
///DocStringBegin
detail: patch_waitRespawn()
summary: When a player dies, the spawn wait is redirected to a handler for bots and another for survivors.
///DocStringEnd
*/
patch_waitRespawn(time, notifyname)
{
	if(self.team == "allies") self lethalbeats\Survival\survivorHandler::playerWaitRespawn();
	else self lethalbeats\Survival\botHandler::botWaitRespawn();
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

    origin = getGroundPosition(result[0], 32, 0, 32);

    weaponModel = lethalbeats\utility::spawn_model(origin, weaponModel);
    weaponModel.angles = result[1];
    weaponModel.owner = self;

    if (!isDefined(weaponModel)) return;
    if (!self player_is_survivor()) 
    {
        droppedIndex = level.droppedWeapons.size;
        level.droppedWeapons[droppedIndex] = weaponModel;
        weaponModel.droppedIndex = droppedIndex;
    }

    displayName = lethalbeats\weapon::weapon_get_display_name(weaponName);

    trigger = lethalbeats\trigger::trigger_create(origin, 45);
    trigger.owner = self;
    trigger.weapon = weaponName;
    trigger lethalbeats\trigger::trigger_set_use("Hold ^3[{+activate}] ^7to pick up " + displayName);
    trigger lethalbeats\trigger::trigger_set_enable_condition(::_weaponPickupFilter);
    trigger thread weaponPickupMonitor(weaponName, ammoData, weaponData, weaponModel);
    trigger thread ammoPickupMonitor(weaponName, ammoData, weaponModel);    
    trigger thread _deletePickupAfterAWhile(weaponModel);
}

_weaponPickupFilter(player)
{
    foreach(weapon in player player_get_weapons())
        if (isDefined(weapon) && self.weapon == weapon && player player_has_max_ammo(weapon, true))
            return false;
    return self survivor_trigger_filter(player);
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

        angles = lethalbeats\vector::vector_angles_orient_to_normal(trace["normal"], self.angles[1]);
        return [trace["position"] + (0, 0, 0.5), angles + (0, 0, 90)];
    }
    waittillframeend;
    return [self.origin, self.angles];
}

weaponPickupMonitor(weaponName, ammoData, weaponData, weaponModel)
{
    self endon("death");

    for(;;)
    {
        self waittill("trigger_use", player, keyType);

        if (keyType == "jkey_down")
        {
            result = player lethalbeats\utility::waittill_any_return("jkey_up", 0.45);
            if (isString(result)) continue;
        }

        currWeapon = player getCurrentWeapon();
        if (!isDefined(currWeapon) || currWeapon == "none") continue;

        weapons = player player_get_weapons();
        if (weapons.size > 1)
        {
            player player_drop_weapon();
            waittillframeend;

            if (player hasWeapon(currWeapon))
            {
                player player_take_all_weapon_buffs();
                player takeWeapon(currWeapon);
            }
        }
		
        player player_give_weapon(weaponName);
        
        if (!isDefined(weaponData)) weaponData = level player_get_weapon_data(weaponName);
        player player_set_weapon_data(weaponName, weaponData);

        if (!isDefined(ammoData)) ammoData = lethalbeats\weapon::weapon_get_random_ammo_data(weaponName);
        player player_set_ammo_data(weaponName, ammoData);

        player survivor_switch_to_weapon(weaponName);
        player playLocalSound("weap_ammo_pickup");

        if (isDefined(weaponModel.droppedIndex)) level.droppedWeapons = lethalbeats\array::array_remove_index(level.droppedWeapons, weaponModel.droppedIndex);

        weaponModel delete();
        self lethalbeats\trigger::trigger_delete();
    }
}

ammoPickupMonitor(weaponName, ammoData, weaponModel)
{
    level endon("game_ended");
    self endon("death");

    baseWeaponName = lethalbeats\weapon::weapon_get_baseName(weaponName);

    dropOwner = undefined;
    if (isDefined(self.owner)) dropOwner = self.owner;
    else if (isDefined(weaponModel) && isDefined(weaponModel.owner)) dropOwner = weaponModel.owner;

    isSurvivorWeapon = isDefined(dropOwner) && isPlayer(dropOwner) && dropOwner player_is_survivor();

    for(;;)
    {
        self waittill("trigger_radius", player);        

        if (isSurvivorWeapon) continue;

        targetWeapon = player player_get_build_weapon(baseWeaponName);
        if (!isDefined(targetWeapon)) continue;

        if (player player_has_max_ammo(targetWeapon, true)) continue;

        if (!isDefined(ammoData)) ammoData = lethalbeats\weapon::weapon_get_random_ammo_data(weaponName);
        player player_add_ammo_from_data(targetWeapon, ammoData);
        player playLocalSound("weap_ammo_pickup");
        if (isDefined(weaponModel.droppedIndex)) level.droppedWeapons = lethalbeats\array::array_remove_index(level.droppedWeapons, weaponModel.droppedIndex);
        
        if (isDefined(weaponModel)) weaponModel delete();
        self lethalbeats\trigger::trigger_delete();
    }
}

_deletePickupAfterAWhile(weaponModel)
{
    level endon("game_ended");
    self endon("death");

    isSurvivorWeapon = isDefined(weaponModel)
        && isDefined(weaponModel.owner)
        && isPlayer(weaponModel.owner)
        && weaponModel.owner player_is_survivor();
    
    if (isSurvivorWeapon) wait 120;
    else wait randomIntRange(10, 20);

    if (!isDefined(weaponModel)) return;
    if (!isSurvivorWeapon) level.droppedWeapons = lethalbeats\array::array_remove_index(level.droppedWeapons, weaponModel.droppedIndex);
    
    weaponModel delete();
    self lethalbeats\trigger::trigger_delete();
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

    if (isdefined(enterFunc)) self thread [[enterFunc]](trigger);

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
        if (isdefined(exitFunc)) self thread [[exitFunc]](trigger);
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

patch_hurtPlayersThink()
{
    level endon("game_ended");
    wait(randomfloat(1));

    for (;;)
    {
        foreach (player in survivors())
        {
            if (player istouching(self) && maps\mp\_utility::isReallyAlive(player))
                player maps\mp\_utility::_suicide();
        }
        wait 0.5;
    }
}

patch_cac_modified_damage(victim, attacker, damage, meansOfDeath, weapon, impactPoint, impactDir, hitLoc)
{
    if (victim.team == "axis") return int(damage);

    damageAdd = 0;

    if (maps\mp\_utility::isBulletDamage(meansOfDeath))
    {
        if (isplayer(attacker) && attacker maps\mp\_utility::_hasPerk("specialty_paint_pro") && !maps\mp\_utility::isKillstreakWeapon(weapon))
        {
            if (!victim maps\mp\perks\_perkfunctions::isPainted())
                attacker maps\mp\gametypes\_missions::processChallenge("ch_bulletpaint");

            victim thread maps\mp\perks\_perkfunctions::setPainted();
        }

        if (isplayer(attacker) && isdefined(weapon) && maps\mp\_utility::getWeaponClass(weapon) == "weapon_sniper" && issubstr(weapon, "silencer"))
            damage *= 0.75;

        if (isplayer(attacker) && (attacker maps\mp\_utility::_hasPerk("specialty_stopping_power") && attacker maps\mp\_utility::_hasPerk("specialty_bulletdamage") || attacker maps\mp\_utility::_hasPerk("specialty_moredamage")))
            damage += damage * level.bulletdamagemod;

        if (victim maps\mp\_utility::isJuggernaut())
            damage *= level.armorvestmod;
    }
    else if (isexplosivedamagemod(meansOfDeath))
    {
        if (isplayer(attacker) && attacker != victim && attacker isitemunlocked("specialty_paint") && attacker maps\mp\_utility::_hasPerk("specialty_paint") && !maps\mp\_utility::isKillstreakWeapon(weapon))
        {
            if (!victim maps\mp\perks\_perkfunctions::isPainted())
                attacker maps\mp\gametypes\_missions::processChallenge("ch_paint_pro");

            victim thread maps\mp\perks\_perkfunctions::setPainted();
        }

        if (isplayer(attacker) && weaponinheritsperks(weapon) && attacker maps\mp\_utility::_hasPerk("specialty_explosivedamage") && victim maps\mp\_utility::_hasPerk("_specialty_blastshield"))
            damageAdd += 0;
        else if (isplayer(attacker) && weaponinheritsperks(weapon) && attacker maps\mp\_utility::_hasPerk("specialty_explosivedamage"))
            damageAdd += damage * level.explosivedamagemod;
        else if (victim maps\mp\_utility::_hasPerk("_specialty_blastshield") && (weapon != "semtex_mp" || damage != 120))
            damageAdd -= int(damage * (1 - level.blastshieldmod));

        if (maps\mp\_utility::isKillstreakWeapon(weapon) && isplayer(attacker) && attacker maps\mp\_utility::_hasPerk("specialty_dangerclose"))
            damageAdd += damage * level.dangerclosemod;

        if (victim maps\mp\_utility::isJuggernaut())
        {
            switch (weapon)
            {
                case "ac130_25mm_mp":
                    damage *= level.armorvestmod;
                    break;
                case "remote_mortar_missile_mp":
                    damage *= 0.2;
                    break;
                default:
                    if (damage < 1000)
                    {
                        if (damage > 1)
                            damage *= level.armorvestmod;
                    }

                    break;
            }
        }

        if (10 - (level.graceperiod - level.ingraceperiod) > 0)
            damage *= level.armorvestmod;
    }
    else if (meansOfDeath == "MOD_FALLING")
    {
        if (victim isitemunlocked("specialty_falldamage") && victim maps\mp\_utility::_hasPerk("specialty_falldamage"))
        {
            if (damage > 0)
                victim maps\mp\gametypes\_missions::processChallenge("ch_falldamage");

            damageAdd = 0;
            damage = 0;
        }
    }
    else if (meansOfDeath == "MOD_MELEE")
    {
        if (isdefined(victim.haslightarmor) && victim.haslightarmor)
        {
            if (issubstr(weapon, "riotshield"))
                damage = int(victim.maxhealth * 0.66);
            else
                damage = victim.maxhealth + 1;
        }

        if (victim maps\mp\_utility::isJuggernaut())
        {
            damage = 20;
            damageAdd = 0;
        }
    }
    else if (meansOfDeath == "MOD_IMPACT")
    {
        if (victim maps\mp\_utility::isJuggernaut())
        {
            switch (weapon)
            {
                case "concussion_grenade_mp":
                case "frag_grenade_mp":
                case "smoke_grenade_mp":
                case "flash_grenade_mp":
                case "semtex_mp":
                    damage = 5;
                    break;
                default:
                    if (damage < 1000)
                        damage = 25;

                    break;
            }

            damageAdd = 0;
        }
    }

    if (victim maps\mp\_utility::_hasPerk("specialty_combathigh"))
    {
        if (isdefined(self.damageblockedtotal) && (!level.teambased || isdefined(attacker) && isdefined(attacker.team) && victim.team != attacker.team))
        {
            damageTotal = damage + damageAdd;
            damageBlocked = damageTotal - damageTotal / 3;
            self.damageblockedtotal += damageBlocked;

            if (self.damageblockedtotal >= 101)
            {
                self notify("combathigh_survived");
                self.damageblockedtotal = undefined;
            }
        }

        if (weapon != "throwingknife_mp")
        {
            switch (meansOfDeath)
            {
                case "MOD_MELEE":
                case "MOD_FALLING":
                    break;
                default:
                    damage = int(damage / 3);
                    damageAdd = int(damageAdd / 3);
                    break;
            }
        }
    }

    if (isdefined(victim.haslightarmor) && victim.haslightarmor && weapon == "throwingknife_mp")
    {
        damage = victim.health;
        damageAdd = 0;
    }

    if (damage <= 1)
    {
        damage = 1;
        return damage;
    }
    else
        return int(damage + damageAdd);
}

patch_updateDamageFeedback(typeHit)
{
    if (!isplayer(self) || self.team == "axis") return;

    x = -12;
    y = -12;

    if (getdvarint("camera_thirdPerson"))
        yOffset = self getthirdpersoncrosshairoffset() * 240;
    else
        yOffset = getdvarfloat("cg_crosshairVerticalOffset") * 240;

    if (level.splitscreen || self issplitscreenplayer())
        yOffset *= 0.5;

    feedbackDurationOverride = 0;
    startAlpha = 1;

    if (typeHit == "hitBodyArmor")
    {
        self.hud_damagefeedback setshader("damage_feedback_j", 24, 48);
        self playlocalsound("MP_hit_alert");
    }
    else if (typeHit == "hitLightArmor")
    {
        self.hud_damagefeedback setshader("damage_feedback_lightarmor", 24, 48);
        self playlocalsound("MP_hit_alert");
    }
    else if (typeHit == "hitJuggernaut")
    {
        self.hud_damagefeedback setshader("damage_feedback_juggernaut", 24, 48);
        self playlocalsound("MP_hit_alert");
    }
    else if (typeHit == "none")
        return;
    else if (typeHit == "scavenger" && !level.hardcoremode)
    {
        x = -36;
        y = 32;
        self.hud_damagefeedback setshader("scavenger_pickup", 64, 32);
        feedbackDurationOverride = 2.5;
    }
    else
    {
        self.hud_damagefeedback setshader("damage_feedback", 24, 48);
        self playlocalsound("MP_hit_alert");
    }

    self.hud_damagefeedback.alpha = startAlpha;

    if (feedbackDurationOverride != 0)
        self.hud_damagefeedback fadeovertime(feedbackDurationOverride);
    else
        self.hud_damagefeedback fadeovertime(1);

    self.hud_damagefeedback.alpha = 0;

    if (self.hud_damagefeedback.x != x)
        self.hud_damagefeedback.x = x;

    y -= int(yOffset);

    if (self.hud_damagefeedback.y != y)
        self.hud_damagefeedback.y = y;
}

patch_teamsInit()
{
    maps\mp\gametypes\_teams::initScoreBoard();
    maps\mp\gametypes\_teams::setPlayerModels();
}

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_weapons;
#include maps\mp\gametypes\_hud_util;
#include lethalbeats\survival\utility;
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
    replacefunc(maps\mp\gametypes\_playerlogic::waitRespawnButton, ::blank); // disable use button pressed to spawn
    replacefunc(maps\mp\gametypes\_playerlogic::notifyConnecting,  maps\mp\gametypes\survival::onAddSurvivor); // skip obituary, notify players ready, and player spawn handler
    replaceFunc(maps\mp\gametypes\_healthoverlay::init, ::blank);
    replaceFunc(maps\mp\perks\_perks::cac_modified_damage, ::patch_cac_modified_damage);
    replaceFunc(maps\mp\_stinger::stingerUsageLoop, ::patch_stingerUsageLoop);
    
    // GAME
    replacefunc(maps\mp\_events::killedPlayer, ::patch_killedPlayer);
    replacefunc(maps\mp\_events::multiKill, ::patch_multiKill); // update challenges, double, triple, multi
    replacefunc(maps\mp\_utility::playDeathSound, ::patch_playDeathSound); // modifies deaths sound
    replacefunc(maps\mp\_utility::waitForTimeOrNotify, ::patch_waitRespawn); // set custom wait respawn
    replacefunc(maps\mp\_utility::isKillstreakWeapon, ::patch_iskillstreakweapon); // enable c4 & claymore action slot
    replacefunc(maps\mp\gametypes\_weapons::watchWeaponUsage, ::patch_watchWeaponUsage); // fix last stand
	replacefunc(maps\mp\gametypes\_spawnlogic::getAllOtherPlayers, ::_survivor_alives); // get spawnpoints dm will check getallotherplayers, now where the survivors are
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
    replacefunc(maps\mp\gametypes\_missions::playerKilled, ::blank); // disables challenge splash?... I don't remember
    replacefunc(maps\mp\gametypes\_deathicons::addDeathIcon, ::blank); // disable death icon
	replacefunc(maps\mp\gametypes\_damage::playerKilled_internal,  lethalbeats\survival\patch\damage::playerkilled_internal); // disable death obituary & disable death corpses on first bot death
    replacefunc(maps\mp\gametypes\_damage::handleNormalDeath,  lethalbeats\survival\patch\damage::handlenormaldeath); // disable nuke streak
    replacefunc(maps\mp\gametypes\_damage::handleSuicideDeath,  lethalbeats\survival\patch\damage::handlesuicidedeath); // disable kill card display
    replacefunc(maps\mp\gametypes\_spawnlogic::avoidWeaponDamage, ::blank);
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
    replaceFunc(maps\mp\_load::deletedestructiblekillcament, ::deleteDestructibleKillCamEnt);

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
	scoreVal = (isDefined(self.pers) && isDefined(self.pers["score"])) ? self.pers["score"] : 0;
	score_str = "" + scoreVal;
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
	scoreVal = (isDefined(self.pers) && isDefined(self.pers["score"])) ? self.pers["score"] : 0;
	score_str = "" + scoreVal;
	self.hud_xpPointsPopup.x -= 400 - score_str.size * 20;
	self.hud_xpPointsPopup.y += 275;
    self.xpupdatetotal = 0;
	
	wait 0.75;
	self.hud_xppointspopup fadeovertime(0.75);
    self.hud_xppointspopup.alpha = 0;
	self setClientDvar("ui_money", scoreVal);
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
	if (!isDefined(custom_amount) || custom_amount <= 0) return;
	if (!isDefined(player.pers["score"])) player.pers["score"] = 0;
	if (!isDefined(player.score)) player.score = 0;

    score = player.pers["score"];
	player setClientDvar("ui_old_money", score);
    player.pers["score"] += custom_amount;
	player.score = player.pers["score"];

	player thread maps\mp\gametypes\_rank::xpPointsPopup(custom_amount, 0, undefined, 0);
    player maps\mp\gametypes\_persistence::statAdd("score", custom_amount);
    player maps\mp\gametypes\_persistence::statSetChild("round", "score", player.score);
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
detail: patch_killedPlayer()
summary: Safe replacement for maps\mp\_events::killedPlayer in Survival mode.
///DocStringEnd
*/
patch_killedPlayer(killId, victim, weapon, meansOfDeath)
{
	if (!isDefined(self) || !isPlayer(self)) return;
	if (self player_is_bot()) return;

	if (!isDefined(self.recentkillcount)) self.recentkillcount = 0;
	self thread maps\mp\_events::updaterecentkills(killId);

	self.lastkilltime = gettime();
	self.lastkilledplayer = victim;
	self.modifiers = [];
	if (!isDefined(level.numkills)) level.numkills = 0;
	level.numkills++;

	if (isDefined(victim) && isPlayer(victim) && isDefined(victim.guid) && isDefined(self.damagedplayers))
		self.damagedplayers[victim.guid] = undefined;

	if (isDefined(meansOfDeath) && meansOfDeath == "MOD_HEAD_SHOT")
	{
		self.modifiers["headshot"] = 1;
		self thread maps\mp\gametypes\_rank::xpEventPopup(&"SPLASHES_HEADSHOT");
		self notify("headshot");
	}
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
summary: When a player dies, the spawn wait is redirected to a handler for survivors.
///DocStringEnd
*/
patch_waitRespawn(time, notifyname)
{
	if(self.team == "allies") self lethalbeats\Survival\survivorHandler::playerWaitRespawn();
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

deleteDestructibleKillCamEnt()
{
	self.killCamEnt delete();
}

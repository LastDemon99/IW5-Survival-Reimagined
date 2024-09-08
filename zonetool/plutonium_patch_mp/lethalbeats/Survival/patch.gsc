#include lethalbeats\survival\patch\_patch;
#include lethalbeats\survival\_utility;

init()
{
	replacefunc(maps\mp\gametypes\_quickmessages::init, ::blank); // remove unnecessary menus
	replacefunc(maps\mp\gametypes\_hud_message::init, lethalbeats\survival\patch\_menus::initHudMessage); // remove unnecessary menus
	replacefunc(maps\mp\gametypes\_menus::init, lethalbeats\survival\patch\_menus::init); // remove unnecessary menus & set armories trigger menu handle

	replacefunc(maps\mp\gametypes\_damage::playerkilled_internal, lethalbeats\survival\patch\_damage::playerkilled_internal); // disable death obituary & disable death corpses on first bot death
	replacefunc(maps\mp\gametypes\_damage::handlenormaldeath, lethalbeats\survival\patch\_damage::handlenormaldeath); // disable nuke streak
	replacefunc(maps\mp\gametypes\_damage::callback_playerlaststand, lethalbeats\survival\patch\_damage::callback_playerlaststand); // custom lastand for bots y players
	
	replacefunc(maps\mp\gametypes\_hud_message::notifyMessage, ::notifyMessage); // disable welcome msg, team splash on start
	replacefunc(maps\mp\gametypes\_weapons::watchweaponusage, ::_watchweaponusage); // fix last stand error
	replacefunc(maps\mp\gametypes\_missions::playerKilled, ::blank); // disables challenge splash?... I don't remember
	replacefunc(maps\mp\bots\_bot_chat::bot_chat_death_watch, ::blank); // disable bot chat
	replacefunc(maps\mp\bots\_bot_chat::doquickmessage, ::blank); // disable quickmessage
	replacefunc(maps\mp\gametypes\_deathicons::adddeathicon, ::blank); // disable death icon
	replacefunc(maps\mp\_events::multiKill, ::multiKill); // check wave challenges [ double, triple, multi ]
	replacefunc(maps\mp\gametypes\_playerlogic::initClientDvars, ::initClientDvars);
	replacefunc(maps\mp\killstreaks\_remotemissile::missileEyes, maps\mp\killstreaks\_aamissile::missileEyes); // predator missileEyes causes server crash
    replacefunc(maps\mp\gametypes\_music_and_dialog::onPlayerSpawned, ::blank); // disable default mp music and on start match
	replacefunc(maps\mp\_utility::playDeathSound, ::_playDeathSound); // disable death sound on first bots death
	replacefunc(maps\mp\_utility::waitForTimeOrNotify, ::_respawnDealy); // set custom wait respawn
	replacefunc(maps\mp\gametypes\_spawnlogic::getallotherplayers, ::getSurvivorsAlive); // get spawnpoints dm will check getallotherplayers, now where the survivors are
	replacefunc(maps\mp\_utility::iskillstreakweapon, ::_iskillstreakweapon); // enable c4 & claymore action slot
	replacefunc(maps\mp\gametypes\_weapons::equipmentWatchUse, ::_equipmentWatchUse); // wacth custom equipment stock
	replacefunc(maps\mp\gametypes\_gamescore::giveplayerscore, ::giveplayerscore); // giveplayerscore set cdvar old_money for money animation
	replacefunc(maps\mp\gametypes\_rank::xpeventpopupfinalize, ::xpeventpopupfinalize); // money animation moveOverTime left_down
	replacefunc(maps\mp\gametypes\_rank::xppointspopup, ::xppointspopup); // money animation moveOverTime left_down
	
	level.onRespawnDelay = ::getRespawnDelay; // although it is not used, it is required to return a value to avoid errors
	level thread hook_callbacks(); // game callbacks split between _bots.gsc & _survivors.gsc
}

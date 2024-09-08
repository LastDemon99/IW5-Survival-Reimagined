main()
{
    maps\mp\gametypes\_globallogic::init();
    maps\mp\gametypes\_callbacksetup::setupcallbacks();
    maps\mp\gametypes\_globallogic::setupcallbacks();
    maps\mp\_utility::registerroundswitchdvar(level.gametype, 0, 0, 9);
	maps\mp\_utility::registertimelimitdvar(level.gametype, 10);
	maps\mp\_utility::registerscorelimitdvar(level.gametype, 500);
	maps\mp\_utility::registerroundlimitdvar(level.gametype, 1);
	maps\mp\_utility::registerwinlimitdvar(level.gametype, 1);
	maps\mp\_utility::registernumlivesdvar(level.gametype, 0);
	maps\mp\_utility::registerhalftimedvar(level.gametype, 0);

    level.matchrules_damagemultiplier = 0;
    level.matchrules_vampirism = 0;
    level.teambased = 1;
    level.onstartgametype = ::onstartgametype;
    level.getspawnpoint = ::getspawnpoint;
    level.onNormalDeath = ::onNormalDeath;

    lethalbeats\survival\_main::main();
}

onStartGametype()
{
    setclientnamemode("auto_change");

    game["switchedsides"] = 0;

    maps\mp\_utility::setobjectivetext("allies", &"SURVIVAL_OBJECTIVE");
    maps\mp\_utility::setobjectivetext("axis", &"OBJECTIVES_WAR");

    maps\mp\_utility::setobjectivescoretext("allies", &"SURVIVAL_OBJECTIVE");
	maps\mp\_utility::setobjectivescoretext("axis", &"OBJECTIVES_WAR_SCORE");

    maps\mp\_utility::setobjectivehinttext("allies", &"SURVIVAL_OBJECTIVE");
    maps\mp\_utility::setobjectivehinttext("axis", &"OBJECTIVES_WAR_HINT");
	
    level.spawnmins = (0, 0, 0);
    level.spawnmaxs = (0, 0, 0);
	
    maps\mp\gametypes\_spawnlogic::placespawnpoints("mp_tdm_spawn_allies_start");
    maps\mp\gametypes\_spawnlogic::placespawnpoints("mp_tdm_spawn_axis_start");
    maps\mp\gametypes\_spawnlogic::addspawnpoints("allies", "mp_tdm_spawn");
    maps\mp\gametypes\_spawnlogic::addspawnpoints("axis", "mp_tdm_spawn");
	
    level.mapcenter = maps\mp\gametypes\_spawnlogic::findboxcenter(level.spawnmins, level.spawnmaxs);
    setmapcenter(level.mapcenter);
	
    allowed[0] = level.gametype;
    allowed[1] = "airdrop_pallet";
	
    maps\mp\gametypes\_gameobjects::main(allowed);
    lethalbeats\survival\_main::init();
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

onNormalDeath(victim, attacker, lifeId)
{
	score = maps\mp\gametypes\_rank::getScoreInfoValue("kill");
	attacker maps\mp\gametypes\_gamescore::giveTeamScoreForObjective(attacker.pers["team"], score);
	
	if (game["state"] == "postgame" && game["teamScores"][attacker.team] > game["teamScores"][level.otherTeam[attacker.team]])
		attacker.finalKill = true;
}

blank(args) {}
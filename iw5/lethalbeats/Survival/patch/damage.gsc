#include maps\mp\gametypes\_damage;

playerKilled_internal(eInflictor, attacker, victim, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, isFauxDeath)
{
    victim endon("spawned");
    victim notify("killed_player");

    if (isdefined(attacker))
        attacker.assistedsuicide = undefined;

    if (!isdefined(victim.idflags))
    {
        if (sMeansOfDeath == "MOD_SUICIDE")
            victim.idflags = 0;
        else if (sMeansOfDeath == "MOD_GRENADE" && issubstr(sWeapon, "frag_grenade") && iDamage == 100000)
            victim.idflags = 0;
        else if (sWeapon == "nuke_mp")
            victim.idflags = 0;
        else if (level.friendlyfire >= 2)
            victim.idflags = 0;
    }

    if (victim.hasriotshieldequipped)
        victim launchShield(iDamage, sMeansOfDeath);

    if (!isFauxDeath)
    {
        if (isdefined(victim.endgame))
        {
            if (isdefined(level.nukedetonated))
                self visionsetnakedforplayer(level.nukevisionset, 2);
            else
                self visionsetnakedforplayer("", 2);
        }
        else
        {
            if (isdefined(level.nukedetonated))
                self visionsetnakedforplayer(level.nukevisionset, 0);
            else
                self visionsetnakedforplayer("", 0);

            victim thermalvisionoff();
        }
    }
    else
    {
        victim.fauxdead = 1;
        self notify("death");
    }

    if (game["state"] == "postgame")
        return;

    deathTimeOffset = 0;

    if (!isplayer(eInflictor) && isdefined(eInflictor.primaryweapon))
        sPrimaryWeapon = eInflictor.primaryweapon;
    else if (isdefined(attacker) && isplayer(attacker) && attacker getcurrentprimaryweapon() != "none")
        sPrimaryWeapon = attacker getcurrentprimaryweapon();
    else if (issubstr(sWeapon, "alt_"))
        sPrimaryWeapon = getsubstr(sWeapon, 4, sWeapon.size);
    else
        sPrimaryWeapon = undefined;

    if (isdefined(victim.uselaststandparams) || isdefined(victim.laststandparams) && sMeansOfDeath == "MOD_SUICIDE")
    {
        victim ensureLastStandParamsValidity();
        victim.uselaststandparams = undefined;
        eInflictor = victim.laststandparams.einflictor;
        attacker = victim.laststandparams.attacker;
        iDamage = victim.laststandparams.idamage;
        sMeansOfDeath = victim.laststandparams.smeansofdeath;
        sWeapon = victim.laststandparams.sweapon;
        sPrimaryWeapon = victim.laststandparams.sprimaryweapon;
        vDir = victim.laststandparams.vdir;
        sHitLoc = victim.laststandparams.shitloc;
        deathTimeOffset = (gettime() - victim.laststandparams.laststandstarttime) / 1000;
        victim.laststandparams = undefined;
    }

    if ((!isdefined(attacker) || attacker.classname == "trigger_hurt" || attacker.classname == "worldspawn" || attacker == victim) && isdefined(self.attackers))
    {
        bestPlayer = undefined;

        foreach (player in self.attackers)
        {
            if (!isdefined(player))
                continue;

            if (!isdefined(victim.attackerdata[player.guid].damage))
                continue;

            if (player == victim || level.teambased && player.team == victim.team)
                continue;

            if (victim.attackerdata[player.guid].lasttimedamaged + 2500 < gettime() && (attacker != victim && (isdefined(victim.laststand) && victim.laststand)))
                continue;

            if (victim.attackerdata[player.guid].damage > 1 && !isdefined(bestPlayer))
            {
                bestPlayer = player;
                continue;
            }

            if (isdefined(bestPlayer) && victim.attackerdata[player.guid].damage > victim.attackerdata[bestPlayer.guid].damage)
                bestPlayer = player;
        }

        if (isdefined(bestPlayer))
        {
            attacker = bestPlayer;
            attacker.assistedsuicide = 1;
            sWeapon = victim.attackerdata[bestPlayer.guid].weapon;
            vDir = victim.attackerdata[bestPlayer.guid].vdir;
            sHitLoc = victim.attackerdata[bestPlayer.guid].shitloc;
            psOffsetTime = victim.attackerdata[bestPlayer.guid].psoffsettime;
            sMeansOfDeath = victim.attackerdata[bestPlayer.guid].smeansofdeath;
            iDamage = victim.attackerdata[bestPlayer.guid].damage;
            sPrimaryWeapon = victim.attackerdata[bestPlayer.guid].sprimaryweapon;
            eInflictor = attacker;
        }
    }
    else if (isdefined(attacker))
        attacker.assistedsuicide = undefined;

    if (isHeadShot(sWeapon, sHitLoc, sMeansOfDeath, attacker))
        sMeansOfDeath = "MOD_HEAD_SHOT";
    else if (sMeansOfDeath != "MOD_MELEE" && !isdefined(victim.nuked))
        victim maps\mp\_utility::playDeathSound();

    friendlyFire = isFriendlyFire(victim, attacker);

    if (isdefined(attacker))
    {
        if (attacker.code_classname == "script_vehicle" && isdefined(attacker.owner))
            attacker = attacker.owner;

        if (attacker.code_classname == "misc_turret" && isdefined(attacker.owner))
        {
            if (isdefined(attacker.vehicle))
                attacker.vehicle notify("killedPlayer", victim);

            attacker = attacker.owner;
        }

        if (attacker.code_classname == "script_model" && isdefined(attacker.owner))
        {
            attacker = attacker.owner;

            if (!isFriendlyFire(victim, attacker) && attacker != victim)
                attacker notify("crushed_enemy");
        }
    }

    victim maps\mp\gametypes\_weapons::dropScavengerForDeath(attacker);
    victim maps\mp\gametypes\_weapons::dropWeaponForDeath(attacker);

    if (!isFauxDeath)
    {
        victim.sessionstate = "dead";
        victim.statusicon = "hud_status_dead";
    }

    victim maps\mp\gametypes\_playerlogic::removeFromAliveCount();

    if (!isdefined(victim.switching_teams))
    {
        victim maps\mp\_utility::incPersStat("deaths", 1);
        victim.deaths = victim maps\mp\_utility::getPersStat("deaths");
        victim maps\mp\_utility::updatePersRatio("kdRatio", "kills", "deaths");
        victim maps\mp\gametypes\_persistence::statSetChild("round", "deaths", victim.deaths);
        victim maps\mp\_utility::incPlayerStat("deaths", 1);
    }

    if (isdefined(attacker) && isplayer(attacker))
        attacker checkKillSteal(victim);

    doKillcam = 0;
    lifeId = maps\mp\_utility::getNextLifeId();

    if (sMeansOfDeath == "MOD_MELEE")
    {
        if (issubstr(sWeapon, "riotshield"))
        {
            attacker maps\mp\_utility::incPlayerStat("shieldkills", 1);

            if (!maps\mp\_utility::matchMakingGame())
                victim maps\mp\_utility::incPlayerStat("shielddeaths", 1);
        }
        else
            attacker maps\mp\_utility::incPlayerStat("knifekills", 1);
    }

    if (victim isSwitchingTeams())
        handleTeamChangeDeath();
    else if (!isplayer(attacker) || isplayer(attacker) && sMeansOfDeath == "MOD_FALLING")
        handleWorldDeath(attacker, lifeId, sMeansOfDeath, sHitLoc);
    else if (attacker == victim)
        handleSuicideDeath(sMeansOfDeath, sHitLoc);
    else if (friendlyFire)
    {
        if (!isdefined(victim.nuked))
            handleFriendlyFireDeath(attacker);
    }
    else
    {
        if (sMeansOfDeath == "MOD_GRENADE" && eInflictor == attacker)
            addAttacker(victim, attacker, eInflictor, sWeapon, iDamage, (0.0, 0.0, 0.0), vDir, sHitLoc, psOffsetTime, sMeansOfDeath);

        doKillcam = 1;
        handleNormalDeath(lifeId, attacker, eInflictor, sWeapon, sMeansOfDeath);
        victim thread maps\mp\gametypes\_missions::playerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, sPrimaryWeapon, sHitLoc, attacker.modifiers);
        victim.pers["cur_death_streak"]++;

        if (!maps\mp\_utility::getGametypeNumLives() && !maps\mp\_utility::matchMakingGame())
            victim maps\mp\_utility::setPlayerStatIfGreater("deathstreak", victim.pers["cur_death_streak"]);

        if (isplayer(attacker) && victim maps\mp\_utility::isJuggernaut())
            attacker thread maps\mp\_utility::teamPlayerCardSplash("callout_killed_juggernaut", attacker);
    }

    wasInLastStand = 0;
    lastWeaponBeforeDroppingIntoLastStand = undefined;

    if (isdefined(self.previousprimary))
    {
        wasInLastStand = 1;
        lastWeaponBeforeDroppingIntoLastStand = self.previousprimary;
        self.previousprimary = undefined;
    }

    if (isplayer(attacker) && attacker != self && (!level.teambased || level.teambased && self.team != attacker.team))
    {
        if (wasInLastStand && isdefined(lastWeaponBeforeDroppingIntoLastStand))
            weaponName = lastWeaponBeforeDroppingIntoLastStand;
        else
            weaponName = self.lastdroppableweapon;

        thread maps\mp\gametypes\_gamelogic::trackLeaderBoardDeathStats(weaponName, sMeansOfDeath);
        attacker thread maps\mp\gametypes\_gamelogic::trackAttackerLeaderBoardDeathStats(sWeapon, sMeansOfDeath);
    }

    victim resetPlayerVariables();
    victim.lastattacker = attacker;
    victim.lastdeathpos = victim.origin;
    victim.deathtime = gettime();
    victim.wantsafespawn = 0;
    victim.revived = 0;
    victim.sameshotdamage = 0;

    if (maps\mp\killstreaks\_killstreaks::streaktyperesetsondeath(victim.streaktype))
        victim maps\mp\killstreaks\_killstreaks::resetadrenaline();

    if (isFauxDeath)
    {
        doKillcam = 0;
        deathAnimDuration = victim playerforcedeathanim(eInflictor, sMeansOfDeath, sWeapon, sHitLoc, vDir);
    }

	if (level.wave_num) victim.body = victim cloneplayer(deathAnimDuration);

    if (isFauxDeath)
        victim playerhide();

	if (level.wave_num)
	{
		if (victim isonladder() || victim ismantling() || !victim isonground() || isdefined(victim.nuked))
			victim.body startragdoll();

		if (!isdefined(victim.switching_teams))
			thread maps\mp\gametypes\_deathicons::addDeathIcon(victim.body, victim, victim.team, 5.0);

		thread delayStartRagdoll(victim.body, sHitLoc, vDir, sWeapon, eInflictor, sMeansOfDeath);
	}
	
    victim thread [[level.onplayerkilled]](eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, lifeId);

    if (isplayer(attacker))
        attackerNum = attacker getentitynumber();
    else
        attackerNum = -1;

    killcamentity = victim getKillcamEntity(attacker, eInflictor, sWeapon);
    killcamentityindex = -1;
    killcamentitystarttime = 0;

    if (isdefined(killcamentity))
    {
        killcamentityindex = killcamentity getentitynumber();
        killcamentitystarttime = killcamentity.birthtime;

        if (!isdefined(killcamentitystarttime))
            killcamentitystarttime = 0;
    }

    if (sMeansOfDeath != "MOD_SUICIDE" && !(!isdefined(attacker) || attacker.classname == "trigger_hurt" || attacker.classname == "worldspawn" || attacker == victim))
        recordFinalKillCam(5.0, victim, attacker, attackerNum, killcamentityindex, killcamentitystarttime, sWeapon, deathTimeOffset, psOffsetTime);

    victim setplayerdata("killCamHowKilled", 0);

    switch (sMeansOfDeath)
    {
        case "MOD_HEAD_SHOT":
            victim setplayerdata("killCamHowKilled", 1);
            break;
        default:
            break;
    }

    if (!isFauxDeath)
    {
        if (!level.showingfinalkillcam && !level.killcam && doKillcam)
        {
            if (victim maps\mp\_utility::_hasPerk("specialty_copycat") && isdefined(victim.pers["copyCatLoadout"]))
            {
                victim thread maps\mp\gametypes\_killcam::waitDeathCopyCatButton(attacker);
                wait 1.0;
            }
        }

        wait 0.25;
        victim thread maps\mp\gametypes\_killcam::cancelKillCamOnUse();
        wait 0.25;
        self.respawntimerstarttime = gettime() + 1000;
        timeUntilSpawn = maps\mp\gametypes\_playerlogic::timeUntilSpawn(1);

        if (timeUntilSpawn < 1)
            timeUntilSpawn = 1;

        victim thread maps\mp\gametypes\_playerlogic::predictAboutToSpawnPlayerOverTime(timeUntilSpawn);
        wait 1.0;
        victim notify("death_delay_finished");
    }

    postDeathDelay = (gettime() - victim.deathtime) / 1000;
    self.respawntimerstarttime = gettime();

    if (!(isdefined(victim.cancelkillcam) && victim.cancelkillcam) && doKillcam && level.killcam && game["state"] == "playing" && !victim maps\mp\_utility::isUsingRemote() && !level.showingfinalkillcam)
    {
        livesLeft = !(maps\mp\_utility::getGametypeNumLives() && !victim.pers["lives"]);
        timeUntilSpawn = maps\mp\gametypes\_playerlogic::timeUntilSpawn(1);
        willRespawnImmediately = livesLeft && timeUntilSpawn <= 0;

        if (!livesLeft)
        {
            timeUntilSpawn = -1;
            level notify("player_eliminated", victim);
        }

        victim maps\mp\gametypes\_killcam::killcam(attackerNum, killcamentityindex, killcamentitystarttime, sWeapon, postDeathDelay + deathTimeOffset, psOffsetTime, timeUntilSpawn, maps\mp\gametypes\_gamelogic::timeUntilRoundEnd(), attacker, victim);
    }

    if (game["state"] != "playing")
    {
        if (!level.showingfinalkillcam)
        {
            victim.sessionstate = "dead";
            victim maps\mp\_utility::clearKillcamState();
        }

        return;
    }

    if (maps\mp\_utility::isValidClass(victim.class))
        victim thread maps\mp\gametypes\_playerlogic::spawnClient();
}

handleNormalDeath(lifeId, attacker, eInflictor, sWeapon, sMeansOfDeath)
{
    attacker thread maps\mp\_events::killedPlayer(lifeId, self, sWeapon, sMeansOfDeath);
    attacker setcarddisplayslot(self, 8);
    self setcarddisplayslot(attacker, 7);

    if (sMeansOfDeath == "MOD_HEAD_SHOT")
    {
        attacker maps\mp\_utility::incPersStat("headshots", 1);
        attacker.headshots = attacker maps\mp\_utility::getPersStat("headshots");
        attacker maps\mp\_utility::incPlayerStat("headshots", 1);
        value = isdefined(attacker.laststand) ? maps\mp\gametypes\_rank::getScoreInfoValue("kill") * 2 : undefined;
        attacker playlocalsound("bullet_impact_headshot_2");
    }
    else if (isdefined(attacker.laststand)) value = maps\mp\gametypes\_rank::getScoreInfoValue("kill") * 2;
    else value = undefined;

    attacker thread maps\mp\gametypes\_rank::giveRankXP("kill", value, sWeapon, sMeansOfDeath);
    attacker maps\mp\_utility::incPersStat("kills", 1);
    attacker.kills = attacker maps\mp\_utility::getPersStat("kills");
    attacker maps\mp\_utility::updatePersRatio("kdRatio", "kills", "deaths");
    attacker maps\mp\gametypes\_persistence::statSetChild("round", "kills", attacker.kills);
    attacker maps\mp\_utility::incPlayerStat("kills", 1);

    if (isFlankKill(self, attacker))
    {
        attacker maps\mp\_utility::incPlayerStat("flankkills", 1);
        maps\mp\_utility::incPlayerStat("flankdeaths", 1);
    }

    lastKillStreak = attacker.pers["cur_kill_streak"];
    self.pers["copyCatLoadout"] = undefined;

    if (maps\mp\_utility::_hasPerk("specialty_copycat"))
        self.pers["copyCatLoadout"] = attacker maps\mp\gametypes\_class::cloneLoadout();

    if (isalive(attacker) || attacker.streaktype == "support")
    {
        if (attacker maps\mp\_utility::killShouldAddToKillstreak(sWeapon))
        {
            attacker thread maps\mp\killstreaks\_killstreaks::giveadrenaline("kill");
            attacker.pers["cur_kill_streak"]++;
        }

        attacker maps\mp\_utility::setPlayerStatIfGreater("killstreak", attacker.pers["cur_kill_streak"]);

        if (attacker.pers["cur_kill_streak"] > attacker maps\mp\_utility::getPersStat("longestStreak"))
            attacker maps\mp\_utility::setPersStat("longestStreak", attacker.pers["cur_kill_streak"]);
    }

    attacker.pers["cur_death_streak"] = 0;

    if (attacker.pers["cur_kill_streak"] > attacker maps\mp\gametypes\_persistence::statGetChild("round", "killStreak"))
        attacker maps\mp\gametypes\_persistence::statSetChild("round", "killStreak", attacker.pers["cur_kill_streak"]);

    if (attacker.pers["cur_kill_streak"] > attacker.kill_streak)
    {
        attacker maps\mp\gametypes\_persistence::statSet("killStreak", attacker.pers["cur_kill_streak"]);
        attacker.kill_streak = attacker.pers["cur_kill_streak"];
    }

    maps\mp\gametypes\_gamescore::givePlayerScore("kill", attacker, self);
    maps\mp\_skill::processKill(attacker, self);
    scoreSub = maps\mp\gametypes\_tweakables::getTweakableValue("game", "deathpointloss");
    maps\mp\gametypes\_gamescore::_getPlayerScore(self, maps\mp\gametypes\_gamescore::_setPlayerScore(self) - scoreSub);

    if (isdefined(level.ac130player) && level.ac130player == attacker)
        level notify("ai_killed", self);

    level notify("player_got_killstreak_" + attacker.pers["cur_kill_streak"], attacker);
    attacker notify("got_killstreak", attacker.pers["cur_kill_streak"]);
    attacker notify("killed_enemy");

    if (isdefined(self.uavremotemarkedby))
    {
        if (self.uavremotemarkedby != attacker)
            self.uavremotemarkedby thread maps\mp\killstreaks\_remoteuav::remoteuav_processtaggedassist(self);

        self.uavremotemarkedby = undefined;
    }

    if (isdefined(level.onnormaldeath) && attacker.pers["team"] != "spectator")
        [[level.onnormaldeath]](self, attacker, lifeId);

    if (!level.teambased)
    {
        self.attackers = [];
        return;
    }

    level thread maps\mp\gametypes\_battlechatter_mp::sayLocalSoundDelayed(attacker, "kill", 0.75);

    if (isdefined(self.lastattackedshieldplayer) && isdefined(self.lastattackedshieldtime) && self.lastattackedshieldplayer != attacker)
    {
        if (gettime() - self.lastattackedshieldtime < 2500)
        {
            self.lastattackedshieldplayer thread maps\mp\gametypes\_gamescore::processShieldAssist(self);

            if (self.lastattackedshieldplayer maps\mp\_utility::_hasPerk("specialty_assists"))
            {
                self.lastattackedshieldplayer.pers["assistsToKill"]++;

                if (!(self.lastattackedshieldplayer.pers["assistsToKill"] % 2))
                {
                    self.lastattackedshieldplayer maps\mp\gametypes\_missions::processChallenge("ch_hardlineassists");
                    self.lastattackedshieldplayer maps\mp\killstreaks\_killstreaks::giveadrenaline("kill");
                    self.lastattackedshieldplayer.pers["cur_kill_streak"]++;
                }
            }
            else
                self.lastattackedshieldplayer.pers["assistsToKill"] = 0;
        }
        else if (isalive(self.lastattackedshieldplayer) && gettime() - self.lastattackedshieldtime < 5000)
        {
            forwardVec = vectornormalize(anglestoforward(self.angles));
            shieldVec = vectornormalize(self.lastattackedshieldplayer.origin - self.origin);

            if (vectordot(shieldVec, forwardVec) > 0.925)
            {
                self.lastattackedshieldplayer thread maps\mp\gametypes\_gamescore::processShieldAssist(self);

                if (self.lastattackedshieldplayer maps\mp\_utility::_hasPerk("specialty_assists"))
                {
                    self.lastattackedshieldplayer.pers["assistsToKill"]++;

                    if (!(self.lastattackedshieldplayer.pers["assistsToKill"] % 2))
                    {
                        self.lastattackedshieldplayer maps\mp\gametypes\_missions::processChallenge("ch_hardlineassists");
                        self.lastattackedshieldplayer maps\mp\killstreaks\_killstreaks::giveadrenaline("kill");
                        self.lastattackedshieldplayer.pers["cur_kill_streak"]++;
                    }
                }
                else
                    self.lastattackedshieldplayer.pers["assistsToKill"] = 0;
            }
        }
    }

    if (isdefined(self.attackers))
    {
        foreach (player in self.attackers)
        {
            if (!isdefined(player))
                continue;

            if (player == attacker)
                continue;

            player thread maps\mp\gametypes\_gamescore::processAssist(self);

            if (player maps\mp\_utility::_hasPerk("specialty_assists"))
            {
                player.pers["assistsToKill"]++;

                if (!(player.pers["assistsToKill"] % 2))
                {
                    player maps\mp\gametypes\_missions::processChallenge("ch_hardlineassists");
                    player maps\mp\killstreaks\_killstreaks::giveadrenaline("kill");
                    player.pers["cur_kill_streak"]++;
                }

                continue;
            }

            player.pers["assistsToKill"] = 0;
        }

        self.attackers = [];
    }
}

handleSuicideDeath(sMeansOfDeath, sHitLoc)
{
    self setcarddisplayslot(self, 7);
    self thread [[level.onxpevent]]("suicide");
    maps\mp\_utility::incPersStat("suicides", 1);
    self.suicides = maps\mp\_utility::getPersStat("suicides");

    if (!maps\mp\_utility::matchMakingGame())
        maps\mp\_utility::incPlayerStat("suicides", 1);

    scoreSub = maps\mp\gametypes\_tweakables::getTweakableValue("game", "suicidepointloss");
    maps\mp\gametypes\_gamescore::_getPlayerScore(self, maps\mp\gametypes\_gamescore::_setPlayerScore(self) - scoreSub);

    if (sMeansOfDeath == "MOD_SUICIDE" && sHitLoc == "none" && isdefined(self.throwinggrenade))
        self.lastgrenadesuicidetime = gettime();

    if (isdefined(self.friendlydamage))
        self iprintlnbold(&"MP_FRIENDLY_FIRE_WILL_NOT");
}

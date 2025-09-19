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

callback_playerDamage_internal( eInflictor, eAttacker, victim, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime )
{
    if ( !maps\mp\_utility::isReallyAlive( victim ) )
        return;

    if ( isdefined( eAttacker ) && eAttacker.classname == "script_origin" && isdefined( eAttacker.type ) && eAttacker.type == "soft_landing" )
        return;

    if ( sWeapon == "killstreak_emp_mp" )
        return;

    if ( sWeapon == "bouncingbetty_mp" && !maps\mp\gametypes\_weapons::mineDamageHeightPassed( eInflictor, victim ) )
        return;

    if ( sWeapon == "bouncingbetty_mp" && ( victim getstance() == "crouch" || victim getstance() == "prone" ) )
        iDamage = int( iDamage / 2 );

    if ( sWeapon == "xm25_mp" && sMeansOfDeath == "MOD_IMPACT" )
        iDamage = 95;

    if ( sWeapon == "emp_grenade_mp" && sMeansOfDeath != "MOD_IMPACT" )
        victim notify( "emp_grenaded", eAttacker );

    if ( isdefined( level.hostmigrationtimer ) )
        return;

    if ( sMeansOfDeath == "MOD_FALLING" )
        victim thread emitFallDamage( iDamage );

    if ( sMeansOfDeath == "MOD_EXPLOSIVE_BULLET" && iDamage != 1 )
    {
        iDamage = iDamage * getdvarfloat( "scr_explBulletMod" );
        iDamage = int( iDamage );
    }

    if ( isdefined( eAttacker ) && eAttacker.classname == "worldspawn" )
        eAttacker = undefined;

    if ( isdefined( eAttacker ) && isdefined( eAttacker.gunner ) )
        eAttacker = eAttacker.gunner;

    attackerIsNPC = isdefined( eAttacker ) && !isdefined( eAttacker.gunner ) && ( eAttacker.classname == "script_vehicle" || eAttacker.classname == "misc_turret" || eAttacker.classname == "script_model" );
    attackerIsHittingTeammate = level.teambased && isdefined( eAttacker ) && victim != eAttacker && isdefined( eAttacker.team ) && ( victim.pers["team"] == eAttacker.team || isdefined( eAttacker.teamchangedthisframe ) );
    attackerIsInflictorVictim = isdefined( eAttacker ) && isdefined( eInflictor ) && isdefined( victim ) && isplayer( eAttacker ) && eAttacker == eInflictor && eAttacker == victim;

    if ( attackerIsInflictorVictim )
        return;

    stunFraction = 0.0;

    if ( iDFlags & level.idflags_stun )
    {
        stunFraction = 0.0;
        iDamage = 0.0;
    }
    else if ( sHitLoc == "shield" )
    {
        if ( attackerIsHittingTeammate && level.friendlyfire == 0 )
            return;

        if ( sMeansOfDeath == "MOD_PISTOL_BULLET" || sMeansOfDeath == "MOD_RIFLE_BULLET" || sMeansOfDeath == "MOD_EXPLOSIVE_BULLET" && !attackerIsHittingTeammate )
        {
            if ( isplayer( eAttacker ) )
            {
                eAttacker.lastattackedshieldplayer = victim;
                eAttacker.lastattackedshieldtime = gettime();
            }

            victim notify( "shield_blocked" );

            if ( maps\mp\_utility::isEnvironmentWeapon( sWeapon ) )
                shieldDamage = 25;
            else
                shieldDamage = maps\mp\perks\_perks::cac_modified_damage( victim, eAttacker, iDamage, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc );

            victim.shielddamage = victim.shielddamage + shieldDamage;

            if ( !maps\mp\_utility::isEnvironmentWeapon( sWeapon ) || common_scripts\utility::coinToss() )
                victim.shieldbullethits++;

            if ( victim.shieldbullethits >= level.riotshieldxpbullets )
            {
                if ( self.recentshieldxp > 4 )
                    xpVal = int( 50 / self.recentshieldxp );
                else
                    xpVal = 50;

                victim thread maps\mp\gametypes\_rank::giveRankXP( "shield_damage", xpVal );
                victim thread giveRecentShieldXP();
                victim thread maps\mp\gametypes\_missions::genericChallenge( "shield_damage", victim.shielddamage );
                victim thread maps\mp\gametypes\_missions::genericChallenge( "shield_bullet_hits", victim.shieldbullethits );
                victim.shielddamage = 0;
                victim.shieldbullethits = 0;
            }
        }

        if ( iDFlags & level.idflags_shield_explosive_impact )
        {
            if ( !attackerIsHittingTeammate )
                victim thread maps\mp\gametypes\_missions::genericChallenge( "shield_explosive_hits", 1 );

            sHitLoc = "none";

            if ( !( iDFlags & level.idflags_shield_explosive_impact_huge ) )
                iDamage = iDamage * 0.0;
        }
        else if ( iDFlags & level.idflags_shield_explosive_splash )
        {
            if ( isdefined( eInflictor ) && isdefined( eInflictor.stuckenemyentity ) && eInflictor.stuckenemyentity == victim )
                iDamage = 151;

            victim thread maps\mp\gametypes\_missions::genericChallenge( "shield_explosive_hits", 1 );
            sHitLoc = "none";
        }
        else
            return;
    }
    else if ( sMeansOfDeath == "MOD_MELEE" && issubstr( sWeapon, "riotshield" ) )
    {
        if ( !( attackerIsHittingTeammate && level.friendlyfire == 0 ) )
        {
            stunFraction = 0.0;
            victim stunplayer( 0.0 );
        }
    }

    if ( isdefined( eInflictor ) && isdefined( eInflictor.stuckenemyentity ) && eInflictor.stuckenemyentity == victim )
        iDamage = 151;

    if ( !attackerIsHittingTeammate )
        iDamage = maps\mp\perks\_perks::cac_modified_damage( victim, eAttacker, iDamage, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc );

    if ( isdefined( level.modifyplayerdamage ) )
        iDamage = [[ level.modifyplayerdamage ]]( victim, eAttacker, iDamage, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc );

    if ( !iDamage )
        return 0;

    victim.idflags = iDFlags;
    victim.idflagstime = gettime();

    if ( game["state"] == "postgame" )
        return;

    if ( victim.sessionteam == "spectator" )
        return;

    if ( isdefined( victim.candocombat ) && !victim.candocombat )
        return;

    if ( isdefined( eAttacker ) && isplayer( eAttacker ) && isdefined( eAttacker.candocombat ) && !eAttacker.candocombat )
        return;

    if ( attackerIsNPC && attackerIsHittingTeammate )
    {
        if ( sMeansOfDeath == "MOD_CRUSH" )
        {
            victim maps\mp\_utility::_suicide();
            return;
        }

        if ( !level.friendlyfire )
            return;
    }

    if ( !isdefined( vDir ) )
        iDFlags = iDFlags | level.idflags_no_knockback;

    friendly = 0;

    if ( victim.health == victim.maxhealth && ( !isdefined( victim.laststand ) || !victim.laststand ) || !isdefined( victim.attackers ) && !isdefined( victim.laststand ) )
    {
        victim.attackers = [];
        victim.attackerdata = [];
    }

    if ( isHeadShot( sWeapon, sHitLoc, sMeansOfDeath, eAttacker ) )
        sMeansOfDeath = "MOD_HEAD_SHOT";

    if ( maps\mp\gametypes\_tweakables::getTweakableValue( "game", "onlyheadshots" ) )
    {
        if ( sMeansOfDeath == "MOD_PISTOL_BULLET" || sMeansOfDeath == "MOD_RIFLE_BULLET" || sMeansOfDeath == "MOD_EXPLOSIVE_BULLET" )
            return;
        else if ( sMeansOfDeath == "MOD_HEAD_SHOT" )
        {
            if ( victim maps\mp\_utility::isJuggernaut() )
                iDamage = 75;
            else
                iDamage = 150;
        }
    }

    if ( sWeapon == "none" && isdefined( eInflictor ) )
    {
        if ( isdefined( eInflictor.destructible_type ) && issubstr( eInflictor.destructible_type, "vehicle_" ) )
            sWeapon = "destructible_car";
    }

    if ( gettime() < victim.spawntime + level.killstreakspawnshield )
    {
        damageLimit = int( max( victim.health / 4, 1 ) );

        if ( iDamage >= damageLimit && maps\mp\_utility::isKillstreakWeapon( sWeapon ) )
            iDamage = damageLimit;
    }

    if ( !( iDFlags & level.idflags_no_protection ) )
    {
        if ( !level.teambased && attackerIsNPC && isdefined( eAttacker.owner ) && eAttacker.owner == victim )
        {
            if ( sMeansOfDeath == "MOD_CRUSH" )
                victim maps\mp\_utility::_suicide();

            return;
        }

        if ( ( issubstr( sMeansOfDeath, "MOD_GRENADE" ) || issubstr( sMeansOfDeath, "MOD_EXPLOSIVE" ) || issubstr( sMeansOfDeath, "MOD_PROJECTILE" ) ) && isdefined( eInflictor ) && isdefined( eAttacker ) )
        {
            if ( victim != eAttacker && eInflictor.classname == "grenade" && victim.lastspawntime + 3500 > gettime() && isdefined( victim.lastspawnpoint ) && distanceSquared( eInflictor.origin, victim.lastspawnpoint.origin ) < (250 * 250) )
                return;

            victim.explosiveinfo = [];
            victim.explosiveinfo["damageTime"] = gettime();
            victim.explosiveinfo["damageId"] = eInflictor getentitynumber();
            victim.explosiveinfo["returnToSender"] = 0;
            victim.explosiveinfo["counterKill"] = 0;
            victim.explosiveinfo["chainKill"] = 0;
            victim.explosiveinfo["cookedKill"] = 0;
            victim.explosiveinfo["throwbackKill"] = 0;
            victim.explosiveinfo["suicideGrenadeKill"] = 0;
            victim.explosiveinfo["weapon"] = sWeapon;
            isFrag = issubstr( sWeapon, "frag_" );

            if ( eAttacker != victim )
            {
                if ( ( issubstr( sWeapon, "c4_" ) || issubstr( sWeapon, "claymore_" ) ) && isdefined( eAttacker ) && isdefined( eInflictor.owner ) )
                {
                    victim.explosiveinfo["returnToSender"] = eInflictor.owner == victim;
                    victim.explosiveinfo["counterKill"] = isdefined( eInflictor.wasdamaged );
                    victim.explosiveinfo["chainKill"] = isdefined( eInflictor.waschained );
                    victim.explosiveinfo["bulletPenetrationKill"] = isdefined( eInflictor.wasdamagedfrombulletpenetration );
                    victim.explosiveinfo["cookedKill"] = 0;
                }

                if ( isdefined( eAttacker.lastgrenadesuicidetime ) && eAttacker.lastgrenadesuicidetime >= gettime() - 50 && isFrag )
                    victim.explosiveinfo["suicideGrenadeKill"] = 1;
            }

            if ( isFrag )
            {
                victim.explosiveinfo["cookedKill"] = isdefined( eInflictor.iscooked );
                victim.explosiveinfo["throwbackKill"] = isdefined( eInflictor.threwback );
            }

            victim.explosiveinfo["stickKill"] = isdefined( eInflictor.isstuck ) && eInflictor.isstuck == "enemy";
            victim.explosiveinfo["stickFriendlyKill"] = isdefined( eInflictor.isstuck ) && eInflictor.isstuck == "friendly";

            if ( isplayer( eAttacker ) && eAttacker != self )
                maps\mp\gametypes\_gamelogic::setInflictorStat( eInflictor, eAttacker, sWeapon );
        }

        if ( issubstr( sMeansOfDeath, "MOD_IMPACT" ) && ( sWeapon == "m320_mp" || issubstr( sWeapon, "gl" ) || issubstr( sWeapon, "gp25" ) || sWeapon == "xm25_mp" ) )
        {
            if ( isplayer( eAttacker ) && eAttacker != self )
                maps\mp\gametypes\_gamelogic::setInflictorStat( eInflictor, eAttacker, sWeapon );
        }

        if ( isplayer( eAttacker ) && isdefined( eAttacker.pers["participation"] ) )
            eAttacker.pers["participation"]++;
        else if ( isplayer( eAttacker ) )
            eAttacker.pers["participation"] = 1;

        prevHealthRatio = victim.health / victim.maxhealth;

        if ( attackerIsHittingTeammate )
        {
            if ( !maps\mp\_utility::matchMakingGame() && isplayer( eAttacker ) )
                eAttacker maps\mp\_utility::incPlayerStat( "mostff", 1 );

            if ( level.friendlyfire == 0 || !isplayer( eAttacker ) && level.friendlyfire != 1 )
            {
                if ( sWeapon == "artillery_mp" || sWeapon == "stealth_bomb_mp" )
                    victim damageShellshockAndRumble( eInflictor, sWeapon, sMeansOfDeath, iDamage, iDFlags, eAttacker );

                return;
            }
            else if ( level.friendlyfire == 1 )
            {
                if ( iDamage < 1 )
                    iDamage = 1;

                if ( victim maps\mp\_utility::isJuggernaut() )
                    iDamage = maps\mp\perks\_perks::cac_modified_damage( victim, eAttacker, iDamage, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc );

                victim.lastdamagewasfromenemy = 0;
                victim finishPlayerDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, stunFraction );
            }
            else if ( level.friendlyfire == 2 && maps\mp\_utility::isReallyAlive( eAttacker ) )
            {
                iDamage = int( iDamage * 0.5 );

                if ( iDamage < 1 )
                    iDamage = 1;

                eAttacker.lastdamagewasfromenemy = 0;
                eAttacker.friendlydamage = 1;
                eAttacker finishPlayerDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, stunFraction );
                eAttacker.friendlydamage = undefined;
            }
            else if ( level.friendlyfire == 3 && maps\mp\_utility::isReallyAlive( eAttacker ) )
            {
                iDamage = int( iDamage * 0.5 );

                if ( iDamage < 1 )
                    iDamage = 1;

                victim.lastdamagewasfromenemy = 0;
                eAttacker.lastdamagewasfromenemy = 0;
                victim finishPlayerDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, stunFraction );

                if ( maps\mp\_utility::isReallyAlive( eAttacker ) )
                {
                    eAttacker.friendlydamage = 1;
                    eAttacker finishPlayerDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, stunFraction );
                    eAttacker.friendlydamage = undefined;
                }
            }

            friendly = 1;
        }
        else
        {
            if ( iDamage < 1 )
                iDamage = 1;

            if ( isdefined( eAttacker ) && isplayer( eAttacker ) )
                addAttacker( victim, eAttacker, eInflictor, sWeapon, iDamage, vPoint, vDir, sHitLoc, psOffsetTime, sMeansOfDeath );

            if ( sMeansOfDeath == "MOD_EXPLOSIVE" || sMeansOfDeath == "MOD_GRENADE_SPLASH" && iDamage < victim.health )
                victim notify( "survived_explosion", eAttacker );

            if ( isdefined( eAttacker ) )
                level.lastlegitimateattacker = eAttacker;

            if ( isdefined( eAttacker ) && isplayer( eAttacker ) && isdefined( sWeapon ) )
                eAttacker thread maps\mp\gametypes\_weapons::checkHit( sWeapon, victim );

            if ( isdefined( eAttacker ) && isplayer( eAttacker ) && isdefined( sWeapon ) && eAttacker != victim )
            {
                eAttacker thread maps\mp\_events::damagedPlayer( self, iDamage, sWeapon );
                victim.attackerposition = eAttacker.origin;
            }
            else
                victim.attackerposition = undefined;

            if ( issubstr( sMeansOfDeath, "MOD_GRENADE" ) && isdefined( eInflictor.iscooked ) )
                victim.wascooked = gettime();
            else
                victim.wascooked = undefined;

            victim.lastdamagewasfromenemy = isdefined( eAttacker ) && eAttacker != victim;

            if ( victim.lastdamagewasfromenemy )
                eAttacker.damagedplayers[victim.guid] = gettime();

            victim finishPlayerDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, stunFraction );

            if ( isdefined( level.ac130player ) && isdefined( eAttacker ) && level.ac130player == eAttacker )
                level notify( "ai_pain", victim );

            victim thread maps\mp\gametypes\_missions::playerDamaged( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, sHitLoc );
        }

        if ( attackerIsNPC && isdefined( eAttacker.gunner ) )
            damager = eAttacker.gunner;
        else
            damager = eAttacker;

        if ( isdefined( damager ) && damager != victim && iDamage > 0 && ( !isdefined( sHitLoc ) || sHitLoc != "shield" ) )
        {
            if ( iDFlags & level.idflags_stun )
                typeHit = "stun";
            else if ( isexplosivedamagemod( sMeansOfDeath ) && victim maps\mp\_utility::_hasPerk( "_specialty_blastshield" ) )
                typeHit = "hitBodyArmor";
            else if ( victim maps\mp\_utility::_hasPerk( "specialty_combathigh" ) )
                typeHit = "hitEndGame";
            else if ( isdefined( victim.haslightarmor ) )
                typeHit = "hitLightArmor";
            else if ( victim maps\mp\_utility::isJuggernaut() )
                typeHit = "hitJuggernaut";
            else if ( !shouldWeaponFeedback( sWeapon ) )
                typeHit = "none";
            else
                typeHit = "standard";

            damager thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback( typeHit );
        }

        maps\mp\gametypes\_gamelogic::setHasDoneCombat( victim, 1 );
    }

    if ( isdefined( eAttacker ) && eAttacker != victim && !friendly )
        level.usestartspawn = 0;

    if ( iDamage > 0 && isdefined( eAttacker ) && !victim maps\mp\_utility::isUsingRemote() )
        victim thread maps\mp\gametypes\_shellshock::bloodEffect( eAttacker.origin );

    if ( victim.sessionstate != "dead" )
    {
        lpselfnum = victim getentitynumber();
        lpselfname = victim.name;
        lpselfteam = victim.pers["team"];
        lpselfGuid = victim.guid;
        lpattackerteam = "";

        if ( isplayer( eAttacker ) )
        {
            lpattacknum = eAttacker getentitynumber();
            lpattackGuid = eAttacker.guid;
            lpattackname = eAttacker.name;
            lpattackerteam = eAttacker.pers["team"];
        }
        else
        {
            lpattacknum = -1;
            lpattackGuid = "";
            lpattackname = "";
            lpattackerteam = "world";
        }
    }

    hitlocDebug( eAttacker, victim, iDamage, sHitLoc, iDFlags );

    if ( isdefined( eAttacker ) && eAttacker != victim )
    {
        if ( isplayer( eAttacker ) )
            eAttacker maps\mp\_utility::incPlayerStat( "damagedone", iDamage );

        victim maps\mp\_utility::incPlayerStat( "damagetaken", iDamage );
    }
}

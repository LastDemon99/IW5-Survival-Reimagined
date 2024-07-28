// IW5 GSC SOURCE
// Decompiled by https://github.com/xensik/gsc-tool

isswitchingteams()
{
    if ( isdefined( self.switching_teams ) )
        return 1;

    return 0;
}

isteamswitchbalanced()
{
    var_0 = maps\mp\gametypes\_teams::countplayers();
    var_0[self.leaving_team]--;
    var_0[self.joining_team]++;
    return var_0[self.joining_team] - var_0[self.leaving_team] < 2;
}

isfriendlyfire( var_0, var_1 )
{
    if ( !level.teambased )
        return 0;

    if ( !isdefined( var_1 ) )
        return 0;

    if ( !isplayer( var_1 ) && !isdefined( var_1.team ) )
        return 0;

    if ( var_0.team != var_1.team )
        return 0;

    if ( var_0 == var_1 )
        return 0;

    return 1;
}

killedself( var_0 )
{
    if ( !isplayer( var_0 ) )
        return 0;

    if ( var_0 != self )
        return 0;

    return 1;
}

isHeadShot(sWeapon, sHitLoc, sMeansOfDeath, attacker)
{	
	if (isDefined(attacker))
	{
		if (attacker.code_classname == "script_vehicle" && isDefined(attacker.owner)) return false;
		if (attacker.code_classname == "misc_turret" && isDefined(attacker.owner)) return false;
		if (attacker.code_classname == "script_model" && isDefined(attacker.owner)) return false;
	}
	
	if (!isDefined(sHitLoc)) sHitLoc = "none";
	if (!isDefined(sMeansOfDeath)) sMeansOfDeath = "MOD_MELEE";
	
	return(sHitLoc == "head" || sHitLoc == "helmet") && sMeansOfDeath != "MOD_MELEE" && sMeansOfDeath != "MOD_IMPACT" && !maps\mp\_utility::isEnvironmentWeapon(sWeapon);
}

handleteamchangedeath()
{
    if ( !level.teambased )
        return;

    if ( self.joining_team == "spectator" || !isteamswitchbalanced() )
    {
        self thread [[ level.onxpevent ]]( "suicide" );
        maps\mp\_utility::incpersstat( "suicides", 1 );
        self.suicides = maps\mp\_utility::getpersstat( "suicides" );
    }
}

handleworlddeath( var_0, var_1, var_2, var_3 )
{
    if ( !isdefined( var_0 ) )
        return;

    if ( !isdefined( var_0.team ) )
    {
        handlesuicidedeath( var_2, var_3 );
        return;
    }

    if ( level.teambased && var_0.team != self.team || !level.teambased )
    {
        if ( isdefined( level.onnormaldeath ) && isplayer( var_0 ) && var_0.team != "spectator" )
            [[ level.onnormaldeath ]]( self, var_0, var_1 );
    }
}

handlesuicidedeath( var_0, var_1 )
{
    self setcarddisplayslot( self, 7 );
    self thread [[ level.onxpevent ]]( "suicide" );
    maps\mp\_utility::incpersstat( "suicides", 1 );
    self.suicides = maps\mp\_utility::getpersstat( "suicides" );

    if ( !maps\mp\_utility::matchmakinggame() )
        maps\mp\_utility::incplayerstat( "suicides", 1 );

    var_2 = maps\mp\gametypes\_tweakables::gettweakablevalue( "game", "suicidepointloss" );
    maps\mp\gametypes\_gamescore::_getplayerscore( self, maps\mp\gametypes\_gamescore::_setplayerscore( self ) - var_2 );

    if ( var_0 == "MOD_SUICIDE" && var_1 == "none" && isdefined( self.throwinggrenade ) )
        self.lastgrenadesuicidetime = gettime();

    if ( isdefined( self.friendlydamage ) )
        self iprintlnbold( &"MP_FRIENDLY_FIRE_WILL_NOT" );
}

handlefriendlyfiredeath( var_0 )
{
    var_0 setcarddisplayslot( self, 8 );
    self setcarddisplayslot( var_0, 7 );    
    var_0 thread [[ level.onxpevent ]]( "teamkill" );
    var_0.pers["teamkills"] += 1.0;
    var_0.teamkillsthisround++;

    if ( maps\mp\gametypes\_tweakables::gettweakablevalue( "team", "teamkillpointloss" ) )
    {
        var_1 = maps\mp\gametypes\_rank::getscoreinfovalue( "kill" );
        maps\mp\gametypes\_gamescore::_getplayerscore( var_0, maps\mp\gametypes\_gamescore::_setplayerscore( var_0 ) - var_1 );
    }

    if ( level.maxallowedteamkills < 0 )
        return;

    if ( level.ingraceperiod )
    {
        var_2 = 1;
        var_0.pers["teamkills"] += level.maxallowedteamkills;
    }
    else if ( var_0.pers["teamkills"] > 1 && maps\mp\_utility::gettimepassed() < level.graceperiod * 1000 + 8000 + var_0.pers["teamkills"] * 1000 )
    {
        var_2 = 1;
        var_0.pers["teamkills"] += level.maxallowedteamkills;
    }
    else
        var_2 = var_0 maps\mp\gametypes\_playerlogic::teamkilldelay();

    if ( var_2 > 0 )
    {
        var_0.pers["teamKillPunish"] = 1;
        var_0 maps\mp\_utility::_suicide();
    }
}

handlenormaldeath( var_0, var_1, var_2, var_3, var_4 )
{
    var_1 thread maps\mp\_events::killedplayer( var_0, self, var_3, var_4 );
    var_1 setcarddisplayslot( self, 8 );
    self setcarddisplayslot( var_1, 7 );

    if ( var_4 == "MOD_HEAD_SHOT" )
    {
        var_1 maps\mp\_utility::incpersstat( "headshots", 1 );
        var_1.headshots = var_1 maps\mp\_utility::getpersstat( "headshots" );
        var_1 maps\mp\_utility::incplayerstat( "headshots", 1 );

        if ( isdefined( var_1.laststand ) )
            var_5 = maps\mp\gametypes\_rank::getscoreinfovalue( "kill" ) * 2;
        else
            var_5 = undefined;

        var_1 playlocalsound( "bullet_impact_headshot_2" );
    }
    else if ( isdefined( var_1.laststand ) )
        var_5 = maps\mp\gametypes\_rank::getscoreinfovalue( "kill" ) * 2;
    else
        var_5 = undefined;

    var_1 thread maps\mp\gametypes\_rank::giverankxp( "kill", var_5, var_3, var_4 );
    var_1 maps\mp\_utility::incpersstat( "kills", 1 );
    var_1.kills = var_1 maps\mp\_utility::getpersstat( "kills" );
    var_1 maps\mp\_utility::updatepersratio( "kdRatio", "kills", "deaths" );
    var_1 maps\mp\gametypes\_persistence::statsetchild( "round", "kills", var_1.kills );
    var_1 maps\mp\_utility::incplayerstat( "kills", 1 );

    if ( isflankkill( self, var_1 ) )
    {
        var_1 maps\mp\_utility::incplayerstat( "flankkills", 1 );
        maps\mp\_utility::incplayerstat( "flankdeaths", 1 );
    }

    var_6 = var_1.pers["cur_kill_streak"];
    self.pers["copyCatLoadout"] = undefined;

    if ( maps\mp\_utility::_hasperk( "specialty_copycat" ) )
        self.pers["copyCatLoadout"] = var_1 maps\mp\gametypes\_class::cloneloadout();

    if ( isalive( var_1 ) || var_1.streaktype == "support" )
    {
        if ( var_1 maps\mp\_utility::killshouldaddtokillstreak( var_3 ) )
        {
            var_1 thread maps\mp\killstreaks\_killstreaks::giveadrenaline( "kill" );
            var_1.pers["cur_kill_streak"]++;
        }

        var_1 maps\mp\_utility::setplayerstatifgreater( "killstreak", var_1.pers["cur_kill_streak"] );

        if ( var_1.pers["cur_kill_streak"] > var_1 maps\mp\_utility::getpersstat( "longestStreak" ) )
            var_1 maps\mp\_utility::setpersstat( "longestStreak", var_1.pers["cur_kill_streak"] );
    }

    var_1.pers["cur_death_streak"] = 0;

    if ( var_1.pers["cur_kill_streak"] > var_1 maps\mp\gametypes\_persistence::statgetchild( "round", "killStreak" ) )
        var_1 maps\mp\gametypes\_persistence::statsetchild( "round", "killStreak", var_1.pers["cur_kill_streak"] );

    if ( var_1.pers["cur_kill_streak"] > var_1.kill_streak )
    {
        var_1 maps\mp\gametypes\_persistence::statset( "killStreak", var_1.pers["cur_kill_streak"] );
        var_1.kill_streak = var_1.pers["cur_kill_streak"];
    }

    maps\mp\gametypes\_gamescore::giveplayerscore( "kill", var_1, self );
    maps\mp\_skill::processkill( var_1, self );
    var_8 = maps\mp\gametypes\_tweakables::gettweakablevalue( "game", "deathpointloss" );
    maps\mp\gametypes\_gamescore::_getplayerscore( self, maps\mp\gametypes\_gamescore::_setplayerscore( self ) - var_8 );

    if ( isdefined( level.ac130player ) && level.ac130player == var_1 )
        level notify( "ai_killed", self );

    level notify( "player_got_killstreak_" + var_1.pers["cur_kill_streak"], var_1 );
    var_1 notify( "got_killstreak", var_1.pers["cur_kill_streak"] );
    var_1 notify( "killed_enemy" );

    if ( isdefined( self.uavremotemarkedby ) )
    {
        if ( self.uavremotemarkedby != var_1 )
            self.uavremotemarkedby thread maps\mp\killstreaks\_remoteuav::remoteuav_processtaggedassist( self );

        self.uavremotemarkedby = undefined;
    }

    if ( isdefined( level.onnormaldeath ) && var_1.pers["team"] != "spectator" )
        [[ level.onnormaldeath ]]( self, var_1, var_0 );

    if ( !level.teambased )
    {
        self.attackers = [];
        return;
    }

    level thread maps\mp\gametypes\_battlechatter_mp::saylocalsounddelayed( var_1, "kill", 0.75 );

    if ( isdefined( self.lastattackedshieldplayer ) && isdefined( self.lastattackedshieldtime ) && self.lastattackedshieldplayer != var_1 )
    {
        if ( gettime() - self.lastattackedshieldtime < 2500 )
        {
            self.lastattackedshieldplayer thread maps\mp\gametypes\_gamescore::processshieldassist( self );

            if ( self.lastattackedshieldplayer maps\mp\_utility::_hasperk( "specialty_assists" ) )
            {
                self.lastattackedshieldplayer.pers["assistsToKill"]++;

                if ( !( self.lastattackedshieldplayer.pers["assistsToKill"] % 2 ) )
                {
                    self.lastattackedshieldplayer maps\mp\gametypes\_missions::processchallenge( "ch_hardlineassists" );
                    self.lastattackedshieldplayer maps\mp\killstreaks\_killstreaks::giveadrenaline( "kill" );
                    self.lastattackedshieldplayer.pers["cur_kill_streak"]++;
                }
            }
            else
                self.lastattackedshieldplayer.pers["assistsToKill"] = 0;
        }
        else if ( isalive( self.lastattackedshieldplayer ) && gettime() - self.lastattackedshieldtime < 5000 )
        {
            var_9 = vectornormalize( anglestoforward( self.angles ) );
            var_10 = vectornormalize( self.lastattackedshieldplayer.origin - self.origin );

            if ( vectordot( var_10, var_9 ) > 0.925 )
            {
                self.lastattackedshieldplayer thread maps\mp\gametypes\_gamescore::processshieldassist( self );

                if ( self.lastattackedshieldplayer maps\mp\_utility::_hasperk( "specialty_assists" ) )
                {
                    self.lastattackedshieldplayer.pers["assistsToKill"]++;

                    if ( !( self.lastattackedshieldplayer.pers["assistsToKill"] % 2 ) )
                    {
                        self.lastattackedshieldplayer maps\mp\gametypes\_missions::processchallenge( "ch_hardlineassists" );
                        self.lastattackedshieldplayer maps\mp\killstreaks\_killstreaks::giveadrenaline( "kill" );
                        self.lastattackedshieldplayer.pers["cur_kill_streak"]++;
                    }
                }
                else
                    self.lastattackedshieldplayer.pers["assistsToKill"] = 0;
            }
        }
    }

    if ( isdefined( self.attackers ) )
    {
        foreach ( var_12 in self.attackers )
        {
            if ( !isdefined( var_12 ) )
                continue;

            if ( var_12 == var_1 )
                continue;

            var_12 thread maps\mp\gametypes\_gamescore::processassist( self );

            if ( var_12 maps\mp\_utility::_hasperk( "specialty_assists" ) )
            {
                var_12.pers["assistsToKill"]++;

                if ( !( var_12.pers["assistsToKill"] % 2 ) )
                {
                    var_12 maps\mp\gametypes\_missions::processchallenge( "ch_hardlineassists" );
                    var_12 maps\mp\killstreaks\_killstreaks::giveadrenaline( "kill" );
                    var_12.pers["cur_kill_streak"]++;
                }

                continue;
            }

            var_12.pers["assistsToKill"] = 0;
        }

        self.attackers = [];
    }
}

isplayerweapon( var_0 )
{
    if ( weaponclass( var_0 ) == "non-player" )
        return 0;

    if ( weaponclass( var_0 ) == "turret" )
        return 0;

    if ( weaponinventorytype( var_0 ) == "primary" || weaponinventorytype( var_0 ) == "altmode" )
        return 1;

    return 0;
}

callback_playerkilled( var_0, var_1, var_2, var_3, var_4, var_5, var_6, var_7, var_8 )
{
    playerkilled_internal( var_0, var_1, self, var_2, var_3, var_4, var_5, var_6, var_7, var_8, 0 );
}

queueshieldforremoval( var_0 )
{
    var_1 = 5;

    if ( !isdefined( level.shieldtrasharray ) )
        level.shieldtrasharray = [];

    if ( level.shieldtrasharray.size >= var_1 )
    {
        var_2 = level.shieldtrasharray.size - 1;
        level.shieldtrasharray[0] delete();

        for ( var_3 = 0; var_3 < var_2; var_3++ )
            level.shieldtrasharray[var_3] = level.shieldtrasharray[var_3 + 1];

        level.shieldtrasharray[var_2] = undefined;
    }

    level.shieldtrasharray[level.shieldtrasharray.size] = var_0;
}

launchshield( var_0, var_1 )
{
    var_2 = "weapon_riot_shield_mp";

    if ( !isdefined( self.hasriotshieldhidden ) || self.hasriotshieldhidden == 0 )
        self detachshieldmodel( var_2, "tag_weapon_left" );

    self.hasriotshield = 0;
    self.hasriotshieldequipped = 0;
}

playerkilled_internal( var_0, var_1, var_2, var_3, var_4, var_5, var_6, var_7, var_8, var_9, var_10 )
{
    var_2 endon( "spawned" );
    var_2 notify( "killed_player" );

    if ( isdefined( var_1 ) )
        var_1.assistedsuicide = undefined;

    if ( !isdefined( var_2.idflags ) )
    {
        if ( var_4 == "MOD_SUICIDE" )
            var_2.idflags = 0;
        else if ( var_4 == "MOD_GRENADE" && issubstr( var_5, "frag_grenade" ) && var_3 == 100000 )
            var_2.idflags = 0;
        else if ( var_5 == "nuke_mp" )
            var_2.idflags = 0;
        else if ( level.friendlyfire >= 2 )
            var_2.idflags = 0;
        else
        {

        }
    }

    if ( var_2.hasriotshieldequipped )
        var_2 launchshield( var_3, var_4 );

    if ( !var_10 )
    {
        if ( isdefined( var_2.endgame ) )
        {
            if ( isdefined( level.nukedetonated ) )
                self visionsetnakedforplayer( level.nukevisionset, 2 );
            else
                self visionsetnakedforplayer( "", 2 );
        }
        else
        {
            if ( isdefined( level.nukedetonated ) )
                self visionsetnakedforplayer( level.nukevisionset, 0 );
            else
                self visionsetnakedforplayer( "", 0 );

            var_2 thermalvisionoff();
        }
    }
    else
    {
        var_2.fauxdead = 1;
        self notify( "death" );
    }

    if ( game["state"] == "postgame" )
        return;

    var_11 = 0;

    if ( !isplayer( var_0 ) && isdefined( var_0.primaryweapon ) )
        var_12 = var_0.primaryweapon;
    else if ( isdefined( var_1 ) && isplayer( var_1 ) && var_1 getcurrentprimaryweapon() != "none" )
        var_12 = var_1 getcurrentprimaryweapon();
    else if ( issubstr( var_5, "alt_" ) )
        var_12 = getsubstr( var_5, 4, var_5.size );
    else
        var_12 = undefined;

    if ( isdefined( var_2.uselaststandparams ) || isdefined( var_2.laststandparams ) && var_4 == "MOD_SUICIDE" )
    {
        var_2 ensurelaststandparamsvalidity();
        var_2.uselaststandparams = undefined;
        var_0 = var_2.laststandparams.einflictor;
        var_1 = var_2.laststandparams.attacker;
        var_3 = var_2.laststandparams.idamage;
        var_4 = var_2.laststandparams.smeansofdeath;
        var_5 = var_2.laststandparams.sweapon;
        var_12 = var_2.laststandparams.sprimaryweapon;
        var_6 = var_2.laststandparams.vdir;
        var_7 = var_2.laststandparams.shitloc;
        var_11 = ( gettime() - var_2.laststandparams.laststandstarttime ) / 1000;
        var_2.laststandparams = undefined;
    }

    if ( ( !isdefined( var_1 ) || var_1.classname == "trigger_hurt" || var_1.classname == "worldspawn" || var_1 == var_2 ) && isdefined( self.attackers ) )
    {
        var_13 = undefined;

        foreach ( var_15 in self.attackers )
        {
            if ( !isdefined( var_15 ) )
                continue;

            if ( !isdefined( var_2.attackerdata[var_15.guid].damage ) )
                continue;

            if ( var_15 == var_2 || level.teambased && var_15.team == var_2.team )
                continue;

            if ( var_2.attackerdata[var_15.guid].lasttimedamaged + 2500 < gettime() && ( var_1 != var_2 && ( isdefined( var_2.laststand ) && var_2.laststand ) ) )
                continue;

            if ( var_2.attackerdata[var_15.guid].damage > 1 && !isdefined( var_13 ) )
            {
                var_13 = var_15;
                continue;
            }

            if ( isdefined( var_13 ) && var_2.attackerdata[var_15.guid].damage > var_2.attackerdata[var_13.guid].damage )
                var_13 = var_15;
        }

        if ( isdefined( var_13 ) )
        {
            var_1 = var_13;
            var_1.assistedsuicide = 1;
            var_5 = var_2.attackerdata[var_13.guid].weapon;
            var_6 = var_2.attackerdata[var_13.guid].vdir;
            var_7 = var_2.attackerdata[var_13.guid].shitloc;
            var_8 = var_2.attackerdata[var_13.guid].psoffsettime;
            var_4 = var_2.attackerdata[var_13.guid].smeansofdeath;
            var_3 = var_2.attackerdata[var_13.guid].damage;
            var_12 = var_2.attackerdata[var_13.guid].sprimaryweapon;
            var_0 = var_1;
        }
    }
    else if ( isdefined( var_1 ) )
        var_1.assistedsuicide = undefined;

    if ( isheadshot( var_5, var_7, var_4, var_1 ) )
        var_4 = "MOD_HEAD_SHOT";
    else if ( var_4 != "MOD_MELEE" && !isdefined( var_2.nuked ) )
        var_2 maps\mp\_utility::playdeathsound();

    var_17 = isfriendlyfire( var_2, var_1 );

    if ( isdefined( var_1 ) )
    {
        if ( var_1.code_classname == "script_vehicle" && isdefined( var_1.owner ) )
            var_1 = var_1.owner;

        if ( var_1.code_classname == "misc_turret" && isdefined( var_1.owner ) )
        {
            if ( isdefined( var_1.vehicle ) )
                var_1.vehicle notify( "killedPlayer", var_2 );

            var_1 = var_1.owner;
        }

        if ( var_1.code_classname == "script_model" && isdefined( var_1.owner ) )
        {
            var_1 = var_1.owner;

            if ( !isfriendlyfire( var_2, var_1 ) && var_1 != var_2 )
                var_1 notify( "crushed_enemy" );
        }
    }

    var_2 maps\mp\gametypes\_weapons::dropscavengerfordeath( var_1 );
    var_2 maps\mp\gametypes\_weapons::dropweaponfordeath( var_1 );

    if ( !var_10 )
    {
        var_2.sessionstate = "dead";
        var_2.statusicon = "hud_status_dead";
    }

    var_2 maps\mp\gametypes\_playerlogic::removefromalivecount();

    if ( !isdefined( var_2.switching_teams ) )
    {
        var_2 maps\mp\_utility::incpersstat( "deaths", 1 );
        var_2.deaths = var_2 maps\mp\_utility::getpersstat( "deaths" );
        var_2 maps\mp\_utility::updatepersratio( "kdRatio", "kills", "deaths" );
        var_2 maps\mp\gametypes\_persistence::statsetchild( "round", "deaths", var_2.deaths );
        var_2 maps\mp\_utility::incplayerstat( "deaths", 1 );
    }

    if ( isdefined( var_1 ) && isplayer( var_1 ) )
        var_1 checkkillsteal( var_2 );

    var_18 = 0;
    var_19 = maps\mp\_utility::getnextlifeid();

    if ( var_4 == "MOD_MELEE" )
    {
        if ( issubstr( var_5, "riotshield" ) )
        {
            var_1 maps\mp\_utility::incplayerstat( "shieldkills", 1 );

            if ( !maps\mp\_utility::matchmakinggame() )
                var_2 maps\mp\_utility::incplayerstat( "shielddeaths", 1 );
        }
        else
            var_1 maps\mp\_utility::incplayerstat( "knifekills", 1 );
    }

    if ( var_2 isswitchingteams() )
        handleteamchangedeath();
    else if ( !isplayer( var_1 ) || isplayer( var_1 ) && var_4 == "MOD_FALLING" )
        handleworlddeath( var_1, var_19, var_4, var_7 );
    else if ( var_1 == var_2 )
        handlesuicidedeath( var_4, var_7 );
    else if ( var_17 )
    {
        if ( !isdefined( var_2.nuked ) )
            handlefriendlyfiredeath( var_1 );
    }
    else
    {
        if ( var_4 == "MOD_GRENADE" && var_0 == var_1 )
            addattacker( var_2, var_1, var_0, var_5, var_3, ( 0.0, 0.0, 0.0 ), var_6, var_7, var_8, var_4 );

        var_18 = 1;
        handlenormaldeath( var_19, var_1, var_0, var_5, var_4 );
        var_2 thread maps\mp\gametypes\_missions::playerkilled( var_0, var_1, var_3, var_4, var_5, var_12, var_7, var_1.modifiers );
        var_2.pers["cur_death_streak"]++;

        if ( !maps\mp\_utility::getgametypenumlives() && !maps\mp\_utility::matchmakinggame() )
            var_2 maps\mp\_utility::setplayerstatifgreater( "deathstreak", var_2.pers["cur_death_streak"] );

        if ( isplayer( var_1 ) && var_2 maps\mp\_utility::isjuggernaut() )
            var_1 thread maps\mp\_utility::teamplayercardsplash( "callout_killed_juggernaut", var_1 );
    }

    var_20 = 0;
    var_21 = undefined;

    if ( isdefined( self.previousprimary ) )
    {
        var_20 = 1;
        var_21 = self.previousprimary;
        self.previousprimary = undefined;
    }

    if ( isplayer( var_1 ) && var_1 != self && ( !level.teambased || level.teambased && self.team != var_1.team ) )
    {
        if ( var_20 && isdefined( var_21 ) )
            var_22 = var_21;
        else
            var_22 = self.lastdroppableweapon;

        thread maps\mp\gametypes\_gamelogic::trackleaderboarddeathstats( var_22, var_4 );
        var_1 thread maps\mp\gametypes\_gamelogic::trackattackerleaderboarddeathstats( var_5, var_4 );
    }

    var_2 resetplayervariables();
    var_2.lastattacker = var_1;
    var_2.lastdeathpos = var_2.origin;
    var_2.deathtime = gettime();
    var_2.wantsafespawn = 0;
    var_2.revived = 0;
    var_2.sameshotdamage = 0;

    if ( maps\mp\killstreaks\_killstreaks::streaktyperesetsondeath( var_2.streaktype ) )
        var_2 maps\mp\killstreaks\_killstreaks::resetadrenaline();

    if ( var_10 )
    {
        var_18 = 0;
        var_9 = var_2 playerforcedeathanim( var_0, var_4, var_5, var_7, var_6 );
    }

	if (level.wave_num) var_2.body = var_2 cloneplayer( var_9 );

    if ( var_10 )
        var_2 playerhide();

	if (level.wave_num)
	{
		if ( var_2 isonladder() || var_2 ismantling() || !var_2 isonground() || isdefined( var_2.nuked ) )
			var_2.body startragdoll();

		if ( !isdefined( var_2.switching_teams ) )
			thread maps\mp\gametypes\_deathicons::adddeathicon( var_2.body, var_2, var_2.team, 5.0 );

		thread delaystartragdoll( var_2.body, var_7, var_6, var_5, var_0, var_4 );
	}
	
    var_2 thread [[ level.onplayerkilled ]]( var_0, var_1, var_3, var_4, var_5, var_6, var_7, var_8, var_9, var_19 );

    if ( isplayer( var_1 ) )
        var_23 = var_1 getentitynumber();
    else
        var_23 = -1;

    var_24 = var_2 getkillcamentity( var_1, var_0, var_5 );
    var_25 = -1;
    var_26 = 0;

    if ( isdefined( var_24 ) )
    {
        var_25 = var_24 getentitynumber();
        var_26 = var_24.birthtime;

        if ( !isdefined( var_26 ) )
            var_26 = 0;
    }

    if ( var_4 != "MOD_SUICIDE" && !( !isdefined( var_1 ) || var_1.classname == "trigger_hurt" || var_1.classname == "worldspawn" || var_1 == var_2 ) )
        recordfinalkillcam( 5.0, var_2, var_1, var_23, var_25, var_26, var_5, var_11, var_8 );

    var_2 setplayerdata( "killCamHowKilled", 0 );

    switch ( var_4 )
    {
        case "MOD_HEAD_SHOT":
            var_2 setplayerdata( "killCamHowKilled", 1 );
            break;
        default:
            break;
    }

    if ( !var_10 )
    {
        if ( !level.showingfinalkillcam && !level.killcam && var_18 )
        {
            if ( var_2 maps\mp\_utility::_hasperk( "specialty_copycat" ) && isdefined( var_2.pers["copyCatLoadout"] ) )
            {
                var_2 thread maps\mp\gametypes\_killcam::waitdeathcopycatbutton( var_1 );
                wait 1.0;
            }
        }

        wait 0.25;
        var_2 thread maps\mp\gametypes\_killcam::cancelkillcamonuse();
        wait 0.25;
        self.respawntimerstarttime = gettime() + 1000;
        var_27 = maps\mp\gametypes\_playerlogic::timeuntilspawn( 1 );

        if ( var_27 < 1 )
            var_27 = 1;

        var_2 thread maps\mp\gametypes\_playerlogic::predictabouttospawnplayerovertime( var_27 );
        wait 1.0;
        var_2 notify( "death_delay_finished" );
    }

    var_28 = ( gettime() - var_2.deathtime ) / 1000;
    self.respawntimerstarttime = gettime();

    if ( !( isdefined( var_2.cancelkillcam ) && var_2.cancelkillcam ) && var_18 && level.killcam && game["state"] == "playing" && !var_2 maps\mp\_utility::isusingremote() && !level.showingfinalkillcam )
    {
        var_29 = !( maps\mp\_utility::getgametypenumlives() && !var_2.pers["lives"] );
        var_27 = maps\mp\gametypes\_playerlogic::timeuntilspawn( 1 );
        var_30 = var_29 && var_27 <= 0;

        if ( !var_29 )
        {
            var_27 = -1;
            level notify( "player_eliminated", var_2 );
        }

        var_2 maps\mp\gametypes\_killcam::killcam( var_23, var_25, var_26, var_5, var_28 + var_11, var_8, var_27, maps\mp\gametypes\_gamelogic::timeuntilroundend(), var_1, var_2 );
    }

    if ( game["state"] != "playing" )
    {
        if ( !level.showingfinalkillcam )
        {
            var_2.sessionstate = "dead";
            var_2 maps\mp\_utility::clearkillcamstate();
        }

        return;
    }

    if ( maps\mp\_utility::isvalidclass( var_2.class ) )
        var_2 thread maps\mp\gametypes\_playerlogic::spawnclient();
}

checkforcebleedout()
{
    if ( level.diehardmode != 1 )
        return 0;

    if ( !maps\mp\_utility::getgametypenumlives() )
        return 0;

    if ( level.livescount[self.team] > 0 )
        return 0;

    foreach ( var_1 in level.players )
    {
        if ( !isalive( var_1 ) )
            continue;

        if ( var_1.team != self.team )
            continue;

        if ( var_1 == self )
            continue;

        if ( !var_1.inlaststand )
            return 0;
    }

    foreach ( var_1 in level.players )
    {
        if ( !isalive( var_1 ) )
            continue;

        if ( var_1.team != self.team )
            continue;

        if ( var_1.inlaststand && var_1 != self )
            var_1 laststandbleedout( 0 );
    }

    return 1;
}

checkkillsteal( var_0 )
{
    if ( maps\mp\_utility::matchmakinggame() )
        return;

    var_1 = 0;
    var_2 = undefined;

    if ( isdefined( var_0.attackerdata ) && var_0.attackerdata.size > 1 )
    {
        foreach ( var_4 in var_0.attackerdata )
        {
            if ( var_4.damage > var_1 )
            {
                var_1 = var_4.damage;
                var_2 = var_4.attackerent;
            }
        }

        if ( isdefined( var_2 ) && var_2 != self )
            maps\mp\_utility::incplayerstat( "killsteals", 1 );
    }
}

initfinalkillcam()
{
    level.finalkillcam_delay = [];
    level.finalkillcam_victim = [];
    level.finalkillcam_attacker = [];
    level.finalkillcam_attackernum = [];
    level.finalkillcam_killcamentityindex = [];
    level.finalkillcam_killcamentitystarttime = [];
    level.finalkillcam_sweapon = [];
    level.finalkillcam_deathtimeoffset = [];
    level.finalkillcam_psoffsettime = [];
    level.finalkillcam_timerecorded = [];
    level.finalkillcam_timegameended = [];
    level.finalkillcam_delay["axis"] = undefined;
    level.finalkillcam_victim["axis"] = undefined;
    level.finalkillcam_attacker["axis"] = undefined;
    level.finalkillcam_attackernum["axis"] = undefined;
    level.finalkillcam_killcamentityindex["axis"] = undefined;
    level.finalkillcam_killcamentitystarttime["axis"] = undefined;
    level.finalkillcam_sweapon["axis"] = undefined;
    level.finalkillcam_deathtimeoffset["axis"] = undefined;
    level.finalkillcam_psoffsettime["axis"] = undefined;
    level.finalkillcam_timerecorded["axis"] = undefined;
    level.finalkillcam_timegameended["axis"] = undefined;
    level.finalkillcam_delay["allies"] = undefined;
    level.finalkillcam_victim["allies"] = undefined;
    level.finalkillcam_attacker["allies"] = undefined;
    level.finalkillcam_attackernum["allies"] = undefined;
    level.finalkillcam_killcamentityindex["allies"] = undefined;
    level.finalkillcam_killcamentitystarttime["allies"] = undefined;
    level.finalkillcam_sweapon["allies"] = undefined;
    level.finalkillcam_deathtimeoffset["allies"] = undefined;
    level.finalkillcam_psoffsettime["allies"] = undefined;
    level.finalkillcam_timerecorded["allies"] = undefined;
    level.finalkillcam_timegameended["allies"] = undefined;
    level.finalkillcam_delay["none"] = undefined;
    level.finalkillcam_victim["none"] = undefined;
    level.finalkillcam_attacker["none"] = undefined;
    level.finalkillcam_attackernum["none"] = undefined;
    level.finalkillcam_killcamentityindex["none"] = undefined;
    level.finalkillcam_killcamentitystarttime["none"] = undefined;
    level.finalkillcam_sweapon["none"] = undefined;
    level.finalkillcam_deathtimeoffset["none"] = undefined;
    level.finalkillcam_psoffsettime["none"] = undefined;
    level.finalkillcam_timerecorded["none"] = undefined;
    level.finalkillcam_timegameended["none"] = undefined;
    level.finalkillcam_winner = undefined;
}

recordfinalkillcam( var_0, var_1, var_2, var_3, var_4, var_5, var_6, var_7, var_8 )
{
    if ( level.teambased && isdefined( var_2.team ) )
    {
        level.finalkillcam_delay[var_2.team] = var_0;
        level.finalkillcam_victim[var_2.team] = var_1;
        level.finalkillcam_attacker[var_2.team] = var_2;
        level.finalkillcam_attackernum[var_2.team] = var_3;
        level.finalkillcam_killcamentityindex[var_2.team] = var_4;
        level.finalkillcam_killcamentitystarttime[var_2.team] = var_5;
        level.finalkillcam_sweapon[var_2.team] = var_6;
        level.finalkillcam_deathtimeoffset[var_2.team] = var_7;
        level.finalkillcam_psoffsettime[var_2.team] = var_8;
        level.finalkillcam_timerecorded[var_2.team] = maps\mp\_utility::getsecondspassed();
        level.finalkillcam_timegameended[var_2.team] = maps\mp\_utility::getsecondspassed();
    }

    level.finalkillcam_delay["none"] = var_0;
    level.finalkillcam_victim["none"] = var_1;
    level.finalkillcam_attacker["none"] = var_2;
    level.finalkillcam_attackernum["none"] = var_3;
    level.finalkillcam_killcamentityindex["none"] = var_4;
    level.finalkillcam_killcamentitystarttime["none"] = var_5;
    level.finalkillcam_sweapon["none"] = var_6;
    level.finalkillcam_deathtimeoffset["none"] = var_7;
    level.finalkillcam_psoffsettime["none"] = var_8;
    level.finalkillcam_timerecorded["none"] = maps\mp\_utility::getsecondspassed();
    level.finalkillcam_timegameended["none"] = maps\mp\_utility::getsecondspassed();
}

erasefinalkillcam()
{
    level.finalkillcam_delay["axis"] = undefined;
    level.finalkillcam_victim["axis"] = undefined;
    level.finalkillcam_attacker["axis"] = undefined;
    level.finalkillcam_attackernum["axis"] = undefined;
    level.finalkillcam_killcamentityindex["axis"] = undefined;
    level.finalkillcam_killcamentitystarttime["axis"] = undefined;
    level.finalkillcam_sweapon["axis"] = undefined;
    level.finalkillcam_deathtimeoffset["axis"] = undefined;
    level.finalkillcam_psoffsettime["axis"] = undefined;
    level.finalkillcam_timerecorded["axis"] = undefined;
    level.finalkillcam_timegameended["axis"] = undefined;
    level.finalkillcam_delay["allies"] = undefined;
    level.finalkillcam_victim["allies"] = undefined;
    level.finalkillcam_attacker["allies"] = undefined;
    level.finalkillcam_attackernum["allies"] = undefined;
    level.finalkillcam_killcamentityindex["allies"] = undefined;
    level.finalkillcam_killcamentitystarttime["allies"] = undefined;
    level.finalkillcam_sweapon["allies"] = undefined;
    level.finalkillcam_deathtimeoffset["allies"] = undefined;
    level.finalkillcam_psoffsettime["allies"] = undefined;
    level.finalkillcam_timerecorded["allies"] = undefined;
    level.finalkillcam_timegameended["allies"] = undefined;
    level.finalkillcam_delay["none"] = undefined;
    level.finalkillcam_victim["none"] = undefined;
    level.finalkillcam_attacker["none"] = undefined;
    level.finalkillcam_attackernum["none"] = undefined;
    level.finalkillcam_killcamentityindex["none"] = undefined;
    level.finalkillcam_killcamentitystarttime["none"] = undefined;
    level.finalkillcam_sweapon["none"] = undefined;
    level.finalkillcam_deathtimeoffset["none"] = undefined;
    level.finalkillcam_psoffsettime["none"] = undefined;
    level.finalkillcam_timerecorded["none"] = undefined;
    level.finalkillcam_timegameended["none"] = undefined;
    level.finalkillcam_winner = undefined;
}

dofinalkillcam()
{
    level waittill( "round_end_finished" );
    level.showingfinalkillcam = 1;
    var_0 = "none";

    if ( isdefined( level.finalkillcam_winner ) )
        var_0 = level.finalkillcam_winner;

    var_1 = level.finalkillcam_delay[var_0];
    var_2 = level.finalkillcam_victim[var_0];
    var_3 = level.finalkillcam_attacker[var_0];
    var_4 = level.finalkillcam_attackernum[var_0];
    var_5 = level.finalkillcam_killcamentityindex[var_0];
    var_6 = level.finalkillcam_killcamentitystarttime[var_0];
    var_7 = level.finalkillcam_sweapon[var_0];
    var_8 = level.finalkillcam_deathtimeoffset[var_0];
    var_9 = level.finalkillcam_psoffsettime[var_0];
    var_10 = level.finalkillcam_timerecorded[var_0];
    var_11 = level.finalkillcam_timegameended[var_0];

    if ( !isdefined( var_2 ) || !isdefined( var_3 ) )
    {
        level.showingfinalkillcam = 0;
        level notify( "final_killcam_done" );
        return;
    }

    var_12 = 15;
    var_13 = var_11 - var_10;

    if ( var_13 > var_12 )
    {
        level.showingfinalkillcam = 0;
        level notify( "final_killcam_done" );
        return;
    }

    if ( isdefined( var_3 ) )
        var_3.finalkill = 1;

    var_14 = ( gettime() - var_2.deathtime ) / 1000;

    foreach ( var_16 in level.players )
    {
        var_16 closepopupmenu();
        var_16 closeingamemenu();

        if ( isdefined( level.nukedetonated ) )
            var_16 visionsetnakedforplayer( level.nukevisionset, 0 );
        else
            var_16 visionsetnakedforplayer( "", 0 );

        var_16.killcamentitylookat = var_2 getentitynumber();

        if ( ( var_16 != var_2 || !maps\mp\_utility::isroundbased() || maps\mp\_utility::islastround() ) && var_16 maps\mp\_utility::_hasperk( "specialty_copycat" ) )
            var_16 maps\mp\_utility::_unsetperk( "specialty_copycat" );

        var_16 thread maps\mp\gametypes\_killcam::killcam( var_4, var_5, var_6, var_7, var_14 + var_8, var_9, 0, 10000, var_3, var_2 );
    }

    wait 0.1;

    while ( anyplayersinkillcam() )
        wait 0.05;

    level notify( "final_killcam_done" );
    level.showingfinalkillcam = 0;
}

anyplayersinkillcam()
{
    foreach ( var_1 in level.players )
    {
        if ( isdefined( var_1.killcam ) )
            return 1;
    }

    return 0;
}

resetplayervariables()
{
    self.killedplayerscurrent = [];
    self.switching_teams = undefined;
    self.joining_team = undefined;
    self.leaving_team = undefined;
    self.pers["cur_kill_streak"] = 0;
    self.pers["cur_kill_streak_for_nuke"] = 0;
    maps\mp\gametypes\_gameobjects::detachusemodels();
}

getkillcamentity( var_0, var_1, var_2 )
{
    if ( !isdefined( var_1 ) || var_1 == var_0 )
        return undefined;

    switch ( var_2 )
    {
        case "artillery_mp":
        case "bouncingbetty_mp":
        case "stealth_bomb_mp":
        case "pavelow_minigun_mp":
        case "apache_minigun_mp":
        case "littlebird_guard_minigun_mp":
        case "osprey_minigun_mp":
        case "airdrop_trap_explosive_mp":
        case "bomb_site_mp":
            return var_1.killcament;
        case "sam_projectile_mp":
            if ( isdefined( var_1.samturret ) && isdefined( var_1.samturret.killcament ) )
                return var_1.samturret.killcament;

            break;
        case "ims_projectile_mp":
            if ( isdefined( var_0 ) && isdefined( var_0.imskillcament ) )
                return var_0.imskillcament;

            break;
        case "none":
            if ( isdefined( var_1.targetname ) && var_1.targetname == "care_package" )
                return var_1.killcament;

            break;
        case "ac130_105mm_mp":
        case "ac130_40mm_mp":
        case "ac130_25mm_mp":
        case "remotemissile_projectile_mp":
        case "remote_turret_mp":
        case "osprey_player_minigun_mp":
        case "ugv_turret_mp":
            return undefined;
    }

    if ( var_1.classname == "script_origin" || var_1.classname == "script_model" || var_1.classname == "script_brushmodel" )
    {
        if ( isdefined( var_1.killcament ) && !var_0 attackerinremotekillstreak() )
            return var_1.killcament;
        else
            return undefined;
    }

    return var_1;
}

attackerinremotekillstreak()
{
    if ( !isdefined( self ) )
        return 0;

    if ( isdefined( level.ac130player ) && self == level.ac130player )
        return 1;

    if ( isdefined( level.chopper ) && isdefined( level.chopper.gunner ) && self == level.chopper.gunner )
        return 1;

    if ( isdefined( level.remote_mortar ) && isdefined( level.remote_mortar.owner ) && self == level.remote_mortar.owner )
        return 1;

    if ( isdefined( self.using_remote_turret ) && self.using_remote_turret )
        return 1;

    if ( isdefined( self.using_remote_tank ) && self.using_remote_tank )
        return 1;

    return 0;
}

hitlocdebug( var_0, var_1, var_2, var_3, var_4 )
{
    var_5 = [];
    var_5[0] = 2;
    var_5[1] = 3;
    var_5[2] = 5;
    var_5[3] = 7;

    if ( !getdvarint( "scr_hitloc_debug" ) )
        return;

    if ( !isdefined( var_0.hitlocinited ) )
    {
        for ( var_6 = 0; var_6 < 6; var_6++ )
            var_0 setclientdvar( "ui_hitloc_" + var_6, "" );

        var_0.hitlocinited = 1;
    }

    if ( level.splitscreen || !isplayer( var_0 ) )
        return;

    var_7 = 6;

    if ( !isdefined( var_0.damageinfo ) )
    {
        var_0.damageinfo = [];

        for ( var_6 = 0; var_6 < var_7; var_6++ )
        {
            var_0.damageinfo[var_6] = spawnstruct();
            var_0.damageinfo[var_6].damage = 0;
            var_0.damageinfo[var_6].hitloc = "";
            var_0.damageinfo[var_6].bp = 0;
            var_0.damageinfo[var_6].jugg = 0;
            var_0.damageinfo[var_6].colorindex = 0;
        }

        var_0.damageinfocolorindex = 0;
        var_0.damageinfovictim = undefined;
    }

    for ( var_6 = var_7 - 1; var_6 > 0; var_6-- )
    {
        var_0.damageinfo[var_6].damage = var_0.damageinfo[var_6 - 1].damage;
        var_0.damageinfo[var_6].hitloc = var_0.damageinfo[var_6 - 1].hitloc;
        var_0.damageinfo[var_6].bp = var_0.damageinfo[var_6 - 1].bp;
        var_0.damageinfo[var_6].jugg = var_0.damageinfo[var_6 - 1].jugg;
        var_0.damageinfo[var_6].colorindex = var_0.damageinfo[var_6 - 1].colorindex;
    }

    var_0.damageinfo[0].damage = var_2;
    var_0.damageinfo[0].hitloc = var_3;
    var_0.damageinfo[0].bp = var_4 & level.idflags_penetration;
    var_0.damageinfo[0].jugg = var_1 maps\mp\_utility::isjuggernaut();

    if ( isdefined( var_0.damageinfovictim ) && var_0.damageinfovictim != var_1 )
    {
        var_0.damageinfocolorindex++;

        if ( var_0.damageinfocolorindex == var_5.size )
            var_0.damageinfocolorindex = 0;
    }

    var_0.damageinfovictim = var_1;
    var_0.damageinfo[0].colorindex = var_0.damageinfocolorindex;

    for ( var_6 = 0; var_6 < var_7; var_6++ )
    {
        var_8 = "^" + var_5[var_0.damageinfo[var_6].colorindex];

        if ( var_0.damageinfo[var_6].hitloc != "" )
        {
            var_9 = var_8 + var_0.damageinfo[var_6].hitloc;

            if ( var_0.damageinfo[var_6].bp )
                var_9 += " (BP)";

            if ( var_0.damageinfo[var_6].jugg )
                var_9 += " (Jugg)";

            var_0 setclientdvar( "ui_hitloc_" + var_6, var_9 );
        }

        var_0 setclientdvar( "ui_hitloc_damage_" + var_6, var_8 + var_0.damageinfo[var_6].damage );
    }
}

giverecentshieldxp()
{
    self endon( "death" );
    self endon( "disconnect" );
    self notify( "giveRecentShieldXP" );
    self endon( "giveRecentShieldXP" );
    self.recentshieldxp++;
    wait 20.0;
    self.recentshieldxp = 0;
}

callback_playerdamage_internal( var_0, var_1, var_2, var_3, var_4, var_5, var_6, var_7, var_8, var_9, var_10 )
{
    if ( !maps\mp\_utility::isreallyalive( var_2 ) )
        return;

    if ( isdefined( var_1 ) && var_1.classname == "script_origin" && isdefined( var_1.type ) && var_1.type == "soft_landing" )
        return;

    if ( var_6 == "killstreak_emp_mp" )
        return;

    if ( var_6 == "bouncingbetty_mp" && !maps\mp\gametypes\_weapons::minedamageheightpassed( var_0, var_2 ) )
        return;

    if ( var_6 == "bouncingbetty_mp" && ( var_2 getstance() == "crouch" || var_2 getstance() == "prone" ) )
        var_3 = int( var_3 / 2 );

    if ( var_6 == "xm25_mp" && var_5 == "MOD_IMPACT" )
        var_3 = 95;

    if ( var_6 == "emp_grenade_mp" && var_5 != "MOD_IMPACT" )
        var_2 notify( "emp_grenaded", var_1 );

    if ( isdefined( level.hostmigrationtimer ) )
        return;

    if ( var_5 == "MOD_FALLING" )
        var_2 thread emitfalldamage( var_3 );

    if ( var_5 == "MOD_EXPLOSIVE_BULLET" && var_3 != 1 )
    {
        var_3 *= getdvarfloat( "scr_explBulletMod" );
        var_3 = int( var_3 );
    }

    if ( isdefined( var_1 ) && var_1.classname == "worldspawn" )
        var_1 = undefined;

    if ( isdefined( var_1 ) && isdefined( var_1.gunner ) )
        var_1 = var_1.gunner;

    var_11 = isdefined( var_1 ) && !isdefined( var_1.gunner ) && ( var_1.classname == "script_vehicle" || var_1.classname == "misc_turret" || var_1.classname == "script_model" );
    var_12 = level.teambased && isdefined( var_1 ) && var_2 != var_1 && isdefined( var_1.team ) && var_2.pers["team"] == var_1.team;
    var_13 = isdefined( var_1 ) && isdefined( var_0 ) && isdefined( var_2 ) && isplayer( var_1 ) && var_1 == var_0 && var_1 == var_2;

    if ( var_13 )
        return;

    var_14 = 0.0;

    if ( var_4 & level.idflags_stun )
    {
        var_14 = 0.0;
        var_3 = 0.0;
    }
    else if ( var_9 == "shield" )
    {
        if ( var_12 && level.friendlyfire == 0 )
            return;

        if ( var_5 == "MOD_PISTOL_BULLET" || var_5 == "MOD_RIFLE_BULLET" || var_5 == "MOD_EXPLOSIVE_BULLET" && !var_12 )
        {
            if ( isplayer( var_1 ) )
            {
                var_1.lastattackedshieldplayer = var_2;
                var_1.lastattackedshieldtime = gettime();
            }

            var_2 notify( "shield_blocked" );

            if ( maps\mp\_utility::isenvironmentweapon( var_6 ) )
                var_15 = 25;
            else
                var_15 = maps\mp\perks\_perks::cac_modified_damage( var_2, var_1, var_3, var_5, var_6, var_7, var_8, var_9 );

            var_2.shielddamage += var_15;

            if ( !maps\mp\_utility::isenvironmentweapon( var_6 ) || common_scripts\utility::cointoss() )
                var_2.shieldbullethits++;

            if ( var_2.shieldbullethits >= level.riotshieldxpbullets )
            {
                if ( self.recentshieldxp > 4 )
                    var_16 = int( 50 / self.recentshieldxp );
                else
                    var_16 = 50;

                var_2 thread maps\mp\gametypes\_rank::giverankxp( "shield_damage", var_16 );
                var_2 thread giverecentshieldxp();
                var_2 thread maps\mp\gametypes\_missions::genericchallenge( "shield_damage", var_2.shielddamage );
                var_2 thread maps\mp\gametypes\_missions::genericchallenge( "shield_bullet_hits", var_2.shieldbullethits );
                var_2.shielddamage = 0;
                var_2.shieldbullethits = 0;
            }
        }

        if ( var_4 & level.idflags_shield_explosive_impact )
        {
            if ( !var_12 )
                var_2 thread maps\mp\gametypes\_missions::genericchallenge( "shield_explosive_hits", 1 );

            var_9 = "none";

            if ( !( var_4 & level.idflags_shield_explosive_impact_huge ) )
                var_3 *= 0.0;
        }
        else if ( var_4 & level.idflags_shield_explosive_splash )
        {
            if ( isdefined( var_0 ) && isdefined( var_0.stuckenemyentity ) && var_0.stuckenemyentity == var_2 )
                var_3 = 101;

            var_2 thread maps\mp\gametypes\_missions::genericchallenge( "shield_explosive_hits", 1 );
            var_9 = "none";
        }
        else
            return;
    }
    else if ( var_5 == "MOD_MELEE" && issubstr( var_6, "riotshield" ) )
    {
        if ( !( var_12 && level.friendlyfire == 0 ) )
        {
            var_14 = 0.0;
            var_2 stunplayer( 0.0 );
        }
    }

    if ( !var_12 )
        var_3 = maps\mp\perks\_perks::cac_modified_damage( var_2, var_1, var_3, var_5, var_6, var_7, var_8, var_9 );

    if ( isdefined( level.modifyplayerdamage ) )
        var_3 = [[ level.modifyplayerdamage ]]( var_2, var_1, var_3, var_5, var_6, var_7, var_8, var_9 );

    if ( !var_3 )
        return 0;

    var_2.idflags = var_4;
    var_2.idflagstime = gettime();

    if ( game["state"] == "postgame" )
        return;

    if ( var_2.sessionteam == "spectator" )
        return;

    if ( isdefined( var_2.candocombat ) && !var_2.candocombat )
        return;

    if ( isdefined( var_1 ) && isplayer( var_1 ) && isdefined( var_1.candocombat ) && !var_1.candocombat )
        return;

    if ( var_11 && var_12 )
    {
        if ( var_5 == "MOD_CRUSH" )
        {
            var_2 maps\mp\_utility::_suicide();
            return;
        }

        if ( !level.friendlyfire )
            return;
    }

    if ( !isdefined( var_8 ) )
        var_4 |= level.idflags_no_knockback;

    var_17 = 0;

    if ( var_2.health == var_2.maxhealth && ( !isdefined( var_2.laststand ) || !var_2.laststand ) || !isdefined( var_2.attackers ) && !isdefined( var_2.laststand ) )
    {
        var_2.attackers = [];
        var_2.attackerdata = [];
    }

    if ( isheadshot( var_6, var_9, var_5, var_1 ) )
        var_5 = "MOD_HEAD_SHOT";

    if ( maps\mp\gametypes\_tweakables::gettweakablevalue( "game", "onlyheadshots" ) )
    {
        if ( var_5 == "MOD_PISTOL_BULLET" || var_5 == "MOD_RIFLE_BULLET" || var_5 == "MOD_EXPLOSIVE_BULLET" )
            return;
        else if ( var_5 == "MOD_HEAD_SHOT" )
            var_3 = 150;
    }

    if ( var_6 == "none" && isdefined( var_0 ) )
    {
        if ( isdefined( var_0.destructible_type ) && issubstr( var_0.destructible_type, "vehicle_" ) )
            var_6 = "destructible_car";
    }

    if ( gettime() < var_2.spawntime + level.killstreakspawnshield )
    {
        var_18 = int( max( var_2.health / 4, 1 ) );

        if ( var_3 >= var_18 && maps\mp\_utility::iskillstreakweapon( var_6 ) )
            var_3 = var_18;
    }

    if ( !( var_4 & level.idflags_no_protection ) )
    {
        if ( !level.teambased && var_11 && isdefined( var_1.owner ) && var_1.owner == var_2 )
        {
            if ( var_5 == "MOD_CRUSH" )
                var_2 maps\mp\_utility::_suicide();

            return;
        }

        if ( ( issubstr( var_5, "MOD_GRENADE" ) || issubstr( var_5, "MOD_EXPLOSIVE" ) || issubstr( var_5, "MOD_PROJECTILE" ) ) && isdefined( var_0 ) && isdefined( var_1 ) )
        {
            if ( var_2 != var_1 && var_0.classname == "grenade" && var_2.lastspawntime + 3500 > gettime() && isdefined( var_2.lastspawnpoint ) && distance( var_0.origin, var_2.lastspawnpoint.origin ) < 250 )
                return;

            var_2.explosiveinfo = [];
            var_2.explosiveinfo["damageTime"] = gettime();
            var_2.explosiveinfo["damageId"] = var_0 getentitynumber();
            var_2.explosiveinfo["returnToSender"] = 0;
            var_2.explosiveinfo["counterKill"] = 0;
            var_2.explosiveinfo["chainKill"] = 0;
            var_2.explosiveinfo["cookedKill"] = 0;
            var_2.explosiveinfo["throwbackKill"] = 0;
            var_2.explosiveinfo["suicideGrenadeKill"] = 0;
            var_2.explosiveinfo["weapon"] = var_6;
            var_19 = issubstr( var_6, "frag_" );

            if ( var_1 != var_2 )
            {
                if ( ( issubstr( var_6, "c4_" ) || issubstr( var_6, "claymore_" ) ) && isdefined( var_1 ) && isdefined( var_0.owner ) )
                {
                    var_2.explosiveinfo["returnToSender"] = var_0.owner == var_2;
                    var_2.explosiveinfo["counterKill"] = isdefined( var_0.wasdamaged );
                    var_2.explosiveinfo["chainKill"] = isdefined( var_0.waschained );
                    var_2.explosiveinfo["bulletPenetrationKill"] = isdefined( var_0.wasdamagedfrombulletpenetration );
                    var_2.explosiveinfo["cookedKill"] = 0;
                }

                if ( isdefined( var_1.lastgrenadesuicidetime ) && var_1.lastgrenadesuicidetime >= gettime() - 50 && var_19 )
                    var_2.explosiveinfo["suicideGrenadeKill"] = 1;
            }

            if ( var_19 )
            {
                var_2.explosiveinfo["cookedKill"] = isdefined( var_0.iscooked );
                var_2.explosiveinfo["throwbackKill"] = isdefined( var_0.threwback );
            }

            var_2.explosiveinfo["stickKill"] = isdefined( var_0.isstuck ) && var_0.isstuck == "enemy";
            var_2.explosiveinfo["stickFriendlyKill"] = isdefined( var_0.isstuck ) && var_0.isstuck == "friendly";

            if ( isplayer( var_1 ) && var_1 != self )
                maps\mp\gametypes\_gamelogic::setinflictorstat( var_0, var_1, var_6 );
        }

        if ( isplayer( var_1 ) && isdefined( var_1.pers["participation"] ) )
            var_1.pers["participation"]++;
        else if ( isplayer( var_1 ) )
            var_1.pers["participation"] = 1;

        var_20 = var_2.health / var_2.maxhealth;

        if ( var_12 )
        {
            if ( !maps\mp\_utility::matchmakinggame() && isplayer( var_1 ) )
                var_1 maps\mp\_utility::incplayerstat( "mostff", 1 );

            if ( level.friendlyfire == 0 || !isplayer( var_1 ) && level.friendlyfire != 1 )
            {
                if ( var_6 == "artillery_mp" || var_6 == "stealth_bomb_mp" )
                    var_2 damageshellshockandrumble( var_0, var_6, var_5, var_3, var_4, var_1 );

                return;
            }
            else if ( level.friendlyfire == 1 )
            {
                if ( var_3 < 1 )
                    var_3 = 1;

                if ( var_2 maps\mp\_utility::isjuggernaut() )
                    var_3 = maps\mp\perks\_perks::cac_modified_damage( var_2, var_1, var_3, var_5, var_6, var_7, var_8, var_9 );

                var_2.lastdamagewasfromenemy = 0;
                var_2 finishplayerdamagewrapper( var_0, var_1, var_3, var_4, var_5, var_6, var_7, var_8, var_9, var_10, var_14 );
            }
            else if ( level.friendlyfire == 2 && maps\mp\_utility::isreallyalive( var_1 ) )
            {
                var_3 = int( var_3 * 0.5 );

                if ( var_3 < 1 )
                    var_3 = 1;

                var_1.lastdamagewasfromenemy = 0;
                var_1.friendlydamage = 1;
                var_1 finishplayerdamagewrapper( var_0, var_1, var_3, var_4, var_5, var_6, var_7, var_8, var_9, var_10, var_14 );
                var_1.friendlydamage = undefined;
            }
            else if ( level.friendlyfire == 3 && maps\mp\_utility::isreallyalive( var_1 ) )
            {
                var_3 = int( var_3 * 0.5 );

                if ( var_3 < 1 )
                    var_3 = 1;

                var_2.lastdamagewasfromenemy = 0;
                var_1.lastdamagewasfromenemy = 0;
                var_2 finishplayerdamagewrapper( var_0, var_1, var_3, var_4, var_5, var_6, var_7, var_8, var_9, var_10, var_14 );

                if ( maps\mp\_utility::isreallyalive( var_1 ) )
                {
                    var_1.friendlydamage = 1;
                    var_1 finishplayerdamagewrapper( var_0, var_1, var_3, var_4, var_5, var_6, var_7, var_8, var_9, var_10, var_14 );
                    var_1.friendlydamage = undefined;
                }
            }

            var_17 = 1;
        }
        else
        {
            if ( var_3 < 1 )
                var_3 = 1;

            if ( isdefined( var_1 ) && isplayer( var_1 ) )
                addattacker( var_2, var_1, var_0, var_6, var_3, var_7, var_8, var_9, var_10, var_5 );

            if ( var_5 == "MOD_EXPLOSIVE" || var_5 == "MOD_GRENADE_SPLASH" && var_3 < var_2.health )
                var_2 notify( "survived_explosion", var_1 );

            if ( isdefined( var_1 ) )
                level.lastlegitimateattacker = var_1;

            if ( isdefined( var_1 ) && isplayer( var_1 ) && isdefined( var_6 ) )
                var_1 thread maps\mp\gametypes\_weapons::checkhit( var_6, var_2 );

            if ( isdefined( var_1 ) && isplayer( var_1 ) && isdefined( var_6 ) && var_1 != var_2 )
            {
                var_1 thread maps\mp\_events::damagedplayer( self, var_3, var_6 );
                var_2.attackerposition = var_1.origin;
            }
            else
                var_2.attackerposition = undefined;

            if ( issubstr( var_5, "MOD_GRENADE" ) && isdefined( var_0.iscooked ) )
                var_2.wascooked = gettime();
            else
                var_2.wascooked = undefined;

            var_2.lastdamagewasfromenemy = isdefined( var_1 ) && var_1 != var_2;

            if ( var_2.lastdamagewasfromenemy )
                var_1.damagedplayers[var_2.guid] = gettime();

            var_2 finishplayerdamagewrapper( var_0, var_1, var_3, var_4, var_5, var_6, var_7, var_8, var_9, var_10, var_14 );

            if ( isdefined( level.ac130player ) && isdefined( var_1 ) && level.ac130player == var_1 )
                level notify( "ai_pain", var_2 );

            var_2 thread maps\mp\gametypes\_missions::playerdamaged( var_0, var_1, var_3, var_5, var_6, var_9 );
        }

        if ( var_11 && isdefined( var_1.gunner ) )
            var_21 = var_1.gunner;
        else
            var_21 = var_1;

        if ( isdefined( var_21 ) && var_21 != var_2 && var_3 > 0 && ( !isdefined( var_9 ) || var_9 != "shield" ) )
        {
            if ( var_4 & level.idflags_stun )
                var_22 = "stun";
            else if ( isexplosivedamagemod( var_5 ) && var_2 maps\mp\_utility::_hasperk( "_specialty_blastshield" ) )
                var_22 = "hitBodyArmor";
            else if ( var_2 maps\mp\_utility::_hasperk( "specialty_combathigh" ) )
                var_22 = "hitEndGame";
            else if ( isdefined( var_2.haslightarmor ) )
                var_22 = "hitLightArmor";
            else if ( var_2 maps\mp\_utility::isjuggernaut() )
                var_22 = "hitJuggernaut";
            else if ( !shouldweaponfeedback( var_6 ) )
                var_22 = "none";
            else
                var_22 = "standard";

            var_21 thread maps\mp\gametypes\_damagefeedback::updatedamagefeedback( var_22 );
        }

        var_2.hasdonecombat = 1;
    }

    if ( isdefined( var_1 ) && var_1 != var_2 && !var_17 )
        level.usestartspawn = 0;

    if ( var_3 > 0 && isdefined( var_1 ) && !var_2 maps\mp\_utility::isusingremote() )
        var_2 thread maps\mp\gametypes\_shellshock::bloodeffect( var_1.origin );

    if ( var_2.sessionstate != "dead" )
    {
        var_23 = var_2 getentitynumber();
        var_24 = var_2.name;
        var_25 = var_2.pers["team"];
        var_26 = var_2.guid;
        var_27 = "";

        if ( isplayer( var_1 ) )
        {
            var_28 = var_1 getentitynumber();
            var_29 = var_1.guid;
            var_30 = var_1.name;
            var_27 = var_1.pers["team"];
        }
        else
        {
            var_28 = -1;
            var_29 = "";
            var_30 = "";
            var_27 = "world";
        }

        logprint( "D;" + var_26 + ";" + var_23 + ";" + var_25 + ";" + var_24 + ";" + var_29 + ";" + var_28 + ";" + var_27 + ";" + var_30 + ";" + var_6 + ";" + var_3 + ";" + var_5 + ";" + var_9 + "\\n" );
    }

    hitlocdebug( var_1, var_2, var_3, var_9, var_4 );

    if ( isdefined( var_1 ) && var_1 != var_2 )
    {
        if ( isplayer( var_1 ) )
            var_1 maps\mp\_utility::incplayerstat( "damagedone", var_3 );

        var_2 maps\mp\_utility::incplayerstat( "damagetaken", var_3 );
    }
}

shouldweaponfeedback( var_0 )
{
    switch ( var_0 )
    {
        case "artillery_mp":
        case "stealth_bomb_mp":
            return 0;
    }

    return 1;
}

checkvictimstutter( var_0, var_1, var_2, var_3, var_4 )
{
    if ( var_4 == "MOD_PISTOL_BULLET" || var_4 == "MOD_RIFLE_BULLET" || var_4 == "MOD_HEAD_SHOT" )
    {
        if ( distance( var_0.origin, var_1.origin ) > 256 )
            return;

        var_5 = var_0 getvelocity();

        if ( lengthsquared( var_5 ) < 10 )
            return;

        var_6 = maps\mp\_utility::findisfacing( var_0, var_1, 25 );

        if ( var_6 )
            var_0 thread stutterstep();
    }
}

stutterstep( var_0 )
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    self.instutter = 1;
    self.movespeedscaler = 0.05;
    maps\mp\gametypes\_weapons::updatemovespeedscale();
    wait 0.5;
    self.movespeedscaler = 1;

    if ( maps\mp\_utility::_hasperk( "specialty_lightweight" ) )
        self.movespeedscaler = maps\mp\_utility::lightweightscalar();

    maps\mp\gametypes\_weapons::updatemovespeedscale();
    self.instutter = 0;
}

addattacker( var_0, var_1, var_2, var_3, var_4, var_5, var_6, var_7, var_8, var_9 )
{
    if ( !isdefined( var_0.attackerdata ) )
        var_0.attackerdata = [];

    if ( !isdefined( var_0.attackerdata[var_1.guid] ) )
    {
        var_0.attackers[var_1.guid] = var_1;
        var_0.attackerdata[var_1.guid] = spawnstruct();
        var_0.attackerdata[var_1.guid].damage = 0;
        var_0.attackerdata[var_1.guid].attackerent = var_1;
        var_0.attackerdata[var_1.guid].firsttimedamaged = gettime();
    }

    if ( maps\mp\gametypes\_weapons::isprimaryweapon( var_3 ) && !maps\mp\gametypes\_weapons::issidearm( var_3 ) )
        var_0.attackerdata[var_1.guid].isprimary = 1;

    var_0.attackerdata[var_1.guid].damage += var_4;
    var_0.attackerdata[var_1.guid].weapon = var_3;
    var_0.attackerdata[var_1.guid].vpoint = var_5;
    var_0.attackerdata[var_1.guid].vdir = var_6;
    var_0.attackerdata[var_1.guid].shitloc = var_7;
    var_0.attackerdata[var_1.guid].psoffsettime = var_8;
    var_0.attackerdata[var_1.guid].smeansofdeath = var_9;
    var_0.attackerdata[var_1.guid].attackerent = var_1;
    var_0.attackerdata[var_1.guid].lasttimedamaged = gettime();

    if ( isdefined( var_2 ) && !isplayer( var_2 ) && isdefined( var_2.primaryweapon ) )
        var_0.attackerdata[var_1.guid].sprimaryweapon = var_2.primaryweapon;
    else if ( isdefined( var_1 ) && isplayer( var_1 ) && var_1 getcurrentprimaryweapon() != "none" )
        var_0.attackerdata[var_1.guid].sprimaryweapon = var_1 getcurrentprimaryweapon();
    else
        var_0.attackerdata[var_1.guid].sprimaryweapon = undefined;
}

resetattackerlist()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    wait 1.75;
    self.attackers = [];
    self.attackerdata = [];
}

callback_playerdamage( var_0, var_1, var_2, var_3, var_4, var_5, var_6, var_7, var_8, var_9 )
{
    callback_playerdamage_internal( var_0, var_1, self, var_2, var_3, var_4, var_5, var_6, var_7, var_8, var_9 );
}

finishplayerdamagewrapper( var_0, var_1, var_2, var_3, var_4, var_5, var_6, var_7, var_8, var_9, var_10 )
{
    if ( maps\mp\_utility::isusingremote() && var_2 >= self.health && !( var_3 & level.idflags_stun ) )
    {
        if ( !isdefined( var_7 ) )
            var_7 = ( 0.0, 0.0, 0.0 );

        if ( !isdefined( var_1 ) && !isdefined( var_0 ) )
        {
            var_1 = self;
            var_0 = var_1;
        }

        playerkilled_internal( var_0, var_1, self, var_2, var_4, var_5, var_7, var_8, var_9, 0, 1 );
    }
    else
    {
        if ( !callback_killingblow( var_0, var_1, var_2 - var_2 * var_10, var_3, var_4, var_5, var_6, var_7, var_8, var_9 ) )
            return;

        if ( !isalive( self ) )
            return;

        self finishplayerdamage( var_0, var_1, var_2, var_3, var_4, var_5, var_6, var_7, var_8, var_9, var_10 );
    }

    if ( var_4 == "MOD_EXPLOSIVE_BULLET" )
        self shellshock( "damage_mp", getdvarfloat( "scr_csmode" ) );

    damageshellshockandrumble( var_0, var_5, var_4, var_2, var_3, var_1 );
}

callback_playerlaststand( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
    lastStandParams = spawnstruct();
    lastStandParams.einflictor = eInflictor;
    lastStandParams.attacker = attacker;
    lastStandParams.idamage = iDamage;
    lastStandParams.attackerposition = attacker.origin;

    if ( attacker == self ) lastStandParams.smeansofdeath = "MOD_SUICIDE";
    else lastStandParams.smeansofdeath = sMeansOfDeath;

    lastStandParams.sweapon = sWeapon;

    if ( isdefined( attacker ) && isplayer( attacker ) && attacker getcurrentprimaryweapon() != "none" ) lastStandParams.sprimaryweapon = attacker getcurrentprimaryweapon();
    else lastStandParams.sprimaryweapon = undefined;

    lastStandParams.vdir = vDir;
    lastStandParams.shitloc = sHitLoc;
    lastStandParams.laststandstarttime = gettime();
    lastStandParams = true;
	
	self.inlaststand = 1;

	if ( isdefined( level.ac130player ) && isdefined( attacker ) && level.ac130player == attacker ) level notify( "ai_crawling", self );

	self.laststandparams = lastStandParams;
	self common_scripts\utility::_disableusability();
	self thread enablelaststandweapons();

	if(self isTestClient())
	{
		self.health = 40;
		self thread laststandtimer(10, 0);
	}
	else
	{
		notifyData = spawnstruct();
		notifyData.titletext = "Self Revive";
		notifyData.iconname = "specialty_finalstand";
		notifyData.glowcolor = ( 1.0, 0.0, 0.0 );
		notifyData.sound = "mp_last_stand";
		notifyData.duration = 2.0;
		
		self thread maps\mp\gametypes\_hud_message::notifymessage( notifyData );
		
		self.health = self.maxhealth;
		self.hasRevive = 0;
		self setClientDvar("ui_self_revive", 0);
		
		weapon = "iw5_fnfiveseven_mp";
		
		if (self hasWeapon(weapon)) self.lastStandWeapon = undefined;
		else self.lastStandWeapon = 1;
		
		self maps\mp\_utility::_giveweapon(weapon);

		self givemaxammo(weapon);
		
		self disableweaponswitch();
		self disableoffhandweapons();
		self switchtoweapon(weapon);
		
		self thread laststandtimer(20, 1);
		self thread lastStandTimerBar();
	}
}

lastStandTimerBar()
{
	self endon( "death" );
    self endon( "disconnect" );
    self endon( "revive" );
    level endon( "game_ended" );
	
	overlay = newClientHudElem( self );
	overlay.x = 0;
	overlay.y = 0;
	overlay.alignX = "left";
	overlay.alignY = "top";
	overlay.horzAlign = "fullscreen";
	overlay.vertAlign = "fullscreen";
	overlay setshader ( "combathigh_overlay", 640, 480 );
	overlay.sort = -10;
	overlay.archived = true;	
	
	selfReviveIcon = self maps\mp\gametypes\_hud_util::createIcon("specialty_self_revive", 30, 30);
	selfReviveIcon maps\mp\gametypes\_hud_util::setpoint("CENTER", "BOTTOM", -100, -70);
	
	lastStandBar = self maps\mp\gametypes\_hud_util::createPrimaryProgressBar();
	lastStandBar maps\mp\gametypes\_hud_util::setPoint("CENTER", "BOTTOM", 0, -70);
	lastStandBar.useTime = 20;
	lastStandBar.icon = selfReviveIcon;
	lastStandBar.overlay = overlay;
	self.lastStandBar = lastStandBar;
	
    self.barFrac = 10;
    while (self.barFrac < 20)
    {
        lastStandBar maps\mp\gametypes\_hud_util::updateBar(self.barFrac / 20, 0);
		lastStandBar.bar.color = (1, self.barFrac / 20, 0);
		self.barFrac++;
        wait 1;
    }
	self _revive();
}

dieaftertime( var_0 )
{
    self endon( "death" );
    self endon( "disconnect" );
    self endon( "joined_team" );
    level endon( "game_ended" );
    wait(var_0);
    self.uselaststandparams = 1;
    maps\mp\_utility::_suicide();
}

detonateonuse()
{
    self endon( "death" );
    self endon( "disconnect" );
    self endon( "joined_team" );
    level endon( "game_ended" );
    self waittill( "detonate" );
    self.uselaststandparams = 1;
    c4deathdetonate();
}

detonateondeath()
{
    self endon( "detonate" );
    self endon( "disconnect" );
    self endon( "joined_team" );
    level endon( "game_ended" );
    self waittill( "death" );
    c4deathdetonate();
}

c4deathdetonate()
{
    self playsound( "detpack_explo_default" );
    self.c4deatheffect = playfx( level.c4death, self.origin );
    radiusdamage( self.origin, 400, 100, 100, self );

    if ( isalive( self ) )
        maps\mp\_utility::_suicide();
}

enablelaststandweapons()
{
    self endon( "death" );
    self endon( "disconnect" );
    level endon( "game_ended" );
    maps\mp\_utility::freezecontrolswrapper( 1 );
    wait 0.3;
    maps\mp\_utility::freezecontrolswrapper( 0 );
}

laststandtimer( var_0, var_1 )
{
    self endon( "death" );
    self endon( "disconnect" );
    self endon( "revive" );
    level endon( "game_ended" );
    level notify( "player_last_stand" );
    
	self thread laststandwaittilldeath();
    self.laststand = 1;
	
	self maps\mp\_utility::playdeathsound();
	self thread lastStandKeepOverlay();
	
	if (var_1)  self thread lastStandKill();
	else 
	{
		wait var_0;
		self thread maps\mp\gametypes\_damage::PlayerKilled_internal( self, self, self, 10000, "MOD_SUICIDE", "frag_grenade_mp", (0,0,0), "none", 0, 1116, true );
	}
}

lastStandKill()
{
	self endon( "revive" );
    self endon( "death" );
	
	self waittill("lastStandKill");
	self _revive();
}

_revive()
{
	self maps\mp\survival\_utility::clearLastStand();
	maps\mp\gametypes\_playerlogic::laststandrespawnplayer();
	self notify("revive");
}

maxhealthoverlay( var_0, var_1 )
{
    self endon( "stop_maxHealthOverlay" );
    self endon( "revive" );
    self endon( "death" );

    for (;;)
    {
        self.health -= 1;
        self.maxhealth = var_0;
        wait 0.05;
        self.maxhealth = 50;
        self.health += 1;
        wait 0.5;
    }
}

laststandbleedout( var_0, var_1 )
{
    if ( var_0 )
    {
        self.laststand = undefined;
        self.infinalstand = 0;
        self notify( "revive" );
        maps\mp\_utility::clearlowermessage( "last_stand" );
        maps\mp\gametypes\_playerlogic::laststandrespawnplayer();

        if ( isdefined( var_1 ) )
            var_1 delete();
    }
    else
    {
        self.uselaststandparams = 1;
        self.beingrevived = 0;
        maps\mp\_utility::_suicide();
    }
}

laststandallowsuicide()
{
    self endon( "death" );
    self endon( "disconnect" );
    self endon( "game_ended" );
    self endon( "revive" );

    for (;;)
    {
        if ( self usebuttonpressed() )
        {
            var_0 = gettime();

            while ( self usebuttonpressed() )
            {
                wait 0.05;

                if ( gettime() - var_0 > 700 )
                    break;
            }

            if ( gettime() - var_0 > 700 )
                break;
        }

        wait 0.05;
    }

    thread laststandbleedout( 0 );
}

laststandkeepoverlay()
{
    level endon( "game_ended" );
    self endon( "death" );
    self endon( "disconnect" );
    self endon( "revive" );

    while ( !level.gameended )
    {
        self.health = 2;
        wait 0.05;
        self.health = 1;
        wait 0.5;
    }

    self.health = self.maxhealth;
}

laststandwaittilldeath()
{
    self endon( "disconnect" );
    self endon( "revive" );
    level endon( "game_ended" );
    self waittill( "death" );
    maps\mp\_utility::clearlowermessage( "last_stand" );
    self.laststand = undefined;
}

maydolaststand( var_0, var_1, var_2 )
{
    if ( var_1 == "MOD_TRIGGER_HURT" )
        return 0;

    if ( var_1 != "MOD_PISTOL_BULLET" && var_1 != "MOD_RIFLE_BULLET" && var_1 != "MOD_FALLING" && var_1 != "MOD_EXPLOSIVE_BULLET" )
        return 0;

    if ( var_1 == "MOD_IMPACT" && var_0 == "throwingknife_mp" )
        return 0;

    if ( var_1 == "MOD_IMPACT" && ( var_0 == "m79_mp" || issubstr( var_0, "gl_" ) ) )
        return 0;

    if ( isheadshot( var_0, var_2, var_1 ) )
        return 0;

    if ( maps\mp\_utility::isusingremote() )
        return 0;

    return 1;
}

ensurelaststandparamsvalidity()
{
    if ( !isdefined( self.laststandparams.attacker ) )
        self.laststandparams.attacker = self;
}

gethitlocheight( var_0 )
{
    switch ( var_0 )
    {
        case "helmet":
        case "head":
        case "neck":
            return 60;
        case "torso_upper":
        case "left_arm_upper":
        case "right_arm_upper":
        case "left_arm_lower":
        case "right_arm_lower":
        case "left_hand":
        case "right_hand":
        case "gun":
            return 48;
        case "torso_lower":
            return 40;
        case "left_leg_upper":
        case "right_leg_upper":
            return 32;
        case "left_leg_lower":
        case "right_leg_lower":
            return 10;
        case "left_foot":
        case "right_foot":
            return 5;
    }

    return 48;
}

delaystartragdoll( var_0, var_1, var_2, var_3, var_4, var_5 )
{
    if ( isdefined( var_0 ) )
    {
        var_6 = var_0 getcorpseanim();

        if ( animhasnotetrack( var_6, "ignore_ragdoll" ) )
            return;
    }

    if ( isdefined( level.noragdollents ) && level.noragdollents.size )
    {
        foreach ( var_8 in level.noragdollents )
        {
            if ( distancesquared( var_0.origin, var_8.origin ) < 65536 )
                return;
        }
    }

    wait 0.2;

    if ( !isdefined( var_0 ) )
        return;

    if ( var_0 isragdoll() )
        return;

    var_6 = var_0 getcorpseanim();
    var_10 = 0.35;

    if ( animhasnotetrack( var_6, "start_ragdoll" ) )
    {
        var_11 = getnotetracktimes( var_6, "start_ragdoll" );

        if ( isdefined( var_11 ) )
            var_10 = var_11[0];
    }

    var_12 = var_10 * getanimlength( var_6 );
    wait(var_12);

    if ( isdefined( var_0 ) )
        var_0 startragdoll( 1 );
}

getmostkilledby()
{
    var_0 = "";
    var_1 = 0;
    var_2 = getarraykeys( self.killedby );

    for ( var_3 = 0; var_3 < var_2.size; var_3++ )
    {
        var_4 = var_2[var_3];

        if ( self.killedby[var_4] <= var_1 )
            continue;

        var_1 = self.killedby[var_4];
        var_5 = var_4;
    }

    return var_0;
}

getmostkilled()
{
    var_0 = "";
    var_1 = 0;
    var_2 = getarraykeys( self.killedplayers );

    for ( var_3 = 0; var_3 < var_2.size; var_3++ )
    {
        var_4 = var_2[var_3];

        if ( self.killedplayers[var_4] <= var_1 )
            continue;

        var_1 = self.killedplayers[var_4];
        var_0 = var_4;
    }

    return var_0;
}

damageshellshockandrumble( var_0, var_1, var_2, var_3, var_4, var_5 )
{
    thread maps\mp\gametypes\_weapons::onweapondamage( var_0, var_1, var_2, var_3, var_5 );
    self playrumbleonentity( "damage_heavy" );
}

revivesetup( var_0 )
{
    var_1 = var_0.team;
    self linkto( var_0, "tag_origin" );
    self.owner = var_0;
    self.inuse = 0;
    self makeusable();
    updateusablebyteam( var_1 );
    thread trackteamchanges( var_1 );
    thread revivetriggerthink( var_1 );
    thread deleteonreviveordeathordisconnect();
}

deleteonreviveordeathordisconnect()
{
    self endon( "death" );
    self.owner common_scripts\utility::waittill_any( "death", "disconnect" );
    self delete();
}

updateusablebyteam( var_0 )
{
    foreach ( var_2 in level.players )
    {
        if ( var_0 == var_2.team && var_2 != self.owner )
        {
            self enableplayeruse( var_2 );
            continue;
        }

        self disableplayeruse( var_2 );
    }
}

trackteamchanges( var_0 )
{
    self endon( "death" );

    for (;;)
    {
        level waittill( "joined_team" );
        updateusablebyteam( var_0 );
    }
}

tracklaststandchanges( var_0 )
{
    self endon( "death" );

    for (;;)
    {
        level waittill( "player_last_stand" );
        updateusablebyteam( var_0 );
    }
}

revivetriggerthink( var_0 )
{
    self endon( "death" );
    level endon( "game_ended" );

    for (;;)
    {
        self waittill( "trigger", var_1 );
        self.owner.beingrevived = 1;

        if ( isdefined( var_1.beingrevived ) && var_1.beingrevived )
        {
            self.owner.beingrevived = 0;
            continue;
        }

        self makeunusable();
        self.owner maps\mp\_utility::freezecontrolswrapper( 1 );
        var_2 = useholdthink( var_1 );
        self.owner.beingrevived = 0;

        if ( !isalive( self.owner ) )
        {
            self delete();
            return;
        }

        self.owner maps\mp\_utility::freezecontrolswrapper( 0 );

        if ( var_2 )
        {
            var_1 thread maps\mp\gametypes\_hud_message::splashnotifydelayed( "reviver", 200 );
            var_1 thread maps\mp\gametypes\_rank::giverankxp( "reviver", 200 );
            self.owner.laststand = undefined;
            self.owner maps\mp\_utility::clearlowermessage( "last_stand" );
            self.owner.movespeedscaler = 1;

            if ( self.owner maps\mp\_utility::_hasperk( "specialty_lightweight" ) )
                self.owner.movespeedscaler = maps\mp\_utility::lightweightscalar();

            self.owner.maxhealth = 100;
            self.owner maps\mp\gametypes\_weapons::updatemovespeedscale();
            self.owner maps\mp\gametypes\_playerlogic::laststandrespawnplayer();
            self.owner maps\mp\_utility::giveperk( "specialty_pistoldeath", 0 );
            self.owner.beingrevived = 0;
            self delete();
            return;
        }

        self makeusable();
        updateusablebyteam( var_0 );
    }
}

useholdthink( var_0 )
{
    var_1 = spawn( "script_origin", self.origin );
    var_1 hide();
    var_0 playerlinkto( var_1 );
    var_0 playerlinkedoffsetenable();
    var_0 common_scripts\utility::_disableweapon();
    self.curprogress = 0;
    self.inuse = 1;
    self.userate = 0;
    self.usetime = 3000;
    var_0 thread personalusebar( self );
    var_2 = useholdthinkloop( var_0 );

    if ( isdefined( var_0 ) && maps\mp\_utility::isreallyalive( var_0 ) )
    {
        var_0 unlink();
        var_0 common_scripts\utility::_enableweapon();
    }

    if ( isdefined( var_2 ) && var_2 )
    {
        self.owner thread maps\mp\gametypes\_hud_message::playercardsplashnotify( "revived", var_0 );
        self.owner.inlaststand = 0;
        return 1;
    }

    self.inuse = 0;
    var_1 delete();
    return 0;
}

personalusebar( var_0 )
{
    var_1 = maps\mp\gametypes\_hud_util::createprimaryprogressbar();
    var_2 = maps\mp\gametypes\_hud_util::createprimaryprogressbartext();
    var_2 settext( &"MPUI_REVIVING" );
    var_3 = var_0.owner maps\mp\gametypes\_hud_util::createprimaryprogressbar();
    var_4 = var_0.owner maps\mp\gametypes\_hud_util::createprimaryprogressbartext();
    var_4 settext( &"MPUI_BEING_REVIVED" );
    var_5 = -1;

    while ( maps\mp\_utility::isreallyalive( self ) && isdefined( var_0 ) && var_0.inuse && !level.gameended && isdefined( self ) )
    {
        if ( var_5 != var_0.userate )
        {
            if ( var_0.curprogress > var_0.usetime )
                var_0.curprogress = var_0.usetime;

            var_1 maps\mp\gametypes\_hud_util::updatebar( var_0.curprogress / var_0.usetime, 1000 / var_0.usetime * var_0.userate );
            var_3 maps\mp\gametypes\_hud_util::updatebar( var_0.curprogress / var_0.usetime, 1000 / var_0.usetime * var_0.userate );

            if ( !var_0.userate )
            {
                var_1 maps\mp\gametypes\_hud_util::hideelem();
                var_2 maps\mp\gametypes\_hud_util::hideelem();
                var_3 maps\mp\gametypes\_hud_util::hideelem();
                var_4 maps\mp\gametypes\_hud_util::hideelem();
            }
            else
            {
                var_1 maps\mp\gametypes\_hud_util::showelem();
                var_2 maps\mp\gametypes\_hud_util::showelem();
                var_3 maps\mp\gametypes\_hud_util::showelem();
                var_4 maps\mp\gametypes\_hud_util::showelem();
            }
        }

        var_5 = var_0.userate;
        wait 0.05;
    }

    if ( isdefined( var_1 ) )
        var_1 maps\mp\gametypes\_hud_util::destroyelem();

    if ( isdefined( var_2 ) )
        var_2 maps\mp\gametypes\_hud_util::destroyelem();

    if ( isdefined( var_3 ) )
        var_3 maps\mp\gametypes\_hud_util::destroyelem();

    if ( isdefined( var_4 ) )
        var_4 maps\mp\gametypes\_hud_util::destroyelem();
}

useholdthinkloop( var_0 )
{
    level endon( "game_ended" );
    self.owner endon( "death" );
    self.owner endon( "disconnect" );

    while ( maps\mp\_utility::isreallyalive( var_0 ) && var_0 usebuttonpressed() && self.curprogress < self.usetime )
    {
        self.curprogress += 50 * self.userate;
        self.userate = 1;

        if ( self.curprogress >= self.usetime )
        {
            self.inuse = 0;
            return maps\mp\_utility::isreallyalive( var_0 );
        }

        wait 0.05;
    }

    return 0;
}

callback_killingblow( var_0, var_1, var_2, var_3, var_4, var_5, var_6, var_7, var_8, var_9 )
{
    if ( isdefined( self.lastdamagewasfromenemy ) && self.lastdamagewasfromenemy && var_2 >= self.health && isdefined( self.combathigh ) && self.combathigh == "specialty_endgame" )
    {
        maps\mp\_utility::giveperk( "specialty_endgame", 0 );
        return 0;
    }

    return 1;
}

emitfalldamage( var_0 )
{
    physicsexplosionsphere( self.origin, 64, 64, 1 );
    var_1 = [];

    for ( var_2 = 0; var_2 < 360; var_2 += 30 )
    {
        var_3 = cos( var_2 ) * 16;
        var_4 = sin( var_2 ) * 16;
        var_5 = bullettrace( self.origin + ( var_3, var_4, 4 ), self.origin + ( var_3, var_4, -6 ), 1, self );

        if ( isdefined( var_5["entity"] ) && isdefined( var_5["entity"].targetname ) && ( var_5["entity"].targetname == "destructible_vehicle" || var_5["entity"].targetname == "destructible_toy" ) )
            var_1[var_1.size] = var_5["entity"];
    }

    if ( var_1.size )
    {
        var_6 = spawn( "script_origin", self.origin );
        var_6 hide();
        var_6.type = "soft_landing";
        var_6.destructibles = var_1;
        radiusdamage( self.origin, 64, 100, 100, var_6 );
        wait 0.1;
        var_6 delete();
    }
}

drawline( var_0, var_1, var_2 )
{
    var_3 = int( var_2 * 20 );

    for ( var_4 = 0; var_4 < var_3; var_4++ )
        wait 0.05;
}

isflankkill( var_0, var_1 )
{
    var_2 = anglestoforward( var_0.angles );
    var_2 = ( var_2[0], var_2[1], 0 );
    var_2 = vectornormalize( var_2 );
    var_3 = var_0.origin - var_1.origin;
    var_3 = ( var_3[0], var_3[1], 0 );
    var_3 = vectornormalize( var_3 );
    var_4 = vectordot( var_2, var_3 );

    if ( var_4 > 0 )
        return 1;
    else
        return 0;
}

_obituary( var_0, var_1, var_2, var_3 )
{
    var_4 = var_0.team;

    foreach ( var_6 in level.players )
    {
        var_7 = var_6.team;

        if ( var_7 == "spectator" )
        {
            var_6 iprintln( &"MP_OBITUARY_NEUTRAL", var_1.name, var_0.name );
            continue;
        }

        if ( var_7 == var_4 )
        {
            var_6 iprintln( &"MP_OBITUARY_ENEMY", var_1.name, var_0.name );
            continue;
        }

        var_6 iprintln( &"MP_OBITUARY_FRIENDLY", var_1.name, var_0.name );
    }
}

logprintplayerdeath( var_0, var_1, var_2, var_3, var_4, var_5, var_6 )
{
    var_7 = self getentitynumber();
    var_8 = self.name;
    var_9 = self.team;
    var_10 = self.guid;

    if ( isplayer( var_1 ) )
    {
        var_11 = var_1.guid;
        var_12 = var_1.name;
        var_13 = var_1.team;
        var_14 = var_1 getentitynumber();
        var_15 = var_1 getxuid() + "(" + var_12 + ")";
    }
    else
    {
        var_11 = "";
        var_12 = "";
        var_13 = "world";
        var_14 = -1;
        var_15 = "none";
    }

    logprint( "K;" + var_10 + ";" + var_7 + ";" + var_9 + ";" + var_8 + ";" + var_11 + ";" + var_14 + ";" + var_13 + ";" + var_12 + ";" + var_4 + ";" + var_2 + ";" + var_3 + ";" + var_6 + "\\n" );
}

destroyonreviveentdeath( var_0 )
{
    var_0 waittill( "death" );
    self destroy();
}

gamemodemodifyplayerdamage( var_0, var_1, var_2, var_3, var_4, var_5, var_6, var_7 )
{
    if ( isdefined( var_1 ) && isplayer( var_1 ) && isalive( var_1 ) )
    {
        if ( level.matchrules_damagemultiplier )
            var_2 *= level.matchrules_damagemultiplier;

        if ( level.matchrules_vampirism )
            var_1.health = int( min( float( var_1.maxhealth ), float( var_1.health + 20 ) ) );
    }

    return var_2;
}

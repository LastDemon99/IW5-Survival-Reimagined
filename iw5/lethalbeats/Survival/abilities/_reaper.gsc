init()
{
    replacefunc(maps\mp\killstreaks\_remotemortar::handletimeout, ::_handleTimeout);
    replacefunc(maps\mp\killstreaks\_remotemortar::damagetracker, ::_handleDamage);
    replacefunc(maps\mp\killstreaks\_remotemortar::remotefiring, ::_remotefiring);
    replacefunc(maps\mp\killstreaks\_remotemortar::tryuseremotemortar, ::_tryuseremotemortar);
    replacefunc(maps\mp\killstreaks\_remotemortar::startremotemortar, ::_startremotemortar);
    replacefunc(maps\mp\killstreaks\_remotemortar::handleownerchangeteam, ::_handleOwnerChangeTeam);
    replacefunc(maps\mp\killstreaks\_remotemortar::handleownerdisconnect, ::_handleOwnerDisconnect);
}

giveAbility()
{
    lethalbeats\Survival\utility::level_wait_vehicle_limit();
	self [[level.killStreakFuncs["remote_mortar"]]]();
    self suicide();
}

_handleTimeout(remote)
{
    if (isDefined(self.team) && self.team == "axis")
        return;

    level endon("game_ended");
    remote endon("disconnect");
    remote endon("removed_reaper_ammo");
    self endon("death");
    
    lifeSpan = 40.0;
    maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause(lifeSpan);
    
    if (isDefined(remote) && isDefined(remote.firingreaper))
    {
        while (remote.firingreaper) wait 0.05;
    }
    
    if (isdefined(remote)) remote maps\mp\killstreaks\_remotemortar::remoteendride(self);
    self thread maps\mp\killstreaks\_remotemortar::remoteleave();
}

_handleOwnerChangeTeam(owner)
{
    if (isDefined(self.team) && self.team == "axis")
        return;
        
    level endon("game_ended");
    self endon("remote_done");
    self endon("death");
    owner endon("disconnect");
    owner endon("removed_reaper_ammo");
    owner common_scripts\utility::waittill_any("joined_team", "joined_spectators");

    if (isdefined(owner))
        owner maps\mp\killstreaks\_remotemortar::remoteendride(self);

    thread maps\mp\killstreaks\_remotemortar::remoteleave();
}

_handleOwnerDisconnect(owner)
{
    if (isDefined(self.team) && self.team == "axis")
        return;

    level endon("game_ended");
    self endon("remote_done");
    self endon("death");
    owner endon("removed_reaper_ammo");
    owner waittill("disconnect");
    thread maps\mp\killstreaks\_remotemortar::remoteleave();
}

_handleDamage()
{
    level endon("game_ended");
    
    if (!isDefined(self.team) || self.team != "axis")
        self.owner endon("disconnect");

    self.health = 999999;
    self.maxhealth = 1500;
    self.damagetaken = 0;
    self thread lethalbeats\survival\patch\mines::mineCreateBombSquadModel("vehicle_predator_bombsquad", self);
    
    if (isDefined(self.owner.botPrice)) self.botPrice = self.owner.botPrice;

    for (;;)
    {
        self waittill("damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon);

        if (!maps\mp\gametypes\_weapons::friendlyFireCheck(self.owner, attacker) || !isdefined(self)) continue;
        if (isdefined(iDFlags) && iDFlags & level.idflags_penetration) self.wasdamagedfrombulletpenetration = 1;

        self.wasdamaged = 1;
        self.damagetaken += self lethalbeats\survival\utility::heli_modified_damage(damage, attacker, weapon, meansOfDeath);

        if (isplayer(attacker)) attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback("");
        if (isdefined(self.owner)) self.owner playlocalsound("reaper_damaged");
        if (self.damagetaken >= self.maxhealth)
        {
            if (isplayer(attacker))
            {
                attacker notify("destroyed_killstreak", weapon);
                thread maps\mp\_utility::teamPlayerCardSplash("callout_destroyed_remote_mortar", attacker);
                attacker thread maps\mp\gametypes\_rank::xpEventPopup(&"SPLASHES_DESTROYED_REMOTE_MORTAR");
                thread maps\mp\gametypes\_missions::vehicleKilled(self.owner, self, undefined, attacker, damage, meansOfDeath, weapon);
            }

            if (self.owner.team == "axis") self lethalbeats\survival\utility::bot_kill(attacker);
            self thread maps\mp\killstreaks\_remotemortar::remoteexplode();
            return;
        }
    }
}

_remotefiring(remote)
{
    level endon("game_ended");
    self endon("disconnect");
    remote endon("remote_done");
    remote endon("death");

    isBotRemoteController = (isDefined(self.isHuman) && !self.isHuman);
    reaperSettings = lethalbeats\survival\difficulty::difficulty_get_reaper_burst_settings();

    if (isBotRemoteController)
    {
        ammo = undefined;
        waitTime = reaperSettings["fireTime"] * 1000;
        windUpTime = reaperSettings["windUpTime"] * 1000;
        botWasVisibleLastTick = false;
        botWindUpUntil = 0;
        botTargetId = -1;
    }
    else
    {
        ammo = 14;
        waitTime = 2200;
        windUpTime = 0;
    }

    curTime = gettime();
    lastFireTime = curTime - waitTime;
    self.firingreaper = 0;

    for (;;)
    {
        curTime = gettime();
        wantsToFire = self attackbuttonpressed() || isBotRemoteController;

        if (wantsToFire && curTime - lastFireTime >= waitTime)
        {
            if (!isDefined(remote) || !isDefined(remote.targetent))
            {
                wait 0.05;
                continue;
            }

            targetPos = remote.targetent.origin;
            missileTargetEnt = remote.targetent;
            
            if (isBotRemoteController)
            {
                botTargetEnt = self _getBotRemoteTargetEnt(remote);
                if (!isDefined(botTargetEnt))
                {
                    botWasVisibleLastTick = false;
                    botTargetId = -1;
                    botWindUpUntil = 0;
                    wait 0.05;
                    continue;
                }

                currentTargetId = botTargetEnt getentitynumber();
                if (!botWasVisibleLastTick || botTargetId != currentTargetId)
                {
                    botWasVisibleLastTick = true;
                    botTargetId = currentTargetId;
                    
                    actualWindUpTime = windUpTime;
                    if (botTargetEnt lethalbeats\player::player_has_perk("specialty_blindeye"))
                        actualWindUpTime = int(windUpTime * getDvarFloat("survival_blindeye_windup_mult"));
                        
                    botWindUpUntil = curTime + actualWindUpTime;
                }

                // Require windup every time LOS is reacquired or target changes.
                if (curTime < botWindUpUntil)
                {
                    wait 0.05;
                    continue;
                }

                targetPos = botTargetEnt getTagOrigin("j_spineupper");
                missileTargetEnt = botTargetEnt;
                remote.targetent.origin = targetPos;
                triggerfx(remote.targetent);
            }

            if (isDefined(ammo))
            {
                ammo--;
                self setclientdvar("ui_reaper_ammoCount", ammo);
            }

            lastFireTime = curTime;
            self.firingreaper = 1;
            self playlocalsound("reaper_fire");
            self playrumbleonentity("damage_heavy");
            origin = self geteye();
            forward = anglestoforward(self getplayerangles());
            right = anglestoright(self getplayerangles());
            offset = origin + forward * 100 + right * -100;
            missile = magicbullet("remote_mortar_missile_mp", offset, targetPos, self);
            earthquake(0.3, 0.5, origin, 256);
            missile missile_settargetent(missileTargetEnt);
            missile missile_setflightmodedirect();
            missile thread maps\mp\killstreaks\_remotemortar::remotemissiledistance(remote);
            missile thread maps\mp\killstreaks\_remotemortar::remotemissilelife(remote);
            missile waittill("death");
            self setclientdvar("ui_reaper_targetDistance", -1);
            self.firingreaper = 0;
            if (isDefined(ammo) && ammo == 0) break;
        }
        else wait 0.05;
    }

    self notify("removed_reaper_ammo");
    maps\mp\killstreaks\_remotemortar::remoteendride(remote);
    remote thread maps\mp\killstreaks\_remotemortar::remoteleave();
}

_getBotRemoteTargetEnt(remote)
{
    originRef = self.origin;
    if (isDefined(remote)) originRef = remote.origin;

    return lethalbeats\survival\utility::bot_get_air_target(originRef, isDefined(remote) ? remote : self);
}

_tryuseremotemortar(lifeId)
{
    if (isDefined(self.team) && self.team == "axis")
    {
        self maps\mp\_matchdata::logKillstreakEvent("remote_mortar", self.origin);
        return _startremotemortar(lifeId);
    }

    self maps\mp\_utility::setUsingRemote("remote_mortar");
    var_1 = self maps\mp\killstreaks\_killstreaks::initridekillstreak("remote_mortar");

    if (var_1 != "success")
    {
        if (var_1 != "disconnect") maps\mp\_utility::clearUsingRemote();
        return 0;
    }

    self maps\mp\_matchdata::logKillstreakEvent("remote_mortar", self.origin);
    return maps\mp\killstreaks\_remotemortar::startremotemortar(lifeId);
}

_startremotemortar(lifeId)
{
    remote = maps\mp\killstreaks\_remotemortar::spawnremote(lifeId, self);

    if (!isdefined(remote))
        return 0;

    level.remote_mortar = remote;
    remote.owner = self;
    remote.team = self.team;
    self.firingreaper = 0;

    if (isDefined(self.team) && self.team == "axis") remote thread _axisReaperAI();
    else remote thread maps\mp\killstreaks\_remotemortar::remoteride(remote);
    
    thread maps\mp\_utility::teamPlayerCardSplash("used_remote_mortar", self);
    return 1;
}

_axisReaperAI()
{
    level endon("game_ended");
    self endon("death");
    self endon("remote_done");

    wait 3;

    self.targetent = spawnfx(level.remote_mortar_fx["laserTarget"], (0, 0, 0));
    self thread _axisReaperTargetingAI();

    reaperSettings = lethalbeats\survival\difficulty::difficulty_get_reaper_burst_settings();
    fireRate = reaperSettings["fireTime"];
    lastFireTime = gettime() - fireRate * 1000;

    for (;;)
    {
        target = self _getBotRemoteTargetEnt();

        if (isDefined(target))
        {
            curTime = gettime();
            if (curTime - lastFireTime >= fireRate * 1000)
            {
                lastFireTime = curTime;
                self.firingreaper = 1;

                launchOrigin = self gettagorigin("tag_player");
                if (!isDefined(launchOrigin))
                    launchOrigin = self.origin;

                forward = anglestoforward(self.angles);
                right = anglestoright(self.angles);
                offset = launchOrigin + forward * 100 + right * -100;

                owner = self.owner;
                missileOwner = owner;
                if (!isDefined(missileOwner)) missileOwner = self;

                missile = magicbullet("remote_mortar_missile_mp", offset, self.targetent.origin, missileOwner);
                missile.type = "remote_mortar";
                missile missile_settargetent(self.targetent);
                missile missile_setflightmodedirect();

                missile thread maps\mp\killstreaks\_remotemortar::remotemissiledistance(self);
                missile thread maps\mp\killstreaks\_remotemortar::remotemissilelife(self);

                missile waittill("death");
                self.firingreaper = 0;
            }
        }

        wait 0.05;
    }
}

_axisReaperTargetingAI()
{
    level endon("game_ended");
    self endon("death");
    self endon("remote_done");

    trackingFactor = lethalbeats\survival\difficulty::difficulty_get_reaper_burst_settings()["trackingFactor"];

    for (;;)
    {
        target = self _getBotRemoteTargetEnt();
        if (isDefined(target))
        {
            targetPos = target getTagOrigin("j_spineupper");
            
            // If first time tracking, snap to position. Otherwise, interpolate for lag effect.
            if (!isDefined(self.lastTargetPos)) self.targetent.origin = targetPos;
            else self.targetent.origin = self.targetent.origin + (targetPos - self.targetent.origin) * trackingFactor;
            
            self.lastTargetPos = targetPos;
            triggerfx(self.targetent);
        }
        wait 0.05;
    }
}

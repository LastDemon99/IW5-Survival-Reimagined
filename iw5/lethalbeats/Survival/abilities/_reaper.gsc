init()
{
	replacefunc(maps\mp\killstreaks\_remotemortar::handletimeout, ::_handleTimeout);
    replacefunc(maps\mp\killstreaks\_remotemortar::damagetracker, ::_handleDamage);
    replacefunc(maps\mp\killstreaks\_remotemortar::remotefiring, ::_remotefiring);
    replacefunc(maps\mp\killstreaks\_remotemortar::tryuseremotemortar, ::_tryuseremotemortar);
}

giveAbility()
{
    lethalbeats\Survival\utility::level_wait_vehicle_limit();
	self [[level.killStreakFuncs["remote_mortar"]]]();
}

_handleTimeout(remote)
{
	if (self.team == "axis") return;
    level endon("game_ended");
    remote endon("disconnect");
    remote endon("removed_reaper_ammo");
    self endon("death");
    lifeSpan = 40.0;
    maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause(lifeSpan);
    while (remote.firingreaper) wait 0.05;
    if (isdefined(remote)) remote maps\mp\killstreaks\_remotemortar::remoteendride(self);
    self thread maps\mp\killstreaks\_remotemortar::remoteleave();
}

_handleDamage()
{
    level endon("game_ended");
    self.owner endon("disconnect");
    self.health = 999999;
    self.maxhealth = 1500;
    self.damagetaken = 0;

    for (;;)
    {
        self waittill("damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon);

        if (!maps\mp\gametypes\_weapons::friendlyFireCheck(self.owner, attacker) || !isdefined(self)) continue;
        if (isdefined(iDFlags) && iDFlags & level.idflags_penetration) self.wasdamagedfrombulletpenetration = 1;

        self.wasdamaged = 1;
        self.damagetaken += self lethalbeats\survival\utility::heli_modified_damage(damage, attacker, weapon);

        if (isplayer(attacker)) attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback("");
        if (isdefined(self.owner)) self.owner playlocalsound("reaper_damaged");
        if (self.damagetaken >= self.maxhealth)
        {
            if (isplayer(attacker) && (!isdefined(self.owner) || attacker != self.owner))
            {
                attacker notify("destroyed_killstreak", weapon);
                thread maps\mp\_utility::teamPlayerCardSplash("callout_destroyed_remote_mortar", attacker);
                attacker thread maps\mp\gametypes\_rank::xpEventPopup(&"SPLASHES_DESTROYED_REMOTE_MORTAR");
                thread maps\mp\gametypes\_missions::vehicleKilled(self.owner, self, undefined, attacker, damage, meansOfDeath, weapon);
            }
            self.owner lethalbeats\survival\utility::bot_kill(attacker);
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
                    botWindUpUntil = curTime + windUpTime;
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
    survivorsAlives = lethalbeats\survival\utility::survivors(true);
    if (!isDefined(survivorsAlives) || !survivorsAlives.size)
        return undefined;

    originRef = self.origin;
    if (isDefined(remote)) originRef = remote.origin;

    closestTarget = undefined;
    closestDist = 2147483647;

    foreach (survivor in survivorsAlives)
    {
        if (!isDefined(survivor) || !isPlayer(survivor)) continue;
        if (!(survivor lethalbeats\survival\utility::player_is_valid_target())) continue;
        if (!maps\mp\_utility::isReallyAlive(survivor) || survivor.inLastStand) continue;

        if (isDefined(remote) && !bullettracepassed(originRef, survivor getTagOrigin("j_spineupper"), false, remote))
            continue;

        dist = distanceSquared(originRef, survivor.origin);
        if (dist < closestDist)
        {
            closestDist = dist;
            closestTarget = survivor;
        }
    }

    if (!isDefined(closestTarget))
        return undefined;

    return closestTarget;
}

_tryuseremotemortar( var_0 )
{
    self maps\mp\_utility::setUsingRemote( "remote_mortar" );
    var_1 = self maps\mp\killstreaks\_killstreaks::initridekillstreak( "remote_mortar" );

    if ( var_1 != "success" )
    {
        if ( var_1 != "disconnect" )
            maps\mp\_utility::clearUsingRemote();

        return 0;
    }

    self maps\mp\_matchdata::logKillstreakEvent( "remote_mortar", self.origin );
    return maps\mp\killstreaks\_remotemortar::startremotemortar( var_0 );
}

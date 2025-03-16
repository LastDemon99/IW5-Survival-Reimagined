init()
{
	replacefunc(maps\mp\killstreaks\_remotemortar::handletimeout, ::_handleTimeout);
    replacefunc(maps\mp\killstreaks\_remotemortar::damagetracker, ::_handleDamage);
    replacefunc(maps\mp\killstreaks\_remotemortar::remotefiring, ::_remotefiring);
    replacefunc(maps\mp\killstreaks\_remotemortar::tryuseremotemortar, ::_tryuseremotemortar);
}

giveAbility()
{
    lethalbeats\Survival\utility::waitVehicleLimit();
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
    maps\mp\gametypes\_hostmigration::waitlongdurationwithhostmigrationpause(lifeSpan);
    while (remote.firingreaper) wait 0.05;
    if (isdefined(remote)) remote maps\mp\killstreaks\_remotemortar::remoteendride(self);
    self thread maps\mp\killstreaks\_remotemortar::remoteleave();
}

_handleDamage()
{
    level endon("game_ended");
    self.owner endon("disconnect");
    self.health = 9999;
    self.maxhealth = 1500;
    self.damagetaken = 0;

    for (;;)
    {
        self waittill("damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon);

        if (!maps\mp\gametypes\_weapons::friendlyfirecheck(self.owner, attacker) || !isdefined(self)) continue;
        if (isdefined(iDFlags) && iDFlags & level.idflags_penetration) self.wasdamagedfrombulletpenetration = 1;

        self.wasdamaged = 1;
        modifiedDamage = damage;

        if (isplayer(attacker))
        {
            attacker maps\mp\gametypes\_damagefeedback::updatedamagefeedback("");
            if (meansOfDeath == "MOD_RIFLE_BULLET" || meansOfDeath == "MOD_PISTOL_BULLET")
            {
                if (attacker maps\mp\_utility::_hasperk("specialty_armorpiercing"))
                    modifiedDamage += damage * level.armorpiercingmod;
            }
        }

        if (isdefined(weapon))
        {
            switch (weapon)
            {
                case "stinger_mp":
                case "javelin_mp":
                    self.largeprojectiledamage = 1;
                    modifiedDamage = self.maxhealth + 1;
                    break;
                case "sam_projectile_mp":
                    self.largeprojectiledamage = 1;
                    break;
            }
        }

        self.damagetaken += modifiedDamage;

        if (isdefined(self.owner)) self.owner playlocalsound("reaper_damaged");
        if (self.damagetaken >= self.maxhealth)
        {
            if (isplayer(attacker) && (!isdefined(self.owner) || attacker != self.owner))
            {
                attacker notify("destroyed_killstreak", weapon);
                thread maps\mp\_utility::teamplayercardsplash("callout_destroyed_remote_mortar", attacker);
                attacker thread maps\mp\gametypes\_rank::xpeventpopup(&"SPLASHES_DESTROYED_REMOTE_MORTAR");
                thread maps\mp\gametypes\_missions::vehiclekilled(self.owner, self, undefined, attacker, damage, meansOfDeath, weapon);
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
    
    curTime = gettime();
    lastFireTime = curTime - 2200;
    ammo = self.team == "axis" ? 999999 : 14;
    self.firingreaper = 0;

    for (;;)
    {
        curTime = gettime();

        if (self attackbuttonpressed() && curTime - lastFireTime > 3000)
        {
            ammo--;
            self setclientdvar("ui_reaper_ammoCount", ammo);
            lastFireTime = curTime;
            self.firingreaper = 1;
            self playlocalsound("reaper_fire");
            self playrumbleonentity("damage_heavy");
            origin = self geteye();
            forward = anglestoforward(self getplayerangles());
            right = anglestoright(self getplayerangles());
            offset = origin + forward * 100 + right * -100;
            missile = magicbullet("remote_mortar_missile_mp", offset, remote.targetent.origin, self);
            earthquake(0.3, 0.5, origin, 256);
            missile missile_settargetent(remote.targetent);
            missile missile_setflightmodedirect();
            missile thread maps\mp\killstreaks\_remotemortar::remotemissiledistance(remote);
            missile thread maps\mp\killstreaks\_remotemortar::remotemissilelife(remote);
            missile waittill("death");
            self setclientdvar("ui_reaper_targetDistance", -1);
            self.firingreaper = 0;
            if (ammo == 0) break;
        }
        else wait 0.05;
    }

    self notify("removed_reaper_ammo");
    maps\mp\killstreaks\_remotemortar::remoteendride(remote);
    remote thread maps\mp\killstreaks\_remotemortar::remoteleave();
}

_tryuseremotemortar( var_0 )
{
    self maps\mp\_utility::setusingremote( "remote_mortar" );
    var_1 = self maps\mp\killstreaks\_killstreaks::initridekillstreak( "remote_mortar" );

    if ( var_1 != "success" )
    {
        if ( var_1 != "disconnect" )
            maps\mp\_utility::clearusingremote();

        return 0;
    }

    self maps\mp\_matchdata::logkillstreakevent( "remote_mortar", self.origin );
    return maps\mp\killstreaks\_remotemortar::startremotemortar( var_0 );
}

init()
{
    replacefunc(maps\mp\killstreaks\_remotetank::tank_handletimeout, ::_handleTimeout);
    replacefunc(maps\mp\killstreaks\_remotetank::tank_handledeath, ::_handleDamage);
}

giveAbility()
{
	lethalbeats\Survival\utility::level_wait_vehicle_limit(true);
	self [[level.killStreakFuncs["remote_tank"]]]();
	lethalbeats\player::players_play_sound("US_1mc_enemy_assault_drone", "allies");
}

_handleTimeout()
{
	if (self.team == "axis") return;
    self endon("death");
    lifeSpan = level.tanksettings[self.tanktype].timeout;
    setdvar("ui_remoteTankUseTime", lifeSpan);
    maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause(lifeSpan);
    self notify("death");
}

_handleDamage(inflictor, attacker, damage, iDFlags, meansOfDeath, weapon, point, dir, hitLoc, timeOffset, modelIndex, partName)
{
    vehicle = isdefined(self.tank) ? self.tank : self;

    if (isdefined(vehicle.alreadydead) && vehicle.alreadydead) return;
    if (!maps\mp\gametypes\_weapons::friendlyFireCheck(vehicle.owner, attacker)) return;
    if (isdefined(iDFlags) && iDFlags & level.idflags_penetration)
        vehicle.wasdamagedfrombulletpenetration = 1;

    vehicle.wasdamaged = 1;
    vehicle.damagefade = 0.0;
    vehicle.owner setplayerdata("ugvDamaged", 1);
    playfxontagforclients(level._effect["remote_tank_spark"], vehicle, "tag_player", vehicle.owner);

    switch (weapon)
    {
        case "artillery_mp":
        case "stealth_bomb_mp":
            damage *= 4;
            break;
    }

    if (meansOfDeath == "MOD_MELEE") damage = vehicle.maxhealth * 0.5;

    modifiedDamage = damage;

    if (isplayer(attacker))
    {
        attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback("remote_tank");
        if (meansOfDeath == "MOD_RIFLE_BULLET" || meansOfDeath == "MOD_PISTOL_BULLET")
        {
            if (attacker maps\mp\_utility::_hasPerk("specialty_armorpiercing"))
                modifiedDamage += damage * level.armorpiercingmod;
        }
        if (isexplosivedamagemod(meansOfDeath)) modifiedDamage += damage;
    }

    if (isexplosivedamagemod(meansOfDeath) && weapon == "destructible_car") modifiedDamage = vehicle.maxhealth;
    if (isdefined(attacker.owner) && isplayer(attacker.owner)) attacker.owner maps\mp\gametypes\_damagefeedback::updateDamageFeedback("remote_tank");

    if (isdefined(weapon))
    {
        switch (weapon)
        {
            case "ac130_105mm_mp":
            case "ac130_40mm_mp":
            case "remotemissile_projectile_mp":
            case "remote_mortar_missile_mp":
            case "stinger_mp":
            case "javelin_mp":
                vehicle.largeprojectiledamage = 1;
                modifiedDamage = vehicle.maxhealth + 1;
                break;
            case "artillery_mp":
            case "stealth_bomb_mp":
                vehicle.largeprojectiledamage = 0;
                modifiedDamage = vehicle.maxhealth * 0.5;
                break;
            case "bomb_site_mp":
                vehicle.largeprojectiledamage = 0;
                modifiedDamage = vehicle.maxhealth + 1;
                break;
            case "emp_grenade_mp":
                modifiedDamage = 0;
                vehicle thread maps\mp\killstreaks\_remotetank::tank_empgrenaded();
                break;
            case "ims_projectile_mp":
                vehicle.largeprojectiledamage = 1;
                modifiedDamage = vehicle.maxhealth * 0.5;
                break;
        }
    }

    vehicle.damagetaken += modifiedDamage;
    vehicle playsound("talon_damaged");

	if (vehicle.damagetaken < vehicle.maxhealth) return;

    if (isplayer(attacker) && (!isdefined(vehicle.owner) || attacker != vehicle.owner))
	{
		vehicle.alreadydead = 1;
		attacker notify("destroyed_killstreak", weapon);
		vehicle.owner lethalbeats\survival\utility::bot_kill(attacker);
		thread maps\mp\_utility::teamPlayerCardSplash("callout_destroyed_remote_tank", attacker);
		attacker thread maps\mp\gametypes\_rank::xpEventPopup(&"SPLASHES_DESTROYED_REMOTE_TANK");
		thread maps\mp\gametypes\_missions::vehicleKilled(vehicle.owner, vehicle, undefined, attacker, damage, meansOfDeath, weapon);
	}

	vehicle notify("death");
}

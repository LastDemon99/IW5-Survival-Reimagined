#include maps\mp\killstreaks\_helicopter;

init()
{
	level.killStreakFuncs["pavelow_survival"] = ::tryUsePaveLow;
    replacefunc(maps\mp\killstreaks\_helicopter::startHelicopter, ::_startHelicopter);
    replacefunc(maps\mp\killstreaks\_helicopter::heli_think, ::_heli_think);
    replacefunc(maps\mp\killstreaks\_helicopter::heli_crash, ::_heli_crash);
    replacefunc(maps\mp\killstreaks\_helicopter::tryUseHelicopter, ::_tryusehelicopter);
}

giveAbility()
{
    lethalbeats\Survival\utility::waitVehicleLimit();
	self [[level.killStreakFuncs["pavelow_survival"]]]();
    self suicide();
}

tryUsePaveLow(lifeId)
{
	return tryUseHelicopter(lifeId, "flares_survial");
}

_startHelicopter(lifeId, heliType)
{
    maps\mp\_utility::incrementfauxvehiclecount();

	if (!isDefined(heliType)) heliType = "";

	switch (heliType)
	{
        case "flares":
		case "flares_survial":
			self thread pavelowMadeSelectionVO();
			eventType = "helicopter_flares";
			break;
		case "minigun":
			eventType = "helicopter_minigun";
			break;
		default:
			eventType = "helicopter";
			break;
	}
	
	team = self.pers["team"];	
	startNode = level.heli_start_nodes[randomInt(level.heli_start_nodes.size)];
	self maps\mp\_matchdata::logKillstreakEvent(eventType, self.origin);	
	self thread heli_think(lifeId, self, startNode, self.pers["team"], heliType);
}

_heli_think(lifeId, owner, startNode, heli_team, heliType)
{
    heliOrigin = startNode.origin;
    heliAngles = startNode.angles;

    switch (heliType)
    {
        case "minigun":
            vehicleType = "cobra_minigun_mp";
            vehicleModel = owner.team == "allies" ? "vehicle_apache_mp" : "vehicle_mi-28_mp";
            break;
        case "flares":
        case "flares_survial":
            vehicleType = "pavelow_mp";
            vehicleModel = owner.team == "allies" ? "vehicle_pavelow" : "vehicle_pavelow_opfor";
            break;
        default:
            vehicleType = "cobra_mp";
            vehicleModel = owner.team == "allies" ? "vehicle_cobra_helicopter_fly_low" : "vehicle_mi24p_hind_mp";
            break;
    }

    heli = spawn_helicopter(owner, heliOrigin, heliAngles, vehicleType, vehicleModel);

    if (!isdefined(heli))
        return;

    heli.botType = owner.botType;
	heli.botPrice = owner.botPrice;

    level.chopper = heli;
    heli.helitype = heliType;
    heli.lifeid = lifeId;
    heli.team = heli_team;
    heli.pers["team"] = heli_team;
    heli.owner = owner;
    heli.maxhealth = heliType == "flares" || heliType == "flares_survial" ? level.heli_maxhealth * 2 : level.heli_maxhealth;
    heli.targeting_delay = level.heli_targeting_delay;
    heli.primarytarget = undefined;
    heli.secondarytarget = undefined;
    heli.attacker = undefined;
    heli.currentstate = "ok";
    heli.empgrenaded = 0;

    if (heliType == "flares" || heliType == "flares_survial" || heliType == "minigun")
        heli thread heli_flares_monitor();

    //heli thread heli_leave_on_disconnect(owner);
    //heli thread heli_leave_on_changeteams(owner);
    //heli thread heli_leave_on_gameended(owner);
    heli thread _heli_damage_monitor();
    heli thread heli_health();
    heli thread heli_existance();
    heli endon("helicopter_done");
    heli endon("crashing");
    heli endon("leaving");
    heli endon("death");

    if (heliType == "minigun")
    {
        owner thread heliride(lifeId, heli);
        //heli thread heli_leave_on_spawned(owner);
    }

    attackAreas = getentarray("heli_attack_area", "targetname");
    loopNode = level.heli_loop_nodes[randomint(level.heli_loop_nodes.size)];

    switch (heliType)
    {
        case "minigun":
            heli thread heli_targeting();
            heli heli_fly_simple_path(startNode);
            heli thread heli_leave_on_timeout(40.0);
            if (attackAreas.size) heli thread heli_fly_well(attackAreas);
            else heli thread heli_fly_loop_path(loopNode);
            break;
        case "flares_survial":
            heli thread makegunship();
            heli heli_fly_simple_path(startNode);
            heli thread heli_fly_loop_path(loopNode);
            break;
        case "flares":
            heli thread makegunship();
            thread maps\mp\_utility::teamplayercardsplash("used_helicopter_flares", owner);
            heli heli_fly_simple_path(startNode);
            heli thread heli_leave_on_timeout(60.0);
            heli thread heli_fly_loop_path(loopNode);
            break;
        default:
            heli thread attack_targets();
            heli thread heli_targeting();
            heli heli_fly_simple_path(startNode);
            heli thread heli_leave_on_timeout(60.0);
            heli thread heli_fly_loop_path(loopNode);
            break;
    }
}

_heli_damage_monitor()
{
    self endon("death");
    self endon("crashing");
    self endon("leaving");

    self.health = 9999;
    self.damagetaken = 0;
    self.recentdamageamount = 0;

    for (;;)
    {
        self waittill("damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon);

        if (isdefined(attacker.class) && attacker.class == "worldspawn") continue;
        if (attacker == self || !maps\mp\gametypes\_weapons::friendlyfirecheck(self.owner, attacker))
            continue;

        self.attacker = attacker;
        modifiedDamage = damage;

        if (isplayer(attacker))
        {
            attacker maps\mp\gametypes\_damagefeedback::updatedamagefeedback("");
            if (meansOfDeath == "MOD_RIFLE_BULLET" || meansOfDeath == "MOD_PISTOL_BULLET")
            {
                if (self.helitype == "flares") modifiedDamage *= level.heli_armor_bulletdamage;
                if (attacker maps\mp\_utility::_hasperk("specialty_armorpiercing")) modifiedDamage += damage * level.armorpiercingmod;
            }
        }

        if (isdefined(attacker.owner) && isplayer(attacker.owner))
            attacker.owner maps\mp\gametypes\_damagefeedback::updatedamagefeedback("helicopter");

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
                    self.largeprojectiledamage = 1;
                    modifiedDamage = self.maxhealth + 1;
                    break;
                case "sam_projectile_mp":
                    self.largeprojectiledamage = 1;
                    switch (self.helitype)
                    {
                        case "osprey":
                        case "osprey_gunner":
                        case "flares":
                            modifiedDamage = self.maxhealth * 0.07;
                            break;
                        case "littlebird":
                        case "helicopter":
                            modifiedDamage = self.maxhealth * 0.09;
                            break;
                    }
                    break;
                case "emp_grenade_mp":
                    modifiedDamage = 0;
                    thread heli_empgrenaded();
                    break;
                case "osprey_player_minigun_mp":
                    self.largeprojectiledamage = 0;
                    modifiedDamage *= 2;
                    break;
            }
        }

        self.damagetaken += modifiedDamage;
        self thread addrecentdamage(modifiedDamage);

        if (self.damagetaken >= self.maxhealth)
        {
            self.largeProjectileDamage = undefined;
            attacker notify("destroyed_helicopter");
            switch (self.helitype)
            {
                case "flares":
                case "flares_survial":
                    attacker thread maps\mp\gametypes\_rank::xpeventpopup(&"SPLASHES_DESTROYED_PAVELOW");
                    thread maps\mp\_utility::teamplayercardsplash("callout_destroyed_helicopter_flares", attacker);
                    break;
                case "minigun":
                    attacker thread maps\mp\gametypes\_rank::xpeventpopup(&"SPLASHES_DESTROYED_MINIGUNNER");
                    thread maps\mp\_utility::teamplayercardsplash("callout_destroyed_helicopter_minigun", attacker);
                    break;
                case "osprey":
                case "osprey_gunner":
                    attacker thread maps\mp\gametypes\_rank::xpeventpopup(&"SPLASHES_DESTROYED_OSPREY");
                    thread maps\mp\_utility::teamplayercardsplash("callout_destroyed_osprey", attacker);
                    break;
                case "littlebird":
                    attacker thread maps\mp\gametypes\_rank::xpeventpopup(&"SPLASHES_DESTROYED_LITTLE_BIRD");
                    thread maps\mp\_utility::teamplayercardsplash("callout_destroyed_little_bird", attacker);
                default:
                    attacker thread maps\mp\gametypes\_rank::xpeventpopup(&"SPLASHES_DESTROYED_HELICOPTER");
                    thread maps\mp\_utility::teamplayercardsplash("callout_destroyed_helicopter", attacker);
                    break;
            }

            self lethalbeats\survival\utility::bot_kill(attacker);
            thread maps\mp\gametypes\_missions::vehiclekilled(self.owner, self, undefined, attacker, damage, meansOfDeath, weapon);
        }
    }
}

_heli_crash()
{
    self thread heli_spin(180);
    self notify("crashing");
	self clearLookAtEnt();
	
	yaw = self.angles[1];
	direction = common_scripts\utility::cointoss() ? (0, yaw + 90, 0) : (0, yaw - 90, 0);	
	direction = self.origin + anglesToForward(direction) * 1500;	
	crashPos = bulletTrace(self.origin, direction - (0, 0, 2000), false, self)["position"];
	
	self setVehGoalPos(crashPos);
	self Vehicle_SetSpeed(60, 45);
	self setTargetYaw(self.angles[1] + randomIntRange(180, 220));
	
	self waittill("goal");
	
	earthquake(1.0, 2.0, crashPos, 7000);
	self radiusDamage(crashPos, 512, 100, 20, self, "MOD_EXPLOSIVE", "bomb_site_mp");

	rot = randomfloat(360);
	explosionEffect = spawnFx(level._effect["bombexplosion"], crashPos + (0, 0, 50), (0, 0, 1), (cos(rot), sin(rot), 0));
	triggerFx(explosionEffect);	
	
	self maps\mp\killstreaks\_helicopter::heli_explode();
}

_tryusehelicopter( lifeId, heliType )
{
    numIncomingVehicles = 1;

    if ( ( !isdefined( heliType ) || heliType == "flares" ) && isdefined( level.chopper ) )
    {
        self iprintlnbold( &"MP_HELI_IN_QUEUE" );

        if ( isdefined( heliType ) )
            streakName = "helicopter_" + heliType;
        else
            streakName = "helicopter";

        thread maps\mp\killstreaks\_killstreaks::updatekillstreaks();
        queueEnt = spawn( "script_origin", ( 0.0, 0.0, 0.0 ) );
        queueEnt hide();
        queueEnt thread deleteonentnotify( self, "disconnect" );
        queueEnt.player = self;
        queueEnt.lifeid = lifeId;
        queueEnt.helitype = heliType;
        queueEnt.streakname = streakName;
        maps\mp\_utility::queueadd( "helicopter", queueEnt );
        
        lastWeapon = undefined;

        if ( !self hasweapon( common_scripts\utility::getlastweapon() ) )
            lastWeapon = maps\mp\killstreaks\_killstreaks::getfirstprimaryweapon();
        else
            lastWeapon = common_scripts\utility::getlastweapon();

        killstreakWeapon = maps\mp\killstreaks\_killstreaks::getkillstreakweapon( "helicopter_flares" );
        thread maps\mp\killstreaks\_killstreaks::waittakekillstreakweapon( killstreakWeapon, lastWeapon );
        return 0;
    }

    numIncomingVehicles = 1;

    if ( isdefined( heliType ) && heliType == "minigun" )
    {
        maps\mp\_utility::setusingremote( "helicopter_" + heliType );
        var_7 = maps\mp\killstreaks\_killstreaks::initridekillstreak();

        if ( var_7 != "success" )
        {
            if ( var_7 != "disconnect" )
                maps\mp\_utility::clearusingremote();

            return 0;
        }

        if ( isdefined( level.chopper ) )
        {
            maps\mp\_utility::clearusingremote();
            self iprintlnbold( &"MP_AIR_SPACE_TOO_CROWDED" );
            return 0;
        }
        else if ( maps\mp\_utility::currentactivevehiclecount() >= maps\mp\_utility::maxvehiclesallowed() || level.fauxvehiclecount + numIncomingVehicles >= maps\mp\_utility::maxvehiclesallowed() )
        {
            maps\mp\_utility::clearusingremote();
            self iprintlnbold( &"MP_TOO_MANY_VEHICLES" );
            return 0;
        }
    }

    starthelicopter( lifeId, heliType );
    return 1;
}

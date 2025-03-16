#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\killstreaks\_autosentry;

#define MINIGUN "minigun_turret"
#define GL "gl_turret"
#define SENTRY "sentry_minigun"

init()
{
	replacefunc(maps\mp\killstreaks\_autosentry::sentry_initSentry, ::sentryInitSentry);
	replacefunc(maps\mp\killstreaks\_autosentry::sentry_setplaced, ::sentrySetPlaced);
	replacefunc(maps\mp\killstreaks\_autosentry::init, lethalbeats\Survival\utility::blank);

	level.sentrytype = [];
	level.sentrytype[SENTRY] = "sentry";
	
	level.killStreakFuncs[MINIGUN] = ::tryUseMinigun;
	level.killStreakFuncs[GL] = ::tryUseGL;
	level.killstreakfuncs[level.sentrytype[SENTRY]] = ::tryuseautosentry;

	level.sentrysettings = [];
	
	level.sentrySettings[MINIGUN] = spawnStruct();
	level.sentrySettings[MINIGUN].health = 9999;
	level.sentrySettings[MINIGUN].maxHealth = 1000;
	level.sentrySettings[MINIGUN].burstMin = 20;
	level.sentrySettings[MINIGUN].burstMax = 120;
	level.sentrySettings[MINIGUN].pauseMin = 0.15;
	level.sentrySettings[MINIGUN].pauseMax = 0.35;	
	level.sentrySettings[MINIGUN].sentryModeOn = "sentry";	
	level.sentrySettings[MINIGUN].sentryModeOff = "sentry_offline";	
	level.sentrySettings[MINIGUN].timeOut = 600;
	level.sentrySettings[MINIGUN].spinupTime = 0.05;	
	level.sentrySettings[MINIGUN].overheatTime = 4.0;	
	level.sentrySettings[MINIGUN].cooldownTime = 0.5;	
	level.sentrySettings[MINIGUN].fxTime = 0.3;	
	level.sentrySettings[MINIGUN].streakName = MINIGUN;
	level.sentrySettings[MINIGUN].weaponInfo = "manned_minigun_turret_mp";
	level.sentrySettings[MINIGUN].modelBase = SENTRY;
	level.sentrySettings[MINIGUN].modelPlacement = "sentry_minigun_obj";
	level.sentrySettings[MINIGUN].modelPlacementFailed = "sentry_minigun_obj_red";
	level.sentrySettings[MINIGUN].modelDestroyed = "sentry_minigun_destroyed";	
	level.sentrySettings[MINIGUN].hintString = &"SENTRY_PICKUP";	
	level.sentrySettings[MINIGUN].headIcon = true;	
	level.sentrySettings[MINIGUN].teamSplash = "used_sentry";	
	level.sentrySettings[MINIGUN].shouldSplash = false;	
	level.sentrySettings[MINIGUN].voDestroyed = "sentry_destroyed";
	
	level.sentrySettings[GL] = spawnStruct();
	level.sentrySettings[GL].health = 9999;
	level.sentrySettings[GL].maxHealth = 1000;
	level.sentrySettings[GL].burstMin = 20;
	level.sentrySettings[GL].burstMax = 120;
	level.sentrySettings[GL].pauseMin = 0.15;
	level.sentrySettings[GL].pauseMax = 0.35;	
	level.sentrySettings[GL].sentryModeOn = "sentry";	
	level.sentrySettings[GL].sentryModeOff = "sentry_offline";	
	level.sentrySettings[GL].timeOut = 600;
	level.sentrySettings[GL].spinupTime = 0.05;	
	level.sentrySettings[GL].overheatTime = 4.0;	
	level.sentrySettings[GL].cooldownTime = 0.5;	
	level.sentrySettings[GL].fxTime = 0.3;	
	level.sentrySettings[GL].streakName = GL;
	level.sentrySettings[GL].weaponInfo = "manned_gl_turret_mp";
	level.sentrySettings[GL].modelBase = "sentry_grenade_launcher_upgrade";
	level.sentrySettings[GL].modelPlacement = "sentry_grenade_launcher_upgrade_obj";
	level.sentrySettings[GL].modelPlacementFailed =	"sentry_grenade_launcher_upgrade_obj_red";
	level.sentrySettings[GL].modelDestroyed = "sentry_grenade_launcher_upgrade_destroyed"; 
	level.sentrySettings[GL].hintString = &"SENTRY_PICKUP";	
	level.sentrySettings[GL].headIcon = true;	
	level.sentrySettings[GL].teamSplash = "used_sentry";	
	level.sentrySettings[GL].shouldSplash = false;	
	level.sentrySettings[GL].voDestroyed = "sentry_destroyed";    

    level.sentrysettings[SENTRY] = spawnstruct();
    level.sentrysettings[SENTRY].health = 999999;
    level.sentrysettings[SENTRY].maxhealth = 1000;
    level.sentrysettings[SENTRY].burstmin = 20;
    level.sentrysettings[SENTRY].burstmax = 120;
    level.sentrysettings[SENTRY].pausemin = 0.15;
    level.sentrysettings[SENTRY].pausemax = 0.35;
    level.sentrysettings[SENTRY].sentrymodeon = "sentry";
    level.sentrysettings[SENTRY].sentrymodeoff = "sentry_offline";
    level.sentrysettings[SENTRY].timeout = 600;
    level.sentrysettings[SENTRY].spinuptime = 0.05;
    level.sentrysettings[SENTRY].overheattime = 8.0;
    level.sentrysettings[SENTRY].cooldowntime = 0.1;
    level.sentrysettings[SENTRY].fxtime = 0.3;
    level.sentrysettings[SENTRY].streakname = "sentry";
    level.sentrysettings[SENTRY].weaponinfo = "sentry_minigun_mp";
    level.sentrysettings[SENTRY].modelbase = "sentry_minigun_weak";
    level.sentrysettings[SENTRY].modelplacement = "sentry_minigun_weak_obj";
    level.sentrysettings[SENTRY].modelplacementfailed = "sentry_minigun_weak_obj_red";
    level.sentrysettings[SENTRY].modeldestroyed = "sentry_minigun_weak_destroyed";
    level.sentrysettings[SENTRY].hintstring = &"SENTRY_PICKUP";
    level.sentrysettings[SENTRY].headicon = 1;
    level.sentrysettings[SENTRY].teamsplash = "used_sentry";
    level.sentrysettings[SENTRY].shouldsplash = 0;
    level.sentrysettings[SENTRY].vodestroyed = "sentry_destroyed";

	level.imsSettings["ims"].lifespan = 600;

    foreach (sentry in level.sentrysettings)
    {
        precacheitem(sentry.weaponinfo);
        precachemodel(sentry.modelbase);
        precachemodel(sentry.modelplacement);
        precachemodel(sentry.modelplacementfailed);
        precachemodel(sentry.modeldestroyed);
        precachestring(sentry.hintstring);

        if (isdefined(sentry.ownerhintstring))
            precachestring(sentry.ownerhintstring);
    }

    level._effect["sentry_overheat_mp"] = loadfx("smoke/sentry_turret_overheat_smoke");
    level._effect["sentry_explode_mp"] = loadfx("explosions/sentry_gun_explosion");
    level._effect["sentry_smoke_mp"] = loadfx("smoke/car_damage_blacksmoke");
}

tryUseMinigun(lifeId)
{
	result = self maps\mp\killstreaks\_autosentry::giveSentry(MINIGUN);
	if (result) self maps\mp\_matchdata::logKillstreakEvent(MINIGUN, self.origin);	
	return (result);	
}

tryUseGL(lifeId)
{
	result = self maps\mp\killstreaks\_autosentry::giveSentry(GL);
	if (result) self maps\mp\_matchdata::logKillstreakEvent(GL, self.origin);
	return (result);	
}

sentryInitSentry(sentryType, owner)
{
	self.sentryType = sentryType;
	self.canBePlaced = true;
	self setModel(level.sentrySettings[self.sentryType].modelBase);
	self.shouldSplash = true;	
	self setCanDamage(true);
		
	switch(sentryType)
	{
		case MINIGUN:
		case GL:
			self SetLeftArc(80);
			self SetRightArc(80);
			self SetBottomArc(50);
			self SetDefaultDropPitch(0.0);
			self.originalOwner = owner;
			break;
		case "sam_turret":
			self SetLeftArc(180);
			self SetRightArc(180);
			self SetTopArc(80);
			self SetDefaultDropPitch(-89.0);
			self.laser_on = false;
			killCamEnt = Spawn("script_model", self GetTagOrigin("tag_laser"));
			killCamEnt LinkTo(self);
			self.killcament = killCamEnt;
			self.killcament setscriptmoverkillcam("explosive");
			break;
		default:
            self setdefaultdroppitch(-89.0);
            break;
	}	
	
	self makeTurretInoperable();
	
	self setTurretModeChangeWait(true);
	self sentry_setInactive();	
	self sentry_setOwner(owner);
	self thread sentryHandleDamage();
	self thread sentry_handleDeath();
	self thread sentry_timeOut();
	
	switch(sentryType)
	{
		case MINIGUN:
		case GL:
            self.momentum = 0;
            self.heatlevel = 0;
            self.cooldownwaittime = 0;
            self.overheated = false;
            thread sentry_handleuse();
            thread sentryAattackTargets();
            thread sentry_beepsounds();
            break;
		case "sam_turret":
            thread sentry_handleuse();
            thread sentry_beepsounds();
            break;
        default:
            thread sentry_handleuse();
            thread sentryAattackTargets();
            thread sentry_beepsounds();
            break;
	}

	if (owner lethalbeats\survival\utility::player_is_survivor()) self thread onSentryDeath();
}

sentryAattackTargets()
{
	self endon("death");
	level endon("game_ended");

	self.momentum = 0;
	self.heatLevel = 0;
	self.overheated = false;
	
	self thread sentry_heatMonitor();
	
	for (;;)
	{
		self waittill_either("turretstatechange", "cooled");

		if (self isFiringTurret()) self thread sentryBurstFireStart();
		else
		{
			self LaserOff();
			self.laser_on = false;
			self sentry_spinDown();
			self thread sentry_burstFireStop();
		}
	}
}

sentryBurstFireStart()
{
	self endon("death");
	self endon("stop_shooting");
	level endon("game_ended");

	self LaserOn();
	self.laser_on = true;

	if (self.owner.team == "axis") self playSound("stinger_locking");
	else wait 0.5;

	self sentry_spinUp();
	fireTime = weaponFireTime(level.sentrySettings[self.sentryType].weaponInfo);
	minShots = level.sentrySettings[self.sentryType].burstMin;
	maxShots = level.sentrySettings[self.sentryType].burstMax;
	minPause = level.sentrySettings[self.sentryType].pauseMin;
	maxPause = level.sentrySettings[self.sentryType].pauseMax;

	is_gl = self.sentryType == GL;

	for (;;)
	{		
		numShots = randomIntRange(minShots, maxShots + 1);		
		for (i = 0; i < numShots && !self.overheated; i++)
		{
			if (is_gl) playsoundatpos(self.origin, "weap_m203_fire_npc");
			
			self shootTurret();
			self.heatLevel += fireTime;
			wait (fireTime);
		}		
		wait (randomFloatRange(minPause, maxPause));
	}
}

sentrySetPlaced()
{
    self setmodel(level.sentrysettings[self.sentrytype].modelbase);

    if (self getmode() == "manual")
        self setmode(level.sentrysettings[self.sentrytype].sentrymodeoff);

    self setsentrycarrier(undefined);
    self setcandamage(1);

    sentry_makesolid();
    self.carriedby forceusehintoff();
    self.carriedby = undefined;

    if (isdefined(self.owner))
		self.owner.iscarrying = 0;

    sentry_setactive();
    self playsound("sentry_gun_plant");
    self notify("placed");
}

onSentryDeath()
{
	level endon("game_ended");	
	self waittill_any("death", "deleting");
	level.sentry--;
}

sentryHandleDamage()
{
	self endon("death");
    level endon("game_ended");

    self.health = level.sentrysettings[self.sentrytype].health;
    self.maxhealth = level.sentrysettings[self.sentrytype].maxhealth;
    self.damagetaken = 0;

    for (;;)
    {
        self waittill("damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon);

		if (!isPlayer(attacker) && isDefined(attacker.owner)) attacker = attacker.owner;
        if ((isPlayer(attacker) && self.owner != attacker && self.owner lethalbeats\survival\utility::player_is_survivor()) || !maps\mp\gametypes\_weapons::friendlyfirecheck(self.owner, attacker))
            continue;

        if (isdefined(iDFlags) && iDFlags & level.idflags_penetration)
            self.wasdamagedfrombulletpenetration = 1;

        switch (weapon)
        {
            case "artillery_mp":
            case "stealth_bomb_mp":
                damage *= 4;
                break;
            case "bomb_site_mp":
                damage = self.maxhealth;
                break;
        }

        if (meansOfDeath == "MOD_MELEE")
            self.damagetaken += self.maxhealth;

        modifiedDamage = damage;

        if (isplayer(attacker))
        {
            attacker maps\mp\gametypes\_damagefeedback::updatedamagefeedback("sentry");

            if (attacker maps\mp\_utility::_hasperk("specialty_armorpiercing"))
                modifiedDamage = damage * level.armorpiercingmod;
        }
		
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
                case "artillery_mp":
                case "stealth_bomb_mp":
                    self.largeprojectiledamage = 0;
                    modifiedDamage += damage * 4;
                    break;
                case "emp_grenade_mp":
                case "bomb_site_mp":
                    self.largeprojectiledamage = 0;
                    modifiedDamage = self.maxhealth + 1;
                    break;
            }
        }

        self.damagetaken += modifiedDamage;

        if (self.damagetaken >= self.maxhealth)
        {
            thread maps\mp\gametypes\_missions::vehiclekilled(self.owner, self, undefined, attacker, damage, meansOfDeath, weapon);

            if (isplayer(attacker) && (!isdefined(self.owner) || attacker != self.owner))
            {
                attacker thread maps\mp\gametypes\_rank::giverankxp("kill", 100, weapon, meansOfDeath);
                attacker notify("destroyed_killstreak");

                if (isdefined(self.uavremotemarkedby) && self.uavremotemarkedby != attacker)
                    self.uavremotemarkedby thread maps\mp\killstreaks\_remoteuav::remoteuav_processtaggedassist();
            }

            if (isdefined(self.owner))
                self.owner thread maps\mp\_utility::leaderdialogonplayer(level.sentrysettings[self.sentrytype].vodestroyed);

            self notify("death");
            return;
        }
    }
}

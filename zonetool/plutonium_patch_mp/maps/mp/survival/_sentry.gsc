#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\killstreaks\_autosentry;

init()
{
	replacefunc(maps\mp\killstreaks\_autosentry::sentry_initSentry, ::sentryInitSentry); // fix sentry init funcs
	replacefunc(maps\mp\killstreaks\_autosentry::sentry_burstFireStart, ::sentryBurstFireStart); // fix gl sound
	replacefunc(maps\mp\killstreaks\_autosentry::sentry_setplaced, ::sentrySetPlaced); // fix undefined hintstring
	
	level.killStreakFuncs["minigun_turret"] = ::tryUseMinigun;
	level.killStreakFuncs["gl_turret"] = ::tryUseGL;
	
	level.sentrySettings["minigun_turret"] = spawnStruct();
	level.sentrySettings["minigun_turret"].health = 1000;
	level.sentrySettings["minigun_turret"].maxHealth = 1000;
	level.sentrySettings["minigun_turret"].burstMin = 20;
	level.sentrySettings["minigun_turret"].burstMax = 120;
	level.sentrySettings["minigun_turret"].pauseMin = 0.15;
	level.sentrySettings["minigun_turret"].pauseMax = 0.35;	
	level.sentrySettings["minigun_turret"].sentryModeOn = "sentry";	
	level.sentrySettings["minigun_turret"].sentryModeOff = "sentry_offline";	
	level.sentrySettings["minigun_turret"].timeOut = 240;
	level.sentrySettings["minigun_turret"].spinupTime = 0.05;	
	level.sentrySettings["minigun_turret"].overheatTime = 4.0;	
	level.sentrySettings["minigun_turret"].cooldownTime = 0.5;	
	level.sentrySettings["minigun_turret"].fxTime = 0.3;	
	level.sentrySettings["minigun_turret"].streakName = "minigun_turret";
	level.sentrySettings["minigun_turret"].weaponInfo = "manned_minigun_turret_mp";
	level.sentrySettings["minigun_turret"].modelBase = "sentry_minigun";
	level.sentrySettings["minigun_turret"].modelPlacement = "sentry_minigun_obj";
	level.sentrySettings["minigun_turret"].modelPlacementFailed = "sentry_minigun_obj_red";
	level.sentrySettings["minigun_turret"].modelDestroyed = "sentry_minigun_destroyed";	
	level.sentrySettings["minigun_turret"].hintString = &"SENTRY_PICKUP";	
	level.sentrySettings["minigun_turret"].headIcon = true;	
	level.sentrySettings["minigun_turret"].teamSplash = "used_sentry";	
	level.sentrySettings["minigun_turret"].shouldSplash = false;	
	level.sentrySettings["minigun_turret"].voDestroyed = "sentry_destroyed";
	
	level.sentrySettings["gl_turret"] = spawnStruct();
	level.sentrySettings["gl_turret"].health = 1000;
	level.sentrySettings["gl_turret"].maxHealth = 1000;
	level.sentrySettings["gl_turret"].burstMin = 20;
	level.sentrySettings["gl_turret"].burstMax = 120;
	level.sentrySettings["gl_turret"].pauseMin = 0.15;
	level.sentrySettings["gl_turret"].pauseMax = 0.35;	
	level.sentrySettings["gl_turret"].sentryModeOn = "sentry";	
	level.sentrySettings["gl_turret"].sentryModeOff = "sentry_offline";	
	level.sentrySettings["gl_turret"].timeOut = 240;
	level.sentrySettings["gl_turret"].spinupTime = 0.05;	
	level.sentrySettings["gl_turret"].overheatTime = 4.0;	
	level.sentrySettings["gl_turret"].cooldownTime = 0.5;	
	level.sentrySettings["gl_turret"].fxTime = 0.3;	
	level.sentrySettings["gl_turret"].streakName = "gl_turret";
	level.sentrySettings["gl_turret"].weaponInfo = "manned_gl_turret_mp";
	level.sentrySettings["gl_turret"].modelBase = "sentry_grenade_launcher_upgrade";
	level.sentrySettings["gl_turret"].modelPlacement = "sentry_grenade_launcher_upgrade_obj";
	level.sentrySettings["gl_turret"].modelPlacementFailed =	"sentry_grenade_launcher_upgrade_obj_red";
	level.sentrySettings["gl_turret"].modelDestroyed = "sentry_grenade_launcher_upgrade_destroyed"; 
	level.sentrySettings["gl_turret"].hintString = &"SENTRY_PICKUP";	
	level.sentrySettings["gl_turret"].headIcon = true;	
	level.sentrySettings["gl_turret"].teamSplash = "used_sentry";	
	level.sentrySettings["gl_turret"].shouldSplash = false;	
	level.sentrySettings["gl_turret"].voDestroyed = "sentry_destroyed";
}

tryUseMinigun(lifeId)
{
	result = self maps\mp\killstreaks\_autosentry::giveSentry("minigun_turret");
	if (result) self maps\mp\_matchdata::logKillstreakEvent("minigun_turret", self.origin);	
	return (result);	
}

tryUseGL(lifeId)
{
	result = self maps\mp\killstreaks\_autosentry::giveSentry("gl_turret");
	if (result) self maps\mp\_matchdata::logKillstreakEvent("gl_turret", self.origin);
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
		case "minigun_turret":
		case "gl_turret":
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
	self thread sentry_handleDamage();
	self thread sentry_handleDeath();
	self thread sentry_timeOut();
	
	switch(sentryType)
	{
		case "minigun_turret":
		case "gl_turret":
            self.momentum = 0;
            self.heatlevel = 0;
            self.cooldownwaittime = 0;
            self.overheated = false;
            thread sentry_handleuse();
            thread sentry_attacktargets();
            thread sentry_beepsounds();
            break;
		case "sam_turret":
            thread sentry_handleuse();
            thread sentry_beepsounds();
            break;
        default:
            thread sentry_handleuse();
            thread sentry_attacktargets();
            thread sentry_beepsounds();
            break;
	}

	self thread onSentryDeath();
}

sentryBurstFireStart()
{
	self endon("death");
	self endon("stop_shooting");
	level endon("game_ended");

	self sentry_spinUp();
	fireTime = weaponFireTime(level.sentrySettings[self.sentryType].weaponInfo);
	minShots = level.sentrySettings[self.sentryType].burstMin;
	maxShots = level.sentrySettings[self.sentryType].burstMax;
	minPause = level.sentrySettings[self.sentryType].pauseMin;
	maxPause = level.sentrySettings[self.sentryType].pauseMax;

	is_gl = self.sentryType == "gl_turret";

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

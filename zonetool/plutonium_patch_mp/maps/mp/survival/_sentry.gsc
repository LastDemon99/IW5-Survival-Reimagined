#include maps\mp\_utility;
#include common_scripts\utility;

init()
{
	replacefunc(maps\mp\killstreaks\_autosentry::sentry_initSentry, ::sentryInitSentry);
	replacefunc(maps\mp\killstreaks\_autosentry::sentry_setPlaced, ::sentrySetPlaced);
	replacefunc(maps\mp\killstreaks\_autosentry::updateSentryPlacement, ::updateSentryPlacement);
	replacefunc(maps\mp\_equipment::trophyBreak, ::trophyBreak);
	replacefunc(maps\mp\_equipment::trophyUseListener, ::trophyUseListener);
	
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
	self SetDefaultDropPitch(-89.0);
	self makeTurretInoperable();
	
	if (sentryType == "sam_turret")
	{
		self SetLeftArc(180);
		self SetRightArc(180);
		self SetTopArc(80);
		self.laser_on = false;
		
		killCamEnt = Spawn("script_model", self GetTagOrigin("tag_laser"));
		killCamEnt LinkTo(self);
		self.killCamEnt = killCamEnt;
	}
	
	owner.isCarryObject = 1;
		
	self setTurretModeChangeWait(true);
	self maps\mp\killstreaks\_autosentry::sentry_setInactive();
	
	self  maps\mp\killstreaks\_autosentry::sentry_setOwner(owner);
	self thread  maps\mp\killstreaks\_autosentry::sentry_handleDamage();
	self thread  maps\mp\killstreaks\_autosentry::sentry_handleDeath();
	self thread  maps\mp\killstreaks\_autosentry::sentry_timeOut();
	
	self thread maps\mp\killstreaks\_autosentry::sentry_handleUse();
	self thread maps\mp\killstreaks\_autosentry::sentry_beepSounds();
	
	self thread onSentryDeath();	
	if (sentryType != "sam_turret") self thread sentryAttackTargets();
}

sentrySetPlaced()
{
	self setModel(level.sentrySettings[self.sentryType].modelBase);
	
	self setSentryCarrier(undefined);
	
	self setCanDamage(true);	
	self maps\mp\killstreaks\_autosentry::sentry_makeSolid();

	self.carriedBy forceUseHintOff();
	self.carriedBy = undefined;

	if(IsDefined(self.owner)) self.owner.isCarrying = 0;
	
	trigger = maps\mp\lethalbeats\_trigger::createTrigger("sentry_move", self.origin, 0, 55, 55, &"SENTRY_MOVE", "allies");
	trigger.sentry = self;
	self.ownerTrigger = trigger;
	
	self SetMode(level.sentrySettings[self.sentryType].sentryModeOn);
	self maps\mp\_entityheadicons::setTeamHeadIcon(self.team, (0, 0, 65));
	self thread maps\mp\killstreaks\_autosentry::sentry_watchDisabled();
	
	self playSound("sentry_gun_plant");
	self notify ("placed");
	
	self.owner.isCarryObject = 0;
	if (!isDefined(self.firstPlaced))
	{
		self.firstPlaced = 1;
		self.owner setClientDvar("ui_streak", "");
	}
	
	self.owner maps\mp\lethalbeats\_trigger::clearCustomHintString();
}

updateSentryPlacement(sentryGun)
{
	self endon ("death");
	self endon ("disconnect");
	level endon ("game_ended");
	
	sentryGun endon ("placed");
	sentryGun endon ("death");
	
	sentryGun.canBePlaced = true;
	lastCanPlaceSentry = -1;

	for(;;)
	{
		placement = self canPlayerPlaceSentry();

		sentryGun.origin = placement["origin"];
		sentryGun.angles = placement["angles"];
		sentryGun.canBePlaced = self isOnGround() && placement["result"] && (abs(sentryGun.origin[2]-self.origin[2]) < 10);
	
		if (sentryGun.canBePlaced != lastCanPlaceSentry)
		{
			if (sentryGun.canBePlaced)
			{
				sentryGun setModel(level.sentrySettings[sentryGun.sentryType].modelPlacement);
				self maps\mp\lethalbeats\_trigger::setCustomHintString(&"SENTRY_PLACE");
			}
			else
			{
				sentryGun setModel(level.sentrySettings[sentryGun.sentryType].modelPlacementFailed);
				self maps\mp\lethalbeats\_trigger::setCustomHintString(&"SENTRY_CANNOT_PLACE");
			}
		}
		
		lastCanPlaceSentry = sentryGun.canBePlaced;		
		wait 0.05;
	}
}

sentryAttackTargets()
{
	self endon("death");
	level endon("game_ended");

	self.momentum = 0;
	self.heatLevel = 0;
	self.overheated = false;
	
	self thread maps\mp\killstreaks\_autosentry::sentry_heatMonitor();
	
	for (;;)
	{
		self waittill_either("turretstatechange", "cooled");

		if (self isFiringTurret())
		{
			self thread maps\mp\killstreaks\_autosentry::sentry_burstFireStart();
			self LaserOn();
		}
		else
		{
			self LaserOff();
			self maps\mp\killstreaks\_autosentry::sentry_spinDown();
			self thread maps\mp\killstreaks\_autosentry::sentry_burstFireStop();
		}
	}
}

onSentryDeath()
{
	level endon("game_ended");
	
	self waittill_any("death", "disconnect");
	
	if(isDefined(self.ownerTrigger))
	{
		self.ownerTrigger notify("delete");
		level.sentry--;
	}
	else self.owner maps\mp\lethalbeats\_trigger::clearCustomHintString();
}

trophyUseListener(owner)
{
	self endon ("death");
	level endon ("game_ended");
	owner endon ("disconnect");
	owner endon ("death");
	
	if(isDefined(self.trigger)) 
	{
		self.trigger MakeUnusable();
		self.trigger delete();
	}
	
	trigger = maps\mp\lethalbeats\_trigger::createTrigger("trophy_pickup", self.origin, 0, 32, 32, &"MP_PICKUP_TROPHY", "allies");
	trigger.trophy = self;	
	self._trigger = trigger;
	
	owner.isCarryObject = 0;
}

trophyBreak()
{
	playfxOnTag(getfx("sentry_explode_mp"), self, "tag_origin");
	playfxOnTag(getfx("sentry_smoke_mp"), self, "tag_origin");
	
	self playsound("sentry_explode");	
	self notify("death");
	
	if (self.owner maps\mp\survival\_utility::is_survivor()) 
	{
		self._trigger notify("delete");
		level.sentry--;
	}
	
	placement = self.origin;
	wait 3;
	if(IsDefined(self)) self delete();
}

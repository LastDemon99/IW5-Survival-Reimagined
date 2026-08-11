#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\killstreaks\_autosentry;

#define SENTRY_SPOT_DIST 300

#define MINIGUN "minigun_turret"
#define GL "gl_turret"
#define SENTRY "sentry"

init()
{
	replacefunc(maps\mp\killstreaks\_autosentry::init, lethalbeats\Survival\utility::blank);
	replacefunc(::sentry_initSentry, ::_sentry_initSentry);
	replacefunc(::sentry_setplaced, ::_sentry_setplaced);
	replaceFunc(::setcarryingsentry, ::_setcarryingsentry);
	replaceFunc(::sentry_handleownerdisconnect, ::_sentry_handleownerdisconnect);
	
	level.killStreakFuncs[MINIGUN] = ::tryUseMinigun;
	level.killStreakFuncs[GL] = ::tryUseGL;
	level.killstreakfuncs[SENTRY] = ::tryUseSentry;

	level.sentrysettings = [];
	
	level.sentrySettings[MINIGUN] = spawnStruct();
	level.sentrySettings[MINIGUN].health = 999999;
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
	level.sentrySettings[MINIGUN].modelBase = "sentry_minigun";
	level.sentrySettings[MINIGUN].modelPlacement = "sentry_minigun_obj";
	level.sentrySettings[MINIGUN].modelPlacementFailed = "sentry_minigun_obj_red";
	level.sentrySettings[MINIGUN].modelDestroyed = "sentry_minigun_destroyed";	
	level.sentrySettings[MINIGUN].hintString = &"SENTRY_PICKUP";	
	level.sentrySettings[MINIGUN].headIcon = true;	
	level.sentrySettings[MINIGUN].teamSplash = "used_sentry";	
	level.sentrySettings[MINIGUN].shouldSplash = false;	
	level.sentrySettings[MINIGUN].voDestroyed = "sentry_destroyed";
	
	level.sentrySettings[GL] = spawnStruct();
	level.sentrySettings[GL].health = 999999;
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
    level.sentrysettings[SENTRY].maxhealth = 500;
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
    level.sentrysettings[SENTRY].headicon = false;
    level.sentrysettings[SENTRY].teamsplash = "used_sentry";
    level.sentrysettings[SENTRY].shouldsplash = 0;
    level.sentrysettings[SENTRY].vodestroyed = "sentry_destroyed";

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

tryUseSentry(lifeId)
{
	result = self giveSentry(SENTRY);
	if (result) self maps\mp\_matchdata::logKillstreakEvent(SENTRY, self.origin);
	return result;
}

tryUseMinigun(lifeId)
{
	result = self giveSentry(MINIGUN);
	if (result) self maps\mp\_matchdata::logKillstreakEvent(MINIGUN, self.origin);	
	return (result);	
}

tryUseGL(lifeId)
{
	result = self giveSentry(GL);
	if (result) self maps\mp\_matchdata::logKillstreakEvent(GL, self.origin);
	return (result);	
}

_sentry_initSentry(sentryType, owner)
{
	self.sentryType = sentryType;
	self.canBePlaced = true;
	self setModel(level.sentrySettings[self.sentryType].modelBase);
	self.shouldSplash = true;	
	self setCanDamage(true);
		
	switch(sentryType)
	{
		case SENTRY:
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
			break;
		default:
            self setdefaultdroppitch(-89.0);
            break;
	}

	self.id = self getentitynumber();	
	self makeTurretInoperable();	
	self setTurretModeChangeWait(true);
	self sentry_setInactive();	
	self sentry_setOwner(owner);
	self thread _sentry_handleDamage();
	self thread _sentry_handleDeath();

	if (owner lethalbeats\survival\utility::player_is_survivor()) self thread sentry_timeOut();
	else level.botsSentry[level.botsSentry.size] = self;
	
	switch(sentryType)
	{
		case MINIGUN:
		case GL:
            self.momentum = 0;
            self.heatlevel = 0;
            self.cooldownwaittime = 0;
            self.overheated = false;
            thread sentry_handleuse();
            thread _sentry_attackTargets();
            thread sentry_beepsounds();
            break;
		case "sam_turret":
            thread sentry_handleuse();
            thread sentry_beepsounds();
            break;
        default:
            thread sentry_handleuse();
            thread _sentry_attackTargets();
            thread sentry_beepsounds();
            break;
	}
}

_sentry_attackTargets()
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

		if (self isFiringTurret()) self thread _sentry_burstFireStart();
		else
		{
			self LaserOff();
			self.laser_on = false;
			self sentry_spinDown();
			self thread sentry_burstFireStop();
		}
	}
}

_sentry_burstFireStart()
{
	self endon("death");
	self endon("stop_shooting");
	level endon("game_ended");

	self LaserOn();
	self.laser_on = true;

	if (self.owner.team == "axis")
	{
		self playSound("stinger_locking");
		target = self getturrettarget(false);
		if (isDefined(target) && isPlayer(target) && target lethalbeats\player::player_has_perk("specialty_blindeye"))
			wait (0.5 * getDvarFloat("survival_blindeye_windup_mult"));
	}
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

_sentry_setplaced()
{
    self setmodel(level.sentrysettings[self.sentrytype].modelbase);
	self thread _sentry_createbombsquadmodel();

    if (self getmode() == "manual")
        self setmode(level.sentrysettings[self.sentrytype].sentrymodeoff);

    self setsentrycarrier(undefined);
    self setcandamage(1);

    sentry_makesolid();
    self.carriedby forceusehintoff();
    self.carriedby = undefined;

	sentry_setactive();
    self playsound("sentry_gun_plant");
    self notify("placed");

	owner = self.owner;
    if (!isdefined(owner)) return;
	
	owner.iscarrying = 0;

	turretInfo = [];
	turretInfo["type"] = self.sentrytype;
	turretInfo["origin"] = lethalbeats\vector::vector_truncate(self.origin, 3);
	turretInfo["angles"] = lethalbeats\vector::vector_truncate(owner.angles, 3);
	owner.turrets[self getentitynumber() + ""] = turretInfo;
	
	if (!isDefined(owner) || owner isTestClient()) return;
	if (isDefined(owner.pers["killstreaks"][0].streakname) && owner.pers["killstreaks"][0].streakname == self.sentrytype) 
		owner.pers["killstreaks"][0].streakname = "";

	owner notify("placed_sentry");
	owner notify("weapon_change", owner getCurrentWeapon());
}

_sentry_handleDamage()
{
	self endon("death");
    level endon("game_ended");

    self.health = level.sentrysettings[self.sentrytype].health;
    self.maxhealth = level.sentrysettings[self.sentrytype].maxhealth;
    self.damagetaken = 0;

    for (;;)
    {
        self waittill("damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon);

		owner = self.owner;
		ownerTeam = owner.team;
		if (!maps\mp\gametypes\_weapons::friendlyFireCheck(owner, attacker)) continue;
		if (isDefined(attacker) && isDefined(attacker.owner)) attacker = attacker.owner;
		if (meansOfDeath == "MOD_MELEE" && isDefined(attacker) && attacker == owner)
		{
			attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback("sentry");
			self.damagetaken += self.maxhealth;
		}
		else
		{
			if (ownerTeam == "allies" || (isDefined(attacker) && isDefined(attacker.team) && ownerTeam == attacker.team)) continue;
			if (isplayer(attacker)) attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback("sentry");
			self.damagetaken += self lethalbeats\survival\utility::equipmen_modified_damage(damage, attacker, weapon, meansOfDeath);
		}

        if (self.damagetaken >= self.maxhealth)
        {
            thread maps\mp\gametypes\_missions::vehicleKilled(self.owner, self, undefined, attacker, damage, meansOfDeath, weapon);

            if (isplayer(attacker) && (!isdefined(self.owner) || attacker != self.owner))
            {
                attacker notify("destroyed_killstreak");
                if (isdefined(self.uavremotemarkedby) && self.uavremotemarkedby != attacker)
                    self.uavremotemarkedby thread maps\mp\killstreaks\_remoteuav::remoteuav_processtaggedassist();
            }

            if (isdefined(owner)) owner thread maps\mp\_utility::leaderDialogOnPlayer(level.sentrysettings[self.sentrytype].vodestroyed);
            self notify("death");
            return;
        }
    }
}

_sentry_handleDeath()
{
    self waittill("death");
    if (!isdefined(self)) return;

	owner = self.owner;
	if (isDefined(owner))
	{
		if (owner lethalbeats\survival\utility::player_is_survivor())
		{
			if (isDefined(owner.turrets)) owner.turrets = lethalbeats\array::array_remove_key(owner.turrets, self.id + "");
			level.survivors_sentry_count--;
		}
		else level.botsSentry = array_remove(level.botsSentry, self);
	}

    self setmodel(level.sentrysettings[self.sentrytype].modeldestroyed);
    sentry_setinactive();
    self setdefaultdroppitch(40);
    self setsentryowner(undefined);
    self setturretminimapvisible(0);

    if (isdefined(self.ownertrigger)) self.ownertrigger delete();
    self playsound("sentry_explode");

    switch (self.sentrytype)
    {
        case "gl_turret":
        case "minigun_turret":
            self.forcedisable = 1;
            self turretfiredisable();
            break;
        default:
            break;
    }

    playfxontag(common_scripts\utility::getfx("sentry_explode_mp"), self, "tag_aim");
	self playsound("sentry_explode_smoke");

	waittillframeend;
	origin = self.origin;
    self playSound("detpack_explo_main");
    playRumbleOnPosition("grenade_rumble", origin);
    earthquake(0.4, 0.75, origin, 512);
    playfx(level.mine_explode, origin);

	self notify("deleting");
    self delete();
}

_sentry_handleownerdisconnect()
{
    self endon("death");
    self notify("sentry_handleOwner");
    self endon("sentry_handleOwner");
    self.owner waittill("disconnect");    
    self notify("death");
}

_setcarryingsentry(sentryGun, allowCancel)
{
    self endon("death");
    self endon("disconnect");

    sentryGun sentry_setcarried(self);
    self lethalbeats\player::player_disable_weapons();

	if (self lethalbeats\survival\utility::player_is_survivor())
	{
		self notifyonplayercommand("place_sentry", "+attack");
		self notifyonplayercommand("place_sentry", "+attack_akimbo_accessible");
		self notifyonplayercommand("cancel_sentry", "+actionslot 4");

		for (;;)
		{
			result = common_scripts\utility::waittill_any_return("place_sentry", "cancel_sentry", "force_cancel_placement");

			if (result == "cancel_sentry" || result == "force_cancel_placement")
			{
				if (!allowCancel && result == "cancel_sentry") continue;
				sentryGun sentry_setcancelled();
				self lethalbeats\player::player_enable_weapons();
				return false;
			}

			if (!sentryGun.canbeplaced) continue;
			sentryGun sentry_setplaced();
			self lethalbeats\player::player_enable_weapons();
			return true;
		}
	}

	for (;;)
    {
		wait 0.35;
        if (sentryGun.canbeplaced && !lethalbeats\utility::is_any_entity_near(level.botsIMS, self.origin, SENTRY_SPOT_DIST))
		{
			sentryGun sentry_setplaced();
			self lethalbeats\player::player_enable_weapons();
			self notify("placed_sentry");
			return true;
		}
    }
}

_sentry_createbombsquadmodel()
{
    if (self.owner lethalbeats\survival\utility::player_is_survivor()) return;
    bombSquadModel = spawn("script_model", self.origin);
    bombSquadModel.angles = self.angles;
    bombSquadModel hide();
    bombSquadModel thread maps\mp\gametypes\_weapons::bombsquadvisibilityupdater("allies", self.owner);
    bombSquadModel setmodel("sentry_minigun_bombsquad");
    bombSquadModel linkto(self);
    bombSquadModel setcontents(0);
    self.bombsquadmodel = bombSquadModel;
    self waittill("death");
    bombSquadModel delete();
}

spawnSentryAtLocation(sentryType, origin, angles, owner)
{
	weaponInfo = level.sentrySettings[sentryType].weaponInfo;
    sentry = spawnTurret("misc_turret", origin, weaponInfo);
	sentry.origin = origin;
	sentry.angles = angles;
    sentry _sentry_initSentry(sentryType, owner);
	sentry.carriedby = owner;
	sentry.sentrytype = sentryType;
	sentry _sentry_setplaced();
	return sentry;
}

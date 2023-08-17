#include maps\mp\_utility;
#include common_scripts\utility;

init()
{
	replacefunc(maps\mp\killstreaks\_airdrop::doFlyBy, ::doFlyBy);
	replacefunc(maps\mp\killstreaks\_airdrop::heliSetup, ::heliSetup);
	replacefunc(maps\mp\killstreaks\_airdrop::waitForDropCrateMsg, ::waitForDropCrateMsg);
	
	level.mi17_fx["light"]["cargo"] = loadfx("misc/aircraft_light_cockpit_red");
	level.mi17_fx["light"]["cockpit"] = loadfx("misc/aircraft_light_cockpit_blue");
	
	maps\mp\killstreaks\_helicopter::precacheHelicopter("vehicle_mi17_woodland_fly_cheap", "pavelow");
	
	level.killstreakFuncs["specialty_quickdraw_ks"] = undefined;
	level.killstreakFuncs["specialty_bulletaccuracy_ks"] = undefined;
	level.killstreakFuncs["specialty_stalker_ks"] = undefined;
	level.killstreakFuncs["specialty_longersprint_ks"] = undefined;
	level.killstreakFuncs["specialty_fastreload_ks"] = undefined;
	level.killstreakFuncs["_specialty_blastshield_ks"] = undefined;
	
	level.giveAirdrop = ::giveAirdrop;
}

doFlyBy(owner, dropSite, dropYaw, dropType, heightAdjustment, crateOverride, customDrop, heliType)
{
	if (!isDefined(owner)) return;
		
	flyHeight = self maps\mp\killstreaks\_airdrop::getFlyHeightOffset(dropSite);
	
	if (isDefined(heightAdjustment)) flyHeight += heightAdjustment;	
	
	foreach(littlebird in level.littlebirds)
		if (isDefined(littlebird.dropType)) flyHeight += 128;

	pathGoal = dropSite * (1,1,0) + (0,0,flyHeight);	
	pathStart = maps\mp\killstreaks\_airdrop::getPathStart(pathGoal, dropYaw);
	pathEnd = maps\mp\killstreaks\_airdrop::getPathEnd(pathGoal, dropYaw);		
	
	pathGoal = pathGoal + (AnglesToForward((0, dropYaw, 0)) * -50);

	chopper = heliSetup(owner, pathStart, pathGoal, dropType, heliType);	
	chopper endon("death");
	
	if(dropType == "jugger")
	{
		owner setOrigin(chopper.origin);
		owner playerLinkTo(chopper);
		owner playerLinkedOffsetEnable();
		owner disableWeapons();
	}
	
	if (!isDefined(crateOverride)) crateOverride = undefined;

	chopper.dropType = dropType;	
	chopper setVehGoalPos(pathGoal, 1);
	
	if(dropType != "jugger") chopper thread maps\mp\killstreaks\_airdrop::dropTheCrate(dropSite, dropType, flyHeight, false, crateOverride, pathStart);
	
	wait 2;
	
	chopper Vehicle_SetSpeed(37, 20);
	chopper SetYawSpeed(180, 180, 180, .3);
	if (heliType == "pavelow_mp") chopper thread mi17_FX();
	
	chopper waittill ("goal");
	wait 0.10;
	
	if(dropType == "jugger")
	{
		chopper thread chopper_drop_smoke_at_unloading(owner, chopper);	
		wait 8;
	}
	else
	{
		if (!isDefined(customDrop)) customDrop = dropType;
		chopper notify("drop_crate", customDrop);
	}
	
	chopper setvehgoalpos(pathEnd, 1);
	chopper Vehicle_SetSpeed(300, 75);
	chopper.leaving = true;
	chopper waittill ("goal");
	chopper notify("leaving");
	chopper notify("delete");
	chopper delete();
}

heliSetup(owner, pathStart, pathGoal, dropType, heliType)
{
	forward = vectorToAngles(pathGoal - pathStart);
	
	heliModel = heliType == "pavelow_mp" ? "vehicle_mi17_woodland_fly_cheap" : "vehicle_little_bird_armed";
	
	lb = SpawnHelicopter(owner, pathStart, forward, heliType, heliModel);
	lb maps\mp\killstreaks\_helicopter::addToLittleBirdList();
	lb thread maps\mp\killstreaks\_helicopter::removeFromLittleBirdListOnDeath();
	
	lb.health = 500; 
	lb.maxhealth = 500;
	lb.damageTaken = 0;
	lb setCanDamage(0);
	
	lb.owner = owner;
	lb.team = owner.team;
	lb.isAirdrop = true;
	
	lb thread maps\mp\killstreaks\_airdrop::watchTimeOut();
	lb thread maps\mp\killstreaks\_airdrop::heli_existence();
	
	//lb thread heliDestroyed();
	//lb thread heli_handleDamage();
	
	lb SetMaxPitchRoll(45, 85);	
	lb Vehicle_SetSpeed(250, 175);
	lb.heliType = "airdrop";

	lb.specialDamageCallback = maps\mp\killstreaks\_airdrop::Callback_VehicleDamage;
	
	return lb;
}

chopper_drop_smoke_at_unloading(jugger, chopper)
{	
	tail_pos = self.origin - (vectornormalize(anglestoforward(self.angles)) * 145);	
	groundposition = getGroundPosition(self.origin, 0, 10000, self.origin[2]);

	playSoundOnPlayers("weap_smokegrenade_pin", "allies");
	wait 2;
	playFx(level.match_events_fx["smoke"],  groundposition);
	playSoundAtPos(groundposition, "smokegrenade_explode_default");	
	wait 2;
	
	jugger unLink();
	jugger setOrigin(groundposition);
	jugger setVelocity((0, 0, 0));
	jugger enableWeapons();
}

mi17_FX()
{
	playFXOnTag(level.mi17_fx["light"]["cargo"], self, "tag_light_cargo01");
	wait 0.05;
	playFXOnTag(level.mi17_fx["light"]["cockpit"], self, "tag_light_cockpit01");
	wait 0.05;
	playFXOnTag(level.chopper_fx["light"]["tail"], self, "tag_light_belly");
	wait 0.05;
	playFXOnTag(level.chopper_fx["light"]["belly"], self, "tag_light_tail");
	wait 0.05;
	playFXOnTag(level.chopper_fx["light"]["left"], self, "tag_light_L_wing");
	wait 0.05;
	playFXOnTag(level.chopper_fx["light"]["right"], self, "tag_light_R_wing");
}

waitForDropCrateMsg(dropCrate, dropImpulse, dropType, crateType)
{
	self waittill("drop_crate", customDrop);
	
	dropCrate Unlink();
	dropCrate PhysicsLaunchServer((0,0,0), dropImpulse);		
	dropCrate thread maps\mp\killstreaks\_airdrop::physicsWaiter(dropType, crateType);
	dropCrate thread onCapturedDrop();
	dropCrate.crateType = customDrop;

	if(IsDefined(dropCrate.killCamEnt))
	{
		dropCrate.killCamEnt Unlink();
		groundTrace = BulletTrace(dropCrate.origin, dropCrate.origin + (0, 0, -10000), false, dropCrate);
		travelDistance = Distance(dropCrate.origin, groundTrace[ "position" ]);
		travelTime = travelDistance / 800;
		dropCrate.killCamEnt MoveTo(groundTrace[ "position" ] + (0.0, 0.0, 300.0), travelTime);
	}
}

giveAirdrop(drop)
{
	self endon("disconnect");
	level endon("game_ended");
	
	weapon = "airdrop_marker_mp";
	self _giveWeapon(weapon, 0);
	self _setActionSlot(4, "weapon", weapon);
	
	for (;;)
    {
		self waittill("grenade_fire", grenade, weaponName);	
		if (weaponName == "airdrop_marker_mp")
		{
			self setClientDvar("ui_streak", "");
			self takeWeapon(weapon);
			grenade thread airdropSmokeDetonate(drop);
			break;
		}
	}
}

onCapturedDrop()
{
	level endon("game_ended");
	
	self waittill("captured", player);
	
	if(self.crateType == "minigun_turret" || self.crateType == "gl_turret")
		player setClientDvar("ui_streak", "dpad_killstreak_sentry_gun_static");
	else
	{
		perk = "";
		_perk = self.crateType;		
		for (i = 0; i < _perk.size - 3; i++) perk += _perk[i];		
		player maps\mp\survival\_utility::giveSurvivalPerk(perk);
	}
}

airdropSmokeDetonate(drop)
{
	self endon ("death");	
	self waittill("missile_stuck");
	self.owner thread doFlyBy(self.owner, self.origin, randomFloat(360), "airdrop_sentry_minigun", undefined, undefined, drop, "littlebird_mp");
	self detonate();
}

/*
crateSetupForUse(hintString, mode, icon)
{	
	trigger = maps\mp\survival\_trigger::createTrigger("take_airdrop", self.origin, 0, 55, 55, hintString);
	self.mode = mode;

	curObjID = maps\mp\gametypes\_gameobjects::getNextObjID();	
	objective_add(curObjID, "invisible", (0,0,0));
	objective_position(curObjID, self.origin);
	objective_state(curObjID, "active");
	
	shaderName = "compass_objpoint_ammo_friendly";
	Objective_Team(curObjID, self.team);		
	self.objIdFriendly = curObjID;

	curObjID = maps\mp\gametypes\_gameobjects::getNextObjID();	
	objective_add(curObjID, "invisible", (0,0,0));
	objective_position(curObjID, self.origin);
	objective_state(curObjID, "active");
	objective_icon(curObjID, "compass_objpoint_ammo_enemy");

	Objective_Team(curObjID, level.otherTeam[self.team]);

	self.objIdEnemy = curObjID;

	self thread maps\mp\killstreaks\_airdrop::crateUseTeamUpdater();
	self maps\mp\_entityheadIcons::setHeadIcon(self.team, icon, (0,0,24), 14, 14, undefined, undefined, undefined, undefined, undefined, false);
	
	self thread crateUseJuggernautUpdater();
}*/
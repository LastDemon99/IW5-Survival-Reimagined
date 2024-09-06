#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\killstreaks\_airdrop;

init()
{
	maps\mp\killstreaks\_helicopter::precacheHelicopter("vehicle_mi17_woodland_fly_cheap", "pavelow");

	level.mi17_fx["light"]["cargo"] = loadfx("misc/aircraft_light_cockpit_red");
	level.mi17_fx["light"]["cockpit"] = loadfx("misc/aircraft_light_cockpit_blue");

	level.chopperStartGoal = [(-660, 205, -355), (-280, 1645, -230), (540, 1085, -250), (1203, 780, -270), (1185, -25, -340), (775, -425, -333), (715, 235, -340), (-95, 640, -295), (115, 1050, -240), (14, 2085, -230)];
}

giveJuggernautPassenger()
{
	self thread _doFlyBy(self, random(level.chopperStartGoal), randomFloat(360));
	self.isJuggernaut = true;
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
	self thread maps\mp\killstreaks\_juggernaut::juggernautSounds();
	self setPerk("specialty_radarjuggernaut", true, false);
}

_doFlyBy(owner, dropSite, dropYaw, heightAdjustment)
{
	if (!isDefined(owner)) return;
		
	flyHeight = self getFlyHeightOffset(dropSite);
	
	if (isDefined(heightAdjustment)) flyHeight += heightAdjustment;	
	
	flyHeight += 128;

	pathGoal = dropSite * (1,1,0) + (0,0,flyHeight);	
	pathStart = getPathStart(pathGoal, dropYaw);
	pathEnd = getPathEnd(pathGoal, dropYaw);
	
	pathGoal = pathGoal + (AnglesToForward((0, dropYaw, 0)) * -50);

	mi17 = _mi17Setup(owner, pathStart, pathGoal);
	mi17 endon("death");
	
	owner setOrigin(mi17.origin);
	owner playerLinkTo(mi17);
	owner playerLinkedOffsetEnable();
	owner disableWeapons();

	mi17 setVehGoalPos(pathGoal, 1);
	
	wait 2;
	
	mi17 Vehicle_SetSpeed(37, 20);
	mi17 SetYawSpeed(180, 180, 180, .3);
	mi17 thread mi17_FX();
	
	mi17 waittill("goal");
	wait 0.10;
	
	mi17 thread mi17_drop_smoke_at_unloading(owner);	
	wait 8;
	
	mi17 setvehgoalpos(pathEnd, 1);
	mi17 Vehicle_SetSpeed(300, 75);
	mi17.leaving = true;
	mi17 waittill ("goal");
	mi17 notify("leaving");
	mi17 notify("delete");
	mi17 delete();
}

_mi17Setup(owner, pathStart, pathGoal)
{
	forward = vectorToAngles(pathGoal - pathStart);	
	mi17 = SpawnHelicopter(owner, pathStart, forward, "pavelow_mp", "vehicle_mi17_woodland_fly_cheap");
	mi17 maps\mp\killstreaks\_helicopter::addToLittleBirdList();
	mi17 thread maps\mp\killstreaks\_helicopter::removeFromLittleBirdListOnDeath();
	
	mi17.health = 900; 
	mi17.maxhealth = 900;
	mi17.damageTaken = 0;
	mi17 setCanDamage(true);
	
	mi17.owner = owner;
	mi17.team = owner.team;
	mi17.isAirdrop = true;
	
	mi17 thread watchTimeOut();
	mi17 thread heli_existence();
	mi17 thread heliDestroyed();
	mi17 thread heli_handleDamage();
	
	mi17 SetMaxPitchRoll(45, 85);	
	mi17 Vehicle_SetSpeed(250, 175);
	mi17.heliType = "airdrop";

	mi17.specialDamageCallback = ::Callback_VehicleDamage;
	
	return mi17;
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

mi17_drop_smoke_at_unloading(jugger)
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

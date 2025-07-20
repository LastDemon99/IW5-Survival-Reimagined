#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\killstreaks\_airdrop;

init()
{
	precacheModel("rope_test_ri");
	precacheModel("fullbody_juggernaut_novisor_b_sp");

	precacheMpAnim("mi17_rope_idle_ri");
	precacheMPAnim("mi17_rope_drop_ri");
	precacheMpAnim("mi17_1_idle");
	precacheMPAnim("mi17_1_drop");

	maps\mp\killstreaks\_helicopter::precacheHelicopter("vehicle_mi17_woodland_fly_cheap", "pavelow");

	level.mi17_fx["light"]["cargo"] = loadfx("misc/aircraft_light_cockpit_red");
	level.mi17_fx["light"]["cockpit"] = loadfx("misc/aircraft_light_cockpit_blue");

	level.juggerDropInUse = [];
}

giveAbility()
{
	lethalbeats\Survival\utility::level_wait_vehicle_limit();

	dropZones = level.juggDrop[getDvar("mapname")];
	dropZone = random(dropZones);

	while(lethalbeats\array::array_contains(level.juggerDropInUse, dropZone))
	{
		dropZone = random(dropZones);
		wait 0.5;
	}
	level.juggerDropInUse[level.juggerDropInUse.size] = dropZone;

	self.isDropped = false;
	self thread _doFlyBy(self, dropZone, randomFloat(360), 825);
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
	self thread maps\mp\killstreaks\_juggernaut::juggernautSounds();
	self setPerk("specialty_radarjuggernaut", true, false);
	self lethalbeats\player::player_unset_Perk("specialty_finalstand");
	self.isjuggernaut = true;
	self.dropWeapon = false;
	self.damageData = undefined;
}

giveAbilityExplosive()
{
	self giveAbility();
	self takeAllWeapons();
	self giveWeapon("m79_mp");
	self giveMaxAmmo("m79_mp");
	self switchToWeapon("m79_mp");
}

_doFlyBy(owner, dropSite, dropYaw, heightAdjustment)
{
	self lethalbeats\player::player_disable_weapons();

	pathGoal = dropSite + (0, 0, heightAdjustment);
	pathStart = getPathStart(pathGoal, dropYaw);
	pathEnd = getPathEnd(pathGoal, dropYaw);
	
	pathGoal = pathGoal + (AnglesToForward((0, dropYaw, 0)) * -50);

	mi17 = _mi17_setup(owner, pathStart, pathGoal);
	mi17.dropSite = dropSite;

	rope = spawn("script_model", mi17 getTagOrigin("tag_fastrope_ri"));
	rope setModel("rope_test_ri");
	rope linkTo(mi17, "tag_fastrope_ri", (0, 0, 0), (mi17.angles[0], 0, mi17.angles[2]));
	rope scriptModelPlayAnim("mi17_rope_idle_ri");

	sp_jugger = spawn("script_model", mi17 getTagOrigin("rear_wheel"));
	sp_jugger setModel("fullbody_juggernaut_novisor_b_sp");
	sp_jugger linkTo(mi17, "rear_wheel", (0, 0, 27), (0, 180, 0)); // tag_detach is wrong for some reason
	sp_jugger scriptModelPlayAnim("mi17_1_drop");

	mi17 setVehGoalPos(pathGoal, 1);
	mi17.models = [rope, sp_jugger];

	self thread _juggerDrop(mi17, rope, sp_jugger);
}

_mi17_setup(owner, pathStart, pathGoal)
{
	forward = vectorToAngles(pathGoal - pathStart);	
	mi17 = SpawnHelicopter(owner, pathStart, forward, "pavelow_mp", "vehicle_mi17_woodland_fly_cheap");
	mi17 maps\mp\killstreaks\_helicopter::addToLittleBirdList();
	mi17 thread maps\mp\killstreaks\_helicopter::removeFromLittleBirdListOnDeath();
	
	mi17.health = 999999;
	mi17.maxhealth = 2000;
	mi17.damageTaken = 0;
	mi17 setCanDamage(true);
	
	mi17.owner = owner;
	mi17.team = owner.team;
	mi17.isAirdrop = true;
	
	mi17 thread watchTimeOut();
	mi17 thread heli_existence();
	mi17 thread _mi17_handleDamage();
	mi17 thread lethalbeats\Survival\abilities\_chopper::lbSurvivalDeathCrash();
	
	mi17 SetMaxPitchRoll(45, 85);	
	mi17 Vehicle_SetSpeed(250, 175);
	mi17.heliType = "airdrop";
	
	return mi17;
}

_juggerDrop(mi17, rope, sp_jugger)
{
	level endon("game_ended");
	mi17 endon("death");

	wait 2;
	
	mi17 Vehicle_SetSpeed(37, 20);
	mi17 SetYawSpeed(180, 180, 180, .3);
	mi17 thread _mi17_fx();
	
	mi17 waittill("goal");
	wait 3;

	rope scriptModelPlayAnim("mi17_rope_drop_ri");
	rope thread _keepRopeTag(mi17);

	sp_jugger scriptModelPlayAnim("mi17_1_drop");
	playSoundOnPlayers("weap_smokegrenade_pin", "allies");

	for (i = 0; i < 335; i++)
	{
		lethalbeats\utility::wait_frame();

		switch(i)
		{
			case 30:
				playFx(level.match_events_fx["smoke"],  mi17.dropSite);
				playSoundAtPos(mi17.dropSite, "smokegrenade_explode_default");
				continue;
			case 60:
				forward = anglesToForward(sp_jugger.angles);
				sp_jugger unlink();
				sp_jugger.origin = rope getTagOrigin("ropejoint10_ri");
				sp_jugger.angles = rope getTagAngles("ropejoint10_ri");
				rope unlink();
				continue;
			case 63:
				thread _juggerRopeDrop(sp_jugger, rope, mi17);
				continue;
			case 115:
				self show();
				self setOrigin(mi17.dropSite + (0, 0, 50));
				self lethalbeats\player::player_enable_weapons();
				sp_jugger delete();
				self.isDropped = true;
				continue;
			case 230:
				mi17 thread maps\mp\killstreaks\_helicopter::heli_leave();
				continue;
		}
	}

	rope delete();
	level.juggerDropInUse = lethalbeats\array::array_remove(level.juggerDropInUse, mi17.dropSite);
}

_keepRopeTag(mi17)
{
	level endon("game_ended");
	mi17 endon("death");
	self endon("death");

	for(;;)
	{
		self moveTo(mi17 getTagOrigin("tag_fastrope_ri"), 0.05);
		waitFrame();
	}
}

_juggerRopeDrop(sp_jugger, rope, mi17)
{
	level endon("game_ended");
	rope endon("death");
	mi17 endon("death");

	for (i = 11; i < 58; i++)
    {
        jointTag = "ropejoint" + ((i >= 10) ? i : "0" + i) + "_ri";
        targetOrigin = rope getTagOrigin(jointTag);
        targetAngles = rope getTagAngles(jointTag);

		time = i < 45 ? 0.08 : 0.04;
        sp_jugger MoveTo(targetOrigin, time);
        sp_jugger RotateTo(targetAngles, time);
        
		wait 0.02;
    }
}

_mi17_handleDamage()
{
	level endon("game_ended");
	self endon("death");

	self setCanDamage(true);

	while(true)
	{
		self waittill("damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon);

		if (!maps\mp\gametypes\_weapons::friendlyFireCheck(self.owner, attacker)) continue;
		if (!isDefined(self)) return;
		if (isPlayer(attacker)) attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback("");

		self.damageTaken += damage;		
		if (self.damageTaken >= self.maxhealth)
		{
			level.juggerDropInUse = lethalbeats\array::array_remove(level.juggerDropInUse, self.dropSite);
			models = self.models;
			if (isDefined(models))
			{
				if (isDefined(models[0])) models[0] delete();
				if (isDefined(models[1])) models[1] delete();
			}

			if (isPlayer(attacker))
			{
				attacker notify("destroyed_helicopter");
				attacker notify("destroyed_killstreak", weapon);
				thread teamPlayerCardSplash("callout_destroyed_helicopter", attacker);	
				attacker thread maps\mp\gametypes\_rank::xpEventPopup(&"SPLASHES_DESTROYED_HELICOPTER");
				thread maps\mp\gametypes\_missions::vehicleKilled(self.owner, self, undefined, attacker, damage, meansOfDeath, weapon);
				attacker lethalbeats\survival\utility::survivor_give_score(int(self.owner.botPrice / 2));
			}

			if(isDefined(self.owner) && !self.owner.isDropped) self.owner lethalbeats\survival\utility::bot_kill(attacker);

			self notify("death");
		}
	}
}

_mi17_fx()
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

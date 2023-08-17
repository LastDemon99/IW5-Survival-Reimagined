#include maps\mp\_utility;
#include common_scripts\utility;

init()
{
	level.killStreakFuncs["littlebird_survival"] = ::tryUseLBSurvival;
	level._effect["bombexplosion"] = loadfx("explosions/tanker_explosion");
}

tryUseLBSurvival(lifeId)
{
	level.fauxVehicleCount++;
	
	littleBird = self createLBSurvival();
	
	if (!isDefined(littleBird))
	{
		level.fauxVehicleCount--;
		return false;	
	}

	self thread startLBSupport(littleBird);	
	return true;
}

createLBSurvival()
{
	heliType = "littlebird_support";
	startNode = random(level.air_start_nodes);
	flyHeight = self maps\mp\killstreaks\_airdrop::getFlyHeightOffset(self.origin);
	
	lb = spawnHelicopter(self, startNode.origin, startNode.angles, "attack_littlebird_mp", level.heliGuardSettings[heliType].modelBase);
	if (!isDefined(lb)) return;
		
	lb maps\mp\killstreaks\_helicopter::addToLittleBirdList();
	lb thread maps\mp\killstreaks\_helicopter::removeFromLittleBirdListOnDeath();

	lb.health = 9999; // //why 9999?... on last pluto updates for some reason the heli dies before damagetaken == self.maxhealth, it seems that there is another damage handle func
	lb.maxHealth = 9999;
	lb.customHealth = self.maxHealth;
	lb.damageTaken = 0;
	lb.speed = 100;
	lb.followSpeed = 40;
	lb.owner = self;
	lb.team = self.team;
	lb setMaxPitchRoll(45, 45);	
	lb Vehicle_SetSpeed(lb.speed, 100, 40);
	lb setYawSpeed(120, 60);
	lb setneargoalnotifydist(512);
	lb.killCount = 0;
	lb.heliType = "littlebird";
	lb.targettingRadius = 2000;

	closestNode = maps\mp\killstreaks\_helicopter_guard::lbSupport_getClosestNode(self.origin);	
	forward = anglesToForward(self.angles);
	targetPos = (closestNode.origin * (1,1,0)) + ((0,0,1) * flyHeight) + (forward * -100);

	lb.targetPos = targetPos;
	lb.currentNode = closestNode;
	
	mgTurret = SpawnTurret("misc_turret", lb.origin, level.heliGuardSettings[heliType].weaponInfo);
	mgTurret LinkTo(lb, level.heliGuardSettings[heliType].weaponTagLeft, (0,0,0), (0,0,0));
	mgTurret SetModel(level.heliGuardSettings[heliType].weaponModelLeft);
	mgTurret.angles = lb.angles; 
	mgTurret.owner = lb.owner;
	mgTurret.team = self.team;
	mgTurret makeTurretInoperable();
	mgTurret.vehicle = lb;	
	lb.mgTurretLeft = mgTurret; 
	lb.mgTurretLeft SetDefaultDropPitch(0);
	
	killCamOrigin = (lb.origin + ((AnglesToForward(lb.angles) * -100) + (AnglesToRight(lb.angles) * -100) )) + (0, 0, 50);
	mgTurret.killCamEnt = Spawn("script_model", killCamOrigin);
	mgTurret.killCamEnt LinkTo(lb, "tag_origin");
	
	mgTurret = SpawnTurret("misc_turret", lb.origin, level.heliGuardSettings[heliType].weaponInfo);
	mgTurret LinkTo(lb, level.heliGuardSettings[heliType].weaponTagRight, (0,0,0), (0,0,0));
	mgTurret SetModel(level.heliGuardSettings[heliType].weaponModelRight);
	mgTurret.angles = lb.angles; 
	mgTurret.owner = lb.owner;
	mgTurret.team = self.team;
	mgTurret makeTurretInoperable();
	mgTurret.vehicle = lb;	
	lb.mgTurretRight = mgTurret; 
	lb.mgTurretRight SetDefaultDropPitch(0);

	killCamOrigin = (lb.origin + ((AnglesToForward(lb.angles) * -100) + (AnglesToRight(lb.angles) * 100) )) + (0, 0, 50);
	mgTurret.killCamEnt = Spawn("script_model", killCamOrigin);
	mgTurret.killCamEnt LinkTo(lb, "tag_origin");

	lb.mgTurretLeft setTurretTeam(self.team);
	lb.mgTurretRight setTurretTeam(self.team);

	lb.mgTurretLeft SetMode(level.heliGuardSettings[heliType].sentryMode);
	lb.mgTurretRight SetMode(level.heliGuardSettings[heliType].sentryMode);
 	
	lb.mgTurretLeft SetSentryOwner(self);
	lb.mgTurretRight SetSentryOwner(self);
	
	lb.mgTurretLeft thread lbSurvivalAttackTargets();
	lb.mgTurretRight thread lbSurvivalAttackTargets();
	
	lb.attract_strength = 10000;
	lb.attract_range = 150;
	lb.attractor = Missile_CreateAttractorEnt(lb, lb.attract_strength, lb.attract_range);

	lb.hasDodged = false;
	
	lb thread lbSurvivalHandleDamage();
	lb thread lbSurvivalWatchDeath();
	lb thread maps\mp\killstreaks\_helicopter_guard::lbSupport_lightFX();
	
	return lb;
}

startLBSupport(littleBird)
{			
	level endon("game_ended");
	littleBird endon("death");
	
	littleBird setVehGoalPos(littleBird.targetPos);	
	littleBird waittill("near_goal");
	littleBird Vehicle_SetSpeed(littleBird.speed, 60, 30);	
	littleBird waittill ("goal");
	
	littleBird thread lbSurvivalfollowPlayer();
}

lbSurvivalHandleDamage() 
{
	level endon("game_ended");
	self endon("death");
	
	self setCanDamage(true);
	
	damageState = int(self.customHealth / 3.5);
	state = 1;

	for (;;)
	{
		if(!isDefined(self)) break;
		
		self waittill("damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon);
		
		if (!maps\mp\gametypes\_weapons::friendlyFireCheck(self.owner, attacker)) continue;
		if (!isDefined(self)) return;

		self.wasDamaged = true;
		self.damageTaken += damage;
		
		if(state != 4)
		{
			if (state == 1 && self.damageTaken >= damageState * state)
			{
				playfxontag(level.chopper_fx["damage"]["light_smoke"], self, "tail_rotor_jnt");
				state++;
			}
			if (state == 2 && self.damageTaken >= damageState * state)
			{
				playfxontag(level.chopper_fx["damage"]["heavy_smoke"], self, "tail_rotor_jnt");
				state++;
			}
			if (state == 3 && self.damageTaken >= damageState * state)
			{
				playfxontag(level.chopper_fx["damage"]["on_fire"], self, "tail_rotor_jnt");
				state++;
			}
		}
		
		if(isPlayer(attacker))
		{					
			if(attacker != self.owner && Distance2D(attacker.origin, self.origin) <= self.targettingRadius && !attacker _hasPerk("specialty_blindeye"))
			{
				self setLookAtEnt(attacker);
				self.mgTurretLeft SetTargetEntity(attacker);
				self.mgTurretRight SetTargetEntity(attacker);
			}
			attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback("helicopter");
		}
		
		if(isDefined(attacker.owner) && isPlayer(attacker.owner)) 
			attacker.owner maps\mp\gametypes\_damagefeedback::updateDamageFeedback("helicopter");
		
		if (self.damageTaken >= self.customHealth)
		{			
			stopfxontag(level.chopper_fx["damage"]["light_smoke"], self, "tail_rotor_jnt");
			stopfxontag(level.chopper_fx["damage"]["heavy_smoke"], self, "tail_rotor_jnt");
			stopfxontag(level.chopper_fx["damage"]["on_fire"], self, "tail_rotor_jnt");
			
			if (isPlayer(attacker) && (!isDefined(self.owner) || attacker != self.owner))
			{
				attacker.waveSummary["kills"]++;
				attacker notify("destroyed_helicopter");
				attacker notify("destroyed_killstreak", weapon);
				thread teamPlayerCardSplash("callout_destroyed_little_bird", attacker);			
				attacker thread maps\mp\gametypes\_rank::giveRankXP("kill", self.owner.botPrice, weapon, meansOfDeath);		
				attacker thread maps\mp\gametypes\_rank::xpEventPopup(&"SPLASHES_DESTROYED_LITTLE_BIRD");
				thread maps\mp\gametypes\_missions::vehicleKilled(self.owner, self, undefined, attacker, damage, meansOfDeath, weapon);				
				attacker maps\mp\survival\_utility::giveScore(self.owner.botPrice);
			}

			if(isDefined(self.owner)) self.owner thread leaderDialogOnPlayer("lbguard_destroyed");

			level.bots_death++;
			if(level.bots_death == level.bots_count) level notify("wave_end");

			self notify("death");
		}
		
	}
}

lbSurvivalWatchDeath()
{
	level endon("game_ended");
	self endon("gone" );	
	self waittill("death");
	
	self clearLookAtEnt();
	
	yaw = self.angles[1];
	direction = cointoss() ? (0, yaw + 90, 0) : (0, yaw - 90, 0);	
	direction = self.origin + anglesToForward(direction) * 1500;	
	crashPos = bulletTrace(self.origin, direction - (0, 0, 2000), false, self)["position"];
	
	self setVehGoalPos(crashPos);
	self Vehicle_SetSpeed(self.speed, 60, 30);
	
	self thread lbSurvivalSpinDeath();
	
	self waittill("goal");
	
	earthquake(0.75, 2.0, crashPos, 2000);
	self radiusDamage(crashPos, 512, 100, 20, self, "MOD_EXPLOSIVE", "bomb_site_mp");

	rot = randomfloat(360);
	explosionEffect = spawnFx(level._effect["bombexplosion"], crashPos + (0, 0, 50), (0, 0, 1), (cos(rot), sin(rot), 0));
	triggerFx(explosionEffect);	
	
	self maps\mp\killstreaks\_helicopter_guard::lbExplode();
}

lbSurvivalSpinDeath()
{
	self endon("goal");
	
	for(;;)
	{
		if (!isDefined(self)) return;
		iRand = randomIntRange(180, 220);
		self setTargetYaw(self.angles[1] + iRand);
		wait 0.5;
	}
}

lbSurvivalAttackTargets()
{
	self.vehicle endon("death");
	self.vehicle endon("leaving");
	self endon("stop_shooting");
	level endon("game_ended");
	
	for (;;)
	{
		for (i = 0; i < 40; i++)
		{
			targetEnt = self GetTurretTarget(false);
			if (IsDefined(targetEnt) && (!IsDefined(targetEnt.spawntime) || (gettime() - targetEnt.spawntime)/1000 > 5))
			{
				self.vehicle SetLookAtEnt(targetEnt);
				self ShootTurret();
			}
			wait 0.1;
		}
		wait randomIntRange(2, 3);
	}
}

lbSurvivalfollowPlayer()
{
	level endon("game_ended");
	self endon("death");
	
	self Vehicle_SetSpeed(self.followSpeed, 20, 20);
	
	for(;;)
	{
		foreach(player in level.players)
			if(player.team == "allies" && isAlive(player) && (!isDefined(level.axisTarget) || (level.axisTarget != player && Distance2D(player.origin, self.origin) < Distance2D(level.axisTarget.origin, self.origin))))
			{
				self ClearLookAtEnt();
				level.axisTarget = player;
				self SetLookAtEnt(player);
				self.mgTurretLeft SetTargetEntity(player);
				self.mgTurretRight SetTargetEntity(player);
			}
		
		currentNode = maps\mp\killstreaks\_helicopter_guard::lbSupport_getClosestLinkedNode(level.axisTarget.origin + randomvectorrange(-500, 500));
		if(isDefined(currentNode) && currentNode != self.currentNode)
		{
			self.currentNode = currentNode;
			self maps\mp\killstreaks\_helicopter_guard::lbSupport_moveToPlayer();
			continue;
		}
		wait 1;
	}
}
#include maps\mp\_utility;
#include common_scripts\utility;
#include lethalbeats\array;

#define MIN_HELI_SEPARATION 1500
#define BLIND_SPOT_DOT_PRODUCT 0.95
#define AGGRESSIVE_RADIUS_MIN 700
#define AGGRESSIVE_RADIUS_MAX 1400
#define AGGRESSIVE_DECISION_TIME_MIN 2
#define AGGRESSIVE_DECISION_TIME_MAX 4

init()
{
	level.killStreakFuncs["littlebird_survival"] = ::tryUseLBSurvival;
	level._effect["bombexplosion"] = loadfx("explosions/tanker_explosion");
	level.lbNodeInUse = [];
	level.activeHeliGoals = [];
	level.nextHeliAttackSector = 0;
}

giveAbility()
{
	lethalbeats\Survival\utility::level_wait_vehicle_limit();
	self [[level.killStreakFuncs["littlebird_survival"]]]();
	self suicide();
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
	flyHeight = self maps\mp\killstreaks\_airdrop::getFlyHeightOffset(self.origin);

	goal = undefined;
	yaw = undefined;
	
	hasNodeSystem = level.air_node_mesh.size > 0;

	if (isDefined(level.air_start_nodes) && level.air_start_nodes.size)
	{
		startNode = random(level.air_start_nodes);
		goal = startNode.origin;
		yaw = startNode.angles;
	}
	else if (isDefined(level.heli_start_nodes) && level.heli_start_nodes.size)
	{
		startNode = random(level.heli_start_nodes);
		goal = startNode.origin;
		yaw = startNode.angles;
	}

	if (!isDefined(goal)) goal = level.mapcenter + ((randomfloat(1) * 2 - 1, randomfloat(1) * 2 - 1, 0) * 500);
	if (!isDefined(yaw))
	{
		pathStart = maps\mp\killstreaks\_airdrop::getPathStart(goal, randomInt(360));
		yaw = vectorToAngles(goal - pathStart);
	}
	
	lb = spawnHelicopter(self, goal, yaw, "attack_littlebird_mp", level.heliGuardSettings[heliType].modelBase);
	if (!isDefined(lb)) return;
	
	lb.botType = self.botType;
	lb.botPrice = self.botPrice;		
	lb maps\mp\killstreaks\_helicopter::addToLittleBirdList();
	lb thread maps\mp\killstreaks\_helicopter::removeFromLittleBirdListOnDeath();
	lb.health = 999999;
	lb.maxhealth = 999999;
	
	difficulty = getDvarInt("survival_enemy_difficulty");
	speedMultiplier = 1.0;
	targetingMultiplier = 1.0;
	
	switch(difficulty)
	{
		case 1:
			speedMultiplier = 0.8;
			targetingMultiplier = 0.75;
			break;
		case 2:
			speedMultiplier = 0.9;
			targetingMultiplier = 0.875;
			break;
		default:
			speedMultiplier = 1.0;
			targetingMultiplier = 1.0;
			break;
	}
	
	lb.customHealth = self.maxHealth;
	lb.damageTaken = 0;
	lb.speed = int(100 * speedMultiplier);
	lb.followSpeed = int(40 * speedMultiplier);
	lb.owner = self;
	lb.team = self.team;
	lb setMaxPitchRoll(45, 45);	
	lb Vehicle_SetSpeed(lb.speed, 100, 40);
	lb setYawSpeed(int(120 * speedMultiplier), int(60 * speedMultiplier));
	lb setneargoalnotifydist(512);
	lb.killCount = 0;
	lb.heliType = "littlebird";
	lb.targettingRadius = int(2000 * targetingMultiplier);
	lb.flyHeight = flyHeight;
	lb.minFlyHeight = 500;
	lb.difficulty = difficulty; 
	lb.currentGoalPos = undefined;
	lb.hasNodeSystem = hasNodeSystem;

	if (lb.hasNodeSystem)
	{
		survivors = lethalbeats\survival\utility::survivors(true);
		if(isDefined(survivors) && survivors.size > 0)
			closestNode = maps\mp\killstreaks\_helicopter_guard::lbSupport_getClosestNode(array_random(survivors).origin);
		else
			closestNode = maps\mp\killstreaks\_helicopter_guard::lbSupport_getClosestNode(level.mapcenter);
		
		lb.targetPos = (closestNode.origin * (1,1,0)) + ((0,0,1) * flyHeight) + (anglesToForward(self.angles) * -100);
		lb.currentNode = closestNode;
	}
	else
	{
		survivors = lethalbeats\survival\utility::survivors(true);
		target = (isDefined(survivors) && survivors.size > 0) ? array_random(survivors).origin : level.mapcenter;
		lb.targetPos = (target * (1,1,0)) + (0,0,flyHeight);
	}

	mgTurret = SpawnTurret("misc_turret", lb.origin, level.heliGuardSettings[heliType].weaponInfo);
	mgTurret LinkTo(lb, level.heliGuardSettings[heliType].weaponTagLeft, (0,0,0), (0,0,0));
	mgTurret SetModel(level.heliGuardSettings[heliType].weaponModelLeft);
	mgTurret.owner = lb.owner;
	mgTurret.team = self.team;
	mgTurret makeTurretInoperable();
	mgTurret.vehicle = lb;	
	lb.mgTurretLeft = mgTurret; 
	
	mgTurret = SpawnTurret("misc_turret", lb.origin, level.heliGuardSettings[heliType].weaponInfo);
	mgTurret LinkTo(lb, level.heliGuardSettings[heliType].weaponTagRight, (0,0,0), (0,0,0));
	mgTurret SetModel(level.heliGuardSettings[heliType].weaponModelRight);
	mgTurret.owner = lb.owner;
	mgTurret.team = self.team;
	mgTurret makeTurretInoperable();
	mgTurret.vehicle = lb;	
	lb.mgTurretRight = mgTurret; 
	
	lb.mgTurretLeft setTurretTeam(self.team);
	lb.mgTurretRight setTurretTeam(self.team);
	lb.mgTurretLeft SetMode(level.heliGuardSettings[heliType].sentryMode);
	lb.mgTurretRight SetMode(level.heliGuardSettings[heliType].sentryMode);
	lb.mgTurretLeft SetSentryOwner(self);
	lb.mgTurretRight SetSentryOwner(self);
	
	lb.mgTurretLeft thread lbBurstFireController();
	lb.mgTurretRight thread lbBurstFireController();
	
	lb.attract_strength = 10000;
	lb.attract_range = 150;
	lb.attractor = Missile_CreateAttractorEnt(lb, lb.attract_strength, lb.attract_range);
	lb.hasDodged = false;
	
	lb thread lbSurvivalHandleDamage();
	lb thread lbSurvivalDeathCrash();
	lb thread maps\mp\killstreaks\_helicopter_guard::lbSupport_lightFX();
	lb thread handleIncomingMissiles();

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
	littleBird thread lbSurvivalFollowPlayer_Dispatcher();
}

lbSurvivalFollowPlayer_Dispatcher()
{
	level endon("game_ended");
	self endon("death");
	
	if (self.hasNodeSystem) self thread followPlayer_NodeBased();
	else
	{
		self.attackSector = level.nextHeliAttackSector % 4;
		level.nextHeliAttackSector++;
		self.focusOffsetX = randomFloatRange(-100, 100);
		self.focusOffsetY = randomFloatRange(-100, 100);		
		self thread followPlayer_Dynamic();
	}
}

followPlayer_NodeBased()
{
	level endon("game_ended");
	self endon("death");
	
	self Vehicle_SetSpeed(self.followSpeed, 20, 20);
	
	for(;;)
	{
		wait randomIntRange(2, 4);

		target = sortByDistance(lethalbeats\survival\utility::survivors(true), self.origin)[0];
        if(!isDefined(target))
        {
            wait 1;
            continue;
        }

		nodes = array_filter(self.currentNode.neighbors, ::_nodeFilter);
		
        if (!isDefined(nodes) || nodes.size == 0)
			currentNode = maps\mp\killstreaks\_helicopter_guard::lbSupport_getClosestNode(target.origin);
        else
			currentNode = array_random(nodes);

		if (!isDefined(currentNode) || currentNode == self.currentNode) continue;

		level.lbNodeInUse = array_remove(level.lbNodeInUse, self.currentNode);
		level.lbNodeInUse = array_append(level.lbNodeInUse, currentNode);
		self.currentNode = currentNode;
		self maps\mp\killstreaks\_helicopter_guard::lbSupport_moveToPlayer();
		
		self ClearLookAtEnt();
		self SetLookAtEnt(target);
	}
}

followPlayer_Dynamic()
{
	level endon("game_ended");
	self endon("death");
	
	self Vehicle_SetSpeed(self.followSpeed, 20, 20);
	self.timeForNextMove = gettime();

	for(;;)
	{
		survivors = lethalbeats\survival\utility::survivors(true);
		if (!survivors.size)
		{
			wait 1;
			continue;
		}

		target = sortByDistance(survivors, self.origin)[0];

		is_in_blind_spot = false;
		vector_to_target = vectornormalize(target.origin - self.origin);
		dot = vectordot(vector_to_target, (0,0,-1));
		if (dot > BLIND_SPOT_DOT_PRODUCT)
			is_in_blind_spot = true;
		
		if (is_in_blind_spot || gettime() >= self.timeForNextMove)
		{
			if (isDefined(self.currentGoalPos))
			{
				level.activeHeliGoals = array_remove(level.activeHeliGoals, self.currentGoalPos);
				self.currentGoalPos = undefined;
			}
			
			focusPoint = target.origin + (self.focusOffsetX, self.focusOffsetY, 0);

			newGoalPos = undefined;
			for (i = 0; i < 10; i++)
			{
				altitude = self.flyHeight;
				radius = randomIntRange(AGGRESSIVE_RADIUS_MIN, AGGRESSIVE_RADIUS_MAX);
				
				if (is_in_blind_spot)
				{
					radius *= 1.25; 
					self.attackSector = (self.attackSector + 1) % 4;
                    if (self.origin[2] > self.minFlyHeight + 100)
						altitude = max(self.origin[2] - 300, self.minFlyHeight);
				}

				angle = randomFloatRange(self.attackSector * 90, (self.attackSector * 90) + 90);
				offset = (Cos(angle) * radius, Sin(angle) * radius, 0);
				candidatePos = (focusPoint * (1,1,0)) + offset + (0,0,altitude);
				
				isTooClose = false;
				foreach (otherGoal in level.activeHeliGoals)
				{
					if (distanceSquared(candidatePos, otherGoal) < (MIN_HELI_SEPARATION * MIN_HELI_SEPARATION))
					{
						isTooClose = true;
						break;
					}
				}
				
				if (!isTooClose)
				{
					newGoalPos = candidatePos;
					break;
				}
			}

			if (!isDefined(newGoalPos))
			{
				offset = (Cos(randomint(360)) * AGGRESSIVE_RADIUS_MAX * 1.5, Sin(randomint(360)) * AGGRESSIVE_RADIUS_MAX * 1.5, 0);
				newGoalPos = (target.origin * (1,1,0)) + offset + (0,0,self.flyHeight);
			}

			self.currentGoalPos = newGoalPos;
			level.activeHeliGoals[level.activeHeliGoals.size] = self.currentGoalPos;
			self setVehGoalPos(self.currentGoalPos);
			
			self.timeForNextMove = gettime() + randomIntRange(AGGRESSIVE_DECISION_TIME_MIN, AGGRESSIVE_DECISION_TIME_MAX) * 1000;
		}

		best_target = self.mgTurretLeft getturrettarget(false);
		if (!isDefined(best_target))
			best_target = target;
			
		self ClearLookAtEnt();
		self SetLookAtEnt(best_target);
		
		wait 0.2;
	}
}

handleIncomingMissiles()
{
	level endon("game_ended");
	self endon("death");

	for(;;)
	{
		level waittill("missile_fired", missile, stinger);
		if (isDefined(missile.target) && missile.target == self && !self.hasDodged)
		{
			self.hasDodged = true;
			self thread evadeMissile(missile);
		}
		wait 0.1;
	}
}

evadeMissile(missile)
{
	self endon("death");
	
	strafeDir = anglestoright(self.angles) * (coinToss() ? 1 : -1);
	evadePos = self.origin + (strafeDir * 500);
	self setVehGoalPos(evadePos, 1);
	
	wait 2.0;

	self.hasDodged = false;
	self.timeForNextMove = 0;
}

lbBurstFireController()
{
    self.vehicle endon("death");
    level endon("game_ended");

    for (;;)
    {
        self waittill("turretstatechange");		
        if (self isfiringturret()) thread lbBurstFireStart();
        else self notify("stop_shooting");
    }
}

lbBurstFireStart()
{
    self.vehicle endon("death");
    self.vehicle endon("leaving");
    self endon("stop_shooting");
    level endon("game_ended");

    difficulty = self.vehicle.difficulty;
    
    fireTime = 0.1;
    minShots = 40;
    maxShots = 80;
    minPause = 1.0;
    maxPause = 2.0;
    
    switch(difficulty)
    {
        case 1:
            fireTime = 0.15;
            minShots = 20;
            maxShots = 40;
            minPause = 1.5;
            maxPause = 3.0;
            break;
        case 2:
            fireTime = 0.12;
            minShots = 30;
            maxShots = 60;
            minPause = 1.25;
            maxPause = 2.5;
            break;
        default:
            fireTime = 0.1;
            minShots = 40;
            maxShots = 80;
            minPause = 1.0;
            maxPause = 2.0;
            break;
    }

    for (;;)
    {
        numShots = randomintrange(minShots, maxShots + 1);
        for (i = 0; i < numShots; i++)
        {
            targetEnt = self getturrettarget(false);
            if (isdefined(targetEnt) && (!isdefined(targetEnt.spawntime) || (gettime() - targetEnt.spawntime) / 1000 > 5) && (isdefined(targetEnt.team) && targetEnt.team != "spectator") && maps\mp\_utility::isReallyAlive(targetEnt) && !targetEnt.inLastStand)
            {
                self.vehicle setlookatent(targetEnt);
                self shootturret();
            }
            wait(fireTime);
        }

        wait(randomfloatrange(minPause, maxPause));
    }
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

		if (isDefined(attacker) && !maps\mp\gametypes\_weapons::friendlyFireCheck(self.owner, attacker)) continue;
		if (!isDefined(self)) return;

		self.wasaDmaged = true;
		self.damageTaken += self lethalbeats\survival\utility::heli_modified_damage(damage, attacker, weapon);
		
		if(state != 4)
		{
			if (state == 1 && self.damageTaken >= damageState * state) { playfxontag(level.chopper_fx["damage"]["light_smoke"], self, "tail_rotor_jnt"); state++; }
			if (state == 2 && self.damageTaken >= damageState * state) { playfxontag(level.chopper_fx["damage"]["heavy_smoke"], self, "tail_rotor_jnt"); state++; }
			if (state == 3 && self.damageTaken >= damageState * state) { playfxontag(level.chopper_fx["damage"]["on_fire"], self, "tail_rotor_jnt"); state++; }
		}
		
		if(isDefined(attacker) && isPlayer(attacker))
		{
			if(attacker != self.owner && Distance2D(attacker.origin, self.origin) <= self.targettingRadius && !attacker lethalbeats\player::player_has_perk("specialty_blindeye"))
			{
				self setLookAtEnt(attacker);
				self.mgTurretLeft SetTargetEntity(attacker);
				self.mgTurretRight SetTargetEntity(attacker);
                self.mgTurretLeft notify("turretstatechange");
				self.mgTurretRight notify("turretstatechange");
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
			
			if (isPlayer(attacker))
			{
				attacker notify("destroyed_helicopter");
				attacker notify("destroyed_killstreak", weapon);
				thread teamPlayerCardSplash("callout_destroyed_little_bird", attacker);	
				attacker thread maps\mp\gametypes\_rank::xpEventPopup(&"SPLASHES_DESTROYED_LITTLE_BIRD");
				thread maps\mp\gametypes\_missions::vehicleKilled(self.owner, self, undefined, attacker, damage, meansOfDeath, weapon);
			}

			self.owner thread leaderDialogOnPlayer("lbguard_destroyed");
			self lethalbeats\survival\utility::bot_kill(attacker);
			self notify("death");
		}
	}
}

lbSurvivalDeathCrash()
{
	level endon("game_ended");
	self endon("gone");
	self endon("leaving");

	self waittill("death");
	
	if (isDefined(self.currentGoalPos))
		level.activeHeliGoals = array_remove(level.activeHeliGoals, self.currentGoalPos);
	
	self thread maps\mp\killstreaks\_helicopter::heli_spin(180);
	self notify("crashing");
	self clearLookAtEnt();
	
	yaw = self.angles[1];
	direction = self.origin + anglesToForward((0, yaw + (coinToss() ? 90 : -90), 0)) * 1500;	
	trace = bulletTrace(self.origin, direction - (0, 0, 2000), false, self);
	crashPos = trace["position"];
	
	self setVehGoalPos(crashPos);
	self Vehicle_SetSpeed(100, 60);
	self setTargetYaw(self.angles[1] + randomIntRange(180, 220));
	
	self waittill("goal");
	
	earthquake(0.75, 2.0, crashPos, 2000);
	self radiusDamage(crashPos, 512, 100, 20, self, "MOD_EXPLOSIVE", "bomb_site_mp");

	rot = randomfloat(360);
	explosionEffect = spawnFx(level._effect["bombexplosion"], crashPos + (0, 0, 50), (0, 0, 1), (cos(rot), sin(rot), 0));
	triggerFx(explosionEffect);	
	
	self maps\mp\killstreaks\_helicopter_guard::lbExplode();
}

_nodeFilter(node) 
{ 
	return !array_contains(level.lbNodeInUse, node) && distance2D(node.origin, level.mapCenter) < level.mapRadius;
}

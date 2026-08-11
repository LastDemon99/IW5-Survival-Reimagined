#include common_scripts\utility;
#include maps\mp\_utility;

#define DOG_PREFIX "german_shepherd_"

#define IDLE "idle" // 3.1
#define UP "traverse_up_40" // 0.633333
#define CONCUSSED "run_flashbang_b" // 3.03333

#define RUN_START "run_start" // 0.5
#define RUNNING "run" // 0.4
#define RUN_LEAN_L "run_lean_L" // 0.4
#define RUN_LEAN_R "run_lean_R" // 0.4
#define RUN_STOP "run_stop" // 0.6
#define RUN_START_L "run_start_l"
#define RUN_START_R "run_start_r"
#define RUN_START_180_L "run_start_180_l"
#define RUN_START_180_R "run_start_180_r"
#define RUN_ATTACK "run_attack_b" // 1.5
#define RUN_JUMP "run_jump_40" // 0.933333
#define RUN_PAIN "run_pain" // 1.56667
#define RUN_TURN_180_TIME 0.73

#define ATTACK_KNOCKDOWN "attack_player" // 4.63333
#define DEATH "death_front" // 1.16667
#define DEATH_NECK_SNAP "player_neck_snap" // 2.3

#define PAIN_SOUND "anml_dog_run_hurt"

#define FLASH "flash_grenade_mp"
#define CONCUSSION "concussion_grenade_mp"

#define DOG_SPEED 330
#define DOG_TICK 0.08
#define DOG_ATTACK_DIST 70
#define DOG_REPATH_TIME 800
#define DOG_REPATH_DIST_SQ 128 * 128
#define DOG_GOAL_REACHED_SQ 44 * 44
#define DOG_DIRECT_DIST_SQ 600 * 600
#define DOG_STUCK_DIST_SQ 12 * 12
#define DOG_MAX_GROUND_Z_DELTA 96
#define DOG_MAX_WORLD_Z_DROP 160
#define DOG_MIN_GROUND_NORMAL_Z 0.62
#define DOG_MAX_ORIENT_PITCH 28
#define DOG_MAX_ORIENT_ROLL 28
#define DOG_SEPARATION_RADIUS 35

#define DOG_STEP_Z 18
#define DOG_STEP_SLOP_SQ 20 * 20
#define DOG_BLOCKED_TICKS 3
#define DOG_DEFLECT_ANGLES [35, -35, 70, -70, 110, -110]

#define DOG_PAIN_TIME 1.56
#define DOG_CONCUSSED_TIME 1.5
#define DOG_ATTACK_TIME 1.5

#define EXPLOSIVE_DAMAGE ["MOD_EXPLOSIVE", "MOD_GRENADE", "MOD_GRENADE_SPLASH", "MOD_PROJECTILE", "MOD_PROJECTILE_SPLASH"]

init()
{
	precacheModel("german_sheperd_dog");

	precacheMpAnim("german_shepherd_attack_ai_01_start_a");
	preCacheMpAnim(DOG_PREFIX + IDLE);
	preCacheMpAnim(DOG_PREFIX + UP);
	preCacheMpAnim(DOG_PREFIX + RUN_JUMP);
	preCacheMpAnim(DOG_PREFIX + RUN_PAIN);
	preCacheMpAnim(DOG_PREFIX + CONCUSSED);
	precacheMpAnim(DOG_PREFIX + RUN_START);
	preCacheMpAnim(DOG_PREFIX + RUNNING);
	preCacheMpAnim(DOG_PREFIX + RUN_START_L);
	preCacheMpAnim(DOG_PREFIX + RUN_START_R);
	preCacheMpAnim(DOG_PREFIX + RUN_START_180_L);
	preCacheMpAnim(DOG_PREFIX + RUN_START_180_R);
	preCacheMpAnim(DOG_PREFIX + RUN_LEAN_L);
	preCacheMpAnim(DOG_PREFIX + RUN_LEAN_R);
	preCacheMpAnim(DOG_PREFIX + RUN_STOP);
	preCacheMpAnim(DOG_PREFIX + RUN_ATTACK);
	preCacheMpAnim(DOG_PREFIX + ATTACK_KNOCKDOWN);
	preCacheMpAnim(DOG_PREFIX + DEATH);
	preCacheMpAnim(DOG_PREFIX + DEATH_NECK_SNAP);
	
	precacheShellShock("dog_bite");
	precacheShader("compassping_enemyyelling");
	precacheMiniMapIcon("compassping_enemyyelling");
}

giveAbility()
{
	self.dropWeapon = false;
	self.lastDroppableWeapon = "none";
	self.damageData = undefined;

	dog = spawnDog(self);
	if (!isDefined(dog)) return;

	self suicide();
}

spawnDog(owner)
{
	origin = owner.origin;
	ground = dogGetGround(origin);
	if (isDefined(ground) && isDefined(ground["position"])) origin = ground["position"];
	
	dog = spawn("script_model", origin);
	dog setModel("german_sheperd_dog");
	dog.angles = (0, owner.angles[1], 0);
	dog notSolid();
	dog.team = "axis";
	dog.botType = owner.botType;
	dog.botPrice = isDefined(owner.botPrice) ? owner.botPrice : 100;
	dog.health = isDefined(owner.health) ? owner.health : 100;
	dog.maxHealth = dog.health;
	dog.damageTaken = 0;
	dog.currentAnim = "";
	dog.actor = [];
	dog.isAttacking = false;
	dog.biteCount = 0;
	dog.isInPain = false;
	dog.isConcussed = false;
	dog.painFase = 0;
	dog.victim = undefined;
	dog.path = [];
	dog.pathIndex = 0;
	dog.lastPathTime = 0;
	dog.lastTargetOrigin = dog.origin;
	dog.stuckTime = 0;
	dog.lastOrigin = dog.origin;

	if (!isDefined(level.dogs)) level.dogs = [];
	level.dogs[level.dogs.size] = dog;

	hitBox = spawn("script_model", dog.origin + (0, 0, 25));
	hitBox.angles = dog.angles;
	hitBox setModel("com_plasticcase_trap_bombsquad");
	hitBox hide();
	hitBox setcandamage(1);
	hitBox setCanRadiusDamage(1);
	hitBox.health = 999999;
	hitBox.maxHealth = dog.maxHealth;
	hitBox.damageTaken = 0;
	hitBox linkTo(dog);
	dog.hitBox = hitBox;

	compassIcon = spawnPlane(owner, "script_model", dog.origin, "compassping_enemyyelling", "compassping_enemyyelling");
	compassIcon notSolid();
	compassIcon linkTo(dog, "tag_origin", (0, 0, 0), (0, 0, 0));
	dog.icon = compassIcon;
	
	if (self lethalbeats\survival\utility::bot_is_martyrdom())
	{
		dog lethalbeats\survival\abilities\_martyrdom::giveAbility();
		dog.is_martyrdom = true;
	}
	else dog.is_martyrdom = false;

	dog dogSetAnim(RUNNING);
	dog thread dogThink();
	dog thread onDogDamage(hitBox);
	dog thread onDogDeath();
	dog thread dogSoundsLoop();

	return dog;
}

onDogDamage(hitBox)
{
	level endon("game_ended");
	self endon("dog_death");
	hitBox endon("death");

	for (;;)
	{
		hitBox waittill("damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon);

		IS_MOD_EXPLOSIVE = lethalbeats\array::array_contains(EXPLOSIVE_DAMAGE, meansOfDeath);

		if (IS_MOD_EXPLOSIVE && self.is_martyrdom) 
			self notify("detonate", attacker);

		if (isDefined(attacker) && isDefined(attacker.team) && attacker.team == "axis" && !IS_MOD_EXPLOSIVE)
			continue;

		if (isPlayer(attacker)) attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback("");

		hitBox.damageTaken += damage;
		if (hitBox.damageTaken >= hitBox.maxHealth)
		{
			self notify("dog_death", attacker);
			break;
		}

		if (isDefined(weapon) && (weapon == FLASH || weapon == CONCUSSION))
		{
			self thread dogPain(true);
			continue;
		}

		if (!self.painFase && (hitBox.damageTaken >= hitBox.maxHealth / 2 || IS_MOD_EXPLOSIVE))
		{
			self.painFase = 1;
			self thread dogPain();
			continue;
		}
	}
}

onDogDeath()
{
	self waittill("dog_death", attacker, knockdownMelee);

	if (!isDefined(knockdownMelee)) knockdownMelee = false;
	if (isDefined(self.hitBox)) self.hitBox delete();
	if (isDefined(self.icon)) self.icon delete();
	if (isDefined(level.dogs)) level.dogs = lethalbeats\array::array_remove(level.dogs, self);
	if (self.is_martyrdom) self notify("detonate", attacker);
	if (isDefined(self.victim) && self.victim.dogKnockdown) self.victim notify("dog_saved");
	if (!knockdownMelee) self lethalbeats\survival\utility::bot_kill(attacker);

	if (isDefined(self.knockdownState) && isDefined(self.victim)) self dogKnockdownStandUp(self.victim);
	if (!knockdownMelee) self scriptModelPlayAnim(DOG_PREFIX + DEATH);
	
	self.knockdownState = undefined;
	self.isAttacking = false;
	self.currentAnim = "";
	lethalbeats\survival\utility::add_corpse(self);
}

dogThink()
{
	level endon("game_ended");
	self endon("dog_death");

	target = undefined;

	for (;;)
	{
		if (self.isInPain || self.isConcussed || isDefined(self.knockdownState))
		{
			wait DOG_TICK;
			continue;
		}
		
		if (self.isAttacking)
		{
			self.isAttacking = false;
			self.currentAnim = "";
		}

		if (!isDefined(target) || !lethalbeats\survival\utility::survivor_filter(target))
		{
			target = self dogGetTarget();
			self dogResetPath();
		}

		if (!isDefined(target))
		{
			self dogSetAnim(IDLE);
			wait 0.2;
			continue;
		}

		distSq = distanceSquared(self.origin, target.origin);
		if (distSq <= DOG_ATTACK_DIST * DOG_ATTACK_DIST)
		{
			self dogAttack(target);
			wait DOG_TICK;
			continue;
		}

		if (distSq <= DOG_DIRECT_DIST_SQ && self dogCanMoveDirect(target) && self dogMoveDirect(target))
		{
			wait DOG_TICK;
			continue;
		}

		if (self dogShouldRepath(target) && !self dogBuildPath(target))
		{
			wait 0.15;
			continue;
		}

		if (!self dogFollowPath(target))
		{
			wait DOG_TICK;
			continue;
		}

		self dogResetPath();
		wait DOG_TICK;
	}
}

dogTurn180(targetYaw)
{
	if (self.isAttacking) return;

	startYaw = self.angles[1];
	yawDelta = angleClamp180(targetYaw - startYaw);
	if (yawDelta >= 0)
	{
		self dogSetAnim(RUN_START_180_L);
		finalYaw = angleClamp180(startYaw + 179);
	}
	else
	{
		self dogSetAnim(RUN_START_180_R);
		finalYaw = angleClamp180(startYaw - 179);
	}

	self rotateTo((0, finalYaw, 0), RUN_TURN_180_TIME);
	self waittill("rotatedone");
}

dogAttack(target)
{
	if (self.isAttacking || self.isInPain || self.isConcussed || !lethalbeats\survival\utility::survivor_filter(target)) return;

	self.isAttacking = true;
	self dogSetAnim(RUN_ATTACK, true);
	self rotateTo((0, vectortoyaw(target.origin - self.origin), 0), 0.1);
	self playSound("anml_dog_attack_jump");
	self waittill("rotatedone");

	wait DOG_ATTACK_TIME / 3;
	if (isDefined(target) && distanceSquared(self.origin, target.origin) <= DOG_ATTACK_DIST * DOG_ATTACK_DIST)
	{
		if (self.biteCount > 1 && !target.dogKnockdown)
		{
			self dogKnockdown(target);
			return;
		}
		else
		{
			if (isDefined(self.victim) && self.victim == target) self.biteCount++;
			self.victim = target;
			target shellshock("dog_bite", 1.0);
			vel = target getVelocity();
			target setVelocity((vel[0] * 0.5, vel[1] * 0.5, vel[2]));
			target lethalbeats\survival\utility::player_do_damage(self, self, 35, undefined, "MOD_MELEE", undefined, target.origin);
			if (target isOnLadder()) target lethalbeats\survival\utility::player_action("gostand");
		}
	}
	wait 1;

	self.isAttacking = false;
	self.currentAnim = "";
}

dogPain(isConcussion)
{
	self endon("dog_death");
	if (self.isInPain) return;
	if (!isDefined(isConcussion)) isConcussion = false;

	self notify("dog_pain");
	self.isInPain = true;
	self.isConcussed = isConcussion;
	self playSound(PAIN_SOUND);
	self dogSetAnim(RUN_PAIN, true);

	if (isDefined(self.knockdownState) && isDefined(self.victim)) self dogKnockdownStandUp(self);
	else wait isConcussion ? DOG_CONCUSSED_TIME : DOG_PAIN_TIME;

	self.isConcussed = false;
	self.isInPain = false;
}

dogSoundsLoop()
{
	level endon("game_ended");
	self endon("dog_death");

	for (;;)
	{
		wait randomIntRange(3, 5);
		if (self.isAttacking) continue;
		playSoundAtPos(self.origin, "anml_dog_bark");
	}
}

dogSetAnim(animation, force)
{
	if (!isDefined(self)) return;
	if (!isDefined(force)) force = false;
	if (!force && self.currentAnim == animation) return;
	self.currentAnim = animation;
	self scriptModelPlayAnim(DOG_PREFIX + animation);
}

dogGetTarget()
{
	targets = lethalbeats\player::players_get_list("allies");
	best = undefined;
	bestDist = undefined;

	foreach(player in targets)
	{
		if (!self lethalbeats\survival\utility::survivor_filter(player)) continue;
		dist = distanceSquared(self.origin, player.origin);
		if (!isDefined(bestDist) || dist < bestDist)
		{
			best = player;
			bestDist = dist;
		}
	}

	return best;
}

//////////////////////////////////////////
//	           DOG KNOCKDOWN   		    //
//////////////////////////////////////////

spawnKnockdownSpot(target)
{
	spot = spawn("script_model", target.origin);
	spot setModel("tag_origin");
	spot notSolid();
	spot.angles = target getPlayerAngles();
	target playerLinkToAbsolute(spot);
	return spot;
}

spawnKnockdownHands(handModel, target)
{
	hands = spawn("script_model", self.spot.origin + (0, 0, 60));
	hands setModel(handModel);
	hands.angles = self.spot.angles;
	hands hide();
	if (isDefined(target)) hands showToPlayer(target);
	return hands;
}

spawnKnockdownBody(bodyModel, headModel, headOrigin, target)
{
	if (isDefined(target)) target lethalbeats\survival\utility::player_hide();

	forward = anglesToForward((0, self.spot.angles[1], 0));
	body = spawn("script_model", self.spot.origin + (forward * 15));
	body.angles = self.spot.angles;
	body setModel(bodyModel);

	head = spawn("script_model", headOrigin);
	head setModel(headModel);
	head linkto(body, "j_spine4", (0, 0, 0), (0, 0, 0));
	body.head = head;

	body hide();
	head hide();
	foreach(player in level.players)
	{
		if (isDefined(target) && target == player) continue;
		body showToPlayer(player);
		head showToPlayer(player);
	}

	return body;
}

dogKnockdown(player)
{
	self endon("dog_death");
	self endon("dog_pain");

	player lethalbeats\dynamicmenus\dynamic_shop::closeShop();
	player setStance("stand");
	player.dogKnockdown = true;

	player lethalbeats\player::player_disable_weapons();
	player lethalbeats\player::player_disable_usability();

	handModel = player getViewModel();
	bodyModel = player.model;
	headModel = player.headmodel;
	headOrigin = player.origin;

	self.spot = spawnKnockdownSpot(player);
	self.spot.spawnOrigin = player.origin;

	forward = anglesToForward(self.angles);
	targetPos = player.origin - (forward * 30);
	self.spot rotateTo(vectorToAngles(-forward), 0.1);
	self moveTo(targetPos, 0.1);
	self.knockdownState = 0;
	wait 0.15;

	self.body = spawnKnockdownBody(bodyModel, headModel, headOrigin, player);
	self.hands = spawnKnockdownHands(handModel, player);

	player thread playerAttackEffect(self.spot, 0.3, 10);
	self.hands scriptModelPlayAnim("player_view_dog_knockdown");
	self.body scriptModelPlayAnim("player_3rd_dog_knockdown");
	self scriptModelPlayAnim("german_shepherd_attack_player");
	self playSound("anml_dog_attack_jump");
	self.knockdownState = 1;
	wait 0.3;

	forward = anglesToForward(self.angles);
	self.hands moveTo(self.hands.origin - (forward * 103), 0.5);
	self.spot rotatePitch(-45, 0.2);
	self.spot moveTo(self.spot.origin - (0, 0, 33) - (forward * 45), 0.2);
	self.knockdownState = 2;
	wait 0.3;

	self thread dogKnockdownAttackLate(player);
	self thread dogKnockdownMeleeDeath(player);
	player thread playerShowHintstring();
}

dogKnockdownAttackLate(player)
{
	player endon("dog_melee");

	self.knockdownState = 3;
	for(i = 0; i < 3; i++)
	{
		player thread playerAttackEffect(self.spot, 0.8, 10);
		self playSound("anml_dog_bark");
		self.hands scriptModelPlayAnim("player_view_dog_knockdown_late");
		self scriptModelPlayAnim("german_shepherd_attack_player_late");
		wait 0.2;
		self playSound("anml_dog_bark");
		wait 0.8;
	}

	self.knockdownState = 4;
	self playSound("anml_dog_attack_kill_player");

	if (isDefined(player))
	{
		player notify("dog_late");
		player thread playerAttackEffect(self.spot, 2, 10);
	}

	wait 3.5;
	self.spot moveTo(self.spot.origin + (0, 0, 20), 0.3);
	wait 0.85;

	if (isDefined(player)) player suicide();
	lethalbeats\survival\utility::add_corpse(self.body);

	self.knockdownState = undefined;
	self.biteCount = 0;
	self.isAttacking = false;
	self.victim = undefined;
	self.hands delete();
	self.spot delete();
}

dogKnockdownMeleeDeath(player)
{
	player endon("dog_late");
	player endon("disconnect");
	player endon("death");

	player notifyOnPlayerCommand("dog_melee", "+melee_zoom");
	player waittill("dog_melee");
	
	self.hitBox delete();
	self.body.origin += (anglesToForward(self.angles) * 7);
	self.body scriptModelPlayAnim("player_3rd_dog_knockdown_neck_snap");
	self.hands scriptModelPlayAnim("player_view_dog_knockdown_neck_snap");
	self scriptModelPlayAnim("german_shepherd_player_neck_snap");

	wait 0.5;
	self playSound(PAIN_SOUND);
	self playSound(PAIN_SOUND);
	self lethalbeats\survival\utility::bot_kill(player);
	wait 2.2;

	self notify("dog_death", player, true);
}

dogKnockdownStandUp(player)
{
	self.hands delete();

	forward = anglesToForward(self.spot.angles);	
	self.spot rotatePitch(45, 0.3);
	self.spot moveTo(self.spot.origin + (0, 0, 60) - (forward * 45), 0.3);
	wait 0.45;

	if (isDefined(player))
	{
		player unlink();
		player setOrigin(self.spot.spawnOrigin);
		player setStance("stand");
		player lethalbeats\player::player_enable_weapons();
		player lethalbeats\player::player_enable_usability();
		player lethalbeats\survival\utility::player_show();
		player.dogKnockdown = false;
	}

	self.knockdownState = undefined;
	self.isAttacking = false;
	self.currentAnim = "";
	self.body.head delete();
	self.body delete();
	self.spot delete();
}

playerShowHintstring()
{
	self.hintString = lethalbeats\hud::hud_create_string(self, "^3[[{+melee_zoom}]]", "hudbig", 2);
	self.hintString lethalbeats\hud::hud_set_point("center", "center", 0, 0);
	self.hintString.alpha = 1;	
	self pulseEffect();
	self.hintString lethalbeats\hud::hud_destroy();
}

pulseEffect()
{
	self endon("disconnect");
	self endon("dog_melee");
	self endon("dog_saved");
	self endon("dog_late");

	interval = 0.35;
	duration = 2;
	elapsed = 0;

	for(;;)
	{
		self.hintString lethalbeats\hud::hud_effect_font_pulse(self);
		elapsed += interval;
		wait interval;
	}
}

playerAttackEffect(spot, duration, intensityYaw)
{
	self endon("disconnect");
	self endon("death");
	self thread playerAttackEffectMonitor();
	self thread playerAttackEffectLoop(spot, duration, intensityYaw);
}

playerAttackEffectMonitor()
{
	self waittill_any("dog_melee", "dog_saved", "dog_late");
	self setBlurForPlayer(0, 0.05);
}

playerAttackEffectLoop(spot, duration, intensityYaw)
{
	self endon("dog_melee");
	self endon("dog_saved");
	self endon("dog_late");

	prevOrigin = spot.origin;
	prevAngles = spot.angles;
	speed = 0.1;
	cycleTime = speed * 2;
	iterations = int(duration / cycleTime);
	intensity = 3;
	
	for(i = 0; i < iterations; i++)
	{
		self shellshock("frag_grenade_mp", 0.35);
		self openMenu("blood_effect_center");
		self openMenu("blood_effect_right");
		self openMenu("blood_effect_left");
		self setBlurForPlayer(1, 0.25);
		spot rotateYaw(randomFloatRange(-intensityYaw, intensityYaw), speed);
		spot rotatePitch(randomFloatRange(-intensity, intensity), speed);
		spot rotateRoll(randomFloatRange(-intensity, intensity), speed);	
		wait speed;
		self setBlurForPlayer(0, 0.25);
		spot rotateTo(prevAngles, speed);
		spot moveTo(prevOrigin, speed);
		wait speed;
	}
}

//////////////////////////////////////////
//	        DOG NAVIGATION   	        //
//////////////////////////////////////////

dogShouldRepath(target)
{
	if (!isDefined(self.path) || !self.path.size) return true;
	if (self.pathIndex >= self.path.size) return true;
	if ((getTime() - self.lastPathTime) >= DOG_REPATH_TIME) return true;
	if (isDefined(target) && isDefined(self.lastTargetOrigin) && distanceSquared(self.lastTargetOrigin, target.origin) >= DOG_REPATH_DIST_SQ) return true;
	if (self.stuckTime >= 1.2) return true;
	return false;
}

dogBuildPath(victim)
{
	if (!isDefined(level.waypoints) || !level.waypoints.size) return false;
	if (!lethalbeats\botactor\navigation::_botNavigationUsePathBudget(getTime())) return false;

	rawPath = self lethalbeats\botactor\navigation::bot_astar_search(self.origin, victim.origin, "axis", false);
	if (!isDefined(rawPath) || !rawPath.size)
	{
		self dogResetPath();
		return false;
	}

	positions = [];
	for (i = rawPath.size - 1; i >= 0; i--)
	{
		idx = rawPath[i];
		if (!isDefined(level.waypoints[idx])) continue;
		positions[positions.size] = level.waypoints[idx].origin;
	}
	positions[positions.size] = victim.origin;

	self.path = positions;
	self.pathIndex = 1;
	self.lastPathTime = getTime();
	self.lastTargetOrigin = victim.origin;
	self.stuckTime = 0;
	return (positions.size > 1);
}

dogFollowPath(target)
{
	if (!isDefined(self.path) || !self.path.size) return false;
	if (!isDefined(self.pathIndex)) self.pathIndex = 1;

	for (; self.pathIndex < self.path.size;)
	{
		dest = self.path[self.pathIndex];
		if (!self dogMoveTowards(dest, target)) return false;
		self.pathIndex++;
	}
	return true;
}

dogMoveTowards(dest, target)
{
	prevPos = self.origin;
	blocked = 0;

	for (;;)
	{
		if (self.isInPain || self.isConcussed || isDefined(self.knockdownState))
		{
			wait DOG_TICK;
			continue;
		}

		if (isDefined(target) && !lethalbeats\survival\utility::survivor_filter(target)) return false;

		delta = (dest[0] - self.origin[0], dest[1] - self.origin[1], 0);
		distSq = lengthsquared(delta);

		if (distSq <= DOG_GOAL_REACHED_SQ) return true;

		targetYaw = vectortoyaw(delta);
		yawDelta = angleClamp180(targetYaw - self.angles[1]);

		if (abs(yawDelta) > 135)
		{
			self dogTurn180(targetYaw);
			wait DOG_TICK;
			prevPos = self.origin;
			continue;
		}

		if (yawDelta > 18) self dogSetAnim(RUN_LEAN_L);
		else if (yawDelta < -18) self dogSetAnim(RUN_LEAN_R);
		else self dogSetAnim(RUNNING);

		dir = vectornormalize(delta);
		stepDist = DOG_SPEED * DOG_TICK;
		dist = sqrt(distSq);
		if (stepDist > dist) stepDist = dist;

		targetOrigin = isDefined(target) ? target.origin : dest;
		dir = self dogApplySeparation(dir, targetOrigin, prevPos);

		next = self.origin + (dir * stepDist);

		if (!(self dogCanStep(self.origin, next)))
		{
			dir = self dogDeflect(dir, stepDist);
			if (!isDefined(dir))
			{
				blocked++;
				if (blocked >= DOG_BLOCKED_TICKS)
					return false;

				self dogSetAnim(IDLE);
				self.stuckTime += DOG_TICK;
				wait DOG_TICK;
				continue;
			}

			next = self.origin + (dir * stepDist);
			targetYaw = vectortoyaw(dir);
		}

		blocked = 0;

		ground = self dogGetGround(next);
		nextAngles = (0, targetYaw, 0);
		if (isDefined(ground) && isDefined(ground["position"]))
		{
			next = ground["position"];
			nextAngles = dogGetGroundAngles(ground, targetYaw);
		}

		self rotateTo(nextAngles, DOG_TICK + 0.04);
		self moveTo(next, DOG_TICK + 0.04);

		if (distanceSquared(self.origin, prevPos) <= DOG_STUCK_DIST_SQ)
			self.stuckTime += DOG_TICK;
		else
		{
			self.stuckTime = 0;
			prevPos = self.origin;
		}

		if (self.stuckTime > 1.2) return false;

		if (isDefined(target) && isDefined(self.lastTargetOrigin))
		{
			if (distanceSquared(self.lastTargetOrigin, target.origin) >= DOG_REPATH_DIST_SQ)
				return false;
		}

		wait DOG_TICK;
	}
}

dogMoveDirect(victim)
{
	delta = (victim.origin[0] - self.origin[0], victim.origin[1] - self.origin[1], 0);
	distSq = lengthsquared(delta);

	if (distSq < 16 * 16) return true;

	targetYaw = vectortoyaw(delta);
	yawDelta = angleClamp180(targetYaw - self.angles[1]);

	if (abs(yawDelta) > 135)
	{
		self dogTurn180(targetYaw);
		return true;
	}

	if (yawDelta > 18) self dogSetAnim(RUN_LEAN_L);
	else if (yawDelta < -18) self dogSetAnim(RUN_LEAN_R);
	else self dogSetAnim(RUNNING);

	dir = vectornormalize(delta);
	stepDist = DOG_SPEED * DOG_TICK;
	dist = sqrt(distSq);
	if (stepDist > dist) stepDist = dist;

	next = self.origin + (dir * stepDist);

	if (!(self dogCanStep(self.origin, next)))
		return false;

	ground = self dogGetGround(next);
	if (!isDefined(ground) || !isDefined(ground["position"]))
		return false;

	next = ground["position"];
	nextAngles = dogGetGroundAngles(ground, targetYaw);

	self rotateTo(nextAngles, DOG_TICK + 0.04);
	self moveTo(next, DOG_TICK + 0.04);

	if (distanceSquared(self.origin, self.lastOrigin) <= DOG_STUCK_DIST_SQ)
		self.stuckTime += DOG_TICK;
	else
	{
		self.stuckTime = 0;
		self.lastOrigin = self.origin;
	}

	if (self.stuckTime > 1.2) return false;

	return true;
}

dogResetPath()
{
	self.path = [];
	self.pathIndex = 0;
	self.lastPathTime = 0;
	self.lastTargetOrigin = self.origin;
	self.stuckTime = 0;
	self.lastOrigin = self.origin;
}

dogApplySeparation(dir, targetOrigin, prevPos)
{
	if (!isDefined(level.dogs) || level.dogs.size <= 1) return dir;

	separationForce = (0, 0, 0);
	separationRadius = DOG_SEPARATION_RADIUS;
	separationRadiusSq = separationRadius * separationRadius;
	nearbyCount = 0;

	myDistToTarget = distance(self.origin, targetOrigin);
	isMoving = distanceSquared(self.origin, prevPos) > 4;

	if (!isMoving) return dir;

	foreach (other in level.dogs)
	{
		if (!isDefined(other) || other == self) continue;

		distToOtherSq = distanceSquared(self.origin, other.origin);
		if (distToOtherSq < separationRadiusSq && distToOtherSq > 1)
		{
			awayDir = (self.origin[0] - other.origin[0], self.origin[1] - other.origin[1], 0);
			if (awayDir[0] == 0 && awayDir[1] == 0) awayDir = (1, 0, 0);
			else awayDir = vectorNormalize(awayDir);

			strength = 1.0 - (sqrt(distToOtherSq) / separationRadius);
			separationForce = separationForce + (awayDir * strength);
			nearbyCount++;
		}
	}

	if (nearbyCount > 0)
	{
		separationForce = vectorNormalize(separationForce);
		separationWeight = 0.0;
		if (myDistToTarget > 200)
		{
			if (myDistToTarget > 600) separationWeight = 0.4;
			else separationWeight = ((myDistToTarget - 200) / 400) * 0.4;
		}

		desiredWeight = 1.0 - separationWeight;
		return vectorNormalize((dir * desiredWeight) + (separationForce * separationWeight));
	}

	return dir;
}

dogGetGround(point)
{
	if (!isDefined(point)) return undefined;

	ignoreEnt = self.hitBox;
	bestTrace = undefined;
	bestDist = 999999;

	start = point + (0, 0, 24);
	end = point - (0, 0, 96);
	trace = bulletTrace(start, end, false, ignoreEnt);

	if (isDefined(trace) && isDefined(trace["position"]) && trace["surfacetype"] != "none" && trace["normal"][2] >= DOG_MIN_GROUND_NORMAL_Z)
	{
		if (trace["position"][2] < self.origin[2] - 15)
			trace["position"] = playerPhysicsTrace(start, end, false, ignoreEnt);
		return trace;
	}

	step = 12;
	radius = 36;
	for (x = -radius; x <= radius; x += step)
	{
		for (y = -radius; y <= radius; y += step)
		{
			start = point + (x, y, 24);
			end   = point + (x, y, -96);
			trace = bulletTrace(start, end, false, ignoreEnt);

			if (!isDefined(trace)) continue;
			if (!isDefined(trace["position"])) continue;
			if (trace["surfacetype"] == "none") continue;
			if (trace["normal"][2] < DOG_MIN_GROUND_NORMAL_Z) continue;

			if (trace["position"][2] < self.origin[2] - 15)
				trace["position"] = playerPhysicsTrace(start, end, false, ignoreEnt);

			dist = distanceSquared(point, trace["position"]);
			if (dist < bestDist)
			{
				bestDist = dist;
				bestTrace = trace;
			}
		}
	}

	return bestTrace;
}

dogGetGroundAngles(ground, targetYaw)
{
	flatAngles = (0, targetYaw, 0);
	if (!isDefined(ground) || !isDefined(ground["normal"])) return flatAngles;		
	if (ground["normal"][2] < DOG_MIN_GROUND_NORMAL_Z) return flatAngles;

	groundAngles = lethalbeats\vector::vector_angles_orient_to_normal(ground["normal"], targetYaw);
	pitch = angleClamp180(groundAngles[0]);
	roll = angleClamp180(groundAngles[2]);
	
	if (abs(pitch) > DOG_MAX_ORIENT_PITCH || abs(roll) > DOG_MAX_ORIENT_ROLL) return flatAngles;

	return (pitch, targetYaw, roll);
}

dogCanMoveDirect(target)
{
	if (!isDefined(target)) return false;
	goal = target.origin;
	if (abs(goal[2] - self.origin[2]) > 48) return false;
	if (!(self dogCanStep(self.origin, goal))) return false;
	return self dogPathIsNavigable(self.origin, goal);
}

dogStepTrace(from, to)
{
	lift = (0, 0, DOG_STEP_Z);

	dogTraceIgnore = isDefined(self.hitBox) ? self.hitBox : self;

	start = playerPhysicsTrace(from, from + lift, false, dogTraceIgnore);
	if (!isDefined(start)) start = from + lift;

	end = playerPhysicsTrace(to, to + lift, false, dogTraceIgnore);
	if (!isDefined(end)) end = to + lift;

	hit = playerPhysicsTrace(start, end, false, dogTraceIgnore);
	if (!isDefined(hit)) return undefined;

	return hit;
}

dogCanStep(from, to)
{
	hit = self dogStepTrace(from, to);
	if (!isDefined(hit)) return false;
	return distanceSquared(hit, to + (0, 0, DOG_STEP_Z)) <= DOG_STEP_SLOP_SQ;
}

/*
///DocStringBegin
detail: <Entity> dogDeflect(dir: <Vector3>, stepDist: <Float>): <Vector3 | Undefined>
summary: A nearby walkable direction, or undefined if trapped. Angles up to 110° escape corners, while small adjustments only push the dog into the wall.
///DocStringEnd
*/
dogDeflect(dir, stepDist)
{
	yaw = vectortoyaw(dir);
	deflections = DOG_DEFLECT_ANGLES;

	for (i = 0; i < deflections.size; i++)
	{
		test = anglestoforward((0, yaw + deflections[i], 0));
		test = vectornormalize((test[0], test[1], 0));

		if (self dogCanStep(self.origin, self.origin + (test * stepDist)))
			return test;
	}

	return undefined;
}

dogPathIsNavigable(start, end)
{
	if (!isDefined(level.waypoints) || !level.waypoints.size) return true;

	distSq = distanceSquared(start, end);
	if (distSq < 64 * 64) return true;

	dist = sqrt(distSq);
	dir = (end[0] - start[0], end[1] - start[1], end[2] - start[2]);
	dir = (dir[0] / dist, dir[1] / dist, dir[2] / dist);

	step = 64;
	samples = int(dist / step);
	if (samples < 1) samples = 1;

	maxDistSq = 140 * 140;
	for (i = 1; i <= samples; i++)
	{
		samplePos = start + (dir[0] * (step * i), dir[1] * (step * i), dir[2] * (step * i));
		nearest = lethalbeats\botactor\navigation::_botgetNearestWaypoint(samplePos, true);

		if (!isDefined(nearest) || !isDefined(level.waypoints[nearest]))
			return false;

		wpOrigin = level.waypoints[nearest].origin;
		if (distanceSquared((wpOrigin[0], wpOrigin[1], samplePos[2]), samplePos) > maxDistSq)
			return false;

		if (abs(wpOrigin[2] - samplePos[2]) > 64)
			return false;
	}
	
	return true;
}

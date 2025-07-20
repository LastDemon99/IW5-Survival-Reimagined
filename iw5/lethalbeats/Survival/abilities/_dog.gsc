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

#define ATTACK_KNOCKDOWN "attack_player" // 4.63333
#define DEATH "death_front" // 1.16667
#define DEATH_NECK_SNAP "player_neck_snap" // 2.3

#define PAIN_SOUND "anml_dog_run_hurt"

#define FLASH "flash_grenade_mp"
#define CONCUSSION "concussion_grenade_mp"

#define SHARP_TURN_WHILE_RUNNING_THRESHOLD 100

init()
{
	precacheitem("iw5_dog_mp");
	precacheitem("iw5_dogviewmodel_mp");
	
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
	
	precacheShellShock("radiation_low");
	precacheShellShock("dog_bite");

	precacheShader("compassping_enemyyelling");
	precacheMiniMapIcon("compassping_enemyyelling");
}

giveAbility()
{
	self.pers["bots"]["skill"]["fov"] = 45;

	self.dropWeapon = false;
	self.lastDroppableWeapon = "none";
	self.damageData = undefined;

	weapon = "iw5_dog_mp";
	
	self takeAllWeapons();	
	self _giveWeapon(weapon);
	self setSpawnWeapon(weapon);
	self lethalbeats\player::player_disable_weapon_switch();
	self lethalbeats\player::player_disable_offhand_weapons();
	
	self.pers["primaryWeapon"] = weapon;

	dog = spawn("script_model", self.origin);
	dog.angles = (0, self.angles[1], 0);
	dog setModel("german_sheperd_dog");
	dog linkto(self);
	dog scriptModelPlayAnim(DOG_PREFIX + RUNNING);

	tail_pos = self.origin - (vectornormalize(anglestoforward(self getPlayerAngles())) * 20);	
	hitBox = Spawn("script_model", tail_pos + (0, 0, 25));
	hitBox.angles = (0, self.angles[1], 0);
	hitBox SetModel("com_plasticcase_trap_bombsquad");
	hitBox hide();

	hitBox setcandamage(1);
	hitBox.health = 999999;
	hitBox.maxHealth = self.health;
	hitBox.damageTaken = 0;
	hitBox linkto(dog);	
	dog.hitBox = hitBox;

	compassIcon = spawnPlane(self, "script_model", level.ac130.planeModel.origin, "compassping_enemyyelling", "compassping_enemyyelling");
	compassIcon notSolid();
	compassIcon linkTo(dog, "tag_origin", (0, 0, 0), (0, 0, 0));

	dog.icon = compassIcon;
	dog.isIdle = false;
	dog.isRunning = false;
	dog.isConcussed = false;
	dog.isInPain = false;
	dog.isAttacking0 = false;
	dog.isAttacking1 = false;
	dog.lastAttackChecked = getTime();
	dog.attackAmount = 0;
	dog.lastAttackPlayer = undefined;
	dog.runAnimation = RUNNING;
	
	self.health = 999999;
	self.dog = dog;
	self playerHide();
	self lethalbeats\player::player_give_perk("specialty_longersprint");

	self thread onDogDeath();
	self thread onDogDamage();
	self thread updateAnimation();
	self thread monitorRunning();
	self thread monitorTurn();
	self thread monitorIdle();
	self thread dogSoundsLoop();
}

onDogPlayerDamage(player)
{
	self endon("death");

	if (!isDefined(self.dog)) return;

	if (isDefined(self.dog.lastAttackPlayer))
	{
		if (self.dog.lastAttackPlayer != player || (getTime() - self.dog.lastAttackChecked) >= 4000)
		{
			self.dog.lastAttackPlayer = undefined;
			self.dog.attackAmount = 0;
		}
		//else self.dog.attackAmount++; knockdown requires fixes
	}

	self.dog.lastAttackChecked = getTime();
	self.dog.lastAttackPlayer = player;
	player shellshock("dog_bite", 1.5);

	if (self.dog.attackAmount == 2) self.dog.isAttacking1 = true;
	else self.dog.isAttacking0 = true;

	wait 0.5;
	self.dog.isAttacking0 = false;
	self.dog.isAttacking1 = false;
}

onDogDamage()
{
	level endon("game_ended");
	self endon("disconnect");
	
	hitBox = self.dog.hitBox;
	self.dogFase = 0;

	for(;;)
	{
		hitBox waittill("damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags, weapon);

		if (isDefined(attacker))
		{
			if (isDefined(attacker.team) && (attacker.team == "axis" && type != "MOD_EXPLOSIVE") || attacker == self) continue;
			if (isPlayer(attacker)) attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback("");
		}

		hitBox.damageTaken += damage;
		if (hitBox.damageTaken >= hitBox.maxHealth)
		{
			self playSound(PAIN_SOUND);
			if (isDefined(attacker) && attacker lethalbeats\survival\utility::player_is_survivor()) attacker lethalbeats\survival\utility::survivor_give_score(self.botPrice);
			
			tryCount = 0;
			while(isAlive(self)) // DOG BUG FORCE KILL, In certain cases i think player_do_damage is not applied, occurs occasionally, so figuring out the cause is complicated. (╥﹏╥)
			{
				if (tryCount > 3) self suicide();
				self lethalbeats\survival\utility::player_do_damage(attacker, attacker, 999999, iDFlags, type, weapon);
				tryCount++;
				wait 0.35;
			}
			return;
		}

		if (isDefined(weapon) && (weapon == FLASH || weapon == CONCUSSION)) self thread onDogConcussion();		
		if (!self.dogFase && hitBox.damageTaken >= hitBox.maxHealth / 2) self thread onDogHalfDamage();
	}
}

onDogDeath()
{
	self endon("disconnect");
	self waittill("death");

	dog = self.dog;
	dog unlink();
	dog lethalbeats\utility::fakeGravity();
	dog scriptModelPlayAnim(DOG_PREFIX + DEATH);
	dog.hitBox delete();
	dog.icon delete();

	if (isDefined(self)) self.dog = undefined;
	
	wait randomIntRange(3, 6);
	
	dog delete();
}

onDogHalfDamage()
{
	self endon("death");
	self.dogFase++;
	self playSound(PAIN_SOUND);
	self.dog.isInPain = true;
	wait 0.35;
	self.dog.isInPain = false;
}

onDogConcussion()
{
	self endon("death");
	self playSound(PAIN_SOUND);
	self.dog.isConcussed = true;
	wait 0.35;
	self.dog.isConcussed = false;
}

updateAnimation()
{
	self endon("disconnect");
	self endon("death");

	setDogAnim(RUNNING);

	for(;;)
	{
		if (self.dog.isInPain) self setDogAnim(RUN_PAIN, 1.56);
		else if (self.dog.isConcussed) self setDogAnim(CONCUSSED, 1.5);
		else if (self.dog.isAttacking1) self.dog.lastAttackPlayer thread playerKnockdown(self);
		else if (self.dog.isAttacking0) self setDogAnim(RUN_ATTACK, 1.5);
		else if (self.dog.isIdle) self setDogAnim(RUN_STOP, 0.6);

		switch (self.currentAnim)
		{
			case IDLE:
				if (self.dog.isIdle) self setDogAnim(IDLE, 3);
				else self setDogAnim(RUN_START, 0.3);
				break;
			case RUN_START:
				self setDogAnim(self.dog.runAnimation);
				break;
			case RUNNING:
				if (self.dog.isIdle) self setDogAnim(RUN_STOP, 0.6);
				else self setDogAnim(self.dog.runAnimation);
				break;
			case RUN_LEAN_L:
			case RUN_LEAN_R:
				if (self.dog.isIdle)
				{
					self setDogAnim(RUNNING, 0.4);
					self setDogAnim(RUN_STOP, 0.6);
				}
				else self setDogAnim(self.dog.runAnimation);
				break;
			case RUN_STOP:
				if (self.dog.isIdle) self setDogAnim(IDLE);
				else self setDogAnim(RUN_START, 0.3);
				break;
			case CONCUSSED:
			case RUN_PAIN:
			case RUN_ATTACK:
			case ATTACK_KNOCKDOWN:
				self setDogAnim(RUN_START, 0.3);
				break;
		}
		wait 0.35;
	}
}

setDogAnim(animation, waitTime)
{
	self endon("death");

	self.currentAnim = animation;
	self.dog playAnim(DOG_PREFIX + animation, isDefined(waitTime));

	if (!isDefined(waitTime)) return;
	self freezecontrols(true);
	wait waitTime;
	self freezecontrols(false);
}

playAnim(animation, moveToGround)
{
	self scriptModelPlayAnim(animation);

	if (isDefined(moveToGround) && moveToGround)
	{
		groundTrace = bulletTrace(self.origin, self.origin + (0, 0, -10000), false, self);
		travelDistance = distance(self.origin, groundTrace["position"]);
		travelTime = travelDistance / 800;

		if (groundTrace["position"][2] < self.origin[2])
			self moveTo(groundTrace["position"], travelTime);
	}
}

playerKnockdown(dog)
{
	forward = anglesToForward((0, self.angles[1], 0));
	dog setOrigin(self.origin + (forward * 20));
	dog setDogAnim(ATTACK_KNOCKDOWN, 4.7);
			
	self playerHide();
	self giveWeapon("iw5_dogviewmodel_mp");
	self switchToWeaponImmediate("iw5_dogviewmodel_mp");

	body = spawn("script_model", self.origin);
	body.angles = (0, self.angles[1], 0);
	body setModel(self.model);

	head = spawn("script_model", self.origin);
	head setModel(self.headmodel);
	head linkto(body, "j_spine4", (0, 0, 0), (0, 0, 0));

	body playAnim("player_3rd_dog_knockdown", true);
	
	self setPlayerAngles(vectorToAngles(forward));

	knockdownSpot = spawn("script_origin", self.origin + (0, 0, 5));
	knockdownSpot hide();

	self setPlayerAngles(vectorToAngles(forward));
	self playerLinkTo(knockdownSpot);
	self playerLinkedSetViewZNear(false);

	wait 4.7;
	body startragdoll();
}

monitorTurn()
{
    self endon("disconnect");
    self endon("death");

    for (;;) 
	{
        self.dog.runAnimation = RUNNING;
		self setPlayerAngles(vectorToAngles(self getEntityVelocity()));
		angleDifference = angleClamp180(vectorToAngles(self.bot.moveto)[1] - self getPlayerAngles()[1]);
        if (angleDifference > 10 && angleDifference <= 45) self.dog.runAnimation = RUN_LEAN_R;
        else if (angleDifference < -10 && angleDifference >= -45) self.dog.runAnimation = RUN_LEAN_L;
        wait 0.5;
    }
}

monitorRunning()
{
	self endon("disconnect");
	self endon("death");

	for (;;)
	{
		self waittill("sprint_begin");
		self.moveSpeedScaler = 1.5;
		self.dog.isRunning = true;

		self waittill("sprint_end");
		self.moveSpeedScaler = 1;
		self thread monitorRunningEnd();
	}
}

monitorRunningEnd()
{
	self endon("disconnect");
	self endon("death");
	self endon("sprint_begin");

	for(;;)
	{
		if (lengthSquared(self getEntityVelocity()) < 10)
		{
			self.dog.isRunning = false;
			break;
		}
		wait 0.35;
	}
}

monitorIdle()
{
    self endon("disconnect");
    self endon("death");

    idleCheckInterval = 0.05;
    idleTime = 0;
    
    for (;;)
    {
		if (self isOnLadder()) self maps\mp\bots\_bot_internal::jump();
		else if (self getstance() != "stand") self maps\mp\bots\_bot_internal::stand();

        if (lengthSquared(self getVelocity()) < 2)
        {
            idleTime += idleCheckInterval;
            if (idleTime >= 0.5) self.dog.isIdle = true;
        } 
        else
        {
            idleTime = 0;
            self.dog.isIdle = false;
        }
        wait idleCheckInterval;
    }
}

dogSoundsLoop()
{
	level endon("game_ended");
	self endon("death");
	self endon("disconnect");

	interval = randomIntRange(3, 5);
	for (;;)
	{
		wait interval;
		if (self.dog.isInPain || self.dog.isAttacking0 || self.dog.isAttacking1) continue;
		playsoundatpos(self.origin, "anml_dog_bark");
	}
}

is_alive()
{
	return self.dog.hitBox.damageTaken < self.dog.hitBox.maxHealth;
}

is_dog()
{
	return self lethalbeats\survival\utility::bot_is_dog();
}


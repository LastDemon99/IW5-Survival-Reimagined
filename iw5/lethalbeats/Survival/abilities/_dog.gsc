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
	self allowJump(false);

	self.pers["primaryWeapon"] = weapon;

	dog = spawn("script_model", self.origin);
	dog.angles = (0, self.angles[1], 0);
	dog setModel("german_sheperd_dog");
	dog linkto(self);
	dog scriptModelPlayAnim(DOG_PREFIX + RUNNING);
	dog.owner = self;

	tail_pos = self.origin - (vectornormalize(anglestoforward(self getPlayerAngles())) * 20);	
	hitBox = Spawn("script_model", tail_pos + (0, 0, 25));
	hitBox.angles = (0, self.angles[1], 0);
	hitBox SetModel("com_plasticcase_trap_bombsquad");
	hitBox hide();

	hitBox setcandamage(1);
	hitBox setCanRadiusDamage(1);
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
	dog.victim = undefined;
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

onDogDamage()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("dog_melee");
	
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

onDogPlayerDamage(player)
{
	level endon("game_ended");
	self endon("disconnect");

	if (!isDefined(self.dog)) return;
	dog = self.dog;

	if (player isOnLadder())
	{
		dog.attackAmount = 0;
		player lethalbeats\survival\utility::player_client_cmd("+gostand");
		wait 0.05;
		player lethalbeats\survival\utility::player_client_cmd("-gostand");
	}

	if (player.dogKnockdown)
	{
		dog.isAttacking0 = true;
		wait 0.5;
		dog.isAttacking0 = false;
		return;
	}

	if (isDefined(dog.victim))
	{
		if (dog.victim != player || (getTime() - self.dog.lastAttackChecked) >= 8000)
		{
			dog.victim = undefined;
			dog.attackAmount = 0;
		}
		else dog.attackAmount++;
	}

	dog.lastAttackChecked = getTime();
	dog.victim = player;

	player shellshock("dog_bite", 1.5);

	if (dog.attackAmount == 2) 
	{
		dog.isAttacking1 = true;
		dog.attackAmount = 0;
		player playerDogKnockdown(dog);
	}
	else dog.isAttacking0 = true;

	wait 0.5;
	dog.isAttacking0 = false;
}

onDogDeath()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("dog_melee");

	self waittill("death");
	waittillframeend;

	self allowJump(true);
	dog = self.dog;
	dog unlink();
	dog scriptModelPlayAnim(DOG_PREFIX + DEATH);

	if (isDefined(dog.knockdownState))
	{
		if (dog.knockdownState == 0)
		{
			dog.victim unlink();
			dog.spot delete();
		}
		else if (dog.knockdownState == 1 || dog.knockdownState == 2)
		{
			dog waittill("knockdown_end");
			dog.victim playerStandUp(dog);
		}
		else if (dog.knockdownState == 3)
		{
			dog.victim notify("dog_late", false);
			dog.body scriptModelPlayAnim("player_3rd_dog_knockdown_saved");
			dog.hands scriptModelPlayAnim("player_view_dog_knockdown_saved");
			wait 0.5;
			dog.victim playerStandUp(dog);
		}
	}
	dog dogClear();
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

spawnKnockdownSpot()
{
	spot = spawn("script_model", self.origin);
	spot setModel("tag_origin");
	spot notSolid();
	spot.angles = self getPlayerAngles();
	self playerLinkToAbsolute(spot);
	return spot;
}

moveToDog(dog)
{
	forward = anglesToForward(dog.angles);
	self rotateTo(vectorToAngles(-forward), 0.1);
	self moveTo(dog.origin + (forward * 30), 0.1);
	dog.knockdownState = 0;
	wait 0.15;
}

spawnKnockdownHands(spot)
{
	hands = spawn("script_model", spot.origin + (0, 0, 60));
	hands setModel(self getViewModel());
	hands.angles = spot.angles;	
	hands hide();
	hands showToPlayer(self);
	return hands;
}

spawnKnockdownBody(spot)
{
	self lethalbeats\survival\utility::player_hide();

	forward = anglesToForward((0, spot.angles[1], 0));
	body = spawn("script_model", spot.origin + (forward * 15));
	body.angles = spot.angles;
	body setModel(self.hideData["body"]);

	head = spawn("script_model", self.origin);
	head setModel(self.hideData["head"]);
	head linkto(body, "j_spine4", (0, 0, 0), (0, 0, 0));
	body.head = head;

	body hide();
	head hide();
	foreach(player in level.players)
	{
		if (self == player) continue;
		body showToPlayer(player);
		head showToPlayer(player);
	}

	return body;
}

playKnockdownAnim(dog)
{
	self thread attackEffect(dog.spot, 0.3, 10);
	
	dog.hands scriptModelPlayAnim("player_view_dog_knockdown");
	dog.body scriptModelPlayAnim("player_3rd_dog_knockdown");
	dog scriptModelPlayAnim("german_shepherd_attack_player");
	dog playSound("anml_dog_attack_jump");
	dog.knockdownState = 1;
	wait 0.3;

	forward = anglesToForward(dog.angles);	
	dog.hands moveTo(dog.hands.origin - (forward * 103), 0.5);
	dog.spot rotatePitch(-45, 0.2);
	dog.spot moveTo(dog.spot.origin - (0, 0, 33) - (forward * 45), 0.2);	
	dog.knockdownState = 2;
	wait 0.5;

	dog notify("knockdown_end");
}

playerDogKnockdown(dog)
{
	if (self.dogKnockdown || isDefined(dog.knockdownState)) return;
	if (!isDefined(dog) || !isDefined(dog.owner)) return;

	self setStance("stand");
	waittillframeend;

	self.dogKnockdown = true;
	dog.owner disableWeapons();
	dog.owner freezeControls(true);
	dog unlink();

	self lethalbeats\player::player_disable_weapons();
	self lethalbeats\player::player_disable_usability();

	dog.spot = self spawnKnockdownSpot();
	
	forward = anglesToForward(dog.angles);
	dog.spot rotateTo(vectorToAngles(-forward), 0.1);
	dog moveTo(self.origin - (forward * 30), 0.1);
	dog.owner setOrigin(dog.origin);
	dog.knockdownState = 0;
	wait 0.15;

	if (!isDefined(dog.spot)) return;

	dog.hands = self spawnKnockdownHands(dog.spot);
	dog.body = self spawnKnockdownBody(dog.spot);

	self playKnockdownAnim(dog);

	self thread playerDogAttackLate(dog);
	self thread playerDogMeleeDeath(dog);
	self thread playerShowHintstring();
}

playKnockdownLateAnim(dog)
{
	self endon("dog_melee");
	dog.owner endon("death");

	dog.knockdownState = 3;
	for(i = 0; i < 3; i++)
	{
		self thread attackEffect(dog.spot, 0.8, 10);
		dog playSound("anml_dog_bark");
		dog.hands scriptModelPlayAnim("player_view_dog_knockdown_late");
		dog scriptModelPlayAnim("german_shepherd_attack_player_late");
		wait 0.2;
		dog playSound("anml_dog_bark");
		wait 0.8;
	}

	self notify("dog_late", true);
}

playerDogAttackLate(dog)
{
	self thread playKnockdownLateAnim(dog);
	self waittill("dog_late", dog_late);
	if (!dog_late) return;

	self notify("dog_late_start");

	dog.knockdownState = 4;
	dog.hitbox setCanDamage(false);
	dog.hitbox setCanRadiusDamage(false);
	dog playSound("anml_dog_attack_kill_player");
	self thread attackEffect(dog.spot, 2, 10);
	wait 3;

	dog.knockdownState = undefined;
	dog.hitbox setCanDamage(true);
	dog.hitbox setCanRadiusDamage(true);
	dog.owner setOrigin(dog.origin);
	dog.owner setPlayerAngles(dog.angles);
	dog linkTo(dog.owner);

	hands = dog.hands;
	dog.hands = undefined;

	spot = dog.spot;
	dog.spot = undefined;

	body = dog.body;
	dog.body = undefined;

	dog.isAttacking1 = false;
	dog.owner enableWeapons();
	dog.owner freezeControls(false);

	wait 0.5;
	spot moveTo(spot.origin + (0, 0, 20), 0.3);
	wait 0.85;

	self suicide();
	hands delete();
	spot delete();
	wait randomIntRange(3, 6);
	body.head delete();
	body delete();
}

playerDogMeleeDeath(dog)
{
	self endon("dog_late_start");
	self endon("disconnect");
	dog.owner endon("death");

	self notifyOnPlayerCommand("dog_melee", "+melee_zoom");

	self waittill("dog_melee");
	waittillframeend;
	if (!isDefined(dog.body) || !isDefined(dog.hands)) return;

	self notify("dog_late", false);
	self notify("dog_melee");
	dog.owner notify("dog_melee");

	dogForward = anglesToForward(dog.angles);
	dog.body.origin += (dogForward * 7);
	dog.body scriptModelPlayAnim("player_3rd_dog_knockdown_neck_snap");
	dog.hands scriptModelPlayAnim("player_view_dog_knockdown_neck_snap");
	dog scriptModelPlayAnim("german_shepherd_player_neck_snap");

	wait 0.5;
	dog playSound(PAIN_SOUND);
	self lethalbeats\survival\utility::survivor_give_score(dog.owner.botPrice);
	wait 2.2;

	self playerStandUp(dog);
	dog thread dogClear();
	if (isDefined(dog.owner))
		dog.owner suicide();
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
		if (self isOnLadder()) 
		{
			self allowJump(true);
			self maps\mp\bots\_bot_internal::jump();
			self allowJump(false);
		}
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

updateAnimation()
{
	self endon("disconnect");
	self endon("death");
	self endon("dog_melee");

	setDogAnim(RUNNING);

	for(;;)
	{
		wait 0.35;
		if (self.dog.isInPain) self setDogAnim(RUN_PAIN, 1.56);
		else if (self.dog.isConcussed) self setDogAnim(CONCUSSED, 1.5);
		else if (self.dog.isAttacking1) continue;
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
	}
}

setDogAnim(animation, waitTime)
{
	self endon("death");

	self.currentAnim = animation;
	self.dog scriptModelPlayAnim(DOG_PREFIX + animation);

	if (!isDefined(waitTime)) return;
	self freezecontrols(true);
	wait waitTime;
	self freezecontrols(false);
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

attackEffect(spot, duration, intensityYaw)
{
	self thread attackEffectMonitor();
	self thread attackEffectLoop(spot, duration, intensityYaw);
}

attackEffectMonitor()
{
	self waittill_any("disconnect", "dog_melee", "dog_saved", "dog_late");
	self setBlurForPlayer(0, 0.05);
}

attackEffectLoop(spot, duration, intensityYaw)
{
	self endon("disconnect");
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

playerStandUp(dog)
{
	if (isDefined(dog.hands)) dog.hands delete();	
	if (!isDefined(dog.spot)) return;
		
	spot = dog.spot;

	forward = anglesToForward(spot.angles);
	
	if (isDefined(spot))
	{
		spot rotatePitch(45, 0.3);
		spot moveTo(spot.origin + (0, 0, 60) - (forward * 45), 0.3);
	}

	wait 0.3;

	if (isDefined(self))
	{
		if (isDefined(dog.body))
		{
			bodyOrigin = dog.body.origin;
			origin = (bodyOrigin[0], bodyOrigin[1], getGroundPosition(bodyOrigin, 50)[2] + 5);
			self setOrigin(origin);
		}
		self setStance("stand");
		self lethalbeats\player::player_enable_weapons();
		self lethalbeats\player::player_enable_usability();
		self unlink();
		self.dogKnockdown = false;
		self lethalbeats\survival\utility::player_show();
	}

	dog.isAttacking1 = false;
	
	if (isDefined(dog.body))
	{
		if (isDefined(dog.body.head))
			dog.body.head delete();
		dog.body delete();
	}
	
	if (isDefined(spot))
		spot delete();
}

dogClear()
{
	if (isDefined(self.hitBox))
		self.hitBox delete();
	if (isDefined(self.icon))
		self.icon delete();
	wait 6;
	self delete();
}

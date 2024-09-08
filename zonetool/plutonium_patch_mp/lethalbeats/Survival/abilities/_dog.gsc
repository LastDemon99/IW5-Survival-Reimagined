#include common_scripts\utility;
#include maps\mp\_utility;
#include lethalbeats\survival\abilities\_martyrdom;
#include maps\mp\bots\_bot_utility;
#include maps\mp\bots\_bot_internal;
#include maps\mp\bots\_bot_script;

init()
{
    replacefunc(maps\mp\bots\_bot::add_bot, lethalbeats\survival\_bots::addBot);	
	replacefunc(maps\mp\bots\_bot_internal::crouch, ::_crouch);
	replacefunc(maps\mp\bots\_bot_internal::prone, ::_prone);
	replacefunc(maps\mp\bots\_bot_internal::jump, ::_jump);
	replacefunc(maps\mp\bots\_bot_internal::doBotMovement_loop, ::_doBotMovement_loop);
	replacefunc(maps\mp\bots\_bot_script::start_bot_threads, ::_start_bot_threads);

	preCacheMpAnim("german_shepherd_run");
	preCacheMpAnim("german_shepherd_death_front");
	preCacheMpAnim("german_shepherd_run_jump_40");
	preCacheMpAnim("german_shepherd_attack_player");
	preCacheMpAnim("german_shepherd_run_pain");
	
	precacheShellShock("radiation_low");
	precacheShellShock("dog_bite");
}

giveAbility()
{
	self.dogAnim = 0;
	self.lastDroppableWeapon = "none";
	weapon = "iw5_dog_mp";
	
	self takeAllWeapons();	
	self _giveWeapon(weapon);
	self setSpawnWeapon(weapon);
	self disableweaponswitch();
	self disableoffhandweapons();
	
	self.pers["primaryWeapon"] = weapon;

	dogModel = spawn("script_model", self.origin);
	dogModel.angles = (0, self.angles[1], 0);
	dogModel setModel("german_sheperd_dog");
	dogModel scriptModelPlayAnim("german_shepherd_run");
	dogModel linkto(self);
	
	if(self.botType == "dog_splode")
	{
		dogModel thread attachC4("j_hip_base_ri", (6,6,-3), (0,0,0));
		dogModel thread attachC4("j_hip_base_le", (-6,-6,3), (0,0,0));
		dogModel thread martyrdomDetonate();
	}	
	
	tail_pos = self.origin - (vectornormalize(anglestoforward(self getPlayerAngles())) * 20);	
	hitBox = Spawn("script_model", tail_pos + (0, 0, 25));
	hitBox.angles = (0, self.angles[1], 0);
	hitBox SetModel("com_plasticcase_dummy");
	hitBox hide();

	hitBox setcandamage(1);
	hitBox setCanRadiusDamage(1);
	hitBox.health = self.health; 
	hitBox.maxHealth = self.maxHealth;
	hitBox.damageTaken = 0;
	hitBox linkto(self);
	
	dogModel.hitBox = hitBox;	
	self.dogModel = dogModel;
	
	self thread dogObjetive();
	self thread onDogDeath();
	self thread onDogDamage();
	self thread dogSounds();
	self thread dogTest();
}

dogObjetive()
{
	self endon("death");
	self endon("disconnect");
	level endon("game_ended");
	
	target = undefined;

	for (;;)
	{
		for (i = 0; i < level.players.size; i++)
		{
			player = level.players[i];
			
			if (player == self || !isreallyalive(player) || player.team == "axis") 
				continue;
			
			if (!isDefined(target) || distancesquared(self.origin, player.origin) < distancesquared(self.origin, target.origin))
				target = player;
		}
		
		if (isDefined(target))
		{
			self maps\mp\bots\_bot_utility::SetScriptGoal(target.origin, 32);
			self thread maps\mp\bots\_bot_script::stop_go_target_on_death(target);
			
			if (self waittill_any_return("goal", "bad_path", "new_goal") != "new_goal")
				self maps\mp\bots\_bot_utility::ClearScriptGoal();
		}
		wait 0.35;
	}
}

onDogDamage()
{
	level endon("game_ended");
	self endon("killed_player");
	self endon("disconnect");
	
	hitBox = self.dogModel.hitBox;	
	painFase = hitBox.maxHealth / 3;
	currFase = 0;

	for(;;)
	{
		hitBox waittill("damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags, weapon);
		
		attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback("");	
		if (isDefined(attacker.team) && attacker.team == "axis" && type != "MOD_EXPLOSIVE") continue;
		
		radiusDamage(hitBox.origin, 10, damage, damage, attacker, type);
		hitBox.damageTaken += damage;
		
		if ((!currFase && hitBox.damageTaken >= painFase) || (currFase == 1 && hitBox.damageTaken >= painFase * 2))
		{
			self thread setDogAnim("german_shepherd_run_pain", 1.5, 1);
			self playSound("anml_dog_neckbreak_pain");
			currFase++;
		}
	}
}

onDogDeath()
{
	self waittill("killed_player");	
	self notify("end_anim");

	self playSound("anml_dog_neckbreak_pain");
	self freezeControls(0);
	dog_model = self.dogModel;
	dog_model.hitBox delete();
	self.dogModel = undefined;

	wait 0.25;
	
	dog_model scriptModelPlayAnim("german_shepherd_death_front");	
	dog_model.origin = bulletTrace(self.origin, self.origin - (0, 0, 60), false, self)["position"];	
	dog_model unLink();
	
	wait randomIntRange(2, 6);
	
	dog_model delete();
}

dogSounds()
{
	level endon("game_ended");
	self endon("death");
	self endon("disconnect");

	interval = randomIntRange(3, 5);

	for (;;)
	{
		wait interval;
		playsoundatpos(self.origin, "anml_dog_bark");
	}
}

dogTest()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	
	self.dogAnim = 0;
	dirAngle = self getPlayerAngles();
	
	for(;;)
	{
		wait 0.35;
		if (self.dogAnim) continue;
		dirAngle = vectortoangles(vectornormalize(self getVelocity()));		
		if(vectordot(anglestoforward(self getPlayerAngles()), dirAngle) < 0) self setPlayerAngles((dirAngle[0], dirAngle[1], self getPlayerAngles()[2]));
	}
}

setDogAnim(animation, time, freeze)
{
	self endon("end_anim");
	self endon("killed_player");
	
	if (self.dogAnim) return;
	if (isDefined(freeze)) self freezeControls(1);
	
	self.dogAnim = 1;
	self.dogModel scriptModelPlayAnim(animation);
	wait isDefined(time) ? time : 1;
	
	if (!isDefined(self.dogModel)) return;
	self.dogModel scriptModelPlayAnim("german_shepherd_run");
	
	self freezeControls(0);
	self.dogAnim = 0;
}

_crouch()
{
	if (self isusingremote() || self is_dog())
		return;
	
	self BotBuiltinBotAction("+gocrouch");
	self BotBuiltinBotAction("-goprone");
}

_prone()
{
	if (self isusingremote() || self is_dog())
		return;
	
	self BotBuiltinBotAction("-gocrouch");
	self BotBuiltinBotAction("+goprone");
}

_jump(surfaceInFront) //dog jump anim move the origin, real jump if has surface in front
{
	self endon("death");
	self endon("disconnect");
	self notify("bot_jump");
	self endon("bot_jump");

	if (self IsUsingRemote())
		return;

	if (self getStance() != "stand")
	{
		self stand();
		wait 1;
	}
	
	if (self is_dog() && !isDefined(surfaceInFront))
	{
		self thread setDogAnim("german_shepherd_run_jump_40", 0.65);
		return;
	}

	self botAction("+gostand");
	wait 0.05;
	self botAction("-gostand");
}

_doBotMovement_loop(data) //define surfaceInFront to _jump()
{
	if (isDefined(self.remoteUAV))
		self.bot.moveOrigin = self.remoteUAV.origin - (0, 0, 50);
	else if (isDefined(self.remoteTank))
		self.bot.moveOrigin = self.remoteTank.origin;
	else
		self.bot.moveOrigin = self.origin;

	waittillframeend;
	move_To = self.bot.moveTo;
	angles = self GetPlayerAngles();
	dir = (0, 0, 0);

	if (DistanceSquared(self.bot.moveOrigin, move_To) >= 49)
	{
		cosa = cos(0 - angles[1]);
		sina = sin(0 - angles[1]);

		// get the direction
		dir = move_To - self.bot.moveOrigin;

		// rotate our direction according to our angles
		dir = (dir[0] * cosa - dir[1] * sina,
		        dir[0] * sina + dir[1] * cosa,
		        0);

		// make the length 127
		dir = VectorNormalize(dir) * 127;

		// invert the second component as the engine requires this
		dir = (dir[0], 0 - dir[1], 0);
	}

	// climb through windows
	if (self isMantling())
	{
		data.wasMantling = true;
		self crouch();
	}
	else if (data.wasMantling)
	{
		data.wasMantling = false;
		self stand();
	}

	startPos = self.origin + (0, 0, 50);
	startPosForward = startPos + anglesToForward((0, angles[1], 0)) * 25;
	bt = bulletTrace(startPos, startPosForward, false, self);

	if (bt["fraction"] >= 1)
	{
		// check if need to jump
		bt = bulletTrace(startPosForward, startPosForward - (0, 0, 40), false, self);

		if (bt["fraction"] < 1 && bt["normal"][2] > 0.9 && data.i > 1.5 && !self isOnLadder())
		{
			data.i = 0;
			self thread jump(1);
		}
	}
	// check if need to knife glass
	else if (bt["surfacetype"] == "glass")
	{
		if (data.i > 1.5)
		{
			data.i = 0;
			self thread knife();
		}
	}
	else
	{
		// check if need to crouch
		if (bulletTracePassed(startPos - (0, 0, 25), startPosForward - (0, 0, 25), false, self) && !self.bot.climbing)
			self crouch();
	}

	// move!
	if (self.bot.wantsprint && self.bot.issprinting)
		dir = (127, dir[1], 0);

	self botMovement(int(dir[0]), int(dir[1]));

	if (isDefined(self.remoteUAV))
	{
		if (abs(move_To[2] - self.bot.moveOrigin[2]) > 12)
		{
			if (move_To[2] > self.bot.moveOrigin[2])
				self thread gostand();
			else
				self thread sprint();
		}
	}

	if (self is_dog()) self.dogModel.angles = (0, dir[1], 0);
}

_start_bot_threads()
{
	self endon("disconnect");
	level endon("game_ended");
	self endon("death");
	
	gameflagwait("prematch_done");
	
	self thread bot_weapon_think();
	self thread doReloadCancel();
	
	// script targeting
	if (getdvarint("bots_play_target_other") && !(self is_dog()))
	{
		self thread bot_target_vehicle();
		self thread bot_equipment_kill_think();
	}
	
	// awareness
	self thread bot_uav_think();
	self thread bot_listen_to_steps();
	self thread follow_target();
	
	// camp and follow
	if (getdvarint("bots_play_camp") && !(self is_dog()))
	{
		self thread bot_think_follow();
		self thread bot_think_camp();
	}
	
	// nades
	if (getdvarint("bots_play_nade") && !(self is_dog()))
	{
		self thread bot_jav_loc_think();
		self thread bot_use_tube_think();
		self thread bot_use_grenade_think();
		self thread bot_use_equipment_think();
		self thread bot_watch_riot_weapons();
		self thread bot_watch_think_mw2(); // bots play mw2
	}
}

is_dog()
{
	return isDefined(self.botType) && string_starts_with(self.botType, "dog_");
}
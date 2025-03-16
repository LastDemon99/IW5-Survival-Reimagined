#include common_scripts\utility;
#include maps\mp\_utility;
#include lethalbeats\survival\armories\_spawn;
#include lethalbeats\Survival\utility;
//#include lethalbeats\ServerControl\commands;

#define KNOCKDOWN_VIEW "iw5_dogviewknockdown_mp"
#define DOG_ATTACK_LATE "german_shepherd_attack_player_late"

#define DOG_ATTACK_SOUND "anml_dog_attack_kill_player"

init()
{
	precacheItem(KNOCKDOWN_VIEW);
	precacheMpAnim(DOG_ATTACK_LATE);

	/* ServerControl required: https://github.com/LastDemon99/IW5-Sripts/tree/main/GSC/ServerControl
	setCommand("play", ::play, 90, 1);
	setCommand("crate", ::crate, 90);
	setCommand("ammo", ::infiniteAmmo, 90);
	setCommand("ammo2", ::infiniteAmmo2, 90);
	setCommand("fly", ::fly, 90);
	setCommand("speed", ::setSpeed, 90, 1);
	setCommand("money", ::setMoney, 90, 1);
	setCommand("armor", ::setArmor, 90, 1);
	setCommand("clear", ::clearWave, 90);
	setCommand("wave", ::setWave, 90, 1);
	setCommand("shop", ::setShopsStatus, 90, 1);
	setCommand("view", ::getView, 90);
	setCommand("knife", ::knife, 90);
	setCommand("run", ::sprint, 90);
	setCommand("streak", ::giveKillstreak, 90, 1);
	setCommand("drop", ::dropCurrentWeapon, 90);
	setCommand("damage", ::selfDamage, 90);
	setCommand("dog", ::dogKnockdown, 90);
	setCommand("give", ::give, 90, 1);
	setCommand("test", ::dogHitbox, 90);
	setCommand("jugger", lethalbeats\survival\abilities\_juggernaut::giveAbility, 90);
	setCommand("predator", lethalbeats\Survival\abilities\_killstreaks::givePredator, 90);
	setCommand("airstrike", lethalbeats\Survival\abilities\_killstreaks::giveAirstrike, 90);
	setCommand("pavelow", lethalbeats\Survival\abilities\_pavelow::giveAbility, 90);
	setCommand("sentry", ::giveSentry, 90);
	setCommand("botstatus", ::botStatus, 90);
	//setCommand("test", ::test, 90);
	//setCommand("1", ::testDog, 90, 1);
	//setCommand("test", lethalbeats\Survival\abilities\_reaper::giveAbility, 90);*/
}

//////////////////////////////////////////
//	              TEST  		        //
//////////////////////////////////////////

botStatus()
{
	foreach(bot in bots())
		print(bot.botType, isAlive(bot));
	lethalbeats\array::array_print(lethalbeats\array::array_sort(level.botTest));
}

giveSentry()
{
	self [[level.killStreakFuncs["sentry"]]]();
}

give(weapon)
{
	self giveWeapon(weapon);
	self giveMaxAmmo(weapon);
}

dogHitbox()
{
	print(level.testDog.size);
	foreach(hitbox in level.testDog)
		print(hitbox.maxHealth, hitbox.damageTaken);
}

giveKillstreak(killStreak)
{
	self [[level.killStreakFuncs[killStreak]]]();
}

dropCurrentWeapon()
{
	weapon = self getCurrentWeapon();

	clipAmmoR = self getWeaponAmmoClip(weapon, "right");
	clipAmmoL = self getWeaponAmmoClip(weapon, "left");

	stockAmmo = self getWeaponAmmoStock(weapon);
	stockMax = weaponMaxAmmo(weapon);

	if (stockAmmo > stockMax) stockAmmo = stockMax;

	item = self dropItem(weapon);

	if (!isDefined(item))
		return;

	item ItemWeaponSetAmmo(clipAmmoR, stockAmmo, clipAmmoL);
	
	trigger = spawn("trigger_radius", item.origin, 0, 32, 32);
	trigger thread watchPickup(item);

	self switchToWeaponImmediate(lethalbeats\player::player_get_weapons()[0]);
}

watchPickup(item)
{
	self endon("death");

	weapon = item maps\mp\gametypes\_weapons::getItemWeaponName();
	weapon = lethalbeats\weapon::weapon_get_baseName(weapon);
	
	for(;;)
	{
		self waittill("trigger", player);
		targetWeapon = player lethalbeats\player::player_get_build_weapon(weapon);
		if (isDefined(targetWeapon)) break;
		wait 0.35;
	}

	currentStock = player getWeaponAmmoStock(targetWeapon);
	dropStock = int(weaponMaxAmmo(targetWeapon) * lethalbeats\array::array_random_choices([0.1, 0.2, 0.3])[0]);
	player setWeaponAmmoStock(targetWeapon, currentStock + dropStock);
	player playLocalSound("scavenger_pack_pickup");

	item delete();
	self delete();
}

selfDamage()
{
	radiusdamage(self.origin, 50, 10000, 10000, self, "MOD_EXPLOSIVE");
}

play(sound)
{
	lethalbeats\player::players_play_sound(sound);
}

test()
{
	print(survivors(true).size);
}

getView()
{
	self _giveWeapon(KNOCKDOWN_VIEW);
	self switchToWeaponImmediate(KNOCKDOWN_VIEW);
	//self SetWeaponAmmoClip(KNOCKDOWN_VIEW, 1);
}

knife()
{
	self player_client_cmd("+melee");
	wait 0.05;
	self player_client_cmd("-melee");
}

sprint()
{
	self player_client_cmd("+forward");
	wait 0.05;
	self player_client_cmd("+breath_sprint");
	wait 0.05;
	self player_client_cmd("-forward");
	wait 0.05;
	self player_client_cmd("-breath_sprint");
}

testDog(time)
{
	forward = anglesToForward(self getPlayerAngles());
	dog = spawn("script_model", self.origin + (forward * 50));
	dog setModel("german_sheperd_dog");
	dog scriptModelPlayAnim("german_shepherd_attack_player"); //german_shepherd_attack_player
	wait 0.8;
	dog scriptModelPlayAnim(DOG_ATTACK_LATE);
	wait float(time);
	dog scriptModelPlayAnim(DOG_ATTACK_LATE);
}

giveView()
{
	self _giveWeapon("iw5_dogviewkockdown_mp");
}

dogKnockdown()
{
	forward = anglesToForward(self getPlayerAngles());
	prevOrigin = self.origin;
	prevWeapon = self getCurrentWeapon();
	
	self _giveWeapon(KNOCKDOWN_VIEW);
	self switchToWeaponImmediate(KNOCKDOWN_VIEW);

	self setOrigin(self.origin + (forward * 100));
	knockdownSpot = spawn("script_origin", self.origin);
	knockdownSpot hide();
	
	self setPlayerAngles(vectorToAngles(forward));
	self playerLinkTo(knockdownSpot);

	body = spawn("script_model", prevOrigin);
	body.angles = (0, self.angles[1], 0);
	body setModel(self.model);

	head = spawn("script_model", prevOrigin);
	head setModel(self.headmodel);
	head linkto(body, "j_spine4", (0, 0, 0), (0, 0, 0));

	head hide();
	body hide();
	body playAnim("player_3rd_dog_knockdown", true);

	foreach(player in level.players)
	{
		if (player == self) continue;
		body showToPlayer(player);
		head showToPlayer(player);
	}

	right = anglesToRight(self getplayerangles());

	dog = spawn("script_model", prevOrigin + (forward * 28) - (0, 0, 3));
	dog setModel("german_sheperd_dog");
	dog scriptModelPlayAnim("german_shepherd_attack_player");
	dog.angles = vectorToAngles(-forward);

	//self thread count();
	//self thread dogAttackSound(dog);
	self thread dogSavedMonitor(dog, prevWeapon, knockdownSpot);
	self endon("dog_saved");

	self shellshock("frag_grenade_mp", 0.5);
	self thread sprint();
	wait 0.8;
	dog scriptModelPlayAnim(DOG_ATTACK_LATE);
	wait 1.1;
	self shellshock("frag_grenade_mp", 0.5);
	self thread sprint();
	dog scriptModelPlayAnim(DOG_ATTACK_LATE);
	wait 1.1;
	self shellshock("frag_grenade_mp", 0.5);
	self thread sprint();
	dog scriptModelPlayAnim(DOG_ATTACK_LATE);
	wait 0.25;
	self notify("dog_late");
	self freezeControls(true);
	wait 1;
	self thread maps\mp\gametypes\_shellshock::bloodEffect(self.origin);
	self setBlurForPlayer(1, 0.25);
	wait 3;
	body startragdoll();
	self setWeaponAmmoClip(KNOCKDOWN_VIEW, 0);
	wait 1;
	self setBlurForPlayer(0, 0);
	self suicide();
	wait 2;
	self unlink();
	knockdownSpot delete();
}

blurTest()
{
	wait 0.2;
	self setBlurForPlayer(1, 0.25);
	wait 0.4;
	self setBlurForPlayer(0, 0);
}

blur2()
{
	self setBlurForPlayer(1, 0.25);
	wait 0.35;
	self setBlurForPlayer(0, 0);
}

dogAttackSound(dog)
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	self endon("dog_late");
	self endon("dog_saved");

	playSoundAtPos(dog.origin, "anml_dog_attack_jump");
	wait 3.5;
	playSoundAtPos(dog.origin, "anml_dog_bark");
	wait 0.5;
	playSoundAtPos(dog.origin, "anml_dog_bark");
}

dogSavedMonitor(dog, prevWeapon, knockdownSpot)
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	self endon("dog_late");

	self notifyOnPlayerCommand("melee", "+melee_zoom");
	
	result = self lethalbeats\utility::waittill_any_return("dog_saved", "melee");

	if (result == "melee") dog scriptModelPlayAnim("german_shepherd_player_neck_snap");
	else dog scriptModelPlayAnim("german_shepherd_death_front");

	self notify("dog_saved");
	self iPrintlnBold("DOG SAVE");
	self setBlurForPlayer(0, 0);
	wait 5;
	
	self iPrintlnBold("UNLINK");
	knockdownSpot delete();
	self unlink();
	self takeWeapon(KNOCKDOWN_VIEW);
	self switchToWeaponImmediate(prevWeapon);
}

count()
{
	self endon("dog_late");
	self endon("dog_saved");

	for(i = 0;; i++)
	{
		self iPrintlnBold(i);
		wait 1;
	}
}

crate()
{
	if (!isDefined(level.crateSpawned)) self spawnCrate();
	self setPoint();
}

spawnCrate()
{
	level.crateSpawned = true;

	origin = self.origin;
	angles = self.angles;

	shopModel = spawnShopModel(origin, angles);
	setDvar("crate_origin", origin);
	setDvar("crate_angles", angles);
	
	crate = shopModel[0];
	laptop = shopModel[1];
	laptop setModel("com_laptop_2_open");

	print(int(origin[0]) + " " + int(origin[1]) + " " + int(origin[2]));
	
	for(;;)
	{
		_origin = getDvarVector("crate_origin");
		_angles = getDvarVector("crate_angles");

		if (_origin != origin)
		{
			setDvar("crate_origin", _origin);
			crate.origin = _origin;
			laptop.origin = crate.origin + (0, 0, 14);
			origin = _origin;
		}
		
		if(_angles != angles)
		{
			setDvar("crate_angles", _angles);
			crate.angles = _angles;
			laptop.anles = crate.angles + (0, 90, 0);
			angles = _angles;
		}
		
		wait 0.5;
	}
}

setPoint()
{
	setDvar("crate_origin", self.origin);
	setDvar("crate_angles", self.angles);
	origin = self.origin;
	print(int(origin[0]) + " " + int(origin[1]) + " " + int(origin[2]));
	print(int(origin[0]) + ", " + int(origin[1]) + ", " + int(origin[2]));
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

//////////////////////////////////////////
//	              DEV CMD  		        //
//////////////////////////////////////////

infiniteAmmo()
{
	self thread lethalbeats\player::player_refill_ammo();
}

infiniteAmmo2()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	
    for (;;)
    {
        self waittill("weapon_fired");		
		weapon = self getCurrentWeapon();		
		if(!isDefined(weapon) || lethalbeats\weapon::weapon_get_class(weapon) == "riot") continue;
		self setWeaponAmmoClip(weapon, 99);
    }
}

fly()
{
	if (self.sessionstate == "spectator")
	{
		self allowSpectateTeam("freelook", false);
		self.sessionstate = "playing";
		self setContents(100);
		return;
	}
	
	self allowSpectateTeam("freelook", true);
	self.sessionstate = "spectator";
	self setContents(0);
}

setSpeed(speed)
{
	setDvar("g_speed", speed);
}

setMoney(money)
{
	self lethalbeats\survival\utility::survivor_set_score(int(money));
}

setArmor(armor)
{
	self lethalbeats\survival\utility::survivor_set_body_armor(int(armor));
}

clearWave()
{
	bots = lethalbeats\survival\utility::bots();
	foreach(bot in bots) bot suicide();
}

setWave(wave)
{
	setDvar("survival_wave_start", int(wave));
	cmdexec("map_restart");
}

setShopsStatus(allow)
{
	setDvar("survival_wait_shops", !int(allow));
	cmdexec("map_restart");
}

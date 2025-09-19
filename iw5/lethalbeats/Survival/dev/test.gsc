#include common_scripts\utility;
#include maps\mp\_utility;
#include lethalbeats\survival\armories\_spawn;
#include lethalbeats\Survival\utility;
#include lethalbeats\ServerControl\commands;
#include lethalbeats\vector;
#include lethalbeats\player;
#include lethalbeats\utility;

#define KNOCKDOWN_VIEW "iw5_dogviewknockdown_mp"
#define DOG_ATTACK_LATE "german_shepherd_attack_player_late"
#define DOG_ATTACK_SOUND "anml_dog_attack_kill_player"

init()
{
	precacheItem(KNOCKDOWN_VIEW);
	precacheMpAnim(DOG_ATTACK_LATE);

	//* ServerControl required: https://github.com/LastDemon99/IW5-Sripts/tree/main/GSC/ServerControl
	setCommand("play", ::play, 0, 1);
	setCommand("crate", ::crate);
	setCommand("ammo", ::infiniteAmmo);
	setCommand("ammo2", ::infiniteAmmo2);
	setCommand("fly", ::fly);
	setCommand("speed", ::setSpeed, 0, 1);
	setCommand("money", ::setMoney, 0, 1);
	setCommand("armor", ::setArmor, 0, 1);
	setCommand("clear", ::clearWave);
	setCommand("wave", ::setWave, 0, 1);
	setCommand("shop", ::setShopsStatus, 0, 1);
	setCommand("view", ::getView);
	setCommand("knife", ::knife);
	setCommand("run", ::sprint);
	setCommand("streak", ::giveKillstreak, 0, 1);
	setCommand("drop", ::dropCurrentWeapon);
	setCommand("damage", ::selfDamage);
	setCommand("dog", ::dogKnockdown);
	setCommand("give", ::give, 0, 1);
	setCommand("test", ::dogHitbox);
	setCommand("jugger", lethalbeats\survival\abilities\_juggernaut::giveAbility);
	setCommand("predator", lethalbeats\Survival\abilities\_killstreaks::givePredator);
	setCommand("airstrike", lethalbeats\Survival\abilities\_killstreaks::giveAirstrike);
	setCommand("pavelow", lethalbeats\Survival\abilities\_pavelow::giveAbility);
	setCommand("sentry", ::giveSentry);
	setCommand("botstatus", ::botStatus);
	setCommand("music", ::bgMusic);
	setCommand("saveMap", ::saveMap);
	setCommand("save", ::saveData);
	setCommand("restore", ::restoreData);
	setCommand("revive", ::spawnRevive);
	setCommand("chem", lethalbeats\survival\abilities\_chemical::giveAbility);
	setCommand("detonate", ::abilityDetonate);
	setCommand("chemmine", ::chemMine);
}

chemMine()
{
	playfx(level._effect["chemical_mine_spew"], self.origin);
}

abilityDetonate()
{
	self notify("detonate");
}

saveData()
{
	saveState = [];
	saveState["map"] = getDvar("mapname");
	saveState["wave"] = level.wave_num;

	for(i = 0; i < level.players.size; i++)
	{
		player = level.players[i];
		if (player isTestClient()) continue;
		playerData["origin"] = lethalbeats\vector::vector_truncate(player.origin, 3);
		playerData["angles"] = lethalbeats\vector::vector_truncate(player getPlayerAngles(), 3);
		playerData["stance"] = player getStance();
		playerData["kills"] = player.pers["kills"];
		playerData["deaths"] = player.pers["deaths"];
		playerData["assists"] = player.pers["assists"];
		playerData["score"] = player.pers["score"];
		playerData["armor"] = player.bodyArmor;
		playerData["hasRevive"] = player.hasRevive;
		playerData["perks"] = player.survivalPerks;
		playerData["grenades"] = player.grenades;
		playerData["killstreak"] = "";

		if (isDefined(player.pers["killstreaks"]) && isDefined(player.pers["killstreaks"][0]) && isDefined(player.pers["killstreaks"][0].streakname))
			playerData["killstreak"] = player.pers["killstreaks"][0].streakname;

		if (lethalbeats\string::string_starts_with(playerData["killstreak"], "airdrop_"))
			playerData["killstreak"] = "airdrop_" + player.airdropType;

		playerData["currentWeapon"] = player getCurrentWeapon();
		playerData["prevWeapon"] = player.prevWeapon;
		
		print(playerData["killstreak"], playerData["currentWeapon"]);

		primary = player player_get_primary();
		if (isDefined(primary))
		{
			playerData["weaponData"][0] = player player_get_weapon_data(primary);
        	playerData["ammoData"][0] = player player_get_ammo_data(primary);
		}

		secondary = player player_get_secondary();
		if (isDefined(secondary))
		{
			playerData["weaponData"][1] = player player_get_weapon_data(secondary);
        	playerData["ammoData"][1] = player player_get_ammo_data(secondary);
		}
		
		saveState[player.guid] = playerData;
	}

	game["saveState2"] = saveState;
}

restoreData()
{
	playerData = game["saveState2"][self.guid];

	self setOrigin(playerData["origin"]);
	self setPlayerAngles(playerData["angles"]);
	self setStance(playerData["stance"]);

	self.pers["kills"] = playerData["kills"];
	self.score = self.pers["kills"];

	self.pers["deaths"] = playerData["deaths"];
	self.score = self.pers["deaths"];

	self.pers["assists"] = playerData["assists"];
	self.score = self.pers["assists"];

	self survivor_set_score(playerData["score"]);
	self survivor_set_body_armor(playerData["armor"]);

	if (playerData["hasRevive"]) self survivor_give_last_stand();
	else
	{
		self.hasRevive = false;
		self setClientDvar("ui_self_revive", 0);
		self player_give_perk("specialty_finalstand", false);
	}

	foreach(perk in playerData["perks"])
		self survivor_give_perk(perk);

	self player_clear_nades();
	foreach(grenade, ammount in playerData["grenades"])
	{
		if (ammount) self player_set_nades(grenade, ammount);
		if (grenade == "claymore_mp") self player_set_action_slot(1, "weapon", grenade);
		else if (grenade == "c4_mp") self player_set_action_slot(5, "weapon", grenade);
	}

	if (lethalbeats\string::string_starts_with(playerData["killstreak"], "airdrop_"))
		self lethalbeats\survival\killstreaks\_airdrop::giveAirDrop(lethalbeats\string::string_slice(playerData["killstreak"], 8));
	else
		self maps\mp\killstreaks\_killstreaks::giveKillstreak(playerData["killstreak"]);

	self player_take_all_weapons();
	for(i = 0; i < 2; i++)
	{
		if (!isDefined(playerData["weaponData"][i])) continue;
		weapon = playerData["weaponData"][i][0];
		self player_give_weapon(weapon, false, false, true);
		self player_set_weapon_data(weapon, playerData["weaponData"][i]);
		self player_set_ammo_data(weapon, playerData["ammoData"][i]);
	}

	self.prevWeapon = playerData["prevWeapon"];
	if (maps\mp\_utility::isKillstreakWeapon(playerData["currentWeapon"])) self switchToWeaponImmediate(self.prevWeapon);
	else self switchToWeaponImmediate(playerData["currentWeapon"]);
}

spawnRevive()
{
	reviveEnt = spawn_model(self.origin);
	reviveEnt lethalbeats\hud::hud_create_3d_objective("allies", "waypoint_revive", 8, 8);
	reviveEnt.objective.color = (0.33, 0.75, 0.24);

	trigger = lethalbeats\trigger::trigger_create(self.origin);
	trigger lethalbeats\trigger::trigger_set_use_hold(10, "Hold ^3[{+activate}] ^7to revive the player", true, false);
	trigger lethalbeats\trigger::trigger_set_enable_condition(::survivor_trigger_filter);
	trigger thread reviveMonitor();
}

reviveMonitor()
{
	level endon("game_ended");
    self endon("death");

	for(;;)
	{
		self waittill("trigger_hold_complete", player);
		self lethalbeats\trigger::trigger_delete();
	}
}

saveMap() { lethalbeats\survival\dev\mapedit::saveEdits(); }

bgMusic()
{
	numTracks = game["music"]["suspense"].size;
	maps\mp\_utility::playsoundonplayers(game["music"]["suspense"][randomint(numTracks)]);
}

botStatus()
{
	foreach(bot in bots())
		print(bot.botType, isAlive(bot));
}

giveSentry()
{
	self [[level.killStreakFuncs["sentry"]]]();
}

give(weapon)
{
	self player_give_weapon(weapon, true, true);
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

	self survivor_switch_to_weapon(lethalbeats\player::player_get_weapons()[0]);
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
	self lethalbeats\trigger::trigger_delete();
}

selfDamage()
{
	radiusdamage(self.origin, 50, 10000, 10000, self, "MOD_EXPLOSIVE");
}

play(sound)
{
	lethalbeats\player::players_play_sound(sound);
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
	body.angles = (0, self.angles[1], 90);
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
	self setWeaponAmmoClip(KNOCKDOWN_VIEW);
	wait 1;
	self setBlurForPlayer(0);
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
	self setBlurForPlayer(0);
}

blur2()
{
	self setBlurForPlayer(1, 0.25);
	wait 0.35;
	self setBlurForPlayer(0);
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
	self setBlurForPlayer(0);
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
			laptop.anles = crate.angles + (0, 0, 90);
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
	level endon("wave_end");

	for(;;)
	{
		bots = lethalbeats\survival\utility::bots();
		foreach(bot in bots) bot suicide();

		vehicles = getentarray("script_vehicle", "classname");
		foreach (vehicle in vehicles)
			vehicle notify("damage", 9999999, self, (0, 0, 0), vehicle.origin, "MOD_PROJECTILE_SPLASH", undefined, undefined, undefined, undefined, "artillery_mp");
		wait 0.5;
	}
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

onAddAllyBot()
{
	self thread onJoinAllyBot();
	self thread lethalbeats\Survival\survivorHandler::onPlayerDisconnect();
	self thread lethalbeats\Survival\survivorHandler::onPlayerSpawn();
}

onJoinAllyBot()
{
    self endon("disconnect");

	self.sessionteam = "allies";
	self.pers["team"] = "allies";
	self.sessionteam = "allies";
	self.botType = undefined;
	self survivor_wave_init();

	skill = 30;
	self.pers["bots"]["skill"]["spawn_time"] = 0;
    self.pers["bots"]["skill"]["aim_time"] = _bot_wave_scale(0.6, 0, 0.1, skill);
    self.pers["bots"]["skill"]["init_react_time"] = self.pers["bots"]["skill"]["aim_time"];
    self.pers["bots"]["skill"]["reaction_time"] = _bot_wave_scale(2500, 0, 0.1, skill);
    self.pers["bots"]["skill"]["remember_time"] = _bot_wave_scale(500, 7500, 1, skill);
    self.pers["bots"]["skill"]["no_trace_ads_time"] = _bot_wave_scale(500, 2500, 0.2, skill);
    self.pers["bots"]["skill"]["no_trace_look_time"] = self.pers["bots"]["skill"]["no_trace_ads_time"];
    self.pers["bots"]["skill"]["fov"] = skill > 15 ? -1 : _bot_wave_scale(0.7, 0, 0.2, skill);
    self.pers["bots"]["skill"]["dist_start"] = _bot_wave_scale(1000, 10000, 0.5, skill);
    self.pers["bots"]["skill"]["dist_max"] =_bot_wave_scale(1200, 15000, 0.8, skill);
    self.pers["bots"]["skill"]["help_dist"] = 3000;
    self.pers["bots"]["skill"]["semi_time"] = _bot_wave_scale(0.9, 0.05, 0.3, skill);
    self.pers["bots"]["skill"]["shoot_after_time"] = _bot_wave_scale(1, 0, 0.25, skill);
    self.pers["bots"]["skill"]["aim_offset_time"] = _bot_wave_scale(1.8, 0, 0.25, skill);
    self.pers["bots"]["skill"]["aim_offset_amount"] = _bot_wave_scale(4, 0, 0.25, skill);
    self.pers["bots"]["skill"]["bone_update_interval"] = _bot_wave_scale(2.5, 0.25, 0.25, skill);
    self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_ankle_le,j_ankle_ri,j_ankle_le,j_ankle_ri";
    self.pers["bots"]["skill"]["ads_fov_multi"] = 1;
    self.pers["bots"]["skill"]["ads_aimspeed_multi"] = 1;
	
    self.pers["bots"]["behavior"]["strafe"] = 50;
	self.pers["bots"]["behavior"]["nade"] = 70;
	self.pers["bots"]["behavior"]["sprint"] = 60;
	self.pers["bots"]["behavior"]["camp"] = 0;
	self.pers["bots"]["behavior"]["follow"] = 100;
	self.pers["bots"]["behavior"]["crouch"] = 0;
	self.pers["bots"]["behavior"]["class"] = 0;
	self.pers["bots"]["behavior"]["jump"] = 20;
	self.pers["bots"]["behavior"]["quickscope"] = 0;
	self.pers["bots"]["behavior"]["switch"] = 50;

	self.pers["bots"]["skill"]["dist_max"] = 15000;
	self.pers["bots"]["skill"]["dist_start"] = 10000;

    for (;;)
    {
        self waittill("joined_team");
		self notify("menuresponse", "team_marinesopfor", "allies");
		self maps\mp\gametypes\_menus::addToTeam("allies", 1);
		self lethalbeats\player::player_disable_weapon_pickup();
		self takeWeapon("iw5_fnfiveseven_mp");
		self lethalbeats\player::player_give_weapon("stinger_mp");
		self lethalbeats\player::player_give_weapon("iw5_ak47_mp", true);
		//self thread lethalbeats\player::player_refill_ammo();
		self thread lethalbeats\survival\dev\test::infiniteAmmo2();
    }
}

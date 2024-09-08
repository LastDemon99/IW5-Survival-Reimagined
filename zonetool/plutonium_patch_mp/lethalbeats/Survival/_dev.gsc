#include common_scripts\utility;
#include maps\mp\_utility;
#include lethalbeats\survival\armories\_spawn;

//add forge mode

init()
{
	setDvarIfUninitialized("survival_dev_mode", 0);
	setDvarIfUninitialized("disable_waves", 0);
	setDvarIfUninitialized("await_shops", 1);
	
	if(!getDvarInt("survival_dev_mode")) 
	{
		setDvar("disable_waves", 0);
		setDvar("await_shops", 1);
		setDvar("jump_slowdownEnable", 1);
		setDvar("g_speed", 190);
		return;
	}
	
	level thread onSay();	
	//level thread test();
}

test()
{
	pos = (40, -365, -377);
	rot = 24;
	
	setDvar("crate_pos", pos[0] + " " + pos[1] + " " + pos[2]);
	setDvar("crate_rot", rot);
	
	shopModel = spawnShopModel(pos, rot);
	
	crate = shopModel[0];
	laptop = shopModel[1];
	laptop setModel("com_laptop_2_open");
	
	for(;;)
	{
		_pos = strTok(getDvar("crate_pos"), " ");
		_pos = (int(_pos[0]), int(_pos[1]), int(_pos[2]));		
		
		_rot = getDvarInt("crate_rot");
		
		if(_rot != rot)
		{
			setDvar("crate_rot", _rot);
			crate.angles = (0, _rot, 0);
			laptop.anles = (0, _rot + 90, 0);
			rot = _rot;
		}

		if (_pos != pos)
		{
			setDvar("crate_pos", _pos[0] + " " + _pos[1] + " " + _pos[2]);
			crate.origin = _pos;
			laptop.origin = crate.origin + (0, 0, 14);
			pos = _pos;
		}
		
		wait 0.5;
	}
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

#using_animtree("player_3rd_person");
test2()
{
	body = spawn("script_model", self.origin);
	body.angles = (0, self.angles[1], 0);
	body setModel(self.model);

	head = spawn("script_model", self.origin);
	head setModel(self.headmodel);
	head linkto(body, "j_spine4", (0, 0, 0), (0, 0, 0));

	body playAnim("player_3rd_dog_knockdown", true);

	forward = anglesToForward((0, self.angles[1], 0));
	dog = spawn("script_model", self.origin + (forward * 20));
	dog.angles = (0, -self.angles[1], 0);
	dog setModel("german_sheperd_dog");
	dog playAnim("german_shepherd_attack_player", true);

	wait(0.35 * getAnimLength(%player_3rd_dog_knockdown));	
	self iprintlnbold("ANIM END");
	body startragdoll();

	//self.body = self clonePlayer(1);
	//self PlayerHide();
	//self.model scriptModelPlayAnim("player_3rd_dog_knockdown");
}

onCommand(player, msg)
{
	args = [];
	foreach(i in msg)
		args[args.size] = tolower(i);
	
	switch(args[0])
	{
		case "!test": player thread test2(); break;
		case "!s": player suicide(); break;
		case "!fly": player fly(); break;
		case "!weapon": level thread spawnShopModel(player.origin, "weapon"); break;
		case "!equipment": level thread spawnShopModel(player.origin, "equipment"); break;
		case "!support": level thread spawnShopModel(player.origin, "support"); break;
		case "!speed": setDvar("g_speed", int(args[1])); break;
		case "!money": player lethalbeats\survival\_utility::setScore(int(args[1])); break;
		case "!armor": player.bodyArmor = int(args[1]); break;
		case "!clear":
			foreach(player in level.players)
				if(player.team == "axis") player suicide();
			break;
		case "!wave": level.wave_num = int(args[1]); break;
		case "!waves": 
			setDvar("disable_waves", !int(args[1]));
			cmdexec("map_restart");
			break;
		case "!shops": 
			setDvar("await_shops", int(args[1]));
			cmdexec("map_restart");
			break;
		case "!res":
		case "!restart": cmdexec("map_restart"); break;
		case "!rot":
		case "!rotate": cmdexec("start_map_rotate"); break;
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

onSay()
{
	level endon("game_ended");
	
	for(;;) 
	{
		level waittill("say", message, player);
		
		level.args = [];	
		str = strTok(message, "");
		i = 0;
		
		if(!string_starts_with(str[0], "!")) break;
		
		foreach (s in str) 
		{
			level.args[i] = s;
			i++;
		}
		
		str = strTok( level.args[0], " ");
		i = 0;
		
		if(!string_starts_with(str[0], "!")) break;
		
		foreach(s in str) 
		{
			level.args[i] = s;
			i++;
		}
		
		onCommand(player, level.args);
	}
}

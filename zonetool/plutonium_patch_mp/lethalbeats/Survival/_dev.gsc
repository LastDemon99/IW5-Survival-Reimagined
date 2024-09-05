#include common_scripts\utility;
#include maps\mp\_utility;
#include lethalbeats\survival\armory\_spawn;

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

onCommand(player, msg)
{
	args = [];
	foreach(i in msg)
		args[args.size] = tolower(i);
	
	switch(args[0])
	{
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

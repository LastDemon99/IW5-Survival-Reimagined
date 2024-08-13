#include maps\mp\_utility;
#include maps\mp\survival\_utility;

init()
{
    game["menu_team"] = "custom_options";
    game["menu_class_axis"] = "custom_options";
    game["menu_class_allies"] = "custom_options";
}

shopTrigger()
{
	self endon("disconnect");
	level endon("game_ended");
	self endon("death");
	
	for (;;)
	{
		self waittill("trigger_use", trigger);
		if (isDefined(self.currMenu)) continue;
		if (trigger.tag == "weapon_shop") self maps\lethalbeats\DynamicMenus\dynamic_shop::openShop("weapon_armory");
		else if (trigger.tag == "equipment_shop") self maps\lethalbeats\DynamicMenus\dynamic_shop::openShop("equipment_armory");
		else if (trigger.tag == "support_shop") self maps\lethalbeats\DynamicMenus\dynamic_shop::openShop("air_support_armory");
	}
}

getTeamAssignment()
{
	if (self.sessionteam != "none" && self.sessionteam != "spectator" && self.sessionstate != "playing" && self.sessionstate != "dead") return self.sessionteam;
	return common_scripts\utility::random(["allies", "axis"]);
}

menuAutoAssign()
{
	self closeMenus();
	
	assignment = getTeamAssignment();
		
	if (isDefined(self.pers["team"]) && (self.sessionstate == "playing" || self.sessionstate == "dead"))
	{		
		if (assignment == self.pers["team"])
		{
			self beginClassChoice();
			return;
		}
		else
		{
			self.switching_teams = true;
			self.joining_team = assignment;
			self.leaving_team = self.pers["team"];
			self suicide();
		}
	}	

	self addToTeam(assignment);
	self.pers["class"] = undefined;
	self.class = undefined;
	
	if (!isAlive(self))
		self.statusicon = "hud_status_dead";
	
	self notify("end_respawn");
	
	self beginClassChoice();
}

beginClassChoice(forceNewChoice)
{
	self thread bypassClassChoice();	
	if (!isAlive(self)) self thread maps\mp\gametypes\_playerlogic::predictAboutToSpawnPlayerOverTime(0.1);
}

bypassClassChoice()
{
	self.selectedClass = true;
	self [[level.class]]("class0");	
}

menuSpectator()
{
	self closeMenus();
	
	if(isDefined(self.pers["team"]) && self.pers["team"] == "spectator")
		return;

	if(isAlive(self))
	{
		assert(isDefined(self.pers["team"]));
		self.switching_teams = true;
		self.joining_team = "spectator";
		self.leaving_team = self.pers["team"];
		self suicide();
	}

	self addToTeam("spectator");
	self.pers["class"] = undefined;
	self.class = undefined;

	self thread maps\mp\gametypes\_playerlogic::spawnSpectator();
}

menuClass(response)
{
	self closeMenus();
	
	// clear new status of unlocked classes
	if (response == "demolitions_mp,0" && self getPlayerData("featureNew", "demolitions"))
	{
		self setPlayerData("featureNew", "demolitions", false);
	}
	if (response == "sniper_mp,0" && self getPlayerData("featureNew", "sniper"))
	{
		self setPlayerData("featureNew", "sniper", false);
	}

	// this should probably be an assert
	if(!isDefined(self.pers["team"]) || (self.pers["team"] != "allies" && self.pers["team"] != "axis"))
		return;

	class = self maps\mp\gametypes\_class::getClassChoice(response);
	primary = self maps\mp\gametypes\_class::getWeaponChoice(response);

	if (class == "restricted")
	{
		self beginClassChoice();
		return;
	}

	if((isDefined(self.pers["class"]) && self.pers["class"] == class) && 
		(isDefined(self.pers["primary"]) && self.pers["primary"] == primary))
		return;

	if (self.sessionstate == "playing")
	{
		// if last class is already set then we don't want an undefined class to replace it
		if(IsDefined(self.pers["lastClass"]) && IsDefined(self.pers["class"]))
		{
			self.pers["lastClass"] = self.pers["class"];
			self.lastClass = self.pers["lastClass"];
		}

		self.pers["class"] = class;
		self.class = class;
		self.pers["primary"] = primary;

		if (game["state"] == "postgame")
			return;

		if (level.inGracePeriod && !self.hasDoneCombat) // used weapons check?
		{
			self maps\mp\gametypes\_class::setClass(self.pers["class"]);
			self.tag_stowed_back = undefined;
			self.tag_stowed_hip = undefined;
			self maps\mp\gametypes\_class::giveLoadout(self.pers["team"], self.pers["class"]);
		}
		else
		{
			self iPrintLnBold(game["strings"]["change_class"]);
		}
	}
	else
	{
		// if last class is already set then we don't want an undefined class to replace it
		if(IsDefined(self.pers["lastClass"]) && IsDefined(self.pers["class"]))
		{
			self.pers["lastClass"] = self.pers["class"];
			self.lastClass = self.pers["lastClass"];
		}

		self.pers["class"] = class;
		self.class = class;
		self.pers["primary"] = primary;

		if (game["state"] == "postgame")
			return;

		if (game["state"] == "playing" && !isInKillcam())
			self thread maps\mp\gametypes\_playerlogic::spawnClient();
	}

	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
}

addToTeam(team, firstConnect)
{
	// UTS update playerCount remove from team
	if (isDefined(self.team))
		self maps\mp\gametypes\_playerlogic::removeFromTeamCount();
		
	self.pers["team"] = team;
	// this is the only place self.team should ever be set
	self.team = team;
	
	// session team is readonly in ranked matches on console
	if (!matchMakingGame() || isDefined(self.pers["isBot"]) || !allowTeamChoice())
	{
		if (level.teamBased)
		{
			self.sessionteam = team;
		}
		else
		{
			if (team == "spectator")
				self.sessionteam = "spectator";
			else
				self.sessionteam = "none";
		}
	}

	// UTS update playerCount add to team
	if (game["state"] != "postgame")
		self maps\mp\gametypes\_playerlogic::addToTeamCount();	

	self updateObjectiveText();

	// give "joined_team" and "joined_spectators" handlers a chance to start
	// these are generally triggered from the "connected" notify, which can happen on the same
	// frame as these notifies
	if (isDefined(firstConnect) && firstConnect)
		waittillframeend;

	self updateMainMenu();

	if (team == "spectator")
	{
		self notify("joined_spectators");
		level notify("joined_team");
	}
	else
	{
		self notify("joined_team");
		level notify("joined_team");
	}
}

beginTeamChoice() {}
showMainMenuForTeam() {}
menuAllies() {}
menuAxis() {}

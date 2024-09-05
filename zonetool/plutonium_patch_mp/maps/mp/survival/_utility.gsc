#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

//////////////////////////////////////////
//	Hud								    //
//////////////////////////////////////////

hudDisplay(hud)
{
	self setClientDvar("ui_display", hud);
	self OpenMenu("ui_display");
}

notifyHideInMenu(hide)
{
	self.notifyTitle.hideWhenInMenu = hide;
	self.notifyText.hideWhenInMenu = hide;
	self.notifyText2.hideWhenInMenu = hide;
	self.notifyIcon.hideWhenInMenu = hide;
	self.notifyOverlay.hideWhenInMenu = hide;
}

setScore(score)
{
	self.pers["score"] = score;
	self.score = self.pers["score"];
	self setClientDvar("ui_money", self.pers["score"]);
}

giveScore(score, type)
{
	if (!isDefined(type)) type = undefined;
	maps\mp\gametypes\_gamescore::giveplayerscore("survival", self, undefined, int(score), type);
}

onDamageArmor(damage)
{
	armor = int(self.bodyArmor - damage);
	
	if (armor <= 0)
	{
		self.bodyArmor = 0;
		self setClientDvar("ui_body_armor", 0);
		return;
	}
	
	self.bodyArmor = armor;
	self setClientDvar("ui_body_armor", self.bodyArmor);
	self hudDisplay("armor_damage");
}

destroyIntermissionTimer()
{
	if(!isDefined(level.timerHud)) return;
	level.timerHud destroy();
	level.timerHud = undefined;
}

setChallenge(index, label, steps)
{
	challenge["label"] = label;
	challenge["type"] = toLower(strTok(label, " ")[0]);
	challenge["step"] = 0;
	challenge["max_step"] = steps;	
	self.challenges[index] = challenge;

	self setClientDvar("ui_ch_label_" + index, label);	
	self setClientDvar("ui_ch_step_" + index, 0);
	self setClientDvar("ui_ch_maxstep_" + index, steps);
}

checkChallenge(type)
{
	if (self.challenges[0]["type"] == type) index = 0;
	else if (self.challenges[1]["type"] == type) index = 1;
	else return;

	if (self.challenges[index]["step"] == self.challenges[index]["max_step"] - 1)
	{
		award = int(500 * (((self.challenges[index]["max_step"] - 5) / 2) + 1));

		notifyData = spawnStruct();
		notifyData.titleText = self.challenges[index]["label"] + " $ " + award;
		notifyData.glowColor = (1, 0.49, 0);
		notifyData.sound = "survival_bonus_splash";
		notifyData.foreground = true;
		notifyData.hidewheninmenu = true;

		self giveScore(award);
		self maps\mp\gametypes\_hud_message::notifyMessage(notifyData);

		self.challenges[index]["step"] = 0;
		self.challenges[index]["max_step"] += 2;
		self setClientDvar("ui_ch_maxstep_" + index, self.challenges[index]["max_step"]);
	}
	else self.challenges[index]["step"]++;

	self setClientDvar("ui_ch_step_" + index, self.challenges[index]["step"]);
}

destroySurvivalHuds()
{
	if (isDefined(self.hintString)) 
	{
		self.hintString destroyElem();
		self.hintString = undefined;
	}
	
	self.currMenu = undefined;
	self.onTrigger = undefined;
	
	self setClientDvar("ui_body_armor", 0);
	self setClientDvar("ui_self_revive", 0);
	self setClientDvar("ui_use_slot", "none");
	self setClientDvar("client_cmd", "");	
	
	ch = self.ch1;
	ch["huds"][0] destroyElem();
	ch["huds"][1] destroy();
	ch["huds"][2] destroy();
	self.ch1 = undefined;
	
	ch = self.ch2;
	ch["huds"][0] destroyElem();
	ch["huds"][1] destroy();
	ch["huds"][2] destroy();
	self.ch2 = undefined;
}

updatePerks()
{
	self setClientDvar("ui_perk1", "");
	self setClientDvar("ui_perk2", "");
	self setClientDvar("ui_perk3", "");
	
	if (self.survivalPerks.size > 0) self setClientDvar("ui_perk1", self.survivalPerks[0]);
	else return;
	
	if (self.survivalPerks.size > 1) self setClientDvar("ui_perk2", self.survivalPerks[1]);
	else return;
	
	if (self.survivalPerks.size > 2) self setClientDvar("ui_perk3", self.survivalPerks[2]);
	else return;
}

//////////////////////////////////////////
//	Random Stuffs 				        //
//////////////////////////////////////////

hasStreak()
{
	return self.pers["killstreaks"].size == 6 || self hasWeapon("airdrop_sentry_marker_mp");
}

refillNades()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	
	for (;;)
    {
		self waittill("grenade_fire", grenade, weaponName);
				
		if(!contains(weaponName, getarraykeys(self.grenades))) continue;
		if(self.grenades[weaponName])
		{
			self addNades(weaponName, -1);
			if(weaponName == "claymore_mp" && self.grenades[weaponName]) self switchToWeapon(weaponName);
		}
	}
}

refillAmmo()
{
    level endon( "game_ended" );
    self endon( "disconnect" );

    for (;;)
    {
        self waittill("reload");
		currWep = self getCurrentWeapon();		
		if(currWep == "riotshield_mp" || !isDefined(currWep)) continue;		
		self giveMaxAmmo(currWep);
    }
}

refillSingleCountAmmo()
{
    level endon( "game_ended" );
    self endon( "disconnect" );

    for (;;)
    {
		wait 0.3;		
		currWep = self getCurrentWeapon();
		if(currWep == "riotshield_mp" || !isDefined(currWep)) continue;		
        if (isAlive(self) && self getammocount(currWep) == 0) self notify("reload");
	}
}

setNades(nade, value)
{
	self checkNadeClass(nade);
	
	ui_dvar = "";	
	if (nade == "frag_grenade_mp" || nade == "throwingknife_mp") ui_dvar = "ui_lethal";
	else if (nade == "flash_grenade_mp" || nade == "concussion_grenade_mp") ui_dvar = "ui_tactical";
	else ui_dvar = "ui_" + strTok(nade, "_")[0];
	
	maxAmmo = getNadeMaxAmmmo(nade);	
	self.grenades[nade] = min(value, maxAmmo);
	self setClientDvar(ui_dvar, self.grenades[nade]);
	self setWeaponAmmoStock(nade, int(self.grenades[nade]));
}

addNades(nade, value)
{
	if(!(self hasWeapon(nade))) self giveweapon(nade);
	self setNades(nade, self.grenades[nade] + value);
}

checkNadeClass(nade)
{
	if (nade == "frag_grenade_mp")
	{
		self setOffhandPrimaryClass("frag");
		self takeweapon("throwingknife_mp");
		self _giveWeapon("frag_grenade_mp");
		self.grenades["throwingknife_mp"] = 0;
	}
	else if (nade == "throwingknife_mp")
	{
		self setOffhandPrimaryClass("throwingknife");
		self takeweapon("frag_grenade_mp");
		self _giveWeapon("throwingknife_mp");
		self.grenades["frag_grenade_mp"] = 0;
	}
	else if (nade == "flash_grenade_mp")
	{
		self setOffhandSecondaryClass("flash");
		self takeweapon("concussion_grenade_mp");
		self _giveWeapon("flash_grenade_mp");
		self.grenades["concussion_grenade_mp"] = 0;
	}
	else if (nade == "concussion_grenade_mp")
	{
		self setOffhandSecondaryClass("smoke");
		self takeweapon("flash_grenade_mp");
		self _giveWeapon("concussion_grenade_mp");
		self.grenades["flash_grenade_mp"] = 0;
	}
}

getNadeMaxAmmmo(nade)
{
	switch(nade)
	{
		case "frag_grenade_mp":
		case "throwingknife_mp":
		case "flash_grenade_mp":
		case "semtex_mp":
		case "concussion_grenade_mp": return 4;
		case "claymore_mp":
		case "c4_mp": return 10;
	}
}

is_survivor()
{
	return isDefined(self.team) && isPlayer(self) && self.team == "allies";
}

is_bot() 
{
	return isDefined(self) && isPlayer(self) && self isTestClient();
}

is_dog()
{
	return isDefined(self.botType) && string_starts_with(self.botType, "dog_");
}

survivorsCount()
{
	count = 0;
	foreach (player in level.players)
		if (player.team == "allies") count++;
	return count;	
}

hasSurvivorDeath()
{
	death = false;
	foreach (player in level.players)
		if (player.team == "allies" && !isAlive(player)) return true;
	return death;
}

allSurvivorsDeath()
{
	death = true;
	foreach (player in level.players)
		if (player.team == "allies" && isAlive(player)) return false;
	return death;
}

getSurvivorsAlive()
{
	survivors = [];
	foreach (player in level.players)
		if (player.team == "allies" && isAlive(player)) survivors[survivors.size] = player;
	return survivors;
}

botsCount()
{
	count = 0;
	foreach (player in level.players)
		if (player.team == "axis")
			count++;
	return count;	
}

_revive()
{
	self clearLastStand();
	self LastStandRevive();
	self _unsetPerk( "specialty_finalstand" );
	self.headicon = "";
	self setStance("stand");
	self.revived = true;
	
	self notify ("revive");
}

getPerkFromKsPerk(killstreak_perk)
{
	perk = "";	
	for (i = 0; i < killstreak_perk.size - 3; i++) perk += killstreak_perk[i];		
	return perk;
}

clearLastStand()
{	
	if(isDefined(self.lastStandBar))
	{
		self.lastStandBar.overlay destroy();
		self.lastStandBar.icon destroy();
		self.lastStandBar destroyElem();
	}
	
	self.health = self.maxhealth;
	self.laststand = undefined;
	self.barFrac = undefined;
	
	self _enableUsability();
	self enableWeaponSwitch();
	self enableOffhandWeapons();
	self enableWeaponPickup();
	
	if (isDefined(self.lastStandWeapon)) 
	{
		self takeweapon("iw5_fnfiveseven_mp");
		self.lastStandWeapon = undefined;
	}
	
	if (isDefined(self.prevWeapon)) self switchtoweapon(self.prevWeapon);
	
	maps\mp\_utility::clearlowermessage( "last_stand" );
}

clearSurvivalPerks()
{
	foreach(perk in self.survivalPerks) self _unsetPerk(perk);
	self.survivalPerks = [];
	self updatePerks();
}

giveSurvivalPerk(perk)
{
	if (self _hasPerk(perk)) return;	
	if(self.survivalPerks.size == 3) return;
	
	self givePerk(perk, false);
	
	if(perk == "specialty_bulletaccuracy") perk = "specialty_steadyaim";
	else if(perk == "_specialty_blastshield") perk = "specialty_blastshield";
	
	self.survivalPerks[self.survivalPerks.size] = perk;
	self updatePerks();
}

removeSurvivalPerk(perk)
{
	if (!isDefined(self.perks[perk])) return;
	
	self _unsetPerk(perk);
	
	if(perk == "specialty_bulletaccuracy") perk = "specialty_steadyaim";
	else if(perk == "_specialty_blastshield") perk = "specialty_blastshield";
	
	perks = [];
	foreach(i in self.survivalPerks)
	{
		if (i == perk) continue;
		perks[perks.size] = i;
	}
	
	self.survivalPerks = perks;
	self updatePerks();
}

_setDogAnim(animation, time, freeze)
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

standard_deviation(array)
{
	mean = sum(array) / array.size;
	
	diff = [];
	foreach(i in array) diff[diff.size] = i - mean;
	
	sqr = [];
	foreach(i in diff) sqr[sqr.size] = squared(i);
	
	sd = sqrt(sum(sqr) / sqr.size);
	
	return sd;
}

contains(target, array)
{
	foreach(i in array)
		if(i == target) return true;
	return false;
}

sum(array)
{
	sum = 0;
	foreach(i in array) sum += i;
	return sum;
}

replace(string, target)
{
	if(!isSubstr(string, target)) return string;
	
	newString = "";
	index = 0;
	
	for(;;)
	{
		if (string.size - (index + 1) < target.size) break;		
		_target = "";		
		for(i = index; i < string.size; i++) _target += string[i];
		if (string_starts_with(_target, target)) break;
		index++;
	}
	
	for(i = 0; i < string.size; i++)
		if (i < index || i > index + target.size - 1) newString += string[i];
	
	return newString;
}
#include maps\mp\killstreaks\_ims;

#define IMS_CARRY_MAX_MS 25000
#define IMS_KAMIKAZE_PLANT_SQ 140 * 140
#define IMS_SPOT_NODE_DIST 160
#define IMS_MIN_NEIGHBOURS 3

init()
{
    replaceFunc(::tryuseims, ::_tryUseIMS);
    replaceFunc(::ims_setActive, ::_ims_setActive);
    replaceFunc(::ims_timeOut, ::_ims_timeOut);
    replaceFunc(::addtoimslist, ::_blank);
    replaceFunc(::removefromimslist, ::_blank);
    replaceFunc(::ims_handleownerdisconnect, ::_ims_handleownerdisconnect);
    replaceFunc(::ims_createbombsquadmodel, ::_ims_createbombsquadmodel);
    replaceFunc(::ims_handleDamage, ::_ims_handleDamage);
    replaceFunc(::ims_handleDeath, ::_ims_handleDeath);
}

_blank(var) { }

_tryUseIMS() 
{
    imsForPlayer = createIMSForPlayer("ims", self);
    return self _setcarryingims(imsForPlayer);
}

_setcarryingims(imsForPlayer)
{
    self endon("death");
    self endon("disconnect");
    
    imsForPlayer thread ims_setcarried(self);
    self lethalbeats\player::player_disable_weapons();

    if (self lethalbeats\survival\utility::player_is_survivor())
    {
        self notifyonplayercommand("place_ims", "+attack");
        self notifyonplayercommand("place_ims", "+attack_akimbo_accessible");
        self notifyonplayercommand("cancel_ims", "+actionslot 4");

        for (;;)
        {
            result = common_scripts\utility::waittill_any_return("place_ims", "cancel_ims", "force_cancel_placement");
            
            if (result == "cancel_ims" || result == "force_cancel_placement")
            {
                imsForPlayer ims_setcancelled();
                self lethalbeats\player::player_enable_weapons();
                return false;
            }

            if (!imsForPlayer.canbeplaced) continue;

            imsForPlayer thread ims_setplaced();
            self lethalbeats\player::player_enable_weapons();
            return true;
        }
    }

    deadline = getTime() + IMS_CARRY_MAX_MS;
    for (;;)
    {
        wait 0.35;
        if (!imsForPlayer.canbeplaced || lethalbeats\utility::is_any_entity_near(level.botsIMS, self.origin, IMS_SPOT_NODE_DIST)) continue;
        if (lethalbeats\utility::is_any_entity_near(lethalbeats\survival\utility::survivors(true), self.origin, IMS_KAMIKAZE_PLANT_SQ) || self ims_spot_is_allowed() || getTime() >= deadline)
        {
            imsForPlayer thread ims_setplaced();
            self lethalbeats\player::player_enable_weapons();
            self notify("placed_ims");
            return true;
        }
    }
}

ims_spot_is_allowed()
{
    lethalbeats\botactor\navigation::_botactorEnsureWaypoints();
    if (!isDefined(level.waypoints) || !level.waypoints.size)
        return false;

    if (isDefined(self lethalbeats\botactor\utility::bot_claymore_nearest_node(IMS_SPOT_NODE_DIST)))
        return true;

    idx = self lethalbeats\botactor\navigation::_botgetNearestWaypoint(self.origin, true);
    if (!isDefined(idx))
        return false;

    wp = level.waypoints[idx];
    if (!isDefined(wp) || !isDefined(wp.children) || !isDefined(wp.origin))
        return false;

    if (wp.children.size < IMS_MIN_NEIGHBOURS)
        return false;

    return distanceSquared(self.origin, wp.origin) <= IMS_SPOT_NODE_DIST * IMS_SPOT_NODE_DIST;
}

_ims_setActive() // self == ims
{
	owner = self.owner;
	owner forceUseHintOff();
    isSurvivor = owner lethalbeats\survival\utility::player_is_survivor();

    self makeUsable();
	self setCanDamage(true);

    foreach (player in level.players) self disablePlayerUse(player);	
    if (isSurvivor) 
    {
        self setCursorHint("HINT_NOICON");
	    self setHintString(level.imsSettings[self.imsType].hintString);
        self maps\mp\_entityheadicons::setTeamHeadIcon("allies", (0, 0, 20));
        self enablePlayerUse(owner);
        level thread maps\mp\_utility::teamPlayerCardSplash(level.imsSettings[self.imsType].splashName, owner);
		self.shouldSplash = false;
    }
    else level.botsIMS[level.botsIMS.size] = self;

	positionOffset = (0, 0, 20);
	traceOffset = (0, 0, 256);
	results = [];
	tagOrigin = self getTagOrigin(level.imsSettings[self.imsType].tagExplosive1) + positionOffset;
	results[0] = bulletTrace(tagOrigin, tagOrigin + (traceOffset - positionOffset), false, self);
	tagOrigin = self getTagOrigin(level.imsSettings[self.imsType].tagExplosive2) + positionOffset;
	results[1] = bulletTrace(tagOrigin, tagOrigin + (traceOffset - positionOffset), false, self);
	tagOrigin = self getTagOrigin(level.imsSettings[self.imsType].tagExplosive3) + positionOffset;
	results[2] = bulletTrace(tagOrigin, tagOrigin + (traceOffset - positionOffset), false, self);
	tagOrigin = self getTagOrigin(level.imsSettings[self.imsType].tagExplosive4) + positionOffset;
	results[3] = bulletTrace(tagOrigin, tagOrigin + (traceOffset - positionOffset), false, self);
	
	lowestZ = results[0];
	for(i = 0; i < results.size; i++)
        if(results[i]["position"][2] < lowestZ["position"][2])
			lowestZ = results[i];

	self.attackHeightPos = lowestZ["position"] - (0, 0, 20);
	attackTrigger = spawn("trigger_radius", self.origin, 0, 256, 100);
	self.attackTrigger = attackTrigger;
	self.attackMoveTime = distance(self.origin, self.attackHeightPos) / 200;

	self thread ims_blinky_light();
	self thread _ims_attacktargets();
	self thread ims_playerConnected();
}

_ims_timeOut()
{
	self endon("death");
	level endon("game_ended");

	if (isDefined(self.owner) && self.owner lethalbeats\survival\utility::player_is_bot()) return;
	lifespan = level.imsSettings[self.imsType].lifespan;
	while (lifespan)
	{
		wait 1;
		if (!isDefined(self.carriedBy)) lifespan = max(0, lifespan - 1.0);
	}

	self notify("death");
}

_ims_handleownerdisconnect()
{
    self endon("death");
    self notify("ims_handleOwner");
    self endon("ims_handleOwner");
    self.owner waittill("disconnect");    
    self notify("death");
}

_ims_createbombsquadmodel()
{
    if (self.owner lethalbeats\survival\utility::player_is_survivor()) return;
    bombSquadModel = spawn("script_model", self.origin);
    bombSquadModel.angles = self.angles;
    bombSquadModel hide();
    bombSquadModel thread maps\mp\gametypes\_weapons::bombsquadvisibilityupdater("allies", self.owner);
    bombSquadModel setmodel(level.imssettings[self.imstype].modelbombsquad);
    bombSquadModel linkto(self);
    bombSquadModel setcontents(0);
    self.bombsquadmodel = bombSquadModel;
    self waittill("death");
    bombSquadModel delete();
}

_ims_handleDamage() // self == ims
{
	self endon("death");
	level endon("game_ended");

	self.health = 999999;
	self.maxHealth = 300;
	self.damageTaken = 0;

	while(true)
	{
		self waittill("damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon);

        if (isDefined(weapon))
		{
			switch(weapon)
			{
                case "concussion_grenade_mp":
                case "flash_grenade_mp":
                case "smoke_grenade_mp":
                case "ims_projectile_mp":
                    continue;
			}
		}

		owner = self.owner;
		ownerTeam = owner.team;
		if (!maps\mp\gametypes\_weapons::friendlyFireCheck(owner, attacker)) continue;
		if (isDefined(attacker) && isDefined(attacker.owner)) attacker = attacker.owner;
		if (meansOfDeath == "MOD_MELEE" && isDefined(attacker) && attacker == owner)
		{
			attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback("sentry");
			self.damagetaken += self.maxhealth;
		}
		else
		{
			if (ownerTeam == "allies" || (isDefined(attacker) && isDefined(attacker.team) && ownerTeam == attacker.team)) continue;
			if (isplayer(attacker)) attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback("sentry");
			self.damagetaken += self lethalbeats\survival\utility::equipmen_modified_damage(damage, attacker, weapon, meansOfDeath);
		}
		
		if (self.damageTaken >= self.maxHealth)
		{
			attacker notify("destroyed_killstreak");
			if (isdefined(owner)) owner thread maps\mp\_utility::leaderdialogonplayer("ims_destroyed");
            self notify("death");
			return;
		}
	}
}

_ims_handleDeath()
{
	self waittill("death");
	if (!isDefined(self)) return;

    level.botsIMS = lethalbeats\array::array_remove(level.botsIMS, self);

	self ims_setInactive();
	self playSound("ims_destroyed");

    origin = self.origin;
	playfx(common_scripts\utility::getfx("ims_explode_mp"), origin + (0, 0, 10));
    
    waittillframeend;
    self playSound("detpack_explo_main");
    playRumbleOnPosition("grenade_rumble", origin);
    earthquake(0.4, 0.75, origin, 512);
    playfx(level.mine_explode, origin);

	if (isDefined(self.objIdFriendly)) maps\mp\_utility::_objective_delete(self.objIdFriendly);
	if (isDefined(self.objIdEnemy)) maps\mp\_utility::_objective_delete(self.objIdEnemy);

	if(isDefined(self.lid1)) self.lid1 delete();
	if(isDefined(self.lid2)) self.lid2 delete();
	if(isDefined(self.lid3)) self.lid3 delete();
	if(isDefined(self.lid4)) self.lid4 delete();

	if(isDefined(self.explosive1)) self.explosive1 delete();
	if(isDefined(self.explosive2)) self.explosive2 delete();
	if(isDefined(self.explosive3)) self.explosive3 delete();
	if(isDefined(self.explosive4)) self.explosive4 delete();

	self delete();
}

_ims_attacktargets()
{
    level endon("game_ended");
    self endon("death");

    for (;;)
    {
        if (!isdefined(self.attacktrigger)) break;

        self.attacktrigger waittill("trigger", target);

        if (isplayer(target))
        {
            if (isdefined(self.owner) && target == self.owner) continue;
            if (level.teambased && target.pers["team"] == self.team) continue;
            if (!maps\mp\_utility::isreallyalive(target)) continue;
        }
        else if (isdefined(target.owner))
        {
            if (isdefined(self.owner) && target.owner == self.owner) continue;
            if (level.teambased && target.owner.pers["team"] == self.team) continue;
        }

        if (!sighttracepassed(self.attackheightpos, target.origin + (0, 0, 50), 0, self) || !sighttracepassed(self gettagorigin(level.imssettings[self.imstype].taglid1) + (0, 0, 5), target.origin + (0, 0, 50), 0, self) && !sighttracepassed(self gettagorigin(level.imssettings[self.imstype].taglid2) + (0, 0, 5), target.origin + (0, 0, 50), 0, self) && !sighttracepassed(self gettagorigin(level.imssettings[self.imstype].taglid3) + (0, 0, 5), target.origin + (0, 0, 50), 0, self) && !sighttracepassed(self gettagorigin(level.imssettings[self.imstype].taglid4) + (0, 0, 5), target.origin + (0, 0, 50), 0, self))
            continue;

        self playsound("ims_trigger");

        if (isplayer(target) && target maps\mp\_utility::_hasperk("specialty_delaymine"))
        {
            target notify("triggered_ims");
            wait(level.delayminetime);
            if (!isdefined(self.attacktrigger)) break;
        }
        else wait(level.imssettings[self.imstype].graceperiod);

        if (isdefined(self.explosive1) && !isdefined(self.explosive1.fired))
            fire_sensor(target, self.explosive1, self.lid1);
        else if (isdefined(self.explosive2) && !isdefined(self.explosive2.fired))
            fire_sensor(target, self.explosive2, self.lid2);
        else if (isdefined(self.explosive3) && !isdefined(self.explosive3.fired))
            fire_sensor(target, self.explosive3, self.lid3);
        else if (isdefined(self.explosive4) && !isdefined(self.explosive4.fired))
            fire_sensor(target, self.explosive4, self.lid4);

        self.attacks--;

        if (self.attacks <= 0)
            break;

        wait 2.0;

        if (!isdefined(self.owner))
            break;
    }

    if (isdefined(self.carriedby) && isdefined(self.owner) && self.carriedby == self.owner)
        return;

    self notify("death");
}


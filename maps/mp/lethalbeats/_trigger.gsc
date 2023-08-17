#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

set2DIcon(showTo, shader)
{
	if (showTo == "all")
	{
		set2DIcon("allies", shader);
		set2DIcon("axis", shader);
		return;
	}
	
	objId = maps\mp\gametypes\_gameobjects::getNextObjID();
	objective_add(objId, "active", (0, 0, 0));
	objective_state(objId, "active");
	objective_position(objId, self.origin);
	objective_icon(objId, shader);
	
	if (isPlayer(showTo)) objective_player(objId, showTo);
	else objective_team(objId, showTo);
	
	if(!isDefined(self.icon2D)) self.icon2D = [];
	self.icon2D[showTo] = objId;
}

update2DIcon(showTo, shader)
{
	if(!isDefined(self.icon2D[showTo])) return;
	objective_icon(self.icon2D[showTo], shader);
}

set3DIcon(showTo, shader, height, width, targetEnt, offset)
{	
	if (isPlayer(showTo)) icon = newClientHudElem(showTo);
	else if (showTo == "all") icon = newHudElem();
	else icon = newTeamHudElem(showTo);
	
	icon setShader(shader, height, width);
	icon setWaypoint(true, true);
	
	if(!isDefined(targetEnt)) targetEnt = isDefined(offset) ? spawn("script_model", self.origin + offset) : self;	
	icon setTargetEnt(targetEnt);	
	
	if(!isDefined(self.icon3D)) self.icon3D = [];
	self.icon3D[showTo] = icon;
}

update3DIcon(showTo, shader)
{
	if(!isDefined(self.icon3D[showTo])) return;
	icon = self.icon3D[showTo];
	icon setShader(shader, icon.height, icon.width);
}

setUseHold(useTime, hintString, progressBar)
{
	self.type = "useHold";
	self.useTime = useTime;
	self.useHintString = isDefined(hintString) ? hintString : "";
	
	if (!isDefined(progressBar) || (isDefined(progressBar) && progressBar)) 
		self progressBarOffset(0, 25);
}

setRadiusHold(useTime, hintString, progressBar)
{
	self setUseHold(useTime, hintString, progressBar);
	self.type = "radiusHold";
}

progressBarOffset(xOffset, yOffset)
{
	self.pbarX = xOffset;
	self.pbarY = yOffset;
}

createTrigger(tag, origin, rx, ry, rz, hintString, showTo)
{
	trigger = spawn("trigger_radius", origin, rx, ry, rz);
	trigger.tag = tag;
	trigger.type = "use";
	trigger.showTo = showTo;
	trigger.hintString = isDefined(hintString) ? hintString : "";
	trigger thread onTriggerRadius();
	trigger thread deleteTriggerMonitor();
	return trigger;
}

onTriggerRadius()
{
	level endon("game_ended");
	self endon("delete");
	
	for(;;)
	{
		self waittill("trigger", player);
		
		if (isDefined(self.showTo) && (isPlayer(self.showTo) && self.showTo != player) || (!isPlayer(self.showTo) && self.showTo != player.team)) continue;
		if (isDefined(self.condition) && !(self [[self.condition]](player))) continue;
		if (isDefined(player.onTrigger) || isDefined(player.hintString)) continue;
		
		player.onTrigger = self;
		player notifyTrigger("trigger_enter", self);
		if(isDefined(self.hintString)) player setCustomHintString(self.hintString);
		
		player thread triggerMonitor(self);
		
		player notifyTrigger("trigger_zone", self);
		if (self.type != "radiusHold") continue;
		else if (!(self radiusHoldThink(player))) continue;
		player notifyTrigger("trigger_radius_holded", self);
	}
}

triggerMonitor(trigger)
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	trigger endon("delete");
	
	for(;;)
	{
		if (!(self isTouching(trigger)))
		{
			self notifyTrigger("trigger_leave", trigger);
			self clearCustomHintString();
			self.onTrigger = undefined;
			break;
		}
		
		if (self useButtonPressed())
		{
			if (trigger.type == "use") self notifyTrigger("trigger_use", trigger);
			else if(trigger.type == "useHold")
			{
				if (!(trigger useHoldThink(self))) continue;
				self notifyTrigger("trigger_use_holded", trigger);
			}
		}
		wait 0.15;
	}
}

deleteTriggerMonitor()
{
	level endon("game_ended");
	self waittill("delete");
	
	foreach(player in level.players) 
		if (isDefined(player.onTrigger) && player.onTrigger == self)
		{
			player clearCustomHintString();
			player.onTrigger = undefined;
		}
	
	if (isDefined(self.icon3D)) 
		foreach(showTo in getarraykeys(self.icon3D)) self.icon3D[showTo] destroy();
	
	if (isDefined(self.icon2D)) 
		foreach(showTo in getarraykeys(self.icon2D)) _objective_delete(self.icon2D[showTo]);
	
	self delete();
}

setCustomHintString(text)
{
	if(isDefined(self.hintString))
	{
		self.hintString setText(text);
		return;
	}	
	
	hintString = self maps\mp\gametypes\_hud_util::createFontString("hudbig", 0.6);
	hintString setText(text);
	hintString maps\mp\gametypes\_hud_util::setPoint("center", "center", 0, 115);
	hintString.alpha = 0.75;
	self.hintString = hintString;
}

clearCustomHintString()
{
	if(!isDefined(self.hintString)) return;
	self.hintString maps\mp\gametypes\_hud_util::destroyElem();
	self.hintString = undefined;
}

useHoldThink(player)
{
    player playerLinkTo(self);
    player playerLinkedOffsetEnable();    
    player _disableWeapon();
    
    self.curProgress = 0;
    self.inUse = true;
    self.useRate = 0;
    
    if (isDefined(self.pbarX)) player thread personalUseBar(self);
   
    result = useHoldThinkLoop(player);
	if (self.curProgress > self.useTime) wait 0.3;
    
    if (isAlive(player))
    {
        player _enableWeapon();
        player unlink();
    }
    
    if (!isDefined(self)) return false;

    self.inUse = false;
	self.curProgress = 0;

	return result;
}

radiusHoldThink(player)
{
    self.curProgress = 0;
    self.inUse = true;
    self.useRate = 0;
    
    if (isDefined(self.pbarX)) player thread personalUseBar(self);
    
	result = radiusHoldThinkLoop(player);
	if (self.curProgress > self.useTime) wait 0.3;
	
    if (!isDefined(self)) return false;

    self.inUse = false;
	self.curProgress = 0;

	return result;
}

useHoldThinkLoop(player)
{
	while(!level.gameEnded && isDefined(self) && isReallyAlive(player) && player useButtonPressed() && self.curProgress < self.useTime)
    {
        self.curProgress += (66 * self.useRate);       
		if (isDefined(self.triggeriveScaler)) self.useRate = 1 * self.triggeriveScaler;
		else self.useRate = 1;
		if (self.curProgress > self.useTime) return (isReallyAlive(player));
        wait 0.05;
    }
    return false;
}

radiusHoldThinkLoop(player)
{
	while(!level.gameEnded && isDefined(self) && isReallyAlive(player) && player isTouching(self) && self.curProgress < self.useTime)
    {
        self.curProgress += (66 * self.useRate);       
		if (isDefined(self.triggeriveScaler)) self.useRate = 1 * self.triggeriveScaler;
		else self.useRate = 1;
		if (self.curProgress > self.useTime) return (isReallyAlive(player));
        wait 0.05;
    }    
    return false;
}

personalUseBar(trigger)
{
    self endon("disconnect");
	
	useBar = createPrimaryProgressBar(trigger.pbarX, trigger.pbarY);
    useBarText = createPrimaryProgressBarText(trigger.pbarX, trigger.pbarY);
    useBarText setText(trigger.useHintString);
	
    lastRate = -1;
    while (isReallyAlive(self) && isDefined(trigger) && trigger.inUse && !level.gameEnded)
    {
        if (lastRate != trigger.useRate)
        {			
            useBar updateBar(trigger.curProgress / trigger.useTime, (1000 / trigger.useTime) * trigger.useRate);

            if (!trigger.useRate)
            {
                useBar hideElem();
                useBarText hideElem();
            }
            else
            {
                useBar showElem();
                useBarText showElem();
            }
        }    
        lastRate = trigger.useRate;
        wait (0.05);
    }
    useBar destroyElem();
    useBarText destroyElem();
}

notifyTrigger(msg, trigger)
{
	self notify(msg, trigger);
	trigger notify(msg, self);
}
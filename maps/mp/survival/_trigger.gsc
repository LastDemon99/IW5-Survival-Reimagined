#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

setUseHold(useTime, hintString, progressBar)
{
	self.type = "useHold";
	self.useTime = useTime;
	self.useHintString = isDefined(hintString) ? hintString : "";
	
	if (isDefined(progressBar))
	{
		self.progressBar = progressBar;
		self progressBarOffset(0, 25);
	}
	else self.progressBar = undefined;
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

createTrigger(tag, origin, rx, ry, rz, hintString)
{
	trigger = spawn("trigger_radius", origin, rx, ry, rz);
	trigger.tag = tag;
	trigger.hintString = isDefined(hintString) ? hintString : "";
	trigger.type = "use";
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
		if (isDefined(player.onTrigger) || isDefined(player.hintString)) continue;
		
		player.onTrigger = self;
		player notify("trigger_enter", self);
		if(isDefined(self.hintString)) player setCustomHintString(self.hintString);
		
		player thread triggerMonitor(self);
		
		player notify("trigger_zone", self);
		if (self.type != "radiusHold") continue;
		else if (!(self radiusHoldThink(player))) continue;
		player notify("trigger_radius_holded", self);
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
			self notify("trigger_leave", trigger);
			self clearCustomHintString();
			self.onTrigger = undefined;
			break;
		}
		
		if (self useButtonPressed())
		{
			self notify("trigger_use", trigger);
			
			if (trigger.type != "useHold") continue;
			else if (!(trigger useHoldThink(self))) continue;
			self notify("trigger_use_holded", trigger);
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
    
    if (isDefined(self.progressBar)) player thread personalUseBar(self);
   
    result = useHoldThinkLoop(player);
	if (self.curProgress > self.useTime) wait 0.35;
    
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
    
    if (isDefined(self.progressBar)) player thread personalUseBar(self);
    
	result = radiusHoldThinkLoop(player);
	if (self.curProgress > self.useTime) wait 0.35;
	
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
#include maps\mp\gametypes\_weapons;
#include lethalbeats\trigger;
#include lethalbeats\array;

#define CLAYMORE "claymore_mp"
#define C4 "c4_mp"
#define BOUNCINGBETTY "bouncingbetty_mp"

grenadeWatchUsage()
{
    self endon("death");
    self endon("disconnect");
    self endon("faux_spawn");
    
    if (!isDefined(self.mines)) self.mines = [];

    self.throwinggrenade = undefined;
    self.gotpullbacknotify = 0;

    self thread grenadeWatchPullback();
    self thread c4WatchAltDetonate();
    self thread watchForThrowbacks();
    self thread mineDeleteOnDisconnect();

    for (;;)
    {
        self waittill("grenade_fire", item, weaponName);

        maps\mp\gametypes\_gamelogic::setHasDoneCombat(self, 1);
        otherTeam = level.otherteam[self.team];

        if (weaponName == C4)
        {
            item thread mineCreateBombSquadModel("weapon_c4_bombsquad", self);
            self c4Watch(item, weaponName);
            continue;
        }

        if (weaponName == CLAYMORE)
        {
            item thread mineCreateBombSquadModel("weapon_claymore_bombsquad", self);
            self claymoreWatch(item, weaponName);
            continue;
        }

        if (weaponName == BOUNCINGBETTY)
        {
            item thread mineCreateBombSquadModel("projectile_bouncing_betty_grenade_bombsquad", self);
            self bouncingbettyWatch(item, weaponName);
            continue;
        }

        if (weaponName == "frag_grenade_mp")
        {
            item thread mineCreateBombSquadModel("projectile_m67fraggrenade_bombsquad", self);
            continue;
        }

        if (weaponName == "frag_grenade_short_mp")
        {
            item thread mineCreateBombSquadModel("projectile_m67fraggrenade_bombsquad", self);
            continue;
        }

        if (weaponName == "semtex_mp")
            item thread mineCreateBombSquadModel("projectile_semtex_grenade_bombsquad", self);

        if (weaponName == "throwingknife_mp")
            self throwingKnifeWatch(item, weaponName);
    }
}

grenadeWatchPullback()
{
    for (;;)
    {
        self waittill("grenade_pullback", weaponName);

        setWeaponStat(weaponName, 1, "shots");
        maps\mp\gametypes\_gamelogic::setHasDoneCombat(self, 1);
        thread watchOffHandCancel();

        if (weaponName == CLAYMORE) continue;

        self.throwinggrenade = weaponName;
        self.gotpullbacknotify = 1;

        if (weaponName == C4) beginC4Tracking();
        else beginGrenadeTracking();

        self.throwinggrenade = undefined;
    }
}

c4Watch(item, weaponName)
{
    if (!isDefined(self.mines[C4]))
    {
        self.mines[C4] = [];
        self thread c4WatchAltDetonate();
    }
    else if (self.mines[C4].size > level.maxperplayerexplosives)
    {
        result = array_pop(self.mines[C4]);
        self.mines[C4] = result[0];
        result[1] detonate();
    }

    self.mines[C4][self.mines[C4].size] = item;

    item.owner = self;
    item.team = self.team;
    item.activated = true;
    item.weaponname = weaponName;

    item thread maps\mp\gametypes\_shellshock::c4_earthquake();
    item thread mineDamage();
    item thread c4empdamage();
    item thread c4empkillstreakwait();
    item thread c4WatchStuck();
}

c4WatchStuck()
{
    self.owner endon("spawned_player");
    self.owner endon("disconnect");
    self endon("death");

    self waittill("missile_stuck");
    
    trigger = trigger_create(self.origin, 70);
    trigger trigger_set_use("Press ^3[{+activate}] ^7to pick up C4");
    trigger trigger_set_enable_condition(::minePickupCondition);
    trigger.owner = self.owner;
    self.trigger = trigger;

    if (self.owner.team == "allies") self thread setClaymoreTeamHeadIcon(self.owner.team);
    self mineWatchPickup(self.owner, trigger);
}

c4WatchAltDetonate()
{
    level endon("game_ended");
    self endon("death");
    self endon("disconnect");

    self notifyOnPlayerCommand("attack", "+attack");

    for(;;)
	{
		self waittill("attack");
        if (self getCurrentWeapon() != C4 || !self.mines[C4].size) continue;
        wait 0.3;

        foreach(mine in self.mines[C4])
        {
            if (isdefined(mine))
            {
                if (isdefined(mine.trigger)) mine.trigger trigger_delete();
                mine detonate();
            }
        }
        self.mines[C4] = [];
    }
}

claymoreWatch(item, weaponName)
{
    item.owner = self;
    item.team = self.team;
    item.activated = true;
    item.weaponname = weaponName;
    item hide();

    item thread claymoreWatchStuck(self, weaponName);
}

claymoreWatchStuck(owner, weaponName)
{
    self waittill("missile_stuck");

    distanceZ = 40;
    if (distanceZ * distanceZ < distanceSquared(self.origin, owner.origin))
    {
        secTrace = bulletTrace(owner.origin, owner.origin - (0, 0, distanceZ), 0, owner);
        if (!isDefined(secTrace["fraction"]) || secTrace["fraction"] == 1)
        {
            owner setWeaponAmmoStock(CLAYMORE, owner getWeaponAmmoStock(CLAYMORE) + 1);
            self delete();
            return;
        }
        self.origin = secTrace["position"];
    }

    self show();
    owner notify("claymore_stuck", self);
    owner.changingweapon = undefined;

    if (!isDefined(owner.mines[CLAYMORE])) owner.mines[CLAYMORE] = [];
    else if (owner.mines[CLAYMORE].size > level.maxperplayerexplosives)
    {
        result = array_pop(owner.mines[CLAYMORE]);
        owner.mines[CLAYMORE] = result[0];
        result[1] detonate();
    }

    owner.mines[CLAYMORE][owner.mines[CLAYMORE].size] = self;

    self thread mineDamage();
    self thread c4empdamage();
    self thread c4empkillstreakwait();
    self thread claymoreWatchProximity();

    trigger = trigger_create(self.origin, 70);
    trigger trigger_set_use("Press ^3[{+activate}] ^7to pick up Claymore");
    trigger trigger_set_enable_condition(::minePickupCondition);
    trigger.owner = owner;
    self.trigger = trigger;

    if (owner.team == "allies") self thread setClaymoreTeamHeadIcon(owner.team);
    self mineWatchPickup(owner, trigger);
}

claymoreWatchProximity()
{
    self endon("death");

    self.damageArea = trigger_create(self.origin + (0, 0, 0 - level.claymoredetonateradius), level.claymoredetonateradius, level.claymoredetonateradius * 2);

    for (;;)
    {
        self.damageArea waittill("trigger_radius", player);
        
        if (isdefined(self.owner) && player == self.owner) continue;
        if (!friendlyFireCheck(self.owner, player, 0)) continue;
        //if (lengthsquared(player getEntityVelocity()) < 10) continue; disable for bots

        zDistance = abs(player.origin[2] - self.origin[2]);

        if (zDistance > 128 || !player shouldAffectClaymore(self)) continue;
        if (player damageConeTrace(self.origin, self) > 0) break;
    }

    self notify("mine_triggered");
    self playsound("claymore_activated");

    if (isplayer(player) && player maps\mp\_utility::_hasPerk("specialty_delaymine"))
    {
        player notify("triggered_claymore");
        wait(level.delayminetime);
    }
    else wait(level.claymoredetectiongraceperiod);

    if (isdefined(self.trigger))
    {
        if (isdefined(self.damageArea)) self.damageArea trigger_delete();
        self.trigger trigger_delete();
        self.bombSquad delete();
        self.owner.mines[self.weaponname] = array_remove(self.owner.mines[self.weaponname], self);
    }

    self detonate();
}

bouncingbettyWatch(item, weaponName)
{
    if (!isDefined(self.mines[BOUNCINGBETTY])) self.mines[BOUNCINGBETTY] = [];
    else if (self.mines[BOUNCINGBETTY].size > level.maxperplayerexplosives)
    {
        result = array_pop(self.mines[BOUNCINGBETTY]);
        self.mines[BOUNCINGBETTY] = result[0];
        result[1] detonate();
    }

    self.mines[BOUNCINGBETTY][self.mines[BOUNCINGBETTY].size] = item;

    item.owner = self;
    item.team = self.team;
    item.activated = true;
    item.weaponname = weaponName;

    item thread mineDamage();
    item thread c4empdamage();
    item thread c4empkillstreakwait();
    item thread bouncingbettyWatchStuck(self);
}

bouncingbettyWatchStuck(owner)
{
    self waittill("missile_stuck");

    self.origin -= (0, 0, 2);
    self thread mineBeacon();
    self thread bouncingbettyWatchProximity();

    trigger = trigger_create(self.origin + (0, 0, 25), 70);
    trigger trigger_set_use("Press ^3[{+activate}] ^7to pick up Bouncing Betty");
    trigger trigger_set_enable_condition(::minePickupCondition);
    trigger.owner = owner;
    self.trigger = trigger;

    if (owner.team == "allies") self thread setClaymoreTeamHeadIcon(owner.team);
    self mineWatchPickup(owner, trigger);
}

bouncingbettyWatchProximity()
{
    self endon("mine_destroyed");
    self endon("mine_selfdestruct");
    self endon("death");

    self.damageArea = trigger_create(self.origin, level.minedetectionradius);

    for (;;)
    {
        self.damageArea waittill("trigger_radius", player);

        if (isDefined(self.owner) && player == self.owner) continue;
        if (!friendlyFireCheck(self.owner, player, 0)) continue;
        if (lengthSquared(player getEntityVelocity()) > 10) break;
    }

    self notify("mine_triggered");
    self playSound("mine_betty_click");

    if (isPlayer(player) && player maps\mp\_utility::_hasPerk("specialty_delaymine"))
    {
        player notify("triggered_mine");
        wait(level.delayminetime);
    }
    else wait(level.minedetectiongraceperiod);

    self playSound("mine_betty_spin");
    playFx(level.mine_launch, self.origin);

    mine = spawn("script_model", self.origin);
    mine.angles = self.angles;
    mine setModel("projectile_bouncing_betty_grenade");
    self hide();

    explodePos = self.origin + (0, 0, 64);
    mine moveTo(explodePos, 0.7, 0, 0.65);
    mine rotateVelocity((0, 750, 32), 0.7, 0, 0.65);
    mine thread playSpinnerFX();

    wait 0.65;
    mine playsound("grenade_explode_metal");
    fx = mine gettagorigin("tag_fx");
    playfx(level.mine_explode, fx);

    self.owner radiusdamage(mine.origin, level.minedamageradius, level.minedamagemax, level.minedamagemin, self.owner, "MOD_EXPLOSIVE", "bouncingbetty_mp");
    wait 0.05;

    if (isdefined(self.trigger))
    {
        if (isdefined(self.damageArea)) self.damageArea trigger_delete();
        self.trigger trigger_delete();
        self.bombSquad delete();
        self.owner.mines[self.weaponname] = array_remove(self.owner.mines[self.weaponname], self);
    }

    mine delete();
    self delete();
}

throwingKnifeWatch(item, weaponName)
{
    if (!isDefined(self.mines[weaponName])) self.mines[weaponName] = [];
    
    if (self.mines[weaponName].size >= 4)
    {
        oldest = self.mines[weaponName][0];
        self.mines[weaponName] = array_remove_index(self.mines[weaponName], 0);
        if (isDefined(oldest))
        {
            if (isDefined(oldest.trigger)) oldest.trigger trigger_delete();
            oldest delete();
        }
    }

    self.mines[weaponName][self.mines[weaponName].size] = item;

    item.owner = self;
    item.team = self.team;
    item.weaponname = weaponName;
    item thread throwingKnifeWatchStuck(self, weaponName);
}

throwingKnifeWatchStuck(owner, weaponName)
{
    owner endon("spawned_player");
    owner endon("disconnect");
    self endon("death");

    self waittill("missile_stuck");
    
    trigger = trigger_create(self.origin, 90);
    trigger trigger_set_use("Press ^3[{+activate}] ^7to pick up ThrowingKnife");
    trigger trigger_set_enable_condition(::minePickupCondition);
    trigger.owner = owner;
    trigger.tag = "throwingKnife";
    self.trigger = trigger;

    if (owner.team == "allies") self thread setClaymoreTeamHeadIcon(owner.team);
    self mineWatchPickup(owner, trigger);
}

minePickupCondition(player)
{
    return player == self.owner && isAlive(player) && !player.inLastStand && !player.disabledusability;
}

mineDamage()
{
    self endon("mine_triggered");
    self endon("death");
    self setcandamage(1);
    self.maxhealth = 100000;
    self.health = self.maxhealth;
    attacker = undefined;

    for (;;)
    {
        self waittill("damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags, weapon);
        if (!isplayer(attacker)) continue;
        if (!friendlyFireCheck(self.owner, attacker)) continue;
        if (isdefined(weapon))
        {
            switch (weapon)
            {
                case "concussion_grenade_mp":
                case "flash_grenade_mp":
                case "smoke_grenade_mp":
                    continue;
            }
        }
        break;
    }

    if (level.c4explodethisframe) wait(0.1 + randomfloat(0.4));
    else wait 0.05;

    if (!isdefined(self)) return;

    level.c4explodethisframe = 1;
    thread resetC4ExplodeThisFrame();

    if (isdefined(type) && (issubstr(type, "MOD_GRENADE") || issubstr(type, "MOD_EXPLOSIVE")))
        self.waschained = 1;

    if (isdefined(iDFlags) && iDFlags & level.idflags_penetration)
        self.wasdamagedfrombulletpenetration = 1;

    self.wasdamaged = 1;

    if (isplayer(attacker)) attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback("c4");

    if (level.teambased)
    {
        if (isdefined(attacker) && isdefined(attacker.pers["team"]) && isdefined(self.owner) && isdefined(self.owner.pers["team"]))
        {
            if (attacker.pers["team"] != self.owner.pers["team"])
                attacker notify("destroyed_explosive");
        }
    }
    else if (isdefined(self.owner) && isdefined(attacker) && attacker != self.owner)
        attacker notify("destroyed_explosive");

    if (isdefined(self.trigger))
    {
        if (isdefined(self.damageArea)) self.damageArea trigger_delete();
        self.trigger trigger_delete();
        if (isDefined(self.bombSquad)) self.bombSquad delete();
        
        if (isDefined(self.owner) && isDefined(self.owner.mines[self.weaponname]))
            self.owner.mines[self.weaponname] = array_remove(self.owner.mines[self.weaponname], self);
    }

    self detonate(attacker);
}

mineDeleteOnDisconnect()
{
    self endon("death");

    self lethalbeats\utility::waittill_any("disconnect", "joined_team", "joined_spectators");

    mines = array_get_values(self.mines);
    wait 0.05;

    foreach(mine in mines)
    {
        if (isdefined(mine.trigger)) mine.trigger trigger_delete();
        mine delete();
    }
}

mineWatchPickup(owner, trigger)
{
    level endon("game_ended");
	owner endon("disconnect");

    self notify("mine_ready");

    for (;;)
    {
        trigger waittill("trigger_use", owner);

        owner playLocalSound("scavenger_pack_pickup");
		if(owner isTestClient()) owner SetWeaponAmmoStock(self.weaponname, owner GetWeaponAmmoStock(self.weaponname) + 1);
		else if (isDefined(owner.grenades[self.weaponname]))
		{
			owner lethalbeats\survival\utility::player_add_nades(self.weaponname, 1);
			if (self.weaponname == CLAYMORE) owner maps\mp\_utility::_setActionSlot(1, "weapon", self.weaponname);
            else if (self.weaponname == C4) owner maps\mp\_utility::_setActionSlot(5, "weapon", self.weaponname);
		}

        trigger trigger_delete();
        if (isDefined(owner.mines[self.weaponname]))
            owner.mines[self.weaponname] = array_remove(owner.mines[self.weaponname], self);

        self delete();
        self notify("death");
    }
}

mineCreateBombSquadModel(model, owner)
{
    level endon("game_ended");
	self endon("death");

    self waittill("mine_ready");
    bombSquadModel = spawn("script_model", self.origin);
    bombSquadModel hide();
    wait 0.05;

    bombSquadModel setmodel(model);
    bombSquadModel linkTo(self);
    bombSquadModel setContents(0);

    self.bombSquad = bombSquadModel;
    level notify("update_bombsquad");
    self waittill("death");

    if (isdefined(self.trigger))
    {
        if (isdefined(self.damageArea)) self.damageArea trigger_delete();
        self.trigger trigger_delete();
        if (isDefined(self.bombSquad)) self.bombSquad delete();
        
        if (isDefined(owner) && isDefined(owner.mines[self.weaponname]))
            owner.mines[self.weaponname] = array_remove(owner.mines[self.weaponname], self);
    }
}

mineBombSquadVisibilityUpdater()
{
    level endon("game_ended");

    for(;;)
    {
        level lethalbeats\utility::waittill_any("joined_team", "player_spawned", "changed_kit", "update_bombsquad");
        
        mines = [];
		foreach(player in level.players)
            if (isDefined(player.mines))
                mines = array_combine(mines, array_get_values(player.mines));

        foreach(mine in mines)
        {
            foreach(player in level.players)
                if (player.team != mine.team && player maps\mp\_utility::_hasPerk("specialty_detectexplosive"))
                    mine.bombSquad showToPlayer(player);
        }
    }
}

init()
{
	level._effect["laserTarget"] = loadfx("misc/laser_glow");
	level._effect["martyrdom_c4_explosion"] = loadfx("explosions/grenadeExp_metal");
	level.martyrdom_c4_pool = [];
	level.martyrdom_fx_pool = [];
}

martyrdom_fx_pool_get(pos, forward, right)
{
	fxEnt = undefined;
	if (isDefined(level.martyrdom_fx_pool))
	{
		foreach(item in level.martyrdom_fx_pool)
		{
			if (isDefined(item) && !item.inUse)
			{
				fxEnt = item;
				break;
			}
		}
	}

	if (!isDefined(fxEnt))
	{
		fxEnt = spawnFx(level._effect["laserTarget"], pos, forward, right);
		fxEnt.isPooled = true;
		if (!isDefined(level.martyrdom_fx_pool))
			level.martyrdom_fx_pool = [];
		level.martyrdom_fx_pool[level.martyrdom_fx_pool.size] = fxEnt;
	}
	else
	{
		fxEnt.origin = pos;
		if (isDefined(forward))
			fxEnt.angles = vectorToAngles(forward);
	}

	fxEnt.inUse = true;
	fxEnt show();
	triggerFx(fxEnt);
	return fxEnt;
}

martyrdom_fx_pool_release(fxEnt)
{
	if (!isDefined(fxEnt)) return;

	fxEnt.inUse = false;
	fxEnt hide();
	fxEnt.origin = (0, 0, -10000);
}

martyrdom_c4_pool_get(body, tag, origin_offset, angles_offset)
{
	c4 = undefined;
	if (isDefined(level.martyrdom_c4_pool))
	{
		foreach(item in level.martyrdom_c4_pool)
		{
			if (isDefined(item) && !item.inUse)
			{
				c4 = item;
				break;
			}
		}
	}

	if (!isDefined(c4))
	{
		c4 = spawn("script_model", (0, 0, -10000));
		c4 setModel("weapon_c4");
		c4 setCanDamage(false);
		c4 notSolid();
		c4 setcontents(0);
		c4.isPooled = true;

		bombSquadModel = spawn("script_model", (0, 0, -10000));
		bombSquadModel hide();
		bombSquadModel setModel("weapon_c4_bombsquad");
		bombSquadModel setcontents(0);
		bombSquadModel linkTo(c4);
		c4.bombsquadmodel = bombSquadModel;

		if (!isDefined(level.martyrdom_c4_pool))
			level.martyrdom_c4_pool = [];
		level.martyrdom_c4_pool[level.martyrdom_c4_pool.size] = c4;
	}

	c4.inUse = true;
	c4.origin = body getTagOrigin(tag) + origin_offset;
	c4.angles = body.angles;
	c4 linkTo(body, tag, origin_offset, angles_offset);
	c4 show();

	owner = isDefined(body.owner) ? body.owner : body;
	if (isDefined(c4.bombsquadmodel) && isDefined(owner) && !owner lethalbeats\survival\utility::player_is_survivor())
	{
		c4.bombsquadmodel.origin = c4.origin;
		c4.bombsquadmodel linkTo(c4);
		c4.bombsquadmodel notify("restart_bombsquad");
		c4.bombsquadmodel thread _c4_bombsquad_monitor("allies", owner);
	}

	return c4;
}

martyrdom_c4_pool_release(c4)
{
	if (!isDefined(c4)) return;

	c4 notify("c4_recycled");
	c4 unlink();
	c4 hide();
	c4.origin = (0, 0, -10000);
	c4.inUse = false;

	if (isDefined(c4.bombsquadmodel))
	{
		c4.bombsquadmodel notify("stop_bombsquad");
		c4.bombsquadmodel unlink();
		c4.bombsquadmodel hide();
		c4.bombsquadmodel.origin = (0, 0, -10000);
		c4.bombsquadmodel linkTo(c4);
	}
}

_c4_bombsquad_monitor(teamName, owner)
{
	self endon("death");
	self endon("stop_bombsquad");
	self endon("restart_bombsquad");

	for (;;)
	{
		self hide();
		foreach(player in level.players)
		{
			if (level.teambased)
			{
				if (player.team == teamName && player maps\mp\_utility::_hasperk("specialty_detectexplosive"))
					self showToPlayer(player);
			}
			else if (player != owner && player maps\mp\_utility::_hasperk("specialty_detectexplosive"))
				self showToPlayer(player);
		}
		level common_scripts\utility::waittill_any("joined_team", "player_spawned", "changed_kit", "update_bombsquad");
	}
}

giveAbility()
{
	c4_attach = [];

	isDog = self lethalbeats\survival\utility::bot_is_dog();
	
	if (isPlayer(self) && isDog) return;
	else if (isDog)
	{
		c4_attach[0] = attachC4(self, "j_hip_base_ri", (6, 6, -3), (0, 0, 0));
		c4_attach[1] = attachC4(self, "j_hip_base_le", (-6, -6, 3), (0, 0, 0));
	}
	else
	{
		c4_attach[0] = attachC4(self, "j_spine4", (0, 6, 0), (0, 0, -90));
		c4_attach[1] = attachC4(self, "tag_stowed_back", (0, 1, 5), (80, 90, 0));
	}

	self thread playc4Fx(c4_attach);
	self thread watchMartyrdomDetonation(c4_attach);
	self thread watchMartyrdomCleanup(c4_attach);
}

attachC4(body, tag, origin_offset, angles_offset)
{
	return martyrdom_c4_pool_get(body, tag, origin_offset, angles_offset);
}

playc4Fx(c4_attach)
{
	level endon("game_ended");
	self endon("death");
	self endon("dog_death");
	self endon("dog_recycled");

	foreach(c4 in c4_attach)
	{
		wait 0.15;
		playFXOnTag(level.mine_beacon["enemy"], c4, "tag_origin");
	}
}

watchMartyrdomCleanup(c4_attach)
{
	self endon("martyrdom_detonated");
	self lethalbeats\utility::waittill_any_return("disconnect", "death", "dog_death", "dog_recycled");

	wait 3.0;
	foreach(c4 in c4_attach)
		if (isDefined(c4) && isDefined(c4.inUse) && c4.inUse)
			martyrdom_c4_pool_release(c4);

	if (isDefined(self.detonateFx))
	{
		foreach(fx in self.detonateFx)
			if (isDefined(fx) && isDefined(fx.inUse) && fx.inUse)
				martyrdom_fx_pool_release(fx);
	}
}

watchMartyrdomDetonation(c4_attach)
{
	self waittill("detonate", attacker);
	
	self.detonate = 1;

	c4_attach[0] playSound("semtex_warning");
	
	traceStart = c4_attach[0].origin + (0, 0, 32);
	traceEnd = c4_attach[0].origin - (0, 0, 32);
	trace = bulletTrace(traceStart, traceEnd, false, undefined);
	
	upangles = vectorToAngles(trace["normal"]);
	forward = anglesToForward(upangles);
	right = anglesToRight(upangles);
	
	self.detonateFx = [];

	wait 0.25;
	fxEnt = martyrdom_fx_pool_get(getGroundPosition(c4_attach[0].origin, 12, 0, 32), forward, right);
	self.detonateFx[0] = fxEnt;

	wait 0.25;
	fxEnt2 = martyrdom_fx_pool_get(getGroundPosition(c4_attach[0].origin, 12, 0, 32), forward, right);
	self.detonateFx[1] = fxEnt2;
	
	wait 1.5;
	for (i = 0; i < c4_attach.size; i++)
	{
		if (!isDefined(c4_attach[i])) continue;

		playfx(level._effect["martyrdom_c4_explosion"], c4_attach[i].origin);
		playSoundAtPos(c4_attach[i].origin, "detpack_explo_main");
		earthquake(0.4, 0.8, c4_attach[i].origin, 600);
		
		c4_attach[i] radiusdamage(c4_attach[i].origin, 192, 100, 50, isDefined(attacker) ? attacker : self, "MOD_EXPLOSIVE", "c4_mp");
		martyrdom_c4_pool_release(c4_attach[i]);
		wait 0.5;
	}
	
	wait 1.5;
	martyrdom_fx_pool_release(fxEnt);
	martyrdom_fx_pool_release(fxEnt2);
	self.detonateFx = undefined;
	self.detonate = undefined;
	self notify("martyrdom_detonated");
}

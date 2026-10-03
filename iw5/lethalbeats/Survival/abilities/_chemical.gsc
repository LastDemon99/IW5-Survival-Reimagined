init()
{
	precacheShellShock("radiation_low");
	precacheModel("gas_canisters_backpack");
	precacheModel("gas_backpack_bombsquad");
	precacheModel("ims_scorpion_explosive1");
	precacheModel("ims_explosive_bombsquad");

	level._effect["chemical_tank_explosion"] = loadfx("smoke/so_chemical_explode_smoke");
	level._effect["chemical_tank_smoke"] = loadfx("smoke/so_chemical_stream_smoke");
	level._effect["chemical_mine_spew"] = loadfx("smoke/so_chemical_mine_spew");

	level.chemical_tank_pool = [];
	level.chemical_mine_pool = [];
	level.chemical_fx_pool = [];
}

chemical_fx_pool_get(pos)
{
	fxEnt = undefined;
	if (isDefined(level.chemical_fx_pool))
	{
		foreach(item in level.chemical_fx_pool)
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
		fxEnt = spawnFx(level._effect["chemical_mine_spew"], pos);
		fxEnt.isPooled = true;
		if (!isDefined(level.chemical_fx_pool))
			level.chemical_fx_pool = [];
		level.chemical_fx_pool[level.chemical_fx_pool.size] = fxEnt;
	}
	else
	{
		fxEnt.origin = pos;
	}

	fxEnt.inUse = true;
	fxEnt show();
	triggerFx(fxEnt);
	return fxEnt;
}

chemical_fx_pool_release(fxEnt)
{
	if (!isDefined(fxEnt)) return;

	fxEnt.inUse = false;
	fxEnt hide();
	fxEnt.origin = (0, 0, -10000);
}

chemical_tank_pool_get(owner)
{
	tank = undefined;
	if (isDefined(level.chemical_tank_pool))
	{
		foreach(item in level.chemical_tank_pool)
		{
			if (isDefined(item) && !item.inUse)
			{
				tank = item;
				break;
			}
		}
	}

	if (!isDefined(tank))
	{
		tank = spawn("script_model", (0, 0, -10000));
		tank setModel("gas_canisters_backpack");
		tank setCanDamage(false);
		tank notSolid();
		tank setContents(0);
		tank.isChemicalTank = true;
		tank.isPooled = true;

		bombSquadModel = spawn("script_model", (0, 0, -10000));
		bombSquadModel hide();
		bombSquadModel setModel("gas_backpack_bombsquad");
		bombSquadModel setContents(0);
		bombSquadModel linkTo(tank);
		tank.bombsquadmodel = bombSquadModel;

		if (!isDefined(level.chemical_tank_pool))
			level.chemical_tank_pool = [];
		level.chemical_tank_pool[level.chemical_tank_pool.size] = tank;
	}

	tank.inUse = true;
	tagOrigin = owner getTagOrigin("tag_shield_back");
	tank.origin = isDefined(tagOrigin) ? tagOrigin : owner.origin;
	tank.angles = owner.angles;
	tank linkTo(owner, "tag_shield_back", (0, 0, 0), (0, 0, 0));
	tank show();

	if (isDefined(tank.bombsquadmodel) && isDefined(owner) && !owner lethalbeats\survival\utility::player_is_survivor())
	{
		tank.bombsquadmodel.origin = tank.origin;
		tank.bombsquadmodel linkTo(tank);
		tank.bombsquadmodel notify("restart_bombsquad");
		tank.bombsquadmodel thread _chemical_bombsquad_monitor("allies", owner);
	}

	return tank;
}

chemical_tank_pool_release(tank)
{
	if (!isDefined(tank)) return;

	tank notify("tank_recycled");
	tank unlink();
	tank hide();
	tank.origin = (0, 0, -10000);
	tank.inUse = false;

	if (isDefined(tank.bombsquadmodel))
	{
		tank.bombsquadmodel notify("stop_bombsquad");
		tank.bombsquadmodel unlink();
		tank.bombsquadmodel hide();
		tank.bombsquadmodel.origin = (0, 0, -10000);
		tank.bombsquadmodel linkTo(tank);
	}
}

chemical_mine_pool_get(pos, angles, owner)
{
	mine = undefined;
	if (isDefined(level.chemical_mine_pool))
	{
		foreach(item in level.chemical_mine_pool)
		{
			if (isDefined(item) && !item.inUse)
			{
				mine = item;
				break;
			}
		}
	}

	if (!isDefined(mine))
	{
		mine = spawn("script_model", (0, 0, -10000));
		mine setModel("ims_scorpion_explosive1");
		mine setCanDamage(false);
		mine notSolid();
		mine setContents(0);
		mine.isChemicalMine = true;
		mine.isPooled = true;

		bombSquadModel = spawn("script_model", (0, 0, -10000));
		bombSquadModel hide();
		bombSquadModel setModel("ims_explosive_bombsquad");
		bombSquadModel setContents(0);
		bombSquadModel linkTo(mine);
		mine.bombsquadmodel = bombSquadModel;

		if (!isDefined(level.chemical_mine_pool))
			level.chemical_mine_pool = [];
		level.chemical_mine_pool[level.chemical_mine_pool.size] = mine;
	}

	mine.inUse = true;
	mine.origin = pos;
	if (isDefined(angles))
		mine.angles = angles;
	mine show();

	if (isDefined(mine.bombsquadmodel) && isDefined(owner) && !owner lethalbeats\survival\utility::player_is_survivor())
	{
		mine.bombsquadmodel.origin = mine.origin;
		mine.bombsquadmodel linkTo(mine);
		mine.bombsquadmodel notify("restart_bombsquad");
		mine.bombsquadmodel thread _chemical_bombsquad_monitor("allies", owner);
	}

	return mine;
}

chemical_mine_pool_release(mine)
{
	if (!isDefined(mine)) return;

	mine notify("mine_recycled");
	mine unlink();
	mine hide();
	mine.origin = (0, 0, -10000);
	mine.inUse = false;

	if (isDefined(mine.bombsquadmodel))
	{
		mine.bombsquadmodel notify("stop_bombsquad");
		mine.bombsquadmodel unlink();
		mine.bombsquadmodel hide();
		mine.bombsquadmodel.origin = (0, 0, -10000);
		mine.bombsquadmodel linkTo(mine);
	}
}

_chemical_bombsquad_monitor(teamName, owner)
{
	self endon("death");
	self endon("stop_bombsquad");
	self endon("restart_bombsquad");

	for(;;)
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
	tank = chemical_tank_pool_get(self);
	self thread detonateMonitor(tank);
	self thread watchChemicalCleanup(tank);
	self thread smokeFx();

	if (lethalbeats\survival\utility::player_has_nades("claymore_mp"))
		self thread mineMonitor();
}

smokeFx()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	self endon("detonate");
	self endon("chemical_detonated");

	for(;;)
	{
		wait 0.1;
		playFXOnTag(level._effect["chemical_tank_smoke"], self, "tag_shield_back");
	}
}

watchChemicalCleanup(tank)
{
	self endon("chemical_detonated");
	self lethalbeats\utility::waittill_any_return("disconnect", "death");

	wait 3.0;
	if (isDefined(tank) && isDefined(tank.inUse) && tank.inUse)
		chemical_tank_pool_release(tank);
}

detonateMonitor(tank)
{
	level endon("game_ended");
	self waittill("detonate", attacker);
	self notify("chemical_detonated");
	origin = self.origin;
	level thread detonation(tank, origin, attacker);
}

detonation(object, origin, attacker)
{
	if (isDefined(object))
	{
		playsoundatpos(origin, "detpack_explo_main");
		object unlink();
	}
	earthquake(0.2, 0.4, origin, 600);
	playfx(level._effect["chemical_tank_explosion"], origin);
	wait 0.05;
	if (isDefined(object))
	{
		if (isDefined(object.isChemicalTank) && object.isChemicalTank)
			chemical_tank_pool_release(object);
		else if (isDefined(object.isChemicalMine) && object.isChemicalMine)
			chemical_mine_pool_release(object);
		else
			object delete();
	}

	if (!isDefined(attacker))
		attacker = isDefined(self) && isPlayer(self) ? self : undefined;

	for(i = 0; i < 10; i++)
	{
		foreach(player in lethalbeats\survival\utility::survivors(true))
		{
			if (lethalbeats\collider::pointInSphere(player.origin, origin, 70))
			{
				player shellshock("radiation_low", 0.45);
				player viewKick(3, origin);
			}
		}
		radiusdamage(origin, 70, 200, 20, attacker, "MOD_TRIGGER_HURT");
		wait 0.5;
	}
}

mineMonitor()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	
	for(;;)
	{
		self waittill("claymore_stuck", claymore);

		claymore hide();

		mine = chemical_mine_pool_get(claymore.origin + (0, 0, 3), claymore.angles, self);
		fxEnt = chemical_fx_pool_get(mine.origin);
		
		level thread mineDeathMonitor(claymore, mine, fxEnt, self);
	}
}

mineDeathMonitor(claymore, mine, fxEnt, owner)
{
	level endon("game_ended");
	claymore waittill("death");

	if (isDefined(fxEnt))
		chemical_fx_pool_release(fxEnt);

	if (isDefined(mine))
	{
		origin = mine.origin;
		attacker = isDefined(owner) && isPlayer(owner) ? owner : undefined;
		level thread detonation(mine, origin, attacker);
	}
}

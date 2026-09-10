init()
{
	precacheShellShock("radiation_low");
	precacheModel("ims_scorpion_explosive1");
	
	level._effect["chemical_tank_explosion"] = loadfx("smoke/so_chemical_explode_smoke");
	level._effect["chemical_tank_smoke"] = loadfx("smoke/so_chemical_stream_smoke");
	level._effect["chemical_mine_spew"] = loadfx("smoke/so_chemical_mine_spew");
}

giveAbility()
{
	tank = spawn("script_model", self gettagorigin("tag_shield_back"));
	tank setmodel("gas_canisters_backpack");
	tank linkto(self, "tag_shield_back", (0,0,0), (0,0,0));
	tank setCanDamage(false);
	tank notSolid();
	tank thread lethalbeats\survival\patch\mines::mineCreateBombSquadModel("gas_backpack_bombsquad", self);
	self thread detonateMonitor(tank);
	self thread smokeFx();

	if (lethalbeats\survival\utility::player_has_nades("claymore_mp"))
		self thread mineMonitor();
}

smokeFx()
{
	level endon("game_ended");
	self endon("detonate");

	for(;;)
	{
		wait 0.1;
		playFXOnTag(level._effect["chemical_tank_smoke"], self, "tag_shield_back");
	}
}

detonateMonitor(tank)
{
	level endon("game_ended");
	self waittill("detonate");
	self detonation(tank, self.origin);
}

detonation(tank, origin)
{
	if (isDefined(tank))
	{
		tank playsound("detpack_explo_main");
		tank unlink();
	}
	earthquake(0.2, 0.4, origin, 600);
	playfx(level._effect["chemical_tank_explosion"], origin);
	wait 0.05;
	if (isDefined(tank)) tank delete();

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
	self endon("death");
	
	for(;;)
	{
		self waittill("claymore_stuck", claymore);

		claymore hide();

		mine = spawn("script_model", claymore.origin + (0, 0, 3));
		mine setModel("ims_scorpion_explosive1");
		mine setCanDamage(false);
		mine notSolid();
		mine setContents(0);
		mine thread lethalbeats\survival\patch\mines::mineCreateBombSquadModel("ims_explosive_bombsquad", self);

		fxEnt = SpawnFx(level._effect["chemical_mine_spew"], mine.origin);
		triggerFx(fxEnt);
		
		self thread mineDeathMonitor(claymore, mine, fxEnt);
	}
}

mineDeathMonitor(claymore, mine, fxEnt)
{
	claymore waittill("death");
	if (isDefined(fxEnt)) fxEnt delete();
	if (isDefined(mine) && isDefined(mine.origin)) self detonation(mine, mine.origin);
}

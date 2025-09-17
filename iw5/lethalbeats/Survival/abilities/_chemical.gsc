init()
{
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
	self thread detonateMonitor(tank);
	self thread smokeFx();
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

	explode_origin = self.origin;
	tank playsound("detpack_explo_main");
	earthquake(0.2, 0.4, explode_origin, 600);
	playfx(level._effect["chemical_tank_explosion"], explode_origin);
	tank unlink();
	wait 0.05;
	tank delete();

	for(i = 0; i < 10; i++)
	{
		foreach(player in level.players)
			if (lethalbeats\collider::pointInSphere(player.origin, explode_origin, 70))
			{
				player shellshock("radiation_low", 0.45);
				player viewKick(3, self.origin);
			}

		radiusdamage(explode_origin, 70, 200, 20, self, "MOD_TRIGGER_HURT");
        wait 0.5;
	}
}

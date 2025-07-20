init()
{
	level._effect["chemical_tank_explosion"] = loadfx("smoke/so_chemical_explode_smoke");
	level._effect["chemical_tank_smoke"] = loadfx("smoke/so_chemical_stream_smoke");
	level._effect["chemical_mine_spew"] = loadfx("smoke/so_chemical_mine_spew");
}

giveAbility()
{
	//tank = spawn("script_model", self gettagorigin("tag_shield_back"));
	//tank setmodel("gas_canisters_backpack");
	//tank linkto(self, "tag_shield_back", (0,0,0), (0,0,0));
	self thread detonateMonitor();
	self thread smokeFx();
}

smokeFx()
{
	level endon("game_ended");
	self endon("death");

	for(;;)
	{
		wait 0.1;
		playFXOnTag(level._effect["chemical_tank_smoke"], self, "tag_shield_back");
	}
}

detonateMonitor(tank)
{
	level endon("game_ended");
	self waittill("detonate", attacker);

	explode_origin = self.origin;
	//tank playsound("detpack_explo_main");
	earthquake(0.2, 0.4, explode_origin, 600);
	playfx(level._effect["chemical_tank_explosion"], explode_origin);
	//tank unlink();
	wait 0.05;
	//tank delete();
	
	trigger = spawn("trigger_radius", explode_origin, 0, 70, 70 * 2);	
	for(i = 0; i < 10; i++)
	{
		foreach(player in level.players) 
			if (player isTouching(trigger))
			{
				player shellshock("radiation_low", 0.45);
				player viewKick(3, self.origin);
			}
			
		radiusdamage(trigger.origin, 70, 10, 5, self, "MOD_EXPLOSIVE");
		wait 0.5;
	}

	trigger delete();
}

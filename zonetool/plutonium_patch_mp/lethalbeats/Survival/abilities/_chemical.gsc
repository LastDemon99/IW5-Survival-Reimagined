init()
{
	level._effect["chemical_tank_explosion"] = loadfx("smoke/so_chemical_explode_smoke");
	level._effect["chemical_tank_smoke"] = loadfx("smoke/so_chemical_stream_smoke");
	level._effect["chemical_mine_spew"] = loadfx("smoke/so_chemical_mine_spew");
}

giveAbility()
{
	self thread attachChemicalTank();
	self thread chemicalDetonate();
}

attachChemicalTank()
{
	level endon("game_ended");
	self endon("death");
	
	tank = spawn("script_model", self gettagorigin("tag_shield_back"));
	tank setmodel("gas_canisters_backpack");
    tank.health = 99999;
	tank setcandamage(true);
	tank linkto(self, "tag_shield_back", (0,0,0), (0,0,0));
	self.tankAttach = tank;
	self.chemical = 1;
	
	for(;;)
	{
		wait 0.05;
		playFXOnTag(level._effect["chemical_tank_smoke"], self, "tag_shield_back");
	}
}

chemicalDetonate()
{	
	self waittill("detonate");
	self notify("tank_detonated");
	explode_origin = self.origin;
	self.tankAttach playsound("detpack_explo_main");
	earthquake(0.2, 0.4, explode_origin, 600);
	playfx(level._effect["chemical_tank_explosion"], explode_origin);
	self.tankAttach unlink();
	wait 0.05;
	self.tankAttach delete();
	
	trigger = spawn("trigger_radius", explode_origin, 0, 70, 70 * 2);
	self thread onGasHandle(trigger);
	
	wait(7);
	self notify("gas_done");
}

onGasHandle(trigger)
{
	level endon("game_ended");	
	self endon("gas_done");
	
	for(;;)
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
}

init()
{
	level._effect["laserTarget"] = loadfx( "misc/laser_glow" );
	level._effect["martyrdom_c4_explosion"] = loadfx("explosions/grenadeExp_metal");
}

giveAbility()
{
	c4_attach = [];
	if (isDefined(self.dog))
	{
		c4_attach[0] = attachC4(c4_attach, self.dog, "j_hip_base_ri", (6,6,-3), (0,0,0));
		c4_attach[1] = attachC4(c4_attach, self.dog, "j_hip_base_le", (-6,-6,3), (0,0,0));
	}
	else
	{
		c4_attach[0] = attachC4(c4_attach, self, "j_spine4", (0,6,0), (0,0,-90));
		c4_attach[1] = attachC4(c4_attach, self, "tag_stowed_back", (0,1,5), (80,90,0));
	}
	thread playc4Fx(c4_attach);
	self thread watchMartyrdomDetonation(c4_attach);
}

attachC4(c4_attach, body, tag, origin_offset, angles_offset)
{
	c4_model = spawn("script_model", body gettagorigin(tag) + origin_offset);
	c4_model setmodel("weapon_c4");
	c4_model linkto(body, tag, origin_offset, angles_offset);
	return c4_model;
}

playc4Fx(c4_attach)
{
	foreach(c4 in c4_attach)
	{
		wait 0.15;
		playFXOnTag(level.mine_beacon["enemy"], c4, "tag_origin");
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
	
	wait 0.25;
	fxEnt = SpawnFx(level._effect["laserTarget"], getGroundPosition(c4_attach[0].origin, 12, 0, 32), forward, right);
	triggerFx(fxEnt);
	wait 0.25;
	fxEnt2 = SpawnFx(level._effect["laserTarget"], getGroundPosition(c4_attach[0].origin, 12, 0, 32), forward, right);
	triggerFx(fxEnt2);
	
	wait 1.5;
	for (i = 0; i < c4_attach.size; i++)
	{
		if (!isDefined(c4_attach[i])) continue;

		playfx(level._effect["martyrdom_c4_explosion"], c4_attach[i].origin);
		playSoundAtPos(c4_attach[i].origin, "detpack_explo_main");
		earthquake(0.4, 0.8, c4_attach[i].origin, 600);
		
		c4_attach[i] radiusdamage(c4_attach[i].origin, 192, 100, 50, attacker, "MOD_EXPLOSIVE");
		c4_attach[i] unlink();
		c4_attach[i] delete();
		wait 0.5;
	}
	
	wait 1.5;
	fxEnt delete();
	fxEnt2 delete();
	self.detonate = undefined;
}

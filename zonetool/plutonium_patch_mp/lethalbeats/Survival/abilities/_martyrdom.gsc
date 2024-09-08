init()
{
	level._effect["martyrdom_c4_explosion"] = loadfx("explosions/grenadeExp_metal");
}

giveAbility()
{
	self thread attachC4("j_spine4", (0,6,0), (0,0,-90));
	self thread attachC4("tag_stowed_back", (0,1,5), (80,90,0));
	self thread martyrdomDetonate();
}

attachC4(tag, origin_offset, angles_offset, isDog)
{
	c4_model = spawn("script_model", self gettagorigin(tag) + origin_offset);
	c4_model setmodel("weapon_c4");
	c4_model linkto(self, tag, origin_offset, angles_offset);
	
	wait 0.15;
	playFXOnTag(level.mine_beacon["enemy"], c4_model, "tag_origin");
	
	if (!isdefined(self.c4_attachments)) self.c4_attachments = [];
	self.c4_attachments[self.c4_attachments.size] = c4_model;
}

martyrdomDetonate()
{
	self waittill("detonate");
	
	c4_array = self.c4_attachments;		
	c4_array[0] playSound("semtex_warning");
	
	traceStart = c4_array[0].origin + (0,0,32);
	traceEnd = c4_array[0].origin + (0,0,-32);
	trace = bulletTrace(traceStart, traceEnd, false, undefined);
	
	upangles = vectorToAngles(trace["normal"]);
	forward = anglesToForward(upangles);
	right = anglesToRight(upangles);
	
	wait 0.25;
	fxEnt = SpawnFx(level._effect["laserTarget"], getGroundPosition(c4_array[0].origin, 12, 0, 32), forward, right);
	triggerFx(fxEnt);
	wait 0.25;
	fxEnt2 = SpawnFx(level._effect["laserTarget"], getGroundPosition(c4_array[0].origin, 12, 0, 32), forward, right);
	triggerFx(fxEnt2);
	
	wait 1.5;
	for (i = 0; i < c4_array.size; i++)
	{
		
		playfx(level._effect["martyrdom_c4_explosion"], c4_array[i].origin);
		playSoundAtPos(c4_array[i].origin, "detpack_explo_main");
		earthquake(0.4, 0.8, c4_array[i].origin, 600);
		
		c4_array[i] radiusdamage(c4_array[i].origin, 192, 100, 50, undefined, "MOD_EXPLOSIVE");
		c4_array[i] unlink();
		c4_array[i] delete();		
		wait 0.5;
	}
	
	self.c4_attachments = [];
	
	wait 1.5;
	fxEnt delete();
	fxEnt2 delete();
}

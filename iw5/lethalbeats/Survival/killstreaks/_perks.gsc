#include lethalbeats\survival\utility;
#include lethalbeats\player;

#define CUSTOM_PERKS ["specialty_scavenger", "specialty_blindeye"]

perks_is_custom(perk)
{
	return lethalbeats\array::array_contains(CUSTOM_PERKS, perk);
}

perks_give(perk)
{
	if (perk == "specialty_blindeye") 
	{
		self player_give_perk("specialty_armorpiercing");
		self player_give_perk("specialty_fasterlockon");
	}
	self.perks[perk] = true;
}

scavenger_drop()
{
    ground = playerPhysicsTrace(self.origin, self.origin - (0, 0, 1024), false, self.body);
    if (!isDefined(ground)) ground = self.origin;

    dropAngles = (0, self.angles[1], 0);
    normalTrace = bullettrace(self.origin + (0, 0, 20), ground - (0, 0, 32), false, self);
    if (isDefined(normalTrace) && isDefined(normalTrace["normal"]))
        dropAngles = lethalbeats\vector::vector_angles_orient_to_normal(normalTrace["normal"], self.angles[1]) + (0, 0, 90);

    weaponModel = lethalbeats\utility::spawn_model(ground + (0, 0, 0.5), "weapon_scavenger_grenadebag");
    weaponModel.angles = dropAngles;
	weaponModel thread _scavengerBagVisibilityUpdater();

	trigger = lethalbeats\trigger::trigger_create(weaponModel.origin, 45);
	weaponModel.trigger = trigger;

	level.scavengerBags[level.scavengerBags.size] = weaponModel;
	
	trigger.owner = self;
	trigger thread _onScavengerBagPickup(weaponModel);
	trigger thread _onModelDeath(weaponModel);
}

_onScavengerBagPickup(weaponModel)
{
 	self endon("death");
    level endon("game_ended");
    
	for (;;)
	{
		self waittill("trigger_radius", player);
		if (!survivor_trigger_filter(player)) continue;
		if (!player player_has_perk("specialty_scavenger")) continue;

		currentWep = player getCurrentWeapon();
		foreach(weapon in player player_get_weapons())
			if (weapon == currentWep || player player_has_max_ammo(currentWep) || lethalbeats\math::math_chance(50))
				player player_give_random_ammo(weapon, 5, 15);

		foreach(nade in player player_get_nades())
			if (lethalbeats\math::math_chance(10))
				player player_add_nades(nade, 1);

		player playlocalsound("scavenger_pack_pickup");
		player maps\mp\gametypes\_damagefeedback::updatedamagefeedback("scavenger");

		if (isDefined(weaponModel)) weaponModel delete();
		self lethalbeats\trigger::trigger_delete();
	}
}

_scavengerBagVisibilityUpdater()
{
	self endon("death");
	for (;;)
	{		
		self hide();
		foreach (player in level.players)
		if (player.team == "allies" && player lethalbeats\player::player_has_perk("specialty_scavenger"))
			self showToPlayer(player);
		lethalbeats\utility::waittill_any("joined_team", "joined_spectators", "player_spawned", "changed_kit");
	}
}

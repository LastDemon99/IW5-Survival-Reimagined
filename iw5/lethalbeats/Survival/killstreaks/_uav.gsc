#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\killstreaks\_uav;

#define HEALTH 14
#define PRICE 16

init()
{
	level endon("game_ended");
	
	replacefunc(maps\mp\killstreaks\_uav::updateUAVModelVisibility, ::_updateUAVModelVisibility);
	replacefunc(maps\mp\killstreaks\_uav::damageTracker, ::_damageTracker);
	replacefunc(maps\mp\killstreaks\_uav::_getRadarStrength, ::__getRadarStrength);
	
	level.radarStrength = 2;
	level thread maps\mp\killstreaks\_uav::launchUAV(undefined, "axis", 9999, "uav");
	
	level.radarStrength = 0;
	level thread maps\mp\killstreaks\_uav::launchUAV(undefined, "allies", 9999, "uav");
	
	for(;;)
	{
		level waittill("wave_start");
		wait 0.4;

		if (level.radarStrength != -3) 
        {
            level.radarStrength = 2;
		    maps\mp\killstreaks\_uav::updateTeamUAVStatus("allies");
        }
		
		level waittill("wave_end");

        if (level.radarStrength != -3) 
        {
            level.radarStrength = 0;
		    maps\mp\killstreaks\_uav::updateTeamUAVStatus("allies");
        }
	}
}

__getRadarStrength(team)
{
	return team == "allies" ? level.radarStrength : 2;
}

_updateUAVModelVisibility()
{
	if (self.team == "axis" && !level.activeUAVs["axis"]) self hide();
}

_damageTracker(isCounterUAV, isAdvanced)
{
    level endon("game_ended");

    if (!isCounterUAV)
    {
        level endon ("game_ended");	
        level waittill("disable_uav");
        self notify("death");
        return;
    }

    self setcandamage(1);
    self.health = 99999;
    self.maxhealth = getBotData(HEALTH);
    self.damagetaken = 0;

    for (;;)
    {
        self waittill("damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon);

        if (!isplayer(attacker))
        {
            if (!isdefined(self)) return;
        }
        else
        {
            if (isdefined(iDFlags) && iDFlags & level.idflags_penetration)
                self.wasdamagedfrombulletpenetration = 1;

            self.wasdamaged = 1;
            modifiedDamage = damage;

            if (isplayer(attacker))
            {
                attacker maps\mp\gametypes\_damagefeedback::updatedamagefeedback("");
                if (meansOfDeath == "MOD_RIFLE_BULLET" || meansOfDeath == "MOD_PISTOL_BULLET")
                {
                    if (attacker maps\mp\_utility::_hasperk("specialty_armorpiercing"))
                        modifiedDamage += damage * level.armorpiercingmod;
                }
            }

            if (isdefined(weapon))
            {
                switch (weapon)
                {
                    case "stinger_mp":
                    case "javelin_mp":
                        self.largeprojectiledamage = 1;
                        modifiedDamage = self.maxhealth + 1;
                        break;
                    case "sam_projectile_mp":
                        self.largeprojectiledamage = 1;
                        mult = 0.25;

                        if (isAdvanced)
                            mult = 0.15;

                        modifiedDamage = self.maxhealth * mult;
                        break;
                }
            }

            self.damagetaken += modifiedDamage;
            if (self.damagetaken >= self.maxhealth)
            {
                if (isplayer(attacker) && (!isdefined(self.owner) || attacker != self.owner))
                {
                    self hide();
                    var_14 = anglestoright(self.angles) * 200;
                    playfx(level.uav_fx["explode"], self.origin, var_14);

                    if (isdefined(self.uavtype) && self.uavtype == "remote_mortar")
                        thread maps\mp\_utility::teamplayercardsplash("callout_destroyed_remote_mortar", attacker);
                    else if (isCounterUAV)
                        thread maps\mp\_utility::teamplayercardsplash("callout_destroyed_counter_uav", attacker);
                    else
                        thread maps\mp\_utility::teamplayercardsplash("callout_destroyed_uav", attacker);

                    thread maps\mp\gametypes\_missions::vehiclekilled(self.owner, self, undefined, attacker, damage, meansOfDeath, weapon);
                    attacker thread maps\mp\gametypes\_rank::giverankxp("kill", 50, weapon, meansOfDeath);
                    attacker notify("destroyed_killstreak");

                    if (isdefined(self.uavremotemarkedby) && self.uavremotemarkedby != attacker)
                        self.uavremotemarkedby thread maps\mp\killstreaks\_remoteuav::remoteuav_processtaggedassist();

                    attacker lethalbeats\survival\utility::survivor_give_score(getBotData(PRICE));
                }

                self notify("death");
                level.radarStrength = lethalbeats\survival\utility::bots(undefined, true).size ? 2 : 0;
                lethalbeats\player::players_play_sound("emp_activate", "allies");
                lethalbeats\player::players_play_sound("US_1mc_use_uav", "allies");
                return;
            }
        }
    }
}

getBotData(column)
{
    return int(tableLookup("mp/survival_bots.csv", 0, "counteruav", column));
}

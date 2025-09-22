#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\killstreaks\_airdrop;

init()
{
	replacefunc(maps\mp\killstreaks\_airdrop::getCrateTypeForDropType, ::_getcratetypefordroptype);
	
    level.killStreakFuncs["airdrop_assault"] = ::_tryUseAssaultAirdrop;

    game["strings"]["specialty_quickdraw_ks_hint"] = &"PERK_CAREPACKAGE_PICKUP";
    game["strings"]["specialty_bulletaccuracy_ks_hint"] = &"PERK_CAREPACKAGE_PICKUP";
    game["strings"]["specialty_stalker_ks_hint"] = &"PERK_CAREPACKAGE_PICKUP";
    game["strings"]["specialty_longersprint_ks_hint"] = &"PERK_CAREPACKAGE_PICKUP";
    game["strings"]["specialty_fastreload_ks_hint"] = &"PERK_CAREPACKAGE_PICKUP";
    game["strings"]["_specialty_blastshield_ks_hint"] = &"PERK_CAREPACKAGE_PICKUP";

	addCrateType("minigun_turret", "minigun_turret", 20, ::_killstreakCrateThink);
	addCrateType("gl_turret", "gl_turret", 20, ::_killstreakCrateThink);
    addCrateType("perk_quickdraw", "specialty_quickdraw_ks", 20, ::_killstreakCrateThink);
    addCrateType("perk_bulletaccuracy", "specialty_bulletaccuracy_ks", 20, ::_killstreakCrateThink);
    addCrateType("perk_stalker", "specialty_stalker_ks", 20, ::_killstreakCrateThink);
    addCrateType("perk_longersprint", "specialty_longersprint_ks", 20, ::_killstreakCrateThink);
    addCrateType("perk_fastreload", "specialty_fastreload_ks", 20, ::_killstreakCrateThink);
    addCrateType("perk_blastshield", "_specialty_blastshield_ks", 20, ::_killstreakCrateThink);
    addCrateType("perk_sitrep", "specialty_detectexplosive_ks", 20, ::_killstreakCrateThink);
}

giveAirDrop(type)
{
    self.airdropType = type;
    self maps\mp\killstreaks\_killstreaks::giveKillstreak("airdrop_assault");
}

_tryUseAssaultAirdrop(lifeId, kID)
{
	return (self tryUseAirdrop(lifeId, kID, self.airdropType));
}

_getcratetypefordroptype(dropType)
{
    switch (dropType)
    {
		case "minigun_turret":
			return "minigun_turret";
		case "gl_turret":
			return "gl_turret";
        case "perk_quickdraw":
            return "specialty_quickdraw_ks";
        case "perk_bulletaccuracy":
            return "specialty_bulletaccuracy_ks";
        case "perk_stalker":
            return "specialty_stalker_ks";
        case "perk_longersprint":
            return "specialty_longersprint_ks";
        case "perk_fastreload":
            return "specialty_fastreload_ks";
        case "perk_blastshield":
            return "_specialty_blastshield_ks";
        case "perk_sitrep":
            return "specialty_detectexplosive_ks";
        case "airdrop_sentry_minigun":
            return "sentry";
        case "airdrop_predator_missile":
            return "predator_missile";
        case "airdrop_juggernaut":
            return "airdrop_juggernaut";
        case "airdrop_juggernaut_def":
            return "airdrop_juggernaut_def";
        case "airdrop_juggernaut_gl":
            return "airdrop_juggernaut_gl";
        case "airdrop_juggernaut_recon":
            return "airdrop_juggernaut_recon";
        case "airdrop_trap":
            return "airdrop_trap";
        case "airdrop_trophy":
            return "airdrop_trophy";
        case "airdrop_remote_tank":
            return "remote_tank";
        case "airdrop_assault":
        case "airdrop_mega":
        case "airdrop_escort":
        case "airdrop_support":
        case "airdrop_grnd":
        case "airdrop_grnd_mega":
        default:
            return getRandomCrateType(dropType);
    }
}

_killstreakCrateThink(dropType)
{
	self endon ("death");
	
	if (isDefined(game["strings"][self.crateType + "_hint"]))
		crateHint = game["strings"][self.crateType + "_hint"];
	else 
		crateHint = &"PLATFORM_GET_KILLSTREAK";
	
	crateSetupForUse(crateHint, "all", maps\mp\killstreaks\_killstreaks::getKillstreakCrateIcon(self.crateType));

	self thread crateOtherCaptureThink();
	self thread crateOwnerCaptureThink();

	for (;;)
	{
		self waittill ("captured", player);
		
		if (isDefined(self.owner) && player != self.owner)
		{
			if (!level.teamBased || player.team != self.team)
			{
				switch(dropType)
				{
                    case "airdrop_assault":
                    case "airdrop_support":
                    case "airdrop_escort":
                    case "airdrop_osprey_gunner":
                        player thread maps\mp\gametypes\_missions::genericChallenge("hijacker_airdrop");
                        player thread hijackNotify(self, "airdrop");
                        break;
                    case "airdrop_sentry_minigun":
                        player thread maps\mp\gametypes\_missions::genericChallenge("hijacker_airdrop");
                        player thread hijackNotify(self, "sentry");
                        break;
                    case "airdrop_remote_tank":
                        player thread maps\mp\gametypes\_missions::genericChallenge("hijacker_airdrop");
                        player thread hijackNotify(self, "remote_tank");
                        break;
                    case "airdrop_mega":
                        player thread maps\mp\gametypes\_missions::genericChallenge("hijacker_airdrop_mega");
                        player thread hijackNotify(self, "emergency_airdrop");
                        break;
				}
			}
			else
			{
				self.owner thread maps\mp\gametypes\_rank::giveRankXP("killstreak_giveaway", Int((maps\mp\killstreaks\_killstreaks::getStreakCost(self.crateType) / 10) * 50));
				self.owner thread maps\mp\gametypes\_hud_message::splashNotifyDelayed("sharepackage", Int((maps\mp\killstreaks\_killstreaks::getStreakCost(self.crateType) / 10) * 50));
			}
		}

        lastDistance = undefined;
        lastTarget = undefined;
        airdrops = self.owner.airdrops;
        for(i = 0; i < airdrops.size; i++)
        {
            if (_getcratetypefordroptype(airdrops[i][0]) == self.crateType)
            {
                targetDistance = distanceSquared(airdrops[i][1], self.origin);
                if (!isDefined(lastDistance) || lastDistance > targetDistance)
                {
                    lastDistance = targetDistance;
                    lastTarget = i;
                }
            }
        }
        if (isDefined(lastTarget)) self.owner.airdrops = lethalbeats\array::array_remove_index(self.owner.airdrops, lastTarget);
	
        if (string_starts_with(dropType, "perk_")) 
        {
            perk = lethalbeats\survival\utility::getPerkFromKsPerk(self.crateType);
		    player lethalbeats\survival\utility::survivor_give_perk(perk);
            if (dropType == "perk_sitrep") level notify("update_bombsquad");
        }
		else player thread maps\mp\killstreaks\_killstreaks::giveKillstreak(self.crateType, false, false, self.owner);
        player playLocalSound("ammo_crate_use");

        player notify("weapon_change", player getCurrentWeapon());

        self deleteCrate();
	}
}

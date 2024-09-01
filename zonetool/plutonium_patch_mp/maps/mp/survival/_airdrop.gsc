#include maps\mp\_utility;
#include common_scripts\utility;

init()
{
	replacefunc(maps\mp\killstreaks\_airdrop::getcratetypefordroptype, ::getcratetypefordroptype);
	
	level.killStreakFuncs["airdrop_minigun_turret"] = ::tryUseMinigunAirdrop;
	level.killStreakFuncs["airdrop_gl_turret"] = ::tryUseGlAirdrop;

	maps\mp\killstreaks\_airdrop::addCrateType("airdrop_minigun_turret", "minigun_turret", 20, maps\mp\killstreaks\_airdrop::killstreakCrateThink);
	maps\mp\killstreaks\_airdrop::addCrateType("airdrop_gl_turret", "gl_turret", 20, maps\mp\killstreaks\_airdrop::killstreakCrateThink);
}

tryUseMinigunAirdrop(lifeId, kID)
{
	return (self maps\mp\killstreaks\_airdrop::tryUseAirdrop(lifeId, kID, "airdrop_minigun_turret"));
}

tryUseGlAirdrop(lifeId, kID)
{
	return (self maps\mp\killstreaks\_airdrop::tryUseAirdrop(lifeId, kID, "airdrop_gl_turret"));
}

getcratetypefordroptype(dropType)
{
    switch (dropType)
    {
		case "airdrop_minigun_turret":
			return "minigun_turret";
		case "airdrop_gl_turret":
			return "gl_turret";
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
            return maps\mp\killstreaks\_airdrop::getrandomcratetype(dropType);
    }
}

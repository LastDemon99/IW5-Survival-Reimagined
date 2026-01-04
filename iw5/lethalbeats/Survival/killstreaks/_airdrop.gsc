#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\killstreaks\_airdrop;

init()
{
    precacheString(&"PLATFORM_GET_KILLSTREAK");

	replacefunc(maps\mp\killstreaks\_airdrop::getCrateTypeForDropType, ::_getcratetypefordroptype);
    replacefunc(maps\mp\killstreaks\_airdrop::watchairdropmarker, ::_watchairdropmarker);
    replacefunc(maps\mp\killstreaks\_airdrop::dropthecrate, ::_dropthecrate);
	
    level.killStreakFuncs["airdrop_assault"] = ::_tryUseAssaultAirdrop;

    game["strings"]["specialty_quickdraw_ks_hint"] = &"PERK_CAREPACKAGE_PICKUP";
    game["strings"]["specialty_bulletaccuracy_ks_hint"] = &"PERK_CAREPACKAGE_PICKUP";
    game["strings"]["specialty_stalker_ks_hint"] = &"PERK_CAREPACKAGE_PICKUP";
    game["strings"]["specialty_longersprint_ks_hint"] = &"PERK_CAREPACKAGE_PICKUP";
    game["strings"]["specialty_fastreload_ks_hint"] = &"PERK_CAREPACKAGE_PICKUP";
    game["strings"]["_specialty_blastshield_ks_hint"] = &"PERK_CAREPACKAGE_PICKUP";
    game["strings"]["specialty_detectexplosive_ks_hint"] = &"PERK_CAREPACKAGE_PICKUP";

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

_watchairdropmarker(lifeId, kID, dropType)
{
    level endon("game_ended");
    self notify("watchAirDropMarker");
    self endon("watchAirDropMarker");
    self endon("disconnect");
    self endon("markerDetermined");

    for (;;)
    {
        self waittill("grenade_fire", airDropWeapon, weapname);

        if (!isairdropmarker(weapname))
            continue;

        self.threwairdropmarker = 1;
        self.threwairdropmarkerindex = self.killstreakindexweapon;

        airDropWeapon thread _airdropdetonateonstuck();
        airDropWeapon.owner = self;
        airDropWeapon.weaponname = weapname;
        airDropWeapon thread _airdropmarkeractivate(dropType, undefined, "" + airDropWeapon getEntityNumber() + getTime());
    }
}

_airdropdetonateonstuck()
{
    self endon("explode");    
    self waittill("missile_stuck");

    for(;;)
    {
        wait 0.35;
        self detonate(); // sometimes the airdrop marker doesn't activate. ¯\_(ᵕ—ᴗ—)_/¯
    }
}

_airdropmarkeractivate(dropType, lifeId, airdropId)
{
    level endon("game_ended");
    self notify("airDropMarkerActivate");
    self endon("airDropMarkerActivate");
    self waittill("explode", position);
    owner = self.owner;

    if (!isdefined(owner) || owner maps\mp\_utility::isEMPed() || owner maps\mp\_utility::isAirDenied() || (issubstr(tolower(dropType), "escort_airdrop") && isdefined(level.chopper)))
        return;

    wait 0.05;

    owner.airdrops[owner.airdrops.size] = [owner.airdropType, lethalbeats\vector::vector_truncate(position, 3), airdropId]; // saves airdrop if the match is reset to clear entities.

    if (issubstr(tolower(dropType), "juggernaut"))
        level doc130flyby(owner, position, randomfloat(360), dropType);
    else if (issubstr(tolower(dropType), "escort_airdrop"))
        owner maps\mp\killstreaks\_escortairdrop::finishsupportescortusage(lifeId, position, randomfloat(360), "escort_airdrop");
    else
        level _doflyby(owner, position, randomfloat(360), dropType, undefined, undefined, airdropId);
}

_doflyby(owner, dropSite, dropYaw, dropType, heightAdjustment, crateOverride, airdropId)
{
    if (!isdefined(owner)) return;

    flyHeight = getflyheightoffset(dropSite);
    if (isdefined(heightAdjustment)) flyHeight = flyHeight + heightAdjustment;

    foreach (littlebird in level.littlebirds)
    {
        if (isdefined(littlebird.droptype))
            flyHeight = flyHeight + 128;
    }

    pathGoal = dropSite * (1, 1, 0) + (0, 0, flyHeight);
    pathStart = getpathstart(pathGoal, dropYaw);
    pathEnd = getpathend(pathGoal, dropYaw);
    pathGoal = pathGoal + anglestoforward((0, dropYaw, 0)) * -50;
    
    chopper = helisetup(owner, pathStart, pathGoal);
    chopper.airdropId = airdropId;
    chopper endon("death");

    if (!isdefined(crateOverride))
        crateOverride = undefined;

    chopper.droptype = dropType;
    chopper setvehgoalpos(pathGoal, 1);
    chopper thread dropthecrate(dropSite, dropType, flyHeight, 0, crateOverride, pathStart);
    wait 2;
    chopper vehicle_setspeed(75, 40);
    chopper setyawspeed(180, 180, 180, 0.3);
    chopper waittill("goal");
    wait 0.1;
    chopper notify("drop_crate");
    chopper setvehgoalpos(pathEnd, 1);
    chopper vehicle_setspeed(300, 75);
    chopper.leaving = 1;
    chopper waittill("goal");
    chopper notify("leaving");
    chopper notify("delete");
    maps\mp\_utility::decrementFauxVehicleCount();
    chopper delete();
}

_dropthecrate(dropPoint, dropType, lbHeight, dropImmediately, crateOverride, startPos, dropImpulse, previousCrateTypes, tagName)
{
    dropCrate = [];
    self.owner endon("disconnect");

    if (!isdefined(crateOverride))
    {
        if (isdefined(previousCrateTypes))
        {
            foundDupe = undefined;
            crateType = undefined;

            for (i = 0; i < 100; i++)
            {
                crateType = getcratetypefordroptype(dropType);
                foundDupe = 0;

                for (j = 0; j < previousCrateTypes.size; j++)
                {
                    if (crateType == previousCrateTypes[j])
                    {
                        foundDupe = 1;
                        break;
                    }
                }

                if (foundDupe == 0)
                    break;
            }

            if (foundDupe == 1)
                crateType = getcratetypefordroptype(dropType);
        }
        else
            crateType = getcratetypefordroptype(dropType);
    }
    else
        crateType = crateOverride;

    if (!isdefined(dropImpulse))
        dropImpulse = (randomint(5), randomint(5), randomint(5));

    dropCrate = createairdropcrate(self.owner, dropType, crateType, startPos);
    dropCrate.airdropId = self.airdropId;
    dropCrate thread _airDropCrateDeath();

    switch (dropType)
    {
        case "nuke_drop":
        case "airdrop_mega":
        case "airdrop_juggernaut_recon":
        case "airdrop_juggernaut":
            dropCrate linkto(self, "tag_ground", (64, 32, -128), (0, 0, 0));
            break;
        case "airdrop_escort":
        case "airdrop_osprey_gunner":
            dropCrate linkto(self, tagName, (0, 0, 0), (0, 0, 0));
            break;
        default:
            dropCrate linkto(self, "tag_ground", (32, 0, 5), (0, 0, 0));
            break;
    }

    dropCrate.angles = (0, 0, 0);
    dropCrate show();
    dropSpeed = self.veh_speed;
    thread waitfordropcratemsg(dropCrate, dropImpulse, dropType, crateType);
    return crateType;
}

_airDropCrateDeath()
{
    self endon("captured");
    self waittill("death");
    self _clearSurvivorAirdrop();
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
		self waittill("captured", player);
		
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

        self _clearSurvivorAirdrop();
	
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

/*
///DocStringBegin
detail: _clearSurvivorAirdrop(): <Void>
summary: `onAirdropFire` in `survivorHandler` monitors when an airdrop is called, and if the match is reset to clear entities, it spawns it again. This func clears used airdrops.
///DocStringEnd
*/
_clearSurvivorAirdrop()
{
    if (!isDefined(self.airdropId)) return;

    airdrops = self.owner.airdrops;
    airdropIndex = undefined;

    for(i = 0; i < airdrops.size; i++)
    {
        if (self.airdropId == airdrops[i][2])
        {
            airdropIndex = i;
            break;
        }
    }

    if (isDefined(airdropIndex)) self.owner.airdrops = lethalbeats\array::array_remove_index(self.owner.airdrops, airdropIndex);
}

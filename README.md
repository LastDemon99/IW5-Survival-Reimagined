<p align="center">
  <img src="https://github.com/LastDemon99/LastDemon99/blob/main/Data/lb_logo.jpg">  
  <br><br>
  <b>IW5 SURVIVAL REIMAGINED</b><br>
  <a>This project aims to replicate to some extent the spec ops survival mode for plutonium dedicated servers.</a> 
  <br><br>
    • <a href="#key-features">Key Features</a> •  
  <a href="#how-to-use">How To Use</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#download">Download</a> •
  <a href="#credits">Credits</a> •
  <a href="#sponsor">Sponsor</a> •
</p>

> [!IMPORTANT]
> This mod required: [IW5 Bot Warfare](https://github.com/ineedbots/piw5_bot_warfare)
> This mod required: [LB Utility](https://github.com/LastDemon99/IW5-Sripts/tree/main/GSC/Utility)
> Mod under development

# <a name="key-features"></a>Key Features
- Compatible with all stock maps.
- Unlimited waves.
- Number of survivors defined by dvar, note that these occupy bot slots, a limit of 4 is recommended.
- Difficulty adaptable to the number of waves and players.
- The ammunition is collected independently of the weapon modifications.
- The buffs of the dropped weapons are preserved.
- You can drop the weapon to an ally with the `H` key.
- New enemy types were added including streaks.

# <a name="how-to-use"></a>How To Use
- Unzip the rar file at `%localappdata%/plutonium/storage/iw5/`
- In the console type `fs_game mods/survival` and then type vid_restart_safe to load the mod, or simply login to a server that has the mod.
- Once the mod is loaded you can start a game by loading Survival dsr.

# <a name="configuration"></a>Configuration

You can edit the following dvar inside the survival_config.cfg file located at  

| **Dvar**                              | **Default Value** |
|---------------------------------------|-------------------|
| survival_survivors_limit              | 4                 |
| survival_start_armor                  | 250               |
| survival_start_money                  | 500               |
| survival_wait_respawn                 | 1                 |
| survival_wait_shops                   | 1                 |
| survival_wave_start                   | 1                 |

## Ammo Prices

| **Dvar**                              | **Default Value** |
|---------------------------------------|-------------------|
| price_ammo_pistol                     | 600               |
| price_ammo_shotgun                    | 850               |
| price_ammo_machine_pistol             | 850               |
| price_ammo_smg                        | 1000              |
| price_ammo_assault                    | 1000              |
| price_ammo_lmg                        | 1500              |
| price_ammo_sniper                     | 1000              |
| price_ammo_projectile                 | 2000              |
| price_ammo_xmags                       | 500               |
| price_ammo_gl                          | 300               |
| price_ammo_shotgun_alt                 | 300               |

## Weapons Prices

| **Dvar**                              | **Default Value** |
|---------------------------------------|-------------------|
| price_iw5_usp45                       | 600               |
| price_iw5_p99                         | 600               |
| price_iw5_mp412                       | 600               |
| price_iw5_44magnum                    | 600               |
| price_iw5_fnfiveseven                 | 600               |
| price_iw5_deserteagle                 | 600               |
| price_iw5_usas12                      | 1000              |
| price_iw5_ksg                         | 1000              |
| price_iw5_spas12                      | 1000              |
| price_iw5_aa12                        | 1000              |
| price_iw5_striker                     | 1000              |
| price_iw5_1887                        | 1000              |
| price_iw5_fmg9                        | 1250              |
| price_iw5_mp9                         | 1250              |
| price_iw5_skorpion                    | 1250              |
| price_iw5_g18                         | 1250              |
| price_iw5_mp5                         | 1500              |
| price_iw5_ump45                       | 1500              |
| price_iw5_pp90m1                      | 1500              |
| price_iw5_p90                         | 1500              |
| price_iw5_m9                          | 1500              |
| price_iw5_mp7                         | 1500              |
| price_iw5_ak74u                       | 1500              |
| price_iw5_m4                          | 2000              |
| price_iw5_m16                         | 2000              |
| price_iw5_scar                        | 2000              |
| price_iw5_cm901                       | 2000              |
| price_iw5_type95                      | 2000              |
| price_iw5_g36c                        | 2000              |
| price_iw5_acr                         | 2000              |
| price_iw5_mk14                        | 2000              |
| price_iw5_ak47                        | 2000              |
| price_iw5_fad                         | 2000              |
| price_iw5_sa80                        | 3000              |
| price_iw5_mg36                        | 3000              |
| price_iw5_pecheneg                    | 4000              |
| price_iw5_mk46                        | 4000              |
| price_iw5_m60                         | 4000              |
| price_iw5_barrett                     | 2000              |
| price_iw5_l96a1                       | 1500              |
| price_iw5_dragunov                    | 2000              |
| price_iw5_as50                        | 2000              |
| price_iw5_rsass                        | 2000              |
| price_iw5_msr                          | 1500              |
| price_iw5_cheytac                      | 1500              |

## Buffs Prices

| **Dvar**                              | **Default Value** |
|---------------------------------------|-------------------|
| price_specialty_marksman              | 2000              |
| price_specialty_bulletpenetration     | 2000              |
| price_specialty_bling                 | 3000              |
| price_specialty_sharp_focus           | 2000              |
| price_specialty_holdbreathwhileads    | 2000              |
| price_specialty_reducedsway           | 2000              |
| price_specialty_longerrange           | 2000              |
| price_specialty_fastermelee           | 3000              |
| price_specialty_lightweight           | 3000              |
| price_specialty_moredamage            | 2000              |
| price_remove_buff_multiplier          | 0.3               |

## Attachs Prices

| **Dvar**                              | **Default Value** |
|---------------------------------------|-------------------|
| price_gl                              | 2000              |
| price_silencer                        | 2000              |
| price_akimbo                          | 2000              |
| price_tactical                        | 1000              |
| price_xmags                           | 3000              |
| price_grip                            | 2000              |
| price_reflex                          | 1250              |
| price_eotech                          | 750               |
| price_rof                             | 3000              |
| price_acog                            | 1500              |
| price_hamrhybrid                      | 1700              |
| price_thermal                         | 2000              |
| price_heartbeat                       | 1500              |
| price_shotgun                         | 1000              |
| price_hybrid                          | 1700              |
| price_vzscope                         | 1000              |
| price_remove_attach_multiplier        | 0.3               |

## Camos Prices

| **Dvar**                              | **Default Value** |
|---------------------------------------|-------------------|
| price_classic                         | 500               |
| price_snow                            | 500               |
| price_multi                           | 500               |
| price_d_urban                         | 500               |
| price_hex                             | 500               |
| price_choco                           | 500               |
| price_snake                           | 500               |
| price_blue                            | 500               |
| price_red                             | 500               |
| price_autumn                          | 500               |
| price_gold                            | 1000              |
| price_marine                          | 500               |
| price_winter                          | 500               |

## Slots Prices

| **Dvar**                              | **Default Value** |
|---------------------------------------|-------------------|
| price_attach_slot                     | 1000              |
| price_attach_slot_multiplier          | 1.5               |
| price_buff_slot                       | 1000              |
| price_buff_slot_multiplier            | 2                 |

## Equipment Prices

| **Dvar**                              | **Default Value** |
|---------------------------------------|-------------------|
| price_frag_grenade_mp                 | 750               |
| price_flash_grenade_mp                | 750               |
| price_throwingknife_mp                | 1000              |
| price_concussion_grenade_mp           | 1000              |
| price_claymore_mp                     | 1500              |
| price_c4_mp                           | 1500              |
| price_trophy_mp                       | 750               |
| price_body_armor                      | 2000              |
| price_self_revive                     | 3000              |

## Air Support Prices

| **Dvar**                              | **Default Value** |
|---------------------------------------|-------------------|
| price_predator_missile                | 2500              |
| price_precision_airstrike             | 4000              |
| price_minigun_turret                   | 3000              |
| price_gl_turret                        | 4000              |
| price_specialty_quickdraw_ks           | 3000              |
| price_specialty_bulletaccuracy_ks      | 3000              |
| price_specialty_stalker_ks             | 3000              |
| price_specialty_longersprint_ks        | 3000              |
| price_specialty_fastreload_ks          | 3000              |
| price__specialty_blastshield_ks        | 3000              |
| price_specialty_detectexplosive_ks     | 3000              |
| price_remove_perk_multiplier           | 0.35              |

# <a name="download"></a>Download
- Mod files: [IW5_SURVIVAL_REIMAGINED](https://github.com/LastDemon99/IW5-Survival-Reimagined/releases/download/iw5-mp-survival-v2.0/IW5-Survival-Reimagined.rar)

# <a name="credits"></a>Credits
- [Master-64](https://github.com/Master-64) for Sponsor this project
- [SadSlothXL](https://github.com/SadSlothXL) for helping with modding issues 
- [Plutonium team](https://github.com/plutoniummod) for gsc & mod implementation
- LethalBeats team
  
# <a name="sponsor"></a>Sponsor
If you like my work and wish to contribute:<br><br/>
<a href="https://www.paypal.com/paypalme/lastdemon99/"><img src="https://github.com/LastDemon99/LastDemon99/blob/main/Data/paypal_dark.svg" height="60"></a>

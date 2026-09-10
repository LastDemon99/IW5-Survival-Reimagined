#include common_scripts\utility;
#include maps\mp\_utility;
#include lethalbeats\dynamicmenus\dynamic_shop;

// OPTION TYPE
#define OPTION_BUY -5
#define OPTION_DISABLE -4
#define OPTION_OWNED -3
#define OPTION_UPGRADE -2
#define OPTION_SCRIPTRESPONSE -1

// ARMORY MENUS
#define PAGE_NULL -1
#define WEAPON_ARMORY 0
#define WEAPON_EQUIPMENT 1
#define WEAPON_AIR_SUPPORT 2

// PAGE & ITEM INDICES
#define PAGE_ITEMS 3
#define ITEM_UNLOCK_LEVEL 6

init()
{
	precacheShader("specialty_self_revive");
	precacheShader("specops_ui_equipmentstore");
	precacheShader("specops_ui_weaponstore");
	precacheShader("specops_ui_airsupport");

    level.onOpenPage = ::onOpenPage;
    level.onSelectOption = ::onSelectOption;
    level.onUpdateOption = ::onUpdateOption;
    level.isUpgradeOption = ::isUpgradeOption;
    level.isOwnedOption = ::isOwnedOption;
    level.isDisabledOption = ::isDisabledOption;

    init_weapon_armory();
    init_equipment_armory();
    init_air_support_armory();
    
    thread lethalbeats\Survival\armories\_spawn::init();
}

init_weapon_armory()
{
    menu = shop_create_menu("weapon_armory");

    // Main Page (Submenus)
    page = menu shop_create_page("weapon_armory", "SO_SURVIVAL_ARMORY_WEAPON", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("ammo", undefined, "SO_SURVIVAL_AMMO_REFILL", "SO_SURVIVAL_AMMO_REFILL_DESC");
    page shop_create_item("select_pistol", undefined, "MPUI_HANDGUNS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("select_shotgun", undefined, "MPUI_SHOTGUNS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("select_machine_pistol", undefined, "MPUI_MACHINE_PISTOLS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("select_smg", undefined, "MPUI_SUB_MACHINE_GUNS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("select_assault", undefined, "MPUI_ASSAULT_RIFLES", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("select_lmg", undefined, "MPUI_LIGHT_MACHINE_GUNS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("select_sniper", undefined, "MPUI_SNIPER_RIFLES", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("select_projectile", undefined, "MPUI_ROCKETS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("select_riot", undefined, "MPUI_RIOTSHIELD", "SO_SURVIVAL_ARMORY_WEAPON_DESC");

    // Ammo Refill Slots
    page = menu shop_create_page("ammo", "SO_SURVIVAL_AMMO_REFILL", "SO_SURVIVAL_AMMO_REFILL_DESC");
    page shop_create_item("0", undefined, "weapon_0", "SO_SURVIVAL_AMMO_REFILL_DESC");
    page shop_create_item("1", undefined, "weapon_1", "SO_SURVIVAL_AMMO_REFILL_DESC");

    // Handguns
    page = menu shop_create_page("select_pistol", "MENU_HANDGUNS_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("iw5_usp45", 600, "WEAPON_USP", "PERKS_PISTOL_SEMIAUTO", "weapon_usp_45", undefined, 1);
    page shop_create_item("iw5_p99", 600, "WEAPON_P99", "PERKS_PISTOL_SEMIAUTO", "weapon_p99", undefined, 39);
    page shop_create_item("iw5_mp412", 600, "WEAPON_MP412", "PERKS_PISTOL_REVOLVER", "weapon_mp412", undefined, 2);
    page shop_create_item("iw5_44magnum", 900, "WEAPON_MAGNUM", "PERKS_PISTOL_REVOLVER", "weapon_magnum", undefined, 19);
    page shop_create_item("iw5_fnfiveseven", 600, "WEAPON_FNFIVESEVEN", "PERKS_PISTOL_SEMIAUTO", "weapon_fnfiveseven", undefined, 29);
    page shop_create_item("iw5_deserteagle", 900, "WEAPON_DESERTEAGLE", "PERKS_PISTOL_SEMIAUTO", "weapon_desert_eagle", undefined, 10);
    page shop_create_item("iw5_iw4beretta", 600, "WEAPON_BERETTA", "PERKS_PISTOL_SEMIAUTO", "weapon_m9beretta", undefined, 8);

    // Shotguns
    page = menu shop_create_page("select_shotgun", "MENU_SHOTGUNS_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("iw5_usas12", 1000, "WEAPON_USAS12", "PERKS_SHOTGUN_FULLAUTO", "weapon_usas12", undefined, 1);
    page shop_create_item("iw5_ksg", 1000, "WEAPON_KSG", "PERKS_SHOTGUN_PUMP", "weapon_ksg", undefined, 25);
    page shop_create_item("iw5_spas12", 1000, "WEAPON_SPAS12", "PERKS_SHOTGUN_PUMP", "weapon_spas12", undefined, 15);
    page shop_create_item("iw5_aa12", 1000, "WEAPON_AA12", "PERKS_SHOTGUN_FULLAUTO", "weapon_aa12", undefined, 43);
    page shop_create_item("iw5_striker", 1000, "WEAPON_STRIKER", "PERKS_SHOTGUN_SEMIAUTO", "weapon_striker", undefined, 32);
    page shop_create_item("iw5_1887", 1000, "WEAPON_MODEL1887", "PERKS_SHOTGUN_LEVER", "weapon_model1887", undefined, 22);
    page shop_create_item("iw5_iw4m1014", 1000, "WEAPON_BENELLI", "PERKS_SHOTGUN_PUMP", "weapon_benelli_m4", undefined, 18);
    page shop_create_item("iw5_iw4ranger", 1000, "WEAPON_RANGER", "PERKS_SHOTGUN_DOUBLE", "weapon_ranger", undefined, 8);

    // Machine Pistols
    page = menu shop_create_page("select_machine_pistol", "MENU_MACHINE_PISTOLS_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("iw5_fmg9", 1250, "WEAPON_FMG9", "PERKS_MPISTOL_FULLAUTO", "weapon_fmg9", undefined, 36);
    page shop_create_item("iw5_mp9", 1250, "WEAPON_MP9", "PERKS_MPISTOL_FULLAUTO", "weapon_mp9", undefined, 16);
    page shop_create_item("iw5_skorpion", 1250, "WEAPON_SKORPION", "PERKS_MPISTOL_FULLAUTO", "weapon_skorpion", undefined, 1);
    page shop_create_item("iw5_g18", 1250, "WEAPON_GLOCK", "PERKS_MPISTOL_FULLAUTO", "weapon_glock", undefined, 10);
    page shop_create_item("iw5_iw4beretta393", 1250, "WEAPON_BERETTA393", "PERKS_MPISTOL_FULLAUTO", "weapon_beretta393", undefined, 26);
    page shop_create_item("iw5_iw4pp2000", 1250, "WEAPON_PP2000", "PERKS_MPISTOL_FULLAUTO", "weapon_pp2000", undefined, 4);

    // SMGs
    page = menu shop_create_page("select_smg", "MENU_SMGS_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("iw5_mp5", 1500, "WEAPON_MP5K", "PERKS_SMG", "weapon_mp5k", undefined, 1);
    page shop_create_item("iw5_ump45", 1500, "WEAPON_UMP45", "PERKS_SMG", "weapon_ump45", undefined, 3);
    page shop_create_item("iw5_pp90m1", 1500, "WEAPON_PP90M1", "PERKS_SMG_RAPID", "weapon_pp90m1", undefined, 37);
    page shop_create_item("iw5_p90", 1500, "WEAPON_P90", "PERKS_SMG_AMMO", "weapon_p90", undefined, 45);
    page shop_create_item("iw5_m9", 1500, "WEAPON_PM9", "PERKS_SMG", "weapon_mini_uzi", undefined, 22);
    page shop_create_item("iw5_mp7", 1500, "WEAPON_MP7", "PERKS_MP7", "weapon_mp7", undefined, 12);
    page shop_create_item("iw5_ak74u", 1500, "AK-74u", "PERKS_SMG", "weapon_aks74u", undefined, 27);
    page shop_create_item("iw5_iw4mp5k", 1500, "WEAPON_IW4_MP5K", "PERKS_SMG", "weapon_mp5k", undefined, 8);
    page shop_create_item("iw5_iw4uzi", 1500, "WEAPON_MINI_UZI", "PERKS_SMG", "weapon_uzi", undefined, 24);
    page shop_create_item("iw5_iw4kriss", 1500, "WEAPON_KRISS", "PERKS_SMG", "weapon_kriss", undefined, 14);

    // Assault Rifles
    page = menu shop_create_page("select_assault", "MENU_ASSAULT_RIFLES_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("iw5_m4", 2000, "WEAPON_M4", "PERKS_AR_FULLAUTO", "weapon_m4_short", undefined, 1);
    page shop_create_item("iw5_m16", 2000, "WEAPON_M16", "PERKS_AR_THREEROUND", "weapon_m16a4", undefined, 8);
    page shop_create_item("iw5_scar", 2000, "WEAPON_SCAR", "PERKS_AR_FULLAUTO", "weapon_scar_h", undefined, 4);
    page shop_create_item("iw5_cm901", 2000, "WEAPON_CM901", "PERKS_AR_FULLAUTO", "weapon_cm901", undefined, 42);
    page shop_create_item("iw5_type95", 2000, "WEAPON_TYPE95", "PERKS_AR_THREEROUND", "weapon_type95", undefined, 49);
    page shop_create_item("iw5_g36c", 2000, "WEAPON_G36", "PERKS_AR_FULLAUTO", "weapon_g36", undefined, 38);
    page shop_create_item("iw5_acr", 2000, "WEAPON_ACR", "PERKS_AR_FULLAUTO", "weapon_acr", undefined, 13);
    page shop_create_item("iw5_mk14", 2000, "WEAPON_MK14", "PERKS_AR_SEMIAUTO", "weapon_mk14", undefined, 44);
    page shop_create_item("iw5_ak47", 2000, "WEAPON_AK47", "PERKS_AR_FULLAUTO", "weapon_ak47", undefined, 23);
    page shop_create_item("iw5_fad", 2000, "WEAPON_FAD", "PERKS_AR_FULLAUTO", "weapon_fad", undefined, 31);
    page shop_create_item("iw5_iw4fal", 2000, "WEAPON_FAL", "PERKS_AR_SEMIAUTO", "weapon_fnfal", undefined, 46);
    page shop_create_item("iw5_iw4famas", 2000, "WEAPON_FAMAS", "PERKS_AR_SEMIAUTO", "weapon_famas", undefined, 20);
    page shop_create_item("iw5_iw4fn2000", 2000, "WEAPON_FN2000", "PERKS_AR_FULLAUTO", "weapon_fn2000", undefined, 32);
    page shop_create_item("iw5_iw4tavor", 2000, "WEAPON_TAVOR", "PERKS_AR_FULLAUTO", "weapon_tavor", undefined, 6);

    // LMGs
    page = menu shop_create_page("select_lmg", "MENU_LMGS_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("iw5_sa80", 3000, "WEAPON_SA80", "PERKS_LMG", "weapon_sa80", undefined, 40);
    page shop_create_item("iw5_mg36", 3000, "WEAPON_MG36", "PERKS_LMG", "weapon_mg36", undefined, 47);
    page shop_create_item("iw5_pecheneg", 4000, "WEAPON_PECHENEG", "PERKS_LMG", "weapon_pecheneg", undefined, 17);
    page shop_create_item("iw5_mk46", 4000, "WEAPON_MK46", "PERKS_LMG", "weapon_mk46", undefined, 33);
    page shop_create_item("iw5_m60", 4000, "WEAPON_M60", "PERKS_LMG", "weapon_m60e4", undefined, 11);
    page shop_create_item("iw5_iw4m240", 4000, "WEAPON_M240", "PERKS_LMG", "weapon_m240", undefined, 11);
    page shop_create_item("iw5_iw4aug", 3000, "WEAPON_AUG", "PERKS_LMG", "weapon_steyr", undefined, 40);
    page shop_create_item("iw5_iw4rpd", 4000, "WEAPON_RPD", "PERKS_LMG", "weapon_rpd", undefined, 17);

    // Sniper Rifles
    page = menu shop_create_page("select_sniper", "MENU_SNIPER_RIFLES_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("iw5_barrett", 2000, "WEAPON_BARRETT", "PERKS_SNIPER_SEMIAUTO", "weapon_barrett", undefined, 48);
    page shop_create_item("iw5_l96a1", 1500, "WEAPON_L96A1", "PERKS_SNIPER_BOLT", "weapon_l96a1", undefined, 34);
    page shop_create_item("iw5_dragunov", 2000, "WEAPON_DRAGUNOV", "PERKS_SNIPER_SEMIAUTO", "weapon_dragunov", undefined, 15);
    page shop_create_item("iw5_as50", 2000, "WEAPON_AS50", "PERKS_SNIPER_SEMIAUTO", "weapon_as50", undefined, 41);
    page shop_create_item("iw5_rsass", 2000, "WEAPON_RSASS", "PERKS_SNIPER_SEMIAUTO", "weapon_rsass", undefined, 28);
    page shop_create_item("iw5_msr", 1500, "WEAPON_MSR", "PERKS_SNIPER_BOLT", "weapon_msr", undefined, 6);
    page shop_create_item("iw5_cheytac", 1500, "INTERVENTION", "PERKS_SNIPER_BOLT", "weapon_cheytac", undefined, 6);

    // Launchers
    page = menu shop_create_page("select_projectile", "MENU_ROCKETS_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("iw5_smaw", 2000, "WEAPON_SMAW", "PERKS_LAUNCHER_AT4", "weapon_smaw");
    page shop_create_item("javelin", 3000, "WEAPON_JAVELIN", "PERKS_LAUNCHER_JAVELIN", "weapon_javelin");
    page shop_create_item("stinger", 3000, "WEAPON_STINGER", "PERKS_LAUNCHER_STINGER", "weapon_stinger");
    page shop_create_item("xm25", 2000, "WEAPON_XM25", "PERKS_LAUNCHER_XM25", "weapon_xm25");
    page shop_create_item("m320", 2000, "WEAPON_M320", "PERKS_LAUNCHER_GL", "weapon_m320");
    page shop_create_item("rpg", 2000, "WEAPON_RPG", "PERKS_LAUNCHER_ROCKET", "weapon_rpg7", undefined, 26);

    // Riot Shield
    page = menu shop_create_page("select_riot", "MENU_RIOT_SHIELD_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("riotshield", 2000, "WEAPON_RIOTSHIELD", "PERKS_RIOT_SHIELD", "weapon_riotshield", undefined, 30);

    // Upgrade Weapon
    page = menu shop_create_page("upgrade_weapon", "MENU_UPGRADE_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("add_attach", undefined, "MPUI_ATTACHMENT", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("add_buff", undefined, "MPUI_PROFICIENCY", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("weapon_camo", undefined, "MPUI_CAMO", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("attach_slot", 1000, "MPUI_ATTACH_SLOT", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("buff_slot", 1000, "MPUI_BUFF_SLOT", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("remove_attach", undefined, "MPUI_REMOVE_ATTACH", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("remove_buff", undefined, "MPUI_REMOVE_BUFF", "SO_SURVIVAL_ARMORY_WEAPON_DESC");

    // Proficiencies / Buffs
    page = menu shop_create_page("assault_buff", "MENU_PROFICIENCY_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("specialty_marksman", 2000, "PERKS_MARKSMAN", "PERKS_DESC_MARKSMAN", undefined, "specialty_marksman", 4);
    page shop_create_item("specialty_bulletpenetration", 2000, "PERKS_DEEP_IMPACT", "PERKS_DESC_DEEP_IMPACT", undefined, "specialty_bulletpenetration", 10);
    page shop_create_item("specialty_sharp_focus", 2000, "PERKS_SHARPFOCUS", "PERKS_DESC_SHARPFOCUS", undefined, "specialty_sharp_focus", 18);
    page shop_create_item("specialty_holdbreathwhileads", 2000, "PERKS_HOLDBREATHWHILEADS", "PERKS_DESC_HOLDBREATHWHILEADS", undefined, "specialty_holdbreathwhileads", 24);
    page shop_create_item("specialty_reducedsway", 2000, "PERKS_REDUCEDSWAY", "PERKS_DESC_REDUCEDSWAY", undefined, "specialty_reducedsway", 30);

    page = menu shop_create_page("smg_buff", "MENU_PROFICIENCY_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("specialty_marksman", 2000, "PERKS_MARKSMAN", "PERKS_DESC_MARKSMAN", undefined, "specialty_marksman", 4);
    page shop_create_item("specialty_longerrange", 2000, "PERKS_LONGERRANGE", "PERKS_DESC_LONGERRANGE", undefined, "specialty_longerrange", 36);
    page shop_create_item("specialty_sharp_focus", 2000, "PERKS_SHARPFOCUS", "PERKS_DESC_SHARPFOCUS", undefined, "specialty_sharp_focus", 18);
    page shop_create_item("specialty_fastermelee", 3000, "PERKS_FASTERMELEE", "PERKS_DESC_FASTERMELEE", undefined, "specialty_fastmeleerecovery", 42);
    page shop_create_item("specialty_reducedsway", 2000, "PERKS_REDUCEDSWAY", "PERKS_DESC_REDUCEDSWAY", undefined, "specialty_reducedsway", 30);

    page = menu shop_create_page("lmg_buff", "MENU_PROFICIENCY_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("specialty_marksman", 2000, "PERKS_MARKSMAN", "PERKS_DESC_MARKSMAN", undefined, "specialty_marksman", 4);
    page shop_create_item("specialty_bulletpenetration", 2000, "PERKS_DEEP_IMPACT", "PERKS_DESC_DEEP_IMPACT", undefined, "specialty_bulletpenetration", 10);
    page shop_create_item("specialty_sharp_focus", 2000, "PERKS_SHARPFOCUS", "PERKS_DESC_SHARPFOCUS", undefined, "specialty_sharp_focus", 18);
    page shop_create_item("specialty_lightweight", 3000, "PERKS_LIGHTWEIGHT", "PERKS_DESC_LIGHTWEIGHT", undefined, "specialty_lightweight", 46);
    page shop_create_item("specialty_reducedsway", 2000, "PERKS_REDUCEDSWAY", "PERKS_DESC_REDUCEDSWAY", undefined, "specialty_reducedsway", 30);

    page = menu shop_create_page("sniper_buff", "MENU_PROFICIENCY_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("specialty_marksman", 2000, "PERKS_MARKSMAN", "PERKS_DESC_MARKSMAN", undefined, "specialty_marksman", 4);
    page shop_create_item("specialty_bulletpenetration", 2000, "PERKS_DEEP_IMPACT", "PERKS_DESC_DEEP_IMPACT", undefined, "specialty_bulletpenetration", 10);
    page shop_create_item("specialty_sharp_focus", 2000, "PERKS_SHARPFOCUS", "PERKS_DESC_SHARPFOCUS", undefined, "specialty_sharp_focus", 18);
    page shop_create_item("specialty_lightweight", 3000, "PERKS_LIGHTWEIGHT", "PERKS_DESC_LIGHTWEIGHT", undefined, "specialty_lightweight", 46);
    page shop_create_item("specialty_reducedsway", 2000, "PERKS_REDUCEDSWAY", "PERKS_DESC_REDUCEDSWAY", undefined, "specialty_reducedsway", 30);

    page = menu shop_create_page("shotgun_buff", "MENU_PROFICIENCY_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("specialty_marksman", 2000, "PERKS_MARKSMAN", "PERKS_DESC_MARKSMAN", undefined, "specialty_marksman", 4);
    page shop_create_item("specialty_sharp_focus", 2000, "PERKS_SHARPFOCUS", "PERKS_DESC_SHARPFOCUS", undefined, "specialty_sharp_focus", 18);
    page shop_create_item("specialty_fastermelee", 3000, "PERKS_FASTERMELEE", "PERKS_DESC_FASTERMELEE", undefined, "specialty_fastmeleerecovery", 42);
    page shop_create_item("specialty_longerrange", 2000, "PERKS_LONGERRANGE", "PERKS_DESC_LONGERRANGE", undefined, "specialty_longerrange", 36);
    page shop_create_item("specialty_moredamage", 2000, "PERKS_MOREDAMAGE", "PERKS_DESC_MOREDAMAGE", undefined, "specialty_moredamage", 50);

    page = menu shop_create_page("riot_buff", "MENU_PROFICIENCY_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("specialty_fastermelee", 3000, "PERKS_FASTERMELEE", "PERKS_DESC_FASTERMELEE", undefined, "specialty_fastmeleerecovery", 42);
    page shop_create_item("specialty_lightweight", 3000, "PERKS_LIGHTWEIGHT", "PERKS_DESC_LIGHTWEIGHT", undefined, "specialty_lightweight", 46);

    // Attachments
    page = menu shop_create_page("pistol_attach", "MENU_ATTACHMENT_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("silencer", 2000, "MPUI_SILENCER", "PERKS_INVISIBLE_ON_GPS_WHEN", "weapon_attachment_suppressor", undefined, 24);
    page shop_create_item("akimbo", 2000, "MPUI_AKIMBO", "PERKS_DESC_AKIMBO", "weapon_attachment_akimbo", undefined, 8);
    page shop_create_item("tactical", 1000, "MPUI_TACTICAL", "PERKS_DESC_TACTICAL", "weapon_attachment_tactical", undefined, 14);
    page shop_create_item("xmags", 3000, "MPUI_XMAGS", "PERKS_DESC_EXTENDEDMAGS", "weapon_attachment_xmags", undefined, 35);

    page = menu shop_create_page("shotgun_attach", "MENU_ATTACHMENT_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("grip", 2000, "MPUI_GRIP", "PERKS_VERTICAL_FOREGRIP_FOR", "weapon_attachment_grip", undefined, 18);
    page shop_create_item("silencer", 2000, "MPUI_SILENCER", "PERKS_INVISIBLE_ON_GPS_WHEN", "weapon_attachment_suppressor", undefined, 24);
    page shop_create_item("reflex", 1250, "MPUI_RED_DOT_SIGHT", "PERKS_REPLACE_THE_IRON_SIGHTS", "weapon_attachment_reflex", undefined, 7);
    page shop_create_item("eotech", 750, "MPUI_EOTECH", "PERKS_DESC_EOTECH", "weapon_attachment_eotech", undefined, 1);
    page shop_create_item("xmags", 3000, "MPUI_XMAGS", "PERKS_DESC_EXTENDEDMAGS", "weapon_attachment_xmags", undefined, 35);
    page shop_create_item("akimbo", 2000, "MPUI_AKIMBO", "PERKS_DESC_AKIMBO", "weapon_attachment_akimbo", undefined, 8);

    page = menu shop_create_page("machine_pistol_attach", "MENU_ATTACHMENT_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("silencer", 2000, "MPUI_SILENCER", "PERKS_INVISIBLE_ON_GPS_WHEN", "weapon_attachment_suppressor", undefined, 24);
    page shop_create_item("akimbo", 2000, "MPUI_AKIMBO", "PERKS_DESC_AKIMBO", "weapon_attachment_akimbo", undefined, 8);
    page shop_create_item("reflex", 1250, "MPUI_RED_DOT_SIGHT", "PERKS_REPLACE_THE_IRON_SIGHTS", "weapon_attachment_reflex", undefined, 7);
    page shop_create_item("eotech", 750, "MPUI_EOTECH", "PERKS_DESC_EOTECH", "weapon_attachment_eotech", undefined, 1);
    page shop_create_item("xmags", 3000, "MPUI_XMAGS", "PERKS_DESC_EXTENDEDMAGS", "weapon_attachment_xmags", undefined, 35);

    page = menu shop_create_page("smg_attach", "MENU_ATTACHMENT_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("reflex", 1250, "MPUI_RED_DOT_SIGHT", "PERKS_REPLACE_THE_IRON_SIGHTS", "weapon_attachment_reflex", undefined, 7);
    page shop_create_item("silencer", 2000, "MPUI_SILENCER", "PERKS_INVISIBLE_ON_GPS_WHEN", "weapon_attachment_suppressor", undefined, 24);
    page shop_create_item("rof", 3000, "MPUI_ROF", "PERKS_DESC_ROF", "weapon_attachment_rof", undefined, 44);
    page shop_create_item("acog", 1500, "MPUI_ACOG_SCOPE", "PERKS_ENHANCED_ZOOM_ACOG_SCOPE", "weapon_attachment_acog", undefined, 30);
    page shop_create_item("eotech", 750, "MPUI_EOTECH", "PERKS_DESC_EOTECH", "weapon_attachment_eotech", undefined, 1);
    page shop_create_item("hamrhybrid", 1700, "MPUI_HAMRHYBRID", "PERKS_HAMRHYBRID", "weapon_attachment_hamrhybrid", undefined, 38);
    page shop_create_item("xmags", 3000, "MPUI_XMAGS", "PERKS_DESC_EXTENDEDMAGS", "weapon_attachment_xmags", undefined, 35);
    page shop_create_item("thermal", 2000, "MPUI_THERMAL", "PERKS_DESC_THERMAL", "weapon_attachment_thermal", undefined, 45);
    page shop_create_item("akimbo", 2000, "MPUI_AKIMBO", "PERKS_DESC_AKIMBO", "weapon_attachment_akimbo", undefined, 8);

    page = menu shop_create_page("assault_attach", "MENU_ATTACHMENT_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("reflex", 1250, "MPUI_RED_DOT_SIGHT", "PERKS_REPLACE_THE_IRON_SIGHTS", "weapon_attachment_reflex", undefined, 7);
    page shop_create_item("silencer", 2000, "MPUI_SILENCER", "PERKS_INVISIBLE_ON_GPS_WHEN", "weapon_attachment_suppressor", undefined, 24);
    page shop_create_item("gl", 2000, "MPUI_GRENADE_LAUNCHER", "PERKS_GRENADE_LAUNCHER_ATTACHMENT2", "weapon_attachment_m203", undefined, 28);
    page shop_create_item("acog", 1500, "MPUI_ACOG_SCOPE", "PERKS_ENHANCED_ZOOM_ACOG_SCOPE", "weapon_attachment_acog", undefined, 30);
    page shop_create_item("rof", 3000, "MPUI_ROF", "PERKS_DESC_ROF", "weapon_attachment_rof", undefined, 44);
    page shop_create_item("heartbeat", 1500, "MPUI_HEARTBEAT", "PERKS_DESC_HEARTBEAT", "weapon_attachment_heartbeat", undefined, 47);
    page shop_create_item("eotech", 750, "MPUI_EOTECH", "PERKS_DESC_EOTECH", "weapon_attachment_eotech", undefined, 1);
    page shop_create_item("shotgun", 1000, "MPUI_SHOTGUN", "PERKS_DESC_SHOTGUN", "weapon_attachment_shotgun", undefined, 40);
    page shop_create_item("hybrid", 1700, "MPUI_HYBRID", "PERKS_HYBRID", "weapon_attachment_hybrid", undefined, 38);
    page shop_create_item("xmags", 3000, "MPUI_XMAGS", "PERKS_DESC_EXTENDEDMAGS", "weapon_attachment_xmags", undefined, 35);
    page shop_create_item("thermal", 2000, "MPUI_THERMAL", "PERKS_DESC_THERMAL", "weapon_attachment_thermal", undefined, 45);

    page = menu shop_create_page("lmg_attach", "MENU_ATTACHMENT_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("reflex", 1250, "MPUI_RED_DOT_SIGHT", "PERKS_REPLACE_THE_IRON_SIGHTS", "weapon_attachment_reflex", undefined, 7);
    page shop_create_item("silencer", 2000, "MPUI_SILENCER", "PERKS_INVISIBLE_ON_GPS_WHEN", "weapon_attachment_suppressor", undefined, 24);
    page shop_create_item("grip", 2000, "MPUI_GRIP", "PERKS_VERTICAL_FOREGRIP_FOR", "weapon_attachment_grip", undefined, 18);
    page shop_create_item("acog", 1500, "MPUI_ACOG_SCOPE", "PERKS_ENHANCED_ZOOM_ACOG_SCOPE", "weapon_attachment_acog", undefined, 30);
    page shop_create_item("rof", 3000, "MPUI_ROF", "PERKS_DESC_ROF", "weapon_attachment_rof", undefined, 44);
    page shop_create_item("heartbeat", 1500, "MPUI_HEARTBEAT", "PERKS_DESC_HEARTBEAT", "weapon_attachment_heartbeat", undefined, 47);
    page shop_create_item("eotech", 750, "MPUI_EOTECH", "PERKS_DESC_EOTECH", "weapon_attachment_eotech", undefined, 1);
    page shop_create_item("xmags", 3000, "MPUI_XMAGS", "PERKS_DESC_EXTENDEDMAGS", "weapon_attachment_xmags", undefined, 35);
    page shop_create_item("thermal", 2000, "MPUI_THERMAL", "PERKS_DESC_THERMAL", "weapon_attachment_thermal", undefined, 45);

    page = menu shop_create_page("sniper_attach", "MENU_ATTACHMENT_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("acog", 1500, "MPUI_ACOG_SCOPE", "PERKS_ENHANCED_ZOOM_ACOG_SCOPE", "weapon_attachment_acog", undefined, 30);
    page shop_create_item("silencer", 2000, "MPUI_SILENCER", "PERKS_INVISIBLE_ON_GPS_WHEN", "weapon_attachment_suppressor", undefined, 24);
    page shop_create_item("heartbeat", 1500, "MPUI_HEARTBEAT", "PERKS_DESC_HEARTBEAT", "weapon_attachment_heartbeat", undefined, 47);
    page shop_create_item("xmags", 3000, "MPUI_XMAGS", "PERKS_DESC_EXTENDEDMAGS", "weapon_attachment_xmags", undefined, 35);
    page shop_create_item("thermal", 2000, "MPUI_THERMAL", "PERKS_DESC_THERMAL", "weapon_attachment_thermal", undefined, 45);
    page shop_create_item("vzscope", 1000, "MPUI_VZSCOPE", "PERKS_DESC_VARIABLE_ZOOM_SCOPE", "weapon_attachment_zoomscope", undefined, 20);

    // Camouflages
    page = menu shop_create_page("weapon_camo", "MENU_CAMO_CAPS", "SO_SURVIVAL_ARMORY_WEAPON_DESC");
    page shop_create_item("classic", 500, "MPUI_CLASSIC", "PERKS_CLASSIC", "ui_camoskin_classic");
    page shop_create_item("snow", 500, "MPUI_SNOW", "PERKS_SNOW", "ui_camoskin_snow");
    page shop_create_item("multi", 500, "MPUI_MULTI", "PERKS_MULTI", "ui_camoskin_multi");
    page shop_create_item("d_urban", 500, "MPUI_D_URBAN", "PERKS_D_URBAN", "ui_camoskin_d_urban");
    page shop_create_item("hex", 500, "MPUI_HEX", "PERKS_HEX", "ui_camoskin_hex");
    page shop_create_item("choco", 500, "MPUI_CHOCO", "PERKS_CHOCO", "ui_camoskin_choco");
    page shop_create_item("snake", 500, "MPUI_SNAKE", "PERKS_SNAKE", "ui_camoskin_snake");
    page shop_create_item("blue", 500, "MPUI_BLUE", "PERKS_BLUE", "ui_camoskin_blue");
    page shop_create_item("red", 500, "MPUI_RED", "PERKS_RED", "ui_camoskin_red");
    page shop_create_item("autumn", 500, "MPUI_AUTUMN", "PERKS_AUTUMN", "ui_camoskin_autumn");
    page shop_create_item("gold", 1000, "MPUI_GOLD", "PERKS_GOLD", "ui_camoskin_gold");
}

init_equipment_armory()
{
    menu = shop_create_menu("equipment_armory");

    page = menu shop_create_page("equipment_armory", "SO_SURVIVAL_ARMORY_EQUIPMENT", "SO_SURVIVAL_ARMORY_EQUIPMENT_DESC");
    page shop_create_item("frag_grenade_mp", 750, "SO_SURVIVAL_EQUIPMENT_FRAG_REFILL", "SO_SURVIVAL_EQUIPMENT_FRAG_REFILL_DESC", undefined, "equipment_frag", 1);
    page shop_create_item("flash_grenade_mp", 750, "SO_SURVIVAL_EQUIPMENT_FLASH_REFILL", "SO_SURVIVAL_EQUIPMENT_FLASH_REFILL_DESC", undefined, "equipment_flash_grenade", 1);
    page shop_create_item("throwingknife_mp", 1000, "SO_SURVIVAL_EQUIPMENT_KNIFETHROW_REFILL", "SO_SURVIVAL_EQUIPMENT_KNIFETHROW_REFILL_DESC", undefined, "equipment_throwing_knife", 4);
    page shop_create_item("concussion_grenade_mp", 1000, "SO_SURVIVAL_EQUIPMENT_CONCUSSION_REFILL", "SO_SURVIVAL_EQUIPMENT_CONCUSSION_REFILL_DESC", undefined, "equipment_concussion_grenade", 6);
    page shop_create_item("claymore_mp", 1500, "SO_SURVIVAL_EQUIPMENT_CLAYMORE", "PERKS_DIRECTIONAL_ANTIPERSONNEL", undefined, "equipment_claymore", 2);
    page shop_create_item("c4_mp", 1500, "SO_SURVIVAL_EQUIPMENT_C4", "PERKS_CHARGE_OF_PLASTIC_EXPLOSIVES", undefined, "equipment_c4", 5);
    page shop_create_item("body_armor", 2000, "SO_SURVIVAL_EQUIPMENT_BODYARMOR", "SO_SURVIVAL_EQUIPMENT_BODYARMOR_DESC", undefined, "equipment_body_armor", 9);
    page shop_create_item("self_revive", 3000, "SO_SURVIVAL_EQUIPMENT_LASTSTAND", "SO_SURVIVAL_EQUIPMENT_LASTSTAND_DESC", undefined, "specialty_self_revive", 12);
}

init_air_support_armory()
{
    menu = shop_create_menu("air_support_armory");

    // Main Page
    page = menu shop_create_page("air_support_armory", "SO_SURVIVAL_ARMORY_AIRSUPPORT", "SO_SURVIVAL_ARMORY_AIRSUPPORT_DESC");
    page shop_create_item("perks", undefined, "SO_SURVIVAL_ARMORY_PERKS", "SO_SURVIVAL_ARMORY_PERKS_DESC", undefined, "dpad_killstreak_carepackage_static_frontend");
    page shop_create_item("predator_missile", 2500, "KILLSTREAKS_PREDATOR_MISSILE", "SO_SURVIVAL_AIRSUPPORT_PREDATOR_DESC", undefined, "dpad_killstreak_predator_missile_static_frontend", 1);
    page shop_create_item("precision_airstrike", 4000, "KILLSTREAKS_AIRSTRIKE", "SO_SURVIVAL_AIRSUPPORT_AIRSTRIKE_DESC", undefined, "dpad_killstreak_precision_airstrike_static_frontend", 3);
    page shop_create_item("minigun_turret", 3000, "KILLSTREAKS_MINIGUN_TURRET", "SO_SURVIVAL_EQUIPMENT_SENTRY_DESC", undefined, "equipment_sentry_gun", 16);
    page shop_create_item("gl_turret", 4000, "KILLSTREAKS_GL_TURRET", "SO_SURVIVAL_EQUIPMENT_SENTRY_GL_DESC", undefined, "equipment_grenade_launcher", 30);
    page shop_create_item("remove_perks", undefined, "SO_SURVIVAL_REMOVE_PERKS", "SO_SURVIVAL_REMOVE_PERKS_DESC");

    // Perks Care Package
    page = menu shop_create_page("perks_care_package", "SO_SURVIVAL_ARMORY_PERKS", "SO_SURVIVAL_ARMORY_AIRSUPPORT_DESC");
    page shop_create_item("specialty_quickdraw_ks", 3000, "PERKS_QUICKDRAW", "PERKS_DESC_QUICKDRAW", undefined, "specialty_quickdraw", 4);
    page shop_create_item("specialty_bulletaccuracy_ks", 3000, "PERKS_STEADY_AIM", "PERKS_DESC_STEADY_AIM", undefined, "specialty_steadyaim", 7);
    page shop_create_item("specialty_stalker_ks", 3000, "PERKS_STALKER", "PERKS_DESC_STALKER", undefined, "specialty_stalker", 21);
    page shop_create_item("specialty_longersprint_ks", 3000, "PERKS_LONGERSPRINT", "PERKS_DESC_LONGERSPRINT", undefined, "specialty_longersprint", 35);
    page shop_create_item("specialty_fastreload_ks", 3000, "PERKS_SLEIGHT_OF_HAND", "PERKS_DESC_SLEIGHT_OF_HAND", undefined, "specialty_fastreload", 49);
    page shop_create_item("_specialty_blastshield_ks", 3000, "PERKS_BLASTSHIELD", "PERKS_DESC_BLASTSHIELD", undefined, "specialty_blastshield", 14);
    page shop_create_item("specialty_blindeye_ks", 3000, "PERKS_BLINDEYE", "PERKS_DESC_BLINDEYE", undefined, "specialty_blindeye", 25);
    page shop_create_item("specialty_detectexplosive_ks", 3000, "PERKS_SITREP", "PERKS_DESC_SITREP", undefined, "specialty_bombsquad", 44);
    page shop_create_item("specialty_scavenger_ks", 3000, "PERKS_SCAVENGER", "PERKS_DESC_SCAVENGER", undefined, "specialty_scavenger", 40);
}

//////////////////////////////////////////
//	            MENU LOGIC              //
//////////////////////////////////////////

onOpenPage(menu)
{
    if (menu == "weapon_armory")
    {
        self shopInit(WEAPON_ARMORY);
        self.shop lethalbeats\survival\armories\weapons::onInit();
        return;
    }

    if (menu == "equipment_armory")
    {
        self shopInit(WEAPON_EQUIPMENT);
        return;
    }

    if (menu == "air_support_armory")
    {
        self shopInit(WEAPON_AIR_SUPPORT);
        self.shop lethalbeats\survival\armories\air_support::onInit();
        return;
    }

    if (!isDefined(self.shop.menu)) return;

    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            self.shop lethalbeats\survival\armories\weapons::onOpenPage(menu);
            break;
        case WEAPON_AIR_SUPPORT:
            self.shop lethalbeats\survival\armories\air_support::onOpenPage(menu);
            break;
    }
}

onSelectOption(page, item, price, option_type, index)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            self.shop lethalbeats\survival\armories\weapons::onSelectOption(page, item, price, option_type, index);
            break;
        case WEAPON_EQUIPMENT:
            self lethalbeats\survival\armories\equipment::onBuy(item, price, index);
            break;
        case WEAPON_AIR_SUPPORT:
            self.shop lethalbeats\survival\armories\air_support::onSelectOption(page, item, price, option_type, index);
            break;
    }
}

onUpdateOption(index, item, option_label, price_label)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            self.shop lethalbeats\survival\armories\weapons::onUpdateOption(index, item, option_label, price_label);
            break;
        case WEAPON_EQUIPMENT:
            self updateOption(index, item, option_label, price_label);
            break;
        case WEAPON_AIR_SUPPORT:
            self.shop lethalbeats\survival\armories\air_support::onUpdateOption(index, item, option_label, price_label);
            break;
    }
}

isOwnedOption(page, item, index)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            return self.shop lethalbeats\survival\armories\weapons::isOwnedOption(item);
        case WEAPON_EQUIPMENT:
            return self lethalbeats\survival\armories\equipment::isOwnedOption(item, index);
        case WEAPON_AIR_SUPPORT:
            return self.shop lethalbeats\survival\armories\air_support::isOwnedOption(item);
        default:
            return false;
    }
}

isDisabledOption(page, item, index)
{
    if (!isLevelUnlockedOption(page, index, self)) return true;
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            return self.shop lethalbeats\survival\armories\weapons::isDisabledOption(item, index);
        case WEAPON_AIR_SUPPORT:
            return self.shop lethalbeats\survival\armories\air_support::isDisabledOption(item, index);
        default:
            return false;
    }
}

isUpgradeOption(page, item, index)
{
    switch(self.shop.menu)
    {
        case WEAPON_ARMORY:
            return self.shop lethalbeats\survival\armories\weapons::isUpgradeOption(item);
        default:
            return false;
    }
}

isLevelUnlockedOption(page, index, player)
{
    if (getDvarInt("survival_casual")) return true;
    if (!isDefined(level.dynamicShopPages) || !isDefined(level.dynamicShopPages[page])) return true;

    pageData = level.dynamicShopPages[page];
    itemData = pageData[PAGE_ITEMS][index];
    if (!isDefined(itemData) || !isDefined(itemData[ITEM_UNLOCK_LEVEL])) return true;

    req_lvl = itemData[ITEM_UNLOCK_LEVEL];
    player_lvl = isDefined(player.survival_level) ? player.survival_level : 1;
    return (player_lvl >= req_lvl);
}

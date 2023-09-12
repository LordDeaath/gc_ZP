#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <reapi>

new const PLUGIN_VERSION[] = "1.1";

/****************************************************************************************
****************************************************************************************/

new const g_szNewModel[] = "models/wmg_default_v2.mdl";

/****************************************************************************************
****************************************************************************************/

const SHIELD_SUBMODEL = 28;
const C4_SUBMODEL = 31;
const THIGHPACK_SUBMODEL = 32;

new const g_szSubModels[][] =
{
	// Pistol
	"models/w_glock18.mdl",
	"models/w_usp.mdl",
	"models/w_deagle.mdl",
	"models/w_elite.mdl",
	"models/w_p228.mdl",
	"models/w_fiveseven.mdl",

	// Shotgun
	"models/w_m3.mdl",
	"models/w_xm1014.mdl",

	// Submachine gun
	"models/w_mac10.mdl",
	"models/w_tmp.mdl",
	"models/w_mp5.mdl",
	"models/w_ump45.mdl",
	"models/w_p90.mdl",

	// Assault Rifle
	"models/w_famas.mdl",
	"models/w_galil.mdl",
	"models/w_m4a1.mdl",
	"models/w_ak47.mdl",
	"models/w_aug.mdl",
	"models/w_sg552.mdl",

	// Sniper Rifle
	"models/w_awp.mdl",
	"models/w_sg550.mdl",
	"models/w_g3sg1.mdl",
	"models/w_scout.mdl",

	// Machine gun
	"models/w_m249.mdl",

	// Grenades
	"models/w_hegrenade.mdl",
	"models/w_flashbang.mdl",
	"models/w_smokegrenade.mdl",

	// Other
	"models/w_backpack.mdl"
};

new Trie:g_tSubModels;

new const g_iSubModels[] =
{
	0, // WEAPON_NONE
	5, // WEAPON_P228
	0, // WEAPON_GLOCK
	23, // WEAPON_SCOUT
	25, // WEAPON_HEGRENADE
	8, // WEAPON_XM1014
	30, // WEAPON_C4
	9, // WEAPON_MAC10
	18, // WEAPON_AUG
	27, // WEAPON_SMOKEGRENADE
	4, // WEAPON_ELITE
	6, // WEAPON_FIVESEVEN
	12, // WEAPON_UMP45
	21, // WEAPON_SG550
	15, // WEAPON_GALIL
	14, // WEAPON_FAMAS
	2, // WEAPON_USP
	1, // WEAPON_GLOCK18
	20, // WEAPON_AWP
	11, // WEAPON_MP5N
	24, // WEAPON_M249
	7, // WEAPON_M3
	16, // WEAPON_M4A1
	10, // WEAPON_TMP
	22, // WEAPON_G3SG1
	26, // WEAPON_FLASHBANG
	3, // WEAPON_DEAGLE
	19, // WEAPON_SG552
	17, // WEAPON_AK47
	0, // WEAPON_KNIFE
	13 // WEAPON_P90
};

new const g_iArmourySubModels[] =
{
	11, // ARMOURY_MP5NAVY
	10, // ARMOURY_TMP
	13, // ARMOURY_P90
	9, // ARMOURY_MAC10
	17, // ARMOURY_AK47
	19, // ARMOURY_SG552
	16, // ARMOURY_M4A1
	18, // ARMOURY_AUG
	23, // ARMOURY_SCOUT
	22, // ARMOURY_G3SG1
	20, // ARMOURY_AWP
	7, // ARMOURY_M3
	8, // ARMOURY_XM1014
	24, // ARMOURY_M249
	26, // ARMOURY_FLASHBANG
	25, // ARMOURY_HEGRENADE
	29, // ARMOURY_KEVLAR
	29, // ARMOURY_ASSAULT
	27, // ARMOURY_SMOKEGRENADE
	SHIELD_SUBMODEL, // ARMOURY_SHIELD
	14, // ARMOURY_FAMAS
	21, // ARMOURY_SG550
	15, // ARMOURY_GALIL
	12, // ARMOURY_UMP45
	1, // ARMOURY_GLOCK18
	2, // ARMOURY_USP
	4, // ARMOURY_ELITE
	6, // ARMOURY_FIVESEVEN
	5, // ARMOURY_P228
	3, // ARMOURY_DEAGLE
};

public plugin_init()
{
	register_plugin("World Model Group", PLUGIN_VERSION, "w0w");

	RegisterHookChain(RG_CWeaponBox_SetModel, "refwd_WeaponBox_SetModel_Pre", false);
	RegisterHookChain(RG_CBasePlayer_ThrowGrenade, "refwd_Player_ThrowGrenade_Post", true);
	RegisterHookChain(RG_CBasePlayer_DropShield, "refwd_Player_DropShield_Post", true);
	RegisterHookChain(RG_PlantBomb, "refwd_PlantBomb_Post", true);
	RegisterHam(Ham_Spawn, "item_thighpack", "hamfwd_Spawn_ThighPack_Post", true, true);

	g_tSubModels = TrieCreate();

	for(new i; i < sizeof g_szSubModels; i++)
		TrieSetCell(g_tSubModels, g_szSubModels[i], 0);

	new iEnt = NULLENT;

	while((iEnt = rg_find_ent_by_class(iEnt, "armoury_entity", true)))
	{
        new iArmouryItem = get_member(iEnt, m_Armoury_iItem);
        func_SetModel(iEnt, g_iArmourySubModels[iArmouryItem]);
	}
}

public plugin_precache()
{
	precache_model(g_szNewModel);
}

public refwd_WeaponBox_SetModel_Pre(const iEnt, const szModelName[])
{
	if(!TrieKeyExists(g_tSubModels, szModelName))
		return HC_CONTINUE;

	new iWeaponId = any:rg_get_weaponbox_id(iEnt);

	if(!iWeaponId)
		return HC_CONTINUE;

	SetHookChainArg(2, ATYPE_STRING, g_szNewModel);
	set_entvar(iEnt, var_body, g_iSubModels[iWeaponId]);

	return HC_CONTINUE;
}

public refwd_Player_ThrowGrenade_Post(const id, const iGrenade, Float:flVecSrc[3], Float:flVecThrow[3], Float:flTime, const iEvent)
{
	new iEnt = GetHookChainReturn(ATYPE_INTEGER);

	if(is_nullent(iEnt))
		return;

	new iGrenadeId = get_member(iGrenade, m_iId);

	func_SetModel(iEnt, g_iSubModels[iGrenadeId]);
}

public refwd_Player_DropShield_Post(const id, bool:bDeploy)
{
	new iEnt = GetHookChainReturn(ATYPE_INTEGER);
	func_SetModel(iEnt, SHIELD_SUBMODEL);
}

public refwd_PlantBomb_Post(const id, Float:flVecStart[3], Float:flVecVelocity[3])
{
	new iEnt = GetHookChainReturn(ATYPE_INTEGER);
	func_SetModel(iEnt, C4_SUBMODEL);
}

public hamfwd_Spawn_ThighPack_Post(const iEnt)
{
	func_SetModel(iEnt, THIGHPACK_SUBMODEL);
}

func_SetModel(iEnt, iSubModel)
{
	entity_set_model(iEnt, g_szNewModel);
	set_entvar(iEnt, var_body, iSubModel);
}
#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <zp50_items>

#define PLUGIN "[ZP] Frost"
#define VERSION "1.4"
#define AUTHOR "alan_el_more"

new g_pack_grenades
new const g_cost = 5 // Cost of pack

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	g_pack_grenades = zp_items_register("Napalm", "[Burn Zombies]", g_cost, 0, 0)
}
public zp_fw_items_select_pre(id, it, cost)
{
	if (it != g_pack_grenades)
		return ZP_ITEM_AVAILABLE
	if(zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW;
	return ZP_ITEM_AVAILABLE
}
public zp_fw_items_select_post(id, it, cost)
{
	if (it != g_pack_grenades)
		return
	if(user_has_weapon(id, CSW_HEGRENADE))
	{
		static frost
		frost = cs_get_user_bpammo(id, CSW_HEGRENADE)
		cs_set_user_bpammo(id, CSW_HEGRENADE, frost + 1)
	}
	else
		give_item(id, "weapon_hegrenade")
}
/*
public zp_extra_item_selected(player, itemid)
{
	if (itemid == g_pack_grenades)
	{
		if (get_pcvar_num(g_enabled)) {
			if(user_has_weapon(player, CSW_HEGRENADE))
			{
				static napalm
				napalm = cs_get_user_bpammo(player, CSW_HEGRENADE)
				cs_set_user_bpammo(player, CSW_HEGRENADE, napalm + 1)
			}
			else
			{
				fm_give_item(player, "weapon_hegrenade")
			}
			

			
			if(user_has_weapon(player, CSW_SMOKEGRENADE))
			{
				static flare
				flare = cs_get_user_bpammo(player, CSW_SMOKEGRENADE)
				cs_set_user_bpammo(player, CSW_SMOKEGRENADE, flare + 1)
			}
			else
			{
				fm_give_item(player, "weapon_smokegrenade")
			}
			
			client_print(player, print_chat, "[ZP] You have bought a pack of grenades.")
		}
		else
		{
			static ammopacks
			ammopacks = zp_get_user_ammo_packs(player)
			zp_set_user_ammo_packs(player, ammopacks + g_cost)
		}
	}
}

stock fm_give_item(id, const item[])
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if (!pev_valid(ent)) return;
	
	static Float:originF[3]
	pev(id, pev_origin, originF)
	set_pev(ent, pev_origin, originF)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)
	
	static save
	save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, id)
	if (pev(ent, pev_solid) != save)
		return;
	
	engfunc(EngFunc_RemoveEntity, ent)
}
*/
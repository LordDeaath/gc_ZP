#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zp50_core>
#include <zp50_items>
#include <xs>
#include <colorchat>
new g_norecoil[33]
new Float: cl_pushangle[33][3]
new g_itemid_norecoil, g_maxplayers

const WEAPONS_BITSUM = (1<<CSW_KNIFE|1<<CSW_HEGRENADE|1<<CSW_FLASHBANG|1<<CSW_SMOKEGRENADE|1<<CSW_C4)

public plugin_init()
{
	register_plugin("[ZP] Extra Item: No Recoil", "0.1.0", "CarsonMotion")

	g_itemid_norecoil = zp_items_register("No Recoil","[No Bullet Spread]", 20, 1,1)

	new weapon_name[24]
	for (new i = 1; i <= 30; i++)
	{
		if (!(WEAPONS_BITSUM & 1 << i) && get_weaponname(i, weapon_name, 23))
		{
			RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "fw_Weapon_PrimaryAttack_Pre")
			RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "fw_Weapon_PrimaryAttack_Post", 1)
		}
	}

	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")

	g_maxplayers = get_maxplayers()
}
public zp_fw_items_select_pre(id, it)
{
	if(it != g_itemid_norecoil)
		return ZP_ITEM_AVAILABLE;
	
	if(zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW;
	
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(player, it)
{
	if (it != g_itemid_norecoil)
		return;
	g_norecoil[player] = true
	ColorChat(player, GREEN, "[ZP]^3 You have bought No Recoil for your weapon!")
}

public zp_fw_core_infect_post(id)
	g_norecoil[id] = false
public zp_fw_core_cure_post(id)
	g_norecoil[id] = false
public client_connect(id)
	g_norecoil[id] = false
public client_disconnect(id)
	g_norecoil[id] = false
public event_round_start()
	for (new id = 1; id <= g_maxplayers; id++)
		g_norecoil[id] = false

public fw_Weapon_PrimaryAttack_Pre(entity)
{
	new id = pev(entity, pev_owner)

	if (g_norecoil[id])
	{
		pev(id, pev_punchangle, cl_pushangle[id])
		return HAM_IGNORED;
	}
	return HAM_IGNORED;
}

public fw_Weapon_PrimaryAttack_Post(entity)
{
	new id = pev(entity, pev_owner)

	if (g_norecoil[id])
	{
		new Float: push[3]
		pev(id, pev_punchangle, push)
		xs_vec_sub(push, cl_pushangle[id], push)
		xs_vec_mul_scalar(push, 0.0, push)
		xs_vec_add(push, cl_pushangle[id], push)
		set_pev(id, pev_punchangle, push)
		return HAM_IGNORED;
	}
	return HAM_IGNORED;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1252\\ deff0\\ deflang1033{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/
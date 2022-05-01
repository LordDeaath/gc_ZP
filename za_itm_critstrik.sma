#include <amxmodx>
#include <fun>
#include <zp50_items>
#include <za_items>
#include <hamsandwich>
#include <engine>

#define _PLUGIN        "ZA: Stealth"
#define _VERSION              "1.0"
#define _AUTHOR            "Lord. D."

//Cvars.
new Itm_Jump, HasInv[33], rng
public plugin_init()
{
	register_plugin( _PLUGIN, _VERSION, _AUTHOR )
	
	RegisterHam(Ham_TakeDamage, "player", "FwdTakeDamage")
	
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0") 
	
	Itm_Jump = za_items_register("Critical Strike", "[25% Chance To Critical Damage]", 20, 0, 0)
}

public zp_fw_core_infect_post(id)
{
	if (is_user_alive(id))
		HasInv[id] = 0   
}

public event_new_round()
{
	for(new id; id < get_maxplayers();id++)
		if (is_user_alive(id))
			HasInv[id] = 0 
}

public za_fw_items_select_pre(id, it,cost)
{
	if(it != Itm_Jump)
		return ZP_ITEM_AVAILABLE
		
	if(zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW
		
	if(HasInv[id])
		return ZP_ITEM_NOT_AVAILABLE
		
	return ZP_ITEM_AVAILABLE
}
public za_fw_items_select_post(id, it, cost)
{
	if(it != Itm_Jump)
		return
		
	HasInv[id]++
}

public FwdTakeDamage(victim, inflictor, attacker, Float:damage, damage_bits)
{
	if(!is_user_alive(attacker))
		return HAM_IGNORED
		
	if(!is_user_alive(victim))
		return	HAM_IGNORED
		
	if (!HasInv[attacker] || (attacker == victim) || !(damage_bits&DMG_BULLET) )
		return HAM_IGNORED
	
	rng = random_num(1,60)
	
	switch(rng)
	{
		case 1,60:
		{
			SetHamParamFloat(4, damage * 1.5)
			set_hudmessage(255, 255, 255, -1.0, 0.42)
			show_hudmessage(attacker, "[Critical Strike]")
		}
		case 10,50:
		{
			SetHamParamFloat(4, damage * 1.75)
			set_hudmessage(0, 0, 255, -1.0, 0.42)
			show_hudmessage(attacker, "[Critical Strike]")
		}
		case 20,40:
		{
			SetHamParamFloat(4, damage * 2.0)
			set_hudmessage(0, 255, 0, -1.0, 0.42)
			show_hudmessage(attacker, "[Critical Strike]")
		}
		case 30:
		{
			SetHamParamFloat(4, damage * 3.0)
			set_hudmessage(255, 0, 0, -1.0, 0.42)
			show_hudmessage(attacker, "[Critical Strike]")
		}
	}
	return HAM_IGNORED
}
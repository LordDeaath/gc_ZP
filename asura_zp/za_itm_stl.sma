#include < amxmodx >
#include < fun >
#include < fakemeta >
#include <za_items>
#include <hamsandwich>

#define _PLUGIN        "ZA: Stealth"
#define _VERSION              "1.0"
#define _AUTHOR            "Lord. D."

//Cvars.
new Itm_Jump, HasInv[33]
native zp_set_human_glow(id, bool:on)
public plugin_init() {
	
	register_plugin( _PLUGIN, _VERSION, _AUTHOR )
	
	Itm_Jump = za_items_register("Stealth", "[75% Invisible]", 10, 0, 0)
	RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1) 
	
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0") 

}
public fwHamPlayerSpawnPost(id)
{
	if (is_user_alive(id))
		HasInv[id] = 0   
}
public zp_fw_core_infect_post(id)
{
	HasInv[id] = 0
	set_user_rendering(id)
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
	
	zp_set_human_glow(id, false)
	set_user_rendering(id, kRenderFxNone, 75,75,75, kRenderTransTexture, 35)
	HasInv[id]++
}
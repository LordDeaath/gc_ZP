#include <amxmodx>
#include <fun>
#include <za_items>

#define _PLUGIN        "ZA: Stealth"
#define _VERSION              "1.0"
#define _AUTHOR            "Lord. D."

//Cvars.
new Itm_Jump, HasInv[33]
public plugin_init() {
	
	register_plugin( _PLUGIN, _VERSION, _AUTHOR )
	
	Itm_Jump = za_items_register("200 Armor", "[Free Armor]", 0, 0, 0)
	
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0") 

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
		
	if(HasInv[id])
		return ZP_ITEM_NOT_AVAILABLE
		
	return ZP_ITEM_AVAILABLE
}
public za_fw_items_select_post(id, it, cost)
{
	if(it != Itm_Jump)
		return
	
	set_user_armor(id, 200)
	HasInv[id]++
}
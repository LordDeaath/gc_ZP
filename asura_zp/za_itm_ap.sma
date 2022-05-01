#include <amxmodx>
#include <fun>
#include <za_items>
#include <zp50_ammopacks>

#define _PLUGIN        "ZA: Itm AP"
#define _VERSION              "1.0"
#define _AUTHOR            "Lord. D."

//Cvars.
new Itm_Jump, HasInv[33]
public plugin_init()
{
	register_plugin( _PLUGIN, _VERSION, _AUTHOR )
	
	Itm_Jump = za_items_register("100 AP", "[1 Time/Map]", 0, 0, 0)
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
	zp_ammopacks_set(id, zp_ammopacks_get(id) + 100)
	HasInv[id]++
}
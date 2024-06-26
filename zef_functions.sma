/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <zp50_items>

#define PLUGIN "ZE Functions"
#define VERSION "1.0"
#define AUTHOR "Administrator"


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	new iMap[32]
	get_mapname(iMap, charsmax(iMap))
	if(!equali(iMap, "zm_osprey_escape"))
	{
		server_cmd("mp_unduck_method 0")
		server_cmd("amx_autounstuck 1")
		server_cmd("zp_knockback_damage 0")
		server_cmd("zp_knockback_zvel 0")	
		server_cmd("zp_deathmatch 0")			
		pause("ad");
		return;
	}
	server_cmd("mp_unduck_method 1")
	server_cmd("amx_autounstuck 0")
	server_cmd("zp_knockback_damage 1")
	server_cmd("zp_knockback_zvel 1")
	server_cmd("zp_deathmatch 2")				
}

public zp_fw_items_select_pre(id, it,c)
{	
	if( it == zp_items_get_id("Blind Bomb (Blind enemies)") )
	{
		zp_items_menu_text_add("\r[Escape]")
		return ZP_ITEM_NOT_AVAILABLE
	}
	
	if( it == zp_items_get_id("Infection Bomb") )
	{
		zp_items_menu_text_add("\r[Escape]")
		return ZP_ITEM_NOT_AVAILABLE
	}

	if( it == zp_items_get_id("Infection Bomb") )
	{
		zp_items_menu_text_add("\r[Escape]")
		return ZP_ITEM_NOT_AVAILABLE
	}
	
	if( it == zp_items_get_id("Sandbags") )
	{
		zp_items_menu_text_add("\r[Escape]")
		return ZP_ITEM_NOT_AVAILABLE
	}
	
	if( it == zp_items_get_id("Laser Mine") )
	{
		zp_items_menu_text_add("\r[Escape]")
		return ZP_ITEM_NOT_AVAILABLE
	}
	if( it == zp_items_get_id("T-Virus") )
	{
		zp_items_menu_text_add("\r[Escape]")
		return ZP_ITEM_NOT_AVAILABLE
	}
	if( it == zp_items_get_id("Zombie Madness") )
	{
		zp_items_menu_text_add("\r[Escape]")
		return ZP_ITEM_NOT_AVAILABLE
	}
	return ZP_ITEM_AVAILABLE
}
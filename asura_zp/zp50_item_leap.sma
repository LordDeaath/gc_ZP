/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <zp50_items>
#include <zp50_class_sniper>
#include <zp50_class_survivor>
#include <zp50_gamemodes>
#include <cs_maxspeed_api>

#include <fun>

#define PLUGIN "Extra Item: Armor"
#define VERSION "1.0"
#define AUTHOR "Lord. Death."
new Item_Leap
native set_leap(id,num)
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	Item_Leap = zp_items_register("Speed","[25% Increase]",25,0,0)
}

public zp_fw_items_select_pre(id, item, ignorecost)
{
	if(item != Item_Leap)
	return ZP_ITEM_AVAILABLE

	if(zp_core_is_zombie(id) || zp_class_sniper_get(id) || zp_class_survivor_get(id))
	return ZP_ITEM_DONT_SHOW

	return ZP_ITEM_AVAILABLE
}

public zp_fw_items_select_post(id, item, ignorecost)
{
	if(item != Item_Leap)
	return;

	cs_set_player_maxspeed_auto(id, 1.25)

}
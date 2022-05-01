/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <zp50_items>
#include <zmvip>

#define PLUGIN "New Plug-In"
#define VERSION "1.0"
#define AUTHOR "Administrator"

new ItmVIP

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Add your code here...
	ItmVIP = zp_items_register("Extra Items", "[VIP]",0,0,0)
}
public zp_fw_items_select_pre(id, i)
{
	if(i != ItmVIP)
		return ZP_ITEM_AVAILABLE
		
	if(zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW
		
	return ZP_ITEM_AVAILABLE

}
public zp_fw_items_select_post(id, i)
{
	if(i != ItmVIP)
		return
				
	zv_menu_open(id)
}
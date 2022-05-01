/*================================================================================
	
	--------------------------------------
	-*- [ZA] Items Manager: Ammo Packs -*-
	--------------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <za_items>
#include <zp50_ammopacks>
#include <zmvip>

public plugin_init()
{
	register_plugin("[ZA] Items Manager", ZP_VERSION_STRING, "ZP Dev Team")
}


public za_fw_items_select_pre(id, itemid, ignorecost)
{
	// Ignore item costs?
	if (ignorecost)
		return ZP_ITEM_AVAILABLE;
	
	if(!(zv_get_user_flags(id) & ZV_DAMAGE))
		return ZP_ITEM_NOT_AVAILABLE;
		
	// Get current and required ammo packs
	new current_ammopacks = zp_ammopacks_get(id)
	new required_ammopacks = za_items_get_cost(itemid)

	// Not enough ammo packs
	if (current_ammopacks < required_ammopacks)
		return ZP_ITEM_NOT_AVAILABLE;
	
	
	return ZP_ITEM_AVAILABLE;
}

public za_fw_items_select_post(id, itemid, ignorecost)
{
	// Ignore item costs?
	if (ignorecost)
		return;
		
	// Get current and required ammo packs
	new required_ammopacks, current_ammopacks = zp_ammopacks_get(id)
	required_ammopacks = za_items_get_cost(itemid)
		//required_ammopacks = zp_items_get_cost(itemid) + 40

	// Deduct item's ammo packs after purchase event
	zp_ammopacks_set(id, current_ammopacks - required_ammopacks)
}
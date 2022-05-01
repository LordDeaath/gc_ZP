/*================================================================================
	
	--------------------------------------
	-*- [ZP] Items Manager: Ammo Packs -*-
	--------------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_items>
#include <zp50_ammopacks>
#include <colorchat>

new Bought[33],giHasMusic[33]
native zp_is_apocalypse()

public plugin_init()
{
	register_plugin("[ZP] Items Manager: Ammo Packs", ZP_VERSION_STRING, "ZP Dev Team")
	register_clcmd("say /sound", "Switch")
}

public plugin_precache()
{
	precache_sound("zombie_plague/select.wav");
}
public plugin_natives()
{
	register_native("zp_items_bought_get","native_items_bought_get",1)
}

public native_items_bought_get(id)
{
	return Bought[id]
}

public zp_fw_gamemodes_start()
{
	for(new id=1;id<33;id++)
	{
		Bought[id]=0;
	}
}
public Switch(id)
{
	if(giHasMusic[id] == 0)
	{
		giHasMusic[id] = 1
		ColorChat(id, GREEN, "[GC]^3 sound toggled off")
	}
	else
	{
		giHasMusic[id] = 1
		ColorChat(id, GREEN, "[GC]^3 sound toggled on")
	}
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	// Ignore item costs?
	if (ignorecost)
		return ZP_ITEM_AVAILABLE;
	
	if(zp_is_apocalypse()&&!zp_core_is_zombie(id))
		return ZP_ITEM_AVAILABLE;

	// Get current and required ammo packs
	new current_ammopacks = zp_ammopacks_get(id)
	new required_ammopacks = zp_items_get_cost(itemid)
	/*
	(zp_madness_set_cost(id, required_ammopacks, itemid)
	||zp_grenades_set_cost(id, required_ammopacks, itemid)
	||zp_brains_set_cost(id, required_ammopacks, itemid))
	*/
	// Not enough ammo packs
	if (current_ammopacks < required_ammopacks)
		return ZP_ITEM_NOT_AVAILABLE;
	
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
	// Ignore item costs?
	if (ignorecost)
		return;
		
	if(zp_is_apocalypse()&&!zp_core_is_zombie(id))
		return;

	// Get current and required ammo packs
	new required_ammopacks, current_ammopacks = zp_ammopacks_get(id)
	 required_ammopacks = zp_items_get_cost(itemid)
		//required_ammopacks = zp_items_get_cost(itemid) + 40

	
	//(zp_madness_set_cost(id, required_ammopacks, itemid)
	//||zp_grenades_set_cost(id, required_ammopacks, itemid)
	//||zp_brains_set_cost(id, required_ammopacks, itemid))

	if(!zp_core_is_zombie(id))
		Bought[id]+=required_ammopacks

	// Deduct item's ammo packs after purchase event
	zp_ammopacks_set(id, current_ammopacks - required_ammopacks)
	PlaySoundToClients(id, "zombie_plague/Select.mp3")
}
PlaySoundToClients(i, const sound[])
{
	
	if(!is_user_connected(i))
		return;

	if(giHasMusic[i])
		return;
			
	client_cmd(i, "spk ^"%s^"", sound)
}
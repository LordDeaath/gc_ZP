/*================================================================================
	
	-----------------------------------
	-*- [ZP] Class: Zombie: Classic -*-
	-----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_zombie>
#include <fun>
#include <colorchat>

// Classic Zombie Attributes
new const zombieclass1_name[] = "Despawn Zombie"
new const zombieclass1_info[] = "Passive Ability"
new const zombieclass1_models[][] = { "gc_dspawn" }
new const zombieclass1_clawmodels[][] = { "models/zombie_plague/v_knife_zombie.mdl" }
const zombieclass1_health = 3800
const Float:zombieclass1_speed = 0.75
const Float:zombieclass1_gravity = 1.0
const Float:zombieclass1_knockback = 1.0

new g_ZombieClassID, iCurrHP[33]

public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Classic", ZP_VERSION_STRING, "ZP Dev Team")
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")	
	new index
	g_ZombieClassID = zp_class_zombie_register(zombieclass1_name, zombieclass1_info, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity)
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass1_knockback)
	for (index = 0; index < sizeof zombieclass1_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass1_models[index])
	for (index = 0; index < sizeof zombieclass1_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass1_clawmodels[index])
}

public Event_NewRound()
{
	for(new id;id <= get_maxplayers();id++)
	{
		if(is_user_connected(id))
		{
			if(is_user_alive(id))
				iCurrHP[id] = zp_class_zombie_get_max_health(id, g_ZombieClassID)
		}
	}
}
public zp_fw_core_infect_post(id, att)
{
	if(is_user_connected(id))
		iCurrHP[id] = zp_class_zombie_get_max_health(id, g_ZombieClassID)
	if(att != id)
	{
		if(zp_class_zombie_get_current(att) == g_ZombieClassID)
		{
			set_user_health(att, iCurrHP[att])
			ColorChat(att, GREEN,"[GC]^3 You've^4 Despawned.^3 Your^4 Health ^3is back to^4 %d",iCurrHP[att])
			if(iCurrHP[att] > 2000)
				iCurrHP[att] -= 400
		}
	}
}
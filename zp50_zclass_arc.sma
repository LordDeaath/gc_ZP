/*================================================================================
	
	-----------------------------------
	-*- [ZP] Class: Zombie: Classic -*-
	-----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <zp50_class_zombie>
#include <fun>
#include <colorchat>
#include <zmvip>
#include <zp50_grenade_frost>
#include <zp50_grenade_fire>

// Classic Zombie Attributes
new const zombieclass1_name[] = "Arachne Zombie"
new const zombieclass1_info[] = "[20% Damage]"
new const zombieclass1_models[][] = { "pv_zskin1" }
new const zombieclass1_clawmodels[][] = { "models/zombie_plague/v_knife_zombie.mdl" }
const zombieclass1_health = 2000
const Float:zombieclass1_speed = 0.85
const Float:zombieclass1_gravity = 0.80
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
	RegisterHam(Ham_TakeDamage, "info_target", "fw_TakeDamage");	
	RegisterHam(Ham_TakeDamage, "func_wall", "fw_TakeDamage");
	RegisterHam(Ham_TakeDamage, "func_breakable", "fw_TakeDamage");	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post",1);
}

public fw_TakeDamage_Post(victim,inflictor, attacker, Float:damage)
{
	if(!is_user_alive(victim))
		return HAM_IGNORED;
	if (!zp_core_is_zombie(victim))
		return HAM_IGNORED;
	if(zp_class_zombie_get_current(victim)!=g_ZombieClassID)
		return HAM_IGNORED;
	set_pdata_float(victim, 108, 0.9, 5 );
	return HAM_IGNORED;
}

public zp_fw_class_zombie_select_pre(id, class)
{
	if(class != g_ZombieClassID)
		return ZP_CLASS_AVAILABLE
		
	new AuthID[34]
	get_user_authid(id, AuthID,charsmax(AuthID))
	if(!equal(AuthID,"STEAM_0:1:32564552"))
		return ZP_CLASS_DONT_SHOW
		
	return ZP_CLASS_AVAILABLE
}
public zp_fw_grenade_fire_pre(id)
{	
	if(!zp_core_is_zombie(id))
		return PLUGIN_CONTINUE;
		
	if(zp_class_zombie_get_current(id)==g_ZombieClassID)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}
public zp_fw_grenade_frost_pre(id)
{	
	if(!zp_core_is_zombie(id))
		return PLUGIN_CONTINUE;
		
	if(zp_class_zombie_get_current(id)==g_ZombieClassID)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if(is_user_connected(victim))
	{
	}
	else
	{
		new sz_classname[32] 
		entity_get_string( victim , EV_SZ_classname , sz_classname, 31 )			
		if(equali(sz_classname,"lasermine") ) 
		{
		}
		else
		if(equali(sz_classname,"amxx_pallets"))
		{
		}
		else
		if(equali(sz_classname,"rcbomb"))
		{
		}
		else
		if(equali(sz_classname,"amxx_mt"))
		{
		}
		else	
			return HAM_IGNORED; 
	}
	
	if(!is_user_alive(attacker))
		return HAM_IGNORED;
		
	if(victim == attacker)
		return HAM_IGNORED;
	
	if(!zp_core_is_zombie(attacker))
		return HAM_IGNORED;
	if(zp_class_zombie_get_current(attacker)!=g_ZombieClassID)
		return HAM_IGNORED;
		
	SetHamParamFloat(4, damage*1.23)
	return HAM_IGNORED;
		
}
public Event_NewRound()
{
	for(new id=1;id <= get_maxplayers();id++)
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
		if(!is_user_alive(att))
			return
		if(zp_class_zombie_get_current(att) == g_ZombieClassID)
		{
			set_user_health(att, iCurrHP[att])
			ColorChat(att, GREEN,"[GC]^3 You've^4 Respawned.^3 Your^4 Health ^3is back to^4 %d",iCurrHP[att])
		}
	}
}
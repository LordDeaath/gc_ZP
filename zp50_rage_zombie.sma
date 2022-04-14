/*================================================================================
	
	--------------------------------
	-*- [ZP] Class: Zombie: Rage -*-
	--------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <zp50_class_zombie>
#include <zp50_class_nemesis>
#include <zp50_class_predator>
#include <zp50_class_dragon>
#include <zp50_class_nightcrawler>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <zmvip>
//#include <colorchat>

#define TASK_STOP	100
#define TASK_CD		200
#define is_valid_player(%1) (1 <= %1 <= 32)

// Rage Zombie Attributes
new const zombieclass6_name[] = "Rage Zombie"
new const zombieclass6_info[] = "=Radioactivity="
new const zombieclass6_models[][] = { "gc_rage" }
new const zombieclass6_clawmodels[][] = { "models/zombie_plague/zow_claws.mdl" }
const zombieclass6_health = 2000
const Float:zombieclass6_speed = 0.9
const Float:zombieclass6_gravity = 0.6
const Float:zombieclass6_knockback = 0.65

new g_ZombieClassID/*
new g_HasPowers[33]
new g_UsingPowers[33]*/


public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Rage", ZP_VERSION_STRING, "ZP Dev Team")
	//RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	//register_clcmd("drop","Use_Powers")
	new index
	
	g_ZombieClassID = zp_class_zombie_register(zombieclass6_name, zombieclass6_info, zombieclass6_health, zombieclass6_speed, zombieclass6_gravity)
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass6_knockback)
	for (index = 0; index < sizeof zombieclass6_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass6_models[index])
	for (index = 0; index < sizeof zombieclass6_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass6_clawmodels[index])
}

public zp_fw_class_zombie_select_pre(id, classid)
{
	if(classid!=g_ZombieClassID)
		return ZP_CLASS_AVAILABLE
	
	if(!(zv_get_user_flags(id)&ZV_MAIN))
	{
		zp_class_zombie_menu_text_add("\r[VIP]")
		return ZP_CLASS_NOT_AVAILABLE;
	}

	return ZP_CLASS_AVAILABLE
}
/*================================================================================
	
	--------------------------
	-*- [ZP] Leap/Longjump -*-
	--------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <zp50_gamemodes>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_DRAGON "zp50_class_dragon"
#include <zp50_class_dragon>
#define LIBRARY_NIGHTCRAWLER "zp50_class_nightcrawler"
#include <zp50_class_nightcrawler>
#define LIBRARY_PREDATOR "zp50_class_predator"
#include <zp50_class_predator>


#define MAXPLAYERS 32

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new Float:g_LeapLastTime[MAXPLAYERS+1]

new cvar_leap_nemesis, cvar_leap_nemesis_force,cvar_leap_nemesis_cooldown,cvar_leap_nemesis_height
new cvar_leap_dragon, cvar_leap_dragon_force, cvar_leap_dragon_height, cvar_leap_dragon_cooldown
new cvar_leap_nightcrawler, cvar_leap_nightcrawler_force, cvar_leap_nightcrawler_height, cvar_leap_nightcrawler_cooldown
new cvar_leap_predator, cvar_leap_predator_force, cvar_leap_predator_height, cvar_leap_predator_cooldown
new cvar_leap_player_force, cvar_leap_player_height, cvar_leap_player_cooldown

new CanLeap[33]
public plugin_init()
{
	register_plugin("[ZP] Leap/Longjump", ZP_VERSION_STRING, "ZP Dev Team")
		
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
	{
		cvar_leap_nemesis = register_cvar("zp_leap_nemesis", "1")
		cvar_leap_nemesis_force = register_cvar("zp_leap_nemesis_force", "500")
		cvar_leap_nemesis_height = register_cvar("zp_leap_nemesis_height", "300")
		cvar_leap_nemesis_cooldown = register_cvar("zp_leap_nemesis_cooldown", "0.03")
	}

	// Predator Class loaded?
	if (LibraryExists(LIBRARY_PREDATOR, LibType_Library))
	{
		cvar_leap_predator = register_cvar("zp_leap_predator", "1")
		cvar_leap_predator_force = register_cvar("zp_leap_predator_force", "500")
		cvar_leap_predator_height = register_cvar("zp_leap_predator_height", "300")
		cvar_leap_predator_cooldown = register_cvar("zp_leap_predator_cooldown", "0.03")
	}

	// Dragon Class loaded?
	if (LibraryExists(LIBRARY_DRAGON, LibType_Library))
	{
		cvar_leap_dragon = register_cvar("zp_leap_dragon", "1")
		cvar_leap_dragon_force = register_cvar("zp_leap_dragon_force", "500")
		cvar_leap_dragon_height = register_cvar("zp_leap_dragon_height", "300")
		cvar_leap_dragon_cooldown = register_cvar("zp_leap_dragon_cooldown", "0.03")
	}	

	// Nightcrawler Class loaded?
	if (LibraryExists(LIBRARY_NIGHTCRAWLER, LibType_Library))
	{
		cvar_leap_nightcrawler = register_cvar("zp_leap_nightcrawler", "1")
		cvar_leap_nightcrawler_force = register_cvar("zp_leap_nightcrawler_force", "500")
		cvar_leap_nightcrawler_height = register_cvar("zp_leap_nightcrawler_height", "300")
		cvar_leap_nightcrawler_cooldown = register_cvar("zp_leap_nightcrawler_cooldown", "0.03")
	}
	cvar_leap_player_force = register_cvar("zp_leap_predator_force", "500")
	cvar_leap_player_height = register_cvar("zp_leap_predator_height", "300")
	cvar_leap_player_cooldown = register_cvar("zp_leap_predator_cooldown", "0.03")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
}


public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
	register_native("set_leap","nat_set_leap", 1)
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_DRAGON) || equal(module, LIBRARY_NIGHTCRAWLER) || equal(module, LIBRARY_PREDATOR))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}
public nat_set_leap(id, num)
	CanLeap[id] = num
	
// Forward Player PreThink
public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return;	

	if(!zp_core_is_zombie(id) && !CanLeap[id])
		return;

	// Don't allow leap if player is frozen (e.g. freezetime)
	if (get_user_maxspeed(id) == 1.0)
		return;
	
	static Float:cooldown, force, Float:height
	
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
	{
		// Check if nemesis should leap
		if (!get_pcvar_num(cvar_leap_nemesis)) return;
		cooldown = get_pcvar_float(cvar_leap_nemesis_cooldown)
		force = get_pcvar_num(cvar_leap_nemesis_force)
		height = get_pcvar_float(cvar_leap_nemesis_height)
	}
	// Dragon Class loaded?
	else if (LibraryExists(LIBRARY_DRAGON, LibType_Library) && zp_class_dragon_get(id))
	{
		// Check if dragon should leap
		if (!get_pcvar_num(cvar_leap_dragon)) return;
		cooldown = get_pcvar_float(cvar_leap_dragon_cooldown)
		force = get_pcvar_num(cvar_leap_dragon_force)
		height = get_pcvar_float(cvar_leap_dragon_height)
	}
	// Nightcrawler Class loaded?
	else if (LibraryExists(LIBRARY_NIGHTCRAWLER, LibType_Library) && zp_class_nightcrawler_get(id))
	{
		// Check if nightcrawler should leap
		if (!get_pcvar_num(cvar_leap_nightcrawler)) return;
		cooldown = get_pcvar_float(cvar_leap_nightcrawler_cooldown)
		force = get_pcvar_num(cvar_leap_nightcrawler_force)
		height = get_pcvar_float(cvar_leap_nightcrawler_height)
	}
	// Predator Class loaded?
	else if (LibraryExists(LIBRARY_PREDATOR, LibType_Library) && zp_class_predator_get(id))
	{
		// Check if predator should leap
		if (!get_pcvar_num(cvar_leap_predator)) return;
		cooldown = get_pcvar_float(cvar_leap_predator_cooldown)
		force = get_pcvar_num(cvar_leap_predator_force)
		height = get_pcvar_float(cvar_leap_predator_height)
	}
	else
	{
		cooldown = get_pcvar_float(cvar_leap_player_cooldown)
		force = get_pcvar_num(cvar_leap_player_force)
		height = get_pcvar_float(cvar_leap_player_height)
	}
	static Float:current_time
	current_time = get_gametime()
	
	// Cooldown not over yet
	if (current_time - g_LeapLastTime[id] < cooldown)
		return;
	
	// Not doing a longjump (don't perform check for bots, they leap automatically)
	if (!is_user_bot(id) && !(pev(id, pev_button) & (IN_JUMP | IN_DUCK) == (IN_JUMP | IN_DUCK)))
		return;
	
	// Not on ground or not enough speed
	//if (!(pev(id, pev_flags) & FL_ONGROUND) || fm_get_speed(id) < 80)
	//	return;
	
	static Float:velocity[3]
	
	// Make velocity vector
	velocity_by_aim(id, force, velocity)
	
	// Set custom height
	velocity[2] = height
	
	// Apply the new velocity
	set_pev(id, pev_velocity, velocity)
	
	// Update last leap time
	g_LeapLastTime[id] = current_time
}

// Get entity's speed (from fakemeta_util)
stock fm_get_speed(entity)
{
	static Float:velocity[3]
	pev(entity, pev_velocity, velocity)
	
	return floatround(vector_length(velocity));
}
/*================================================================================
	
	---------------------------------
	-*- [ZP] Item: Zombie Madness -*-
	---------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#define ITEM_NAME "Zombie Madness"
#define ITEM_DESC "Take no damage [5 sec]"
#define ITEM_COST 15

#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_ham_bots_api>
#include <zp50_items>
#include <zp50_gamemodes>
#define LIBRARY_GRENADE_FROST "zp50_grenade_frost"
#include <zp50_grenade_frost>
#define LIBRARY_GRENADE_FIRE "zp50_grenade_fire"
#include <zp50_grenade_fire>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_ASSASSIN "zp50_class_assassin"
#include <zp50_class_assassin>
#define LIBRARY_DRAGON "zp50_class_dragon"
#include <zp50_class_dragon>
#include <zp50_fps>
#include <fun>
#include <zmvip>

const MAXPLAYERS = 32;

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_zombie_madness[][] = { "zombie_plague/zombie_madness1.wav" }

#define SOUND_MAX_LENGTH 64

new Array:g_sound_zombie_madness

#define TASK_MADNESS 100
#define TASK_AURA 200
#define ID_MADNESS (taskid - TASK_MADNESS)
#define ID_AURA (taskid - TASK_AURA)

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))
//native zp_class_predator_get(id)

new g_ItemID
//new g_iMaxPlayers
new g_MadnessBlockDamage
new cvar_zombie_madness_time
new cvar_madness_aura_color_R, cvar_madness_aura_color_G, cvar_madness_aura_color_B

new Float:MadnessStart[33]

new Purchases[33]

//new gMode_Survivor;
public plugin_init()
{
	register_plugin("[ZP] Item: Zombie Madness", ZP_VERSION_STRING, "ZP Dev Team")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHamBots(Ham_Spawn, "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHamBots(Ham_TraceAttack, "fw_TraceAttack")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	
	register_clcmd("say /madness","BuyMadness",0,"- Buys Zombie Madness")
	register_clcmd("say_team /madness", "BuyMadness",0,"- Buys Zombie Madness")
	register_clcmd("say /mad", "BuyMadness",0,"- Buys Zombie Madness")
	register_clcmd("say_team /mad", "BuyMadness",0,"- Buys Zombie Madness")
	
	cvar_zombie_madness_time = register_cvar("zp_zombie_madness_time", "5.0")
	cvar_madness_aura_color_R = register_cvar("zp_madness_aura_color_R", "150")
	cvar_madness_aura_color_G = register_cvar("zp_madness_aura_color_G", "0")
	cvar_madness_aura_color_B = register_cvar("zp_madness_aura_color_B", "0")
	g_ItemID = zp_items_register(ITEM_NAME, ITEM_DESC, ITEM_COST, 0, 0)
	//g_iMaxPlayers = get_maxplayers()
}

public BuyMadness(id)
{
	zp_items_force_buy(id, g_ItemID);
	return PLUGIN_HANDLED;
}

new Infection, Multi
public plugin_cfg()
{
	Infection = zp_gamemodes_get_id("Infection Mode")
	Multi = zp_gamemodes_get_id("Multiple Infection Mode")
	//gMode_Survivor=zp_gamemodes_get_id("Survivor Mode")
}

public plugin_end()
{
	ArrayDestroy(g_sound_zombie_madness)
}

public plugin_precache()
{
	// Initialize arrays
	g_sound_zombie_madness = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE MADNESS", g_sound_zombie_madness)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_zombie_madness) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_madness; index++)
			ArrayPushString(g_sound_zombie_madness, sound_zombie_madness[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE MADNESS", g_sound_zombie_madness)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_zombie_madness); index++)
	{
		ArrayGetString(g_sound_zombie_madness, index, sound, charsmax(sound))
		precache_sound(sound)
	}
}

public plugin_natives()
{
	register_library("zp50_item_zombie_madness")
	register_native("zp_item_zombie_madness_get", "native_item_zombie_madness_get")	
	register_native("zp_madness_set", "native_zombie_madness_set",1)
	register_native("zp_madness_set_cost","native_madness_set_cost")
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public native_madness_set_cost(plugin,params)
{
	if(get_param(3)!=g_ItemID)
		return false;	

	set_param_byref(2, ((Purchases[get_param(1)]<2?Purchases[get_param(1)]:2)+2) * get_param_byref(2)/2)
	return true;
}

public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_ASSASSIN) || equal(module, LIBRARY_DRAGON) || equal(module, LIBRARY_GRENADE_FROST) || equal(module, LIBRARY_GRENADE_FIRE))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public native_item_zombie_madness_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return flag_get_boolean(g_MadnessBlockDamage, id);
}

public zp_fw_gamemodes_start()
{
	for(new id=1;id<33;id++)
	{
		Purchases[id]=0
	}
}

public zp_fw_items_select_pre(id, itemid)
{
	// This is not our item
	if (itemid != g_ItemID)
		return ZP_ITEM_AVAILABLE;
		
	// Zombie madness only available to zombies
	if (!zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW;
	
	//if(zp_gamemodes_get_current()==gMode_Survivor)
	//	return ZP_ITEM_DONT_SHOW
	
	// Zombie madness not available to Nemesis/assassin/dragon
	if ((LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id)) || 
		(LibraryExists(LIBRARY_ASSASSIN, LibType_Library) && zp_class_assassin_get(id)) || 
		(LibraryExists(LIBRARY_DRAGON, LibType_Library) && zp_class_dragon_get(id)) )//|| zp_class_predator_get(id))
		return ZP_ITEM_DONT_SHOW;
	
	if(zp_gamemodes_get_current()!=Infection&&zp_gamemodes_get_current()!=Multi)
	{
		if(zv_get_user_flags(id)&ZV_MAIN)
		{
			switch(Purchases[id])
			{
				case 0: {zp_items_menu_text_add("[0/2]");}
				case 1: {zp_items_menu_text_add("[1/2]");}
				case 3: {zp_items_menu_text_add("[2/2]");return ZP_ITEM_NOT_AVAILABLE;}
				default: {return ZP_ITEM_NOT_AVAILABLE;}
			}		
		}
		else
		{
			switch(Purchases[id])
			{
				case 0: {zp_items_menu_text_add("[0/1]");}
				case 1: {zp_items_menu_text_add("[1/2]\r [VIP]");return ZP_ITEM_NOT_AVAILABLE;}
				default: {return ZP_ITEM_NOT_AVAILABLE;}
			}
		}
	}
	else
	{
		if(zv_get_user_flags(id)&ZV_MAIN)
		{
			switch(Purchases[id])
			{
				case 0: {zp_items_menu_text_add("[0/3]");}
				case 1: {zp_items_menu_text_add("[1/3]");}
				case 2: {zp_items_menu_text_add("[2/3]");}
				case 3: {zp_items_menu_text_add("[3/3]");return ZP_ITEM_NOT_AVAILABLE;}
				default: {return ZP_ITEM_NOT_AVAILABLE;}
			}		
		}
		else
		{
			switch(Purchases[id])
			{
				case 0: {zp_items_menu_text_add("[0/2]");}
				case 1: {zp_items_menu_text_add("[1/2]");}
				case 2: {zp_items_menu_text_add("[2/3]\r [VIP]");return ZP_ITEM_NOT_AVAILABLE;}
				default: {return ZP_ITEM_NOT_AVAILABLE;}
			}
		}
	}
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid)
{
	// This is not our item
	if (itemid != g_ItemID)
		return;
	
	Purchases[id]++
	native_zombie_madness_set(id);
}

public native_zombie_madness_set(id)
{		
	if (!is_user_alive(id)||!zp_core_is_zombie(id))
	{
		return 0;
	}
	if ((LibraryExists("zp50_class_nemesis", LibType_Library) && zp_class_nemesis_get(id)) || (LibraryExists("zp50_class_assassin", LibType_Library) && zp_class_assassin_get(id)) || (LibraryExists("zp50_class_dragon", LibType_Library) && zp_class_dragon_get(id)) )//|| zp_class_predator_get(id))
	{
		return 3;
	}
		
	if(task_exists(id+TASK_MADNESS))
	{
		set_task(get_pcvar_float(cvar_zombie_madness_time)+MadnessStart[id]-get_gametime(), "native_zombie_madness_set", id)		
		MadnessStart[id]=get_gametime()
		return 1;
	}

	MadnessStart[id]=get_gametime()
	// Do not take damage
	flag_set(g_MadnessBlockDamage, id)
	
	// Madness aura
	set_task(0.1, "madness_aura", id+TASK_AURA, _, _, "b")/*
	zp_items_set_purchases(g_ItemID, zp_items_get_purchases(g_ItemID)+1)
	zp_items_set_player_purchases(g_ItemID,id, zp_items_get_player_purchases(g_ItemID,id)+1)*/
	// Madness sound
	new sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_sound_zombie_madness, random_num(0, ArraySize(g_sound_zombie_madness) - 1), sound, charsmax(sound))
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	zp_grenade_fire_set(id, false)
	zp_grenade_frost_set(id, false)
	// Set task to remove it
	set_task(get_pcvar_float(cvar_zombie_madness_time), "remove_zombie_madness", id+TASK_MADNESS)
	set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 16)
	//set_user_health(id, get_user_health(id) + 1000)
	return 1;
}
// Ham Player Spawn Post Forward
public fw_PlayerSpawn_Post(id)
{
	// Not alive or didn't join a team yet
	if (!is_user_alive(id) || !cs_get_user_team(id))
		return;
	
	// Remove zombie madness from a previous round
	remove_task(id+TASK_MADNESS)
	remove_task(id+TASK_AURA)
	flag_unset(g_MadnessBlockDamage, id)
}

// Ham Trace Attack Forward
public fw_TraceAttack(victim, attacker)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Prevent attacks when victim has zombie madness
	if (flag_get(g_MadnessBlockDamage, victim))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Take Damage Forward (needed to block explosion damage too)
public fw_TakeDamage(victim, inflictor, attacker)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Prevent attacks when victim has zombie madness
	if (flag_get(g_MadnessBlockDamage, victim))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public zp_fw_grenade_frost_pre(id)
{
	// Prevent frost when victim has zombie madness
	if (flag_get(g_MadnessBlockDamage, id))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_grenade_fire_pre(id)
{
	// Prevent burning when victim has zombie madness
	if (flag_get(g_MadnessBlockDamage, id))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_cure(id, attacker)
{
	// Remove zombie madness task
	remove_task(id+TASK_MADNESS)
	remove_task(id+TASK_AURA)
	flag_unset(g_MadnessBlockDamage, id)
	set_user_rendering(id)
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Remove zombie madness task
	remove_task(victim+TASK_MADNESS)
	remove_task(victim+TASK_AURA)
	flag_unset(g_MadnessBlockDamage, victim)
	set_user_rendering(victim)
}

// Remove Spawn Protection Task
public remove_zombie_madness(taskid)
{
	// Remove aura
	remove_task(ID_MADNESS+TASK_AURA)
	
	// Remove zombie madness
	flag_unset(g_MadnessBlockDamage, ID_MADNESS)
	set_user_rendering(ID_MADNESS)
}

public client_disconnected(id)
{
	// Remove tasks on disconnect
	remove_task(id+TASK_MADNESS)
	remove_task(id+TASK_AURA)
	flag_unset(g_MadnessBlockDamage, id)
}

// Madness aura task
public madness_aura(taskid)
{
	// Get player's origin
	new origin[3], rgiColor[3];

	get_user_origin(ID_AURA, origin)

	rgiColor[0] = get_pcvar_num(cvar_madness_aura_color_R);
	rgiColor[1] = get_pcvar_num(cvar_madness_aura_color_G);
	rgiColor[2] = get_pcvar_num(cvar_madness_aura_color_B);

	new rgpPlayers[MAXPLAYERS], i, iPlayerCount, pPlayer;
	
	get_players(rgpPlayers, iPlayerCount, "c");

	for (i = 0; i < iPlayerCount; i++)
	{
		pPlayer = rgpPlayers[i];

		if (!(zp_fps_get_user_flags(pPlayer) & FPS_MADNESS_AURA))
			continue;

		// Colored Aura
		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, .player = pPlayer)
		write_byte(TE_DLIGHT) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]) // z
		write_byte(20) // radius
		write_byte(rgiColor[0]) // r
		write_byte(rgiColor[1]) // g
		write_byte(rgiColor[2]) // b
		write_byte(2) // life
		write_byte(0) // decay rate
		message_end()
	}
}

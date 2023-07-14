/*================================================================================
	
	-----------------------------
	-*- [ZP] Game Mode: Swarm -*-
	-----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <amx_settings_api>
#include <cs_teams_api>
#include <zp50_gamemodes>
#include <zp50_deathmatch>
#include <zp50_items>
#include <zp50_random_spawn>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_swarm[][] = { "ambience/the_horror2.wav" }

#define SOUND_MAX_LENGTH 64

new Array:g_sound_swarm

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 20
#define HUD_EVENT_G 255
#define HUD_EVENT_B 20

new g_MaxPlayers
new g_HudSync

new cvar_swarm_chance, cvar_swarm_min_players, cvar_multi_ratio,Trm
new cvar_swarm_show_hud, cvar_swarm_sounds, cvar_multi_min_zombies
new cvar_swarm_allow_respawn

public plugin_end()
{
	ArrayDestroy(g_sound_swarm)
}

public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Swarm", ZP_VERSION_STRING, "ZP Dev Team")
	zp_gamemodes_register("Swarm Mode")
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_swarm_chance = register_cvar("zp_swarm_chance", "20")
	cvar_swarm_min_players = register_cvar("zp_swarm_min_players", "0")
	cvar_swarm_show_hud = register_cvar("zp_swarm_show_hud", "1")
	cvar_swarm_sounds = register_cvar("zp_swarm_sounds", "1")
	cvar_swarm_allow_respawn = register_cvar("zp_swarm_allow_respawn", "0")
	cvar_multi_ratio = register_cvar("zp_trm_ratio", "0.15")
	cvar_multi_min_zombies = register_cvar("zp_multi_min_zombies", "2")
	
	// Initialize arrays
	g_sound_swarm = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND SWARM", g_sound_swarm)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_swarm) == 0)
	{
		for (index = 0; index < sizeof sound_swarm; index++)
			ArrayPushString(g_sound_swarm, sound_swarm[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND SWARM", g_sound_swarm)
	}
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_swarm); index++)
	{
		ArrayGetString(g_sound_swarm, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
}


// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_swarm_allow_respawn))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	new alive_count = GetAliveCount()
	
	// Calculate zombie count with current ratio setting
	new zombie_count = floatround(alive_count * get_pcvar_float(cvar_multi_ratio), floatround_ceil)

	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_swarm_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// Min players
		if (GetAliveCount() < get_pcvar_num(cvar_swarm_min_players))
			return PLUGIN_HANDLED;
		// Min zombies
		if (zombie_count < get_pcvar_num(cvar_multi_min_zombies))
			return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}
public zp_fw_items_select_pre(id, itm, c)
{
	new zpMad = zp_items_get_id("Zombie Madness")
	new zpBlind = zp_items_get_id("Unlimited Clip")
	if(!Trm)
		return ZP_ITEM_AVAILABLE
	if(itm == zpMad || itm == zpBlind)
		return ZP_ITEM_NOT_AVAILABLE
		
	return ZP_ITEM_AVAILABLE
	
}
public ItmBuy(id)
{
	new itmXM = zp_items_get_id("AKM 12")
	new itmLM = zp_items_get_id("Laser Mine")
	zp_items_force_buy(id, itmXM,true)
	zp_items_force_buy(id, itmLM,true)
}
public zp_fw_gamemodes_end(mod)
	Trm = 0
public zp_fw_gamemodes_start()
{
	zp_gamemodes_set_allow_infect()	
	// Turn every Terrorist into a zombie
	new iZombies, id, alive_count = GetAliveCount()
	new iMaxZombies = floatround(alive_count * get_pcvar_float(cvar_multi_ratio), floatround_ceil)
	iZombies = 0
	// Randomly turn iMaxZombies players into zombies
	while (iZombies < iMaxZombies)
	{
		// Choose random guy
		id = GetRandomAlive(random_num(1, alive_count))
		
		// Dead or already a zombie
		if (!is_user_alive(id) || zp_core_is_zombie(id))
			continue;
		
		// Turn into a zombie
		zp_core_infect(id, id)
		zp_random_spawn_do(id,false)
		iZombies++
	}
	// Turn the remaining players into humans
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Only those of them who aren't zombies
		if (!is_user_alive(id) || zp_core_is_zombie(id))
			continue;
		
		// Switch to CT
		cs_set_player_team(id, CS_TEAM_CT)
		ItmBuy(id)
	}
	Trm = 1
	// Play swarm sound
	if (get_pcvar_num(cvar_swarm_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_swarm, random_num(0, ArraySize(g_sound_swarm) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_swarm_show_hud))
	{
		// Show Swarm HUD notice
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "Terminal Infection")
	}
}

// Plays a sound on clients
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}

// Get Alive Count -returns alive players number-
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}
// Get Random Alive -returns index of alive player number target_index -
GetRandomAlive(target_index)
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id;
	}
	
	return -1;
}
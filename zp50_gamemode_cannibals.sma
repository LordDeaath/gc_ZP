/*================================================================================
	
	-----------------------------
	-*- [ZP] Game Mode: Cannibals -*-
	-----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <amx_settings_api>
#include <zp50_gamemodes>
#include <zp50_deathmatch>
#include <zp50_class_nemesis>
#include <fun>
#include <colorchat>
#include <zp50_ammopacks>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_Cannibals[][] = { "ambience/the_horror2.wav" }

#define SOUND_MAX_LENGTH 64

new Array:g_sound_Cannibals

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 20
#define HUD_EVENT_G 255
#define HUD_EVENT_B 20

new g_MaxPlayers
new g_HudSync
new Cannibals_Mode;
new cvar_Cannibals_chance, cvar_Cannibals_min_players
new cvar_Cannibals_show_hud, cvar_Cannibals_sounds
new cvar_Cannibals_allow_respawn
new user_kills[33]
new user_hp[33]

public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Cannibals", ZP_VERSION_STRING, "ZP Dev Team")
	zp_gamemodes_register("Cannibals Mode")
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_Cannibals_chance = register_cvar("zp_Cannibals_chance", "20")
	cvar_Cannibals_min_players = register_cvar("zp_Cannibals_min_players", "0")
	cvar_Cannibals_show_hud = register_cvar("zp_Cannibals_show_hud", "1")
	cvar_Cannibals_sounds = register_cvar("zp_Cannibals_sounds", "1")
	cvar_Cannibals_allow_respawn = register_cvar("zp_Cannibals_allow_respawn", "0")
	
	// Initialize arrays
	g_sound_Cannibals = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND Cannibals", g_sound_Cannibals)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_Cannibals) == 0)
	{
		for (index = 0; index < sizeof sound_Cannibals; index++)
			ArrayPushString(g_sound_Cannibals, sound_Cannibals[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND Cannibals", g_sound_Cannibals)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_Cannibals); index++)
	{
		ArrayGetString(g_sound_Cannibals, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
}

public plugin_end()
{
	ArrayDestroy(g_sound_Cannibals)
}

// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_Cannibals_allow_respawn))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_Cannibals_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// Min players
		if (GetAliveCount() < get_pcvar_num(cvar_Cannibals_min_players))
			return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}
public Check_HP()
{
	new id
	// Turn every Terrorist into a zombie
	for (id = 1; id <= g_MaxPlayers; id++)
		{
			if(Cannibals_Mode == 1)
				{
					if(!is_user_alive(id))
					continue
					
					if(get_user_health(id) >= 500)
					{						
						set_user_health(id, get_user_health(id)/10)
					}
						
					if(!zp_core_is_zombie(id))
						zp_core_force_infect(id)
						
				}

		}
	set_task(0.5,"Check_HP")
}

public zp_fw_gamemodes_start()
{
	Cannibals_Mode = 1
	new id
	// Turn every Terrorist into a zombie
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Not alive
		if (!is_user_alive(id))
			continue;
		
		// Turn into a zombie
		zp_core_infect(id, 0)
		set_user_health(id, get_user_health(id)/10)
	}
	RemoveGrenade()
	server_cmd("mp_freeforall 1")
	server_cmd("mp_round_infinite bcdefg")
	Check_Alive()
	set_task(2.0,"Check_HP")
	// Play Cannibals sound
	if (get_pcvar_num(cvar_Cannibals_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_Cannibals, random_num(0, ArraySize(g_sound_Cannibals) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_Cannibals_show_hud))
	{
		// Show Cannibals HUD notice
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "Cannibals Mode!")
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

public Check_Alive()
{
	if(Cannibals_Mode == 1)
	{
		if(GetAliveCount() > 1) set_task(2.0,"Check_Alive")
			else Solve_Winner()
	}
	//client_print(0,print_chat,"Debugging : Checking alive count")
}
public Solve_Winner()
{
	server_cmd("mp_freeforall 0")
	// server_cmd("humans_join_team any")
	server_cmd("mp_round_infinite 0")
	server_cmd("endround")
	Cannibals_Mode = 0
}
public client_death(killer,victim,wpnindex,hitplace,TK)
{	
	new Nick[32]
	if(killer != victim)
	{	
		if(zp_core_is_zombie(victim) & zp_core_is_zombie(killer) && !zp_class_nemesis_get(killer))
		{
			if(user_kills[killer] < 2 && !zp_class_nemesis_get(killer))
			{
				user_kills[killer] += 1
			}
			else
			{
				get_user_name(killer, Nick,31)
				user_hp[killer] = get_user_health(killer)
				zp_class_nemesis_set(killer)
				set_user_health(killer, user_hp[killer])
				ColorChat(0, GREEN,"[GC]^03 ^01%s^03 ate ^04 3 zombies^03 and evolved into a ^04Nemesis!",Nick)
			}
		}
	}
}
public RemoveGrenade()
{
	new iEnt
	while( (iEnt = find_ent_by_class(iEnt, "grenade")) )
	{
		if(pev_valid(iEnt))
			remove_entity(iEnt)
	}
}
public zp_fw_gamemodes_end()
{
	new id
	// Turn every Terrorist into a zombie
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Not alive
		if (!is_user_alive(id))
			continue;
		
		// Turn into a zombie
		user_kills[id] = 0
	}
	Cannibals_Mode = 0
	server_cmd("mp_freeforall 0")
	// server_cmd("humans_join_team any")
	server_cmd("mp_round_infinite 0")
	new gText[32]
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if(!is_user_connected(id))
			continue;
		if(is_user_alive(id))
		{
			get_user_name(id, gText, 31)
			zp_ammopacks_set(id, zp_ammopacks_get(id) + 50)
			ColorChat(0, GREEN, "[GC]^01 %s ^03 has become the perfect cannibal & got ^04 50 ^03 Ammo Packs!", gText)
		}
	}
}

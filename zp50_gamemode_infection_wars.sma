/*================================================================================
	
--------------------------------------
-*- [ZP] Game Mode: Infection Wars -*-
--------------------------------------

This plugin is part of Zombie Plague Mod and is distributed under the
terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <engine>
#include <amx_settings_api>
#include <cs_weap_models_api>
#include <zp50_gamemodes>
#include <zp50_deathmatch>
#include <hamsandwich>
#include <fun>
#include <zp50_grenade_frost>
#include <zp50_ammopacks>
#include <zp50_colorchat>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound[][] = { "ambience/the_horror2.wav" }

// Default sounds
new const sound_cure[] = "items/smallmedkit1.wav" 

#define SOUND_MAX_LENGTH 64

new Array:g_sound

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 20
#define HUD_EVENT_G 20
#define HUD_EVENT_B 255

new g_MaxPlayers
new g_HudSync

new cvar_chance, cvar_min_players
new cvar_show_hud, cvar_sounds
new cvar_allow_respawn

new bool:ZombiesWin, bool:Ongoing;

new FrostDuration;

new V_MODEL[]="models/zombie_plague/v_infection_wars_knife.mdl"
new P_MODEL[]="models/zombie_plague/p_infection_wars_knife.mdl"

public plugin_end()
{
	ArrayDestroy(g_sound)
}

public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Infection Wars", ZP_VERSION_STRING, "ZP Dev Team")

	zp_gamemodes_register("Infection Wars Mode")
	

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_Killed")
	
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_chance = register_cvar("zp_infection_wars_chance", "20")
	cvar_min_players = register_cvar("zp_infection_wars_min_players", "2")
	cvar_show_hud = register_cvar("zp_infection_wars_show_hud", "1")
	cvar_sounds = register_cvar("zp_infection_wars_sounds", "1")
	cvar_allow_respawn = register_cvar("zp_infection_wars_allow_respawn", "0")
	
	// Initialize arrays
	g_sound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND INFECTION WARS", g_sound)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound) == 0)
	{
		for (index = 0; index < sizeof sound; index++)
		ArrayPushString(g_sound, sound[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND INFECTION WARS", g_sound)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound); index++)
	{
		ArrayGetString(g_sound, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
		precache_sound(sound)
	}
	precache_sound(sound_cure)
	precache_model(V_MODEL)
	precache_model(P_MODEL)
}


public fw_TakeDamage(victim, inflictor, attacker)
{
	if(is_user_connected(attacker))
	{
		if(zp_grenade_frost_get(attacker)||zp_grenade_frost_get(victim))
		{
			return HAM_SUPERCEDE;
		}

		if(zp_core_is_zombie(attacker)&&!zp_core_is_zombie(victim))
		{
			zp_core_infect(victim, attacker)
			zp_grenade_frost_set(victim)
			entity_set_int(victim, EV_INT_solid, SOLID_NOT)
			set_task(5.0, "solid", victim)
		}
		else
		if(zp_core_is_zombie(victim)&&!zp_core_is_zombie(attacker))
		{
			zp_core_force_cure(victim)
			zp_grenade_frost_set(victim)
			entity_set_int(victim, EV_INT_solid, SOLID_NOT)
			set_task(5.0, "solid", victim)
			SendDeathMsg(attacker, victim)
			FixDeadAttrib(victim)			
			emit_sound(victim, CHAN_BODY, sound_cure, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}
	return HAM_IGNORED;
}

public solid(victim)
{
	if(is_user_alive(victim))
	entity_set_int(victim, EV_INT_solid, SOLID_SLIDEBOX);
}

// Send Death Message for infections
SendDeathMsg(attacker, victim)
{
	message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(1) // headshot flag
	write_string("cure") // killer's weapon
	message_end()
}

// Fix Dead Attrib on scoreboard
FixDeadAttrib(id)
{
	message_begin(MSG_BROADCAST, get_user_msgid("ScoreAttrib"))
	write_byte(id) // id
	write_byte(0) // attrib
	message_end()
}

public zp_fw_core_cure_post(id)
{	
	strip_user_weapons(id)
	give_item(id, "weapon_knife")
	
	cs_set_player_view_model(id, CSW_KNIFE, V_MODEL)
	cs_set_player_weap_model(id, CSW_KNIFE, P_MODEL)
	if(!CheckStatus(0))
	{
		zp_colored_print(id, "You are a^3 Human^1, you must^3 Cure^1 all^3 Zombies^1 to^3 Win!")
	}
}

public zp_fw_core_infect_post(id)
{
	if(!CheckStatus(0))
	{
		zp_colored_print(id, "You are a^3 Zombie^1, you must^3 Infect^1 all^3 Humans^1 to^3 Win!")
	}
}

public client_disconnected(id)
{
	CheckStatus(id);
}

public fw_Killed(id)
{
	CheckStatus(id)
}

// Ham Weapon Touch Forward
public fw_TouchWeapon(weapon, id)
{
	return HAM_SUPERCEDE;
}

// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_allow_respawn))
	return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_chance)) != 1)
		return PLUGIN_HANDLED;
		
		// Min players
		if (GetAliveCount() < get_pcvar_num(cvar_min_players))
		return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_start()
{
	ZombiesWin=false;
	Ongoing=false;
	FrostDuration = get_cvar_num("zp_grenade_frost_duration")
	set_cvar_num("zp_grenade_frost_duration", 5)
	new id
	
	// Turn every Terrorist into a zombie
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Not alive
		if (!is_user_alive(id))
		continue;
		
		// Not a Terrorist
		if (cs_get_user_team(id) != CS_TEAM_T)
		{			
			zp_core_force_cure(id)
			continue;
		}
		
		// Turn into a zombie
		zp_core_force_infect(id)
	}
	
	// Play Infection Wars sound
	if (get_pcvar_num(cvar_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound, random_num(0, ArraySize(g_sound) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_show_hud))
	{
		// Show Infection Wars HUD notice
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "Infection Wars Mode !!!")
	}
	Ongoing=true;
}

public zp_fw_gamemodes_end()
{
	for(new i=1;i<33;i++)
	{
		zp_ammopacks_set(i, zp_ammopacks_get(i)+10)
	}

	if(ZombiesWin)
	{
		
		zp_colored_print(0, "^3Zombies^1 earned^3 10 AmmoPacks^1 for winning the^3 Infection Wars!")
	}
	else
	{
		zp_colored_print(0, "^3Humans^1 earned^3 10 AmmoPacks^1 for winning the^3 Infection Wars!")
	}
	set_cvar_num("zp_grenade_frost_duration",FrostDuration)
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

CheckStatus(skip)
{
	if(!Ongoing)
		return false;

	new zombie,human;
	for(new id=1;id<33;id++)
	{
		if(!is_user_alive(id))
			continue;
		
		if(id==skip)
			continue;
			
		if(zp_core_is_zombie(id))
		{
			if(human)
				return false;
			
			zombie=true;
		}
		else
		{
			if(zombie)
				return false;
			
			human=true;

		} 
	}

	if(zombie)
	{
		ZombiesWin = true
		server_cmd("endround T")
	}
	else
	{
		server_cmd("endround CT")
	}
	
		
	return true;
}
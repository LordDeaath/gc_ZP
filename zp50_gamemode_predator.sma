/*================================================================================
	
	-------------------------------
	-*- [ZP] Game Mode: Predator -*-
	-------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amx_settings_api>
#include <cs_teams_api>
#include <zp50_gamemodes>
#include <zp50_class_predator>
#include <zp50_deathmatch>
#include <zombieplague>
#include <zp50_colorchat>

native zp_select_participator2()
native zp_select_participator3()

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_predator[][] = { "zombie_plague/nemesis1.wav" , "zombie_plague/nemesis2.wav" }

#define SOUND_MAX_LENGTH 64

new Array:g_sound_predator

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 255
#define HUD_EVENT_G 20
#define HUD_EVENT_B 20

new g_MaxPlayers
new g_HudSync
new g_TargetPlayer, g_TargetPlayer2, g_TargetPlayer3;

new cvar_predator_chance, cvar_predator_min_players
new cvar_predator_show_hud, cvar_predator_sounds
new cvar_predator_allow_respawn
new Player_ResapwnCount[33]

public plugin_end()
{
	ArrayDestroy(g_sound_predator)
}

public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Predator", ZP_VERSION_STRING, "ZP Dev Team")
	zp_gamemodes_register("Predators Mode")
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_predator_chance = register_cvar("zp_predator_chance", "20")
	cvar_predator_min_players = register_cvar("zp_predator_min_players", "0")
	cvar_predator_show_hud = register_cvar("zp_predator_show_hud", "1")
	cvar_predator_sounds = register_cvar("zp_predator_sounds", "1")
	cvar_predator_allow_respawn = register_cvar("zp_predator_allow_respawn", "0")
	
	// Initialize arrays
	g_sound_predator = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND DRAGON", g_sound_predator)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_predator) == 0)
	{
		for (index = 0; index < sizeof sound_predator; index++)
			ArrayPushString(g_sound_predator, sound_predator[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND DRAGON", g_sound_predator)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_predator); index++)
	{
		ArrayGetString(g_sound_predator, index, sound, charsmax(sound))
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
	if (!get_pcvar_num(cvar_predator_allow_respawn))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(id)
{
	// Always respawn as human on predator rounds
	zp_core_respawn_as_zombie(id, false)
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_predator_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// Min players
		if (GetAliveCount() < get_pcvar_num(cvar_predator_min_players))
			return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_post(game_mode_id, target_player)
{
	// Pick player randomly?
	g_TargetPlayer = (target_player == RANDOM_TARGET_PLAYER) ? GetRandomAlive(random_num(1, GetAliveCount())) : target_player
	
	new iPlayersAlive = GetAliveCount();
	if (iPlayersAlive >= 12)
	{		
		g_TargetPlayer2 = zp_select_participator2();
	}
	if (iPlayersAlive >= 24)
	{						
		g_TargetPlayer3 = zp_select_participator3();
	}

}

public zp_fw_gamemodes_start()
{	
	new iPlayersAlive = GetAliveCount();
	new iZombiesRemaining
	if(iPlayersAlive<13)
	{
		iZombiesRemaining = 1
	}
	else if(iPlayersAlive<25)
	{
		iZombiesRemaining = 2
	}
	else
	{		
		iZombiesRemaining = 3
	}

	new iZombies, name1[32],name2[32],name3[32],id1;
	if(is_user_alive(g_TargetPlayer))
	{
		get_user_name(g_TargetPlayer, name1, charsmax(name1))
		zp_class_predator_set(g_TargetPlayer)		
		iZombies++;
		id1 = g_TargetPlayer;
	}	
	if(iZombies<iZombiesRemaining&&is_user_alive(g_TargetPlayer2)&&!zp_class_predator_get(g_TargetPlayer2))
	{
		get_user_name(g_TargetPlayer2, name2, charsmax(name2))
		zp_class_predator_set(g_TargetPlayer2)		
		iZombies++;
	}
	if(iZombies<iZombiesRemaining&&is_user_alive(g_TargetPlayer3)&&!zp_class_predator_get(g_TargetPlayer3))
	{
		get_user_name(g_TargetPlayer3, name3, charsmax(name3))
		zp_class_predator_set(g_TargetPlayer3)		
		iZombies++;
	}

	new id;
	while (iZombies < iZombiesRemaining)
	{
		// Choose random guy
		id = GetRandomAlive(random_num(1, iPlayersAlive))
		
		// Already a zombie?
		if (zp_class_predator_get(id))
			continue;
		
		// If not, turn him into one
		zp_class_predator_set(id)
		iZombies++

		if(iZombies==1)
		{
			get_user_name(id, name1, charsmax(name1))			
			id1 = id;
		}
		if (iZombies==2)
		{
			get_user_name(id, name2, charsmax(name2))
		}
		else
		if(iZombies==3)		
		{			
			get_user_name(id, name3, charsmax(name3))
		}	
	}
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Not alive
		if (!is_user_alive(id))
			continue;
		
		// This is our Predator
		if (zp_class_predator_get(id))
			continue;
		
		// Switch to CT
		cs_set_player_team(id, CS_TEAM_CT)
		Player_ResapwnCount[id] = 0
	}

	// Play Predator sound
	if (get_pcvar_num(cvar_predator_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_predator, random_num(0, ArraySize(g_sound_predator) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_predator_show_hud))
	{
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		if (iZombies == 1)
		ShowSyncHudMsg(0, g_HudSync, "%s is a Predator!", name1)
		else if (iZombies == 2)
		ShowSyncHudMsg(0, g_HudSync, "%s & %s are the Predators", name1, name2)
		else if (iZombies == 3)
		ShowSyncHudMsg(0, g_HudSync, "%s , %s & %s are the Predators", name1, name2, name3)
	}
	
	if (iZombies == 1)
	{		
		zp_colored_print(0,"^x03%s^x01 will be released in 5 seconds",name1)
		set_task(5.0,"print",id1);
	}
	else if (iZombies == 2)
	{
		zp_colored_print(0,"^3Predators^1 will be released in^3 5 seconds");
		set_task(5.0,"print",0);
	}
	else if (iZombies == 3)
	{		
		zp_colored_print(0,"^3Predators^1 will be released in^3 5 seconds");
		set_task(5.0,"print",0);
	}
	
	server_cmd("amx_spawnprotect 1")
	server_cmd("amx_spawnprotect_glow 1")
	//server_cmd("amx_spawnprotect_message 1")
	server_cmd("amx_spawnprotect_time 5.0")
	server_exec();
}
/*
public zp_fw_gamemodes_start()
{
	// Turn player into predator
	
	new iPlayersAlive = GetAliveCount(),
	iPlayersRemaining,
	iZombies,
	iZombiesRemaining;
	
	// Remaining players should be humans (CTs)
	
	new id, id1, name[32], szName2[32], szName3[32];
	if(is_user_alive(g_TargetPlayer))
	{
		get_user_name(g_TargetPlayer, name, charsmax(name))
		zp_class_predator_set(g_TargetPlayer)		
		iZombies = 1;
		id1=g_TargetPlayer
	}
	
	if (iPlayersAlive >= 24)
	{
		if(is_user_alive(g_TargetPlayer2)&&!zp_class_predator_get(g_TargetPlayer2))
			zp_class_predator_set(g_TargetPlayer2)
		if(is_user_alive(g_TargetPlayer3)&&!zp_class_predator_get(g_TargetPlayer3))
			zp_class_predator_set(g_TargetPlayer3)
	}
	else if (iPlayersAlive >= 12)
	{
		if(is_user_alive(g_TargetPlayer2))
			zp_class_predator_set(g_TargetPlayer2)
	}
	
	iPlayersRemaining = iPlayersAlive - 1;
	
	if (iPlayersAlive >= 24)
	{
		iZombiesRemaining = 3 - GetPredatorCount();
	}
	else if (iPlayersAlive >= 12)
	{
		iZombiesRemaining = 2 - GetPredatorCount();
	}
	else
		iZombiesRemaining = 1- GetPredatorCount();
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Not alive
		if (!is_user_alive(id))
			continue;
		
		// This is our Predator
		if (zp_class_predator_get(id))
			continue;
		
		// Switch to CT
		cs_set_player_team(id, CS_TEAM_CT)
		Player_ResapwnCount[id] = 0
	}
	
	while (iPlayersRemaining && iZombies <= iZombiesRemaining)
	{
		// Choose random guy
		id = GetRandomAlive(random_num(1, iPlayersAlive))
		
		// Already a zombie?
		if (zp_class_predator_get(id))
			continue;
		
		// If not, turn him into one
		zp_class_predator_set(id)
		iZombies++
		iPlayersRemaining--
		
		// Apply zombie health multiplier
		//fm_set_user_health(id, floatround(float(pev(id, pev_health)) * get_pcvar_float(cvar_plaguesurvhpmulti)))
		
		if(iZombies==1)
		{
			id1=id;
			get_user_name(id, name, charsmax(name))
		}
		if (iZombies==2)
		{
			get_user_name(id, szName2, charsmax(szName2))
		}
		else
		if(iZombies==3)		
		{			
			get_user_name(id, szName3, charsmax(szName3))
		}	
	}

	// Play Predator sound
	if (get_pcvar_num(cvar_predator_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_predator, random_num(0, ArraySize(g_sound_predator) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_predator_show_hud))
	{
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		if (iZombies == 1)
		ShowSyncHudMsg(0, g_HudSync, "%s is a Predator!", name)
		else if (iZombies == 2)
		ShowSyncHudMsg(0, g_HudSync, "%s & %s are the Predators", name, szName2)
		else if (iZombies == 3)
		ShowSyncHudMsg(0, g_HudSync, "%s , %s & %s are the Predators", name, szName2, szName3)
	}
	
	if (iZombies == 1)
	{		
		zp_colored_print(0,"^x03%s^x01 will be released in 5 seconds",name)
		set_task(5.0,"print",id1);
	}
	else if (iZombies == 2)
	{
		zp_colored_print(0,"^3Predators^1 will be released in^3 5 seconds");
		set_task(5.0,"print",0);
	}
	else if (iZombies == 3)
	{		
		zp_colored_print(0,"^3Predators^1 will be released in^3 5 seconds");
		set_task(5.0,"print",0);
	}
	
	server_cmd("amx_spawnprotect 1")
	server_cmd("amx_spawnprotect_glow 1")
	//server_cmd("amx_spawnprotect_message 1")
	server_cmd("amx_spawnprotect_time 5.0")
	server_exec();
}*/

public zp_fw_gamemodes_end()
{	
	server_cmd("amx_spawnprotect 0")
	server_cmd("amx_spawnprotect_glow 0")
	//server_cmd("amx_spawnprotect_message 0")
	server_cmd("amx_spawnprotect_time 0.0")
	server_exec();
}

public print(id)
{
	if(!id)
	{
		zp_colored_print(0,"^3Predators^1 are released!");
		return;
	}	
	
	if(!is_user_alive(id))
	{
		return;
	}
	if(!zp_class_predator_get(id))
	{
		return;
	}
	new name[32]
	get_user_name(id,name,charsmax(name))
	zp_colored_print(0,"^3%s^1 is released!",name);

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
public client_death(killer,victim,wpnindex,hitplace,TK)
{
	if(is_user_connected(victim)&&!zp_core_is_zombie(victim))
	{
		if(Player_ResapwnCount[victim] < zp_class_predator_get_count() - 1)
		{
			Player_ResapwnCount[victim] += 1
			set_task(3.0,"do_respawn", victim)
			zp_colored_print(victim,"You have^3 %d %s^1 left, don't die!", zp_class_predator_get_count() - Player_ResapwnCount[victim],(zp_class_predator_get_count() - Player_ResapwnCount[victim]==1)?"Life":"Lives")
		}
	}
}
public do_respawn(id)
{
	zp_respawn_user(id, ZP_TEAM_HUMAN)
}

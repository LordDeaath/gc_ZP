/*================================================================================
	
	---------------------------------
	-*- [ZP] Game Mode: Infection -*-
	---------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <cs_teams_api>
#include <cs_ham_bots_api>
#include <zp50_gamemodes>
#include <zp50_deathmatch>
#include <zp50_colorchat>
native zp_is_apocalypse();

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 255
#define HUD_EVENT_G 0
#define HUD_EVENT_B 0

new g_MaxPlayers
new g_HudSync
new g_TargetPlayer, iFirstZombi[33]

new cvar_infection_chance, cvar_infection_min_players
new cvar_infection_show_hud
new cvar_infection_allow_respawn, cvar_respawn_after_last_human
new cvar_zombie_first_hp_multiplier

public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Infection", ZP_VERSION_STRING, "ZP Dev Team")
	new game_mode_id = zp_gamemodes_register("Infection Mode")
	zp_gamemodes_set_default(game_mode_id)
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_infection_chance = register_cvar("zp_infection_chance", "1")
	cvar_infection_min_players = register_cvar("zp_infection_min_players", "0")
	cvar_infection_show_hud = register_cvar("zp_infection_show_hud", "1")
	cvar_infection_allow_respawn = register_cvar("zp_infection_allow_respawn", "1")
	cvar_respawn_after_last_human = register_cvar("zp_respawn_after_last_human", "0")
	cvar_zombie_first_hp_multiplier = register_cvar("zp_zombie_first_hp_multiplier", "2.0")
}
public plugin_natives()
{
	register_native("zp_mark_as_first_zombie", "mark_as_first_zombie",1)
	register_native("zp_is_first_zombie", "is_first_zombie",1)
}

public mark_as_first_zombie(id)
	iFirstZombi[id] = 1
public is_first_zombie(id)
	return iFirstZombi;
	
// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_infection_allow_respawn))
		return PLUGIN_HANDLED;
	
	// Respawn if only the last human is left?
	if ((!get_pcvar_num(cvar_respawn_after_last_human) && zp_core_get_human_count() == 1)&&!zp_is_apocalypse())
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_infection_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// Min players
		if (GetAliveCount() < get_pcvar_num(cvar_infection_min_players))
			return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_post(game_mode_id, target_player)
{
	// Pick player randomly?
	g_TargetPlayer = (target_player == RANDOM_TARGET_PLAYER) ? GetRandomAlive(random_num(1, GetAliveCount())) : target_player
}

public zp_fw_gamemodes_start()
{
	if(g_TargetPlayer==-1)
		return;
	
	// Allow infection for this game mode
	zp_gamemodes_set_allow_infect()
	
	// Field Part ?
	new iPlayersAlive = GetAliveCount(),
	iPlayersRemaining,
	iZombies,
	iZombiesRemaining;
	// Turn player into the first zombie
	zp_core_infect(g_TargetPlayer, g_TargetPlayer) // victim = atttacker so that infection sound is played
	set_user_health(g_TargetPlayer, floatround(get_user_health(g_TargetPlayer) * get_pcvar_float(cvar_zombie_first_hp_multiplier)))
	//Block_Antidote(g_TargetPlayer, FIRSTZM)
	mark_as_first_zombie(g_TargetPlayer)

	iZombies = 1;
	iPlayersRemaining = iPlayersAlive - 1;
	
	switch(iPlayersAlive)
	{
		case 6..12: iZombiesRemaining = 1
		case 13..25: iZombiesRemaining = 2
		case 26..32: iZombiesRemaining = 3
		default: iZombiesRemaining = 0
	}
	
	new id, name[32], szName2[32], szName3[32], szName4[32];
	
	while (iPlayersRemaining && iZombies <= iZombiesRemaining) //iMaxSurvivors
	{
		// Choose random guy
		id = GetRandomAlive(random_num(1, iPlayersAlive))
		
		// Already a zombie?
		if (zp_core_is_zombie(id))
			continue;
		
		// If not, turn him into one
		zp_core_infect(id, id)
		mark_as_first_zombie(id)
		set_user_health(id, get_user_health(id) + ( 150 * iPlayersRemaining * GetAliveCount() ) )
		iZombies++
		iPlayersRemaining--
		// Apply zombie health multiplier
		//fm_set_user_health(id, floatround(float(pev(id, pev_health)) * get_pcvar_float(cvar_plaguesurvhpmulti)))
		
		switch(iZombies)
		{
			case 2: get_user_name(id, szName2, charsmax(szName2))
			case 3: get_user_name(id, szName3, charsmax(szName3))
			case 4: get_user_name(id, szName3, charsmax(szName4))
		}
	}
	
	// Remaining players should be humans (CTs)
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Not alive
		if (!is_user_alive(id))
			continue;
		
		// This is our first zombie
		if (zp_core_is_zombie(id))
			continue;
		
		// Switch to CT
		cs_set_player_team(id, CS_TEAM_CT)
	}
	get_user_name(g_TargetPlayer, name, charsmax(name))
	if (get_pcvar_num(cvar_infection_show_hud))
	{
		// Show First Zombie HUD notice
		//new name[32]
		
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
		switch(iZombies)
		{
			case 1: ShowSyncHudMsg(0, g_HudSync, "%s is the infected zombie!", name)
			case 2: ShowSyncHudMsg(0, g_HudSync, "%s and %s are the infected zombies!", name, szName2)
			case 3: ShowSyncHudMsg(0, g_HudSync, "%s , %s and %s are the infected zombies!", name, szName2, szName3)
			case 4: ShowSyncHudMsg(0, g_HudSync, "%s , %s , %s and %s are the infected zombies!", name, szName2, szName3, szName4)
		}
	}
	switch(iZombies)
	{
		case 1: zp_colored_print(0, "^3%s^1 is the infected zombie !", name)
		case 2: zp_colored_print(0, "^3%s^4 and ^3%s^1 are the infected zombies!", name, szName2)
		case 3: zp_colored_print(0, "^3%s^4 , ^3%s^4 and ^3%s^1 are the infected zombies!", name, szName2, szName3)
		case 4: zp_colored_print(0, "^3%s^4 , ^3%s^4 , ^3%s^1 and ^3%s^1 are the infected zombies!", name, szName2, szName3, szName4)
	}
	/*
	if (iZombies == 1)
		zp_colored_print(0, "^x03%s^x01 is the infected zombie !", name)
	else if (iZombies == 2)
		zp_colored_print(0, "^x03%s^x04 and ^x03%s^x01 are the infected zombies !", name, szName2)
	else if (iZombies == 3)
		zp_colored_print(0, "^x03%s^x04 , ^x03%s^x04 and ^x03%s^x01 are the infected zombies !", name, szName2, szName3)
	*/
	//CheckRespawn();	
}
/*
public client_putinserver(id)
{
	CheckRespawn();
}

public client_disconnect(id)
{
	CheckRespawn();
}

CheckRespawn()
{
	new iConnected, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_connected(id))
			iConnected++
	}
	if(iConnected>14)
	{
		set_pcvar_num(cvar_respawn_after_last_human, 0)
	}
	else
	{
		set_pcvar_num(cvar_respawn_after_last_human, 1)
	}
}*/


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
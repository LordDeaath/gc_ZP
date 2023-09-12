#include <amxmodx>
#include <cstrike>
#include <fun>
#include <amx_settings_api>
#include <cs_teams_api>
#include <zp50_gamemodes>
#include <zp50_class_knifer>
#include <zp50_class_plasma>
#include <zp50_deathmatch>
#include <hamsandwich>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_sva[][] = { "zombie_plague/nemesis1.wav" , "zombie_plague/survivor1.wav" }

#define SOUND_MAX_LENGTH 64

new Array:g_sound_sva

#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 0
#define HUD_EVENT_G 50
#define HUD_EVENT_B 200

new g_MaxPlayers
new g_HudSync
new g_LValue[2]

new cvar_sva_chance, cvar_sva_min_players
new cvar_sva_ratio
new cvar_sva_sniper_hp_multi, cvar_sva_nemesis_hp_multi
new cvar_sva_show_hud, cvar_sva_sounds
new cvar_sva_allow_respawn, IsPvK

public plugin_end()
{
	ArrayDestroy(g_sound_sva)
}

public plugin_precache()
{
	register_plugin("[ZP] Game Mode: Sniper vs Nemesis", ZP_VERSION_STRING, "zmd94")
	zp_gamemodes_register("Plasma vs Knifer")
	
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	RegisterHam(Ham_TakeDamage,"player","fw_dm_pr",0)
	
	cvar_sva_chance = register_cvar("zp_sva_chance", "20")
	cvar_sva_min_players = register_cvar("zp_sva_min_players", "0")
	cvar_sva_ratio = register_cvar("zp_pvk_ratio", "0.5")
	cvar_sva_sniper_hp_multi = register_cvar("zp_sva_plasma_hp_multi", "0.25")
	cvar_sva_nemesis_hp_multi = register_cvar("zp_sva_knifer_hp_multi", "0.25")
	cvar_sva_show_hud = register_cvar("zp_sva_show_hud", "1")
	cvar_sva_sounds = register_cvar("zp_sva_sounds", "1")
	cvar_sva_allow_respawn = register_cvar("zp_sva_allow_respawn", "0")
	
	// Initialize arrays
	g_sound_sva = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND SVA", g_sound_sva)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_sva) == 0)
	{
		for (index = 0; index < sizeof sound_sva; index++)
			ArrayPushString(g_sound_sva, sound_sva[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND SVA", g_sound_sva)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_sva); index++)
	{
		ArrayGetString(g_sound_sva, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
}

public zp_fw_deathmatch_respawn_pre(id)
{
	if (!get_pcvar_num(cvar_sva_allow_respawn))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		if (random_num(1, get_pcvar_num(cvar_sva_chance)) != 1)
			return PLUGIN_HANDLED;
		
		if (GetAliveCount() < get_pcvar_num(cvar_sva_min_players))
			return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
public fw_dm_pr(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(IsPvK!=1)
		return HAM_HANDLED
	if(zp_class_plasma_get(victim) && zp_class_plasma_get(attacker))
		return HAM_SUPERCEDE
	if(zp_class_knifer_get(victim) && zp_class_knifer_get(attacker))
		return HAM_SUPERCEDE	
	return HAM_HANDLED		
}
public zp_fw_gamemodes_start()
{
	new id, alive_count = GetAliveCount()
	new sniper_count = floatround(alive_count * get_pcvar_float(cvar_sva_ratio), floatround_ceil)
	new nemesis_count = alive_count - sniper_count	
	new iSnipers, iMaxSnipers = sniper_count
	IsPvK=1
	while (iSnipers < iMaxSnipers)
	{
		id = GetRandomAlive(random_num(1, alive_count))
		
		if (zp_class_knifer_get(id))
			continue;
		
		zp_class_knifer_set(id)
		iSnipers++
		cs_set_player_team(id, CS_TEAM_T)
		set_user_health(id, floatround(get_user_health(id) * get_pcvar_float(cvar_sva_sniper_hp_multi)))
	}
	new iNemesis, iMaxNemesis = nemesis_count
	while (iNemesis < iMaxNemesis)
	{
		id = GetRandomAlive(random_num(1, alive_count))
		
		if (zp_class_knifer_get(id) || zp_class_plasma_get(id))
			continue;
		
		zp_class_plasma_set(id)
		iNemesis++
		
		set_user_health(id, floatround(get_user_health(id) * get_pcvar_float(cvar_sva_nemesis_hp_multi)))
	}
	
	if (get_pcvar_num(cvar_sva_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_sva, random_num(0, ArraySize(g_sound_sva) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_sva_show_hud))
	{
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "Plasma vs Knifer!")
	}
	set_task(3.0,"CheckTeamCount")
	server_cmd("mp_freeforall 1")
	server_cmd("mp_round_infinite bcdefg")
	
}
public CheckTeamCount()
{
	if(!zp_class_plasma_get_count())
	{
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "Knifers won!")
		server_cmd("endround")
		server_cmd("mp_freeforall 0")
		server_cmd("mp_round_infinite 0")
		IsPvK=0
	}
	if(!zp_class_knifer_get_count())
	{
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "Plasma won!")
		server_cmd("endround")
		server_cmd("mp_freeforall 0")
		server_cmd("mp_round_infinite 0")
		IsPvK=0
	}
	if(IsPvK)
		set_task(1.0,"CheckTeamCount")
}

PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}

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

public zp_fw_gamemodes_end()
{
	new cfgdir[32]
	get_configsdir(cfgdir, charsmax(cfgdir))
	server_cmd("exec %s/zombieplague.cfg", cfgdir)
}

stock get_configsdir(name[],len)
{
    return get_localinfo("amxx_configsdir",name,len);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
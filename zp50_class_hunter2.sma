/*================================================================================
	
	---------------------------
	-*- [ZP] Class: Hunter -*-
	---------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_maxspeed_api>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <cs_ham_bots_api>
#include <zp50_core>
#define LIBRARY_GRENADE_FROST "zp50_grenade_frost"
#include <zp50_grenade_frost>
#define LIBRARY_GRENADE_FIRE "zp50_grenade_fire"
#include <zp50_grenade_fire>
#include <zp50_gamemodes>
#include <zp50_items>
#include <zp50_log>
#include <zp50_colorchat>
#include <colorchat>

//#define ADDRESS "74.91.116.201:27015"

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default models
new const models_hunter_player[][] = { "zombie_source" }
new const models_hunter_claw[][] = { "models/zombie_plague/v_knife_zombie.mdl" }

#define PLAYERMODEL_MAX_LENGTH 32
#define MODEL_MAX_LENGTH 64

// Custom models
new Array:g_models_hunter_player
new Array:g_models_hunter_claw

#define TASK_AURA 100
#define ID_AURA (taskid - TASK_AURA)
const UNIT_SECOND = 		(1<<12)
const FFADE_IN = 		0x0000

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))
new const zclass_ring_sprite[] = "sprites/shockwave.spr" // ring sprite
new const zclass_screamsounds[][] = { "killing_floor/siren_scream.wav" } // scream sound
new zclass_ring_colors[3] = {255, 0, 0}

new g_MaxPlayers, g_iPlayerTaskTimes[33]
new g_IsHunter, g_GameModeSniperID

new cvar_hunter_health, cvar_hunter_base_health, cvar_hunter_speed, cvar_hunter_gravity, cvar_force
new cvar_hunter_glow, cvar_painshockfree_hunter, bool:IsActive[33], Float:pCooldown[33], cvar_cooldown, cvar_duration
new cvar_hunter_aura, cvar_hunter_aura_color_R, cvar_hunter_aura_color_G, cvar_hunter_aura_color_B
new cvar_hunter_damage, cvar_hunter_kill_explode
new cvar_hunter_grenade_frost, cvar_hunter_grenade_fire
new bool:g_bCannotBeFrozen[33], g_msgScreenFade, g_msgScreenShake, g_sprRing, g_bDoingScream[33], g_bCanDoScreams[33] 
new g_i_CacheGibsMdl;

new cvar_frost_duration,frost_duration
public plugin_init()
{
	register_plugin("[ZP] Class: Hunter", ZP_VERSION_STRING, "ZP Dev Team")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamagePost",1)
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_MaxPlayers = get_maxplayers()
	
	cvar_hunter_health = register_cvar("zp_hunter_health", "0")
	cvar_hunter_base_health = register_cvar("zp_hunter_base_health", "2000")
	cvar_hunter_speed = register_cvar("zp_hunter_speed", "1.05")
	cvar_hunter_gravity = register_cvar("zp_hunter_gravity", "0.5")
	cvar_hunter_glow = register_cvar("zp_hunter_glow", "1")
	cvar_hunter_aura = register_cvar("zp_hunter_aura", "1")
	cvar_hunter_aura_color_R = register_cvar("zp_hunter_aura_color_R", "150")
	cvar_hunter_aura_color_G = register_cvar("zp_hunter_aura_color_G", "0")
	cvar_hunter_aura_color_B = register_cvar("zp_hunter_aura_color_B", "0")
	cvar_hunter_damage = register_cvar("zp_hunter_damage", "2.0")
	cvar_hunter_kill_explode = register_cvar("zp_hunter_kill_explode", "1")
	cvar_hunter_grenade_frost = register_cvar("zp_hunter_grenade_frost", "0")
	cvar_hunter_grenade_fire = register_cvar("zp_hunter_grenade_fire", "1")
	cvar_cooldown = register_cvar("zp_attract_cooldown", "50")
	cvar_force = register_cvar("zp_attract_force", "200")
	cvar_duration = register_cvar("zp_attract_duration", "5")
	cvar_painshockfree_hunter = register_cvar("zp_painshockfree_hunter", "1")
	register_concmd("zp_hunter", "cmd_hunter", ADMIN_CFG, "<target> - Turn someone into a hunter", 0)
	register_clcmd("drop", "Skillo")
	//Protection
//////////////////////////////////////
	/*static address[32]
	get_cvar_string("net_address", address, charsmax(address))
	if (!equal(ADDRESS, address)) set_fail_state("Private Plugin :)")*/
//////////////////////////////////////
}

public plugin_end()
{	
	ArrayDestroy(g_models_hunter_player)
	ArrayDestroy(g_models_hunter_claw)
}
public plugin_cfg()
{
	g_GameModeSniperID = zp_gamemodes_get_id("Hunter Mode")
}
public plugin_precache()
{
	g_i_CacheGibsMdl = precache_model("models/hgibs.mdl")
	// Initialize arrays
	g_models_hunter_player = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_hunter_claw = ArrayCreate(MODEL_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "HUNTER", g_models_hunter_player)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE HUNTER", g_models_hunter_claw)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_models_hunter_player) == 0)
	{
		for (index = 0; index < sizeof models_hunter_player; index++)
			ArrayPushString(g_models_hunter_player, models_hunter_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "HUNTER", g_models_hunter_player)
	}
	if (ArraySize(g_models_hunter_claw) == 0)
	{
		for (index = 0; index < sizeof models_hunter_claw; index++)
			ArrayPushString(g_models_hunter_claw, models_hunter_claw[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE HUNTER", g_models_hunter_claw)
	}
	
	// Precache models
	new player_model[PLAYERMODEL_MAX_LENGTH], model[MODEL_MAX_LENGTH], model_path[128]
	for (index = 0; index < ArraySize(g_models_hunter_player); index++)
	{
		ArrayGetString(g_models_hunter_player, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_generic(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_generic(model_path)
	}
	for (index = 0; index < ArraySize(g_models_hunter_claw); index++)
	{
		ArrayGetString(g_models_hunter_claw, index, model, charsmax(model))
		precache_model(model)
	}
	// Ring sprite
	g_sprRing = precache_model(zclass_ring_sprite)
	
	// Sounds
	static i
	for(i = 0; i < sizeof zclass_screamsounds; i++)
		precache_sound(zclass_screamsounds[i])

}


public plugin_natives()
{
	register_library("zp50_class_hunter")
	register_native("zp_class_hunter_get", "native_class_hunter_get")
	register_native("zp_class_hunter_set", "native_class_hunter_set")
	register_native("zp_class_hunter_get_count", "native_class_hunter_get_count")
	
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_GRENADE_FROST) || equal(module, LIBRARY_GRENADE_FIRE))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public client_disconnected(id)
{
	if (flag_get(g_IsHunter, id))
	{
		// Remove hunter glow
		if (get_pcvar_num(cvar_hunter_glow))
			set_user_rendering(id)
		
		// Remove hunter aura
		if (get_pcvar_num(cvar_hunter_aura))
			remove_task(id+TASK_AURA)
	}
}

public fw_ClientDisconnect_Post(id)
{
	// Reset flags AFTER disconnect (to allow checking if the player was hunter before disconnecting)
	flag_unset(g_IsHunter, id)
}
public fw_TakeDamagePost(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(get_pcvar_num(cvar_painshockfree_hunter) && flag_get(g_IsHunter, victim))
		set_pdata_float(victim, 108, 0.9, 5 );
}
// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Hunter attacking human
	if (flag_get(g_IsHunter, attacker))
	{
		// Ignore hunter damage override if damage comes from a 3rd party entity
		// (to prevent this from affecting a sub-plugin's rockets e.g.)
		if (inflictor == attacker)
		{
			if(damage > 35.0)
				SetHamParamFloat(4, get_pcvar_float(cvar_hunter_damage))
			return HAM_HANDLED;
		}
	}
	
	return HAM_IGNORED;
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (flag_get(g_IsHunter, victim))
	{
		// Hunter explodes!
		if (get_pcvar_num(cvar_hunter_kill_explode))
			SetHamParamInteger(3, 2)
		
		// Remove hunter aura
		if (get_pcvar_num(cvar_hunter_aura))
			remove_task(victim+TASK_AURA)
	}
	else
	if (flag_get(g_IsHunter, attacker))
	{	
		new i_v_Origin[3]
		get_user_origin(victim,i_v_Origin)
		
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(10);
		write_coord(i_v_Origin[0]);
		write_coord(i_v_Origin[1]);
		write_coord(i_v_Origin[2]);
		message_end();
		
		message_begin(MSG_PVS,SVC_TEMPENTITY, i_v_Origin)
		{
			write_byte(TE_BREAKMODEL)
			
			write_coord(i_v_Origin[0])
			write_coord(i_v_Origin[1])
			write_coord(i_v_Origin[2] + 16)
			
			write_coord(32)
			write_coord(32)
			write_coord(32)
			
			write_coord(0)
			write_coord(0)
			write_coord(25)
			
			write_byte(10)
			
			write_short(g_i_CacheGibsMdl)
			
			write_byte(8)
			write_byte(30)
			
			write_byte(1)
		}
		message_end()
		SetHamParamInteger(3, 2)
	}
}

public zp_fw_grenade_frost_pre(id)
{
	// Prevent frost for Hunter
	if (g_bCannotBeFrozen[id] && flag_get(g_IsHunter, id) && !get_pcvar_num(cvar_hunter_grenade_frost))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_grenade_fire_pre(id)
{
	// Prevent burning for Hunter
	if (flag_get(g_IsHunter, id) && !get_pcvar_num(cvar_hunter_grenade_fire))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(id)
{
	if (flag_get(g_IsHunter, id))
	{
		// Remove hunter glow
		if (get_pcvar_num(cvar_hunter_glow))
			set_user_rendering(id)
		
		// Remove hunter aura
		if (get_pcvar_num(cvar_hunter_aura))
			remove_task(id+TASK_AURA)
		
		// Remove hunter flag
		flag_unset(g_IsHunter, id)
	}
}

public zp_fw_core_cure(id, attacker)
{
	if (flag_get(g_IsHunter, id))
	{
		// Remove hunter glow
		if (get_pcvar_num(cvar_hunter_glow))
			set_user_rendering(id)
		
		// Remove hunter aura
		if (get_pcvar_num(cvar_hunter_aura))
			remove_task(id+TASK_AURA)
		
		// Remove hunter flag
		flag_unset(g_IsHunter, id)
	}
}

public zp_fw_core_infect_post(id, attacker)
{
	// Apply Hunter attributes?
	if (!flag_get(g_IsHunter, id))
		return;
	
	
	if (get_pcvar_num(cvar_hunter_health) == 0)
		set_user_health(id, get_pcvar_num(cvar_hunter_base_health) * GetAliveCount())		
	else
		set_user_health(id, get_pcvar_num(cvar_hunter_health))			
	// Gravity
	set_user_gravity(id, get_pcvar_float(cvar_hunter_gravity))
	
	// Speed
	cs_set_player_maxspeed_auto(id, get_pcvar_float(cvar_hunter_speed))
	
	// Apply hunter player model
	new player_model[PLAYERMODEL_MAX_LENGTH]
	ArrayGetString(g_models_hunter_player, random_num(0, ArraySize(g_models_hunter_player) - 1), player_model, charsmax(player_model))
	cs_set_player_model(id, player_model)
	
	// Apply hunter claw model
	new model[MODEL_MAX_LENGTH]
	ArrayGetString(g_models_hunter_claw, random_num(0, ArraySize(g_models_hunter_claw) - 1), model, charsmax(model))
	cs_set_player_view_model(id, CSW_KNIFE, model)	
	
	// Hunter glow
	if (get_pcvar_num(cvar_hunter_glow))
		set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 25)
	
	// Hunter aura task
	if (get_pcvar_num(cvar_hunter_aura))
		set_task(0.1, "hunter_aura", id+TASK_AURA, _, _, "b")	
	g_iPlayerTaskTimes[id] = 0
	g_bDoingScream[id] = 0
	g_bCanDoScreams[id] = 0
	// Freeze the hunter. ;)
	// So, all humans can run away!	
//	g_bCannotBeFrozen[id]=true;
//	
//	new name[32]
//	get_user_name(id, name, charsmax(name))
//	set_pcvar_num(cvar_frost_duration, 10)
//	set_task(10.0, "DisableFrozenForHunter", id)		
//	ColorChat(0,GREEN,"[GC]^3 %s^1 will be released in 10 seconds",name)
//	zp_grenade_frost_set(id)
//	set_pcvar_num(cvar_frost_duration, frost_duration)
	ColorChat(id,GREEN,"GC |^3 Activate your ^4Attraction^3 Skill by pressing G!")
	ColorChat(id,GREEN,"GC |^3 Activate your ^4Scream^3 Skill by pressing E!")
	ColorChat(id,GREEN,"GC |^3 Activate your ^4Attraction^3 Skill by pressing G!")
	ColorChat(id,GREEN,"GC |^3 Activate your ^4Scream^3 Skill by pressing E!")
	// Set task to enable hunter for not being frozen after X seconds
	
	
}
public DisableFrozenForHunter(id)
{
	if(is_user_connected(id))
	{
		if(is_user_alive(id) && flag_get(g_IsHunter, id))
		{
		new name[32]
		get_user_name(id, name, charsmax(name))
		// Now hunter cannot be frozen
		g_bCannotBeFrozen[id] = false
		//zp_grenade_frost_set(id,false)
		//if(zp_gamemodes_get_current()!=Sniper)	
		ColorChat(0,GREEN,"[GC]^3 %s^1 is released!",name)
		}
	}
}

public native_class_hunter_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsHunter, id);
}

public native_class_hunter_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_IsHunter, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a hunter (%d)", id)
		return false;
	}
	
	flag_set(g_IsHunter, id)
	zp_core_force_infect(id)
	return true;
}
public local_class(id)
{

	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_IsHunter, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a hunter (%d)", id)
		return false;
	}
	
	flag_set(g_IsHunter, id)
	zp_core_force_infect(id)
	return true;
}
public native_class_hunter_get_count(plugin_id, num_params)
{
	return GetHunterCount();
}

// Hunter aura task
public hunter_aura(taskid)
{
	// Get player's origin
	static origin[3]
	get_user_origin(ID_AURA, origin)
	
	// Colored Aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(20) // radius
	write_byte(get_pcvar_num(cvar_hunter_aura_color_R)) // r
	write_byte(get_pcvar_num(cvar_hunter_aura_color_G)) // g
	write_byte(get_pcvar_num(cvar_hunter_aura_color_B)) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}
// zp_hunter [target]
public cmd_hunter(id, level, cid)
{
	// Check for access flag - Make sniper
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	// Retrieve arguments
	new arg[32], player
	read_argv(1, arg, charsmax(arg))
	player = cmd_target(id, arg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF))
	
	// Invalid target
	if (!player) 
		return PLUGIN_HANDLED;
	
	// Target not allowed to be sniper
	if (flag_get(g_IsHunter, player))
	{
		new player_name[32]
		get_user_name(player, player_name, charsmax(player_name))
		client_print(id, print_console, "[ZP] (%s) is alreeady a hunter", player_name)
		return PLUGIN_HANDLED;
	}
	
	command_hunter(id, player)
	return PLUGIN_HANDLED;
}
public zp_fw_items_select_pre(id, itm, c)
{
	new zpMad = zp_items_get_id("Zombie Madness")
	if (!flag_get(g_IsHunter, id))
		return ZP_ITEM_AVAILABLE
	if(itm == zpMad)
		return ZP_ITEM_NOT_AVAILABLE
		
	return ZP_ITEM_AVAILABLE
	
}

command_hunter(id, player)
{
	// Prevent infecting last zombie
	if (zp_core_is_last_zombie(player))
	{
		zp_colored_print(id, "%L", id, "CMD_CANT_LAST_ZOMBIE")
		return;
	}
	
	// Check if a game mode is in progress
	if (zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
	{
		// sniper mode disabled
		if (g_GameModeSniperID == ZP_INVALID_GAME_MODE)
		{
			zp_colored_print(id, "%L", id, "CMD_ONLY_AFTER_GAME_MODE")
			return;
		}
		
		// Start sniper game mode with this target player
		if (!zp_gamemodes_start(g_GameModeSniperID, player))
		{
			zp_colored_print(id, "%L", id, "GAME_MODE_CANT_START")
			return;
		}
	}
	else
	{
		// Make player sniper
		local_class(player)
	}
	
	// Get user names
	new admin_name[32], player_name[32]
	get_user_name(id, admin_name, charsmax(admin_name))
	get_user_name(player, player_name, charsmax(player_name))
	
	zp_colored_print(0, "ADMIN %s turned %s into a hunter", admin_name, player_name)
	
	// Log to Zombie Plague log file?
	new authid[32], ip[16]
	get_user_authid(id, authid, charsmax(authid))
	get_user_ip(id, ip, charsmax(ip), 1)
	zp_log("ADMIN %s <%s> - <%s> turn into a hunter (PlayersA: %d)", admin_name, authid, player_name, GetAliveCount())
}

//Skill stuff
public Skillo(id)
{
	if(!is_user_connected(id))
		return;
	if(!is_user_alive(id))
		return;
	if (!flag_get(g_IsHunter, id))
		return;
		
	static Float:gTime, Float:cTime, Float:dTime, iRandom
	gTime = get_gametime()
	cTime = get_pcvar_float(cvar_cooldown)
	dTime = get_pcvar_float(cvar_duration)
	iRandom = random(1)
	if(gTime - cTime >= pCooldown[id])
	{
		if(iRandom)
		{
			set_task(0.1,"StartAttAim", id,_,_,"a",50)	
			ColorChat(id,GREEN,"GC |^3 You've activated your ^4Attraction^3 Skill!")
			ColorChat(0,GREEN,"GC |^3 Hunter activated thier  ^4Attraction^3 Skill!")
		}
		else
		{
			set_task(0.1,"StartAtt", id,_,_,"a",50)
			ColorChat(id,GREEN,"GC |^3 You've activated your ^4Sucktion^3 Skill!")
			ColorChat(0,GREEN,"GC |^3 Hunter activated thier  ^4Sucktion^3 Skill!")
		}
		set_task(dTime, "StopAtt", id)
		pCooldown[id] = gTime
		IsActive[id] = true
	}
	else
		ColorChat(id,GREEN,"GC |^3 Please wait^4 [%d s]^3 before using your ^4Skill^3 again!",floatround(pCooldown[id]- gTime +cTime)+1)

}
public fw_CmdStart(id, handle, random_seed)
{
	// Not alive
	if(!is_user_alive(id))
		return FMRES_IGNORED;
	
	// Isn't a hunter?
	if (!flag_get(g_IsHunter, id))
		return FMRES_IGNORED;
		
	// Get user old and actual buttons
	static iInUseButton, iInUseOldButton
	iInUseButton = (get_uc(handle, UC_Buttons) & IN_USE)
	iInUseOldButton = (get_user_oldbutton(id) & IN_USE)
	if(iInUseButton)
	{
		// Last used button isn't +use, i need to
		// do this, because i call this "only" 1 time
		if(!iInUseOldButton && !g_bCanDoScreams[id] && !g_bDoingScream[id])
			set_task(0.5, "task_do_scream", id+1000)
	}
	return FMRES_IGNORED;
}
public task_do_scream(id)
{
	// Normalize task
	id -= 1000
	
	// Do scream sound
	emit_sound(id, CHAN_STREAM, zclass_screamsounds[random_num(0, sizeof zclass_screamsounds - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	g_bCanDoScreams[id] = 1
	set_task(25.0, "task_reload_scream", id+2000)
	g_bDoingScream[id] = 1
	// Do a good effect, life the original Killing Floor.

	// Get his origin coords
	static iOrigin[3]
	get_user_origin(id, iOrigin)
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin) 
	write_byte(TE_LAVASPLASH)
	write_coord(iOrigin[0]) 
	write_coord(iOrigin[1]) 
	write_coord(iOrigin[2]) 
	message_end()
	set_task(0.1, "task_scream_process", id+3000, _, _, "b")		
}
public task_reload_scream(id)
{
	id -= 2000
	g_bCanDoScreams[id] = 0
	// Message
	ColorChat(id,GREEN, "[Hunter]^3 Scream ^4Ready^3 you can do ^4Screams^3 again by pressing^4 +use")
}
public task_scream_process(id)
{
	id -= 3000
	if(g_iPlayerTaskTimes[id] >= (5*5) )	
	{
		// Remove player task
		if(task_exists(id+3000))
			remove_task(id+3000)
		
		// Reset task times count
		g_iPlayerTaskTimes[id] = 0
		
		// Update bool
		g_bDoingScream[id] = 0
		
		return;
	}
	g_iPlayerTaskTimes[id]++
	
	// Get player origin
	static Float:flOrigin[3]
	entity_get_vector(id, EV_VEC_origin, flOrigin)
	
	// Collisions
	static iVictim
	iVictim = -1
	// A ring effect
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, flOrigin[0]) // x
	engfunc(EngFunc_WriteCoord, flOrigin[1]) // y
	engfunc(EngFunc_WriteCoord, flOrigin[2]) // z
	engfunc(EngFunc_WriteCoord, flOrigin[0]) // x axis
	engfunc(EngFunc_WriteCoord, flOrigin[1]) // y axis
	engfunc(EngFunc_WriteCoord, flOrigin[2] + 256) // z axis
	write_short(g_sprRing) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(10) // life
	write_byte(25) // width
	write_byte(0) // noise
	write_byte(zclass_ring_colors[0]) // red
	write_byte(zclass_ring_colors[1]) // green
	write_byte(zclass_ring_colors[2]) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	// Screen effects for him self
	screen_effects(id)
	// Do scream effects
	while((iVictim = find_ent_in_sphere(iVictim, flOrigin, 256.0)) != 0)
	{
		if(!is_user_alive(iVictim))
			continue;
		if(zp_core_is_zombie(iVictim))
			continue;
		ExecuteHamB(Ham_TakeDamage, iVictim, id, id, 10.0, DMG_BULLET)
		screen_effects(iVictim)
	}
}
screen_effects(id)
{
	// Screen Fade
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
	write_short(UNIT_SECOND*1) // duration
	write_short(UNIT_SECOND*1) // hold time
	write_short(FFADE_IN) // fade type
	write_byte(200) // r
	write_byte(0) // g
	write_byte(0) // b
	write_byte(125) // alpha
	message_end()
	
	// Screen Shake
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short(UNIT_SECOND*5) // amplitude
	write_short(UNIT_SECOND*1) // duration
	write_short(UNIT_SECOND*5) // frequency
	message_end()
}

public StopAtt(id)
	IsActive[id] = false
public StartAttAim(id)
{
	static Float:pOr[3], Float:tOr[3], Float: AttSpd
	AttSpd = get_pcvar_float(cvar_force)
	entity_get_vector(id, EV_VEC_origin, pOr)
	for(new pl;pl < get_maxplayers();pl++)
	{
		if(pl == id)
			continue
		if(!is_user_alive(pl))
			continue
		entity_get_vector(pl, EV_VEC_origin, tOr)
		if(get_distance_f(tOr,pOr) >= 256.0)
			continue
		Aim_To(pl,pOr)
	}
}
public StartAtt(id)
{
	static Float:pOr[3], Float:tOr[3], Float: AttSpd
	AttSpd = get_pcvar_float(cvar_force)
	entity_get_vector(id, EV_VEC_origin, pOr)
	for(new pl;pl < get_maxplayers();pl++)
	{
		if(pl == id)
			continue
		if(!is_user_alive(pl))
			continue
		entity_get_vector(pl, EV_VEC_origin, tOr)
		if(get_distance_f(tOr,pOr) >= 256.0)
			continue
		hook(pl,pOr,AttSpd)
	}
}
		
public Aim_To(ent, Float:Origin[3]) 
{
	if(is_valid_ent(ent)!=1)	
		return
	static Float:Vec[3], Float:Angles[3]
	entity_get_vector(ent,EV_VEC_origin,Vec)
	Vec[0] = Origin[0] - Vec[0]
	Vec[1] = Origin[1] - Vec[1]
	Vec[2] = Origin[2] - Vec[2]
	engfunc(EngFunc_VecToAngles, Vec, Angles)
	Angles[0] = Angles[2] = 0.0
	entity_set_vector(ent, EV_VEC_angles, Angles)
	entity_set_vector(ent, EV_VEC_v_angle, Angles)
	//ColorChat(0,GREEN,"a3")

}
stock hook(ent, Float:VicOrigin[3], Float:speed)
{
	if(pev_valid(ent)!=2)
		return
	
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
		
	fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
	fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
	fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time

	set_pev(ent, pev_velocity, fl_Velocity)
	//ColorChat(0,GREEN,"a4")
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

// Get Hunter Count -returns alive hunter number-
GetHunterCount()
{
	new iHunter, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && flag_get(g_IsHunter, id))
			iHunter++
	}
	
	return iHunter;
}
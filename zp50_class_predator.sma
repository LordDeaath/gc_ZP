/*===============================================================================
	
	---------------------------
	-*- [ZP] Class: Predator -*-
	---------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_maxspeed_api>
#include <cs_player_models_api>
#include <zp50_colorchat>
#include <cs_weap_models_api>
#include <cs_ham_bots_api>
#include <zp50_core>
#include <zp50_gamemodes>
#define LIBRARY_GRENADE_FROST "zp50_grenade_frost"
#include <zp50_grenade_frost>
#define LIBRARY_GRENADE_FIRE "zp50_grenade_fire"
#include <zp50_grenade_fire>
#include <msgstocks>
#include <zp50_class_survivor>
#include <zp50_class_plasma>
#include <zp50_class_knifer>
#include <zp50_class_sniper>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"
new Random_Skill[33]
// Default models
new const models_predator_player[][] = { "zombie_source" }
new const models_predator_claw[][] = { "models/zombie_plague/v_knife_zombie.mdl" }
new g_iSpriteLaser
#define PLAYERMODEL_MAX_LENGTH 32
#define MODEL_MAX_LENGTH 64

// Custom models
new Array:g_models_predator_player
new Array:g_models_predator_claw

#define TASK_AURA 100
#define ID_AURA (taskid - TASK_AURA)

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_MaxPlayers
new g_IsPredator

new cvar_predator_health, cvar_predator_base_health, cvar_predator_speed, cvar_predator_gravity
new cvar_predator_glow
new cvar_predator_aura, cvar_predator_aura_color_R, cvar_predator_aura_color_G, cvar_predator_aura_color_B
new cvar_predator_damage, cvar_predator_kill_explode
new cvar_predator_grenade_frost, cvar_predator_grenade_fire
new gMode_Nightmare,gMode_Predators;

//new arrays for freez ability
new frostsprite, pcvar_predator_freez_distance, pcvar_predator_freez_cooldown//, pcvar_predator_freez_time
new Bloqueado[33]
new Float:gLastUseCmd[ 33 ]
new g_i_CacheGibsMdl
new g_bCannotBeFrozen[33];
#define MAXPLAYERS 32
new g_FrozenRenderingFx[MAXPLAYERS+1]
new Float:g_FrozenRenderingColor[MAXPLAYERS+1][3]
new g_FrozenRenderingRender[MAXPLAYERS+1]
new Float:g_FrozenRenderingAmount[MAXPLAYERS+1]
public plugin_init()
{
	register_plugin("[ZP] Class: Predator", ZP_VERSION_STRING, "ZP Dev Team")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	//register_clcmd("drop","Do_Predator_Skills")
	g_MaxPlayers = get_maxplayers()
	
	register_forward(FM_CmdStart, "OnPredatorCMD")
	cvar_predator_health = register_cvar("zp_predator_health", "0")
	cvar_predator_base_health = register_cvar("zp_predator_base_health", "2000")
	cvar_predator_speed = register_cvar("zp_predator_speed", "1.05")
	cvar_predator_gravity = register_cvar("zp_predator_gravity", "0.5")
	cvar_predator_glow = register_cvar("zp_predator_glow", "0")
	cvar_predator_aura = register_cvar("zp_predator_aura", "0")
	cvar_predator_aura_color_R = register_cvar("zp_predator_aura_color_R", "150")
	cvar_predator_aura_color_G = register_cvar("zp_predator_aura_color_G", "0")
	cvar_predator_aura_color_B = register_cvar("zp_predator_aura_color_B", "0")
	cvar_predator_damage = register_cvar("zp_predator_damage", "250.0")
	cvar_predator_kill_explode = register_cvar("zp_predator_kill_explode", "1")
	cvar_predator_grenade_frost = register_cvar("zp_predator_grenade_frost", "0")
	cvar_predator_grenade_fire = register_cvar("zp_predator_grenade_fire", "1")
	pcvar_predator_freez_distance = register_cvar("zp_predator_freez_distance", "750")
	pcvar_predator_freez_cooldown = register_cvar("zp_predator_freez_cooldown", "30.0")
               
}

public OnPredatorCMD(id, handle)
{
	if( !is_user_alive( id )) 
		return;
		
	if(!zp_core_is_zombie( id ))		
		return;
		
	if(!flag_get(g_IsPredator, id))	
		return;	
		
		   
	static button
	button = get_uc(handle, UC_Buttons)
	if (button & IN_RELOAD )
	{
		if( get_gametime( ) - gLastUseCmd[ id ] < get_pcvar_float( pcvar_predator_freez_cooldown ) )
		{
			
			set_hudmessage(0, 255, 0, -1.0, -1.0, 0, 1.5, 3.0)
			show_hudmessage(id, "You need to wait for %.f sec. to use your skill again!",get_pcvar_float( pcvar_predator_freez_cooldown ) - ( get_gametime( ) - gLastUseCmd[ id ] ))
			return;
		}
		
		if(Random_Skill[id] == 1)
			use_cmd(id)
		else 
			use_cmd2(id)	
		
		UTIL_PlayWeaponAnimation(id, 8)
	
		gLastUseCmd[ id ] = get_gametime( )	
		Random_Skill[id] = random_num(1,2)
		set_task(get_pcvar_float( pcvar_predator_freez_cooldown ),"PredatorCooldown",id)		
	}
}	

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

public plugin_cfg()
{
	gMode_Nightmare  = zp_gamemodes_get_id("Nightmare Mode");	
	gMode_Predators  = zp_gamemodes_get_id("Predators Mode");
}

public plugin_end()
{	
	ArrayDestroy(g_models_predator_player)
	ArrayDestroy(g_models_predator_claw)
}

public plugin_precache()
{
	g_i_CacheGibsMdl = precache_model("models/hgibs.mdl")
	// Initialize arrays
	g_models_predator_player = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_predator_claw = ArrayCreate(MODEL_MAX_LENGTH, 1)
	g_iSpriteLaser = precache_model( "sprites/animglow01.spr");

	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "PREDATOR", g_models_predator_player)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE PREDATOR", g_models_predator_claw)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_models_predator_player) == 0)
	{
		for (index = 0; index < sizeof models_predator_player; index++)
			ArrayPushString(g_models_predator_player, models_predator_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "PREDATOR", g_models_predator_player)
	}
	if (ArraySize(g_models_predator_claw) == 0)
	{
		for (index = 0; index < sizeof models_predator_claw; index++)
			ArrayPushString(g_models_predator_claw, models_predator_claw[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE PREDATOR", g_models_predator_claw)
	}
	
	// Precache models
	new player_model[PLAYERMODEL_MAX_LENGTH], model[MODEL_MAX_LENGTH], model_path[128]
	for (index = 0; index < ArraySize(g_models_predator_player); index++)
	{
		ArrayGetString(g_models_predator_player, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	for (index = 0; index < ArraySize(g_models_predator_claw); index++)
	{
		ArrayGetString(g_models_predator_claw, index, model, charsmax(model))
		precache_model(model)
		frostsprite = precache_model( "sprites/frost_explode.spr" )
	}
}

public plugin_natives()
{
	register_library("zp50_class_predator")
	register_native("zp_class_predator_get", "native_class_predator_get")
	register_native("zp_class_predator_set", "native_class_predator_set")
	register_native("zp_class_predator_get_count", "native_class_predator_get_count")
	
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
	if (flag_get(g_IsPredator, id))
	{
		// Remove predator glow
		if (get_pcvar_num(cvar_predator_glow))
			set_user_rendering(id)
		
		// Remove predator aura
		if (get_pcvar_num(cvar_predator_aura))
			remove_task(id+TASK_AURA)
	}
}



public fw_ClientDisconnect_Post(id)
{
	// Reset flags AFTER disconnect (to allow checking if the player was predator before disconnecting)
	flag_unset(g_IsPredator, id)
}

public zp_user_infected_post(player, infector)
{
    if(flag_get(g_IsPredator, player))
    {
        zp_colored_print( player, " Press ^x04[R]^x01 to use your skills!" )
    }
}




public use_cmd( id )
{    	    
	
	sprite_control( id )
	static Float:origin [ 3 ]
	pev ( id, pev_origin, origin )
	// Collisions
	static victim 
	victim = -1
	
	// Find radius
	static Float:radius
	radius = get_pcvar_float ( pcvar_predator_freez_distance )
	
	// Find all players in a radius
	while ( ( victim = engfunc ( EngFunc_FindEntityInSphere, victim, origin, radius ) ) != 0 )
	{
		// Dead or zombie
		if ( !is_user_alive ( victim ) || zp_core_is_zombie( victim )||get_user_godmode(victim) )
			continue
		
		// Continiously affect them
		Bloqueado[victim] = true
		zp_grenade_frost_set(victim, true)
		if(zp_class_survivor_get(victim)||zp_class_plasma_get(victim)||zp_class_sniper_get(victim)||zp_class_knifer_get(victim))
		{
			set_task (2.0 , "unfrozen_user", victim)
		}
		else
		{
			set_task (5.0 , "unfrozen_user", victim)
		}
	}
	
	return PLUGIN_HANDLED
}
public use_cmd2( id )
{		 
	new iStartPos[3]
	get_user_origin(id, iStartPos); 
	te_display_glow_sprite(iStartPos, g_iSpriteLaser, 20, 20,255)
	static Float:origin [ 3 ]
	pev ( id, pev_origin, origin )
	// Collisions
	static victim 
	victim = -1
	
	// Find radius
	static Float:radius
	radius = 500.0
	// Find all players in a radius
	while ( ( victim = engfunc ( EngFunc_FindEntityInSphere, victim, origin, radius ) ) != 0 )
	{
	// Dead or zombie
		if ( !is_user_alive ( victim ) || zp_core_is_zombie( victim )||get_user_godmode(victim) )
			continue
		
		// Continiously affect them
		ApplyFrozenRendering(victim)
		if(zp_class_survivor_get(victim)||zp_class_plasma_get(victim)||zp_class_sniper_get(victim)||zp_class_knifer_get(victim))
		{			
			ScreenFade(victim,3.0,100,100,100,255)
			set_task(3.0, "remove_glow",victim);
		}
		else
		{			
			ScreenFade(victim,5.0,100,100,100,255)
			set_task(5.0, "remove_glow",victim);
		}
	}
	
	return PLUGIN_HANDLED
}

public PredatorCooldown(id)
{
	// Not alive
	if (!is_user_alive(id))
		return;
		
	if(!flag_get(g_IsPredator, id))
		return;	
	
	zp_colored_print(id, "Freeze/Blind ability is ready. Press ^x04[R]^x01 button.")
}
public unfrozen_user( target )
{
    if(is_user_alive(target) && is_user_connected(target))
    {
    zp_grenade_frost_set( target, false )
    Bloqueado[target] = false
   }
}


public te_spray( args[ ] )
{
    message_begin( MSG_BROADCAST,SVC_TEMPENTITY )
    write_byte( 120 ) // Throws a shower of sprites or models
    write_coord( args[ 0 ] ) // start pos
    write_coord( args[ 1 ] )
    write_coord( args[ 2 ] )
    write_coord( args[ 3 ] ) // velocity
    write_coord( args[ 4 ] )
    write_coord( args[ 5 ] )
    write_short( frostsprite ) // spr
    write_byte( 8 ) // count
    write_byte( 70 ) // speed
    write_byte( 100 ) //(noise)
    write_byte( 5 ) // (rendermode)
    message_end( )
    
    return PLUGIN_CONTINUE
}

public sqrt( num )
{
    new div = num
    new result = 1
    while( div > result )
    {
        div = ( div + result ) / 2
        result = num / div
    }
    return div
}


public sprite_control( player )
{
    new vec[ 3 ]
    new aimvec[ 3 ]
    new velocityvec[ 3 ]
    new length
    new speed = 10
    
    get_user_origin( player, vec )
    get_user_origin( player, aimvec, 2 )
    
    velocityvec[ 0 ] = aimvec[ 0 ] - vec[ 0 ]
    velocityvec[ 1 ] = aimvec[ 1 ] - vec[ 1 ]
    velocityvec[ 2 ] = aimvec[ 2 ] - vec[ 2 ]
    length = sqrt( velocityvec[ 0 ] * velocityvec[ 0 ] + velocityvec[ 1 ] * velocityvec[ 1 ] + velocityvec[ 2 ] * velocityvec[ 2 ] )
    velocityvec[ 0 ] = velocityvec[ 0 ] * speed / length
    velocityvec[ 1 ] = velocityvec[ 1 ] * speed / length
    velocityvec[ 2 ] = velocityvec[ 2 ] * speed / length
    
    new args[ 8 ]
    args[ 0 ] = vec[ 0 ]
    args[ 1 ] = vec[ 1 ]
    args[ 2 ] = vec[ 2 ]
    args[ 3 ] = velocityvec[ 0 ]
    args[ 4 ] = velocityvec[ 1 ]
    args[ 5 ] = velocityvec[ 2 ]
    
    set_task( 0.1, "te_spray", 0, args, 8, "a", 2 )
    
}
/*
public Do_Predator_Skills(id)
{
	
    
	if( !is_user_alive( id )) 
		return PLUGIN_CONTINUE;
		
	if(!zp_core_is_zombie( id ))		
		return PLUGIN_CONTINUE;
		
	if(!flag_get(g_IsPredator, id))	
		return PLUGIN_CONTINUE;		
	
	if(Random_Skill[id] == 1)
		use_cmd(id)
	else 
		use_cmd2(id)
		
	return PLUGIN_HANDLED;
	
}  */


public client_putinserver(id)
{
	if(is_user_connected(id))
	{
		set_task(5.0, "unfrozen_user", id)
	}
}

// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Dragon attacking human
	if (flag_get(g_IsPredator, attacker) && !zp_core_is_zombie(victim))
	{
		// Ignore predator damage override if damage comes from a 3rd party entity
		// (to prevent this from affecting a sub-plugin's rockets e.g.)
		if (inflictor == attacker)
		{
			// Set predator damage
			SetHamParamFloat(4, get_pcvar_float(cvar_predator_damage))
			return HAM_HANDLED;
		}
	}
	
	return HAM_IGNORED;
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (flag_get(g_IsPredator, victim))
	{
		// Dragon explodes!
		if (get_pcvar_num(cvar_predator_kill_explode))
			SetHamParamInteger(3, 2)
		
		// Remove predator aura
		if (get_pcvar_num(cvar_predator_aura))
			remove_task(victim+TASK_AURA)
	}
	else
	if(flag_get(g_IsPredator, attacker))
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
	// Prevent frost for Dragon
	if (g_bCannotBeFrozen[id]&&flag_get(g_IsPredator, id) && !get_pcvar_num(cvar_predator_grenade_frost))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_grenade_fire_pre(id)
{
	// Prevent burning for Dragon
	if (flag_get(g_IsPredator, id) && !get_pcvar_num(cvar_predator_grenade_fire))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(id)
{
	if (flag_get(g_IsPredator, id))
	{
		// Remove predator glow
		if (get_pcvar_num(cvar_predator_glow))
			set_user_rendering(id)
		
		// Remove predator aura
		if (get_pcvar_num(cvar_predator_aura))
			remove_task(id+TASK_AURA)
		
		// Remove predator flag
		flag_unset(g_IsPredator, id)
	}
}

public zp_fw_core_cure(id, attacker)
{
	if (flag_get(g_IsPredator, id))
	{
		// Remove predator glow
		if (get_pcvar_num(cvar_predator_glow))
			set_user_rendering(id)
		
		// Remove predator aura
		if (get_pcvar_num(cvar_predator_aura))
			remove_task(id+TASK_AURA)
		
		// Remove predator flag
		flag_unset(g_IsPredator, id)
	}
}

public zp_fw_core_infect_post(id, attacker)
{
	// Apply predator attributes?
	if (!flag_get(g_IsPredator, id))
		return;
	
	// Health
	if (get_pcvar_num(cvar_predator_health) == 0)
		set_user_health(id, get_pcvar_num(cvar_predator_base_health) * GetAliveCount())
	else
		set_user_health(id, get_pcvar_num(cvar_predator_health))
	
	// Gravity
	set_user_gravity(id, get_pcvar_float(cvar_predator_gravity))
	
	// Speed
	cs_set_player_maxspeed_auto(id, get_pcvar_float(cvar_predator_speed))
	
	// Apply predator player model
	new player_model[PLAYERMODEL_MAX_LENGTH]
	ArrayGetString(g_models_predator_player, random_num(0, ArraySize(g_models_predator_player) - 1), player_model, charsmax(player_model))
	cs_set_player_model(id, player_model)
	
	// Apply predator claw model
	new model[MODEL_MAX_LENGTH]
	ArrayGetString(g_models_predator_claw, random_num(0, ArraySize(g_models_predator_claw) - 1), model, charsmax(model))
	cs_set_player_view_model(id, CSW_KNIFE, model)	
	
	// Dragon glow
	if (get_pcvar_num(cvar_predator_glow))
		set_user_rendering(id, kRenderFxGlowShell, 0, 50, 200, kRenderNormal, 25)
	
	// Dragon aura task
	if (get_pcvar_num(cvar_predator_aura))
	set_task(0.1, "predator_aura", id+TASK_AURA, _, _, "b")
	
	if(zp_gamemodes_get_current()!=gMode_Nightmare)
	{
		g_bCannotBeFrozen[id]=false;
		zp_grenade_frost_set(id)
		set_task(5.0, "DisableFrozenForNemesis", id)
		new name[32]
		get_user_name(id, name, charsmax(name))
		if(zp_gamemodes_get_current()!=gMode_Predators)
		zp_colored_print(0,"^x03%s^x01 will be released in 5 seconds",name)
	}
	else
	{
		g_bCannotBeFrozen[id]=true;
	}
}

public DisableFrozenForNemesis(id)
{
	if(is_user_connected(id))
	{
	if(is_user_alive(id) && flag_get(g_IsPredator, id))
	{
	new name[32]
	get_user_name(id, name, charsmax(name))
	// Now nemesis cannot be frozen
	g_bCannotBeFrozen[id] = true
	zp_grenade_frost_set(id,false)	
	if(zp_gamemodes_get_current()!=gMode_Predators)
	zp_colored_print(0,"^x03%s^x01 is released!",name)
	}
	}
}
public native_class_predator_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsPredator, id);
}

public native_class_predator_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_IsPredator, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a predator (%d)", id)
		return false;
	}
	
	flag_set(g_IsPredator, id)
	zp_core_force_infect(id)
	return true;
}

public native_class_predator_get_count(plugin_id, num_params)
{
	return GetPredatorCount();
}

// Dragon aura task
public predator_aura(taskid)
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
	write_byte(get_pcvar_num(cvar_predator_aura_color_R)) // r
	write_byte(get_pcvar_num(cvar_predator_aura_color_G)) // g
	write_byte(get_pcvar_num(cvar_predator_aura_color_B)) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
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

// Get Dragon Count -returns alive predator number- (LOL)
GetPredatorCount()
{
	new iPredator, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && flag_get(g_IsPredator, id))
			iPredator++
	}
	
	return iPredator;
}

stock ScreenFade(plr, Float:fDuration, red, green, blue, alpha)
{
    new i = plr ? plr : get_maxplayers();
    if( !i )
    {
        return 0;
    }
    
    message_begin(plr ? MSG_ONE : MSG_ALL, get_user_msgid( "ScreenFade"), {0, 0, 0}, plr);
    write_short(floatround(4096.0 * fDuration, floatround_round));
    write_short(floatround(4096.0 * fDuration, floatround_round));
    write_short(4096);
    write_byte(red);
    write_byte(green);
    write_byte(blue);
    write_byte(alpha);
    message_end();
    
    return 1;
}

ApplyFrozenRendering(id)
{
	// Get current rendering
	new rendering_fx = pev(id, pev_renderfx)
	new Float:rendering_color[3]
	pev(id, pev_rendercolor, rendering_color)
	new rendering_render = pev(id, pev_rendermode)
	new Float:rendering_amount
	pev(id, pev_renderamt, rendering_amount)
	
	// Already set, no worries...
	if (rendering_fx == kRenderFxGlowShell && rendering_color[0] == 0.0 && rendering_color[1] == 200.0
		&& rendering_color[2] == 100.0 && rendering_render == kRenderNormal && rendering_amount == 25.0)
		return;
	
	// Save player's old rendering	
	g_FrozenRenderingFx[id] = pev(id, pev_renderfx)
	pev(id, pev_rendercolor, g_FrozenRenderingColor[id])
	g_FrozenRenderingRender[id] = pev(id, pev_rendermode)
	pev(id, pev_renderamt, g_FrozenRenderingAmount[id])
	
	// Light blue glow while frozen
	fm_set_rendering(id, kRenderFxGlowShell, 0, 200, 100, kRenderNormal, 25)
}



public remove_glow(id)
{
	if(is_user_alive(id))
	fm_set_rendering_float(id, g_FrozenRenderingFx[id], g_FrozenRenderingColor[id], g_FrozenRenderingRender[id], g_FrozenRenderingAmount[id])
}

// Set entity's rendering type (from fakemeta_util)
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}

stock fm_set_rendering_float(entity, fx = kRenderFxNone, Float:color[3], render = kRenderNormal, Float:amount = 16.0)
{
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, amount)
}

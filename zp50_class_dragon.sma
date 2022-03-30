/*===============================================================================
	
	---------------------------
	-*- [ZP] Class: Dragon -*-
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
#include <zp50_colorchat>
#include <xs>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default models
new const models_dragon_player[][] = { "zombie_source" }
new const models_dragon_claw[][] = { "models/zombie_plague/v_knife_zombie.mdl" }
new const CVAR_DRAGONFLY_SPEED[]  = "zp_dragon_fly_speed"

#define PLAYERMODEL_MAX_LENGTH 32
#define MODEL_MAX_LENGTH 64

// Custom models
new Array:g_models_dragon_player
new Array:g_models_dragon_claw

#define TASK_AURA 100
#define ID_AURA (taskid - TASK_AURA)

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new gMode_Nightmare
new g_MaxPlayers
new g_IsDragon

new cvar_dragon_health, cvar_dragon_base_health, cvar_dragon_speed, cvar_dragon_gravity
new cvar_dragon_glow
new cvar_dragon_aura, cvar_dragon_aura_color_R, cvar_dragon_aura_color_G, cvar_dragon_aura_color_B
new cvar_dragon_damage, cvar_dragon_kill_explode
new cvar_dragon_grenade_frost, cvar_dragon_grenade_fire
new pcvar_predator_fire_distance, pcvar_predator_fire_cooldown
//new cvar_leap_zombie_force, cvar_leap_zombie_cooldown, cvar_leap_zombie_height
//new Float:g_LeapLastTime[33]
//new arrays for freez ability
new frostsprite
new Float:gLastUseCmd[ 33 ]
new g_i_CacheGibsMdl
new bool:g_bCannotBeFrozen[33]
public plugin_init()
{
	register_plugin("[ZP] Class: Dragon", ZP_VERSION_STRING, "ZP Dev Team")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	register_forward(FM_CmdStart, "fw_Start")
	pcvar_predator_fire_distance = register_cvar("zp_dragon_fire_radius", "180.0")
	pcvar_predator_fire_cooldown = register_cvar("zp_dragon_fire_cooldown", "60.0")
	g_MaxPlayers = get_maxplayers()
	
	cvar_dragon_health = register_cvar("zp_dragon_health", "0")
	cvar_dragon_base_health = register_cvar("zp_dragon_base_health", "2000")
	cvar_dragon_speed = register_cvar("zp_dragon_speed", "1.05")
	cvar_dragon_gravity = register_cvar("zp_dragon_gravity", "0.5")
	cvar_dragon_glow = register_cvar("zp_dragon_glow", "1")
	cvar_dragon_aura = register_cvar("zp_dragon_aura", "1")
	cvar_dragon_aura_color_R = register_cvar("zp_dragon_aura_color_R", "150")
	cvar_dragon_aura_color_G = register_cvar("zp_dragon_aura_color_G", "0")
	cvar_dragon_aura_color_B = register_cvar("zp_dragon_aura_color_B", "0")
	cvar_dragon_damage = register_cvar("zp_dragon_damage", "2.0")
	cvar_dragon_kill_explode = register_cvar("zp_dragon_kill_explode", "1")
	cvar_dragon_grenade_frost = register_cvar("zp_dragon_grenade_frost", "0")
	cvar_dragon_grenade_fire = register_cvar("zp_dragon_grenade_fire", "1")
	register_cvar(CVAR_DRAGONFLY_SPEED    , "300")

	/*cvar_leap_zombie_cooldown = register_cvar( "zp_leap_cooldown", "30" )
	cvar_leap_zombie_force = register_cvar( "zp_leap_force", "750.0" )
	cvar_leap_zombie_height = register_cvar( "zp_leap_height", "450.0" )
   
	register_clcmd("drop","fw_PlayerSkill")*/

                
}

public plugin_cfg()
{
	gMode_Nightmare  = zp_gamemodes_get_id("Nightmare Mode");
}

public plugin_end()
{
	ArrayDestroy(g_models_dragon_player)
	ArrayDestroy(g_models_dragon_claw)
}

public plugin_precache()
{
	g_i_CacheGibsMdl = precache_model("models/hgibs.mdl")
	// Initialize arrays
	g_models_dragon_player = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_dragon_claw = ArrayCreate(MODEL_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "DRAGON", g_models_dragon_player)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE DRAGON", g_models_dragon_claw)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_models_dragon_player) == 0)
	{
		for (index = 0; index < sizeof models_dragon_player; index++)
			ArrayPushString(g_models_dragon_player, models_dragon_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "DRAGON", g_models_dragon_player)
	}
	if (ArraySize(g_models_dragon_claw) == 0)
	{
		for (index = 0; index < sizeof models_dragon_claw; index++)
			ArrayPushString(g_models_dragon_claw, models_dragon_claw[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE DRAGON", g_models_dragon_claw)
	}
	
	// Precache models
	new player_model[PLAYERMODEL_MAX_LENGTH], model[MODEL_MAX_LENGTH], model_path[128]
	for (index = 0; index < ArraySize(g_models_dragon_player); index++)
	{
		ArrayGetString(g_models_dragon_player, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	for (index = 0; index < ArraySize(g_models_dragon_claw); index++)
	{
		ArrayGetString(g_models_dragon_claw, index, model, charsmax(model))
		precache_model(model)
		frostsprite = precache_model( "sprites/flame_puff01.spr" )
	}
}

public plugin_natives()
{
	register_library("zp50_class_dragon")
	register_native("zp_class_dragon_get", "native_class_dragon_get")
	register_native("zp_class_dragon_set", "native_class_dragon_set")
	register_native("zp_class_dragon_get_count", "native_class_dragon_get_count")
	
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
	if (flag_get(g_IsDragon, id))
	{
		// Remove dragon glow
		if (get_pcvar_num(cvar_dragon_glow))
			set_user_rendering(id)
		
		// Remove dragon aura
		if (get_pcvar_num(cvar_dragon_aura))
			remove_task(id+TASK_AURA)
	}
}



public fw_ClientDisconnect_Post(id)
{
	// Reset flags AFTER disconnect (to allow checking if the player was dragon before disconnecting)
	flag_unset(g_IsDragon, id)
}

public zp_user_infected_post(player, infector)
{
    if(flag_get(g_IsDragon, player))
    {
        zp_colored_print( player, " Press ^x04[R]^x01 to Burn humans! Hold ^x04[Jump]^x01 to fly!" )
    }
}


public client_PreThink(id) 
{
	if(!is_user_alive(id))return PLUGIN_CONTINUE;
	
	if(!flag_get(g_IsDragon, id)) return PLUGIN_CONTINUE
	
	if(zp_grenade_frost_get(id))return PLUGIN_CONTINUE;
	
	new Float:fAim[3] , Float:fVelocity[3];

	if(get_speed(id)>get_cvar_num(CVAR_DRAGONFLY_SPEED))
	{
		VelocityByAim(id , get_speed(id)-1 , fAim);
	}
	else
	{		
		VelocityByAim(id , get_cvar_num(CVAR_DRAGONFLY_SPEED) , fAim);
	}

	
	if((get_user_button(id) & IN_JUMP) && !(get_user_button(id) & IN_USE))
	{
		fVelocity[0] = fAim[0];
		fVelocity[1] = fAim[1];
		fVelocity[2] = fAim[2];

		set_user_velocity(id , fVelocity);
	}
	return PLUGIN_CONTINUE;
}

public use_cmd(id)
{
    
	if( !is_user_alive( id ) || !zp_core_is_zombie( id ) || !flag_get(g_IsDragon, id))
		return PLUGIN_HANDLED

	if( get_gametime( ) - gLastUseCmd[ id ] < get_pcvar_float( pcvar_predator_fire_cooldown ) )
	{
		set_hudmessage(0, 255, 0, -1.0, -1.0, 0, 1.5, 3.0)
		show_hudmessage(id, "You need to wait for %.f sec. to use your skill again!",get_pcvar_float( pcvar_predator_fire_cooldown ) - ( get_gametime( ) - gLastUseCmd[ id ] ))

		return PLUGIN_HANDLED
	}

	gLastUseCmd[ id ] = get_gametime( )
	set_task(get_pcvar_float( pcvar_predator_fire_cooldown ),"FireCooldown",id)
	sprite_control( id )	    
	static Float:origin [ 3 ]
	pev ( id, pev_origin, origin )
		// Collisions
	static victim 
	victim = -1

	// Find radius
	static Float:radius
	radius = get_pcvar_float ( pcvar_predator_fire_distance )
	
	new Float:predatorAngle[3], Float:predatorOrigin[3]
	entity_get_vector(id, EV_VEC_origin, predatorOrigin)
	entity_get_vector(id, EV_VEC_v_angle, predatorAngle)
		// Find all players in a radius
	while ( ( victim = engfunc ( EngFunc_FindEntityInSphere, victim, origin, radius ) ) != 0 )
	{
		// Dead or zombie
		if ( !is_user_alive ( victim ) || zp_core_is_zombie( victim )  )
			continue
		
		static Float:victimAngle[3]
		entity_get_vector(victim, EV_VEC_origin, victimAngle)
		xs_vec_sub(victimAngle, predatorOrigin , victimAngle)
		vector_to_angle(victimAngle, victimAngle)
		xs_vec_sub(victimAngle, predatorAngle, victimAngle)
		if((-60.0<victimAngle[0]<60.0||300.0<victimAngle[0]<420.0||-420.0<victimAngle[0]<-300.0)&&(-60.0<victimAngle[1]<60.0||300.0<victimAngle[1]<420.0||-420.0<victimAngle[1]<-300.0))
		{
			ExecuteHamB(Ham_TakeDamage, victim, id, id, 500.0, DMG_BURN)
		}
	}
	return PLUGIN_HANDLED
}

public FireCooldown(id)
{
	// Not alive
	if (!is_user_alive(id))
		return;
		
	if(!flag_get(g_IsDragon, id))
		return;	
	
	zp_colored_print(id, "Fire ability is ready. Press ^x04[R]^x01 button.")
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
    new speed = 4
    
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



public fw_Start(id, uc_handle, seed)
{
    new button = get_uc(uc_handle,UC_Buttons)
    if((button & IN_RELOAD))
        use_cmd(id)
}  
/*
// Forward Player PreThink
public fw_PlayerSkill(id)
{
	// Not alive
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE;
		
	if(!flag_get(g_IsDragon, id))
		return PLUGIN_CONTINUE;
    
	if( get_gametime( ) - g_LeapLastTime[ id ] < get_pcvar_float( cvar_leap_zombie_cooldown ) )
	{
		
		set_hudmessage(0, 255, 0, -1.0, -1.0, 0, 1.5, 3.0)
		show_hudmessage(id, "You need to wait for %.f sec. leap again!",get_pcvar_float( cvar_leap_zombie_cooldown ) - ( get_gametime( ) - g_LeapLastTime[ id ] ))
	
		return PLUGIN_HANDLED;
	}	
	// Don't allow leap if player is frozen (e.g. freezetime)
	if (zp_grenade_frost_get(id))
		return PLUGIN_HANDLED;
		
	static Float:cooldown, force, Float:height
	
		// Not a zombie
	if (!zp_core_is_zombie(id))
		return PLUGIN_HANDLED;
			
	cooldown = get_pcvar_float(cvar_leap_zombie_cooldown)
	cooldown++
	force = get_pcvar_num(cvar_leap_zombie_force)
	height = get_pcvar_float(cvar_leap_zombie_height)
	
	static Float:current_time
	current_time = get_gametime()
	
	static Float:velocity[3]
	
	// Make velocity vector
	velocity_by_aim(id, force, velocity)
	
	// Set custom height
	velocity[2] = height
	
	// Apply the new velocity
	set_pev(id, pev_velocity, velocity)
	
	// Update last leap time
	g_LeapLastTime[id] = current_time
	set_task(get_pcvar_float( cvar_leap_zombie_cooldown ),"LeapCooldown",id)
	return PLUGIN_HANDLED;
}

public LeapCooldown(id)
{
	// Not alive
	if (!is_user_alive(id))
		return;
		
	if(!flag_get(g_IsDragon, id))
		return;
	
	
	zp_colored_print(id, "Leap ability is ready. Press ^x04[G]^x01 button.")
}
*/
stock fm_get_speed(entity)
{
	static Float:velocity[3]
	pev(entity, pev_velocity, velocity)
	
	return floatround(vector_length(velocity));
}

// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Dragon attacking human
	if (flag_get(g_IsDragon, attacker) && !zp_core_is_zombie(victim))
	{
		// Ignore dragon damage override if damage comes from a 3rd party entity
		// (to prevent this from affecting a sub-plugin's rockets e.g.)
		if (inflictor == attacker)
		{
			// Set dragon damage
			SetHamParamFloat(4, get_pcvar_float(cvar_dragon_damage))
			return HAM_HANDLED;
		}
	}
	
	return HAM_IGNORED;
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (flag_get(g_IsDragon, victim))
	{
		// Dragon explodes!
		if (get_pcvar_num(cvar_dragon_kill_explode))
			SetHamParamInteger(3, 2)
		
		// Remove dragon aura
		if (get_pcvar_num(cvar_dragon_aura))
			remove_task(victim+TASK_AURA)
	}
	else
	if(flag_get(g_IsDragon, attacker))
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
	if (g_bCannotBeFrozen[id] && flag_get(g_IsDragon, id) && !get_pcvar_num(cvar_dragon_grenade_frost))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_grenade_fire_pre(id)
{
	// Prevent burning for Dragon
	if (flag_get(g_IsDragon, id) && !get_pcvar_num(cvar_dragon_grenade_fire))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(id)
{
	if (flag_get(g_IsDragon, id))
	{
		// Remove dragon glow
		if (get_pcvar_num(cvar_dragon_glow))
			set_user_rendering(id)
		
		// Remove dragon aura
		if (get_pcvar_num(cvar_dragon_aura))
			remove_task(id+TASK_AURA)
		
		// Remove dragon flag
		flag_unset(g_IsDragon, id)
	}
}

public zp_fw_core_cure(id, attacker)
{
	if (flag_get(g_IsDragon, id))
	{
		// Remove dragon glow
		if (get_pcvar_num(cvar_dragon_glow))
			set_user_rendering(id)
		
		// Remove dragon aura
		if (get_pcvar_num(cvar_dragon_aura))
			remove_task(id+TASK_AURA)
		
		// Remove dragon flag
		flag_unset(g_IsDragon, id)
	}
}

public zp_fw_core_infect_post(id, attacker)
{
	// Apply dragon attributes?
	if (!flag_get(g_IsDragon, id))
		return;
	
	// Health
	if (get_pcvar_num(cvar_dragon_health) == 0)
		set_user_health(id, get_pcvar_num(cvar_dragon_base_health) * GetAliveCount())
	else
		set_user_health(id, get_pcvar_num(cvar_dragon_health))
	
	// Gravity
	set_user_gravity(id, get_pcvar_float(cvar_dragon_gravity))
	
	// Speed
	cs_set_player_maxspeed_auto(id, get_pcvar_float(cvar_dragon_speed))
	
	// Apply dragon player model
	new player_model[PLAYERMODEL_MAX_LENGTH]
	ArrayGetString(g_models_dragon_player, random_num(0, ArraySize(g_models_dragon_player) - 1), player_model, charsmax(player_model))
	cs_set_player_model(id, player_model)
	
	// Apply dragon claw model
	new model[MODEL_MAX_LENGTH]
	ArrayGetString(g_models_dragon_claw, random_num(0, ArraySize(g_models_dragon_claw) - 1), model, charsmax(model))
	cs_set_player_view_model(id, CSW_KNIFE, model)	
	
	// Dragon glow
	if (get_pcvar_num(cvar_dragon_glow))
		set_user_rendering(id, kRenderFxGlowShell, 0, 50, 200, kRenderNormal, 25)
	
	// Dragon aura task
	if (get_pcvar_num(cvar_dragon_aura))
		set_task(0.1, "dragon_aura", id+TASK_AURA, _, _, "b")
		
	if(zp_gamemodes_get_current()!=gMode_Nightmare)
	{
		// Freeze the nemesis. ;)
		// So, all humans can run away!	
		g_bCannotBeFrozen[id]=false;
		zp_grenade_frost_set(id)
		// Set task to enable nemesis for not being frozen after X seconds
		set_task(5.0, "DisableFrozenForNemesis", id)
		new name[32]
		get_user_name(id, name, charsmax(name))
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
	if(is_user_alive(id) && flag_get(g_IsDragon, id))
	{
	new name[32]
	get_user_name(id, name, charsmax(name))
	// Now nemesis cannot be frozen
	g_bCannotBeFrozen[id] = true
	zp_grenade_frost_set(id,false)
	zp_colored_print(0,"^x03%s^x01 is released!",name)
	}
	}
}
public native_class_dragon_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsDragon, id);
}

public native_class_dragon_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_IsDragon, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a dragon (%d)", id)
		return false;
	}
	
	flag_set(g_IsDragon, id)
	zp_core_force_infect(id)
	return true;
}

public native_class_dragon_get_count(plugin_id, num_params)
{
	return GetDragonCount();
}

// Dragon aura task
public dragon_aura(taskid)
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
	write_byte(get_pcvar_num(cvar_dragon_aura_color_R)) // r
	write_byte(get_pcvar_num(cvar_dragon_aura_color_G)) // g
	write_byte(get_pcvar_num(cvar_dragon_aura_color_B)) // b
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

// Get Dragon Count -returns alive dragon number-
GetDragonCount()
{
	new iDragon, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && flag_get(g_IsDragon, id))
			iDragon++
	}
	
	return iDragon;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

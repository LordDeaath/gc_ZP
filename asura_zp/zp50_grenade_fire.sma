/*================================================================================
	
	--------------------------
	-*- [ZP] Grenade: Fire -*-
	--------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <amx_settings_api>
#include <cs_weap_models_api>
#include <cs_ham_bots_api>
#include <zp50_core>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#include <zp50_fps>
#include <bulletdamage>
#include <zp50_ammopacks>
#include <engine>

#define OFFSET_ACTIVE    373
#define LINUX_DIFF    5

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_grenade_fire_explode[][] = { "zombie_plague/grenade_explode.wav" }
new const sound_grenade_fire_player[][] = { "zombie_plague/zombie_burn3.wav" , "zombie_plague/zombie_burn4.wav" , "zombie_plague/zombie_burn5.wav" , "zombie_plague/zombie_burn6.wav" , "zombie_plague/zombie_burn7.wav" }

#define MODEL_MAX_LENGTH 64
#define SOUND_MAX_LENGTH 64
#define SPRITE_MAX_LENGTH 64

// Models
new g_model_grenade_fire[MODEL_MAX_LENGTH] = "models/zombie_plague/v_grenade_fire.mdl"

// Sprites
new g_sprite_grenade_trail[SPRITE_MAX_LENGTH] = "sprites/laserbeam.spr"
new g_sprite_grenade_ring[SPRITE_MAX_LENGTH] = "sprites/shockwave.spr"
new g_sprite_grenade_fire[SPRITE_MAX_LENGTH] = "sprites/flame.spr"
new g_sprite_grenade_smoke[SPRITE_MAX_LENGTH] = "sprites/black_smoke3.spr"

new Array:g_sound_grenade_fire_explode
new Array:g_sound_grenade_fire_player

// Explosion radius for custom grenades
const Float:NADE_EXPLOSION_RADIUS = 240.0

// HACK: pev_ field used to store custom nade types and their values
const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_NAPALM = 2222

#define TASK_BURN 100
#define ID_BURN (taskid - TASK_BURN)

#define MAXPLAYERS 32

// Custom Forwards
enum _:TOTAL_FORWARDS
{
	FW_USER_BURN_PRE = 0
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

new g_BurningDuration[MAXPLAYERS+1]

new g_MsgDamage
new g_trailSpr, g_exploSpr, g_flameSpr, g_smokeSpr, explosion
native zp_item_zombie_madness_get(i)
new cvar_grenade_fire_duration, cvar_grenade_fire_damage, cvar_grenade_fire_slowdown, cvar_grenade_fire_hudicon, cvar_grenade_fire_explosion, cvar_fire_stats[3],
bomb_radius, cvar_damage

public plugin_init()
{
	register_plugin("[ZP] Grenade: Fire", ZP_VERSION_STRING, "ZP Dev Team")
	
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	
	g_MsgDamage = get_user_msgid("Damage")
	bomb_radius = register_cvar("zp_rc_distance", "350")
	cvar_damage=register_cvar("zp_rc_damage","1000")
	cvar_grenade_fire_duration = register_cvar("zp_grenade_fire_duration", "10")
	cvar_grenade_fire_damage = register_cvar("zp_grenade_fire_damage", "5")
	cvar_grenade_fire_slowdown = register_cvar("zp_grenade_fire_slowdown", "0.5")
	cvar_grenade_fire_hudicon = register_cvar("zp_grenade_fire_hudicon", "1")
	cvar_grenade_fire_explosion = register_cvar("zp_grenade_fire_explosion", "0")
	cvar_fire_stats[0] = register_cvar("zp_nap_stat_1", "30")
	cvar_fire_stats[1] = register_cvar("zp_nap_stat_2", "30")
	cvar_fire_stats[2] = register_cvar("zp_nap_stat_3", "30")

	g_Forwards[FW_USER_BURN_PRE] = CreateMultiForward("zp_fw_grenade_fire_pre", ET_CONTINUE, FP_CELL)	
	
}

public plugin_end()
{
	ArrayDestroy(g_sound_grenade_fire_explode)
	ArrayDestroy(g_sound_grenade_fire_player)
}

public plugin_precache()
{
	// Initialize arrays
	g_sound_grenade_fire_explode = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_grenade_fire_player = ArrayCreate(SOUND_MAX_LENGTH, 1)
	explosion = precache_model("sprites/Za_fire_explode.spr")

	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE FIRE EXPLODE", g_sound_grenade_fire_explode)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE FIRE PLAYER", g_sound_grenade_fire_player)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_grenade_fire_explode) == 0)
	{
		for (index = 0; index < sizeof sound_grenade_fire_explode; index++)
			ArrayPushString(g_sound_grenade_fire_explode, sound_grenade_fire_explode[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE FIRE EXPLODE", g_sound_grenade_fire_explode)
	}
	if (ArraySize(g_sound_grenade_fire_player) == 0)
	{
		for (index = 0; index < sizeof sound_grenade_fire_player; index++)
			ArrayPushString(g_sound_grenade_fire_player, sound_grenade_fire_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE FIRE PLAYER", g_sound_grenade_fire_player)
	}
	
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "GRENADE FIRE", g_model_grenade_fire, charsmax(g_model_grenade_fire)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "GRENADE FIRE", g_model_grenade_fire)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "TRAIL", g_sprite_grenade_trail, charsmax(g_sprite_grenade_trail)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "TRAIL", g_sprite_grenade_trail)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "RING", g_sprite_grenade_ring, charsmax(g_sprite_grenade_ring)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "RING", g_sprite_grenade_ring)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "FIRE", g_sprite_grenade_fire, charsmax(g_sprite_grenade_fire)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "FIRE", g_sprite_grenade_fire)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "SMOKE", g_sprite_grenade_smoke, charsmax(g_sprite_grenade_smoke)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "SMOKE", g_sprite_grenade_smoke)
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_grenade_fire_explode); index++)
	{
		ArrayGetString(g_sound_grenade_fire_explode, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_grenade_fire_player); index++)
	{
		ArrayGetString(g_sound_grenade_fire_player, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	
	// Precache models
	precache_model(g_model_grenade_fire)
	g_trailSpr = precache_model(g_sprite_grenade_trail)
	g_exploSpr = precache_model(g_sprite_grenade_ring)
	g_flameSpr = precache_model(g_sprite_grenade_fire)
	g_smokeSpr = precache_model(g_sprite_grenade_smoke)
}

new Burned, Frozen;
public plugin_cfg()
{
	Burned = zp_class_zombie_get_id("Burned Zombie");
	Frozen = zp_class_zombie_get_id("Frozen Zombie")
}
public plugin_natives()
{
	register_library("zp50_grenade_fire")
	register_native("zp_grenade_fire_get", "native_grenade_fire_get")
	register_native("zp_grenade_fire_set", "native_grenade_fire_set")
	
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public native_grenade_fire_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return task_exists(id+TASK_BURN);
}

public native_grenade_fire_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new set = get_param(2)
	
	// End fire
	if (!set)
	{
		// Not burning
		if (!task_exists(id+TASK_BURN))
			return true;
		
		// Get player origin
		static origin[3]
		get_user_origin(id, origin)
		
		// Smoke sprite
		for(new i = 1;i < 33; i++)
		{
			if(!is_user_connected(i))
				continue;
			
			if(zp_fps_get_user_flags(i) & FPS_SPRITES)
				continue;
				
			message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,{0,0,0},i)
			write_byte(TE_SMOKE) // TE id
			write_coord(origin[0]) // x
			write_coord(origin[1]) // y
			write_coord(origin[2]-50) // z
			write_short(g_smokeSpr) // sprite
			write_byte(random_num(15, 20)) // scale
			write_byte(random_num(10, 20)) // framerate
			message_end()
		}
		
		// Task not needed anymore
		remove_task(id+TASK_BURN)
		return true;
	}
	
	// Set on fire
	return set_on_fire(id);
}

public zp_fw_core_cure_post(id, attacker)
{
	// Stop burning
	remove_task(id+TASK_BURN)
	g_BurningDuration[id] = 0
	
	// Set custom grenade model
	cs_set_player_view_model(id, CSW_HEGRENADE, g_model_grenade_fire)
}

public zp_fw_core_infect(id, attacker)
{
	// Remove custom grenade model
	cs_reset_player_view_model(id, CSW_HEGRENADE)
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Stop burning
	remove_task(victim+TASK_BURN)
	g_BurningDuration[victim] = 0
}

public client_disconnected(id)
{
	// Stop burning
	remove_task(id+TASK_BURN)
	g_BurningDuration[id] = 0
}

// Forward Set Model
public fw_SetModel(entity, const model[])
{
	// We don't care
	if (strlen(model) < 8)
		return;
	
	// Narrow down our matches a bit
	if (model[7] != 'w' || model[8] != '_')
		return;
	
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Grenade not yet thrown
	if (dmgtime == 0.0)
		return;
	
	// Grenade's owner is zombie?
	if (zp_core_is_zombie(pev(entity, pev_owner)))
		return;
	
	// HE Grenade
	if (model[9] == 'h' && model[10] == 'e')
	{
		// Give it a glow
		fm_set_rendering(entity, kRenderFxGlowShell, 200, 0, 0, kRenderNormal, 16)
		
		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(entity) // entity
		write_short(g_trailSpr) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(200) // r
		write_byte(0) // g
		write_byte(0) // b
		write_byte(200) // brightness
		message_end()
		
		// Set grenade type on the thrown grenade entity
		set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_NAPALM)
	}
}

// Ham Grenade Think Forward
public fw_ThinkGrenade(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return HAM_IGNORED;
	
	// Get damage time of grenade
	
	static Float:dmgtime, Float:origin[3]
	pev(entity, pev_dmgtime, dmgtime)
	pev(entity, pev_origin, origin)
	new attacker = entity_get_edict(entity, EV_ENT_owner)
	//client_print(0, print_chat, "%d", attacker)
	
	// Check if it's time to go off
	if (dmgtime > get_gametime())
		return HAM_IGNORED;
	
	// Not a napalm grenade
	if (pev(entity, PEV_NADE_TYPE) != NADE_TYPE_NAPALM)
		return HAM_IGNORED;
	
	fire_explode(entity);
	ExplosionCreate(attacker, origin)
	// Keep the original explosion?
	if (get_pcvar_num(cvar_grenade_fire_explosion))
	{
		set_pev(entity, PEV_NADE_TYPE, 0)
		return HAM_IGNORED;
	}
	
	// Get rid of the grenade
	engfunc(EngFunc_RemoveEntity, entity)
	return HAM_SUPERCEDE;
}

// Fire Grenade Explosion
fire_explode(ent)
{
	// Get origin
	static Float:origin[3]
	pev(ent, pev_origin, origin)
	
	// Override original HE grenade explosion?
	if (!get_pcvar_num(cvar_grenade_fire_explosion))
	{
		// Make the explosion
		create_blast2(origin)
		// Fire nade explode sound
		static sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_grenade_fire_explode, random_num(0, ArraySize(g_sound_grenade_fire_explode) - 1), sound, charsmax(sound))
		emit_sound(ent, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	
	// Collisions
	new victim = -1
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, origin, NADE_EXPLOSION_RADIUS)) != 0)
	{
		// Only effect alive zombies
		if (!is_user_alive(victim) || !zp_core_is_zombie(victim))
			continue;
		set_on_fire(victim)
	}
}

ExplosionCreate(this, Float:vecOrigin[3])
{
	new ZombiCount = zp_core_get_human_count()
	new fStat[3]
	fStat[0] = get_pcvar_num(cvar_fire_stats[0])
	fStat[1] = get_pcvar_num(cvar_fire_stats[1])
	fStat[2] = get_pcvar_num(cvar_fire_stats[2])
	for(new i = 1;i < 33; i++)
	{	
		if(!is_user_connected(i))
			continue;
			
		if(zp_fps_get_user_flags(i) & FPS_SPRITES)
			continue;
			
		engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, vecOrigin, i)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, vecOrigin[0])
		engfunc(EngFunc_WriteCoord, vecOrigin[1])
		engfunc(EngFunc_WriteCoord, vecOrigin[2] + 32)
		write_short(explosion)
		write_byte(fStat[0])
		write_byte(fStat[1])
		write_byte(fStat[2])
		message_end()
	}
	new Float:PlayerPos[3], Float:distance, Float:damage//, DmgAP, Ammo
	for (new i = 1; i < 33; i++) 
	{
		if(!is_user_connected(i))
			continue;
		if(!is_user_alive(i)) 
			continue;		
		
		pev(i, pev_origin, PlayerPos)
		
		distance = get_distance_f(PlayerPos, vecOrigin)
		if (distance <= get_pcvar_float(bomb_radius))
		{
			new FinalDamage
			damage = get_pcvar_float(cvar_damage)*(1.0-distance/get_pcvar_float(bomb_radius))
			new attacker = this		
			FinalDamage = floatround(damage)
			switch(ZombiCount)
			{
				case 1..12: FinalDamage = floatround(damage) / 4 
				case 13..20: FinalDamage = floatround(damage) / 3
				case 21..27: FinalDamage = floatround(damage) / 2
				case 28..32: FinalDamage = floatround(damage)
				default: FinalDamage = floatround(damage)
			}
			if (zp_core_is_zombie(i))
			{
				//bd_show_damage(this, FinalDamage, 0, 1)
				//bd_show_damage(i, FinalDamage, 1, 0)
				ExecuteHamB(Ham_TakeDamage, i, this, this, float(FinalDamage), DMG_BLAST)
				//DmgAP += FinalDamage
				//fakedamage(i,"Nade", float(FinalDamage), DMG_FALL)
				//set_user_health(i, get_user_health(i) - FinalDamage)
				//client_print(this, print_chat, "%2.2f", float(FinalDamage))
			}
				//ExecuteHam(Ham_TraceAttack, i, ant, attacker, float(FinalDamage))
		}
	}
	/*
	Ammo = DmgAP / 1000
	if(Ammo)
	{
		zp_ammopacks_set(this, zp_ammopacks_get(this) + Ammo)
		set_hudmessage(0, 255, 0, -1.0, 0.35)
		show_hudmessage(this, "+ %d AP", Ammo)
	}
	*/
}

set_on_fire(victim)
{
	// Allow other plugins to decide whether player should be burned or not
	ExecuteForward(g_Forwards[FW_USER_BURN_PRE], g_ForwardResult, victim)
	if (g_ForwardResult >= PLUGIN_HANDLED)
		return false;
	
	// Heat icon?
	if (get_pcvar_num(cvar_grenade_fire_hudicon))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgDamage, _, victim)
		write_byte(0) // damage save
		write_byte(0) // damage take
		write_long(DMG_BURN) // damage type
		write_coord(0) // x
		write_coord(0) // y
		write_coord(0) // z
		message_end()
	}
	
	// Reduced duration for Nemesis
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(victim))
	{
		// fire duration (nemesis)
		g_BurningDuration[victim] += get_pcvar_num(cvar_grenade_fire_duration)
	}
	else
	{
		// fire duration (zombie)
		g_BurningDuration[victim] += get_pcvar_num(cvar_grenade_fire_duration) * 5
	}
	
	// Set burning task on victim
	remove_task(victim+TASK_BURN)
	set_task(0.2, "burning_flame", victim+TASK_BURN, _, _, "b")
	return true;
}

// Burning Flames
public burning_flame(taskid)
{
	// Get player origin and flags
	static origin[3]
	get_user_origin(ID_BURN, origin)
	
	// In water or burning stopped
	if (pev(ID_BURN , pev_waterlevel)  || g_BurningDuration[ID_BURN] < 1)
	{
		// Smoke sprite
		for(new i = 1;i < 33; i++)
		{
			if(!is_user_connected(i))
				continue;
			
			if(zp_fps_get_user_flags(i) & FPS_SPRITES)
				continue;
				
			message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,{0,0,0},i)
			write_byte(TE_SMOKE) // TE id
			write_coord(origin[0]) // x
			write_coord(origin[1]) // y
			write_coord(origin[2]-50) // z
			write_short(g_smokeSpr) // sprite
			write_byte(random_num(15, 20)) // scale
			write_byte(random_num(10, 20)) // framerate
			message_end()
		}
		
		// Task not needed anymore
		remove_task(taskid)
		return;
	}
	
	// Nemesis Class loaded?
	if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library) || !zp_class_nemesis_get(ID_BURN))
	{
		// Randomly play burning zombie scream sounds
		if (random_num(1, 20) == 1)
		{
			static sound[SOUND_MAX_LENGTH]
			ArrayGetString(g_sound_grenade_fire_player, random_num(0, ArraySize(g_sound_grenade_fire_player) - 1), sound, charsmax(sound))
			emit_sound(ID_BURN, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		
		// Fire slow down
		if ((pev(ID_BURN, pev_flags) & FL_ONGROUND) && get_pcvar_float(cvar_grenade_fire_slowdown) > 0.0)
		{
			static Float:velocity[3]
			pev(ID_BURN, pev_velocity, velocity)
			xs_vec_mul_scalar(velocity, get_pcvar_float(cvar_grenade_fire_slowdown), velocity)
			set_pev(ID_BURN, pev_velocity, velocity)
		}
	}
	
	// Get player's health
	new health = get_user_health(ID_BURN)
	
	if(!zp_core_is_zombie(ID_BURN))
	{
		set_user_health(ID_BURN,health - 3)
	}
	else
	{
		if(zp_class_zombie_get_current(ID_BURN)==Burned)
		{
			set_user_health(ID_BURN, health + 10)
		}
		else
		if(zp_class_zombie_get_current(ID_BURN)==Frozen)
		{
			if (health - floatround(get_pcvar_float(cvar_grenade_fire_damage), floatround_ceil) > 0)
				set_user_health(ID_BURN, health - 2*floatround(get_pcvar_float(cvar_grenade_fire_damage), floatround_ceil))
		}
		// Take damage from the fire
		else
		if (health - floatround(get_pcvar_float(cvar_grenade_fire_damage), floatround_ceil) > 0)
			set_user_health(ID_BURN, health - floatround(get_pcvar_float(cvar_grenade_fire_damage), floatround_ceil))
	}
	
	for(new i = 1;i < 33; i++)
	{
		if(!is_user_connected(i))
			continue;
		
		if(zp_fps_get_user_flags(i) & FPS_SPRITES)
			continue;
			
		message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,{0,0,0},i)
		write_byte(TE_SPRITE) // TE id
		write_coord(origin[0]+random_num(-5, 5)) // x
		write_coord(origin[1]+random_num(-5, 5)) // y
		write_coord(origin[2]+random_num(-10, 10)) // z
		write_short(g_flameSpr) // sprite
		write_byte(random_num(5, 10)) // scale
		write_byte(200) // brightness
		message_end()
	}
	
	// Decrease burning duration counter
	g_BurningDuration[ID_BURN]--
}


// Command start
public client_PreThink (Player)
{
	// Dead, zombie or not affected
	if (!is_user_alive(Player))
		return;
	
	if(zp_core_is_zombie(Player))
		return;
	
	if(!task_exists(Player+TASK_BURN))
		return;
		
	// We are holding an active weapon
	if ( get_pdata_cbase ( Player, OFFSET_ACTIVE, LINUX_DIFF ) )
	{
		// New recoil
		static Float:r[3]
		r[0] = float(random_num(-3,3))
		r[1] = float(random_num(-3,3))
		r[2] = float(random_num(-3,3))
		set_pev ( Player, pev_punchangle, r )
	}	
}
// Fire Grenade: Fire Blast
create_blast2(const Float:origin[3])
{
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+385.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(100) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+470.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(80) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(50) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+555.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(100) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
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
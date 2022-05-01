/*
[ZP] Extra Item: Golden MP5 NAVY
Team: Humans

Description: This plugin adds a new weapon for Human Teams.
Weapon Cost: 15

Features:
- This weapon do more damage
- This weapon has zoom
- Launch Lasers
- This weapon has unlimited bullets


Cvars:


- zp_gmp5_dmg_multiplier <5> - Damage Multiplier for Golden mp5?
- zp_gmp5_gold_bullets <1|0> - Golden bullets effect ?
- zp_gmp5_custom_model <1|0> - golden mp5 Custom Model
- zp_gmp5_unlimited_clip <1|0> - golden mp5 Unlimited Clip 

*/



#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>
#include <zmvip>
#include <zp50_fps>
//#include <xs>

#define is_valid_player(%1) (1 <= %1 <= 32)

new gmp5_V_MODEL[64] = "models/zac/v_golden_mp5.mdl"
new gmp5_P_MODEL[64] = "models/zac/p_golden_mp5.mdl"

/* Pcvars */
new cvar_dmgmultiplier, cvar_goldbullets,  cvar_custommodel, cvar_uclip

// Item ID
new g_itemid

new bool:g_Hasmp5navy[33]

new g_hasZoom[ 33 ]
new bullets[ 33 ]

// Sprite
new m_spriteTexture

const Wep_mp5navy = ((1<<CSW_MP5NAVY))

public plugin_init()
{
	
	/* CVARS */
	cvar_dmgmultiplier = register_cvar("zp_gmp5_dmg_multiplier", "2.5")
	cvar_custommodel = register_cvar("zp_gmp5_custom_model", "1")
	cvar_goldbullets = register_cvar("zp_gmp5_gold_bullets", "1")
	cvar_uclip = register_cvar("zp_gmp5_unlimited_clip", "1")
	
	// Register The Plugin
	register_plugin("[ZP] Extra: Golden MP5", "1.1", "Wisam187")
	// Register Zombie Plague extra item
	g_itemid = zv_register_extra_item("Golden MP5","", 30, ZP_TEAM_HUMAN)
	// Death Msg
	register_event("DeathMsg", "Death", "a")
	// Weapon Pick Up
	register_event("WeapPickup","checkModel","b","1=19")
	// Current Weapon Event
	register_event("CurWeapon","checkWeapon","be","1=1")
	//register_event("CurWeapon", "make_tracer", "be", "1=1", "3>0")
	// Ham TakeDamage
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	//register_forward( FM_CmdStart, "fw_CmdStart" )
	RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1)
	RegisterHam(Ham_TraceAttack, "player", "CBaseEntity_TraceAttack_PostP", 1);
	RegisterHam(Ham_TraceAttack, "worldspawn", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_wall", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_breakable", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_door", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "CBaseEntity_TraceAttack_Post", 1);	
	RegisterHam(Ham_TraceAttack, "info_target", "CBaseEntity_TraceAttack_Post", 1);	

}

public client_connect(id)
{
	g_Hasmp5navy[id] = false
}
public CBaseEntity_TraceAttack_Post(this, pevAttacker, Float:flDamage, Float:vecDir[3], tr,damage_type)
{
	if(!is_user_connected(pevAttacker))
	return HAM_IGNORED;
	
	new clip,ammo
	new wpnid = get_user_weapon(pevAttacker,clip,ammo)
	new pteam[16]
		
	get_user_team(pevAttacker, pteam, 15)
	if (this == pevAttacker)
	return HAM_IGNORED;
	if (!is_user_alive(pevAttacker))
	return HAM_IGNORED;
	if(wpnid == CSW_MP5NAVY && g_Hasmp5navy[pevAttacker] )
	{
		new Float:vecEndPos[3];
		get_tr2(tr, TR_vecEndPos, vecEndPos);
		for(new i = 1;i < 33; i++)
		{
			if(!is_user_connected(i))
				continue;
			
			if(zp_fps_get_user_flags(i) & FPS_SPRITES)
				continue;
				
			message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,{0,0,0},i)
			write_byte(TE_BEAMENTPOINT);
			write_short(pevAttacker | 0x1000);
			engfunc(EngFunc_WriteCoord, vecEndPos[0]);
			engfunc(EngFunc_WriteCoord, vecEndPos[1]);
			engfunc(EngFunc_WriteCoord, vecEndPos[2]);
			write_short(m_spriteTexture);
			write_byte(0); // starting frame
			write_byte(0); // frame rate in 0.1's
			write_byte(1); // life in 0.1's
			write_byte(5); // line wdith in 0.1's
			write_byte(0); // noise amplitude in 0.01's
			write_byte(255); // red
			write_byte(200); // green
			write_byte(0); // blue
			write_byte(100); // brightness
			write_byte(10); // scroll speed in 0.1's
			message_end();
		}
		/*
		if(!(damage_type & DMG_BULLET))
			return HAM_IGNORED;
		
		if(!is_user_connected(this))
			return HAM_IGNORED;
		
		if(!zp_core_is_zombie(this))
			return HAM_IGNORED;					
			
		new Float:velocity[3]; pev(this, pev_velocity, velocity)
		if(pev(this, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)) //ducking
			xs_vec_mul_scalar(vecDir, 20.0, vecDir)
		else
			xs_vec_mul_scalar(vecDir, 40.0, vecDir)
		xs_vec_add(velocity, vecDir, vecDir)
		entity_set_vector(this, EV_VEC_velocity, vecDir)
		*/
	}	 
	return HAM_IGNORED;
}
public CBaseEntity_TraceAttack_PostP(this, pevAttacker, Float:flDamage, Float:vecDir[3], tr,damage_type)
{
	if(!is_user_connected(pevAttacker))
	return HAM_IGNORED;
	
	new clip,ammo
	new wpnid = get_user_weapon(pevAttacker,clip,ammo)
	new pteam[16]
		
	get_user_team(pevAttacker, pteam, 15)
	if (this == pevAttacker)
	return HAM_IGNORED;
	if (!is_user_alive(pevAttacker))
	return HAM_IGNORED;
	if(wpnid == CSW_MP5NAVY && g_Hasmp5navy[pevAttacker] )
	{
		new Float:vecEndPos[3];
		get_tr2(tr, TR_vecEndPos, vecEndPos);
		for(new i = 1;i < 33; i++)
		{
			if(!is_user_connected(i))
				continue;
			
			if(zp_fps_get_user_flags(i) & FPS_SPRITES)
				continue;
				
			message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,{0,0,0},i)
			write_byte(TE_BEAMENTPOINT);
			write_short(pevAttacker | 0x1000);
			engfunc(EngFunc_WriteCoord, vecEndPos[0]);
			engfunc(EngFunc_WriteCoord, vecEndPos[1]);
			engfunc(EngFunc_WriteCoord, vecEndPos[2]);
			write_short(m_spriteTexture);
			write_byte(0); // starting frame
			write_byte(0); // frame rate in 0.1's
			write_byte(1); // life in 0.1's
			write_byte(5); // line wdith in 0.1's
			write_byte(5); // noise amplitude in 0.01's
			write_byte(255); // red
			write_byte(200); // green
			write_byte(0); // blue
			write_byte(100); // brightness
			write_byte(10); // scroll speed in 0.1's
			message_end();
		}
		/*
		if(!(damage_type & DMG_BULLET))
			return HAM_IGNORED;
		
		if(!is_user_connected(this))
			return HAM_IGNORED;
		
		if(!zp_core_is_zombie(this))
			return HAM_IGNORED;					
			
		new Float:velocity[3]; pev(this, pev_velocity, velocity)
		if(pev(this, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)) //ducking
			xs_vec_mul_scalar(vecDir, 20.0, vecDir)
		else
			xs_vec_mul_scalar(vecDir, 40.0, vecDir)
		xs_vec_add(velocity, vecDir, vecDir)
		entity_set_vector(this, EV_VEC_velocity, vecDir)	
		*/
	}	 
	return HAM_IGNORED;
}
public client_disconnect(id)
{
	g_Hasmp5navy[id] = false
}

public Death()
{
	g_Hasmp5navy[read_data(2)] = false
}

public fwHamPlayerSpawnPost(id)
{
	g_Hasmp5navy[id] = false
}

public plugin_precache()
{
	precache_model(gmp5_V_MODEL)
	precache_model(gmp5_P_MODEL)
	m_spriteTexture = precache_model("sprites/dot.spr")
	precache_sound("weapons/zoom.wav")
}

public zp_fw_core_cure_post(id)
	g_Hasmp5navy[id] = false
public zp_fw_core_infect_post(id)
	g_Hasmp5navy[id] = false
	
public checkModel(id)
{
	if ( zp_core_is_zombie(id) )
		return PLUGIN_HANDLED
	
	new szWeapID = read_data(2)
	
	if ( szWeapID == CSW_MP5NAVY && g_Hasmp5navy[id] == true && get_pcvar_num(cvar_custommodel) )
	{
		set_pev(id, pev_viewmodel2, gmp5_V_MODEL)
		set_pev(id, pev_weaponmodel2, gmp5_P_MODEL)
	}
	return PLUGIN_HANDLED
}

public checkWeapon(id)
{
	new plrClip, plrAmmo, plrWeap[32]
	new plrWeapId
	
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	if (plrWeapId == CSW_MP5NAVY && g_Hasmp5navy[id])
	{
		checkModel(id)
	}
	else 
	{
		return PLUGIN_CONTINUE
	}
	
	if (plrClip == 0 && get_pcvar_num(cvar_uclip))
	{
		// If the user is out of ammo..
		get_weaponname(plrWeapId, plrWeap, 31)
		// Get the name of their weapon
		give_item(id, plrWeap)
		engclient_cmd(id, plrWeap) 
		engclient_cmd(id, plrWeap)
		engclient_cmd(id, plrWeap)
	}
	return PLUGIN_HANDLED
}



public fw_TakeDamage(victim, inflictor, attacker, Float:damage, bits)
{
    if ( is_valid_player( attacker ) && get_user_weapon(attacker) == CSW_MP5NAVY && g_Hasmp5navy[attacker] && (bits&DMG_BULLET) )
    {
        SetHamParamFloat(4, damage * get_pcvar_float( cvar_dmgmultiplier ) )
    }
}

public fw_CmdStart( id, uc_handle, seed )
{
	if( !is_user_alive( id ) ) 
		return PLUGIN_HANDLED
	
	if( ( get_uc( uc_handle, UC_Buttons ) & IN_ATTACK2 ) && !( pev( id, pev_oldbuttons ) & IN_ATTACK2 ) )
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon( id, szClip, szAmmo )
		
		if( szWeapID == CSW_MP5NAVY && g_Hasmp5navy[id] == true && !g_hasZoom[id] == true)
		{
			g_hasZoom[id] = true
			cs_set_user_zoom( id, CS_SET_AUGSG552_ZOOM, 0 )
			emit_sound( id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100 )
		}
		
		else if ( szWeapID == CSW_MP5NAVY && g_Hasmp5navy[id] == true && g_hasZoom[id])
		{
			g_hasZoom[ id ] = false
			cs_set_user_zoom( id, CS_RESET_ZOOM, 0 )
			
		}
		
	}
	return PLUGIN_HANDLED
}


public make_tracer(id)
{
	if (get_pcvar_num(cvar_goldbullets))
	{
		new clip,ammo
		new wpnid = get_user_weapon(id,clip,ammo)
		new pteam[16]
		
		get_user_team(id, pteam, 15)
		
		if ((bullets[id] > clip) && (wpnid == CSW_MP5NAVY) && g_Hasmp5navy[id]) 
		{
			new vec1[3], vec2[3]
			get_user_origin(id, vec1, 1) // origin; your camera point.
			get_user_origin(id, vec2, 4) // termina; where your bullet goes (4 is cs-only)
			
			
			//BEAMENTPOINTS
			message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte (0)     //TE_BEAMENTPOINTS 0
			write_coord(vec1[0])
			write_coord(vec1[1])
			write_coord(vec1[2])
			write_coord(vec2[0])
			write_coord(vec2[1])
			write_coord(vec2[2])
			write_short( m_spriteTexture )
			write_byte(1) // framestart
			write_byte(5) // framerate
			write_byte(2) // life
			write_byte(10) // width
			write_byte(0) // noise
			write_byte( 255 )     // r, g, b
			write_byte( 215 )       // r, g, b
			write_byte( 0 )       // r, g, b
			write_byte(200) // brightness
			write_byte(150) // speed
			message_end()
		}
	
		bullets[id] = clip
	}
	
}

public zv_extra_item_selected(player, itemid)
{
	if ( itemid == g_itemid )
	{
		if ( user_has_weapon(player, CSW_MP5NAVY) )
		{
			drop_prim(player)
		}
		
		give_item(player, "weapon_mp5navy")
		//client_print(player, print_chat, "[ZP] You bought Golden MP5")
		g_Hasmp5navy[player] = true;
	}
}

stock drop_prim(id) 
{
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	for (new i = 0; i < num; i++) {
		if (Wep_mp5navy & (1<<weapons[i])) 
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang1034\\ f0\\ fs16 \n\\ par }
*/
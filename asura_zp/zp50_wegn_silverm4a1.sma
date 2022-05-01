/*
	[WEGN] Extra Item: Silver M4A1
	Team: Humans
	
	Copyrights 2009, Shuttle_Wave
	
	--------------------------------------
	Coded For Waves Extreme Gaming Network
	--------------------------------------
	
	------------------------
	www.waves-gaming.info
	------------------------
	
	THIS MOD IS CURRENTLY USE IN [WEGN] Waves Extreme Gaming Network ZOMBIE-PLAGUE
	
	///////////////////////
	// Credits THANKS    //
	///////////////////////
	
	Exolent[jNr] : Helping with Silver Bullets and few bugs.
	AlejandroSk : Orginal Golden AK47 Script
	Alex Kim (Shadow_Wave) : Tester
	
	////////////////// 
	//Cvars:	//
	//////////////////
	
	- zp_silverm4_dmg_multiplier <5> - Damage Multiplier for Silver M4A1
	- zp_silverm4_silver_bullets <1|0> - Silver bullets effect ?
	- zp_silverm4_custom_model <1|0> - M4A1 Custom Model
	- zp_silverm4_unlimited_clip <1|0> - M4A1 Unlimited Clip 
*/

///////////////////
// Includes	 //
///////////////////
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <zp50_items>
#include <zp50_colorchat>
#include <zp50_fps>
#include <za_items>
/////////////////
//Define       //
/////////////////
#define is_valid_player(%1) (1 <= %1 <= 32)

///////////////////////////////////////////////////
// ADD OUR OWN CUSTOM SILVER M4A1 MODELS HERE    //
///////////////////////////////////////////////////

new M4A1_V_MODEL[64] = "models/zombie_plague/v_gc_silverm4a1.mdl"
new M4A1_P_MODEL[64] = "models/zombie_plague/p_silverm4a1.mdl"
new M4A1_W_MODEL[64] = "models/zombie_plague/w_silverm4a1.mdl"

new ASURA_M4_V_MODEL[64] = "models/zombie_plague/v_m4a1_gold.mdl"
new ASURA_M4_P_MODEL[64] = "models/zombie_plague/p_m4a1_gold.mdl"

/* Pcvars */
new cvar_dmgmultiplier, cvar_custommodel, cvar_uclip

// Item ID
new g_itemid,g_itemid_vip
new g_HasM4A1[33]
//new g_hasZoom[ 33 ]
//new bullets[ 33 ]

// Sprite
new m_spriteTexture
const Wep_m4a1 = ((1<<CSW_M4A1))
public plugin_init()
{
	
	/* CVARS */
	cvar_dmgmultiplier = register_cvar("zp_silverm4_dmg_multiplier", "2")
	cvar_custommodel = register_cvar("zp_silverm4_custom_model", "1")
	cvar_uclip = register_cvar("zp_silverm4_unlimited_clip", "1")
	
	// Register The Plugin
	register_plugin("[WEGN] Extra: Silver/Gold M4A1", "2.0", "Shuttle_Wave")
	// Register Zombie Plague extra item
	g_itemid = zp_items_register("Silver M4A1", "",25)
	
	g_itemid_vip = za_items_register("Goldden M4a1", "[2.25x Damage]", 25, 0, 0)
	
	//g_itemid_vip = zv_register_extra_item("Silver M4A1", "FREE",0,ZV_TEAM_HUMAN)
	// Death Msg
	register_event("DeathMsg", "Death", "a")
	// Weapon Pick Up
	register_event("WeapPickup","checkModel","b","1=19")
	// Current Weapon Event
	register_event("CurWeapon","checkWeapon","be","1=1")
	//register_event("CurWeapon", "make_tracer", "be", "1=1", "3>0")
	RegisterHam(Ham_TraceAttack, "player", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "worldspawn", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_wall", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_breakable", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_door", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "info_target", "CBaseEntity_TraceAttack_Post", 1);
	// Ham TakeDamage
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	//register_forward( FM_CmdStart, "fw_CmdStart" )
	RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1)
	
	register_forward(FM_SetModel, "fw_SetModel");	
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m4a1", "fw_AddToPlayer");
	
}
public client_connect(id)
{
	g_HasM4A1[id] =0
}
public client_disconnected(id)
{
	g_HasM4A1[id] = 0
}
public Death()
{
	g_HasM4A1[read_data(2)] = 0
}
public fwHamPlayerSpawnPost(id)
{
	g_HasM4A1[id] = 0
}
public plugin_precache()
{
	precache_model(M4A1_V_MODEL)
	precache_model(M4A1_P_MODEL)
	precache_model(ASURA_M4_V_MODEL)
	precache_model(ASURA_M4_P_MODEL)
	precache_model(M4A1_W_MODEL)
	m_spriteTexture = precache_model("sprites/dot.spr")
	//precache_sound("weapons/zoom.wav")
}
public zp_user_infected_post(id)
{
	g_HasM4A1[id] = 0
}
public checkModel(id)
{
	if ( zp_core_is_zombie(id) )
	return PLUGIN_HANDLED
	
	new szWeapID = read_data(2)
	
	if ( szWeapID == CSW_M4A1 && g_HasM4A1[id] == 1 && get_pcvar_num(cvar_custommodel) )
	{
		set_pev(id, pev_viewmodel2, M4A1_V_MODEL)
		set_pev(id, pev_weaponmodel2, M4A1_P_MODEL)
	}
	if ( szWeapID == CSW_M4A1 && g_HasM4A1[id] == 2 && get_pcvar_num(cvar_custommodel) )
	{
		set_pev(id, pev_viewmodel2, ASURA_M4_V_MODEL)
		set_pev(id, pev_weaponmodel2, ASURA_M4_P_MODEL)
	}
	return PLUGIN_HANDLED
}
public checkWeapon(id)
{
	new plrClip, plrAmmo, plrWeap[32]
	new plrWeapId
	
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	if (plrWeapId == CSW_M4A1 && g_HasM4A1[id])
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

public fw_TakeDamage(victim, inflictor, attacker, Float:damage,bits)
{
	if ( is_valid_player( attacker ) && get_user_weapon(attacker) == CSW_M4A1 && g_HasM4A1[attacker] && (bits&DMG_BULLET))
	{
		if(g_HasM4A1[attacker] == 1)
			SetHamParamFloat(4, damage * get_pcvar_float( cvar_dmgmultiplier ) )
		if(g_HasM4A1[attacker] == 2)
		{
			SetHamParamFloat(4, damage * get_pcvar_float( cvar_dmgmultiplier ) * 1.5 )
			new vic = -1
			static MainVicOrig[3], VicOrigin[3]
			static Float:origin[3]
			get_user_origin(victim, MainVicOrig, 0)
			pev(victim,pev_origin,origin)

			while ((vic = engfunc(EngFunc_FindEntityInSphere, vic, origin, 150.0)) != 0)
			{
				if (!is_user_alive(vic) || !zp_core_is_zombie(vic) || victim == vic)
					continue;
					
				get_user_origin(vic, VicOrigin, 0)
				make_tracer(MainVicOrig, VicOrigin)
				
				ExecuteHamB(Ham_TakeDamage, vic, attacker, attacker, damage, DMG_SHOCK)
			}
		}

	}
}
/*
public fw_CmdStart( id, uc_handle, seed )
{
	if( !is_user_alive( id ) ) 
	return PLUGIN_HANDLED
	
	if( ( get_uc( uc_handle, UC_Buttons ) & IN_ATTACK2 ) && !( pev( id, pev_oldbuttons ) & IN_ATTACK2 ) )
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon( id, szClip, szAmmo )
		
		if( szWeapID == CSW_M4A1 && g_HasM4A1[id] == true && !g_hasZoom[id] == true)
		{
			g_hasZoom[id] = true
			cs_set_user_zoom( id, CS_SET_AUGSG552_ZOOM, 0 )
			emit_sound( id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100 )
		}
		
		else if ( szWeapID == CSW_M4A1 && g_HasM4A1[id] == true && g_hasZoom[id])
		{
			g_hasZoom[ id ] = false
			cs_set_user_zoom( id, CS_RESET_ZOOM, 0 )
			
		}
		
	}
	return PLUGIN_HANDLED
}*/

public CBaseEntity_TraceAttack_Post(this, pevAttacker, Float:flDamage, Float:vecDir[3], tr)
{
	if(!is_user_connected(pevAttacker))
	return;
	
	new clip,ammo
	new wpnid = get_user_weapon(pevAttacker,clip,ammo)
	new pteam[16]
	if(g_HasM4A1[pevAttacker] == 1)
	get_user_team(pevAttacker, pteam, 15)
	if (this == pevAttacker)
	return;
	if (!is_user_alive(pevAttacker))
	return;
	if(wpnid == CSW_M4A1 && g_HasM4A1[pevAttacker] )
	{
		new Float:vecEndPos[3];
		get_tr2(tr, TR_vecEndPos, vecEndPos);
		for(new i = 1;i < 33; i++)
		{
			if(!is_user_connected(i))
				continue;
			
			if(zp_fps_get_user_flags(i) & FPS_SPRITES)
				continue;
			if(g_HasM4A1[pevAttacker] == 1)
			{
				//BEAMENTPOINTS
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
				write_byte(10); // line wdith in 0.1's
				write_byte(0); // noise amplitude in 0.01's
				write_byte(255); // red
				write_byte(255); // green
				write_byte(255) // blue
				write_byte(200); // brightness
				write_byte(150); // scroll speed in 0.1's
				message_end();
			}
			if(g_HasM4A1[pevAttacker] == 2)
			{
				//BEAMENTPOINTS
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
				write_byte(10); // line wdith in 0.1's
				write_byte(0); // noise amplitude in 0.01's
				write_byte(255); // red
				write_byte(200); // green
				write_byte(0) // blue
				write_byte(200); // brightness
				write_byte(150); // scroll speed in 0.1's
				message_end();
			}
		}
	}
}

make_tracer(Vec1[3], Vec2[3])
{	
	//BEAMENTPOINTS
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte (0)     //TE_BEAMENTPOINTS 0
	write_coord(Vec1[0])
	write_coord(Vec1[1])
	write_coord(Vec1[2])
	write_coord(Vec2[0])
	write_coord(Vec2[1])
	write_coord(Vec2[2])
	write_short( m_spriteTexture )
	write_byte(1) // framestart
	write_byte(5) // framerate
	write_byte(2) // life
	write_byte(10) // width
	write_byte(random(10)) // noise
	write_byte( 255 )     // r, g, b
	write_byte( 220 )       // r, g, b
	write_byte( 000 )       // r, g, b 
	write_byte(200) // brightness
	write_byte(150) // speed
	message_end()
}
public zp_fw_items_select_pre(player, itemid)
{
	if(itemid!=g_itemid)
		return ZP_ITEM_AVAILABLE
	
	if(zp_core_is_zombie(player))
		return ZP_ITEM_DONT_SHOW
	
	if(g_HasM4A1[player])
		return ZP_ITEM_NOT_AVAILABLE
	
	return ZP_ITEM_AVAILABLE
}

public zp_fw_items_select_post(player, itemid)
{
	if ( itemid == g_itemid )
	{
		if ( user_has_weapon(player, CSW_M4A1) )
		{
			drop_prim(player)
		}
		
		give_item(player, "weapon_m4a1")
		zp_colored_print(player, "You bought a^3 Silver M4A1")
		g_HasM4A1[player] = 1;		
		engclient_cmd(player, "weapon_m4a1");
	}
}
public za_fw_items_select_pre(player, itemid)
{
	if(itemid!=g_itemid_vip)
		return ZP_ITEM_AVAILABLE
	
	if(zp_core_is_zombie(player))
		return ZP_ITEM_DONT_SHOW
	
	if(g_HasM4A1[player])
		return ZP_ITEM_NOT_AVAILABLE
	
	return ZP_ITEM_AVAILABLE
}

public za_fw_items_select_post(player, itemid)
{
	if ( itemid == g_itemid_vip )
	{
		if ( user_has_weapon(player, CSW_M4A1) )
		{
			drop_prim(player)
		}
		
		give_item(player, "weapon_m4a1")
		zp_colored_print(player, "You bought a^3 Golden M4A1")
		g_HasM4A1[player] = 2;		
		engclient_cmd(player, "weapon_m4a1");
	}
}
/*
public zv_extra_item_selected(player, itemid)
{
	if ( itemid == g_itemid_vip )
	{
		if ( user_has_weapon(player, CSW_M4A1) )
		{
			drop_prim(player)
		}
		
		give_item(player, "weapon_m4a1")
		zp_colored_print(player, "You bought a^3 Silver M4A1")
		g_HasM4A1[player] = true;		
		engclient_cmd(player, "weapon_m4a1");
	}
}
*/
public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_m4a1.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName))
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn
	owner = pev(entity, pev_owner)
	wpn = find_ent_by_owner(-1, "weapon_m4a1", entity)
	
	if(g_HasM4A1[owner] && pev_valid(wpn))
	{
		g_HasM4A1[owner] = false;
		set_pev(wpn, pev_impulse, 12412);	
		engfunc(EngFunc_SetModel, entity, M4A1_W_MODEL);	
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_AddToPlayer(wpn, id)
{
	if(pev_valid(wpn) && is_user_connected(id) && pev(wpn, pev_impulse) == 12412)
	{
		g_HasM4A1[id] = true;
		set_pev(wpn, pev_impulse, 0);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

stock drop_prim(id) 
{
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	for (new i = 0; i < num; i++) {
		if (Wep_m4a1 & (1<<weapons[i])) 
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}
/* Shuttle_Wave Notes - DO NOT MODIFY BELOW HERE
	*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1034\\ f0\\ fs16 \n\\ par }
*/ 
/*
[ZP] Extra Item: Golden Ak 47
Team: Humans

Description: This plugin adds a new weapon for Human Teams.
Weapon Cost: 30

Features:
- This weapon do more damage
- This weapon has zoom
- Launch Lasers
- This weapon has unlimited bullets

Credits:

KaOs - For his Dual MP5 mod

Cvars:


- zp_goldenak_dmg_multiplier <5> - Damage Multiplier for Golden Ak 47
- zp_goldenak_gold_bullets <1|0> - Golden bullets effect ?
- zp_goldenak_custom_model <1|0> - Golden ak Custom Model
- zp_goldenak_unlimited_clip <1|0> - Golden ak Unlimited Clip 

*/



#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <zp50_items>
#include <zp50_fps>
#include <zp50_colorchat>
#include <zmvip>
#include <xs>
#include <zp50_gamemodes>

#define is_valid_player(%1) (1 <= %1 <= 32)

new AK_V_MODEL[64] = "models/zombie_plague/v_gc_golden_ak47.mdl"
new AK_P_MODEL[64] = "models/zombie_plague/p_golden_ak47.mdl"
new AK_W_MODEL[64] = "models/zombie_plague/w_golden_ak47.mdl"

/* Pcvars */
new cvar_dmgmultiplier,   cvar_custommodel, cvar_uclip

// Item ID
new  g_itemid, g_itemid_vip

new bool:g_HasAk[33]
new g_hasZoom[ 33 ]

native drop_akm12(id);
new Purchases;
//new Bought[33]

// Ammo Type Names for weapons
new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
			"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
			"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }

// Sprite
new m_spriteTexture, MyAkLimit

const Wep_ak47 = ((1<<CSW_AK47))

public plugin_init()
{
	
	/* CVARS */
	cvar_dmgmultiplier = register_cvar("zp_goldenak_dmg_multiplier", "5")
	cvar_custommodel = register_cvar("zp_goldenak_custom_model", "1")
	cvar_uclip = register_cvar("zp_goldenak_unlimited_clip", "1")
	
	// Register The Plugin
	register_plugin("[ZP] Extra: Golden Ak 47", "1.1", "AlejandroSk")
	// Register Zombie Plague extra item
	g_itemid = zp_items_register("Golden Ak 47","",60);
	g_itemid_vip = zv_register_extra_item("Golden AK-47","20 Ammo Packs",20,ZV_TEAM_HUMAN)
	// Death Msg
	register_event("DeathMsg", "Death", "a")
	// Weapon Pick Up
	register_event("WeapPickup","checkModel","b","1=19")
	// Current Weapon Event
	register_event("CurWeapon","checkWeapon","be","1=1")
//	register_event("CurWeapon", "make_tracer", "be", "1=1", "3>0")
	// Ham TakeDamage
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1)	
	RegisterHam(Ham_TraceAttack, "player", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "worldspawn", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_wall", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_breakable", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_door", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "info_target", "CBaseEntity_TraceAttack_Post", 1);
	register_forward( FM_CmdStart, "fw_CmdStart" )	
	
	register_forward(FM_SetModel, "fw_SetModel");	
	RegisterHam(Ham_Item_AddToPlayer, "weapon_ak47", "fw_AddToPlayer");
}

new Infection, Multi;

public plugin_cfg()
{
	Infection = zp_gamemodes_get_id("Infection Mode");
	Multi = zp_gamemodes_get_id("Multiple Infection Mode");
}
public client_connect(id)
{
	g_HasAk[id] = false
}

public client_disconnecteded(id)
{
	g_HasAk[id] = false
}

public Death()
{
	g_HasAk[read_data(2)] = false
}

public fwHamPlayerSpawnPost(id)
{
	g_HasAk[id] = false
}

public plugin_precache()
{
	precache_model(AK_V_MODEL)
	precache_model(AK_P_MODEL)
	precache_model(AK_W_MODEL)
	m_spriteTexture = precache_model("sprites/dot.spr")
	precache_sound("weapons/zoom.wav")
}

public zp_fw_core_infect_post(id)
{
	g_HasAk[id] = false
}

public checkModel(id)
{
	if ( zp_core_is_zombie(id) )
		return PLUGIN_HANDLED
	
	new szWeapID = read_data(2)
	
	if ( szWeapID == CSW_AK47 && g_HasAk[id] == true && get_pcvar_num(cvar_custommodel))
	{
		set_pev(id, pev_viewmodel2, AK_V_MODEL)
		set_pev(id, pev_weaponmodel2, AK_P_MODEL)
	}
	return PLUGIN_HANDLED
}

public checkWeapon(id)
{
	new plrClip, plrAmmo, plrWeap[32]
	new plrWeapId
	
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	if (plrWeapId == CSW_AK47 && g_HasAk[id])
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
    if ( is_valid_player( attacker ) && get_user_weapon(attacker) == CSW_AK47 && g_HasAk[attacker]&&(bits&DMG_BULLET))
    {
        SetHamParamFloat(4, damage * get_pcvar_float( cvar_dmgmultiplier ) )
    }
}

/*
public make_tracer(id)
{
	if (get_pcvar_num(cvar_goldbullets))
	{
		new clip,ammo
		new wpnid = get_user_weapon(id,clip,ammo)
		new pteam[16]
		
		get_user_team(id, pteam, 15)
		
		if ((bullets[id] > clip) && (wpnid == CSW_AK47) && g_HasAk[id]) 
		{
			new Float:vecEndPos[3];
			get_tr2(trace, TR_vecEndPos, vecEndPos)
		//	new vec2[3], vec[3]
		//	get_user_origin(id,vec, 4)
		//	get_user_origin(id, vec2, 3) // termina; where your bullet goes (4 is cs-only)
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
			write_byte(TE_BEAMENTPOINT);
			write_short(id | 0x1000); // start entity
			engfunc(EngFunc_WriteCoord, vecEndPos[0]); // endposition.x
			engfunc(EngFunc_WriteCoord, vecEndPos[1]); // endposition.y
			engfunc(EngFunc_WriteCoord, vecEndPos[2]); // endposition.z
			write_short(m_spriteTexture); // sprite index
			write_byte(0); // starting frame
			write_byte(0); // frame rate in 0.1's
			write_byte(1); // life in 0.1's
			write_byte(10); // line wdith in 0.1's
			write_byte(0); // noise amplitude in 0.01's
			write_byte(255); // red
			write_byte(200); // green
			write_byte(0); // blue
			write_byte(200); // brightness
			write_byte(10); // scroll speed in 0.1's
			message_end();


		}
	
		bullets[id] = clip
	}
	
}
*/		

public fw_CmdStart( id, uc_handle, seed )
{
	if( !is_user_alive( id ) ) 
		return PLUGIN_HANDLED
	
	if( ( get_uc( uc_handle, UC_Buttons ) & IN_ATTACK2 ) && !( pev( id, pev_oldbuttons ) & IN_ATTACK2 ) )
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon( id, szClip, szAmmo )
		
		if( szWeapID == CSW_AK47 && g_HasAk[id] == true && !g_hasZoom[id] == true)
		{
			g_hasZoom[id] = true
			cs_set_user_zoom( id, CS_SET_AUGSG552_ZOOM, 0 )
			emit_sound( id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100 )
		}
		
		else if ( szWeapID == CSW_AK47 && g_HasAk[id] == true && g_hasZoom[id])
		{
			g_hasZoom[ id ] = false
			cs_set_user_zoom( id, CS_RESET_ZOOM, 0 )
			
		}
		
	}
	return PLUGIN_HANDLED
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_ak47.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName))
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn
	owner = pev(entity, pev_owner)
	wpn = find_ent_by_owner(-1, "weapon_ak47", entity)
	
	if(g_HasAk[owner] && pev_valid(wpn))
	{
		g_HasAk[owner] = false;
		set_pev(wpn, pev_impulse, 10124);	
		engfunc(EngFunc_SetModel, entity, AK_W_MODEL);	
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_AddToPlayer(wpn, id)
{
	if(pev_valid(wpn) && is_user_connected(id) && pev(wpn, pev_impulse) == 10124)
	{
		g_HasAk[id] = true;
		set_pev(wpn, pev_impulse, 0);
		
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public CBaseEntity_TraceAttack_Post(this, pevAttacker, Float:flDamage, Float:vecDir[3], tr)
{
	if(!is_user_connected(pevAttacker))
	return;
	
	new clip,ammo
	new wpnid = get_user_weapon(pevAttacker,clip,ammo)
	new pteam[16]
		
	get_user_team(pevAttacker, pteam, 15)
	if (this == pevAttacker)
	return;
	if (!is_user_alive(pevAttacker))
	return;
	if(wpnid == CSW_AK47 && g_HasAk[pevAttacker] )
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
			write_byte(10); // line wdith in 0.1's
			write_byte(0); // noise amplitude in 0.01's
			write_byte(255); // red
			write_byte(200); // green
			write_byte(0); // blue
			write_byte(200); // brightness
			write_byte(10); // scroll speed in 0.1's
			message_end();
		}
	}
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_itemid)
		return ZP_ITEM_AVAILABLE;
	
	// Antidote only available to zombies
	if (zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW;
	
	if(zp_gamemodes_get_current()!=Infection&&zp_gamemodes_get_current()!=Multi)
		return ZP_ITEM_DONT_SHOW;
	

	if(g_HasAk[id])
		return ZP_ITEM_NOT_AVAILABLE;
	
	if(AlivCount() >= 22)
		MyAkLimit = 2
	else MyAkLimit = 1
	
	new Txt[32]
	format(Txt,charsmax(Txt),"[%d/%d]",Purchases,MyAkLimit)
	zp_items_menu_text_add(Txt)
	
	if(Purchases >= MyAkLimit)
		return ZP_ITEM_NOT_AVAILABLE


	//if(Bought[id])
	//return ZP_ITEM_NOT_AVAILABLE
	
	return ZP_ITEM_AVAILABLE;
}
public zp_fw_items_select_post(player, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_itemid)
	return;
	Purchases++;
	drop_akm12(player);
	drop_prim(player)
	give_item(player, "weapon_ak47")
	new weaponid = get_weaponid("weapon_ak47")
	ExecuteHamB(Ham_GiveAmmo, player, MAXBPAMMO[weaponid], AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
	zp_colored_print(player,"You bought a^3 Golden AK-47")
	g_HasAk[player] = true;
	//Bought[player]++;	
	engclient_cmd(player, "weapon_ak47");
}

public zv_extra_item_selected(player, itemid)
{
	// This is not our item
	if (itemid != g_itemid_vip)
	return;
	drop_akm12(player);
	drop_prim(player)
	give_item(player, "weapon_ak47")
	new weaponid = get_weaponid("weapon_ak47")
	ExecuteHamB(Ham_GiveAmmo, player, MAXBPAMMO[weaponid], AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
	zp_colored_print(player,"You bought a^3 Golden AK-47")
	g_HasAk[player] = true;
	//Bought[player]++;	
	engclient_cmd(player, "weapon_ak47");
}

public zp_fw_gamemodes_start()
{
	Purchases=0;
	/*for(new id=1;id<33;id++)
		Bought[id]=false;*/
}

public plugin_natives()
{
	register_native("give_golden_ak","native_give_ak", 1)
	register_native("drop_golden_ak","native_drop_ak",1);
}

public native_drop_ak(id)
{
	g_HasAk[id]=false;
}
public native_give_ak(player)
{
	give_item(player, "weapon_ak47")
	new weaponid = get_weaponid("weapon_ak47")
	ExecuteHamB(Ham_GiveAmmo, player, MAXBPAMMO[weaponid], AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
	zp_colored_print(player,"You got^3 Golden AK-47")
	g_HasAk[player] = true;
}

AlivCount()
{
	new AlivePlayers
	for(new i=1; i < 32;i++)
	{
		if(!is_user_alive(i))
			continue
		AlivePlayers++
	}
	return AlivePlayers;
}

stock drop_prim(id) 
{
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	for (new i = 0; i < num; i++) {
		if (Wep_ak47 & (1<<weapons[i])) 
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
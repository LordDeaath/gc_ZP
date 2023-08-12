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
#include <targetex>
#include <zp50_grenade_frost>
#include <zp50_grenade_fire>
#include <zp50_class_human>

native zp_set_damage_required(id,amount);
native zp_get_damage_required(id);

new AK_V_MODEL[64] = "models/gc_mdls/v_mp5_r.mdl"
new AK_V_MODEL_B[64] = "models/gc_mdls/v_mp5_b.mdl"
new AK_V_MODEL_G[64] = "models/gc_mdls/v_mp5_g.mdl"
new AK_V_MODEL_GG[64] = "models/gc_mdls/v_mp5_gold.mdl"

new AK_P_MODEL[64] = "models/gc_mdls/p_mp5_n.mdl"
new AK_W_MODEL[64] = "models/gc_mdls/w_mp5.mdl"

/* Pcvars */
new cvar_dmgmultiplier[4],   cvar_custommodel, cvar_uclip, iSAffct[33]

// Item ID
new  g_itemid//, g_itemid_vip

new bool:g_HasAk[33], iCombo[33], iCol[33][4], iColor[33], Float:iNoise[33]
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
new m_spriteTexture, Float:pCooldown[33], cvar_cooldown
new Float: cl_pushangle[33][3]

const Wep_ak47 = ((1<<CSW_MP5NAVY))

public plugin_init()
{
	
	/* CVARS */
	cvar_custommodel = register_cvar("zp_blackmp_custom_model", "1")
	cvar_uclip = register_cvar("zp_blackmp_unlimited_clip", "1")
	cvar_cooldown = register_cvar("zp_blackmp_cooldown", "10")
	cvar_dmgmultiplier[0] = register_cvar("zp_blackmp_dmg1", "2.25")
	cvar_dmgmultiplier[1] = register_cvar("zp_blackmp_dmg2", "2.50")
	cvar_dmgmultiplier[2] = register_cvar("zp_blackmp_dmg3", "2.75")
	cvar_dmgmultiplier[3] = register_cvar("zp_blackmp_dmg4", "2.0")
	
	// Register The Plugin
	register_plugin("[ZP] Extra: Elemental MP5", "1.1", "AlejandroSk")
	// Register Zombie Plague extra item
	g_itemid = zp_items_register("Elemental MP5","",100);
	// g_itemid_vip = zv_register_extra_item("Golden AK-47","20 Ammo Packs",20,ZV_TEAM_HUMAN)
	// Death Msg
	register_event("DeathMsg", "Death", "a")

	// Weapon Pick Up
	register_event("WeapPickup","checkModel","b","1=19")
	// Current Weapon Event
	register_event("CurWeapon","checkWeapon","be","1=1")
//	register_event("CurWeapon", "make_tracer", "be", "1=1", "3>0")
	// Ham TakeDamage
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamagePost",1)
	RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1)	
	RegisterHam(Ham_TraceAttack, "player", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "worldspawn", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_wall", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_breakable", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_door", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "CBaseEntity_TraceAttack_Post", 1);
	RegisterHam(Ham_TraceAttack, "info_target", "CBaseEntity_TraceAttack_Post", 1);
	register_clcmd("zp_bmp5", "cmd_ak", ADMIN_IMMUNITY, "zp_bmp5 <player> - free Elemental mp5")

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mp5navy", "fw_Weapon_PrimaryAttack_Pre")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mp5navy", "fw_Weapon_PrimaryAttack_Post", 1)
	
	register_forward(FM_SetModel, "fw_SetModel");	
	RegisterHam(Ham_Item_AddToPlayer, "weapon_mp5navy", "fw_AddToPlayer");
}

new Infection, Multi, DeadPool;

public plugin_cfg()
{
	Infection = zp_gamemodes_get_id("Infection Mode");
	Multi = zp_gamemodes_get_id("Multiple Infection Mode");
	DeadPool = zp_class_human_get_id("Dead Pool")
}
public client_connect(id)
{
	g_HasAk[id] = false
}

public client_disconnecteded(id)
{
	if(g_HasAk[id])
		Purchases--
		
	g_HasAk[id] = false
}

public Death()
{
	if(g_HasAk[read_data(2)])
	{	
		Purchases--
		g_HasAk[read_data(2)] = false
	}
}

public fwHamPlayerSpawnPost(id)
{
	if(g_HasAk[id])
		Purchases--
	g_HasAk[id] = false
}

public plugin_precache()
{
	precache_model(AK_V_MODEL)
	precache_model(AK_V_MODEL_B)
	precache_model(AK_V_MODEL_G)
	precache_model(AK_V_MODEL_GG)	
	precache_model(AK_P_MODEL)
	precache_model(AK_W_MODEL)
	m_spriteTexture = precache_model("sprites/dot.spr")
	precache_sound("weapons/zoom.wav")
}

public zp_fw_core_infect_post(id)
{
	if(g_HasAk[id])
		Purchases--
	g_HasAk[id] = false
}

public checkModel(id)
{
	if( !is_user_alive(id))
		return PLUGIN_HANDLED	
	if ( zp_core_is_zombie(id) )
		return PLUGIN_HANDLED
	
	new szWeapID = read_data(2)
	
	if ( szWeapID == CSW_MP5NAVY && g_HasAk[id] == true && get_pcvar_num(cvar_custommodel))
	{
		if(iColor[id] <= 100)
			set_pev(id, pev_viewmodel2, AK_V_MODEL)
		else if(iColor[id] <= 250)
			set_pev(id, pev_viewmodel2, AK_V_MODEL_B)
		else if(iColor[id] <= 500)
			set_pev(id, pev_viewmodel2, AK_V_MODEL_G)
		else if (iColor[id] <= 750)
			set_pev(id, pev_viewmodel2, AK_V_MODEL_GG)
		set_pev(id, pev_weaponmodel2, AK_P_MODEL)
	}
	return PLUGIN_HANDLED
}

public checkWeapon(id)
{
	new plrClip, plrAmmo, plrWeap[32]
	new plrWeapId
	
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	if (plrWeapId == CSW_MP5NAVY && g_HasAk[id])
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
	if(!is_user_connected(attacker))
		return HAM_IGNORED
	if (get_user_weapon(attacker) == CSW_MP5NAVY && g_HasAk[attacker]&&(bits&DMG_BULLET))
	{
		if(zp_class_human_get_current(attacker) == DeadPool)
			SetHamParamFloat(4, damage * get_pcvar_float( cvar_dmgmultiplier[3] ) )
		else if(iColor[attacker] <= 100)
			SetHamParamFloat(4, damage * get_pcvar_float( cvar_dmgmultiplier[0] ) )
		else if(iColor[attacker] <= 250)
			SetHamParamFloat(4, damage * get_pcvar_float( cvar_dmgmultiplier[1] ) )
		else if(iColor[attacker] <= 500)
			SetHamParamFloat(4, damage * get_pcvar_float( cvar_dmgmultiplier[2] ) )	
		else if(iColor[attacker] <= 750)
			SetHamParamFloat(4, damage * get_pcvar_float( cvar_dmgmultiplier[3] ) )	
		iColor[attacker]++
		iNoise[attacker] += 0.025

	}
	return HAM_IGNORED
}
public fw_TakeDamagePost(victim, inflictor, attacker, Float:damage,bits)
{
     if(!is_user_connected(attacker))
	return HAM_IGNORED
     if( !is_user_alive(victim))
	return HAM_IGNORED	
     if(!zp_core_is_zombie(victim))
	return HAM_IGNORED;
     static Float:gTime, Float:cTime
     gTime = get_gametime()
     cTime = get_pcvar_float(cvar_cooldown)
     if(gTime - cTime >= pCooldown[attacker])
     {
	if (get_user_weapon(attacker) == CSW_MP5NAVY && g_HasAk[attacker]&&(bits&DMG_BULLET))
	{
		if(iColor[attacker] <= 100)
		{
			if(!zp_grenade_fire_get(victim))
				zp_grenade_fire_set(victim, true)
			set_task(1.5,"UnFire",victim+1000)
		}
		else if(iColor[attacker] <= 250)
		{
			if(!zp_grenade_frost_get(victim))
				zp_grenade_frost_set(victim, true)
			set_task(3.5,"UnFreeze",victim+2000)
		}
		else if(iColor[attacker] <= 500)
		{
			set_user_rendering(victim, 19,0,255,0,kRenderGlow,16)
			ScreenFade(victim, 1.0, 0, 0, 0,255)
			set_task(1.0,"UnBlind",victim+3000)
		}
		else if(iColor[attacker] <= 750)
		{
			if(!zp_grenade_fire_get(victim))
				zp_grenade_fire_set(victim, true)
			set_task(1.5,"UnFire",victim+1000)
			set_user_rendering(victim, 19,255,200,0,kRenderGlow,16)
			ScreenFade(victim, 1.5, 0, 0, 0,255)
			set_task(1.0,"UnBlind",victim+3000)
		}		
	}
	pCooldown[attacker] = gTime
    }
    return HAM_IGNORED;
}
public UnFire(id)
{
	new task_id = id - 1000
	if(is_user_alive(task_id))
	{
		if(zp_grenade_fire_get(task_id))
			zp_grenade_fire_set(task_id, false)		
	}
}
public UnFreeze(id)
{
	new task_id = id - 2000
	if(is_user_alive(task_id))
	{
		if(zp_grenade_frost_get(task_id))
			zp_grenade_frost_set(task_id, false)		
	}
}
public UnBlind(id)
{
	new task_id = id - 3000
	if(is_user_alive(task_id))
	{
		set_user_rendering(task_id)
	}
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

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_mp5.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName))
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn
	owner = pev(entity, pev_owner)
	wpn = find_ent_by_owner(-1, "weapon_mp5navy", entity)
	
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
	if(wpnid == CSW_MP5NAVY && g_HasAk[pevAttacker] )
	{
		if(iColor[pevAttacker] >= 750)
			iCombo[pevAttacker] = 0
		if(iCombo[pevAttacker] >= 199)
			iCombo[pevAttacker] = 50
		if(iNoise[pevAttacker] >= 50.0)
			iNoise[pevAttacker] = 0.0
		if(iColor[pevAttacker] <= 100)
		{
			iCol[pevAttacker][0] = 50 + iCombo[pevAttacker]
			iCol[pevAttacker][1] = 0
			iCol[pevAttacker][2] = 0
		}
		else
		if(iColor[pevAttacker] <= 250)
		{
			iCol[pevAttacker][2] = 50 + iCombo[pevAttacker]
			iCol[pevAttacker][0] = 0
			iCol[pevAttacker][1] = 0
		}
		else
		if(iColor[pevAttacker] <= 500)
		{
			iCol[pevAttacker][1] = 50 + iCombo[pevAttacker]
			iCol[pevAttacker][0] = 0
			iCol[pevAttacker][2] = 0
		}
		else
		if(iColor[pevAttacker] <= 750)
		{
			iCol[pevAttacker][0] = 50 + iCombo[pevAttacker]
			iCol[pevAttacker][1] = iCombo[pevAttacker]
			iCol[pevAttacker][2] = 0
		}
		else
		{
			iColor[pevAttacker] = 500
		}
		iCombo[pevAttacker]++
		new Nos = floatround(iNoise[pevAttacker])
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
			write_byte(Nos); // noise amplitude in 0.01's
			write_byte(iCol[pevAttacker][0]); // red
			write_byte(iCol[pevAttacker][1]); // green
			write_byte(iCol[pevAttacker][2]); // blue
			write_byte(255); // brightness
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
	
	if(zv_get_user_flags(id)&ZV_MAIN)
		return ZP_ITEM_AVAILABLE;

	static limit, alive, i
	alive = 0;

	for(i=1;i<33;i++)
		if(is_user_alive(i))
			alive++

	if(alive<=22)
		limit= 2
	else
		limit=3

	if(Purchases>=limit)
	{		
		zp_items_menu_text_add(fmt("[%d/%d] \r[VIP]",Purchases,limit))
		return ZP_ITEM_NOT_AVAILABLE
	}
	
	zp_items_menu_text_add(fmt("[%d/%d]",Purchases,limit))

	return ZP_ITEM_AVAILABLE
}

public zp_fw_items_select_post(player, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_itemid)
	return;
			
	Purchases++;
	drop_prim(player)
	give_item(player, "weapon_mp5navy")
	new weaponid = get_weaponid("weapon_mp5navy")
	ExecuteHamB(Ham_GiveAmmo, player, MAXBPAMMO[weaponid], AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
	zp_colored_print(player,"You bought a^3 Elemental MP5-Navy")
	g_HasAk[player] = true;
	//Bought[player]++;	
	engclient_cmd(player, "weapon_mp5navy");
	zp_set_damage_required(player,2*zp_get_damage_required(player));
}

public fw_Weapon_PrimaryAttack_Pre(entity)
{
	new id = pev(entity, pev_owner)
	new clip,ammo
	new wpnid = get_user_weapon(id,clip,ammo)
	
	if(!g_HasAk[id])
		return HAM_IGNORED
	if (wpnid != CSW_MP5NAVY)
		return HAM_IGNORED;	
	pev(id, pev_punchangle, cl_pushangle[id])
	return HAM_IGNORED;
}

public fw_Weapon_PrimaryAttack_Post(entity)
{
	new id = pev(entity, pev_owner)
	new clip,ammo
	new wpnid = get_user_weapon(id,clip,ammo)
	
	if(!g_HasAk[id])
		return HAM_IGNORED
	if (wpnid != CSW_MP5NAVY)
		return HAM_IGNORED;
	if(iColor[id] <= 765)
		return HAM_IGNORED;
	new Float: push[3]
	pev(id, pev_punchangle, push)
	xs_vec_sub(push, cl_pushangle[id], push)
	xs_vec_mul_scalar(push, 0.0, push)
	xs_vec_add(push, cl_pushangle[id], push)
	set_pev(id, pev_punchangle, push)
	return HAM_IGNORED;
}


public zp_fw_gamemodes_start()
{
	Purchases=0;
	/*for(new id=1;id<33;id++)
		Bought[id]=false;*/
}

public plugin_natives()
{
	register_native("has_golden_mp","native_has_mp", 1)
	register_native("give_golden_mp","native_give_mp", 1)
	register_native("drop_golden_mp","native_drop_mp",1);
}
public native_has_mp(id)
	return g_HasAk[id];
public native_drop_mp(id)
{
	g_HasAk[id]=false;
}
public native_give_mp(player)
{
	give_item(player, "weapon_mp5navy")
	new weaponid = get_weaponid("weapon_mp5navy")
	ExecuteHamB(Ham_GiveAmmo, player, MAXBPAMMO[weaponid], AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
	zp_colored_print(player,"You got^3 Elemental MP5-Navy")
	g_HasAk[player] = true;
}
public cmd_ak(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED

	new szArg[32], szTarget[32], idp
	read_argv(1, szArg, charsmax(szArg))

	new iPlayers[32], iPnum = cmd_targetex(id, szArg, iPlayers, szTarget, charsmax(szTarget), TARGETEX_OBEY_IMM_SINGLE, 0)

	if(!iPnum)
		return PLUGIN_HANDLED
	for(new i; i < iPnum; i++)
	{
		idp = iPlayers[i]
		native_give_mp(idp)
	}
	new szName[32]
	get_user_name(id, szName, charsmax(szName))
	zp_colored_print(0, "^1 %s ^3gave ^1%s ^3a ^4Elemental mp5", szName, szTarget)
	return PLUGIN_HANDLED	
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

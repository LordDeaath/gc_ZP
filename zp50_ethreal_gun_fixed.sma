#include <amxmodx>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <zp50_items>
#include <zp50_colorchat>
#include <zp50_fps>
#include <xs>
// #include <zmvip>
#include <zp50_gamemodes>
#include <zp50_class_survivor>

new HasEthereal[33]
//new Bought[33]

new Fire_snd[][] ={"weapons/ethereal_shoot1.wav","weapons/ethereal_draw.wav","weapons/ethereal_reload.wav","weapons/ethereal_idle1.wav"}

new ethereal_V_MODEL[]={"models/v_ethereal.mdl"}
new ethereal_P_MODEL[]={"models/p_ethereal.mdl"}
new ethereal_W_MODEL[]={"models/p_ethereal.mdl"}
new cvar_dmg_ethereal;
new g_itemid_ethereal//, g_itemid_vip;
new cvar_clip_ethereal;
new cvar_ethereal_ammo;
new g_orig_event_ethereal;
new g_clip_ammo[33];
new Float:cl_pushangle[33][3];
new m_iBlood[2];
new g_ethereal_TmpClip[33];
new g_beamSpr;
new g_IsInPrimaryAttack;
new Purchases;

public plugin_init()
{
	register_plugin("[ZP] Extra Item: Ethereal Gun", "1.0", "lambda");
	register_event("CurWeapon", "CurrentWeapon", "be", "1=1");
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	RegisterHam(Ham_Item_Deploy, "weapon_ump45", "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ump45", "fw_ethereal_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ump45", "fw_ethereal_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_ump45", "ethereal__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_ump45", "ethereal__Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_ump45", "ethereal__Reload_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "func_wall", "TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "func_breakable", "TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "func_door", "TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "info_target", "TraceAttack", 1);
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	
	register_forward(FM_SetModel, "fw_SetModel");	
	RegisterHam(Ham_Item_AddToPlayer, "weapon_ump45", "fw_AddToPlayer");
	
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent");
	cvar_dmg_ethereal = register_cvar("zp_Ethereal_dmg", "3.0");
	cvar_clip_ethereal = register_cvar("zp_Ethereal_clip", "40");
	cvar_ethereal_ammo = register_cvar("zp_Ethereal_ammo", "400");
	g_itemid_ethereal = zp_items_register("Ethereal Plasma Rifle", "",75);
	// g_itemid_vip = zv_register_extra_item("Ethereal Plasma", "10 Ammo Packs", 10, ZV_TEAM_HUMAN)
}

new Infection, Multi;
public plugin_cfg()
{
	Infection = zp_gamemodes_get_id("Infection Mode");
	Multi = zp_gamemodes_get_id("Multiple Infection Mode");
}

public plugin_precache()
{
	precache_model(ethereal_V_MODEL);
	precache_model(ethereal_P_MODEL);
	precache_model(ethereal_W_MODEL);
	for(new i;i<sizeof(Fire_snd);i++)
	{
		precache_sound(Fire_snd[i]);
	}
	m_iBlood[0] = precache_model("sprites/blood.spr");
	m_iBlood[1] = precache_model("sprites/bloodspray.spr");
	g_beamSpr = precache_model("sprites/zbeam4.spr");
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1);
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/ump45.sc", name,0))
	{
		g_orig_event_ethereal = get_orig_retval();
		return FMRES_HANDLED;
	}
	return FMRES_IGNORED;
}

public plugin_natives()
{
	register_native("clear_plasma", "native_clear_plasma", 1);
	register_native("zp_ethereal_get","native_ethereal_get",1);
}

public native_ethereal_get(id)
{
	return HasEthereal[id];
}
public native_clear_plasma(id)
{
	HasEthereal[id]=false
}


public client_connect(id)
{
	HasEthereal[id]=false;
}

public client_disconnected(id)
{
	HasEthereal[id]=false
}

public zp_fw_core_infect_post(id)
{
	HasEthereal[id]=false
}

public event_round_start()
{
	Purchases=0;
	for(new id=1;id<33;id++)
	{		
		HasEthereal[id]=false
	}
}
public zp_fw_items_select_pre(id, itemid)
{
	if (g_itemid_ethereal != itemid)
	{
		return ZP_ITEM_AVAILABLE
	}
	
	if (zp_core_is_zombie(id))
	{
		return ZP_ITEM_DONT_SHOW
	}

	if(zp_class_survivor_get(id))
	{
		return ZP_ITEM_DONT_SHOW;
	}

	if (HasEthereal[id])
	{
		return ZP_ITEM_NOT_AVAILABLE;
	}

	static limit, alive, i
	alive = 0;

	for(i=1;i<33;i++)
	{
		if(is_user_alive(i))
		{
			alive++
		}
	}

	if(zp_gamemodes_get_current()!=Infection&&zp_gamemodes_get_current()!=Multi)
	{		
		if(alive<23)
		{
			limit=1
		}
		else
		{
			limit=2
		}
	}
	else
	{	
		if(alive<23)
		{
			limit=2
		}
		else
		{
			limit=3
		}
	}

	zp_items_menu_text_add(fmt("[%d/%d]",Purchases,limit))

	if(Purchases>=limit)
		return ZP_ITEM_NOT_AVAILABLE
	
	return ZP_ITEM_AVAILABLE
}

public zp_fw_items_select_post(player, itemid)
{
	if (g_itemid_ethereal == itemid)
	{
		Purchases++;
		//Bought[player]++
		zp_colored_print(player, "You bought an^3 Ethereal Plasma")
		give_ethereal(player);
	}
}

// public zv_extra_item_selected(player, itemid)
// {
// 	if(itemid==g_itemid_vip)
// 	{
// 		//Bought[player]++
// 		zp_colored_print(player, "You bought an^3 Ethereal Plasma")
// 		give_ethereal(player);
// 	}
// }
public give_ethereal(id)
{
	engclient_cmd(id, "drop", "weapon_ump45")	
	HasEthereal[id]=true;
	new iWep2 = give_item(id, "weapon_ump45");
	cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_ethereal));
	cs_set_user_bpammo(id, CSW_UMP45, get_pcvar_num(cvar_ethereal_ammo))	
	engclient_cmd(id, "weapon_ump45")
}

public OnItemSlotPrimary(item)
{
	static owner;
	owner = fm_cs_get_weapon_ent_owner(item);
	if (!HasEthereal[owner])
	{
		return 1;
	}
	SetHamReturnInteger(5);
	return 4;
}

public fw_Item_Deploy_Post(weapon_ent)
{
	static owner;
	owner = fm_cs_get_weapon_ent_owner(weapon_ent);
	static weaponid;
	weaponid = cs_get_weapon_id(weapon_ent);
	replace_weapon_models(owner, weaponid);
	UTIL_PlayWeaponAnimation(owner, 2)
}

public CurrentWeapon(id)
{
	replace_weapon_models(id, read_data(2));
	return 0;
}

replace_weapon_models(id, weaponid)
{
	if (!HasEthereal[id])
	{
		return 0;
	}
	switch (weaponid)
	{
		case 12:
		{
			set_pev(id, pev_viewmodel2, ethereal_V_MODEL);
			set_pev(id, pev_weaponmodel2, ethereal_P_MODEL);
		}
		default:
		{
		}
	}
	return 0;
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if (is_user_alive(Player)&& get_user_weapon(Player) == CSW_UMP45&& HasEthereal[Player])
	{		
		set_cd(CD_Handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_ethereal_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4);
	if (!HasEthereal[Player])
	{
		return ;
	}
	pev(Player, pev_punchangle, cl_pushangle[Player]);
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon);	
	g_IsInPrimaryAttack = 1;
}

public fw_ethereal_PrimaryAttack_Post(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4);
	if (!HasEthereal[Player])
	{
		return;
	}	
	if (!g_clip_ammo[Player])
	{
		return ;
	}
		
	g_IsInPrimaryAttack = 0;
	new Float:push[3];
	pev(Player, pev_punchangle, push);
	xs_vec_sub(push, cl_pushangle[Player], push);
	xs_vec_mul_scalar(push, 0.60, push);
	xs_vec_add(push, cl_pushangle[Player], push);
	set_pev(Player, pev_punchangle, push);	
	emit_sound(Player, CHAN_WEAPON, Fire_snd[0], 1.00, 0.80, 0, 100);
	UTIL_PlayWeaponAnimation(Player, 5);
	//make_blood_and_bulletholes(Player);
	
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (g_orig_event_ethereal != eventid||!g_IsInPrimaryAttack)
	{		
		return FMRES_IGNORED;
	}
	
	if (!(1 <= invoker <= get_maxplayers()))
		return FMRES_IGNORED;
		
	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2);
	return FMRES_SUPERCEDE;
}

public TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if (!is_user_alive(iAttacker) || !HasEthereal[iAttacker])
	{
		return 0;
	}
	new iWeapon = get_user_weapon(iAttacker);
	if (iWeapon != CSW_UMP45)
	{
		return 0;
	}
	new szClip = 0;
	get_user_weapon(iAttacker, szClip);
	if (szClip < 1)
	{
		return 0;
	}
	new flEnd[3];
	get_tr2(ptr, TR_vecEndPos, flEnd);
	for(new i = 1;i < 33; i++)
	{
		if(!is_user_connected(i))
			continue;
		
		if (zp_fps_get_user_flags(i) & FPS_SPRITES)
			continue;
			
		message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,{0,0,0},i)
		write_byte(1);
		write_short(iAttacker | 4096);
		engfunc(EngFunc_WriteCoord, flEnd);
		engfunc(EngFunc_WriteCoord, flEnd[1]);
		engfunc(EngFunc_WriteCoord, flEnd[2]);
		write_short(g_beamSpr);
		write_byte(0);
		write_byte(0);
		write_byte(1);
		write_byte(5);
		write_byte(0);
		write_byte(0);
		write_byte(0);
		write_byte(255);
		write_byte(255);
		write_byte(200);
		message_end();		
	}
	
	new target = get_tr2(ptr, TR_pHit)
	if(is_user_connected(target)&&zp_core_is_zombie(target))
	{		
		for(new i=1;i<33;i++)
		{
			if(!is_user_connected(i))
				continue
			
			if(zp_fps_get_user_flags(i)&FPS_BLOOD)
				continue;	
				
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY,{0,0,0},i)
			write_byte(TE_BLOODSPRITE)
			engfunc(EngFunc_WriteCoord, flEnd[0]);
			engfunc(EngFunc_WriteCoord, flEnd[1]);
			engfunc(EngFunc_WriteCoord, flEnd[2]);
			write_short(m_iBlood[1])
			write_short(m_iBlood[0])
			write_byte(70)
			write_byte(random_num(1, 2))
			message_end()
		}
	}
	else
	{
		for(new i=1;i<33;i++)
		{
			if(!is_user_connected(i))
				continue;
			
			if (!(zp_fps_get_user_flags(i) & FPS_SPRITES))
				continue;
				
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY,{0,0,0},i)
			write_byte(TE_SPARKS);
			engfunc(EngFunc_WriteCoord, flEnd[0]-2);
			engfunc(EngFunc_WriteCoord, flEnd[1]);
			engfunc(EngFunc_WriteCoord, flEnd[2]);
			message_end();
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY,{0,0,0},i)
			write_byte(TE_SPARKS);
			engfunc(EngFunc_WriteCoord, flEnd[0]);
			engfunc(EngFunc_WriteCoord, flEnd[1]+2);
			engfunc(EngFunc_WriteCoord, flEnd[2]);
			message_end();
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY,{0,0,0},i)
			write_byte(TE_SPARKS);
			engfunc(EngFunc_WriteCoord, flEnd[0]);
			engfunc(EngFunc_WriteCoord, flEnd[1]-2);
			engfunc(EngFunc_WriteCoord, flEnd[2]);
			message_end();
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY,{0,0,0},i)
			write_byte(TE_SPARKS);
			engfunc(EngFunc_WriteCoord, flEnd[0]+2);
			engfunc(EngFunc_WriteCoord, flEnd[1]);
			engfunc(EngFunc_WriteCoord, flEnd[2]);
			message_end();
		}		
	}
	return 0;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, bits)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED;
		
	if(attacker==victim)
		return HAM_IGNORED;
	
	if(!HasEthereal[attacker])
		return HAM_IGNORED;
	
	if(get_user_weapon(attacker)!=CSW_UMP45)
		return HAM_IGNORED;
	
	if(!(bits&DMG_BULLET))
		return HAM_IGNORED;

	SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_ethereal));
		
	return HAM_IGNORED;
}

public ethereal__ItemPostFrame(weapon_entity)
{
	new id = pev(weapon_entity,pev_owner);
	if (!is_user_connected(id) || !HasEthereal[id])
	{
		return 1;
	}
	
	new Float:flNextAttack = get_pdata_float(id, 83, 5);

	new iBpAmmo = cs_get_user_bpammo(id, CSW_UMP45);
	new iClip = get_pdata_int(weapon_entity, 51, 4);

	new fInReload = get_pdata_int(weapon_entity, 54, 4);
	if (fInReload && flNextAttack <= 0.00)
	{
		new j = min(get_pcvar_num(cvar_clip_ethereal) - iClip, iBpAmmo);
		set_pdata_int(weapon_entity, 51, j + iClip, 4);
		cs_set_user_bpammo(id, CSW_UMP45, iBpAmmo - j);
		set_pdata_int(weapon_entity, 54, 0, 4);
		fInReload = 0;
	}
	return 1;
}

public ethereal__Reload(weapon_entity)
{
	new id = pev(weapon_entity,pev_owner);
	if (!is_user_connected(id) || !HasEthereal[id])
	{
		return 1;
	}
	g_ethereal_TmpClip[id] = -1;
	new iBpAmmo = cs_get_user_bpammo(id, CSW_UMP45);
	new iClip = get_pdata_int(weapon_entity, 51, 4);
	if (0 >= iBpAmmo)
	{
		return 4;
	}
	if (get_pcvar_num(cvar_clip_ethereal) <= iClip)
	{
		return 4;
	}
	UTIL_PlayWeaponAnimation(id, 1)
	g_ethereal_TmpClip[id] = iClip;
	return 1;
}

public ethereal__Reload_Post(weapon_entity)
{
	new id = pev(weapon_entity,pev_owner);
	if (!is_user_connected(id) ||!HasEthereal[id])
	{
		return 1;
	}
	if (g_ethereal_TmpClip[id] == -1)
	{
		return 1;
	}
	set_pdata_int(weapon_entity, 51, g_ethereal_TmpClip[id], 4);
	set_pdata_float(weapon_entity, 48, 3.0, 4);
	set_pdata_float(id, 83, 3.0, 5);
	set_pdata_int(weapon_entity, 54, 1, 4);
	UTIL_PlayWeaponAnimation(id, 1)
	return 1;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_ump45.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName))
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn
	owner = pev(entity, pev_owner)
	wpn = find_ent_by_owner(-1, "weapon_ump45", entity)
	
	if(HasEthereal[owner] && pev_valid(wpn))
	{
		HasEthereal[owner] = false;
		set_pev(wpn, pev_impulse, 12324);	
		engfunc(EngFunc_SetModel, entity, ethereal_W_MODEL);		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_AddToPlayer(wpn, id)
{
	if(pev_valid(wpn) && is_user_connected(id) && pev(wpn, pev_impulse) == 12324)
	{
		HasEthereal[id] = true;
		set_pev(wpn, pev_impulse, 0);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}
fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, 41, 4);
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(2)
	message_end()
}

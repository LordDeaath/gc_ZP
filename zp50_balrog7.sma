#include <amxmodx>
#include <fun>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zp50_items>
#include <zp50_colorchat>
#include <zmvip>
#include <xs>
#include <zp50_class_survivor>

#define WEAPON_BITSUM ((1<<CSW_M249))

new HasBalrog7[33];

new g_hasZoom[ 33 ]
new GUNSHOT_DECALS[5] =
{
	41, 42, 43, 44, 45
}
new Fire_Sounds[][]=
{
	"weapons/balrog7.wav","weapons/balrog7_clipin3.wav","weapons/balrog7_clipin2.wav","weapons/balrog7_clipin1.wav","weapons/balrog7_clipout2.wav","weapons/balrog7_clipout1.wav"
};
new balrog7_V_MODEL[] ={"models/v_balrog7.mdl"}
new balrog7_P_MODEL[] ={"models/p_balrog7.mdl"}
new balrog7_W_MODEL[] ={"models/w_balrog7.mdl"}

new cvar_dmg_balrog7, cvar_dmg_balrog7_normal;
new cvar_recoil_balrog7;
new g_itemid_balrog7,g_itemid_vip;
new cvar_clip_balrog7;
new cvar_spd_balrog7;
new cvar_balrog7_ammo;
new g_MaxPlayers;
new g_orig_event_balrog7;
new g_IsInPrimaryAttack;
new Float:cl_pushangle[33][3];
new m_iBlood[2];
new g_clip_ammo[33];
new oldweap[33];
new g_balrog7_TmpClip[33];

public plugin_init()
{
	register_plugin("[ZP] Extra Item: Balrog-7", "1.0", "lambda");
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	register_event("DeathMsg", "Death", "a");
	RegisterHam(Ham_Item_Deploy, "weapon_m249", "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_balrog7_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_balrog7_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_m249", "balrog7_ItemPostFrame");
	
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "balrog7_Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "balrog7_Reload_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	register_forward( FM_CmdStart, "fw_CmdStart" )
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent");
	
	register_forward(FM_SetModel, "fw_SetModel");	
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m249", "fw_AddToPlayer");
	
	
	cvar_dmg_balrog7 = register_cvar("zp_balrog7_dmg_hs", "2.0");
	cvar_dmg_balrog7_normal = register_cvar("zp_balrog7_dmg", "2.0");
	cvar_recoil_balrog7 = register_cvar("zp_balrog7_recoil", "0.85");
	cvar_clip_balrog7 = register_cvar("zp_balrog7_clip", "120");
	cvar_spd_balrog7 = register_cvar("zp_balrog7_shot_speed", "0.115");
	cvar_balrog7_ammo = register_cvar("zp_balrog7_ammo", "240");
	g_itemid_balrog7 = zp_items_register("Balrog-7 (2x Damage)", "",40);
	//g_itemid_vip = zv_register_extra_item("Balrog-VII Machine Gun", "FREE",0,ZV_TEAM_HUMAN);
	g_MaxPlayers = get_maxplayers();
}

public plugin_natives()
{
	register_native("zp_balrog7_get","native_balrog7_get",1)
}

public native_balrog7_get(id)
{
	return HasBalrog7[id]
}
public plugin_precache()
{
	precache_sound("weapons/zoom.wav")
	precache_model(balrog7_V_MODEL);
	precache_model(balrog7_P_MODEL);
	precache_model(balrog7_W_MODEL);
	for(new i;i<sizeof(Fire_Sounds);i++)
	{
		precache_sound(Fire_Sounds[i]);
	}
	m_iBlood[0] = precache_model("sprites/blood.spr");
	m_iBlood[1] = precache_model("sprites/bloodspray.spr");
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1);
}

public fwPrecacheEvent_Post(type,  const name[])
{
	if (equal("events/m249.sc", name, 0))
	{
		g_orig_event_balrog7 = get_orig_retval();
		return FMRES_HANDLED;
	}
	return FMRES_IGNORED;
}

public event_round_start()
{
		for (new i = 1; i <= get_maxplayers(); i++) HasBalrog7[i]=false;
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if (is_user_alive(Player)&&get_user_weapon(Player) == CSW_M249&&HasBalrog7[Player])
	{
		set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001);
	}
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (g_orig_event_balrog7 != eventid || !g_IsInPrimaryAttack)
	{
		return FMRES_IGNORED;
	}
	
	if (!(1 <= invoker <= get_maxplayers()))
		return FMRES_IGNORED;
		
	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2);
	return FMRES_SUPERCEDE;
}

public client_connect(id)
{
	HasBalrog7[id]=false;
}

public client_disconnecteded(id)
{
	HasBalrog7[id]=false;
}

public zp_fw_core_infect_post(id)
{
	HasBalrog7[id]=false;
}

public Death()
{
	HasBalrog7[read_data(2)]=false;
}

public zp_fw_items_select_pre(id, itemid)
{
	if (g_itemid_balrog7 != itemid)
	{
		return ZP_ITEM_AVAILABLE;
	}
	if (zp_core_is_zombie(id))
	{
		return ZP_ITEM_DONT_SHOW;
	}
	if(zp_class_survivor_get(id))
		return ZP_ITEM_DONT_SHOW
	if (HasBalrog7[id])
	{
		return ZP_ITEM_NOT_AVAILABLE;
	}
	return ZP_ITEM_AVAILABLE
}

public zp_fw_items_select_post(player, itemid)
{	
	if (g_itemid_balrog7 == itemid)
	{
		HasBalrog7[player]=true;
		give_balrog7(player);
		zp_colored_print(player, "You bought a^3 Balrog-VII Machine Gun");
	}
}
/*
public zv_extra_item_selected(player, itemid)
{	
	if (g_itemid_vip == itemid)
	{
		HasBalrog7[player]=true;
		give_balrog7(player);
		zp_colored_print(player, "You bought a^3 Balrog-VII Machine Gun");
	}
}
*/
public give_balrog7(player)
{	
	if(user_has_weapon(player, CSW_M249))
	{
		drop_primary(player);
	}
	HasBalrog7[player] = true;
	new weaponid = give_item(player, "weapon_m249");
	cs_set_weapon_ammo(weaponid,  get_pcvar_num(cvar_clip_balrog7));
	cs_set_user_bpammo(player, CSW_M249, get_pcvar_num(cvar_balrog7_ammo));
	engclient_cmd(player, "weapon_m249");
	UTIL_PlayWeaponAnimation(player, 4);
	set_pdata_float(player, 83, 1.00, 5);
}

stock drop_primary(id)
{
	new weapons[32], num;
	get_user_weapons(id, weapons, num);
	for (new i = 0; i < num; i++)
	{
		if (WEAPON_BITSUM & (1<<weapons[i]))
		{
			static wname[32];
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname);
		}
	}
}


public fw_Item_Deploy_Post(weapon_ent)
{
	static owner;
	owner = fm_cs_get_weapon_ent_owner(weapon_ent);
	static weaponid;
	weaponid = cs_get_weapon_id(weapon_ent);
	replace_weapon_models(owner, weaponid);
	return 0;
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_M249:
		{
			if (!HasBalrog7[id])
			{
				return;
			}
			set_pev(id, pev_viewmodel2, balrog7_V_MODEL);
			set_pev(id, pev_weaponmodel2, balrog7_P_MODEL);
			if (oldweap[id]!= CSW_M249)
			{
				UTIL_PlayWeaponAnimation(id, 4);
				set_pdata_float(id, 83, 1.00, 5);
			}
		}
		default:
		{
		}
	}
	oldweap[id] = weaponid;
}

public fw_balrog7_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4);
	if (HasBalrog7[Player])
	{		
		g_IsInPrimaryAttack = 1;
		pev(Player, pev_punchangle, cl_pushangle[Player]);
		g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon);
	}
}

public fw_balrog7_PrimaryAttack_Post(Weapon)
{	
	new Player= get_pdata_cbase(Weapon, 41, 4);
	if(HasBalrog7[Player]&&g_clip_ammo[Player])
	{		
		g_IsInPrimaryAttack = 0;
		set_pdata_float(Weapon, 46, get_pcvar_float(cvar_spd_balrog7), 4);
		new Float:push[3];
		pev(Player, pev_punchangle, push);
		xs_vec_sub(push, cl_pushangle[Player], push);
		xs_vec_mul_scalar(push, get_pcvar_float(cvar_recoil_balrog7), push);
		xs_vec_add(push, cl_pushangle[Player], push);
		set_pev(Player, pev_punchangle, push);
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], 1.00, 0.80, 0, 100);
		UTIL_PlayWeaponAnimation(Player, random_num(1, 2));
		make_blood_and_bulletholes(Player);
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
		
		if( szWeapID == CSW_M249 && HasBalrog7[id])
		{
			if(g_hasZoom[id])
			{
				g_hasZoom[ id ] = false
				cs_set_user_zoom( id, CS_RESET_ZOOM, 0 )
			}
			else
			{
				g_hasZoom[id] = true
				cs_set_user_zoom( id, CS_SET_AUGSG552_ZOOM, 0 )
				emit_sound( id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100 )
			}
		}		
	}
	return PLUGIN_HANDLED
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage,bits)
{
	const m_LastHitGroup = 75;
	if(is_user_alive(attacker)&&get_user_weapon(attacker)==CSW_M249&&HasBalrog7[attacker] && (bits&DMG_BULLET))
	{
		if (get_pdata_int( victim , m_LastHitGroup ) == HIT_HEAD)
			SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_balrog7));
		else
			SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_balrog7) * get_pcvar_float(cvar_dmg_balrog7_normal));
	}
	return HAM_IGNORED;
}

public balrog7_ItemPostFrame(weapon_entity)
{
	
	new id = pev(weapon_entity, pev_owner);
	if (!is_user_connected(id) || !HasBalrog7[id])
	{
		return FMRES_IGNORED;
	}
	
	static iClipExtra; iClipExtra = get_pcvar_num(cvar_clip_balrog7);

	new Float:flNextAttack = get_pdata_float(id, 83, 5);

	new iBpAmmo = cs_get_user_bpammo(id, CSW_M249);
	new iClip = get_pdata_int(weapon_entity, 51, 4);

	new fInReload = get_pdata_int(weapon_entity, 54, 4);
	
	if (fInReload && flNextAttack <= 0.00)
	{
		new j = min(iClipExtra - iClip, iBpAmmo);
		set_pdata_int(weapon_entity, 51, j + iClip, 4);
		cs_set_user_bpammo(id, CSW_M249, iBpAmmo - j);
		set_pdata_int(weapon_entity, 54, 0, 4);
		fInReload = 0;
	}
	return FMRES_IGNORED;
}

public balrog7_Reload(weapon_entity)
{
	new id = pev(weapon_entity,pev_owner);
	if (!is_user_connected(id) || !HasBalrog7[id])
	{
		return 1;
	}
	g_balrog7_TmpClip[id] = -1;
	new iBpAmmo = cs_get_user_bpammo(id, CSW_M249);
	new iClip = get_pdata_int(weapon_entity, 51, 4);
	if (0 >= iBpAmmo)
	{
		return 4;
	}
	if (get_pcvar_num(cvar_clip_balrog7) <= iClip)
	{
		return 4;
	}
	UTIL_PlayWeaponAnimation(id, 3)
	g_balrog7_TmpClip[id] = iClip;
	return 1;
}

public balrog7_Reload_Post(weapon_entity)
{
	new id = pev(weapon_entity,pev_owner);
	if (!is_user_connected(id) ||!HasBalrog7[id])
	{
		return 1;
	}
	if (g_balrog7_TmpClip[id] == -1)
	{
		return 1;
	}
	set_pdata_int(weapon_entity, 51, g_balrog7_TmpClip[id], 4);
	set_pdata_float(weapon_entity, 48, 4.0, 4);
	set_pdata_float(id, 83, 4.0, 5);
	set_pdata_int(weapon_entity, 54, 1, 4);
	UTIL_PlayWeaponAnimation(id, 3)
	return 1;
}


public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_m249.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName))
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn
	owner = pev(entity, pev_owner)
	wpn = find_ent_by_owner(-1, "weapon_m249", entity)
	
	if(HasBalrog7[owner] && pev_valid(wpn))
	{
		HasBalrog7[owner] = false;
		set_pev(wpn, pev_impulse, 42324);			
		engfunc(EngFunc_SetModel, entity, balrog7_W_MODEL);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_AddToPlayer(wpn, id)
{
	if(pev_valid(wpn) && is_user_connected(id) && pev(wpn, pev_impulse) == 42324)
	{
		HasBalrog7[id] = true;
		set_pev(wpn, pev_impulse, 0);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}
stock make_blood_and_bulletholes(id)
{
	new aimOrigin[3], target, body
	get_user_origin(id, aimOrigin, 3)
	get_user_aiming(id, target, body)
	if(target > 0 && target <= g_MaxPlayers && HasBalrog7[id])
	{
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3]
		pev(id, pev_origin, fStart)
		velocity_by_aim(id, 64, fVel)
		fStart[0] = float(aimOrigin[0])
		fStart[1] = float(aimOrigin[1])
		fStart[2] = float(aimOrigin[2])
		fEnd[0] = fStart[0]+fVel[0]
		fEnd[1] = fStart[1]+fVel[1]
		fEnd[2] = fStart[2]+fVel[2]
		new res
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res)
		get_tr2(res, TR_vecEndPos, fRes)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(fStart[0]))
		write_coord(floatround(fStart[1]))
		write_coord(floatround(fStart[2]))
		write_short(m_iBlood[1])
		write_short(m_iBlood[0])
		write_byte(70)
		write_byte(random_num(1, 2))
		message_end()
	}
	else if(!is_user_connected(target))
	{
		if(target)
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DECAL)
			write_coord(aimOrigin[0])
			write_coord(aimOrigin[1])
			write_coord(aimOrigin[2])
			write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
			write_short(target)
			message_end()
		}
		else
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_WORLDDECAL)
			write_coord(aimOrigin[0])
			write_coord(aimOrigin[1])
			write_coord(aimOrigin[2])
			write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
			message_end()
		}
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord(aimOrigin[0])
		write_coord(aimOrigin[1])
		write_coord(aimOrigin[2])
		write_short(id)
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		message_end()
		message_begin(MSG_ALL, SVC_TEMPENTITY)
		write_byte(TE_SPARKS);
		write_coord(aimOrigin[0]);
		write_coord(aimOrigin[1]);
		write_coord(aimOrigin[2]);
		message_end();
		message_begin(MSG_ALL, SVC_TEMPENTITY)
		write_byte(TE_SPARKS);
		write_coord(aimOrigin[0] + 2);
		write_coord(aimOrigin[1]);
		write_coord(aimOrigin[2]);
		message_end();
		message_begin(MSG_ALL, SVC_TEMPENTITY)
		write_byte(TE_SPARKS);
		write_coord(aimOrigin[0]);
		write_coord(aimOrigin[1] + 2);
		write_coord(aimOrigin[2]);
		message_end();
		message_begin(MSG_ALL, SVC_TEMPENTITY)
		write_byte(TE_SPARKS);
		write_coord(aimOrigin[0]);
		write_coord(aimOrigin[1]);
		write_coord(aimOrigin[2] + 2);
		message_end();
	}
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
	write_byte(pev(Player, pev_body))
	message_end()
}

#include < amxmodx >
#include < amxmisc >
#define Frost

#include <fun>
#include < engine >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >
#include < zp50_items >
#include < zmvip >
#include <zp50_colorchat>
#include <zp50_gamemodes>
#include <zp50_class_survivor>

#if defined Frost
#include <zp50_grenade_frost>
#include <zp50_fps>
#endif

#define ITEM_NAME "Violingun"
#define ITEM_COST 35

#define WEAPON_BITSUM ((1<<CSW_GALIL))


new const VERSION[] = "1.3";

new g_clipammo[33], g_has_violingun[33], g_itemid,g_itemid_vip, g_hamczbots, g_event_violingun, g_primaryattack, cvar_violingun_damage_x, cvar_violingun_bpammo, cvar_violingun_shotspd, cvar_violingun_oneround, cvar_violingun_clip, cvar_botquota;

new const SHOT_SOUND[][] = {"weapons/violingun_shoot1.wav", "weapons/violingun_shoot2.wav"}

new const VIOLIN_SOUNDS[][] = {"weapons/violingun_idle2.wav", "weapons/violingun_draw.wav", "weapons/violingun_clipout.wav", "weapons/violingun_clipin.wav"}

#if defined Frost
#else
new const GUNSHOT_DECALS[] = {41, 42, 43, 44, 45}
#endif

#if defined Frost
new const V_VIOLIN_MDL[64] = "models/zombie_plague/v_violingun_frost.mdl";
new const P_VIOLIN_MDL[64] = "models/zombie_plague/p_violingun_frost.mdl";
new const W_VIOLIN_MDL[64] = "models/zombie_plague/w_violingun_frost.mdl";
#else
new const V_VIOLIN_MDL[64] = "models/zombie_plague/v_violingun_fixed.mdl";
new const P_VIOLIN_MDL[64] = "models/zombie_plague/p_violingun.mdl";
new const W_VIOLIN_MDL[64] = "models/zombie_plague/w_violingun.mdl";
#endif

new g_TmpClip[33]

native drop_guitar(id);
native zp_class_hunter_get(id);

new Purchases;

//Frost Crap
#if defined Frost
new g_laser_sprite, g_balrog_exp,cvar_balrog_freeze_time,cvar_balrog_freeze_req;
new Random_Chance[33]
#endif
public plugin_init()
{
	// Plugin Register
	register_plugin("[ZP:50] Extra Item: Violingun", VERSION, "CrazY");

	// Extra Item Register
	g_itemid = zp_items_register(ITEM_NAME,"", ITEM_COST);	
	g_itemid_vip = zv_register_extra_item("Frost Violin", "10 Ammo Packs",10,ZV_TEAM_HUMAN);
	// Cvars Register
	cvar_violingun_damage_x = register_cvar("zp_violingun_damage_x", "3.0");
	cvar_violingun_clip = register_cvar("zp_violingun_clip", "40");
	cvar_violingun_bpammo = register_cvar("zp_violingun_bpammo", "200");
	cvar_violingun_shotspd = register_cvar("zp_violingun_shot_speed", "0.12");
	cvar_violingun_oneround = register_cvar("zp_violingun_oneround", "0");

	// Cvar Pointer
	cvar_botquota = get_cvar_pointer("bot_quota");
	
	// Events
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");

	// Forwards
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent");
	register_forward(FM_SetModel, "fw_SetModel");

	RegisterHam(Ham_Weapon_Reload, "weapon_galil", "fw_Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_galil", "fw_Reload_Post", 1);
	
	// HAM Forwards
	RegisterHam(Ham_Item_PostFrame, "weapon_galil", "fw_ItemPostFrame");
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "info_target", "fw_TraceAttack", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_galil", "fw_ItemDeploy_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_Item_AddToPlayer, "weapon_galil", "fw_AddToPlayer");
	
	#if defined Frost
	cvar_balrog_freeze_time = register_cvar( "zp_balrog_freeze_time" , "1.0")
	cvar_balrog_freeze_req = register_cvar ("zp_balrog_freeze_req","15");
	#endif
}

new Infection, Multi, MyAkLimit;
public plugin_cfg()
{
	Infection = zp_gamemodes_get_id("Infection Mode");
	Multi = zp_gamemodes_get_id("Multiple Infectin Mode");
}

public plugin_natives()
{
	register_native("drop_violin","native_drop_violin",1)
	register_native("give_balrog_frost", "command_give_violingun",1);
	register_native("zp_violingun_get","native_violingun_get",1);
}
public native_violingun_get(id)
{
	return g_has_violingun[id]
}
public native_drop_violin(id)
{
	g_has_violingun[id]=false;
}
public plugin_precache()
{
	precache_model(V_VIOLIN_MDL);
	precache_model(P_VIOLIN_MDL);
	precache_model(W_VIOLIN_MDL);
	for(new i = 0; i < sizeof SHOT_SOUND; i++) precache_sound(SHOT_SOUND[i]);
	for(new i = 0; i < sizeof VIOLIN_SOUNDS; i++) precache_sound(VIOLIN_SOUNDS[i]);
	
	#if defined Frost
	g_laser_sprite = precache_model("sprites/laserbeam.spr");
	g_balrog_exp = precache_model("sprites/zombie_plague/violin_frost_exp.spr");
	#endif
}

public client_disconnecteded(id)
{
	g_has_violingun[id] = false;
}

public client_connect(id)
{
	g_has_violingun[id] = false;
}

public zp_fw_core_infect_post(id)
{
	g_has_violingun[id] = false;
}

public zp_fw_core_cure_post(id)
{
	if (get_pcvar_num(cvar_violingun_oneround))
	g_has_violingun[id] = false;
}

public client_putinserver(id)
{
	g_has_violingun[id] = false;

	if (is_user_bot(id) && !g_hamczbots && cvar_botquota)
	{
		set_task(0.1, "register_ham_czbots", id);
	}
}

public event_round_start()
{
	Purchases=0;
	if (get_pcvar_num(cvar_violingun_oneround))
		for (new i = 1; i <= get_maxplayers(); i++) g_has_violingun[i] = false;
}

public register_ham_czbots(id)
{
	if (g_hamczbots || !is_user_bot(id) || !get_pcvar_num(cvar_botquota))
		return;

	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage");
	g_hamczbots = true;
}

public zp_fw_items_select_pre(id, itemid)
{
	if(itemid != g_itemid) return ZP_ITEM_AVAILABLE;
	
	if(zp_core_is_zombie(id)) return ZP_ITEM_DONT_SHOW;
	if(zp_class_survivor_get(id)) return ZP_ITEM_DONT_SHOW;
	
	if(g_has_violingun[id])
	{
		return ZP_ITEM_NOT_AVAILABLE;
	}
	
	if(AlivCount() >= 22)
		MyAkLimit = 3
	else MyAkLimit = 2
	new Txt[32]
	format(Txt,charsmax(Txt),"[%d/%d]",Purchases,MyAkLimit)
	zp_items_menu_text_add(Txt)

	
	if(zp_gamemodes_get_current()!=Infection&&zp_gamemodes_get_current()!=Multi)
		MyAkLimit = 2
		
	if(Purchases>=MyAkLimit)
		return ZP_ITEM_NOT_AVAILABLE

	
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(player, itemid)
{
	if(itemid != g_itemid)
		return;
	
	Purchases++;
	command_give_violingun(player);
	zp_colored_print(player, "You bought a^3 Frost Violin");
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
public command_give_violingun(player)
{	
	drop_guitar(player);
	if(user_has_weapon(player, CSW_GALIL))
	{
		drop_primary(player)
	}
	g_has_violingun[player] = true;
	new weaponid = give_item(player, "weapon_galil");
	emit_sound(player, CHAN_STREAM, VIOLIN_SOUNDS[0], 1.00, 0.80, 0, 100);
	cs_set_weapon_ammo(weaponid, get_pcvar_num(cvar_violingun_clip));
	cs_set_user_bpammo(player, CSW_GALIL, get_pcvar_num(cvar_violingun_bpammo));
	engclient_cmd(player, "weapon_galil");
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if (is_user_alive(id) && get_user_weapon(id) == CSW_GALIL && g_has_violingun[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time () + 0.001);
	}
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if (equal("events/galil.sc", name))
	{
		g_event_violingun = get_orig_retval()
		return FMRES_HANDLED;
	}
	return FMRES_IGNORED;
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_event_violingun) || !g_primaryattack)
		return FMRES_IGNORED;

	if (!(1 <= invoker <= get_maxplayers()))
    	return FMRES_IGNORED;

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2);
	return FMRES_SUPERCEDE;
}

public fw_Reload(weapon_entity)
{
	new id = pev(weapon_entity,pev_owner);
	if (!is_user_connected(id) || !g_has_violingun[id])
	{
		return 1;
	}
	g_TmpClip[id] = -1;
	new iBpAmmo = cs_get_user_bpammo(id, CSW_GALIL);
	new iClip = get_pdata_int(weapon_entity, 51, 4);
	if (0 >= iBpAmmo)
	{
		return 4;
	}
	if (get_pcvar_num(cvar_violingun_clip) <= iClip)
	{
		return 4;
	}
	UTIL_PlayWeaponAnimation(id, 1)
	g_TmpClip[id] = iClip;
	return 1;
}

public fw_Reload_Post(weapon_entity)
{
	new id = pev(weapon_entity,pev_owner);
	if (!is_user_connected(id) ||!g_has_violingun[id])
	{
		return 1;
	}
	if (g_TmpClip[id] == -1)
	{
		return 1;
	}
	set_pdata_int(weapon_entity, 51, g_TmpClip[id], 4);
	set_pdata_float(weapon_entity, 48,2.6, 4);
	set_pdata_float(id, 83,2.6, 5);
	set_pdata_int(weapon_entity, 54, 1, 4);
	UTIL_PlayWeaponAnimation(id, 1)
	return 1;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_galil.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName))
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn
	owner = pev(entity, pev_owner)
	wpn = find_ent_by_owner(-1, "weapon_galil", entity)
	
	if(g_has_violingun[owner] && pev_valid(wpn))
	{
		g_has_violingun[owner] = false;
		set_pev(wpn, pev_impulse, 10991);
		engfunc(EngFunc_SetModel, entity, W_VIOLIN_MDL);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_AddToPlayer(wpn, id)
{
	if(pev_valid(wpn) && is_user_connected(id) && pev(wpn, pev_impulse) == 10991)
	{
		g_has_violingun[id] = true;
		set_pev(wpn, pev_impulse, 0);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_ItemPostFrame(weapon_entity)
{
	new id = pev(weapon_entity, pev_owner);

	if(!g_has_violingun[id] || !is_user_connected(id) || !pev_valid(weapon_entity))
		return HAM_IGNORED;

	static iClipExtra; iClipExtra = get_pcvar_num(cvar_violingun_clip);

	new Float:flNextAttack = get_pdata_float(id, 83, 5);

	new iBpAmmo = cs_get_user_bpammo(id, CSW_GALIL);
	new iClip = get_pdata_int(weapon_entity, 51, 4);

	new fInReload = get_pdata_int(weapon_entity, 54, 4);

	if(fInReload && flNextAttack <= 0.0)
	{
		new Clp = min(iClipExtra - iClip, iBpAmmo);
		set_pdata_int(weapon_entity, 51, iClip + Clp, 4);
		cs_set_user_bpammo(id, CSW_GALIL, iBpAmmo-Clp);
		set_pdata_int(weapon_entity, 54, 0, 4);
		fInReload = 0;

		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if (is_user_alive(iAttacker) && get_user_weapon(iAttacker) == CSW_GALIL && g_has_violingun[iAttacker])
	{
	    static Float:flEnd[3]
	    get_tr2(ptr, TR_vecEndPos, flEnd)
	    
	   #if defined Frost 
	    make_laser_beam(iAttacker, flEnd)
	    #else
	    if(iEnt)
	    {
	        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	        write_byte(TE_DECAL)
	        engfunc(EngFunc_WriteCoord, flEnd[0])
	        engfunc(EngFunc_WriteCoord, flEnd[1])
	        engfunc(EngFunc_WriteCoord, flEnd[2])
	        write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
	        write_short(iEnt)
	        message_end()
	    } else {
	        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	        write_byte(TE_WORLDDECAL)
	        engfunc(EngFunc_WriteCoord, flEnd[0])
	        engfunc(EngFunc_WriteCoord, flEnd[1])
	        engfunc(EngFunc_WriteCoord, flEnd[2])
	        write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
	        message_end()
	    }
	    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	    write_byte(TE_GUNSHOTDECAL)
	    engfunc(EngFunc_WriteCoord, flEnd[0])
	    engfunc(EngFunc_WriteCoord, flEnd[1])
	    engfunc(EngFunc_WriteCoord, flEnd[2])
	    write_short(iAttacker)
	    write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
	    message_end()
	    #endif
    }
}

public fw_PrimaryAttack(weapon_entity)
{
	new id = get_pdata_cbase(weapon_entity, 41, 4);

	if (g_has_violingun[id])
	{
		g_clipammo[id] = cs_get_weapon_ammo(weapon_entity);
		g_primaryattack = 1;
	}
}

public fw_PrimaryAttack_Post(weapon_entity)
{
	new id = get_pdata_cbase(weapon_entity, 41, 4);

	if (g_has_violingun[id] && g_clipammo[id])
	{
		g_primaryattack = 0;
		set_pdata_float(weapon_entity, 46, get_pcvar_float(cvar_violingun_shotspd), 4);
		emit_sound(id, CHAN_WEAPON, SHOT_SOUND[random_num(0, sizeof SHOT_SOUND - 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		UTIL_PlayWeaponAnimation(id, random_num(3, 5));
	}
}

public fw_ItemDeploy_Post(weapon_entity)
{
	static id; id = get_weapon_ent_owner(weapon_entity);

	if (pev_valid(id) && g_has_violingun[id])
	{
		set_pev(id, pev_viewmodel2, V_VIOLIN_MDL);
		set_pev(id, pev_weaponmodel2, P_VIOLIN_MDL);
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage,bits)
{
	if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_GALIL && g_has_violingun[attacker]&&(bits&DMG_BULLET))
	{
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_violingun_damage_x));
		
		#if defined Frost
		if(zp_core_is_zombie(victim)) Random_Chance[attacker]++
		if(Random_Chance[attacker] >= get_pcvar_num(cvar_balrog_freeze_req)) 
		{
			if(zp_core_is_zombie(victim)&&!zp_class_hunter_get(victim))
			{
				zp_grenade_frost_set(victim, true)
				make_explosion_effect(attacker)
				set_task(get_pcvar_float(cvar_balrog_freeze_time), "Cancel_Ability",victim)
			} 
			Random_Chance[attacker] = 0
		}
		#endif
	}
}
#if defined Frost
public Cancel_Ability(id) 
{
	if(is_user_connected(id))
	{
	if(is_user_alive(id)) zp_grenade_frost_set(id, false)
	}
}

make_laser_beam(id,const Float:End[3], Size=15, R=0,G=128 , B=255) 
{
	for(new i = 1;i < 33; i++)
	{
		if(!is_user_connected(i))
			continue;
		
		if(zp_fps_get_user_flags(i) & FPS_SPRITES)
			continue;
			
		message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,{0,0,0},i)
		write_byte (TE_BEAMENTPOINT)
		write_short( id |0x1000 )
		write_coord(floatround(End[0]))
		write_coord(floatround(End[1]))
		write_coord(floatround(End[2]))
		write_short(g_laser_sprite)
		write_byte(0)
		write_byte(30)// FPS in 0.1
		write_byte(1)// Lifetime in 0.1
		write_byte(Size)// Width 0.1
		write_byte(2)// distortion in 0.1
		write_byte(R)
		write_byte(G)
		write_byte(B)
		write_byte(255)// brightness
		write_byte(20)// scroll speed in 0.1
		message_end()
	}
}

make_explosion_effect(id)
{
	static end[3];
	get_user_origin(id, end, 3);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	write_coord(end[0])
	write_coord(end[1])
	write_coord(end[2])
	write_short(g_balrog_exp)
	write_byte(10)
	write_byte(15)
	write_byte(4)
	message_end()
}
#endif
public zv_extra_item_selected(player, itemid)
{
	if(itemid != g_itemid_vip)
		return;
	
	command_give_violingun(player);
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

stock get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, 41, 4);
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

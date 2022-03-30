#define Electric

#include < amxmodx >
#include < fun >
#include < cstrike >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < zp50_items >
#include <zp50_colorchat>
#include <zmvip>
#include <zp50_gamemodes>

#if defined Electric
#include <zp50_fps>
#include <screenfade_util>
#define TASK_SHOCK 100
#define TASK_UNSHOCK 200
#define SHOCK_FREQ 0.1
#endif

#define WEAPON_BITSUM ((1<<CSW_GALIL))

new const VERSION[] = "1.1";

#define ITEM_NAME "Rock Guitar"
#define ITEM_COST 35

#if defined Electric

new const V_GUITAR_MDL[64] = "models/zombie_plague/v_guitar_electric.mdl";
new const P_GUITAR_MDL[64] = "models/zombie_plague/p_guitar_electric.mdl";
new const W_GUITAR_MDL[64] = "models/zombie_plague/w_guitar_electric.mdl";
new const PAIN_SOUNDS[][] = {"zombie_plague/zombie_pain1.wav","zombie_plague/zombie_pain2.wav","zombie_plague/zombie_pain3.wav","zombie_plague/zombie_pain4.wav","zombie_plague/zombie_pain5.wav"}
new const SHOCK_SOUND[] = "zombie_plague/guitar_shock.wav"
new g_laser_sprite, cvar_guitar_shock_time,cvar_guitar_shock_req;
new Random_Chance[33]
#else
new const V_GUITAR_MDL[64] = "models/zombie_plague/v_rock_guitar.mdl";
new const P_GUITAR_MDL[64] = "models/zombie_plague/p_rock_guitar.mdl";
new const W_GUITAR_MDL[64] = "models/zombie_plague/w_rock_guitar.mdl";
new const GUNSHOT_DECALS[] = {41, 42, 43, 44, 45}
#endif
new const OLD_W_MDL[64] = "models/w_galil.mdl";


new const GUITAR_SOUNDS[][] = {"weapons/gt_clipin.wav", "weapons/gt_clipon.wav", "weapons/gt_clipout.wav", "weapons/gt_draw.wav"}

new const ZOOM_SOUND[] = "weapons/zoom.wav";
new const SHOT_SOUND[] = "weapons/rguitar.wav";

native drop_violin(id);
native zp_class_hunter_get(id);

new g_itemid , g_itemid_vip, g_has_guitar[33] , g_hamczbots , g_clip_ammo[33] , g_has_zoom[33] , blood_spr[2] , cvar_rockguitar_damage_x , cvar_rockguitar_clip , cvar_rockguitar_bpammo , cvar_rockguitar_shotspd , cvar_rockguitar_oneround , cvar_botquota;

new g_TmpClip[33]

new g_RenderingFx[33]
new Float:g_RenderingColor[33][3]
new g_RenderingRender[33]
new Float:g_RenderingAmount[33]

new g_event_guitar, g_primaryattack;

new Purchases,MyAkLimit;

public plugin_init()
{
	// Plugin Register
	register_plugin("[ZP] Extra Item: Rock Guitar", VERSION, "CrazY");

	// Extra Item Register
	g_itemid = zp_items_register(ITEM_NAME, "bla",ITEM_COST);

	g_itemid_vip = zv_register_extra_item("Electric Guitar", "20 Ammo Packs",20,ZV_TEAM_HUMAN);
	// Cvars Register
	cvar_rockguitar_damage_x = register_cvar("zp_rockguitar_damage_x", "3.5");
	cvar_rockguitar_clip = register_cvar("zp_rockguitar_clip", "40");
	cvar_rockguitar_bpammo = register_cvar("zp_rockguitar_bpammo", "200");
	cvar_rockguitar_shotspd = register_cvar("zp_rockguitar_shot_speed", "0.11");
	cvar_rockguitar_oneround = register_cvar("zp_rockguitar_oneround", "0");

	// Cvar Pointer
	cvar_botquota = get_cvar_pointer("bot_quota");

	// Events
	register_event("CurWeapon", "event_CurWeapon", "b", "1=1");
	register_event("HLTV", "event_RoundStart", "a", "1=0", "2=0");
	register_event("DeathMsg", "event_DeathMsg", "a", "1>0");

	// Forwards
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent");
	register_forward(FM_CmdStart, "fw_CmdStart");

	// Hams
	RegisterHam(Ham_Item_PostFrame, "weapon_galil", "fw_ItemPostFrame");
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1);
	RegisterHam(Ham_TraceAttack, "info_target", "fw_TraceAttack", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_galil", "fw_AddToPlayer");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Weapon_Reload, "weapon_galil", "fw_Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_galil", "fw_Reload_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	#if defined Electric
	cvar_guitar_shock_time = register_cvar( "zp_rockguitar_shock_time" , "1.0")
	cvar_guitar_shock_req = register_cvar ("zp_rockguitar_shock_req","30");
	//register_clcmd("test","test")
	#endif
}

new Infection, Multi

public plugin_cfg()
{
	Infection = zp_gamemodes_get_id("Infection Mode");
	Multi = zp_gamemodes_get_id("Multiple Infection Mode");
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if (equal("events/galil.sc", name))
	{
		g_event_guitar = get_orig_retval()
		return FMRES_HANDLED;
	}
	return FMRES_IGNORED;
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_event_guitar) || !g_primaryattack)
		return FMRES_IGNORED;

	if (!(1 <= invoker <= get_maxplayers()))
    	return FMRES_IGNORED;

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2);
	return FMRES_SUPERCEDE;
}

public plugin_natives()
{
	register_native("drop_guitar","native_drop_guitar",1)
	register_native("zp_guitar_get","native_guitar_get",1);
}

public native_guitar_get(id)
{
	return g_has_guitar[id]
}
public native_drop_guitar(id)
{
	g_has_guitar[id]=false;
}
public plugin_precache()
{
	// Models
	precache_model(V_GUITAR_MDL);
	precache_model(P_GUITAR_MDL);
	precache_model(W_GUITAR_MDL);
	precache_model(OLD_W_MDL);

	// Blood Sprites
	blood_spr[0] = precache_model("sprites/blood.spr");
	blood_spr[1] = precache_model("sprites/bloodspray.spr");

	// Sounds
	for(new i = 0; i < sizeof GUITAR_SOUNDS; i++) precache_sound(GUITAR_SOUNDS[i]);
	precache_sound(ZOOM_SOUND);
	precache_sound(SHOT_SOUND);

	#if defined Electric
	g_laser_sprite = precache_model("sprites/laserbeam.spr");	
	precache_sound(SHOCK_SOUND)
	for(new i=0;i<sizeof(PAIN_SOUNDS);i++)
	{
		precache_sound(PAIN_SOUNDS[i])		
	}
	#endif
}

public client_putinserver(id)
{
	g_has_guitar[id] = false;

	if (is_user_bot(id) && !g_hamczbots && cvar_botquota)
	{
		set_task(0.1, "register_ham_czbots", id);
	}
}

public client_disconnected(id)
{
	g_has_guitar[id] = false;
}

public client_connect(id)
{
	g_has_guitar[id] = false;
}

public zp_fw_core_infect_post(id)
{
	g_has_guitar[id] = false;
}

public zp_fw_core_cure_post(id)
{
	if(get_pcvar_num(cvar_rockguitar_oneround))
		g_has_guitar[id] = false;
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
	
	if(zp_gamemodes_get_current()!=Infection&&zp_gamemodes_get_current()!=Multi)
	{
		return ZP_ITEM_DONT_SHOW;
	}

	if(!(zv_get_user_flags(id)&ZV_MAIN)&&!(get_user_flags(id)&ADMIN_KICK))
	{
		zp_items_menu_text_add("\r(VIP/ADMIN)")
		return ZP_ITEM_NOT_AVAILABLE
	}

	if(g_has_guitar[id])
	{
		return ZP_ITEM_NOT_AVAILABLE;
	}
	if(AlivCount() >= 22)
		MyAkLimit = 2
	else MyAkLimit = 1
	
	new Txt[32]
	format(Txt,charsmax(Txt),"[%d/%d]",Purchases,MyAkLimit)
	zp_items_menu_text_add(Txt)
	
	if(Purchases>MyAkLimit)
		return ZP_ITEM_NOT_AVAILABLE;

	zp_items_menu_text_add("[0/1]")
	return ZP_ITEM_AVAILABLE;
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

public zv_extra_item_selected(player, itemid)
{
	if(itemid != g_itemid_vip)
		return;
	
	drop_violin(player);
	if(user_has_weapon(player, CSW_GALIL))
	{
		drop_primary(player);
	}
	g_has_guitar[player] = true;
	new wpnid = give_item(player, "weapon_galil");
	zp_colored_print(player, "You bought an^3 Electric Guitar");
	cs_set_weapon_ammo(wpnid, get_pcvar_num(cvar_rockguitar_clip));
	cs_set_user_bpammo(player, CSW_GALIL, get_pcvar_num(cvar_rockguitar_bpammo));	
	engclient_cmd(player, "weapon_galil");
}

public zp_fw_items_select_post(player, itemid)
{
	if(itemid != g_itemid)
		return;
	
	Purchases++;
	drop_violin(player);
	if(user_has_weapon(player, CSW_GALIL))
	{
		drop_primary(player);
	}
	g_has_guitar[player] = true;
	new wpnid = give_item(player, "weapon_galil");
	zp_colored_print(player, "You bought an^3 Electric Guitar");
	cs_set_weapon_ammo(wpnid, get_pcvar_num(cvar_rockguitar_clip));
	cs_set_user_bpammo(player, CSW_GALIL, get_pcvar_num(cvar_rockguitar_bpammo));	
	engclient_cmd(player, "weapon_galil");
}

public event_CurWeapon(id)
{
	if (!is_user_alive(id) || zp_core_is_zombie(id)) return PLUGIN_HANDLED;
	
	if (read_data(2) == CSW_GALIL && g_has_guitar[id])
	{
		set_pev(id, pev_viewmodel2, V_GUITAR_MDL);
		set_pev(id, pev_weaponmodel2, P_GUITAR_MDL);
	}
	return PLUGIN_CONTINUE;
}

public event_RoundStart()
{
	Purchases = 0;
	if(get_pcvar_num(cvar_rockguitar_oneround))
	{
		for (new i = 1; i <= get_maxplayers(); i++)
			g_has_guitar[i] = false;
	}
}

public event_DeathMsg()
{
	g_has_guitar[read_data(2)] = false;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, OLD_W_MDL)) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_galil", entity);
	
	if(g_has_guitar[owner] && pev_valid(wpn))
	{
		g_has_guitar[owner] = false;
		set_pev(wpn, pev_impulse, 43555);
		engfunc(EngFunc_SetModel, entity, W_GUITAR_MDL);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_GALIL && g_has_guitar[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time () + 0.001);
	}
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(is_user_alive(id) &&  get_user_weapon(id) == CSW_GALIL && g_has_guitar[id])
	{
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
		{
			if(!g_has_zoom[id])
			{
				g_has_zoom[id] = true;
				cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1);
				emit_sound(id, CHAN_ITEM, ZOOM_SOUND, 0.20, 2.40, 0, 100);
			}
			else
			{
				g_has_zoom[id] = false;
				cs_set_user_zoom(id, CS_RESET_ZOOM, 0);
			}
		}

		if (g_has_zoom[id] && (pev(id, pev_button) & IN_RELOAD))
		{
			g_has_zoom[id] = false;
			cs_set_user_zoom(id, CS_RESET_ZOOM, 0);
		}
	}
}

public fw_ItemPostFrame(weapon_entity)
{
	new id = pev(weapon_entity, pev_owner);

	if(g_has_guitar[id] && is_user_alive(id))
	{
		static iClipExtra; iClipExtra = get_pcvar_num(cvar_rockguitar_clip);

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
	    }
    }
}

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 43555)
	{
		g_has_guitar[id] = true;
		set_pev(weapon_entity, pev_impulse, 0);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if (is_user_alive(iAttacker) && get_user_weapon(iAttacker) == CSW_GALIL && g_has_guitar[iAttacker])
	{
	    static Float:flEnd[3]
	    get_tr2(ptr, TR_vecEndPos, flEnd)
	    
	   	#if defined Electric 
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

#if defined Electric
public Shock(id)
{
	id-=TASK_SHOCK
	if(!is_user_alive(id)||!zp_core_is_zombie(id))
	{
		remove_task(id+TASK_SHOCK)
		return;
	}
	new color[3]
	color[1] = random_num(0,192)
	color[2] = random_num(0,255)
	UTIL_ScreenFade(id,color,-1.0,SHOCK_FREQ,random_num(50,100));	
	emit_sound(id,CHAN_AUTO,PAIN_SOUNDS[random(sizeof(PAIN_SOUNDS))],VOL_NORM,ATTN_NORM,0,PITCH_NORM)
	fm_set_rendering(id, kRenderFxGlowShell, color[0], color[1], color[2], kRenderNormal, 25)
	add_to_aim(id, random_float(-30.0,30.0),random_float(-30.0,30.0))
}

public Unshock(id)
{
	id-=TASK_UNSHOCK
	if(!is_user_alive(id)||!zp_core_is_zombie(id))
	{
		remove_task(id+TASK_UNSHOCK)
		return;
	}
	fm_set_rendering_float(id, g_RenderingFx[id], g_RenderingColor[id], g_RenderingRender[id], g_RenderingAmount[id])
}
add_to_aim(id, Float:up, Float:right)
{
     new Float:angle[3];
     entity_get_vector(id, EV_VEC_v_angle, angle);
     angle[0] -= up;
     angle[1] -= right;
     if(angle[0] < -88.994750)
     {
          angle[0] = -88.994750;
     }
     else if(angle[0] > 88.994750)
     {
          angle[0] = 88.994750;
     }
     if(angle[1] > 180.0)
     {
          angle[1] -= 360.0;
     }
     else if(angle[1] < -180.0)
     {
          angle[1] += 360.0;
     } 
     entity_set_vector(id, EV_VEC_angles, angle);
     entity_set_int(id, EV_INT_fixangle, 1);
}

make_laser_beam(id,const Float:End[3], Size=15)
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
		write_byte(20)// distortion in 0.1
		write_byte(0)//r
		write_byte(64)//g
		write_byte(255)//b
		write_byte(255)// brightness
		write_byte(20)// scroll speed in 0.1
		message_end()
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
		write_byte(20)// distortion in 0.1
		write_byte(0)//r
		write_byte(255)//g
		write_byte(64)//b
		write_byte(255)// brightness
		write_byte(20)// scroll speed in 0.1
		message_end()
	}
}

#endif
public fw_PrimaryAttack(weapon_entity)
{
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	
	if(g_has_guitar[id])
	{
		g_primaryattack = 1;
		g_clip_ammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
}

public fw_PrimaryAttack_Post(weapon_entity)
{
	new id = get_pdata_cbase(weapon_entity, 41, 4);

	if (g_has_guitar[id] && g_clip_ammo[id])
	{
		g_primaryattack = 0;
		set_pdata_float(weapon_entity, 46, get_pcvar_float(cvar_rockguitar_shotspd), 4);
		emit_sound(id, CHAN_WEAPON, SHOT_SOUND[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		UTIL_PlayWeaponAnimation(id, random_num(3, 5));
	}
}

public fw_Reload(weapon_entity)
{
	new id = pev(weapon_entity,pev_owner);
	if (!is_user_connected(id) || !g_has_guitar[id])
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
	if (get_pcvar_num(cvar_rockguitar_clip) <= iClip)
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
	if (!is_user_connected(id) ||!g_has_guitar[id])
	{
		return 1;
	}
	if (g_TmpClip[id] == -1)
	{
		return 1;
	}
	set_pdata_int(weapon_entity, 51, g_TmpClip[id], 4);
	set_pdata_float(weapon_entity, 48,3.33, 4);
	set_pdata_float(id, 83,3.33, 5);
	set_pdata_int(weapon_entity, 54, 1, 4);
	UTIL_PlayWeaponAnimation(id, 1)
	return 1;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage,bits)
{
	if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_GALIL && g_has_guitar[attacker]&&(bits&DMG_BULLET))
	{
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_rockguitar_damage_x));
		#if defined Electric
		if(zp_core_is_zombie(victim)) Random_Chance[attacker]++
		if(Random_Chance[attacker] >= get_pcvar_num(cvar_guitar_shock_req)) 
		{
			if(zp_core_is_zombie(victim)&&!zp_class_hunter_get(victim))
			{
				// Save player's old rendering	
				g_RenderingFx[victim] = pev(victim, pev_renderfx)
				pev(victim, pev_rendercolor, g_RenderingColor[victim])
				g_RenderingRender[victim] = pev(victim, pev_rendermode)
				pev(victim, pev_renderamt, g_RenderingAmount[victim])

				Shock(victim)			
				emit_sound(victim,CHAN_AUTO,SHOCK_SOUND,VOL_NORM,ATTN_NORM,0,PITCH_NORM)
				set_task(SHOCK_FREQ, "Shock",victim+TASK_SHOCK,_,_,"a",floatround(get_pcvar_float(cvar_guitar_shock_time)/SHOCK_FREQ)-1)
				set_task(get_pcvar_float(cvar_guitar_shock_time),"Unshock",victim+TASK_UNSHOCK)
			}
			
			Random_Chance[attacker] = 0
		}
		#endif
	}
}
/*
public test(id)
{
	Shock(id)			
	emit_sound(id,CHAN_AUTO,SHOCK_SOUND,VOL_NORM,ATTN_NORM,0,PITCH_NORM)
	set_task(SHOCK_FREQ, "Shock",id+TASK_SHOCK,_,_,"a",floatround(get_pcvar_float(cvar_guitar_shock_time)/SHOCK_FREQ)-1)
	set_task(get_pcvar_float(cvar_guitar_shock_time),"Unshock",id+TASK_UNSHOCK)
	return PLUGIN_HANDLED;
}*/

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player);
	write_byte(Sequence);
	write_byte(pev(Player, pev_body));
	message_end();
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
// Set entity's rendering type (float parameters version)
stock fm_set_rendering_float(entity, fx = kRenderFxNone, Float:color[3], render = kRenderNormal, Float:amount = 16.0)
{
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, amount)
}
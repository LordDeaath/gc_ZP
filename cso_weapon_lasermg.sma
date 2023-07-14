#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <zp50_core>

#define PLUGIN	"[CSO LIKE] LaserMG"
#define VERSION	"1.1"
#define AUTHOR	"Lakerovich"

#define weapon_name		"weapon_tmp"
#define weapon_new		"weapon_laserminigun"

#define ANIM_IDLE		0
#define ANIM_SHOOT_1		7
#define ANIM_SHOOT_2		8
#define ANIM_RELOAD		5
#define ANIM_DRAW		6

#define IDLE_TIME		1.7
#define DRAW_TIME		2.53
#define RELOAD_TIME		5.23

#define WEAPON_KEY		38591238491
#define Is_CustomItem(%0)	(pev(%0,pev_impulse) == WEAPON_KEY)

#define MODEL_V			"models/v_laserminigun.mdl"
#define MODEL_W			"models/w_laserminigun.mdl"
#define MODEL_P			"models/p_laserminiguna.mdl"
#define MODEL_P_CHARGE		"models/p_laserminigunb.mdl"

/******* CONFIGURATION LASERMINIGUN ********/
#define RECOIL			0.25				
#define EXPLODE_RADIUS		150.0
#define WEAPON_CLIP		100
#define WEAPON_BPAMMO		200
#define SHOOTS_FOR_HIGH		100
#define SHOOTS_FOR_EXTRREME	SHOOTS_FOR_HIGH + 200
/**** END OF CONFIGURATION LASERMINIGUN ****/

#define classname_ball	"laserminigun_ball"

#define Get_BitVar(%1,%2) (%1&(1<<(%2&31)))
#define Set_BitVar(%1,%2) %1|=(1<<(%2&31))
#define UnSet_BitVar(%1,%2) %1&=~(1<<(%2&31))

#define MUZZLEFLASH_1	"sprites/muzzleflash37.spr"
#define MUZZLEFLASH_2	"sprites/muzzleflash38.spr"
#define MUZZLEFLASH_3	"sprites/muzzleflash39.spr"

#define SPRITE_BALL_1	"sprites/laserminigun_charge_1.spr"
#define SPRITE_BALL_2	"sprites/laserminigun_charge_2.spr"
#define SPRITE_BALL_3	"sprites/laserminigun_charge_3.spr"

#define EXTRA_ITEM_NAME		"Laserminigun"
#define EXTRA_ITEM_PRICE	30

new gMaxPlayers, Msg_WeaponList, g_AllocString_V
new g_ChargeState[512],g_ChargeShots[512], g_AllocString_P, g_AllocString_P_charge
new Float:g_VecEndTrace[3], g_ChargeBall[33], g_ChargeForEntity[33]
new g_ChargeBall1_Explosion, g_ChargeBall2_Explosion, g_ChargeBall3_Explosion

new g_Muzzleflash_Ent1,g_Muzzleflash1
new g_Muzzleflash_Ent2,g_Muzzleflash2
new g_Muzzleflash_Ent3,g_Muzzleflash3

new g_MuzzleflashBall_Ent1,g_MuzzleflashBall1
new g_MuzzleflashBall_Ent2,g_MuzzleflashBall2
new g_MuzzleflashBall_Ent3,g_MuzzleflashBall3
new dam_wpn[6], wpn_spd
new const Weapon_Sounds[15][] = 
{
	"weapons/laserminigun-1.wav",			// 0
	"weapons/laserminigun-charge_start.wav",	// 1
	"weapons/laserminigun-charge_loop.wav",		// 2
	"weapons/laserminigun-charge_origin.wav",	// 3
	"weapons/laserminigun-charge_shoot.wav",	// 4
	"weapons/laserminigun_idle.wav",		// 5
	"weapons/laserminigun_draw.wav",		// 6
	"weapons/laserminigun_clipout2.wav",		// 7
	"weapons/laserminigun_clipout1.wav",		// 8
	"weapons/laserminigun_clipin2.wav",		// 9
	"weapons/laserminigun_clipin1.wav",		// 10
	"weapons/laserminigun_charge_end.wav",		// 11
	"weapons/laserminigun_exp1.wav",		// 12
	"weapons/laserminigun_exp2.wav",		// 13
	"weapons/laserminigun_exp3.wav"			// 14
}

enum
{
	STATE_LOW = 0,
	STATE_HIGH,
	STATE_EXTREME,
	STATE_CHARGE
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Item_Deploy,weapon_name,"HookHam_Weapon_Deploy",1)
	RegisterHam(Ham_Item_AddToPlayer,weapon_name,"HookHam_Weapon_Add",1)
	RegisterHam(Ham_Item_PostFrame,weapon_name,"HookHam_Weapon_Frame",0)
	
	RegisterHam(Ham_Weapon_Reload,weapon_name,"HookHam_Weapon_Reload",0)
	RegisterHam(Ham_Weapon_WeaponIdle,weapon_name,"HookHam_Weapon_Idle",0)
	RegisterHam(Ham_Weapon_PrimaryAttack,weapon_name,"HookHam_Weapon_PrimaryAttack",0)
	RegisterHam(Ham_TakeDamage,"player","HookHam_TakeDamage")
	
	register_forward(FM_SetModel,"HookFm_SetModel")
	register_forward(FM_AddToFullPack,"fw_AddToFullPack_post",1)
	register_forward(FM_CheckVisibility,"fw_CheckVisibility")
	register_forward(FM_UpdateClientData,"HookFm_UpdateClientData",1)
	
	register_touch("*", classname_ball, "BallTouch")
	dam_wpn[0] = register_cvar("zp_mdm_a", "2.0")
	dam_wpn[1] = register_cvar("zp_mdm_b", "2.25")
	dam_wpn[2] = register_cvar("zp_mdm_c", "2.50")
	dam_wpn[3] = register_cvar("zp_mdm_xa", "350.0")
	dam_wpn[4] = register_cvar("zp_mdm_xb", "700.0")
	dam_wpn[5] = register_cvar("zp_mdm_xc", "1000.0")
	wpn_spd = register_cvar("zp_mspd", "0.07")
	gMaxPlayers = get_maxplayers()
	Msg_WeaponList = get_user_msgid("WeaponList");
	
	register_clcmd("add_lm","get_item")
	register_clcmd(weapon_new,"hook_item")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, MODEL_W)
	engfunc(EngFunc_PrecacheModel, MODEL_V)
	engfunc(EngFunc_PrecacheModel, MODEL_P)
	engfunc(EngFunc_PrecacheModel, MODEL_P_CHARGE)
	
	engfunc(EngFunc_PrecacheModel, SPRITE_BALL_1)
	engfunc(EngFunc_PrecacheModel, SPRITE_BALL_2)
	engfunc(EngFunc_PrecacheModel, SPRITE_BALL_3)
	
	g_AllocString_V = engfunc(EngFunc_AllocString, MODEL_V)
	g_AllocString_P = engfunc(EngFunc_AllocString, MODEL_P)
	g_AllocString_P_charge = engfunc(EngFunc_AllocString, MODEL_P_CHARGE)
	
	for(new i = 0; i < sizeof(Weapon_Sounds); i++)
		engfunc(EngFunc_PrecacheSound,Weapon_Sounds[i])
	
	g_ChargeBall1_Explosion = engfunc(EngFunc_PrecacheModel,"sprites/laserminigun_explode_1.spr")
	g_ChargeBall2_Explosion = engfunc(EngFunc_PrecacheModel,"sprites/laserminigun_explode_2.spr")
	g_ChargeBall3_Explosion = engfunc(EngFunc_PrecacheModel,"sprites/laserminigun_explode_3.spr")
	
	
	g_Muzzleflash_Ent1 = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	precache_model(MUZZLEFLASH_1)
	engfunc(EngFunc_SetModel,g_Muzzleflash_Ent1,MUZZLEFLASH_1)
	set_pev(g_Muzzleflash_Ent1,pev_scale,0.1)
	set_pev(g_Muzzleflash_Ent1,pev_rendermode,kRenderTransTexture)
	set_pev(g_Muzzleflash_Ent1,pev_renderamt,0.0)
	
	g_Muzzleflash_Ent2 = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	precache_model(MUZZLEFLASH_2)
	engfunc(EngFunc_SetModel,g_Muzzleflash_Ent2,MUZZLEFLASH_2)
	set_pev(g_Muzzleflash_Ent2,pev_scale,0.1)
	set_pev(g_Muzzleflash_Ent2,pev_rendermode,kRenderTransTexture)
	set_pev(g_Muzzleflash_Ent2,pev_renderamt,0.0)
	
	g_Muzzleflash_Ent3 = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	precache_model(MUZZLEFLASH_3)
	engfunc(EngFunc_SetModel,g_Muzzleflash_Ent3,MUZZLEFLASH_3)
	set_pev(g_Muzzleflash_Ent3,pev_scale,0.1)
	set_pev(g_Muzzleflash_Ent3,pev_rendermode,kRenderTransTexture)
	set_pev(g_Muzzleflash_Ent3,pev_renderamt,0.0)
	
	g_MuzzleflashBall_Ent1 = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	engfunc(EngFunc_SetModel,g_MuzzleflashBall_Ent1,SPRITE_BALL_1)
	set_pev(g_MuzzleflashBall_Ent1,pev_scale,0.1)
	set_pev(g_MuzzleflashBall_Ent1,pev_rendermode,kRenderTransTexture)
	set_pev(g_MuzzleflashBall_Ent1,pev_renderamt,0.0)
	set_pev(g_MuzzleflashBall_Ent1,pev_fuser1, 0.1)
	
	g_MuzzleflashBall_Ent2 = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	engfunc(EngFunc_SetModel,g_MuzzleflashBall_Ent2,SPRITE_BALL_2)
	set_pev(g_MuzzleflashBall_Ent2,pev_scale,0.2)
	set_pev(g_MuzzleflashBall_Ent2,pev_rendermode,kRenderTransTexture)
	set_pev(g_MuzzleflashBall_Ent2,pev_renderamt,0.0)
	set_pev(g_MuzzleflashBall_Ent2,pev_fuser1, 0.2)
	
	g_MuzzleflashBall_Ent3 = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	engfunc(EngFunc_SetModel,g_MuzzleflashBall_Ent3,SPRITE_BALL_3)
	set_pev(g_MuzzleflashBall_Ent3,pev_scale,0.25)
	set_pev(g_MuzzleflashBall_Ent3,pev_rendermode,kRenderTransTexture)
	set_pev(g_MuzzleflashBall_Ent3,pev_renderamt,0.0)
	set_pev(g_MuzzleflashBall_Ent3,pev_fuser1, 0.25)
	
	engfunc(EngFunc_PrecacheGeneric,MUZZLEFLASH_1)
	engfunc(EngFunc_PrecacheGeneric,MUZZLEFLASH_2)
	engfunc(EngFunc_PrecacheGeneric,MUZZLEFLASH_3)
	
	engfunc(EngFunc_PrecacheGeneric,"sprites/640hud133.spr")
	engfunc(EngFunc_PrecacheGeneric,"sprites/640hud14.spr")
	engfunc(EngFunc_PrecacheGeneric,"sprites/weapon_laserminigun.txt")
	
	register_forward(FM_Spawn,"HookFm_Spawn",0)
}

public plugin_natives()
{
	register_native("give_laserminigun","get_item", 1)
}

public zp_user_infected_post(id)
{
	remove_laserminigun(id)
}

public zp_user_humanized_post(id)
{
	remove_laserminigun(id)
}
public zp_fw_gamemodes_end(gm)
{
	for(new id; id <= get_maxplayers();id++)
	{
		if(is_user_connected(id))
			remove_laserminigun(id)
	}
}

public remove_laserminigun(id)
{
	g_ChargeBall[id] = 0
	g_ChargeForEntity[id] = 0
	
	UnSet_BitVar(g_MuzzleflashBall1,id)
	UnSet_BitVar(g_MuzzleflashBall2,id)
	UnSet_BitVar(g_MuzzleflashBall3,id)
}

public client_command(id)
{
	new Command[32];read_argv(0,Command,charsmax(Command));  
	new ent = fm_find_ent_by_owner(-1,weapon_name,id)
	if(equali(Command,"weapon_",7) && g_ChargeBall[id] && Is_CustomItem(ent) || equali(Command,"lastinv") && g_ChargeBall[id] && Is_CustomItem(ent))
	{  
		client_print(id,print_center,"Saat Ini Senjata Tidak Bisa Di Ganti")
		return PLUGIN_HANDLED;
	}
	else if(equali(Command,"drop") && g_ChargeBall[id] && Is_CustomItem(ent))
	{
		client_print(id,print_center,"Saat Ini Senjata Tidak Bisa Di Drop")
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public get_item(id)
{	
	UTIL_DropWeapon(id,1)
	new weapon = make_weapon()
	
	if(weapon <= 0)
		return
	
	if(!ExecuteHamB(Ham_AddPlayerItem,id,weapon))
	{
		engfunc(EngFunc_RemoveEntity,weapon)
		return
	}
	
	ExecuteHam(Ham_Item_AttachToPlayer,weapon,id)
	
	new ammotype = 376 + get_pdata_int(weapon,49,4)
	new ammo = get_pdata_int(id,ammotype,5)
	
	if(ammo < WEAPON_BPAMMO)
		set_pdata_int(id, ammotype, WEAPON_BPAMMO, 5)
		
	set_pdata_int(weapon, 51, WEAPON_CLIP, 4)
	emit_sound(id,CHAN_ITEM,"items/gunpickup2.wav",VOL_NORM,ATTN_NORM,0,PITCH_NORM)
	
	g_ChargeState[weapon] = STATE_LOW
	g_ChargeShots[weapon] = 0
	g_ChargeBall[id] = 0
	g_ChargeForEntity[id] = 0
	
	UnSet_BitVar(g_MuzzleflashBall1,id)
	UnSet_BitVar(g_MuzzleflashBall2,id)
	UnSet_BitVar(g_MuzzleflashBall3,id)
}

public hook_item(id)
{
	engclient_cmd(id,weapon_name)
	return PLUGIN_HANDLED
}

public fw_AddToFullPack_post(esState,iE,ent,iHost,iHostFlags,iPlayer,pSet)
{
	if(ent == g_Muzzleflash_Ent1)
	{
		if(Get_BitVar(g_Muzzleflash1,iHost))
		{
			set_es(esState,ES_Frame,float(random_num(0,2)))
			set_es(esState,ES_RenderMode,kRenderTransAdd)
			set_es(esState,ES_RenderAmt,255.0)
			UnSet_BitVar(g_Muzzleflash1,iHost)
		}	
		set_es(esState,ES_Skin,iHost)
		set_es(esState,ES_Body,1)
		set_es(esState,ES_AimEnt,iHost)
		set_es(esState,ES_MoveType,MOVETYPE_FOLLOW)
	} 
	if(ent == g_Muzzleflash_Ent2)
	{
		if(Get_BitVar(g_Muzzleflash2,iHost))
		{
			set_es(esState,ES_Frame,float(random_num(0,2)))
			set_es(esState,ES_RenderMode,kRenderTransAdd)
			set_es(esState,ES_RenderAmt,255.0)
			UnSet_BitVar(g_Muzzleflash2,iHost)
		}	
		set_es(esState,ES_Skin,iHost)
		set_es(esState,ES_Body,1)
		set_es(esState,ES_AimEnt,iHost)
		set_es(esState,ES_MoveType,MOVETYPE_FOLLOW)
	}
	if(ent == g_Muzzleflash_Ent3)
	{
		if(Get_BitVar(g_Muzzleflash3,iHost))
		{
			set_es(esState,ES_Frame,float(random_num(0,2)))
			set_es(esState,ES_RenderMode,kRenderTransAdd)
			set_es(esState,ES_RenderAmt,255.0)
			UnSet_BitVar(g_Muzzleflash3,iHost)
		}	
		set_es(esState,ES_Skin,iHost)
		set_es(esState,ES_Body,1)
		set_es(esState,ES_AimEnt,iHost)
		set_es(esState,ES_MoveType,MOVETYPE_FOLLOW)
	}
	if(ent == g_MuzzleflashBall_Ent1)
	{
		if(Get_BitVar(g_MuzzleflashBall1,iHost))
		{
			set_es(esState,ES_Frame,float(random_num(0,8)))
			set_es(esState,ES_RenderMode,kRenderTransAdd)
			set_es(esState,ES_RenderAmt,240.0)
		}	
		set_es(esState,ES_Skin,iHost)
		set_es(esState,ES_Body,1)
		set_es(esState,ES_AimEnt,iHost)
		set_es(esState,ES_MoveType,MOVETYPE_FOLLOW)
	}
	if(ent == g_MuzzleflashBall_Ent2)
	{
		if(Get_BitVar(g_MuzzleflashBall2,iHost))
		{
			set_es(esState,ES_Frame,float(random_num(0,8)))
			set_es(esState,ES_RenderMode,kRenderTransAdd)
			set_es(esState,ES_RenderAmt,240.0)
		}	
		set_es(esState,ES_Skin,iHost)
		set_es(esState,ES_Body,1)
		set_es(esState,ES_AimEnt,iHost)
		set_es(esState,ES_MoveType,MOVETYPE_FOLLOW)
	}
	if(ent == g_MuzzleflashBall_Ent3)
	{
		if(Get_BitVar(g_MuzzleflashBall3,iHost))
		{
			set_es(esState,ES_Frame,float(random_num(0,8)))
			set_es(esState,ES_RenderMode,kRenderTransAdd)
			set_es(esState,ES_RenderAmt,240.0)
		}	
		set_es(esState,ES_Skin,iHost)
		set_es(esState,ES_Body,1)
		set_es(esState,ES_AimEnt,iHost)
		set_es(esState,ES_MoveType,MOVETYPE_FOLLOW)
	}
}

public fw_CheckVisibility(entity,pSet)
{
	if(entity == g_Muzzleflash_Ent1 || entity == g_Muzzleflash_Ent2 || entity == g_Muzzleflash_Ent3)
	{
		forward_return(FMV_CELL,1)
		return FMRES_SUPERCEDE
	} 
	else if(entity == g_MuzzleflashBall_Ent1 || entity == g_MuzzleflashBall_Ent2 || entity == g_MuzzleflashBall_Ent3)
	{
		forward_return(FMV_CELL,1)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public HookHam_Weapon_Deploy(ent)
{
	if(!Is_CustomItem(ent))
		return HAM_IGNORED
		
	static id
	id = get_pdata_cbase(ent,41,4)

	set_pev_string(id,pev_viewmodel2, g_AllocString_V)
	set_pev_string(id,pev_weaponmodel2, g_AllocString_P)
	
	set_pdata_float(ent,46,DRAW_TIME,4)
	set_pdata_float(ent,47,DRAW_TIME,4)
	set_pdata_float(ent,48,DRAW_TIME,4)
	Play_WeaponAnim(id,ANIM_DRAW)
	set_pdata_string(id,1968,"m249",-1,20)
	Weaponlist(id, true)
	
	return HAM_IGNORED
}

public HookHam_Weapon_Add(ent,id)
{
	switch(pev(ent,pev_impulse))
	{
		case WEAPON_KEY: Weaponlist(id,true)
		case 0: Weaponlist(id,false)
	}
	return HAM_IGNORED
}

public MakeBall(id)
{
	new ent = create_entity("env_sprite"),Float:f_origin[3],Float:f_vec[3]
	set_pev(ent,pev_classname,classname_ball)
	pev(id,pev_origin,f_origin)
	velocity_by_aim(id,35,f_vec)
	
	for(new i=0;i<3;i++){ f_origin[i]+=f_vec[i];f_vec[i]*=40.0;}
	f_origin[2] += (pev(id,pev_flags)&FL_DUCKING)?2.0:10.0;
	
	set_pev(ent,pev_origin,f_origin)
	set_pev(ent,pev_velocity,f_vec)
	set_pev(ent,pev_solid,SOLID_BBOX)
	set_pev(ent,pev_movetype,MOVETYPE_FLY)
	
	if(g_ChargeForEntity[id] == 1)
	{
		set_pev(ent, pev_scale, 0.2)
		entity_set_model(ent,SPRITE_BALL_1)
	}
	else if(g_ChargeForEntity[id] == 2)
	{
		set_pev(ent, pev_scale, 0.25)
		entity_set_model(ent,SPRITE_BALL_1)
	}
	else if(g_ChargeForEntity[id] == 3)
	{
		set_pev(ent, pev_scale, 0.27)
		entity_set_model(ent,SPRITE_BALL_2)
	}
	else if(g_ChargeForEntity[id] == 4)
	{
		set_pev(ent, pev_scale, 0.32)
		entity_set_model(ent,SPRITE_BALL_3)
	}
	
	set_pev(ent,pev_mins,Float:{-4.0,-4.0,-4.0})
	set_pev(ent,pev_maxs,Float:{4.0,4.0,4.0})
	set_pev(ent,pev_owner,id)
	
	set_pev(ent,pev_rendermode,kRenderTransAdd)
	set_pev(ent,pev_renderamt,255.0)
	
	pev(id,pev_v_angle,f_vec)
	set_pev(ent,pev_v_angle,f_vec)
}

public BallTouch(id, ent)
{
	new Float:origin[3],Float:f_vec[3]
	pev(ent, pev_origin, origin)
	velocity_by_aim(ent,-15,f_vec)
	
	for(new i = 0; i < 3; i++)
		origin[i] += f_vec[i] 
	
	static classnameptd[32]
	pev(id, pev_classname, classnameptd, 31)
	if(equali(classnameptd, "func_breakable"))
		ExecuteHamB(Ham_TakeDamage, id, 0, 0, 100.0, DMG_GENERIC)
	
	BallSprites(ent, origin)
	BallDamage(ent)
}

public BallSprites(ent, Float:origin[3])
{
	static owner
	owner = pev(ent, pev_owner)
	
	if(g_ChargeForEntity[owner] == 1)
	{ 
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_SPRITE);
		write_coord(floatround(origin[0]))
		write_coord(floatround(origin[1]))
		write_coord(floatround(origin[2] + 40.0))
		write_short(g_ChargeBall1_Explosion)
		write_byte(30)
		write_byte(225)
		message_end()
		
		emit_sound(ent, CHAN_ITEM, Weapon_Sounds[13], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else if(g_ChargeForEntity[owner] == 2)
	{ 
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(TE_SPRITE);
		write_coord(floatround(origin[0]))
		write_coord(floatround(origin[1]))
		write_coord(floatround(origin[2] + 40.0))
		write_short(g_ChargeBall1_Explosion)
		write_byte(30)
		write_byte(225)
		message_end()
		
		emit_sound(ent, CHAN_ITEM, Weapon_Sounds[12], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else if(g_ChargeForEntity[owner] == 3)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(TE_SPRITE);
		write_coord(floatround(origin[0]))
		write_coord(floatround(origin[1]))
		write_coord(floatround(origin[2] + 40.0))
		write_short(g_ChargeBall2_Explosion)
		write_byte(30)
		write_byte(225)
		message_end()
		
		emit_sound(ent, CHAN_ITEM, Weapon_Sounds[13], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else if(g_ChargeForEntity[owner] == 4)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_SPRITE)
		write_coord(floatround(origin[0]))
		write_coord(floatround(origin[1]))
		write_coord(floatround(origin[2] + 40.0))
		write_short(g_ChargeBall3_Explosion)
		write_byte(30)
		write_byte(225)
		message_end()
		
		emit_sound(ent, CHAN_ITEM, Weapon_Sounds[14], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

public BallDamage(ent)
{
	static owner, attacker, Float:dm_ball, Float:dm_ball2, Float:dm_ball3, Float:dm_dis
	static Float:Or[3], Float:pOr[3]
	owner = pev(ent, pev_owner)
	dm_ball = get_pcvar_float(dam_wpn[3])
	dm_ball2 = get_pcvar_float(dam_wpn[4])
	dm_ball3 = get_pcvar_float(dam_wpn[5])
	pev(ent, pev_origin, Or)
	if(!is_user_alive(owner) || zp_core_is_zombie(owner))
	{
		attacker = 0;
		return
	} 
	else attacker = owner
	if(get_user_weapon(owner) == CSW_KNIFE)
		return;

	for(new i = 0; i < gMaxPlayers; i++)
	{
		if(i == attacker)
			continue
		if(!is_user_alive(i))
			continue
		if(!zp_core_is_zombie(i))
			continue
		if(entity_range(i, ent) > EXPLODE_RADIUS)
			continue
		pev(i, pev_origin, pOr)
		dm_dis = get_distance_f(Or, pOr)
		
		if(g_ChargeForEntity[attacker] == 1) ExecuteHamB(Ham_TakeDamage,i,0,attacker,dm_ball - (dm_dis * 1.5),DMG_BULLET)
		else if(g_ChargeForEntity[attacker] == 2) ExecuteHamB(Ham_TakeDamage,i,0,attacker,dm_ball - (dm_dis * 1.5),DMG_BULLET)
		else if(g_ChargeForEntity[attacker] == 3) ExecuteHamB(Ham_TakeDamage,i,0,attacker,dm_ball2 - (dm_dis * 2.0),DMG_BULLET)
		else if(g_ChargeForEntity[attacker] == 4) ExecuteHamB(Ham_TakeDamage,i,0,attacker,dm_ball3 - (dm_dis * 3.0),DMG_BULLET)
	}
	
	remove_entity(ent)
}

public HookHam_Weapon_Frame(ent)
{
	if(!Is_CustomItem(ent))
		return HAM_IGNORED
	
	static id
	id = get_pdata_cbase(ent,41,4)
	
	if(get_pdata_int(ent,54,4))
	{
		if(get_pdata_float(ent,46,4) >= 0.0)
			return HAM_IGNORED
		
		static clip,ammotype,ammo,j
		clip = get_pdata_int(ent,51,4)
		ammotype = 376 + get_pdata_int(ent,49,4)
		ammo = get_pdata_int(id,ammotype,5)
		j = min(WEAPON_CLIP-clip,ammo)
		set_pdata_int(ent, 51, clip+j, 4)
		set_pdata_int(id, ammotype, ammo-j, 5)
		set_pdata_int(ent, 54, 0, 4)
	}
	
	if(g_ChargeShots[ent] < SHOOTS_FOR_HIGH) g_ChargeState[ent] = STATE_LOW
	else if(g_ChargeShots[ent] >= SHOOTS_FOR_HIGH && g_ChargeShots[ent] < SHOOTS_FOR_EXTRREME) g_ChargeState[ent] = STATE_HIGH
	else if(g_ChargeShots[ent] >= SHOOTS_FOR_EXTRREME) g_ChargeState[ent] = STATE_EXTREME
	if(g_ChargeBall[id]) g_ChargeState[ent] = STATE_CHARGE
	if(g_ChargeShots[ent] > 0 && !(pev(id,pev_button) & IN_ATTACK) &&!g_ChargeBall[id])
		g_ChargeShots[ent]--
	
	static iButton;iButton = pev(id,pev_button)
	g_ChargeBall[id] = pev(ent, pev_iuser1)
	
	new Float:fFinshTime, Float:ScaleNew, Float:ScaleDelay[33]
	pev(ent,pev_fuser1,fFinshTime)
	
	static ammo
	ammo = get_pdata_int(ent,51,4)
	
	if(iButton & IN_ATTACK2)
	{
		if(get_pdata_float(ent, 46, 4) >= 0.0)
			return HAM_IGNORED
		if(ammo == 0)
			return HAM_IGNORED
			
		g_ChargeState[ent] = STATE_CHARGE
		set_pev_string(id,pev_weaponmodel2,g_AllocString_P_charge)
		
		if(!g_ChargeBall[id])
		{
			g_ChargeBall[id] = 1
			fFinshTime = get_gametime()+2.0
			
			Play_WeaponAnim(id, 1)
			emit_sound(ent, CHAN_ITEM, Weapon_Sounds[3], 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			set_pdata_float(ent, 48, 1.0, 4)
			set_pdata_float(ent, 46, 1.0, 4)
			set_pev(ent,pev_iuser1,g_ChargeBall[id])
			
			if(get_gametime() - 0.01 > ScaleDelay[id])
			{
				pev(g_MuzzleflashBall_Ent1, pev_scale, ScaleNew)
				ScaleNew += 0.01
				set_pev(g_MuzzleflashBall_Ent1, pev_scale, ScaleNew)
				ScaleDelay[id] = get_gametime()
			}
			
			set_pev(ent, pev_fuser1, fFinshTime)
			
			Set_BitVar(g_MuzzleflashBall1,id)
			UnSet_BitVar(g_MuzzleflashBall2,id)
			UnSet_BitVar(g_MuzzleflashBall3,id)
		}
		else if(get_gametime() > fFinshTime && g_ChargeBall[id] == 1)
		{
			g_ChargeBall[id] = 2;
			fFinshTime = get_gametime()+4.0
			
			Play_WeaponAnim(id,2)
			emit_sound(ent, CHAN_ITEM, Weapon_Sounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			set_pdata_float(ent, 48, 1.25, 4)
			set_pdata_float(ent, 46, 1.25, 4)
			set_pev(ent,pev_iuser1,g_ChargeBall[id])
			
			if(get_gametime() - 0.01 > ScaleDelay[id])
			{
				pev(g_MuzzleflashBall_Ent1, pev_scale, ScaleNew)
				ScaleNew += 0.02
				set_pev(g_MuzzleflashBall_Ent1, pev_scale, ScaleNew)
				ScaleDelay[id] = get_gametime()
			}
			
			Set_BitVar(g_MuzzleflashBall1,id)
			UnSet_BitVar(g_MuzzleflashBall2,id)
			UnSet_BitVar(g_MuzzleflashBall3,id)
		}
		else if(get_gametime() > fFinshTime && g_ChargeBall[id] == 2)
		{
			g_ChargeBall[id] = 3
			fFinshTime = get_gametime()+5.0
			
			set_pdata_float(ent, 48, 1.5, 4)
			set_pdata_float(ent, 46, 1.5, 4)
			set_pev(ent,pev_iuser1,g_ChargeBall[id])
			
			if(get_gametime() - 0.01 > ScaleDelay[id])
			{
				pev(g_MuzzleflashBall_Ent1, pev_scale, ScaleNew)
				ScaleNew += 0.05
				set_pev(g_MuzzleflashBall_Ent1, pev_scale, ScaleNew)
				ScaleDelay[id] = get_gametime()
			}
			
			UnSet_BitVar(g_MuzzleflashBall1,id)
			Set_BitVar(g_MuzzleflashBall2,id)
			UnSet_BitVar(g_MuzzleflashBall3,id)

		}
		else if(get_gametime() > fFinshTime && g_ChargeBall[id] == 3)
		{
			g_ChargeBall[id] = 4
			fFinshTime = get_gametime() + 200.0
			
			Play_WeaponAnim(id, 3)
			emit_sound(ent, CHAN_ITEM, Weapon_Sounds[2], 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			set_pdata_float(ent, 48, 250.0, 4)
			set_pdata_float(ent, 46, 250.0, 4)
			set_pev(ent,pev_iuser1,g_ChargeBall[id])
			
			if(get_gametime() - 0.01 > ScaleDelay[id])
			{
				pev(g_MuzzleflashBall_Ent1, pev_scale, ScaleNew)
				ScaleNew += 0.08
				set_pev(g_MuzzleflashBall_Ent1, pev_scale, ScaleNew)
				ScaleDelay[id] = get_gametime()
			}
			
			set_pev(ent, pev_fuser1, fFinshTime)
			UnSet_BitVar(g_MuzzleflashBall1,id)
			UnSet_BitVar(g_MuzzleflashBall2,id)
			Set_BitVar(g_MuzzleflashBall3,id)
		}
		
		iButton &= ~IN_ATTACK2;
		set_pev(id,pev_button,iButton)
	}
	else
	{
		switch(g_ChargeBall[id])
		{	
			case 1:
			{
				Play_WeaponAnim(id,4)
				emit_sound(ent, CHAN_ITEM, Weapon_Sounds[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
				
				set_pdata_float(ent,48,1.63,4)
				set_pdata_float(ent,46,1.0,4)
				
				UnSet_BitVar(g_MuzzleflashBall1,id)
				UnSet_BitVar(g_MuzzleflashBall2,id)
				UnSet_BitVar(g_MuzzleflashBall3,id)
				
				g_ChargeState[ent] = STATE_LOW
				g_ChargeShots[ent] = 0
				g_ChargeForEntity[id] = g_ChargeBall[id]
				
				set_pev_string(id,pev_weaponmodel2,g_AllocString_P)
				MakeBall(id)
				
				if(ammo > 19) set_pdata_int(ent, 51, ammo - 20, 4)
				else set_pdata_int(ent,51, 0, 4)
			}
			case 2:
			{
				Play_WeaponAnim(id,4);
				emit_sound(ent, CHAN_ITEM, Weapon_Sounds[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
				
				set_pdata_float(ent,48,1.63,4)
				set_pdata_float(ent,46,1.0,4)
				
				UnSet_BitVar(g_MuzzleflashBall1,id)
				UnSet_BitVar(g_MuzzleflashBall2,id)
				UnSet_BitVar(g_MuzzleflashBall3,id)
				
				g_ChargeState[ent] = STATE_LOW
				g_ChargeShots[ent] = 0
				g_ChargeForEntity[id] = g_ChargeBall[id]
				
				set_pev_string(id,pev_weaponmodel2,g_AllocString_P)
				MakeBall(id)
				
				if(ammo > 19) set_pdata_int(ent, 51, ammo - 20, 4)
				else set_pdata_int(ent,51, 0, 4)
			}
			case 3:
			{
				Play_WeaponAnim(id,4)
				emit_sound(ent, CHAN_ITEM, Weapon_Sounds[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
				
				set_pdata_float(ent,48,1.63,4)
				set_pdata_float(ent,46,1.0,4)
				
				UnSet_BitVar(g_MuzzleflashBall1,id)
				UnSet_BitVar(g_MuzzleflashBall2,id)
				UnSet_BitVar(g_MuzzleflashBall3,id)
				
				g_ChargeState[ent] = STATE_LOW
				g_ChargeShots[ent] = 0
				g_ChargeForEntity[id] = g_ChargeBall[id]
				
				set_pev_string(id,pev_weaponmodel2,g_AllocString_P)
				MakeBall(id)
				
				if(ammo > 19) set_pdata_int(ent, 51, ammo - 20, 4)
				else set_pdata_int(ent,51, 0, 4)
			}
			case 4:
			{
				Play_WeaponAnim(id,4)
				emit_sound(ent, CHAN_ITEM, Weapon_Sounds[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
				
				set_pdata_float(ent,48,1.63,4)
				set_pdata_float(ent,46,1.0,4)
				
				UnSet_BitVar(g_MuzzleflashBall1,id)
				UnSet_BitVar(g_MuzzleflashBall2,id)
				UnSet_BitVar(g_MuzzleflashBall3,id)
				
				g_ChargeState[ent] = STATE_LOW
				g_ChargeShots[ent] = 0
				g_ChargeForEntity[id] = g_ChargeBall[id]
				
				set_pev_string(id,pev_weaponmodel2,g_AllocString_P)
				MakeBall(id)
					
				if(ammo > 19) set_pdata_int(ent, 51, ammo - 20, 4)
				else set_pdata_int(ent,51, 0, 4)
			}
		}
		
		g_ChargeBall[id] = 0
		
		new Float:ResetScale[3]
		pev(g_MuzzleflashBall_Ent1, pev_fuser1, ResetScale[0])
		set_pev(g_MuzzleflashBall_Ent1, pev_scale, ResetScale[0])
		pev(g_MuzzleflashBall_Ent2, pev_fuser1, ResetScale[1])
		set_pev(g_MuzzleflashBall_Ent2, pev_scale, ResetScale[1])
		pev(g_MuzzleflashBall_Ent3, pev_fuser1, ResetScale[2])
		set_pev(g_MuzzleflashBall_Ent3, pev_scale, ResetScale[2])
		
		set_pev_string(id,pev_weaponmodel2,g_AllocString_P)
		set_pev(ent,pev_iuser1,g_ChargeBall[id])
	}
	
	return HAM_IGNORED
}

public HookHam_Weapon_Reload(ent)
{
	if(!Is_CustomItem(ent))
		return HAM_IGNORED
	
	static clip
	clip = get_pdata_int(ent,51,4)
	
	if(clip >= WEAPON_CLIP)
		return HAM_SUPERCEDE
	
	static id
	id = get_pdata_cbase(ent,41,4)
	
	if(get_pdata_int(id, 376 + get_pdata_int(ent,49,4), 5) <= 0)
		return HAM_SUPERCEDE
	
	set_pdata_int(ent, 51, 0,4)
	ExecuteHam(Ham_Weapon_Reload, ent)
	set_pdata_int(ent,51, clip, 4)
	set_pdata_int(ent,54, 1,4)
	set_pdata_float(ent, 46,RELOAD_TIME,4)
	set_pdata_float(ent, 47,RELOAD_TIME,4)
	set_pdata_float(ent, 48,RELOAD_TIME,4)
	set_pdata_float(id, 83, RELOAD_TIME,5)
	Play_WeaponAnim(id, ANIM_RELOAD)
	return HAM_SUPERCEDE;
}

public HookHam_Weapon_Idle(ent)
{
	if(!Is_CustomItem(ent))
		return HAM_IGNORED
		
	if(get_pdata_float(ent, 48, 4) > 0.0)
		return HAM_IGNORED
		
	set_pdata_float(ent,48,IDLE_TIME,4)
	Play_WeaponAnim(get_pdata_cbase(ent, 41, 4), ANIM_IDLE)
	
	return HAM_SUPERCEDE
}

public HookHam_Weapon_PrimaryAttack(ent)
{
	if(!Is_CustomItem(ent))
		return HAM_IGNORED
		
	static ammo, Float:WEAPON_SPEED
	ammo = get_pdata_int(ent,51,4)
	WEAPON_SPEED = get_pcvar_float(wpn_spd)
	if(ammo <= 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound,ent);
		set_pdata_float(ent,46,WEAPON_SPEED,4)
		return HAM_SUPERCEDE
	}
		
	static id; id = get_pdata_cbase(ent,41,4)
	static Float:user_punchangle[3];pev(id,pev_punchangle,user_punchangle)
	static fm_hooktrace;fm_hooktrace=register_forward(FM_TraceLine,"HookFm_TraceLine",true)
	static fm_playbackevent;fm_playbackevent=register_forward(FM_PlaybackEvent,"HookFm_PlayBackEvent",false)
	
	state FireBullets: Enabled;
	ExecuteHam(Ham_Weapon_PrimaryAttack,ent)
	state FireBullets: Disabled;
	
	unregister_forward(FM_TraceLine,fm_hooktrace,true)
	unregister_forward(FM_PlaybackEvent,fm_playbackevent,false)
	
	Play_WeaponAnim(id,random_num(ANIM_SHOOT_1,ANIM_SHOOT_2))
	set_pdata_int(ent,51,ammo-1,4)
	set_pdata_float(ent,48,2.0,4)
	static Float:user_newpunch[3];pev(id,pev_punchangle,user_newpunch)
	
	user_newpunch[0]=user_punchangle[0]+(user_newpunch[0]-user_punchangle[0])*RECOIL
	user_newpunch[1]=user_punchangle[1]+(user_newpunch[1]-user_punchangle[1])*RECOIL
	user_newpunch[2]=user_punchangle[2]+(user_newpunch[2]-user_punchangle[2])*RECOIL
	set_pev(id,pev_punchangle,user_newpunch)

	emit_sound(ent, CHAN_ITEM, Weapon_Sounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_pdata_float(ent,46,WEAPON_SPEED,4)
	
	new Float:Origin[3]
	get_weapon_position(id,Origin,.add_forward=10.0,.add_right=7.0,.add_up=-10.5)
		
	new Float:Velo[3]
	Velo[0]=g_VecEndTrace[0]-Origin[0]
	Velo[1]=g_VecEndTrace[1]-Origin[1]
	Velo[2]=g_VecEndTrace[2]-Origin[2]
		
	vec_normalize(Velo,Velo)
	vec_mul_scalar(Velo,4096.0,Velo)
	
	if(g_ChargeState[ent] == STATE_LOW)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_USERTRACER)
		engfunc(EngFunc_WriteCoord,Origin[0])
		engfunc(EngFunc_WriteCoord,Origin[1])
		engfunc(EngFunc_WriteCoord,Origin[2])
		engfunc(EngFunc_WriteCoord,Velo[0])
		engfunc(EngFunc_WriteCoord,Velo[1])
		engfunc(EngFunc_WriteCoord,Velo[2])
		write_byte(20)
		write_byte(4)
		write_byte(5)
		message_end()
		
		Set_BitVar(g_Muzzleflash1,id)
	}
	else if(g_ChargeState[ent] == STATE_HIGH)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_USERTRACER)
		engfunc(EngFunc_WriteCoord,Origin[0])
		engfunc(EngFunc_WriteCoord,Origin[1])
		engfunc(EngFunc_WriteCoord,Origin[2])
		engfunc(EngFunc_WriteCoord,Velo[0])
		engfunc(EngFunc_WriteCoord,Velo[1])
		engfunc(EngFunc_WriteCoord,Velo[2])
		write_byte(20)
		write_byte(5)
		write_byte(5)
		message_end()
		
		Set_BitVar(g_Muzzleflash2,id)
	}
	else if(g_ChargeState[ent] == STATE_EXTREME)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_USERTRACER)
		engfunc(EngFunc_WriteCoord,Origin[0])
		engfunc(EngFunc_WriteCoord,Origin[1])
		engfunc(EngFunc_WriteCoord,Origin[2])
		engfunc(EngFunc_WriteCoord,Velo[0])
		engfunc(EngFunc_WriteCoord,Velo[1])
		engfunc(EngFunc_WriteCoord,Velo[2])
		write_byte(20)
		write_byte(1)
		write_byte(5)
		message_end()
		
		Set_BitVar(g_Muzzleflash3,id)
	}
	g_ChargeShots[ent]++
	
	return HAM_SUPERCEDE
}

public HookHam_TakeDamage(victim,inflictor,attacker,Float:damage)<FireBullets: Enabled>
{ 
	if(get_user_weapon(attacker) != CSW_TMP)
		return HAM_IGNORED;
	static Float:dx, Float:dx2, Float:dx3;
	dx = get_pcvar_float(dam_wpn[0])
	dx2 = get_pcvar_float(dam_wpn[1])
	dx3 = get_pcvar_float(dam_wpn[2])
	
	new ent = fm_find_ent_by_owner(-1,weapon_name,attacker)
	if(g_ChargeState[ent] == STATE_LOW)
		SetHamParamFloat(4,damage*dx)
	else if(g_ChargeState[ent] == STATE_HIGH)
		SetHamParamFloat(4,damage*dx2)
	else if(g_ChargeState[ent] == STATE_EXTREME)
		SetHamParamFloat(4,damage*dx3)
		
	return HAM_OVERRIDE;
}

public HookHam_TakeDamage()<FireBullets: Disabled>
{ 
	return HAM_IGNORED;
}

public HookHam_TakeDamage()<>
{
	return HAM_IGNORED;
}

public HookFm_SetModel(ent)
{ 
	static i,classname[32],item;pev(ent,pev_classname,classname,31);
	if(!equal(classname,"weaponbox"))
		return FMRES_IGNORED
		
	for(i=0; i < 6; i++)
	{
		item = get_pdata_cbase(ent,34+i,4)
		
		static id
		id = pev(ent,pev_owner)
		
		if(item > 0 && Is_CustomItem(item))
		{
			engfunc(EngFunc_SetModel,ent,MODEL_W)
			g_ChargeState[ent] = STATE_LOW
			g_ChargeShots[ent] = 0
			UnSet_BitVar(g_MuzzleflashBall1,id)
			UnSet_BitVar(g_MuzzleflashBall2,id)
			UnSet_BitVar(g_MuzzleflashBall3,id)
			g_ChargeBall[id] = 0
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED;
}

public HookFm_PlayBackEvent()
{ 
	return FMRES_SUPERCEDE
}

public HookFm_TraceLine(Float:tr_start[3],Float:tr_end[3],tr_flag,tr_ignore,tr)
{
	if(tr_flag&IGNORE_MONSTERS)
		return FMRES_IGNORED
		
	static hit
	hit=get_tr2(tr,TR_pHit)
	
	static Decal, glassdecal
	
	if(!glassdecal)
		glassdecal = engfunc(EngFunc_DecalIndex,"{bproof1")
	
	hit = get_tr2(tr,TR_pHit)
	if(hit > 0 && pev_valid(hit))
	{
		if(pev(hit,pev_solid) != SOLID_BSP)
			return FMRES_IGNORED
			
		else if(pev(hit,pev_rendermode) != 0) Decal=glassdecal
		else Decal = random_num(41,45)
	}
	else Decal = random_num(41,45)

	static Float:vecEnd[3]
	get_tr2(tr,TR_vecEndPos,vecEnd)
	g_VecEndTrace = vecEnd
	
	engfunc(EngFunc_MessageBegin,MSG_PAS,SVC_TEMPENTITY,vecEnd,0)
	write_byte(TE_GUNSHOTDECAL)
	engfunc(EngFunc_WriteCoord,vecEnd[0])
	engfunc(EngFunc_WriteCoord,vecEnd[1])
	engfunc(EngFunc_WriteCoord,vecEnd[2])
	write_short(hit>0?hit:0)
	write_byte(Decal)
	message_end()
	
	static Float:WallVector[3];get_tr2(tr,TR_vecPlaneNormal,WallVector)
	engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,vecEnd,0);
	write_byte(TE_STREAK_SPLASH)
	engfunc(EngFunc_WriteCoord,vecEnd[0]);
	engfunc(EngFunc_WriteCoord,vecEnd[1]);
	engfunc(EngFunc_WriteCoord,vecEnd[2]);
	engfunc(EngFunc_WriteCoord,WallVector[0]*random_float(25.0,30.0));
	engfunc(EngFunc_WriteCoord,WallVector[1]*random_float(25.0,30.0));
	engfunc(EngFunc_WriteCoord,WallVector[2]*random_float(25.0,30.0));
	write_byte(111)
	write_short(12)
	write_short(3)
	write_short(75)	
	message_end()
	
	return FMRES_IGNORED
}

public HookFm_UpdateClientData(id,SendWeapons,CD_Handle)
{
	static item
	item = get_pdata_cbase(id,373,5)
	if(item <= 0 || !Is_CustomItem(item))
		return FMRES_IGNORED
		
	set_cd(CD_Handle,CD_flNextAttack,99999.0)
	return FMRES_HANDLED
}

public HookFm_Spawn(id)
{
	if(pev_valid(id) != 2)
		return FMRES_IGNORED
		
	static ClName[32]
	pev(id,pev_classname,ClName,31)
	
	if(strlen(ClName) < 5)
		return FMRES_IGNORED
		
	static Trie:ClBuffer
	if(!ClBuffer) ClBuffer = TrieCreate()
	if(!TrieKeyExists(ClBuffer,ClName))
	{
		TrieSetCell(ClBuffer, ClName, 1)
		RegisterHamFromEntity(Ham_TakeDamage, id, "HookHam_TakeDamage", 0)
	}
	return FMRES_IGNORED
}

stock make_weapon()
{
	static ent, g_AllocString_E
	if(g_AllocString_E || (g_AllocString_E = engfunc(EngFunc_AllocString,weapon_name)))
		ent = engfunc(EngFunc_CreateNamedEntity,g_AllocString_E)
	else
		return 0
	if(ent <= 0)
		return 0
		
	set_pev(ent,pev_spawnflags,SF_NORESPAWN)
	set_pev(ent,pev_impulse,WEAPON_KEY)
	ExecuteHam(Ham_Spawn,ent)
	
	return ent
}

stock UTIL_DropWeapon(id,slot)
{
	static iEntity
	iEntity = get_pdata_cbase(id,(367 + slot),5)
	
	if(iEntity > 0)
	{
		static iNext,szWeaponName[32]
		
		do
		{
			iNext = get_pdata_cbase(iEntity,42,4);
			if(get_weaponname(get_pdata_int(iEntity, 43, 4), szWeaponName, 31))
				engclient_cmd(id,"drop",szWeaponName)
		} 
		while((iEntity=iNext)>0)
	}
}

stock Play_WeaponAnim(id,anim)
{
	set_pev(id,pev_weaponanim,anim)
	message_begin(MSG_ONE_UNRELIABLE,SVC_WEAPONANIM,_,id)
	write_byte(anim)
	write_byte(0)
	message_end()
}

stock Weaponlist(id,bool:set)
{
	if(!is_user_connected(id))
		return
		
	message_begin(MSG_ONE,Msg_WeaponList,_,id);
	write_string(set == false ? weapon_name:weapon_new);
	write_byte(3);
	write_byte(WEAPON_BPAMMO);
	write_byte(-1);
	write_byte(-1);
	write_byte(0);
	write_byte(4);
	write_byte(20);
	write_byte(0);
	message_end();
}

stock get_weapon_position(id,Float:fOrigin[3],Float:add_forward=0.0,Float:add_right=0.0,Float:add_up=0.0)
{
	static Float:Angles[3],Float:ViewOfs[3],Float:vAngles[3]
	static Float:Forward[3],Float:Right[3],Float:Up[3]
	pev(id,pev_v_angle,vAngles)
	pev(id,pev_origin,fOrigin)
	pev(id,pev_view_ofs,ViewOfs)
	vec_add(fOrigin,ViewOfs,fOrigin)
	pev(id,pev_v_angle,Angles)
	engfunc(EngFunc_MakeVectors,Angles)
	global_get(glb_v_forward,Forward)
	global_get(glb_v_right,Right)
	global_get(glb_v_up,Up)
	vec_mul_scalar(Forward,add_forward,Forward)
	vec_mul_scalar(Right,add_right,Right)
	vec_mul_scalar(Up,add_up,Up)
	fOrigin[0]=fOrigin[0]+Forward[0]+Right[0]+Up[0]
	fOrigin[1]=fOrigin[1]+Forward[1]+Right[1]+Up[1]
	fOrigin[2]=fOrigin[2]+Forward[2]+Right[2]+Up[2]
}

vec_add(const Float:in1[],const Float:in2[],Float:out[])
{
	out[0]=in1[0]+in2[0];
	out[1]=in1[1]+in2[1];
	out[2]=in1[2]+in2[2];
}

vec_mul_scalar(const Float:vec[],Float:scalar,Float:out[])
{
	out[0]=vec[0]*scalar;
	out[1]=vec[1]*scalar;
	out[2]=vec[2]*scalar;
}

vec_normalize(const Float:vec[],Float:out[])
{
	new Float:invlen=rsqrt(vec[0]*vec[0]+vec[1]*vec[1]+vec[2]*vec[2]);
	out[0]=vec[0]*invlen;
	out[1]=vec[1]*invlen;
	out[2]=vec[2]*invlen;
}

Float:rsqrt(Float:x)
{
	new Float:xhalf=x*0.5;
	
	new i=_:x;
	i=0x5f375a84 - (i>>1);
	x=Float:i;
			
	x=x*(1.5-xhalf*x*x);
	x=x*(1.5-xhalf*x*x);
	x=x*(1.5-xhalf*x*x);
		
	return x;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
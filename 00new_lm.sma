/*
	Shidla [SGC] | 2013 год
	ICQ: 312-298-513

	2.8.2 [Final Version] | 21.05.2013
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <zombieplague>
#include <zp50_gamemodes>
#include <engine>
#include <zp50_items>
#include <zp50_gamemodes>
#include <colorchat>
#include <zp50_ammopacks>
#include <zmvip>
#include <bulletdamage>
#include <beams>
#include <zp50_grenade_frost>

#include <zp50_class_survivor>
#include <zp50_class_sniper>
#include <zp50_class_knifer>
#include <zp50_class_plasma>

native zp_bought_vip_item_get(id)
native zp_bought_vip_item_set(id)

#define DMG_GRENADE                     (1<<24)     // Counter-Strike only - Hit by HE grenade

#if AMXX_VERSION_NUM < 180
	#assert AMX Mod X v1.8.0 or greater library required!
#endif

#define PLUGIN "[ZP] LaserMine"
#define VERSION "3.0"
#define AUTHOR "SandStriker / Shidla / QuZ / DJ_WEST"

#define RemoveEntity(%1)	engfunc(EngFunc_RemoveEntity,%1)

#define LASERMINE_TEAM		pev_iuser1 //EV_INT_iuser1
#define LASERMINE_OWNER		pev_iuser2 //EV_INT_iuser3
#define LASERMINE_STEP		pev_iuser3
#define LASERMINE_HITING	pev_iuser4
#define LASERMINE_COUNT		pev_fuser1

#define LASERMINE_POWERUP	pev_fuser2
#define LASERMINE_BEAMTHINK	pev_fuser3

#define LASERMINE_BEAMENDPOINT	pev_vuser1
#define MAX_MINES			10
#define MODE_LASERMINE		0
#define OFFSET_TEAM			114
#define OFFSET_MONEY		115
#define OFFSET_DEATH		444

#define TASK_PLANT		30100
#define TASK_RESET		15500
#define TASK_RELEASE		15900

#define cs_get_user_team(%1)	CsTeams:get_offset_value(%1,OFFSET_TEAM)
#define cs_get_user_deaths(%1)	get_offset_value(%1,OFFSET_DEATH)
#define is_valid_player(%1)	(1 <= %1 <= 32)

native zp_show_reward(id, amount, const reason[32])

enum tripmine_e {
	TRIPMINE_IDLE1 = 0,
	TRIPMINE_IDLE2,
	TRIPMINE_ARM1,
	TRIPMINE_ARM2,
	TRIPMINE_FIDGET,
	TRIPMINE_HOLSTER,
	TRIPMINE_DRAW,
	TRIPMINE_WORLD,
	TRIPMINE_GROUND,
};

enum
{
	POWERUP_THINK,
	BEAMBREAK_THINK,
	EXPLOSE_THINK
};

enum
{
	POWERUP_SOUND,
	ACTIVATE_SOUND,
	STOP_SOUND
};

new const
	ENT_MODELS[]	= "models/gc_lasermine.mdl",
	ENT_SOUND1[]	= "weapons/mine_deploy.wav",
	ENT_SOUND2[]	= "weapons/mine_charge.wav",
	ENT_SOUND3[]	= "weapons/mine_activate.wav",
	ENT_SOUND4[]	= "debris/beamstart9.wav",
	ENT_SOUND5[]	= "items/gunpickup2.wav",
	ENT_SOUND6[]	= "debris/bustglass1.wav",
	ENT_SOUND7[]	= "debris/bustglass2.wav",
	ENT_SPRITE1[]	= "sprites/laserbeam.spr",
	ENT_SPRITE2[]	= "sprites/zerogxplodex.spr";

new const
	ENT_CLASS_NAME[]	=	"lasermine",
	ENT_CLASS_NAME3[]	=	"func_breakable"
	
new g_EntMine, beam, boom
new g_LENABLE,  g_LHEALTH, g_LHEALTH_VIP, g_LRADIUS
new g_LRDMG, g_LDMGMODE
new  g_LDSEC,  g_LME, g_LDMG;
new g_MaxPL, LaserEnt
new  g_havemine[33], g_deployed[33];
//new CVAR_LMCost
new g_GameModeArma,Nemesis,Predator,Dragon,Nightcrawler,Swarm,Plague
new Float:iLaserMineHealth[33][3]
native zp_item_zombie_madness_get(id)
new g_pSB[33], g_pBeam[33], iSBCanBePlaced[33]
//new ipDistance[33] = 50
new Float:ivecOrigin[3]
new const SB_CLASSNAME[] = "FakeLasermine"
new gMsgBarTime;
new g_iMaxPlayers;
// new g_LME_vip;
new Bought[33];

new bool:Colors;

new Float:DamageDealt[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	RegisterHam(Ham_TakeDamage, ENT_CLASS_NAME3, "Laser_TakeDamage", 0)
	register_clcmd("say /lm", "Lasermenu_LgK",0,"- Buys lasermine/Opens lasermine menu")
	g_LENABLE	= register_cvar("zp_ltm","1")
	g_LHEALTH	= register_cvar("zp_ltm_health","455")
	g_LHEALTH_VIP	= register_cvar("zp_ltm_health_vip","520")
	g_LRADIUS	= register_cvar("zp_ltm_radius","25.0")
	g_LRDMG		= register_cvar("zp_ltm_rdmg","1000") //radius damage
	g_LDMGMODE	= register_cvar("zp_ltm_ldmgmode","0") //0 - frame dmg, 1 - once dmg, 2 - 1 second dmg
	g_LDSEC		= register_cvar("zp_ltm_ldmgseconds","1") //mode 2 only, damage / seconds. default 1 (sec)
	g_LDMG 		= register_cvar("zp_ltm_ldmg","100")	//0 is +USE key, 1 is bind, 2 is each.
	register_event("HLTV","event_newround", "a","1=0", "2=0"); // it's called every on new round 
	
	register_clcmd("+setlaser","CreateLaserMine_Progress_b");
   	register_clcmd("-setlaser","StopCreateLaserMine");
	register_clcmd("+dellaser","ReturnLaserMine_Progress");
   	register_clcmd("-dellaser","StopReturnLaserMine");
	
	
	gMsgBarTime	= get_user_msgid("BarTime");
	// Forward.
	register_forward(FM_Think, "ltm_Think");

	register_cvar("[DS] Lasermine", "3.0", FCVAR_SERVER|FCVAR_SPONLY)

	g_LME = zp_items_register("Laser Mine","", 15, 0,1)
	// g_LME_vip = zv_register_extra_item("Laser Mine", "FREE",0,ZV_TEAM_HUMAN);
	register_forward(FM_OnFreeEntPrivateData, "OnFreeEntPrivateData");
	g_iMaxPlayers = get_maxplayers();
	register_think(SB_CLASSNAME, "SB_Think");
	
	RegisterHam(Ham_Killed, "player", "Player_Death", 1)
	new mapname[32]
	get_mapname(mapname, charsmax(mapname))
	if(equali(mapname,"zm_lgk_colors"))
	{
		Colors = true;
	}
}

public plugin_natives()
{
	register_native("zp_lasermine_set_cost","native_lasermine_set_cost")	
}
public native_lasermine_set_cost(plugin,params)
{
	if(get_param(3)!=g_LME)
		return false;	

	if(Bought[get_param(1)])
	set_param_byref(2, 2 * get_param_byref(2))

	return true;
}

public Player_Death(victim)
{
	
	if (g_pBeam[victim] && is_valid_ent(g_pBeam[victim]))
		remove_entity(g_pBeam[victim]);
		
	if (g_pSB[victim] && is_valid_ent(g_pSB[victim]))
		remove_entity(g_pSB[victim]);	
}

public OnFreeEntPrivateData(this)
{
	if (!FClassnameIs(this, SB_CLASSNAME))
		return FMRES_IGNORED;

	new pOwner = pev(this, pev_owner);

	if ((1 <= pOwner <= g_iMaxPlayers))
	{
		if (g_pBeam[pOwner] && is_valid_ent(g_pBeam[pOwner]))
			remove_entity(g_pBeam[pOwner]);

		g_pBeam[pOwner] = 0;
		g_pSB[pOwner] = 0;
	}
	return FMRES_IGNORED;
}

public plugin_precache() 
{
	precache_sound(ENT_SOUND1);
	precache_sound(ENT_SOUND2);
	precache_sound(ENT_SOUND3);
	precache_sound(ENT_SOUND4);
	precache_sound(ENT_SOUND5);
	precache_sound(ENT_SOUND6);
	precache_sound(ENT_SOUND7);
	precache_model(ENT_MODELS);
	beam = precache_model(ENT_SPRITE1);
	boom = precache_model(ENT_SPRITE2);
	return PLUGIN_CONTINUE;
}

public plugin_cfg()
{
	LaserEnt = create_custom_entity("LaserMine_Hurt")
	g_EntMine = engfunc(EngFunc_AllocString,ENT_CLASS_NAME3);
	arrayset(g_havemine,0,sizeof(g_havemine));
	arrayset(g_deployed,0,sizeof(g_deployed));
	g_MaxPL = get_maxplayers();
	g_GameModeArma= zp_gamemodes_get_id("Armageddon Mode")
	Nemesis=zp_gamemodes_get_id("Nemesis Mode")
	Dragon=zp_gamemodes_get_id("Dragon Mode")
	Nightcrawler=zp_gamemodes_get_id("Nightcrawler Mode")
	Predator=zp_gamemodes_get_id("Predators Mode")
	Swarm = zp_gamemodes_get_id("Swarm Mode");
	Plague = zp_gamemodes_get_id("Plague Mode");
}

public Laser_TakeDamage(victim, inflictor, attacker, Float:f_Damage, bit_Damage)
{
	//Victim is not lasermine.
	
	new sz_classname[32] 
	entity_get_string( victim , EV_SZ_classname , sz_classname, 31 )
		
	if( !equali(sz_classname,"lasermine") ) 
	return HAM_IGNORED; 
	
	if(!is_user_alive(attacker))
		return HAM_IGNORED;	
	
	if(!zp_core_is_zombie(attacker))
		return HAM_SUPERCEDE;
	
	if(zp_grenade_frost_get(attacker))  
		return HAM_SUPERCEDE; 
	
	new iHealth = pev(victim,pev_health);	
	iHealth -=floatround(f_Damage)
	if(is_valid_ent(victim) && zp_core_is_zombie(attacker))
	{
		DamageDealt[attacker] += f_Damage
		if(DamageDealt[attacker] >= 65.0)
		{
			static AP
			AP = floatround(DamageDealt[attacker] / 65.0, floatround_floor)
			zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + AP)
			zp_show_reward(attacker, AP, "[LASERMINE]")
			DamageDealt[attacker]-= 65.0 * AP;
		}
	}
	/*if(is_valid_ent(victim) && zp_core_is_zombie(attacker) && (iHealth) <= 0.0)
	{
		zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + 5)
		ColorChat(attacker,GREEN,"[GC]^03 You won^04 5 Ammopacks^03 for destorying a lasermine!")		
		return HAM_IGNORED;
	}*/
	new health = get_pcvar_num(g_LHEALTH),viphealth=get_pcvar_num(g_LHEALTH_VIP);
	if( iHealth <= health) 
	{
		set_rendering ( victim, kRenderFxGlowShell, 255-255*iHealth/health, 255*iHealth/health, 0, kRenderNormal, 22)
	}
	else
	if( iHealth <= viphealth) 
	{
		set_rendering ( victim, kRenderFxGlowShell, 0,255-255*(iHealth-health)/(viphealth-health),255*(iHealth-health)/(viphealth-health), kRenderNormal, 22)
	}		
	
	return HAM_IGNORED; 
}

public Lasermenu_LgK( id )
{	
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
	
	if(zp_core_is_zombie(id))
		return PLUGIN_HANDLED;
		
	new menu_id = menu_create("\y[GC]\w Lasermine","lgk_lm_handler")
	if(!g_havemine[id]&&!g_deployed[id])
	{
		zp_items_force_buy(id, g_LME);
		return PLUGIN_HANDLED;
	}
	new text[34]
	if(g_havemine[id])
	{
		formatex(text,charsmax(text),"Place a Lasermine [%d/%d]",g_deployed[id],g_havemine[id]+g_deployed[id])
		menu_additem(menu_id,text,"",0)
		CreateFakeSandBag(id)	
	}
	else
	if(Bought[id])
	{
		if(zv_get_user_flags(id)&ZV_MAIN)
		{
			if(zp_bought_vip_item_get(id))
			{
				formatex(text,charsmax(text),"\dBuy a Lasermine")
			}
			else
			{
				formatex(text,charsmax(text),"Buy a Lasermine\y %d\w [1/2]",2*zp_items_get_cost(g_LME))
			}
		}
		else
		{			
			formatex(text,charsmax(text),"\dBuy a Lasermine [1/2]\r [VIP]")
		}
		menu_additem(menu_id,text,"",0)
	}
	else
	{
		if(zv_get_user_flags(id)&ZV_MAIN)
		{
			formatex(text,charsmax(text),"Buy a Lasermine\y %d\w [0/2]",zp_items_get_cost(g_LME))
		}
		else
		{
			formatex(text,charsmax(text),"Buy a Lasermine\y %d\w [0/1]",zp_items_get_cost(g_LME))
		}
		menu_additem(menu_id,text,"",0)
	}
	

	menu_additem(menu_id,"Takeback a Lasermine","",0)

	menu_setprop(menu_id, MPROP_EXIT, MEXIT_ALL );
	menu_display(id, menu_id, 0 );
	return PLUGIN_HANDLED;
}

public Lasermenu_LgK2( id )
{	
	if(!is_user_alive(id))
		return;
	
	if(zp_core_is_zombie(id))
		return;
		
	new menu_id = menu_create("\y[GC]\w Lasermine","lgk_lm_handler")
	new text[34]
	if(g_havemine[id])
	{
		formatex(text,charsmax(text),"Place a Lasermine [%d/%d]",g_deployed[id],g_havemine[id]+g_deployed[id])
		menu_additem(menu_id,text,"",0)
		Lasermenu_LgK(id);
	}
	else	
	if(Bought[id])
	{
		if(zv_get_user_flags(id)&ZV_MAIN)
		{
			if(zp_bought_vip_item_get(id))
			{
				formatex(text,charsmax(text),"\dBuy a Lasermine")
			}
			else
			{
				formatex(text,charsmax(text),"Buy a Lasermine\y %d\w [1/2]",2*zp_items_get_cost(g_LME))
			}
		}
		else
		{			
			formatex(text,charsmax(text),"\dBuy a Lasermine [1/2]\r [VIP]")
		}
		menu_additem(menu_id,text,"",0)
	}
	else
	{
		if(zv_get_user_flags(id)&ZV_MAIN)
		{
			formatex(text,charsmax(text),"Buy a Lasermine\y %d\w [0/2]",zp_items_get_cost(g_LME))
		}
		else
		{
			formatex(text,charsmax(text),"Buy a Lasermine\y %d\w [0/1]",zp_items_get_cost(g_LME))
		}
		menu_additem(menu_id,text,"",0)
	}
	

	menu_additem(menu_id,"Takeback a Lasermine","",0)
	
	
	menu_setprop(menu_id, MPROP_EXIT, MEXIT_ALL );
	menu_display(id, menu_id, 0 );
}
public lgk_lm_handler( id, menu, item )
{
	menu_destroy(menu);
	
	if (!is_user_alive(id) || zp_core_is_zombie(id))
	{
		ColorChat(id, GREEN, "[GC]^03 Only humans can use Lasermines")
		return PLUGIN_HANDLED;
	}
	
	switch( item )
	{		
		case 0:
		{
			if(g_havemine[id])
			{
				if(!g_pSB[id])
				{
					Lasermenu_LgK(id);					
				}
				else
				if(iSBCanBePlaced[id] == 5)
				{
					Lasermenu_LgK(id); 
					ColorChat(id, GREEN, "[GC]^03 Lasermines can't be placed here!")
					
				}
				else
				if(zp_gamemodes_get_current()!=ZP_NO_GAME_MODE)
				{								
					Spawn(id)		
					if(zv_get_user_flags(id)&&(g_havemine[id]||!zp_bought_vip_item_get(id)))
					Lasermenu_LgK2(id);
				}
				else
				ColorChat(id, GREEN,"[GC]^03Lasermines can be placed only in infection modes.")	
			}
			else
			if((zp_items_get_purchases(g_LME)>=zp_items_get_limit(g_LME)&&zp_items_get_limit(g_LME))||((zp_items_get_player_purchases(g_LME,id)>=zp_items_get_player_limit(g_LME)&&zp_items_get_player_limit(g_LME)))&&(zpv_is_user_vip(id)&&zp_items_get_player_purchases(g_LME,id)>=zp_items_get_vip_limit(g_LME)&&zp_items_get_vip_limit(g_LME)))
			{				
				Lasermenu_LgK2(id);
			}
			else
			if(Bought[id]&&!(zv_get_user_flags(id)&ZV_MAIN))
			{
				ColorChat(id, GREEN, "[GC]^1 Buy^3 VIP^1 at^3 GamerClub.NeT^1 for^3 Increased Item Limits!")
				Lasermenu_LgK2(id);
				return PLUGIN_HANDLED;
			}
			else
			{
				zp_items_force_buy(id, g_LME)				
			}
		}
		case 1:
		{
			Destroy(id)
			//client_cmd(id,"+dellaser")
			ReturnMine(id)	
			Lasermenu_LgK2(id);	
		}
		case MENU_EXIT:
			Destroy(id)		
	}
	return PLUGIN_HANDLED;
}

public Destroy(id)
{
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
	
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);
}

public CreateFakeSandBag(id)
{
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		return
		
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		return;
		
	new iSB = create_entity("info_target")
	
	if (!iSB)
		return;
		
	static Float:vecAngles[3]
	//GetOriginAimEndEyes(id, ipDistance[id], ivecOrigin, vecAngles)
	GetOriginAimEndEyes(id, 128, ivecOrigin, vecAngles)
	engfunc(EngFunc_SetModel, iSB, ENT_MODELS)
	engfunc(EngFunc_SetOrigin, iSB, ivecOrigin);
	
	set_pev(iSB, pev_classname, SB_CLASSNAME);
	set_pev(iSB, pev_owner, id);
	set_pev(iSB, pev_rendermode, kRenderTransAdd);
	set_pev(iSB, pev_renderamt, 200.0);
	set_pev(iSB, pev_body, 1);
	set_pev(iSB, pev_nextthink, get_gametime());
	set_pev(iSB,pev_movetype,MOVETYPE_FLY); // Movestep <- for Preview
	set_pev(iSB,pev_frame,0);
	set_pev(iSB,pev_body,5);
	set_pev(iSB,pev_sequence,TRIPMINE_WORLD);
	set_pev(iSB,pev_framerate,0);
	set_pev(iSB,pev_angles,vecAngles);
	new pBeam = Beam_Create("sprites/laserbeam.spr", 6.0);
	
	if (pBeam != FM_NULLENT)
	{	
		Beam_EntsInit(pBeam, iSB, id);
		Beam_SetColor(pBeam, Float:{150.0, 0.0, 0.0});
		Beam_SetScrollRate(pBeam, 255.0);
		Beam_SetBrightness(pBeam, 200.0);
	}
	else
	{
		pBeam = 0;
	}
	
	g_pBeam[id] = pBeam;
	g_pSB[id] = iSB;
}

public SB_Think(SandBag)
{
	if (pev_valid(SandBag) != 2)
		return;

	static pOwner;
	pOwner = pev(SandBag, pev_owner);
	
	if (!(1 <= pOwner <= g_iMaxPlayers) || !is_user_alive(pOwner))
		return;
		
	static iBody, Float:vecColor[3], Float:vecAngles[3];

	//new hitwall=GetOriginAimEndEyes(pOwner, ipDistance[pOwner], ivecOrigin, vecAngles);
	new hitwall=GetOriginAimEndEyes(pOwner, 128, ivecOrigin, vecAngles);
	iBody = 5
	xs_vec_set(vecColor, 250.0, 0.0, 0.0);
	engfunc(EngFunc_SetOrigin, SandBag, ivecOrigin);	
	set_pev(SandBag,pev_angles,vecAngles);
	//set_pev(SandBag,pev_flags, Fl_ONGROUND)
	//engfunc( EngFunc_DropToFloor, SandBag);
	if (!IsHullVacant(ivecOrigin, HULL_HEAD, SandBag))
	{
		if(hitwall&&CheckSandBag(pOwner,SandBag))
		{
			if(!Colors||ivecOrigin[0]>2150.0||ivecOrigin[0]<2016.0||ivecOrigin[1]>-945.0||ivecOrigin[1]<-1136.0||ivecOrigin[2]<502.968750)
			{						
				iBody = 3
				xs_vec_set(vecColor, 0.0, 250.0, 0.0);
			}
		}
	}	
	
	if (g_pBeam[pOwner] && is_valid_ent(g_pBeam[pOwner]))
	{
		Beam_RelinkBeam(g_pBeam[pOwner]);
		Beam_SetColor(g_pBeam[pOwner], vecColor);
	}	
	
	iSBCanBePlaced[pOwner] = iBody	
	set_pev(SandBag, pev_angles, vecAngles);
	set_pev(SandBag, pev_body, iBody);
	set_pev(SandBag, pev_nextthink, get_gametime() + 0.01);
	
	return;
}


public ReturnMine(id)
{
	new tgt,body,Float:vo[3],Float:to[3];
	get_user_aiming(id,tgt,body);
	if(!pev_valid(tgt)) return;
	pev(id,pev_origin,vo);
	pev(tgt,pev_origin,to);
	if(get_distance_f(vo,to) > 100.0) return;
	new EntityName[32];
	pev(tgt, pev_classname, EntityName, 31);
	if(!equal(EntityName, ENT_CLASS_NAME)) return;
	if(pev(tgt,LASERMINE_OWNER) != id) return;
	iLaserMineHealth[id][g_havemine[id]]=float(pev(tgt,pev_health))
	g_havemine[id] ++;
	g_deployed[id] --;
	RemoveEntity(tgt);
	
	emit_sound(id, CHAN_ITEM, ENT_SOUND5, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	//client_cmd(id, "-dellaser")
	return;
}

public Spawn(id)
{
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
		
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);
	new gName[32]
	get_user_name(id,gName,charsmax(gName))
	// motor
	new i_Ent = engfunc(EngFunc_CreateNamedEntity,g_EntMine);
	if(!i_Ent)
	{
		ColorChat(id, GREEN,"[GC]^1 Can't Create Entity");
		return PLUGIN_HANDLED_MAIN;
	}
	set_pev(i_Ent,pev_classname,ENT_CLASS_NAME);

	engfunc(EngFunc_SetModel,i_Ent,ENT_MODELS);

	set_pev(i_Ent,pev_solid,SOLID_NOT);
	set_pev(i_Ent,pev_movetype,MOVETYPE_FLY);

	set_pev(i_Ent,pev_frame,0);
	set_pev(i_Ent,pev_body,3);
	set_pev(i_Ent,pev_sequence,TRIPMINE_WORLD);
	set_pev(i_Ent,pev_framerate,0);
	set_pev(i_Ent,pev_takedamage,DAMAGE_YES);
	set_pev(i_Ent,pev_dmg,100.0);
	set_pev(i_Ent,pev_health,iLaserMineHealth[id][g_havemine[id]-1])
	set_pev(i_Ent,pev_movetype,MOVETYPE_FLY)
	engfunc(EngFunc_SetSize, i_Ent, Float:{ -6.0, -6.0, 2.0 }, Float:{ 6.0, 6.0, 12.0 });
	//set_user_health(i_Ent,get_pcvar_num(g_LHEALTH));
	new Float:vOrigin[3];
	new	Float:vNewOrigin[3],Float:vNormal[3],	Float:vEntAngles[3]; 
	pev(id, pev_origin, vOrigin);
	
	/*velocity_by_aim(id, 192, vTraceDirection);
	xs_vec_add(vTraceDirection, vOrigin, vTraceEnd);
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, IGNORE_MONSTERS, id, 0);
	
	new Float:fFraction;	
	get_tr2(0, TR_flFraction, fFraction);	
	
	// -- We hit something!
	if(fFraction < 1.0)
	{
		// -- Save results to be used later.
		get_tr2(0, TR_vecEndPos, vTraceEnd);
		get_tr2(0, TR_vecPlaneNormal, vNormal);
	}

	xs_vec_mul_scalar(vNormal, 8192.0, vNormal);
	xs_vec_add(vTraceEnd, vNormal, vNewOrigin);*/
	GetOriginAimEndEyes(id, 128, vNewOrigin, vEntAngles,vNormal);
	engfunc(EngFunc_SetOrigin, i_Ent, vNewOrigin);

	// -- Rotate tripmine.
	/*vector_to_angle(vNormal,vEntAngles);*/
	set_pev(i_Ent,pev_angles,vEntAngles);
	
	//set_pev(SandBag,pev_flags, Fl_ONGROUND)
	//engfunc( EngFunc_DropToFloor, SandBag);
	
	

	// -- Calculate laser end origin.
	new Float:vBeamEnd[3], Float:vTracedBeamEnd[3];
		 
	xs_vec_mul_scalar(vNormal, 8192.0, vNormal);
	xs_vec_add(vNewOrigin, vNormal, vBeamEnd);

	new oldents[33], oldsolids[33], iHits, sizehits = sizeof oldents;
	new iHit=1;
	new tr3 = create_tr2();
	while( iHit > 0 )
	{
		engfunc(EngFunc_TraceLine, vNewOrigin, vBeamEnd, DONT_IGNORE_MONSTERS, i_Ent, tr3)
		iHit = get_tr2(tr3, TR_pHit);
		
		get_tr2(tr3, TR_vecEndPos, vNewOrigin)
		if( iHit > 0)
		{
			if(!is_user_alive(iHit))
			{
				if(pev_valid(iHit))
				{
					new classname[32]
					entity_get_string(iHit,EV_SZ_classname,classname,charsmax(classname))
					if(!equali(classname,"lasermine")&&!equali(classname,"amxx_pallets")&&!equali(classname,"rcbomb"))
						break;
				}
			}
			
			if( !(sizehits > iHits) ) break;
			oldents[iHits] = iHit;
			oldsolids[iHits] = pev(iHit, pev_solid);
			iHits ++;
			set_pev(iHit, pev_solid, SOLID_NOT)
			
		}
		
	}
	
	get_tr2(tr3, TR_vecPlaneNormal, vNormal);
	get_tr2(tr3, TR_vecEndPos, vTracedBeamEnd)
	free_tr2(tr3)
	
	// set back old solids....
	
	for(new i; i < iHits; i++)
	{
		set_pev(oldents[i], pev_solid, oldsolids[i])
	}
			/*
	engfunc(EngFunc_TraceLine, vNewOrigin, vBeamEnd, IGNORE_MONSTERS, i_Ent, 0);

	get_tr2(0, TR_vecPlaneNormal, vNormal);
	get_tr2(0, TR_vecEndPos, vTracedBeamEnd);*/

	// -- Save results to be used later.
	set_pev(i_Ent, LASERMINE_OWNER, id);
	set_pev(i_Ent,LASERMINE_BEAMENDPOINT,vTracedBeamEnd);
	set_pev(i_Ent,LASERMINE_TEAM,int:cs_get_user_team(id));
	new Float:fCurrTime = get_gametime();

	set_pev(i_Ent,LASERMINE_POWERUP, fCurrTime + 2.5);
	set_pev(i_Ent,LASERMINE_STEP,POWERUP_THINK);
	set_pev(i_Ent,pev_nextthink, fCurrTime + 0.2);

	PlaySound(i_Ent,POWERUP_SOUND);
	g_deployed[id]++;
	g_havemine[id]--;
	new iHealth = floatround(iLaserMineHealth[id][g_havemine[id]])
	new health = get_pcvar_num(g_LHEALTH),viphealth=get_pcvar_num(g_LHEALTH_VIP);
	if( iHealth <= health) 
	{
		set_rendering ( i_Ent, kRenderFxGlowShell, 255-255*iHealth/health, 255*iHealth/health, 0, kRenderNormal, 22)
	}
	else
	if( iHealth <= viphealth ) 
	{
		set_rendering ( i_Ent, kRenderFxGlowShell, 0,255-255*(iHealth-health)/(viphealth-health),255*(iHealth-health)/(viphealth-health), kRenderNormal, 22)
	}		
			
	client_print(0,print_console,"[GC] %s Has Placed a Lasermine", gName)
	//ColorChat(0,GREEN,"[GC | Mines]^01 %s ^03 Has Placed a Lasermine", gName)
	return 1;
}

public ltm_Think(i_Ent)
{
	if(!pev_valid(i_Ent))
		return FMRES_IGNORED;
	new EntityName[32];
	pev(i_Ent, pev_classname, EntityName, 31);
	if(!get_pcvar_num(g_LENABLE)) return FMRES_IGNORED;
	// -- Entity is not a tripmine, ignoring the next...
	if(!equal(EntityName, ENT_CLASS_NAME))
		return FMRES_IGNORED;

	static Float:fCurrTime;
	fCurrTime = get_gametime();

	switch(pev(i_Ent, LASERMINE_STEP))
	{
		case POWERUP_THINK :
		{
			new Float:fPowerupTime;
			pev(i_Ent, LASERMINE_POWERUP, fPowerupTime);

			if(fCurrTime > fPowerupTime)
			{
				set_pev(i_Ent, pev_solid, SOLID_BBOX);
				set_pev(i_Ent, LASERMINE_STEP, BEAMBREAK_THINK);

				PlaySound(i_Ent, ACTIVATE_SOUND);
			}
			set_pev(i_Ent, pev_nextthink, fCurrTime + 0.1);
		}
		case BEAMBREAK_THINK :
		{
			static Float:vEnd[3],Float:vOrigin[3],Float:vOriginalOrigin[3]
			
			pev(i_Ent, pev_origin, vOrigin);
			
			vOriginalOrigin[0]=vOrigin[0]
			vOriginalOrigin[1]=vOrigin[1]
			vOriginalOrigin[2]=vOrigin[2]
			
			pev(i_Ent, LASERMINE_BEAMENDPOINT, vEnd);
			
			new oldents[33], oldsolids[33], iHits, sizehits = sizeof oldents;
			new iHit=1;
			new tr3 = create_tr2();
			while( iHit > 0 )
			{
				engfunc(EngFunc_TraceLine, vOrigin, vEnd, DONT_IGNORE_MONSTERS, i_Ent, tr3)
				iHit = get_tr2(tr3, TR_pHit);
				
				get_tr2(tr3, TR_vecEndPos, vOrigin)
				if( iHit > 0)
				{
					if(is_user_alive(iHit))
					{
						if(zp_core_is_zombie(iHit))
						{
							CreateLaserDamage(i_Ent,iHit)
							break;
						}
					}
					else
					{
						if(pev_valid(iHit))
						{
							new classname[32]
							entity_get_string(iHit,EV_SZ_classname,classname,charsmax(classname))
							if(!equali(classname,"lasermine")&&!equali(classname,"amxx_pallets")&&!equali(classname,"rcbomb"))
								break;
						}
					}
					
					if( !(sizehits > iHits) ) break;
					oldents[iHits] = iHit;
					oldsolids[iHits] = pev(iHit, pev_solid);
					iHits ++;
					set_pev(iHit, pev_solid, SOLID_NOT)
					
				}
				
			}
			
			free_tr2(tr3)
			
			// set back old solids....
			
			for(new i; i < iHits; i++)
			{
				set_pev(oldents[i], pev_solid, oldsolids[i])
			}
			
			//client_print(0,print_chat,"%d",iHits);
			if(get_pcvar_num(g_LDMGMODE)!=0)
				if(pev(i_Ent,LASERMINE_HITING) != iHit)
					set_pev(i_Ent,LASERMINE_HITING,iHit);
 
			// -- Tripmine is still there.
			if(pev_valid(i_Ent))
			{
				static Float:fHealth;
				pev(i_Ent, pev_health, fHealth);

				if(fHealth <= 0.0 || (pev(i_Ent,pev_flags) & FL_KILLME))
				{
				set_pev(i_Ent, LASERMINE_STEP, EXPLOSE_THINK);
				set_pev(i_Ent, pev_nextthink, fCurrTime + random_float(0.1, 0.3));
				}
										 
				static Float:fBeamthink;
				pev(i_Ent, LASERMINE_BEAMTHINK, fBeamthink);
						 
				if(fBeamthink < fCurrTime )
				{
					DrawLaser(vOriginalOrigin, vOrigin);
					set_pev(i_Ent, LASERMINE_BEAMTHINK, fCurrTime + 0.1);
				}
				set_pev(i_Ent, pev_nextthink, fCurrTime + 0.01);
			}
		}/*
		case BEAMBREAK_THINK :
		{
			static Float:vEnd[3],Float:vOrigin[3];
			pev(i_Ent, pev_origin, vOrigin);
			pev(i_Ent, LASERMINE_BEAMENDPOINT, vEnd);

			static iHit, Float:fFraction, Trace_Result;
			//engfunc(EngFunc_TraceLine, vOrigin, vEnd, DONT_IGNORE_MONSTERS, i_Ent, 0);
			
			engfunc(EngFunc_TraceLine, vOrigin, vEnd, DONT_IGNORE_MONSTERS, i_Ent, Trace_Result);
			get_tr2(Trace_Result, TR_flFraction, fFraction);
			iHit = get_tr2(Trace_Result, TR_pHit);

			// -- Something has passed the laser.
			if(fFraction < 1.0)
			{
				get_tr2(Trace_Result, TR_vecEndPos, vEnd)
				// -- Ignoring others tripmines entity.
				if(pev_valid(iHit))
				{
					pev(iHit, pev_classname, EntityName, 31);
					// Игнорим всякую хрень
					if(is_user_alive(iHit))
					{
						set_pev(i_Ent, pev_enemy, iHit);

						CreateLaserDamage(i_Ent,iHit);

						if (!pev_valid(i_Ent))	// если не верный объект - ничего не делаем. Спасибо DJ_WEST
							return FMRES_IGNORED;

						set_pev(i_Ent, pev_nextthink, fCurrTime + random_float(0.1, 0.3));
					}
				}
			}
			if(get_pcvar_num(g_LDMGMODE)!=0)
				if(pev(i_Ent,LASERMINE_HITING) != iHit)
					set_pev(i_Ent,LASERMINE_HITING,iHit);
 
			// -- Tripmine is still there.
			if(pev_valid(i_Ent))
			{
				static Float:fHealth;
				pev(i_Ent, pev_health, fHealth);

				if(fHealth <= 0.0 || (pev(i_Ent,pev_flags) & FL_KILLME))
				{
				set_pev(i_Ent, LASERMINE_STEP, EXPLOSE_THINK);
				set_pev(i_Ent, pev_nextthink, fCurrTime + random_float(0.1, 0.3));
				}
										 
				static Float:fBeamthink;
				pev(i_Ent, LASERMINE_BEAMTHINK, fBeamthink);
						 
				if(fBeamthink < fCurrTime )
				{
					DrawLaser(vOrigin, vEnd);
					set_pev(i_Ent, LASERMINE_BEAMTHINK, fCurrTime + 0.1);
				}
				set_pev(i_Ent, pev_nextthink, fCurrTime + 0.01);
			}
		}*/
		case EXPLOSE_THINK :
		{
			// -- Stopping entity to think
			set_pev(i_Ent, pev_nextthink, 0.0);
			PlaySound(i_Ent, STOP_SOUND);
			g_deployed[pev(i_Ent,LASERMINE_OWNER)]--;
			CreateExplosion(i_Ent);
			CreateDamage(i_Ent,get_pcvar_float(g_LRDMG),get_pcvar_float(g_LRADIUS))
			RemoveEntity(i_Ent);
		}
	}

	return FMRES_IGNORED;
}

PlaySound(i_Ent, i_SoundType)
{
	switch (i_SoundType)
	{
		case POWERUP_SOUND :
		{
			emit_sound(i_Ent, CHAN_VOICE, ENT_SOUND1, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			emit_sound(i_Ent, CHAN_BODY , ENT_SOUND2, 0.2, ATTN_NORM, 0, PITCH_NORM);
		}
		case ACTIVATE_SOUND :
		{
			emit_sound(i_Ent, CHAN_VOICE, ENT_SOUND3, 0.5, ATTN_NORM, 1, 75);
		}
		case STOP_SOUND :
		{
			emit_sound(i_Ent, CHAN_BODY , ENT_SOUND2, 0.2, ATTN_NORM, SND_STOP, PITCH_NORM);
			emit_sound(i_Ent, CHAN_VOICE, ENT_SOUND3, 0.5, ATTN_NORM, SND_STOP, 75);
		}
	}
}

DrawLaser(const Float:v_Origin[3], const Float:v_EndOrigin[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord,v_Origin[0]);
	engfunc(EngFunc_WriteCoord,v_Origin[1]);
	engfunc(EngFunc_WriteCoord,v_Origin[2]);
	engfunc(EngFunc_WriteCoord,v_EndOrigin[0]); //Random
	engfunc(EngFunc_WriteCoord,v_EndOrigin[1]); //Random
	engfunc(EngFunc_WriteCoord,v_EndOrigin[2]); //Random
	write_short(beam);
	write_byte(0);
	write_byte(0);
	write_byte(1);	//Life
	write_byte(5);	//Width
	write_byte(0);	//wave
	write_byte(255); // r
	write_byte(0); // g
	write_byte(0); // b
	write_byte(255);
	write_byte(255);
	message_end();
	//client_print(0, print_chat, "%f %f %f to %f %f %f",v_Origin[0],v_Origin[1],v_Origin[2],v_EndOrigin[0],v_EndOrigin[1],v_EndOrigin[2])
}

CreateDamage(iCurrent,Float:DmgMAX,Float:Radius)
{
	// Get given parameters
	new Float:vecSrc[3];
	pev(iCurrent, pev_origin, vecSrc);

	new AtkID =pev(iCurrent,LASERMINE_OWNER);
	
	new ent = -1;
	new Float:tmpdmg = DmgMAX;

	new Float:kickback = 0.0;
	// Needed for doing some nice calculations :P
	new Float:Tabsmin[3], Float:Tabsmax[3];
	new Float:vecSpot[3];
	new Float:Aabsmin[3], Float:Aabsmax[3];
	new Float:vecSee[3];
	new trRes;
	new Float:flFraction;
	new Float:vecEndPos[3];
	new Float:distance;
	new Float:origin[3], Float:vecPush[3];
	new Float:invlen;
	new Float:velocity[3];
	// Calculate falloff
	new Float:falloff;
	if(Radius > 0.0)
	{
		falloff = DmgMAX / Radius;
	} else {
		falloff = 1.0;
	}
	// Find monsters and players inside a specifiec radius
	while((ent = engfunc(EngFunc_FindEntityInSphere, ent, vecSrc, Radius)) != 0)
	{
		if(!pev_valid(ent)) continue;
		if(!(pev(ent, pev_flags) & (FL_CLIENT | FL_FAKECLIENT | FL_MONSTER)))
		{
			// Entity is not a player or monster, ignore it
			continue;
		}
		if(!pev_user_alive(ent)) continue;
		if(!zp_core_is_zombie(ent))continue;
		// Reset data
		kickback = 1.0;
		tmpdmg = DmgMAX;
		// The following calculations are provided by Orangutanz, THANKS!
		// We use absmin and absmax for the most accurate information
		pev(ent, pev_absmin, Tabsmin);
		pev(ent, pev_absmax, Tabsmax);
		xs_vec_add(Tabsmin,Tabsmax,Tabsmin);
		xs_vec_mul_scalar(Tabsmin,0.5,vecSpot);
		pev(iCurrent, pev_absmin, Aabsmin);
		pev(iCurrent, pev_absmax, Aabsmax);
		xs_vec_add(Aabsmin,Aabsmax,Aabsmin);
		xs_vec_mul_scalar(Aabsmin,0.5,vecSee);
		engfunc(EngFunc_TraceLine, vecSee, vecSpot, 0, iCurrent, trRes);
		get_tr2(trRes, TR_flFraction, flFraction);
		// Explosion can 'see' this entity, so hurt them! (or impact through objects has been enabled xD)
		if(flFraction >= 0.9 || get_tr2(trRes, TR_pHit) == ent)
		{
			// Work out the distance between impact and entity
			get_tr2(trRes, TR_vecEndPos, vecEndPos);
			distance = get_distance_f(vecSrc, vecEndPos) * falloff;
			tmpdmg -= distance;
			if(tmpdmg < 0.0)
				tmpdmg = 0.0;
			ExecuteHamB(Ham_TakeDamage, ent, LaserEnt, AtkID, tmpdmg, DMG_GRENADE)
			// Kickback Effect
			if(kickback != 0.0)
			{
				xs_vec_sub(vecSpot,vecSee,origin);
				invlen = 1.0/get_distance_f(vecSpot, vecSee);

				xs_vec_mul_scalar(origin,invlen,vecPush);
				pev(ent, pev_velocity, velocity)
				xs_vec_mul_scalar(vecPush,tmpdmg,vecPush);
				xs_vec_mul_scalar(vecPush,kickback,vecPush);
				xs_vec_add(velocity,vecPush,velocity);
				if(tmpdmg < 60.0)
				{
					xs_vec_mul_scalar(velocity,12.0,velocity);
				} else {
					xs_vec_mul_scalar(velocity,4.0,velocity);
				}
				if(velocity[0] != 0.0 || velocity[1] != 0.0 || velocity[2] != 0.0)
				{
					// There's some movement todo :)
					set_pev(ent, pev_velocity, velocity)
				}
			}
		}
	}
	return
}

bool:pev_user_alive(ent)
{
	new deadflag = pev(ent,pev_deadflag);
	if(deadflag != DEAD_NO)
		return false;
	return true;
}

CreateExplosion(iCurrent)
{
	new Float:vOrigin[3];
	pev(iCurrent,pev_origin,vOrigin);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(99); //99 = KillBeam
	write_short(iCurrent);
	message_end();

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord,vOrigin[0]);
	engfunc(EngFunc_WriteCoord,vOrigin[1]);
	engfunc(EngFunc_WriteCoord,vOrigin[2]);
	write_short(boom);
	write_byte(30);
	write_byte(15);
	write_byte(0);
	message_end();
}

CreateLaserDamage(iCurrent,isHit)
{
	if(isHit < 0) return PLUGIN_CONTINUE
	switch(get_pcvar_num(g_LDMGMODE))
	{
		case 1:
		{
			if(pev(iCurrent,LASERMINE_HITING) == isHit)
				return PLUGIN_CONTINUE
		}
		case 2:
		{
			//if(pev(iCurrent,LASERMINE_HITING) == isHit)
		//	{
				static Float:now;
				static Float:htime;
				now = get_gametime()

				pev(iCurrent,LASERMINE_COUNT,htime)
				if(now - htime < get_pcvar_float(g_LDSEC))
				{
					return PLUGIN_CONTINUE;
				}else{
					set_pev(iCurrent,LASERMINE_COUNT,now)
				}
			/*}else
			{
				set_pev(iCurrent,LASERMINE_COUNT,get_gametime())
			}*/
		}
	}

	new id
	id = pev(iCurrent,LASERMINE_OWNER)//, szNetName[32]
	if(is_user_connected(id))
	{
		if(is_user_alive(isHit))
		{
			if(!zp_grenade_frost_get(isHit)&&zp_core_is_zombie(isHit) && !zp_item_zombie_madness_get(isHit))
			{
				ExecuteHamB(Ham_TakeDamage, isHit, LaserEnt, id, get_pcvar_float(g_LDMG), DMG_GRENADE)
				emit_sound(isHit, CHAN_WEAPON, ENT_SOUND4, 1.0, ATTN_NORM, 0, PITCH_NORM)
				bd_show_damage(id,get_pcvar_num(g_LDMG),1,1)
				bd_show_damage(isHit,get_pcvar_num(g_LDMG),1,0)
			}
		}
	}
	return PLUGIN_CONTINUE
}

create_custom_entity(const weaponDescription[])
{
    new iEnt = create_entity("info_target")
    if( iEnt > 0 )
    {
        set_pev(iEnt, pev_classname, weaponDescription)
    }
    return iEnt
} 

stock pev_user_health(id)
{
	new Float:health
	pev(id,pev_health,health)
	return floatround(health)
}

stock set_user_health(id,health)
{
	health > 0 ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);
}

stock get_user_godmode(index) {
	new Float:val
	pev(index, pev_takedamage, val)

	return (val == DAMAGE_NO)
}

stock set_user_frags(index, frags)
{
	set_pev(index, pev_frags, float(frags))

	return 1
}

stock pev_user_frags(index)
{
	new Float:frags;
	pev(index,pev_frags,frags);
	return floatround(frags);
}

/*
public AddDistance(id)
{
	if(g_havemine[id] < 1)
		return;

	ipDistance[id] += 25

	if(ipDistance[id] >= 300)
		ipDistance[id] = 300
}
public RemoveDistance(id)
{
	if(g_havemine[id] < 1)
		return;

	ipDistance[id] -= 25

	if(ipDistance[id] <= 100)
		ipDistance[id] = 100
}*/
// public zv_extra_item_selected(id, itemid)
// {
// 	if (itemid != g_LME_vip)
// 	return;
	
		
// 	if(zpv_is_user_vip(id))
// 	iLaserMineHealth[id][g_havemine[id]] = get_pcvar_float(g_LHEALTH_VIP)
// 	else
// 		iLaserMineHealth[id][g_havemine[id]] = get_pcvar_float(g_LHEALTH)
		
// 	g_havemine[id]++;
	
// 	ColorChat(id, GREEN,"[GC]^03You just bought a ^04Laser Mine^03. Type ^04/lm^03 to open this menu again.")
// 	emit_sound(id, CHAN_ITEM, ENT_SOUND5, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
// 	Lasermenu_LgK(id)
// }

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_LME)
		return ZP_ITEM_AVAILABLE;
	
	// Antidote only available to zombies
	if (zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW;
	
	if(zp_class_survivor_get(id)||zp_class_sniper_get(id)||zp_class_plasma_get(id)||zp_class_knifer_get(id))
		return ZP_ITEM_DONT_SHOW
	
	//Antidote only available during infection modes
	new current_mode = zp_gamemodes_get_current()
	if (current_mode==Swarm||current_mode==Plague||current_mode == g_GameModeArma||current_mode == Nemesis||current_mode == Dragon||current_mode == Nightcrawler||current_mode == Predator||zp_gamemodes_get_current()==ZP_NO_GAME_MODE)
		return ZP_ITEM_DONT_SHOW;
		
	if(zv_get_user_flags(id)&ZV_MAIN)
	{
		if(Bought[id])
		{				
			if(zp_bought_vip_item_get(id))
			{					
				return ZP_ITEM_NOT_AVAILABLE;
			}
			
			zp_items_menu_text_add("[1/2]")
			return ZP_ITEM_AVAILABLE;
		}
		if(zp_bought_vip_item_get(id))
		zp_items_menu_text_add("[0/1]")
		else
		zp_items_menu_text_add("[0/2]")
		return ZP_ITEM_AVAILABLE
	}

	if(Bought[id])
	{
		zp_items_menu_text_add("[1/2] \r[VIP]")
		return ZP_ITEM_NOT_AVAILABLE;
	}
	
	zp_items_menu_text_add("[0/1]")
		
	return ZP_ITEM_AVAILABLE;
}
public zp_fw_items_select_post(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_LME)
	return;
	
	if(zpv_is_user_vip(id))
		iLaserMineHealth[id][g_havemine[id]] = get_pcvar_float(g_LHEALTH_VIP)
	else
	iLaserMineHealth[id][g_havemine[id]] = get_pcvar_float(g_LHEALTH)
		
	g_havemine[id]++;
	if(Bought[id])
	{
		zp_bought_vip_item_set(id)
	}
	else
	{
		Bought[id]=true;
	}
	
	ColorChat(id, GREEN,"[GC]^03You just bought a ^04Laser Mine^03. Type ^04/lm^03 to open this menu again.")
	emit_sound(id, CHAN_ITEM, ENT_SOUND5, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	Lasermenu_LgK(id)
}

public client_putinserver(id){
	g_deployed[id] = 0;
	g_havemine[id] = 0;
	//ipDistance[id] = 100
	return PLUGIN_CONTINUE
}

public client_disconnecteded(id){
	if(!get_pcvar_num(g_LENABLE))
		return PLUGIN_CONTINUE
	RemoveAllTripmines(id);
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
	
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);
	return PLUGIN_CONTINUE
}

public RemoveAllTripmines(i_Owner)
{
	new iEnt = g_MaxPL + 1;
	new clsname[32];
	while((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", ENT_CLASS_NAME)))
	{
		if(i_Owner)
		{
			if(pev(iEnt, LASERMINE_OWNER) != i_Owner)
				continue;
			clsname[0] = '^0'
			pev(iEnt, pev_classname, clsname, sizeof(clsname)-1);
			if(equali(clsname, ENT_CLASS_NAME))
			{
				PlaySound(iEnt, STOP_SOUND);
				RemoveEntity(iEnt);
			}
		}
		else
			set_pev(iEnt, pev_flags, FL_KILLME);
	}
	g_deployed[i_Owner]=0;
}

get_offset_value(id, type)
{
	new key = -1;
	switch(type)
	{
		case OFFSET_TEAM: key = OFFSET_TEAM;
		case OFFSET_MONEY:
		key = OFFSET_MONEY;
		case OFFSET_DEATH: key = OFFSET_DEATH;
	}
	if(key != -1)
	{
		return get_pdata_int(id, key);
	}
	return -1;
}
public event_newround() 
{
	if(!get_pcvar_num(g_LENABLE))
		return PLUGIN_CONTINUE
		 
	for ( new id; id <= get_maxplayers(); id++) 
	{ 
		g_havemine[id] = 0
		RemoveAllTripmines(id);
		g_deployed[id]=0
		Bought[id]=false
		DamageDealt[id] = 0.0
	} 
	
	return PLUGIN_CONTINUE;
} 

bool:IsHullVacant(const Float:vecSrc[3], iHull, pEntToSkip = 0)
{
	engfunc(EngFunc_TraceHull, vecSrc, vecSrc, DONT_IGNORE_MONSTERS, iHull, pEntToSkip, 0);
	return bool:(!get_tr2(0, TR_AllSolid) && !get_tr2(0, TR_StartSolid) && get_tr2(0, TR_InOpen));
}


public zp_fw_core_infect(id)
{
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
	
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);	
}

public zp_fw_core_cure(id)
{
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
	
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);
}
/*
GetOriginAimEndEyes(this, iDistance, Float:vecOut[3], Float:vecAngles[3])
{
	static Float:vecSrc[3], Float:vecEnd[3], Float:vecViewOfs[3], Float:vecVelocity[3];
	static Float:flFraction, Float:vecPlaneNormal[3];

	pev(this, pev_origin, vecSrc);
	pev(this, pev_view_ofs, vecViewOfs);

	xs_vec_add(vecSrc, vecViewOfs, vecSrc);
	velocity_by_aim(this, iDistance, vecVelocity);
	xs_vec_add(vecSrc, vecVelocity, vecEnd);

	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, this, 0);
	
	get_tr2(0, TR_flFraction, flFraction);
	
	get_tr2(0, TR_PlaneNormal, vecPlaneNormal);
	get_tr2(0, TR_vecEndPos, vecOut);
	
	new hitwall,iHit
	iHit=get_tr2(0, TR_pHit)	
	
	if(flFraction < 1.0)
	{
		hitwall=true;
	}
	
	if(pev_valid(iHit))
	{
		new classname[32]
		entity_get_string(iHit,EV_SZ_classname,classname,charsmax(classname))
		if(equali(classname,"lasermine")||equali(classname,"amxx_pallets"))
		{
			hitwall=false;
		}	
	}
	
	
	xs_vec_mul_scalar(vecPlaneNormal, 8.0, vecPlaneNormal);
	xs_vec_add(vecOut, vecPlaneNormal, vecOut);

	//vecVelocity[2] = 0.0;
	vector_to_angle(vecPlaneNormal, vecAngles);
	return hitwall;
}*/


GetOriginAimEndEyes(this, iDistance, Float:vecOut[3], Float:vecAngles[3],Float:vecPlaneNormal[3]={0.0,0.0,0.0})
{
	static Float:vecSrc[3], Float:vecEnd[3], Float:vecViewOfs[3], Float:vecVelocity[3];
	static Float:flFraction

	pev(this, pev_origin, vecSrc);
	pev(this, pev_view_ofs, vecViewOfs);

	xs_vec_add(vecSrc, vecViewOfs, vecSrc);
	velocity_by_aim(this, iDistance, vecVelocity);
	xs_vec_add(vecSrc, vecVelocity, vecEnd);
	new oldents[33], oldsolids[33], iHits, sizehits = sizeof oldents;
	new iHit=1;
	new tr3 = create_tr2();
	while( iHit > 0 )
	{
		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, this, tr3)
		iHit = get_tr2(tr3, TR_pHit);
		
		get_tr2(tr3, TR_vecEndPos, vecSrc)
		
		if( iHit > 0)
		{
			if(!is_user_alive(iHit))
			{
				if(pev_valid(iHit))
				{
					new classname[32]
					entity_get_string(iHit,EV_SZ_classname,classname,charsmax(classname))
					if(equali(classname,"amxx_pallets")||equali(classname,"lasermine")||equali(classname,"rcbomb"))
					{						
						if( !(sizehits > iHits) ) break;
						oldents[iHits] = iHit;
						oldsolids[iHits] = pev(iHit, pev_solid);
						iHits ++;
						set_pev(iHit, pev_solid, SOLID_NOT)
					}
					else
					break;
				}
				else
				break;
			}	
			else
			{
				if( !(sizehits > iHits) ) break;
				oldents[iHits] = iHit;
				oldsolids[iHits] = pev(iHit, pev_solid);
				iHits ++;
				set_pev(iHit, pev_solid, SOLID_NOT)
			}
		}	
	}
	
	get_tr2(tr3, TR_flFraction, flFraction);	
	
	get_tr2(tr3, TR_PlaneNormal, vecPlaneNormal);
	
	// set back old solids....
	
	for(new i; i < iHits; i++)
	{
		set_pev(oldents[i], pev_solid, oldsolids[i])
	}	
	
	new hitwall;
	if (flFraction < 1.0)
	{
		static Float:vecPlaneNormal[3];

		get_tr2(tr3, TR_PlaneNormal, vecPlaneNormal);
		get_tr2(tr3, TR_vecEndPos, vecOut);


		xs_vec_mul_scalar(vecPlaneNormal, 1.0, vecPlaneNormal);
		xs_vec_add(vecOut, vecPlaneNormal, vecOut);
		hitwall=true;
	}
	else
	{
		xs_vec_copy(vecEnd, vecOut);
	}
	
	free_tr2(tr3)
	//vecVelocity[2] = 0.0;
	
	xs_vec_mul_scalar(vecPlaneNormal, 8.0, vecPlaneNormal);
	xs_vec_add(vecOut, vecPlaneNormal, vecOut);

	//vecVelocity[2] = 0.0;
	vector_to_angle(vecPlaneNormal, vecAngles);
	return hitwall;
}

public CheckSandBag(id,sb)
{
	static victim
	victim = -1
	while ( ( victim = find_ent_in_sphere(victim,ivecOrigin,15.0)) != 0 )
	{
		if(victim==sb)
		continue;
		
		/*if( is_user_alive(victim)&&victim!=id&&!zp_core_is_zombie(victim))
			return false; 		*/
		
		if(pev_valid(victim))
		{
			static classname[32]
			entity_get_string(victim,EV_SZ_classname,classname,charsmax(classname))
			if(equal(classname,"func_door")||equal(classname,"func_train"))
				return false;
		}
	}
	return true;
}

FClassnameIs(this, const szClassName[])
{
	if (pev_valid(this) != 2)
		return 0;

	new szpClassName[32];
	pev(this, pev_classname, szpClassName, charsmax(szpClassName));

	return equal(szClassName, szpClassName);
}

public CheckPlant(taskid)
{

	new id = taskid-TASK_PLANT
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
	if(zp_core_is_zombie(id))
		return PLUGIN_HANDLED;
	if(!g_havemine[id])
	{
		ColorChat(id, GREEN, "[GC]^03 You don't have any lasermines!!")
		return PLUGIN_HANDLED;
	}
	if(iSBCanBePlaced[id] == 5)
	{
		Lasermenu_LgK2(id); 
		ColorChat(id, GREEN, "[GC]^03 Lasermines can't be placed here!")
		return PLUGIN_CONTINUE;
	}
	
	if(zp_gamemodes_get_current()!=ZP_NO_GAME_MODE)
	{								
		Spawn(id)					
		//Lasermenu_LgK2(id)					
	}
	else
	ColorChat(id, GREEN,"[GC]^03Lasermines can be placed only in infection modes.")	
			
	return PLUGIN_CONTINUE;
}


public CreateLaserMine_Progress_b(id) //+setlaser
{	
	
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
	if(zp_core_is_zombie(id))
		return PLUGIN_HANDLED;
		
	if(g_havemine[id])
	{
		CreateFakeSandBag(id)
		set_task(1.2,"CheckPlant",TASK_PLANT+id);
		message_begin( MSG_ONE, 108, {0,0,0}, id );
		write_byte(1);
		write_byte(0);
		message_end();
		
	}
	else
	if((zp_items_get_purchases(g_LME)>=zp_items_get_limit(g_LME)&&zp_items_get_limit(g_LME))||((zp_items_get_player_purchases(g_LME,id)>=zp_items_get_player_limit(g_LME)&&zp_items_get_player_limit(g_LME)))&&(zpv_is_user_vip(id)&&zp_items_get_player_purchases(g_LME,id)>=zp_items_get_vip_limit(g_LME)&&zp_items_get_vip_limit(g_LME)))
	{				
		Lasermenu_LgK2(id);
	}
	else
	{
		zp_items_force_buy(id, g_LME)				
	}
	return PLUGIN_HANDLED;
}

public ReturnLaserMine_Progress(id) //+dellaser
{
	
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
	if(zp_core_is_zombie(id))
		return PLUGIN_HANDLED;
		
	Destroy(id);
	
	new tgt,body,Float:vo[3],Float:to[3];
	get_user_aiming(id,tgt,body);
	if(!pev_valid(tgt)) return PLUGIN_HANDLED;
	pev(id,pev_origin,vo);
	pev(tgt,pev_origin,to);
	if(get_distance_f(vo,to) > 100.0) return PLUGIN_HANDLED;
	new EntityName[32];
	pev(tgt, pev_classname, EntityName, 31);
	if(!equal(EntityName, ENT_CLASS_NAME)) return PLUGIN_HANDLED;
	if(pev(tgt,LASERMINE_OWNER) != id)return PLUGIN_HANDLED;
	lm_show_progress(id);
	set_task(1.0,"CheckRemove",TASK_RELEASE+id)
	//client_cmd(id, "-dellaser")
	return PLUGIN_HANDLED;
}

public CheckRemove(taskid)
{
	
		
	new id = taskid-TASK_RELEASE
	
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
	if(zp_core_is_zombie(id))
		return PLUGIN_HANDLED;
	Destroy(id);
	
	new tgt,body,Float:vo[3],Float:to[3];
	get_user_aiming(id,tgt,body);
	if(!pev_valid(tgt)) return PLUGIN_HANDLED;
	pev(id,pev_origin,vo);
	pev(tgt,pev_origin,to);
	if(get_distance_f(vo,to) > 100.0) return PLUGIN_HANDLED;
	new EntityName[32];
	pev(tgt, pev_classname, EntityName, 31);
	if(!equal(EntityName, ENT_CLASS_NAME)) return PLUGIN_HANDLED;
	if(pev(tgt,LASERMINE_OWNER) != id) return PLUGIN_HANDLED;

	iLaserMineHealth[id][g_havemine[id]]=float(pev(tgt,pev_health))
	g_havemine[id] ++;
	g_deployed[id] --;
	RemoveEntity(tgt);
	
	emit_sound(id, CHAN_ITEM, ENT_SOUND5, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	return PLUGIN_HANDLED;
}

public StopCreateLaserMine(id) //-setlaser
{
	
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
	if(zp_core_is_zombie(id))
		return PLUGIN_HANDLED;
		
	if(task_exists(TASK_PLANT+id))
	{
		Destroy(id);
		remove_task(id+TASK_PLANT);
		lm_hide_progress(id)
	}
	return PLUGIN_HANDLED;
}

   public StopReturnLaserMine(id)
   {
   	
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
   	if(zp_core_is_zombie(id))
		return PLUGIN_HANDLED;
		
   	if(task_exists(TASK_RELEASE+id))
	{
		remove_task(TASK_RELEASE+id)
		lm_hide_progress(id);
	}
	return PLUGIN_HANDLED;
   }

//====================================================
// Show Progress Bar.
//====================================================
stock lm_show_progress(id)
{
	if (pev_valid(id))
	{
		engfunc(EngFunc_MessageBegin, MSG_ONE,  gMsgBarTime, {0,0,0}, id);
		write_short(1);
		message_end();
	}
}

//====================================================
// Hide Progress Bar.
//====================================================
stock lm_hide_progress(id)
{
	if (pev_valid(id))
	{
		engfunc(EngFunc_MessageBegin, MSG_ONE, gMsgBarTime, {0,0,0}, id);
		write_short(0);
		message_end();
	}
}

public zpv_is_user_vip(id)
{
	if(zv_get_user_flags(id)&ZV_MAIN)
	{
		return true;
	}
	return false;
}

/*
public Lasermenu_LgK( id )
{	
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
	
	if(zp_core_is_zombie(id))
		return PLUGIN_HANDLED;
		
	new menu_id = menu_create("[GC | Lasermine]","lgk_lm_handler")
	if(!g_havemine[id]&&!g_deployed[id])
	{
		zp_items_force_buy(id, g_LME);
		return PLUGIN_HANDLED;
	}
	new text[34]
	if(g_havemine[id])
	{
		formatex(text,charsmax(text),"Place a Lasermine [%d / %d]",g_deployed[id],g_havemine[id]+g_deployed[id])
		menu_additem(menu_id,text,"",0)
		CreateFakeSandBag(id)	
	}
	else	
	if((zp_items_get_purchases(g_LME)>=zp_items_get_limit(g_LME)&&zp_items_get_limit(g_LME)))
	{
		formatex(text,charsmax(text),"\dBuy a Lasermine [%d / %d]",zp_items_get_purchases(g_LME),zp_items_get_limit(g_LME))
		menu_additem(menu_id,text,"",0)
	}
	else
	if(!zpv_is_user_vip(id))
	{	
		if(zp_items_get_player_purchases(g_LME,id)>=zp_items_get_player_limit(g_LME)&&zp_items_get_player_limit(g_LME))
		{
			if(zp_items_get_player_limit(g_LME)<zp_items_get_vip_limit(g_LME))
			formatex(text,charsmax(text),"\dBuy a Lasermine [%d / %d] \y[VIP]",zp_items_get_player_purchases(g_LME,id),zp_items_get_vip_limit(g_LME))
			else
			if(!zp_items_get_vip_limit(g_LME))
			formatex(text,charsmax(text),"\dBuy a Lasermine \y[VIP]")
			else
			formatex(text,charsmax(text),"\dBuy a Lasermine [%d / %d]",zp_items_get_player_purchases(g_LME,id),zp_items_get_vip_limit(g_LME))
			
			menu_additem(menu_id,text,"",0)
		}
		else
		{
			formatex(text,charsmax(text),"Buy a Lasermine [%d / %d]",zp_items_get_player_purchases(g_LME,id),zp_items_get_player_limit(g_LME))
			menu_additem(menu_id,text,"",0)
		}
	}
	else
	{
		if(zp_items_get_player_purchases(g_LME,id)>=zp_items_get_vip_limit(g_LME)&&zp_items_get_vip_limit(g_LME))
		{
			formatex(text,charsmax(text),"\dBuy a Lasermine [%d / %d]",zp_items_get_player_purchases(g_LME,id),zp_items_get_vip_limit(g_LME))
			menu_additem(menu_id,text,"",0)
		}
		else
		{
			formatex(text,charsmax(text),"Buy a Lasermine [%d / %d]",zp_items_get_player_purchases(g_LME,id),zp_items_get_vip_limit(g_LME))
			menu_additem(menu_id,text,"",0)
		}
	}
	

	menu_additem(menu_id,"Takeback a Lasermine","",0)

	menu_setprop(menu_id, MPROP_EXIT, MEXIT_ALL );
	menu_display(id, menu_id, 0 );
	return PLUGIN_HANDLED;
}

public Lasermenu_LgK2( id )
{	
	if(!is_user_alive(id))
		return;
	
	if(zp_core_is_zombie(id))
		return;
		
	new menu_id = menu_create("[GC | Lasermine]","lgk_lm_handler")
	new text[34]
	if(g_havemine[id])
	{
		formatex(text,charsmax(text),"Place a Lasermine [%d / %d]",g_deployed[id],g_havemine[id]+g_deployed[id])
		menu_additem(menu_id,text,"",0)
		Lasermenu_LgK(id);
	}
	else	
	if((zp_items_get_purchases(g_LME)>=zp_items_get_limit(g_LME)&&zp_items_get_limit(g_LME)))
	{
		formatex(text,charsmax(text),"\dBuy a Lasermine [%d / %d]",zp_items_get_purchases(g_LME),zp_items_get_limit(g_LME))
		menu_additem(menu_id,text,"",0)
	}
	else
	if(!zpv_is_user_vip(id))
	{	
		if(zp_items_get_player_purchases(g_LME,id)>=zp_items_get_player_limit(g_LME)&&zp_items_get_player_limit(g_LME))
		{
			if(zp_items_get_player_limit(g_LME)<zp_items_get_vip_limit(g_LME))
			formatex(text,charsmax(text),"\dBuy a Lasermine [%d / %d] \y[VIP]",zp_items_get_player_purchases(g_LME,id),zp_items_get_vip_limit(g_LME))
			else
			if(!zp_items_get_vip_limit(g_LME))
			formatex(text,charsmax(text),"\dBuy a Lasermine \y[VIP]")
			else
			formatex(text,charsmax(text),"\dBuy a Lasermine [%d / %d]",zp_items_get_player_purchases(g_LME,id),zp_items_get_vip_limit(g_LME))
			
			menu_additem(menu_id,text,"",0)
		}
		else
		{
			formatex(text,charsmax(text),"Buy a Lasermine [%d / %d]",zp_items_get_player_purchases(g_LME,id),zp_items_get_player_limit(g_LME))
			menu_additem(menu_id,text,"",0)
		}
	}
	else
	{
		if(zp_items_get_player_purchases(g_LME,id)>=zp_items_get_vip_limit(g_LME)&&zp_items_get_vip_limit(g_LME))
		{
			formatex(text,charsmax(text),"\dBuy a Lasermine [%d / %d]",zp_items_get_player_purchases(g_LME,id),zp_items_get_vip_limit(g_LME))
			menu_additem(menu_id,text,"",0)
		}
		else
		{
			formatex(text,charsmax(text),"Buy a Lasermine [%d / %d]",zp_items_get_player_purchases(g_LME,id),zp_items_get_vip_limit(g_LME))
			menu_additem(menu_id,text,"",0)
		}
	}
	

	menu_additem(menu_id,"Takeback a Lasermine","",0)
	
	
	menu_setprop(menu_id, MPROP_EXIT, MEXIT_ALL );
	menu_display(id, menu_id, 0 );
}
public lgk_lm_handler( id, menu, item )
{
	menu_destroy(menu);
	
	if (!is_user_alive(id) || zp_core_is_zombie(id))
	{
		ColorChat(id, GREEN, "[GC]^03 Only humans can use Lasermines")
		return PLUGIN_HANDLED;
	}
	
	switch( item )
	{		
		case 0:
		{
			if(g_havemine[id])
			{
				if(!g_pSB[id])
				{
					Lasermenu_LgK(id);					
				}
				else
				if(iSBCanBePlaced[id] == 5)
				{
					Lasermenu_LgK(id); 
					ColorChat(id, GREEN, "[GC]^03 Lasermines can't be placed here!")
					
				}
				else
				if(zp_gamemodes_get_current()!=ZP_NO_GAME_MODE)
				{								
					Spawn(id)					
					Lasermenu_LgK2(id)					
				}
				else
				ColorChat(id, GREEN,"[GC]^03Lasermines can be placed only in infection modes.")	
			}
			else
			if((zp_items_get_purchases(g_LME)>=zp_items_get_limit(g_LME)&&zp_items_get_limit(g_LME))||((zp_items_get_player_purchases(g_LME,id)>=zp_items_get_player_limit(g_LME)&&zp_items_get_player_limit(g_LME)))&&(zpv_is_user_vip(id)&&zp_items_get_player_purchases(g_LME,id)>=zp_items_get_vip_limit(g_LME)&&zp_items_get_vip_limit(g_LME)))
			{				
				Lasermenu_LgK2(id);
			}
			else
			{
				zp_items_force_buy(id, g_LME)				
			}
		}
		case 1:
		{
			Destroy(id)
			//client_cmd(id,"+dellaser")
			ReturnMine(id)	
			Lasermenu_LgK(id);	
		}
		case MENU_EXIT:
			Destroy(id)		
	}
	return PLUGIN_HANDLED;
}*/

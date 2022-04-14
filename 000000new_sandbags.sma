#include <amxmodx>
#include <amxmisc> 
#include <fakemeta> 
#include <hamsandwich> 
#include <engine> 
#include <xs> 
#include <fun> 
#include <zombieplague> 
#include <zp50_items>
#include <zp50_gamemodes>
#include <zmvip>
#include <colorchat>
#include <zp50_main>
#include <beams>
native zp_show_reward(id, amount, const reason[32])

#define TEST
// The sizes of models 
#if defined TEST
#define PALLET_MINS Float:{ PALLET_MINSX, PALLET_MINSY, PALLET_MINSZ} 
#define PALLET_MAXS Float:{ PALLET_MAXSX, PALLET_MAXSY, PALLET_MAXSZ}

#define PALLET_MINSX -21.0
#define PALLET_MINSY -24.0
#define PALLET_MINSZ 0.0
#define PALLET_MAXSX 21.0
#define PALLET_MAXSY 24.0
#define PALLET_MAXSZ 29.0
#else
// The sizes of models 
#define PALLET_MINS Float:{ -27.260000, -22.280001, -22.290001 } 
#define PALLET_MAXS Float:{  27.340000,  26.629999,  29.020000 } 
#endif
// from fakemeta util by VEN 
#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2) 
#define fm_remove_entity(%1) engfunc(EngFunc_RemoveEntity, %1) 
// this is mine 
#define fm_drop_to_floor(%1) engfunc(EngFunc_DropToFloor,%1) 
#define fm_get_user_noclip(%1) (pev(%1, pev_movetype) == MOVETYPE_NOCLIP) 

// cvars 
new remove_nrnd 
new g_GameModeInfectionID
new g_GameModeMultiID
new g_GameModeSwarmID
new g_GameModePlagueID

new const SB_CLASSNAME[] = "FakeSandBag"
// num of pallets with bags 
/* Models for pallets with bags . 
Are available 2 models, will be set a random of them  */ 

new Counter[33];

new g_models[][] = 
{ 
	"models/gc_sandbags.mdl"
} 
new g_bolsas[33]; 

const g_item_bolsas = 30 
new g_itemid_bolsas
//new g_itemid_bolsas_vip
new cvar_health,cvar_health_vip;
new g_iMaxPlayers;
new iSandBagHealth[33]
//new iTeamLimit, gAlreadyBought[33] ,g_RoundLimit;
new bool:Bought[33];
new bool:BoughtVIP[33]
new g_pSB[33], g_pBeam[33], iSBCanBePlaced[33]
new Float:ivecOrigin[3]

new Float:DamageDealt[33]

new HudSync;

new bool:Colors;

/************************************************************* 
************************* AMXX PLUGIN ************************* 
**************************************************************/ 
public plugin_init()  
{ 
	/* Register the plugin */ 
	
	register_plugin("[ZP] Extra: SandBags", "1.1", "LARP") 
	g_itemid_bolsas = zp_items_register("Sandbags","", 30, 0, 0) 
	// g_itemid_bolsas_vip= zv_register_extra_item("Sandbags","FREE",0,ZV_TEAM_HUMAN)
	/* Register the cvars */ 
	remove_nrnd = register_cvar("zp_pb_remround","1"); 
	cvar_health=register_cvar("zp_sandbag_health","585")
	cvar_health_vip=register_cvar("zp_sandbag_health_vip","650")
	
	g_iMaxPlayers = get_maxplayers();
	/* Game Events */ 
	register_event("HLTV","event_newround", "a","1=0", "2=0"); // it's called every on new round 
	HudSync = CreateHudSyncObj();
	
	/* This is for menuz: */ 
	register_clcmd("say /sb","show_the_menu",0,"- Buys sandbags/Opens sandbag menu"); 
	register_clcmd("say_team /sb","show_the_menu",0,"- Buys sandbags/Opens sandbag menu"); 
	register_think(SB_CLASSNAME, "SB_Think");

	//RegisterHam(Ham_TakeDamage,"func_wall","fw_TakeDamage");  

	RegisterHam(Ham_TakeDamage,"func_wall","fw_TakeDamage"); 
	/*RegisterHam(Ham_Killed, "func_wall", "fw_PlayerKilled", 1)*/
	RegisterHam(Ham_Killed, "player", "Player_Death", 1)
	
	register_forward(FM_OnFreeEntPrivateData, "OnFreeEntPrivateData");
	
	new mapname[32]
	get_mapname(mapname, charsmax(mapname))
	if(equali(mapname,"zm_lgk_colors"))
	{
		Colors = true;
	}
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

	new pOwner = pev(this, pev_iuser2);

	if ((1 <= pOwner <= g_iMaxPlayers))
	{
		if (g_pBeam[pOwner] && is_valid_ent(g_pBeam[pOwner]))
			remove_entity(g_pBeam[pOwner]);

		g_pBeam[pOwner] = 0;
		g_pSB[pOwner] = 0;
	}
	return FMRES_IGNORED;
}

//Here is what I am tryin to make just owner and zombie to be able to destroy sandbags 
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) 
{ 
	//Victim is not aa sandbag. 
	new sz_classname[32] 
	entity_get_string( victim , EV_SZ_classname , sz_classname, 31 )
	new iHealth = pev( victim, pev_health )-floatround(damage)
	if(iHealth<=0)
	iHealth=1;
	
	if( !equali(sz_classname,"amxx_pallets") ) 
	return HAM_IGNORED; 
	
	if(!is_user_alive(attacker))
		return HAM_IGNORED;	
	
	if(!zp_core_is_zombie(attacker))
		return HAM_SUPERCEDE;
	
	if(zp_grenade_frost_get(attacker))  
		return HAM_SUPERCEDE; 
	
	if(is_valid_ent(victim) && zp_core_is_zombie(attacker))
	{
		DamageDealt[attacker] += damage
		if(DamageDealt[attacker] >= 65.0)
		{
			static AP
			AP = floatround(DamageDealt[attacker] / 65.0, floatround_floor)
			zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + AP)
			zp_show_reward(attacker, AP, "[SANDBAG]")
			DamageDealt[attacker]-=65.0 * AP;
		}
	}

	new health = get_pcvar_num(cvar_health)
	new viphealth = get_pcvar_num(cvar_health_vip)
	if( iHealth <=  health) 
	{
		set_rendering ( victim, kRenderFxGlowShell, 255-255*iHealth/health, 255*iHealth/health, 0, kRenderNormal, 16)
	}
	else
	if( iHealth <= viphealth) 
	{
		set_rendering ( victim, kRenderFxGlowShell, 0, 255-(255*iHealth-health)/(viphealth-health),255*(iHealth-health)/(viphealth-health), kRenderNormal, 16)
	}	
		
	return HAM_IGNORED; 
} 
/*
public fw_PlayerKilled(victim, attacker, shouldgib)
{     
	if(!is_user_connected(attacker))
		return HAM_IGNORED;
	new sz_classname[32], Float: health 
	entity_get_string( victim , EV_SZ_classname , sz_classname, charsmax(sz_classname))
	health = entity_get_float(victim, EV_FL_health)
	if(equal(sz_classname, "amxx_pallets") && is_valid_ent(victim) && zp_get_user_zombie(attacker) && health <= 0.0)
	{
		zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + 5)
		ColorChat(attacker,GREEN,"[GC]^03 You won^04 5 Ammopacks ^03 for destroying a sandbag!")
		return HAM_IGNORED;
	} 
	return HAM_IGNORED;
} */

public plugin_precache() 
{ 
	for(new i;i < sizeof g_models;i++) 
	engfunc(EngFunc_PrecacheModel,g_models[i]); 
}
public show_the_menu(id)
{
	if(!is_user_alive(id))return PLUGIN_HANDLED
	if(zp_core_is_zombie(id))return PLUGIN_HANDLED
	if(zp_class_survivor_get(id))return PLUGIN_HANDLED;
	if(!g_bolsas[id])
	{		
		if(Bought[id]&&!(zv_get_user_flags(id)&ZV_MAIN))
		{
			ColorChat(id, GREEN, "[GC]^1 Buy^3 VIP^1 at^3 GamerClub.NeT^1 for^3 Increased Item Limits!")
			// show_the_menu2(id);
			return PLUGIN_HANDLED;
		}

		zp_items_force_buy(id, g_itemid_bolsas)
	}
	else
	{
		show_the_menu2(id);		
	}
	return PLUGIN_HANDLED;
}
	
public show_the_menu2(id)
{
	if(!is_user_alive(id))return
	if(zp_core_is_zombie(id))return
	if(zp_class_survivor_get(id))return;
	new Menu = menu_create("\y[GC]\w Sandbags", "menu_command")
	new text[32]
	if(!g_bolsas[id])
	{	
		if(zv_get_user_flags(id)&ZV_MAIN)
		{
			if(Bought[id])
			{
				formatex(text,charsmax(text),"Buy a Sandbag\y %d\w [1/2] ",2*zp_items_get_cost(g_itemid_bolsas))
			}
		}
		else
		{	
			if(Bought[id])		
			formatex(text,charsmax(text),"\dBuy a Sandbag [1/2]\r [VIP]")
		}
		menu_additem(Menu,text,"",0)
	}
	else
	{
		formatex(text,charsmax(text),"Place a Sandbag [%d]",g_bolsas[id])
		menu_additem(Menu, text)
		CreateFakeSandBag(id);
	}
	menu_setprop( Menu, MPROP_EXIT, MEXIT_ALL );
	menu_display(id, Menu, 0 );
}

public menu_command(id, menu, item)
{
	menu_destroy(menu);
	
	switch(item)
	{
		case 0:  
		{
			if(g_bolsas[id])
			{
				if ( !zp_get_user_zombie(id) ) 
				{ 
					if( zp_gamemodes_get_current() == g_GameModeInfectionID || zp_gamemodes_get_current() == g_GameModeMultiID|| zp_gamemodes_get_current() == g_GameModePlagueID|| zp_gamemodes_get_current() == g_GameModeSwarmID )
					{
						if(iSBCanBePlaced[id] == 2)
						{
							show_the_menu(id); 
							ColorChat(id, GREEN, "[GC]^03 Sandbags can't be placed here!")
							return PLUGIN_CONTINUE;
						}
						new money = g_bolsas[id] 
						if ( money < 1 ) 
						{ 
						ColorChat(id,GREEN,"[GC]^03 You do not have enough sandbags to place sandbags!") 
						return PLUGIN_CONTINUE 
						}
						g_bolsas[id]--
						place_palletwbags(id); 
						if(g_bolsas[id]||((zv_get_user_flags(id)&ZV_MAIN)&&!BoughtVIP[id]))
						show_the_menu2(id); 
					}
					else ColorChat(id,GREEN,"[GC]^03 Sandbags cannot be used in this mode")
				}
	
				else ColorChat(id,GREEN,"[GC]^03 Zombies  Can't use this.")
				return PLUGIN_CONTINUE     
			}
			else
				zp_items_force_buy(id, g_itemid_bolsas)				
		}
		case MENU_EXIT:
		{
			if (g_pSB[id] && is_valid_ent(g_pSB[id]))
				remove_entity(g_pSB[id]);
				
			if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
				remove_entity(g_pBeam[id]);			
		}
	}	
	return PLUGIN_HANDLED; 
}

public CreateFakeSandBag(id)
{
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
		
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);
		
	new iSB = create_entity("info_target")
	
	if (!iSB)
		return;
		
	#if defined TEST
	//static Float:vecAngles[3]
	GetOriginAimEndEyes(id, 192, ivecOrigin)//, vecAngles)
	#else
	static Float:vecAngles[3]
	GetOriginAimEndEyes(id, 192, ivecOrigin, vecAngles)
	#endif
	engfunc(EngFunc_SetModel, iSB,g_models[random(sizeof g_models)]);
	engfunc(EngFunc_SetOrigin, iSB, ivecOrigin);
	
	set_pev(iSB, pev_classname, SB_CLASSNAME);
	set_pev(iSB, pev_iuser2, id);
	set_pev(iSB, pev_rendermode, kRenderTransAdd);
	set_pev(iSB, pev_renderamt, 200.0);
	set_pev(iSB, pev_body, 1);
	set_pev(iSB, pev_nextthink, get_gametime());
	set_pev(iSB,pev_movetype,MOVETYPE_FLY); // Movestep <- for Preview

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
	pOwner = pev(SandBag, pev_iuser2);
	
	if (!(1 <= pOwner <= g_iMaxPlayers) || !is_user_alive(pOwner))
		return;
		
	static iBody, Float:vecColor[3]
	#if !defined TEST
	static Float:vecAngles[3];	
	new hitwall=GetOriginAimEndEyes(pOwner, 192, ivecOrigin, vecAngles);
	#else
	new hitwall=GetOriginAimEndEyes(pOwner, 192, ivecOrigin)//, vecAngles);
	#endif

	iBody = 2
	xs_vec_set(vecColor, 250.0, 0.0, 0.0);
	engfunc(EngFunc_SetOrigin, SandBag, ivecOrigin);	
	
	//if (!IsHullVacant(ivecOrigin, SandBag))
	//{
	if(hitwall&&CheckSandBag(pOwner))
	{
		if(!Colors||ivecOrigin[0]>2165.0||ivecOrigin[0]<2016.0||ivecOrigin[1]>-945.0||ivecOrigin[1]<-1136.0||ivecOrigin[2]>512.0||ivecOrigin[2]<418.0)
		{		
			iBody = 1
			xs_vec_set(vecColor, 0.0, 250.0, 0.0);
		}
	}
	//}	
	
	if (g_pBeam[pOwner] && is_valid_ent(g_pBeam[pOwner]))
	{
		Beam_RelinkBeam(g_pBeam[pOwner]);
		Beam_SetColor(g_pBeam[pOwner], vecColor);
	}	
	
	iSBCanBePlaced[pOwner] = iBody	
	
	
	
	//vecAngles[0]=0.0
	//vecAngles[1]=0.0
	//vecAngles[2]=0.0
	#if !defined TEST
		set_pev(SandBag, pev_angles, vecAngles);
	#endif
	
	set_pev(SandBag, pev_body, iBody);
	set_pev(SandBag, pev_nextthink, get_gametime() + 0.01);
	
	return;
}
	
public place_palletwbags(id) 
{ 
	new Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_wall")); 
	
	set_pev(Ent,pev_classname,"amxx_pallets"); 
	
	engfunc(EngFunc_SetModel,Ent,g_models[random(sizeof g_models)]); 
	
	static Float:p_mins[3], Float:p_maxs[3], Float:vecOrigin[3]
	#if !defined TEST
	static Float:vecAngles[3];
	#endif
	p_mins = PALLET_MINS; 
	p_maxs = PALLET_MAXS; 
	engfunc(EngFunc_SetSize, Ent, p_mins, p_maxs); 
	set_pev(Ent, pev_mins, p_mins); 
	set_pev(Ent, pev_maxs, p_maxs ); 
	set_pev(Ent, pev_absmin, p_mins); 
	set_pev(Ent, pev_absmax, p_maxs ); 	
	set_pev(Ent, pev_body, 3);
	//vecOrigin[2] -= 8.0;
	#if defined TEST
	GetOriginAimEndEyes(id, 192, vecOrigin)//, vecAngles);
	#else
	GetOriginAimEndEyes(id, 192, vecOrigin, vecAngles);
	#endif
	
	//client_print(0, print_chat, "%f %f %f", vecOrigin[0],vecOrigin[1],vecOrigin[2]);
	engfunc(EngFunc_SetOrigin, Ent, vecOrigin); 
	
	#if !defined TEST
		set_pev(Ent,pev_angles,vecAngles); 
	#endif
	set_pev(Ent,pev_solid,SOLID_BBOX); // touch on edge, block 

	if(zv_get_user_flags(id)&ZV_MAIN) set_rendering ( Ent, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 16)
	else set_rendering (Ent, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 16)
	
	set_pev(Ent,pev_movetype,MOVETYPE_FLY); // no gravity, but still collides with stuff 
	
	new Float:p_cvar_health = float(iSandBagHealth[id])
	set_pev(Ent,pev_health,p_cvar_health); 
	set_pev(Ent,pev_takedamage,DAMAGE_YES); 

	/*static Float:rvec[3]; 
	pev(Ent,pev_v_angle,rvec); 
	
	rvec[0] = 0.0; 
	
	set_pev(Ent,pev_angles,rvec); */
	
	set_pev(Ent, pev_iuser2, id);

	set_pev(Ent, pev_owner, id);
	

	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);
		
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);	
		
	new player_name[34]
	get_user_name(id, player_name, charsmax(player_name))
	client_print(0,print_console, "[GC] %s has placed a sandbag!", player_name)
	//ColorChat(0,GREEN,"[GC][GC]^01 %s ^03 has placed a sandbag!", player_name)
} 

/* ==================================================== 
get_user_hitpoin stock . Was maked by P34nut, and is  
like get_user_aiming but is with floats and better :o 
====================================================*/     
stock get_user_hitpoint(id, Float:hOrigin[3])  
{ 
	if ( ! is_user_alive( id )) 
	return 0; 
	
	new Float:fOrigin[3], Float:fvAngle[3], Float:fvOffset[3], Float:fvOrigin[3], Float:feOrigin[3]; 
	new Float:fTemp[3]; 
	
	pev(id, pev_origin, fOrigin); 
	pev(id, pev_v_angle, fvAngle); 
	pev(id, pev_view_ofs, fvOffset); 
	
	xs_vec_add(fOrigin, fvOffset, fvOrigin); 
	
	engfunc(EngFunc_AngleVectors, fvAngle, feOrigin, fTemp, fTemp); 
	
	xs_vec_mul_scalar(feOrigin, 9999.9, feOrigin); 
	xs_vec_add(fvOrigin, feOrigin, feOrigin); 
	
	engfunc(EngFunc_TraceLine, fvOrigin, feOrigin, 0, id); 
	global_get(glb_trace_endpos, hOrigin); 
	
	return 1; 
}  
/* ==================================================== 
This is called on every round, at start up, 
with HLTV logevent. So if the "pallets_wbags_nroundrem" 
cvar is set to 1, all placed pallets with bugs will be 
removed. 
====================================================*/ 
public event_newround() 
{ 
	//iTeamLimit = 0	
	for ( new id; id <= get_maxplayers(); id++) 
	{ 		
		remove_task(id);
		if( get_pcvar_num ( remove_nrnd ) == 1) 
		remove_allpalletswbags(); 
		g_bolsas[id] = 0  
		Bought[id] = false;
		BoughtVIP[id] = false
		DamageDealt[id] = 0.0
		
		if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
			remove_entity(g_pBeam[id])
		if (g_pSB[id] && is_valid_ent(g_pSB[id]))
			remove_entity(g_pSB[id]);
	} 

}  
/* ==================================================== 
This is a stock to help for remove all pallets with 
bags placed . Is called on new round if the cvar 
"pallets_wbags_nroundrem" is set 1. 
====================================================*/ 
stock remove_allpalletswbags() 
{ 
	new pallets = -1; 
	while((pallets = fm_find_ent_by_class(pallets, "amxx_pallets"))) 
	fm_remove_entity(pallets); 
} 

public plugin_natives()
{
	register_native("zp_bought_vip_item_get", "native_bought_vip_item_get",1)
	register_native("zp_bought_vip_item_set", "native_bought_vip_item_set",1)
	register_native("zp_sandbags_set_cost","native_sandbags_set_cost")	
}

public native_sandbags_set_cost(plugin,params)
{
	if(get_param(3)!=g_itemid_bolsas)
		return false;	

	if(Bought[get_param(1)])
	set_param_byref(2, 2 * get_param_byref(2))

	return true;
}

public native_bought_vip_item_get(id)
{
	return BoughtVIP[id]
}

public native_bought_vip_item_set(id)
{
	BoughtVIP[id] = true;
}

public plugin_cfg()
{
	g_GameModeInfectionID = zp_gamemodes_get_id("Infection Mode")
	g_GameModeMultiID = zp_gamemodes_get_id("Multiple Infection Mode")
	g_GameModeSwarmID = zp_gamemodes_get_id("Swarm Mode")
	g_GameModePlagueID = zp_gamemodes_get_id("Plague Mode")
}
public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_itemid_bolsas)
		return ZP_ITEM_AVAILABLE;	
	
	if (zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW;
	
	if(zp_class_survivor_get(id))
		return ZP_ITEM_DONT_SHOW
	
	
	new current_mode = zp_gamemodes_get_current()
	if (current_mode != g_GameModeInfectionID && current_mode != g_GameModeMultiID)
		return ZP_ITEM_DONT_SHOW;	
	
	
	if(zv_get_user_flags(id)&ZV_MAIN)
	{
		if(Bought[id])
		{				
			if(BoughtVIP[id])
			{					
				return ZP_ITEM_NOT_AVAILABLE;
			}
			
			zp_items_menu_text_add("[1/2]")
			return ZP_ITEM_AVAILABLE;
		}
		
		if(BoughtVIP[id])
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
	if (itemid != g_itemid_bolsas)
	return;
	g_bolsas[id]+=2;
	//Counter[id]=60;
	//remove_task(id)
	//set_task(1.0,"CheckIfPlaced",id,"",0,"b")
	
	//gAlreadyBought[id] = 1
	//iTeamLimit++
	if(!Bought[id])
	Bought[id]=true;
	else
	BoughtVIP[id]=true;
	show_the_menu2(id)
	//client_print(id, print_chat, "[ZP] You have %i sandbags, to use type 'say / sb'", g_bolsas[id]) 
	if(zv_get_user_flags(id)&ZV_MAIN)
	iSandBagHealth[id] = get_pcvar_num(cvar_health_vip)
	else
	iSandBagHealth[id] = get_pcvar_num(cvar_health)
}

// public zv_extra_item_selected(id, itemid)
// {
// 	// This is not our item
// 	if (itemid != g_itemid_bolsas_vip)
// 	return;
// 	g_bolsas[id]+=2;
// 	//Counter[id]=60;
// 	//remove_task(id)
// 	//set_task(1.0,"CheckIfPlaced",id,"",0,"b")
	
// 	//gAlreadyBought[id] = 1
// 	//iTeamLimit++
// 	show_the_menu2(id)
// 	//client_print(id, print_chat, "[ZP] You have %i sandbags, to use type 'say / sb'", g_bolsas[id]) 
// 	if(zv_get_user_flags(id)&ZV_MAIN)
// 	iSandBagHealth[id] = get_pcvar_num(cvar_health_vip)
// 	else
// 	iSandBagHealth[id] = get_pcvar_num(cvar_health)
// }

public CheckIfPlaced(id)
{
	if(!is_user_connected(id))
	{
		remove_task(id);
		return;
	}
	
	if(!is_user_alive(id))
	{
		remove_task(id);
		return;
	}
		
	if(zp_core_is_zombie(id))
	{
		remove_task(id);
		return;
	}
		
	Counter[id]--;
	if(g_bolsas[id]>0)
	{
		if(!Counter[id])
		{
			zp_items_set_purchases(g_itemid_bolsas,zp_items_get_purchases(g_itemid_bolsas)-1);
			if (g_pSB[id] && is_valid_ent(g_pSB[id]))
				remove_entity(g_pSB[id]);
			
			if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
				remove_entity(g_pBeam[id]);	
			set_hudmessage(0, 255, 0, 0.5, 0.35,0,5.0,5.0);
			
			zp_ammopacks_set(id, zp_ammopacks_get(id)+zp_items_get_cost(g_itemid_bolsas));
			ShowSyncHudMsg(id, HudSync, "Your sandbags have been revoked!")
			client_print(id, print_chat, "[ZP] Your sandbags have been revoked!") 
			g_bolsas[id]=0;
			remove_task(id)
		}
		else
		{
			set_hudmessage(0, 255, 0, 0.5, 0.35,0,1.0,1.0);
			ShowSyncHudMsg(id, HudSync, "You have %d s left to place the sandbags!",Counter[id])
		}
		
	}
	else
	{
		remove_task(id)
	}	
}

public client_disconnecteded(id)
{	
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
	
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);
}

public zp_fw_core_infect(id)
{	
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
	
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);	
	
	new ent=-1;
	while((ent = find_ent_by_class(ent,"amxx_pallets")))
	{
		if(pev(ent,pev_iuser2)==id)
		{
			set_pev(ent,pev_owner,0);
		}
	}
}

public zp_fw_core_cure(id)
{
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
	
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);
	
	new ent=-1;
	while((ent = find_ent_by_class(ent,"amxx_pallets")))
	{
		if(pev(ent,pev_iuser2)==id)
		{
			set_pev(ent,pev_owner,id);
		}
	}
}
/*
bool:is_monster_hull_vacant(const Float:vecSrc[3], iHull, pEntToSkip = 0)
{
	engfunc(EngFunc_TraceMonsterHull, pEntToSkip,vecSrc, vecSrc, DONT_IGNORE_MONSTERS, pEntToSkip, 0);
	return bool:(!get_tr2(0, TR_AllSolid) && !get_tr2(0, TR_StartSolid) && get_tr2(0, TR_InOpen));
}

bool:IsHullVacant(const Float:vecSrc[3], iHull, pEntToSkip = 0)
{
	engfunc(EngFunc_TraceHull, vecSrc, vecSrc, DONT_IGNORE_MONSTERS, iHull, pEntToSkip, 0);
	return bool:(!get_tr2(0, TR_AllSolid) && !get_tr2(0, TR_StartSolid) && get_tr2(0, TR_InOpen));
}*/

#if defined TEST
GetOriginAimEndEyes(this, iDistance, Float:vecOut[3])//, Float:vecAngles[3])
#else
GetOriginAimEndEyes(this, iDistance, Float:vecOut[3], Float:vecAngles[3])
#endif
{
	static Float:vecSrc[3], Float:vecEnd[3], Float:vecViewOfs[3], Float:vecVelocity[3];
	static Float:flFraction;

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
					if(equali(classname,"amxx_pallets")||equali(classname,"lasermine"))
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

		#if defined TEST
		if(vecPlaneNormal[0]>0)
		{
			xs_vec_sub(vecOut, Float:{PALLET_MINSX,0.0,0.0}, vecOut);
		}
		else if(vecPlaneNormal[0]<0)
		{
			xs_vec_sub(vecOut, Float:{PALLET_MAXSX,0.0,0.0}, vecOut);
		}
		else if(vecPlaneNormal[1]>0)
		{
			xs_vec_sub(vecOut, Float:{0.0,PALLET_MINSY,0.0}, vecOut);
		}
		else if(vecPlaneNormal[1]<0)
		{
			xs_vec_sub(vecOut, Float:{0.0,PALLET_MAXSY,0.0}, vecOut);
		}
		else if(vecPlaneNormal[2]<0)
		{
			xs_vec_sub(vecOut, Float:{0.0,0.0,PALLET_MAXSZ}, vecOut);
		}/*
		else if(vecPlaneNormal[2]<0)
		{
			xs_vec_sub(vecOut, Float:{0.0,0.0,PALLET_MAXSZ}, vecOut);
		}*/
		#else		
		xs_vec_mul_scalar(vecPlaneNormal, 1.0, vecPlaneNormal);
		#endif
		hitwall=true;
	}
	else
	{
		xs_vec_copy(vecEnd, vecOut);
	}
	
	free_tr2(tr3)
	#if !defined TEST
	vecVelocity[2] = 0.0;
	vector_to_angle(vecVelocity, vecAngles);
	#endif
	return hitwall;
/*
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, this, 0);
	
	get_tr2(0, TR_flFraction, flFraction);
	
	new hitwall;
	if (flFraction < 1.0)
	{
		static Float:vecPlaneNormal[3];

		get_tr2(0, TR_PlaneNormal, vecPlaneNormal);
		get_tr2(0, TR_vecEndPos, vecOut);

		xs_vec_mul_scalar(vecPlaneNormal, 1.0, vecPlaneNormal);
		xs_vec_add(vecOut, vecPlaneNormal, vecOut);
		hitwall=true;
	}
	else
	{
		xs_vec_copy(vecEnd, vecOut);
	}
	
	vecVelocity[2] = 0.0;
	vector_to_angle(vecVelocity, vecAngles);
	return hitwall;*/
}

public CheckSandBag(id)
{
	static victim
	victim = -1
	while ( ( victim = find_ent_in_sphere(victim,ivecOrigin,30.0)) != 0 )
	{
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

/*
public show_the_menu(id)
{
	if(!is_user_alive(id))return PLUGIN_HANDLED
	if(zp_core_is_zombie(id))return PLUGIN_HANDLED
	if(zp_class_survivor_get(id))return PLUGIN_HANDLED;
	if(!g_bolsas[id])
	{
		
		zp_items_force_buy(id, g_itemid_bolsas)
	}
	else
	{
		show_the_menu2(id);		
	}
	return PLUGIN_HANDLED;
}
	
public show_the_menu2(id)
{
	if(!is_user_alive(id))return
	if(zp_core_is_zombie(id))return
	if(zp_class_survivor_get(id))return;
	new Menu = menu_create("\rSandbags \yMenu", "menu_command")
	new text[32]
	if(!g_bolsas[id])
	{
		if((zp_items_get_purchases(g_itemid_bolsas)>=zp_items_get_limit(g_itemid_bolsas)&&zp_items_get_limit(g_itemid_bolsas)))
		{	
			formatex(text,charsmax(text),"\dBuy a Sandbag [%d / %d]",zp_items_get_purchases(g_itemid_bolsas),zp_items_get_limit(g_itemid_bolsas))
			menu_additem(Menu,text,"",0)			
		}
		else
		if(!zpv_is_user_vip(id))
		{			
			if((zp_items_get_player_purchases(g_itemid_bolsas,id)>=zp_items_get_player_limit(g_itemid_bolsas)&&zp_items_get_player_limit(g_itemid_bolsas)))
			{	
				if(zp_items_get_player_limit(g_itemid_bolsas)<zp_items_get_vip_limit(g_itemid_bolsas))
				formatex(text,charsmax(text),"\dBuy a Sandbag [%d / %d] \y[VIP]",zp_items_get_player_purchases(g_itemid_bolsas,id),zp_items_get_vip_limit(g_itemid_bolsas))
				else
				if(!zp_items_get_vip_limit(g_itemid_bolsas))
				formatex(text,charsmax(text),"\dBuy a Sandbag \y[VIP]")
				else
				formatex(text,charsmax(text),"\dBuy a Sandbag [%d / %d]",zp_items_get_player_purchases(g_itemid_bolsas,id),zp_items_get_player_limit(g_itemid_bolsas))
				
				menu_additem(Menu,text,"",0)
			}
			else
			{
				formatex(text,charsmax(text),"Buy a Sandbag [%d / %d]",zp_items_get_player_purchases(g_itemid_bolsas,id),zp_items_get_player_limit(g_itemid_bolsas))
				menu_additem(Menu,text,"",0)
			}
		}
		else
		{
			if(zp_items_get_player_purchases(g_itemid_bolsas,id)>=zp_items_get_vip_limit(g_itemid_bolsas)&&zp_items_get_vip_limit(g_itemid_bolsas))
			{	
				formatex(text,charsmax(text),"\dBuy a Sandbag [%d / %d]",zp_items_get_player_purchases(g_itemid_bolsas,id),zp_items_get_vip_limit(g_itemid_bolsas))
				menu_additem(Menu,text,"",0)
			}
			else
			{
				formatex(text,charsmax(text),"Buy a Sandbag [%d / %d]",zp_items_get_player_purchases(g_itemid_bolsas,id),zp_items_get_vip_limit(g_itemid_bolsas))
				menu_additem(Menu,text,"",0)
			}
		}
	}
	else
	{
		formatex(text,charsmax(text),"Place a Sandbag [%d]",g_bolsas[id])
		menu_additem(Menu, text)
		CreateFakeSandBag(id);
	}
	menu_setprop( Menu, MPROP_EXIT, MEXIT_ALL );
	menu_display(id, Menu, 0 );
}*/
#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cs_maxspeed_api>
//#include <cs_ham_bots_api>
#include <beams>
#include <colorchat>
#include <zp50_items>
#include <zp50_gamemodes>
#include <bulletdamage>
#include <zp50_item_zombie_madness>
#include <zp50_class_zombie>
#include <zp50_grenade_frost>
#include <zmvip>
#include <zp50_ammopacks>

native zp_bought_vip_item_get(id)
native zp_bought_vip_item_set(id)

const MAXPLAYERS = 32;

#define SetPlayerBit(%1,%2)		(%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)	(%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)	(%1 & (1<<(%2&31)))

#define ADDRESS "74.91.116.201:27015"

new const RC_CLASSNAME[] = "rcbomb";
new const RC_MODEL[] = "models/zombie_plague/gc_rc.mdl";
new const CAM_CLASSNAME[] = "rccam";
new const CAM_MODEL[] = "models/rpgrocket.mdl";
new const RC_SOUND[] = "zombie_plague/monster_engine.wav";

new Bought[33]
new g_pCar[MAXPLAYERS+1], g_pBeam[MAXPLAYERS+1], bool:g_bIsJumping[MAXPLAYERS+1], Float:g_flMaxSpeed[MAXPLAYERS+1], Float:g_vecAngles[MAXPLAYERS+1][3], Float:g_vecOrigin[MAXPLAYERS+1][3], g_pTriggerCam;
new g_iMaxPlayers;
new g_fViewEntCar;

new Inventory[33],Parked[33];
//new CapCount;
new g_iItemId//, g_itemid_vip
new explosion, rc_radius,cvar_health,cvar_health_vip,cvar_damage;

new MenuID;
new Float:DamageDealt[33]
native zp_show_reward(id, amount, const reason[32])

public plugin_init()
{
	register_plugin("[ZP] Item: RC", "2.0", "Several");

	g_pTriggerCam = create_entity("trigger_camera");
	engfunc(EngFunc_SetModel, g_pTriggerCam, CAM_MODEL);
	set_pev(g_pTriggerCam, pev_classname, CAM_CLASSNAME);
	set_pev(g_pTriggerCam, pev_movetype, MOVETYPE_NOCLIP);
	set_pev(g_pTriggerCam, pev_solid, SOLID_NOT);
	set_pev(g_pTriggerCam, pev_renderamt, 0.0);
	set_pev(g_pTriggerCam, pev_rendermode, kRenderTransTexture);

	g_iMaxPlayers = get_maxplayers();

	g_iItemId = zp_items_register("Remote Controlled Bomb", "Blow up zombies", 45, 5, 1)
	
	// g_itemid_vip = zv_register_extra_item("Remote Controlled Bomb", "FREE",0,ZV_TEAM_HUMAN);
//	g_iVIPItemId = zpv_items_register("RC-Bomb", 25, 1);

	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0");

	RegisterHam(Ham_TakeDamage, "info_target", "CBaseEntity_TakeDamage");
	register_think(RC_CLASSNAME, "RC_Think");

	RegisterHam(Ham_Killed, "player", "CBasePlayer_Killed");
//RegisterHamBots(Ham_TakeDamage, "CBasePlayer_Killed");
	rc_radius = register_cvar("zp_rc_distance", "350")
	cvar_health=register_cvar("zp_rc_health","260")
	cvar_health_vip=register_cvar("zp_rc_health_vip","290")
	cvar_damage=register_cvar("zp_rc_damage","2000")
	register_forward(FM_UpdateClientData, "CBasePlayer_UpdateData_Post", 1);
	register_forward(FM_OnFreeEntPrivateData, "OnFreeEntPrivateData");
	register_forward(FM_Touch, "fw_touch")
	register_clcmd("say /rc", "CmdRC",0,"- Buys RC/Opens RC Menu");
	register_clcmd("say_team /rc", "CmdRC",0,"- Buys RC/Opens RC Menu");

	MenuID = register_menuid("RC")
	register_menucmd(MenuID,MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9,"HandleMenu_RC")
	//register_clcmd("give_rc","gimme_rc")
	//Protection
//////////////////////////////////////
	//static address[32]
	//get_cvar_string("net_address", address, charsmax(address))
	//if (!equal(ADDRESS, address)) set_fail_state("Private Plugin :)")
//////////////////////////////////////

}

public fw_touch(zone, ent) {
	
	if (!pev_valid(zone) || !pev_valid(ent))
		return FMRES_IGNORED

	if (!FClassnameIs(ent, RC_CLASSNAME))
		return FMRES_IGNORED;
	
	if (FClassnameIs(zone, "trigger_teleport"))
	{	
		new destination[32]
		entity_get_string(zone,EV_SZ_target,destination,charsmax(destination))
		new dest
		while((dest = find_ent_by_class(dest,"info_teleport_destination")) != 0)
		{
			new destination2[32]
			entity_get_string(dest,EV_SZ_targetname,destination2,charsmax(destination2))
			if(equal(destination,destination2))
			{
				new Float:vecDestination[3]
				entity_get_vector(dest,EV_VEC_origin,vecDestination)			
				entity_set_vector(ent, EV_VEC_origin, vecDestination)
				return FMRES_IGNORED
			}
		}	
		return FMRES_IGNORED
	}
	return FMRES_IGNORED;
}


public plugin_precache()
{
	precache_model(RC_MODEL);
	precache_model(CAM_MODEL);
	precache_sound(RC_SOUND);
	precache_sound("buttons/blip1.wav");
	explosion = precache_model("sprites/zerogxplode.spr")
}

/*public gimme_rc(id)
{
	RC_Spawn(id);
	ShowMenu_RC(id);
}*/
public plugin_natives()
{
	register_native("free_rc", "giveRC", 1)
	register_native("zp_rc_set_cost","native_rc_set_cost")	
}

public native_rc_set_cost(plugin,params)
{
	if(get_param(3)!=g_iItemId)
		return false;	

	if(Bought[get_param(1)])
	set_param_byref(2, 3 * get_param_byref(2)/2)

	return true;
}
public client_disconnecteded(this)
{
	if (g_pCar[this] && is_valid_ent(g_pCar[this]))
		remove_entity(g_pCar[this]);
}

public zp_fw_core_infect(this)
{
	if (g_pCar[this] && is_valid_ent(g_pCar[this]))
		remove_entity(g_pCar[this]);
}

public zp_fw_core_cure(this)
{
	if (g_pCar[this] && is_valid_ent(g_pCar[this]))
		remove_entity(g_pCar[this]);
}

public zp_fw_items_select_pre(this, iItemId)
{
	if (iItemId != g_iItemId)
		return ZP_ITEM_AVAILABLE;

	if (!IsAllowedMode())
		return ZP_ITEM_DONT_SHOW;
		
	if (zp_core_is_zombie(this))
		return ZP_ITEM_DONT_SHOW;
	
	if (g_pCar[this] && is_valid_ent(g_pCar[this]))
		return ZP_ITEM_NOT_AVAILABLE;

	if(zv_get_user_flags(this)&ZV_MAIN)
	{
		if(Bought[this])
		{				
			if(zp_bought_vip_item_get(this))
			{					
				return ZP_ITEM_NOT_AVAILABLE;
			}
			
			zp_items_menu_text_add("[1/2]")
			return ZP_ITEM_AVAILABLE;
		}
		if(zp_bought_vip_item_get(this))
		zp_items_menu_text_add("[0/1]")
		else
		zp_items_menu_text_add("[0/2]")
		return ZP_ITEM_AVAILABLE
	}

	if(Bought[this])
	{
		zp_items_menu_text_add("[1/2] \r[VIP]")
		return ZP_ITEM_NOT_AVAILABLE;
	}
	
	zp_items_menu_text_add("[0/1]")
	return ZP_ITEM_AVAILABLE;
}
public giveRC(id)
{
	Inventory[id]++;
	RC_Spawn(id);
}

public zp_fw_items_select_post(this, iItemId)
{
	if (iItemId != g_iItemId)
		return;
	
	if(!Bought[this])
	Bought[this]=true;
	else
	zp_bought_vip_item_set(this)
	Inventory[this]++;
	RC_Spawn(this);
	ShowMenu_RC(this)
}

// public zv_extra_item_selected(this, itemid)
// {
// 	if(itemid != g_itemid_vip)
// 		return;

// 	Inventory[this]++;
// 	RC_Spawn(this);
// 	ShowMenu_RC(this)
// }

bool:IsAllowedMode()
{
	new Mode[4]
	Mode[0] = zp_gamemodes_get_current()
	Mode[1] = zp_gamemodes_get_id("Multiple Infection Mode")
	Mode[2] = zp_gamemodes_get_id("Infection Mode")
	
	for(new num = 1; num <= charsmax(Mode); num++)
	{
		if(Mode[0] == Mode[num])
			return true
	}
	return false;	
}
public CmdRC(this)
{
	if(!is_user_alive(this))
		return PLUGIN_HANDLED;
		
	if (zp_core_is_zombie(this))
	{
		//ColorChat(this, GREEN, "[GC]]^03 Zombies can't use RC")
		return PLUGIN_HANDLED;
	}
	if(!IsAllowedMode())
	{
		//ColorChat(this, GREEN, "[GC]^03 RC Unavailable")
		return PLUGIN_HANDLED;		
	}		
	
	if (pev(g_pCar[this], pev_movetype) == MOVETYPE_PUSHSTEP)
	{
		if(Parked[this])
		{
			g_flMaxSpeed[this] = get_user_maxspeed(this);
			cs_set_player_maxspeed(this, 1.0);
			attach_view(this, g_pTriggerCam);
			SetPlayerBit(g_fViewEntCar, this);
			Parked[this]=false;
		}
		return PLUGIN_HANDLED;
	}
	if(Inventory[this])
	{
		RC_Spawn(this)
		ShowMenu_RC(this)
		return PLUGIN_HANDLED;
	}		

	if(Bought[this]&&!(zv_get_user_flags(this)&ZV_MAIN))
	{
		ColorChat(this, GREEN, "[GC]^1 Buy^3 VIP^1 at^3 GamerClub.NeT^1 for^3 Increased Item Limits!")
		return PLUGIN_HANDLED;
	}

	if (!zp_items_force_buy(this, g_iItemId))
	{
		//ColorChat(this, GREEN, "[GC]^03 Item Unavailable")
		return PLUGIN_HANDLED;
	}	
	

	return PLUGIN_HANDLED;
}

public ShowMenu_RC(this)
{
	if(!IsAllowedMode())
	{
		//ColorChat(this, GREEN, "[GC]^03 RC Unavailable")
		return;		
	}
	
	if(!Parked[this]&&pev(g_pCar[this], pev_movetype) == MOVETYPE_PUSHSTEP)
	{
		return;
	}	
	
	new menu_msg[] = "\y[GC] \wRemote Controlled Bomb^n^n\r1.\w Place The RC^n\r2.\w Place and Detonate the RC^n^nPress \r+forward \wto move forward \r+back \wto move backwards, \r+moveleft\w -> Left, \r+moveright \w-> Right^nJump/Climb ladders with \r+jump\w^nPress buttons with \r+use\w^nPark with \r+attack2\w^nDetonate with \r+attack^n"
	show_menu(this,(MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9), menu_msg,  -1, "RC")
	/*
	new iMenu, szBuffer[512], iLen;	
	iMenu = menu_create("\y[GC] \wRemote Controlled Bomb", "HandleMenu_RC");
	
	menu_additem(iMenu, "Place The RC!");	
			
	
	iLen = formatex(szBuffer, charsmax(szBuffer), "^nPress \r+forward \wto move forward \r+back \wto move backwards, \r+moveleft\w -> Left, \r+moveright \w-> Right^n");
	iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "Jump/Climb ladders with \r+jump\w^n");
	iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "Press buttons with \r+use\w^n");	
	iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "Park with \r+attack2\w^n");
	iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "Detonate with \r+attack^n");	
	menu_addtext(iMenu, szBuffer, 1);
	
	menu_display(this, iMenu);*/
}
public HandleMenu_RC(this, key)
{	
	if (!g_pCar[this] || !is_valid_ent(g_pCar[this]))
	{
		return PLUGIN_HANDLED;
	}
	
	if(key>1)
	{
		if(pev(g_pCar[this], pev_movetype) != MOVETYPE_PUSHSTEP)
			if (g_pCar[this] && is_valid_ent(g_pCar[this]))
			{
				remove_entity(g_pCar[this])			
				if(is_user_connected(this))	
				ColorChat(this, GREEN, "[GC]^3 Type^4 /rc^3 to open this menu again!")
			}		
	}
	else	
	if(!Parked[this]&&pev(g_pCar[this], pev_movetype) == MOVETYPE_PUSHSTEP)
	{
		return PLUGIN_HANDLED;
	}		
	else
	{
		if (pev(g_pCar[this], pev_movetype) != MOVETYPE_PUSHSTEP)
		{
			if(key==0)
			{
				if (pev(g_pCar[this], pev_body) == 0)
				{
					if (g_pBeam[this] && is_valid_ent(g_pBeam[this]))
						remove_entity(g_pBeam[this]);
			
					pev(this, pev_origin, g_vecOrigin[this]);
					pev(g_pCar[this], pev_angles, g_vecAngles[this]);
		
					set_pev(g_pCar[this], pev_solid, SOLID_BBOX);
					set_pev(g_pCar[this], pev_movetype, MOVETYPE_PUSHSTEP);
					set_pev(g_pCar[this], pev_takedamage, DAMAGE_YES);
					set_pev(g_pCar[this], pev_body, random_num(2, 12));
					set_pev(g_pCar[this], pev_rendermode, kRenderNormal);
					set_pev(g_pCar[this], pev_renderamt, 255.0);

					if(zv_get_user_flags(this)&ZV_MAIN) set_rendering ( g_pCar[this], kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 16)
					else set_rendering (g_pCar[this], kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 16)
					drop_to_floor(g_pCar[this]);
		
					g_flMaxSpeed[this] = get_user_maxspeed(this);
					g_pBeam[this] = 0;
		
					cs_set_player_maxspeed(this, 1.0);
					attach_view(this, g_pTriggerCam);
					SetPlayerBit(g_fViewEntCar, this);
					
					Inventory[this]--;
				}
				else
				{
					ShowMenu_RC(this);
				}
			}
			else
			if(key==1)
			{
				if (g_pBeam[this] && is_valid_ent(g_pBeam[this]))
					remove_entity(g_pBeam[this]);
		
				pev(this, pev_origin, g_vecOrigin[this]);
				pev(g_pCar[this], pev_angles, g_vecAngles[this]);
	
				set_pev(g_pCar[this], pev_solid, SOLID_BBOX);
				set_pev(g_pCar[this], pev_movetype, MOVETYPE_PUSHSTEP);
				set_pev(g_pCar[this], pev_takedamage, DAMAGE_YES);
				set_pev(g_pCar[this], pev_body, random_num(2, 12));
				set_pev(g_pCar[this], pev_rendermode, kRenderNormal);
				set_pev(g_pCar[this], pev_renderamt, 255.0);

				if(zv_get_user_flags(this)&ZV_MAIN) set_rendering ( g_pCar[this], kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 16)
				else set_rendering (g_pCar[this], kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 16)
				drop_to_floor(g_pCar[this]);
	
				g_flMaxSpeed[this] = get_user_maxspeed(this);
				g_pBeam[this] = 0;
	
				cs_set_player_maxspeed(this, 1.0);
				attach_view(this, g_pTriggerCam);
				SetPlayerBit(g_fViewEntCar, this);
				
				Inventory[this]--;
				remove_entity(g_pCar[this])
			}
		}
	}
	return PLUGIN_HANDLED;
}
/*
public HandleMenu_RC(this, iMenu, iItem)
{	
	if (!g_pCar[this] || !is_valid_ent(g_pCar[this]))
	{
		menu_destroy(iMenu)
		return PLUGIN_HANDLED;
	}
	
	if(iItem==MENU_EXIT)
	{
		if(pev(g_pCar[this], pev_movetype) != MOVETYPE_PUSHSTEP)
			if (g_pCar[this] && is_valid_ent(g_pCar[this]))
				remove_entity(g_pCar[this]);
	}
	else	
	if(!Parked[this]&&pev(g_pCar[this], pev_movetype) == MOVETYPE_PUSHSTEP)
	{
		
		menu_destroy(iMenu)
		return PLUGIN_HANDLED;
	}		
	else
	if (iItem == 0)
	{
		if (pev(g_pCar[this], pev_movetype) != MOVETYPE_PUSHSTEP)
		{
			if (pev(g_pCar[this], pev_body) == 0)
			{
				if (g_pBeam[this] && is_valid_ent(g_pBeam[this]))
					remove_entity(g_pBeam[this]);
		
				pev(this, pev_origin, g_vecOrigin[this]);
				pev(g_pCar[this], pev_angles, g_vecAngles[this]);
	
				set_pev(g_pCar[this], pev_solid, SOLID_BBOX);
				set_pev(g_pCar[this], pev_movetype, MOVETYPE_PUSHSTEP);
				set_pev(g_pCar[this], pev_takedamage, DAMAGE_YES);
				set_pev(g_pCar[this], pev_body, random_num(2, 12));
				set_pev(g_pCar[this], pev_rendermode, kRenderNormal);
				set_pev(g_pCar[this], pev_renderamt, 255.0);

				if(zv_get_user_flags(this)&ZV_MAIN) set_rendering ( g_pCar[this], kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 16)
				else set_rendering (g_pCar[this], kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 16)
				drop_to_floor(g_pCar[this]);
	
				g_flMaxSpeed[this] = get_user_maxspeed(this);
				g_pBeam[this] = 0;
	
				cs_set_player_maxspeed(this, 1.0);
				attach_view(this, g_pTriggerCam);
				SetPlayerBit(g_fViewEntCar, this);
				
				Inventory[this]--;
			}
			else
			{
				ShowMenu_RC(this);
				//ColorChat(this, GREEN, "[GC]^03 You Can't Place ^04The RC ^03 Here")
			}
		}
	}
	
	menu_destroy(iMenu)
	return PLUGIN_HANDLED;
}*/
/*RC_Spawn(this)
{
	new pCar = create_entity("info_target");

	if (!pCar)
		return;

	new Float:vecOrigin[3], Float:vecAngles[3];

	pev(this, pev_origin, vecOrigin);
	//pev(this, pev_angles, vecAngles);

	new Float:vecVelocity[3];
	velocity_by_aim(this, 128, vecVelocity);
	vecVelocity[2] = 0.0;
	vector_to_angle(vecVelocity, vecAngles);

	vecOrigin[2] += 25.0;

	xs_vec_copy(vecOrigin, g_vecOrigin[this]);
	xs_vec_copy(vecAngles, g_vecAngles[this]);

	engfunc(EngFunc_SetModel, pCar, RC_MODEL);
	engfunc(EngFunc_SetSize, pCar, Float:{ -14.0, -14.0, 0.0 }, Float:{ 14.0, 14.0, 18.5 });
	engfunc(EngFunc_SetOrigin, pCar, vecOrigin);

	set_pev(pCar, pev_classname, RC_CLASSNAME);
	set_pev(pCar, pev_owner, this);
	set_pev(pCar, pev_angles, vecAngles);
	set_pev(pCar, pev_solid, SOLID_BBOX);
	set_pev(pCar, pev_movetype, MOVETYPE_PUSHSTEP);
	set_pev(pCar, pev_takedamage, DAMAGE_YES);
	set_pev(pCar, pev_health, 400.0);
	set_pev(pCar, pev_body, random_num(2, 12));
	set_pev(pCar, pev_controller_0, 125);
	set_pev(pCar, pev_controller_1, 125);
	set_pev(pCar, pev_controller_2, 125);
	set_pev(pCar, pev_nextthink, get_gametime());

	g_pCar[this] = pCar;
	g_flMaxSpeed[this] = get_user_maxspeed(this);

	cs_set_player_maxspeed(this, 1.0);
	attach_view(this, g_pTriggerCam);
}*/

RC_Spawn(this)
{	
	if (g_pCar[this] && is_valid_ent(g_pCar[this]))
	{		
		return;
	}
	new pCar = create_entity("info_target");

	if (!pCar)
		return;	
	
	//set_task(0.3,"ShowMenu_RC",this)
	//ShowMenu_RC(this)
	
	new Float:vecOrigin[3], Float:vecAngles[3];

	pev(this, pev_origin, vecOrigin);
	//pev(this, pev_angles, vecAngles);

	new Float:vecVelocity[3];
	velocity_by_aim(this, 128, vecVelocity);
	vecVelocity[2] = 0.0;
	vector_to_angle(vecVelocity, vecAngles);

	vecOrigin[2] += 25.0;

	xs_vec_copy(vecOrigin, g_vecOrigin[this]);
	xs_vec_copy(vecAngles, g_vecAngles[this]);

	engfunc(EngFunc_SetModel, pCar, RC_MODEL);
	engfunc(EngFunc_SetSize, pCar, Float:{ -14.0, -14.0, 0.0 }, Float:{ 14.0, 14.0, 18.5 });
	engfunc(EngFunc_SetOrigin, pCar, vecOrigin);

	set_pev(pCar, pev_classname, RC_CLASSNAME);
	set_pev(pCar, pev_owner, this);
	set_pev(pCar, pev_angles, vecAngles);
	if(zv_get_user_flags(this)&ZV_MAIN)	
	set_pev(pCar, pev_health, get_pcvar_float(cvar_health_vip));
	else
	set_pev(pCar, pev_health, get_pcvar_float(cvar_health));
	set_pev(pCar, pev_body, 1);
	set_pev(pCar, pev_rendermode, kRenderTransAdd);
	set_pev(pCar, pev_renderamt, 200.0);
	set_pev(pCar, pev_controller_0, 125);
	set_pev(pCar, pev_controller_1, 125);
	set_pev(pCar, pev_controller_2, 125);
	set_pev(pCar, pev_nextthink, get_gametime());

	new pBeam = Beam_Create("sprites/laserbeam.spr", 6.0);

	if (pBeam != FM_NULLENT)
	{	
		Beam_EntsInit(pBeam, pCar, this);
		Beam_SetColor(pBeam, Float:{150.0, 0.0, 0.0});
		Beam_SetScrollRate(pBeam, 255.0);
		Beam_SetBrightness(pBeam, 200.0);
	}
	else
	{
		pBeam = 0;
	}

	g_pBeam[this] = pBeam;
	g_pCar[this] = pCar;
}

public Event_NewRound()
{
	for(new id=1;id<33;id++)
	{
		Bought[id]=false;
		DamageDealt[id]= 0.0;
	}
	new pEdict;
	while ((pEdict = find_ent_by_class(pEdict, RC_CLASSNAME)) > 0)
		remove_entity(pEdict);
}

public CBaseEntity_TakeDamage(this, pInflictor, pAttacker,Float:damage)
{
	if (!FClassnameIs(this, RC_CLASSNAME))
		return HAM_IGNORED;

	if(!is_user_connected(pAttacker))
		return HAM_SUPERCEDE;

	if (!zp_core_is_zombie(pAttacker))
		return HAM_SUPERCEDE;
	
	if(zp_grenade_frost_get(pAttacker))
		return HAM_SUPERCEDE;

	if(is_valid_ent(this) && zp_core_is_zombie(pAttacker))
	{
		DamageDealt[pAttacker] += damage
		if(DamageDealt[pAttacker] >= 65.0)
		{
			static AP
			AP = floatround(DamageDealt[pAttacker] / 65.0, floatround_floor)
			zp_ammopacks_set(pAttacker, zp_ammopacks_get(pAttacker) + AP)
			zp_show_reward(pAttacker, AP, "[RC]")
			DamageDealt[pAttacker]-=65.0 * AP;
		}
	}

	new iHealth = pev( this, pev_health )-floatround(damage)
	if(iHealth<=0)
	iHealth=1;
	new health = get_pcvar_num(cvar_health)
	new viphealth = get_pcvar_num(cvar_health_vip)
	if( iHealth <=  health) 
	{
		set_rendering ( this, kRenderFxGlowShell, 255-255*iHealth/health, 255*iHealth/health, 0, kRenderNormal, 16)
	}
	else
	if( iHealth <= viphealth) 
	{
		set_rendering ( this, kRenderFxGlowShell, 0, 255-(255*iHealth-health)/(viphealth-health),255*(iHealth-health)/(viphealth-health), kRenderNormal, 16)
	}	
	return HAM_IGNORED;
}


public client_PreThink(id)
{	
	if(!is_user_alive(id))
		return;
	
	if(!g_pCar[id])
		return
		
	if(!pev_valid(g_pCar[id]))
		return;
	
	if(Parked[id])
		return;
	
	if (pev(g_pCar[id], pev_movetype) != MOVETYPE_PUSHSTEP)	
		return;
		
	static bitsButton;
	static oldButtons;
	bitsButton = pev(id, pev_button)	
	oldButtons = pev(id, pev_oldbuttons);
	
	if ((bitsButton &IN_USE)&&!(oldButtons & IN_USE))
	{
		new Float:vecOrigin[3];
		pev(g_pCar[id], pev_origin, vecOrigin);
		new ent = -1
		new classname[32]
		while((ent = find_ent_in_sphere(ent,vecOrigin,20.0)) != 0)
		{
			pev(ent,pev_classname,classname,charsmax(classname))
			if(equal(classname,"func_button"))
				dllfunc(DLLFunc_Use, ent, id)
		}		
	}
}
public RC_Think(this)
{
	if (pev_valid(this) != 2)
		return;

	static pOwner;
	pOwner = pev(this, pev_owner);

	if (!(1 <= pOwner <= g_iMaxPlayers) || !is_user_alive(pOwner))
		return;

	if (pev(this, pev_movetype) != MOVETYPE_PUSHSTEP)
	{
		static iBody, Float:vecColor[3], Float:vecOrigin[3], Float:vecAngles[3];

		GetOriginAimEndEyes(pOwner, 128, vecOrigin, vecAngles);
		iBody = 0;
		xs_vec_set(vecColor, 0.0, 150.0, 0.0);

		engfunc(EngFunc_SetOrigin, this, vecOrigin);

		vecOrigin[2] += 18.0;

		if (/*!IsOnGround(this) || */!IsHullVacant(vecOrigin, HULL_HEAD, this))
		{
			iBody = 1;
			xs_vec_set(vecColor, 150.0, 0.0, 0.0);
		}

		if (g_pBeam[pOwner] && is_valid_ent(g_pBeam[pOwner]))
		{
			Beam_RelinkBeam(g_pBeam[pOwner]);
			Beam_SetColor(g_pBeam[pOwner], vecColor);
		}

		set_pev(this, pev_angles, vecAngles);
		set_pev(this, pev_body, iBody);
		set_pev(this, pev_nextthink, get_gametime() + 0.01);
		return;
	}
	
	static bitsButton;
	bitsButton = pev(pOwner, pev_button)	
	
	/*
	if (bitsButton & IN_ATTACK2)
	{
		client_cmd(pOwner, "spk buttons/blip1.wav");

		if (!CheckPlayerBit(g_fViewEntCar, pOwner))
		{
			attach_view(pOwner, g_pTriggerCam);
			SetPlayerBit(g_fViewEntCar, pOwner);
		}
		else
		{
			attach_view(pOwner, pOwner);
			ClearPlayerBit(g_fViewEntCar, pOwner);
		}

		set_pev(this, pev_nextthink, get_gametime() + 0.2);
		return;
	}
	*/	
		
	if(Parked[pOwner])
	{	
		set_pev(this, pev_nextthink, get_gametime() + 0.2);
		return;		
	}
	
	if (!CheckPlayerBit(g_fViewEntCar, pOwner))
		bitsButton = 0;
		
	if (bitsButton & IN_ATTACK2)
	{
		cs_set_player_maxspeed_auto(pOwner, g_flMaxSpeed[pOwner]);
		attach_view(pOwner, pOwner);
		ClearPlayerBit(g_fViewEntCar, pOwner)
		Parked[pOwner]=true;
		ColorChat(pOwner, GREEN, "[GC]^3 Type^4 /rc^3 to drive the RC again!")
		set_pev(this, pev_framerate, 0.0);
		set_pev(this, pev_animtime, 0.0);
		set_pev(this, pev_nextthink, get_gametime() + 0.2);
		return;	
		
	}
	if (bitsButton & IN_ATTACK)
	{
		new Float:vecOrigin[3];
		pev(this, pev_origin, vecOrigin);

		remove_entity(this);
		return;
	}

	
	static Float:flSpeed, bool:bOnGround, Float:vecAngles[3], Float:vecSrc[3], Float:flGameTime;

	pev(this, pev_angles, vecAngles);
	pev(this, pev_origin, vecSrc);
	bOnGround = IsOnGround(this);	
	flGameTime = get_gametime();

	if (!flSpeed)
	{
		static Float:vecVelocity[3];
		pev(this, pev_velocity, vecVelocity);
		flSpeed = vector_length(vecVelocity);
	}

	static Float:d;
	d = vecAngles[1] - g_vecAngles[pOwner][1];

	if (d > 180.0)
		d -= 360.0;
	else if (d < -180.0)
		d += 360.0;

	g_vecAngles[pOwner][1] += d * 0.15;

	ValidateAngles(g_vecAngles[pOwner][1]);
				
	if (bOnGround)
	{		
		g_bIsJumping[pOwner] = false;

		SetGroundAngles(this);

		static Float:vecGoal[3], Float:vecVelocity[3], Float:vecForward[3];

		//bitsButton = pev(pOwner, pev_button);
		pev(this, pev_angles, vecAngles);

		engfunc(EngFunc_MakeVectors, vecAngles);
		global_get(glb_v_forward, vecForward);

		vecForward[2] *= -1.0;

		if (bitsButton & IN_FORWARD)
		{
			flSpeed = floatmin(flSpeed + 28.0, 350.0);

			xs_vec_mul_scalar(vecForward, 0.05, vecVelocity);
			xs_vec_add(vecSrc, vecVelocity, vecGoal);
			engfunc(EngFunc_MoveToOrigin, this, vecGoal, vector_distance(vecSrc, vecGoal), 1);

			pev(this, pev_velocity, vecVelocity);
			xs_vec_mul_scalar(vecForward, flSpeed, vecVelocity);
			set_pev(this, pev_velocity, vecVelocity);
		}
		else if (bitsButton & IN_BACK)
		{
			flSpeed = floatmin(flSpeed + 28.0, 350.0);

			xs_vec_mul_scalar(vecForward, -0.05, vecVelocity);
			xs_vec_add(vecSrc, vecVelocity, vecGoal);
			engfunc(EngFunc_MoveToOrigin, this, vecGoal, vector_distance(vecSrc, vecGoal), 1);

			pev(this, pev_velocity, vecVelocity);
			xs_vec_mul_scalar(vecForward, -1.0 * flSpeed, vecVelocity);
			set_pev(this, pev_velocity, vecVelocity);
		}

		if (bitsButton & (IN_MOVELEFT|IN_LEFT))
		{
			vecAngles[1] += 4.0;
			ValidateAngles(vecAngles[1]);
			set_pev(this, pev_angles, vecAngles);
		}
		else if (bitsButton & (IN_MOVERIGHT|IN_RIGHT))
		{
			vecAngles[1] -= 4.0;
			ValidateAngles(vecAngles[1]);
			set_pev(this, pev_angles, vecAngles);
		}

		if (bitsButton & IN_JUMP)
		{
			pev(this, pev_velocity, vecVelocity);
			vecVelocity[2] = 400.0;
			set_pev(this, pev_velocity, vecVelocity);

			g_bIsJumping[pOwner] = true;
		}
	}
	else
	if (g_bIsJumping[pOwner])
	{		
		
		static Float:vecVelocity[3], Float:vecForward[3];
		
		bitsButton = pev(pOwner, pev_button);
		pev(this, pev_angles, vecAngles);
		pev(this, pev_velocity, vecVelocity);
		
		new Float:vec[3]
		pev(this,pev_origin,vec)
		new ent = -1
		while((ent = find_ent_in_sphere(ent,vec,20.0)) != 0)
		{
			if(FClassnameIs(ent, "func_ladder"))
			{						
				if (bitsButton & IN_FORWARD)
				{			
					vecVelocity[2] = 250.0;	
		
				}
				else if (bitsButton & IN_BACK)
				{			
					vecVelocity[2] = 250.0;
				}	
				else
				{				
					vecVelocity[2] = 0.0;
				}		
				
				if (bitsButton & (IN_MOVELEFT|IN_LEFT))
				{
					vecAngles[1] += 4.0;
					ValidateAngles(vecAngles[1]);
					set_pev(this, pev_angles, vecAngles);
				}
				else if (bitsButton & (IN_MOVERIGHT|IN_RIGHT))
				{
					vecAngles[1] -= 4.0;
					ValidateAngles(vecAngles[1]);
					set_pev(this, pev_angles, vecAngles);
				}
				break;
			}
		}	
		engfunc(EngFunc_MakeVectors, vecAngles);
		global_get(glb_v_forward, vecForward);
		
		if (bitsButton & IN_FORWARD)
		{
			vecVelocity[0] = vecForward[0] * 270.0;
			vecVelocity[1] = vecForward[1] * 270.0;

			set_pev(this, pev_velocity, vecVelocity);
		}
		else if (bitsButton & IN_BACK)
		{
			vecVelocity[0] = vecForward[0] * -270.0;
			vecVelocity[1] = vecForward[1] * -270.0;

			set_pev(this, pev_velocity, vecVelocity);
		}
	}				
	if(pev(this,pev_waterlevel))
	{				
		static Float:vecVelocity[3], Float:vecForward[3];
		
		bitsButton = pev(pOwner, pev_button);
		pev(this, pev_angles, vecAngles);
		pev(this, pev_velocity, vecVelocity);
		if(bitsButton& IN_JUMP)
			vecVelocity[2]=300.0;
		else
			vecVelocity[2]=-100.0;		
		
		if (bitsButton & (IN_MOVELEFT|IN_LEFT))
		{
			vecAngles[1] += 4.0;
			ValidateAngles(vecAngles[1]);
			set_pev(this, pev_angles, vecAngles);
		}
		else if (bitsButton & (IN_MOVERIGHT|IN_RIGHT))
		{
			vecAngles[1] -= 4.0;
			ValidateAngles(vecAngles[1]);
			set_pev(this, pev_angles, vecAngles);
		}		
		
		engfunc(EngFunc_MakeVectors, vecAngles);
		global_get(glb_v_forward, vecForward);
		
		if (bitsButton & IN_FORWARD)
		{
			vecVelocity[0] = vecForward[0] * 270.0;
			vecVelocity[1] = vecForward[1] * 270.0;
		}
		else if (bitsButton & IN_BACK)
		{
			vecVelocity[0] = vecForward[0] * -270.0;
			vecVelocity[1] = vecForward[1] * -270.0;
		}
		set_pev(this, pev_velocity, vecVelocity);
		
	}
	if (!get_speed(this) || !bOnGround)
	{
		flSpeed = 0.0;
		
		static Float:flFrameRate;
		pev(this, pev_framerate, flFrameRate);

		if (flFrameRate != 0.0)
		{
			set_pev(this, pev_framerate, 0.0);
			set_pev(this, pev_animtime, 0.0);
			emit_sound(this, CHAN_ITEM, RC_SOUND, 0.35, ATTN_NORM, SND_STOP, PITCH_NORM);
		}
	}
	else
	{
		static Float:flSoundTime;
		pev(this, pev_ltime, flSoundTime);

		if (flGameTime - flSoundTime > 1.0)
		{
			emit_sound(this, CHAN_ITEM, RC_SOUND, 0.35, ATTN_NORM, SND_STOP, PITCH_NORM);
			emit_sound(this, CHAN_ITEM, RC_SOUND, 0.35, ATTN_NORM, 0, PITCH_NORM);
			SetAnim(this, 0);
			set_pev(this, pev_ltime, flGameTime);
		}
	}

	set_pev(this, pev_nextthink, flGameTime + 0.02);
}

SetGroundAngles(this)
{
	static tr, Float:vecSrc[3], Float:vecEnd[3], Float:flFraction;

	pev(this, pev_origin, vecSrc);
	vecSrc[2] += 10.0;
	xs_vec_sub(vecSrc, Float:{0.0, 0.0, 20.0}, vecEnd);

	tr = create_tr2();

	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, IGNORE_MONSTERS, this, tr);
	get_tr2(tr, TR_flFraction, flFraction);

	if (flFraction < 1.0)
	{
		static Float:vecPlaneNormal[3], Float:vecForward[3], Float:vecRight[3], Float:vecAngles[3];

		pev(this, pev_angles, vecAngles);
		angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);

		get_tr2(tr, TR_vecPlaneNormal, vecPlaneNormal);

		xs_vec_cross(vecForward, vecPlaneNormal, vecRight);
		xs_vec_cross(vecPlaneNormal, vecRight, vecForward);

		static Float:flPitch, Float:vecAngles2[3];

		flPitch = vecAngles[1];
	
		vector_to_angle(vecForward, vecAngles);
		vector_to_angle(vecRight, vecAngles2);

		vecAngles[1] = flPitch;
		vecAngles[2] = -1.0 * vecAngles2[0];

		set_pev(this, pev_angles, vecAngles);
	}

	free_tr2(tr);
	return 1;
}

ValidateAngles(&Float:angles)
{
	if (angles > 360.0)
		angles -= 360.0;
	if (angles < 0.0)
		angles += 360.0;
}

public CBasePlayer_Killed(this)
{
	if (g_pCar[this] && pev_valid(g_pCar[this]))
		remove_entity(g_pCar[this]);
}

public CBasePlayer_UpdateData_Post(this)
{
	if (!is_user_alive(this))
		return;

	if (!g_pCar[this] || pev_valid(g_pCar[this]) != 2 || pev_valid(g_pTriggerCam) != 2)
		return;

	if (pev(g_pCar[this], pev_movetype) != MOVETYPE_PUSHSTEP)
		return;

	static Float:vecSrc[3], Float:vecEnd[3], Float:vecAngles[3], Float:vec[3];

	pev(g_pCar[this], pev_origin, vecSrc);

	g_vecOrigin[this][0] += (vecSrc[0] - g_vecOrigin[this][0]) * 0.14;
	g_vecOrigin[this][1] += (vecSrc[1] - g_vecOrigin[this][1]) * 0.14;
	g_vecOrigin[this][2] += (vecSrc[2] - g_vecOrigin[this][2]) * 0.14;

	//pev(g_pCar[this], pev_origin, vecSrc);
	//pev(g_pCar[this], pev_angles, vecAngles);
	xs_vec_copy(g_vecOrigin[this], vecSrc);
	xs_vec_copy(g_vecAngles[this], vecAngles)

	engfunc(EngFunc_MakeVectors, vecAngles);
	global_get(glb_v_forward, vec);
	vec[2] *= -1.0;
	//angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vec);

	//vec[2] *= -1.0;

	vecEnd[0] = vecSrc[0] + ((vec[0] * 100.0) * -1);
	vecEnd[1] = vecSrc[1] + ((vec[1] * 100.0) * -1);
	vecEnd[2] = vecSrc[2] + ((vec[2] * 100.0) * -1) + 45.0;


	//vecEnd[2] *= 2.0;


	static Float:flFraction;
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, IGNORE_MONSTERS, g_pCar[this], 0);
	get_tr2(0, TR_flFraction, flFraction);

	if (flFraction < 1.0)
		get_tr2(0, TR_vecEndPos, vecEnd);

	engfunc(EngFunc_SetOrigin, g_pTriggerCam, vecEnd);

	/*static Float:flDistance;
	flDistance = vector_distance(vecSrc, vecEnd);
	vec[0] = (vecSrc[0] - vecEnd[0]) / flDistance;
	vec[1] = (vecSrc[1] - vecEnd[1]) / flDistance;
	vec[2] = 0.3;
	vector_to_angle(vec, vecAngles);*/

	set_pev(g_pTriggerCam, pev_angles, vecAngles);
}

public OnFreeEntPrivateData(this)
{
	if (!FClassnameIs(this, RC_CLASSNAME))
		return FMRES_IGNORED;

	new pOwner = pev(this, pev_owner);

	if ((1 <= pOwner <= g_iMaxPlayers))
	{
		if (is_user_connected(pOwner))
		{
			if (pev(g_pCar[pOwner], pev_movetype) == MOVETYPE_PUSHSTEP)
			{
				cs_set_player_maxspeed_auto(pOwner, g_flMaxSpeed[pOwner]);
				attach_view(pOwner, pOwner);		
				new Float:vecOrigin[3]
				pev(this,pev_origin,vecOrigin)
				ExplosionCreate(pOwner, vecOrigin);
			}
		}

		if (g_pBeam[pOwner] && is_valid_ent(g_pBeam[pOwner]))
			remove_entity(g_pBeam[pOwner]);

		g_pCar[pOwner] = 0;
		g_pBeam[pOwner] = 0;
		Parked[pOwner] = 0;
		ClearPlayerBit(g_fViewEntCar, pOwner);
	}

	emit_sound(this, CHAN_ITEM, RC_SOUND, 0.35, ATTN_NORM, SND_STOP, PITCH_NORM);
	set_pev(this, pev_framerate, 0.0);

	return FMRES_IGNORED;
}

FClassnameIs(this, const szClassName[])
{
	if (pev_valid(this) != 2)
		return 0;

	new szpClassName[32];
	pev(this, pev_classname, szpClassName, charsmax(szpClassName));

	return equal(szClassName, szpClassName);
}

ExplosionCreate(this, Float:vecOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecOrigin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 32)
	write_short(explosion)
	write_byte(60)
	write_byte(30)
	write_byte(10)
	message_end()
	/*
	new AuthID[32]
	new isEmma,isNala;	
	get_user_authid(this ,AuthID,31)
	if(equali(AuthID,"STEAM_0:0:555283776"))
	{
		isEmma=true;
	}
	else
	if(equali(AuthID,"STEAM_0:0:2055819299"))
	{
		isNala=true
	}
	*/
	
	new Float:PlayerPos[3], Float:distance, Float:damage
	
	for (new i = 1; i < 33; i++) 
	{
		if(!is_user_connected(i))
			continue;
		if(!is_user_alive(i)) 
			continue;		
		
		pev(i, pev_origin, PlayerPos)
		
		distance = get_distance_f(PlayerPos, vecOrigin)
		if (distance <= get_pcvar_num(rc_radius))
		{
			new FinalDamage
			damage = get_pcvar_float(cvar_damage)*(1.0-distance/get_pcvar_float(rc_radius))
			new attacker = this		
			if(zp_item_zombie_madness_get(i))
			{
				FinalDamage = floatround(damage / 3)
				if(get_user_health(i)<FinalDamage)
					FinalDamage=get_user_health(i)-1;
			}
			else
				FinalDamage = floatround(damage)
				
			if (zp_core_is_zombie(i))
			{				
				if(zp_grenade_frost_get(i))
					zp_grenade_frost_set(i, false)

				ExecuteHam(Ham_TakeDamage, i, 0, attacker, float(FinalDamage), DMG_GRENADE)		
				bd_show_damage(attacker, FinalDamage, 0, 1)
				bd_show_damage(i, FinalDamage, 1, 0)
				if(is_user_alive(i))
				{
					new Float:Power = (damage - distance) / 3.0
					new Float:zKnockback = 1.0
					KnockbackPlayer(i, vecOrigin, zKnockback, distance, Power, 2)
				}
			}

		}
	}
/*
	new pExplosion = create_entity("env_explosion");

	if (!pExplosion)
		return;

	engfunc(EngFunc_SetOrigin, pExplosion, vecOrigin);
	set_pev(pExplosion, pev_classname, RCEXP_CLASSNAME);
	set_pev(pExplosion, pev_owner, pOwner);
	set_pev(pExplosion, pev_dmg, flMultiplier);

	if (!bDoDamage)
		set_pev(pExplosion, pev_spawnflags, pev(pExplosion, pev_spawnflags) | SF_ENVEXPLOSION_NODAMAGE);

	new szMagnitude[22];
	formatex(szMagnitude, charsmax(szMagnitude), "%3d", iMagnitude);

	DispatchKeyValue(pExplosion, "iMagnitude", szMagnitude);
	DispatchSpawn(pExplosion);
	force_use(pExplosion, pExplosion);
*/
}

stock KnockbackPlayer(ent, Float:VicOrigin[3], Float:speed, Float:distance, Float:Minus, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	
	pev(ent, pev_origin, EntOrigin)
	
	new Float:fl_Time = distance / speed
	//ColorChat(0,GREEN,"KB [0]: %d", floatround(fl_Time))	
	if (type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time)// * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time)// * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time	
	}
	else if (type == 2)
	{
		if(distance > 100.0)
		{
			fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0])) * Minus
			fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1])) * Minus
			fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) * Minus
		}
		else
		{
			fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0])) * Minus * 2.0
			fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1])) * Minus * 2.0
			fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) * Minus * 2.0
		}
			
	//	ColorChat(0,GREEN,"KB [1]: %d | KB [2]: %d | KB [3]: %d", floatround(fl_Velocity[0]), floatround(fl_Velocity[1]), floatround(fl_Velocity[2]))	
	}
	
	set_pev(ent, pev_velocity, fl_Velocity)
}
SetAnim(this, iAnim, Float:flFrameRate = 1.0)
{
	set_pev(this, pev_sequence, iAnim);
	set_pev(this, pev_frame, 0.0);
	set_pev(this, pev_animtime, get_gametime());
	set_pev(this, pev_framerate, flFrameRate);
}

bool:IsOnGround(this)
{
	static Float:vecSrc[3], Float:vecEnd[3];
	pev(this, pev_origin, vecSrc);
	xs_vec_sub(vecSrc, Float:{ 0.0, 0.0, 10.0 }, vecEnd);

	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, IGNORE_MONSTERS, this, 0);

	static Float:flFraction;
	get_tr2(0, TR_flFraction, flFraction);

	if (!(pev(this, pev_flags) & FL_ONGROUND) && flFraction == 1.0)
		return false;

	return true;
}

bool:IsHullVacant(const Float:vecSrc[3], iHull, pEntToSkip = 0)
{
	engfunc(EngFunc_TraceHull, vecSrc, vecSrc, DONT_IGNORE_MONSTERS, iHull, pEntToSkip, 0);
	return bool:(!get_tr2(0, TR_AllSolid) && !get_tr2(0, TR_StartSolid) && get_tr2(0, TR_InOpen));
}

GetOriginAimEndEyes(this, iDistance, Float:vecOut[3], Float:vecAngles[3])
{
	static Float:vecSrc[3], Float:vecEnd[3], Float:vecViewOfs[3], Float:vecVelocity[3];
	static Float:flFraction;

	pev(this, pev_origin, vecSrc);
	pev(this, pev_view_ofs, vecViewOfs);

	xs_vec_add(vecSrc, vecViewOfs, vecSrc);
	velocity_by_aim(this, iDistance, vecVelocity);
	xs_vec_add(vecSrc, vecVelocity, vecEnd);

	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, this, 0);

	get_tr2(0, TR_flFraction, flFraction);

	if (flFraction < 1.0)
	{
		static Float:vecPlaneNormal[3];

		get_tr2(0, TR_PlaneNormal, vecPlaneNormal);
		get_tr2(0, TR_vecEndPos, vecOut);

		xs_vec_mul_scalar(vecPlaneNormal, 8.0, vecPlaneNormal);
		xs_vec_add(vecOut, vecPlaneNormal, vecOut);
	}
	else
	{
		xs_vec_copy(vecEnd, vecOut);
	}

	vecVelocity[2] = 0.0;
	vector_to_angle(vecVelocity, vecAngles);
}

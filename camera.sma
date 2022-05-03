/* BIG CREDITS FOR ConnorMcLeod
I Only just modified the front camera and added a scale controlled by a player, so he can zoom in/out! & added a menu*/

#include <amxmodx> 
#include <fakemeta> 
#include <hamsandwich> 

#define VERSION "0.0.3" 

#define USE_TOGGLE 3

#define MAX_BACKWARD_UNITS	-200.0
#define MAX_FORWARD_UNITS	200.0

new g_iPlayerCamera[33], Float:g_camera_position[33];

public plugin_init()
{
	register_plugin("Camera View Menu", VERSION, "ConnorMcLeod & Natsheh") 
	
	register_clcmd("say /cam", "camera_menu")
	register_clcmd("say_team /cam", "camera_menu")
	
	register_forward(FM_SetView, "SetView") 
	RegisterHam(Ham_Think, "trigger_camera", "Camera_Think")
}

public camera_menu(id)
{
	if(!is_user_alive(id)) return;
	
	new menu = menu_create("Choose an option!", "cam_m_handler"), sText[48], bool:mode = (g_iPlayerCamera[id] > 0) ? true:false;
	
	formatex(sText, charsmax(sText), "%s \r3RD Person camera!", (mode) ? "\dDisable":"\yEnable")
	menu_additem(menu, sText)
	
	if(mode)
	{
		menu_additem(menu, "Forward Further!")
		menu_additem(menu, "Backward Further!")
	}
	
	menu_display(id, menu)
}

public cam_m_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	
	menu_destroy(menu);
	
	if(g_iPlayerCamera[id] > 0 && item == 0)
	{		
		new iEnt = g_iPlayerCamera[id];
		if(pev_valid(iEnt)) engfunc(EngFunc_RemoveEntity, iEnt);
		g_iPlayerCamera[id] = 0;
		g_camera_position[id] = -100.0;
		engfunc(EngFunc_SetView, id, id);
	}
	else
	{
		switch( item )
		{
			case 0:
			{
				g_camera_position[id] = -150.0;
				enable_camera(id)
			}
			case 1: if(g_camera_position[id] < MAX_FORWARD_UNITS) g_camera_position[id] += 50.0;
			case 2: if(g_camera_position[id] > MAX_BACKWARD_UNITS) g_camera_position[id] -= 50.0;
		}
	}
	
	return 1;
}

public enable_camera(id)
{ 
	if(!is_user_alive(id)) return;
	
	new iEnt = g_iPlayerCamera[id] 
	if(!pev_valid(iEnt))
	{
		static iszTriggerCamera 
		if( !iszTriggerCamera ) 
		{ 
			iszTriggerCamera = engfunc(EngFunc_AllocString, "trigger_camera") 
		} 
		
		iEnt = engfunc(EngFunc_CreateNamedEntity, iszTriggerCamera);
		set_kvd(0, KV_ClassName, "trigger_camera") 
		set_kvd(0, KV_fHandled, 0) 
		set_kvd(0, KV_KeyName, "wait") 
		set_kvd(0, KV_Value, "999999") 
		dllfunc(DLLFunc_KeyValue, iEnt, 0) 
	
		set_pev(iEnt, pev_spawnflags, SF_CAMERA_PLAYER_TARGET|SF_CAMERA_PLAYER_POSITION) 
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_ALWAYSTHINK) 
	
		dllfunc(DLLFunc_Spawn, iEnt)
	
		g_iPlayerCamera[id] = iEnt;
 //   } 	
		new Float:flMaxSpeed, iFlags = pev(id, pev_flags) 
		pev(id, pev_maxspeed, flMaxSpeed)
		
		ExecuteHam(Ham_Use, iEnt, id, id, USE_TOGGLE, 1.0)
		
		set_pev(id, pev_flags, iFlags)
		// depending on mod, you may have to send SetClientMaxspeed here. 
		// engfunc(EngFunc_SetClientMaxspeed, id, flMaxSpeed) 
		set_pev(id, pev_maxspeed, flMaxSpeed)
	}
}

public SetView(id, iEnt) 
{ 
	if(is_user_alive(id))
	{
		new iCamera = g_iPlayerCamera[id] 
		if( iCamera && iEnt != iCamera ) 
		{ 
			new szClassName[16] 
			pev(iEnt, pev_classname, szClassName, charsmax(szClassName)) 
			if(!equal(szClassName, "trigger_camera")) // should let real cams enabled 
			{ 
				engfunc(EngFunc_SetView, id, iCamera) // shouldn't be always needed 
				return FMRES_SUPERCEDE 
			} 
		} 
	} 
	return FMRES_IGNORED 
}

public client_disconnected(id) 
{ 
	new iEnt = g_iPlayerCamera[id];
	if(pev_valid(iEnt)) engfunc(EngFunc_RemoveEntity, iEnt);
	g_iPlayerCamera[id] = 0;
	g_camera_position[id] = -100.0;
} 

public client_putinserver(id) 
{
	g_iPlayerCamera[id] = 0
	g_camera_position[id] = -100.0;
} 

get_cam_owner(iEnt) 
{ 
	new players[32], pnum;
	get_players(players, pnum, "ch");
	
	for(new id, i; i < pnum; i++)
	{ 
		id = players[i];
		
		if(g_iPlayerCamera[id] == iEnt)
		{
			return id;
		}
	}
	
	return 0;
} 

public Camera_Think(iEnt)
{
	static id;
	if(!(id = get_cam_owner(iEnt))) return ;
	
	static Float:fVecPlayerOrigin[3], Float:fVecCameraOrigin[3], Float:fVecAngles[3], Float:fVec[3];
	
	pev(id, pev_origin, fVecPlayerOrigin) 
	pev(id, pev_view_ofs, fVecAngles) 
	fVecPlayerOrigin[2] += fVecAngles[2] 
	
	pev(id, pev_v_angle, fVecAngles) 
	
	angle_vector(fVecAngles, ANGLEVECTOR_FORWARD, fVec);
	static Float:units; units = g_camera_position[id];
	
	//Move back/forward to see ourself
	fVecCameraOrigin[0] = fVecPlayerOrigin[0] + (fVec[0] * units)
	fVecCameraOrigin[1] = fVecPlayerOrigin[1] + (fVec[1] * units) 
	fVecCameraOrigin[2] = fVecPlayerOrigin[2] + (fVec[2] * units) + 15.0
	
	static tr2; tr2 = create_tr2();
	engfunc(EngFunc_TraceLine, fVecPlayerOrigin, fVecCameraOrigin, IGNORE_MONSTERS, id, tr2)
	static Float:flFraction 
	get_tr2(tr2, TR_flFraction, flFraction)
	if( flFraction != 1.0 ) // adjust camera place if close to a wall 
	{
		flFraction *= units;
		fVecCameraOrigin[0] = fVecPlayerOrigin[0] + (fVec[0] * flFraction);
		fVecCameraOrigin[1] = fVecPlayerOrigin[1] + (fVec[1] * flFraction);
		fVecCameraOrigin[2] = fVecPlayerOrigin[2] + (fVec[2] * flFraction);
	}
	
	if(units > 0.0)
	{
		fVecAngles[0] *= fVecAngles[0] > 180.0 ? 1:-1
		fVecAngles[1] += fVecAngles[1] > 180.0 ? -180.0:180.0
	}
	
	set_pev(iEnt, pev_origin, fVecCameraOrigin); 
	set_pev(iEnt, pev_angles, fVecAngles);
	
	free_tr2(tr2);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/

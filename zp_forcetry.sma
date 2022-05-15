/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <colorchat>
#include <zp50_gamemodes>
#include <fun>
#include <hamsandwich>
#include <fakemeta>
#include <engine>

#define PLUGIN "Force Try"
#define VERSION "1.0"
#define AUTHOR "zXCaptainXz"

#define Freeze(%1)     	 (frozen |= (1<<(%1&31)))
#define UnFreeze(%1)   	 (frozen &= ~(1<<(%1&31)))
#define IsFrozen(%1)     (frozen & (1<<(%1&31))) 

#define GRAVITY_HIGH 999999.9
#define GRAVITY_NONE 0.000001


new iAdminOrigin[33][3];
new Float:iAdminAngle[33][3];

new Float:LastDeath[33];
new Float:LastInfect[33];
new Deaths[33], Infects[33];
// Hack to be able to use Ham_Player_ResetMaxSpeed (by joaquimandrade)
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame

new frozen;
new g_PreThinkId;
//new CaptainID=-1;
new Float: g_Angles[33][3];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("amx_tryset","SetOrigin",ADMIN_SLAY,"- Sets teleport location")	
	register_clcmd("amx_lasttry","LastTryCmd",ADMIN_SLAY,"<name or #userid> - Shows player infection/death stats")
	register_clcmd("say /tryset","SetOrigin",ADMIN_SLAY,"- Sets teleport location")
	register_clcmd("amx_try","ForceTryCmd",ADMIN_SLAY,"<name or #userid> - Teleports player to location")		
	register_clcmd("say", "handleSay")
	
	register_clcmd( " say /tp","TryMenuCmd",ADMIN_SLAY , "- Opens Teleport Menu");
	register_clcmd( " say_team /tp","TryMenuCmd",ADMIN_SLAY, "- Opens Teleport Menu");
	register_clcmd( "amx_trymenu","TryMenuCmd",ADMIN_SLAY , "- Opens Teleport Menu");
	RegisterHam(Ham_Killed,"player","Player_Death")
	RegisterHam(Ham_Player_ResetMaxSpeed, "player", "fw_ResetMaxSpeed_Post", 1)
}

public plugin_natives()
{
	register_native("show_teleport_menu","TryMenu",1);
}

public TryMenuCmd( id,level,cid)
{
	if (!cmd_access(id, level, cid, 0))
		return PLUGIN_HANDLED;
		
	TryMenu(id);
	return PLUGIN_HANDLED;	
}

public TryMenu(id)
{
	new menu = menu_create( "\rTeleport\y Menu", "menu_handler" );	
			
	menu_additem( menu, "Define Location");	
	menu_additem( menu, "Teleport Current Player");	
	menu_additem( menu, "Current Player Last Try");	
	menu_display( id, menu);
	return PLUGIN_HANDLED;
}
public menu_handler( id, menu, item )
{
	switch( item )
	{
		case 0:
		{
			get_user_origin(id,iAdminOrigin[id],0);	
			entity_get_vector(id, EV_VEC_angles, iAdminAngle[id]); 
			client_print(id,print_console,"Location defined!");
			ColorChat(id,GREEN,"[GC]^3 Teleport location defined!");
		}
		
		case 1:
		{						
			ForceTry(id, "");
		}
		
		case 2:
		{						
			LastTry(id, "");
		}
		
		case MENU_EXIT:
		{
			menu_destroy(menu)
			return PLUGIN_HANDLED;
		}
	}
	
	menu_destroy(menu)
	TryMenu(id)
	return PLUGIN_HANDLED;
}
public handleSay(id)
{
	if(!(get_user_flags(id)&ADMIN_SLAY))
		return PLUGIN_CONTINUE;
	
	new args[64]
	
	read_args(args, charsmax(args))
	remove_quotes(args)
	
	new arg1[16]
	new arg2[32]
	
	argbreak(args, arg1, charsmax(arg1), arg2, charsmax(arg2))
	if (equali(arg1,"/try"))
	{
		ForceTry(id, arg2)
		return PLUGIN_HANDLED;
	}
	else
	if(equali(arg1,"/lasttry"))
	{
		LastTry(id,arg2);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

/*
public client_putinserver(id)
{
	new AuthID[32]
	get_user_authid(id,AuthID,charsmax(AuthID))
	if(equali(AuthID,"STEAM_0:0:1291169669"))
		CaptainID = id;
}*/

public client_disconnected(id)
{
	//if(id==CaptainID)
	//{
	//	CaptainID = -1;
	//}
	iAdminAngle[id][0]=0.0
	iAdminAngle[id][1]=0.0
	iAdminAngle[id][2]=0.0
	iAdminOrigin[id]={0,0,0}
	LastDeath[id]=0.0;
	LastInfect[id]=0.0;
	Deaths[id]=0;
	Infects[id]=0;
	if(IsFrozen(id))
		UnFreeze(id);
	
	if(!frozen && g_PreThinkId)
	{
		unregister_forward(FM_PlayerPreThink, g_PreThinkId);
		
		g_PreThinkId = 0;
	}
}

public SetOrigin(id,level,cid)
{	
	if (!cmd_access(id, level, cid, 0))
		return PLUGIN_HANDLED
	get_user_origin(id,iAdminOrigin[id],0);	
	entity_get_vector(id, EV_VEC_angles, iAdminAngle[id]); 
	client_print(id,print_console,"Location defined!");
	ColorChat(id,GREEN,"[GC]^3 Teleport location defined!");
	return PLUGIN_HANDLED;		
}

public ForceTryCmd(id,level,cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED	
	
	new arg[32];	
	read_argv(1, arg, charsmax(arg))
	ForceTry(id, arg)
	
	return PLUGIN_HANDLED;
}

public ForceTry(id, arg[])
{	
	if(iAdminAngle[id][0]==0&&iAdminAngle[id][1]==0&&iAdminAngle[id][2]==0&&iAdminOrigin[id][0]==0&&iAdminOrigin[id][1]==0&&iAdminOrigin[id][2]==0)
	{
		client_print(id,print_console,"You must use 1. Define Location or amx_tryset to define a location first!");
		ColorChat(id, GREEN, "[GC]^3 You must use^4 1. Define Location^3 or^4 /tryset^3 or^4 amx_tryset^3 to define a location first!");
		return PLUGIN_HANDLED
	}		
		
	new player;
	if(!arg[0])
	{	
		//get the spec mode
		new mode = pev(id, pev_iuser1)
		if (mode == 2 || mode==4||mode ==6)
		{	
			//get the spectated player
			player = pev(id, pev_iuser2)	
		}
		else
		{
			new body
			get_user_aiming(id, player,body)
			if(!player)
			{		
				client_print(id,print_console,"You must aim at or spectate a player!");
				ColorChat(id,GREEN,"[GC]^3 You must^4 aim at or spectate^3 a player!");
				return PLUGIN_HANDLED;	
			}
		}
		/*new body
		get_user_aiming(id, player,body)
		if(!player)
		{
			//get the spec mode
			new mode = pev(id, pev_iuser1)
			if (mode != 2 && mode!=4 && mode !=6)
			{			
				client_print(id,print_console,"You must aim at or spectate a player!");
				ColorChat(id,GREEN,"[GC]^3 You must^4 aim at or spectate^3 a player!");
				return PLUGIN_HANDLED;		
			}	
		}	*/	
	}
	else
	{
		player = cmd_target(id, arg,  0)	
	}
	
	if (!player)
	{
		ColorChat(id, GREEN, "[GC]^3 No or multiple players with this name!")
		return PLUGIN_HANDLED
	}
	
	if((player!=id)&&((get_user_flags(player)&ADMIN_RCON)||((get_user_flags(player) & ADMIN_IMMUNITY)&&!(get_user_flags(id)&ADMIN_RCON))))
	{
		console_print(id,"[GC]^3 You don't have enough access!")
		return PLUGIN_HANDLED;
	}
	
	if(!is_user_alive(player))
	{
		client_print(id,print_console,"Player is dead!");
		ColorChat(id,GREEN,"[GC]^3 Dead Player!");
		return PLUGIN_HANDLED
	}
	if(!(zp_core_is_zombie(player)))
	{
		client_print(id,print_console,"Player is not a zombie!");
		ColorChat(id,GREEN,"[GC]^3 Player is not a^4 Zombie!");
		return PLUGIN_HANDLED
	}
	if(player==id)
	{
		client_print(id,print_console,"You are not allowed to use this on yourself!");
		ColorChat(id,GREEN,"[GC]^3 You are not allowed to use this on yourself!");
		return PLUGIN_HANDLED
	}
	client_print(id,print_console,"Player has been teleported")
	
	client_cmd(player,"+duck");
	
	new param[2];
	param[0]=id;
	param[1]=player;
	set_task(1.0,"Teleport",0,param,sizeof(param));
	
	return PLUGIN_HANDLED;
}
public Teleport(param[])
{	
	new id = param[0]
	new player = param[1]
	
	if(!is_user_connected(player))
	{
		return
	}
	if(!is_user_alive(player))
	{
		return
	}
	if(!(zp_core_is_zombie(player)))
	{
		return
	}
	
	new playername[32]
	new adminname[32]
	get_user_name(player,playername,charsmax(playername))
	get_user_name(id,adminname,charsmax(adminname))
	//if(id!=CaptainID)
	//{
	new authid[32],authid2[32];
	get_user_authid(id,authid,32)
	get_user_authid(player,authid2,32)
	
	log_amx("Cmd: ^"%s<%d><%s><>^" teleported ^"%s<%d><%s><>^"", adminname, get_user_userid(id), authid,  playername, get_user_userid(player), authid2)
	
	for(new i=1;i<33;i++)
	{
		if(is_user_connected(i))
		ColorChat(i,NORMAL,"ADMIN ^4%s^1 forced ^4%s^1 to attack humans by teleporting him!",adminname,playername)
	}
	ColorChat(player,TEAM_COLOR,"ADMIN ^4%s^3 teleported you to a human campspot. Go ^4ATTACK^3 or get  ^4BANNED!",adminname)
	ColorChat(player,TEAM_COLOR,"ADMIN ^4%s^3 teleported you to a human campspot. Go ^4ATTACK^3 or get  ^4BANNED!",adminname)
	ColorChat(player,TEAM_COLOR,"ADMIN ^4%s^3 teleported you to a human campspot. Go ^4ATTACK^3 or get  ^4BANNED!",adminname)
	ColorChat(player,TEAM_COLOR,"ADMIN ^4%s^3 teleported you to a human campspot. Go ^4ATTACK^3 or get  ^4BANNED!",adminname)
	ColorChat(player,TEAM_COLOR,"ADMIN ^4%s^3 teleported you to a human campspot. Go ^4ATTACK^3 or get  ^4BANNED!",adminname)
	/*}
	else
	{
		adminname="ANONYMOUS"
		ColorChat(player,TEAM_COLOR,"ADMIN ^4%s^3 teleported you to a human campspot. Go ^4ATTACK^3 or get  ^4BANNED!",adminname)
		ColorChat(player,TEAM_COLOR,"ADMIN ^4%s^3 teleported you to a human campspot. Go ^4ATTACK^3 or get  ^4BANNED!",adminname)
		ColorChat(player,TEAM_COLOR,"ADMIN ^4%s^3 teleported you to a human campspot. Go ^4ATTACK^3 or get  ^4BANNED!",adminname)
		ColorChat(player,TEAM_COLOR,"ADMIN ^4%s^3 teleported you to a human campspot. Go ^4ATTACK^3 or get  ^4BANNED!",adminname)
		ColorChat(player,TEAM_COLOR,"ADMIN ^4%s^3 teleported you to a human campspot. Go ^4ATTACK^3 or get  ^4BANNED!",adminname)
	}*/

	
	
	set_user_origin(player,iAdminOrigin[id])
	
	if(!frozen && !g_PreThinkId)
		g_PreThinkId = register_forward(FM_PlayerPreThink, "Fwd_PlayerPreThink");	
	
	pev(player, pev_v_angle, g_Angles[player]);
	
		
	entity_set_vector(player, EV_VEC_angles, iAdminAngle[id]);
	entity_set_int(player, EV_INT_fixangle, 1);
	
	
	Freeze(player);		
	ExecuteHamB(Ham_Player_ResetMaxSpeed, player)
	set_task(5.0, "Task_Unfreeze", player);
}

public Task_Unfreeze(id)
{
	if(is_user_connected(id))
	{
		UnFreeze(id);		
		set_pev(id, pev_fixangle, 0);
		client_cmd(id,"-duck")
		
		// Update player's maxspeed
		ExecuteHamB(Ham_Player_ResetMaxSpeed, id)	
		if(!frozen && g_PreThinkId)
		{
			unregister_forward(FM_PlayerPreThink, g_PreThinkId);
			
			g_PreThinkId = 0;
		}
	}
}

public Fwd_PlayerPreThink(id)
{
	if(IsFrozen(id))
	{
		if(is_user_alive(id))
		{			
			set_pev(id, pev_v_angle, g_Angles[id]);
			set_pev(id, pev_fixangle, 1);			
			set_pev(id, pev_velocity, Float:{0.0,0.0,0.0})
		}
	}
}

public fw_ResetMaxSpeed_Post(id)
{
	// Dead or not frozen
	if (!is_user_alive(id) || !IsFrozen(id))
		return;
	
	// Prevent from moving
	set_user_maxspeed(id, 1.0)
}


public LastTryCmd(id,level,cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED	
	
	new arg[32];
	
	read_argv(1, arg, charsmax(arg))
	LastTry(id, arg);	
	return PLUGIN_HANDLED;
}

public LastTry(id, arg[])
{
	new player;
	if(!arg[0])
	{	
		//get the spec mode
		new mode = pev(id, pev_iuser1)
		if (mode == 2 || mode==4||mode ==6)
		{	
			//get the spectated player
			player = pev(id, pev_iuser2)	
		}
		else
		{
			new body
			get_user_aiming(id, player,body)
			if(!player)
			{		
				client_print(id,print_console,"You must aim at or spectate a player!");
				ColorChat(id,GREEN,"[GC]^3 You must^4 aim at or spectate^3 a player!");
				return PLUGIN_HANDLED;	
			}
		}		
	}
	else
	{
		player = cmd_target(id, arg,  0)	
	}
	
	if (!player)
	{
		ColorChat(id, GREEN, "[GC]^3 No or multiple players with this name!")
		return PLUGIN_HANDLED
	}		
	
	if(!zp_core_is_zombie(player))
	{
		ColorChat(id, GREEN, "[GC]^3 Player is not a zombie!")
		client_print(id, print_console, "Player is not a zombie!")
		return PLUGIN_HANDLED;		
	}
	
	static Float:gt;
	static name[32]
	gt=get_gametime();
	get_user_name(player,name,charsmax(name))
	if(!Deaths[player]&&!Infects[player])		
	{
		ColorChat(id, GREEN, "%s^3 didn't infect/die yet for ^4%d s.",name,floatround(gt-LastDeath[player]))
		client_print(id, print_console, "%s didn't infect/die yet for ^4%d s",name,floatround(gt-LastDeath[player]))
	}
	else
	if(!Deaths[player])
	{
		ColorChat(id, GREEN, "%s^3 didn't die yet for^4 %d s^3. ^4%d^3 Infection(s): Last ^4%d s^3 ago.",name,floatround(gt-LastDeath[player]),Infects[player],floatround(gt-LastInfect[player]))
		client_print(id, print_console, "%s didn't die yet for %d s. %d Infection(s): Last %d s ago.",name,floatround(gt-LastDeath[player]),Infects[player],floatround(gt-LastInfect[player]))
	}
	else
	if(!Infects[player])
	{
		ColorChat(id, GREEN, "%s: %d^3 Death(s): Last ^4%d s^3 ago. Didn't infect yet for ^4%d s.",name, Deaths[player],floatround(gt-LastDeath[player]),floatround(gt-LastInfect[player]))
		client_print(id, print_console, "%s: %d Death(s): Last %d s ago. Didn't infect yet for %d s.",name, Deaths[player],floatround(gt-LastDeath[player]),floatround(gt-LastInfect[player]))
	}
	else	
	{
		ColorChat(id, GREEN, "%s: %d^3 Death(s): Last ^4%d s^3 ago. ^4%d^3 Infection(s): Last ^4%d s^3 ago.",name,Deaths[player],floatround(gt-LastDeath[player]),Infects[player],floatround(gt-LastInfect[player]))
		client_print(id, print_console, "%s: %d Death(s): Last %d s ago. %d Infection(s): Last %d s ago.",name,Deaths[player],floatround(gt-LastDeath[player]),Infects[player],floatround(gt-LastInfect[player]))
	}
	return PLUGIN_HANDLED;
}
public Player_Death(id, attacker)
{
	if(zp_core_is_zombie(id))
	{
		static Float:gt;
		gt=get_gametime();
		
		LastDeath[id]=gt;
		Deaths[id]++;
	}
}

public zp_fw_core_infect_post(victim, infector)
{
	static Float:gt;
	gt=get_gametime();
	if(!Deaths[victim])
	{
		LastDeath[victim]=gt;
		LastInfect[victim]=gt;
	}
	
	if(is_user_connected(infector))
	{
		if(victim!=infector)
		{			
			LastInfect[infector]=gt;
			Infects[infector]++;
		}
	}
}

public zp_fw_core_cure_post(id)
{	
	Deaths[id]=0;
	Infects[id]=0;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
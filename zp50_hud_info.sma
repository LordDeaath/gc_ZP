/*================================================================================
	
	----------------------------
	-*- [ZP] HUD Information -*-
	----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/
#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fvault>
#include <fakemeta>
#include <zp50_class_human>
#include <zp50_class_zombie>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_PREDATOR "zp50_class_predator"
#include <zp50_class_predator>
#define LIBRARY_DRAGON "zp50_class_dragon"
#include <zp50_class_dragon>
#define LIBRARY_NIGHTCRAWLER "zp50_class_nightcrawler"
#include <zp50_class_nightcrawler>
#define LIBRARY_ASSASSIN "zp50_class_assassin"
#include <zp50_class_assassin>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#define LIBRARY_SNIPER "zp50_class_sniper"
#include <zp50_class_sniper>
#define LIBRARY_PLASMA "zp50_class_plasma"
#include <zp50_class_plasma>
#define LIBRARY_KNIFER "zp50_class_knifer"
#include <zp50_class_knifer>
#define LIBRARY_AMMOPACKS "zp50_ammopacks"
#include <zp50_ammopacks>
#include <zp50_fps>
#include <reapi_reunion>
#include <zp50_colorchat>
#include <user_afk_status>

native crxranks_get_user_xp(id)
native crxranks_get_user_next_xp(id)
native crxranks_get_user_level(id)
native crxranks_get_max_levels()
native crxranks_get_user_rank(id, buffer[], len)
new Float:g_flGameTime[33],Float:g_flFpsTime[33],Float:g_flWarnTime[33], g_iFrames[33], g_FrameRate[33];
new bool:Steam[33]
new Warn[33];
const Float:HUD_SPECT_X = 0.6
const Float:HUD_SPECT_Y = 0.7
//const Float:HUD_STATS_X = 0.02
//const Float:HUD_STATS_Y = 0.9
const Float:HUD_STATS_X = 0.02
const Float:HUD_STATS_Y = 0.82
const HUD_STATS_ZOMBIE_R = 200
const HUD_STATS_ZOMBIE_G = 250
const HUD_STATS_ZOMBIE_B = 0
const HUD_STATS_HUMAN_R = 0
const HUD_STATS_HUMAN_G = 200
const HUD_STATS_HUMAN_B = 250
const HUD_STATS_SPEC_R = 255
const HUD_STATS_SPEC_G = 255
const HUD_STATS_SPEC_B = 255
#define TASK_SHOWHUD 100
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)
const PEV_SPEC_TARGET = pev_iuser2
#define MAX_PLAYERS	32
new g_MsgSync[2]
new g_MsgStatusValue
new g_MsgStatusText
new const g_vault_name[] = "iLocations";
new Float:iXloc[33], Float:iYLoc[33];
new cvar_fps_limit, Sty[33]
public plugin_init()
{
	register_plugin("[ZP] HUD Information", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_MsgStatusValue = get_user_msgid("StatusValue")
	g_MsgStatusText = get_user_msgid("StatusText")
	cvar_fps_limit = register_cvar("zp_limit_fps","0")
	register_message( g_MsgStatusValue, "Message_Status")
	register_message( g_MsgStatusText, "Message_Status")
	register_clcmd("say /loc", "HudLoc")
	register_clcmd("say /hud", "HudLoc")
	register_clcmd("say /warns", "sWarn")	
	g_MsgSync [0]= CreateHudSyncObj()
	g_MsgSync[1]=CreateHudSyncObj();
}
public plugin_natives()
{
	register_native("zp_remove_hud","native_remove_hud",1)
	register_native("zp_enable_hud","native_enable_hud",1)
	register_native("get_user_fps","native_get_user_fps",1)
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public native_get_user_fps(id)
{
	return g_FrameRate[id];
}
public native_remove_hud(id)
{	
	remove_task(id+TASK_SHOWHUD)
}
public native_enable_hud(id)
{	
	set_task(0.1, "ShowHUD", id+TASK_SHOWHUD, _, _, "b")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_PREDATOR) ||equal(module, LIBRARY_DRAGON) || equal(module, LIBRARY_NIGHTCRAWLER) || equal(module, LIBRARY_SURVIVOR) || equal(module, LIBRARY_SNIPER) || equal(module, LIBRARY_KNIFER) || equal(module, LIBRARY_PLASMA) || equal(module, LIBRARY_AMMOPACKS)|| equal(module, LIBRARY_ASSASSIN) )
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public sWarn(id) zp_colored_print(id,"Warns: %d",Warn[id])
public client_PreThink(this)
{
	if (!is_user_alive(this))
	return;
	static Float:flGameTime;
	flGameTime = get_gametime();
	g_iFrames[this]++;
	if (flGameTime - g_flGameTime[this] < 1.0)
		return;
	g_flGameTime[this] = flGameTime;
	g_FrameRate[this] = g_iFrames[this];    
	g_iFrames[this] = 0;
	if(get_pcvar_num(cvar_fps_limit))
	{
		if (flGameTime - g_flFpsTime[this] < 2.0)
			return;
		g_flFpsTime[this] = flGameTime; 	
		if(g_FrameRate[this]>110)
		{
			Warn[this]++;
			zp_colored_print(this, "^3FPS >>> 100 ^1IS NOT ALLOWED!^4 [Warn %d/15]", Warn[this])
			zp_colored_print(this, "Set^3 fps_max 100 / developer 0^1 in your^3 Console!")
			if(Warn[this] >= 15)
			{
				new name[32]
				get_user_name(this, name, charsmax(name))
				server_cmd("kick #%d ^"Sorry, FPS higher than 100 is not allowed!^nSet fps_max 100 in console to play!", get_user_userid(this))
				zp_colored_print(0, "^3%s^1 was kicked for having higher than^3 100 FPS!",name)	
			}
		}
	}
}
public client_PostThink(this)
{
	if (!is_user_alive(this))
	return;
	static Float:flGameTime;
	flGameTime = get_gametime();	
	if (flGameTime - g_flWarnTime[this] < 15.0)
		return;
	g_flWarnTime[this] = flGameTime; 		
	if(Warn[this] > 0)
		Warn[this]--;
}
public client_putinserver(id)
{
	if (!is_user_bot(id))
	{
		if(get_pcvar_num(cvar_fps_limit))
		{
			Warn[id] = 0;
			client_cmd(id, "fps_override 0");
			if(is_user_steam(id))
			{
				Steam[id]=true;
			}
			else
			{
				Steam[id]=false;
				client_cmd(id, "developer 0");
				client_cmd(id, "fps_max 100");
				client_cmd(id, "fps_modem 100");
			}
		}
		// Set the custom HUD display task
		if(zp_fps_get_user_flags(id)&FPS_HUD_MAIN)
			return;
		set_task(0.1, "ShowHUD", id+TASK_SHOWHUD, _, _, "b")
	}
}
public client_disconnected(id)
{
	if(Warn[id] >= 5)
		Warn[id]-=5;
	SaveData(id);
	remove_task(id+TASK_SHOWHUD)
}

public client_authorized(plr)
{
    if( !is_user_hltv(plr) && !is_user_bot(plr) )
    {
        LoadData(plr);
    }
}
LoadData(plr)
{
    new authid[35]
    new authid_x[38],authid_y[38], authid_sty[40];
    get_user_authid(plr, authid, sizeof(authid) - 1);
    formatex(authid_x,charsmax(authid_x),"%s_x",authid)
    formatex(authid_y,charsmax(authid_y),"%s_y",authid)
    formatex(authid_sty,charsmax(authid_sty),"%s_sty",authid)

    new data[16];
    if( fvault_get_data(g_vault_name, authid_x, data, sizeof(data) - 1) )
        iXloc[plr] = str_to_float(data);
    else iXloc[plr] = HUD_STATS_X
    
    if( fvault_get_data(g_vault_name, authid_y, data, sizeof(data) - 1) )
        iYLoc[plr] = str_to_float(data);
    else iYLoc[plr] = HUD_STATS_Y
    
    if( fvault_get_data(g_vault_name, authid_sty, data, sizeof(data) - 1) )
        Sty[plr] = str_to_num(data);
    else Sty[plr] = 0
}

SaveData(plr)
{
    new authid[35]
    new authid_x[38],authid_y[38], authid_sty[40];
    get_user_authid(plr, authid, sizeof(authid) - 1);
    formatex(authid_x,charsmax(authid_x),"%s_x",authid)
    formatex(authid_y,charsmax(authid_y),"%s_y",authid)
    formatex(authid_sty,charsmax(authid_sty),"%s_sty",authid)
  
    new data[16];
    float_to_str(iXloc[plr], data, sizeof(data) - 1);
    fvault_set_data(g_vault_name, authid_x, data);
    float_to_str(iYLoc[plr], data, sizeof(data) - 1);
    fvault_set_data(g_vault_name, authid_y, data);
    num_to_str(Sty[plr], data, sizeof(data) - 1);
    fvault_set_data(g_vault_name, authid_sty, data);  
}
public HudLoc(id)
{
	new Mnu = menu_create("Hud settings","LocS")
	menu_additem(Mnu,"Move \yUP","",0) // y -0.04
	menu_additem(Mnu,"Move \yDOWN","",0) // y +0.04
	menu_additem(Mnu,"Move \rLEFT","",0) // x -0.04
	menu_additem(Mnu,"Move \rRIGHT","",0) // x +0.04
	if(!Sty[id])
		menu_additem(Mnu,"Hud Style \r[New]","",0) // x +0.04
	else menu_additem(Mnu,"Hud Style \r[Old]","",0) // x +0.04
	menu_display(id, Mnu)	
}
public LocS(id, menu, item)
{
	switch(item)
	{
		case 0: //up
		{
			if(iYLoc[id] <= 0.04)
				iYLoc[id] = 1.0
			else iYLoc[id] -= 0.04
			
			HudLoc(id)
		}
		case 1: //down
		{
			if(iYLoc[id] >= 1.0)
				iYLoc[id] = 0.04
			else iYLoc[id] += 0.04
			
			HudLoc(id)
		}
		case 2: //left
		{
			if(iXloc[id] <= 0.02)
				iXloc[id] = 1.0
			else iXloc[id] -= 0.04
			
			HudLoc(id)
		}
		case 3: //rigt
		{
			if(iXloc[id] >= 1.0)
				iXloc[id] = 0.02
			else iXloc[id] += 0.04
			
			HudLoc(id)
		}
		case 4: //Style
		{
			if(Sty[id])
				Sty[id] = 0
			else Sty[id] = 1
			
			HudLoc(id)
		}
	}
	menu_destroy(menu)
	
}

// Show HUD Task
public ShowHUD(taskid)
{
	new player = ID_SHOWHUD
	
	// Player dead?
	if (!is_user_alive(player))
	{
		// Get spectating target
		player = pev(player, PEV_SPEC_TARGET)
		
		// Target not alive
		if (!is_user_alive(player))
			return;
	}
	
	// Format classname
	static class_name[32], transkey[64]
	new rank[40]
	new red, green, blue
	
	if (zp_core_is_zombie(player)) // zombies
	{
		red = HUD_STATS_ZOMBIE_R
		green = HUD_STATS_ZOMBIE_G
		blue = HUD_STATS_ZOMBIE_B
		
		// Nemesis Class loaded?
		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player))
		{
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_NEMESIS")
		}
		// Predator Class loaded?
		else  if (LibraryExists(LIBRARY_PREDATOR, LibType_Library) && zp_class_predator_get(player))
		{
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_PREDATOR")
		}
		// Dragon Class loaded?
		else if (LibraryExists(LIBRARY_DRAGON, LibType_Library) && zp_class_dragon_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_DRAGON")		
		// Nightcrawler Class loaded?
		else if (LibraryExists(LIBRARY_NIGHTCRAWLER, LibType_Library) && zp_class_nightcrawler_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_NIGHTCRAWLER")					
		// Assassin Class loaded?
		else if (LibraryExists(LIBRARY_ASSASSIN, LibType_Library) && zp_class_assassin_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_ASSASSIN")
		else
		{
			zp_class_zombie_get_name(zp_class_zombie_get_current(player), class_name, charsmax(class_name))
			
			// ML support for class name
			formatex(transkey, charsmax(transkey), "ZOMBIENAME %s", class_name)
			if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, transkey)
		}
	}
	else // humans
	{
		red = HUD_STATS_HUMAN_R
		green = HUD_STATS_HUMAN_G
		blue = HUD_STATS_HUMAN_B
		
		// Survivor Class loaded?
		if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_SURVIVOR")
		// Sniper Class loaded?
		else if (LibraryExists(LIBRARY_SNIPER, LibType_Library) && zp_class_sniper_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_SNIPER")
                                
                                // Plasma Class loaded?
		else if (LibraryExists(LIBRARY_PLASMA, LibType_Library) && zp_class_plasma_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_PLASMA")
                                 // Knifer Class loaded?
		else if (LibraryExists(LIBRARY_KNIFER, LibType_Library) && zp_class_knifer_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_KNIFER")
                    
		else
		{
			zp_class_human_get_name(zp_class_human_get_current(player), class_name, charsmax(class_name))
			
			// ML support for class name
			formatex(transkey, charsmax(transkey), "HUMANNAME %s", class_name)
			if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, transkey)
		}
	}
	
	// Spectating someone else?
	if (player != ID_SHOWHUD)
	{
		new player_name[32]
		get_user_name(player, player_name, charsmax(player_name))
		crxranks_get_user_rank(player, rank, charsmax(rank))
		new ap = zp_ammopacks_get(player)
		if(ap > 500000)
			ap = ap - ( ap - 5000 )
		new Float:Afk = get_user_afktime(player) / 60.0
		
		// Show name, health, class, and money
		//set_hudmessage(HUD_STATS_SPEC_R, HUD_STATS_SPEC_G, HUD_STATS_SPEC_B, HUD_SPECT_X, HUD_SPECT_Y, 0, 6.0, 1.1, 0.0, 0.0, -1)
		set_hudmessage(HUD_STATS_SPEC_R, HUD_STATS_SPEC_G, HUD_STATS_SPEC_B, HUD_SPECT_X, HUD_SPECT_Y, 0, 0.05, 0.15 ,0.05, 0.05, -1)
		ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync[1], "%L: %s^nHP: %d - %L %s - %L %d - FPS: %d^nRank: %s - Level %d/%d -  XP: %d/%d^nAFK Time: %0.2f ", ID_SHOWHUD, "SPECTATING", player_name, get_user_health(player), ID_SHOWHUD, "CLASS_CLASS", class_name, ID_SHOWHUD, "AMMO_PACKS1", ap, g_FrameRate[player],rank,crxranks_get_user_level(player),crxranks_get_max_levels(),crxranks_get_user_xp(player),crxranks_get_user_next_xp(player),Afk)
	}
	else
	{
		crxranks_get_user_rank(ID_SHOWHUD, rank, charsmax(rank))

		// Show health, class
		//set_hudmessage(red, green, blue, HUD_STATS_X, HUD_STATS_Y, 0, 6.0, 1.1, 0.0, 0.0, -1)
		if(Sty[ID_SHOWHUD])
			set_hudmessage(red, green, blue, iXloc[ID_SHOWHUD], iYLoc[ID_SHOWHUD], 0, 0.05, 0.15, 0.05, 0.05, -1)
		else 
			set_hudmessage(red, green, blue, 0.02, 0.22, 0, 0.05, 0.15, 0.05, 0.05, -1)
		
		if(Sty[ID_SHOWHUD])
			ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync[1], "HP: %d - %L %s - %L %d - FPS: %d^nRank: %s - Level %d/%d - XP: %d/%d", get_user_health(ID_SHOWHUD), ID_SHOWHUD, "CLASS_CLASS", class_name, ID_SHOWHUD, "AMMO_PACKS1", zp_ammopacks_get(ID_SHOWHUD), g_FrameRate[ID_SHOWHUD],rank,crxranks_get_user_level(ID_SHOWHUD),crxranks_get_max_levels(),crxranks_get_user_xp(ID_SHOWHUD),crxranks_get_user_next_xp(ID_SHOWHUD))
		else 
			ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync[1], "[HP: %d]^n[%L %s]^n[%L %d]^n[FPS: %d]^n^n[Rank: %s]^n[Level %d/%d]^n[XP: %d/%d]", get_user_health(ID_SHOWHUD), ID_SHOWHUD, "CLASS_CLASS", class_name, ID_SHOWHUD, "AMMO_PACKS1", zp_ammopacks_get(ID_SHOWHUD), g_FrameRate[ID_SHOWHUD] + 1000,rank,crxranks_get_user_level(ID_SHOWHUD),crxranks_get_max_levels(),crxranks_get_user_xp(ID_SHOWHUD),crxranks_get_user_next_xp(ID_SHOWHUD))
	}
}
public Message_Status( message_id, iDestination, id )
{		
	if(is_user_bot(id))
		return PLUGIN_HANDLED;
		
	if (!is_user_alive(id))
		return PLUGIN_HANDLED;		
	
	if(zp_fps_get_user_flags(id)&FPS_HUD_MAIN)
		return PLUGIN_HANDLED;
		
	if(get_msg_arg_int(1)!=2)
		return PLUGIN_HANDLED;
		
	new player = get_msg_arg_int(2)	
	if (!is_user_alive(player))
		return PLUGIN_HANDLED;
	if(zp_class_nightcrawler_get(player))
		return PLUGIN_HANDLED;
	
	new red, green, blue, rank[40]
	if (zp_core_is_zombie(player)) 
	{
		red = HUD_STATS_ZOMBIE_R
		green = HUD_STATS_ZOMBIE_G
		blue = HUD_STATS_ZOMBIE_B	
	}
	else
	{	
		red = HUD_STATS_HUMAN_R
		green = HUD_STATS_HUMAN_G
		blue = HUD_STATS_HUMAN_B		
	}
	new ap = zp_ammopacks_get(player)
	if(ap > 500000)
		ap = ap - ( ap - 5000 )
	crxranks_get_user_rank(player,rank, charsmax(rank))
	static name[32]
	get_user_name(player, name, charsmax(name))
	set_hudmessage(red, green, blue, -1.0, 0.53, 2, 0.5, 3.0, 0.015, 0.5,-1)
	ShowSyncHudMsg(id, g_MsgSync[0], "%L: %s^nHP: %d^n%L %d^nLevel %d | Rank %s", id, "ATTRIBUTE_NAME", name,   get_user_health(player), id, "AMMO_PACKS1", ap,crxranks_get_user_level(player), rank)
	
	return PLUGIN_HANDLED;	
}
/*
public Message_Status( message_id, iDestination, id )
{
	
	
	if( message_id == g_MsgStatusValue )
	{
		if (!is_user_alive(id) || is_user_bot(id) )
			return PLUGIN_HANDLED;
		new player = get_msg_arg_int(2)
		if (!is_user_alive(player))
			return PLUGIN_HANDLED;
		if(zp_class_nightcrawler_get(player))
			return PLUGIN_HANDLED;
		// Format classname
		//static class_name[32], transkey[64]
		new red, green, blue//, class_id
		if (zp_core_is_zombie(player)) // zombies
		{
			red = HUD_STATS_ZOMBIE_R
			green = HUD_STATS_ZOMBIE_G
			blue = HUD_STATS_ZOMBIE_B
		/\*	class_id = max(0, zp_class_zombie_get_current(player));
		
			// Nemesis Class loaded?
			if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player))
				formatex(class_name, charsmax(class_name), "%L", id, "CLASS_NEMESIS")
			// Dragon Class loaded?
			else if (LibraryExists(LIBRARY_DRAGON, LibType_Library) && zp_class_dragon_get(player))
				formatex(class_name, charsmax(class_name), "%L", id, "CLASS_DRAGON")
			// Nightcrawler Class loaded?
			else if (LibraryExists(LIBRARY_NIGHTCRAWLER, LibType_Library) && zp_class_nightcrawler_get(player))
				formatex(class_name, charsmax(class_name), "%L", id, "CLASS_NIGHTCRAWLER")
			
			// Assassin Class loaded?
			else if (LibraryExists(LIBRARY_ASSASSIN, LibType_Library) && zp_class_assassin_get(player))
				formatex(class_name, charsmax(class_name), "Winos")				
				
			else
			{
				zp_class_zombie_get_name(class_id, class_name, charsmax(class_name))
				
				// ML support for class name
				formatex(transkey, charsmax(transkey), "ZOMBIENAME %s", class_name)	
				if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", id, transkey)
				
			}*\/
		}
		else
		{	
			red = HUD_STATS_HUMAN_R
			green = HUD_STATS_HUMAN_G
			blue = HUD_STATS_HUMAN_B
			/\*class_id = max(0, zp_class_human_get_current(player))
			
			// Survivor Class loaded?
			if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player))
				formatex(class_name, charsmax(class_name), "%L", id, "CLASS_SURVIVOR")
	
			// Sniper Class loaded?
			else if (LibraryExists(LIBRARY_SNIPER, LibType_Library) && zp_class_sniper_get(player))
				formatex(class_name, charsmax(class_name), "%L", id, "CLASS_SNIPER")
					
			// Plasma Class loaded?
			else if (LibraryExists(LIBRARY_PLASMA, LibType_Library) && zp_class_plasma_get(player))
				formatex(class_name, charsmax(class_name), "%L", id, "CLASS_PLASMA")
	
			// Knifer Class loaded?
			else if (LibraryExists(LIBRARY_KNIFER, LibType_Library) && zp_class_knifer_get(player))
				formatex(class_name, charsmax(class_name), "%L", id, "CLASS_KNIFER")				
					 
			else
			{
				zp_class_human_get_name(class_id, class_name, charsmax(class_name))
				
				// ML support for class name
				formatex(transkey, charsmax(transkey), "HUMANNAME %s", class_name)
				if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", id, transkey)
			}*\/
		}
		static name[32]
		get_user_name(player, name, charsmax(name))
		set_hudmessage(red, green, blue, -1.0, 0.6, 2, 0.5, 1.0, 0.015, 0.5)
		ShowSyncHudMsg(id, g_MsgSync[0], "%L: %s^nHP: %d^n%L %d", id, "ATTRIBUTE_NAME", name, /\*id, "CLASS_CLASS", class_name,*\/   get_user_health(player), id, "AMMO_PACKS1", zp_ammopacks_get(player))
	}
	else
		return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}*/
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
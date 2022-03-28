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

native crxranks_get_user_rank(id, rank[], size)

native crxranks_get_user_xp(id)
native crxranks_get_user_next_xp(id)
native crxranks_get_user_level(id)
native crxranks_get_max_levels();

new Float:g_flGameTime[33], g_iFrames[33], g_FrameRate[33];

new bool:Steam[33]
new Warn[33];

const Float:HUD_SPECT_X = 0.6
const Float:HUD_SPECT_Y = 0.8

//const Float:HUD_STATS_X = 0.02
//const Float:HUD_STATS_Y = 0.9

const Float:HUD_STATS_X = 0.02
const Float:HUD_STATS_Y = 1.0

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

public plugin_init()
{
	register_plugin("[ZP] HUD Information", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_MsgStatusValue = get_user_msgid("StatusValue")
	g_MsgStatusText = get_user_msgid("StatusText")
	
	register_message( g_MsgStatusValue, "Message_Status")
	register_message( g_MsgStatusText, "Message_Status")
	
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

public client_PreThink(this)
{
	if (!is_user_alive(this))
	return;

	static Float:flGameTime;

	flGameTime = get_gametime();
	g_iFrames[this]++;

	if (flGameTime - g_flGameTime[this] < 1.0)
		return;

	g_FrameRate[this] = g_iFrames[this];    

	g_iFrames[this] = 0;
	g_flGameTime[this] = flGameTime;

	if(g_FrameRate[this]>105)
	{
		client_cmd(this, "fps_override 0")
		if(!Steam[this])
		{
			client_cmd(this, "developer 0");
			client_cmd(this, "fps_max 100");
			client_cmd(this, "fps_modem 100");
		}
		
		Warn[this]++;
		if(Warn[this]==1)
		{
			query_client_cvar(this, "fps_max", "cvar_query_callback", 1, {0})
		}
	}
	else
	{
		Warn[this]=0;
	}

}

public cvar_query_callback(id, const cvar[], const value[], const param[])
{
	if(is_user_alive(id)&&str_to_num(value)>100)
	{
		if(!param[0])
		{
			zp_colored_print(id, "^3FPS^1 higher than 100 is^3 NOT ALLOWED!")
			zp_colored_print(id, "^3FPS^1 higher than 100 is^3 NOT ALLOWED!")
			zp_colored_print(id, "Set^3 fps_max 100^1 in your^3 Console!")
			zp_colored_print(id, "Set^3 fps_max 100^1 in your^3 Console!")
			zp_colored_print(id, "You have^3 10 Seconds!")

			client_cmd(id, "fps_max 100")
			client_cmd(id, "fps_override 0")
			if(!Steam[id])
			{
				client_cmd(id, "fps_modem 100")
				client_cmd(id, "developer 0")
			}

			set_task(10.0, "second_query", id)
		}
		else if(Warn[id])
		{
			new name[32]
			get_user_name(id, name, charsmax(name))
			server_cmd("kick #%d ^"Sorry, FPS higher than 100 is not allowed!^nSet fps_max 100 in console to play!", get_user_userid(id))
			zp_colored_print(0, "^3%s^1 was kicked for having higher than^3 100 FPS!",name)
		}
	}
	else
	{
		Warn[id] = 0;
	}
}

public second_query(id)
{
	query_client_cvar(id, "fps_max", "cvar_query_callback", 1, {1})
}

public client_putinserver(id)
{
	if (!is_user_bot(id))
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
		
		// Set the custom HUD display task
		if(zp_fps_get_user_flags(id)&FPS_HUD_MAIN)
			return;

		set_task(0.1, "ShowHUD", id+TASK_SHOWHUD, _, _, "b")
	}
}

public client_disconnected(id)
{
	remove_task(id+TASK_SHOWHUD)
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
			class_name = "Human"
        /*             
		else
		{
			zp_class_human_get_name(zp_class_human_get_current(player), class_name, charsmax(class_name))
			
			// ML support for class name
			formatex(transkey, charsmax(transkey), "HUMANNAME %s", class_name)
			if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, transkey)
		}*/
	}
	
	// Spectating someone else?
	if (player != ID_SHOWHUD)
	{
		new player_name[32], rank[32]
		get_user_name(player, player_name, charsmax(player_name))
		crxranks_get_user_rank(player, rank, charsmax(rank))
		
		// Show name, health, class, and money
		//set_hudmessage(HUD_STATS_SPEC_R, HUD_STATS_SPEC_G, HUD_STATS_SPEC_B, HUD_SPECT_X, HUD_SPECT_Y, 0, 6.0, 1.1, 0.0, 0.0, -1)
		set_hudmessage(HUD_STATS_SPEC_R, HUD_STATS_SPEC_G, HUD_STATS_SPEC_B, HUD_SPECT_X, HUD_SPECT_Y, 0, 0.05, 0.15 ,0.05, 0.05, -1)
		ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync[1], "%L: %s^nHP: %d - %L %s - %L %d - FPS: %d^nXP: %d/%d - Level %d/%d: %s", ID_SHOWHUD, "SPECTATING", player_name, get_user_health(player), ID_SHOWHUD, "CLASS_CLASS", class_name, ID_SHOWHUD, "AMMO_PACKS1", zp_ammopacks_get(player), g_FrameRate[player],crxranks_get_user_xp(player),crxranks_get_user_next_xp(player),crxranks_get_user_level(player),crxranks_get_max_levels(),rank)
	}
	else
	{
		new rank[32]		
		crxranks_get_user_rank(ID_SHOWHUD, rank, charsmax(rank))
		// Show health, class
		//set_hudmessage(red, green, blue, HUD_STATS_X, HUD_STATS_Y, 0, 6.0, 1.1, 0.0, 0.0, -1)
		set_hudmessage(red, green, blue, HUD_STATS_X, HUD_STATS_Y, 0, 0.05, 0.15, 0.05, 0.05, -1)

		ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync[1], "HP: %d - %L %s - %L %d - FPS: %d^nXP: %d/%d - Level %d/%d: %s^n^n", get_user_health(ID_SHOWHUD), ID_SHOWHUD, "CLASS_CLASS", class_name, ID_SHOWHUD, "AMMO_PACKS1", zp_ammopacks_get(ID_SHOWHUD), g_FrameRate[ID_SHOWHUD],crxranks_get_user_xp(ID_SHOWHUD),crxranks_get_user_next_xp(ID_SHOWHUD),crxranks_get_user_level(ID_SHOWHUD),crxranks_get_max_levels(),rank)
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
	
	new red, green, blue

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

	static name[32], rank[32]
	get_user_name(player, name, charsmax(name))
	crxranks_get_user_rank(player, rank, charsmax(rank))
	set_hudmessage(red, green, blue, -1.0, 0.53, 2, 0.5, 3.0, 0.015, 0.5,-1)
	ShowSyncHudMsg(id, g_MsgSync[0], "%L: %s^nHP: %d^n%L %d^nLevel %d - %s", id, "ATTRIBUTE_NAME", name,   get_user_health(player), id, "AMMO_PACKS1", zp_ammopacks_get(player),crxranks_get_user_level(player),rank)
	
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

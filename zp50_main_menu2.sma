/*================================================================================
	
	----------------------
	-*- [ZP] Main Menu -*-
	----------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#define LIBRARY_BUYMENUS "zp50_buy_menus"
#include <zp50_buy_menus>
#define LIBRARY_ZOMBIECLASSES "zp50_class_zombie"
#include <zp50_class_zombie>
#define LIBRARY_HUMANCLASSES "zp50_class_human"
#include <zp50_class_human>
#define LIBRARY_ITEMS "zp50_items"
#include <zp50_items>
#define LIBRARY_ADMIN_MENU "zp50_admin_menu"
#include <zp50_admin_menu>
//#define LIBRARY_RANDOMSPAWN "zp50_random_spawn"
//#include <zp50_random_spawn>
#include <colorchat>
#include <hamsandwich>
#include <zp50_gamemodes>
#include <cstrike>
#include <fun>
#include <zmvip>

native zp_fps_show_fps_menu(index)
native zv_glow_menu_show(id)
native zp_open_vote_menu(id);
native zv_information_show(id);
native zp_spec(id)
native zp_back(id)
native zp_vip_model_toggle(id)
native zp_vip_model_get(id)
native zp_vip_glow_toggle(id)
native zp_vip_glow_get(id)

#define TASK_WELCOMEMSG 100

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

// Menu keys
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

new const music[][]={"zombie_plague/gc_connect.mp3","zombie_plague/gc_connect2.mp3"}

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

//new g_ChooseTeamOverrideActive
new cvar_buy_custom_primary, cvar_buy_custom_secondary, cvar_buy_custom_grenades
//new cvar_random_spawning
//native open_custom_vip_menu(index)
//native open_clan_menu(index);
//native zp_skin_shop_show(index);
//new g_NormalID, g_MultiInfectionID, g_AlienID, g_RaceID;

public plugin_init()
{
	register_plugin("[ZP] Main Menu", ZP_VERSION_STRING, "ZP Dev Team")
	
	//register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	register_clcmd("chooseteam", "clcmd_chooseteam")
	
	register_clcmd("say /zpmenu", "clcmd_zpmenu",0,"- Opens ZP Main Menu")
	register_clcmd("say zpmenu", "clcmd_zpmenu",0,"- Opens ZP Main Menu")
	
	// Menus
	register_menu("Main Menu", KEYSMENU, "menu_main")	
	register_menu("Human Menu", KEYSMENU, "menu_human")
	register_menu("VIP Menu", KEYSMENU, "menu_vip")	
}

public plugin_precache()
{
	for(new i;i<sizeof(music);i++)
	{
		precache_sound(music[i])
	}
}
public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_BUYMENUS) || equal(module, LIBRARY_ZOMBIECLASSES) || equal(module, LIBRARY_HUMANCLASSES) || equal(module, LIBRARY_ITEMS) || equal(module, LIBRARY_ADMIN_MENU)) //|| equal(module, LIBRARY_RANDOMSPAWN))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public plugin_cfg()
{
	cvar_buy_custom_primary = get_cvar_pointer("zp_buy_custom_primary")
	cvar_buy_custom_secondary = get_cvar_pointer("zp_buy_custom_secondary")
	cvar_buy_custom_grenades = get_cvar_pointer("zp_buy_custom_grenades")
	//g_NormalID = zp_gamemodes_get_id("Infection Mode")
	//g_MultiInfectionID = zp_gamemodes_get_id("Multiple Infection Mode")
	//g_AlienID = zp_gamemodes_get_id("Alien Mode")
	//g_RaceID = zp_gamemodes_get_id("Race Mode")
}
/*
// Event Round Start
public event_round_start()
{
	// Show main menu message
	remove_task(TASK_WELCOMEMSG)
	set_task(2.0, "task_welcome_msg", TASK_WELCOMEMSG)
}

// Welcome Message Task
public task_welcome_msg()
{
	ColorChat(0,GREEN, "^04 Welcome 2 The Dark Side! ^01", ZP_VERSION_STR_LONG)
	ColorChat(0,TEAM_COLOR, "Add Our IP: ^04 [ 74.91.116.201:27015 ] ^01 to comeback easly.")
}*/

public clcmd_chooseteam(id)
{
	//if (flag_get(g_ChooseTeamOverrideActive, id))
	//{
		show_menu_main(id)
		return PLUGIN_HANDLED;
	//}
	
	//flag_set(g_ChooseTeamOverrideActive, id)
	//return PLUGIN_CONTINUE;
}

public clcmd_zpmenu(id)
{
	show_menu_main(id)
}
/*
public client_putinserver(id)
{
	flag_set(g_ChooseTeamOverrideActive, id)
}*/

// Main Menu
show_menu_main(id)
{
	static menu[500]
	new len
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\yGamerClub.NeT | Zombie Plague ^n^n", ZP_VERSION_STR_LONG)
	
	// 1. Buy menu
	if (LibraryExists(LIBRARY_BUYMENUS, LibType_Library) && (get_pcvar_num(cvar_buy_custom_primary)
	|| get_pcvar_num(cvar_buy_custom_secondary) || get_pcvar_num(cvar_buy_custom_grenades)) && is_user_alive(id))
		len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L^n", id, "MENU_BUY")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d1. %L^n", id, "MENU_BUY")
	
	// 2. Extra Items
	if (LibraryExists(LIBRARY_ITEMS, LibType_Library) && is_user_alive(id))
		len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L^n", id, "MENU_EXTRABUY")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d2. %L^n", id, "MENU_EXTRABUY")
	
	// 3. Zombie class
	if (LibraryExists(LIBRARY_ZOMBIECLASSES, LibType_Library) && zp_class_zombie_get_count() > 1)
		len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L^n", id, "MENU_ZCLASS")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d3. %L^n", id, "MENU_ZCLASS")
		
	// 4. Player Menu
	len += formatex(menu[len], charsmax(menu) - len, "\r4.\w Player Menu^n")

	// 5. FPS
	len += formatex(menu[len], charsmax(menu) - len, "\r5.\w FPS Menu^n^n")

	// 6. Choose Team
	if(cs_get_user_team(id)==CS_TEAM_SPECTATOR||cs_get_user_team(id)==CS_TEAM_UNASSIGNED)
	{		
		len += formatex(menu[len], charsmax(menu) - len, "\r6.\w Exit Spectator Mode^n^n")
	}
	else
	{		
		len += formatex(menu[len], charsmax(menu) - len, "\r6.\w Enter Spectator Mode^n^n")
	}
	//len += formatex(menu[len], charsmax(menu) - len, "\r5.\w %L^n^n", id, "MENU_CHOOSE_TEAM")
		
	// 7. VIP Menu
	len += formatex(menu[len], charsmax(menu) - len, "\r7.\w VIP Menu^n^n")

	// 9. Admin menu
	if (LibraryExists(LIBRARY_ADMIN_MENU, LibType_Library) && is_user_admin(id))
		len += formatex(menu[len], charsmax(menu) - len, "\r9.\w %L", id, "MENU_ADMIN")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d9. %L", id, "MENU_ADMIN")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0.\w Exit")

	/*
	// 4. Human Classes
	if (LibraryExists(LIBRARY_HUMANCLASSES, LibType_Library) && zp_class_human_get_count() > 1)
		len += formatex(menu[len], charsmax(menu) - len, "\r4.\w Choose Human Skin^n")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d4. Choose Human Skin^n")*/
		
		/*
	// 6. VIP Menu Items
	len += formatex(menu[len], charsmax(menu) - len, "\r6.\w VIP Items Menu^n")

	// 7. VIP Glow Menu
	len += formatex(menu[len], charsmax(menu) - len, "\r7.\w VIP Glow Menu^n^n")*/
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "Main Menu")
}
// Main Menu
public menu_main(id, key)
{
	// Player disconnected?
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	switch (key)
	{
		case 0: // Buy Menu
		{
			// Custom buy menus enabled?
			if (LibraryExists(LIBRARY_BUYMENUS, LibType_Library) && (get_pcvar_num(cvar_buy_custom_primary)
			|| get_pcvar_num(cvar_buy_custom_secondary) || get_pcvar_num(cvar_buy_custom_grenades)))
			{
				// Check whether the player is able to buy anything
				if (is_user_alive(id))
					zp_buy_menus_show(id)
				else
					ColorChat(id,GREEN, "[GC]^03 %L", id, "CANT_BUY_WEAPONS_DEAD")
			}
			else
				ColorChat(id,GREEN, "[GC]^03 %L", id, "CUSTOM_BUY_DISABLED")
		}
		case 1: // Extra Items
		{
			// Items enabled?
			if (LibraryExists(LIBRARY_ITEMS, LibType_Library))
			{
				// Check whether the player is able to buy anything
				if (is_user_alive(id))
					zp_items_show_menu(id)
				else
					ColorChat(id,GREEN, "[GC]^03 %L", id, "CANT_BUY_ITEMS_DEAD")
			}
			else
				ColorChat(id,GREEN, "[GC]^03 %L", id, "CMD_NOT_EXTRAS")
		}
		case 2: // Zombie Classes
		{
			if (LibraryExists(LIBRARY_ZOMBIECLASSES, LibType_Library) && zp_class_zombie_get_count() > 1)
				zp_class_zombie_show_menu(id)
			else
				ColorChat(id,GREEN, "[GC]^03 %L", id, "CMD_NOT_ZCLASSES")
		}
		
		case 3: //Player Menu
		{
			zp_show_player_menu(id);
		}

		case 4: //FPS Menu
		{
			zp_fps_show_fps_menu(id);
		}
		
		case 5: // Menu override
		{
			if(cs_get_user_team(id)==CS_TEAM_SPECTATOR||cs_get_user_team(id)==CS_TEAM_UNASSIGNED)
			{	
				//flag_unset(g_ChooseTeamOverrideActive, id)
				zp_back(id)
			}
			else
			{		
				zp_spec(id)
			}
		}
		/*
		case 4: // Menu override
		{
			flag_unset(g_ChooseTeamOverrideActive, id)
			client_cmd(id, "chooseteam")
		}*/

		case 6: // VIP Menu
		{
			zp_vip_menu_show(id)
		}

		case 8: // Admin Menu
		{
			if (LibraryExists(LIBRARY_ADMIN_MENU, LibType_Library) && is_user_admin(id))
				zp_admin_menu_show(id)
			else 
				ColorChat(id,GREEN, "[GC]^03 %L", id, "NO_ADMIN_MENU")
		}
		/*
		case 5: // Menu override
		{
			zv_menu_open(id);
		}
		case 6: // Menu override
		{
			zv_glow_menu_show(id);
		}*/
		/*
		case 3: //Human Classes
		{
			if (LibraryExists(LIBRARY_HUMANCLASSES, LibType_Library) && zp_class_human_get_count() > 1)
			{
				zp_class_human_show_menu(id);
			}
			else
			{
				ColorChat(id, GREEN, "[GC]^3 %L", id, "CMD_NOT_HCLASSES");
			}
		}*/
	}
	
	return PLUGIN_HANDLED;
}
public zp_show_player_menu(id)
{
	new menu = menu_create( "\yGamerClub.NeT | Player Menu", "menu_player" );
	menu_additem(menu, "Show Rules\y /rules","/rules")
	menu_additem(menu, "Mostrar Reglas\y /reglas","/reglas")
	menu_additem(menu, "Show Rank\y hlx","hlx")
	menu_additem(menu, "Report Player\y /report","/report")
	menu_additem(menu, "VIP Benefits\y /vip","/vip")
	menu_additem(menu, "Online VIPs List\y /vips","/vips")
	menu_additem(menu, "Get Free Ammopacks\y /get","/get")
	menu_additem(menu, "Guns Menu\y /guns","/guns")
	menu_additem(menu, "Extra Items Menu\y /items","/items")
	menu_additem(menu, "Donate Extra Item\y /donate ","/donate")
	menu_additem(menu, "Zombie Class Menu\y /zclass","/zclass")
	menu_additem(menu, "Buy Lasermine\y /lm","/lm")
	menu_additem(menu, "Buy Sandbags\y /sb","/sb")
	menu_additem(menu, "Buy Remote Control Bomb\y /rc","/rc")
	menu_additem(menu, "Buy Unlimited Clip\y /unlimited","/unlimited")
	menu_additem(menu, "Buy Brains\y /brains","/brains")
	menu_additem(menu, "Buy Madness\y /madness","/madness")
	menu_additem(menu, "GamerClub Server List\y /server","/server")
	menu_additem(menu, "Player Mute Menu\y /mute","/mute")
	menu_additem(menu, "Enter Spectator Mode\y /spec","/spec")
	menu_additem(menu, "Exit Spectator Mode\y /back","/back")
	menu_additem(menu, "Participate as a Boss\y /participate","/participate")
	menu_additem(menu, "Happy Hour Times\y /happyhours","/happyhours")
	menu_additem(menu, "Toggle Player View\y /cam","/cam")
	menu_additem(menu, "Toggle Bullet Damage\y /showbd","/showbd")
	menu_additem(menu, "Toggle Own Keys Display\y /showkeys","/showkeys")
	menu_additem(menu, "Toggle Spectator Keys\y /speckeys","/speckeys")
	menu_additem(menu, "Toggle Speed Display\y /speed","/speed")
	menu_additem(menu, "Current Map Name\y currentmap","currentmap")
	menu_additem(menu, "Recent Maps List\y recentmaps","recentmaps")
	menu_additem(menu, "Next Map Name\y nextmap","nextmap")
	menu_additem(menu, "Map Nomination Menu\y nom","nom")
	menu_additem(menu, "Nominated Maps\y noms","noms")
	menu_additem(menu, "Server's Current Time\y thetime","thetime")
	menu_additem(menu, "Map Time Left\y timeleft","timeleft")
	menu_display(id, menu)
}


public menu_player( id, menu, item )
 {
	if ( item == MENU_EXIT )
	{
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}

	new szData[32]
	new _access, item_callback;
	menu_item_getinfo(menu, item,_access, szData,charsmax(szData),"",0,item_callback)
	client_cmd(id, "say %s",szData)

	menu_destroy( menu );
	return PLUGIN_HANDLED;
 }

public zp_vip_menu_show(id)
{	
	static menu[500]
	new len
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\yGamerClub.NeT | VIP Menu ^n^n", ZP_VERSION_STR_LONG)
	
	// 1. VIP Items
	len += formatex(menu[len], charsmax(menu) - len, "\r1.\w VIP Items Menu\y (/vm)^n")
	
	// 2. Glow Menu
	len += formatex(menu[len], charsmax(menu) - len, "\r2.\w Glow Menu\y (/glow)^n")

	// 3. Mode Menu
	len += formatex(menu[len], charsmax(menu) - len, "\r3.\w Mode Menu\y (/mode)^n")

	// 4. Skins Menu
	len += formatex(menu[len], charsmax(menu) - len, "\r4.\w Skins Menu\y (/hclass)^n^n")

	// 5. Toggle Zombie VIP Model
	len += formatex(menu[len], charsmax(menu) - len, "\r5.\w Zombie VIP Skin\r [%s]\y (/zskin)^n",((zv_get_user_flags(id)&ZV_MAIN)&&zp_vip_model_get(id))?"ON":"OFF")

	// 6. Toggle VIP Zombie Glow
	len += formatex(menu[len], charsmax(menu) - len, "\r6.\w Zombie VIP Special Glow\r [%s]\y (/zglow)^n^n",((zv_get_user_flags(id)&ZV_MAIN)&&zp_vip_glow_get(id))?"ON":"OFF")

	// 7. VIP Information
	len += formatex(menu[len], charsmax(menu) - len, "\r7.\w VIP Information\y (/vip)^n^n")

	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "\r0.\w Exit^n")

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "VIP Menu")
}

// VIP Menu
public menu_vip(id, key)
{
	// Player disconnected?
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	switch (key)
	{
		case 0: //Items Menu
		{
			zv_menu_open(id);
		}

		case 1: //Glow Menu
		{
			zv_glow_menu_show(id);
		}

		case 2: //Mode Menu
		{
			zp_open_vote_menu(id)
		}

		case 3://Skin Menu
		{
			zp_class_human_show_menu(id);
		}
		
		case 4: // Toggle VIP
		{
			zp_vip_model_toggle(id)
		}
		
		case 5: // Toggle VIP
		{
			zp_vip_glow_toggle(id)
		}
		case 6: // VIP Information
		{
			zv_information_show(id);
		}

	}
	return PLUGIN_HANDLED;
}
public menu_human(id, key)
{
	
	// Player disconnected?
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	switch (key)
	{
		case 0: 
		{
			if (LibraryExists(LIBRARY_HUMANCLASSES, LibType_Library) && zp_class_human_get_count() > 1)
			{
				zp_class_human_show_menu(id);
			}
			else
			{
				ColorChat(id, GREEN, "[GC]^3 %L", id, "CMD_NOT_HCLASSES");
			}
		}
		//case 1: // Extra Items
		//{
		//	zp_skin_shop_show(id);
		//}
	}
	return PLUGIN_HANDLED;
}
/*
// Help MOTD
show_help(id)
{
	static motd[1024]
	new len
	
	len += formatex(motd[len], charsmax(motd) - len, "%L", id, "MOTD_INFO11", "Zombie Plague Mod", ZP_VERSION_STR_LONG, "ZP Dev Team")
	len += formatex(motd[len], charsmax(motd) - len, "%L", id, "MOTD_INFO12")
	
	show_motd(id, motd)
}
*/
// Check if a player is stuck (credits to VEN)
stock is_player_stuck(id)
{
	static Float:originF[3]
	pev(id, pev_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

public client_connect(id)
{
	client_cmd(id, "mp3 play ^"sound/%s^"", music[random(sizeof(music))])
}
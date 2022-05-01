/*================================================================================
	
	--------------------------
	-*- [ZP] Items Manager -*-
	--------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/
#include <amxmodx>
#include <fakemeta>
#include <amx_settings_api>
#include <zp50_gamemodes>
//#include <zp50_vip>
#include <zp50_colorchat>
#include <zp50_core_const>
#include <zp50_items_const>
#include <zmvip>
#include <zp50_class_dragon>
#include <zp50_class_nightcrawler>
#include <zp50_class_nemesis>
#include <zp50_class_predator>
#include <zp50_class_survivor>
#include <zp50_class_plasma>
#include <zp50_class_sniper>
#include <zp50_class_knifer>
// Extra Items file
new const ZP_EXTRAITEMS_FILE[] = "zp_extraitems.ini"
// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205
#define MAXPLAYERS 32
// For item list menu handlers
#define MENU_PAGE_ITEMS g_menu_data[id]
new g_menu_data[MAXPLAYERS+1]
native zp_is_apocalypse()
/*
native zp_madness_set_cost(id, &cost, itemid)
native zp_blind_set_cost(id, &cost, itemid)
native zp_grenades_set_cost(id, &cost, itemid)
native zp_brains_set_cost(id, &cost, itemid)
native zp_2000_set_cost(id, &cost, itemid)
native zp_sandbags_set_cost(id, &cost, itemid)
native zp_lasermine_set_cost(id, &cost, itemid)
native zp_rc_set_cost(id, &cost, itemid)
*/
enum _:TOTAL_FORWARDS
{
	FW_ITEM_SELECT_PRE = 0,
	FW_ITEM_SELECT_POST
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult
// Items data
new Array:g_ItemRealName
new Array:g_ItemName
new Array:g_ItemDesc
new Array:g_ItemCost
new Array:g_ItemLimit
new Array:g_ItemPlayerLimit
new Array:g_ItemVIP
new Array:g_ItemVIPLimit
new Array:g_Purchases
new Array:g_PlayerPurchases
new g_ItemCount
new g_AdditionalMenuText[32]
/*
new gMode_Infection;
new gMode_Multi;
new gMode_Swarm;
new gMode_Plague;
new gMode_Nemesis;
new gMode_Survivor;
new gMode_Sniper;
new gMode_Armageddon;*/
public plugin_init()
{
	register_plugin("[ZP] Items Manager", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_clcmd("say /items", "clcmd_items",0,"- Opens ZP Extra Item Menu")
	register_clcmd("say items", "clcmd_items",0,"- Opens ZP Extra Item Menu")
	
	g_Forwards[FW_ITEM_SELECT_PRE] = CreateMultiForward("zp_fw_items_select_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	g_Forwards[FW_ITEM_SELECT_POST] = CreateMultiForward("zp_fw_items_select_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
}
new Tag,Wars,Potato,Cannibals,Nightmare,Alien,Race,SVN//,Santa,Presents,GG
public plugin_cfg()
{
	SVN = zp_gamemodes_get_id("Snipers Vs Nemesis");
	Tag = zp_gamemodes_get_id("Zombie Tag Mode");
	Wars = zp_gamemodes_get_id("Infection Wars Mode");
	Potato = zp_gamemodes_get_id("Hot Potato Mode");
	Cannibals = zp_gamemodes_get_id("Cannibals Mode")
	Nightmare = zp_gamemodes_get_id("Nightmare Mode")
	Alien = zp_gamemodes_get_id("Alien Mode")
	Race = zp_gamemodes_get_id("Nemesis Race Mode")
	/*Santa = zp_gamemodes_get_id("Santa Mode")
	Presents = zp_gamemodes_get_id("Presents Event!")
	GG=zp_gamemodes_get_id("Gun Game Mode");*/
}
public plugin_natives()
{
	register_library("zp50_items")
	register_native("zp_items_register", "native_items_register")
	register_native("zp_items_get_id", "native_items_get_id")
	register_native("zp_items_get_name", "native_items_get_name")
	register_native("zp_items_get_real_name", "native_items_get_real_name")
	register_native("zp_items_get_cost", "native_items_get_cost")
	register_native("zp_items_get_limit", "native_items_get_limit")
	register_native("zp_items_get_player_limit", "native_items_get_player_limit")
	register_native("zp_items_get_vip_limit", "native_items_get_vip_limit")
	register_native("zp_items_get_purchases", "native_items_get_purchases")
	register_native("zp_items_get_player_purchases", "native_items_get_player_purchas")
	register_native("zp_items_set_purchases", "native_items_set_purchases")
	register_native("zp_items_set_player_purchases", "native_items_set_player_purchas")
	register_native("zp_items_get_cost", "native_items_get_cost")
	register_native("zp_items_show_menu", "native_items_show_menu")
	register_native("zp_items_force_buy", "native_items_force_buy")
	register_native("zp_items_menu_text_add", "native_items_menu_text_add")
	
	// Initialize dynamic arrays
	g_ItemRealName = ArrayCreate(32, 1)
	g_ItemName = ArrayCreate(32, 1)
	g_ItemDesc = ArrayCreate(32, 1)
	g_ItemCost = ArrayCreate(1, 1)
	g_ItemLimit = ArrayCreate(1, 1)
	g_ItemPlayerLimit = ArrayCreate(1, 1)
	g_Purchases = ArrayCreate(1, 1)
	g_PlayerPurchases = ArrayCreate(32, 1)
	g_ItemVIP = ArrayCreate(1, 1)
	g_ItemVIPLimit = ArrayCreate(1, 1)
}
public plugin_end()
{
	ArrayDestroy(g_ItemRealName)
	ArrayDestroy(g_ItemName)
	ArrayDestroy(g_ItemDesc)
	ArrayDestroy(g_ItemCost)
	ArrayDestroy(g_ItemLimit)
	ArrayDestroy(g_ItemPlayerLimit)
	ArrayDestroy(g_Purchases)
	ArrayDestroy(g_PlayerPurchases)
	ArrayDestroy(g_ItemVIP)
	ArrayDestroy(g_ItemVIPLimit)
}
public native_items_register(plugin_id, num_params)
{
	new name[32], desc[32] , cost = get_param(3), limit = get_param(4), playerlimit = get_param(5), vip
	
	if(get_param(6)==1)
	vip=1;
	else
	vip=0;
	new viplimit=get_param(7)
	get_string(1, name, charsmax(name))
	get_string(2, desc, charsmax(desc))
	
	if (strlen(name) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't register item with an empty name")
		return ZP_INVALID_ITEM;
	}
	
	new index, item_name[32]
	for (index = 0; index < g_ItemCount; index++)
	{
		ArrayGetString(g_ItemRealName, index, item_name, charsmax(item_name))
		if (equali(name, item_name))
		{
			log_error(AMX_ERR_NATIVE, "[ZP] Item already registered (%s)", name)
			return ZP_INVALID_ITEM;
		}
	}
	
	// Load settings from extra items file
	new real_name[32]
	copy(real_name, charsmax(real_name), name)
	ArrayPushString(g_ItemRealName, real_name)
	
	// Name
	if (!amx_load_setting_string(ZP_EXTRAITEMS_FILE, real_name, "NAME", name, charsmax(name)))
		amx_save_setting_string(ZP_EXTRAITEMS_FILE, real_name, "NAME", name)
	ArrayPushString(g_ItemName, name)
	
	// Desc
	if (!amx_load_setting_string(ZP_EXTRAITEMS_FILE, real_name, "DESCRIPTION", desc,  charsmax(desc)))
		amx_save_setting_string(ZP_EXTRAITEMS_FILE, real_name, "DESCRIPTION", desc)
	ArrayPushString(g_ItemDesc, desc)
	
	// Cost
	if (!amx_load_setting_int(ZP_EXTRAITEMS_FILE, real_name, "COST", cost))
		amx_save_setting_int(ZP_EXTRAITEMS_FILE, real_name, "COST", cost)
	ArrayPushCell(g_ItemCost, cost)
	
	
	// Limit
	if (!amx_load_setting_int(ZP_EXTRAITEMS_FILE, real_name, "LIMIT", limit))
		amx_save_setting_int(ZP_EXTRAITEMS_FILE, real_name, "LIMIT", limit)
	ArrayPushCell(g_ItemLimit, limit)
	ArrayPushCell(g_Purchases, 0)
	
	// Player Limit
	if (!amx_load_setting_int(ZP_EXTRAITEMS_FILE, real_name, "PLAYER LIMIT", playerlimit))
		amx_save_setting_int(ZP_EXTRAITEMS_FILE, real_name, "PLAYER LIMIT", playerlimit)
	ArrayPushCell(g_ItemPlayerLimit, playerlimit)
	new empty[32]
	ArrayPushArray(g_PlayerPurchases, empty)
	// VIP Limit
	if (!amx_load_setting_int(ZP_EXTRAITEMS_FILE, real_name, "VIP LIMIT", viplimit))
		amx_save_setting_int(ZP_EXTRAITEMS_FILE, real_name, "VIP LIMIT", viplimit)
	ArrayPushCell(g_ItemVIPLimit, viplimit)
	
	// VIP
	if (!amx_load_setting_int(ZP_EXTRAITEMS_FILE, real_name, "VIP", vip))
		amx_save_setting_int(ZP_EXTRAITEMS_FILE, real_name, "VIP", vip)		
	ArrayPushCell(g_ItemVIP, vip)
	
	
	g_ItemCount++
	return g_ItemCount - 1;
}
public native_items_get_id(plugin_id, num_params)
{
	new real_name[32]
	get_string(1, real_name, charsmax(real_name))
	
	// Loop through every item
	new index, item_name[32]
	for (index = 0; index < g_ItemCount; index++)
	{
		ArrayGetString(g_ItemRealName, index, item_name, charsmax(item_name))
		if (equali(real_name, item_name))
			return index;
	}
	
	return ZP_INVALID_ITEM;
}
public native_items_get_name(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return false;
	}
	
	new name[32]
	ArrayGetString(g_ItemName, item_id, name, charsmax(name))
	
	new len = get_param(3)
	set_string(2, name, len)
	return true;
}
public native_items_get_real_name(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return false;
	}
	
	new real_name[32]
	ArrayGetString(g_ItemRealName, item_id, real_name, charsmax(real_name))
	
	new len = get_param(3)
	set_string(2, real_name, len)
	return true;
}
public native_items_get_cost(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return -1;
	}
	
	return ArrayGetCell(g_ItemCost, item_id);
}
public native_items_get_limit(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return -1;
	}
	
	return ArrayGetCell(g_ItemLimit, item_id);
}
public native_items_get_player_limit(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return -1;
	}
	
	return ArrayGetCell(g_ItemPlayerLimit, item_id);
}
public native_items_get_vip_limit(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return -1;
	}
	
	return ArrayGetCell(g_ItemVIPLimit, item_id);
}
public native_items_get_purchases(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return -1;
	}
	
	return ArrayGetCell(g_Purchases, item_id);
}
public native_items_set_purchases(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return -1;
	}
	ArraySetCell(g_Purchases, item_id, get_param(2))
	return PLUGIN_HANDLED;
}
public native_items_get_player_purchas(plugin_id, num_params)
{
	new item_id = get_param(1)
	new id = get_param(2)
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return -1;
	}
	if (id<0||id>32)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid id (%d)", id)
		return -1;
	}
	new players[32]
	ArrayGetArray(g_PlayerPurchases, item_id, players)
	return players[id-1]
}
public native_items_set_player_purchas(plugin_id, num_params)
{
	new item_id = get_param(1)
	new id = get_param(2)
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return -1;
	}
	if (id<0||id>32)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid id (%d)", id)
		return -1;
	}
	new players[32]
	ArrayGetArray(g_PlayerPurchases, item_id, players)
	players[id-1]=get_param(3)
	ArrayGetArray(g_PlayerPurchases, item_id, players)
	return PLUGIN_HANDLED;
}
public native_items_show_menu(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	clcmd_items(id)
	return true;
}
public native_items_force_buy(plugin_id, num_params)
{
	new get_cm = zp_gamemodes_get_current();
	
	if (get_cm==ZP_NO_GAME_MODE||get_cm == SVN|| get_cm == Tag|| get_cm == Wars ||get_cm == Potato || get_cm == Cannibals||get_cm== Nightmare || get_cm == Alien|| get_cm == Race)/*||get_cm == GG||get_cm == Santa||get_cm == Presents*/
	{
		return false;
	}
	
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new item_id = get_param(2)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return false;
	}
	
	new ignorecost = get_param(3)
	
	buy_item(id, item_id, ignorecost)
	return true;
}
public native_items_menu_text_add(plugin_id, num_params)
{
	static text[32]
	get_string(1, text, charsmax(text))
	format(g_AdditionalMenuText, charsmax(g_AdditionalMenuText), "%s %s", g_AdditionalMenuText, text)
}
public client_disconnected(id)
{
	// Reset remembered menu pages
	MENU_PAGE_ITEMS = 0
}
public clcmd_items(id)
{
	// Player dead
	if (!is_user_alive(id))
		return;
		
	show_items_menu(id);
	/*
	new get_cm = zp_gamemodes_get_current();
	
	if (cant_buy(id)||get_cm==ZP_NO_GAME_MODE||get_cm == SVN|| get_cm == Tag || get_cm == Wars ||get_cm == Potato || get_cm == Cannibals||get_cm== Nightmare || get_cm == Alien|| get_cm == Race)||get_cm == GG||get_cm == Santa||get_cm == Presents
	{
		zp_colored_print(id,"%L", id, "NO_EXTRA_ITEMS");
	}
	
	else
	{
		show_items_menu(id);
	}
	*/
}
// Items Menu
public zp_fw_items_select_pre(id, it, cost)
{
	if(!CanPurchase(id, it))
		return ZP_ITEM_NOT_AVAILABLE
		
	if(ArrayGetCell(g_ItemVIP,it))
	{
		if(!(zv_get_user_flags(id)&ZV_DAMAGE))
		{	
			formatex(g_AdditionalMenuText, charsmax(g_AdditionalMenuText), "\r[PREMIUM]")
			return ZP_ITEM_NOT_AVAILABLE;
		}
	}		
	return ZP_ITEM_AVAILABLE
}
bool:CanPurchase(id, itemid)
{	
	if(ArrayGetCell(g_ItemLimit,itemid)&&ArrayGetCell(g_Purchases,itemid)>=ArrayGetCell(g_ItemLimit,itemid))
		return false;
	new playerlimit[32]
	ArrayGetArray(g_PlayerPurchases, itemid, playerlimit)

	if((zv_get_user_flags(id)&ZV_DAMAGE)&&(playerlimit[id-1]>=ArrayGetCell(g_ItemVIPLimit,itemid)&&ArrayGetCell(g_ItemVIPLimit,itemid)))
		return false;

	if(!(zv_get_user_flags(id)&ZV_DAMAGE)&&(playerlimit[id-1]>=ArrayGetCell(g_ItemPlayerLimit,itemid)&&ArrayGetCell(g_ItemPlayerLimit,itemid)))		
		return false;

	return true;
}
show_items_menu(id)
{
	static menu[512], name[32], desc[32], cost, itemlimit, itemplayerlimit ,itemviplimit, transkey[64], limit
	new menuid, index, itemdata[2], player[32], playerlimit
	
	// Title
	formatex(menu, charsmax(menu), "%L:\r", id, "MENU_EXTRABUY")
	menuid = menu_create(menu, "menu_extraitems")
	
	// Item List
	for (index = 0; index < g_ItemCount; index++)
	{
		new iLen, Limit[64]
		// Additional text to display
		g_AdditionalMenuText[0] = 0
		
		// Execute item select attempt forward
		ExecuteForward(g_Forwards[FW_ITEM_SELECT_PRE], g_ForwardResult, id, index, 0)
		
		
		// Add Item Name and Cost
		ArrayGetString(g_ItemName, index, name, charsmax(name))
		ArrayGetString(g_ItemDesc, index, desc, charsmax(desc))
		if(zp_is_apocalypse()&&!zp_core_is_zombie(id))
			cost=0
		
		else			
			cost = ArrayGetCell(g_ItemCost, index)
			/*
			(zp_madness_set_cost(id, cost, index)
			||zp_blind_set_cost(id, cost, index)
			||zp_grenades_set_cost(id, cost, index)
			||zp_brains_set_cost(id, cost, index)
			||zp_2000_set_cost(id, cost, index)
			||zp_sandbags_set_cost(id, cost, index)
			||zp_lasermine_set_cost(id, cost, index)
			||zp_rc_set_cost(id, cost, index))
		}
		*/
		itemlimit = ArrayGetCell(g_ItemLimit, index)
		itemplayerlimit = ArrayGetCell(g_ItemPlayerLimit, index)
		itemviplimit = ArrayGetCell(g_ItemVIPLimit, index)
		limit = ArrayGetCell(g_Purchases,index)
		ArrayGetArray(g_PlayerPurchases, index, player)
		playerlimit = player[id-1]
		// ML support for item name
		formatex(transkey, charsmax(transkey), "ITEMNAME %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(name, charsmax(name), "%L", id, transkey)
		switch(g_ForwardResult)
		{
			case ZP_ITEM_DONT_SHOW: continue;
			case ZP_ITEM_NOT_AVAILABLE: formatex(menu, charsmax(menu), "\d%s \r%s \d[%d AP]", name, g_AdditionalMenuText,  cost)
			default:
			{
				iLen += formatex(menu[iLen], charsmax(menu) - iLen, "%s ", name)
				
				if(strlen(desc) > 0)
					iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r%s ", desc)
					
				if(strlen(g_AdditionalMenuText) > 0)
					iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\w%s ", g_AdditionalMenuText)	
					
				if(itemlimit) 
					formatex(Limit, charsmax(Limit), "[%d/%d] ", limit, itemlimit)
				if(itemplayerlimit)
					formatex(Limit, charsmax(Limit), "[%d/%d] ", playerlimit, itemplayerlimit)
				if( (zv_get_user_flags(id)&ZV_DAMAGE) && itemviplimit)
					formatex(Limit, charsmax(Limit), "[%d/%d] ", playerlimit, itemviplimit)
					
				if(strlen(Limit) > 0)
					iLen += formatex(menu[iLen], charsmax(menu) - iLen,"\w%s", Limit)
				
				if(cost)
					iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\w[\y%d AP\w]", cost)
			}
		}
		/*	
		// Item available to player?
		if (g_ForwardResult >= ZP_ITEM_NOT_AVAILABLE)
		{
			formatex(menu, charsmax(menu), "\d%s\r%s \d%d %s", name,  desc,  cost, g_AdditionalMenuText)
		}
		else
		if(vip&&!(zv_get_user_flags(id)&ZV_MAIN))
		{
			formatex(menu, charsmax(menu), "\d%s\r%s \d%d \r[VIP] %s", name,  desc, cost, g_AdditionalMenuText)
		}
		else
		if(itemlimit)
		{
			new limit = ArrayGetCell(g_Purchases,index)
			if(limit>=itemlimit)
			{
				formatex(menu, charsmax(menu), "\d%s \r%s \d%d [%d/%d] %s", name, desc,  cost,limit,itemlimit, g_AdditionalMenuText)
			}
			else
			if(itemplayerlimit)
			{
				new player[32]
				ArrayGetArray(g_PlayerPurchases, index, player)
				new playerlimit=player[id-1];
				if(!((zv_get_user_flags(id)&ZV_MAIN)))
				{					
					if(playerlimit>=itemplayerlimit)
					{				
						if(itemviplimit>itemplayerlimit)
						formatex(menu, charsmax(menu), "\d%s\r%s \d%d [%d/%d] \r[VIP] %s", name, desc,  cost, playerlimit,itemviplimit, g_AdditionalMenuText)
						else
						if(!itemviplimit)
						formatex(menu, charsmax(menu), "\d%s\r%s \d%d \r[VIP] %s", name, desc,  cost,  g_AdditionalMenuText)
						else
						formatex(menu, charsmax(menu), "\d%s\r%s \d%d [%d/%d] %s", name, desc,  cost, playerlimit,itemplayerlimit, g_AdditionalMenuText)
					}
					else
					{
						formatex(menu, charsmax(menu), "%s\r%s \y%d \w[%d/%d] %s", name, desc, cost, playerlimit,itemplayerlimit, g_AdditionalMenuText)
					}
				}
				else
				{	
					if(itemviplimit)
					{					
						if(playerlimit>=itemviplimit)
						{					
							formatex(menu, charsmax(menu), "\d%s\r%s \d%d [%d/%d] %s", name, desc,  cost, playerlimit,itemviplimit, g_AdditionalMenuText)
						}
						else
						{
							formatex(menu, charsmax(menu), "%s\r%s \y%d \w[%d/%d] %s", name, desc, cost, playerlimit,itemviplimit, g_AdditionalMenuText)
						}
					}
					else
					{					
						formatex(menu, charsmax(menu), "%s\r%s \y%d %s", name, desc, cost, g_AdditionalMenuText)
					}
				}
			}
			else
			{
				formatex(menu, charsmax(menu), "%s\r%s \y%d \w[%d/%d] %s", name, desc, cost,limit,itemlimit, g_AdditionalMenuText)
			}
		}
		else
		if(itemplayerlimit)
		{
			new player[32]
			ArrayGetArray(g_PlayerPurchases, index, player)
			new playerlimit=player[id-1];
			if(!(zv_get_user_flags(id)&ZV_MAIN))
			{				
				if(playerlimit>=itemplayerlimit)
				{
					if(itemplayerlimit<itemviplimit)
					formatex(menu, charsmax(menu), "\d%s\r%s \d%d [%d/%d] \r[VIP] %s", name, desc,  cost, playerlimit,itemviplimit, g_AdditionalMenuText)
					else
					if(!itemviplimit)
					formatex(menu, charsmax(menu), "\d%s\r%s \d%d \r[VIP] %s", name, desc,  cost, g_AdditionalMenuText)
					else
					formatex(menu, charsmax(menu), "\d%s\r%s \d%d [%d/%d] %s", name, desc,  cost, playerlimit,itemplayerlimit, g_AdditionalMenuText)
				}
				else
				{
					formatex(menu, charsmax(menu), "%s\r%s \y%d \w[%d/%d] %s", name, desc, cost, playerlimit,itemplayerlimit, g_AdditionalMenuText)
				}
			}
			else
			{
				if(itemviplimit)
				{
					if(playerlimit>=itemviplimit)
					{
						formatex(menu, charsmax(menu), "\d%s\r%s \d%d [%d/%d] %s", name, desc,  cost, playerlimit,itemviplimit, g_AdditionalMenuText)
					}
					else
					{
						formatex(menu, charsmax(menu), "%s\r%s \y%d \w[%d/%d] %s", name, desc, cost, playerlimit,itemviplimit, g_AdditionalMenuText)
					}
				}
				else
				{
					formatex(menu, charsmax(menu), "%s\r%s \y%d %s", name, desc, cost, g_AdditionalMenuText)
				}
				
			}
		}
		else
		formatex(menu, charsmax(menu), "%s\r%s \y%d \w%s", name, desc, cost, g_AdditionalMenuText)		
		*/
		itemdata[0] = index
		itemdata[1] = 0
		menu_additem(menuid, menu, itemdata)
	}
	
	// No items to display?
	if (menu_items(menuid) <= 0)
	{
		zp_colored_print(id, "%L", id, "NO_EXTRA_ITEMS")
		menu_destroy(menuid)
		return;
	}
	
	// Back - Next - Exit
	formatex(menu, charsmax(menu), "%L", id, "MENU_BACK")
	menu_setprop(menuid, MPROP_BACKNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_NEXT")
	menu_setprop(menuid, MPROP_NEXTNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_EXIT")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_ITEMS = min(MENU_PAGE_ITEMS, menu_pages(menuid)-1)
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	menu_display(id, menuid, MENU_PAGE_ITEMS)
}
// Items Menu
public menu_extraitems(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT)
	{
		MENU_PAGE_ITEMS = 0
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Remember items menu page
	MENU_PAGE_ITEMS = item / 7
	
	// Dead players are not allowed to buy items
	if (!is_user_alive(id))
	{
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Retrieve item id
	new itemdata[2], dummy, itemid
	menu_item_getinfo(menuid, item, dummy, itemdata, charsmax(itemdata), _, _, dummy)
	itemid = itemdata[0]
	
	buy_item(id, itemid)
	menu_destroy(menuid)
	return PLUGIN_HANDLED;
}
// Buy Item
buy_item(id, itemid, ignorecost = 0)
{
	// Execute item select attempt forward
	ExecuteForward(g_Forwards[FW_ITEM_SELECT_PRE], g_ForwardResult, id, itemid, ignorecost)
	
	// Item available to player?
	if (g_ForwardResult >= ZP_ITEM_NOT_AVAILABLE)
	{			
		return;
	}
		
	if(ArrayGetCell(g_ItemVIP,itemid))
	{
		if(!(zv_get_user_flags(id)&ZV_MAIN))
		{				
			return;
		}
	}
	
	if(ArrayGetCell(g_ItemLimit,itemid)&&ArrayGetCell(g_Purchases,itemid)>=ArrayGetCell(g_ItemLimit,itemid))
	{			
		return;
	}
	new playerlimit[32]
	ArrayGetArray(g_PlayerPurchases, itemid, playerlimit)
	
	if((zv_get_user_flags(id)&ZV_MAIN)&&(playerlimit[id-1]>=ArrayGetCell(g_ItemVIPLimit,itemid)&&ArrayGetCell(g_ItemVIPLimit,itemid)))
	{
		return;
	}
	
	if(!(zv_get_user_flags(id)&ZV_MAIN)&&(playerlimit[id-1]>=ArrayGetCell(g_ItemPlayerLimit,itemid)&&ArrayGetCell(g_ItemPlayerLimit,itemid)))
	{		
		return;
	}
	
	playerlimit[id-1]++;
	ArraySetArray(g_PlayerPurchases, itemid, playerlimit)
	
	ArraySetCell(g_Purchases,itemid,ArrayGetCell(g_Purchases,itemid)+1);
	
	// Execute item selected forward
	ExecuteForward(g_Forwards[FW_ITEM_SELECT_POST], g_ForwardResult, id, itemid, ignorecost)
	
}
public zp_fw_gamemodes_start()
{
	new empty[32];
	for(new item=0;item<g_ItemCount;item++)
	{
		if(ArrayGetCell(g_ItemLimit, item))
			ArraySetCell(g_Purchases,item,0)
		if(ArrayGetCell(g_ItemPlayerLimit, item))
			ArraySetArray(g_PlayerPurchases,item,empty)
	}
}
cant_buy(id)
{
		return(zp_class_nemesis_get(id)||zp_class_predator_get(id)||zp_class_dragon_get(id)||zp_class_nightcrawler_get(id)||zp_class_sniper_get(id)||zp_class_knifer_get(id)||zp_class_plasma_get(id))
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
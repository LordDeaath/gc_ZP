#include <amxmodx>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <amx_settings_api>
#include <colorchat>
#include <zp50_items_const>
#include <zp50_core_const>
#include <zp50_gamemodes>
#include <zmvip>

const MAXPLAYERS = 32;
 
new const ZP_EXTRAITEMS_FILE[] = "za_items.ini";
 
enum _:ePluginForwards
{
	FW_ITEM_SELECT_PRE = 0,
	FW_ITEM_SELECT_POST,
};
 
enum _:eExtraItems
{
	ITEM_KEY[32],
	ITEM_NAME[32],
	ITEM_DESC[64],
	ITEM_COST,
	ITEM_LIMIT,
	ITEM_LIMIT_PL,
	ITEM_TXT[32],
};
 
new Array:g_arrItems;
new g_iItemLimit[MAXPLAYERS+1][64], g_iMenuPage[MAXPLAYERS+1], g_hForward[ePluginForwards], g_szExtraText[32];
new g_Limit[64]
new g_iItemsCount, g_iForwardRet, ItTxt;
new gMode_Infection, gMode_Multi;

#define SetPlayerBit(%1,%2) (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2) (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2) (%1 & (1<<(%2&31)))
 
public plugin_init()
{
	register_plugin("[ZP] Items Manager", ZP_VERSION_STRING, "ZP Dev Team");
 
	register_event("HLTV", "eventNewRound", "a", "1=0", "2=0");
 
	register_clcmd("say /zaitems", "cmdShowMenuItems");
	register_clcmd("say zaitems", "cmdShowMenuItems");
	ItTxt = register_cvar("zp_item_cost_string", "AP");
	g_hForward[FW_ITEM_SELECT_PRE] = CreateMultiForward("za_fw_items_select_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	g_hForward[FW_ITEM_SELECT_POST] = CreateMultiForward("za_fw_items_select_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	
	gMode_Multi = zp_gamemodes_get_id("Multiple Infection Mode")
	gMode_Infection = zp_gamemodes_get_id("Infection Mode")
}
 
public plugin_precache()
{
	g_arrItems = ArrayCreate(eExtraItems, 1);
}
 //za_menu_open
public plugin_natives()
{
	register_library("za_items");
	register_native("za_items_register", "native_items_register");
	register_native("za_items_get_id", "native_items_get_id");
	register_native("za_items_get_name", "native_items_get_name");
	register_native("za_items_get_key", "native_items_get_key");
	register_native("za_items_get_desc", "native_items_get_desc")
	register_native("za_items_get_cost", "native_items_get_cost");
	register_native("za_items_get_limit", "native_items_get_limit");
	register_native("za_items_get_limitpl", "native_items_get_limit_pl");
	register_native("za_items_show_menu", "native_items_show_menu");
	register_native("za_menu_open", "native_items_show_menu");
	register_native("za_items_force_buy", "native_items_force_buy");
	register_native("za_items_menu_text_add", "native_items_menu_text_add");
}
 
public eventNewRound()
{
	new stPlayers[MAXPLAYERS], iPlayersCount, pPlayer;
 
	get_players(stPlayers, iPlayersCount);
 
	for (new i = 0; i < g_iItemsCount; i++)
		g_Limit[i] = 0;
 
	for (new i = 0; i < iPlayersCount; i++)
	{
		pPlayer = stPlayers[i];
		arrayset(g_iItemLimit[pPlayer], 0, g_iItemsCount);
	}
 
	arrayset(g_iItemLimit[0], 0, g_iItemsCount);
}
 
public client_disconnected(this)
{
	g_iMenuPage[this] = 0;
	arrayset(g_iItemLimit[this], 0, g_iItemsCount);
}
 
public cmdShowMenuItems(pPlayer)
{
	if (!is_user_alive(pPlayer))
		return PLUGIN_CONTINUE;
		
 	new get_cm = zp_gamemodes_get_current();
	
	if(get_cm==ZP_NO_GAME_MODE)
	{
		ColorChat(pPlayer, GREEN, "[GC]^3 Wait till round starts to use this.")
		return PLUGIN_CONTINUE;
	}
	if (get_cm==gMode_Infection || get_cm == gMode_Multi)
		showMenuItems(pPlayer);
	else
		ColorChat(pPlayer, GREEN, "[GC]^3 Can't use^4 premium^3 in this ^4mode.")
		
	return PLUGIN_HANDLED;
}
 
public za_fw_items_select_pre(pPlayer, iItem, iIgnoreCost)
{
	new stItem[eExtraItems];
 
	ArrayGetArray(g_arrItems, iItem, stItem);
 
	if (stItem[ITEM_LIMIT] && g_Limit[ iItem ] >= stItem[ITEM_LIMIT])
		return ZP_ITEM_NOT_AVAILABLE;
 
	if (stItem[ITEM_LIMIT_PL] && g_iItemLimit[stItem[ITEM_LIMIT_PL] ? pPlayer : 0][iItem] >= stItem[ITEM_LIMIT_PL])
		return ZP_ITEM_NOT_AVAILABLE;
 
	return ZP_ITEM_AVAILABLE;
}
 
public za_fw_items_select_post(pPlayer, iItem, iIgnoreCost)
{
	new stItem[eExtraItems], Nick[32];
	get_user_name(pPlayer, Nick, charsmax(Nick))
	
	ArrayGetArray(g_arrItems, iItem, stItem);
	
	ColorChat(0, GREEN, "[GC]^3 %s ^1bought^3 %s ^1from^4 Premium Items", Nick, stItem[ITEM_NAME])
 
	if (stItem[ITEM_LIMIT])
		g_Limit[iItem]++;
 
	if (stItem[ITEM_LIMIT_PL])
		g_iItemLimit[stItem[ITEM_LIMIT_PL] ? pPlayer : 0][iItem]++;	
}
 
showMenuItems(pPlayer)
{	
	new szBuffer[64], stItem[eExtraItems], szId[3], iLen, Txt[32];
	get_pcvar_string(ItTxt,Txt, charsmax(Txt))
	if( zv_get_user_flags(pPlayer) & ZV_DAMAGE )
		formatex(szBuffer, charsmax(szBuffer), "Premium Items:\r");
	else formatex(szBuffer, charsmax(szBuffer), "\dPremium Items:");
	new hMenu = menu_create(szBuffer, "menuItems");
 
	for (new i = 0; i < g_iItemsCount; i++)
	{
		ArrayGetArray(g_arrItems, i, stItem);
 
		iLen = 0;
		g_szExtraText[0] = 0
 
		ExecuteForward(g_hForward[FW_ITEM_SELECT_PRE], g_iForwardRet, pPlayer, i, 0);
 
		switch (g_iForwardRet)
		{
			case ZP_ITEM_DONT_SHOW:
			{
				continue;
			}
			case ZP_ITEM_NOT_AVAILABLE:
			{
				iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "\d%s", stItem[ITEM_NAME]);
 
				iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, " %s", stItem[ITEM_DESC]);
 
				iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, " %s", g_szExtraText);
 
				if (stItem[ITEM_LIMIT] || stItem[ITEM_LIMIT_PL])
				{
					if(stItem[ITEM_LIMIT_PL])
						iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, " [%d/%d]", g_iItemLimit[stItem[ITEM_LIMIT_PL] ? pPlayer : 0][i],stItem[ITEM_LIMIT_PL]);
					else
						iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, " [%d/%d]", g_Limit[i], stItem[ITEM_LIMIT]);
				}
 
				if (stItem[ITEM_COST])
					iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, " %d %s", stItem[ITEM_COST], Txt);
				else
					iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, " [FREE]");
 
			}
			default:
			{
				iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "%s", stItem[ITEM_NAME]);
 
				iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, " \r%s", stItem[ITEM_DESC]);
 
				iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, " \w%s", g_szExtraText);
 
				if (stItem[ITEM_LIMIT] || stItem[ITEM_LIMIT_PL])
				{
					if(stItem[ITEM_LIMIT_PL])
						iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, " \w[%d/%d]", g_iItemLimit[stItem[ITEM_LIMIT_PL] ? pPlayer : 0][i],stItem[ITEM_LIMIT_PL]);
					else
						iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, " \w[%d/%d]", g_Limit[i], stItem[ITEM_LIMIT]);
				}
				if (stItem[ITEM_COST])
					iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, " \y%d %s", stItem[ITEM_COST], Txt);
				else
					iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, " \y[FREE]");
 
			}
		}
 
		num_to_str(i, szId, charsmax(szId));
		menu_additem(hMenu, szBuffer, szId);
	}
 
	if (!menu_items(hMenu))
	{
		ColorChat(pPlayer,GREEN, "[ZP]^3 No items are available for this class.");
		return;
	}
 
	g_iMenuPage[pPlayer] = min(g_iMenuPage[pPlayer], menu_pages(hMenu) - 1);
 
	menu_display(pPlayer, hMenu, g_iMenuPage[pPlayer]);
}
 
public menuItems(pPlayer, hMenu, iItem)
{
	if (!is_user_alive(pPlayer))
		return PLUGIN_HANDLED;
 
	if (iItem == MENU_EXIT)
	{
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}
 
	new anyDummy, szItem[3];
 
	menu_item_getinfo(hMenu, iItem, anyDummy, szItem, charsmax(szItem), _, _, anyDummy);
	new iItemId = str_to_num(szItem);
 
	menu_destroy(hMenu);
	buyItem(pPlayer, iItemId, 0);
 
	g_iMenuPage[pPlayer] = iItem / 7;
 
	if (g_iForwardRet >= ZP_ITEM_NOT_AVAILABLE)
		showMenuItems(pPlayer);
 
	return PLUGIN_HANDLED;
}
 
public native_items_register(iPlugin, iParams)
{
	new stItem[eExtraItems], stItem2[eExtraItems];
 
	get_string(1, stItem[ITEM_NAME], charsmax(stItem[ITEM_NAME]));
 
	get_string(2, stItem[ITEM_DESC], charsmax(stItem[ITEM_DESC]));
 
	for (new i = 0; i < g_iItemsCount; i++)
	{
		ArrayGetArray(g_arrItems, i, stItem2);
 
		if (equali(stItem[ITEM_NAME], stItem2[ITEM_NAME]))
		{
			log_error(AMX_ERR_NATIVE, "[ZP] Item (%s) already registered.", stItem[ITEM_NAME]);
			return ZP_INVALID_ITEM;
		}
	}
 
	copy(stItem[ITEM_KEY], charsmax(stItem[ITEM_KEY]), stItem[ITEM_NAME]);
 
	stItem[ITEM_COST] = get_param(3);
	stItem[ITEM_LIMIT] = get_param(4);
	stItem[ITEM_LIMIT_PL] = get_param(5);
 
	if (!amx_load_setting_string(ZP_EXTRAITEMS_FILE, stItem[ITEM_KEY], "NAME", stItem[ITEM_NAME], charsmax(stItem[ITEM_NAME])))
		amx_save_setting_string(ZP_EXTRAITEMS_FILE, stItem[ITEM_KEY], "NAME", stItem[ITEM_NAME]);
 
	if (!amx_load_setting_string(ZP_EXTRAITEMS_FILE, stItem[ITEM_KEY], "DESC", stItem[ITEM_DESC], charsmax(stItem[ITEM_DESC])))
		amx_save_setting_string(ZP_EXTRAITEMS_FILE, stItem[ITEM_KEY], "DESC", stItem[ITEM_DESC]);
 
	if (!amx_load_setting_int(ZP_EXTRAITEMS_FILE, stItem[ITEM_KEY], "COST", stItem[ITEM_COST]))
		amx_save_setting_int(ZP_EXTRAITEMS_FILE, stItem[ITEM_KEY], "COST", stItem[ITEM_COST]);
 
	if (!amx_load_setting_int(ZP_EXTRAITEMS_FILE, stItem[ITEM_KEY], "LIMIT", stItem[ITEM_LIMIT]))
		amx_save_setting_int(ZP_EXTRAITEMS_FILE, stItem[ITEM_KEY], "LIMIT", stItem[ITEM_LIMIT]);
 
	if (!amx_load_setting_int(ZP_EXTRAITEMS_FILE, stItem[ITEM_KEY], "LIMIT PER PLAYER", stItem[ITEM_LIMIT_PL]))
		amx_save_setting_int(ZP_EXTRAITEMS_FILE, stItem[ITEM_KEY], "LIMIT PER PLAYER", stItem[ITEM_LIMIT_PL]);
 
	ArrayPushArray(g_arrItems, stItem);
 
	g_iItemsCount++;
	return g_iItemsCount - 1;
}
 
public native_items_get_id(iPlugin, iParams)
{
	new szKey[32], stItem[eExtraItems];
 
	get_string(1, szKey, charsmax(szKey));
 
	for (new i = 0; i < g_iItemsCount; i++)
	{
		ArrayGetArray(g_arrItems, i, stItem);
 
		if (equali(szKey, stItem[ITEM_NAME]))
			return i;
	}
 
	return ZP_INVALID_ITEM;
}
 
public native_items_get_name(iPlugin, iParams)
{
	new stItem[eExtraItems];
	new iItem = get_param(1);
	new iLen = get_param(3);
 
	if (iItem < 0 || iItem >= g_iItemsCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", iItem);
		return 0;
	}
 
	ArrayGetArray(g_arrItems, iItem, stItem);
 
	set_string(2, stItem[ITEM_NAME], iLen);
 
	return 1;
}
 
public native_items_get_key(iPlugin, iParams)
{
	new stItem[eExtraItems];
	new iItem = get_param(1);
	new iLen = get_param(3);
 
	if (iItem < 0 || iItem >= g_iItemsCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", iItem);
		return 0;
	}
 
	ArrayGetArray(g_arrItems, iItem, stItem);
 
	set_string(2, stItem[ITEM_KEY], iLen);
 
	return 1;
}
 
public native_items_get_desc(iPlugin, iParams)
{
	new stItem[eExtraItems];
	new iItem = get_param(1);
	new iLen = get_param(3);
 
	if (iItem < 0 || iItem >= g_iItemsCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", iItem);
		return ZP_INVALID_ITEM;
	}
 
	ArrayGetArray(g_arrItems, iItem, stItem);
 
	set_string(2, stItem[ITEM_DESC], iLen);
 
	return 1;
}
 
public native_items_get_cost(iPlugin, iParams)
{
	new stItem[eExtraItems];
	new iItem = get_param(1);
 
	if (iItem < 0 || iItem >= g_iItemsCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", iItem);
		return ZP_INVALID_ITEM;
	}
 
	ArrayGetArray(g_arrItems, iItem, stItem);
 
	return stItem[ITEM_COST];
}
 
public native_items_get_limit(iPlugin, iParams)
{
	new stItem[eExtraItems];
	new iItem = get_param(1);
 
	if (iItem < 0 || iItem >= g_iItemsCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", iItem);
		return ZP_INVALID_ITEM;
	}
 
	ArrayGetArray(g_arrItems, iItem, stItem);
 
	return stItem[ITEM_LIMIT];
}
 
public native_items_get_limit_pl(iPlugin, iParams)
{
	new stItem[eExtraItems];
	new iItem = get_param(1);
 
	if (iItem < 0 || iItem >= g_iItemsCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", iItem);
		return ZP_INVALID_ITEM;
	}
 
	ArrayGetArray(g_arrItems, iItem, stItem);
 
	return stItem[ITEM_LIMIT_PL];
}
 
public native_items_show_menu(iPlugin, iParams)
{
	new pPlayer = get_param(1);
 
	if (!is_user_connected(pPlayer))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", pPlayer);
		return 0;
	}
 
	cmdShowMenuItems(pPlayer);
	return 1;
}
 
public native_items_force_buy(iPlugin, iParams)
{
	new pPlayer = get_param(1);
	new iItem = get_param(2);
	new iIgnoreCost = get_param(3);
 
	if (!is_user_connected(pPlayer))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", pPlayer);
		return 0;
	}
 
	if (iItem < 0 || iItem >= g_iItemsCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", iItem);
		return 0;
	}
 
	return buyItem(pPlayer, iItem, iIgnoreCost);
}
 
public native_items_menu_text_add(iPlugin, iParams)
{
	new szText[32];
 
	get_string(1, szText, charsmax(szText));
	format(g_szExtraText, charsmax(g_szExtraText), "%s%s", g_szExtraText, szText);
}
 
buyItem(pPlayer, iItem, iIgnoreCost)
{
	ExecuteForward(g_hForward[FW_ITEM_SELECT_PRE], g_iForwardRet, pPlayer, iItem, iIgnoreCost);
	
	
	if (g_iForwardRet >= ZP_ITEM_NOT_AVAILABLE && !(zv_get_user_flags(pPlayer) & ZV_DAMAGE) )
	{
		ColorChat(pPlayer, GREEN, "[GC]^3 You are not a ^4Premium^3 member. say^1 /premium^3 for more info")
		return 0;
	}
	if (g_iForwardRet >= ZP_ITEM_NOT_AVAILABLE)
		return 0;
		
	ExecuteForward(g_hForward[FW_ITEM_SELECT_POST], g_iForwardRet, pPlayer, iItem, iIgnoreCost);
	return 1;
}
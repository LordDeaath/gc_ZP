/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * AMX Bans - http://www.amxbans.net
 *  Include - menu_flag
 * 
 * Copyright (C) 2014  Ryan "YamiKaitou" LeBlanc
 * Copyright (C) 2009, 2010  Thomas Kurz
 * Copyright (C) 2003, 2004  Ronald Renes / Jeroen de Rover
 * 
 * 
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2 of the License, or (at
 *  your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software Foundation,
 *  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 *  In addition, as a special exception, the author gives permission to
 *  link the code of this program with the Half-Life Game Engine ("HL
 *  Engine") and Modified Game Libraries ("MODs") developed by Valve,
 *  L.L.C ("Valve"). You must obey the GNU General Public License in all
 *  respects for all of the code used other than the HL Engine and MODs
 *  from Valve. If you modify this file, you may extend this exception
 *  to your version of the file, but you are not obligated to do so. If
 *  you do not wish to do so, delete this exception statement from your
 *  version.
 * 
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


#if defined _menu_flag_included
    #endinput
#endif
#define _menu_flag_included

#include <amxmodx>
#include <amxmisc>
#include <sqlx>

public cmdFlaggingMenu(id,level,cid) {
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	new menu = menu_create("menu_flagplayer","actionFlaggingMenu")
	new callback=menu_makecallback("callback_MenuGetPlayers")
	
	MenuSetProps(id,menu,"FLAGGING_MENU")
	MenuGetPlayers(menu,callback)
	
	menu_display(id,menu,0)
	
	return PLUGIN_HANDLED
}
public actionFlaggingMenu(id,menu,item) {
	if(item < 0) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new acc,szInfo[8],szText[128],callb
	menu_item_getinfo(menu,item,acc,szInfo,charsmax(szInfo),szText,charsmax(szText),callb)
	
	new pid = find_player("k", str_to_num(szInfo))
	if(!pid)
	{
		client_print(id, print_chat, "[AMXBANS] Player has disconnected!")
		return PLUGIN_HANDLED
	}
	
	copy(g_choicePlayerName[id],charsmax(g_choicePlayerName[]),g_PlayerName[pid])
	get_user_authid(pid,g_choicePlayerAuthid[id],charsmax(g_choicePlayerAuthid[]))
	get_user_ip(pid,g_choicePlayerIp[id],charsmax(g_choicePlayerIp[]),1)
	g_choicePlayerId[id]= str_to_num(szInfo)
	
	if(get_pcvar_num(pcvar_debug) >= 2)
		log_amx("[AMXBans FlagPlayerMenu %d] %d choice: %d | %s | %s | %d",menu,id,g_choicePlayerName[id],g_choicePlayerAuthid[id],g_choicePlayerIp[id],g_choicePlayerId[id])
	
	if(g_being_flagged[pid])
		set_task(0.2,"cmdUnflagMenu",id)
	else
		set_task(0.2,"cmdFlagtimeMenu",id)
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public cmdUnflagMenu(id,level,cid) {
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED

	new pid = find_player("k", g_choicePlayerId[id])
	if(!pid)
	{
		client_print(id, print_chat, "[AMXBANS] Player has disconnected!")
		return PLUGIN_HANDLED
	}

	new menu = menu_create("menu_unflagplayer","actionUnflagMenu")
	
	MenuSetProps(id,menu,"UNFLAG_MENU")
	
	new szDisplay[128],szTime[64]
	
	get_flagtime_string(id,g_flaggedTime[pid],szTime,charsmax(szTime),1)
	if(g_coloredMenus)
		format(szTime,charsmax(szTime),"\y(%s: %s)\w",szTime,g_flaggedReason[pid])
	else
		format(szTime,charsmax(szTime),"(%s: %s)",szTime,g_flaggedReason[pid])
	
	formatex(szDisplay,charsmax(szDisplay),"%L %s",id,"UNFLAG_PLAYER",szTime)
	menu_additem(menu,szDisplay,"1",0)
	formatex(szDisplay,charsmax(szDisplay),"%L",id,"FLAG_PLAYER_NEW")
	menu_additem(menu,szDisplay,"2",0)
	
	menu_display(id,menu,0)
	
	return PLUGIN_HANDLED
}
public actionUnflagMenu(id,menu,item) {
	if(item < 0) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new acc,szInfo[3],szText[128],callb
	menu_item_getinfo(menu,item,acc,szInfo,charsmax(szInfo),szText,charsmax(szText),callb)
	
	new mid=str_to_num(szInfo)
	
	if(mid==1) {
		UnflagPlayer(id,1)
	} else if(mid==2) {
		UnflagPlayer(id,0)
		set_task(0.2,"cmdFlagtimeMenu",id)
	}
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public cmdFlagtimeMenu(id) {
	
	new menu = menu_create("menu_flagtime","actionFlagtimeMenu")
	
	MenuSetProps(id,menu,"FLAGTIME_MENU")
	MenuGetFlagtime(id,menu)
	
	menu_display(id,menu,0)
	
	return PLUGIN_HANDLED
}
public actionFlagtimeMenu(id,menu,item) {
	if(item < 0) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new acc,szInfo[11],szText[128],callb
	menu_item_getinfo(menu,item,acc,szInfo,10,szText,127,callb)
	
	g_choiceTime[id]=str_to_num(szInfo)
	
	if(get_pcvar_num(pcvar_debug) >= 2)
		log_amx("[AMXBans FlagtimeMenu %d] %d choice: %d min",menu,id,g_choiceTime[id])
	
	set_task(0.2,"cmdFlagReasonMenu",id)
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public cmdFlagReasonMenu(id) {
	
	new menu = menu_create("menu_flagreason","actionFlagReasonMenu")
	
	MenuSetProps(id,menu,"FLAGREASON_MENU")
	MenuGetReason(id,menu,amxbans_get_static_bantime(id))
	
	menu_display(id,menu,0)
	
	return PLUGIN_HANDLED
}
public actionFlagReasonMenu(id,menu,item) {
	if(item < 0) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new acc,szInfo[3],szText[128],callb
	menu_item_getinfo(menu,item,acc,szInfo,charsmax(szInfo),szText,charsmax(szText),callb)
	
	new aid=str_to_num(szInfo)
	
	if(aid == 99) {
		if(amxbans_get_static_bantime(id)) g_choiceTime[id]=get_pcvar_num(pcvar_custom_statictime)
		g_in_flagging[id]=true
		set_custom_reason[id]=true
		client_cmd(id,"messagemode amxbans_custombanreason")
		menu_destroy(menu)
		return PLUGIN_HANDLED
	} else {
		ArrayGetString(g_banReasons,aid,g_choiceReason[id],charsmax(g_choiceReason[]))
		if(amxbans_get_static_bantime(id)) g_choiceTime[id]=ArrayGetCell(g_banReasons_Bantime,aid)
	}
	
	if(get_pcvar_num(pcvar_debug) >= 2)
		log_amx("[AMXBans FlagReasonMenu %d] %d choice: %s (%d min)",menu,id,g_choiceReason[id],g_choiceTime[id])
	
	FlagPlayer(id)
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
/*******************************************************************************************************************/
FlagPlayer(id) {
	if(get_pcvar_num(pcvar_debug) >= 2)
		log_amx("[AMXBans FlagPlayer %d] %d | %s | %s | %s | %s | %d min ",id,\
			g_choicePlayerId[id],g_choicePlayerName[id],g_choicePlayerAuthid[id],g_choicePlayerIp[id],\
			g_choiceReason[id],g_choiceTime[id])
			
	new anick[64],aauthid[35],aip[22],pname[64]
	mysql_get_username_safe(id,anick,charsmax(anick))
	get_user_authid(id,aauthid,charsmax(aauthid))
	get_user_ip(id,aip,charsmax(aip),1)
	
	mysql_escape_string(g_choicePlayerName[id],pname,charsmax(pname))
	
	new pquery[1024]
	
	formatex(pquery, charsmax(pquery), "INSERT INTO `%s%s` (`player_ip`,`player_id`,`player_nick`,\
		`admin_ip`,`admin_id`,`admin_nick`,`reason`,`created`,`length`,`server_ip`) VALUES \
		('%s','%s','%s','%s','%s','%s','%s',UNIX_TIMESTAMP(NOW()),'%d','%s:%s')",g_dbPrefix, tbl_flagged, \
		g_choicePlayerIp[id],g_choicePlayerAuthid[id],pname,aip,aauthid,anick,\
		g_choiceReason[id],g_choiceTime[id],g_ip,g_port)
	
	new data[2]
	data[0] = id
	SQL_ThreadQuery(g_SqlX, "_FlagPlayer", pquery, data, 1)
	
	g_in_flagging[id]=false
	
	return PLUGIN_HANDLED
	
}
UnflagPlayer(id,announce=0) {
	if(get_pcvar_num(pcvar_debug) >= 2)
		log_amx("[AMXBans UnflagPlayer %d] %d | %s",id,g_choicePlayerId[id],g_choicePlayerName[id])
	
	new pquery[1024]
	
	formatex(pquery, charsmax(pquery), "DELETE FROM `%s%s` WHERE `player_id`='%s' OR `player_ip`='%s'",g_dbPrefix, tbl_flagged, \
		g_choicePlayerAuthid[id],g_choicePlayerIp[id])
	
	if(!get_pcvar_num(pcvar_flagged_all))
		format(pquery, charsmax(pquery),"%s AND `server_ip`='%s:%s'",pquery,g_ip,g_port)
	
	
	new data[2]
	data[0] = id
	data[1] = announce
	SQL_ThreadQuery(g_SqlX, "_UnflagPlayer", pquery, data, 2)
	
	g_in_flagging[id]=false
	
	return PLUGIN_HANDLED
}
/*******************************************************************************************************************/
public _FlagPlayer(failstate, Handle:query, error[], errnum, data[], size) {
	new id=data[0]

	new pid = find_player("k", g_choicePlayerId[id])
	if(!pid)
	{
		client_print(id, print_chat, "[AMXBANS] Player has disconnected!")
		return PLUGIN_HANDLED
	}

	if (failstate) {
		client_print(id,print_chat,"[AMXBans] %L",data[0],"FLAGG_MESS_ERROR",g_choicePlayerName[id])
		//ColorChat(id, RED, "[AMXBans]^x01 %L",data[0],"FLAGG_MESS_ERROR",g_choicePlayerName[id])
		new szQuery[256]
		MySqlX_ThreadError( szQuery, error, errnum, failstate, 31 )
		return PLUGIN_HANDLED
	}
	
	if(SQL_AffectedRows(query)) {
		client_print(id,print_chat,"[AMXBans] %L",data[0],"FLAGG_MESS",g_choicePlayerName[id])
		//ColorChat(id, RED, "[AMXBans]^x01 %L",data[0],"FLAGG_MESS",g_choicePlayerName[id])
		g_being_flagged[pid]=true
		g_flaggedTime[pid]=g_choiceTime[id]
		copy(g_flaggedReason[pid],charsmax(g_flaggedReason[]),g_choiceReason[id])
		
		new ret
		ExecuteForward(MFHandle[Player_Flagged],ret,pid,(g_choiceTime[id]*60),g_choiceReason[id])
	} else { 
		client_print(id,print_chat,"[AMXBans] %L",data[0],"FLAGG_MESS_ERROR",g_choicePlayerName[id])
		//ColorChat(id, RED, "[AMXBans]^x01 %L",data[0],"FLAGG_MESS_ERROR",g_choicePlayerName[id])
		g_being_flagged[pid]=false
	}
	return PLUGIN_HANDLED
}
public _UnflagPlayer(failstate, Handle:query, error[], errnum, data[], size) {
	new id=data[0]
	
	new pid = find_player("k", g_choicePlayerId[id])
	if(!pid)
	{
		client_print(id, print_chat, "[AMXBANS] Player has disconnected!")
		return PLUGIN_HANDLED
	}

	if (failstate) {
		client_print(id,print_chat,"[AMXBans] %L",data[0],"UN_FLAGG_MESS_ERROR",g_choicePlayerName[id])
		//ColorChat(id, RED, "[AMXBans]^x01 %L",data[0],"UN_FLAGG_MESS_ERROR",g_choicePlayerName[id])
		new szQuery[256]
		MySqlX_ThreadError( szQuery, error, errnum, failstate, 31 )
		return PLUGIN_HANDLED
	}
	
	if(SQL_AffectedRows(query)) {
		if(data[1]) {
			client_print(id,print_chat,"[AMXBans] %L",id,"UN_FLAGG_MESS",g_choicePlayerName[id])
			//ColorChat(id, RED, "[AMXBans]^x01 %L",id,"UN_FLAGG_MESS",g_choicePlayerName[id])
		}
		g_being_flagged[pid]=false
		new ret
		ExecuteForward(MFHandle[Player_UnFlagged],ret,pid)
	} else { 
		client_print(id,print_chat,"[AMXBans] %L",data[0],"UN_FLAGG_MESS_ERROR",g_choicePlayerName[id])
		//ColorChat(id, RED, "[AMXBans]^x01 %L",data[0],"UN_FLAGG_MESS_ERROR",g_choicePlayerName[id])
	}
	return PLUGIN_HANDLED
}

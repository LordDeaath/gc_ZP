#include <amxmodx>
#include <amxmisc>
#include <discord>
#include <colorchat>
#include <sqlx>

#define SERVER_IP "5.161.56.165" // Server IP - to be changed

#define	TABLE_NAME "report_system_zp" // Do not touch

#define DB_CALL "INSERT INTO `%s` (hacker_id, hacker_nick, reporter_id, reporter_nick, report_reason) VALUES ('%s', '%s', '%s', '%s', '%s')"

#define REPORT_TIMEOUT 60.0

new Handle:SqlConnection;

new g_szAuthid[33][32]

new reported[33]

new Trie:Timeout;

static const webHook[] = "example";

public plugin_init( )
{
	register_plugin("Report System : ZP", "1.0", "zXCaptainXz");

	new ip[20];
	get_user_ip(0, ip, 21, 1);

	if(!equal(SERVER_IP, ip)) 
	{
		server_print("Server IP has no rights to use this plugin!")
		pause("d");
	}

	register_clcmd("say /report", "CallMenu", 0, "- Opens report menu")
	register_clcmd("say_team /report", "CallMenu", 0, "- Opens report menu")
	register_clcmd("say report", "CallMenu", 0, "- Opens report menu")
	register_clcmd("say_team report", "CallMenu", 0, "- Opens report menu")
	register_clcmd("report_reason","report_reason");
	register_clcmd("amx_report", "cmdReport", 0, "<name or #userid> <reason>")
	Timeout = TrieCreate()
}

public plugin_end()
{
	TrieDestroy(Timeout)
}

public report_reason(id)
{
	if(!reported[id])
	{		
		ColorChat(id, GREEN, "[GC]^1 Please type^3 /report^1 to start a^3 Report!")
		return PLUGIN_HANDLED;
	}

	if(!is_user_connected(reported[id]))
	{
		ColorChat(id, GREEN, "[GC]^1 The^3 Player^1 you are reporting has^3 Disconnected^1!")
		return PLUGIN_HANDLED;
	}

	new reason[100]
	
	read_argv(1, reason, charsmax(reason))
	remove_quotes(reason)
	trim(reason)
	if(!reason[0])
	{
		ColorChat(id, GREEN, "[GC]^1 Please enter a valid^3 Reason!")
		client_cmd(id, "messagemode report_reason")
		return PLUGIN_HANDLED;
	}

	new Query[512];
	new name[32], reported_name[32]
	get_user_name(id, name, charsmax(name))
	get_user_name(reported[id], reported_name, charsmax(reported_name))
	replace_all(name, 31, "'", "''");
	replace_all(reported_name, 31, "'", "''");
	replace_all(reason, charsmax(reason), "'", "''");	

	formatex( Query, charsmax(Query), DB_CALL, TABLE_NAME, g_szAuthid[reported[id]], reported_name, g_szAuthid[id], name, reason)
		
	if (Discord_StartMessage())
    {
		Discord_SetStringParam(USERNAME, "Report Bot");
		Discord_SetStringParam(CONTENT, "A new report was made for ZP")
		Discord_AddField("Rulebreaker Name", reported_name);
		Discord_AddField("Rulebreaker SteamID", g_szAuthid[reported[id]]);
		Discord_AddField("Reason", reason);
		Discord_AddField("Reporter Name", name);
		Discord_AddField("Reporter SteamID", g_szAuthid[id]);
		Discord_SendMessage(webHook);
    }

	SQL_ThreadQuery( SqlConnection, "QueryHandler", Query );
	for(new admin=1;admin<33;admin++)
	{
		if(!is_user_connected(admin))continue;
		if(!(get_user_flags(admin)&ADMIN_KICK))continue;
		ColorChat(admin, GREEN, "[GC]^3 %s^1 reported^3 %s^1 for^3 %s!",name,reported_name,reason);
		ColorChat(admin, GREEN, "[GC]^3 %s^1 reported^3 %s^1 for^3 %s!",name,reported_name,reason);
		ColorChat(admin, GREEN, "[GC]^3 %s^1 reported^3 %s^1 for^3 %s!",name,reported_name,reason);
		ColorChat(admin, GREEN, "[GC]^3 %s^1 reported^3 %s^1 for^3 %s!",name,reported_name,reason);
		ColorChat(admin, GREEN, "[GC]^3 %s^1 reported^3 %s^1 for^3 %s!",name,reported_name,reason);
	}
	set_timeout(id);
	reported[id]=0;
	ColorChat(id, GREEN, "[GC]^1 The call has been sent^3 Successfully!");
	return PLUGIN_HANDLED;
}

public cmdReport(id, level, cid)
{
	new Float:timeleft = cant_report(id)
	if(timeleft)
	{
		console_print(id, "You need to wait %.0f Seconds to make another report!",timeleft)
		return PLUGIN_HANDLED;
	}

	if(!cmd_access(id, level, cid, 3))
	{
		return PLUGIN_HANDLED;
	}	

	new arg[32]
	read_argv(1, arg, charsmax(arg))
	new player = cmd_target(id, arg, 0)
	
	if(!player)
	{
		return PLUGIN_HANDLED;
	}

	if(player==id)
	{
		console_print(id, "You cannot report yourself!");
		return PLUGIN_HANDLED;
	}

	new reason[100]
	read_argv(2, reason, charsmax(reason))
	
	remove_quotes(reason)
	trim(reason)

	if(!reason[0])
	{
		console_print(id,"Please enter a valid Reason!")
		return PLUGIN_HANDLED;
	}

	new Query[512];
	new name[32], reported_name[32]
	get_user_name(id, name, charsmax(name))
	get_user_name(player, reported_name, charsmax(reported_name))
	replace_all(name, 31, "'", "''");
	replace_all(reported_name, 31, "'", "''");
	replace_all(reason, charsmax(reason), "'", "''");	

	formatex( Query, charsmax(Query), DB_CALL, TABLE_NAME, g_szAuthid[player], reported_name, g_szAuthid[id], name, reason)
	
	if (Discord_StartMessage())
    {
		Discord_SetStringParam(USERNAME, "Report Bot");
		Discord_SetStringParam(CONTENT, "A new report was made for ZP")
		Discord_AddField("Rulebreaker Name", reported_name);
		Discord_AddField("Rulebreaker SteamID", g_szAuthid[reported[id]]);
		Discord_AddField("Reason", reason);
		Discord_AddField("Reporter Name", name);
		Discord_AddField("Reporter SteamID", g_szAuthid[id]);
		Discord_SendMessage(webHook);
    }
	
	SQL_ThreadQuery( SqlConnection, "QueryHandler", Query );
	for(new admin=1;admin<33;admin++)
	{
		if(!is_user_connected(admin))continue;
		if(!(get_user_flags(admin)&ADMIN_KICK))continue;
		ColorChat(admin, GREEN, "[GC]^3 %s^1 reported^3 %s^1 for^3 %s!",name,reported_name,reason);
		ColorChat(admin, GREEN, "[GC]^3 %s^1 reported^3 %s^1 for^3 %s!",name,reported_name,reason);
		ColorChat(admin, GREEN, "[GC]^3 %s^1 reported^3 %s^1 for^3 %s!",name,reported_name,reason);
		ColorChat(admin, GREEN, "[GC]^3 %s^1 reported^3 %s^1 for^3 %s!",name,reported_name,reason);
		ColorChat(admin, GREEN, "[GC]^3 %s^1 reported^3 %s^1 for^3 %s!",name,reported_name,reason);
	}
	set_timeout(id);
	reported[id]=0;
	client_print(id, print_console, "The call has been sent successfully!");
	return PLUGIN_HANDLED;
}

public plugin_cfg( )
{
	SqlConnection = SQL_MakeDbTuple("62.108.35.183","bloodypro","uFk%0iPldv#$","reports")
}

public client_putinserver(id) {
	get_user_authid(id, g_szAuthid[id], 31);
	reported[id]=0;
}


public CallMenu(id)
{	
	new Float:timeleft = cant_report(id)
	if(timeleft)
	{
		ColorChat(id, GREEN, "[GC]^1 You need to wait^3 %.0f Seconds^1 to make another^3 Report!",timeleft)
		return PLUGIN_HANDLED;
	}

	new menu = menu_create("\rWARNING!\w Read before proceeding!^n^nFalse reports will be\r PUNISHED!^n^n\wDo you want to\r PROCEED\w with the report?", "CallMenuHandler");

	new yes = random(4)
	
	for(new i=0;i<4;i++)
	{
		if(i==yes)
		{
			menu_additem(menu, "Yes")
		}
		else
		{			
			menu_additem(menu, "\yNo")
		}
	}

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public CallMenuHandler(id, menu, item)
{
	if( item == MENU_EXIT ) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}


	new dummy[1], answer[5]
	menu_item_getinfo(menu, item, dummy[0], dummy, charsmax(dummy), answer, charsmax(answer), dummy[0])
	if(equal(answer,"Yes"))
	{		
		CallMenuTrue(id);
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public CallMenuTrue(id)
{	
	new menu = menu_create("Select\r Player", "CallMenuTrueHandler");
	new players[32], pnum, tempid;
	new szTempid[10];

	get_players(players, pnum);
	new name[32]
	for( new i; i<pnum; i++ ) {
		tempid = players[i];
		if(is_user_hltv(tempid)||tempid==id) continue;		
		num_to_str(tempid, szTempid, charsmax(szTempid));
		get_user_name(tempid, name, charsmax(name))
		menu_additem(menu, name, szTempid, 0);
	}

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public CallMenuTrueHandler(id, menu, item)
{
	if( item == MENU_EXIT ) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new data[6], szName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data, charsmax(data), szName, charsmax(szName), callback);

	reported[id] = str_to_num(data);

	if(!is_user_connected(reported[id]))
	{
		ColorChat(id, GREEN, "[GC]^1 The^3 Player^1 you are reporting has^3 Disconnected^1!")		
		menu_destroy(menu);
		return PLUGIN_HANDLED;	
	}

	ReasonsMenu(id);
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public ReasonsMenu(id) {
	new menu = menu_create("Select \rGeneral\y Reason", "ReasonsMenuHandler");

	menu_additem(menu, "Custom Reason")
	menu_additem(menu, "Cheating")
	menu_additem(menu, "Breaking General Rules")
	menu_additem(menu, "Breaking Zombie Plague Rules")
	if(get_user_flags(reported[id])&ADMIN_KICK)
	{		
		menu_additem(menu, "Admin Abuse");
	}
	
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public ReasonsMenuHandler(id, menu, item) {
	if( item == MENU_EXIT ) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	if(!is_user_connected(reported[id]))
	{
		ColorChat(id, GREEN, "[GC]^1 The^3 Player^1 you are reporting has^3 Disconnected^1!")		
		menu_destroy(menu);
		return PLUGIN_HANDLED;	
	}

	if(item==0)
	{
		client_cmd(id, "messagemode report_reason");
	}
	else
	{
		switch(item)
		{
			case 1: CheatMenu(id)
			case 2:	GeneralMenu(id)
			case 3:	ZPMenu(id)
			case 4:
			{
				if(get_user_flags(reported[id])&ADMIN_KICK)
				{		
					SendCall(id, "Admin Abuse");
				}
			}
		}
	}

	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public CheatMenu(id)
{	
	new menu = menu_create("Select\r Cheat", "CheatMenuHandler");

	menu_additem(menu, "AutoBhop")
	menu_additem(menu, "Sgs/Gs Hack")
	menu_additem(menu, "FPS Booster")
	menu_additem(menu, "Hyperscroll")
	menu_additem(menu, "Wallhack/Aimbot")
	menu_additem(menu, "Speedhack")
	menu_additem(menu, "Scripting")
	menu_additem(menu, "Multi-Hacks")
	menu_additem(menu, "Ban Evading")
	
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public CheatMenuHandler(id, menu, item) {
	if( item == MENU_EXIT ) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	if(!is_user_connected(reported[id]))
	{
		ColorChat(id, GREEN, "[GC]^1 The^3 Player^1 you are reporting has^3 Disconnected^1!")		
		menu_destroy(menu);
		return PLUGIN_HANDLED;	
	}

	new dummy[1], reason[64]
	menu_item_getinfo(menu, item, dummy[0], dummy, charsmax(dummy), reason, charsmax(reason), dummy[0])
	SendCall(id, reason)
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}
public GeneralMenu(id)
{	
	new menu = menu_create("Select\r General\y Rule", "GeneralMenuHandler");

	menu_additem(menu, "Disrespect/Racism")
	menu_additem(menu, "Mic Abuse")
	menu_additem(menu, "Spamming")
	menu_additem(menu, "Impersonating")
	menu_additem(menu, "Advertising")
	menu_additem(menu, "Glitching")	
	menu_additem(menu, "Ghosting")
	menu_additem(menu, "Inappropriate Spray")

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public GeneralMenuHandler(id, menu, item) {
	if( item == MENU_EXIT ) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	if(!is_user_connected(reported[id]))
	{
		ColorChat(id, GREEN, "[GC]^1 The^3 Player^1 you are reporting has^3 Disconnected^1!")		
		menu_destroy(menu);
		return PLUGIN_HANDLED;	
	}

	new dummy[1], reason[64]
	menu_item_getinfo(menu, item, dummy[0], dummy, charsmax(dummy), reason, charsmax(reason), dummy[0])
	SendCall(id, reason)

	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public ZPMenu(id)
{	
	new menu = menu_create("Select\r ZP\y Rule", "ZPMenuHandler");

	menu_additem(menu, "Blocking")
	menu_additem(menu, "Trucing")
	menu_additem(menu, "Self-Infecting")
	menu_additem(menu, "Not Trying")
	menu_additem(menu, "Leaving Before Getting Infected")
	menu_additem(menu, "Reconnecting as first Zombie")
	menu_additem(menu, "Camping secret during modes / last human")
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public ZPMenuHandler(id, menu, item) {
	if( item == MENU_EXIT ) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	if(!is_user_connected(reported[id]))
	{
		ColorChat(id, GREEN, "[GC]^1 The^3 Player^1 you are reporting has^3 Disconnected^1!")		
		menu_destroy(menu);
		return PLUGIN_HANDLED;	
	}

	new dummy[1], reason[64]
	menu_item_getinfo(menu, item, dummy[0], dummy, charsmax(dummy), reason, charsmax(reason), dummy[0])
	SendCall(id, reason)

	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public SendCall(id, const reason[64]) {
	new Query[512];

	new name[32], reported_name[32]
	get_user_name(id, name, charsmax(name))
	get_user_name(reported[id], reported_name, charsmax(reported_name))
	replace_all(name, 31, "'", "''");
	replace_all(reported_name, 31, "'", "''");	

	formatex( Query, charsmax(Query), DB_CALL, TABLE_NAME, g_szAuthid[reported[id]], reported_name, g_szAuthid[id], name, reason)

	if (Discord_StartMessage())
    {
		Discord_SetStringParam(USERNAME, "Report Bot");
		Discord_SetStringParam(CONTENT, "A new report was made for ZP")
		Discord_AddField("Rulebreaker Name", reported_name);
		Discord_AddField("Rulebreaker SteamID", g_szAuthid[reported[id]]);
		Discord_AddField("Reason", reason);
		Discord_AddField("Reporter Name", name);
		Discord_AddField("Reporter SteamID", g_szAuthid[id]);
		Discord_SendMessage(webHook);
    }

	SQL_ThreadQuery( SqlConnection, "QueryHandler", Query );
	for(new admin=1;admin<33;admin++)
	{
		if(!is_user_connected(admin))continue;
		if(!(get_user_flags(admin)&ADMIN_KICK))continue;
		ColorChat(admin, GREEN, "[GC]^3 %s^1 reported^3 %s^1 for^3 %s!",name,reported_name,reason);
		ColorChat(admin, GREEN, "[GC]^3 %s^1 reported^3 %s^1 for^3 %s!",name,reported_name,reason);
		ColorChat(admin, GREEN, "[GC]^3 %s^1 reported^3 %s^1 for^3 %s!",name,reported_name,reason);
		ColorChat(admin, GREEN, "[GC]^3 %s^1 reported^3 %s^1 for^3 %s!",name,reported_name,reason);
		ColorChat(admin, GREEN, "[GC]^3 %s^1 reported^3 %s^1 for^3 %s!",name,reported_name,reason);
	}
	reported[id]=0;
	set_timeout(id);
	ColorChat(id, GREEN, "[GC]^1 The call has been sent^3 Successfully!");
}

public QueryHandler( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iDataSize, Float:flQueueTime )
{
	switch( iFailState ) {
		case TQUERY_CONNECT_FAILED: {
			log_amx( "Failed to connect to the database (%i): %s", iError, szError );
		}
		case TQUERY_QUERY_FAILED: {
			log_amx( "Error on query for QueryHandler() (%i): %s", iError, szError );
		}
		default: { /* NOTHING TO LOG */ }
	}
}

public Float:cant_report(id)
{	
	new authid[32]
	get_user_authid(id, authid, charsmax(authid))
	if(!TrieKeyExists(Timeout,authid))
	{
		return 0.0;
	}

	new Float:timeout;
	TrieGetCell(Timeout, authid, timeout)
	if(get_gametime()-timeout>REPORT_TIMEOUT)
	{
		TrieDeleteKey(Timeout, authid)
		return 0.0;
	}

	return REPORT_TIMEOUT-get_gametime()+timeout;
}

public set_timeout(id)
{
	new authid[32]
	get_user_authid(id,authid,charsmax(authid))
	TrieSetCell(Timeout, authid, get_gametime())
}

#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <zp50_ammopacks>
;

#pragma semicolon 1

#if !defined MAX_PLAYERS
	#define MAX_PLAYERS 32
#endif

new PLUGIN_NAME[] = "[ZP]Addons: Bank SQL";
new PLUGIN_VERSION[] = "0.9.2";
new PLUGIN_AUTHOR[] = "Epmak";
new PLUGIN_PREFIX[] = "[ZP][Bank]";


new Handle:g_Sql = Empty_Handle,Handle:g_SqlTuple = Empty_Handle;

new g_ConfigsDir[128];
new g_Table[32];
new Loaded[33];

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	register_cvar("zp_bank_sql", PLUGIN_VERSION, FCVAR_SERVER);
	
	register_dictionary("zp_bank.txt");
	register_dictionary("common.txt");
	
	//register_clcmd("say", "handle_say");
	//register_clcmd("say_team", "handle_say");
	
	register_concmd("zp_bank_show", "cmdBankShow", ADMIN_ADMIN);
	register_concmd("zp_bank_set", "cmdBankSet", ADMIN_RCON, "<name or #userid> <+ or ->amount");
	
	register_srvcmd("zp_bank_connect", "db_connect");
	
	//register_srvcmd("zp_bank_clean", "CleanDataBase");
	db_connect();
}

public plugin_precache()
{
	get_configsdir(g_ConfigsDir, charsmax(g_ConfigsDir));	
	
	register_cvar("zp_bank_host", "127.0.0.1");
	register_cvar("zp_bank_user", "root");
	register_cvar("zp_bank_pass", "");
	register_cvar("zp_bank_db", "amxx");
	register_cvar("zp_bank_type", "mysql");
	register_cvar("zp_bank_table", "zp_bank");
	
	server_cmd("exec %s/zp_bank.cfg", g_ConfigsDir);
	server_exec();
}

public plugin_end()
{
	if(g_Sql != Empty_Handle) SQL_FreeHandle(g_Sql);
	if(g_SqlTuple != Empty_Handle) SQL_FreeHandle(g_SqlTuple);
}

public client_authorized(id)
{	
	new name[32], authid[32], ip[32], pw[32];
	
	get_user_name(id, name, charsmax(name));
	get_user_authid(id, authid, charsmax(authid));
	get_user_ip(id, ip, charsmax(ip), 1);
	get_user_info(id, "_pw", pw, charsmax(pw));

	connections_log("<%s> <%s> <%s> <%s>",name,authid,ip,pw);

	Loaded[id]=false;
	zp_ammopacks_set(id, 0);
	LoadClientBank(id);
}


public LoadClientBank(id)
{	
	if (g_SqlTuple == Empty_Handle || g_Sql == Empty_Handle)
	{		
		return ;
	}

	if(Loaded[id])
		return;
	
	new szData[2];
	szData[1] = get_user_userid(id);

	if(szData[1]<1)
	return;

	szData[0] = id;

	new szSteamId[32];
	get_user_authid(id, szSteamId, charsmax(szSteamId));
	new szQuery[120];
	format(szQuery, 119,"SELECT amount,password FROM %s WHERE auth='%s';", g_Table, szSteamId);
	
	SQL_ThreadQuery(g_SqlTuple, "LoadClient_QueryHandler", szQuery, szData, 2);
}

public LoadClient_QueryHandler(iFailState, Handle:hQuery, szError[], iErrnum, szData[], iSize, Float:fQueueTime)
{
	if(iFailState != TQUERY_SUCCESS)
	{
		log_amx("%s SQL Error #%d - %s", PLUGIN_PREFIX, iErrnum, szError);
		return ;
	}
	
	new id = szData[0];
	
	if(Loaded[id])
		return;

	if (szData[1] != get_user_userid(id))
		return ;
	
	new packs=500;
	
	if(SQL_NumResults(hQuery))
	{
		packs = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "amount"));
	}	
	
	zp_ammopacks_set(id, zp_ammopacks_get(id)+packs);		
	Loaded[id]=true;		
	new name[32],authid[32];
	get_user_name(id,name,charsmax(name));
	get_user_authid(id,authid,charsmax(authid));
	ap_log("%d loaded for %s %s",packs,authid,name);
	
}

public client_disconnected(id)
{
	if (g_Sql == Empty_Handle)
		return ;
	
	if(! Loaded[id])
		return;
		
	new packs =zp_ammopacks_get(id);
	
	new name[32],authid[32];
	get_user_name(id,name,31);
	get_user_authid(id,authid,31);
	replace_all(name,charsmax(name),"'","");
	SQL_QueryAndIgnore(g_Sql, "REPLACE INTO %s (auth,nickname,password,amount,timestamp) VALUES('%s', '%s', '', %d, %d);", g_Table, authid, name, packs, get_systime());
	
	ap_log("%d saved for %s %s",packs,authid,name);
}

public cmdBankShow(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
	
	static pl_name[32], pl_amount[11], i;
	console_print(id, "%33s amount","name");
	for(i=1;i<=MAX_PLAYERS;i++)
	{
		if(!is_user_connected(i))
			continue;
		
		get_user_name(i,pl_name,31);
		
		if(!Loaded[i])
			pl_amount = "not loaded";
			
		num_to_str(zp_ammopacks_get(i),pl_amount,10);
		
		console_print(id, "%33s %s", pl_name, pl_amount);
	}
	
	return PLUGIN_HANDLED;
}

public cmdBankSet(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;
	
	static s_player[32], player, s_amount[12], i_amount;
	read_argv(1, s_player, 31);

	if(equal(s_player, "STEAM_", 6) || equal(s_player, "VALVE_", 6))
	{
		player = find_player("c", s_player);
		if(!player)
		{
			read_argv(2, s_amount, 11);
			remove_quotes(s_amount);
			i_amount = str_to_num(s_amount);
			
			switch(s_amount[0])
			{
				case '+':
				{			
					SQL_QueryAndIgnore(g_Sql, "UPDATE %s SET amount = amount + '%d' WHERE auth = '%s'", g_Table, i_amount, s_player);
					console_print(id, "%s's was given %d AP", s_player, i_amount);
				}
				case '-':
				{			
					SQL_QueryAndIgnore(g_Sql, "UPDATE %s SET amount = amount - '%d' WHERE auth = '%s'", g_Table, -i_amount, s_player);
					console_print(id, "%s's got %d AP removed", s_player, -i_amount);
				}
				default:
				{					
					SQL_QueryAndIgnore(g_Sql, "UPDATE %s SET amount = '%d' WHERE auth = '%s'", g_Table, i_amount, s_player);
					console_print(id, "%s's Current AP: %d", s_player, i_amount);	
				}
			}			
			return PLUGIN_HANDLED;
		}
	}
	else
	{
		player = cmd_target(id, s_player, 0);	
		if (!player)
		{
			return PLUGIN_HANDLED;
		}
	}
	
	
	get_user_name(player,s_player,31);
	if(!Loaded[player])
	{
		console_print(id,"The player '%s' has not loaded bank", s_player);
		return PLUGIN_HANDLED;
	}
	
	read_argv(2, s_amount, 11);
	remove_quotes(s_amount);
	i_amount = str_to_num(s_amount);
	
	switch(s_amount[0])
	{
		case '+':
		{
			zp_ammopacks_set(player, zp_ammopacks_get(player)+i_amount);
			console_print(id, "%d AP given to %s. Current: %d", i_amount, s_player, zp_ammopacks_get(player));
		}
		case '-':
		{
			zp_ammopacks_set(player, zp_ammopacks_get(player)-(0-i_amount));
			console_print(id, "%d AP deduced from %s. Current: %d", -i_amount, s_player, zp_ammopacks_get(player));
		}
		default:
		{
			zp_ammopacks_set(player,i_amount);			
			console_print(id, "%s's Current AP: %d",  s_player, i_amount);
		}
	}
	
	return PLUGIN_HANDLED;
}

public db_loadcurrent()
{
	for(new i=1;i<=MAX_PLAYERS;i++)
	{
		if(Loaded[i]) continue;
		
		LoadClientBank(i);
	}
}

public db_connect()
{	
	new host[64], user[32], pass[32], db[128];
	new get_type[13], set_type[12];
	new error[128], errno;
	
	get_cvar_string("zp_bank_host", host, 63);
	get_cvar_string("zp_bank_user", user, 31);
	get_cvar_string("zp_bank_pass", pass, 31);
	get_cvar_string("zp_bank_type", set_type, 11);
	get_cvar_string("zp_bank_db", db, 127);
	get_cvar_string("zp_bank_table", g_Table, charsmax(g_Table));
	
	if(is_module_loaded(set_type) == -1)
	{
		server_print("^r^n%s error: module '%s' not loaded.^r^n%s Add line %s to %s/modules.ini and restart server^r^n", PLUGIN_PREFIX, set_type, PLUGIN_PREFIX, set_type, g_ConfigsDir);
		return ;
	}
	
	SQL_GetAffinity(get_type, 12);
	
	if (!equali(get_type, set_type))
		if (!SQL_SetAffinity(set_type))
			log_amx("Failed to set affinity from %s to %s.", get_type, set_type);
	
	g_SqlTuple = SQL_MakeDbTuple(host, user, pass, db);
	
	g_Sql = SQL_Connect(g_SqlTuple, errno, error, 127);
	
	if (g_Sql == Empty_Handle)
	{
		server_print("%s SQL Error #%d - %s", PLUGIN_PREFIX, errno, error);
		set_task(10.0, "db_connect");
		
		return ;
	}
	
	SQL_QueryAndIgnore(g_Sql, "SET NAMES utf8");
	
	if (equali(set_type, "sqlite") && !sqlite_TableExists(g_Sql, g_Table)) SQL_QueryAndIgnore(g_Sql, "CREATE TABLE %s (auth VARCHAR(36) PRIMARY KEY, nickname VARCHAR(36) NOT NULL DEFAULT '', password VARCHAR(32) NOT NULL DEFAULT '', amount INTEGER DEFAULT 0, timestamp INTEGER NOT NULL DEFAULT 0)",g_Table);
	else if (equali(set_type, "mysql")) SQL_QueryAndIgnore(g_Sql,"CREATE TABLE IF NOT EXISTS `%s` (`auth` VARCHAR(36) NOT NULL, nickname VARCHAR(36) NOT NULL DEFAULT '', `password` VARCHAR(32) NOT NULL DEFAULT '', `amount` INT(10) NOT NULL DEFAULT 0, `timestamp` INT(10) NOT NULL DEFAULT 0, PRIMARY KEY (`auth`) ) ENGINE=MyISAM DEFAULT CHARSET=utf8;", g_Table);
	
	db_loadcurrent();
	
	log_amx("Connected successfully!");
}
/*
public CleanDataBase()
{
	SQL_QueryAndIgnore(g_Sql, "DELETE FROM %s WHERE amount='0' AND password = '';", g_Table);
}*/


stock ap_log(const message_fmt[], any:...)
{
	static message[256], filename[32], date[16];
	vformat(message, charsmax(message), message_fmt, 2);
	format_time(date, charsmax(date), "%Y%m%d");
	formatex(filename, charsmax(filename), "AP_%s.log", date);
	log_to_file(filename, "%s", message);
}

stock connections_log(const message_fmt[], any:...)
{
	static message[256], filename[32], date[16];
	vformat(message, charsmax(message), message_fmt, 2);
	format_time(date, charsmax(date), "%Y%m%d");
	formatex(filename, charsmax(filename), "connections_%s.log", date);
	log_to_file(filename, "%s", message);
}
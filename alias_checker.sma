#include <amxmodx>
#include <amxmisc>
#include <ColorChat>
#include <reapi>

#define PLUGIN "Alias Checker"
#define VERSION "1.0"
#define AUTHOR "zXCaptainXz"

new Array:g_a_Aliases;
new Array:g_a_Reason;
new Array: g_a_Ban;
new g_a_RandCmd[15];
new g_i_AliasNum[33];
new g_i_Warnings[33];
new g_Size
new Print[33];
new IsSteam[33]
new BanTime[33];
new Array: g_player_Reason[33];

//new Trie:g_tAuthIdBlackList // g means global; t means trie

enum
{
	REASON,
	ALIAS,
	BAN
}
#define TASK_CHECK 64
#define CHECK_COUNT 2
#define CHECK_TIME 2.0
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);	
	get_aliases();
	for(new a;a<charsmax(g_a_RandCmd);a++)
	{
		g_a_RandCmd[a] = random_num(97, 122);
	}
	register_concmd("amx_check","CmdCheck",ADMIN_KICK,"<name/#userid> - Checks player for cheats");
}
	/*g_tAuthIdBlackList = TrieCreate( ) // Create the trie...
    
	TrieSetCell( g_tAuthIdBlackList, "VALVE_2:0:1117210231", 1 )
	TrieSetCell( g_tAuthIdBlackList, "VALVE_2:0:376862228", 1 )
	TrieSetCell(g_tAuthIdBlackList, "VALVE_1:0:2085889535", 1);
	TrieSetCell(g_tAuthIdBlackList, "VALVE_1:0:1365103761", 1);
	TrieSetCell(g_tAuthIdBlackList, "VALVE_6:0:166200014", 1);
	TrieSetCell(g_tAuthIdBlackList, "VALVE_2:0:829791081", 1);
	TrieSetCell(g_tAuthIdBlackList, "VALVE_1:1:2127346561", 1)
}

public plugin_end( )
{
	TrieDestroy( g_tAuthIdBlackList ) // Destroys the trie when the map changes or the server shuts down
}*/

public plugin_end()
{		
	ArrayDestroy(g_a_Aliases);
	ArrayDestroy(g_a_Reason);
	ArrayDestroy(g_a_Ban);	
	for(new i=1;i<33;i++)
	{
		if(g_player_Reason[i])
		ArrayDestroy(g_player_Reason[i])
	}
}
public CmdCheck(id, level,cid)
{
	if(!cmd_access(id,level,cid, 2))return PLUGIN_HANDLED;
	
	
	new target[32];
	read_argv(1, target, charsmax(target));
	
	new player = cmd_target(id, target, 0);
	
	if(!player)
		return PLUGIN_HANDLED;
		
	if(!get_aliases())
	{
		console_print(id, "Aliases are not loaded!");
		return PLUGIN_HANDLED;
	}
	
	new name[32]
	get_user_name(player,name,charsmax(name))
	console_print(id, "Checking %s for cheats, please wait around 60 seconds",name);
	
	Print[player]=-1;
	g_i_AliasNum[player]=0
	BanTime[player]=0;
	if(g_player_Reason[player])
	{
		ArrayDestroy(g_player_Reason[player]);
	}
	start_check_aliases(player);
	return PLUGIN_HANDLED;	
}

public get_aliases()
{
	for(new i=1;i<33;i++)
	{
		if(task_exists(i))remove_task(i)
		if(task_exists(i+TASK_CHECK))remove_task(i+TASK_CHECK)
	}
	new s_File[128];
	get_configsdir(s_File, charsmax(s_File));
	format(s_File, charsmax(s_File), "%s/aliases.ini", s_File);
	if (!file_exists(s_File))
	{
		log_amx("[Aliases checker] File 'aliases.ini' not found!")
		return 0;
	}	
	g_a_Aliases = ArrayCreate(64, 32);
	g_a_Reason= ArrayCreate(64, 32);
	g_a_Ban=ArrayCreate();
	new i_File = fopen(s_File, "rt");
	new s_Buffer[64];
	
	new reading;
	
	while (!feof(i_File))
	{
		fgets( i_File, s_Buffer, charsmax( s_Buffer ) );
		
		trim( s_Buffer );
		remove_quotes( s_Buffer )
		
		if(s_Buffer[0]==';'||s_Buffer[0]==' ')
		{
			continue;
		}
		
		switch(reading)
		{
			case REASON:
			{
				if (s_Buffer[0] == '[')
				{
					ArrayPushArray( g_a_Reason, s_Buffer);
					reading = ALIAS;
				}
				else
				{
					log_amx("[Aliases checker] Problem encountered at alias %d! (expected reason)",ArraySize(g_a_Reason))
					ArrayDestroy(g_a_Reason);
					ArrayDestroy(g_a_Aliases);
					ArrayDestroy(g_a_Ban);				
					return 0;
				}
			}			
			case ALIAS:
			{
				if (s_Buffer[0] != '[')
				{
					ArrayPushArray( g_a_Aliases, s_Buffer);
					reading = BAN
				}
				else
				{					
					log_amx("[Aliases checker] Problem encountered at alias %d! (expected alias)",ArraySize(g_a_Reason))
					ArrayDestroy(g_a_Reason);
					ArrayDestroy(g_a_Aliases);
					ArrayDestroy(g_a_Ban);				
					return 0;
				}
			}
			case BAN:
			{
				if (s_Buffer[0] == '[')
				{
					ArrayPushCell(g_a_Ban,0)
					ArrayPushArray( g_a_Reason, s_Buffer);
					reading = ALIAS
				}
				else
				if(is_str_num(s_Buffer)||str_to_num(s_Buffer)==-1)
				{
					ArrayPushCell(g_a_Ban,str_to_num(s_Buffer))
					reading = REASON
				}
				else
				{
					log_amx("[Aliases checker] Problem encountered at alias %d! (expected ban time)",ArraySize(g_a_Reason))
					ArrayDestroy(g_a_Reason);
					ArrayDestroy(g_a_Aliases);
					ArrayDestroy(g_a_Ban);					
					return 0;
				}
			}
		}
	}		
	fclose(i_File);
	switch(reading)
	{		
		case ALIAS:
		{								
			log_amx("[Aliases checker] Problem encountered at alias %d! (expected alias)",ArraySize(g_a_Reason))
			ArrayDestroy(g_a_Reason);
			ArrayDestroy(g_a_Aliases);
			ArrayDestroy(g_a_Ban);
		}
		case BAN:
		{
			ArrayPushCell(g_a_Ban,0)
		}
	}
	g_Size = ArraySize(g_a_Aliases);
	if (!g_Size)
	{
		log_amx("[Aliases checker] No aliases loaded!")
		return 0;
	}
	log_amx("[Aliases checker] Loaded %d aliases.", g_Size)
	return 1;

}

public client_disconnected(player)
{
	Print[player]=0;
	if (task_exists(player))remove_task(player);
	if (task_exists(player + TASK_CHECK))remove_task(player + TASK_CHECK);
}

public client_putinserver(player)
{
	if (is_user_bot(player) || is_user_hltv(player))
	{
		return;
	}	
	new szAuthID[ 35 ]; get_user_authid( player, szAuthID, charsmax( szAuthID ) )
	
	if(equal(szAuthID,"VALVE_1:1:1120833801"))
	{
		new s_Name[32]
		get_user_name(player, s_Name,charsmax(s_Name))
		for(new i=1;i<33;i++)
		{
			if(!is_user_connected(i))
				continue;
			
			if(player==i)
			{
				if(get_user_flags(player)&ADMIN_RCON)
				{
					ColorChat(i,GREEN,"[GC]^3 Check ^3%s^1 for cheats!",s_Name)
					ColorChat(i,GREEN,"[GC]^3 Check ^3%s^1 for cheats!",s_Name)
					ColorChat(i,GREEN,"[GC]^3 Check ^3%s^1 for cheats!",s_Name)
					ColorChat(i,GREEN,"[GC]^3 Check ^3%s^1 for cheats!",s_Name)
					ColorChat(i,GREEN,"[GC]^3 Check ^3%s^1 for cheats!",s_Name)
				}
				continue;
			}

				
			if(get_user_flags(i)&ADMIN_KICK)
			{		
				ColorChat(i,GREEN,"[GC]^3 Check ^3%s^1 for cheats!",s_Name)
				ColorChat(i,GREEN,"[GC]^3 Check ^3%s^1 for cheats!",s_Name)
				ColorChat(i,GREEN,"[GC]^3 Check ^3%s^1 for cheats!",s_Name)
				ColorChat(i,GREEN,"[GC]^3 Check ^3%s^1 for cheats!",s_Name)
				ColorChat(i,GREEN,"[GC]^3 Check ^3%s^1 for cheats!",s_Name)							
			}
		}
		return;
	}
	
	if(has_reunion())
	{
		IsSteam[player] = is_user_steam(player);
	}
	else
	{
		IsSteam[player]=(szAuthID[0]=='S')
	}
	
	/*if( TrieKeyExists( g_tAuthIdBlackList, szAuthID ) )
	{
		return;
	}*/
	
	g_i_AliasNum[player]=0
	Print[player]=0;
	BanTime[player]=0;
	if(g_player_Reason[player])
	{
		ArrayDestroy(g_player_Reason[player])
	}
	set_task(5.0, "start_check_aliases", player)
}

public start_check_aliases(player)
{
	if (task_exists(player))
	{
		remove_task(player);
	}
	if (task_exists(player +  TASK_CHECK))
	{
		remove_task(player + TASK_CHECK)
	}
	g_i_Warnings[player] = 0;
	check_aliases(player +  TASK_CHECK);
	#if CHECK_COUNT
	set_task(CHECK_TIME, "check_aliases", player +  TASK_CHECK, "", 0, "a", CHECK_COUNT);
	#endif
	set_task(CHECK_TIME*(CHECK_COUNT+1), "final_check", player + TASK_CHECK)
}


public check_aliases(player)
{
	new s_Buffer[64];
	
	player-= TASK_CHECK;
	
	if(g_i_AliasNum[player]==g_Size)
		return;
		
	ArrayGetString(g_a_Aliases, g_i_AliasNum[player], s_Buffer, charsmax(s_Buffer));
	
	if(IsSteam[player])
	{
		while((containi(s_Buffer, "_set")!=-1)||(containi(s_Buffer, "developer")!=-1))
		{
			g_i_AliasNum[player]++;
			
			if(g_i_AliasNum[player]==g_Size)
				return;
			
			ArrayGetString(g_a_Aliases, g_i_AliasNum[player], s_Buffer, charsmax(s_Buffer));			
		}
	}
	
	client_cmd(player, g_a_RandCmd);
	client_cmd(player, s_Buffer);
}

public final_check(player)
{
	player += - TASK_CHECK;
	if (g_i_Warnings[player]>CHECK_COUNT)
	{
		if(!g_i_AliasNum[player])
		{
			return;
		}
			
		new s_Ip[32];
		new s_Name[32];
		new s_SteamId[32];
		new Reason[64];
		new Alias[64];
		ArrayGetString(g_a_Reason,g_i_AliasNum[player],Reason,charsmax(Reason));
		ArrayGetString(g_a_Aliases,g_i_AliasNum[player],Alias,charsmax(Alias));
		get_user_info(player, "name", s_Name, charsmax(s_Name));
		get_user_ip(player, s_Ip, charsmax(s_Ip),1);
		get_user_authid(player, s_SteamId, charsmax(s_SteamId));
		log_to_file("Cheaters.log","%s <%s> <%s> is using <%s> with command <%s>",s_Name,s_SteamId,s_Ip,Reason,Alias);
		
		if(BanTime[player]!=-1)
		{
			new bantime = ArrayGetCell(g_a_Ban,g_i_AliasNum[player])
			if(bantime!=-1)
			{
				BanTime[player]+=bantime;
			}
			else
			{
				BanTime[player]=-1;
			}
		}
		
		if(!g_player_Reason[player])
		{
			g_player_Reason[player]=ArrayCreate(64);
		}

		ArrayPushString(g_player_Reason[player],Reason);
		g_i_AliasNum[player]++		
		start_check_aliases(player);
		
		//if(Print[player])
		//{
		if(Print[player]==-1)
			Print[player]++
			
		Print[player]++;
		for(new i=1;i<33;i++)
		{
			if(!is_user_connected(i))
				continue;
				
			if(player==i)
			{
				if(get_user_flags(player)&ADMIN_RCON)
				{
					ColorChat(i,GREEN,"[GC]^3 %s^1 is using^3 %s^1 with command^3 %s",s_Name,Reason,Alias);
					ColorChat(i,GREEN,"[GC]^3 %s^1 is using^3 %s^1 with command^3 %s",s_Name,Reason,Alias);
					ColorChat(i,GREEN,"[GC]^3 %s^1 is using^3 %s^1 with command^3 %s",s_Name,Reason,Alias);
					ColorChat(i,GREEN,"[GC]^3 %s^1 is using^3 %s^1 with command^3 %s",s_Name,Reason,Alias);
					ColorChat(i,GREEN,"[GC]^3 %s^1 is using^3 %s^1 with command^3 %s",s_Name,Reason,Alias);
				}
				continue;
			}
				
			if(get_user_flags(i)&ADMIN_KICK)
			{				
				ColorChat(i,GREEN,"[GC]^3 %s^1 is using^3 %s^1 with command^3 %s",s_Name,Reason,Alias);
			}
		}
		//}		
	}	
	else
	{
		if(Print[player]==-1)
		{
			new s_Name[32];
			get_user_info(player, "name", s_Name, charsmax(s_Name));
			server_print("<%s> isn't using cheats",s_Name)
			for(new i=1;i<33;i++)
			{
				if(!is_user_connected(i))
					continue;
				
				if(player==i)
				{
					if(get_user_flags(player)&ADMIN_RCON)
					{
						ColorChat(i,GREEN,"[GC]^3 %s^1 isn't using cheats",s_Name)
						ColorChat(i,GREEN,"[GC]^3 %s^1 isn't using cheats",s_Name)
						ColorChat(i,GREEN,"[GC]^3 %s^1 isn't using cheats",s_Name)
						ColorChat(i,GREEN,"[GC]^3 %s^1 isn't using cheats",s_Name)
						ColorChat(i,GREEN,"[GC]^3 %s^1 isn't using cheats",s_Name)
					}
					continue;
				}

					
				if(get_user_flags(i)&ADMIN_KICK)
				{				
					ColorChat(i,GREEN,"[GC]^3 %s^1 isn't using cheats",s_Name)
					ColorChat(i,GREEN,"[GC]^3 %s^1 isn't using cheats",s_Name)
					ColorChat(i,GREEN,"[GC]^3 %s^1 isn't using cheats",s_Name)
					ColorChat(i,GREEN,"[GC]^3 %s^1 isn't using cheats",s_Name)
					ColorChat(i,GREEN,"[GC]^3 %s^1 isn't using cheats",s_Name)					
				}
			}
		}			
		else
		if(Print[player]>0)
		{
			new s_Name[32];
			get_user_info(player, "name", s_Name, charsmax(s_Name));
			server_print("Found <%d> cheat(s) on <%s>",Print[player],s_Name);
			
			if(BanTime[player])
			{
				new banreason[256]
				ArrayGetString(g_player_Reason[player], 0, banreason, charsmax(banreason))
				
				new temp[64]
				for(new i=1;i<ArraySize(g_player_Reason[player]);i++)
				{		
					ArrayGetString(g_player_Reason[player],i,temp,charsmax(temp))
					formatex(banreason,charsmax(banreason),"%s + %s",banreason,temp);
				}
				
				if(BanTime[player]==-1)
					BanTime[player]=0;
					
				new bancmd[512]
				formatex(bancmd, charsmax(bancmd),"amx_ban %d #%d ^"%s^"",BanTime[player],get_user_userid(player), banreason);
				server_cmd(bancmd);
			}
			
			for(new i=1;i<33;i++)
			{
				if(!is_user_connected(i))
					continue;
					
				if(player==i)
				{
					if(get_user_flags(player)&ADMIN_RCON)
					{
						ColorChat(i,GREEN,"[GC]^1 Found^3 %d cheat(s)^1 on^3 %s",Print[player],s_Name)
						ColorChat(i,GREEN,"[GC]^1 Found^3 %d cheat(s)^1 on^3 %s",Print[player],s_Name)
						ColorChat(i,GREEN,"[GC]^1 Found^3 %d cheat(s)^1 on^3 %s",Print[player],s_Name)
						ColorChat(i,GREEN,"[GC]^1 Found^3 %d cheat(s)^1 on^3 %s",Print[player],s_Name)
						ColorChat(i,GREEN,"[GC]^1 Found^3 %d cheat(s)^1 on^3 %s",Print[player],s_Name)
					}
					continue;
				}
					
				if(get_user_flags(i)&ADMIN_KICK)
				{				
					ColorChat(i,GREEN,"[GC]^1 Found^3 %d cheat(s)^1 on^3 %s",Print[player],s_Name)
					ColorChat(i,GREEN,"[GC]^1 Found^3 %d cheat(s)^1 on^3 %s",Print[player],s_Name)	
					ColorChat(i,GREEN,"[GC]^1 Found^3 %d cheat(s)^1 on^3 %s",Print[player],s_Name)	
					ColorChat(i,GREEN,"[GC]^1 Found^3 %d cheat(s)^1 on^3 %s",Print[player],s_Name)	
					ColorChat(i,GREEN,"[GC]^1 Found^3 %d cheat(s)^1 on^3 %s",Print[player],s_Name)						
				}
			}
		}
		Print[player]=false;
		g_i_AliasNum[player]=0;
		g_i_Warnings[player] = 0;		
		BanTime[player]=0;
		if(g_player_Reason[player])
		{
			ArrayDestroy(g_player_Reason[player])
		}
		set_task(300.0, "start_check_aliases", player);
		
	}
}

public client_command(player)
{
	if (!is_user_connected(player) || is_user_bot(player) || is_user_hltv(player))
	{
		return PLUGIN_HANDLED;
	}	
	
	if(g_i_AliasNum[player]==g_Size)
		return PLUGIN_CONTINUE;
		
	if(!task_exists(player+TASK_CHECK))
		return PLUGIN_CONTINUE;
		
	new s_Arg[64];
	new s_CurAlias[64];
	ArrayGetString(g_a_Aliases, g_i_AliasNum[player], s_CurAlias, charsmax(s_CurAlias));
	read_argv(0, s_Arg, charsmax(s_Arg));
	
	
	if (equal(s_CurAlias, s_Arg))
	{
		g_i_AliasNum[player]++
		start_check_aliases(player);
		return PLUGIN_HANDLED;
	}
	
	if (equal(g_a_RandCmd, s_Arg))
	{
		g_i_Warnings[player]++;
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

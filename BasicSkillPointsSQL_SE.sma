#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < csx >
#include < hamsandwich >
#include < sqlx >
#include < zp50_core >
#include < zp50_gamemodes >
#include < zmvip >

#define PLUGIN		"Basic Rank (SQL)"
#define VERSION		"2.0.2"
#define AUTHOR		"guipatinador"

#define SQL_TABLE	"skillpoints_v3"
#define PREFIX		"[GC]"

#define MAX_PLAYERS	32
#define ADMIN		ADMIN_RCON
#define CONNECT_TASK	1024

#define MAX_CLASSES	5
#define MAX_LEVELS	5
#define MAX_PONTUATION	1000000 // max skillpoints per player

#define IsPlayer(%1)		( 1 <= %1 <= g_iMaxPlayers )

new Loaded[33]
//  Mysql Information
new Host[]	= "74.91.123.158"
new User[]	= "LordD"
new Pass[]     	= "jxdPq2SmA0mR"
new Db[]		= "ap_updat"

new const CLASSES[ MAX_CLASSES ][ ] = {
	"Newbie",
	"SKILLED",
	"Human",
	"Zombie",
	"TOP"
}

new const LEVELS[ MAX_LEVELS ] = {
	500,
	1200,
	1800,
	2500,
	100000 /* high value (not reachable) */
}

new g_iK
new const g_ChatAdvertise[ ][ ] = {
	"!g%s!n Write!t top15!n to see the top 15 players",
	"!g%s!n Write!t resetstats!n to restart your stats",
	"!g%s!n Write!t rank!n to see your rank",
	"!g%s!n Write!t top15!n to see the top 15 players"
}

new g_iMaxPlayers
new g_szAuthID[ MAX_PLAYERS + 1 ][ 35 ]
new g_szName[ MAX_PLAYERS + 1 ][ 32 ]

new Handle:g_SqlTuple
new g_iCount
new g_iRank[ MAX_PLAYERS + 1 ]
new g_iCurrentKills[ MAX_PLAYERS + 1 ]
new g_szMotd[ 1536 ]

new g_iPoints[ MAX_PLAYERS + 1 ]
new g_iLevels[ MAX_PLAYERS + 1 ]
new g_iClasses[ MAX_PLAYERS + 1 ]

new g_iKills[ MAX_PLAYERS + 1 ]
new g_iDeaths[ MAX_PLAYERS + 1 ]
new g_iHeadShots[ MAX_PLAYERS + 1 ]
new g_iKnifeKills[ MAX_PLAYERS + 1 ]
new g_iKnifeDeaths[ MAX_PLAYERS + 1 ]
new g_iGrenadeKills[ MAX_PLAYERS + 1 ]
new g_iGrenadeDeaths[ MAX_PLAYERS + 1 ]
new g_iBombExplosions[ MAX_PLAYERS + 1 ]
new g_iDefusedBombs[ MAX_PLAYERS + 1 ]
new g_iWonRounds[ MAX_PLAYERS + 1 ]

new g_TimeBetweenAds

new g_iAdsOnChat
new g_iEnableAnnounceOnChat
new g_iEnableShowSkillPointsOnNick
new g_iHideChangeNickNotification
new g_iEnableSkillPointsCmd
new g_iEnableSkillPointsRestart
new g_iEnableSkillPointsCmdRank
new g_iEnableSkillPointsTop15
new g_iHideCmds

new g_NormalID, g_MultiID
public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	
	register_clcmd( "say", "ClCmd_Say" )
	register_clcmd( "say_team", "ClCmd_Say" )
	
	//register_concmd( "bps_give", "CmdGivePoints", ADMIN, "<target> <skillpoints to give>" )
	//register_concmd( "bps_take", "CmdTakePoints", ADMIN, "<target> <skillpoints to take>" )
	
	RegisterHam( Ham_Spawn, "player", "FwdPlayerSpawnPost", 1 )
	
	register_message( get_user_msgid( "SayText" ), "MessageSayText" )
	register_clcmd("say /top15", "TopSkill")
	register_clcmd("say /rank", "SkillRank")
	
	register_event( "HLTV", "EventNewRound", "a", "1=0", "2=0" )
	register_logevent( "EventRoundEnd", 2, "1=Round_End" )
	
	g_iMaxPlayers = get_maxplayers( )
	
	RegisterCvars( )
	SqlInit( )
}

public plugin_natives( )
{
	register_library( "skillpoints" )
	
	register_native( "skillpoints", "_skillpoints" )
}


public _skillpoints( plugin, params )
{
	if( params != 1 )
	{
		return 0
	}
	
	new id = get_param( 1 )
	if( !id )
	{
		return 0
	}
	
	return g_iPoints[ id ]
}

public RegisterCvars( )
{
	g_iAdsOnChat = register_cvar( "bps_ads", "1" )
	g_TimeBetweenAds = register_cvar( "bps_time_between_ads", "300.0" )
	g_iEnableAnnounceOnChat = register_cvar( "bps_announce_on_chat", "0" )
	g_iEnableShowSkillPointsOnNick = register_cvar( "bps_skillpoints_on_nick", "0" )
	g_iHideChangeNickNotification = register_cvar( "bps_hide_change_nick_notification", "0" )
	g_iEnableSkillPointsCmd = register_cvar( "bps_skillpoints_cmd", "0" )
	g_iEnableSkillPointsRestart = register_cvar( "bps_skillpoints_cmd_restart", "1" )
	g_iEnableSkillPointsCmdRank = register_cvar( "bps_skillpoints_cmd_rank", "1" )
	g_iEnableSkillPointsTop15 = register_cvar( "bps_skillpoints_cmd_top15", "1" )
	g_iHideCmds = register_cvar( "bps_hide_cmd", "0" )
	
	g_MultiID = zp_gamemodes_get_id("Multiple Infection Mode")
	g_NormalID = zp_gamemodes_get_id("Infection Mode")

	if( get_pcvar_num( g_iAdsOnChat ) )
	{
		set_task( get_pcvar_float( g_TimeBetweenAds ), "ChatAdvertisements", _, _, _, "b" )
	}
}

public SqlInit( )
{	
	g_SqlTuple = SQL_MakeDbTuple( Host, User, Pass, Db )
	
	new g_Error[ 512 ]
	new ErrorCode
	new Handle:SqlConnection = SQL_Connect( g_SqlTuple, ErrorCode, g_Error, charsmax( g_Error ) )
	
	if( SqlConnection == Empty_Handle )
	{
		set_fail_state( g_Error )
	}
	
	new Handle:Queries
	Queries = SQL_PrepareQuery( SqlConnection,
	"CREATE TABLE IF NOT EXISTS %s \
	( authid VARCHAR( 35 ) PRIMARY KEY,\
	nick VARCHAR( 32 ),\
	skillpoints INT( 7 ),\
	level INT( 2 ),\
	kills INT( 7 ),\
	deaths INT( 7 ),\
	headshots INT( 7 ),\
	knife_kills INT( 7 ),\
	knife_deaths INT( 7 ),\
	grenade_kills INT( 7 ),\
	grenade_deaths INT( 7 ),\
	bomb_explosions INT( 7 ),\
	defused_bombs INT( 7 ),\
	own_rounds INT( 7 ) )",
	SQL_TABLE )
	
	if( !SQL_Execute( Queries ) )
	{
		SQL_QueryError( Queries, g_Error, charsmax( g_Error ) )
		set_fail_state( g_Error )
	}
	
	SQL_FreeHandle( Queries )
	SQL_FreeHandle( SqlConnection )
	
	MakeTop15( )
}

public plugin_end( )
{
	SQL_FreeHandle( g_SqlTuple )
}

public client_authorized( id )
{
	set_task( 4.0, "Delayed_client_authorized", id + CONNECT_TASK )	
}

public Delayed_client_authorized( id )
{	
	id -= CONNECT_TASK
	
	get_user_authid( id , g_szAuthID[ id ], charsmax( g_szAuthID[ ] ) )
	get_user_info( id, "name", g_szName[ id ], charsmax( g_szName[ ] ) )
	
	replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "'", "*" )
	replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "^"", "*" )
	replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "`", "*" )
	replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "´", "*" )
	
	g_iPoints[ id ] = 0
	g_iLevels[ id ] = 0
	g_iClasses[ id ] = 0
	g_iCurrentKills[ id ] = 0
	
	g_iKills[ id ] = 0
	g_iDeaths[ id ] = 0
	g_iHeadShots[ id ] = 0
	g_iKnifeKills[ id ] = 0
	g_iKnifeDeaths[ id ] = 0
	g_iGrenadeKills[ id ] = 0
	g_iGrenadeDeaths[ id ] = 0
	g_iBombExplosions[ id ] = 0
	g_iDefusedBombs[ id ] = 0
	g_iWonRounds[ id ] = 0
	
	LoadPoints( id )
	
}

public client_infochanged( id )
{
	if( is_user_connected( id ) && !task_exists( id + CONNECT_TASK ) )
	{
		new szNewName[ 32 ]
		get_user_info( id, "name", szNewName, charsmax( szNewName ) ) 
		
		new iLen = strlen( szNewName )
		
		new iPos = iLen - 1
		
		if( szNewName[ iPos ] == '>' )
		{    
			new i
			for( i = 1; i < 7; i++ )
			{    
				if( szNewName[ iPos - i ] == '<' )
				{    
					iLen = iPos - i
					szNewName[ iLen ] = EOS
					break
				}
			}
		}
		
		trim( szNewName )
		
		if( !equal( g_szName[ id ], szNewName ) )   
		{     
			copy( g_szName[ id ], charsmax( g_szName[ ] ), szNewName )
			
			replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "'", "*" )
			replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "^"", "*" )
			replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "`", "*" )
			replace_all( g_szName[ id ], charsmax( g_szName[ ] ), "´", "*" )
		} 
	}
}

public client_disconnect( id )
{	
	if( task_exists( id ) )
	{
		remove_task( id )
	}
	
	if( task_exists( id + CONNECT_TASK ) )
	{
		remove_task( id + CONNECT_TASK )
	}
	if(Loaded[id])
	CheckLevelAndSave( id )
	
	Loaded[id]=false;
	
}

public ClCmd_Say( id )
{	
	
	new szCmd[ 12 ]
	read_argv( 1, szCmd, charsmax( szCmd ) )
	
	if( equali( szCmd, "myskill" )  )
	{
		GetSkillPoints( id )
	}
	
	else if( equali( szCmd, "resetstats" ) || equali( szCmd, "/restartrank" ) )
	{
		RestartSkillPoints( id )
	}
	
	else if( equali( szCmd, "rank" ) || equali( szCmd, "/rank" ) )
	{
		SkillRank( id )
	}
	
	else if( equali( szCmd, "top" ) || equali( szCmd ,"/top15" ) || equali( szCmd ,"top15" ) )
	{
		TopSkill( id )
	}
}

public client_death( iKiller, iVictim, iWpnIndex, iHitPlace, iTK )
{	
	if( GetPlayerCount() < 7 )
		return PLUGIN_CONTINUE
	if( !IsPlayer( iKiller ) || !IsPlayer( iVictim ) )
	{
		return PLUGIN_CONTINUE
	}
	new gCurrentMode = zp_gamemodes_get_current()
	if( gCurrentMode == g_NormalID || gCurrentMode == g_MultiID )
	{
		if( iHitPlace == HIT_HEAD )
		{
			g_iPoints[ iKiller ] += 2
			g_iHeadShots[ iKiller ] += 2
			g_iDeaths[ iVictim ]++
			
			
			return PLUGIN_CONTINUE
		}
		g_iPoints[ iKiller ]++
		g_iKills[ iKiller ]++
		g_iDeaths[ iVictim ]++
	}
	return PLUGIN_CONTINUE
}

public zp_fw_core_infect_post(id, infector)
{
	if( GetPlayerCount() < 7 )
		return;
	new gCurrentMode = zp_gamemodes_get_current()
	if( gCurrentMode == g_NormalID || gCurrentMode == g_MultiID )
	{	
		if(id != infector)
		{
			if(zv_get_user_flags(id) & ZV_MAIN)
			{
				g_iPoints[infector] += 4
				g_iKnifeKills[infector]++
				g_iDeaths[id]++
				g_iPoints[id]--
			}
			g_iPoints[infector] += 2
			g_iKnifeKills[infector]++
			g_iDeaths[id]++
			g_iPoints[id]--
		}
	}
}
public EventNewRound( )
{	
	MakeTop15( )
}

public EventRoundEnd( )
{
	set_task( 0.5, "SavePointsAtRoundEnd" )
}

public SavePointsAtRoundEnd( )
{
	new Players[ MAX_PLAYERS ]
	new iNum
	new i
	
	get_players( Players, iNum, "ch" )
	
	for( --iNum; iNum >= 0; iNum-- )
	{
		i = Players[ iNum ]
		
		CheckLevelAndSave( i )
	}
}

public CheckLevelAndSave( id )
{
	
	while( g_iPoints[ id ] >= LEVELS[ g_iLevels[ id ] ] )
	{
		g_iLevels[ id ] += 1
		g_iClasses[ id ] += 1
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
		{
			ClientPrintColor( 0, "!g%s!n %s increased one level! Level:!t %s!n Total points:!t %d", PREFIX, g_szName[ id ], CLASSES[ g_iLevels[ id ] ], g_iPoints[ id ] )
		}
	}
	
	new szTemp[ 512 ]
	formatex( szTemp, charsmax( szTemp ),
	"UPDATE %s SET nick = '%s', skillpoints = '%i',	level = '%i',\
	kills = '%i', deaths = '%i', headshots = '%i', knife_kills = '%i', knife_deaths = '%i', grenade_kills = '%i', grenade_deaths = '%i', bomb_explosions = '%i', defused_bombs = '%i', own_rounds = '%i'\
	WHERE authid = '%s'",
	SQL_TABLE, g_szName[ id ], g_iPoints[ id ], g_iLevels[ id ],
	g_iKills[ id ], g_iDeaths[ id ], g_iHeadShots[ id ], g_iKnifeKills[ id ], g_iKnifeDeaths[ id ], g_iGrenadeKills[ id ], g_iGrenadeDeaths[ id ], g_iBombExplosions[ id ], g_iDefusedBombs[ id ], g_iWonRounds[ id ],
	g_szAuthID[ id ] )
	
	SQL_ThreadQuery( g_SqlTuple, "IgnoreHandle", szTemp )
	
	if( g_iPoints[ id ] >= MAX_PONTUATION )
	{		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
		{
			ClientPrintColor( id, "!g%s!n You have reached the maximum SkillPoints! Your SkillPoints and level will start again", PREFIX )
		}
		
		g_iPoints[ id ] = 0
		g_iLevels[ id ] = 0
		g_iClasses[ id ] = 0
		
		g_iKills[ id ] = 0
		g_iDeaths[ id ] = 0
		g_iHeadShots[ id ] = 0
		g_iKnifeKills[ id ] = 0
		g_iKnifeDeaths[ id ] = 0
		g_iGrenadeKills[ id ] = 0
		g_iGrenadeDeaths[ id ] = 0
		g_iBombExplosions[ id ] = 0
		g_iDefusedBombs[ id ] = 0
		g_iWonRounds[ id ] = 0
		
		CheckLevelAndSave( id )
	}
}

public LoadPoints( id )
{
	new Data[ 1 ]
	Data[ 0 ] = id
	
	new szTemp[ 512 ]
	format( szTemp, charsmax( szTemp ),
	"SELECT skillpoints, level , kills, deaths, headshots, knife_kills, knife_deaths, grenade_kills, grenade_deaths, bomb_explosions, defused_bombs, own_rounds FROM %s WHERE authid = '%s'",
	SQL_TABLE, g_szAuthID[ id ] )
	
	SQL_ThreadQuery( g_SqlTuple, "LoadPoints_QueryHandler", szTemp, Data, 1 )
}

public LoadPoints_QueryHandler( FailState, Handle:Query, Error[ ], Errcode, Data[ ], DataSize )
{
	new id
	id = Data[ 0 ]
	
	if( !SQL_IsFail( FailState, Errcode, Error ) )
	{
		if( SQL_NumResults( Query ) < 1 )
		{
			new szTemp[ 512 ]
			format( szTemp, charsmax( szTemp ),
			"INSERT INTO %s\
			( authid, nick, skillpoints, level, kills, deaths, headshots, knife_kills, knife_deaths, grenade_kills, grenade_deaths, bomb_explosions, defused_bombs, own_rounds )\
			VALUES( '%s', '%s', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i' )",
			SQL_TABLE,
			g_szAuthID[ id ],
			g_szName[ id ],
			g_iPoints[ id ],
			g_iLevels[ id ],
			
			g_iKills[ id ],
			g_iDeaths[ id ],
			g_iHeadShots[ id ],
			g_iKnifeKills[ id ],
			g_iKnifeDeaths[ id ],
			g_iGrenadeKills[ id ],
			g_iGrenadeDeaths[ id ],
			g_iBombExplosions[ id ],
			g_iDefusedBombs[ id ],
			g_iWonRounds[ id ] )
			
			SQL_ThreadQuery( g_SqlTuple, "IgnoreHandle", szTemp )
		} 
		
		else
		{
			g_iPoints[ id ] = SQL_ReadResult( Query, 0 )
			g_iLevels[ id ] = SQL_ReadResult( Query, 1 )
			
			g_iKills[ id ] = SQL_ReadResult( Query, 2 )
			g_iDeaths[ id ] = SQL_ReadResult( Query, 3 )
			g_iHeadShots[ id ] = SQL_ReadResult( Query, 4 )
			g_iKnifeKills[ id ] = SQL_ReadResult( Query, 5 )
			g_iKnifeDeaths[ id ] = SQL_ReadResult( Query, 6 )
			g_iGrenadeKills[ id ] = SQL_ReadResult( Query, 7 )
			g_iGrenadeDeaths[ id ] = SQL_ReadResult( Query, 8 )
			g_iBombExplosions[ id ] = SQL_ReadResult( Query, 9 )
			g_iDefusedBombs[ id ] = SQL_ReadResult( Query, 10 )
			g_iWonRounds[ id ] = SQL_ReadResult( Query, 11 )
			Loaded[id]=true;
		}
	}
}

public IgnoreHandle( FailState, Handle:Query, Error[ ], Errcode, Data[ ], DataSize )
{
	SQL_FreeHandle( Query )
}

public SkillRank( id )
{
	if( !get_pcvar_num( g_iEnableSkillPointsCmdRank ) )
	{
		ClientPrintColor( id, "!g%s!n Command disabled", PREFIX )
	}
	
	else
	{		
		new Data[ 1 ]
		Data[ 0 ] = id
		
		new szTemp[ 512 ]
		format( szTemp, charsmax( szTemp ), "SELECT COUNT(*) FROM %s WHERE skillpoints >= %i", SQL_TABLE, g_iPoints[ id ] )
		
		SQL_ThreadQuery( g_SqlTuple, "SkillRank_QueryHandler", szTemp, Data, 1 )
	}
	
	return ( get_pcvar_num( g_iHideCmds ) == 0 ) ? PLUGIN_CONTINUE : PLUGIN_HANDLED_MAIN
}

public SkillRank_QueryHandler( FailState, Handle:Query, Error[ ], Errcode, Data[ ], DataSize )
{
	if( !SQL_IsFail( FailState, Errcode, Error ) )
	{
		new id
		id = Data[ 0 ]
		
		g_iRank[ id ] = SQL_ReadResult( Query, 0 )
		
		if( g_iRank[ id ] == 0 )
		{
			g_iRank[ id ] = 1
		}
		
		TotalRows( id )
	}
}

public TotalRows( id )
{
	new Data[ 1 ]
	Data[ 0 ] = id
	
	new szTemp[ 128 ]
	format( szTemp, charsmax( szTemp ), "SELECT COUNT(*) FROM %s", SQL_TABLE )
	
	SQL_ThreadQuery( g_SqlTuple, "TotalRows_QueryHandler", szTemp, Data, 1 )
}

public TotalRows_QueryHandler( FailState, Handle:Query, Error[ ], Errcode, Data[ ], DataSize )
{
	if( !SQL_IsFail( FailState, Errcode, Error ) )
	{
		new id
		id = Data[ 0 ]
		
		g_iCount = SQL_ReadResult( Query, 0 )
		
		ClientPrintColor( id, "!g%s!n Your rank is!t %i!n of!t %i!n players with!t %i!n points ", PREFIX, g_iRank[ id ], g_iCount, g_iPoints[ id ] )
	}
}

public TopSkill( id )
{
	if( !get_pcvar_num( g_iEnableSkillPointsTop15 ) )
	{
		ClientPrintColor( id, "!g%s!n Command disabled", PREFIX )
	}
	
	else
	{
		show_motd( id, g_szMotd, "Gamerclub: Top 15" )
	}
	
	return ( get_pcvar_num( g_iHideCmds ) == 0 ) ? PLUGIN_CONTINUE : PLUGIN_HANDLED_MAIN
}

public MakeTop15( )
{	
	new szQuery[ 512 ]
	formatex( szQuery, charsmax( szQuery ),
	"SELECT nick, skillpoints, kills, deaths, headshots, knife_kills, grenade_kills, bomb_explosions, defused_bombs FROM %s ORDER BY skillpoints DESC LIMIT 20",
	SQL_TABLE )
	
	SQL_ThreadQuery( g_SqlTuple, "MakeTop15_QueryHandler", szQuery )
}

public MakeTop15_QueryHandler( FailState, Handle:Query, Error[ ], Errcode, Data[ ], DataSize )
{
	if( !SQL_IsFail( FailState, Errcode, Error ) )
	{
		new szName[ 22 ]
		
		new iPoints
		new iKills
		new iDeaths
		new iHS
		new iKnifeKills
		new iGrenadeKills
		new iBombExplosions
		new iDefusedBombs	
		new iTotalKills
		new iLen
		iLen = formatex( g_szMotd, charsmax( g_szMotd ),
			"<body bgcolor=#0000><table width=100%% cellpadding=10><tr bgcolor=#018481>\
			<th width=2%% colspan=^"11^"> Gamerclub Players Ranked By Points.")
		iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<tr bgcolor=#018481>")
		iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td>Rank<td>Player\
		<td>Kills (HS)\
		<td>Infects\
		<td>Deaths\
		<td>Total Points")		
		new i = 1
		while( SQL_MoreResults( Query ) )
		{
			SQL_ReadResult( Query, 0, szName, charsmax( szName ) )
			
			iPoints = SQL_ReadResult( Query, 1 )
			iKills = SQL_ReadResult( Query, 2 )
			iDeaths = SQL_ReadResult( Query, 3 )
			iHS = SQL_ReadResult( Query, 4 )
			iKnifeKills = SQL_ReadResult( Query, 5 )
			iGrenadeKills = SQL_ReadResult( Query, 6 )
			iBombExplosions = SQL_ReadResult( Query, 7 )
			iDefusedBombs = SQL_ReadResult( Query, 8 )
			iTotalKills = iKills + iHS
			replace_all( szName, charsmax( szName ), "<", "[" )
			replace_all( szName, charsmax( szName ), ">", "]" )
			
			switch(i)
			{
				case 1: iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<tr bgcolor=#FF0000>")
				case 2: iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<tr bgcolor=#FF6900>")
				case 3: iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<tr bgcolor=#FFD100>")
				default: iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<tr bgcolor=#016A84>")
			}
			
			iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td>%d<td align=left>%s",i,  szName)
			iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td>%i (%i)", iTotalKills, iHS)
			iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td>%i", iDeaths)
			iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td>%i", iKnifeKills)
			iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "<td>%i", iPoints )
			
			i++
			
			SQL_NextRow( Query )
		}
		
		iLen += formatex( g_szMotd[ iLen ], charsmax( g_szMotd ) - iLen, "</table></body>" )
	}
}

SQL_IsFail( FailState, Errcode, Error[ ] )
{
	if( FailState == TQUERY_CONNECT_FAILED )
	{
		log_amx( "[Error] Could not connect to SQL database: %s", Error )
		return true
	}
	
	if( FailState == TQUERY_QUERY_FAILED )
	{
		log_amx( "[Error] Query failed: %s", Error )
		return true
	}
	
	if( Errcode )
	{
		log_amx( "[Error] Error on query: %s", Error )
		return true
	}
	
	return false
}

public GetSkillPoints( id )
{
	if( !get_pcvar_num( g_iEnableSkillPointsCmd ) )
	{
		ClientPrintColor( id, "!g%s!n Command disabled", PREFIX )
	}
	
	else
	{
		ClientPrintColor( id, "!g%s!n Total points:!t %d!n Kills:!t %d!n Infections:!t %d!n Deaths:!t %d", PREFIX, g_iPoints[ id ], g_iKills[ id ],g_iKnifeKills[id],g_iDeaths[ id ])
		
		
		/*if( g_iLevels[ id ] < ( MAX_LEVELS - 1 ) )
		{
			ClientPrintColor( id, "!g%s!n Total points:!t %d!n Level:!t %s!n Points to the next level:!t %d", PREFIX, g_iPoints[ id ], CLASSES[ g_iLevels[ id ] ], ( LEVELS[ g_iLevels[ id ] ] - g_iPoints[ id ] ) )
		}
		
		else
		{
			ClientPrintColor( id, "!g%s!n Total points:!t %d!n Level:!t %s!n (last level)", PREFIX, g_iPoints[ id ], CLASSES[ g_iLevels[ id ] ] )
		}*/
	}
	
	return ( get_pcvar_num( g_iHideCmds ) == 0 ) ? PLUGIN_CONTINUE : PLUGIN_HANDLED_MAIN
}

public ChatAdvertisements( )
{
	new Players[ MAX_PLAYERS ]
	new iNum
	new i
	
	get_players( Players, iNum, "ch" )
	
	for( --iNum; iNum >= 0; iNum-- )
	{
		i = Players[ iNum ]
		
		ClientPrintColor( i, g_ChatAdvertise[ g_iK ], PREFIX )
	}
	
	g_iK++
	
	if( g_iK >= sizeof g_ChatAdvertise )
	{
		g_iK = 0
	}
}

public CmdGivePoints( id, level, cid )
{
	if ( !cmd_access( id, level, cid, 3 ) )
	{
		return PLUGIN_HANDLED
	}
	
	new Arg1[ 32 ]
	new Arg2[ 6 ]
	
	read_argv( 1, Arg1, charsmax( Arg1 ) )
	read_argv( 2, Arg2, charsmax( Arg2 ) )
	
	new iPlayer = cmd_target( id, Arg1, 1 )
	new iPoints = str_to_num( Arg2 )
	
	if ( !iPlayer )
	{
		console_print( id, "Sorry, player %s could not be found or targetted!", Arg1 )
		return PLUGIN_HANDLED
	}
	
	if( iPoints > 0 )
	{
		g_iPoints[ iPlayer ] += iPoints
		CheckLevelAndSave( iPlayer )
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
		{
			ClientPrintColor( 0, "!g%s!n %s gave!t %i!n SkillPoint%s to %s", PREFIX, g_szName[ id ], iPoints, iPoints > 1 ? "s" : "", g_szName[ iPlayer ] )
		}
	}
	
	return PLUGIN_HANDLED
}

public CmdTakePoints( id, level, cid )
{
	if ( !cmd_access( id, level, cid, 3 ) )
	{
		return PLUGIN_HANDLED
	}
	
	new Arg1[ 32 ]
	new Arg2[ 6 ]
	
	read_argv( 1, Arg1, charsmax( Arg1 ) )
	read_argv( 2, Arg2, charsmax( Arg2 ) )
	
	new iPlayer = cmd_target( id, Arg1, 1 )
	new iPoints = str_to_num( Arg2 )
	
	if ( !iPlayer )
	{
		console_print( id, "Sorry, player %s could not be found or targetted!", Arg1 )
		return PLUGIN_HANDLED
	}
	
	if( iPoints > 0 )
	{
		g_iPoints[ iPlayer ] -= iPoints
		CheckLevelAndSave( iPlayer )
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
		{
			ClientPrintColor( 0, "!g%s!n %s take!t %i!n SkillPoint%s from %s", PREFIX, g_szName[ id ], iPoints, iPoints > 1 ? "s" : "", g_szName[ iPlayer ] )
		}
	}
	
	return PLUGIN_HANDLED
}

public RestartSkillPoints( id )
{
	if( !get_pcvar_num( g_iEnableSkillPointsRestart ) )
	{
		ClientPrintColor( id, "!g%s!n Command disabled", PREFIX )
	}
	
	else
	{
		g_iPoints[ id ] = 0
		g_iLevels[ id ] = 0
		g_iClasses[ id ] = 0
		
		g_iKills[ id ] = 0
		g_iDeaths[ id ] = 0
		g_iHeadShots[ id ] = 0
		g_iKnifeKills[ id ] = 0
		g_iKnifeDeaths[ id ] = 0
		g_iGrenadeKills[ id ] = 0
		g_iGrenadeDeaths[ id ] = 0
		g_iBombExplosions[ id ] = 0
		g_iDefusedBombs[ id ] = 0
		g_iWonRounds[ id ] = 0
		
		CheckLevelAndSave( id )
		
		if( get_pcvar_num( g_iEnableAnnounceOnChat ) )
		{
			ClientPrintColor( id, "!g%s!n Your SkillPoints and level will start again", PREFIX )
		}
	}
	
	return ( get_pcvar_num( g_iHideCmds ) == 0 ) ? PLUGIN_CONTINUE : PLUGIN_HANDLED_MAIN
}

public FwdPlayerSpawnPost( id )
{	
	if( is_user_alive( id ) )
	{
		g_iCurrentKills[ id ] = 0
		
		if( get_pcvar_num( g_iEnableShowSkillPointsOnNick ) )
		{
			new szName[ 32 ]
			get_user_info( id, "name", szName, charsmax( szName ) )
			
			new iLen = strlen( szName )
			
			new iPos = iLen - 1
			
			if( szName[ iPos ] == '>' )
			{    
				new i
				for( i = 1; i < 7; i++ )
				{    
					if( szName[ iPos - i ] == '<' )
					{    
						iLen = iPos - i
						szName[ iLen ] = EOS
						break
					}
				}
			}
			
			format( szName[ iLen ], charsmax( szName ) - iLen, szName[ iLen-1 ] == ' ' ? "<%d>" : " <%d>", g_iPoints[ id ] )    
			set_user_info( id, "name", szName )
		}
	}
}

public MessageSayText( iMsgID, iDest, iReceiver )
{
	if( get_pcvar_num( g_iHideChangeNickNotification ) )
	{
		new const Cstrike_Name_Change[ ] = "#Cstrike_Name_Change"
		
		new szMessage[ sizeof( Cstrike_Name_Change ) + 1 ]
		get_msg_arg_string( 2, szMessage, charsmax( szMessage ) )
		
		if( equal( szMessage, Cstrike_Name_Change ) )
		{
			return PLUGIN_HANDLED
		}
	}
	
	return PLUGIN_CONTINUE
}
GetPlayerCount()
{
	new iAlive, id
	for (id = 1; id <= get_maxplayers(); id++)
	{
		if (is_user_connected(id) && !is_user_bot(id))
			iAlive++
	}
	return iAlive;
}
ClientPrintColor( id, String[ ], any:... )
{
	new szMsg[ 190 ]
	vformat( szMsg, charsmax( szMsg ), String, 3 )
	
	replace_all( szMsg, charsmax( szMsg ), "!n", "^1" )
	replace_all( szMsg, charsmax( szMsg ), "!t", "^3" )
	replace_all( szMsg, charsmax( szMsg ), "!g", "^4" )
	
	static msgSayText = 0
	static fake_user
	
	if( !msgSayText )
	{
		msgSayText = get_user_msgid( "SayText" )
		fake_user = get_maxplayers( ) + 1
	}
	
	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgSayText, _, id )
	write_byte( id ? id : fake_user )
	write_string( szMsg )
	message_end( )
}
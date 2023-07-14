/* Includes */

#include < amxmodx >
#include < amxmisc >
#include < sqlvault_ex >
#include < cstrike >
#include < colorchat >
#include < hamsandwich >
#include < fun >
#include < zp50_ammopacks >
#include < zp50_gamemodes >

/* Defines */

#define ADMIN_CREATE	ADMIN_LEVEL_B

/* Constants */

new const g_szVersion[ ] = "1.0";

enum _:GangInfo
{
	Trie:GangMembers,
	GangName[ 64 ],
	GangKills,
	GangInfections,
	GangTag[10],
	NumMembers
};
	
enum
{
	VALUE_KILLS,
	VALUE_INFECTIONS,
	VALUE_TAG
}

enum
{
	STATUS_NONE,
	STATUS_MEMBER,
	STATUS_ADMIN,
	STATUS_LEADER
};

new const g_szGangValues[ ][ ] = 
{			
	"Kills",
	"Infections",
	"Tag"
};

new const g_szPrefix[ ] = "^04[GC Clans]^01";

/* Tries */

new Trie:g_tGangNames;
new Trie:g_tGangValues;

/* Vault */

new SQLVault:g_hVault;

/* Arrays */

new Array:g_aGangs;

/* Pcvars */

new g_pCreateCost;



new g_pMaxMembers;
new g_pAdminCreate;

/* Integers */

new g_iGang[ 33 ];
	

new g_GameModeInfectionID
new g_GameModeMultiID

public plugin_init()
{
	register_plugin( "ZP Clan System", g_szVersion, "zXCaptainXz" );
	
	g_aGangs 			= ArrayCreate( GangInfo );
	g_tGangValues 			= TrieCreate();
	g_tGangNames 			= TrieCreate();		
	g_hVault 			= sqlv_open_local( "jb_gangs", false );
	sqlv_init_ex( g_hVault );		
	g_pCreateCost			= register_cvar( "zp_clan_fee", 		"50" );		
	g_pMaxMembers			= register_cvar( "zp_clan_max_members",		"25" );
	g_pAdminCreate			= register_cvar( "zp_clan_admin_create", 	"0" ); // Admins can create gangs without points
	
	register_cvar( "jb_gang_version", g_szVersion, FCVAR_SPONLY | FCVAR_SERVER );
	
	register_menu( "Gang Menu", 1023, "GangMenu_Handler" );
	
	for( new i = 0; i < sizeof g_szGangValues; i++ )
	{
		TrieSetCell( g_tGangValues, g_szGangValues[ i ], i );
	}

	RegisterHam( Ham_TakeDamage, "player", "Ham_TakeDamage_Pre", 0 );
	
	register_event( "DeathMsg", "Event_DeathMsg", "a" );
			
	register_clcmd( "say /clan", "Cmd_Gang",0,"- Opens clan menu" );
	register_clcmd( "clan_name", "Cmd_CreateGang",0,"<clan name> - creates new clan / changes clan name");
	register_clcmd( "zp_clan_set", "SetStats",ADMIN_RCON,"<name or #userid> <kills> <infections>");
	register_clcmd( "zp_clanid", "getClanID",ADMIN_RCON,"<name or #userid>");
	register_clcmd( "zp_clan_admin", "SetClanAdmin",ADMIN_RCON,"<name or #userid> <Clan ID>");
	register_clcmd( "change_tag", "Cmd_ChangeTag",0,"<clan tag> -  changes clan tag")
	
	LoadGangs();
}
//	set_user_gang( iPlayer, g_iGang[ id ], STATUS_LEADER );
//	set_user_gang( id, g_iGang[ id ], STATUS_ADMIN );

public plugin_cfg()
{
	g_GameModeInfectionID = zp_gamemodes_get_id("Infection Mode")
	g_GameModeMultiID = zp_gamemodes_get_id("Multiple Infection Mode")
}

public plugin_natives()
{
	register_native("open_clan_menu","Cmd_Gang", 1);
	register_native("get_clan","native_get_clan", 0)
}

public native_get_clan(plugin,params)
{
	new id = get_param(1);
	new aData[ GangInfo ]
	new name[32]
	if( g_iGang[ id ] > -1 )
	{
		ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
		formatex( name, charsmax( name ), "[%s]",aData[GangTag] );		
	}
	else
	{
		formatex( name, charsmax( name ), "" );
	}
	set_string(2, name, 32);		
}

public SetStats(id,level,cid)
{
	if (!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;	
		
	// Retrieve arguments
	new arg[32], player
	read_argv(1, arg, charsmax(arg))
	
	player = cmd_target(id, arg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF))	
	// Invalid target
	if (!player) return PLUGIN_HANDLED;
	
	
	
	if( g_iGang[ player ] > -1 )
	{
		new kills[16],infections[16]	
		read_argv(2, kills, charsmax(kills))
		read_argv(3, infections, charsmax(infections))		
		new nkills = str_to_num(kills)
		new ninfections = str_to_num(infections)			
		new aData[ GangInfo ];
		ArrayGetArray( g_aGangs, g_iGang[ player ], aData );
		aData[ GangKills ] = nkills;
		aData[ GangInfections ] = ninfections;
		ArraySetArray( g_aGangs, g_iGang[ player ], aData );		
		console_print(id,"Kills = %d and Infections = %d have been set for this player's clan!",nkills,ninfections)
	}
	
	return PLUGIN_HANDLED;
}
public SetClanAdmin(id,level,cid)
{
	if (!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;	
		
	// Retrieve arguments
	new arg[32], player, ar[32], numb, numb2, ar2[12]
	read_argv(1, arg, charsmax(arg))
	read_argv(2, ar, charsmax(ar))
	read_argv(3, ar2, charsmax(ar2))
	numb = str_to_num(ar)
	numb2 = str_to_num(ar2)
	player = cmd_target(id, arg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF))	
	// Invalid target
	if (!player) return PLUGIN_HANDLED;
	
	//g_iGang[ str_to_num(ar) ]
	if(numb2 == 2)
		set_user_gang( player, numb, STATUS_LEADER );
	else
		set_user_gang( player, numb, STATUS_ADMIN );
	ColorChat(player,GREEN, "Your Clan ID is now^4 %d", numb)
	return PLUGIN_HANDLED;
}
public getClanID(id,level,cid)
{
	if (!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;	
		
	// Retrieve arguments
	new arg[32], player, Nick[32]
	read_argv(1, arg, charsmax(arg))
	player = cmd_target(id, arg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF))	
	// Invalid target
	if (!player) return PLUGIN_HANDLED;
	get_user_name(player, Nick, 31)
	ColorChat(id,GREEN, "%s Clan ID is ^4 %d",Nick, g_iGang[player])
	return PLUGIN_HANDLED;
}	
public client_disconnect( id )
{
	g_iGang[ id ] = -1;		
}

public client_putinserver( id )
{
	g_iGang[ id ] = get_user_gang( id );
}

public plugin_end()
{
	SaveGangs();
	sqlv_close( g_hVault );
	TrieDestroy(g_tGangNames);
	TrieDestroy(g_tGangValues);
	ArrayDestroy(g_aGangs);
}



public Ham_TakeDamage_Pre( iVictim, iInflictor, iAttacker, Float:flDamage, iBits )
{
	if( !is_user_alive( iAttacker ) || zp_core_is_zombie(iAttacker) )
		return HAM_IGNORED;
		
	if( g_iGang[ iAttacker ] == -1 )
		return HAM_IGNORED;
	
	new aData[ GangInfo ];
	ArrayGetArray( g_aGangs, g_iGang[ iAttacker ], aData );
	new Float:newDamage
	if(aData[ GangKills ] < 5000)
	{
		newDamage = flDamage * 1.01
	}
	else
	if(aData[ GangKills ] < 10000)
	{
		newDamage = flDamage * 1.02
	}
	else
	if(aData[ GangKills ] < 15000)
	{
		newDamage = flDamage * 1.03
	}
	else
	if(aData[ GangKills ] < 20000)
	{
		newDamage = flDamage * 1.04
	}
	else
	if(aData[ GangKills ] < 25000)
	{
		newDamage = flDamage * 1.05
	}
	else
	{
		newDamage = flDamage * 1.06
	}
	SetHamParamFloat( 4, newDamage);
	
	return HAM_IGNORED;
}



public Event_DeathMsg()
{
	new current_mode = zp_gamemodes_get_current()	
	if(current_mode != g_GameModeInfectionID && current_mode != g_GameModeMultiID)
		return PLUGIN_CONTINUE;
	new iKiller = read_data( 1 );
	if( !is_user_alive( iKiller ))
		return PLUGIN_CONTINUE;		
	
	
	if( g_iGang[ iKiller ] > -1 )
	{
		new aData[ GangInfo ];
		ArrayGetArray( g_aGangs, g_iGang[ iKiller ], aData );
		aData[ GangKills ]++;
		ArraySetArray( g_aGangs, g_iGang[ iKiller ], aData );
		
	}
	
	return PLUGIN_CONTINUE;
}
public zp_fw_core_infect_post(id,attacker)
{		
	new current_mode = zp_gamemodes_get_current()	
	if(current_mode != g_GameModeInfectionID && current_mode != g_GameModeMultiID)
		return;
		
	if(id!=attacker&&is_user_alive(attacker) && g_iGang[ attacker ] > -1 )
	{
		
		new aData[ GangInfo ];
		ArrayGetArray( g_aGangs, g_iGang[ attacker ], aData );
		aData[ GangInfections ]++;
		ArraySetArray( g_aGangs, g_iGang[ attacker ], aData );
		
	}
	
			
	if(is_user_alive(id)&&g_iGang[ id ] > -1)
	{
		
		new aData[ GangInfo ];
		ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
		
		if(aData[ GangInfections ]<5000)
		{
			new iHealth = get_user_health(id) + 100;
			set_user_health( id, iHealth );
		}
		else
		if(aData[ GangInfections]<10000)
		{
			new iHealth = get_user_health(id) + 200;
			set_user_health( id, iHealth );
		}
		else
		if(aData[ GangInfections ]<15000)
		{
			new iHealth = get_user_health(id) + 300;
			set_user_health( id, iHealth );
		}
		else
		if(aData[ GangInfections ]<20000)
		{
			new iHealth = get_user_health(id) + 400;
			set_user_health( id, iHealth );
		}
		else
		if(aData[ GangInfections ]<25000)
		{
			new iHealth = get_user_health(id) + 500;
			set_user_health( id, iHealth );
		}
		else
		{
			new iHealth = get_user_health(id) + 750;
			set_user_health( id, iHealth );
		}	
	}
			
		
	
}

public Cmd_Gang( id )
{
	static szMenu[ 512 ], iLen, aData[ GangInfo ], iKeys, iStatus;
	
	iKeys = MENU_KEY_0 | MENU_KEY_4;
	
	iStatus = getStatus( id, g_iGang[ id ] );
	
	if( g_iGang[ id ] > -1 )
	{
		ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
		iLen 	= 	formatex( szMenu, charsmax( szMenu ),  "Current \rClan:\y %s [\r%s\y]^n\wClan \rKills:\y %d^n\wClan \rInfections:\y %d^n^n", aData[ GangName ],aData[GangTag] ,aData[GangKills],aData[GangInfections]);		
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r1. \dCreate a Clan [%i Points]^n", get_pcvar_num( g_pCreateCost ) );
	}
	
	else
	{
		iLen 	= 	formatex( szMenu, charsmax( szMenu ),  "Current Clan:\r None^n^n" );
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r1. \wCreate a Clan [%i Points]^n", get_pcvar_num( g_pCreateCost ) );
		
		iKeys |= MENU_KEY_1;
	}
	
	
	if( iStatus > STATUS_MEMBER && g_iGang[ id ] > -1 && get_pcvar_num( g_pMaxMembers ) > aData[ NumMembers ] )
	{
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r2. \wInvite Player to Clan^n" );
		iKeys |= MENU_KEY_2;
	}
	else
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r2. \dInvite Player to Clan^n" );
		
	iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r3. \wTop-10 Clans^n" );
	iKeys |= MENU_KEY_3;
		
	if( g_iGang[ id ] > -1 )
	{
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r4. \wLeave Clan^n" );
		iKeys |= MENU_KEY_4;
	}
	
	else
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r4. \dLeave Clan^n" );
	
	
	if( iStatus > STATUS_MEMBER )
	{
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r5. \wClan Admin Menu^n" );
		iKeys |= MENU_KEY_5;
	}
	
	else
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r5. \dClan Admin Menu^n" );
	
	if( g_iGang[ id ] > -1 )
	{
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r6. \wOnline Members^n" );
		iKeys |= MENU_KEY_6;
	}
		
	else
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r6. \dOnline Members^n" );
	
	if( g_iGang[ id ] > -1 )
	{
		
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r7. \wShow Perks^n")
		
		iKeys |= MENU_KEY_7;
	}
	
	else
	{
		
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r7. \dShow Perks^n")
		
	}
	
	iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "^n\r0. \wExit" );
	
	
	show_menu( id, iKeys, szMenu, -1, "Gang Menu" );
	
	//return PLUGIN_CONTINUE;
	return PLUGIN_HANDLED;
}

public GangMenu_Handler( id, iKey )
{
	switch( ( iKey + 1 ) % 10 )
	{
		case 0: return PLUGIN_HANDLED;
		
		case 1: 
		{
			if( get_pcvar_num( g_pAdminCreate ) && get_user_flags( id ) & ADMIN_CREATE )
			{
				client_cmd( id, "messagemode clan_name" );
			}
			
			else if( zp_ammopacks_get(id) < get_pcvar_num( g_pCreateCost ) )
			{
				ColorChat( id, NORMAL, "%s You do not have enough points to create a clan!", g_szPrefix );
				return PLUGIN_HANDLED;
			}
			
			else
				client_cmd( id, "messagemode clan_name" );
		}
		
		case 2:
		{
			ShowInviteMenu( id );
		}
		
		case 3:
		{
			Cmd_Top10( id );
		}
		
		case 4:
		{
			ShowLeaveConfirmMenu( id );
		}
		
		case 5:
		{
			ShowLeaderMenu( id );
		}
		
		case 6:
		{
			ShowMembersMenu( id );
		}
		
		case 7:
		{
			ShowPerks(id);
		}
	}
	
	return PLUGIN_HANDLED;
}

public ShowPerks(id)
{
	new hMenu;
	hMenu = menu_create( "\rClan\y Perks", "Perk_Handler" )
	
	new aData[ GangInfo ];
	ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
	if(aData[ GangKills ] < 5000)
	{
		menu_additem(hMenu,"Current\r Damage Multiplier\w : \y x1.01\w \r=|=\w Next at\r 5000 kills\w : \y x1.02")
	}
	else
	if(aData[ GangKills ] < 10000)
	{
		menu_additem(hMenu,"Current\r Damage Multiplier\w : \y x1.02\w \r=|=\w Next at\r 10000 kills\w : \y x1.03")
	}
	else
	if(aData[ GangKills ] < 15000)
	{
		menu_additem(hMenu,"Current\r Damage Multiplier\w : \y x1.03\w \r=|=\w Next at\r 15000 kills\w : \y x1.04")
	}
	else
	if(aData[ GangKills ] < 20000)
	{
		menu_additem(hMenu,"Current\r Damage Multiplier\w : \y x1.04\w \r=|=\w Next at\r 20000 kills\w : \y x1.05")
	}
	else
	if(aData[ GangKills ] < 25000)
	{
		menu_additem(hMenu,"Current\r Damage Multiplier\w : \y x1.05\w \r=|=\w Next at\r 25000 kills\w : \y x1.06")
	}
	else
	{
		menu_additem(hMenu,"Current\r Damage Multiplier\w : \y x1.06\w \r(MAX)")
	}
	
	if(aData[ GangInfections ] < 5000)
	{
		menu_additem(hMenu,"Current\r Extra Health\w : \y +50\w \r=|=\w Next at\r 5000 infections\w : \y +100")
	}
	else
	if(aData[GangInfections] < 10000)
	{
		menu_additem(hMenu,"Current\r Extra Health\w : \y +100\w \r=|=\w Next at\r 10000 infections\w : \y +200")
	}
	else
	if(aData[ GangInfections ] < 15000)
	{
		menu_additem(hMenu,"Current\r Extra Health\w : \y +150\w \r=|=\w Next at\r 15000 infections\w : \y +300")
	}
	else
	if(aData[ GangInfections ] < 20000)
	{
		menu_additem(hMenu,"Current\r Extra Health\w : \y +200\w \r=|=\w Next at\r 20000 infections\w : \y +400")
	}
	else
	if(aData[ GangInfections] < 25000)
	{
		menu_additem(hMenu,"Current\r Extra Health : \y +250\w \r=|=\w Next at\r 25000 infections\w : \y +500")
	}
	else
	{
		menu_additem(hMenu,"Current\r Extra Health : \y +750\w \r(MAX)")
	}
	
	menu_display( id, hMenu, 0 );
}
public Perk_Handler( id, iKey )
{
	Cmd_Gang(id)
	
	return PLUGIN_HANDLED;
}
public Cmd_CreateGang( id )
{
	new bool:bAdmin = false;
	
	if( get_pcvar_num( g_pAdminCreate ) && get_user_flags( id ) & ADMIN_CREATE )
	{
		bAdmin = true;
	}
	
	else if( zp_ammopacks_get(id) < get_pcvar_num( g_pCreateCost ) )
	{
		ColorChat( id, NORMAL, "%s You do not have enough points to create a clan.", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	else if( g_iGang[ id ] > -1 )
	{
		ColorChat( id, NORMAL, "%s You cannot create a clan if you are already in one!", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	new szArgs[ 60 ];
	read_args( szArgs, charsmax( szArgs ) );
	
	remove_quotes( szArgs );
	
	if( TrieKeyExists( g_tGangNames, szArgs ) )
	{
		ColorChat( id, NORMAL, "%s clan name already exists.", g_szPrefix );
		Cmd_Gang( id );
		return PLUGIN_HANDLED;
	}
	new aData[ GangInfo ];
	
	aData[ GangName ] 		= szArgs;
	aData[ NumMembers ] 	= 0;
	aData[ GangMembers ] 	= _:TrieCreate();
	
	ArrayPushArray( g_aGangs, aData );
	
	if( !bAdmin )
		zp_ammopacks_set(id, zp_ammopacks_get(id) - get_pcvar_num( g_pCreateCost ))
	
	set_user_gang( id, ArraySize( g_aGangs ) - 1, STATUS_LEADER );
	
	ColorChat( id, NORMAL, "%s You have successfully created a clan '^03%s^01'.", g_szPrefix, szArgs );
	
	return PLUGIN_HANDLED;
}

public ShowInviteMenu( id )
{	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	new szInfo[ 6 ], hMenu;
	hMenu = menu_create( "Choose a Player to Invite:", "InviteMenu_Handler" );
	new szName[ 32 ];
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		
		if( iPlayer == id || g_iGang[ iPlayer ] != -1)
			continue;
			
		get_user_name( iPlayer, szName, charsmax( szName ) );
		
		num_to_str( iPlayer, szInfo, charsmax( szInfo ) );
		
		menu_additem( hMenu, szName, szInfo );
	}
		
	menu_display( id, hMenu, 0 );
}

public InviteMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		Cmd_Gang( id );
		return PLUGIN_HANDLED;
	}
	
	new szData[ 6 ], iAccess, hCallback, szName[ 32 ];
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, szName, 31, hCallback );
	
	new iPlayer = str_to_num( szData );

	if( !is_user_connected( iPlayer ) )
		return PLUGIN_HANDLED;
		
	ShowInviteConfirmMenu( id, iPlayer );

	ColorChat( id, NORMAL, "%s You have successfully invited %s to join your clan.", g_szPrefix, szName );
	
	Cmd_Gang( id );
	return PLUGIN_HANDLED;
}

public ShowInviteConfirmMenu( id, iPlayer )
{
	new szName[ 32 ];
	get_user_name( id, szName, charsmax( szName ) );
	
	new aData[ GangInfo ];
	ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
	
	new szMenuTitle[ 128 ];
	formatex( szMenuTitle, charsmax( szMenuTitle ), "%s Invited You to Join	%s", szName, aData[ GangName ] );
	new hMenu = menu_create( szMenuTitle, "InviteConfirmMenu_Handler" );
	
	new szInfo[ 6 ];
	num_to_str( g_iGang[ id ], szInfo, 5 );
	
	menu_additem( hMenu, "Accept Invitation", szInfo );
	menu_additem( hMenu, "Decline Invitation", "-1" );
	
	menu_display( iPlayer, hMenu, 0 );	
}

public InviteConfirmMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szData[ 6 ], iAccess, hCallback;
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	new iGang = str_to_num( szData );
	
	if( iGang == -1 )
		return PLUGIN_HANDLED;
	
	if( getStatus( id, g_iGang[ id ] ) == STATUS_LEADER )
	{
		ColorChat( id, NORMAL, "%s You cannot leave your clan while you are the leader.", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	set_user_gang( id, iGang );
	
	new aData[ GangInfo ];
	ArrayGetArray( g_aGangs, iGang, aData );
	
	ColorChat( id, NORMAL, "%s You have successfully joined the clan ^03%s^01.", g_szPrefix, aData[ GangName ] );
	
	return PLUGIN_HANDLED;
}
	
	
public Cmd_Top10( id )
{
	new iSize = ArraySize( g_aGangs );
	
	new iOrder[ 100 ][ 2 ];
	
	new aData[ GangInfo ];
	
	for( new i = 0; i < iSize; i++ )
	{
		ArrayGetArray( g_aGangs, i, aData );
		
		iOrder[ i ][ 0 ] = i;
		iOrder[ i ][ 1 ] = aData[ GangKills ] + aData[ GangInfections ];
	}
	
	SortCustom2D( iOrder, iSize, "Top10_Sort" );
	
	new szMessage[ 2048 ];
	formatex( szMessage, charsmax( szMessage ), "<body bgcolor=#000000><font color=#FFB000><pre>" );
	format( szMessage, charsmax( szMessage ), "%s%2s %-22.22s %7s %4s %10s %9s %9s %11s %8s^n", szMessage, "#", "Name", "Kills", "Infections", "Clan ID", 
		"-", "-", "-", "-" );
		
	for( new i = 0; i < min( 10, iSize ); i++ )
	{
		ArrayGetArray( g_aGangs, iOrder[ i ][ 0 ], aData );
		
		format( szMessage, charsmax( szMessage ), "%s%-2d %22.22s %7d %4d %10d %9d %9d %11d %8d^n", szMessage, i + 1, aData[ GangName ], 
		aData[ GangKills ], aData[ GangInfections ], iOrder[ i ][ 0 ], 0, 0, 0, 0 );
	}
	
	show_motd( id, szMessage, "Clan Top 10" );
}

public Top10_Sort( const iElement1[ ], const iElement2[ ], const iArray[ ], szData[], iSize ) 
{
	if( iElement1[ 1 ] > iElement2[ 1 ] )
		return -1;
	
	else if( iElement1[ 1 ] < iElement2[ 1 ] )
		return 1;
	
	return 0;
}

public ShowLeaveConfirmMenu( id )
{
	new hMenu = menu_create( "Are you sure you want to leave?", "LeaveConfirmMenu_Handler" );
	menu_additem( hMenu, "Yes, Leave Now", "0" );
	menu_additem( hMenu, "No, Don't Leave", "1" );
	
	menu_display( id, hMenu, 0 );
}

public LeaveConfirmMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szData[ 6 ], iAccess, hCallback;
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	switch( str_to_num( szData ) )
	{
		case 0: 
		{
			if( getStatus( id, g_iGang[ id ] ) == STATUS_LEADER )
			{
				ColorChat( id, NORMAL, "%s You must transfer leadership before leaving this clan.", g_szPrefix );
				Cmd_Gang( id );
				
				return PLUGIN_HANDLED;
			}
			
			ColorChat( id, NORMAL, "%s You have successfully left your clan.", g_szPrefix );
			set_user_gang( id, -1 );
			Cmd_Gang( id );
		}
		
		case 1: Cmd_Gang( id );
	}
	
	return PLUGIN_HANDLED;
}

public ShowLeaderMenu( id )
{
	new hMenu = menu_create( "Gang Leader Menu", "LeaderMenu_Handler" );
	
	new iStatus = getStatus( id, g_iGang[ id ] );
	
	if( iStatus == STATUS_LEADER )
	{
		menu_additem( hMenu, "Disband clan", "0" );
		menu_additem( hMenu, "Transfer Leadership", "1" );
		menu_additem( hMenu, "Add An Admin", "3" );
		menu_additem( hMenu, "Remove An Admin", "4" );
		menu_additem( hMenu, "Change Tag", "5" );
		menu_additem( hMenu, "Kick Offline Member", "6" );
	}
	
	menu_additem( hMenu, "Kick Online Member", "2" );
	
	menu_display( id, hMenu, 0 );
}

public LeaderMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		Cmd_Gang( id );
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[ 6 ];
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	switch( str_to_num( szData ) )
	{
		case 0:
		{
			ShowDisbandConfirmMenu( id );
		}
		
		case 1:
		{
			ShowTransferMenu( id );
		}
		
		case 2:
		{
			ShowKickMenu( id );
		}
		case 3:
		{
			ShowAddAdminMenu( id );
		}
		
		case 4:
		{
			ShowRemoveAdminMenu( id );
		}			
		case 5:
		{
			client_cmd(id,"messagemode change_tag");
		}			
		case 6:
		{
			ShowOfflineKickMenu(id);
		}
	}
	
	return PLUGIN_HANDLED;
}

public ShowOfflineKickMenu(id)
{	
	new Array:aSQL;
	sqlv_read_all_ex( g_hVault, aSQL );
	
	new aVaultData[ SQLVaultEntryEx ];
		
	new aData[ GangInfo ]
	ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
	
	
	new menu=menu_create("Kick Offline Member", "OfflineHandler")
	
	for( new i = 0; i < ArraySize( aSQL ); i++ )
	{
		ArrayGetArray( aSQL, i, aVaultData );
		if(equal(aData[GangName],aVaultData[ SQLVEx_Key2 ] ))
		{
			menu_additem(menu,aVaultData[ SQLVEx_Key1 ],aVaultData[ SQLVEx_Key1 ])
		}
	}
	menu_display(id,menu)
}

public OfflineHandler(id,menu,item)
{
	
	if( item == MENU_EXIT )
	{
		Cmd_Gang( id );
		return PLUGIN_HANDLED;
	}
	
	new szAuthID[32]
	new access, callback; 
	menu_item_getinfo ( menu, item, access, szAuthID, 32, _, _, callback )
	new player=find_player("c",szAuthID)
	if(!player)
	{		
		new aData[ GangInfo ];
		
		if( g_iGang[ id ] > -1 )
		{
			ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
			TrieDeleteKey( aData[ GangMembers ], szAuthID);
			aData[ NumMembers ]--;
			ArraySetArray( g_aGangs, g_iGang[ id ], aData );		
			sqlv_remove_ex( g_hVault, szAuthID, aData[ GangName ] );
		}
		ColorChat(id,GREEN,"GC |^3 Player has been kicked!")
	}
	else
	{
		ColorChat(id,GREEN,"GC |^3 This player is connected! Kick him from the Online Kick Menu!")
	}
	return PLUGIN_HANDLED;
}
public Cmd_ChangeTag(id)
{
	new iStatus = getStatus( id, g_iGang[ id ] );
	
	if( iStatus == STATUS_LEADER )
	{
		new szArgs[ 10];
		read_args( szArgs, charsmax( szArgs ) );	
		remove_quotes( szArgs );
		new aData[ GangInfo ];
		ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
		aData[ GangTag ] = szArgs;
		ArraySetArray( g_aGangs, g_iGang[ id ], aData );
		
		ColorChat( id, NORMAL, "You have successfully changed the Clan Tag" );
	}
	else
	{
		
		ColorChat( id, NORMAL, "You have failed to change the Clan Tag" );
	}
	
	
	return PLUGIN_HANDLED
}

public ShowDisbandConfirmMenu( id )
{
	new hMenu = menu_create( "Are you sure you want to disband the clan?", "DisbandConfirmMenu_Handler" );
	menu_additem( hMenu, "Yes, Disband Now", "0" );
	menu_additem( hMenu, "No, Don't Disband", "1" );
	
	menu_display( id, hMenu, 0 );
}

public DisbandConfirmMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szData[ 6 ], iAccess, hCallback;
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	switch( str_to_num( szData ) )
	{
		case 0: 
		{
			
			ColorChat( id, NORMAL, "%s You have successfully disbanded your clan.", g_szPrefix );
			
			new iPlayers[ 32 ], iNum;
			
			get_players( iPlayers, iNum );
			
			new iPlayer;
			
			for( new i = 0; i < iNum; i++ )
			{
				iPlayer = iPlayers[ i ];
				
				if( iPlayer == id )
					continue;
				
				if( g_iGang[ id ] != g_iGang[ iPlayer ] )
					continue;

				ColorChat( iPlayer, NORMAL, "%s Your clan has been disband by its leader.", g_szPrefix );
				set_user_gang( iPlayer, -1 );
			}
			
			new iGang = g_iGang[ id ];
			
			set_user_gang( id, -1 );
			
			ArrayDeleteItem( g_aGangs, iGang );

			Cmd_Gang( id );
		}
		
		case 1: Cmd_Gang( id );
	}
	
	return PLUGIN_HANDLED;
}

public ShowTransferMenu( id )
{
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum);
	
	new hMenu = menu_create( "Transfer Leadership to:", "TransferMenu_Handler" );
	new szName[ 32 ], szData[ 6 ];
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ iPlayer ] != g_iGang[ id ] || id == iPlayer )
			continue;
			
		get_user_name( iPlayer, szName, charsmax( szName ) );
		num_to_str( iPlayer, szData, charsmax( szData ) );
		
		menu_additem( hMenu, szName, szData );
	}
	
	menu_display( id, hMenu, 0 );
}

public TransferMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		ShowLeaderMenu( id );
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[ 6 ], szName[ 32 ];
	
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, szName, charsmax( szName ), hCallback );
	
	new iPlayer = str_to_num( szData );
	
	if( !is_user_connected( iPlayer ) )
	{
		ColorChat( id, NORMAL, "%s That player is no longer connected.", g_szPrefix );
		ShowTransferMenu( id );
		return PLUGIN_HANDLED;
	}
	
	set_user_gang( iPlayer, g_iGang[ id ], STATUS_LEADER );
	set_user_gang( id, g_iGang[ id ], STATUS_ADMIN );
	
	Cmd_Gang( id );
	
	new iPlayers[ 32 ], iNum, iTemp;
	get_players( iPlayers, iNum );

	for( new i = 0; i < iNum; i++ )
	{
		iTemp = iPlayers[ i ];
		
		if( iTemp == iPlayer )
		{
			ColorChat( iTemp, NORMAL, "%s You are the new leader of your clan.", g_szPrefix );
			continue;
		}
		
		else if( g_iGang[ iTemp ] != g_iGang[ id ] )
			continue;
		
		ColorChat( iTemp, NORMAL, "%s ^03%s^01 is the new leader of your clan.", g_szPrefix, szName );
	}
	
	return PLUGIN_HANDLED;
}


public ShowKickMenu( id )
{
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	new hMenu = menu_create( "Kick Player From Clan:", "KickMenu_Handler" );
	new szName[ 32 ], szData[ 6 ];
	
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ iPlayer ] != g_iGang[ id ] || id == iPlayer )
			continue;
			
		
		if(getStatus(id, g_iGang[id])<=getStatus(i,g_iGang[i]))
			continue;
			
		get_user_name( iPlayer, szName, charsmax( szName ) );
		num_to_str( iPlayer, szData, charsmax( szData ) );
		
		menu_additem( hMenu, szName, szData );
	}
	
	menu_display( id, hMenu, 0 );
}

public KickMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		ShowLeaderMenu( id );
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[ 6 ], szName[ 32 ];
	
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, szName, charsmax( szName ), hCallback );
	
	new iPlayer = str_to_num( szData );
	
	if( !is_user_connected( iPlayer ) )
	{
		ColorChat( id, NORMAL, "%s That player is no longer connected.", g_szPrefix );
		ShowTransferMenu( id );
		return PLUGIN_HANDLED;
	}
	
	set_user_gang( iPlayer, -1 );
	
	Cmd_Gang( id );
	
	new iPlayers[ 32 ], iNum, iTemp;
	get_players( iPlayers, iNum );
	
	for( new i = 0; i < iNum; i++ )
	{
		iTemp = iPlayers[ i ];
		
		if( iTemp == iPlayer || g_iGang[ iTemp ] != g_iGang[ id ] )
			continue;
		
		ColorChat( iTemp, NORMAL, "%s ^03%s^01 has been kicked from the clan.", g_szPrefix, szName );
	}
	
	ColorChat( iPlayer, NORMAL, "%s You have been kicked from your clan.", g_szPrefix, szName );
	
	return PLUGIN_HANDLED;
}

public ChangeName_Handler( id )
{
	if( g_iGang[ id ] == -1 || getStatus( id, g_iGang[ id ] ) == STATUS_MEMBER )
	{
		return;
	}
	
	new iGang = g_iGang[ id ];
	
	new szArgs[ 64 ];
	read_args( szArgs, charsmax( szArgs ) );
	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	new bool:bInGang[ 33 ];
	new iStatus[ 33 ];
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ id ] != g_iGang[ iPlayer ] )
			continue;
	
		bInGang[ iPlayer ] = true;
		iStatus[ iPlayer ] = getStatus( id, iGang );
		
		set_user_gang( iPlayer, -1 );
	}
	
	new aData[ GangInfo ];
	ArrayGetArray( g_aGangs, iGang, aData );
	
	aData[ GangName ] = szArgs;
	
	ArraySetArray( g_aGangs, iGang, aData );
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( !bInGang[ iPlayer ] )
			continue;
		
		set_user_gang( iPlayer, iGang, iStatus[ id ] );
	}
}
	
public ShowAddAdminMenu( id )
{
	new iPlayers[ 32 ], iNum;
	new szName[ 32 ], szData[ 6 ];
	new hMenu = menu_create( "Choose a Player to Promote:", "AddAdminMenu_Handler" );
	
	get_players( iPlayers, iNum );
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ id ] != g_iGang[ iPlayer ] || getStatus( iPlayer, g_iGang[ iPlayer ] ) > STATUS_MEMBER )
			continue;
		
		get_user_name( iPlayer, szName, charsmax( szName ) );
		
		num_to_str( iPlayer, szData, charsmax( szData ) );
		
		menu_additem( hMenu, szName, szData );
	}
	
	menu_display( id, hMenu, 0 );
}

public AddAdminMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( hMenu );
		ShowLeaderMenu( id );
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[ 6 ], szName[ 32 ];
	
	menu_item_getinfo( hMenu, iItem, iAccess, szData, charsmax( szData ), szName, charsmax( szName ), hCallback );
	
	new iChosen = str_to_num( szData );
	
	if( !is_user_connected( iChosen ) )
	{
		menu_destroy( hMenu );
		ShowLeaderMenu( id );
		return PLUGIN_HANDLED;
	}
	
	set_user_gang( iChosen, g_iGang[ id ], STATUS_ADMIN );
	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ iPlayer ] != g_iGang[ id ] || iPlayer == iChosen )
			continue;
		
		ColorChat( iPlayer, NORMAL, "%s ^03%s ^01has been promoted to an admin of your clan.", g_szPrefix, szName );
	}
	
	ColorChat( iChosen, NORMAL, "%s ^01You have been promoted to an admin of your clan.", g_szPrefix );
	
	menu_destroy( hMenu );
	return PLUGIN_HANDLED;
}

public ShowRemoveAdminMenu( id )
{
	new iPlayers[ 32 ], iNum;
	new szName[ 32 ], szData[ 6 ];
	new hMenu = menu_create( "Choose a Player to Demote:", "RemoveAdminMenu_Handler" );
	
	get_players( iPlayers, iNum );
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ id ] != g_iGang[ iPlayer ] || getStatus( iPlayer, g_iGang[ iPlayer ] ) != STATUS_ADMIN )
			continue;
		
		get_user_name( iPlayer, szName, charsmax( szName ) );
		
		num_to_str( iPlayer, szData, charsmax( szData ) );
		
		menu_additem( hMenu, szName, szData );
	}
	
	menu_display( id, hMenu, 0 );
}

public RemoveAdminMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( hMenu );
		ShowLeaderMenu( id );
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[ 6 ], szName[ 32 ];
	
	menu_item_getinfo( hMenu, iItem, iAccess, szData, charsmax( szData ), szName, charsmax( szName ), hCallback );
	
	new iChosen = str_to_num( szData );
	
	if( !is_user_connected( iChosen ) )
	{
		menu_destroy( hMenu );
		ShowLeaderMenu( id );
		return PLUGIN_HANDLED;
	}
	
	set_user_gang( iChosen, g_iGang[ id ], STATUS_MEMBER );
	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ iPlayer ] != g_iGang[ id ] || iPlayer == iChosen )
			continue;
		
		ColorChat( iPlayer, NORMAL, "%s ^03%s ^01has been demoted from being an admin of your clan.", g_szPrefix, szName );
	}
	
	ColorChat( iChosen, NORMAL, "%s ^01You have been demoted from being an admin of your clan.", g_szPrefix );
	
	menu_destroy( hMenu );
	return PLUGIN_HANDLED;
}
	
public ShowMembersMenu( id )
{
	new szName[ 64 ], iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	new hMenu = menu_create( "Online Members:", "MemberMenu_Handler" );
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ id ] != g_iGang[ iPlayer ] )
			continue;
		
		get_user_name( iPlayer, szName, charsmax( szName ) );
		
		switch( getStatus( iPlayer, g_iGang[ id ] ) )
		{
			case STATUS_MEMBER:
			{
				add( szName, charsmax( szName ), " \r[Member]" );
			}
			
			case STATUS_ADMIN:
			{
				add( szName, charsmax( szName ), " \r[Admin]" );
			}
			
			case STATUS_LEADER:
			{
				add( szName, charsmax( szName ), " \r[Leader]" );
			}
		}

		menu_additem( hMenu, szName );
	}
	
	menu_display( id, hMenu, 0 );
}

public MemberMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( hMenu );
		Cmd_Gang( id );
		return PLUGIN_HANDLED;
	}
	
	menu_destroy( hMenu );
	
	ShowMembersMenu( id )
	return PLUGIN_HANDLED;
}

// Credits to Tirant from zombie mod and xOR from xRedirect
public LoadGangs()
{
	new szConfigsDir[ 60 ];
	get_configsdir( szConfigsDir, charsmax( szConfigsDir ) );
	add( szConfigsDir, charsmax( szConfigsDir ), "/jb_gangs.ini" );
	
	new iFile = fopen( szConfigsDir, "rt" );
	
	new aData[ GangInfo ];
	
	new szBuffer[ 512 ], szData[ 6 ], szValue[ 6 ], i, iCurGang;
	
	while( !feof( iFile ) )
	{
		fgets( iFile, szBuffer, charsmax( szBuffer ) );
		
		trim( szBuffer );
		remove_quotes( szBuffer );
		
		if( !szBuffer[ 0 ] || szBuffer[ 0 ] == ';' ) 
		{
			continue;
		}
		
		if( szBuffer[ 0 ] == '[' && szBuffer[ strlen( szBuffer ) - 1 ] == ']' )
		{
			copy( aData[ GangName ], strlen( szBuffer ) - 2, szBuffer[ 1 ] );
			aData[ GangKills ] = 0;
			aData[ GangInfections ] = 0;
			aData[ GangTag] = "";
			aData[ NumMembers ] = 0;
			aData[ GangMembers ] = _:TrieCreate();
			
			if( TrieKeyExists( g_tGangNames, aData[ GangName ] ) )
			{
				new szError[ 256 ];
				formatex( szError, charsmax( szError ), "GC | Clan already exists: %s", aData[ GangName ] );
				set_fail_state( szError );
			}
			
			ArrayPushArray( g_aGangs, aData );
			
			TrieSetCell( g_tGangNames, aData[ GangName ], iCurGang );

			//log_amx( "Clan Created: %s", aData[ GangName ] );
			
			iCurGang++;
			
			continue;
		}
		
		strtok( szBuffer, szData, 31, szValue, 511, '=' );
		trim( szData );
		trim( szValue );
		
		if( TrieGetCell( g_tGangValues, szData, i ) )
		{
			ArrayGetArray( g_aGangs, iCurGang - 1, aData );
			
			switch( i )
			{									
				case VALUE_KILLS:
					aData[ GangKills ] = str_to_num( szValue );
					
				case VALUE_INFECTIONS:
					aData[ GangInfections ] = str_to_num( szValue );	
					
				case VALUE_TAG:
					copy(aData[GangTag], sizeof(szValue),szValue)
					
			}
			
			ArraySetArray( g_aGangs, iCurGang - 1, aData );
		}
	}
	
	new Array:aSQL;
	sqlv_read_all_ex( g_hVault, aSQL );
	
	new aVaultData[ SQLVaultEntryEx ];
	
	new iGang;
	
	for( i = 0; i < ArraySize( aSQL ); i++ )
	{
		ArrayGetArray( aSQL, i, aVaultData );
		
		if( TrieGetCell( g_tGangNames, aVaultData[ SQLVEx_Key2 ], iGang ) )
		{
			ArrayGetArray( g_aGangs, iGang, aData );
			
			TrieSetCell( aData[ GangMembers ], aVaultData[ SQLVEx_Key1 ], str_to_num( aVaultData[ SQLVEx_Data ] ) );
			
			aData[ NumMembers ]++;
			
			ArraySetArray( g_aGangs, iGang, aData );
		}
	}
	
	fclose( iFile );
}

public SaveGangs()
{
	new szConfigsDir[ 64 ];
	get_configsdir( szConfigsDir, charsmax( szConfigsDir ) );
	
	add( szConfigsDir, charsmax( szConfigsDir ), "/jb_gangs.ini" );
	
	if( file_exists( szConfigsDir ) )
		delete_file( szConfigsDir );
		
	new iFile = fopen( szConfigsDir, "wt" );
		
	new aData[ GangInfo ];
	
	new szBuffer[ 256 ];

	for( new i = 0; i < ArraySize( g_aGangs ); i++ )
	{
		ArrayGetArray( g_aGangs, i, aData );
		
		formatex( szBuffer, charsmax( szBuffer ), "[%s]^n", aData[ GangName ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "Kills=%i^n^n", aData[ GangKills ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "Infections=%i^n^n", aData[ GangInfections ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "Tag=%s^n^n", aData[ GangTag ] );
		fputs( iFile, szBuffer );
	}
	
	fclose( iFile );
}
	
	

set_user_gang( id, iGang, iStatus=STATUS_MEMBER )
{
	new szAuthID[ 35 ];
	get_user_authid( id, szAuthID, charsmax( szAuthID ) );

	new aData[ GangInfo ];
	
	if( g_iGang[ id ] > -1 )
	{
		ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
		TrieDeleteKey( aData[ GangMembers ], szAuthID );
		aData[ NumMembers ]--;
		ArraySetArray( g_aGangs, g_iGang[ id ], aData );
		
		sqlv_remove_ex( g_hVault, szAuthID, aData[ GangName ] );
	}

	if( iGang > -1 )
	{
		ArrayGetArray( g_aGangs, iGang, aData );
		TrieSetCell( aData[ GangMembers ], szAuthID, iStatus );
		aData[ NumMembers ]++;
		ArraySetArray( g_aGangs, iGang, aData );		
		sqlv_set_num_ex( g_hVault, szAuthID, aData[ GangName ], iStatus );		
	}

	g_iGang[ id ] = iGang;
	
	return 1;
}
	
get_user_gang( id )
{
	new szAuthID[ 35 ];
	get_user_authid( id, szAuthID, charsmax( szAuthID ) );
	
	new aData[ GangInfo ];
	
	for( new i = 0; i < ArraySize( g_aGangs ); i++ )
	{
		ArrayGetArray( g_aGangs, i, aData );
		
		if( TrieKeyExists( aData[ GangMembers ], szAuthID ) )
			return i;
	}
	
	return -1;
}
	
getStatus( id, iGang )
{
	if( !is_user_connected( id ) || iGang == -1 )
		return STATUS_NONE;
		
	new aData[ GangInfo ];
	ArrayGetArray( g_aGangs, iGang, aData );
	
	new szAuthID[ 35 ];
	get_user_authid( id, szAuthID, charsmax( szAuthID ) );
	
	new iStatus;
	TrieGetCell( aData[ GangMembers ], szAuthID, iStatus );
	return iStatus;
}
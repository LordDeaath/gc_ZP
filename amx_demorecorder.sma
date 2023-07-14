/****************************************/
/*					*/
/*	Auto Demo Recorder		*/
/*	by IzI				*/
/*					*/
/****************************************/

#include <amxmodx>
#include <colorchat>
#pragma semicolon 1

new g_Toggle, g_DMod, g_UseNI, g_RStartAfter, g_DemoName, g_DemoNamePrefix, iFinalTxt[148];

public plugin_init() { 
	register_plugin( "Auto Demo Recorder", "1.5", "IzI" );
	g_Toggle 		= register_cvar( "amx_demo",		"1" );
	g_DMod			= register_cvar( "amx_demo_mode",	"0" );
	g_UseNI 		= register_cvar( "amx_demo_steamid",	"0" );
	g_RStartAfter 		= register_cvar( "amx_demo_rectime",	"15" );	// If it is less than 5, it will automatically set to 5, but willn't apply the changes to the console. I recoment to use default settings.
	g_DemoName 		= register_cvar( "amx_demo_name",	"Autorecorded demo" );
	g_DemoNamePrefix	= register_cvar( "amx_demo_prefix",	"AMXX" );
	register_dictionary( "demorecorder.txt" );
	register_clcmd("say /r", "recordDemo");
	register_clcmd("say /s", "stopDemo");
}

public client_putinserver( id ) {
	if( get_pcvar_num( g_Toggle ) ) {
		new Float:delay = get_pcvar_float( g_RStartAfter );
		if( delay < 5 )
			set_pcvar_float( g_RStartAfter, ( delay = 5.0 ) );
		set_task( delay, "Record", id );
	}
}

public Record( id ) {
	if( !is_user_connected( id ) || get_pcvar_num( g_Toggle ) != 1 )
		return;

	// Getting time, client SteamID, server's name, server's ip with port.
	new szSName[128], szINamePrefix[64], szTimedata[9], iMap[32];
	new iUseIN = get_pcvar_num( g_UseNI );
	new iDMod = get_pcvar_num( g_DMod );
	get_pcvar_string( g_DemoNamePrefix, szINamePrefix, 63 );
	get_time ( "%H:%M:%S", szTimedata, 8 );
	get_mapname(iMap,charsmax(iMap));
	
	switch( iDMod ) {
		case 0: get_pcvar_string( g_DemoName, szSName, 127 );
		case 1: get_user_ip( 0, szSName, 127, 0 );
		case 2: get_user_name( 0, szSName, 127 );
	}

	if( iUseIN ) {
		new szCID[32];
		get_user_authid( id, szCID, 31 );
		format( szSName, 127, "[%s]%s", szCID, szSName );
	}
	// Replacing signs.
	replace_all( szSName, 127, ":", "_" );
	replace_all( szSName, 127, ".", "_" );
	replace_all( szSName, 127, "*", "_" );
	replace_all( szSName, 127, "/", "_" );
	replace_all( szSName, 127, "|", "_" );
	replace_all( szSName, 127, "\", "_" );
	replace_all( szSName, 127, "?", "_" );
	replace_all( szSName, 127, ">", "_" );
	replace_all( szSName, 127, "<", "_" );
	replace_all( szSName, 127, " ", "_" );

	// Displaying messages.
	client_cmd( id, "stop; record ^"%s^"", szSName );
	ColorChat(id, GREEN, "[GC]^3 Demo^4 %s ^3started recording.", szSName);
}
public recordDemo(id)
{
	new iDate[32],iMap[32];
	get_time("%d%m%Y_%H;%M",iDate,charsmax(iDate));
	get_mapname(iMap,charsmax(iMap));
	client_cmd(id, "stop");
	formatex(iFinalTxt,charsmax(iFinalTxt),"gc_%s_%s",iMap,iDate);
	client_cmd(id, "record %s",iFinalTxt);
	ColorChat(id,GREEN, "[GC]^3 Demo^4 %s ^3started recording.", iFinalTxt);
	return PLUGIN_HANDLED;
}

public stopDemo(id)
{
	client_cmd(id, "stop");
	ColorChat(id, GREEN,"[GC]^3 Demo^4 %s ^3finished recording.", iFinalTxt);
	return PLUGIN_HANDLED;
}
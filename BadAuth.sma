/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Bad AuthID"
#define VERSION "1.0"
#define AUTHOR "zXCaptainXz"

new UserAuthID[32], UserName[32]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)	
}

public client_authorized(id)
{
	get_user_authid(id, UserAuthID,charsmax(UserAuthID))
	/*if(equal(UserAuthID,"HLTV"))
	{
		new ip[32]
		get_user_ip(id, ip, charsmax(ip),1)
		if(equal(ip,"149.56.117.253"))
			return;
			
		get_user_name(id,UserName, charsmax(UserName))
		log_to_file("BadAuthID","%s kicked for bad AuthID [HLTV]", UserName)	
		server_cmd("kick #%d ^"Bad AuthID^" ",get_user_userid(id), UserName)
		return;
	}	*/
	if(contain(UserAuthID,"VALVE_0:4:")!=-1)
	{
		get_user_name(id,UserName, charsmax(UserName))
		log_to_file("BadAuthID","%s kicked for bad AuthID [P47]", UserName)	
		server_cmd("kick #%d ^"Bad AuthID^" ",get_user_userid(id), UserName)
		return;
	}
	if(equal(UserAuthID,"STEAM_ID_LAN"))
	{
		get_user_name(id,UserName, charsmax(UserName))
		log_to_file("BadAuthID","%s kicked for bad AuthID [STEAM_ID_LAN]", UserName)	
		server_cmd("kick #%d ^"Bad AuthID^" ",get_user_userid(id), UserName)
		return;
	}
	if(equal(UserAuthID,"STEAM_ID_PENDING"))
	{
		get_user_name(id,UserName, charsmax(UserName))
		log_to_file("BadAuthID","%s kicked for bad AuthID [STEAM_ID_PENDING]", UserName)	
		server_cmd("kick #%d ^"Bad AuthID^" ",get_user_userid(id), UserName)
		return;
	}
	if(equal(UserAuthID,"VALVE_ID_PENDING"))
	{
		get_user_name(id,UserName, charsmax(UserName))
		log_to_file("BadAuthID","%s kicked for bad AuthID [VALVE_ID_PENDING]", UserName)	
		server_cmd("kick #%d ^"Bad AuthID^" ",get_user_userid(id), UserName)
		return;
	}	
} 

public client_putinserver(id)
{
	new authid[32]
	get_user_authid(id, authid, charsmax(authid))
	if(equal(authid,"STEAM_ID_PENDING"))
	{
		get_user_name(id,UserName, charsmax(UserName))
		log_to_file("BadAuthID","%s kicked for bad AuthID [STEAM_ID_PENDING]", UserName)	
		server_cmd("kick #%d ^"Bad AuthID^" ",get_user_userid(id), UserName)
	}
}

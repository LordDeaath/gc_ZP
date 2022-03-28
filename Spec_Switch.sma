/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <zp50_core>
#include <zp50_gamemodes>
#include <Colorchat>
#include <hamsandwich>

native zp_force_respawn(id);
native zp_respawn_task_remove(id);

#define PLUGIN "Spec Switch"
#define VERSION "0.1.3"
#define AUTHOR "many"

//new CsTeams:zTeam[33]
new zDeath[33]
//new bool:type_spec[33] = false
new g_cvar
//new gUsed[33]

new g_msgid_ClCorpse

new Trie:SpecTime;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	/* Cvar */
	g_cvar	= register_cvar("amx_specmode",	"0") 	// 0 - enable use to all, 1 - enable use only ADMINs
	
	/* Client Commands */
	register_clcmd("say /spec", 		"cmdSpec", ADMIN_ALL, "- go to spectator")
	register_clcmd("say_team /spec", 	"cmdSpec", ADMIN_ALL, "- go to spectator")
	register_clcmd("say /back", 		"cmdBack", ADMIN_ALL, "- go back to your team")
	register_clcmd("say_team /back", 	"cmdBack", ADMIN_ALL, "- go back to your team")
	
	g_msgid_ClCorpse = get_user_msgid("ClCorpse")
	SpecTime = TrieCreate()
}

public plugin_end()
{
	TrieDestroy(SpecTime)
}


public plugin_natives()
{
	register_native("zp_transfer_spec","native_transfer_spec",1)
	register_native("zp_spec","cmdSpec",1)
	register_native("zp_back","cmdBack",1)
	register_native("zp_cant_respawn","native_cant_respawn",1)
}

public Float:native_cant_respawn(id)
{
	if(get_user_flags(id)&ADMIN_KICK)
		return 0.0;
	
	new authid[32]
	get_user_authid(id, authid, charsmax(authid))
	if(!TrieKeyExists(SpecTime,authid))
	{
		return 0.0;
	}

	new Float:spectime;
	TrieGetCell(SpecTime, authid, spectime)
	if(get_gametime()-spectime>60.0)
	{
		TrieDeleteKey(SpecTime, authid)
		return 0.0;
	}
	ColorChat(id, GREEN, "[GC]^1 You went to^3 Spectator^1 while being^3 Alive!")
	ColorChat(id, GREEN, "[GC]^1 You will be^3 Respawned^1 in^3 %.0f Seconds!",60.0-get_gametime()+spectime)
	return 60.0-get_gametime()+spectime;
}
public native_transfer_spec(id)
{	
	return Spec(id);
}

public cmdSpec(id)
{
	if(!SpecAllowed(id))
	{
		ColorChat(id, GREEN, "[GC]^3 You are not allowed to use^4 /spec^3 right now!")
		return PLUGIN_HANDLED;
	}
	
	if (cs_get_user_team(id) == CS_TEAM_SPECTATOR)
	return PLUGIN_HANDLED;
	
	if(!get_pcvar_num(g_cvar)) Spec(id)
	else if( get_pcvar_num(g_cvar) && (get_user_flags(id) & ADMIN_KICK)) Spec(id)
	else if( get_pcvar_num(g_cvar) && !(get_user_flags(id) & ADMIN_KICK)) PrintUserNotAdmin(id)
	return PLUGIN_HANDLED;
}

public cmdBack(id)
{
	if (/*type_spec[id] &&*/ cs_get_user_team(id) == CS_TEAM_SPECTATOR || cs_get_user_team(id) == CS_TEAM_UNASSIGNED) Back(id)
	else if( get_pcvar_num(g_cvar) && !(get_user_flags(id) & ADMIN_KICK) ) PrintUserNotAdmin(id)
	return PLUGIN_HANDLED;
}
/*
public zp_fw_gamemodes_end()
{
	new iPlayer
	for (iPlayer = 1; iPlayer <= 32; iPlayer++)
	{
		if(is_user_connected(iPlayer))
			gUsed[iPlayer] = 0
	}	
}*/
public Spec(id)
{	
	if(get_user_flags(id) & ADMIN_KICK)
	{
		zDeath[id] = cs_get_user_deaths(id)
		//type_spec[id] = true
		//zTeam[id] = cs_get_user_team(id)
		set_msg_block(g_msgid_ClCorpse, BLOCK_ONCE)
		cs_set_user_team(id, CS_TEAM_SPECTATOR)
		user_silentkill(id)
		zp_respawn_task_remove(id)
		ColorChat(id,GREEN,"[GC]^03 Type ^04/back^03 to return from Spectator")
		return true;
	}
	
	if(is_user_alive(id))
	{		
		new authid[32]
		get_user_authid(id,authid,charsmax(authid))
		TrieSetCell(SpecTime, authid, get_gametime())
	}

	zDeath[id] = cs_get_user_deaths(id)
	cs_set_user_team(id, CS_TEAM_SPECTATOR)
	user_kill(id)
	zp_respawn_task_remove(id)
	ColorChat(id,GREEN,"[GC]^03 Type ^04/back^03 to return from Spectator")
	
	return true;
	/*
	if(gUsed[id] == 0)
	{
		zDeath[id] = cs_get_user_deaths(id)
		//type_spec[id] = true
		//zTeam[id] = cs_get_user_team(id)
		cs_set_user_team(id, CS_TEAM_SPECTATOR)
		user_kill(id)
		ColorChat(id,GREEN,"[GC]^03 Type ^04/back^03 to return from Spectator")
		gUsed[id]++
		return 1;
	}
	
	ColorChat(id, GREEN, "[GC]^03 You can't go to spectate now!")
	return 0;*/
}

public zp_fw_gamemodes_end()
{
	TrieClear(SpecTime);
}

public Back(id)
{	
	zp_force_respawn(id)
	set_pdata_int(id, 125, get_pdata_int(id, 125, 5) &  ~(1<<8), 5)
	set_msg_block(get_user_msgid("VGUIMenu"),BLOCK_SET)
	engclient_cmd(id, "jointeam", "5")	
	engclient_cmd(id, "joinclass","5")	
	set_msg_block(get_user_msgid("VGUIMenu"),BLOCK_NOT)	
	/*
	new gMode = zp_gamemodes_get_current()
	if(gMode == g_NormalID || gMode == g_MultiInfectionID)
	{
		if(zp_core_get_human_count() > 1)
		{			
			cs_set_user_team(id, CS_TEAM_T)
			cs_set_user_deaths(id, zDeath[id])
			zp_core_respawn_as_zombie(id, true)
			ExecuteHamB(Ham_CS_RoundRespawn, id)			
			give_item(id, "weapon_knife")
		}
		else
		{			
			if(random(2))
			cs_set_user_team(id, CS_TEAM_T)
			else
			cs_set_user_team(id, CS_TEAM_CT)
			
			cs_set_user_deaths(id, zDeath[id])
		}
	}
	else
	if(gMode == g_RaceID || gMode == g_AlienID)
	{		
		cs_set_user_team(id, CS_TEAM_CT)
		cs_set_user_deaths(id, zDeath[id])
		zp_core_respawn_as_zombie(id, false)
		ExecuteHamB(Ham_CS_RoundRespawn, id)			
		give_item(id, "weapon_knife")
	}
	else
	if(gMode == ZP_NO_GAME_MODE)
	{			
		if(random(2))
		cs_set_user_team(id, CS_TEAM_T)
		else
		cs_set_user_team(id, CS_TEAM_CT)
		
		cs_set_user_deaths(id, zDeath[id])
		ExecuteHamB(Ham_CS_RoundRespawn, id)			
		give_item(id, "weapon_knife")
	}
	else
	{		
		if(random(2))
		cs_set_user_team(id, CS_TEAM_T)
		else
		cs_set_user_team(id, CS_TEAM_CT)
		
		cs_set_user_deaths(id, zDeath[id])
	}*/
	
}

/*public FirstRespawn(id)
{
	cs_user_spawn(id)
}

public SecondRespawn(id)
{
	cs_user_spawn(id)
	give_item(id, "weapon_knife")
	zp_core_force_infect(id)
}*/

PrintUserNotAdmin(id)
{
	client_print(id,print_chat,"Only Admins can use /spec, /back command")
}
/*
public PrintRule(id)
{
	if ( is_user_connected(id) && !is_user_bot(id) && !is_user_hltv(id) ){
		client_print(id,print_chat,"Type /spec if you want to go Spectator")
		client_print(id,print_chat,"Type /back to return from Spectator")
	}
}*/
/*
public client_putinserver(id)
{
	if(!get_pcvar_num(g_cvar)) Rule(id)
	else if( get_pcvar_num(g_cvar) && (get_user_flags(id) & ADMIN_KICK)) Rule(id)
}

//public client_disconnect(id) type_spec[id] = false
//public client_connect(id) type_spec[id] = false
public Rule(id) set_task(20.0, "PrintRule", id)*/

bool:SpecAllowed(id)
{
	if(!is_user_alive(id))
		return true;
		
	new CsTeams:team;
	team = cs_get_user_team(id)
	for(new i = 1;i < 33;i++)
	{
		if(i==id) continue;
		if(!is_user_alive(i)) continue;
		if(cs_get_user_team(i)==team) return true;
	}
	return false;
}
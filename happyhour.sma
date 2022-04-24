#include <amxmodx>
#include <hamsandwich>
#include <zombieplague>
#include <zp50_colorchat>
new bool:g_happyhour
new cvar_on,cvar_multi,g_packs[33],message[80]

// Uncomment this line if you use the zombie plague 4.2 or an older
//#define ZP_42_OR_OLDER
//new g_SyncHud;
public plugin_init() 
{
	register_plugin("Happy hour", "1.0", "capostrike")
	
	cvar_on = register_cvar("zp_happyhour", "1")
	cvar_multi = register_cvar("zp_happymultipler", "2")
	
	register_clcmd("say /hh","cmd_sayhh",0,"- Displays happy hour times");
	register_clcmd("say /happyhours","cmd_sayhh",0,"- Displays happy hour times");
	register_clcmd("say_team /hh","cmd_sayhh",0,"- Displays happy hour times");
	register_clcmd("say_team /happyhours","cmd_sayhh",0,"- Displays happy hour times");
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_post",1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_post", 1)
	//g_SyncHud=CreateHudSyncObj();
	set_task(900.00, "loop_ad", 0, "", 0, "b", 0);
}

public loop_ad()
{
	new szActive[4]
	if(g_happyhour)
	szActive="ON"
	else
	szActive="OFF"
}


public cmd_sayhh(id)
{	
	new szActive[4]
	if(g_happyhour)
	szActive="ON"
	else
	szActive="OFF"
	
	zp_colored_print(id,"^3Double AP^1 is currently^3 %s^1! Start:^3 2:00^1 | End:^3 6:00^1",szActive)
	return PLUGIN_HANDLED;
}

public plugin_cfg()
{
	if(get_pcvar_num(cvar_on))
	{
		new data[3]
		get_time("%H", data, 2)
		if(str_to_num(data) < 6 && str_to_num (data) >= 2)
		{
			g_happyhour = true
			formatex(message, charsmax(message), "[Happy Hour ON] Start: 2 o'clock - End: 6 o'clock")
		}  
		else
		{
			formatex(message, charsmax(message), "[Happy Hour OFF] Next Start: 2 o'clock - End: 6 o'clock")
		}
	}
}
public zp_fw_gamemodes_start()
{
	if(get_pcvar_num(cvar_on))
	{
		new data[3]
		get_time("%H", data, 2)
		new bool:iTemp=g_happyhour;
		if( str_to_num(data) >= 2&&str_to_num(data)<6)
		{
			g_happyhour = true
			formatex(message, charsmax(message), "^3[Happy Hour ON]^1 Start: 2 o'clock - End: 6 o'clock")
		}  
		else
		{
			g_happyhour = false
			formatex(message, charsmax(message), "^3[Happy Hour OFF]^1 Next Start: 2 o'clock - End: 6 o'clock")
		}
		if(iTemp!=g_happyhour)
		{
			zp_colored_print(0, message);
		}
	}
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(!g_happyhour) return HAM_IGNORED;
	if(victim == attacker || !is_user_alive(attacker)) return HAM_IGNORED;
	#if !defined ZP_42_OR_OLDER
	if(!zp_get_user_zombie(victim) || zp_get_user_zombie(attacker)) return HAM_IGNORED;
	#endif
	
	g_packs[attacker] = zp_get_user_ammo_packs(attacker)
	
	return HAM_IGNORED;
}
public fw_TakeDamage_post(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(!g_happyhour) return HAM_IGNORED;
	if(victim == attacker || !is_user_alive(attacker)) return HAM_IGNORED;
	#if !defined ZP_42_OR_OLDER
	if(!zp_get_user_zombie(victim) || zp_get_user_zombie(attacker)) return HAM_IGNORED;
	#endif
	if(!g_packs[attacker])  return HAM_IGNORED;
	
	new diff = (zp_get_user_ammo_packs(attacker) - g_packs[attacker]);
	
	if(diff)
	{
		diff *= get_pcvar_num(cvar_multi);
		zp_set_user_ammo_packs(attacker, g_packs[attacker]+diff)
		g_packs[attacker] = 0;
	}
	
	return HAM_IGNORED;
}
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if(!g_happyhour) return HAM_IGNORED;
	if(victim == attacker || !is_user_alive(attacker)) return HAM_IGNORED;
	
	g_packs[attacker] = zp_get_user_ammo_packs(attacker)
	
	return HAM_IGNORED;
}
public fw_PlayerKilled_post(victim, attacker, shouldgib)
{
	if(!g_happyhour) return HAM_IGNORED;
	if(victim == attacker || !is_user_alive(attacker)) return HAM_IGNORED;
	if(!g_packs[attacker])  return HAM_IGNORED;
	
	new diff = (zp_get_user_ammo_packs(attacker) - g_packs[attacker]);
	
	if(diff)
	{
		diff *= get_pcvar_num(cvar_multi);
		zp_set_user_ammo_packs(attacker, g_packs[attacker]+diff)
		g_packs[attacker] = 0;
	}
	
	return HAM_IGNORED;
}
#if !defined ZP_42_OR_OLDER
public zp_user_infected_pre(victim,attacker)
{
	if(!g_happyhour) return HAM_IGNORED;
	if(victim == attacker || !is_user_alive(attacker)) return HAM_IGNORED;
	
	g_packs[attacker] = zp_get_user_ammo_packs(attacker)
	
	return HAM_IGNORED;
}
public zp_user_infected_post(victim,attacker)
{
	if(!g_happyhour) return HAM_IGNORED;
	if(victim == attacker || !is_user_alive(attacker)) return HAM_IGNORED;
	if(!g_packs[attacker])  return HAM_IGNORED;
	
	new diff = (zp_get_user_ammo_packs(attacker) - g_packs[attacker]);
	
	if(diff)
	{
		diff *= get_pcvar_num(cvar_multi);
		zp_set_user_ammo_packs(attacker, g_packs[attacker]+diff)
		g_packs[attacker] = 0;
	}
	
	return HAM_IGNORED;
}
#endif
/*
public client_putinserver(id)
{
    set_task(8.00, "mode_hud", id, "", 0, "b", 0);
    return 0;
}*/

public client_disconnected(id)
{
	remove_task(id)
}
/*
public mode_hud(id)
{
	if (!get_pcvar_num(cvar_on)||!g_happyhour)
	{
		return;
	}
	set_hudmessage(0, 255, 0, -1.00, 0.20, 0, 8.00, 8.00, 0.00, 0.00);
	ShowSyncHudMsg(id, g_SyncHud, "%s",message);
}*/

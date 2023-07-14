#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

// players view angles
new Float:g_fViewAngles[33][2], Float:g_fOldViewAngles[33][2],

// how long player is afk
Float:g_fAfkTime[33],

// last check time
Float:g_fLastCheck[33], idb[33];
public plugin_init()
{
	register_plugin("[NATIVE] User AFK status", "1.2", "beast")
	
	register_forward(FM_CmdStart, "fw_FM_CmdStart")
	
	register_clcmd("say", "HandleSay")
	register_clcmd("say_team", "HandleSay")
	register_clcmd("say /db","db")
}

public plugin_natives()
{
	register_library("user_afk_status")
	
	register_native("get_user_afktime", "native_get_user_afktime")
	register_native("set_user_afktime", "native_set_user_afktime")
}
public db(id)
{
	if(idb[id] == 1)
		idb[id] = 0
	else idb[id] = 1
}
public client_disconnect(id)
{
	g_fAfkTime[id] = 0.0
	g_fLastCheck[id] = 0.0
	
	for(new i = 0; i < 2; i++)
	{
		g_fOldViewAngles[id][i] = 0.0
		g_fViewAngles[id][i] = 0.0
	}
}


// core...
public fw_FM_CmdStart(id, handle)
{
	// ignoring dead players and bots
	if(is_user_bot(id) || !is_user_alive(id))
		return FMRES_IGNORED

	static buttons
	
	buttons = get_uc(handle, UC_Buttons)

	if(buttons)
	{
		NotAfk(id) // player is not afk
	}
	
	get_uc(handle, UC_ViewAngles, g_fViewAngles[id])		
		
		// checking if new view angles are the same as the old ones 
	if(g_fViewAngles[id][0] == g_fOldViewAngles[id][0]
	&& g_fViewAngles[id][1] == g_fOldViewAngles[id][1])
	{
		static Float:gametime
			
		gametime = get_gametime()

		// updating afk time
		g_fAfkTime[id] += gametime - g_fLastCheck[id]
			
			// updating last check time
		g_fLastCheck[id] = gametime
	}
		
	// new angles are not the same as the old ones
	else
	{

		for(new i = 0; i < 2; i++)
			g_fOldViewAngles[id][i] = g_fViewAngles[id][i]
	}
		
	return FMRES_IGNORED
}

// player said something
public HandleSay(id)
	NotAfk(id) // he's not afk

NotAfk(id)
{
	g_fAfkTime[id] = 0.0
	g_fLastCheck[id] = get_gametime()
}

/* get_user_afktime
   more info in user_afk_status.inc */
public Float:native_get_user_afktime(iPlugin, iParams)
{
	new id = get_param(1)

	if(!(1 <= id <= 32) || !is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", id)
		return 0.0
	}
	
	return g_fAfkTime[id]
}

/* set_user_afktime
   more info in user_afk_status.inc */
public native_set_user_afktime(iPlugin, iParams)
{       
	new id = get_param(1)
	
	if(!(1 <= id <= 32) || !is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", id)
		return
	}
	
	new Float:afkTime = get_param_f(2)

	if(afkTime < 0.0)
	{
		log_error(AMX_ERR_NATIVE, "Invalid afkTime (%f)", afkTime)
		return
	}
	
	g_fAfkTime[id] = afkTime
}
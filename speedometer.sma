#include <amxmodx>
#include <fakemeta>
#include <zp50_fps>

#define PLUGIN "Speedometer"
#define VERSION "1.2"
#define AUTHOR "AciD"

#define FREQ 0.1

new bool:plrSpeed[33]

new TaskEnt,SyncHud, maxplayers;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("AcidoX", "Speedometer 1.1", FCVAR_SERVER)
	register_forward(FM_Think, "Think")
	
	register_forward(FM_CmdStart, "CmdStart")
	TaskEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))	
	set_pev(TaskEnt, pev_classname, "speedometer_think")
	set_pev(TaskEnt, pev_nextthink, get_gametime() + 1.01)
	
	register_clcmd("say /speed", "toogleSpeed")
	
	
	SyncHud = CreateHudSyncObj()
	
	maxplayers = get_maxplayers()
}


public CmdStart(id, uc_handle, seed)
{	
	if(!is_user_alive(id))
		return;
		
	//if(plrSpeed[id])
	//	return;

	// if( !(pev(id, pev_flags) & FL_ONGROUND))return;
	
	if( ( get_uc( uc_handle, UC_Buttons ) & IN_DUCK ) && !( pev( id, pev_oldbuttons ) & IN_DUCK ) ) 
	{
		check_speed(id);
		//set_task(0.1, "check_speed",id,_,_,"a",6);
	}	
}

public check_speed(id)
{		
	/*if(!is_user_alive(id))
		return;*/
		
	static Float:velocity[3]
	pev(id, pev_velocity, velocity)
	static Float:speed;
	speed=vector_length(velocity);
	
	if(speed>300.0&&speed<1000.0)
		set_hudmessage(floatround(51*(speed-300)/140),floatround(-51*(speed-1000)/140),0, -1.0, 0.7, 0, 0.0, FREQ, 0.01, 0.0)
	else	
	if(speed>=1000.0)
		set_hudmessage(255, 0,0 , -1.0, 0.7, 0, 0.0, FREQ, 0.01, 0.0)
	
	if(speed>300.0)
	{
		static Float:speedh
		speedh = floatsqroot(floatpower(velocity[0], 2.0) + floatpower(velocity[1], 2.0))
		
		static player, specmode
		for(player=1;player<33;player++)
		{
			if(!is_user_connected(player))
				continue;
		
			if(zp_fps_get_user_flags(player)&FPS_SPEEDOMETER)
				continue;
			
			if(plrSpeed[player])
				continue;

			if(is_user_alive(player))
			{
				if(player!=id)
					continue;
			}
			else
			{
				specmode = pev(player, pev_iuser1)
				if(specmode!=1&&specmode!=2&&specmode!=4)
					continue;
				
				if(pev(player, pev_iuser2)!=id)
					continue;
			}

			ShowSyncHudMsg(player, SyncHud, "%3.2f units/second^n%3.2f velocity", speed, speedh)
		}
		
	}
}


public Think(ent)
{
	if(ent == TaskEnt) 
	{
		SpeedTask()
		set_pev(ent, pev_nextthink,  get_gametime() + FREQ)
	}
}

public client_putinserver(id)
{
	plrSpeed[id] = false
}

public toogleSpeed(id)
{
	plrSpeed[id] = plrSpeed[id] ? false : true
	return PLUGIN_HANDLED
}

SpeedTask()
{
	static i, target, specmode
	static Float:velocity[3]
	static Float:speed, Float:speedh
	
	for(i=1; i<=maxplayers; i++)
	{
		if(!is_user_connected(i)) continue
		if(!plrSpeed[i]) continue
		
		if(is_user_alive(i))
		{
			target = i;
		}
		else
		{
			specmode = pev(i, pev_iuser1)
			if(specmode!=1&&specmode!=2&&specmode!=4)
				continue;

			target = pev(i, pev_iuser2)
		}

		pev(target, pev_velocity, velocity)

		speed = vector_length(velocity)
		speedh = floatsqroot(floatpower(velocity[0], 2.0) + floatpower(velocity[1], 2.0))
		
		if(speed<=300.0)
		{
			set_hudmessage(0, 255,0 , -1.0, 0.7, 0, 0.0, FREQ, 0.01, 0.0)
		}
		if(speed>300.0&&speed<1000.0)
			set_hudmessage(floatround(51*(speed-300)/140),floatround(-51*(speed-1000)/140),0, -1.0, 0.7, 0, 0.0, FREQ, 0.01, 0.0)
		else	
		if(speed>=1000.0)
			set_hudmessage(255, 0,0 , -1.0, 0.7, 0, 0.0, FREQ, 0.01, 0.0)
			
		ShowSyncHudMsg(i, SyncHud, "%3.2f units/second^n%3.2f velocity", speed, speedh)
	}
}

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <orpheu>

new stuck[33]

new cvar[3]

new const Float:size[][3] = {
	{0.0, 0.0, 1.0}, {0.0, 0.0, -1.0}, {0.0, 1.0, 0.0}, {0.0, -1.0, 0.0}, {1.0, 0.0, 0.0}, {-1.0, 0.0, 0.0}, {-1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {1.0, 1.0, -1.0}, {-1.0, -1.0, 1.0}, {1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0}, {-1.0, -1.0, -1.0},
	{0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0},
	{0.0, 0.0, 3.0}, {0.0, 0.0, -3.0}, {0.0, 3.0, 0.0}, {0.0, -3.0, 0.0}, {3.0, 0.0, 0.0}, {-3.0, 0.0, 0.0}, {-3.0, 3.0, 3.0}, {3.0, 3.0, 3.0}, {3.0, -3.0, 3.0}, {3.0, 3.0, -3.0}, {-3.0, -3.0, 3.0}, {3.0, -3.0, -3.0}, {-3.0, 3.0, -3.0}, {-3.0, -3.0, -3.0},
	{0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
	{0.0, 0.0, 5.0}, {0.0, 0.0, -5.0}, {0.0, 5.0, 0.0}, {0.0, -5.0, 0.0}, {5.0, 0.0, 0.0}, {-5.0, 0.0, 0.0}, {-5.0, 5.0, 5.0}, {5.0, 5.0, 5.0}, {5.0, -5.0, 5.0}, {5.0, 5.0, -5.0}, {-5.0, -5.0, 5.0}, {5.0, -5.0, -5.0}, {-5.0, 5.0, -5.0}, {-5.0, -5.0, -5.0}
}

public plugin_init() {
	register_plugin("Automatic Unstuck","1.5","NL)Ramon(NL")
	cvar[0] = register_cvar("amx_autounstuck","1")
	cvar[1] = register_cvar("amx_autounstuckeffects","0")
	cvar[2] = register_cvar("amx_autounstuckwait","1")
	if(LibraryExists("orpheu",LibType_Library))
		OrpheuRegisterHook(OrpheuGetFunction("PM_CheckStuck"),"OnPM_CheckStuck"); 
	set_task(0.1,"checkstuck",0,"",0,"b")	

	// register_clcmd("say test1","test1")	
	// register_clcmd("say test2","test2")	
	// register_clcmd("say test3","test3")	
	// register_clcmd("say test4","test4")
}

// public test1(id)
// {
// 	for(new i=1;i<33;i++)
// 	{
// 		if(i==id)continue
// 		if(!is_user_alive(i))continue
// 		new Float:origin[3]
// 		pev(i, pev_origin, origin)
// 		origin[0]+=32.0
// 		origin[2]-=10.0
// 		set_pev(id, pev_origin, origin)
// 	}
// }

// public test2(id)
// {
// 	for(new i=1;i<33;i++)
// 	{
// 		if(i==id)continue
// 		if(!is_user_alive(i))continue
// 		new Float:origin[3]
// 		pev(i, pev_origin, origin)
// 		origin[0]-=32.0
// 		origin[2]-=10.0
// 		set_pev(id, pev_origin, origin)
// 	}
// }


// public test3(id)
// {
// 	for(new i=1;i<33;i++)
// 	{
// 		if(i==id)continue
// 		if(!is_user_alive(i))continue
// 		new Float:origin[3]
// 		pev(i, pev_origin, origin)
// 		origin[1]+=32.0
// 		origin[2]-=10.0
// 		set_pev(id, pev_origin, origin)
// 	}
// }


// public test4(id)
// {
// 	for(new i=1;i<33;i++)
// 	{
// 		if(i==id)continue
// 		if(!is_user_alive(i))continue
// 		new Float:origin[3]
// 		pev(i, pev_origin, origin)
// 		origin[1]-=32.0
// 		origin[2]-=10.0
// 		set_pev(id, pev_origin, origin)
// 	}
// }

public OrpheuHookReturn:OnPM_CheckStuck() 
{ 
    return OrpheuSupercede;
} 

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public module_filter(const module[])
{
	if (equal(module, "orpheu"))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public checkstuck() {
	if(get_pcvar_num(cvar[0]) >= 1) {
		static players[32], pnum, player
		get_players(players, pnum)
		static Float:origin[3]
		static Float:mins[3], hull
		static Float:vec[3]
		static o,i
		for(i=0; i<pnum; i++){
			player = players[i]
			if (is_user_connected(player) && is_user_alive(player)) {
				pev(player, pev_origin, origin)
				hull = pev(player, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN
				if (!is_hull_vacant2(origin, hull,player) && !get_user_noclip(player) && (pev(player,pev_solid) != SOLID_NOT)) {
					++stuck[player]
					if(stuck[player] >= get_pcvar_num(cvar[2])) {
						pev(player, pev_mins, mins)
						vec[2] = origin[2]
						for (o=0; o < sizeof size; ++o) {
							vec[0] = origin[0] - mins[0] * size[o][0]
							vec[1] = origin[1] - mins[1] * size[o][1]
							vec[2] = origin[2] - mins[2] * size[o][2]
							if (is_hull_vacant(vec, hull,player)) {
								engfunc(EngFunc_SetOrigin, player, vec)
								effects(player)
								set_pev(player,pev_velocity,{0.0,0.0,0.0})
								o = sizeof size
							}
						}
					}
				}
				else
				{
					stuck[player] = 0
				}
			}
		}
	}
}

stock bool:is_hull_vacant2(const Float:origin[3], hull,id) {
	static tr
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr)
	if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid))//get_tr2(tr, TR_InOpen))
	{
		return true
	} 	
	static id2
	id2 = get_tr2(tr, TR_pHit)
	if(is_user_alive(id2))
	{
		if(get_user_noclip(id2)||(pev(id2,pev_solid) == SOLID_NOT))
		{
			return true;
		}
		static Float: origin2[3]
		pev(id2, pev_origin, origin2)

		// if(origin[0]-origin2[0]==32.0||origin[0]-origin2[0]==-32.0||origin[1]-origin2[1]==32.0||origin[1]-origin2[1]==-32.0)
		
		if(origin[0]-origin2[0]==-32.0||origin[1]-origin2[1]==-32.0)
		{
			static oldsolid
			oldsolid = pev(id2, pev_solid)
			set_pev(id2, pev_solid, SOLID_NOT)
			engfunc(EngFunc_TraceHull, origin, origin, 0, HULL_HUMAN, id, tr)
			set_pev(id2, pev_solid, oldsolid)
			if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid))//get_tr2(tr2, TR_InOpen))
			{
				return true
			} 	
		}
	}
	
	return false
}

stock bool:is_hull_vacant(const Float:origin[3], hull,id) {
	static tr
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr)
	if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid))//get_tr2(tr, TR_InOpen))
	{
		return true
	} 	
	
	return false
}

public effects(id) {
	if(get_pcvar_num(cvar[1])) {
		set_hudmessage(255,150,50, -1.0, 0.65, 0, 6.0, 1.5,0.1,0.7) // HUDMESSAGE
		show_hudmessage(id,"You should be unstucked now!") // HUDMESSAGE
		message_begin(MSG_ONE_UNRELIABLE,105,{0,0,0},id )      
		write_short(1<<10)   // fade lasts this long duration
		write_short(1<<10)   // fade lasts this long hold time
		write_short(1<<1)   // fade type (in / out)
		write_byte(20)            // fade red
		write_byte(255)    // fade green
		write_byte(255)        // fade blue
		write_byte(255)    // fade alpha
		message_end()
		client_cmd(id,"spk fvox/blip.wav")
	}
}

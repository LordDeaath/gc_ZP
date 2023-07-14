#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#define VERSION "1.2"
//#define	FL_ONGROUND	(1<<9)	// not moving on the ground (REMOVE)

new bunny_mode,spd,spd2,spd3,spd4,spd5,spd6,spd7,spd8,spd9
native get_user_fps(id)
public plugin_init() {
	register_plugin("Auto BunnyHop", VERSION, "Night Dreamer");
	bunny_mode = register_cvar("autoduck_on","1");
	spd = register_cvar("autoduck_spd_fast","1.06");
	spd2 = register_cvar("autoduck_spd_mid","1.10");
	spd3 = register_cvar("autoduck_spd_slow","1.12");
	spd4 = register_cvar("fps_spd_slow","1.10");
	spd5 = register_cvar("fps_spd_mid","1.08");
	spd6 = register_cvar("fps_spd_fast","1.05");
	spd7 = register_cvar("fps_spd_sfast","0.998");
	spd8 = register_cvar("fps_spd_sfast2","0.996");
	spd9 = register_cvar("fps_spd_sfast3","0.992");
	register_forward(FM_CmdStart, "fw_Start")
}

public fw_Start(id, uc_handle, seed)
{
	if(!get_pcvar_num(bunny_mode))
		return
	if((get_uc( uc_handle, UC_Buttons ) & IN_DUCK ) && !( pev( id, pev_oldbuttons ) & IN_DUCK ))
		check_speed(id)
}  
public check_speed(id)
{			
	if( !(pev(id, pev_flags) & FL_ONGROUND) )
		return;

	if(get_user_fps(id) < 95)
		return;

	static Float:velocity[3]
	pev(id, pev_velocity, velocity)
	static Float:speed[6], Float:spdmax;
	if(get_user_fps(id) < 200)
	{
		speed[0] = get_pcvar_float(spd)
		speed[1] = get_pcvar_float(spd2)
		speed[2] = get_pcvar_float(spd3)
	}
	else
	{
		speed[0] = get_pcvar_float(spd4)
		speed[1] = get_pcvar_float(spd5)
		speed[2] = get_pcvar_float(spd6)
	}
	speed[3] = get_pcvar_float(spd7)
	speed[4] = get_pcvar_float(spd8)
	speed[5] = get_pcvar_float(spd9)

	spdmax = vector_length(velocity)
	if(spdmax < 350.0)
		xs_vec_mul_scalar(velocity, speed[2], velocity)	
	else if(spdmax < 425,0)
		xs_vec_mul_scalar(velocity, speed[1], velocity)
	else if(spdmax < 500.0 )
		xs_vec_mul_scalar(velocity, speed[0], velocity)	
	else if(spdmax < 600.0)	
		xs_vec_mul_scalar(velocity, speed[3], velocity)	
	else if(spdmax < 650.0)	
		xs_vec_mul_scalar(velocity, speed[4], velocity)		
	else xs_vec_mul_scalar(velocity, speed[5], velocity)	
	set_pev(id, pev_velocity, velocity)
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1048\\ f0\\ fs16 \n\\ par }
*/
/* Plugin generated by AMXX-Studio */
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <zp50_class_zombie>
#include <zp50_items>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_DRAGON "zp50_class_dragon"
#include <zp50_class_dragon>
#include <zp50_class_nightcrawler>
#include <cs_maxspeed_api>
#include <zp50_grenade_frost>
#include <zp50_grenade_fire>
#include <colorchat>
#include <fun>
#include <hamsandwich>

#define PLUGIN "Zombie Power"
#define VERSION "1.0"
#define AUTHOR "Administrator"
#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47
#define m_flTimeWeaponIdle 48

new zItm, Float:pCooldown[33], cvar_cooldown, cvar_duration, cvar_speed, zPow[33], iAccess[33]
new Class[12], bool:IsActive[33]
new cvar_leap_zm_force, cvar_leap_zm_height
native zp_class_predator_get(id)
native set_sjump(id,num)
native zp_has_toxic_m4(id)
new g_pCvarPrimaryAttackRate, g_pCvarSecondaryAttackRate
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("drop", "Powr")
	//register_clcmd("skill_pls", "IwantSkill")
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	cvar_cooldown = register_cvar("zp_skill_cooldown", "40")
	cvar_duration = register_cvar("zp_skill_duration", "7")
	cvar_speed = register_cvar("zp_speed_amount", "1.50")	
	cvar_leap_zm_force = register_cvar("zp_leap_zm_force", "600")
	cvar_leap_zm_height = register_cvar("zp_leap_zm_height", "350")
	zItm = zp_items_register("Zombie Power", "", 35,0,0,0,0)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage",0);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1);
	
	g_pCvarPrimaryAttackRate = register_cvar("skill_attack1_rate", "0.15")
	g_pCvarSecondaryAttackRate = register_cvar("skill_attack2_rate", "0.30")

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "Knife_PrimaryAttack", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "Knife_SecondaryAttack", 1)
}
public plugin_natives()
	register_native("player_has_skill","_has_skill",1)
	
public _has_skill(id)
	return zPow[id]
	
public IwantSkill(id)
	iAccess[id] = 1
	
public Event_NewRound()
{
	for(new id;id < get_maxplayers();id++)
		zPow[id] = 0
}
public plugin_cfg()
{
	Class[0] = zp_class_zombie_get_id("Classic Zombie")
	Class[1] = zp_class_zombie_get_id("Catcher Zombie") //Fast
	Class[2] = zp_class_zombie_get_id("Climb Zombie") //Climber
	Class[3] = zp_class_zombie_get_id("Rubber Zombie") //Jumper
	Class[4] = zp_class_zombie_get_id("Fat Zombie") //Fat
	Class[5] = zp_class_zombie_get_id("Vampire Zombie") //Vampire
	Class[6] = zp_class_zombie_get_id("Assassin Zombie") //Assassin
	Class[7] = zp_class_zombie_get_id("Blood Zombie") //Blood
	Class[8] = zp_class_zombie_get_id("Frozen Zombie") //Frozen
	Class[9] = zp_class_zombie_get_id("Burned Zombie") //Burned
	Class[10] = zp_class_zombie_get_id("Rage Zombie") //Rage
	Class[11] = zp_class_zombie_get_id("Arachne Zombie")//Private
}
public fw_CmdStart(id,uc_handle, seed)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;
	if(!zPow[id])
		return FMRES_IGNORED;
	if(!zp_core_is_zombie(id))
		return FMRES_IGNORED;		
	if(zp_class_zombie_get_current(id) != Class[11])
		return FMRES_IGNORED;
	new buttons = get_uc(uc_handle,UC_Buttons)
	new oldbuttons = pev(id, pev_oldbuttons)
	if( (buttons & IN_RELOAD) && !(oldbuttons & IN_RELOAD))
	{
		if( get_gametime() - pCooldown[id] < 8.0 )
		{
			ColorChat(id,GREEN, "[GC]^3 You need to wait for^4 %.f sec.^3 to use another skill!",8.0 - ( get_gametime() - pCooldown[id] ))
			return FMRES_IGNORED
		}
		new force = get_pcvar_num(cvar_leap_zm_force)
		new Float:height = get_pcvar_float(cvar_leap_zm_height)
		Leap(id, force, height)
		pCooldown[id] = get_gametime()
	}
	if( (buttons & IN_USE) && !(oldbuttons & IN_USE))
	{
		if( get_gametime() - pCooldown[id] < 10.0 )
		{
			ColorChat(id,GREEN, "[GC]^3 You need to wait for^4 %.f sec.^3 to use another skill!",10.0 - ( get_gametime() - pCooldown[id] ))
			return FMRES_IGNORED
		}		
		set_task(5.0, "StopSpeed", id)
		IsActive[id] = true
		pCooldown[id] = get_gametime()
	}
	return FMRES_IGNORED;	
}
public zp_fw_items_select_pre(id, it,c)
{
	if(it != zItm)
		return ZP_ITEM_AVAILABLE;
	if(!zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW
	zp_items_menu_text_add("\r[1 Round]")
/*
	if(!iAccess[id])
	{
		zp_items_menu_text_add("\r[Beta Access]")
		return ZP_ITEM_NOT_AVAILABLE;
	}*/
	if(zPow[id])
		return ZP_ITEM_NOT_AVAILABLE;
	return ZP_ITEM_AVAILABLE;
}
public zp_fw_items_select_post(id,it,c)
{
	if(it != zItm)
		return 
	zPow[id] = 1
	set_sjump(id,360)
}
public client_disconnect(id)
{
	zPow[id] = 0
	iAccess[id] = 1
	IsActive[id] = false
}
public zp_fw_core_infect_post(id)
	set_task(1.5,"Skill",id)
	
public fw_TakeDamage(victim,inflictor, attacker, Float:damage)
{
	if(zPow[victim])
		SetHamParamFloat(4,damage * 0.90)
	if(IsActive[victim])
		SetHamParamFloat(4,damage * 0.90)
	
}
public fw_TakeDamage_Post(victim,inflictor, attacker, Float:damage)
{
	static alal
	alal = floatround(damage * 1.60)
	if (zp_core_is_zombie(victim) && IsActive[victim] && (zp_class_zombie_get_current(victim) == Class[4]))
		set_pdata_float(victim, 108, 0.9, 5 );
	if (zp_core_is_zombie(victim) && IsActive[victim] && (zp_class_zombie_get_current(victim) == Class[5]) && zp_has_toxic_m4(attacker) != 2)
		set_user_health(victim, get_user_health(victim) + alal)
}
new Float:MyLast[33]
public client_PreThink(id)
{
	if(!is_user_alive(id))
		return
	if(!zp_core_is_zombie(id))
		return
	if(!zPow[id])
		return
	if(get_gametime() - MyLast[id] < 0.15)
		return
	if(zp_class_zombie_get_current(id) == Class[8])
	{
		if(zp_grenade_frost_get(id) && get_user_health(id) < 7500)
			set_user_health(id, get_user_health(id) + random_num(120,180))
	}
	if(zp_class_zombie_get_current(id) == Class[9])
	{
		if(zp_grenade_fire_get(id) && get_user_health(id) < 7500)
			set_user_health(id, get_user_health(id) + random_num(105,185))
	}
	MyLast[id] = get_gametime()
}
public Skill(id)
{
	if(!is_user_alive(id))
		return
	if(!zp_core_is_zombie(id))
		return
	if(!zPow[id])
		return
	if(zp_core_is_zombie(id))
		set_user_health(id, get_user_health(id) + 1000)	
		
	if(zp_class_zombie_get_current(id) == Class[0])
	{
		ColorChat(id,GREEN,"GC |^3 Your ^4Class Skill^3 is ^4Leap^3 [Press G]!")
		if(zp_core_is_zombie(id))
			set_user_health(id, get_user_health(id) + 600)		
	}
	if(zp_class_zombie_get_current(id) == Class[1])
		ColorChat(id,GREEN,"GC |^3 Your ^4Class Skill^3 is ^4Speed^3 [Press G]!")
	if(zp_class_zombie_get_current(id) == Class[4])
		ColorChat(id,GREEN,"GC |^3 Your ^4Class Skill^3 is ^4Tank^3 [Press G]!")
	if(zp_class_zombie_get_current(id) == Class[3])
		ColorChat(id,GREEN,"GC |^3 Your ^4Class Skill^3 is ^4Passive!^3 Your second jump is ^4Higher!")
	if(zp_class_zombie_get_current(id) == Class[2])
		ColorChat(id,GREEN,"GC |^3 Your ^4Class Skill^3 is ^4Fast Attack^3 [Press G]")
	if(zp_class_zombie_get_current(id) == Class[5])
		ColorChat(id,GREEN,"GC |^3 Your ^4Class Skill^3 is ^4Devour^3 [Press G]!")	
	if(zp_class_zombie_get_current(id) == Class[6])
		ColorChat(id,GREEN,"GC |^3 Your ^4Class Skill^3 is ^4Stealth^3 [Press G]!")	
	if(zp_class_zombie_get_current(id) == Class[7])
		ColorChat(id,GREEN,"GC |^3 Your ^4Class Skill^3 is ^4Borrow^3 [Press G]!")
	if(zp_class_zombie_get_current(id) == Class[8])
		ColorChat(id,GREEN,"GC |^3 Your ^4Class Skill^3 is ^4Passive!^3 You heal when frozen!")
	if(zp_class_zombie_get_current(id) == Class[9])
		ColorChat(id,GREEN,"GC |^3 Your ^4Class Skill^3 is ^4Passive!^3 You heal when burning!")		
}
public Powr(id)
{
	if(!is_user_connected(id))
		return;
	if(!is_user_alive(id))
		return;
	if ((LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id)) ||  (LibraryExists(LIBRARY_DRAGON, LibType_Library) && zp_class_dragon_get(id)) || zp_class_predator_get(id))
		return;
	if(!zp_core_is_zombie(id))
		return;
	if(!zPow[id] || IsActive[id])
		return;
	static Float:gTime, Float:cTime, Float:dTime, Float:pSpeed, Float: height, force, Xtra,iMax
	static Float:StTim
	gTime = get_gametime()
	cTime = get_pcvar_float(cvar_cooldown)
	dTime = get_pcvar_float(cvar_duration)
	pSpeed = get_pcvar_float(cvar_speed)
	force = get_pcvar_num(cvar_leap_zm_force)
	height = get_pcvar_float(cvar_leap_zm_height)
	StTim = dTime - 2.0
	if(zp_class_zombie_get_current(id) == Class[0]) //Classic = Leap
	{
		if(gTime - cTime >= pCooldown[id])
		{
			Leap(id, force, height)
			ColorChat(id,GREEN,"GC |^3 You've activated your ^4Leap^3 Skill!")
			set_task(dTime, "StopSpeed", id)
			pCooldown[id] = gTime
			IsActive[id] = true
		}
		else
		{
			ColorChat(id,GREEN,"GC |^3 Please wait^4 [%d s]^3 before using your ^4Skill^3 again!",floatround(pCooldown[id]- gTime +cTime)+1)
		}
	}
	if(zp_class_zombie_get_current(id) == Class[1])
	{
		if(gTime - cTime >= pCooldown[id])
		{
			cs_set_player_maxspeed_auto(id, pSpeed)
			ColorChat(id,GREEN,"GC |^3 You've activated your ^4Speed^3 Skill!")
			set_task(dTime, "StopSpeed", id)
			pCooldown[id] = gTime
			IsActive[id] = true
		}
		else
		{
			ColorChat(id,GREEN,"GC |^3 Please wait^4 [%d s]^3 before using your ^4Skill^3 again!",floatround(pCooldown[id]- gTime +cTime)+1)
		}
	}
	if(zp_class_zombie_get_current(id) == Class[4])
	{
		if(gTime - cTime >= pCooldown[id])
		{
			ColorChat(id,GREEN,"GC |^3 You've activated your ^4Tank^3 Skill!")
			set_task(dTime, "StopSpeed", id)
			pCooldown[id] = gTime
			IsActive[id] = true
		}
		else
		{
			ColorChat(id,GREEN,"GC |^3 Please wait^4 [%d s]^3 before using your ^4Skill^3 again!",floatround(pCooldown[id]- gTime +cTime)+1)
		}
	}
	if(zp_class_zombie_get_current(id) == Class[5])
	{
		if(gTime - cTime >= pCooldown[id])
		{
			ColorChat(id,GREEN,"GC |^3 You've activated your ^4Devour^3 Skill!")
			set_task(dTime, "StopSpeed", id)
			pCooldown[id] = gTime
			IsActive[id] = true
		}
		else
		{
			ColorChat(id,GREEN,"GC |^3 Please wait^4 [%d s]^3 before using your ^4Skill^3 again!",floatround(pCooldown[id]- gTime +cTime)+1)
		}
	}
	if(zp_class_zombie_get_current(id) == Class[6])
	{
		if(gTime - cTime >= pCooldown[id])
		{
			set_user_rendering(id, kRenderFxNone, 10,10,10,kRenderTransAlpha, 1)
			ColorChat(id,GREEN,"GC |^3 You've activated your ^4Stealth^3 Skill!")
			set_task(StTim, "StopSpeed", id)
			pCooldown[id] = gTime
			IsActive[id] = true
		}
		else
		{
			ColorChat(id,GREEN,"GC |^3 Please wait^4 [%d s]^3 before using your ^4Skill^3 again!",floatround(pCooldown[id]- gTime +cTime)+1)
		}
	}
	if(zp_class_zombie_get_current(id) == Class[7])
	{
		if(gTime - cTime >= pCooldown[id])
		{
			ColorChat(id,GREEN,"GC |^3 You've activated your ^4Borrow^3 Skill!")
			for(new pl=1;pl<=32;pl++)
			{
				if(iMax >= 7)
					break;
				if(!is_user_alive(pl))
					continue;
				if(!zp_core_is_zombie(pl))
					continue;
				if(pl == id)
					continue;					
				if(entity_range(pl,id) > 192)
					continue;
				Xtra += 700
				iMax++
			}
			set_user_health(id,get_user_health(id) + Xtra)
			ColorChat(id, GREEN, "GC |^3 You've borrowed^4 %d Health^3 from^4 %d Zombie(s)!",Xtra, iMax)
			pCooldown[id] = gTime
			IsActive[id] = true
			Xtra = 0
			iMax = 0
			set_task(StTim, "StopSpeed", id)
		}
		else
		{
			ColorChat(id,GREEN,"GC |^3 Please wait^4 [%d s]^3 before using your ^4Skill^3 again!",floatround(pCooldown[id]- gTime +cTime)+1)
		}
	}
	if(zp_class_zombie_get_current(id) == Class[2])
	{
		if(gTime - cTime >= pCooldown[id])
		{
			ColorChat(id,GREEN,"GC |^3 You've activated your ^4Fast Attack^3 Skill!")
			set_task(StTim, "StopSpeed", id)
			pCooldown[id] = gTime
			IsActive[id] = true
		}
		else
		{
			ColorChat(id,GREEN,"GC |^3 Please wait^4 [%d s]^3 before using your ^4Skill^3 again!",floatround(pCooldown[id]- gTime +cTime)+1)
		}
	}
}
public Knife_PrimaryAttack( iEnt )
{
	new id = get_pdata_cbase(iEnt, 41, 4);
	if(!zp_core_is_zombie(id))
		return
	if(!IsActive[id])
		return
	static Float:flRate;
	flRate = get_pcvar_float(g_pCvarPrimaryAttackRate)
	set_pdata_float(iEnt, m_flNextPrimaryAttack, flRate, 4)
	set_pdata_float(iEnt, m_flNextSecondaryAttack, flRate, 4)
	set_pdata_float(iEnt, m_flTimeWeaponIdle, flRate, 4)
}

public Knife_SecondaryAttack( iEnt )
{
	new id = get_pdata_cbase(iEnt, 41, 4);
	if(!zp_core_is_zombie(id))
		return
	if(!IsActive[id])
		return
	if(zp_class_zombie_get_current(id) == Class[2] || zp_class_zombie_get_current(id) == Class[11])
	{
		static Float:flRate;
		flRate = get_pcvar_float(g_pCvarSecondaryAttackRate)
	
		set_pdata_float(iEnt, m_flNextPrimaryAttack, flRate, 4)
		set_pdata_float(iEnt, m_flNextSecondaryAttack, flRate, 4)
		set_pdata_float(iEnt, m_flTimeWeaponIdle, flRate, 4)
	}
} 
public Leap(id, force, Float:ait)
{
	// Not on ground or not enough speed
	if (zp_grenade_fire_get(id) || zp_grenade_frost_get(id))
		return;
	
	static Float:velocity[3]
	
	// Make velocity vector
	velocity_by_aim(id, force, velocity)
	
	// Set custom height
	velocity[2] = ait
	
	// Apply the new velocity
	set_pev(id, pev_velocity, velocity)
}
public StopSpeed(id)
{
	if(!is_user_connected(id))
		return

	IsActive[id] = false
	if(is_user_alive(id))
		cs_set_player_maxspeed_auto(id, 1.20)
	if(zp_class_zombie_get_current(id) == Class[1])
		ColorChat(id, GREEN,"GC |^3 You've ran out of ^4Speed")
	if(zp_class_zombie_get_current(id) == Class[2])
		ColorChat(id, GREEN,"GC |^3 You've ran out of ^4Attack Speed")
	if(zp_class_zombie_get_current(id) == Class[4])
		ColorChat(id, GREEN,"GC |^3 You've ran out of ^4Tank")
	if(zp_class_zombie_get_current(id) == Class[5])
		ColorChat(id, GREEN,"GC |^3 You've ran out of ^4Devour")
	if(zp_class_zombie_get_current(id) == Class[7])
		ColorChat(id, GREEN,"GC |^3 Your^4 Borrow Skill^3 is ready again!")
	if(zp_class_zombie_get_current(id) == Class[6])
	{
		ColorChat(id, GREEN,"GC |^3 You've ran out of ^4Stealth")
		set_user_rendering(id)
	}
}
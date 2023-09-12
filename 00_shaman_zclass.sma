/*================================================================================
	
	-----------------------------------
	-*- [ZP] Class: Zombie: Classic -*-
	-----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_zombie>
#include <fun>
#include <engine>
#include <fakemeta>
#include <colorchat>
#include <crxranks>
#include <hamsandwich>
#include <zp50_gamemodes>

// Classic Zombie Attributes
new const zombieclass1_name[] = "Shaman Zombie"
new const zombieclass1_info[] = "Ability [R/E]"
new const zombieclass1_models[][] = { "gc_dspawn" }
new const zombieclass1_clawmodels[][] = { "models/zombie_plague/v_knife_zombie.mdl" }
const zombieclass1_health = 1020
const Float:zombieclass1_speed = 1.20
const Float:zombieclass1_gravity = 0.60
const Float:zombieclass1_knockback = 1.0

new g_ZombieClassID, Float:LastTime[33],Float:Last[33], iAttack[33], iReg[33],iFrames[33], iFramesAttack[33], iDefFrames[33], iDef[33],GameModeSwarm
native player_has_skill(id)
public plugin_cfg()
{
	GameModeSwarm = zp_gamemodes_get_id("Swarm Mode")
}
public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Shaman", ZP_VERSION_STRING, "ZP Dev Team")
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_clcmd("drop","DefBuff")
	RegisterHam(Ham_TakeDamage, "info_target", "fw_TakeDamage");	
	RegisterHam(Ham_TakeDamage, "func_wall", "fw_TakeDamage");
	RegisterHam(Ham_TakeDamage, "func_breakable", "fw_TakeDamage");
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamagePlay");
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post",1);
	RegisterHam(Ham_Killed, "player","fw_death",1)
	new index
	g_ZombieClassID = zp_class_zombie_register(zombieclass1_name, zombieclass1_info, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity)
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass1_knockback)
	for (index = 0; index < sizeof zombieclass1_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass1_models[index])
	for (index = 0; index < sizeof zombieclass1_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass1_clawmodels[index])

}
public fw_TakeDamagePlay(victim, inflictor, attacker, Float:damage)
{
	if(!is_user_alive(attacker))
		return HAM_IGNORED;
		
	if(victim == attacker)
		return HAM_IGNORED;
	
	if(zp_core_is_zombie(attacker))
		return HAM_IGNORED;
	if(!iDef[victim])
		return HAM_IGNORED;
	new Float:MyDef = 0.50 - (float(iDef[victim]) * 0.08 ) 
	SetHamParamFloat(4, damage * MyDef)
	return HAM_IGNORED;

}
public fw_TakeDamage_Post(victim,inflictor, attacker, Float:damage)
{
	if(!is_user_alive(victim))
		return HAM_IGNORED;
	if (!zp_core_is_zombie(victim))
		return HAM_IGNORED;
	if(!iDef[victim])
		return HAM_IGNORED;
	set_pdata_float(victim, 108, 0.9, 5 );
	return HAM_IGNORED;
}

public fw_death(id)
{
	iAttack[id] = 0 
	iReg[id] = 0
}
public Event_NewRound(id)
{
	for(new id=1;id<=32;id++)
	{
	iAttack[id] = 0 
	iReg[id] = 0
	}
}
public zp_fw_core_infect_pre(id,att)
{
	new Curr = zp_class_zombie_get_current(id)
	if(zp_class_zombie_get_next(id) == g_ZombieClassID)
	{
		if(CountShaman() >= 3)
		{
			ColorChat(id, GREEN,"[GC]^3 Max^4 Shamans ^3Reached! select another ^4class")
			zp_class_zombie_set_next(id, Curr)
		}
	}
}
public zp_fw_core_infect_post(id)
{
	if(zp_class_zombie_get_next(id) == g_ZombieClassID)
	{
		ColorChat(id, GREEN, "[GC]^3 Press^4 [R] ^3to  give a^4 health regeneration^3 buff")
		ColorChat(id, GREEN, "[GC]^3 Press^4 [E] ^3to  give a^4 20 percent attack^3 buff")
		ColorChat(id, GREEN, "[GC]^3 Press^4 [G] ^3to  give a^4 50 percent defense^3 buff")
	}
}
		
public zp_fw_class_zombie_select_pre(id,class)
{
	if(class != g_ZombieClassID)
		return ZP_CLASS_AVAILABLE

	if(crxranks_get_user_level(id) < 15)
	{
		zp_class_zombie_menu_text_add("\r[Level 15]")	
		return ZP_CLASS_NOT_AVAILABLE
	}
	new Txt[16]
	formatex(Txt,charsmax(Txt),"\r(%d/3)",CountShaman())
	zp_class_zombie_menu_text_add(Txt)	
	if(CountShaman() >=3)
		return ZP_CLASS_NOT_AVAILABLE
	return ZP_CLASS_AVAILABLE
}
public DefBuff(id)
{	
	if(zp_gamemodes_get_current() == GameModeSwarm)
		return;	
	if(!is_user_alive(id))
		return;
	if(!zp_core_is_zombie(id))
		return;
	if(zp_class_zombie_get_current(id) != g_ZombieClassID)
		return;
	if( get_gametime() - LastTime[id] < 45.0 )
	{
		ColorChat(id,GREEN, "[GC]^3 You need to wait for^4 %.f sec.^3 to use another skill!",45.0 - ( get_gametime() - LastTime[id] ))
		return
	}
	DoDefRadius(id)
	LastTime[id] = get_gametime()
	
}
public fw_CmdStart(id,uc_handle, seed)
{
	if(zp_gamemodes_get_current() == GameModeSwarm)
		return FMRES_IGNORED;	
	if(!is_user_alive(id))
		return FMRES_IGNORED;
	if(!zp_core_is_zombie(id))
		return FMRES_IGNORED;
	if(zp_class_zombie_get_current(id) != g_ZombieClassID)
		return FMRES_IGNORED;
		
	new buttons = get_uc(uc_handle,UC_Buttons)
	new oldbuttons = pev(id, pev_oldbuttons)
	if( (buttons & IN_RELOAD) && !(oldbuttons & IN_RELOAD))
	{
		if( get_gametime() - LastTime[id] < 45.0 )
		{
			ColorChat(id,GREEN, "[GC]^3 You need to wait for^4 %.f sec.^3 to use another skill!",45.0 - ( get_gametime() - LastTime[id] ))
			return FMRES_IGNORED
		}
		DoHealRadius(id)
		LastTime[id] = get_gametime()
	}
	if( (buttons & IN_USE) && !(oldbuttons & IN_USE))
	{
		if( get_gametime() - LastTime[id] < 40.0 )
		{
			ColorChat(id,GREEN, "[GC]^3 You need to wait for^4 %.f sec.^3 to use another skill!",40.0 - ( get_gametime() - LastTime[id] ))
			return FMRES_IGNORED
		}		
		DoAttackRadius(id)
		LastTime[id] = get_gametime()
	}
	return FMRES_IGNORED
	
}
public DoDefRadius(play)
{	
	for(new id=1;id<=32;id++)
	{
		if(!is_user_alive(id))
			continue
		if(!zp_core_is_zombie(id))
			continue
		if(entity_range(id,play) > 512)
			continue
		iDef[id]++
		if(!player_has_skill(id))
			iDefFrames[id] += 30
		else iDefFrames[id] += 60
		ColorChat(id,GREEN, "[GC]^3 You recieved a^4 defense buff^3 from a^4 shaman ^3zombie!")
	}
}
public DoHealRadius(play)
{
	for(new id=1;id<=32;id++)
	{
		if(!is_user_alive(id))
			continue
		if(!zp_core_is_zombie(id))
			continue
		if(entity_range(id,play) > 512)
			continue
		iReg[id]++
		if(!player_has_skill(id))
			iFrames[id] += 30
		else iFrames[id] += 60
		ColorChat(id,GREEN, "[GC]^3 You recieved a^4 regeneration buff^3 from a^4 shaman ^3zombie!")
	}
}
public DoAttackRadius(play)
{
	for(new id=1;id<=32;id++)
	{
		if(!is_user_alive(id))
			continue
		if(!zp_core_is_zombie(id))
			continue
		if(entity_range(id,play) > 256)
			continue
		iAttack[id]++
		if(!player_has_skill(id))
			iFramesAttack[id] += 30
		else iFramesAttack[id] += 60
		ColorChat(id,GREEN, "[GC]^3 You recieved an^4 attack buff^3 from a^4 shaman ^3zombie!")
	}
}
public client_PreThink(id)
{
	if(!is_user_alive(id))
		return
	if(!zp_core_is_zombie(id))
		return
	if(get_gametime() - Last[id] < 0.25)
		return
	if(iReg[id])
	{
		if(iFrames[id] > 0 )
			iFrames[id]--
		else
		{
			iReg[id] = 0
			ColorChat(id,GREEN, "[GC]^3 Your ^4regeneration buff^3 ended!")
		}
		if(get_user_health(id) < 6000 && iReg[id])
			set_user_health(id, get_user_health(id) + random_num(60,90)*iReg[id])
	}
	if(iAttack[id])
	{
		if(iFramesAttack[id] > 0 )
			iFramesAttack[id]--
		else
		{
			iAttack[id] = 0
			ColorChat(id,GREEN, "[GC]^3 Your ^4attack buff^3 ended!")
		}
	}
	if(iDef[id])
	{
		if(iDefFrames[id] > 0 )
			iDefFrames[id]--
		else
		{
			iDef[id] = 0
			ColorChat(id,GREEN, "[GC]^3 Your ^4defense buff^3 ended!")
		}
	}
	Last[id] = get_gametime()
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if(is_user_connected(victim))
	{
	}
	else
	{
		new sz_classname[32] 
		entity_get_string( victim , EV_SZ_classname , sz_classname, 31 )			
		if(equali(sz_classname,"lasermine") ) 
		{
		}
		else
		if(equali(sz_classname,"amxx_pallets"))
		{
		}
		else
		if(equali(sz_classname,"rcbomb"))
		{
		}
		else
		if(equali(sz_classname,"amxx_mt"))
		{
		}
		else	
			return HAM_IGNORED; 
	}
	
	if(!is_user_alive(attacker))
		return HAM_IGNORED;
		
	if(victim == attacker)
		return HAM_IGNORED;
	
	if(!zp_core_is_zombie(attacker))
		return HAM_IGNORED;
	if(!iAttack[attacker])
		return HAM_IGNORED;
	new Float: MyAttack = 1.0 + ( 0.23 + (float(iAttack[attacker]) * 0.05 ))
	SetHamParamFloat(4, damage*MyAttack)
	return HAM_IGNORED;
		
}

CountShaman()
{
	new Count;
	for(new id=1;id<=32;id++)
	{
		if(!is_user_alive(id))
			continue
		if(!zp_core_is_zombie(id))
			continue
		if(zp_class_zombie_get_current(id) != g_ZombieClassID)
			continue
		Count++
	}
	return Count;
}
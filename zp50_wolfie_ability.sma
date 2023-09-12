#include <amxmodx>
#include <engine>
#include <zp50_class_human>
#include <fun>
#include <colorchat>
#include <hamsandwich>

new g_SkinID_Coco, g_SkinID_Miho, g_Ability[33], iOn[33], Float:iTime[33]

public plugin_init()
{
	register_plugin("[ZP] Wolfie Skill", ZP_VERSION_STRING, "ZP Dev Team")
	RegisterHam(Ham_TakeDamage,"player", "Fw_Damage")
	RegisterHam(Ham_Killed,"player", "Fw_Kill_Post",1)
}
public event_round_start()
{
	for(new id = 1;id < 32;id++)
	{
		g_Ability[id] = 0
		iOn[id] = 0
	}
}

public plugin_cfg()
{
	g_SkinID_Coco = zp_class_human_get_id("Coconut")
	g_SkinID_Miho = zp_class_human_get_id("Miho")
}
public Fw_Damage(victim, inflictor, attacker, Float:damage,bits)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED;
	if(!is_user_alive(attacker))
		return HAM_IGNORED;
	if(zp_core_is_zombie(attacker) || !zp_core_is_zombie(victim))
		return HAM_IGNORED;
	if(zp_class_human_get_current(attacker) == g_SkinID_Coco || zp_class_human_get_current(attacker) == g_SkinID_Miho)
	{
		if(get_user_weapon(attacker) == CSW_KNIFE)
			return HAM_IGNORED;
		if(get_user_weapon(attacker) == CSW_HEGRENADE)
			return HAM_IGNORED;	
		if(get_user_weapon(attacker) == CSW_C4)
			return HAM_IGNORED;
		if(!iOn[attacker])
			return HAM_IGNORED;
		new Float:rDm = random_float(1.25,2.00)
		SetHamParamFloat(4,damage * rDm)
		if(bits&DMG_BULLET)
		{
			if(rDm > 1.50)
			{
				set_user_armor(attacker, get_user_armor(attacker) - 5)
				set_user_health(attacker, get_user_health(attacker) - 5)
			}
			else
			{
				set_user_health(attacker, get_user_health(attacker) - 2)	
				set_user_armor(attacker, get_user_armor(attacker) - 2)
			}
			if(get_user_armor(attacker) <= 5)
			{
				iOn[attacker] = 0
				ColorChat(attacker,GREEN,"[GC]^3 Dark Eye:^4 Off")			
			}
		}
	}	
	return HAM_IGNORED;
}
public Fw_Kill_Post(victim, attacker)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED;
	if(!is_user_alive(attacker))
		return HAM_IGNORED;
	if(zp_core_is_zombie(attacker))
		return HAM_IGNORED;
	if(get_gametime() - iTime[attacker] < 0.5)
		return HAM_IGNORED;
	
	if(zp_class_human_get_current(attacker) == g_SkinID_Coco || zp_class_human_get_current(attacker) == g_SkinID_Miho)
	{
		if(get_user_weapon(attacker) == CSW_KNIFE)
			return HAM_IGNORED;
		if(get_user_weapon(attacker) == CSW_HEGRENADE)
			return HAM_IGNORED;	
		if(get_user_weapon(attacker) == CSW_C4)
			return HAM_IGNORED;
		if(iOn[attacker])
			return HAM_IGNORED;
		set_user_armor(attacker, get_user_armor(attacker) + 10)
		set_user_health(attacker, get_user_health(attacker) + 10)
		if(get_user_armor(attacker) >= 100)
		{
			iOn[attacker] = 1
			ColorChat(attacker,GREEN,"[GC]^3 Dark Eye:^4 On")
		}
		iTime[attacker] = get_gametime()
	}
	return HAM_IGNORED;
}
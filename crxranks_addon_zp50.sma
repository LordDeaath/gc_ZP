#include <amxmodx>
#include <hamsandwich>
#include <zp50_gamemodes>
#tryinclude <crxranks>

#if !defined _crxranks_included
	#error "crxranks.inc" is missing in your "scripting/include" folder. Download it from: "https://amxx-bg.info/inc/"
#endif

#tryinclude <zp50_core>

#if !defined _zp50_core_included
	#error "zp50_core.inc" is missing in your "scripting/include" folder. Download it from: "https://amxx-bg.info/inc/"
#endif

new const PLUGIN_VERSION[] = "1.0 @ 5.0"
native IsExtraXP()
new Tag,Wars
new Infection,Multi,Arma

new Float:DamageDealt[33]
new Float:DamageReceived[33]

new Float:DamageRequired[33]
new Float:DamageSelfRequired[33]
new bool:Zombie[33]

new bool:DamageRewardEnabled
new bool:DamageSelfRewardEnabled
native AddXp(id, xp)
public plugin_init()
{
	register_plugin("CRXRanks: ZP 5.0 Base", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXRanksZPBase", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	//register_event("DeathMsg", "OnPlayerKilled", "a")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
}
public plugin_natives()
{
	register_native("return_xp_dealt", "native_get_damage",1)
	register_native("return_xp_total", "native_get_damage_required",1)
}
public native_get_damage(id)
{
	return floatround(DamageDealt[id]);
}

public native_get_damage_required(id)
{
	return floatround(DamageRequired[id]);
}
public plugin_cfg()
{	
	Tag= zp_gamemodes_get_id("Zombie Tag Mode");
	Wars= zp_gamemodes_get_id("Infection Wars Mode");
	Infection = zp_gamemodes_get_id("Infection Mode")
	Multi = zp_gamemodes_get_id("Multiple Infection Mode")
	Arma = zp_gamemodes_get_id("Armageddon Mode")

}
public zp_fw_gamemodes_start(gm)
{	
	if(gm==Infection||gm==Multi||gm==Arma)
	{
		DamageRewardEnabled=true;
		DamageSelfRewardEnabled=true;
		new Float:ap
		for(new id=1;id<33;id++)
		{			
			if(!is_user_connected(id))
				continue;
				
			ap = float(crxranks_get_user_xp(id))
			
			if(ap<100000)
			{
				DamageRequired[id]= 100+(9*ap/250) //500-3000
				DamageSelfRequired[id]= 500+(ap/25) //1000-4000
				
				DamageRequired[id]=100*float(floatround(DamageRequired[id]/100))
				DamageSelfRequired[id]=100*float(floatround(DamageSelfRequired[id]/100))
				
			}
			else
			{
				DamageRequired[id]= 3000.0
				DamageSelfRequired[id]= 4000.0
			}
			
		}
	}
}
public fw_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return;
	if(DamageSelfRewardEnabled&&zp_core_is_zombie(victim)&&!zp_core_is_zombie(attacker))
	{
		DamageReceived[victim] += damage
		if(DamageReceived[victim] >= DamageSelfRequired[victim])
		{
			static XP
			XP = floatround(DamageReceived[victim] / DamageSelfRequired[victim], floatround_floor)
			if(XP > 0)
			{
			if(IsExtraXP())
				AddXp(victim, XP*2)
			else AddXp(victim, XP)
			}
			DamageReceived[victim]=0.0;
		}
	}

	if(DamageRewardEnabled&&(zp_core_is_zombie(attacker) && !zp_core_is_zombie(victim)||(!zp_core_is_zombie(attacker)&&zp_core_is_zombie(victim))))
	{
		// Store damage dealt
		DamageDealt[attacker] += damage
		if(DamageDealt[attacker] >= DamageRequired[attacker])
		{
			static XP
			XP = floatround(DamageDealt[attacker] / DamageRequired[attacker], floatround_floor)
			if(XP > 0)
			{
			if(IsExtraXP())
				AddXp(attacker, XP*2)
			else AddXp(attacker, XP)
			}
			DamageDealt[attacker]=0.0;
		}	
	}
}
public zp_fw_gamemodes_end()
{
	DamageRewardEnabled=false;
	DamageSelfRewardEnabled=false;
}
public zp_fw_core_cure_post(id, iAttacker)
{
	if(zp_gamemodes_get_current()==Tag||zp_gamemodes_get_current()==Wars)
		return;
	crxranks_give_user_xp(id, _, id == iAttacker ? "zp_cured_self" : "zp_cured", CRXRANKS_XPS_REWARD)

	if(iAttacker)
	{
		crxranks_give_user_xp(iAttacker, _, "zp_cure_player", CRXRANKS_XPS_REWARD)
	}
}

public zp_fw_core_infect_post(id, iAttacker)
{
	if(zp_gamemodes_get_current()==Tag||zp_gamemodes_get_current()==Wars)
		return;
	crxranks_give_user_xp(id, _, id == iAttacker ? "zp_infected_self" : "zp_infected", CRXRANKS_XPS_REWARD)

	if(iAttacker)
	{
		if(IsExtraXP())
			AddXp(iAttacker, 5)
		else
			crxranks_give_user_xp(iAttacker, _, "zp_infect_player", CRXRANKS_XPS_REWARD)
	}
}

public zp_fw_core_last_human(id)
{
	if(zp_gamemodes_get_current()==Tag||zp_gamemodes_get_current()==Wars)
		return;
	crxranks_give_user_xp(id, _, "zp_last_human", CRXRANKS_XPS_REWARD)
}

public zp_fw_core_last_zombie(id)
{
	if(zp_gamemodes_get_current()==Tag||zp_gamemodes_get_current()==Wars)
		return;
	crxranks_give_user_xp(id, _, "zp_last_zombie", CRXRANKS_XPS_REWARD)
}

/*
public OnPlayerKilled()
{
	new iAttacker = read_data(1), iVictim = read_data(2)

	if(!is_user_alive(iVictim)||!is_user_alive(iAttacker))
		return;
	
	if(zp_core_is_zombie(iVictim)&&!zp_core_is_zombie(iAttacker))
	{
		crxranks_give_user_xp(iVictim, _, "zp_zombie_death", CRXRANKS_XPS_REWARD)
	}
}*/
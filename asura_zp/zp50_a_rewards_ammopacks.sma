/*================================================================================
	
	--------------------------------
	-*- [ZP] Rewards: Ammo Packs -*-
	--------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_gamemodes>
#include <zp50_ammopacks>
#include <zmvip>
#include <dhudmessage>

#define REWARD_INFECT 2
#define REWARD_KILL 2
#define REWARD_DEATH 1
#define REWARD_BOSS_KILL 3
#define REWARD_RACE_KILL 4

#define DAMAGE_NORMAL 800.0
#define DAMAGE_ARMA 1000.0
#define DAMAGE_ZBOSS 500.0
#define DAMAGE_SURVIVOR 150.0
#define DAMAGE_KNIFER_PLASMA 65.0

#define REWARD_INFECT_VIP 4
#define REWARD_KILL_VIP 4
#define REWARD_DEATH_VIP 2
#define REWARD_BOSS_KILL_VIP 6
#define REWARD_RACE_KILL_VIP 8

#define DAMAGE_NORMAL_VIP 500.0
#define DAMAGE_ARMA_VIP 500.0
#define DAMAGE_ZBOSS_VIP 250.0
#define DAMAGE_SURVIVOR_VIP 150.0
#define DAMAGE_KNIFER_PLASMA_VIP 65.0

native zp_class_survivor_get(id);
native zp_class_sniper_get(id);
native zp_class_knifer_get(id);
native zp_class_plasma_get(id);
native zp_class_nemesis_get(id);
native zp_class_dragon_get(id);
native zp_class_nightcrawler_get(id);
native zp_class_predator_get(id);

new Float:DamageDealt[33]

new Float:DamageRequired[33]
new Float:DamageRequiredVIP[33]

new bool:InfectReward;
new bool:RaceReward;
new bool:ZombieReward;
new bool:HumanReward;

new bool:Boss[33]
new bool:VIP[33]
new bool:Zombie[33]

new YPos[33]

public plugin_init()
{
	register_plugin("[ZP] Rewards: Ammo Packs", ZP_VERSION_STRING, "ZP Dev Team")
		
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Spawn, "fw_PlayerSpawn_Post", 1)
}

public plugin_natives()
{
	register_native("zp_get_damage","native_get_damage",1)
	register_native("zp_get_damage_required","native_get_damage_required",1)
}

public native_get_damage(id)
{
	return floatround(DamageDealt[id]);
}

public native_get_damage_required(id)
{
	if(!VIP[id])
	{
		return floatround(DamageRequired[id]);
	}

	return floatround(DamageRequiredVIP[id]);
}

public zp_fw_gamemodes_end()
{
	HumanReward=false;
	ZombieReward=false;
	RaceReward=false;
	InfectReward=false;
	arrayset(_:DamageDealt, _:0.0, sizeof(DamageDealt))
}

public zp_fw_gamemodes_start(gm)
{
	HumanReward=true;
	InfectReward=true;
	RaceReward=true;
}

public CheckUserPoints(id)
{
	if(!is_user_connected(id))
		return;
		
	new myAp = zp_ammopacks_get(id)
	
	if(myAp < 5000)
		StData(id, 0.0)
	else if(myAp < 7500)
		StData(id, 200.0)
	else if(myAp < 10000)
		StData(id, 400.0)
	else if(myAp < 20000)
		StData(id, 600.0)
	else if(myAp < 30000)
		StData(id, DAMAGE_NORMAL)
	else if(myAp < 40000)
		StData(id, 1000.0)
	else
		StData(id, 1200.0)
}
/*
public Next(id)
{
	if(!is_user_connected(id))
		return;
		
	new myAp = zp_ammopacks_get(id)
	switch(myAp)
	{
		case 0..2500: StData(id, 200.0)
		case 2501.5000: StData(id, 300.0)
		case 5001.6000: Next(id)
	}
}
*/
public StData(id, Float:Num)
{
	if(!is_user_connected(id))
		return;
	if(VIP[id])
	{
		DamageRequired[id] = DAMAGE_NORMAL + ( Num / 2.0 )
		DamageRequiredVIP[id] = DAMAGE_NORMAL_VIP + ( Num / 2.0 )	
	}
	else
	{
		DamageRequired[id] = DAMAGE_NORMAL + Num
		DamageRequiredVIP[id] = DAMAGE_NORMAL_VIP + Num
	}
}
public client_putinserver(id)
{
	if(zv_get_user_flags(id)&ZV_MAIN)
	{
		VIP[id]=true;
	}
	else
	{
		VIP[id]=false;
	}
	Zombie[id]=false;
	Boss[id]=false;
	DamageDealt[id]=0.0
	set_task(5.0,"CheckUserPoints",id)
}

public zp_fw_core_infect_post(id, attacker)
{	
	CheckUserPoints(attacker)
	Zombie[id]=true;
	if(zp_class_nemesis_get(id)||zp_class_dragon_get(id)||zp_class_nightcrawler_get(id)||zp_class_predator_get(id))
	{
		Boss[id]=true;
	}
	else
	{
		Boss[id]=false;
	}

	if (is_user_connected(attacker) && attacker != id)
	{		
		if(!InfectReward)
			return;

		if(!VIP[attacker])
		{
			zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_INFECT)
			show_reward(attacker, REWARD_INFECT, "[INF]")
		}
		else
		{
			zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_INFECT_VIP)
			show_reward(attacker, REWARD_INFECT_VIP , "[INF]")
		}
	}
}

public zp_fw_core_cure_post(id)
{
	Zombie[id]=false;
	if(zp_class_survivor_get(id)||zp_class_sniper_get(id)||zp_class_knifer_get(id)||zp_class_plasma_get(id))
	{
		Boss[id]=true;
	}
	else
	{
		Boss[id]=false;
	}
}

// Ham Take Damage Post Forward
public fw_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return;
	if((Zombie[attacker] &&ZombieReward && !Zombie[victim])||(!Zombie[attacker]&&HumanReward&&Zombie[victim]))
	{
		if(DamageRequired[attacker])
		{
			// Reward ammo packs to zombies for damaging humans?
			// Store damage dealt
			DamageDealt[attacker] += damage
			if(!VIP[attacker])
			{
				if(DamageDealt[attacker] >= DamageRequired[attacker])
				{
					//CheckUserPoints(attacker)
					static AP
					AP = floatround(DamageDealt[attacker] / DamageRequired[attacker], floatround_floor)
					zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + AP)
					show_reward(attacker, AP, "[DMG]")
					DamageDealt[attacker]-=DamageRequired[attacker] * AP;
				}
			}
			else if(DamageDealt[attacker] >= DamageRequiredVIP[attacker])
			{		
				//CheckUserPoints(attacker)
				static AP
				AP = floatround(DamageDealt[attacker] / DamageRequiredVIP[attacker], floatround_floor)
				zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + AP)
				show_reward(attacker, AP, "[DMG]")
				DamageDealt[attacker]-= DamageRequiredVIP[attacker] * AP;
			}
		}		
	}
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Non-player kill or self kill
	if (victim == attacker || !is_user_connected(attacker))
		return;
	CheckUserPoints(attacker)
	if(Boss[attacker])
	{		
		if(!RaceReward)
		{			
			if(!VIP[attacker])
			{				
				zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_BOSS_KILL)
				show_reward(attacker, REWARD_BOSS_KILL,"[KILL]")
			}
			else
			{
				zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_BOSS_KILL_VIP)
				show_reward(attacker, REWARD_BOSS_KILL_VIP,"[KILL]")
			}
		}
		else
		{
			if(!VIP[attacker])
			{
				zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_RACE_KILL)
				show_reward(attacker, REWARD_RACE_KILL,"[KILL]")
			}
			else
			{
				zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_RACE_KILL_VIP)
				show_reward(attacker, REWARD_RACE_KILL_VIP,"[KILL]")
			}
		}
		return;	
	}
	
	// Reward ammo packs to attacker for the kill
	if(Zombie[victim])
	{
		if(!VIP[attacker])
		{
			zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_KILL)
			show_reward(attacker, REWARD_KILL,"[KILL]")
		}
		else
		{
			zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_KILL_VIP)
			show_reward(attacker, REWARD_KILL_VIP,"[KILL]")
		}
		if(!VIP[victim])
		{
			zp_ammopacks_set(victim, zp_ammopacks_get(victim) + REWARD_DEATH)
			show_reward(victim, REWARD_DEATH,"[DEATH]")
		}
		else
		{
			zp_ammopacks_set(victim, zp_ammopacks_get(victim) + REWARD_DEATH_VIP)
			show_reward(victim, REWARD_DEATH_VIP,"[DEATH]")
		}
	}
	else if(!RaceReward)
	{
		if(!VIP[attacker])
		{
			zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_KILL)
			show_reward(attacker, REWARD_KILL,"[KILL]")
		}
		else
		{
			zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_KILL_VIP)
			show_reward(attacker, REWARD_KILL_VIP,"[KILL]")
		}
	}
}
public fw_PlayerSpawn_Post(id)
	CheckUserPoints(id)
	
stock show_reward(id, amount, const reason[])
{
	static temp[16], i;
	temp = ""
	for(i=0;i<YPos[id];i++)
	{
		strcat(temp, "^n", charsmax(temp))
	}
	if(YPos[id]++>1)
	{
		YPos[id]=0;
	}
	new Color[3]
	Color[0] = random_num(1,150)
	Color[1] = random_num(1,200)
	Color[2] = random_num(1,255)
	set_dhudmessage(Color[0], Color[1], Color[2], -1.0, 0.6,2,0.5,0.5,0.1,0.1)

	show_dhudmessage(id, "%s+%d AP%s %s",temp,amount,amount>1?"(s)":"",reason)
}
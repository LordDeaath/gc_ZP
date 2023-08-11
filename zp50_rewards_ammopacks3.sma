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
#include <zp50_colorchat>
#include <user_afk_status>

#define REWARD_INFECT 5
#define REWARD_KILL 3
#define REWARD_DEATH 1
#define REWARD_BOSS_KILL 5
#define REWARD_RACE_KILL 1

#define DAMAGE_NORMAL 400.0
#define DAMAGE_SELF_NORMAL 2000.0
#define DAMAGE_SELF_SWARM 1500.0
#define DAMAGE_ARMA 1000.0
#define DAMAGE_ZBOSS 250.0
#define DAMAGE_SURVIVOR 65.0
#define DAMAGE_KNIFER_PLASMA 15.0

#define REWARD_INFECT_VIP 8
#define REWARD_KILL_VIP 5
#define REWARD_DEATH_VIP 3
#define REWARD_BOSS_KILL_VIP 8
#define REWARD_RACE_KILL_VIP 2

#define DAMAGE_NORMAL_VIP 200.0
#define DAMAGE_ARMA_VIP 600.0
#define DAMAGE_ZBOSS_VIP 150.0
#define DAMAGE_SURVIVOR_VIP 40.0
#define DAMAGE_KNIFER_PLASMA_VIP 10.0

#define REWARD_XAP_INFECT 7
#define REWARD_XAP_KILL 5
#define REWARD_XAP_DEATH 3
#define REWARD_XAP_BOSS_KILL 5
#define REWARD_XAP_RACE_KILL 3

native zp_class_survivor_get(id);
native zp_class_sniper_get(id);
native zp_class_knifer_get(id);
native zp_class_plasma_get(id);
native zp_class_nemesis_get(id);
native zp_class_dragon_get(id);
native zp_class_nightcrawler_get(id);
native zp_class_predator_get(id);

new Float:DamageDealt[33]
new Float:DamageReceived[33]

new Float:DamageRequired
new Float:DamageRequiredVIP
new Float:DamageSelfRequired

new bool:InfectReward;
new bool:RaceReward;
new bool:ZombieReward;
new bool:HumanReward;

new bool:Boss[33]
new bool:VIP[33]
new bool:Zombie[33]

new YPos[33]
new bool:XtraXP, g_iCvars[3]
public plugin_init()
{
	register_plugin("[ZP] Rewards: Ammo Packs", ZP_VERSION_STRING, "ZP Dev Team")
		
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	g_iCvars[0] = register_cvar( "xap_on", "1" );
	g_iCvars[1] = register_cvar( "xap_start_time", "22" );
	g_iCvars[2] = register_cvar( "xap_end_time", "10" );
}
public Event_NewRound()
{
	if( IsVipHour( get_pcvar_num( g_iCvars[ 1 ] ), get_pcvar_num( g_iCvars[ 2 ] ) ) )
	{
		XtraXP = true;
		zp_colored_print(0, "^3 Happy Hour ^4On^3! ^4AP^3 is increased^1!")
	}
	else
		XtraXP = false;	
}
bool:IsVipHour( iStart, iEnd )
{
    new iHour; time( iHour );
    return bool:( iStart < iEnd ? ( iStart <= iHour < iEnd ) : ( iStart <= iHour || iHour < iEnd ) )
} 
public plugin_natives()
{
	register_native("zp_get_damage","native_get_damage",1)
	register_native("zp_get_damage_required","native_get_damage_required",1)
	register_native("zp_show_reward", "native_show_reward")
}

public native_get_damage(id)
{
	return floatround(DamageDealt[id]);
}

public native_get_damage_required(id)
{
	if(!VIP[id])
		return floatround(ApReq(id))
	return floatround(ApReqVIP(id));
}
new Infection,Multi,Swarm,Plague,Nemesis,Dragon,Predator,Nightcrawler,Survivor,Knifer,Plasma,Race, Armageddon, MnF

public plugin_cfg()
{
	Infection = zp_gamemodes_get_id("Infection Mode")
	Multi = zp_gamemodes_get_id("Multiple Infection Mode")
	Swarm = zp_gamemodes_get_id("Swarm Mode")
	Plague = zp_gamemodes_get_id("Plague Mode")
	Nemesis = zp_gamemodes_get_id("Nemesis Mode")
	Dragon = zp_gamemodes_get_id("Dragon Mode")
	Predator = zp_gamemodes_get_id("Predator Mode")
	Nightcrawler = zp_gamemodes_get_id("Nightcrawler Mode")
	Survivor = zp_gamemodes_get_id("Survivor Mode")
	Knifer = zp_gamemodes_get_id("Knifer Mode")
	Plasma = zp_gamemodes_get_id("Plasma Mode")
	Race = zp_gamemodes_get_id("Nemesis Race Mode");
	Armageddon = zp_gamemodes_get_id("Armageddon Mode");
	MnF = zp_gamemodes_get_id("Monster Fight");
}

public zp_fw_gamemodes_end()
{
	DamageRequired = 0.0
	DamageRequiredVIP = 0.0
	DamageSelfRequired = 0.0
	HumanReward=false;
	ZombieReward=false;
	RaceReward=false;
	InfectReward=false;
	arrayset(_:DamageDealt, _:0.0, sizeof(DamageDealt))
	arrayset(_:DamageReceived, _:0.0, sizeof(DamageReceived))
}

public zp_fw_gamemodes_start(gm)
{	
	if(gm==Infection||gm==Multi)
	{
		DamageRequired = DAMAGE_NORMAL
		DamageRequiredVIP = DAMAGE_NORMAL_VIP		
		DamageSelfRequired = DAMAGE_SELF_NORMAL
		HumanReward=true;
		InfectReward=true;
	}
	else if(gm==Swarm||gm==Plague)
	{
		DamageRequired = DAMAGE_ZBOSS
		DamageRequiredVIP = DAMAGE_ZBOSS_VIP	
		DamageSelfRequired = DAMAGE_SELF_SWARM
		HumanReward=true;
		ZombieReward=true;
	}
	else if(gm==Nemesis||gm==Dragon||gm==Nightcrawler||gm==Predator||gm==MnF)
	{
		DamageRequired = DAMAGE_ZBOSS
		DamageRequiredVIP = DAMAGE_ZBOSS_VIP
		HumanReward=true;
	}
	else if(gm==Armageddon)
	{
		DamageRequired = DAMAGE_ARMA
		DamageRequiredVIP = DAMAGE_ARMA_VIP
		HumanReward=true;
		ZombieReward=true;
	}
	else if(gm==Survivor)
	{
		DamageRequired = DAMAGE_SURVIVOR
		DamageRequiredVIP = DAMAGE_SURVIVOR_VIP
		ZombieReward=true;
	}
	else if(gm==Knifer||gm==Plasma)
	{
		DamageRequired = DAMAGE_KNIFER_PLASMA
		DamageRequiredVIP = DAMAGE_KNIFER_PLASMA_VIP
		ZombieReward=true;
	}
	else
	if(gm==Race)
	{
		RaceReward=true;
	}
	if(XtraXP)
	{
		DamageRequired = DamageRequiredVIP + 50
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
	DamageReceived[id]=0.0
}

public zp_fw_core_infect_post(id, attacker)
{	
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
			if(XtraXP)
				zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_XAP_INFECT)
			else zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_INFECT)
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
public Float:ApReq(id)
{
	new AmmoPack = zp_ammopacks_get(id)
	new Float:Final = DamageRequired + ( 8 * float(AmmoPack) / 200 )
	return Final
}

public Float:ApReqVIP(id)
{
	new AmmoPack = zp_ammopacks_get(id)
	new Float:Final = DamageRequired + ( 8 * float(AmmoPack) / 200 )
	return Final	
}

public Float:ApS(id)
{
	new AmmoPack = zp_ammopacks_get(id)
	new Float:Final = DamageSelfRequired + ( 12 * float(AmmoPack) / 200 )
	return Final	
}

public fw_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return;
	new Float:Afk = get_user_afktime(victim)
	if(Zombie[victim]&&DamageSelfRequired&&!Zombie[attacker]&&Afk < 60.0)
	{
		DamageReceived[victim] += damage
		if(DamageReceived[victim] >= ApS(victim))
		{
			static AP
			AP = floatround(DamageReceived[victim] / ApS(victim), floatround_floor)
			zp_ammopacks_set(victim, zp_ammopacks_get(victim) + AP)
			show_reward(victim, AP, "[TRY]")
			DamageReceived[victim]-= ApS(victim) * AP;
		}
	}

	if((Zombie[attacker] &&ZombieReward && !Zombie[victim])||(!Zombie[attacker]&&HumanReward&&Zombie[victim]))
	{
		if(DamageRequired)
		{	
			// Store damage dealt
			DamageDealt[attacker] += damage
			if(!VIP[attacker])
			{
				if(DamageDealt[attacker] >= ApReq(attacker))
				{
					static AP
					AP = floatround(DamageDealt[attacker] / ApReq(attacker), floatround_floor)
					zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + AP)
					show_reward(attacker, AP, "[DMG]")
					DamageDealt[attacker]-= ApReq(attacker) * AP;
				}
			}
			else if(floatround(DamageDealt[attacker]) >= ApReqVIP(attacker))
			{				
				static AP
				AP = floatround(DamageDealt[attacker] / ApReqVIP(attacker), floatround_floor)
				zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + AP)
				show_reward(attacker, AP, "[DMG]")
				DamageDealt[attacker]-= ApReqVIP(attacker) * AP;
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
	new Float:Afk = get_user_afktime(victim)	
	if(Boss[attacker])
	{		
		if(!RaceReward)
		{			
			if(!VIP[attacker])
			{	
				if(XtraXP)
				{
					zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_XAP_BOSS_KILL)
					show_reward(attacker, REWARD_XAP_BOSS_KILL,"[KILL]")
				}
				else 
				{
					zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_BOSS_KILL)
					show_reward(attacker, REWARD_BOSS_KILL,"[KILL]")
				}
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
				if(XtraXP)
				{
					zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_XAP_RACE_KILL)
					show_reward(attacker, REWARD_XAP_RACE_KILL,"[KILL]")
				}
				else
				{	
					zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_RACE_KILL)
					show_reward(attacker, REWARD_RACE_KILL,"[KILL]")
				}
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
			if(XtraXP)
			{
				zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_XAP_KILL)
				show_reward(attacker, REWARD_XAP_KILL,"[KILL]")
			}
			else
			{
				zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_KILL)
				show_reward(attacker, REWARD_KILL,"[KILL]")
			}
		}
		else
		{
			zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_KILL_VIP)
			show_reward(attacker, REWARD_KILL_VIP,"[KILL]")
		}
		if(!VIP[victim])
		{
			if(Afk > 60.0)
				return
			if(XtraXP)
			{
				zp_ammopacks_set(victim, zp_ammopacks_get(victim) + REWARD_XAP_DEATH)
				show_reward(victim, REWARD_XAP_DEATH,"[DEATH]")
			}
			else
			{
				zp_ammopacks_set(victim, zp_ammopacks_get(victim) + REWARD_DEATH)
				show_reward(victim, REWARD_DEATH,"[DEATH]")				
			}
		}
		else
		{
			if(Afk > 60.0)
				return
			zp_ammopacks_set(victim, zp_ammopacks_get(victim) + REWARD_DEATH_VIP)
			show_reward(victim, REWARD_DEATH_VIP,"[DEATH]")
		}

	}
	else if(!RaceReward)
	{
		if(!VIP[attacker])
		{
			if(XtraXP)
			{
				zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_XAP_KILL)
				show_reward(attacker, REWARD_XAP_KILL,"[KILL]")
			}
			else
			{
				zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_KILL)
				show_reward(attacker, REWARD_KILL,"[KILL]")
			}				
		}
		else
		{
			zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + REWARD_KILL_VIP)
			show_reward(attacker, REWARD_KILL_VIP,"[KILL]")
		}
	}
}

public native_show_reward(pluginid, num_params)
{
	new id = get_param(1)
	new amount = get_param(2)
	new reason[32]
	get_string(3, reason, charsmax(reason))
	show_reward(id, amount, reason);
}

public show_reward(id, amount, const reason[])
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
	set_dhudmessage(0, 255, 0, -1.0, 0.7,2,0.5,0.5,0.1,0.1)

	show_dhudmessage(id, "%s+%d AmmoPack%s %s",temp,amount,amount>1?"s":"",reason)
}
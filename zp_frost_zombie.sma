/*================================================================================
	
	---------------------------------
	-*- [ZP] Class: Zombie: Light -*-
	---------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_zombie>
#include <zp50_grenade_frost>
#include <zp50_grenade_fire>
#include <fun>
#include <engine>
#include <colorchat>

native zp_class_nightcrawler_get(id)
native zp_class_nemesis_get(id)
native zp_class_predator_get(id)
native zp_class_dragon_get(id)
//native zp_is_apocalypse();

// Light Zombie Attributes
new const zombieclass3_name[] = "Frozen Zombie"
new const zombieclass3_info[] = "Freeze Humans" 
new const zombieclass3_models[][] = { "gc_frozen" }
new const zombieclass3_clawmodels[][] = { "models/zombie_plague/zow_claws.mdl" }
const zombieclass3_health = 1600
const Float:zombieclass3_speed = 0.95
const Float:zombieclass3_gravity = 0.6
const Float:zombieclass3_knockback = 0.8
native player_has_skill(id)
new g_ZombieFrost, frostsprite, Health, Float:g_FrostCooldown[33], Float:iRad[33], Float:iTime[33]
public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Frost", ZP_VERSION_STRING, "ZP Dev Team")
	register_clcmd("drop", "UsePower")	
	
	new index
	g_ZombieFrost = zp_class_zombie_register(zombieclass3_name, zombieclass3_info, zombieclass3_health, zombieclass3_speed, zombieclass3_gravity)
	zp_class_zombie_register_kb(g_ZombieFrost, zombieclass3_knockback)
	for (index = 0; index < sizeof zombieclass3_models; index++)
		zp_class_zombie_register_model(g_ZombieFrost, zombieclass3_models[index])
	for (index = 0; index < sizeof zombieclass3_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieFrost, zombieclass3_clawmodels[index])
		
	frostsprite = precache_model( "sprites/frost_explode.spr" )
}

public zp_fw_grenade_frost_pre(id)
{
	if(!is_user_connected(id))
		return;
		
	if(!is_user_alive(id))
		return;	
		
	if(!zp_core_is_zombie(id))
		return;
		
	Health = get_user_health(id)
	if(zp_class_zombie_get_current(id) == g_ZombieFrost)
	{
		if(!zp_grenade_frost_get(id))
			set_user_health(id, Health + 300)
	}
}
public UsePower(id)
{
	if(!is_user_connected(id))
		return;
		
	if(!is_user_alive(id))
		return;	
		
	if(!zp_core_is_zombie(id))
		return;
		
	if(zp_class_zombie_get_current(id) != g_ZombieFrost)
		return;
		
	if(zp_class_nemesis_get(id))
		return;
		
	if(zp_class_predator_get(id))
		return;
		
	if(zp_class_dragon_get(id))
		return;
		
	if(zp_class_nightcrawler_get(id))
		return;
		
	Health = get_user_health(id)	
	if(Health >= 7000)
		return;
	
	/*if(zp_is_apocalypse())
	{
		static Float:CurTime
		CurTime = get_gametime()
		if(CurTime - 15.0 > g_FrostCooldown[id])
		{
			Power(id)
			sprite_control(id)
			g_FrostCooldown[id] = CurTime
		}
		else
			ColorChat(id,GREEN,"[GC]^3 Please Wait ^4[%d Seconds]^3 before using this skill again", floatround( 15.0 + (g_FrostCooldown[id] - CurTime) ) )
	}
	else
	{*/
		static Float:CurTime
		CurTime = get_gametime()
		if(CurTime - 30.0 > g_FrostCooldown[id])
		{
			Power(id)
			sprite_control(id)
			g_FrostCooldown[id] = CurTime
		}
		else
			ColorChat(id,GREEN,"[GC]^3 Please Wait ^4[%d Seconds]^3 before using this skill again", floatround( 30.0 + (g_FrostCooldown[id] - CurTime) ) )
	//}
}
public Power(id)
{
	if(player_has_skill(id))
	{
		iRad[id] = 384.0
		iTime[id] = 3.0
	}
	else
	{
		iRad[id] = 256.0
		iTime[id] = 1.5
	}
	for(new i = 1; i < get_maxplayers(); i++) 
	{
		if(!is_user_connected(i))
			continue;
		if(!is_user_alive(i))
			continue;
		//if(!is_visible(id,i))
			//continue;
		if(entity_range(i, id) <= iRad[id])
		{
			if(zp_core_is_zombie(i))
			{
				if(zp_grenade_fire_get(i))
					zp_grenade_fire_set(i, false)
			}
			else
			{
				zp_grenade_frost_set(i)
				set_task(iTime[id], "UnFreeze",i)
			}
		}
				
	} 
}

public UnFreeze(id)
{
	if(!is_user_connected(id))
		return;
	if(!is_user_alive(id))
		return;
	if(!zp_grenade_frost_get(id))	
		return;
		
	zp_grenade_frost_set(id, false)
}
public te_spray( args[ ] )
{
    message_begin( MSG_BROADCAST,SVC_TEMPENTITY )
    write_byte( 120 ) // Throws a shower of sprites or models
    write_coord( args[ 0 ] ) // start pos
    write_coord( args[ 1 ] )
    write_coord( args[ 2 ] )
    write_coord( args[ 3 ] ) // velocity
    write_coord( args[ 4 ] )
    write_coord( args[ 5 ] )
    write_short( frostsprite ) // spr
    write_byte( 8 ) // count
    write_byte( 70 ) // speed
    write_byte( 100 ) //(noise)
    write_byte( 5 ) // (rendermode)
    message_end( )
    
    return PLUGIN_CONTINUE
}

public sqrt( num )
{
    new div = num
    new result = 1
    while( div > result )
    {
        div = ( div + result ) / 2
        result = num / div
    }
    return div
}

public sprite_control( player )
{
	
    new vec[ 3 ]
    new aimvec[ 3 ]
    new velocityvec[ 3 ]
    new length
    new speed = 10
    
    get_user_origin( player, vec )
    get_user_origin( player, aimvec, 2 )
    
    velocityvec[ 0 ] = aimvec[ 0 ] - vec[ 0 ]
    velocityvec[ 1 ] = aimvec[ 1 ] - vec[ 1 ]
    velocityvec[ 2 ] = aimvec[ 2 ] - vec[ 2 ]
    length = sqrt( velocityvec[ 0 ] * velocityvec[ 0 ] + velocityvec[ 1 ] * velocityvec[ 1 ] + velocityvec[ 2 ] * velocityvec[ 2 ] )
    velocityvec[ 0 ] = velocityvec[ 0 ] * speed / length
    velocityvec[ 1 ] = velocityvec[ 1 ] * speed / length
    velocityvec[ 2 ] = velocityvec[ 2 ] * speed / length
    
    new args[ 8 ]
    args[ 0 ] = vec[ 0 ]
    args[ 1 ] = vec[ 1 ]
    args[ 2 ] = vec[ 2 ]
    args[ 3 ] = velocityvec[ 0 ]
    args[ 4 ] = velocityvec[ 1 ]
    args[ 5 ] = velocityvec[ 2 ]
    
    set_task( 0.1, "te_spray", 0, args, 8, "a", 2 )
}		
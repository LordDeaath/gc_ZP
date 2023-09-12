#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <zombieplague>
#include <hamsandwich>
#include <fun>
#include <zp50_grenade_fire>
#include <zp50_grenade_frost>
//#include <zp50_class_assassin>
#include <zp50_class_sniper>
#include <zp50_class_survivor>
#include <colorchat>
//#include <zmvip>
#include <zp50_class_zombie>


native zp_class_nightcrawler_get(id)
native zp_class_nemesis_get(id)
native zp_class_predator_get(id)
native zp_class_dragon_get(id)
//native zp_is_apocalypse();

new const zclass_name[ ] = "Burned Zombie"
new const zclass_info[ ] = "=Fire="
new const zclass_model[ ] = "gc_burned"
new const zclass_clawmodel[ ] = "models/zombie_plague/zow_claws.mdl"
const zclass_health = 1800
const zclass_speed = 225
const Float:zclass_gravity = 0.6
const Float:zclass_knockback = 0.8

new g_zclass_burned, firesprite
new Float:g_FireCooldown[33], Float:iRad[33], Float:iTime[33]
new bool:Blocked[33]
native player_has_skill(id)
public plugin_init( )
{
    register_plugin( "[ZP] Zombie Class: Fire Zombie", "1.0", "007" )    
    register_clcmd("drop","UsePower")
    RegisterHam(Ham_Killed,"player","Player_Death")
    RegisterHam(Ham_TakeDamage,"player","fw_td_forward")
    
}

public fw_td_forward(victim,inflictor, attacker, Float:damage)
{
	if(!is_user_alive(victim))
		return HAM_IGNORED
	if(!zp_core_is_zombie(victim))
		return HAM_IGNORED		
	if(zp_class_zombie_get_current(victim) != g_zclass_burned)
		return HAM_IGNORED
	if(!zp_grenade_fire_get(victim))
		return HAM_IGNORED
	if(!player_has_skill(victim))
		SetHamParamFloat(4,0.85)
	else SetHamParamFloat(4,0.70)
	
	return HAM_IGNORED
}

public plugin_precache( )
{
    g_zclass_burned = zp_register_zombie_class( zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback )
    firesprite = precache_model( "sprites/flame.spr" )
}


public zp_user_infected_post(id, infector)
{
	if(is_user_connected(infector))
	if( zp_get_user_zombie_class( infector ) == g_zclass_burned &&!zp_class_nemesis_get(infector)&&!zp_class_nightcrawler_get(infector)&&!zp_class_dragon_get(infector)&&!zp_class_predator_get(infector))
	{    	
		Blocked[infector]=false;
	}

	if(zp_get_user_zombie_class(id) != g_zclass_burned)
		return;	

	if(zp_class_nemesis_get(id))
		return;
				
	if(zp_class_predator_get(id))
		return;
		
	if(zp_class_dragon_get(id))
		return;
		
	if(zp_class_nightcrawler_get(id))
		return;
		
	ColorChat(id, GREEN, "[GC]^3 Press^4 G^3 to throw flames at humans!")   
}

public zp_fw_grenade_frost_pre(id)
{
	if(zp_get_user_zombie_class(id) == g_zclass_burned&&!zp_class_nemesis_get(id)&&!zp_class_nightcrawler_get(id)&&!zp_class_dragon_get(id)&&!zp_class_predator_get(id))
	{
		new health;
		health = get_user_health(id);
		if(health<300)
		{
			health = 1
		}
		else
		{
			health-=300
		}
		set_user_health(id, health)
		set_task(2.0,"unfreeze",id)
	}
}

public unfreeze(id)
{
	if(!is_user_alive(id))
		return;
		
	if(zp_core_is_zombie(id))
	{
		zp_grenade_frost_set(id, false)
	}
}

public use_cmd( id )
{
	    
    sprite_control( id )	    
    static Float:origin [ 3 ]
    pev ( id, pev_origin, origin )
        // Collisions
    static victim 
    victim = -1
    
    // Find radius
    if(player_has_skill(id))
    {
	iRad[id] = 384.0
	iTime[id] = 1.0
    }
    else
    {
	iRad[id] = 256.0
	iTime[id] = 0.5    	
    }
    
    // Find all players in a radius
    while ( ( victim = engfunc ( EngFunc_FindEntityInSphere, victim, origin, iRad[id] ) ) != 0 )
    {
        // Dead or zombie
     if(!is_user_connected(victim))
     {
     	static sz_classname[32] 
	entity_get_string( victim , EV_SZ_classname , sz_classname, 31 )
	
	if( equali(sz_classname,"amxx_pallets")||equali(sz_classname,"lasermine")) 
	{
		if(!player_has_skill(id))
			ExecuteHamB(Ham_TakeDamage, victim, 0, id, 15.0, DMG_SLASH)
		else
			ExecuteHamB(Ham_TakeDamage, victim, 0, id, 30.0, DMG_SLASH)
	}
	continue
     }
	
     if (!is_user_alive ( victim ) || zp_class_sniper_get(victim) || zp_class_survivor_get(victim))
	continue
            // Get duration
     if(zp_core_is_zombie(victim)) zombie_unfreeze(victim)
     else
     {
            // Continiously affect them
     zp_grenade_fire_set(victim, true)
     set_task ( iTime[id] , "unfire_user", victim)
     }
    }

    return PLUGIN_HANDLED
}

public zombie_unfreeze(victim)
{
	if(!is_user_alive(victim))
		return PLUGIN_HANDLED
	
	zp_grenade_frost_set(victim, false)
	return PLUGIN_HANDLED

}

public unfire_user( target )
{
	if(!is_user_alive(target))
		return PLUGIN_HANDLED
	
	zp_grenade_fire_set( target, false )
	return PLUGIN_HANDLED
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
    write_short( firesprite ) // spr
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

public UsePower(id)
{

	if(!is_user_connected(id))
		return;
		
	if(!is_user_alive(id))
		return;	
		
	if(!zp_core_is_zombie(id))
		return;
		
	if(zp_get_user_zombie_class(id) != g_zclass_burned)
		return;	

	if(zp_class_nemesis_get(id))
		return;
				
	if(zp_class_predator_get(id))
		return;
		
	if(zp_class_dragon_get(id))
		return;
		
	if(zp_class_nightcrawler_get(id))
		return;
	
	/*if(zp_is_apocalypse())
	{	
		static Float:CurTime
		CurTime = get_gametime()
		
		if(CurTime - 15.0 > g_FireCooldown[id])
		{
			use_cmd(id)
			Blocked[id]=true;
			g_FireCooldown[id] = CurTime
		}
		else
			ColorChat(id,GREEN,"[GC]^3 Please Wait ^4[%d Seconds]^3 before using this skill again", floatround( 15 + (g_FireCooldown[id] - CurTime) ) )
	}
	else
	{*/
	
	if(Blocked[id])
	{
		ColorChat(id,GREEN,"[GC]^3 You must infect humans/die before using this again!")
		return;
	}
	
	static Float:CurTime
	CurTime = get_gametime()
	
	if(CurTime - 30.0 > g_FireCooldown[id])
	{
		use_cmd(id)
		Blocked[id]=true;
		g_FireCooldown[id] = CurTime
	}
	else
	ColorChat(id,GREEN,"[GC]^3 Please Wait ^4[%d Seconds]^3 before using this skill again", floatround( 30.0 + (g_FireCooldown[id] - CurTime) ) )
	//}
}
           

public Player_Death(id, attacker)
{
	if(id!=attacker)
		Blocked[id]=false;
}
/*
public zp_fw_class_zombie_select_pre(id, classid)
{
	if(classid!=g_zclass_burned)
		return ZP_CLASS_AVAILABLE
	
	if(!(zv_get_user_flags(id)&ZV_MAIN)&&!(get_user_flags(id)&ADMIN_KICK))
	{
		zp_class_zombie_menu_text_add("\r(VIP/ADMIN)")
		return ZP_CLASS_NOT_AVAILABLE;
	}

	return ZP_CLASS_AVAILABLE
}*/
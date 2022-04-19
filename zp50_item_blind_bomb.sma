#include < amxmodx >
#include <cstrike>
#include < fakemeta >
#include < hamsandwich >
#include < fun >
//#include < zombieplague >
#include <zp50_core>
#include < zp50_items >
#include < zp50_class_nemesis>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_ASSASSIN "zp50_class_assassin"
#include <zp50_class_assassin>
#define LIBRARY_DRAGON "zp50_class_dragon"
#include <zp50_class_dragon>
#include <zp50_gamemodes>
#include <zmvip>

// Defines
#define MAXPLAYERS     32
#define FCVAR_FLAGS     ( FCVAR_SERVER | FCVAR_SPONLY | FCVAR_UNLOGGED )
#define OFFSET_PLAYER    41
#define OFFSET_ACTIVE    373
#define LINUX_DIFF    5
#define NADE_TYPE_BLIND    8634
#define FFADE_IN    0x0000
#define REPEAT        0.2 // Time when next screen fade message is being sent
#define TASK_AFFECT    666
#define ID_AFFECT    ( taskid - TASK_AFFECT )
#define OFFSET_FLAMMO    387

#define ITEM_NAME "Blind Bomb"
#define ITEM_DESC "Blind the human"
#define ITEM_COST 25

new g_MsgAmmoPickup

const XO_CBASEPLAYERWEAPON = 4;

// Grenade models
new const grenade_model_p [ ] = "models/zombie_plague/p_zombibomb.mdl"
new const grenade_model [ ] = "models/zombie_plague/v_zombibomb.mdl"
new const grenade_model_w [ ] = "models/zombie_plague/w_zombibomb.mdl"

// Sounds
new const explosion_sound [ ] = { "scientist/scream20.wav" , "scientist/scream22.wav" , "scientist/scream05.wav" }
new const purchase_sound [ ] = "items/gunpickup2.wav"
new const purchase_sound2 [ ] = "items/9mmclip1.wav"

// Cached sprite indexes
new m_iTrail, m_iRing

// Item ID
new g_blind

// CVAR pointers
new cvar_nade_radius, cvar_duration

new HasBlind[33]

new Purchases[33]
// CS Sounds
new const g_sound_buyammo[] = "items/9mmclip1.wav"

// Precache
public plugin_precache ( )
{
    // Precache grenade models
    precache_model ( grenade_model_p )
    precache_model ( grenade_model )
    precache_model ( grenade_model_w )
    
    // Precache sounds
    precache_sound ( explosion_sound )
    precache_sound ( purchase_sound )
    precache_sound ( purchase_sound2 )
    
    // Precache sprites
    m_iRing = precache_model ( "sprites/shockwave.spr" )
    m_iTrail = precache_model ( "sprites/laserbeam.spr" )
}

// Plugin initialization
public plugin_init ( )
{
    // New plugin
    register_plugin ( "[ZP] Extra Item: Blind Bomb", "1.0", "Author" )
    
    g_MsgAmmoPickup = get_user_msgid("AmmoPickup")
    // New extra item
    g_blind =     zp_items_register("Blind Bomb (Blind enemies)","",25,0,2,2,0)
    
    // Forwards
    register_forward ( FM_SetModel, "fw_SetModel" )
    RegisterHam ( Ham_Think, "grenade", "fw_ThinkGrenade" )
    RegisterHam(Ham_Item_Deploy, "weapon_smokegrenade", "CSmokegrenade_Deploy_Post", 1)
    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
    register_forward ( FM_CmdStart, "fw_CmdStart" )
    
    // CVARs
    cvar_nade_radius = register_cvar ( "zp_blind_nade_radius", "500" )
    cvar_duration = register_cvar ( "zp_blind_nade_duration", "2.5" )
    
    // Messages
}

new Infection, Multi
public plugin_cfg()
{
	Infection = zp_gamemodes_get_id("Infection Mode")
	Multi = zp_gamemodes_get_id("Multiple Infection Mode")
	//gMode_Survivor=zp_gamemodes_get_id("Survivor Mode")
}

public plugin_natives()
{
    register_native("give_blind_bomb","native_give_blind_bomb",1);
    register_native("zp_blind_set_cost","native_blind_set_cost")
    set_module_filter("module_filter")
    set_native_filter("native_filter")
}

public native_blind_set_cost(plugin,params)
{
    if(get_param(3)!=g_blind)
        return false;	

    set_param_byref(2, ((Purchases[get_param(1)]<2?Purchases[get_param(1)]:2)+2) * get_param_byref(2)/2)

    return true;
}


public module_filter(const module[])
{
    if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_ASSASSIN) || equal(module, LIBRARY_DRAGON))
        return PLUGIN_HANDLED;
    
    return PLUGIN_CONTINUE;
}

public native_filter(const name[], index, trap)
{
    if (!trap)
        return PLUGIN_HANDLED;
    
    return PLUGIN_CONTINUE;
}


public zp_fw_gamemodes_start()
{
	for(new id=1;id<33;id++)
	{
		Purchases[id]=0
	}
}

public zp_fw_items_select_pre(id, item)
{
    if (item != g_blind)
        return ZP_ITEM_AVAILABLE;

    if (!zp_core_is_zombie(id))
        return ZP_ITEM_DONT_SHOW;

    if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
        return ZP_ITEM_DONT_SHOW;

    if (LibraryExists(LIBRARY_ASSASSIN, LibType_Library) && zp_class_assassin_get(id))
        return ZP_ITEM_DONT_SHOW;

    if (LibraryExists(LIBRARY_DRAGON, LibType_Library) && zp_class_dragon_get(id))
        return ZP_ITEM_DONT_SHOW;

    /*
    if (user_has_weapon(id, CSW_SMOKEGRENADE))
        return ZP_ITEM_NOT_AVAILABLE;*/
        
    if(zp_gamemodes_get_current()!=Infection&&zp_gamemodes_get_current()!=Multi)
    {
        if(zv_get_user_flags(id)&ZV_MAIN)
        {
            switch(Purchases[id])
            {
                case 0: {zp_items_menu_text_add("[0/2]");}
                case 1: {zp_items_menu_text_add("[1/2]");}
                case 3: {zp_items_menu_text_add("[2/2]");return ZP_ITEM_NOT_AVAILABLE;}
                default: {return ZP_ITEM_NOT_AVAILABLE;}
            }		
        }
        else
        {
            switch(Purchases[id])
            {
                case 0: {zp_items_menu_text_add("[0/1]");}
                case 1: {zp_items_menu_text_add("[1/2]\r [VIP]");return ZP_ITEM_NOT_AVAILABLE;}
                default: {return ZP_ITEM_NOT_AVAILABLE;}
            }
        }
    }
    else
    {
        if(zv_get_user_flags(id)&ZV_MAIN)
        {
            switch(Purchases[id])
            {
                case 0: {zp_items_menu_text_add("[0/3]");}
                case 1: {zp_items_menu_text_add("[1/3]");}
                case 2: {zp_items_menu_text_add("[2/3]");}
                case 3: {zp_items_menu_text_add("[3/3]");return ZP_ITEM_NOT_AVAILABLE;}
                default: {return ZP_ITEM_NOT_AVAILABLE;}
            }		
        }
        else
        {
            switch(Purchases[id])
            {
                case 0: {zp_items_menu_text_add("[0/2]");}
                case 1: {zp_items_menu_text_add("[1/2]");}
                case 2: {zp_items_menu_text_add("[2/3]\r [VIP]");return ZP_ITEM_NOT_AVAILABLE;}
                default: {return ZP_ITEM_NOT_AVAILABLE;}
            }
        }
    }

    return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, item)
{
    if (item != g_blind)
        return;

    Purchases[id]++
    native_give_blind_bomb(id)
}
public native_give_blind_bomb(id)
{
    HasBlind[id]++

    if(user_has_weapon(id, CSW_SMOKEGRENADE))
    {
        // Increase BP ammo on it instead
        cs_set_user_bpammo(id, CSW_SMOKEGRENADE, cs_get_user_bpammo(id, CSW_SMOKEGRENADE) + 1)
        
        // Flash ammo in hudha
        message_begin(MSG_ONE_UNRELIABLE, g_MsgAmmoPickup, _, id)
        write_byte(13) // ammo id
        write_byte(1) // ammo amount
        message_end()
        
        // Play clip purchase sound
        emit_sound(id, CHAN_ITEM, g_sound_buyammo, 1.0, ATTN_NORM, 0, PITCH_NORM)
    }
    else
    {
        // Give weapon to player
        give_item(id, "weapon_smokegrenade")
    }


    client_cmd ( id, "spk %s", purchase_sound )
}
    

public zp_fw_core_cure(id, infector)
{
    HasBlind[id]=0
}

public zp_fw_core_infect(id, infector)
{
    HasBlind[id]=0

    // We were affected by Blind Bomb
    if ( task_exists ( id+TASK_AFFECT ) )
        remove_task ( id+TASK_AFFECT )
}

// Someone died
public fw_PlayerKilled_Post(id)
{    
    // Remove hallucinations
    remove_task ( id+TASK_AFFECT )    
    HasBlind[id]=0
}

// Set model
public fw_SetModel ( Entity, const Model [ ] )
{
    // Prevent invalid ent messages
    if ( !pev_valid ( Entity ) )
        return FMRES_IGNORED
        
    // Grenade not thrown yet    
    if ( pev ( Entity, pev_dmgtime ) == 0.0 )
        return FMRES_IGNORED
    
    // We are throwing Blind Bomb    
    if ( equal ( Model [7 ], "w_sm", 4 ) )
    {

        if(!HasBlind[pev(Entity, pev_owner)])
            return FMRES_IGNORED;
        
        //Draw trail
        message_begin ( MSG_BROADCAST, SVC_TEMPENTITY )
        write_byte ( TE_BEAMFOLLOW ) // Temp entity ID
        write_short ( Entity ) // Entity to follow
        write_short ( m_iTrail ) // Sprite index
        write_byte ( 10 ) // Life
        write_byte ( 10 ) // Line width
        write_byte ( 255 ) // Red amount
        write_byte ( 255 ) // Blue amount
        write_byte ( 0 ) // Blue amount
        write_byte ( 255 ) // Alpha
        message_end ( )
        
        // Set grenade entity
        set_pev ( Entity, pev_flTimeStepSound, NADE_TYPE_BLIND )
        
        // Decrease nade count
        HasBlind[pev(Entity, pev_owner)]--
      
        // Set world model
        engfunc ( EngFunc_SetModel, Entity, grenade_model_w )
        return FMRES_SUPERCEDE
    }
    return FMRES_IGNORED
}

// Grenade is getting to explode
public fw_ThinkGrenade ( Entity )
{
    // Prevent invalid ent messages
    if ( !pev_valid ( Entity ) )
        return HAM_IGNORED
    
    // Get damage time
    static Float:dmg_time
    pev ( Entity, pev_dmgtime, dmg_time )
    
    // maybe it is time to go off
    if ( dmg_time > get_gametime ( ) )
        return HAM_IGNORED
        
    // Our grenade    
    if ( pev ( Entity, pev_flTimeStepSound ) == NADE_TYPE_BLIND )
    {
        // Force to explode
        blind_explode ( Entity )
        return HAM_SUPERCEDE
    }
    return HAM_IGNORED
}

public CSmokegrenade_Deploy_Post(weapon)
{
    new id = get_pdata_cbase(weapon, OFFSET_PLAYER, XO_CBASEPLAYERWEAPON)

    if (!HasBlind[id])
        return;

    set_pev ( id, pev_viewmodel2, grenade_model )
    set_pev ( id, pev_weaponmodel2, grenade_model_p )
}

// Command start
public fw_CmdStart ( Player, UC_Handle, Seed )
{
    // Dead, zombie or not affected
    if ( !is_user_alive ( Player ) || !task_exists ( Player+TASK_AFFECT ) )
        return FMRES_IGNORED
    
    // Get buttons
    new buttons = get_uc ( UC_Handle, UC_Buttons )
    
    // We are firing
    if ( buttons & IN_ATTACK )
    {
        // We are holding an active weapon
        if ( get_pdata_cbase ( Player, OFFSET_ACTIVE, LINUX_DIFF ) )
        {
            // New recoil
            set_pev ( Player, pev_punchangle, Float:{3.0, 3.0, 4.0} )
        }
    }
    return FMRES_HANDLED
}
            

// Grenade explode
public blind_explode ( Entity )
{
    // Invalid entity ?
    if ( !pev_valid ( Entity  ) )
        return
    
    // Get entities origin
    static Float:origin [ 3 ]
    pev ( Entity, pev_origin, origin )
    
    // Draw ring
    UTIL_DrawRing (origin )
    
    // Explosion sound
    emit_sound ( Entity, CHAN_WEAPON, explosion_sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
    
    // Collisions
    static victim 
    victim = -1
    
    // Find radius
    static Float:radius
    radius = get_pcvar_float ( cvar_nade_radius )
    
    // Find all players in a radius
    while ( ( victim = engfunc ( EngFunc_FindEntityInSphere, victim, origin, radius ) ) != 0 )
    {
        // Dead or zombie
        if ( !is_user_alive ( victim ) || zp_core_is_zombie(victim))
            continue
            
        // Victim isn't affected yet    
        if ( !task_exists ( victim+TASK_AFFECT ) ) 
        {
            // Get duration
            new duration = get_pcvar_num ( cvar_duration )
            
            // Calculate affect times
            new affect_count = floatround ( duration / REPEAT )
            
            // Continiously affect them
            set_task ( REPEAT, "affect_victim", victim+TASK_AFFECT, _, _, "a", affect_count )
        }
    }
    
    // Remove entity from ground
    engfunc ( EngFunc_RemoveEntity, Entity )
}

// We are going to affect you
public affect_victim ( taskid )
{
    // Dead
    if ( !is_user_alive ( ID_AFFECT ) )
        return
        
    // Make a screen fade

    ScreenFade(ID_AFFECT, get_pcvar_float( cvar_duration ), 0, 0, 0, 255)      
    
    // Remove task after all
    remove_task ( ID_AFFECT )
}

// Draw explosion ring ( from zombie_plague40.sma )
stock UTIL_DrawRing ( const Float:origin [ 3 ] )
{
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
    write_byte(TE_BEAMCYLINDER) // TE id
    engfunc(EngFunc_WriteCoord, origin[0]) // x
    engfunc(EngFunc_WriteCoord, origin[1]) // y
    engfunc(EngFunc_WriteCoord, origin[2]) // z
    engfunc(EngFunc_WriteCoord, origin[0]) // x axis
    engfunc(EngFunc_WriteCoord, origin[1]) // y axis
    engfunc(EngFunc_WriteCoord, origin[2]+555.0) // z axis
    write_short( m_iRing ) // sprite
    write_byte(0) // startframe
    write_byte(0) // framerate
    write_byte(4) // life
    write_byte(60) // width
    write_byte(0) // noise
    write_byte(200) // red
    write_byte(200) // green
    write_byte(200) // blue
    write_byte(200) // brightness
    write_byte(0) // speed
    message_end()
}

// ScreenFade
stock ScreenFade(plr, Float:fDuration, red, green, blue, alpha)
{
    new i = plr ? plr : get_maxplayers();
    if( !i )
    {
        return 0;
    } 

    message_begin(plr ? MSG_ONE : MSG_ALL, get_user_msgid( "ScreenFade"), {0, 0, 0}, plr);
    write_short(floatround(4096.0 * fDuration, floatround_round));
    write_short(floatround(4096.0 * fDuration, floatround_round));
    write_short(4096);
    write_byte(red);
    write_byte(green);
    write_byte(blue);
    write_byte(alpha);
    message_end();
    
    return 1;
}

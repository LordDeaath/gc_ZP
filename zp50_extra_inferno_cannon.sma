#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <messages>
#include <fun>
#include <zp50_items>
#include <zp50_colorchat>
#include <zp50_gamemodes>

#include <zmvip>
// These bitsums allow 2048 entities storage. I think that it is enough :P.
new bs_array_transp[64]                // BitSum, This is equal to 64*32 bools (good for quick search)
new bs_array_solid[64]                 // BitSum, This is equal to 64*32 bools (good for quick search) 

#define add_transparent_ent(%1)         bs_array_transp[((%1 - 1) / 32)] |= (1<<((%1 - 1) % 32))
#define del_transparent_ent(%1)         bs_array_transp[((%1 - 1) / 32)] &= ~(1<<((%1 - 1) % 32))
#define  is_transparent_ent(%1)        (bs_array_transp[((%1 - 1) / 32)] & (1<<((%1 - 1) % 32)))
#define add_solid_ent(%1)               bs_array_solid[((%1 - 1) / 32)] |= (1<<((%1 - 1) % 32))
#define del_solid_ent(%1)               bs_array_solid[((%1 - 1) / 32)] &= ~(1<<((%1 - 1) % 32))
#define  is_solid_ent(%1)              (bs_array_solid[((%1 - 1) / 32)] & (1<<((%1 - 1) % 32)))

#define GENERAL_X_Y_SORROUNDING             18.5         // 16.0
#define CONSTANT_Z_CROUCH_UP                 31.25         // 32.0
#define CONSTANT_Z_CROUCH_DOWN                 17.5         // 16.0
#define CONSTANT_Z_STANDUP_UP                 34.0         // 36.0
#define CONSTANT_Z_STANDUP_DOWN             35.25         // 36.0

#define GENERAL_X_Y_SORROUNDING_HALF        9.25         // 8.0
#define GENERAL_X_Y_SORROUNDING_HALF2        12.0         // 8.0
#define CONSTANT_Z_CROUCH_UP_HALF             15.5         // 16.0
#define CONSTANT_Z_CROUCH_DOWN_HALF            8.75         // 8.0
#define CONSTANT_Z_STANDUP_UP_HALF            17.0         // 18.0
#define CONSTANT_Z_STANDUP_DOWN_HALF        17.5         // 18.0

#define ANGLE_COS_HEIGHT_CHECK                0.7071        // cos(45  degrees) 
// This is used to determine the weapon head point
new const Float:weapon_edge_point[CSW_P90+1] =
{
    0.00, 35.5, 0.00, 42.0, 0.00, 35.5, 0.00, 37.0, 37.0, 0.00, 35.5, 35.5, 32.0, 41.0, 32.0, 36.0, 41.0, 35.5, 41.0, 32.0, 37.0, 35.5, 42.0, 41.0, 44.0, 0.00, 35.5, 37.0, 32.0, 0.00, 32.0
}

// This is used as lateral multiplication array
new const Float:vec_multi_lateral[] = 
{
    GENERAL_X_Y_SORROUNDING,
    -GENERAL_X_Y_SORROUNDING,
    GENERAL_X_Y_SORROUNDING_HALF2,
    -GENERAL_X_Y_SORROUNDING_HALF
}

// This is used as height multiplicator if the user crouches!
new const Float:vec_add_height_crouch[] =
{
    CONSTANT_Z_CROUCH_UP,
    -CONSTANT_Z_CROUCH_DOWN,
    CONSTANT_Z_CROUCH_UP_HALF,
    -CONSTANT_Z_CROUCH_DOWN_HALF
}

// This is used as height multiplicator if the user stands up!
new const Float:vec_add_height_standup[] =
{
    CONSTANT_Z_STANDUP_UP,
    -CONSTANT_Z_STANDUP_DOWN,
    CONSTANT_Z_STANDUP_UP_HALF,
    -CONSTANT_Z_STANDUP_DOWN_HALF
} 

new thdl

public plugin_end()
{
    // We free it on plugin end
    free_tr2(thdl)
} 

//Plugin Start

//Configuration
#define VModel "models/zombie_plague/v_gc_inferno.mdl"
#define PModel "models/zombie_plague/p_gc_inferno.mdl"
#define WModel "models/zombie_plague/w_gc_inferno.mdl"

#define WEAPON_EVENT    "events/m249.sc"
#define WEAPON_NAME     "weapon_m249"
#define WEAPON_ID       CSW_M249
#define WEAPON_MODEL    "models/w_m249.mdl"
#define WEAPON_BITSUM   ((1<<CSW_M249))

#define MPR 0.2
#define TOGGLE_DELAY 1.0
#define MULTI_RADIUS 500.0
#define BP 200
#define CLIP 100
new Target[33]
new Combo[33]
new bool:Single[33]
new bool:HasInferno[33]
new g_event_inferno;

new ItemID;
new Purchases;

new LaserSprite

public plugin_init()
{
    register_plugin("[ZP] Extra Item: Inferno Cannon", "1.0", "zXCaptainXz")

    ItemID = zp_items_register("Inferno Cannon", "", 70)
    RegisterHam(Ham_Spawn, "player", "fw_Spawn_Post", 1)
    RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_NAME, "fw_PrimaryAttack")
    register_forward(FM_SetModel, "fw_SetModel");
    register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
    register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)	
    register_forward(FM_PlaybackEvent, "fw_PlaybackEvent");
    register_forward(FM_CmdStart, "fw_CmdStart");
    register_event("CurWeapon", "event_CurWeapon", "b", "1=1");

    register_clcmd("say gimme", "gimme")

    thdl = create_tr2()
}

new Infection, Multi

public plugin_cfg()
{
	Infection = zp_gamemodes_get_id("Infection Mode");
	Multi = zp_gamemodes_get_id("Multiple Infection Mode");
}

public zp_fw_items_select_pre(id, itemid)
{
	if(itemid != ItemID) return ZP_ITEM_AVAILABLE;
	
	if(zp_core_is_zombie(id)) return ZP_ITEM_DONT_SHOW;
	
	if(zp_gamemodes_get_current()!=Infection&&zp_gamemodes_get_current()!=Multi)
	{
		return ZP_ITEM_DONT_SHOW;
	}

	if(!(zv_get_user_flags(id)&ZV_MAIN)&&!(get_user_flags(id)&ADMIN_KICK))
	{
		zp_items_menu_text_add("\r[ADMIN/VIP]")
		return ZP_ITEM_NOT_AVAILABLE
	}

	if(HasInferno[id])
	{
		return ZP_ITEM_NOT_AVAILABLE;
	}
	
	static limit, alive, i
	alive = 0;

	for(i=1;i<33;i++)
	{
		if(is_user_alive(i))
		{
			alive++
		}
	}

	if(alive<23)
	{
		limit=1
	}
	else
	{
		limit=2
	}

	zp_items_menu_text_add(fmt("[%d/%d]",Purchases,limit))

	if(Purchases>=limit)
		return ZP_ITEM_NOT_AVAILABLE
	
	return ZP_ITEM_AVAILABLE
}

public zp_fw_items_select_post(player, itemid)
{
	if(itemid != ItemID)
		return;
	
	Purchases++;

	if(user_has_weapon(player, WEAPON_ID))
	{
		drop_primary(player);
	}

	HasInferno[player] = true

	new wpnid = give_item(player, WEAPON_NAME);    
	cs_set_weapon_ammo(wpnid, CLIP);
	cs_set_user_bpammo(player, WEAPON_ID, BP);
	zp_colored_print(player, "You bought an^3 Inferno Gun");
	zp_colored_print(player, "Press^3 Right-Mouse^1 to switch between^3 Single and Mutliple Target^1 modes");
	engclient_cmd(player, WEAPON_NAME);
}

public gimme(player)
{
    if(user_has_weapon(player, WEAPON_ID))
    {
        drop_primary(player);
    }

    HasInferno[player] = true

    new wpnid = give_item(player, WEAPON_NAME);    
    cs_set_weapon_ammo(wpnid, CLIP);
    cs_set_user_bpammo(player, WEAPON_ID, BP);
    zp_colored_print(player, "You bought an^3 Inferno Gun");
    zp_colored_print(player, "Press^3 Right-Mouse^1 to switch between^3 Single and Mutliple Target^1 modes");
    engclient_cmd(player, WEAPON_NAME);
}
public plugin_precache()
{
    precache_model(VModel);
    precache_model(PModel);
    precache_model(WModel);

    LaserSprite = precache_model("sprites/laserbeam.spr")
}

public zp_fw_gamemodes_start()
{
    Purchases = 0
}

public fw_Spawn_Post(id)
{
    Target[id] = 0
    Combo[id] = 0
    Single[id] = false
    HasInferno[id] = false;
    static player
    for(player=1;player<33;player++)
    {
        if(Target[player]==id)
        {
            Target[player] = 0
        }
    }
}

public zp_fw_core_infect_post(id)
{    
    Target[id] = 0
    Combo[id] = 0
    Single[id] = false
    HasInferno[id] = false;
    static player
    for(player=1;player<33;player++)
    {
        if(Target[player]==id)
        {
            Target[player] = 0
        }
    }
}

public fw_PrimaryAttack(weapon)
{
    static id 
    id = get_pdata_cbase(weapon, 41, 4);

    if(!HasInferno[id])
        return HAM_IGNORED;
    
    if(!cs_get_weapon_ammo(weapon))
        return HAM_SUPERCEDE;

    static player 
    static Float:origin[3]
    if(Single[id])
    {   
        get_user_aiming(id, player)

        if(is_user_alive(player)&&zp_core_is_zombie(player))
        {
            if(Target[id]==player)
            {
                Combo[id]++
            }
            else
            {
                Combo[id]=0            
                Target[id] = player;
            }

            set_pdata_float(weapon, 46, MPR, 4);
            cs_set_weapon_ammo(weapon, cs_get_weapon_ammo(weapon)-1)
            // UTIL_PlayWeaponAnimation(id, random_num(1,2))
            ExecuteHamB(Ham_TakeDamage, player, id, id, 40.0 + (Combo[id] * 8.0), DMG_BULLET);
            
            engfunc(EngFunc_GetBonePosition, player, 8, origin)

            message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
            write_byte(TE_BEAMENTPOINT)
            write_short(id | 0x1000)
            engfunc(EngFunc_WriteCoord, origin[0])
            engfunc(EngFunc_WriteCoord, origin[1])
            engfunc(EngFunc_WriteCoord, origin[2])
            write_short(LaserSprite)
            write_byte(5) //start frame
            write_byte(1) //fps
            write_byte(2) //life
            write_byte(20+2*Combo[id]) //width
            write_byte(5+Combo[id]/2) //noise
            write_byte(255) //r
            write_byte(64) //g
            write_byte(0) //b
            write_byte(Combo[id]<21?10*Combo[id]+45:255) //a
            write_byte(1) //scroll speed
            message_end();
        }
    }
    else
    {
        entity_get_vector(id, EV_VEC_origin, origin)

        static victims[5]
        static Float:radii[5]
        arrayset(victims, 0, sizeof(victims))

        static Float:radius;
        static Float:vorigin[3]
        for(player=1;player<33;player++)
        {
            if(!is_user_alive(player))continue;
            if(!zp_core_is_zombie(player))continue;

            entity_get_vector(player, EV_VEC_origin, vorigin)
            if(!is_player_visible(id, player))continue
            //if(!is_in_viewcone(id, vorigin, 1))continue
            
            radius = get_distance_f(origin, vorigin)
            if(radius>MULTI_RADIUS)continue;

            static i
            for(i=0;i<5;i++)
            {
                if(!victims[i]||radius<radii[i])
                {
                    static j
                    for(j=3;j>=i;j--)
                    {                            
                        radii[j+1]=radii[j]
                        victims[j+1]=victims[j]
                    }
                    victims[i]=player
                    radii[i]=radius
                    break;
                }
            }
        }

        for(player=0;player<5;player++)
        {
            if(!is_user_alive(victims[player]))
                break;

            ExecuteHamB(Ham_TakeDamage, victims[player], id, id, 40.0 , DMG_BULLET);

            engfunc(EngFunc_GetBonePosition, victims[player], 8, origin)
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
            write_byte(TE_BEAMENTPOINT)
            write_short(id | 0x1000)
            engfunc(EngFunc_WriteCoord, origin[0])
            engfunc(EngFunc_WriteCoord, origin[1])
            engfunc(EngFunc_WriteCoord, origin[2])
            write_short(LaserSprite)
            write_byte(5) //start frame
            write_byte(1) //fps
            write_byte(2) //life
            write_byte(20) //width
            write_byte(5) //noise
            write_byte(255) //r
            write_byte(64) //g
            write_byte(0) //b
            write_byte(150) //a
            write_byte(1) //scroll speed
            message_end();
        }

        if(player)
        {
            set_pdata_float(weapon, 46, MPR, 4);            
            cs_set_weapon_ammo(weapon, cs_get_weapon_ammo(weapon)-1)
            // UTIL_PlayWeaponAnimation(id, random_num(1,2))
        }

    }
    return HAM_SUPERCEDE;
}


public fw_PrecacheEvent_Post(type, const name[])
{
	if (equal(WEAPON_EVENT, name))
	{
		g_event_inferno = get_orig_retval()
		return FMRES_HANDLED;
	}

	return FMRES_IGNORED;
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
    if ((eventid != g_event_inferno))
      return FMRES_IGNORED;

    if (!(1 <= invoker <= 32))
        return FMRES_IGNORED;

    if(!HasInferno[invoker])
        return FMRES_IGNORED;
    
    log_amx("params %d %d", iParam1,iParam2)
    playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2);
    return FMRES_SUPERCEDE;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(is_user_alive(id) &&  get_user_weapon(id) == WEAPON_ID && HasInferno[id])
	{
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
		{
            static weapon
            weapon = cs_get_user_weapon_entity(id)
            
            if(get_pdata_int(weapon, 54, 4))
                return;
                
            set_pdata_float(weapon, 46, TOGGLE_DELAY, 4);
            UTIL_PlayWeaponAnimation(id, 5)

            if(Single[id])
            {
                Single[id] = false
                zp_colored_print(id, "^3Multiple Target^1 mode activated!")
            }
            else
            {
                Single[id] = true;        
                zp_colored_print(id, "^3Single Target^1 mode activated!")
            }
        }
	}
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, WEAPON_MODEL)) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, WEAPON_NAME, entity);
	
	if(HasInferno[owner] && pev_valid(wpn))
	{
		HasInferno[owner] = false;
		set_pev(wpn, pev_impulse, 48755);
		engfunc(EngFunc_SetModel, entity, WModel);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(is_user_alive(id) && get_user_weapon(id) == WEAPON_ID && HasInferno[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time () + 0.001);
	}
}
public event_CurWeapon(id)
{
	if (!is_user_alive(id) || zp_core_is_zombie(id)) return PLUGIN_HANDLED;
	
	if (read_data(2) == WEAPON_ID && HasInferno[id])
	{
		set_pev(id, pev_viewmodel2, VModel);
		set_pev(id, pev_weaponmodel2, PModel);
	}
	return PLUGIN_CONTINUE;
}

stock is_player_visible(visor, target)
{
    // Declarations, bla bla
    static Float:origin[3], Float:start[3], Float:end[3], Float:addict[3], Float:plane_vec[3], Float:normal[3], ignore_ent
    
    // The ignore entity is our visor at first (if needed we will change it!
    // This will be used in the point tests!
    ignore_ent = visor
    
    // First of all we check if the player is behind the visor or not
    // We get the visor origin
    pev(visor, pev_origin, origin)
    
    // We get the view angles of the visor
    pev(visor, pev_v_angle, normal)
    // We turn the angle vector into a direction vector
    angle_vector(normal, ANGLEVECTOR_FORWARD, normal)
    
    // We get the targets origin, this will be used to deremine if it the player is behind us
    pev(target, pev_origin, end)
    // We substract the two vectors to obtain a directional vector!
    xs_vec_sub(end, origin, plane_vec)
    // We normalize the vector so that we will be able to obtain the real angle between the vectors
    xs_vec_mul_scalar(plane_vec,  (1.0/xs_vec_len(plane_vec)), plane_vec)
    
    // When we multiply two vectors that are normalized (their length is 1)
    // We will obtain the cosinus of the angle between them, if this is negative then that means that the player is behind, so we return false!
    if (xs_vec_dot(plane_vec, normal) < 0)
    {
        return false
    }
    
    // We get the view offsets and we add them to the origin to obtain the eye origin
    pev(visor, pev_view_ofs, start)
    xs_vec_add(start, origin, start)
    
    // Origin becomes end
    origin = end
    
    // Until now we have 2 important vectors
    // start - that is the eye origin of the visor
    // origin - that is the target origin (usefull later)
    
    // This is used only once to update the ignore_ent
    // If point is visible then guess what, returning true!
    if (is_point_visible_texture(start, origin, ignore_ent))
        return true
    
    // This will get the view offsets of the target, we will add them to obtain the eye origin
    pev(target, pev_view_ofs, end)
    xs_vec_add(end, origin, end)
    
    // If eye origin is visible return true!
    if (is_point_visible(start, end, ignore_ent))
        return true
    
    // Check weapon point, first we need to check if it is no equal to 0
    if (weapon_edge_point[get_user_weapon(target)] != 0.00)
    {
        // We get the view angles and turn them in directional vectors
        pev(target, pev_v_angle, addict)
        angle_vector(addict, ANGLEVECTOR_FORWARD, addict)
        // We multiply it to obtain the weapon headpoint
        xs_vec_mul_scalar(addict, weapon_edge_point[get_user_weapon(target)], addict)
        // We add it to the end origin to obtain the weapon headpoint
        xs_vec_add(end, addict, end)
        
        // If weapon head is visible true!
        if (is_point_visible(start, end, ignore_ent))
            return true
    }
    
    // We subtract them to obtain o directional vector that will be used in plane calculations!
    xs_vec_sub(start, origin, normal)
    
    // We have now an extra important vector
    // normal - a directional vector between the start vector and the target origin
    
    // This is the moment when we move on to plane checks
    // These functions will create a plane that will rotate based on player position
    // The checks will be done on points that will exist on this plane!
    
    // First of all we normalize the normal vector
    // This will be important when we have height problems.
    xs_vec_mul_scalar(normal, 1.0/(xs_vec_len(normal)), normal)
    // We turn the vector into an angle vector
    vector_to_angle(normal, plane_vec)
    // This will create a vector that will be orthogonal/perpendicular with the normal vector!
    // This must be done to easily create the plane!
    angle_vector(plane_vec, ANGLEVECTOR_RIGHT, plane_vec)
    
    // This will check if we are almost at the same level with the target
    if (floatabs(normal[2]) <= ANGLE_COS_HEIGHT_CHECK)
    {
        // We check whether the target crouches
        // This is important to determine what multiplicator vector to use!
        // This will create the plane
        if (pev(target, pev_flags) & FL_DUCKING)
        {
            for (new i=0;i<4;i++)
            {
                if (i<2)
                {
                    for (new j=0;j<2;j++)
                    {
                        // We multiply the directional vector and add it to the origin after that we check if it is visible
                        // The same happens in the other places so this one will be the only one that will be commented!
                        xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
                        addict[2] = vec_add_height_crouch[j]
                        xs_vec_add(origin, addict, end)
                        
                        if (is_point_visible(start, end, ignore_ent))
                            return true
                    }
                }
                else
                {
                    for (new j=2;j<4;j++)
                    {
                        xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
                        addict[2] = vec_add_height_crouch[j]
                        xs_vec_add(origin, addict, end)
                        
                        if (is_point_visible(start, end, ignore_ent))
                            return true
                    }
                }
            }
        }
        else
        {
            for (new i=0;i<4;i++)
            {
                if (i<2)
                {
                    for (new j=0;j<2;j++)
                    {
                        xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
                        addict[2] = vec_add_height_standup[j]
                        xs_vec_add(origin, addict, end)
                        
                        if (is_point_visible(start, end, ignore_ent))
                            return true
                    }
                }
                else
                {
                    for (new j=2;j<4;j++)
                    {
                        xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
                        addict[2] = vec_add_height_standup[j]
                        xs_vec_add(origin, addict, end)
                        
                        if (is_point_visible(start, end, ignore_ent))
                            return true
                    }
                }
            }
        }
    }
    else
    {
        // This is the same as the one above
        // The only difference is that it also uses normal vector to move the points in front and in behind!
        // Here is checked if you are above the player
        if (normal[2] > 0.0)
        {
            normal[2] = 0.0
            xs_vec_mul_scalar(normal, 1/(xs_vec_len(normal)), normal)
        
            if (pev(target, pev_flags) & FL_DUCKING)
            {
                for (new i=0;i<4;i++)
                {
                    if (i<2)
                    {
                        for (new j=0;j<2;j++)
                        {
                            xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
                            addict[2] = vec_add_height_crouch[j]
                            xs_vec_add(origin, addict, end)
                            xs_vec_mul_scalar(normal, (j == 0) ? (-GENERAL_X_Y_SORROUNDING) : (GENERAL_X_Y_SORROUNDING), addict)
                            xs_vec_add(end, addict, end)
                            
                            if (is_point_visible(start, end, ignore_ent))
                                return true
                        }
                    }
                    else
                    {
                        for (new j=2;j<4;j++)
                        {
                            xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
                            addict[2] = vec_add_height_crouch[j]
                            xs_vec_add(origin, addict, end)
                            
                            if (is_point_visible(start, end, ignore_ent))
                                return true
                        }
                    }
                }
            }
            else
            {
                for (new i=0;i<4;i++)
                {
                    if (i<2)
                    {
                        for (new j=0;j<2;j++)
                        {
                            xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
                            addict[2] = vec_add_height_standup[j]
                            xs_vec_add(origin, addict, end)
                            xs_vec_mul_scalar(normal, (j == 0) ? (-GENERAL_X_Y_SORROUNDING) : (GENERAL_X_Y_SORROUNDING), addict)
                            xs_vec_add(end, addict, end)
                            
                            if (is_point_visible(start, end, ignore_ent))
                                return true
                        }
                    }
                    else
                    {
                        for (new j=2;j<4;j++)
                        {
                            xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
                            addict[2] = vec_add_height_standup[j]
                            xs_vec_add(origin, addict, end)
                            
                            if (is_point_visible(start, end, ignore_ent))
                                return true
                        }
                    }
                }
            }
        }
        else
        {
            normal[2] = 0.0
            xs_vec_mul_scalar(normal, 1/(xs_vec_len(normal)), normal)
            
            if (pev(target, pev_flags) & FL_DUCKING)
            {
                for (new i=0;i<4;i++)
                {
                    if (i<2)
                    {
                        for (new j=0;j<2;j++)
                        {
                            xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
                            addict[2] = vec_add_height_crouch[j]
                            xs_vec_add(origin, addict, end)
                            xs_vec_mul_scalar(normal, (j == 0) ? GENERAL_X_Y_SORROUNDING : (-GENERAL_X_Y_SORROUNDING), addict)
                            xs_vec_add(end, addict, end)
                            
                            if (is_point_visible(start, end, ignore_ent))
                                return true
                        }
                    }
                    else
                    {
                        for (new j=2;j<4;j++)
                        {
                            xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
                            addict[2] = vec_add_height_crouch[j]
                            xs_vec_add(origin, addict, end)
                            
                            if (is_point_visible(start, end, ignore_ent))
                                return true
                        }
                    }
                }
            }
            else
            {
                for (new i=0;i<4;i++)
                {
                    if (i<2)
                    {
                        for (new j=0;j<2;j++)
                        {
                            xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
                            addict[2] = vec_add_height_standup[j]
                            xs_vec_add(origin, addict, end)
                            xs_vec_mul_scalar(normal, (j == 0) ? GENERAL_X_Y_SORROUNDING : (-GENERAL_X_Y_SORROUNDING), addict)
                            xs_vec_add(end, addict, end)
                            
                            if (is_point_visible(start, end, ignore_ent))
                                return true
                        }
                    }
                    else
                    {
                        for (new j=2;j<4;j++)
                        {
                            xs_vec_mul_scalar(plane_vec, vec_multi_lateral[i], addict)
                            addict[2] = vec_add_height_standup[j]
                            xs_vec_add(origin, addict, end)
                            
                            if (is_point_visible(start, end, ignore_ent))
                                return true
                        }
                    }
                }
            }
        }
    }
    
    // None visible? 
    return false
} 
// This function checks if a point is visible from start to point! It will ignore glass and players! Also it will ignore the ignore_ent!
bool:is_point_visible(const Float:start[3], const Float:point[3], ignore_ent)
{
    engfunc(EngFunc_TraceLine, start, point, IGNORE_GLASS | IGNORE_MONSTERS, ignore_ent, thdl)

    static Float:fraction
    get_tr2(thdl, TR_flFraction, fraction)
    
    // We will return the fraction
    // If 1.0 that means that we didn't hit anything
    return (fraction == 1.0)
}

// This function is the same as above but will also check if the entity that we hited can be seen through
bool:is_point_visible_texture(const Float:start[3], const Float:point[3], ignore_ent)
{
    engfunc(EngFunc_TraceLine, start, point, IGNORE_GLASS | IGNORE_MONSTERS, ignore_ent, thdl)
    
    // We save also the entity
    static ent
    ent = get_tr2(thdl, TR_pHit)

    static Float:fraction
    get_tr2(thdl, TR_flFraction, fraction)
    
    // If we hit something start the checks
    if (fraction != 1.0 && ent > 0)
    {
        // That means that we didn't know what we hited
        if (!is_transparent_ent(ent) && !is_solid_ent(ent))
        {
            static texture_name[2]
            static Float:vec[3]
            // These calculations are made for security measures
            // TraceTexture function will crash the server if used on short distances
            xs_vec_sub(point, start, vec)
            xs_vec_mul_scalar(vec, (5000.0 / xs_vec_len(vec)), vec)
            xs_vec_add(start, vec, vec)
            
            engfunc(EngFunc_TraceTexture, ent, start, vec, texture_name, charsmax(texture_name))
            
            // If texture_name begins with { that means that we have a trasnaparent texture, 
            // if yes we will retrace and add that entity to our list as a transparent! 
            // If not then we add id as solid so it will not be needed to do the checks again!
            if (equal(texture_name, "{"))
            {
                add_transparent_ent(ent)
                ignore_ent = ent
                engfunc(EngFunc_TraceLine, start, point, IGNORE_GLASS | IGNORE_MONSTERS, ignore_ent, thdl)
                get_tr2(thdl, TR_flFraction, fraction)
                return (fraction == 1.0)
            }
            else
            {
                add_solid_ent(ent)
                return (fraction == 1.0)
            }
        }
        // This means that the entity is registered as solid or transparent so on with the checks
        else
        {
            if (is_solid_ent(ent))
            {
                return (fraction == 1.0)
            }
            else
            {
                ignore_ent = ent
                engfunc(EngFunc_TraceLine, start, point, IGNORE_GLASS | IGNORE_MONSTERS, ignore_ent, thdl)
                get_tr2(thdl, TR_flFraction, fraction)
                return (fraction == 1.0)
            }
        }
    }
    
    return (fraction == 1.0)
} 

// This will add two vectors
stock xs_vec_add(const Float:in1[], const Float:in2[], Float:out[])
{
    out[0] = in1[0] + in2[0];
    out[1] = in1[1] + in2[1];
    out[2] = in1[2] + in2[2];
}

// This will substract two vectors
stock xs_vec_sub(const Float:in1[], const Float:in2[], Float:out[])
{
    out[0] = in1[0] - in2[0];
    out[1] = in1[1] - in2[1];
    out[2] = in1[2] - in2[2];
}

// This will multiply a vector with a scalar
stock xs_vec_mul_scalar(const Float:vec[], Float:scalar, Float:out[])
{
    out[0] = vec[0] * scalar;
    out[1] = vec[1] * scalar;
    out[2] = vec[2] * scalar;
}

// This will return the vector length
stock Float:xs_vec_len(const Float:vec[3])
{
    return floatsqroot(vec[0]*vec[0] + vec[1]*vec[1] + vec[2]*vec[2]);
}

// This will make a scalar multiplication between two vectors
stock Float:xs_vec_dot(const Float:vec[], const Float:vec2[])
{
    return (vec[0]*vec2[0] + vec[1]*vec2[1] + vec[2]*vec2[2])
}

//My Stocks
stock drop_primary(id)
{
	new weapons[32], num;
	get_user_weapons(id, weapons, num);
	for (new i = 0; i < num; i++)
	{
		if (WEAPON_BITSUM & (1<<weapons[i]))
		{
			static wname[32];
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname);
		}
	}
}
stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player);
	write_byte(Sequence);
	write_byte(pev(Player, pev_body));
	message_end();
}
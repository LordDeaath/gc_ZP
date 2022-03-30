#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zp50_core>
#include <zp50_items>
#include <fun>
#include <zmvip>
#include <zp50_class_sniper>
#include <zp50_gamemodes>
#include <zp50_class_survivor>
#include <zp50_colorchat>

new g_TmpClip[33]
native zp_class_hunter_get(id)

// Plug info.
#define PLUG_VERSION "1.0"
#define PLUG_AUTH "H.RED.ZONE"

#define is_valid_player(%1) (1 <= %1 <= 32)

// Items Cost

const GoldenAWP_weapon_cost = 30  // Cost

//----------------
new g_iItemID, g_itemid_vip
new bullets[ 33 ]

new g_HasGoldenAWPWeapon[33], g_CurrentWeapon[33]

// Cvars
new cvar_enable, cvar_oneround, cvar_goldbullets, cvar_uclip,cvar_thunder_clip

// Offsets
const m_pPlayer = 		41
const m_flNextPrimaryAttack = 	46
const m_flNextSecondaryAttack =	47
const m_flTimeWeaponIdle = 	48

// Sprite
new m_spriteTexture
new Thunder

new const thunder_sound[] = "ambience/thunder_clap.wav";

new Purchases,MyAkLimit;

public plugin_init()
{
	//Register the Plugin
	register_plugin("[ZP] Extra Item: GoldenAWP", "1.0", "H.RED.ZONE")
	
	//Cvars
	cvar_enable = register_cvar("zp_GoldenAWP_enable", "1")
	cvar_oneround = register_cvar("zp_GoldenAWP_oneround", "1")
	cvar_goldbullets = register_cvar("zp_GoldenAWP_gold_bullets", "1")
	cvar_uclip = register_cvar("zp_GoldenAWP_unlimited_clip", "0")	
	cvar_thunder_clip = register_cvar("zp_GoldenAWP_clip", "5");
	//cvar_dmgmultiplier = register_cvar("zp_GoldenAWP_dmg_multiplier", "1.8")
	
	//Register Zombie Plague extra item
	g_iItemID = zp_items_register("Thunder AWP", "x3 DMG", 70, 1, 1)
	g_itemid_vip = zv_register_extra_item("Thunder AWP", "10 Ammo Packs",10,ZV_TEAM_HUMAN);
	//Hamsandwich
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	

	//Events
	register_event("CurWeapon", "event_CurWeapon", "b", "1=1")	
	
	
	register_forward(FM_SetModel, "fw_SetModel");	
	RegisterHam(Ham_Item_AddToPlayer, "weapon_awp", "fw_AddToPlayer");

	
	RegisterHam(Ham_Weapon_Reload, "weapon_awp", "fw_Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_awp", "fw_Reload_Post", 1);	
	RegisterHam(Ham_Item_PostFrame, "weapon_awp", "fw_ItemPostFrame");
}

new Infection, Multi
public plugin_cfg()
{
	Infection = zp_gamemodes_get_id("Infection Mode");
	Multi = zp_gamemodes_get_id("Multiple Infection Mode");
}

public plugin_precache()
{	precache_sound( thunder_sound );
	// Models
	precache_model("models/zombie_plague/v_thunder_gc.mdl")
	precache_model("models/zombie_plague/p_thunder_gc.mdl")
	precache_model("models/zombie_plague/w_thunder_gc.mdl")
	Thunder = precache_model("sprites/light_effect.spr");
}

public plugin_natives()
{
	register_native("zp_thunder_get","native_thunder_get",1)
}

public native_thunder_get(id)
{
	return g_HasGoldenAWPWeapon[id];
}
public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_awp.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName))
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn
	owner = pev(entity, pev_owner)
	wpn = find_ent_by_owner(-1, "weapon_awp", entity)
	
	if(g_HasGoldenAWPWeapon[owner] && pev_valid(wpn))
	{
		g_HasGoldenAWPWeapon[owner] = false;
		set_pev(wpn, pev_impulse, 10346);	
		engfunc(EngFunc_SetModel, entity, "models/zombie_plague/w_thunder_gc.mdl");	
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_AddToPlayer(wpn, id)
{
	if(pev_valid(wpn) && is_user_connected(id) && pev(wpn, pev_impulse) == 10346)
	{
		g_HasGoldenAWPWeapon[id] = true;
		set_pev(wpn, pev_impulse, 0);
		
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}
public event_CurWeapon(id)
{
	// Not Alive
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE
	
	// Store weapon
	g_CurrentWeapon[id] = read_data(2)
	
	// Check
	if(zp_core_is_zombie(id))
		return PLUGIN_CONTINUE
	
	// Has GoldenAWP
	if(!g_HasGoldenAWPWeapon[id] || g_CurrentWeapon[id] != CSW_AWP) 
		return PLUGIN_CONTINUE
	
	entity_set_string(id, EV_SZ_viewmodel, "models/zombie_plague/v_thunder_gc.mdl")
	entity_set_string(id, EV_SZ_weaponmodel, "models/zombie_plague/p_thunder_gc.mdl")
	
	return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
	g_HasGoldenAWPWeapon[id] = false
}

public client_disconnected(id)
{
	g_HasGoldenAWPWeapon[id] = false
}
public fw_PlayerSpawn_Post(id)
{
	// Remove Weapon
	if(get_pcvar_num(cvar_oneround) || !get_pcvar_num(cvar_enable))
	{
		if(g_HasGoldenAWPWeapon[id])
		{
			g_HasGoldenAWPWeapon[id] = false;
			ham_strip_weapon(id, "weapon_awp")
		}
	}
}


stock ham_strip_weapon(id, weapon[])
{
	if(!equal(weapon,"weapon_",7)) 
		return 0
	
	new wId = get_weaponid(weapon)
	
	if(!wId) return 0
	
	new wEnt
	
	while((wEnt = find_ent_by_class(wEnt, weapon)) && entity_get_edict(wEnt, EV_ENT_owner) != id) {}
	
	if(!wEnt) return 0
	
	if(get_user_weapon(id) == wId) 
		ExecuteHamB(Ham_Weapon_RetireWeapon,wEnt);
	
	if(!ExecuteHamB(Ham_RemovePlayerItem,id,wEnt)) 
		return 0
	
	ExecuteHamB(Ham_Item_Kill, wEnt)
	
	entity_set_int(id, EV_INT_weapons, entity_get_int(id, EV_INT_weapons) & ~(1<<wId))
	
	return 1
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage,bits){
	const m_LastHitGroup = 75;
	//const m_LastHitGroup = 75
	if ( is_valid_player( attacker ) && get_user_weapon(attacker) == CSW_AWP && g_HasGoldenAWPWeapon[attacker]&& (bits&DMG_BULLET))
	{
		if(is_user_alive(victim)&&zp_core_is_zombie(victim))
		{
			
			if (get_pdata_int( victim , m_LastHitGroup ) == HIT_HEAD||(get_user_health(victim)<=300.0) ) 
			{
				if(get_pdata_int( victim , m_LastHitGroup ) == HIT_HEAD)
				SetHamParamFloat(4, 800.0)
				else
				SetHamParamFloat(4, 300.0)
				//get target's origin
				new vorigin[ 3 ], pos[ 3 ]
				get_user_origin( victim, vorigin )
		
				// modify origins
				vorigin[ 2 ] -= 26
				pos[ 0 ] = vorigin[ 0 ] + 150
				pos[ 1 ] = vorigin[ 1 ] + 150
				pos[ 2 ] = vorigin[ 2 ] + 800
				//create lightning bolt
				Do_Thunder(pos,vorigin)

				new vic = -1
				new corigin[3]
				new Float:origin[3]
				origin[0]=float(vorigin[0])
				origin[1]=float(vorigin[1])
				origin[2]=float(vorigin[2])
				while ((vic = engfunc(EngFunc_FindEntityInSphere, vic, origin, 200.0)) != 0)
				{
					if(vic==victim)
						continue;

					if (!is_user_alive(vic))
					{
						continue;
					}
					if(!zp_core_is_zombie(vic))
						continue;
					
					if(zp_class_hunter_get(vic))
						continue;
						
					get_user_origin( vic, corigin )
					//create lightning bolt
					Do_Thunder(vorigin,corigin)							
					ExecuteHamB(Ham_TakeDamage, vic, attacker, attacker, 200.0, DMG_SHOCK)
				}
			}
			else 
			{
				SetHamParamFloat(4, 300.0)
			}
		}
	}
}
public zp_user_infected_post(id)
{
	// Has a Golden Weapon
	if(g_HasGoldenAWPWeapon[id])
		g_HasGoldenAWPWeapon[id] = false
}

public zp_user_humanized_post(id)
{
	// Has a Golden Weapon
	if(g_HasGoldenAWPWeapon[id])
		g_HasGoldenAWPWeapon[id] = false;
}
stock ham_give_weapon(id, weapon[])
{
	if(!equal(weapon,"weapon_",7)) 
		return 0
	
	new wEnt = create_entity(weapon)
	
	if(!is_valid_ent(wEnt)) 
		return 0
	
	entity_set_int(wEnt, EV_INT_spawnflags, SF_NORESPAWN)
	DispatchSpawn(wEnt)
	
	if(!ExecuteHamB(Ham_AddPlayerItem,id,wEnt))
	{
		if(is_valid_ent(wEnt)) entity_set_int(wEnt, EV_INT_flags, entity_get_int(wEnt, EV_INT_flags) | FL_KILLME)
		return 0
	}
	
	ExecuteHamB(Ham_Item_AttachToPlayer,wEnt,id)
	return 1
}

public zp_fw_gamemodes_start()
{
	Purchases = 0;
}
public zp_fw_items_select_pre(id, i , c)
{
	if(i != g_iItemID)
		return ZP_ITEM_AVAILABLE
	
	if(zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW
	
	if(zp_class_survivor_get(id))
		return ZP_ITEM_DONT_SHOW;

	if(g_HasGoldenAWPWeapon[id])
		return ZP_ITEM_NOT_AVAILABLE;
		
	if(AlivCount() >= 22)
		MyAkLimit = 3
	else MyAkLimit = 2
	new Txt[32]
	format(Txt,charsmax(Txt),"[%d/%d]",Purchases,MyAkLimit)
	zp_items_menu_text_add(Txt)

	
	if(zp_gamemodes_get_current()!=Infection&&zp_gamemodes_get_current()!=Multi)
		MyAkLimit = 2
		
	if(Purchases>=MyAkLimit)
		return ZP_ITEM_NOT_AVAILABLE
/*
	if(zp_gamemodes_get_current()!=Infection&&zp_gamemodes_get_current()!=Multi)
	{
		if(Purchases>0)
		{
			zp_items_menu_text_add("[1/1]")
			return ZP_ITEM_NOT_AVAILABLE;
		}
		zp_items_menu_text_add("[0/1]");
		return ZP_ITEM_AVAILABLE;
	}

	if(Purchases>1)
	{
		zp_items_menu_text_add("[2/2]")
		return ZP_ITEM_NOT_AVAILABLE;
	}

	zp_items_menu_text_add(!Purchases?"[0/2]":"[1/2]")
*/
	return ZP_ITEM_AVAILABLE
}
public zp_fw_items_select_post(id, i, c)
{
	if(i != g_iItemID)
		return;

	Purchases++;
	engclient_cmd(id, "drop", "weapon_awp")
	new weaponid = give_item(id, "weapon_awp")			
	cs_set_weapon_ammo(weaponid, get_pcvar_num(cvar_thunder_clip));
	cs_set_user_bpammo(id, CSW_AWP, 30);
	g_HasGoldenAWPWeapon[id] = true;
	engclient_cmd(id, "weapon_awp")	
	zp_colored_print(id, "You bought a^3 Thunder AWP")
}
AlivCount()
{
	new AlivePlayers
	for(new i=1; i < 32;i++)
	{
		if(!is_user_alive(i))
			continue
		AlivePlayers++
	}
	return AlivePlayers;
}
public zv_extra_item_selected(id, itemid)
{
	if(itemid != g_itemid_vip)
		return;	

	engclient_cmd(id, "drop", "weapon_awp")
	new weaponid = give_item(id, "weapon_awp")			
	cs_set_weapon_ammo(weaponid, get_pcvar_num(cvar_thunder_clip));
	cs_set_user_bpammo(id, CSW_AWP, 30);
	g_HasGoldenAWPWeapon[id] = true;
	engclient_cmd(id, "weapon_awp")	
	zp_colored_print(id, "You bought a^3 Thunder AWP")
}

public fw_Reload(weapon_entity)
{
	new id = pev(weapon_entity,pev_owner);
	if (!is_user_connected(id) || (!g_HasGoldenAWPWeapon[id]&&!zp_class_sniper_get(id)))
	{
		return 1;
	}
	g_TmpClip[id] = -1;
	new iBpAmmo = cs_get_user_bpammo(id, CSW_AWP);
	new iClip = get_pdata_int(weapon_entity, 51, 4);
	if (0 >= iBpAmmo)
	{
		return 4;
	}
	if (get_pcvar_num(cvar_thunder_clip) <= iClip)
	{
		return 4;
	}

	g_TmpClip[id] = iClip;
	return 1;
}

public fw_ItemPostFrame(weapon_entity)
{
	new id = pev(weapon_entity, pev_owner);

	if((!g_HasGoldenAWPWeapon[id]&&!zp_class_sniper_get(id)) || !is_user_connected(id) || !pev_valid(weapon_entity))
		return HAM_IGNORED;

	static iClipExtra; iClipExtra = get_pcvar_num(cvar_thunder_clip);

	new Float:flNextAttack = get_pdata_float(id, 83, 5);

	new iBpAmmo = cs_get_user_bpammo(id, CSW_AWP);
	new iClip = get_pdata_int(weapon_entity, 51, 4);

	new fInReload = get_pdata_int(weapon_entity, 54, 4);

	if(fInReload && flNextAttack <= 0.0)
	{
		new Clp = min(iClipExtra - iClip, iBpAmmo);
		set_pdata_int(weapon_entity, 51, iClip + Clp, 4);
		cs_set_user_bpammo(id, CSW_AWP, iBpAmmo-Clp);
		set_pdata_int(weapon_entity, 54, 0, 4);
		fInReload = 0;

		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}
public fw_Reload_Post(weapon_entity)
{
	new id = pev(weapon_entity,pev_owner);
	if (!is_user_connected(id) ||(!g_HasGoldenAWPWeapon[id]&&!zp_class_sniper_get(id)))
	{
		return 1;
	}
	if (g_TmpClip[id] == -1)
	{
		return 1;
	}
	set_pdata_int(weapon_entity, 51, g_TmpClip[id], 4);
	set_pdata_int(weapon_entity, 54, 1, 4);
	return 1;
}

public make_tracer(id)
{
	if (get_pcvar_num(cvar_goldbullets))
	{
		new clip,ammo
		new wpnid = get_user_weapon(id,clip,ammo)
		new pteam[16]
		
		get_user_team(id, pteam, 15)
		
		if ((bullets[id] > clip) && (wpnid == CSW_AWP) && g_HasGoldenAWPWeapon[id]) 
		{
			new vec1[3], vec2[3]
			get_user_origin(id, vec1, 1) // origin; your camera point.
			get_user_origin(id, vec2, 4) // termina; where your bullet goes (4 is cs-only)
			
			
			//BEAMENTPOINTS
			message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte (0)     //TE_BEAMENTPOINTS 0
			write_coord(vec1[0])
			write_coord(vec1[1])
			write_coord(vec1[2])
			write_coord(vec2[0])
			write_coord(vec2[1])
			write_coord(vec2[2])
			write_short( m_spriteTexture )
			write_byte(1) // framestart
			write_byte(5) // framerate
			write_byte(2) // life
			write_byte(10) // width
			write_byte(0) // noise
			write_byte( 255 )     // r, g, b
			write_byte( 215 )       // r, g, b
			write_byte( 0 )       // r, g, b
			write_byte(200) // brightness
			write_byte(150) // speed
			message_end()
		}
	
		bullets[id] = clip
	}
	
}
public checkWeapon(id)
{
	new plrClip, plrAmmo, plrWeap[32]
	new plrWeapId
	
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	if (plrWeapId == CSW_AWP && g_HasGoldenAWPWeapon[id])
	{
		return PLUGIN_CONTINUE
	}
	
	if (plrClip == 0 && get_pcvar_num(cvar_uclip))
	{
		// If the user is out of ammo..
		get_weaponname(plrWeapId, plrWeap, 31)
		// Get the name of their weapon
		ham_give_weapon(id, plrWeap)
		engclient_cmd(id, plrWeap) 
		engclient_cmd(id, plrWeap)
		engclient_cmd(id, plrWeap)
	}
	return PLUGIN_HANDLED
}

Do_Thunder( start[ 3 ], end[ 3 ] )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY ); 
	write_byte( TE_BEAMPOINTS ); 
	write_coord( start[ 0 ] ); 
	write_coord( start[ 1 ] ); 
	write_coord( start[ 2 ] ); 
	write_coord( end[ 0 ] ); 
	write_coord( end[ 1 ] ); 
	write_coord( end[ 2 ] ); 
	write_short( Thunder ); 
	write_byte( 1 );
	write_byte( 5 );
	write_byte( 7 );
	write_byte( 20 );
	write_byte( 30 );
	write_byte( 200 ); 
	write_byte( 200 );
	write_byte( 200 );
	write_byte( 200 );
	write_byte( 200 );
	message_end();
	
	message_begin( MSG_PVS, SVC_TEMPENTITY, end );
	write_byte( TE_SPARKS );
	write_coord( end[ 0 ]  );
	write_coord( end[ 1 ]);
	write_coord( end[ 2 ] );
	message_end();
	
	emit_sound( 0 ,CHAN_ITEM, thunder_sound, 1.0, ATTN_NORM, 0, PITCH_NORM );
}

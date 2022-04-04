/*================================================================================
	
	--------------------------------
	-*- [ZP] Game Mode: Hot Potato -*-
	--------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <amx_settings_api>
#include <zp50_gamemodes>
#include <zp50_ammopacks>
#include <zp50_colorchat>
#include <hamsandwich>
#include <xs>
#include <zp50_class_zombie>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_hot_potato[][] = { "zombie_plague/survivor1.wav" , "zombie_plague/survivor2.wav" }

#define SOUND_MAX_LENGTH 64

new Array:g_sound_hot_potato

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 20
#define HUD_EVENT_G 255
#define HUD_EVENT_B 20

new g_MaxPlayers
new g_HudSync

new cvar_hot_potato_chance, cvar_hot_potato_min_players
new cvar_hot_potato_show_hud, cvar_hot_potato_sounds
new cvar_hot_potato_allow_respawn

new bool:HasGrenade[33]

new sounds[][]={"fvox/one.wav","fvox/two.wav","fvox/three.wav","fvox/four.wav","fvox/five.wav","fvox/six.wav","fvox/seven.wav","fvox/eight.wav","fvox/nine.wav","fvox/ten.wav"}

new spr_beam, explosion;

public plugin_end()
{
	ArrayDestroy(g_sound_hot_potato)
}

public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Hot Potato", ZP_VERSION_STRING, "ZP Dev Team")

	spr_beam = precache_model( "sprites/laserbeam.spr" );
	for(new i=0;i<sizeof(sounds);i++)
	{
		precache_sound(sounds[i])
	}

	explosion = precache_model("sprites/zerogxplode.spr")	
	precache_sound("weapons/mortarhit.wav")

	zp_gamemodes_register("Hot Potato Mode")
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_hot_potato_chance = register_cvar("zp_hot_potato_chance", "1")
	cvar_hot_potato_min_players = register_cvar("zp_hot_potato_min_players", "2")
	cvar_hot_potato_show_hud = register_cvar("zp_hot_potato_show_hud", "1")
	cvar_hot_potato_sounds = register_cvar("zp_hot_potato_sounds", "1")
	cvar_hot_potato_allow_respawn = register_cvar("zp_hot_potato_allow_respawn", "0")
	
	// Initialize arrays
	g_sound_hot_potato = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND HOT POTATO", g_sound_hot_potato)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_hot_potato) == 0)
	{
		for (index = 0; index < sizeof sound_hot_potato; index++)
			ArrayPushString(g_sound_hot_potato, sound_hot_potato[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND HOT POTATO", g_sound_hot_potato)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_hot_potato); index++)
	{
		ArrayGetString(g_sound_hot_potato, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
}

// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_hot_potato_allow_respawn))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(id)
{
	// Always respawn as zombie on hot potato rounds
	zp_core_respawn_as_zombie(id, true)
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_hot_potato_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// Min players
		if (GetAliveCount() < get_pcvar_num(cvar_hot_potato_min_players))
			return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_start()
{	
	// server_cmd("humans_join_team CT");
	server_cmd("mp_round_infinite 1");
	server_cmd("mp_unduck_method 1");
	server_cmd("sv_airaccelerate 10");
	zp_colored_print(0, "^3Double-duck^1 is^3 Disabled^1 and ^3sv_airaccelerate^1 =^3 10")
	// Turn the players into zombies
	new id, class
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Not alive
		if (!is_user_alive(id))
			continue;
		
		// Already a zombie
		if (zp_core_is_zombie(id))
			continue;
		
		class = zp_class_zombie_get_next(id)
		zp_class_zombie_set_next(id, 0)
		zp_core_infect(id)
		if(class>0)
		zp_class_zombie_set_next(id, class)
	}
	
	// Play Hot Potato sound
	if (get_pcvar_num(cvar_hot_potato_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_hot_potato, random_num(0, ArraySize(g_sound_hot_potato) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_hot_potato_show_hud))
	{
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "Hot Potato Mode!!!")
	}

	register_touch("grenade","*","fw_touch")
	RegisterHam(Ham_Killed, "player", "fw_Killed")
	RegisterHam(Ham_Killed, "player", "fw_KilledPost",1)
	register_think("grenade","fw_think")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_AddToFullPack, "fw_addToFullPack", 1)	
	arrayset(HasGrenade, false, sizeof(HasGrenade))
	set_task(3.0, "start", _,{0},1)
}

// Forward Set Model
public fw_SetModel(entity, const model[])
{
	// We don't care
	if (strlen(model) < 8)
		return;
	
	// Narrow down our matches a bit
	if (model[7] != 'w' || model[8] != '_')
		return;
	
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Grenade not yet thrown
	if (dmgtime == 0.0)
		return;
	
	// HE Grenade
	if (model[9] == 'h' && model[10] == 'e')
	{
		new Float:velocity[3]
		pev(entity, pev_velocity, velocity)
		xs_vec_mul_scalar(velocity, 2.0, velocity)
		set_pev(entity, pev_velocity, velocity)
	}
}

public zp_fw_gamemodes_end()
{
	// server_cmd("humans_join_team ANY");
	server_cmd("mp_round_infinite 0");
	server_cmd("mp_unduck_method 0");
	server_cmd("sv_airaccelerate 1000");
	remove_task()
}

public fw_addToFullPack(es_handle, e, ent, host, hostflags, player, pSet)
{
	if(!player) 
		return FMRES_IGNORED

	if(!HasGrenade[host]&&is_user_alive(host))
		return FMRES_IGNORED;
	
	if(!is_user_alive(ent))
		return FMRES_IGNORED;
	
	if(!HasGrenade[ent])
		return FMRES_IGNORED;
		
	set_es(es_handle,ES_RenderFx, kRenderFxGlowShell)
	set_es(es_handle,ES_RenderColor, {255, 0, 0})
	set_es(es_handle,ES_RenderMode,kRenderTransAlpha)

	return FMRES_IGNORED
} 
public fw_touch(touched, toucher)
{
	if(!is_valid_ent(touched))
		return;
		
	if(!is_user_alive(toucher))
	{
		return;
	}

	if(HasGrenade[toucher])
	{
		return;
	}

	give_item(toucher, "weapon_hegrenade");
	HasGrenade[toucher] = true
	new owner = entity_get_edict(touched, EV_ENT_owner)
	if(is_user_alive(owner))
	{
		HasGrenade[owner] = false;
		new name1[32],name2[32];
		get_user_name(toucher, name1, charsmax(name1))
		get_user_name(owner, name2, charsmax(name2))
		zp_colored_print(owner, "You hit^3 %s^1 with an^3 Infection Bomb!^1", name1)
		zp_colored_print(toucher, "^3%s^1 hit you with an^3Infection Bomb!", name2)
		zp_colored_print(toucher, "Throw it at a^3 Non-Glowing Zombie^1 or you will^3 Explode!")
	}
	remove_entity(touched)
}

public fw_think(entity)
{
	// Invalid entity
	if (!is_valid_ent(entity)) return PLUGIN_CONTINUE;
	
	entity_set_size(entity, Float:{-8.0,-8.0,-8.0}, Float:{8.0,8.0,8.0});

	// Get damage time of grenade
	static Float:dmgtime
	//pev(entity, pev_dmgtime, dmgtime)
	dmgtime = entity_get_float(entity, EV_FL_dmgtime)
	// Check if it's time to go off
	if (dmgtime > get_gametime())
		return PLUGIN_CONTINUE;
	
	return_to_owner(entity)		
	return PLUGIN_CONTINUE;
}

public return_to_owner(entity)
{
	new owner = entity_get_edict(entity, EV_ENT_owner)

	if(!is_user_alive(owner))
		return;
	
	give_item(owner, "weapon_hegrenade");
}

public start(param[1])
{
	if(param[0])
	{
		// Play Hot Potato sound
		if (get_pcvar_num(cvar_hot_potato_sounds))
		{
			new sound[SOUND_MAX_LENGTH]
			ArrayGetString(g_sound_hot_potato, random_num(0, ArraySize(g_sound_hot_potato) - 1), sound, charsmax(sound))
			PlaySoundToClients(sound)
		}
	}
	
	new count = GetAliveCount()/2

	new players[32],num

	get_players(players, num, "a")

	new temp, rand;

	for(new i;i<num;i++)
	{
		rand = random(num)
		temp = players[rand]
		players[rand] = players[i]
		players[i] = temp;
	}
	for(new i;i<count;i++)
	{
		give_item(players[i], "weapon_hegrenade");
		HasGrenade[players[i]] = true;
		zp_colored_print(players[i], "You have an^3 Infection Bomb^1. Throw it at a^3 Non-Glowing Zombie^1 or you will^3 Explode!")
	}
	
	new count2=1
	count = GetAliveCount()
	while(count>2)
	{				
		count -= count/2
		count2++
	}

	set_dhudmessage(255, 0, 0, -1.0, 0.3)

	if(count2>1)
		show_dhudmessage(0, "%d Rounds Left...",count2)
	else
		show_dhudmessage(0, "Final Round!")

	set_task(30.0,"kill")
	set_task(20.0, "countdown",_,{10},1)
	set_task(21.0, "countdown",_,{9},1)
	set_task(22.0, "countdown",_,{8},1)
	set_task(23.0, "countdown",_,{7},1)
	set_task(24.0, "countdown",_,{6},1)
	set_task(25.0, "countdown",_,{5},1)
	set_task(26.0, "countdown",_,{4},1)
	set_task(27.0, "countdown",_,{3},1)
	set_task(28.0, "countdown",_,{2},1)
	set_task(29.0, "countdown",_,{1},1)
}

public countdown(param[1])
{
	new message[192]
	switch(param[0])
	{
		case 10,9:
		{
			formatex(message, charsmax(message),"Bombs Explode in ^n-= %d =-",param[0]);set_hudmessage(0, 255, 255, -1.0, 0.3, 0, 0.02, 0.8, 0.01, 0.1, -1);
			for(new id=1;id<33;id++)
			{
				if(is_user_alive(id)&&HasGrenade[id])
				{
					client_cmd(id, "spk ^"weapons/c4_beep1.wav^"")
				}
			}
		}
		case 8,7:
		{
			formatex(message, charsmax(message),"Bombs Explode in ^n-= %d =-",param[0]);set_hudmessage(0, 255, 0, -1.0, 0.3, 2, 0.02, 0.8, 0.01, 0.1, -1);
			for(new id=1;id<33;id++)
			{
				if(is_user_alive(id)&&HasGrenade[id])
				{
					client_cmd(id, "spk ^"weapons/c4_beep2.wav^"")
				}
			}
		}
		case 6,5:
		{
			formatex(message, charsmax(message),"^nBombs Explode in ^n-= %d =-",param[0]);set_hudmessage(255, 255, 0, -1.0, 0.3, 2, 0.02, 0.8, 0.01, 0.1, -1);
			for(new id=1;id<33;id++)
			{
				if(is_user_alive(id)&&HasGrenade[id])
				{
					client_cmd(id, "spk ^"weapons/c4_beep3.wav^"")
				}
			}
		}
		case 4,3:
		{
			formatex(message, charsmax(message),"^n^nBombs Explode in ^n-= %d =-",param[0]);set_hudmessage(255, 0, 0, -1.0, 0.3, 2, 0.02, 0.8, 0.01, 0.1, -1);
			for(new id=1;id<33;id++)
			{
				if(is_user_alive(id)&&HasGrenade[id])
				{
					client_cmd(id, "spk ^"weapons/c4_beep4.wav^"")
				}
			}
		}
		case 2,1:
		{
			formatex(message, charsmax(message),"^n^nBombs Explode in ^n-= %d =-",param[0]);set_hudmessage(255, 0, 0, -1.0, 0.3, 1, 0.1, 0.8, 0.01, 0.1, -1);
			for(new id=1;id<33;id++)
			{
				if(is_user_alive(id)&&HasGrenade[id])
				{
					client_cmd(id, "spk ^"weapons/c4_beep5.wav^"")
				}
			}
		}
	}

	show_hudmessage(0, message)
	client_cmd(0, "spk ^"%s^"",sounds[param[0]-1])
}

public client_disconnected(id)
{
	CheckStatus(id);
}

public fw_Killed()
{
	SetHamParamInteger(3, 2)
}

public fw_KilledPost(id)
{
	CheckStatus(id)
}

CheckStatus(skip)
{
	new aliveid;
	for(new id=1;id<33;id++)
	{
		if(!is_user_alive(id))
			continue;
		
		if(id==skip)
			continue;

		if(aliveid)
		{
			return;
		}

		aliveid = id;
	}
	
	if(aliveid)
	{		
		new name[32]
		get_user_name(aliveid, name, charsmax(name))
		zp_ammopacks_set(aliveid, zp_ammopacks_get(aliveid) + 50)
		zp_colored_print(0,"^3%s^1 has won the^03 Hot Potato^01 and got^03 50 Ammo Packs!", name)
	}

	server_cmd("endround T")	
}

public kill()
{
	new id, alive
	for(id=1;id<33;id++)
	{
		if(!is_user_alive(id))
		{
			continue;
		}
		
		if(!HasGrenade[id])
		{
			alive++;
			continue;
		}
		
		emit_sound(id, CHAN_VOICE, "weapons/mortarhit.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		new Float:origin[3]
		entity_get_vector(id, EV_VEC_origin, origin)
		engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY,origin,0)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, origin[0])
		engfunc(EngFunc_WriteCoord,	origin[1])
		engfunc(EngFunc_WriteCoord, origin[2] + 32)
		write_short(explosion)
		write_byte(60)
		write_byte(30)
		write_byte(10)
		message_end()

		user_kill(id)
		
	}

	if(alive>1)
	{
		set_task(5.0, "start", _,{1},1);
	}
}

// Plays a sound on clients
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}

// Get Alive Count -returns alive players number-
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}

new Float:Time[33];

public client_PreThink(id)
{
	if(is_user_alive(id)&&get_user_weapon(id)==CSW_HEGRENADE&&(get_user_button(id)&IN_ATTACK)&&(get_gametime()>(Time[id]+0.1)))
	{
		TraceGrenade(id)
		Time[id]=get_gametime();
	}
}




public TraceGrenade( id )
{
		//new Float:dest[3];
	new pmtrace = 0;

	new Float:gravity = 240.0;

	new Float:angThrow[ 3 ], Float:throwvector[ 3 ], Float:startpos[ 3 ], Float:endpos[ 3 ], Float:punchangle[ 3 ];
	new Float:origin[ 3 ], Float:view_ofs[ 3 ];
	new Float:pmEyePos[ 3 ], Float:pmVelocity[ 3 ];

	pev( id, pev_velocity, pmVelocity );

	pev( id, pev_punchangle, punchangle );
	pev( id, pev_v_angle, angThrow );

	pev( id ,pev_origin, origin );
	pev( id, pev_view_ofs, view_ofs );

	xs_vec_add( angThrow, punchangle, angThrow );
	xs_vec_add( origin, view_ofs, pmEyePos );

	if (angThrow[0] < 0)
		angThrow[0] = -10 + angThrow[0] * ((90 - 10) / 90.0);
	else
		angThrow[0] = -10 + angThrow[0] * ((90 + 10) / 90.0);

	new Float:flVel = (90 - angThrow[0]) * 10;
	if (flVel > 1000)
		flVel = 1000.0;
		
	angle_vector( angThrow, ANGLEVECTOR_FORWARD, throwvector );

	startpos[0] = pmEyePos[0] + throwvector[0] * 16;
	startpos[1] = pmEyePos[1] + throwvector[1] * 16;
	startpos[2] = pmEyePos[2] + throwvector[2] * 16;

	throwvector[0] = throwvector[0] * flVel + pmVelocity[0];
	throwvector[1] = throwvector[1] * flVel + pmVelocity[1];
	throwvector[2] = throwvector[2] * flVel + pmVelocity[2];

	new collisions = 0;
	new Float:timelive;
	new Float:step = (2.0 / 20.0);

	new ent;
	new Float:plane_normal[3];
	new Float:fraction;

	for ( timelive = 0.0; timelive < 2.0; timelive += step )
	{
		endpos[0] = startpos[0] + throwvector[0] * step;
		endpos[1] = startpos[1] + throwvector[1] * step;
		endpos[2] = startpos[2] + throwvector[2] * step; //move
		
		engfunc( EngFunc_TraceLine, startpos, endpos, DONT_IGNORE_MONSTERS, 0, pmtrace );
		ent = get_tr2( pmtrace, TR_pHit )

		get_tr2( pmtrace, TR_vecPlaneNormal, plane_normal );
		get_tr2( pmtrace, TR_flFraction, fraction );
		
		if( ent != id && fraction < 1.0 )
		{
			endpos[0] = startpos[0] + throwvector[0] * fraction * step;
			endpos[1] = startpos[1] + throwvector[1] * fraction * step;
			endpos[2] = startpos[2] + throwvector[2] * fraction * step;
			/*
			if ( plane_normal[2] > 0.9 && throwvector[2] <= 0 && throwvector[2] >= -gravity*FLOORSTOP )
			{
				dest[0] = endpos[0];
				dest[1] = endpos[1];
				dest[2] = endpos[2];
			}
			*/
			message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id );
			write_byte( TE_SPARKS );
			engfunc( EngFunc_WriteCoord, endpos[0] );
			engfunc( EngFunc_WriteCoord, endpos[1] );
			engfunc( EngFunc_WriteCoord, endpos[2] );
			message_end();
			
			new Float:proj = xs_vec_dot( throwvector, plane_normal ); 
			
			throwvector[0] = (throwvector[0]*1.5 - proj*2*plane_normal[0]) * 0.5; //reflection off the wall
			throwvector[1] = (throwvector[1]*1.5 - proj*2*plane_normal[1]) * 0.5;
			throwvector[2] = (throwvector[2]*1.5 - proj*2*plane_normal[2]) * 0.5; 

			collisions++;
			if (collisions > 1) break;

			timelive -= (step * (1 - fraction));
		}
		
		BeamPoints( id, startpos, endpos );
		
		startpos[0] = endpos[0];
		startpos[1] = endpos[1];
		startpos[2] = endpos[2];

		throwvector[2] -= gravity * fraction * step; //gravity
	}

	//dest[0] = startpos[0];
	//dest[1] = startpos[1];
	//dest[2] = startpos[2];

	return PLUGIN_HANDLED;
}

BeamPoints( id, Float:startpos[3], Float:endpos[3] )
{
    message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id );
    write_byte( TE_BEAMPOINTS )            // type
    engfunc( EngFunc_WriteCoord, startpos[0] );    // origin[1]
    engfunc( EngFunc_WriteCoord, startpos[1] );    // origin[2]
    engfunc( EngFunc_WriteCoord, startpos[2] );    // origin[3]
    engfunc( EngFunc_WriteCoord, endpos[0] );    // origin2[1]
    engfunc( EngFunc_WriteCoord, endpos[1] );    // origin2[2]
    engfunc( EngFunc_WriteCoord, endpos[2] );    // origin2[3]
    write_short( spr_beam );            // sprite index
    write_byte( 0 );                // start frame
    write_byte( 0 );                // framerate
    write_byte( 1 );                // life in 0.1 sec
    write_byte( 20 );                // width
    write_byte( 0 );                // noise
    write_byte( 0 );                // red
    write_byte( 255 );                // green
    write_byte( 0 );                // blue
    write_byte( 255 );                // brightness
    write_byte( 0 );                // speed
    message_end()
} 

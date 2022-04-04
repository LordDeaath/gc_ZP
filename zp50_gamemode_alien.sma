/* AMX Mod Plugin
* 
* (c) Copyright 2016, Serial-Killer 
* This file is provided as is (no warranties). 
* 
*/ 
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <amx_settings_api>
#include <zp50_gamemodes>
#include <cs_teams_api>
#include <zp50_colorchat>
#include <zp50_ammopacks>
#include <zmvip>
/*------------------------------------------------------------------------------------------
Task/Sons/Models (ALIEN BOSS)
--------------------------------------------------------------------------------------------*/
#define ALIEN_MODEL "models/Zombie_Scenario/Alien/Alien.mdl"
#define ALIEN_CLASS "AlienBoss"

#define TASK_SWING_ALIEN 28000+1
#define TASK_SHOCKWAVE_ALIEN 28000+2
#define TASK_MADASH_ALIEN 28000+3
#define TASK_FLUXING_ALIEN 28000+4
#define TASK_DEATH_ALIEN 28000+5
#define TASK_APPEAR_ALIEN 28000+6
#define ALLIEN_ATTACK_RANGE 290.0

#define DAMAGE 50.0
native zp_give_unlimited(id)

static FluxSpr

new const Resource[][] = 
{
	"sprites/Zombie_Scenario/Alien/fluxing.spr"
}
new const All_boss_WALK[2][] = 
{
	"Zombie_Scenario/boss_footstep_1.wav",
	"Zombie_Scenario/boss_footstep_2.wav"
}
static g_Resource[sizeof Resource]
new const Alien_Sounds[5][] = 
{
	"Zombie_Scenario/Alien/boss_swing.wav",
	"Zombie_Scenario/Alien/boss_voice_1.wav",
	"Zombie_Scenario/Alien/boss_shokwave.wav",
	"Zombie_Scenario/Alien/boss_dash.wav",
	"Zombie_Scenario/Alien/boss_death.wav"
}
enum
{
	ANIM_ALIEN_DUMMY = 0,
	ANIM_ALIEN_DEATH,
	ANIM_ALIEN_IDLE,
	ANIM_ALIEN_WALK,
	ANIM_ALIEN_RUN,
	ANIM_ALIEN_SHOWCKWAVE,
	ANIM_ALIEN_SWING,
	ANIM_ALIEN_MAHADASH,
	ANIM_ALIEN_SCENE
}
enum 
{
	STATE_ALIEN_APEAR = 0,
	STATE_ALIEN_IDLE,
	STATE_ALIEN_SEARCHING,
	STATE_ALIEN_CHASE,
	STATE_ALIEN_SHOCKWAVE,
	STATE_ALIEN_SWING,
	STATE_ALIEN_MAHADASH,
	STATE_ALIEN_FLUXING,
	STATE_ALIEN_DEATH
}

//Cvars (ALIEN BOSS)
new States_Alien, Alien_Ent, g_FootStep_Alien, bool: y_start_alien, bool: Allien_Death_Prevent, shockwave_spr
new Float: Time1, Float: Time2, Float: Time3, Float: Time4, Float: Time5
/*------------------------------------------------------------------------------------------
Cvars  ADICIONAIS
--------------------------------------------------------------------------------------------*/
#define FLAG_ACESS 	ADMIN_RCON
new g_damagedealt[33]
new g_damagedealtvip[33]
new g_MaxPlayers, m_iBlood[2]
static MSGSYNC;
static HPSYNC;
const WPN_NOT_DROP = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))

new Float:SpawnOrigin[3]
//Sounds (ROUND BOSS)
#define TASK_RESPAWN 1111
#define TASK_APPEAR_2 28000+8

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_alien[][] = { "ambience/zapmachine_alien.wav" , "zombie_plague/nemesis2.wav" }

#define SOUND_MAX_LENGTH 64

new Array:g_sound_alien

public plugin_end()
{
	ArrayDestroy(g_sound_alien)
}
/*------------------------------------------------------------------------------------------
Precache
--------------------------------------------------------------------------------------------*/
public plugin_precache()
{
	register_plugin("[ZP] Game Mode: Alien", "1.0", "Many")
	
	precache_model("models/gib_skull.mdl");
	new mapname[32]
	get_mapname(mapname, charsmax(mapname))
	if(equali(mapname,"zm_cubeworld_v1"))
	{
		SpawnOrigin[0]=-1294.0
		SpawnOrigin[1]=1735.0
		SpawnOrigin[2]=64.0			
		create_zone(Float:{-1344.4,1535.9,-5.0},Float:{511.4,831.4,5.0},Float:{-511.4,-831.4,-5.0})
	}
	else
	if(equali(mapname,"zm_zod_abyss"))
	{
		SpawnOrigin[0]=2185.0
		SpawnOrigin[1]=3701.0
		SpawnOrigin[2]=3903.0
	}
	else
	if(equali(mapname,"zm_zod_dustb"))
	{
		SpawnOrigin[0]=2918.0
		SpawnOrigin[1]=1808.0
		SpawnOrigin[2]=3460.0
	}
	else
	if(equali(mapname,"zm_lgk_laser"))
	{
		SpawnOrigin[0]=340.0
		SpawnOrigin[1]=865.0
		SpawnOrigin[2]=36.0
	}
	else
	if(equali(mapname,"zm_lgk_stonedust2"))
	{
		SpawnOrigin[0]=-189.0
		SpawnOrigin[1]= -613.0
		SpawnOrigin[2]= -123.0
	}
	else
	if(equali(mapname,"zm_lgk_colors"))
	{
		SpawnOrigin[0]=1500.0
		SpawnOrigin[1]=-754.0
		SpawnOrigin[2]=36.0		
		create_zone(Float:{1509.3,-923.6,-5.0},Float:{101.8,80.4,5.0},Float:{-101.8,-80.4,-5.0})
	}
	else
	if(equali(mapname,"zm_lgk_blueroom_v3"))
	{
		SpawnOrigin[0]=223.0
		SpawnOrigin[1]=38.0
		SpawnOrigin[2]=-219.0
	}else
	if(equali(mapname,"zm_lgk_assaulted2"))
	{
		SpawnOrigin[0]=723.0
		SpawnOrigin[1]= 121.0
		SpawnOrigin[2]= -731.0
	}
	else
	if(equali(mapname,"zm_lgk_appall_v1"))
	{
		SpawnOrigin[0]=418.0
		SpawnOrigin[1]=-830.0
		SpawnOrigin[2]=72.0		
		create_zone(Float:{414.6,-830.9,16.0},Float:{69.2,68.9,16.0},Float:{-69.2,-68.9,-16.0})		
		create_zone(Float:{-831.9,-960.9,-90.0},Float:{69.8,67.8,10.0},Float:{-69.8,-67.8,-10.0})
	}  
	else
	if(equali(mapname,"zm_ds_laboratory"))
	{
		SpawnOrigin[0]=133.0
		SpawnOrigin[1]=1434.0
		SpawnOrigin[2]=36.0
	}
	else
	if(equali(mapname,"zm_lgk_laboratory_v3"))
	{
		SpawnOrigin[0]=-38.0
		SpawnOrigin[1]=1557.0
		SpawnOrigin[2]=-581.0			
		create_zone(Float:{-31.4,1568.4,-712.0},Float:{95.8,96.0,8.0},Float:{-95.8,-96.0,-8.0})
	}
	else
	if(equali(mapname,"zm_downtown"))
	{
		SpawnOrigin[0]=27.0
		SpawnOrigin[1]=-416.0
		SpawnOrigin[2]=36.0
	}
	else
	if(equali(mapname,"zm_ds_vortex")||equali(mapname,"zm_gc_vortex"))
	{
		SpawnOrigin[0]=119.0
		SpawnOrigin[1]=-142.0
		SpawnOrigin[2]=36.0
	}
	else
	if(equali(mapname,"zm_apprehension"))
	{
		SpawnOrigin[0]=-2094.0
		SpawnOrigin[1]= 2545.0
		SpawnOrigin[2]= -216.0		
		create_zone(Float:{-1280.0,2544.0,-258.0},Float:{400.3,287.8,2.0},Float:{-400.3,-287.8,-2.0})
	}
	else
	if(equali(mapname,"zm_3rooms_remake"))
	{
		SpawnOrigin[0]=560.0
		SpawnOrigin[1]= 385.0
		SpawnOrigin[2]= -219.0
	}
	else
	if(equali(mapname,"ugc_boss"))
	{
		SpawnOrigin[0]=181.0
		SpawnOrigin[1]= 1052.0
		SpawnOrigin[2]= -119.0
	}
	else
	if(equali(mapname,"zm_roz_hell_v1"))
	{
		SpawnOrigin[0]=-70.0
		SpawnOrigin[1]=1108.0
		SpawnOrigin[2]=-275.0
	}
	else
	if(equali(mapname,"zm_biohazard_base_mx"))
	{
		SpawnOrigin[0]=181.0
		SpawnOrigin[1]=251.0
		SpawnOrigin[2]=100.0
	}
	else
	if(equali(mapname,"zm_gc_awaken"))
	{
		SpawnOrigin[0]=-298.0
		SpawnOrigin[1]=-767.0
		SpawnOrigin[2]=100.0
	}
	else
	if(equali(mapname,"zm_lgk_blueroom_remake2"))
	{
		SpawnOrigin[0]=38.0
		SpawnOrigin[1]=77.0
		SpawnOrigin[2]=-211.0
	}
	else
	if(equali(mapname,"zm_lgk_tomb"))
	{
		SpawnOrigin[0]=60.0
		SpawnOrigin[1]=-5.0
		SpawnOrigin[2]=36.0
	}
	else
	if(equali(mapname,"zm_af-concert-2017_final"))
	{
		SpawnOrigin[0]=253.0
		SpawnOrigin[1]=495.0
		SpawnOrigin[2]=-923.0
	}
	else
	if(equali(mapname,"zm_lgk_dirt"))
	{
		SpawnOrigin[0]=0.0
		SpawnOrigin[1]=552.0
		SpawnOrigin[2]=100.0
	}
	else
	if(equali(mapname,"zm_lgk_snowman_v3"))
	{
		SpawnOrigin[0]=-912.0
		SpawnOrigin[1]=-1683.0
		SpawnOrigin[2]=-475.0
	}
	else
	if(equali(mapname,"zm_zod_fortuna"))
	{
		SpawnOrigin[0]=282.0
		SpawnOrigin[1]=-275.0
		SpawnOrigin[2]=36.0
	}
	else
	if(equali(mapname,"zm_antarctica_v2"))
	{
		SpawnOrigin[0]=-920.0
		SpawnOrigin[1]=-268.0
		SpawnOrigin[2]=36.0
	}
	else
	if(equali(mapname,"zm_zod_hideout"))
	{
		SpawnOrigin[0]=770.0
		SpawnOrigin[1]=-69.0
		SpawnOrigin[2]=-603.0
	}
	else
	if(equali(mapname,"zm_zod_labtest"))
	{
		SpawnOrigin[0]=569.0
		SpawnOrigin[1]=520.0
		SpawnOrigin[2]=36.0
	}
	else
	if(equali(mapname,"zm_roz_frozen"))
	{
		SpawnOrigin[0]=829.0
		SpawnOrigin[1]=147.0
		SpawnOrigin[2]=-75.0
	}
	else
	if(equali(mapname,"lgk_zm_clusterFUK-2"))
	{
		SpawnOrigin[0]=0.0
		SpawnOrigin[1]=168.0
		SpawnOrigin[2]=68.0
	}
	else
	if(equali(mapname,"zm_roz_valar_final"))
	{
		SpawnOrigin[0]=1959.0
		SpawnOrigin[1]=1396.0
		SpawnOrigin[2]=-2347.0
	}
	else
	if(equali(mapname,"zm_lgk_juggernaut"))
	{
		SpawnOrigin[0]=-850.0
		SpawnOrigin[1]=-1101.0
		SpawnOrigin[2]=70.0
	}
	else
	if(equali(mapname,"zm_gc_temple"))
	{
		SpawnOrigin[0]=363.0
		SpawnOrigin[1]=-1517.0
		SpawnOrigin[2]=100.0
	}
	else
	if(equali(mapname,"zm_gc_containership"))
	{
		SpawnOrigin[0]=743.0
		SpawnOrigin[1]=-187.0
		SpawnOrigin[2]=-27.0
	}
	else
	if(equali(mapname,"zm_aztec_infinity"))
	{
		SpawnOrigin[0]=-651.0
		SpawnOrigin[1]=-835.0
		SpawnOrigin[2]=-507.0
	}
	else
	if(equali(mapname,"zm_new_army"))
	{
		SpawnOrigin[0]=177.0
		SpawnOrigin[1]=-665.0
		SpawnOrigin[2]=-355.0
	}
	else
	if(equali(mapname,"zm_oldstyle"))
	{
		SpawnOrigin[0]=1113.0
		SpawnOrigin[1]=-612.0
		SpawnOrigin[2]=36.0
	}
	else
	if(equali(mapname,"zm_minecraft"))
	{
		SpawnOrigin[0]=726.0
		SpawnOrigin[1]=-608.0
		SpawnOrigin[2]=-1239.0
	}
	else
	if(equali(mapname,"zm_toronto_v4"))
	{
		SpawnOrigin[0]=1455.0
		SpawnOrigin[1]=1701.0
		SpawnOrigin[2]=3204.0
	}
	else
	if(equali(mapname,"zm_a_zow_christmas"))
	{
		SpawnOrigin[0]=238.0
		SpawnOrigin[1]=249.0
		SpawnOrigin[2]=68.0
	}
	else
	if(equali(mapname,"zm_area51_v2"))
	{
		SpawnOrigin[0]=-2052.0
		SpawnOrigin[1]=-109.0
		SpawnOrigin[2]=-353.0
	}
	else
	if(equali(mapname,"zm_alternative_v2"))
	{
		SpawnOrigin[0]=-1376.0
		SpawnOrigin[1]=100.0
		SpawnOrigin[2]=52.0
	}
	else
	if(equali(mapname,"zm_coldsteel_v4"))
	{
		SpawnOrigin[0]=966.0
		SpawnOrigin[1]=2201.0
		SpawnOrigin[2]=3460.0
	}
	else
	if(equali(mapname,"zm_ds_aztec"))
	{
		SpawnOrigin[0]=-61.0
		SpawnOrigin[1]=-920.0
		SpawnOrigin[2]=-507.0
	}
	else
	if(equali(mapname,"zm_exertion_aj_v1"))
	{
		SpawnOrigin[0]=-93.0
		SpawnOrigin[1]=347.0
		SpawnOrigin[2]=36.0
	}
	else
	if(equali(mapname,"zm_gc_assaulted2"))
	{
		SpawnOrigin[0]=831.0
		SpawnOrigin[1]=39.0
		SpawnOrigin[2]=-731.0
	}
	else
	if(equali(mapname,"zm_gc_assaulted_final"))
	{
		SpawnOrigin[0]=861.0
		SpawnOrigin[1]=145.0
		SpawnOrigin[2]=-731.0
	}
	else
	if(equali(mapname,"zm_nub_house_final"))
	{
		SpawnOrigin[0]=-20.0
		SpawnOrigin[1]=-887.0
		SpawnOrigin[2]=-210.0
	}
	else
	if(equali(mapname,"zm_rylyn_v2z"))
	{
		SpawnOrigin[0]=-1806.0
		SpawnOrigin[1]=-923.0
		SpawnOrigin[2]=-2011.0
	}
	else
	if(equali(mapname,"zm_zod_cave_z"))
	{
		SpawnOrigin[0]=189.0
		SpawnOrigin[1]=155.0
		SpawnOrigin[2]=4.0
	}
	else
	{
		pause("d")
		return;
	}
	zp_gamemodes_register("Alien Mode")
	register_think(ALIEN_CLASS, "Fw_Alien_Think")	
	g_MaxPlayers = get_maxplayers()
	MSGSYNC = CreateHudSyncObj()	
	HPSYNC = CreateHudSyncObj()	
	
	/*
	else
	if(equali(mapname,"zm_"))
	{
		SpawnOrigin[0]=.0
		SpawnOrigin[1]=.0
		SpawnOrigin[2]=.0
	}*/
	
	// Initialize arrays
	g_sound_alien = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND ALIEN", g_sound_alien)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_alien) == 0)
	{
		for (index = 0; index < sizeof sound_alien; index++)
			ArrayPushString(g_sound_alien, sound_alien[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND ALIEN", g_sound_alien)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_alien); index++)
	{
		ArrayGetString(g_sound_alien, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
	/*------------Precache (ALL BOSS)---------------*/
	for(new i = 0; i < sizeof(All_boss_WALK); i++)
		engfunc(EngFunc_PrecacheSound, All_boss_WALK[i])
	
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")	
		
	/*------------Precache (ALIEN BOSS)---------------*/
	engfunc(EngFunc_PrecacheModel, ALIEN_MODEL)			
	
	for(new i = 0; i < sizeof(Alien_Sounds); i++)
		engfunc(EngFunc_PrecacheSound, Alien_Sounds[i])
		
	shockwave_spr = precache_model("sprites/Zombie_Scenario/Alien/shockwave.spr")	

	for(new i; i <= charsmax(Resource); i++)
		g_Resource[i] = precache_model(Resource[i])
}
/*------------------------------------------------------------------------------------------
Natives
--------------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------------
Round Scenario (CODES)
--------------------------------------------------------------------------------------------*/
public zp_fw_gamemodes_start()
{
	new zone
	
	while((zone = find_ent_by_class(zone, "alien_zone")))
	{
		if(pev_valid(zone)==2)
		{
			set_pev(zone, pev_solid, SOLID_BBOX);
		}
	}
	
	remove_task()
	for (new id=1; id<33;id++)
	{
		zp_give_unlimited(id)
		if(is_user_alive(id)&&!get_user_godmode(id))
		{
			cs_set_player_team(id, CS_TEAM_CT)
			set_pev(id,pev_origin,SpawnOrigin)
		}
	}
	
	StopSound();
	new sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_sound_alien, 0, sound, charsmax(sound))
	PlaySound(0, sound)

	Ativar_Alien();
	// server_cmd("mp_auto_join_team 1");
	// server_cmd("humans_join_team CT");
	server_cmd("mp_round_infinite bcdefg");		
	server_cmd("amx_spawnprotect 1")
	server_cmd("amx_spawnprotect_glow 1")
	//server_cmd("amx_spawnprotect_message 1")
	server_cmd("amx_spawnprotect_time 5.0")
	server_exec();
	//set_task(20.0,"rtv")
}

public rtv()
{
	server_cmd("gal_startvote")
}


public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{		
	if (!skipchecks)
	{
		// Min players
		if (GetAliveCount() < 2)
			return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
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
public zp_fw_gamemodes_end()
{	
	new zone
	
	while((zone = find_ent_by_class(zone, "alien_zone")))
	{
		if(pev_valid(zone)==2)
		{
			set_pev(zone, pev_solid, SOLID_NOT);
		}
	}

	StopSound();
	
	if(pev_valid(FluxSpr)==2)
	{
		set_pev(FluxSpr, pev_flags, FL_KILLME)
		FluxSpr=0;
	}
	
	// server_cmd("humans_join_team any");
	server_cmd("mp_round_infinite 0");	
	server_cmd("amx_spawnprotect 0")
	server_cmd("amx_spawnprotect_glow 0")
	//server_cmd("amx_spawnprotect_message 0")
	server_cmd("amx_spawnprotect_time 0.0")
	server_exec();
	
	if(pev_valid(Alien_Ent)!=2)
		return
		
	//PlaySound(0, ROUND_WIN)
	set_pev(Alien_Ent, pev_flags, FL_KILLME)
	Alien_Ent=0;
	//engfunc(EngFunc_RemoveEntity, Alien_Ent)			
	y_start_alien = false
	remove_task()
}

public zp_fw_core_spawn_post(id)
{	
	zp_core_respawn_as_zombie(id, false)
}

public Ativar_Alien()
{
	set_task(7.0, "Game_Start")
	
	set_hudmessage(255, 0,0, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, MSGSYNC, "The alien is coming... Prepare yourselves!")
	
	for(new id = 1; id<= g_MaxPlayers; id++)
	{
		if(!is_user_connected(id))
			continue
			
		shake_screen(id)
		ScreenFade(id, 1, {0, 0, 0}, 255)	
	}
	set_task(1.0, "Tela_preta_Boss", TASK_APPEAR_2, _, _, "b")
}
public Tela_preta_Boss(Tela)
{
	for(new id = 1; id<= g_MaxPlayers; id++)
	{
		if(!is_user_alive(id))
			continue		
		
		if(get_user_godmode(id))
			continue;
		MM_Aim_To(id, SpawnOrigin)
		set_pev(id,pev_fixangle,1);
		shake_screen(id)
		ScreenFade(id, 1, {0, 0, 0}, 255)	
		
	}
	if(get_gametime() - 0.8 > Time3)
	{
		if(g_FootStep_Alien != 0) g_FootStep_Alien = 0
		else g_FootStep_Alien = 1
					
		PlaySound(0, All_boss_WALK[g_FootStep_Alien == 0 ? 0 : 1])
		Time3 = get_gametime()
	}
	KickBack()
}/*
public Music_Round_Boss(id)
{
	PlaySound(0, ROUND_FIGHT)
	set_task(97.0, "Music_Round_Boss", TASK_LOOP_MUSIC, _, _, "b")
}*/
/*-------------------------------------------------------------------------------------------
Spawn (ALIEN Boss)
--------------------------------------------------------------------------------------------*/
public Game_Start()
{
	StopSound()
	new sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_sound_alien, 1, sound, charsmax(sound))
	PlaySound(0, sound)
	
	set_hudmessage(255, 0,0, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, MSGSYNC, "The alien has arrived!")
	
	if(pev_valid(Alien_Ent)==2)
	{
		set_pev(Alien_Ent, pev_flags, FL_KILLME)
		Alien_Ent=0;
	}
		//engfunc(EngFunc_RemoveEntity, Alien_Ent)
	
	
	static Alien; Alien = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if(pev_valid(Alien)!=2) return
	
	Alien_Ent = Alien
	set_pev(Alien, pev_origin, SpawnOrigin)
		
	static Float:Angles[3]
	
	set_pev(Alien, pev_angles, Angles)
	set_pev(Alien, pev_v_angle, Angles)		
			
	// Setar Configura��o
	set_pev(Alien, pev_classname, ALIEN_CLASS)
	engfunc(EngFunc_SetModel, Alien, ALIEN_MODEL)
			
	set_pev(Alien, pev_gamestate, 1)
	set_pev(Alien, pev_solid, SOLID_BBOX)
	set_pev(Alien, pev_movetype, MOVETYPE_PUSHSTEP)
	
	// Setar Tamanho do Alien
	new Float:maxs[3] = {25.0, 50.0, 200.0}
	new Float:mins[3] = {-25.0, -50.0, -35.0}
	entity_set_size(Alien, mins, maxs)	
	
	// Setar Vida do Alien Boss // E o Dano Tambem 	
	set_pev(Alien, pev_takedamage, DAMAGE_YES)
	new count;
	for (new i = 1;i<33;i++)
	{
		if(is_user_alive(i))
			count++
	}
	set_pev(Alien, pev_health, 25000.0* count)
	
	// Setar o boss e criar o spawn
	Set_EntAnim(Alien, ANIM_ALIEN_IDLE, 1.0, 1)	
	States_Alien = STATE_ALIEN_APEAR	
	
	if(!y_start_alien)
	{
		RegisterHamFromEntity(Ham_Killed, Alien, "Allien_Boss_Killed")
		RegisterHamFromEntity(Ham_TakeDamage, Alien, "fw_Alien_TraceAttack", 1)
		y_start_alien = true
		Allien_Death_Prevent = true
	}
	
	set_task(0.5, "Set_Appear", Alien+TASK_APPEAR_ALIEN)
	remove_task(TASK_APPEAR_2)
			
	set_pev(Alien, pev_nextthink, get_gametime() + 1.0)
	
	engfunc(EngFunc_DropToFloor, Alien)
}
public Set_Appear(Alien)
{
	Alien -= TASK_APPEAR_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
	Set_EntAnim(Alien, ANIM_ALIEN_MAHADASH, 1.0, 1)	
	set_task(0.4, "Emit_Som_Scene")
	set_task(0.8, "Move_Dash_Scene", Alien+TASK_APPEAR_ALIEN)	
	set_task(2.0, "Set_state_Alien")
}
public Move_Dash_Scene(Alien)
{
	Alien -= TASK_APPEAR_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
		
	static Float:OriginAhead[3]
	get_position(Alien, 300.0, 0.0, 0.0, OriginAhead)
	
	hook_ent2(Alien, OriginAhead, 500.0)
	
	set_task(0.1, "Move_Dash_Scene", Alien+TASK_APPEAR_ALIEN)
	KickBack()
}
public Emit_Som_Scene(Alien)
{
	PlaySound(0, Alien_Sounds[3])
}
public Set_state_Alien(Alien)
{
	remove_task(Alien_Ent+TASK_APPEAR_ALIEN)
	
	States_Alien = STATE_ALIEN_IDLE
}
/*------------------------------------------------------------------------------------------
Ham Killed/Ham TakeDMG (ALIEN Boss)
--------------------------------------------------------------------------------------------*/
public Allien_Boss_Killed(Alien)
{
	if(!is_valid_ent(Alien))
		return HAM_IGNORED
		
	if(Allien_Death_Prevent)
	{	
		Allien_Death_Prevent = false
			
		zp_colored_print(0, "^x04Humans^x01 won^x04 25 Ammopacks^x01 for killing the alien!");
		for(new i=1;i<33;i++)
		{
			if(is_user_connected(i))
			zp_ammopacks_set(i,zp_ammopacks_get(i)+25)
		}
		//Remove Alien Boss		
		set_task(8.0, "Remove_Alien_boss", Alien)
	}
	return HAM_SUPERCEDE
}
public Remove_Alien_boss(Alien)
{	
	if(pev_valid(Alien_Ent)!=2)
		return
		
	//PlaySound(0, ROUND_WIN)
	set_pev(Alien_Ent, pev_flags, FL_KILLME)
	Alien_Ent=0;
	//engfunc(EngFunc_RemoveEntity, Alien_Ent)		
	remove_task(Alien+TASK_DEATH_ALIEN)
	y_start_alien = false
	//N�o Remover esta linha pode bugar o boss por completo ok
	set_task(1.0, "Restart_Map_antibug")
}
//Nunca Remover (Isso Evita bugs ao boss morrer)
public Restart_Map_antibug()
{
	server_cmd("endround")
}
public fw_Alien_TraceAttack(victim, inflictor, attacker, Float:damage, damagebits)
{
	static Float:Origin[3]
	fm_get_aimorigin(attacker, Origin)

	create_blood(Origin)

	new left =  pev(victim, pev_health)
	if(is_user_alive(attacker) && pev_valid(victim)==2&&left>0)
	{
		set_hudmessage(0,255,0,0.5,0.2,0,1.0,1.0)
		ShowSyncHudMsg(attacker,HPSYNC,"Alien HP: %d", left)
	}
	
	// Store damage dealt
	g_damagedealt[attacker] += floatround(damage)
	if(zv_get_user_flags(attacker)&ZV_MAIN)	
	g_damagedealtvip[attacker] += floatround(damage)
		
	// Reward ammo packs for every [ammo damage] dealt
	while (g_damagedealt[attacker] > 1000)
	{
		g_damagedealt[attacker] = 0
		zp_ammopacks_set(attacker,zp_ammopacks_get(attacker)+1)
		set_hudmessage(169, 188, 245, -1.0, 0.30, 0, 6.0, 0.5 );
		ShowSyncHudMsg(attacker, MSGSYNC, "[ + 1 Ammopack ]")
	}
	
	if(zv_get_user_flags(attacker)&ZV_MAIN)
	{
		// Reward ammo packs for every [ammo damage] dealt
		while (g_damagedealtvip[attacker] > 800)
		{
			g_damagedealtvip[attacker] = 0
			zp_ammopacks_set(attacker,zp_ammopacks_get(attacker)+1)
			set_hudmessage(169, 188, 245, -1.0, 0.30, 0, 6.0, 0.5 );
			ShowSyncHudMsg(attacker, MSGSYNC, "[ + 1 Ammopack ]")
		}
	}
}
/*------------------------------------------------------------------------------------------
Think (ALIEN Boss)
--------------------------------------------------------------------------------------------*/
public Fw_Alien_Think(Alien)
{
	if(pev_valid(Alien)!=2)
		return
	if(States_Alien == STATE_ALIEN_DEATH) return
	
	if(pev(Alien, pev_health)  <= 0.0)
	{	
		Alien_Death_Kill(Alien+TASK_DEATH_ALIEN)		
		return  
	}	
	// Set Next Think
	set_pev(Alien, pev_nextthink, get_gametime() + 0.01)
		
	if(get_gametime() - Time4 > Time5)
	{
		static RandomNum; RandomNum = random_num(0, 5)
	
		switch(RandomNum)
		{
			case 0: Shockwave1_Attack_Alien(Alien+TASK_SHOCKWAVE_ALIEN)
			case 1: Shockwave2_Attack_Alien(Alien+TASK_SHOCKWAVE_ALIEN)
			case 2: Shockwave3_Attack_Alien(Alien+TASK_SHOCKWAVE_ALIEN)
			case 3: Attack_Fluxing1(Alien+TASK_FLUXING_ALIEN)
			case 4: Attack_Fluxing2(Alien+TASK_FLUXING_ALIEN)
			case 5: Attack_Dash(Alien+TASK_MADASH_ALIEN)
		}

		Time4 = random_float(1.0, 5.0)
		Time5 = get_gametime()
	}	
		
	switch(States_Alien)
	{	
		case STATE_ALIEN_IDLE:
		{
			if(get_gametime() - 3.0 > Time1)
			{
				Set_EntAnim(Alien, ANIM_ALIEN_IDLE, 1.0, 1)	
				Time1 = get_gametime()
			}
			if(get_gametime() - 1.0 > Time2)
			{
				States_Alien = STATE_ALIEN_SEARCHING
				Time2 = get_gametime()
			}	
		}	
		case STATE_ALIEN_SEARCHING:
		{
			static Victim;
			Victim = FindClosetEnemy(Alien, 1)
	
			if(is_user_alive(Victim)&&!get_user_godmode(Victim))
			{
				set_pev(Alien, pev_enemy, Victim)
				States_Alien = STATE_ALIEN_CHASE
			} 
			else 
			{
				set_pev(Alien, pev_enemy, 0)
				States_Alien = STATE_ALIEN_IDLE
			}
		}	
		case STATE_ALIEN_CHASE:
		{
			static Enemy; Enemy = pev(Alien, pev_enemy)
			static Float:EnemyOrigin[3]
			pev(Enemy, pev_origin, EnemyOrigin)	
			
			if(is_user_alive(Enemy)&&!get_user_godmode(Enemy))
			{
				if(entity_range(Enemy, Alien) <= floatround(ALLIEN_ATTACK_RANGE))
				{	
					MM_Aim_To(Alien, EnemyOrigin)							
					Swing_Attack_Alien(Alien+TASK_SWING_ALIEN)														
				} 
				else 
				{
					if(pev(Alien, pev_movetype) == MOVETYPE_PUSHSTEP)
					{										
						static Float:OriginAhead[3]									
						MM_Aim_To(Alien, EnemyOrigin)
						get_position(Alien, 200.0, 0.0, 0.0, OriginAhead)						
						hook_ent2(Alien, OriginAhead, 250.0)							
						Set_EntAnim(Alien, ANIM_ALIEN_RUN, 1.0, 0)
						
						if(get_gametime() - 0.8 > Time3)
						{
							if(g_FootStep_Alien != 0) g_FootStep_Alien = 0
							else g_FootStep_Alien = 1
					
							PlaySound(0, All_boss_WALK[g_FootStep_Alien == 0 ? 0 : 1])
							Time3 = get_gametime()
						}			
					}
					else 
					{
						set_pev(Alien, pev_movetype, MOVETYPE_PUSHSTEP)
					}
				}
			} 
			else 
			{
				States_Alien = STATE_ALIEN_SEARCHING
			}
			set_pev(Alien, pev_nextthink, get_gametime() + 0.1)
		}		
	}			
}
/*------------------------------------------------------------------------------------------
Swing (ALIEN Boss)
--------------------------------------------------------------------------------------------*/
public Swing_Attack_Alien(Alien)
{
	Alien -= TASK_SWING_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
		
	if(States_Alien == STATE_ALIEN_IDLE || States_Alien == STATE_ALIEN_SEARCHING || States_Alien == STATE_ALIEN_CHASE)
	{
		Set_EntAnim(Alien, ANIM_ALIEN_SWING, 1.0, 1)	
		PlaySound(0, Alien_Sounds[0])	
		
		set_pev(Alien, pev_movetype, MOVETYPE_NONE)
		States_Alien = STATE_ALIEN_SWING
		set_task(0.7, "Dmg_Swing_Alien", Alien+TASK_SWING_ALIEN)
		
		set_task(1.5, "Remove_Swing_Alien", Alien+TASK_SWING_ALIEN)
	}
}
public Dmg_Swing_Alien(Alien)
{		
	Alien -= TASK_SWING_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
		
	for(new i = 1; i <= g_MaxPlayers; i++)
	{
		if(is_user_alive(i) && entity_range(Alien, i) <= 320.0)
		{			
			if(get_user_godmode(i))
				continue;
			

			DoDamage(i)
			shake_screen(i)
			ScreenFade(i, 2, {140, 0, 0}, 120)	
		}
	}
}
public Remove_Swing_Alien(Alien)
{
	Alien -= TASK_SWING_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
	
	set_pev(Alien, pev_movetype, MOVETYPE_PUSHSTEP)
	States_Alien = STATE_ALIEN_IDLE
	
	remove_task(Alien+TASK_SWING_ALIEN)
}
/*------------------------------------------------------------------------------------------
Shockwave 1 (ALIEN Boss)
--------------------------------------------------------------------------------------------*/
public Shockwave1_Attack_Alien(Alien)
{
	Alien -= TASK_SHOCKWAVE_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
		
	if(States_Alien == STATE_ALIEN_IDLE || States_Alien == STATE_ALIEN_SEARCHING || States_Alien == STATE_ALIEN_CHASE)
	{
		Set_EntAnim(Alien, ANIM_ALIEN_SHOWCKWAVE, 1.0, 1)	
		PlaySound(0, Alien_Sounds[1])	
		set_rendering(Alien, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 30)
		
		set_task(1.8, "Emit_Som_Shockwave1")
		
		set_pev(Alien, pev_movetype, MOVETYPE_NONE)
		States_Alien = STATE_ALIEN_SHOCKWAVE
		
		set_task(2.0, "Create_Shockwave", Alien+TASK_SHOCKWAVE_ALIEN)
		
		set_task(2.5, "Remove_Shockwave_Alien", Alien+TASK_SHOCKWAVE_ALIEN)
	}
}
public Emit_Som_Shockwave1(Alien)
{
	PlaySound(0, Alien_Sounds[2])
}
public Create_Shockwave(Alien)
{
	Alien -= TASK_SHOCKWAVE_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
	
	static Float:Orig[3]
	pev(Alien_Ent, pev_origin, Orig)

	ShockWave(Orig, 5, 35, 1000.0, {255, 0, 0})

	set_rendering(Alien)	
	for(new i = 1; i <= g_MaxPlayers; i++)
	{

		if(is_user_alive(i) && entity_range(Alien, i) <= 550.0)
		{			
			if(get_user_godmode(i))
				continue;
			DoDamage(i)	
			shake_screen(i)
			ScreenFade(i, 2, {140, 0, 0}, 120)	
		}
	}
}
public Remove_Shockwave_Alien(Alien)
{
	Alien -= TASK_SHOCKWAVE_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
	
	set_pev(Alien, pev_movetype, MOVETYPE_PUSHSTEP)
	States_Alien = STATE_ALIEN_IDLE
	
	remove_task(Alien+TASK_SHOCKWAVE_ALIEN)
}
/*------------------------------------------------------------------------------------------
Shockwave 2 (ALIEN Boss)
--------------------------------------------------------------------------------------------*/
public Shockwave2_Attack_Alien(Alien)
{
	Alien -= TASK_SHOCKWAVE_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
		
	if(States_Alien == STATE_ALIEN_IDLE || States_Alien == STATE_ALIEN_SEARCHING || States_Alien == STATE_ALIEN_CHASE)
	{
		Set_EntAnim(Alien, ANIM_ALIEN_SHOWCKWAVE, 1.0, 1)	
		PlaySound(0, Alien_Sounds[1])	
		set_rendering(Alien, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 30)
		
		set_task(1.8, "Emit_Som_Shockwave1")
		
		set_pev(Alien, pev_movetype, MOVETYPE_NONE)
		States_Alien = STATE_ALIEN_SHOCKWAVE
		
		set_task(2.0, "Create_Shockwave_2", Alien+TASK_SHOCKWAVE_ALIEN)
		
		set_task(2.5, "Remove_Shockwave_Alien", Alien+TASK_SHOCKWAVE_ALIEN)
	}
}
public Create_Shockwave_2(Alien)
{
	Alien -= TASK_SHOCKWAVE_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
	
	static Float:Orig[3]
	pev(Alien_Ent, pev_origin, Orig)

	ShockWave(Orig, 5, 35, 1000.0, {0, 255, 0})	

	set_rendering(Alien)
	for(new i = 1; i <= g_MaxPlayers; i++)
	{
		if(is_user_alive(i) && entity_range(Alien, i) <= 550.0)
		{
			if(get_user_godmode(i))
				continue;
			if(!random(4))
			Drop_weapons(i)
			DoDamage(i)
			shake_screen(i)
			ScreenFade(i, 2, {140, 0, 0}, 120)	
		}
	}
}
/*------------------------------------------------------------------------------------------
Shockwave 3 (ALIEN Boss)
--------------------------------------------------------------------------------------------*/
public Shockwave3_Attack_Alien(Alien)
{
	Alien -= TASK_SHOCKWAVE_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
		
	if(States_Alien == STATE_ALIEN_IDLE || States_Alien == STATE_ALIEN_SEARCHING || States_Alien == STATE_ALIEN_CHASE)
	{
		Set_EntAnim(Alien, ANIM_ALIEN_SHOWCKWAVE, 1.0, 1)	
		PlaySound(0, Alien_Sounds[1])	
		set_rendering(Alien, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 30)
		
		set_task(1.8, "Emit_Som_Shockwave1")
		
		set_pev(Alien, pev_movetype, MOVETYPE_NONE)
		States_Alien = STATE_ALIEN_SHOCKWAVE
		
		set_task(2.0, "Create_Shockwave_3", Alien+TASK_SHOCKWAVE_ALIEN)
		
		set_task(2.5, "Remove_Shockwave_Alien", Alien+TASK_SHOCKWAVE_ALIEN)
	}
}
public Create_Shockwave_3(Alien)
{
	Alien -= TASK_SHOCKWAVE_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
	
	static Float:Orig[3]
	pev(Alien_Ent, pev_origin, Orig)

	ShockWave(Orig, 5, 35, 1000.0, {0, 0, 255})
	KickBack()
	KickBack()
	KickBack()
	
	set_rendering(Alien)
	for(new i = 1; i <= g_MaxPlayers; i++)
	{
		if(is_user_alive(i) && entity_range(Alien, i) <= 550.0)
		{
			if(get_user_godmode(i))
				continue;
			DoDamage(i)	
			shake_screen(i)
			ScreenFade(i, 2, {140, 0, 0}, 120)	
		}
	}
}
/*------------------------------------------------------------------------------------------
Dash (ALIEN Boss)
--------------------------------------------------------------------------------------------*/
public Attack_Dash(Alien)
{
	Alien -= TASK_MADASH_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
		
	if(States_Alien == STATE_ALIEN_IDLE || States_Alien == STATE_ALIEN_SEARCHING || States_Alien == STATE_ALIEN_CHASE)
	{
		Set_EntAnim(Alien, ANIM_ALIEN_MAHADASH, 1.0, 1)	
		States_Alien = TASK_MADASH_ALIEN
		set_task(0.4, "Emit_Som_Dash")
		set_task(0.8, "Move_Attack_Dash", Alien+TASK_MADASH_ALIEN)	
	
		set_task(2.0, "Remove_Attack_Dash", Alien+TASK_MADASH_ALIEN)
	}
}
public Move_Attack_Dash(Alien)
{
	Alien -= TASK_MADASH_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
		
	static Float:OriginAhead[3]
	get_position(Alien, 300.0, 0.0, 0.0, OriginAhead)
	
	hook_ent2(Alien, OriginAhead, 1800.0)
	
	set_task(0.1, "Move_Attack_Dash", Alien+TASK_MADASH_ALIEN)
	
	for(new i = 1; i <= g_MaxPlayers; i++)
	{
		if(is_user_alive(i) && entity_range(Alien, i) <= 280.0)
		{
			if(get_user_godmode(i))
				continue;
			DoDamage(i)	
			shake_screen(i)
			ScreenFade(i, 2, {140, 0, 0}, 120)	
		}
	}
}
public Emit_Som_Dash(Alien)
{
	PlaySound(0, Alien_Sounds[3])
}
public Remove_Attack_Dash(Alien)
{
	Alien -= TASK_MADASH_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
		
	States_Alien = STATE_ALIEN_IDLE
	remove_task(Alien+TASK_MADASH_ALIEN)
}
/*------------------------------------------------------------------------------------------
Fluxing 1(ALIEN Boss)
--------------------------------------------------------------------------------------------*/
public Attack_Fluxing1(Alien)
{
	Alien -= TASK_FLUXING_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
		
	if(States_Alien == STATE_ALIEN_IDLE || States_Alien == STATE_ALIEN_SEARCHING || States_Alien == STATE_ALIEN_CHASE)
	{
		Set_EntAnim(Alien, ANIM_ALIEN_IDLE, 1.0, 1)
		States_Alien = STATE_ALIEN_FLUXING	
		set_rendering(Alien, kRenderFxGlowShell, 255, 20, 147, kRenderNormal, 30)
		set_pev(Alien, pev_movetype, MOVETYPE_NONE)
		
		set_task(0.1, "Puxar_players_Fluxing", Alien+TASK_FLUXING_ALIEN)
		set_task(5.0, "Flux_shock1_Attack_Alien", Alien+TASK_SHOCKWAVE_ALIEN)
	}
}
public Puxar_players_Fluxing(Alien)
{
	Alien -= TASK_FLUXING_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
		
	static Float:Origin[3]
	if(pev_valid(FluxSpr)==2)
	{
		set_pev(FluxSpr, pev_flags, FL_KILLME);
		FluxSpr=0;
	}

	FluxSpr = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	set_rendering(FluxSpr, kRenderFxGlowShell, 0, 255, 127, kRenderNormal, 30)
	set_pev(FluxSpr, pev_rendermode, kRenderTransAdd)
	set_pev(FluxSpr, pev_renderfx, kRenderFxGlowShell)
	set_pev(FluxSpr, pev_renderamt, 100.0)
	
	pev(Alien_Ent, pev_origin, Origin)
	Origin[2] += 70
	engfunc(EngFunc_SetOrigin, FluxSpr, Origin)
	engfunc(EngFunc_SetModel, FluxSpr, Resource[0])
	set_pev(FluxSpr, pev_solid, SOLID_NOT)
	set_pev(FluxSpr, pev_movetype, MOVETYPE_NOCLIP)
	
	set_pev(FluxSpr, pev_framerate, 3.0)
	dllfunc(DLLFunc_Spawn, FluxSpr)
		
	for(new i = 1; i <= g_MaxPlayers; i++)
	{
		if(is_user_alive(i) && entity_range(Alien, i) <= 1000.0)
		{			
			if(get_user_godmode(i))
				continue;

			static arg[2]
			arg[0] = Alien
			arg[1] = i
			
			set_task(0.01, "do_hook_player", 512512, arg, sizeof(arg), "b")
		}
	}
	set_task(5.0, "stop_hook", Alien+2012)
}
public do_hook_player(arg[2])
{
	static Float:Origin[3], Float:Speed
	pev(arg[0], pev_origin, Origin)
	
	Speed = (1000.0 / entity_range(arg[0], arg[1])) * 120.0
	
	hook_ent2(arg[1], Origin, Speed)
}
public stop_hook(Alien)
{
	Alien -= 2012
	
	remove_task(512512)
	remove_task(2012)	
	
	if(pev_valid(FluxSpr)==2)		
	{
		set_pev(FluxSpr, pev_flags, FL_KILLME)
		FluxSpr=0;
		//engfunc(EngFunc_RemoveEntity,FluxSpr)	
	}
}
public Flux_shock1_Attack_Alien(Alien)
{
	Alien -= TASK_SHOCKWAVE_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
		
	Set_EntAnim(Alien, ANIM_ALIEN_SHOWCKWAVE, 1.0, 1)	
	PlaySound(0, Alien_Sounds[1])	
	set_rendering(Alien, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 30)
		
	set_task(1.8, "Emit_Som_Shockwave1")			
	set_task(2.0, "Create_Shockwave", Alien+TASK_SHOCKWAVE_ALIEN)		
	set_task(2.5, "Remove_Flux_Alien", Alien+TASK_SHOCKWAVE_ALIEN)
}
public Remove_Flux_Alien(Alien)
{
	Alien -= TASK_SHOCKWAVE_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
	
	set_pev(Alien, pev_movetype, MOVETYPE_PUSHSTEP)
	States_Alien = STATE_ALIEN_IDLE
	
	remove_task(Alien+TASK_SHOCKWAVE_ALIEN)
}
/*------------------------------------------------------------------------------------------
Fluxing 2(ALIEN Boss)
--------------------------------------------------------------------------------------------*/ 
public Attack_Fluxing2(Alien)
{
	Alien -= TASK_FLUXING_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
		
	if(States_Alien == STATE_ALIEN_IDLE || States_Alien == STATE_ALIEN_SEARCHING || States_Alien == STATE_ALIEN_CHASE)
	{
		Set_EntAnim(Alien, ANIM_ALIEN_IDLE, 1.0, 1)	
		States_Alien = STATE_ALIEN_FLUXING
		set_pev(Alien, pev_movetype, MOVETYPE_NONE)
			
		set_rendering(Alien, kRenderFxGlowShell, 255, 165, 0, kRenderNormal, 30)
		
		set_task(0.1, "Puxar_players_Fluxing2", Alien+TASK_FLUXING_ALIEN)
		set_task(5.0, "Flux_shock2_Attack_Alien", Alien+TASK_SHOCKWAVE_ALIEN)
	}
}
public Puxar_players_Fluxing2(Alien)
{
	Alien -= TASK_FLUXING_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
	
	static Float:Origin[3]
	
	if(pev_valid(FluxSpr)==2)
	{
		set_pev(FluxSpr, pev_flags, FL_KILLME)
		FluxSpr=0;
	}

	FluxSpr = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	set_rendering(FluxSpr, kRenderFxGlowShell, 0, 255, 127, kRenderNormal, 30)
	set_pev(FluxSpr, pev_rendermode, kRenderTransAdd)
	set_pev(FluxSpr, pev_renderfx, kRenderFxGlowShell)
	set_pev(FluxSpr, pev_renderamt, 70.0)
	
	pev(Alien_Ent, pev_origin, Origin)
	Origin[2] += 70
	engfunc(EngFunc_SetOrigin, FluxSpr, Origin)
	engfunc(EngFunc_SetModel, FluxSpr, Resource[0])
	set_pev(FluxSpr, pev_solid, SOLID_NOT)
	set_pev(FluxSpr, pev_movetype, MOVETYPE_NOCLIP)
	
	set_pev(FluxSpr, pev_framerate, 3.0)
	dllfunc(DLLFunc_Spawn, FluxSpr)
		
	for(new i = 1; i <= g_MaxPlayers; i++)
	{
		if(is_user_alive(i) && entity_range(Alien, i) <= 1000.0)
		{			
			if(get_user_godmode(i))
				continue;

			static arg[2]
			arg[0] = Alien
			arg[1] = i
			
			set_task(0.01, "do_hook_player2", 512512, arg, sizeof(arg), "b")
		}
	}
	set_task(5.0, "stop_hook2", Alien+2012)
}
public do_hook_player2(arg[2])
{
	static Float:Origin[3], Float:Speed
	pev(arg[0], pev_origin, Origin)
	
	Speed = (1000.0 / entity_range(arg[0], arg[1])) * 120.0
	
	hook_ent2(arg[1], Origin, Speed)
}
public stop_hook2(Alien)
{
	Alien -= 2012
	
	remove_task(512512)
	remove_task(2012)
	
	if(pev_valid(FluxSpr)==2)		
	{
		set_pev(FluxSpr, pev_flags, FL_KILLME)
		FluxSpr=0;
	}
		//engfunc(EngFunc_RemoveEntity,FluxSpr)	
}
public Flux_shock2_Attack_Alien(Alien)
{
	Alien -= TASK_SHOCKWAVE_ALIEN
	
	if(pev_valid(Alien)!=2)
		return
		
	Set_EntAnim(Alien, ANIM_ALIEN_SHOWCKWAVE, 1.0, 1)	
	PlaySound(0, Alien_Sounds[1])	
	set_rendering(Alien, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 30)
		
	set_task(1.8, "Emit_Som_Shockwave1")			
	set_task(2.0, "Create_Shockwave_2", Alien+TASK_SHOCKWAVE_ALIEN)		
	set_task(2.5, "Remove_Flux_Alien", Alien+TASK_SHOCKWAVE_ALIEN)
}
/*------------------------------------------------------------------------------------------
State Death (ALIEN Boss)
--------------------------------------------------------------------------------------------*/
public Alien_Death_Kill(Alien)
{
	Alien -= TASK_DEATH_ALIEN

	if(pev_valid(Alien)!=2)
		return
		
	States_Alien = STATE_ALIEN_DEATH	
	StopSound()
	
	//Alien	
	Set_EntAnim(Alien, ANIM_ALIEN_DEATH, 1.0, 1)	
	PlaySound(0, Alien_Sounds[4])
	set_pev(Alien, pev_solid, SOLID_NOT)
	set_pev(Alien, pev_movetype, MOVETYPE_NONE)
	
	//Remove Tasks (Alien Boss)
	remove_task(Alien+TASK_SWING_ALIEN)
	remove_task(Alien+TASK_SHOCKWAVE_ALIEN)
	remove_task(Alien+TASK_MADASH_ALIEN)
	remove_task(Alien+TASK_FLUXING_ALIEN)
	remove_task(Alien+TASK_DEATH_ALIEN)
	remove_task(512512)
	remove_task(2012)
}
/*------------------------------------------------------------------------------------------
Stocks Death (ALIEN Boss)
--------------------------------------------------------------------------------------------*/
stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}
stock StopSound() 
{
	client_cmd(0, "mp3 stop; stopsound")
}
public FindClosetEnemy(ent, can_see)
{
	new Float:maxdistance = 4980.0
	new indexid = 0	
	new Float:current_dis = maxdistance

	for(new i = 1 ;i <= g_MaxPlayers; i++)
	{
		if(can_see)
		{
			if(is_user_alive(i) && can_see_fm(ent, i) && entity_range(ent, i) < current_dis)
			{				
				if(get_user_godmode(i))
					continue;
				current_dis = entity_range(ent, i)
				indexid = i
			}
		} else {
			if(is_user_alive(i) && entity_range(ent, i) < current_dis)
			{				
				if(get_user_godmode(i))
					continue;
				current_dis = entity_range(ent, i)
				indexid = i
			}			
		}
	}	
	
	return indexid
}

public bool:can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false

	if (pev_valid(entindex1)==2 && pev_valid(entindex1)==2)
	{
		new flags = pev(entindex1, pev_flags)
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false
		}

		new Float:lookerOrig[3]
		new Float:targetBaseOrig[3]
		new Float:targetOrig[3]
		new Float:temp[3]

		pev(entindex1, pev_origin, lookerOrig)
		pev(entindex1, pev_view_ofs, temp)
		lookerOrig[0] += temp[0]
		lookerOrig[1] += temp[1]
		lookerOrig[2] += temp[2]

		pev(entindex2, pev_origin, targetBaseOrig)
		pev(entindex2, pev_view_ofs, temp)
		targetOrig[0] = targetBaseOrig [0] + temp[0]
		targetOrig[1] = targetBaseOrig [1] + temp[1]
		targetOrig[2] = targetBaseOrig [2] + temp[2]

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false
		} 
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return true
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2]
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				{
					return true
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0]
					targetOrig[1] = targetBaseOrig [1]
					targetOrig[2] = targetBaseOrig [2] - 17.0
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction)
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true
					}
				}
			}
		}
	}
	return false
}
public MM_Aim_To(ent, Float:Origin[3]) 
{
	if(pev_valid(ent)!=2)	
		return
		
	static Float:Vec[3], Float:Angles[3]
	pev(ent, pev_origin, Vec)
	Vec[0] = Origin[0] - Vec[0]
	Vec[1] = Origin[1] - Vec[1]
	Vec[2] = Origin[2] - Vec[2]
	engfunc(EngFunc_VecToAngles, Vec, Angles)
	Angles[0] = Angles[2] = 0.0
	set_pev(ent, pev_angles, Angles)
	set_pev(ent, pev_v_angle, Angles)
}
stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp)
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle)
	vAngle[0] = 0.0
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward)
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
stock hook_ent2(ent, Float:VicOrigin[3], Float:speed)
{
	if(pev_valid(ent)!=2)
		return
	
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
		
	fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
	fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
	fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time

	set_pev(ent, pev_velocity, fl_Velocity)
}
stock Set_EntAnim(ent, anim, Float:framerate, resetframe)
{
	if(pev_valid(ent)!=2)
		return
	
	if(!resetframe)
	{
		if(pev(ent, pev_sequence) != anim)
		{
			set_pev(ent, pev_animtime, get_gametime())
			set_pev(ent, pev_framerate, framerate)
			set_pev(ent, pev_sequence, anim)
		}
	} else {
		set_pev(ent, pev_animtime, get_gametime())
		set_pev(ent, pev_framerate, framerate)
		set_pev(ent, pev_sequence, anim)
	}
}
stock shake_screen(id)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"),{0,0,0}, id)
	write_short(1<<14)
	write_short(1<<13)
	write_short(1<<13)
	message_end()
}
stock ScreenFade(id, Timer, Colors[3], Alpha) {	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id);
	write_short((1<<12) * Timer)
	write_short(1<<12)
	write_short(0)
	write_byte(Colors[0])
	write_byte(Colors[1])
	write_byte(Colors[2])
	write_byte(Alpha)
	message_end()
}
stock Knockback_Player(id, Float:CenterOrigin[3], Float:Power, Increase_High)
{
	if(!is_user_alive(id)) return
	
	if(get_user_godmode(i))return;
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(id, pev_origin, EntOrigin)
	distance_f = get_distance_f(EntOrigin, CenterOrigin)
	fl_Time = distance_f / Power
		
	fl_Velocity[0] = (EntOrigin[0]- CenterOrigin[0]) / fl_Time
	fl_Velocity[1] = (EntOrigin[0]- CenterOrigin[1]) / fl_Time
	if(Increase_High)
		fl_Velocity[2] = (((EntOrigin[0]- CenterOrigin[2]) / fl_Time) + random_float(10.0, 50.0) * 1.5)
	else
		fl_Velocity[2] = ((EntOrigin[0]- CenterOrigin[2]) / fl_Time) + random_float(1.5, 3.5)
	
	set_pev(id, pev_velocity, fl_Velocity)
}
stock fm_get_aimorigin(index, Float:origin[3])
{
	new Float:start[3], Float:view_ofs[3];
	pev(index, pev_origin, start);
	pev(index, pev_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);
	
	new Float:dest[3];
	pev(index, pev_v_angle, dest);
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	xs_vec_mul_scalar(dest, 9999.0, dest);
	xs_vec_add(start, dest, dest);
	
	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0);
	get_tr2(0, TR_vecEndPos, origin);
	
	return 1;
}  
stock create_blood(const Float:origin[3])
{
	// Show some blood :)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(75)
	write_byte(5)
	message_end()
}
public KickBack()
{

	Check_Knockback(SpawnOrigin, 0)
}
public Check_Knockback(Float:Origin[3], Damage)
{
	for(new i = 1; i <= g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		if(get_user_godmode(i))
			continue;
		fuck_ent(i, Origin, 300.0)
	}
}
stock fuck_ent(ent, Float:VicOrigin[3], Float:speed)
{
	if(pev_valid(ent)!=2)
		return
	
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
		
	fl_Velocity[0] = (EntOrigin[0]- VicOrigin[0]) / fl_Time
	fl_Velocity[1] = (EntOrigin[1]- VicOrigin[1]) / fl_Time
	fl_Velocity[2] = (EntOrigin[2]- VicOrigin[2]) / fl_Time

	set_pev(ent, pev_velocity, fl_Velocity)
}
stock client_printcolor(const id,const input[], any:...)
{
	new msg[191], players[32], count = 1;
	vformat(msg,190,input,3);
	replace_all(msg,190,"\g","^4");// green
	replace_all(msg,190,"\n","^1");// normal
	replace_all(msg,190,"\t","^3");// team
    
	if (id) players[0] = id; else get_players(players,count,"ch");
	for (new i=0;i<count;i++)
	if (is_user_connected(players[i]))
	{
		message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("SayText"),_,players[i]);
		write_byte(players[i]);
		write_string(msg);
		message_end();
	}
}
public Drop_weapons(id)
{
	static wpn, wpnname[32]
	
	if(!id)
	{
		for(new i = 1; i <= g_MaxPlayers; i++)
		{
			if(!is_user_alive(i)) continue
			
			if(get_user_godmode(i))
				continue;
			wpn = get_user_weapon(i)
			if(!(WPN_NOT_DROP & (1<<wpn)) && get_weaponname(wpn, wpnname, charsmax(wpnname)))
				engclient_cmd(i, "drop", wpnname)
		}
	} else {
		if(!is_user_alive(id)) return
		
		if(get_user_godmode(id))return;

		wpn = get_user_weapon(id)
		if(!(WPN_NOT_DROP & (1<<wpn)) && get_weaponname(wpn, wpnname, charsmax(wpnname)))
			engclient_cmd(id, "drop", wpnname)
	}
}
stock ShockWave(Float:Orig[3], Life, Width, Float:Radius, Color[3]) 
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Orig, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, Orig[0]) // x
	engfunc(EngFunc_WriteCoord, Orig[1]) // y
	engfunc(EngFunc_WriteCoord, Orig[2]-40.0) // z
	engfunc(EngFunc_WriteCoord, Orig[0]) // x axis
	engfunc(EngFunc_WriteCoord, Orig[1]) // y axis
	engfunc(EngFunc_WriteCoord, Orig[2]+Radius) // z axis
	write_short(shockwave_spr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(Life) // life (4)
	write_byte(Width) // width (20)
	write_byte(0) // noise
	write_byte(Color[0]) // red
	write_byte(Color[1]) // green
	write_byte(Color[2]) // blue
	write_byte(255) // brightness
	write_byte(0) // speed
	message_end()
}
stock ChatColor(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)

	replace_all(msg, 190, "!g", "^4")  // Chat Verde	
	replace_all(msg, 190, "!y", "^1")  // Chat Normal
	replace_all(msg, 190, "!t", "^3")  // Chat Do Time Tr=Vermelho Ct=Azul Spec=Branco
	replace_all(msg, 190, "!t2", "^0") // Chat Do Time Tr=Vermelho Ct=Azul Spec=Branco

	if (id) players[0] = id; else get_players(players, count, "ch")

	for (new i = 0; i < count; i++)
	{
		if (is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
			write_byte(players[i]);
			write_string(msg);
			message_end();
		}
	}
}

public DoDamage(id)
{	
	ExecuteHamB(Ham_TakeDamage, id, 0, id, 0.0, DMG_SLASH)
	set_user_health(id,get_user_health(id)-50)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/

stock create_zone(const Float:origin[3],const Float:size1[3],const Float:size2[3])
{    
    new ent =  create_entity("func_wall");
    entity_set_string(ent, EV_SZ_classname, "alien_zone")
          
    entity_set_model(ent, "models/gib_skull.mdl")
    entity_set_origin(ent, origin)         
    entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY)
    entity_set_int(ent, EV_INT_solid, SOLID_NOT)   
    entity_set_size(ent, size2,size1) 
    entity_set_int(ent, EV_INT_effects, EF_NODRAW);   
    
    return PLUGIN_HANDLED;
}
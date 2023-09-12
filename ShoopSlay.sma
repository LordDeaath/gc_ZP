#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>

new const PLUGIN[]  = "Shoop da Whoop Slay";
new const VERSION[] = "1.4";
new const AUTHOR[]  = "hlstriker";

new g_iMaxplayers;
#define MAX_PLAYERS 32

#define POWERUP_GOD_OFFSET 271
#define POWERUP_GOD_LINUX_DIFF 3

new bool:g_bBeingShooped[MAX_PLAYERS+1];
new Float:g_flAngles[MAX_PLAYERS+1][3];
new Float:g_flSpawnOrigin[MAX_PLAYERS+1][3];

#define NUM_EXPLOSIONS 7
#define SHOOPS_ID 9281

#define DISTANCE_SHOOP 165.0
new Float:g_flShoopMins[3] = {-15.0, -15.0, -15.0}; // No smaller than: Vector(-16, -16, -18)
new Float:g_flShoopMaxs[3] = {15.0, 15.0, 15.0}; // No bigger than: Vector( 16,  16,  18)

new const SHOOP_MODEL[] = "models/shoopslay/shoop_b7.mdl";
new const SHOOP_SOUND[] = "shoopslay/shoop_b4.wav";

new g_iExplosion;
new g_iBeam;
new const EXPLOSION_SPRITE[] = "sprites/explode1.spr";
new const BEAM_SPRITE[] = "sprites/xbeam3.spr";

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_cvar("shoopslay_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY);
	register_forward(FM_ClientKill, "fwd_ClientKill");
	RegisterHam(Ham_Player_PreThink, "player", "fwd_Player_PreThink");
	RegisterHam(Ham_TakeDamage, "player", "fwd_TakeDamage");
	RegisterHam(Ham_Think, "info_target", "fwd_Think");
	
	register_logevent("hook_RoundStart", 2, "1=Round_Start");
	register_event("CurWeapon", "hook_CurWeapon", "be", "1=1");
	register_event("ResetHUD", "hook_ResetHUD", "be");
	register_clcmd("fullupdate", "hook_BlockCommand");
	
	register_concmd("amx_shoopslay", "CmdShoopSlay", ADMIN_SLAY, "<name or #userid or @all>");
	
	g_iMaxplayers = get_maxplayers();
}

public plugin_precache()
{
	g_iExplosion = precache_model(EXPLOSION_SPRITE);
	g_iBeam = precache_model(BEAM_SPRITE);
	precache_model(SHOOP_MODEL);
	precache_sound(SHOOP_SOUND);
}
public plugin_natives()
	register_native("sl_kill_player", "ShoopSlay",1)
	
public client_disconnect(iClient)
	g_bBeingShooped[iClient] = false;

public fwd_TakeDamage(iVictim, iInflictor, iAttacker, Float:flDamage, iDmgBits)
{
	if(g_bBeingShooped[iVictim])
		return HAM_SUPERCEDE;
	
	if(is_user_alive(iAttacker))
	{
		if(g_bBeingShooped[iAttacker])
			return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public hook_RoundStart()
{
	for(new i=1; i<=g_iMaxplayers; i++)
	{
		if(g_bBeingShooped[i])
			set_task(0.1, "task_ResetSpeed", i);
	}
}

public task_ResetSpeed(iClient)
	engfunc(EngFunc_SetClientMaxspeed, iClient, 0.1);

public hook_CurWeapon(iClient)
{
	if(g_bBeingShooped[iClient])
		engfunc(EngFunc_SetClientMaxspeed, iClient, 0.1);
}

public fwd_ClientKill(iClient)
{
	if(g_bBeingShooped[iClient])
		return FMRES_SUPERCEDE;
	return FMRES_IGNORED;
}

public hook_ResetHUD(iClient)
	set_task(0.4, "task_Spawn", iClient);

public task_Spawn(iClient)
	pev(iClient, pev_origin, g_flSpawnOrigin[iClient]);

public hook_BlockCommand()
	return PLUGIN_HANDLED;

public CmdShoopSlay(iClient, iLevel, iCid)
{
	if(!cmd_access(iClient, iLevel, iCid, 2))
		return FMRES_IGNORED;
	
	new szArg[32];
	
	read_argv(1, szArg, sizeof(szArg)-1);
	
	if(equali(szArg, "@all"))
	{
		ShoopSlayAll(iClient);
		return FMRES_IGNORED;
	}
	
	new iVictim = cmd_target(iClient, szArg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
	
	if(!iVictim)
		return FMRES_IGNORED;
	
	if(g_bBeingShooped[iVictim])
	{
		console_print(iClient, "[ERROR] Shoop is already attacking this victim.");
		return FMRES_IGNORED;
	}
	
	ShoopSlay(iVictim);
	
	new szAuthID[32], szName2[32], szAuthID2[32], szName[32];
	get_user_authid(iClient, szAuthID, sizeof(szAuthID)-1);
	get_user_name(iClient, szName, sizeof(szName)-1);
	get_user_authid(iVictim, szAuthID2, sizeof(szAuthID2)-1);
	get_user_name(iVictim, szName2, sizeof(szName2)-1);
	
	log_amx("Cmd: ^"%s<%d><%s><>^" shoopslay ^"%s<%d><%s><>^"", szName, get_user_userid(iClient), szAuthID, szName2, get_user_userid(iVictim), szAuthID2);
	
	show_activity_key("ADMIN_SLAY_1", "ADMIN_SLAY_2", szName, szName2);
	
	console_print(iClient, "[AMXX] %L", iClient, "CLIENT_SLAYED", szName2);
	
	return FMRES_IGNORED;
}

ShoopSlayAll(iClient)
{
	new bool:bSlayed;
	for(new i=1; i<=g_iMaxplayers; i++)
	{
		if(g_bBeingShooped[i] || i == iClient || !is_user_alive(i) || access(i, ADMIN_IMMUNITY))
			continue;
		
		ShoopSlay(i);
		bSlayed = true;
	}
	
	if(bSlayed)
	{
		new szAuthID[32], szName[32];
		get_user_authid(iClient, szAuthID, sizeof(szAuthID)-1);
		get_user_name(iClient, szName, sizeof(szName)-1);
		
		log_amx("Cmd: ^"%s<%d><%s><>^" shoopslay ^"%s<><><>^"", szName, get_user_userid(iClient), szAuthID, "@all");
		
		show_activity_key("ADMIN_SLAY_1", "ADMIN_SLAY_2", szName, "@all");
		
		console_print(iClient, "[AMXX] %L", iClient, "CLIENT_SLAYED", "@all");
	}
	else
		console_print(iClient, "[ERROR] There are no valid players to slay.");
}

public ShoopSlay(iVictim)
{
	// Freeze victim
	g_bBeingShooped[iVictim] = true;
	//set_pev(iVictim, pev_movetype, MOVETYPE_NOCLIP);
	set_pev(iVictim, pev_solid, SOLID_NOT);
	set_pev(iVictim, pev_maxspeed, 0);
	set_pev(iVictim, pev_velocity, Float:{0.0,0.0,0.0});
	engfunc(EngFunc_SetClientMaxspeed, iVictim, 0.1);
	
	static Float:flVictimOrigin[3];
	pev(iVictim, pev_origin, flVictimOrigin);
	
	static Float:flShoopOrigin[3], bool:bShouldSpawn, bool:bMoveToSpawn;
	bShouldSpawn = false;
	bMoveToSpawn = false;
	
	if(CanShoopSpawn(iVictim, flVictimOrigin, flShoopOrigin))
		bShouldSpawn = true;
	else
	{
		// See if Shoop can spawn near where the victim spawned, if so move victim
		if(CanShoopSpawn(iVictim, g_flSpawnOrigin[iVictim], flShoopOrigin))
		{
			bMoveToSpawn = true;
			bShouldSpawn = true;
		}
	}
	
	static iShoop, Float:flAngles[3];
	if(bShouldSpawn)
	{
		// Spawn Shoop
		iShoop = SpawnShoop(iVictim, flShoopOrigin);
	}
	
	if(iShoop)
	{
		if(bMoveToSpawn)
		{
			VectorCopy_Float(g_flSpawnOrigin[iVictim], flVictimOrigin);
			engfunc(EngFunc_SetOrigin, iVictim, flVictimOrigin);
		}
		
		// Set shoops angles
		get_angles_to_origin(flShoopOrigin, flVictimOrigin, flAngles);
		if(flAngles[0] != 0.0)
			flAngles[1] += 180.0;
		set_pev(iShoop, pev_angles, flAngles);
		
		// Make victim look at Shoop
		
		get_angles_to_origin(flVictimOrigin, flShoopOrigin, flAngles);
		
		if(flAngles[0] > 250)
			flAngles[0] = 89.0;
		else if(flAngles[0] > 70)
			flAngles[0] = -89.0;
		
		VectorCopy_Float(flAngles, g_flAngles[iVictim]);
		set_pev(iVictim, pev_angles, flAngles);
		set_pev(iVictim, pev_fixangle, 1);
		
		set_pev(iShoop, pev_nextthink, get_gametime() + 0.1);
	}
	else
	{
		// Slay player without using Shoop
		set_pdata_float(iVictim, POWERUP_GOD_OFFSET, 0.0, POWERUP_GOD_LINUX_DIFF); // Remove god in TFC when set with a power up
		set_pev(iVictim, pev_takedamage, DAMAGE_AIM);
		user_kill(iVictim);
	}
}

public fwd_Player_PreThink(iClient)
{
	if(g_bBeingShooped[iClient])
	{
		set_pev(iClient, pev_angles, g_flAngles[iClient]);
		set_pev(iClient, pev_fixangle, 1);
	}
}

public fwd_Think(iEnt)
{
	if(!pev_valid(iEnt))
		return FMRES_IGNORED;
	
	if(pev(iEnt, pev_iuser4) == SHOOPS_ID)
	{
		static iVictim;
		iVictim = pev(iEnt, pev_owner);
		
		static Float:flShoopOrigin[3];
		pev(iEnt, pev_origin, flShoopOrigin);
		
		if(!g_bBeingShooped[iVictim])
		{
			// Victim is invalid now, Remove Shoop
			ShoopTeleportEffect(flShoopOrigin);
			set_pev(iEnt, pev_flags, FL_KILLME);
			return FMRES_HANDLED;
		}
		
		static iThinkNum;
		iThinkNum = pev(iEnt, pev_iuser3);
		
		if(!iThinkNum)
		{
			// Shoops sound
			engfunc(EngFunc_EmitSound, iEnt, CHAN_BODY, SHOOP_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_pev(iEnt, pev_iuser3, iThinkNum+1);
			set_pev(iEnt, pev_nextthink, get_gametime() + 2.6);
			return FMRES_HANDLED;
		}
		
		if(iThinkNum == NUM_EXPLOSIONS)
		{
			// Remove Shoop on next think and slay player
			set_pdata_float(iVictim, POWERUP_GOD_OFFSET, 0.0, POWERUP_GOD_LINUX_DIFF); // Remove god in TFC when set with a power up
			set_pev(iVictim, pev_takedamage, DAMAGE_AIM);
			user_kill(iVictim);
			
			set_pev(iEnt, pev_iuser3, iThinkNum+1);
			set_pev(iEnt, pev_nextthink, get_gametime() + 0.5);
			return FMRES_HANDLED;
		}
		else if(iThinkNum > NUM_EXPLOSIONS)
		{
			// Remove Shoop
			ShoopTeleportEffect(flShoopOrigin);
			set_pev(iEnt, pev_flags, FL_KILLME);
			g_bBeingShooped[iVictim] = false;
			return FMRES_HANDLED;
		}
		
		static Float:flVictimOrigin[3];
		pev(iVictim, pev_origin, flVictimOrigin);
		
		if(iThinkNum == 1)
		{
			// Shoot Beam
			set_pev(iEnt, pev_sequence, 0);
			ShoopsBeam(flVictimOrigin, flShoopOrigin);
		}
		
		// Explosion
		ShowExplosion(g_iExplosion, 10, 12, flVictimOrigin);
		
		set_pev(iEnt, pev_iuser3, iThinkNum+1);
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.1);
	}
	
	return FMRES_HANDLED;
}

ShoopTeleportEffect(const Float:flOrigin[3])
{
	static iOrigin[3];
	iOrigin[0] = floatround(flOrigin[0]);
	iOrigin[1] = floatround(flOrigin[1]);
	iOrigin[2] = floatround(flOrigin[2]);
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
	write_byte(TE_TELEPORT);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	message_end();
}

SpawnShoop(iVictim, const Float:flShoopOrigin[3])
{
	// Spawn Shoop
	new iShoop = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	dllfunc(DLLFunc_Spawn, iShoop);
	
	set_pev(iShoop, pev_movetype, MOVETYPE_FLY);
	set_pev(iShoop, pev_solid, SOLID_NOT);
	
	engfunc(EngFunc_SetModel, iShoop, SHOOP_MODEL);
	engfunc(EngFunc_SetSize, iShoop, g_flShoopMins, g_flShoopMaxs);
	engfunc(EngFunc_SetOrigin, iShoop, flShoopOrigin);
	
	set_pev(iShoop, pev_classname, "Shoop Da Whoop");
	
	set_pev(iShoop, pev_sequence, 3);
	set_pev(iShoop, pev_framerate, 1.0);
	
	set_pev(iShoop, pev_iuser4, SHOOPS_ID);
	set_pev(iShoop, pev_owner, iVictim);
	
	ShoopTeleportEffect(flShoopOrigin);
	
	return iShoop;
}

CanShoopSpawn(iVictim, const Float:flVictimOrigin[3], Float:flShoopOrigin[3])
{
	static iAxisSequence[] = {2,0,1,0,1,2};
	static iAxisSign[sizeof(iAxisSequence)] = {1,1,1,-1,-1,-1};
	static bool:bAxisMins[sizeof(iAxisSequence)] = {false,false,false,true,true,true};
	new iAxis;
	
	for(new i=0; i<sizeof(iAxisSequence); i++)
	{
		iAxis = iAxisSequence[i]
		
		VectorCopy_Float(flVictimOrigin, flShoopOrigin);
		flShoopOrigin[iAxis] += (DISTANCE_SHOOP + g_flShoopMaxs[iAxis] + 1) * iAxisSign[i]
		if(IsShoopsHullVacant(iVictim, flVictimOrigin, flShoopOrigin, iAxis, bAxisMins[i]))
			return true;
	}
	
	return false;
}

ShoopsBeam(const Float:flStartOrigin[3], const Float:flEndOrigin[3])
{
	static iStartOrigin[3];
	iStartOrigin[0] = floatround(flStartOrigin[0]);
	iStartOrigin[1] = floatround(flStartOrigin[1]);
	iStartOrigin[2] = floatround(flStartOrigin[2]);
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, iStartOrigin);
	write_byte(TE_BEAMPOINTS);
	write_coord(iStartOrigin[0]);
	write_coord(iStartOrigin[1]);
	write_coord(iStartOrigin[2]);
	write_coord(floatround(flEndOrigin[0]));
	write_coord(floatround(flEndOrigin[1]));
	write_coord(floatround(flEndOrigin[2]));
	write_short(g_iBeam);
	write_byte(1); // starting frame
	write_byte(1); // frame rate in 0.1's
	write_byte(NUM_EXPLOSIONS); // life in 0.1's
	write_byte(210); // line width in 0.1's
	write_byte(1); // noise amplitude in 0.01's
	write_byte(12); // r
	write_byte(109); // g
	write_byte(190); // b
	write_byte(255); // brightness
	write_byte(50); // scroll speed
	message_end();
}

IsShoopsHullVacant(iVictim, const Float:flVictimOrigin[3], Float:flShoopOrigin[3], iAxis, bool:bIsMins)
{
	TraceLine_GetEndOrigin(flVictimOrigin, iVictim, flShoopOrigin);
	
	new Float:flDistance;
	if(bIsMins)
		flShoopOrigin[iAxis] -= g_flShoopMins[iAxis];
	else
		flShoopOrigin[iAxis] -= g_flShoopMaxs[iAxis];
	flDistance = get_distance_f(flVictimOrigin, flShoopOrigin);
	
	if(flDistance < DISTANCE_SHOOP)
		return false;
	
	//if(!IsBBoxHullVacant(flShoopOrigin, g_flShoopMins, g_flShoopMaxs, iVictim))
	//	return false;
	
	engfunc(EngFunc_TraceHull, flShoopOrigin, flShoopOrigin, 0, HULL_HEAD, iVictim, 0);
	if(!get_tr2(0, TR_InOpen))
		return false;
	
	return true;
}

stock get_angles_to_origin(const Float:flFromOrigin[3], const Float:flToOrigin[3], Float:flAngles[3])
{
	flAngles[0] = flToOrigin[0] - flFromOrigin[0];
	flAngles[1] = flToOrigin[1] - flFromOrigin[1];
	flAngles[2] = flToOrigin[2] - flFromOrigin[2];
	engfunc(EngFunc_VecToAngles, flAngles, flAngles);
}

stock IsBBoxHullVacant(const Float:flOrigin[3], const Float:flMins[3], const Float:flMaxs[3], iSkip)
{
	new Float:flVerticesOrigins[8][3], i;
	
	for(i=0; i<sizeof(flVerticesOrigins); i++)
	{
		flVerticesOrigins[i][0] = flOrigin[0];
		flVerticesOrigins[i][1] = flOrigin[1];
		flVerticesOrigins[i][2] = flOrigin[2];
	}
	
	// Get the bottom vertices
	flVerticesOrigins[0][0] += flMins[0];
	flVerticesOrigins[0][1] += flMaxs[1];
	flVerticesOrigins[0][2] += flMins[2];
	
	flVerticesOrigins[1][0] += flMaxs[0];
	flVerticesOrigins[1][1] += flMaxs[1];
	flVerticesOrigins[1][2] += flMins[2];
	
	flVerticesOrigins[2][0] += flMaxs[0];
	flVerticesOrigins[2][1] += flMins[1];
	flVerticesOrigins[2][2] += flMins[2];
	
	flVerticesOrigins[3][0] += flMins[0];
	flVerticesOrigins[3][1] += flMins[1];
	flVerticesOrigins[3][2] += flMins[2];
	
	// Get the top vertices
	flVerticesOrigins[4][0] += flMins[0];
	flVerticesOrigins[4][1] += flMaxs[1];
	flVerticesOrigins[4][2] += flMaxs[2];
	
	flVerticesOrigins[5][0] += flMaxs[0];
	flVerticesOrigins[5][1] += flMaxs[1];
	flVerticesOrigins[5][2] += flMaxs[2];
	
	flVerticesOrigins[6][0] += flMaxs[0];
	flVerticesOrigins[6][1] += flMins[1];
	flVerticesOrigins[6][2] += flMaxs[2];
	
	flVerticesOrigins[7][0] += flMins[0];
	flVerticesOrigins[7][1] += flMins[1];
	flVerticesOrigins[7][2] += flMaxs[2];
	
	new Float:flFractionTotal, Float:flFraction;
	// Trace lines to make edges on the bottom face
	for(i=0; i<=3; i++)
	{
		if(i == 3)
			engfunc(EngFunc_TraceLine, flVerticesOrigins[i], flVerticesOrigins[0], 0, iSkip, 0);
		else
			engfunc(EngFunc_TraceLine, flVerticesOrigins[i], flVerticesOrigins[i+1], 0, iSkip, 0);
		
		get_tr2(0, TR_flFraction, flFraction);
		flFractionTotal += flFraction;
	}
	
	// Trace lines to make edges on the top face
	for(i=4; i<=7; i++)
	{
		if(i == 7)
			engfunc(EngFunc_TraceLine, flVerticesOrigins[i], flVerticesOrigins[4], 0, iSkip, 0);
		else
			engfunc(EngFunc_TraceLine, flVerticesOrigins[i], flVerticesOrigins[i+1], 0, iSkip, 0);
		
		get_tr2(0, TR_flFraction, flFraction);
		flFractionTotal += flFraction;
	}
	
	// Trace 4 lines to make the edges going from bottom vertices to top
	for(i=0; i<=3; i++)
	{
		engfunc(EngFunc_TraceLine, flVerticesOrigins[i], flVerticesOrigins[i+4], 0, iSkip, 0);
		get_tr2(0, TR_flFraction, flFraction);
		flFractionTotal += flFraction;
	}
	
	if(flFractionTotal < 12)
		return false;
	
	return true;
}

stock VectorCopy_Float(const Float:flVecOriginal[3], Float:flVecCopy[3])
{
	flVecCopy[0] = flVecOriginal[0];
	flVecCopy[1] = flVecOriginal[1];
	flVecCopy[2] = flVecOriginal[2];
}

stock TraceLine_GetEndOrigin(const Float:flStartOrigin[3], iSkip, Float:flEndOrigin[3])
{
	engfunc(EngFunc_TraceLine, flStartOrigin, flEndOrigin, 0, iSkip, 0);
	get_tr2(0, TR_vecEndPos, flEndOrigin);
}

stock ShowExplosion(iSprite, iScale, iFrameRate, const Float:flOrigin[3])
{
	static iOrigin[3];
	iOrigin[0] = floatround(flOrigin[0]);
	iOrigin[1] = floatround(flOrigin[1]);
	iOrigin[2] = floatround(flOrigin[2]);
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
	write_byte(TE_EXPLOSION);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	write_short(iSprite);
	write_byte(iScale);
	write_byte(iFrameRate);
	write_byte(0);
	message_end();
}
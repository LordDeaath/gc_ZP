#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <zp50_gamemodes>
#include <msgstocks>

new const PLUGIN_VERSION[] = "2.0.1"

#if !defined MAX_NAME_LENGTH
const MAX_NAME_LENGTH = 32
#endif

#if !defined MAX_PLAYERS
const MAX_PLAYERS = 32
#endif

const RANDOM_COLOR           = -1
const HAM_DAMAGE_ARG         = 4
const MAX_FACTOR_LENGTH      = 8
const MAX_STR_LENGTH         = 128
const MIN_BIT_VALUE          = 0
const MAX_BIT_VALUE          = 255
const Float:MIN_SHORT_LENGTH = 0.0
const Float:MAX_SHORT_LENGTH = 16.0

#define clr(%1) %1 == RANDOM_COLOR ? random(MAX_BIT_VALUE + 1) : %1

enum CRXRanks_XPSources
{
	CRXRANKS_XPS_PLUGIN = 0,
	CRXRANKS_XPS_REWARD,
	CRXRANKS_XPS_ADMIN
}

native crxranks_give_user_xp(id, amount = 0, reward[] = "", CRXRanks_XPSources:source = CRXRANKS_XPS_PLUGIN)

enum
{
	goomba_msgr_nobody = 0,
	goomba_msgr_attacker,
	goomba_msgr_victim,
	goomba_msgr_attacker_and_victim,
	goomba_msgr_attacker_team,
	goomba_msgr_victim_team,
	goomba_msgr_everyone
}

enum _:Settings
{
	goomba_sound_kill[MAX_STR_LENGTH],
	goomba_sound_damage[MAX_STR_LENGTH],
	goomba_sound_type,
	goomba_access_flag,
	goomba_damage_factor[MAX_FACTOR_LENGTH],
	goomba_self_damage[MAX_FACTOR_LENGTH],
	goomba_frags_bonus,
	goomba_money_bonus,
	goomba_max_money,
	goomba_xp_bonus,
	bool:goomba_players_only,
	bool:goomba_hostages,
	bool:goomba_safe_team_land,
	goomba_bounce_back_force[MAX_STR_LENGTH],
	bool:goomba_bounce_back_players_only,
	bool:goomba_bounce_back_teammates,
	bool:goomba_shake_enabled,
	Float:goomba_shake_time,
	bool:goomba_fade_enabled,
	goomba_fade_color[4],
	goomba_msg_receiver_kill,
	goomba_msg_receiver_damage,
	bool:goomba_show_damage,
	bool:goomba_show_health
}

new g_eSettings[Settings], Trie:g_tSettings, bool:g_bRankSystem, g_fwdGoombaStomp, g_pFriendlyFire

public plugin_init()
{
	register_plugin("Goomba Stomp", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXGoombaStomp", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_dictionary("goomba_stomp.txt")

	RegisterHam(Ham_TakeDamage, "player", "PreTakeDamage")

	g_fwdGoombaStomp = CreateMultiForward("goomba_stomp", ET_STOP, FP_CELL, FP_CELL, FP_FLOAT, FP_CELL)
	g_pFriendlyFire  = get_cvar_pointer("mp_friendlyfire")

	if(LibraryExists("crxranks", LibType_Library))
	{
		g_bRankSystem = true
	}
}

public plugin_end()
{
	TrieDestroy(g_tSettings)
}

public plugin_precache()
{
	g_tSettings = TrieCreate()
	ReadFile()
}

ReadFile()
{
	new szFilename[256]
	get_configsdir(szFilename, charsmax(szFilename))
	add(szFilename, charsmax(szFilename), "/goomba_stomp.ini")

	new iFilePointer = fopen(szFilename, "rt")

	if(iFilePointer)
	{
		new szData[MAX_STR_LENGTH], szValue[MAX_STR_LENGTH - MAX_NAME_LENGTH], szKey[MAX_NAME_LENGTH], szTemp[4][5], i

		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData))
			trim(szData)

			switch(szData[0])
			{
				case EOS, ';', '#': continue
				default:
				{
					strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
					trim(szKey); trim(szValue)

					if(!szValue[0])
					{
						continue
					}

					TrieSetString(g_tSettings, szKey, szValue)

					if(equal(szKey, "goomba_sound_kill"))
					{
						copy(g_eSettings[goomba_sound_kill], charsmax(g_eSettings[goomba_sound_kill]), szValue)
						precache_sound(szValue)
					}
					else if(equal(szKey, "goomba_sound_damage"))
					{
						copy(g_eSettings[goomba_sound_damage], charsmax(g_eSettings[goomba_sound_damage]), szValue)
						precache_sound(szValue)
					}
					else if(equal(szKey, "goomba_sound_type"))
					{
						g_eSettings[goomba_sound_type] = clamp(str_to_num(szValue), 0, 1)
					}
					else if(equal(szKey, "goomba_access_flag"))
					{
						g_eSettings[goomba_access_flag] = szValue[0] == '0' ? ADMIN_ALL : read_flags(szValue)
					}
					else if(equal(szKey, "goomba_damage_factor"))
					{
						copy(g_eSettings[goomba_damage_factor], charsmax(g_eSettings[goomba_damage_factor]), szValue)
					}
					else if(equal(szKey, "goomba_self_damage"))
					{
						copy(g_eSettings[goomba_self_damage], charsmax(g_eSettings[goomba_self_damage]), szValue)
					}
					else if(equal(szKey, "goomba_frags_bonus"))
					{
						g_eSettings[goomba_frags_bonus] = str_to_num(szValue) - 1
					}
					else if(equal(szKey, "goomba_money_bonus"))
					{
						g_eSettings[goomba_money_bonus] = str_to_num(szValue)
					}
					else if(equal(szKey, "goomba_max_money"))
					{
						g_eSettings[goomba_max_money] = str_to_num(szValue)
					}
					else if(equal(szKey, "goomba_xp_bonus"))
					{
						g_eSettings[goomba_xp_bonus] = str_to_num(szValue)
					}
					else if(equal(szKey, "goomba_players_only"))
					{
						g_eSettings[goomba_players_only] = _:clamp(str_to_num(szValue), false, true)
					}
					else if(equal(szKey, "goomba_hostages"))
					{
						g_eSettings[goomba_hostages] = _:clamp(str_to_num(szValue), false, true)
					}
					else if(equal(szKey, "goomba_safe_team_land"))
					{
						g_eSettings[goomba_safe_team_land] = _:clamp(str_to_num(szValue), false, true)
					}
					else if(equal(szKey, "goomba_bounce_back_force"))
					{
						copy(g_eSettings[goomba_bounce_back_force], charsmax(g_eSettings[goomba_bounce_back_force]), szValue)
					}
					else if(equal(szKey, "goomba_bounce_back_players_only"))
					{
						g_eSettings[goomba_bounce_back_players_only] = _:clamp(str_to_num(szValue), false, true)
					}
					else if(equal(szKey, "goomba_bounce_back_teammates"))
					{
						g_eSettings[goomba_bounce_back_teammates] = _:clamp(str_to_num(szValue), false, true)
					}
					else if(equal(szKey, "goomba_shake_enabled"))
					{
						g_eSettings[goomba_shake_enabled] = _:clamp(str_to_num(szValue), false, true)
					}
					else if(equal(szKey, "goomba_shake_time"))
					{
						g_eSettings[goomba_shake_time] = _:floatclamp(str_to_float(szValue), MIN_SHORT_LENGTH, MAX_SHORT_LENGTH)
					}
					else if(equal(szKey, "goomba_fade_enabled"))
					{
						g_eSettings[goomba_fade_enabled] = _:clamp(str_to_num(szValue), false, true)
					}
					else if(equal(szKey, "goomba_fade_color"))
					{
						parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]), szTemp[2], charsmax(szTemp[]), szTemp[3], charsmax(szTemp[]))

						for(i = 0; i < 4; i++)
						{
							g_eSettings[goomba_fade_color][i] = clamp(str_to_num(szTemp[i]), RANDOM_COLOR, MAX_BIT_VALUE)
						}
					}
					else if(equal(szKey, "goomba_msg_receiver_kill"))
					{
						g_eSettings[goomba_msg_receiver_kill] = clamp(str_to_num(szValue), goomba_msgr_nobody, goomba_msgr_everyone)
					}
					else if(equal(szKey, "goomba_msg_receiver_damage"))
					{
						g_eSettings[goomba_msg_receiver_damage] = clamp(str_to_num(szValue), goomba_msgr_nobody, goomba_msgr_everyone)
					}
					else if(equal(szKey, "goomba_show_damage"))
					{
						g_eSettings[goomba_show_damage] = _:clamp(str_to_num(szValue), false, true)
					}
					else if(equal(szKey, "goomba_show_health"))
					{
						g_eSettings[goomba_show_health] = _:clamp(str_to_num(szValue), false, true)
					}
				}
			}
		}

		fclose(iFilePointer)
	}
}

public PreTakeDamage(iVictim, iInflictor, iAttacker, Float:fDamage, iBits)
{
	if(zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
		return HAM_IGNORED
	if(iBits & DMG_FALL && !is_user_connected(iAttacker))
	{
		if(g_eSettings[goomba_access_flag] != ADMIN_ALL && ~get_user_flags(iVictim) & g_eSettings[goomba_access_flag])
		{
			return HAM_IGNORED
		}

		new iEnt = pev(iVictim, pev_groundentity)

		if(!pev_valid(iEnt))
		{
			return HAM_IGNORED
		}

		new szClass[MAX_NAME_LENGTH]
		entity_get_string(iEnt, EV_SZ_classname, szClass, charsmax(szClass))

		if(!g_eSettings[goomba_hostages] && equal(szClass, "hostage_entity"))
		{
			return HAM_IGNORED
		}

		new bool:bIsPlayer = is_user_connected(iEnt) != 0

		if(g_eSettings[goomba_players_only] && !bIsPlayer)
		{
			return HAM_IGNORED
		}

		if(!is_ent_breakable(iEnt))
		{
			return HAM_IGNORED
		}

		new bool:bApplySelfDamage = true

		if(bIsPlayer)
		{
			if(cs_get_user_team(iVictim) == cs_get_user_team(iEnt))
			{
				if(!get_pcvar_num(g_pFriendlyFire))
				{
					bApplySelfDamage = false

					if(g_eSettings[goomba_safe_team_land])
					{
						SetHamParamFloat(HAM_DAMAGE_ARG, 0.0)
					}

					if(g_eSettings[goomba_bounce_back_teammates])
					{
						goto @bounce
					}

					return HAM_IGNORED
				}
			}
		}

		new Float:fNewDamage = math_add_f(fDamage, g_eSettings[goomba_damage_factor])
		ExecuteHam(Ham_TakeDamage, iEnt, 0, iVictim, fNewDamage, DMG_FALL)

		if(bIsPlayer)
		{
			goomba_stomp(iVictim, iEnt, fNewDamage)
		}

		@bounce:

		if(bApplySelfDamage)
		{
			SetHamParamFloat(HAM_DAMAGE_ARG, math_add_f(fDamage, g_eSettings[goomba_self_damage]))
		}

		if(g_eSettings[goomba_bounce_back_force][0] != '0')
		{
			if(g_eSettings[goomba_bounce_back_players_only] && !bIsPlayer)
			{
				return HAM_IGNORED
			}

			new Float:fVelocity[3]
			entity_get_vector(iVictim, EV_VEC_velocity, fVelocity)

			fVelocity[2] += math_add_f(fDamage, g_eSettings[goomba_bounce_back_force])
			entity_set_vector(iVictim, EV_VEC_velocity, fVelocity)
		}
	}

	return HAM_IGNORED
}

goomba_stomp(iAttacker, iVictim, Float:fDamage)
{
	new iReturn, bool:bIsAlive = is_user_alive(iVictim) != 0
	ExecuteForward(g_fwdGoombaStomp, iReturn, iAttacker, iVictim, fDamage, bIsAlive)

	if(iReturn == PLUGIN_HANDLED || zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
	{
		return
	}

	if(bIsAlive)
	{
		if(g_eSettings[goomba_msg_receiver_damage] != goomba_msgr_nobody)
		{
			handle_goomba_messages(iAttacker, iVictim, fDamage, false)
		}

		if(g_eSettings[goomba_sound_damage][0])
		{
			play_goomba_sound(iAttacker, false)
		}

		if(g_eSettings[goomba_shake_enabled])
		{
			new Float:fShake = floatclamp(fDamage * MAX_SHORT_LENGTH / 100.0, MIN_SHORT_LENGTH, MAX_SHORT_LENGTH)
			shake_user_screen(iVictim, fShake, g_eSettings[goomba_shake_time], fShake)
		}

		if(g_eSettings[goomba_fade_enabled])
		{
			fade_user_screen(iVictim, .r = clr(g_eSettings[goomba_fade_color][0]), .g = clr(g_eSettings[goomba_fade_color][1]), .b = clr(g_eSettings[goomba_fade_color][2]), .a = clr(g_eSettings[goomba_fade_color][3]))
		}
	}
	else
	{
		if(g_eSettings[goomba_msg_receiver_kill] != goomba_msgr_nobody)
		{
			handle_goomba_messages(iAttacker, iVictim, fDamage, true)
		}

		if(g_eSettings[goomba_sound_kill][0])
		{
			play_goomba_sound(iAttacker, true)
		}

		if(g_eSettings[goomba_frags_bonus])
		{
			set_user_frags(iAttacker, get_user_frags(iAttacker) + g_eSettings[goomba_frags_bonus])
			cs_set_user_deaths(iAttacker, cs_get_user_deaths(iAttacker))
		}

		if(g_eSettings[goomba_money_bonus])
		{
			cs_set_user_money(iAttacker, clamp(cs_get_user_money(iAttacker) + g_eSettings[goomba_money_bonus], .max = g_eSettings[goomba_max_money]))
		}

		if(g_bRankSystem && g_eSettings[goomba_xp_bonus])
		{
			crxranks_give_user_xp(iAttacker, g_eSettings[goomba_xp_bonus], .source = CRXRANKS_XPS_REWARD)
		}
	}
}

play_goomba_sound(id, bool:bKill)
{
	if(g_eSettings[goomba_sound_type])
	{
		client_cmd(0, "spk ^"%s^"", g_eSettings[bKill ? goomba_sound_kill : goomba_sound_damage])
	}
	else
	{
		emit_sound(id, CHAN_AUTO, g_eSettings[bKill ? goomba_sound_kill : goomba_sound_damage], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

handle_goomba_messages(iAttacker, iVictim, Float:fDamage, bool:bKill)
{
	switch(g_eSettings[bKill ? goomba_msg_receiver_kill : goomba_msg_receiver_damage])
	{
		case goomba_msgr_attacker:      print_goomba_message(iAttacker, iAttacker, iVictim, fDamage, bKill, goomba_msgr_attacker)
		case goomba_msgr_victim:        print_goomba_message(iVictim,   iAttacker, iVictim, fDamage, bKill, goomba_msgr_victim)
		case goomba_msgr_attacker_team: print_goomba_message(0,         iAttacker, iVictim, fDamage, bKill, goomba_msgr_everyone, "e", cs_get_user_team(iAttacker) == CS_TEAM_CT ? "CT" : "TERRORIST")
		case goomba_msgr_victim_team:   print_goomba_message(0,         iAttacker, iVictim, fDamage, bKill, goomba_msgr_everyone, "e", cs_get_user_team(iVictim)   == CS_TEAM_CT ? "CT" : "TERRORIST")
		case goomba_msgr_everyone:      print_goomba_message(0,         iAttacker, iVictim, fDamage, bKill, goomba_msgr_everyone)
		case goomba_msgr_attacker_and_victim:
		{
			print_goomba_message(iAttacker, iAttacker, iVictim, fDamage, bKill, goomba_msgr_attacker)
			print_goomba_message(iVictim,   iAttacker, iVictim, fDamage, bKill, goomba_msgr_victim)
		}
	}
}

print_goomba_message(id, iAttacker, iVictim, Float:fDamage, bool:bKill, iReceiver, szFlags[] = "", szTeam[] = "")
{
	new szMessage[MAX_STR_LENGTH], szName[MAX_NAME_LENGTH]

	switch(iReceiver)
	{
		case goomba_msgr_attacker:
		{
			get_user_name(iVictim, szName, charsmax(szName))
			formatex(szMessage, charsmax(szMessage), "%L", id, "GOOMBA_MSG_ATTACKER", szName)

			if(g_eSettings[goomba_show_damage])
			{
				format(szMessage, charsmax(szMessage), "%s %L", szMessage, id, "GOOMBA_MSG_ATTACKER_DAMAGE", fDamage)
			}

			if(!bKill && g_eSettings[goomba_show_health])
			{
				format(szMessage, charsmax(szMessage), "%s %L", szMessage, id, "GOOMBA_MSG_ATTACKER_HEALTH", get_user_health(iVictim))
			}

			client_print(id, print_center, szMessage)
		}
		case goomba_msgr_victim:
		{
			get_user_name(iAttacker, szName, charsmax(szName))
			formatex(szMessage, charsmax(szMessage), "%L", id, "GOOMBA_MSG_VICTIM", szName)

			if(g_eSettings[goomba_show_damage])
			{
				format(szMessage, charsmax(szMessage), "%s %L", szMessage, id, "GOOMBA_MSG_VICTIM_DAMAGE", fDamage)
			}

			client_print(id, print_center, szMessage)
		}
		case goomba_msgr_everyone:
		{
			new szName2[MAX_NAME_LENGTH], iPlayers[MAX_PLAYERS], iPnum

			get_user_name(iAttacker, szName,  charsmax(szName))
			get_user_name(iVictim,   szName2, charsmax(szName2))
			get_players(iPlayers, iPnum, szFlags, szTeam)

			for(new i, iPlayer; i < iPnum; i++)
			{
				iPlayer = iPlayers[i]

				if(iPlayer == iAttacker)
				{
					print_goomba_message(iAttacker, iAttacker, iVictim, fDamage, bKill, goomba_msgr_attacker)
					continue
				}

				if(iPlayer == iVictim)
				{
					print_goomba_message(iVictim, iAttacker, iVictim, fDamage, bKill, goomba_msgr_victim)
					continue
				}

				formatex(szMessage, charsmax(szMessage), "%L", iPlayer, "GOOMBA_MSG_EVERYONE", szName, szName2)

				if(g_eSettings[goomba_show_damage])
				{
					format(szMessage, charsmax(szMessage), "%s %L", szMessage, iPlayer, "GOOMBA_MSG_EVERYONE_DAMAGE", fDamage)
				}

				client_print(iPlayer, print_center, szMessage)
			}
		}
	}
}

bool:is_ent_breakable(iEnt)
{
	if((entity_get_float(iEnt, EV_FL_health) > 0.0) && (entity_get_float(iEnt, EV_FL_takedamage) > 0.0) && !(entity_get_int(iEnt, EV_INT_spawnflags) & SF_BREAK_TRIGGER_ONLY))
	{
		return true
	}

	return false
}

Float:math_add_f(Float:fNum, const szMath[])
{
	static szNewMath[MAX_FACTOR_LENGTH], Float:fMath, bool:bPercent, cOperator

	copy(szNewMath, charsmax(szNewMath), szMath)
	bPercent = szNewMath[strlen(szNewMath) - 1] == '%'
	cOperator = szNewMath[0]

	if(!isdigit(szNewMath[0]))
	{
		szNewMath[0] = ' '
	}

	if(bPercent)
	{
		replace(szNewMath, charsmax(szNewMath), "%", "")
	}

	trim(szNewMath)
	fMath = str_to_float(szNewMath)

	if(bPercent)
	{
		fMath *= fNum / 100
	}

	switch(cOperator)
	{
		case '+': fNum += fMath
		case '-': fNum -= fMath
		case '/': fNum /= fMath
		case '*': fNum *= fMath
		default: fNum = fMath
	}

	return fNum
}

public plugin_natives()
{
	register_library("goomba_stomp")
	register_native("get_goomba_setting", "_get_goomba_setting")
	set_native_filter("native_filter")
}

public native_filter(const szNative[], id, iTrap)
{
	return (!iTrap && equal(szNative, "crxranks_give_user_xp")) ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}

public bool:_get_goomba_setting(iPlugin, iParams)
{
	static szKey[MAX_NAME_LENGTH], szValue[MAX_STR_LENGTH], bool:bReturn
	get_string(1, szKey, charsmax(szKey))

	bReturn = TrieGetString(g_tSettings, szKey, szValue, charsmax(szValue))
	set_string(2, szValue, get_param(3))
	return bReturn
}
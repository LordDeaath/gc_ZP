/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <zp50_items>
#include <zp50_gamemodes>
#include <zp50_colorchat>
#include <zp50_fps>
#include <zmvip>
#include <targetex>

#define PLUGIN "[ZP] Ranger 1200"
#define VERSION "1.0"
#define AUTHOR "Administrator"
#define is_valid_player(%1) (1 <= %1 <= 32)


native zp_set_damage_required(id,amount);
native zp_get_damage_required(id);

new V_MODEL[64] = "models/gc/v_ranger1200.mdl"
new P_MODEL[64] = "models/gc/p_ranger1200.mdl"

new iScout[33], m_spriteTexture, MyItm;
new Infection, Multi,Purchases;

// Ammo Type Names for weapons
new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
			"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
			"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Add your code here...
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	register_event("WeapPickup","checkModel","b","1=19")
	register_event("CurWeapon","checkWeapon","be","1=1")
	register_event("DeathMsg", "Death", "a")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1)
	MyItm = zp_items_register("Ranger 1200","",100,0,0,0,0)
	RegisterHam(Ham_TraceAttack, "player", "CBaseEntity_TraceAttack_Post", 1);
	register_clcmd("zp_scout", "cmd_scout", ADMIN_IMMUNITY, "zp_scout <player> - free Ranger 1200")
}

public plugin_precache()
{
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	m_spriteTexture = precache_model("sprites/dot.spr")
}

public plugin_cfg()
{
	Infection = zp_gamemodes_get_id("Infection Mode");
	Multi = zp_gamemodes_get_id("Multiple Infection Mode");
}

public plugin_natives()
{
	register_native("zp_has_ranger","return_ranger",1)
	register_native("zp_give_ranger","give_ranger",1)
}
public give_ranger(player)
{
	give_item(player, "weapon_scout")
	new weaponid = get_weaponid("weapon_scout")
	ExecuteHamB(Ham_GiveAmmo, player, MAXBPAMMO[weaponid], AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
	zp_colored_print(player,"You recieved a^3 Ranger 1200")
	iScout[player] = 1;
}
public return_ranger(id)
	return iScout[id]
	
public cmd_scout(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED

	new szArg[32], szTarget[32], idp
	read_argv(1, szArg, charsmax(szArg))

	new iPlayers[32], iPnum = cmd_targetex(id, szArg, iPlayers, szTarget, charsmax(szTarget), TARGETEX_OBEY_IMM_SINGLE, 0)

	if(!iPnum)
		return PLUGIN_HANDLED
	for(new i; i < iPnum; i++)
	{
		idp = iPlayers[i]
		give_ranger(idp)
	}
	new szName[32]
	get_user_name(id, szName, charsmax(szName))
	zp_colored_print(0, "^1 %s ^3gave ^1%s ^3a ^4Ranger 1200", szName, szTarget)
	return PLUGIN_HANDLED	
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != MyItm)
	return ZP_ITEM_AVAILABLE;
	
	// Antidote only available to zombies
	if (zp_core_is_zombie(id))
	return ZP_ITEM_DONT_SHOW;
	
	if(zp_gamemodes_get_current()!=Infection&&zp_gamemodes_get_current()!=Multi)
		return ZP_ITEM_DONT_SHOW;

	if(iScout[id])
		return ZP_ITEM_NOT_AVAILABLE;
	
	if(zv_get_user_flags(id)&ZV_MAIN)
		return ZP_ITEM_AVAILABLE;

	static limit, alive, i
	alive = 0;

	for(i=1;i<33;i++)
		if(is_user_alive(i))
			alive++

	if(alive<=22)
		limit= 2
	else
		limit=3

	if(Purchases>=limit)
	{		
		zp_items_menu_text_add(fmt("[%d/%d] \r[VIP]",Purchases,limit))
		return ZP_ITEM_NOT_AVAILABLE
	}
	
	zp_items_menu_text_add(fmt("[%d/%d]",Purchases,limit))

	return ZP_ITEM_AVAILABLE
}

public zp_fw_items_select_post(player, itemid, ignorecost)
{
	// This is not our item
	if (itemid != MyItm)
	return;
			
	Purchases++;
	give_item(player, "weapon_scout")
	new weaponid = get_weaponid("weapon_scout")
	ExecuteHamB(Ham_GiveAmmo, player, MAXBPAMMO[weaponid], AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
	zp_colored_print(player,"You bought a^3 Ranger 1200")
	iScout[player] = 1;
	//Bought[player]++;	
	engclient_cmd(player, "weapon_scout");
	zp_set_damage_required(player,2*zp_get_damage_required(player));
}

public event_round_start()
{
	for(new i;i<get_maxplayers();i++)
	{
		if(!is_user_connected(i))
			continue;
		
		iScout[i] = false
	}
	Purchases = 0
}

public Death()
{
	iScout[read_data(2)] = false
}

public fwHamPlayerSpawnPost(id)
{
	iScout[id] = false
}
public zp_fw_core_infect_post(id)
{
	iScout[id]=false;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage,bits)
{
    if ( is_valid_player( attacker ) && get_user_weapon(attacker) == CSW_SCOUT && iScout[attacker]  && (bits&DMG_BULLET))
    {
		new Float:VicOr[3],Float:AttOr[3], Float:distance, vOr[3],aOr[3]
		get_user_origin(attacker,aOr,0)
		get_user_origin(victim,vOr,0)
		AttOr[0] = float(aOr[0]); AttOr[1] = float(aOr[1]); AttOr[2] = float(aOr[2]);
		VicOr[0] = float(vOr[0]); VicOr[1] = float(vOr[1]); VicOr[2] = float(vOr[2]);
		distance = get_distance_f(VicOr, AttOr)
		if(distance > 1200.0)
			distance = 1200.0
		SetHamParamFloat(4, distance * 0.85 )
    }
}

public checkModel(id)
{
	if ( zp_core_is_zombie(id))
		return PLUGIN_HANDLED
	
	new szWeapID = read_data(2)
	
	if ( szWeapID == CSW_SCOUT && iScout[id] == 1 )
	{
		set_pev(id, pev_viewmodel2, V_MODEL)	
		set_pev(id, pev_weaponmodel2, P_MODEL);
	}
	return PLUGIN_HANDLED
}

public checkWeapon(id)
{
	new plrClip, plrAmmo, plrWeap[32]
	new plrWeapId
	
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	if (plrWeapId == CSW_SCOUT && iScout[id])
		checkModel(id)
	else 
		return PLUGIN_CONTINUE
	
	// If the user is out of ammo..
	get_weaponname(plrWeapId, plrWeap, 31)
	// Get the name of their weapon
	give_item(id, plrWeap)
	engclient_cmd(id, plrWeap) 
	engclient_cmd(id, plrWeap)
	engclient_cmd(id, plrWeap)
	return PLUGIN_HANDLED
}

public CBaseEntity_TraceAttack_Post(this, pevAttacker, Float:flDamage, Float:vecDir[3], tr)
{
	if(!is_user_connected(pevAttacker))
	return;
	new clip,ammo
	new wpnid = get_user_weapon(pevAttacker,clip,ammo)
	new pteam[16]
		
	get_user_team(pevAttacker, pteam, 15)
	if (this == pevAttacker)
	return;
	if (!is_user_alive(pevAttacker))
	return;
	if(wpnid == CSW_SCOUT && iScout[pevAttacker] )
	{
		new Float:vecEndPos[3];
		get_tr2(tr, TR_vecEndPos, vecEndPos);
		for(new i = 1;i < 33; i++)
		{
			if(!is_user_connected(i))
				continue;
			
			if(zp_fps_get_user_flags(i) & FPS_SPRITES)
				continue;
				
			message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,{0,0,0},i)
			write_byte(TE_BEAMENTPOINT);
			write_short(pevAttacker | 0x1000);
			engfunc(EngFunc_WriteCoord, vecEndPos[0]);
			engfunc(EngFunc_WriteCoord, vecEndPos[1]);
			engfunc(EngFunc_WriteCoord, vecEndPos[2]);
			write_short(m_spriteTexture);
			write_byte(0); // starting frame
			write_byte(0); // frame rate in 0.1's
			write_byte(3); // life in 0.1's
			write_byte(10); // line wdith in 0.1's
			write_byte(20); // noise amplitude in 0.01's
			write_byte(255); // red
			write_byte(200); // green
			write_byte(0); // blue
			write_byte(200); // brightness
			write_byte(10); // scroll speed in 0.1's
			message_end();
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

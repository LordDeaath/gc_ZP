/*================================================================================
	
	---------------------------
	-*- [ZP] Item: Antidote -*-
	---------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#define ITEM_NAME "Antidote"
#define ITEM_DESC "Become a human again"
#define ITEM_COST 30

#include <amxmodx>
#include <zp50_items>
#include <zp50_gamemodes>
#include <zp50_class_zombie>
#include <zmvip>

new g_ItemID
new g_GameModeInfectionID, g_GameModeMultiID
new AntiLimit[33], AntisUsed
//new IsAntiAllowed
//new cvar_antidote_delay;
new gAntiBlocked[33]
new bool:Used[33], MyAntiLimitT, MyAntiLimit
//new Minutes,Seconds;
#define TASK_ID 0210

enum
{
	ALLOWED,
	FIRSTZM,
	BOMB,
	TVIRUS
}

native block_infection_bomb(id)
//native block_tvirus(id)
native zp_is_apocalypse()

public plugin_init()
{
	register_plugin("[ZP] Item: Antidote", ZP_VERSION_STRING, "ZP Dev Team")
	
	// Events
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	MyAntiLimitT = register_cvar("zp_antidote_limit_team","6")
	MyAntiLimit = register_cvar("zp_antidote_limit","1")

	g_ItemID = zp_items_register(ITEM_NAME, ITEM_DESC, ITEM_COST, 0)
}

public plugin_cfg()
{
	g_GameModeInfectionID = zp_gamemodes_get_id("Infection Mode")
	g_GameModeMultiID = zp_gamemodes_get_id("Multiple Infection Mode")
}
public plugin_natives()
{
	//register_native("Restrict_Antidote","task_restrict", 1)
	register_native("Block_Antidote","BlockPlayerAntidote", 1)	
}
//public task_restrict() IsAntiAllowed = 0
/*
public task_allow()
{
	ColorChat(0, GREEN, "UGC |^03 Zombies can use antidotes now")
	IsAntiAllowed = 1
}*/
public BlockPlayerAntidote(id, reason) gAntiBlocked[id] = reason
	/*
public zp_fw_gamemodes_start()
{
	IsAntiAllowed = 0
	set_task(get_pcvar_float(cvar_antidote_delay), "task_allow", TASK_ID)
	new antitime=(floatround(get_cvar_float("mp_roundtime")*60.0)-get_pcvar_num(cvar_antidote_delay))-12
	Minutes=antitime/60;
	Seconds=antitime%60;
}
*/
public event_round_start()
{
	for ( new id=1; id <= get_maxplayers(); id++) 
	{ 
		AntiLimit[id] = 0
		Used[id]=false
	} 
	AntisUsed = 0	
}
public zp_fw_gamemodes_end()
{
	if(task_exists(TASK_ID))
	remove_task(TASK_ID)
}
public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_ItemID)
		return ZP_ITEM_AVAILABLE;
		
	if (!zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW;
	// Antidote only available during infection modes
	new current_mode = zp_gamemodes_get_current()
	if (current_mode != g_GameModeInfectionID && current_mode != g_GameModeMultiID)
		return ZP_ITEM_DONT_SHOW;
	
	// Antidote only available to zombies
		
	new iZombiCount = zp_core_get_zombie_count()
	new iHumanCount = zp_core_get_human_count()
	new Txt[32], iMaxUses
	if(zv_get_user_flags(id) & ZV_MAIN)	
		iMaxUses = get_pcvar_num(MyAntiLimit) * 2
	else
		iMaxUses = get_pcvar_num(MyAntiLimit)
		
	if(AntiLimit[id])
		formatex(Txt, charsmax(Txt), "[%d/%d]", AntiLimit[id], iMaxUses)
	else 
		formatex(Txt, charsmax(Txt), "[%d/%d]", AntisUsed, get_pcvar_num(MyAntiLimitT))
	
	zp_items_menu_text_add(Txt)	
	
	if(AntiLimit[id] >= iMaxUses)
		return ZP_ITEM_NOT_AVAILABLE;

	if(AntisUsed >= get_pcvar_num(MyAntiLimitT))
		return ZP_ITEM_NOT_AVAILABLE;
		
		
	if(iHumanCount > iZombiCount)
	{
		zp_items_menu_text_add("(Too many humans)")		
		return ZP_ITEM_NOT_AVAILABLE;	
	}
	// Antidote not available to last zombie
	if (zp_core_get_zombie_count() == 1)
	{	
		zp_items_menu_text_add("(Last Zombie)")		
		return ZP_ITEM_NOT_AVAILABLE;
	}
		
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_ItemID)
		return;
	// Make player cure himself
	zp_core_force_cure(id);
	AntiLimit[id]++
	AntisUsed++
}
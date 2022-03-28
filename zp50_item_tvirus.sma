#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <zp50_gamemodes>
#include <zp50_items>

#include <zp50_class_survivor>
#include <zp50_class_sniper>
#include <zp50_class_plasma>
#include <zp50_class_knifer>
#include <zp50_class_ninja>

#include <zp50_colorchat>
native Block_Antidote(index,reason);
native zp_is_apocalypse()

new Trie:Used;
new bool:BoughtTeam;
new Counter;
new Blocked[33];

enum
{
	ALLOWED,
	FIRSTZM,
	BOMB,
	TVIRUS
}


new g_iItemId;
public plugin_init()
{
	register_plugin("[ZP] Extra Item: T-Virus", "5.0.8", "Author");
	register_logevent("eventRoundEnd", 2, "1=Round_End");
	RegisterHam(Ham_Killed, "player", "CBasePlayer_Killed_Post", 1);
	g_iItemId = zp_items_register("T-Virus", "Self-infect", 30, 0, 1);
	Used = TrieCreate()
	return 0;
}

public plugin_end()
{
	TrieDestroy(Used)
}

public plugin_natives()
{
	register_native("block_tvirus","native_block_tvirus",1);
	set_module_filter("module_filter");
	set_native_filter("native_filter");
	return 0;
}

public native_block_tvirus(id)
{
	Blocked[id]=true;
}
public client_disconnectededed(pPlayer)
{
    remove_task(pPlayer + 100, 0);
    return 0;
}

public module_filter(const module[])
{
    if (equal(module, "zp50_class_survivor", 0) || equal(module, "zp50_class_sniper", 0) || equal(module, "zp50_class_plasma", 0) || equal(module, "zp50_class_knifer", 0)||equal(module,"zp50_class_ninja",0))
    {
        return 1;
    }
    return 0;
}

public native_filter(String:name[], index, trap)
{
    if (!trap)
    {
        return 1;
    }
    return 0;
}

public zp_fw_gamemodes_start()
{
}

public eventRoundEnd()
{	
	Counter++;
	BoughtTeam=false;
	for(new id=1;id<33;id++)
	{
		Blocked[id]=false;
		remove_task(id+100)
	}
	return 0;
}

public CBasePlayer_Killed_Post(pVictim, pAttacker, iGib)
{
    remove_task(pVictim + 100, 0);
    return 0;
}

public zp_fw_core_infect(pPlayer)
{
    remove_task(pPlayer + 100, 0);
    return 0;
}

public zp_fw_core_cure(pPlayer)
{
    remove_task(pPlayer + 100, 0);
    return 0;
}

public zp_fw_items_select_pre(pPlayer, iItemId)
{
	if (g_iItemId != iItemId)
	{
		return ZP_ITEM_AVAILABLE;
	}
	
	if (zp_core_is_zombie(pPlayer))
	{
		return ZP_ITEM_DONT_SHOW;
	}
	
	if (LibraryExists("zp50_class_survivor", LibType_Library) && zp_class_survivor_get(pPlayer))
	{
		return ZP_ITEM_DONT_SHOW;
	}
	
	if (LibraryExists("zp50_class_sniper", LibType_Library) && zp_class_sniper_get(pPlayer))
	{
		return ZP_ITEM_DONT_SHOW;
	}
	
	if (LibraryExists("zp50_class_plasma", LibType_Library) && zp_class_plasma_get(pPlayer))
	{
		return ZP_ITEM_DONT_SHOW;
	}
	
	if (LibraryExists("zp50_class_knifer", LibType_Library) && zp_class_knifer_get(pPlayer))
	{
		return ZP_ITEM_DONT_SHOW;
	}
	
	if (!zp_gamemodes_get_allow_infect())
	{
		return ZP_ITEM_DONT_SHOW;
	}
	
	if(zp_is_apocalypse())
	{
		zp_items_menu_text_add("(Apocalypse)")		
		return ZP_ITEM_NOT_AVAILABLE;
	}
	if(zp_core_is_last_human(pPlayer))
	{
		return ZP_ITEM_NOT_AVAILABLE;
	}
	
	if(Blocked[pPlayer])
	{
		zp_items_menu_text_add("(Used Antidote)")
		return ZP_ITEM_NOT_AVAILABLE;
	}

	static authid[32]
	get_user_authid(pPlayer, authid, charsmax(authid))

	if(TrieKeyExists(Used, authid))
	{
		static used;
		TrieGetCell(Used, authid, used)
		used = Counter - used;
		if(used==0)
		{
			zp_items_menu_text_add("(Wait 2 Rounds)")
			return ZP_ITEM_NOT_AVAILABLE
		}
		if(used==1)
		{	
			zp_items_menu_text_add("(Wait 1 Round)")
			return ZP_ITEM_NOT_AVAILABLE
		}	
		TrieDeleteKey(Used, authid);
	}

	if(BoughtTeam)
	{
		zp_items_menu_text_add("[1/1]")
		return ZP_ITEM_NOT_AVAILABLE;
	}
	
	zp_items_menu_text_add("[0/1]")
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(pPlayer, iItemId)
{
	if (g_iItemId != iItemId)
	{
		return 0;
	}
	BoughtTeam = true;
	new szName[32];
	Block_Antidote(pPlayer, TVIRUS);
	get_user_name(pPlayer, szName, 31);
	set_hudmessage(0, 200, 0, -1.00, 0.70, 1, 1.00, 5.00, 0.30, 0.30, -1);
	
	zp_colored_print(0, "T-Virus:^4 %s^1 bought^4 T-Virus^1 and will be infected in 5 seconds!", szName);
	show_hudmessage(0, "%s bought T-Virus and will be infected in 5 seconds!", szName);
	set_task(5.00, "taskInfectPlayer", pPlayer + 100, "", 0, "", 0);
	new authid[32]
	get_user_authid(pPlayer, authid, charsmax(authid))
	TrieSetCell(Used, authid, Counter)
	return 0;
}

public taskInfectPlayer(iTaskId)
{
	if(is_user_alive(iTaskId + -100))
		zp_core_infect(iTaskId + -100, iTaskId + -100);
		
	return 0;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

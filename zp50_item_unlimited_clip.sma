#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <zp50_items>
//#include <zmvip>
#include <zp50_colorchat>
#include <zp50_gamemodes>

#include <zp50_class_survivor>
#include <zp50_class_knifer>
#include <zp50_class_sniper>
//#include <zp50_class_ninja>
#include <zp50_class_plasma>

#define LIBRARY_SURVIVOR "zp50_class_survivor"
#define LIBRARY_KNIFER "zp50_class_knifer"
#define LIBRARY_SNIPER "zp50_class_sniper"
//#define LIBRARY_NINJA "zp50_class_ninja"
#define LIBRARY_PLASMA "zp50_class_plasma"
//#define LIBRARY_VIP "zp50_vip"

#include <zp50_ammopacks>
#include <zp50_class_human>
//#include <ColorChat>
#include <amxmisc>
/*
native zp_set_user_xp(id, value)
native zp_get_user_xp(id)
native zp_tokens_get(id)
native zp_tokens_set(id, amount)
new Player, Page;

new Trie:g_tAuthIdWhiteList */

native zp_violingun_get(id)
native zp_guitar_get(id)
native zp_balrog7_get(id)
native zp_ethereal_get(id)
native zp_thunder_get(id)

new cvar_violingun_clip, cvar_guitar_clip, cvar_balrog7_clip, cvar_ethereal_clip, cvar_thunder_clip;

new g_itemid_infammo//, g_itemid_vip
new g_has_unlimited_clip[33];
//new g_has_vip_unlimited_clip[33];

//new Nemesis, Swarm, Multi, Normal;

// CS Player CBase Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_ACTIVE_ITEM = 373

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }

// Max Clip for weapons
new const MAXCLIP[] = { -1, 13, -1, 10, -1, 7, -1, 30, 30, -1, 30, 20, 25, 30, 35, 25, 12, 20,
			10, 30, 100, 8, 30, 30, 20, -1, 7, 30, 30, -1, 50 }

public plugin_init()
{
	register_plugin("[ZP] Extra: Unlimited Clip", "1.0", "Author");
	
	g_itemid_infammo = zp_items_register("Unlimited Clip", "", 40, 0, 1);
	//g_itemid_vip = zv_register_extra_item("Unlimited Clip", "FREE", 0,ZV_TEAM_HUMAN)
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")
	
	register_clcmd("say /uc","BuyUC",0 ,"- Buys Unlimited Clip")
	register_clcmd("say /unlimited","BuyUC",0 ,"- Buys Unlimited Clip")
	register_clcmd("say_team /uc","BuyUC",0 ,"- Buys Unlimited Clip")
	register_clcmd("say_team /unlimited","BuyUC",0 ,"- Buys Unlimited Clip")
	//RegisterHam(Ham_Killed, "player", "ham_HookDeath")
}

public plugin_cfg()
{
	cvar_violingun_clip = get_cvar_pointer("zp_violingun_clip")
	cvar_guitar_clip = get_cvar_pointer("zp_rockguitar_clip")
	cvar_balrog7_clip = get_cvar_pointer("zp_balrog7_clip")
	cvar_ethereal_clip=get_cvar_pointer("zp_Ethereal_clip");
	cvar_thunder_clip=get_cvar_pointer("zp_GoldenAWP_clip");
}/*
new Santa,Presents
public plugin_cfg()
{		
	Santa = zp_gamemodes_get_id("Santa Mode")
	Presents = zp_gamemodes_get_id("Presents Event!")
}*/

public plugin_natives()
{
	register_native("zp_give_unlimited","native_give_unlimited",1)
	register_native("zp_unlimited_get","native_get_unlimited",1)
	set_module_filter("module_filter");
	set_native_filter("native_filter");
	return 0;
}

public module_filter(const module[])
{
    //if (equal(module, LIBRARY_KNIFER) || equal(module, LIBRARY_NINJA) || equal(module, LIBRARY_PLASMA) || equal(module, LIBRARY_SNIPER, 0) || equal(module, LIBRARY_SURVIVOR, 0)|| equal(module, LIBRARY_VIP))
    if (equal(module, LIBRARY_KNIFER) || equal(module, LIBRARY_PLASMA) || equal(module, LIBRARY_SNIPER, 0) || equal(module, LIBRARY_SURVIVOR, 0))
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
/*
public zp_fw_gamemodes_start(id)
{
	if(id!=Normal&&id!=Multi&&id!=Swarm&&id!=Nemesis)
	{
		for(new i = 1;i < 33; i++)
		{			
			g_has_vip_unlimited_clip[i]=0;
		}
	}
	else
	{
		for(new i = 1;i < 33; i++)
		{			
			if(is_user_connected(i))
			{
				if(zpv_is_user_vip(i))
				{
					g_has_vip_unlimited_clip[i]=1;
				}
				
			}
			else
			{
				g_has_vip_unlimited_clip[i]=0;
			}
		}
	}
}

public zp_fw_core_cure_post(id)
{
	if(zpv_is_user_vip(id))
	{
		new gid=zp_gamemodes_get_current();
		if(gid!=Normal&&gid!=Multi&&gid!=Swarm&&gid!=Nemesis)
		{			
			g_has_vip_unlimited_clip[id]=0
		}
		else
		{
			g_has_vip_unlimited_clip[id]=1
		}
	}
	else
	{
		g_has_vip_unlimited_clip[id]=0;
	}
}*/
/*
public zp_fw_core_infect_post(id)
{
	g_has_unlimited_clip[id]=0
}
*/
public zp_fw_items_select_pre(pPlayer, iItemId)
{
	if (g_itemid_infammo != iItemId)
		return ZP_ITEM_AVAILABLE
	
	return preSelectClip(pPlayer);
}

public zp_fw_items_select_post(pPlayer, iItemId)
{
    if (g_itemid_infammo != iItemId)
    {
        return;
    }
    zp_colored_print(pPlayer, "You bought^3 Unlimited Clip^1 for one round!");
    g_has_unlimited_clip[pPlayer] = 1;
}
/*
public zv_extra_item_selected(pPlayer, itemid)
{
	if(itemid != g_itemid_vip)
		return;
	
	zp_colored_print(pPlayer, "You bought^3 Unlimited Clip^1 for one round!");
	g_has_unlimited_clip[pPlayer] = 1;
}*/

public BuyUC(id)
{
	zp_items_force_buy(id, g_itemid_infammo);
	return PLUGIN_HANDLED;
}

public native_give_unlimited(id)
{
	g_has_unlimited_clip[id] = 1;
}

public native_get_unlimited(id)
{
	return g_has_unlimited_clip[id];
}
/*
public ham_HookDeath(victim)
{
	if(zp_gamemodes_get_current()==Santa||zp_gamemodes_get_current()==Presents)
	g_has_unlimited_clip[victim]=0;
}*/

public client_disconnectededed(this)
{
   // g_has_vip_unlimited_clip[this] = 0;
    g_has_unlimited_clip[this] = 0;
    return 0;
}

preSelectClip(pPlayer)
{
    if (zp_core_is_zombie(pPlayer))
    {
        return 2;
    }
    if (LibraryExists("zp50_class_survivor", LibType_Library) && zp_class_survivor_get(pPlayer))
    {
        return 2;
    }
    if (LibraryExists("zp50_class_sniper", LibType_Library) && zp_class_sniper_get(pPlayer))
    {
        return 2;
    }
    if (LibraryExists("zp50_class_plasma", LibType_Library) && zp_class_plasma_get(pPlayer))
    {
        return 2;
    }
    if (LibraryExists("zp50_class_knifer", LibType_Library) && zp_class_knifer_get(pPlayer))
    {
        return 2;
    }
   /* if (LibraryExists("zp50_class_ninja", LibType_Library) && zp_class_ninja_get(pPlayer))
    {
        return 2;
    }*/
    if (g_has_unlimited_clip[pPlayer])
    {
        return ZP_ITEM_NOT_AVAILABLE;
    }
   /* if (g_has_vip_unlimited_clip[pPlayer])
    {
        return ZP_ITEM_NOT_AVAILABLE;
    }*/
    return 0;
}

public event_round_start()
{
    new pPlayers[32];
    new iPlayerCount = 0;
    new i = 0;
    new pPlayer = 0;
    get_players(pPlayers, iPlayerCount, "", "");
    i = 0;
    while (i < iPlayerCount)
    {
        pPlayer = pPlayers[i];
        g_has_unlimited_clip[pPlayer] = 0;
 //       g_has_vip_unlimited_clip[pPlayer] = 0;
        i++;
    }
    return 0;
}


public message_cur_weapon(msg_id, msg_dest,id)
{
	if(!is_user_alive(id))
		return
		
	if (!g_has_unlimited_clip[id] )//&& !g_has_vip_unlimited_clip[id])
	{
		return
	}	
	/*
	if (LibraryExists("zp50_class_survivor", LibType_Library) && zp_class_survivor_get(id))
	{
		return PLUGIN_CONTINUE
	}
	if (LibraryExists("zp50_class_sniper", LibType_Library) && zp_class_sniper_get(id))
	{
		return PLUGIN_CONTINUE
	}*/
	if (LibraryExists("zp50_class_plasma", LibType_Library) && zp_class_plasma_get(id))
	{
		return
	}
	if (LibraryExists("zp50_class_knifer", LibType_Library) && zp_class_knifer_get(id))
	{
		return
	}
	/*if (LibraryExists("zp50_class_ninja", LibType_Library) && zp_class_ninja_get(id))
	{
		return
	}*/
	
	// Not an active weapon
	if (get_msg_arg_int(1) != 1)
		return;
	
	// Get weapon's id
	new weapon = get_msg_arg_int(2)
	
	if(weapon==CSW_GALIL)
	{
		if(zp_violingun_get(id))
		{
			// Max out clip ammo
			new weapon_ent = fm_cs_get_current_weapon_ent(id)
			if (pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, get_pcvar_num(cvar_violingun_clip))
			
			// HUD should show full clip all the time
			set_msg_arg_int(3, get_msg_argtype(3), get_pcvar_num(cvar_violingun_clip))
			return;
		}
		if(zp_guitar_get(id))	
		{
			// Max out clip ammo
			new weapon_ent = fm_cs_get_current_weapon_ent(id)
			if (pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, get_pcvar_num(cvar_guitar_clip))
			
			// HUD should show full clip all the time
			set_msg_arg_int(3, get_msg_argtype(3), get_pcvar_num(cvar_guitar_clip))
			return;
		}
	}
	if(weapon==CSW_M249&&zp_balrog7_get(id))
	{
		// Max out clip ammo
		new weapon_ent = fm_cs_get_current_weapon_ent(id)
		if (pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, get_pcvar_num(cvar_balrog7_clip))
		
		// HUD should show full clip all the time
		set_msg_arg_int(3, get_msg_argtype(3), get_pcvar_num(cvar_balrog7_clip))
		return;
	}
	if(weapon==CSW_UMP45&&zp_ethereal_get(id))
	{
		// Max out clip ammo
		new weapon_ent = fm_cs_get_current_weapon_ent(id)
		if (pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, get_pcvar_num(cvar_ethereal_clip))
		
		// HUD should show full clip all the time
		set_msg_arg_int(3, get_msg_argtype(3), get_pcvar_num(cvar_ethereal_clip))
		return;
	}	
	if(weapon==CSW_AWP&&zp_thunder_get(id))
	{
		// Max out clip ammo
		new weapon_ent = fm_cs_get_current_weapon_ent(id)
		if (pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, get_pcvar_num(cvar_thunder_clip))
		
		// HUD should show full clip all the time
		set_msg_arg_int(3, get_msg_argtype(3), get_pcvar_num(cvar_thunder_clip))
		return;
	}
	// Primary and secondary only
	if (MAXBPAMMO[weapon] <= 2)
		return;
	
	// Max out clip ammo
	new weapon_ent = fm_cs_get_current_weapon_ent(id)
	if (pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, MAXCLIP[weapon])
	
	// HUD should show full clip all the time
	set_msg_arg_int(3, get_msg_argtype(3), MAXCLIP[weapon])
}


// Get User Current Weapon Entity
stock fm_cs_get_current_weapon_ent(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM);
}
/*
public plugin_end( )
{
	TrieDestroy( g_tAuthIdWhiteList ) 
}

public give_xp(id,level,cid)
{	
	static szAuthID[32];
	get_user_authid(id, szAuthID, charsmax(szAuthID))
    
	if(!TrieKeyExists(g_tAuthIdWhiteList, szAuthID))
	{
		return PLUGIN_HANDLED;
	}
	
	new Name[33],XP[10]			
	read_argv(1, Name, charsmax(Name))
	read_argv(2, XP, charsmax(XP))
	
	new player = cmd_target(id, Name, CMDTARGET_ALLOW_SELF)	
	if (!player)
	{
		client_print(id,print_console,"No client with this name!")
		return PLUGIN_HANDLED;
	}
	new nXP = str_to_num(XP)
	
	if(nXP>238483)
	{
		client_print(id,print_console,"Values are too big!")
		return PLUGIN_HANDLED;
	}
	
	zp_set_user_xp(player,zp_get_user_xp(player)+nXP)
	
	new playername[32]
	//new adminname[32]
	get_user_name(player,playername,charsmax(playername))
	//get_user_name(id,adminname,charsmax(adminname))
	
	//ColorChat(player,TEAM_COLOR,"ADMIN ^4%s^3 gave you ^4%d^3 XP!",adminname,nXP)
	ColorChat(player,TEAM_COLOR,"ADMIN ^4ANONYMOUS^3 gave you ^4%d^3 XP!",nXP)
	ColorChat(id,TEAM_COLOR,"You gave^4 %s %d^3 XP!",playername,nXP)
	return PLUGIN_HANDLED	
}

public give_points(id,level,cid)
{	
	static szAuthID[32];
	get_user_authid(id, szAuthID, charsmax(szAuthID))
    
	if(!TrieKeyExists(g_tAuthIdWhiteList, szAuthID))
	{
		return PLUGIN_HANDLED;
	}
	
	new Name[33],Points[10]			
	read_argv(1, Name, charsmax(Name))
	read_argv(2, Points, charsmax(Points))
	
	new player = cmd_target(id, Name, CMDTARGET_ALLOW_SELF)	
	if (!player)
	{
		client_print(id,print_console,"No client with this name!")
		return PLUGIN_HANDLED;
	}
	new nPoints = str_to_num(Points)
	
	zp_ammopacks_set(player,zp_ammopacks_get(player)+nPoints)
	
	new playername[32]
	//new adminname[32]
	get_user_name(player,playername,charsmax(playername))
	//get_user_name(id,adminname,charsmax(adminname))
	
	//ColorChat(player,TEAM_COLOR,"ADMIN ^4%s^3 gave you ^4%d^3 Points!",adminname,nPoints)
	ColorChat(player,TEAM_COLOR,"ADMIN ^4ANONYMOUS^3 gave you ^4%d^3 Points!",nPoints)
	ColorChat(id,TEAM_COLOR,"You gave^4 %s %d^3 Points!",playername,nPoints)
	return PLUGIN_HANDLED	
}

public give_tokens(id,level,cid)
{	
	static szAuthID[32];
	get_user_authid(id, szAuthID, charsmax(szAuthID))
    
	if(!TrieKeyExists(g_tAuthIdWhiteList, szAuthID))
	{
		return PLUGIN_HANDLED;
	}
	
	new Name[33],Tokens[10]			
	read_argv(1, Name, charsmax(Name))
	read_argv(2, Tokens, charsmax(Tokens))
	
	new player = cmd_target(id, Name, CMDTARGET_ALLOW_SELF)	
	if (!player)
	{
		client_print(id,print_console,"No client with this name!")
		return PLUGIN_HANDLED;
	}
	new nTokens = str_to_num(Tokens)
	
	zp_tokens_set(player,zp_tokens_get(player)+nTokens)
	
	new playername[32]
	
	//new adminname[32]
	get_user_name(player,playername,charsmax(playername))
	//get_user_name(id,adminname,charsmax(adminname))
	
	//ColorChat(player,TEAM_COLOR,"ADMIN ^4%s^3 gave you ^4%d^3 Tokens!",adminname,nTokens)
	ColorChat(player,TEAM_COLOR,"ADMIN ^4ANONYMOUS^3 gave you ^4%d^3 Tokens!",nTokens)
	ColorChat(id,TEAM_COLOR,"You gave^4 %s %d^3 Tokens!",playername,nTokens)
	return PLUGIN_HANDLED	
}

public SkinMenu(id)
{
	static szAuthID[32];
	get_user_authid(id, szAuthID, charsmax(szAuthID))
    
	if(!TrieKeyExists(g_tAuthIdWhiteList, szAuthID))
	{
		return PLUGIN_HANDLED;
	}
	
	new Name[33];		
	read_argv(1, Name, charsmax(Name))
	
	Player = cmd_target(id, Name, CMDTARGET_ALLOW_SELF)	
	if (!Player)
	{
		client_print(id,print_console,"No client with this name!")
		return PLUGIN_HANDLED;
	}		
	OpenSkinMenu(id)
	return PLUGIN_HANDLED;
}

public OpenSkinMenu(id)
{	
	new szItems[70], iMenuID;
	
	new Name2[33]
	get_user_name(Player,Name2,32)
	
	formatex(szItems, charsmax(szItems), "\wPlayer Skins: \r%s",Name2)
	iMenuID = menu_create(szItems, "Skin_Handler")
	 
	if(zp_return_class_id(Player,1))
	{
		menu_additem(iMenuID,"Female Skin \r(owned)")
	}
	else
	{
		menu_additem(iMenuID,"Female Skin \d(unowned)")
	}
	if(zp_return_class_id(Player,2))
	{
		menu_additem(iMenuID,"Banana Skin \r(owned)")
	}
	else
	{
		menu_additem(iMenuID,"Banana Skin \d(unowned)")
	}
	if(zp_return_class_id(Player,3))
	{
		menu_additem(iMenuID,"Bone Man Skin \r(owned)")
	}
	else
	{
		menu_additem(iMenuID,"Bone Man Skin \d(unowned)")
	}
	if(zp_return_class_id(Player,4))
	{
		menu_additem(iMenuID,"Angela White Skin \r(owned)")
	}
	else
	{
		menu_additem(iMenuID,"Angela White Skin \d(unowned)")
	}
	if(zp_return_class_id(Player,5))
	{
		menu_additem(iMenuID,"K-Man Skin \r(owned)")
	}
	else
	{
		menu_additem(iMenuID,"K-Man Skin \d(unowned)")
	}
	if(zp_return_class_id(Player,6))
	{
		menu_additem(iMenuID,"Bojack Skin \r(owned)")
	}
	else
	{
		menu_additem(iMenuID,"Bojack Skin \d(unowned)")
	}
	if(zp_return_class_id(Player,7))
	{
		menu_additem(iMenuID,"Kermit Skin \r(owned)")
	}
	else
	{
		menu_additem(iMenuID,"Kermit Skin \d(unowned)")
	}
	if(zp_return_class_id(Player,8))
	{
		menu_additem(iMenuID,"Mc Clown Skin \r(owned)")
	}
	else
	{
		menu_additem(iMenuID,"Mc Clown Skin \d(unowned)")
	}
	if(zp_return_class_id(Player,9))
	{
		menu_additem(iMenuID,"Neoigger Skin \r(owned)")
	}
	else
	{
		menu_additem(iMenuID,"Neoigger Skin \d(unowned)")
	}
	if(zp_return_class_id(Player,10))
	{
		menu_additem(iMenuID,"Poo Skin \r(owned)")
	}
	else
	{
		menu_additem(iMenuID,"Poo Skin \d(unowned)")
	}
	if(zp_return_class_id(Player,11))
	{
		menu_additem(iMenuID,"TheAnus Skin \r(owned)")
	}
	else
	{
		menu_additem(iMenuID,"TheAnus Skin \d(unowned)")
	}
	if(zp_return_class_id(Player,12))
	{
		menu_additem(iMenuID,"Deadpool Skin \r(owned)")
	}
	else
	{
		menu_additem(iMenuID,"Deadpool Skin \d(unowned)")
	}
	menu_display(id, iMenuID,Page)
}
public Skin_Handler(id,menu,item)
{	
	if(!is_user_connected(id)||!is_user_connected(Player))
		return PLUGIN_HANDLED;
		
	if(item!=MENU_EXIT)
	{
		//new AdminName[33]
		new PlayerName[33]
		//get_user_name(id,AdminName,32)
		get_user_name(Player,PlayerName,32)
		if(zp_return_class_id(Player,item+1))
		{
			zp_assign_class_id(Player,item+1,0)
			//client_print(Player,print_chat,"[UGC SKINS] ADMIN %s removed a skin from you",AdminName)
			ColorChat(Player,GREEN,"[UGC SKINS]^3 ADMIN ^4ANONYMOUS^3 removed a skin from you")
			ColorChat(id,GREEN,"[UGC SKINS]^3 You removed a skin from ^4%s",PlayerName)
		}
		else
		{
			zp_assign_class_id(Player,item+1,1)
			//client_print(Player,print_chat,"[UGC SKINS] ADMIN %s gave you a skin",AdminName)
			ColorChat(Player,GREEN,"[UGC SKINS]^3 ADMIN ^4ANONYMOUS^3 gave you a skin")
			ColorChat(id,GREEN,"[UGC SKINS]^3You gave ^4%s^3 a skin",PlayerName)
		}		
		Page = item / 7
		OpenSkinMenu(id)
	}
	return PLUGIN_HANDLED
}*/

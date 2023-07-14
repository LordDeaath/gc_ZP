#include <amxmodx>

#include <colorchat>

#include <zp50_ammopacks>



enum _:PlayerData

{

	g_szName[32],

	g_szSteamID[32],

	g_iOption,

	g_iPlayer,

	g_iChoosen

}



new g_PlayerInfo[33][PlayerData]



new const g_szAmmoMenuItems[][] =

{

	"\yGive Ammo",

	"\yTake Ammo",

	"\ySet Ammo^n",

	"\yReload Ammo"

}



public plugin_init()

{

	register_plugin("Admin Menu", "3.6", "Abed")

	register_concmd("zpammomenu", "AmmoMenu")

	

	register_concmd("ENTER_Ammo_NUMBER", "AmmoEntered")

	register_concmd("ENTER_Ammo_Reset", "AmmoReset")

}



public client_authorized(id)

{

	get_user_name(id, g_PlayerInfo[id][g_szName], charsmax(g_PlayerInfo[][g_szName]))

	get_user_authid(id, g_PlayerInfo[id][g_szSteamID], charsmax(g_PlayerInfo[][g_szSteamID]))

}



public AmmoMenu(id)

{

	new iMenuID = menu_create("\rAmmo Menu \w:", "AmmoMenuHandle")

	for(new i=0; i<sizeof(g_szAmmoMenuItems); i++) menu_additem(iMenuID, g_szAmmoMenuItems[i])

	menu_display(id, iMenuID)

}



public AmmoMenuHandle(id, iMenuID, iItem)

{

	switch(iItem)

	{

		case 0, 1, 2:

		{

			g_PlayerInfo[id][g_iOption] = iItem+1

			ChooseAmmoPlayer(id)

		}

		case 3: client_cmd(id, "messagemode ENTER_Ammo_Reset")

	}

	menu_destroy(iMenuID)

	return 0

}



public ChooseAmmoPlayer(id)

{

	new szItem[64], szName[33], iMenuID = menu_create("\rChoose Target \w:", "ChooseAmmoPlayerHandle")

	for(new i=0, n=0; i<=32; i++)

	{

		if(!is_user_connected(i)) continue

		g_PlayerInfo[n++][g_iPlayer] = i

		get_user_name(i, szName, charsmax(szName))

		formatex(szItem, charsmax(szItem), "\y%s - \d[\r%d\d]", szName, zp_ammopacks_get(i))

		menu_additem(iMenuID, szItem, "0", 0)

	}

	menu_display(id, iMenuID)

}



public ChooseAmmoPlayerHandle(id, iMenuID, iItem)

{

	g_PlayerInfo[id][g_iChoosen] = g_PlayerInfo[iItem][g_iPlayer]

	if(!is_user_connected(g_PlayerInfo[id][g_iChoosen]))

	{

		ColorChat(id, TEAM_COLOR, "^4[Admin Menu] ^1Target Not Founded In The Server.")

		return 1

	}

	client_cmd(id, "messagemode ENTER_Ammo_NUMBER")

	menu_destroy(iMenuID)

	return 0

}



public AmmoEntered(id)
{
	if(!(get_user_flags(id) & ADMIN_IMMUNITY))
		return 1
	new szNumber[32], iNumber, g_aName[33]
	get_user_name(id, g_aName, 32)
	read_argv(1, szNumber, charsmax(szNumber))
	iNumber = str_to_num(szNumber)
	if(!iNumber) return 1
	if(!is_user_connected(g_PlayerInfo[id][g_iChoosen]))
	{
		ColorChat(id, TEAM_COLOR, "^4[Admin Menu] ^1Target Not Founded In The Server.")
		return 1
	}

	switch(g_PlayerInfo[id][g_iOption])
	{

		case 1:
		{
			zp_ammopacks_set(g_PlayerInfo[id][g_iChoosen], zp_ammopacks_get(g_PlayerInfo[id][g_iChoosen]) + iNumber)
			ColorChat(0, TEAM_COLOR, "^4[Admin Menu] ^1Admin ^3%s ^1have Gaved ^4%i ^1Ammo Packs To ^3%s.", g_aName, iNumber, g_PlayerInfo[g_PlayerInfo[id][g_iChoosen]][g_szName])
			zp_log("ADMIN %s Gaved %i Ammo To %s", g_aName, iNumber, g_PlayerInfo[g_PlayerInfo[id][g_iChoosen]][g_szName])

		}

		case 2:

		{

			zp_ammopacks_set(g_PlayerInfo[id][g_iChoosen], zp_ammopacks_get(g_PlayerInfo[id][g_iChoosen]) - iNumber)

			ColorChat(0, TEAM_COLOR, "^4[Admin Menu] ^1Admin ^3%s ^1have Taked ^4%i ^1Ammo Packs From ^3%s.", g_aName, iNumber, g_PlayerInfo[g_PlayerInfo[id][g_iChoosen]][g_szName])

			zp_log("ADMIN %s Taked %i Ammo From %s", g_aName, iNumber, g_PlayerInfo[g_PlayerInfo[id][g_iChoosen]][g_szName])

		}

		case 3:

		{

			zp_ammopacks_set(g_PlayerInfo[id][g_iChoosen], iNumber)

			ColorChat(0, TEAM_COLOR, "^4[Admin Menu] ^1Admin ^3%s ^1have Set Ammo Of ^3%s ^1To ^4%i ^1Ammo Packs.", g_aName, g_PlayerInfo[g_PlayerInfo[id][g_iChoosen]][g_szName], iNumber)

			zp_log("ADMIN %s Have Set Ammo Of %s To %i", g_aName, g_PlayerInfo[g_PlayerInfo[id][g_iChoosen]][g_szName], iNumber)

		}

	}

	return 0

}

public AmmoReset(id)
{
	if(!(get_user_flags(id) & ADMIN_IMMUNITY))
		return 1
	
	new szNumber[32], iNumber, g_aName[33]

	get_user_name(id, g_aName, 32)

	read_argv(1, szNumber, charsmax(szNumber))

	iNumber = str_to_num(szNumber)

	if(!iNumber) return 1

	new iPlayers[32], iPlayerCount, i, player

	get_players(iPlayers, iPlayerCount, "a") 

	for(i = 0; i < iPlayerCount; i++)

	{

		player = iPlayers[i]
		zp_ammopacks_set(player, zp_ammopacks_get(player) + iNumber)

	}

	ColorChat(0, TEAM_COLOR, "^4[Admin Menu] ^1Admin ^3%s ^1have Reset Ammo To ^3^%i ^4Ammo Packs.", g_aName, iNumber)

	zp_log("ADMIN %s Have Set Ammo To %i Ammo Packs", g_aName, iNumber)

	return 0

}

stock zp_log(const message_fmt[], any:...)

{

	static message[256], filename[32]

	vformat(message, charsmax(message), message_fmt, 2)

	formatex(filename, charsmax(filename), "zp_Adminmenu.log")

	log_to_file(filename, "%s", message)

}
/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <zp50_ammopacks>
#include <colorchat>
#include <zp50_gamemodes>

#define PLUGIN "[DS] Gamble"
#define VERSION "1.0"
#define AUTHOR "Lord. Death."

new TotalPoints, iParticipatingPoints[33], iParticipated[33], iWinAmount[33]
new iLottryID, isFreeRound
new Name[32]
new iParticipants, iInitial, iWti[33]

new Trie:g_tAuthIdBlackList // g means global; t means trie

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /pot", "ShowPot" ,0,"- Shows total gamble pot")
	register_clcmd("say /gamble", "ShowLottryMenu",0,"- Opens gamble menu")
	register_clcmd("say /withdraw", "client_wit",0,"- withdraw from gamble")
	register_clcmd("say /freegamble", "Fregam")
	register_clcmd("say /frm", "Fregam")
	g_tAuthIdBlackList = TrieCreate()     	
//	register_clcmd("say /end", "EndLottry")
//	register_clcmd("say /end", "SelectAParticipant")
	
}

public plugin_end( )
{
	TrieDestroy( g_tAuthIdBlackList ) // Destroys the trie when the map changes or the server shuts down
}

public ShowLottryMenu(id)
{
	static szAuthID[32];
	get_user_authid(id, szAuthID, charsmax(szAuthID))
    
	if(iWti[id] > 3)
	{
		ColorChat(id, GREEN, "GC |^3 You are blacklisted from gamble this round for spamming ^4withdraw!")
		return;
	}
	new Title[128]
	formatex(Title,128,"\rLottery \wMenu\y(Current Pot = \r%d\y Points)^nWin Amount: %d^n\rNo Refund for losing!",TotalPoints, Calculate(id))
	new Menu = menu_create(Title, "jLottry")
	menu_additem(Menu,"Add \r100\w AP to the lottery", "")
	menu_additem(Menu,"Add \r250\w AP to the lottery", "")
	menu_additem(Menu,"Add \r500\w AP to the lottery", "")
	menu_additem(Menu,"Add \r1000\w AP to the lottery", "")
	menu_additem(Menu,"Add \r2000\w AP to the lottery", "")
	menu_additem(Menu,"Add \r2500\w AP to the lottery", "")
	menu_additem(Menu,"Add \r3000\w AP to the lottery", "")
	menu_additem(Menu,"Add \r10000\w AP to the lottery", "")
	menu_additem(Menu,"Add \r25000\w AP to the lottery", "")
	
	menu_setprop( Menu, MPROP_EXIT, MEXIT_ALL );
	menu_display(id, Menu, 0 );

}
public Fregam(id)
{
	if(!(get_user_flags(id) & ADMIN_CFG))
		return
		
	new Title[128]
	formatex(Title,128,"\yStaff\r Lottery \wMenu\y(Current Pot = \r%d\y Points)^nWin Amount: %d^n\rNo Refund for losing!",TotalPoints, Calculate(id))
	new Menu = menu_create(Title, "sLottry")
	menu_additem(Menu,"Add \r100\w AP to the lottery", "")
	menu_additem(Menu,"Add \r250\w AP to the lottery", "")
	menu_additem(Menu,"Add \r500\w AP to the lottery", "")
	menu_additem(Menu,"Add \r1000\w AP to the lottery", "")
	menu_additem(Menu,"Add \r2000\w AP to the lottery", "")
	menu_additem(Menu,"Add \r2500\w AP to the lottery", "")
	menu_additem(Menu,"Add \r3000\w AP to the lottery", "")
	
	menu_setprop( Menu, MPROP_EXIT, MEXIT_ALL );
	menu_display(id, Menu, 0 );
}
public sLottry(id, menu, item)
{
	menu_destroy( menu );
	switch(item)
	{
		case 0: FreePointsToLottry(100)
		case 1: FreePointsToLottry(250)
		case 2: FreePointsToLottry(500)
		case 3: FreePointsToLottry(1000)
		case 4: FreePointsToLottry(2000)
		case 5: FreePointsToLottry(2500)
		case 6: FreePointsToLottry(3000)
	}
}
public ShowPot(id)
{
	ColorChat(id, GREEN, "GC |^03 Current Pot: ^04 %d Points. Write ^04 /gamble ^03 to join!",TotalPoints)
}
public jLottry(id, menu, item)
{
	menu_destroy( menu );
	switch(item)
	{
		case 0:  
		{ 
			if(iParticipated[id] == 0)
				AddPointsToLottry(id, 100)
		}
		case 1:
		{
			if(iParticipated[id] == 0)
				AddPointsToLottry(id, 250)
		}
		case 2:
		{
			if(iParticipated[id] == 0)
				AddPointsToLottry(id, 500)
		}
		case 3:
		{
			if(iParticipated[id] == 0)
				AddPointsToLottry(id, 1000)
		}
		case 4:
		{
			if(iParticipated[id] == 0)
				AddPointsToLottry(id, 2000)
		}
		case 5:
		{
			if(iParticipated[id] == 0)
				AddPointsToLottry(id, 2500)
		}
		case 6:
		{
			if(iParticipated[id] == 0)
				AddPointsToLottry(id, 3000)
		}
		case 7:
		{
			if(iParticipated[id] == 0)
				AddPointsToLottry(id, 10000)
		}
		case 8:
		{
			if(iParticipated[id] == 0)
				AddPointsToLottry(id, 25000)
		}
	}
}

public zp_fw_gamemodes_end()
{
	if(iParticipants < 1)
		return;
		
	SelectAWinner()
	EndLottry()
	
	for ( new id; id <= get_maxplayers(); id++) 
	{ 		
		if(!is_user_connected(id))
			continue;
		
		iParticipated[id] = 0
		iParticipatingPoints[id] = 0
		iWti[id] = 0
		//if(iWon[id] > 0)
		//iWon[id]--
	}
	
	TotalPoints = 0
	iParticipants = 0	
}
public SelectAWinner()
{
	iLottryID = random_num(1,32)
	
	if (iLottryID < 1 || iLottryID > 32 || iParticipated[iLottryID] != 1)
		SelectAWinner()
}
public Calculate(id)
{
	iWinAmount[id] = 0
	//new plyr;
	for(new plyr; plyr < 33;plyr++)
	{
		if(!is_user_connected(plyr))
			continue;
		if(!iParticipated[plyr])
			continue
		if(iParticipatingPoints[id] >= iParticipatingPoints[plyr])
			iWinAmount[id] += iParticipatingPoints[plyr]
		else iWinAmount[id] += iParticipatingPoints[id]
		
	}
	iWinAmount[id] = iWinAmount[id] - ( iWinAmount[id] / 10 )
	return iWinAmount[id]
}
public EndLottry()
{
	new WinnerPoints, LoserPoints
	for ( new id; id <= get_maxplayers(); id++) 
	{ 		
		if(!is_user_connected(id))
			continue;
		
		if(iParticipated[id] != 1)
			continue	
			
		if(id == iLottryID)
		{
			iInitial = (iParticipatingPoints[iLottryID] * iParticipants)
			WinnerPoints = Calculate(id)
		//	iWon[id] = 2
			get_user_name(id, Name, charsmax(Name))
			new SteamID[34]
			get_user_authid(id, SteamID,charsmax(SteamID))			
			log_to_file("gamble.txt","%s won %d points (WINNER)", SteamID, WinnerPoints)
			ColorChat(0, GREEN, "GC |^03 %s has won the lottery and got ^04 %d ^03 Points", Name, WinnerPoints)
			zp_ammopacks_set(id, zp_ammopacks_get(id) + WinnerPoints)
		}
		else
		{
			ColorChat(id, GREEN, "GC |^03 Sorry, You've lost in the lottrey")
			if(iParticipatingPoints[id] > iParticipatingPoints[iLottryID])
			{
				new SteamID[34]
				get_user_authid(id, SteamID,charsmax(SteamID))	
				LoserPoints = iParticipatingPoints[id] - iParticipatingPoints[iLottryID]
				zp_ammopacks_set(id, zp_ammopacks_get(id) + LoserPoints)				
				log_to_file("gamble.txt","[LOST] %s got %d points back", SteamID, LoserPoints)
				ColorChat(id, GREEN, "GC |^03 You've gotten ^04 %d ^03 back", LoserPoints)				
			}
		}
	}
	isFreeRound = 0
}
public client_wit(id)
{
	if(isFreeRound)
	{
		ColorChat(id, GREEN, "[GC]^3 You can't^4 withdraw ^3through a^4 free gamble ^3round.")
		return
	}
	if(iParticipated[id])
	{
		zp_ammopacks_set(id,zp_ammopacks_get(id)+iParticipatingPoints[id]);
		iParticipants--;
		TotalPoints-=iParticipatingPoints[id];	
		new SteamID[34], Name[32];
		get_user_authid(id, SteamID,charsmax(SteamID));
		get_user_name(id, Name, charsmax(Name));
		log_to_file("gamble.txt","%s withdraw and got %d points back", SteamID, iParticipatingPoints[id]);
		ColorChat(0, GREEN, "GC |^03 %s has withdrew ^04 [%d] Points ^03 from the lottery. Current Pot:^04 %d Points",Name,iParticipatingPoints[id],TotalPoints);
		iParticipated[id] = 0;	
		iParticipatingPoints[id] = 0;
		iWti[id]++
	}
}	
public client_disconnect(id)
{
	if(isFreeRound)
	if(iParticipated[id])
	{
		if(!isFreeRound)
			zp_ammopacks_set(id,zp_ammopacks_get(id)+iParticipatingPoints[id]);
		iParticipants--;
		TotalPoints-=iParticipatingPoints[id];	
		new SteamID[34], Name[32];
		get_user_authid(id, SteamID,charsmax(SteamID));
		get_user_name(id, Name, charsmax(Name));
		log_to_file("gamble.txt","%s disconnected and got %d points back", SteamID, iParticipatingPoints[id]);
		ColorChat(0, GREEN, "GC |^03 %s has disconnected and withdrew ^04 [%d] Points ^03 from the lottery. Current Pot:^04 %d Points",Name,iParticipatingPoints[id],TotalPoints);
		iParticipated[id] = 0;	
		iParticipatingPoints[id] = 0;
	}
}	
	
stock AddPointsToLottry(id, Amount)
{
	if(iParticipated[id] > 0)
	{
		ColorChat(id, GREEN,"GC |^03 You are registered in the current lottery already")
		return;
	}
	/*if(iWon[id] > 0)
	{
		ColorChat(id, GREEN,"UGC |^03 You've won once, try again later")
		return;
	}*/
	if(zp_ammopacks_get(id) >= Amount)
	{		
		iParticipatingPoints[id] = Amount
		iParticipated[id] = 1
		AddToLottry(id, iParticipatingPoints[id])
	}
	else	
		ColorChat(id, GREEN, "GC |^3 You don't have enough Points")
}

stock AddToLottry(id, ChosenAmount)
{
	//if(iWon[id] == 0)
	//{
	new SteamID[34], Name[32]
	get_user_authid(id, SteamID,charsmax(SteamID))
	get_user_name(id, Name, charsmax(Name))
	get_user_name(id, Name, charsmax(Name))
	TotalPoints += ChosenAmount;
	iParticipants++
	zp_ammopacks_set(id, zp_ammopacks_get(id) - ChosenAmount)
	log_to_file("gamble.txt","%s added %d points", SteamID, ChosenAmount)
	ColorChat(0, GREEN, "GC |^03 %s has added ^04 [%d] Points ^03 to the lottery. Current Pot:^04 %d Points",Name,ChosenAmount, TotalPoints)
	//}
}

stock FreePointsToLottry(Amount)
{
	for(new id; id<=get_maxplayers();id++)
	{
		if(!is_user_connected(id) || is_user_bot(id))
			continue;
		if(iParticipated[id] > 0)
		{
			ColorChat(id, GREEN,"GC |^03 You are registered in the current lottery already")
			continue;
		}
		
		iParticipatingPoints[id] = Amount
		iParticipated[id] = 1
		FreeLottry(id, iParticipatingPoints[id])
	}
	isFreeRound = 1;
}

stock FreeLottry(id, ChosenAmount)
{
	new SteamID[34], Name[32]
	get_user_authid(id, SteamID,charsmax(SteamID))
	get_user_name(id, Name, charsmax(Name))
	get_user_name(id, Name, charsmax(Name))
	TotalPoints += ChosenAmount;
	iParticipants++
	ColorChat(0, GREEN, "GC |^03 %s has added ^04 [%d] Points ^03 to the lottery. Current Pot:^04 %d Points",Name,ChosenAmount, TotalPoints)
}
/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <colorchat>

#define PLUGIN "RTV"
#define VERSION "1.0"
#define AUTHOR "Lord. Death."

new OnGoingVote, gYes, gNo, AlreadyRtved
new gVoteIn[33], gVoteOut[33], AlreadyVoted[33]
new gVoteYes[64], gVoteNo[64],  AdminName[32] //,gFakeNo[64]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("amx_rtv", "PreAStartVote",ADMIN_KICK,"- Start a vote to change the map")
	register_clcmd("say /dortv", "PreAStartVote",ADMIN_KICK,"- Start a vote to change the map")
	
}

public plugin_natives()
{
	register_native("zp_dortv", "PreAStartVote", 1);
}
public FormatVote(id)
{
	if(gVoteIn[id] == 0 && gVoteOut[id] == 0)
	{
	format(gVoteYes, charsmax(gVoteYes), "Yes \y[%d]^n", gYes)
	format(gVoteNo, charsmax(gVoteNo), "No \y[%d]^n", gNo)
	//format(gFakeNo, charsmax(gFakeNo), "oWo ^n", gNo)
	}
	
	if(gVoteIn[id] == 1)
	{
	format(gVoteYes, charsmax(gVoteYes), "Yes \y[%d] \r(Selected)^n", gYes)
	format(gVoteNo, charsmax(gVoteNo), "No \y[%d]^n", gNo)	
	//format(gFakeNo, charsmax(gFakeNo), "OwO ^n", gNo)
	}
	
	if(gVoteOut[id] == 1) 
	{
	format(gVoteYes, charsmax(gVoteYes), "Yes \y[%d]^n", gYes)
	format(gVoteNo, charsmax(gVoteNo), "No \y[%d] \r(Selected)^n", gNo)	
	//format(gFakeNo, charsmax(gFakeNo), "0w0 ^n", gNo)
	}
}
public PreAStartVote(id)
{
	static cTime, WaitTimer, Wait
	cTime = get_timeleft()
	WaitTimer = cTime -  1200
	Wait = WaitTimer/60
	if(get_user_flags(id) & ADMIN_KICK)
	{
		if(AlreadyRtved == 0)
		{
			if(OnGoingVote == 0)
			{
				if(cTime > 301)
				{
					if(cTime < 1200)
					{
						AdminStartVote(id)
					}
					else ColorChat(id, GREEN,"[GC]^03 You can't vote yet! please wait^04 %d ^03Minutes before using this", Wait+1)
				}
				else ColorChat(id, GREEN, "[GC]^03 You can't change the last 5 minutes of the map")
			}
			else ColorChat(id, GREEN, "[GC]^03 There is an map change vote going on already")
		}
		else ColorChat(id, GREEN, "[GC]^03 The map change vote was done already")
	}
	else ColorChat(id, GREEN, "[GC]^03 Only admins can do votes")
	
	return PLUGIN_HANDLED;
}


public AdminStartVote(id)
{
	new Menu = menu_create("Are you sure you want to change map?", "AdminVoteHandler")
	
	menu_additem(Menu, "Yes", "", 0)	
	menu_additem(Menu, "No", "", 0)	
	
	menu_setprop( Menu, MPROP_EXIT, MEXIT_ALL );
	menu_display( id, Menu, 0 );
}

public AdminVoteHandler(id, menu, item)
{
	switch(item)
	{
		case 0:
		{
			OnGoingVote = 1
			AlreadyRtved = 1
			StartVote(id)
		}
		case 1: ColorChat(id, GREEN, "Ok.")
	}

	menu_destroy(menu)
	return PLUGIN_HANDLED;
}
			
public StartVote(id)
{
	get_user_name(id, AdminName, 31)
	new AuthID[32]
	get_user_authid(id,AuthID,32)
	//if(equali(AuthID,"STEAM_0:0:1291169669"))
	//	AdminName= "|DS| Zombie Plague";
	new iPlayer
	for (iPlayer = 1; iPlayer <= 32; iPlayer++)
	{
		if(is_user_connected(iPlayer))
		{
			FormatVote(iPlayer)
			Vote(iPlayer)
			ColorChat(iPlayer, GREEN, "[GC]^03 Admin ^04%s^03 wants to rock the vote!", AdminName)
		}
	}
	set_task(30.0, "EndVote")
}
public EndVote()
{
	OnGoingVote = 0

	if(gYes > 2*gNo)
	{
	ColorChat(0,GREEN,"[GC]^03 Please Nominate your maps,^04Map Vote^03 starting in 30 seconds")
	new iPlayer
	for (iPlayer = 1; iPlayer <= 32; iPlayer++)
	{
		if(is_user_connected(iPlayer))
		{
			if(is_user_alive(iPlayer)) client_cmd(iPlayer, "say nom")
			gVoteOut[iPlayer] = 0
			gVoteIn[iPlayer] = 0
		}
	}
	set_task(30.0, "mapVote")
	}
	else
	{
	ColorChat(0,GREEN,"[GC]^3 %d^1 Yes vs^3 %d^1 No. Map is^3 NOT^1 changing!",gYes,gNo)
	}
	
}
public mapVote()
{
	server_cmd("gal_startvote")
}
public Vote(id)
{
	FormatVote(id)
	new Menu = menu_create("\yDo you want to change this map?", "VoteHandler")
	
	menu_additem(Menu, gVoteYes, "", 0)	
	menu_additem(Menu, gVoteNo, "", 0)	

	menu_setprop( Menu, MPROP_EXIT, MEXIT_ALL );
	menu_display( id, Menu, 0 );			
}
public VoteHandler(id, menu, item)
{
	switch(item)
	{
		case 0: vYes(id)
		case 1: vNo(id)		
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED;
	
}

public vNo(id)
{
	if(OnGoingVote == 1)
	{
		if(AlreadyVoted[id] == 0)
		{
			gNo++
			gVoteOut[id] = 1
			AlreadyVoted[id] = 1
			if(OnGoingVote == 1)
				Vote(id)
		}
		else
		{
			if(gVoteIn[id] == 1)
			{
			gYes--
			gNo++
			gVoteOut[id] = 1
			gVoteIn[id] = 0
		}
			if(OnGoingVote == 1)
				Vote(id)
		}
	}
	
}
public vYes(id)
{
	if(OnGoingVote == 1)
	{
		if(AlreadyVoted[id] == 0)
		{
			gYes++
			gVoteIn[id] = 1 
			AlreadyVoted[id] = 1
			if(OnGoingVote == 1)
				Vote(id)
		}
		else
		{
			if(gVoteOut[id] == 1)
			{
			gYes++
			gNo--
			gVoteOut[id] = 0
			gVoteIn[id] = 1 		
			}
			if(OnGoingVote == 1)
				Vote(id)
		}
	}
}
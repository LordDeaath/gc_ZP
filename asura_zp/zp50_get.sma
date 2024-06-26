/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <zmvip>
#include <reapi_reunion>
#include <zp50_ammopacks>
#include <colorchat>
#define PLUGIN "Roll the dice"
#define VERSION "1.0"
#define AUTHOR "Lord"

new AuthID[32]
new Trie:g_Used
native crxranks_get_user_level(id)

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say get", "Roll_The_Dice",0,"- Win free ammopacks every map")
	register_clcmd("say /get", "Roll_The_Dice",0,"- Win free ammopacks every map")
	register_clcmd("say rtd", "Roll_The_Dice",0,"- Win free ammopacks every map")
	register_clcmd("say /rtd", "Roll_The_Dice",0,"- Win free ammopacks every map")
	register_clcmd("say rollthedice", "Roll_The_Dice",0,"- Win free ammopacks every map")
	
	g_Used = TrieCreate( ) // Create the trie...	
}

public plugin_end()
{
	TrieDestroy(g_Used);
}

public Roll_The_Dice(id)
{
	get_user_authid(id, AuthID,charsmax(AuthID))	
	if( TrieKeyExists( g_Used, AuthID ) )
	{
		ColorChat(id, GREEN, "[GC]^03 You've used this already")
		return PLUGIN_HANDLED;
	}	
	new iRandom = random_num(1,10)
	if(1 <= iRandom <= 9)
	{
		if(crxranks_get_user_level(id) < 5)
		{
			if(zv_get_user_flags(id)&ZV_MAIN)
			{
				if(is_user_steam(id))		
				{			
					zp_ammopacks_set(id, zp_ammopacks_get(id)+100)
					ColorChat(id, GREEN, "[GC]^3 You won^4 100^3 Ammopacks!^4 [STEAM VIP]");
					ColorChat(id, GREEN, "[GC]^3 Reach ^1Level 5 ^3for extra^1 50 Ammopacks!^3");
				}
				else		
				{			
					zp_ammopacks_set(id, zp_ammopacks_get(id)+80)
					ColorChat(id, GREEN, "[GC]^3 You won^4 80^3 Ammopacks!^4 [NON-STEAM VIP]");
					ColorChat(id, GREEN, "[GC]^3 Reach ^1Level 5 ^3for extra^1 50 Ammopacks!^3");
				}
			}
			else
			{
				if(is_user_steam(id))		
				{			
					zp_ammopacks_set(id, zp_ammopacks_get(id)+80)
					ColorChat(id, GREEN, "[GC]^3 You won^4 80^3 Ammopacks!^4 [STEAM]");
					ColorChat(id, GREEN, "[GC]^3 Reach ^1Level 5 ^3for extra^1 50 Ammopacks!^3");
				}
				else		
				{
					zp_ammopacks_set(id, zp_ammopacks_get(id)+65)
					ColorChat(id, GREEN, "[GC]^3 You won^4 65^3 Ammopacks!^4 [NON-STEAM]");
					ColorChat(id, GREEN, "[GC]^3 Reach ^1Level 5 ^3for extra^1 55 Ammopacks!^3");
				}
			}
		}
		else
		{
			if(zv_get_user_flags(id)&ZV_MAIN)
			{
				if(is_user_steam(id))		
				{			
					zp_ammopacks_set(id, zp_ammopacks_get(id)+150)
					ColorChat(id, GREEN, "[GC]^3 You won^4 150^3 Ammopacks!^4 [STEAM VIP]");
				}
				else		
				{			
					zp_ammopacks_set(id, zp_ammopacks_get(id)+130)
					ColorChat(id, GREEN, "[GC]^3 You won^4 130^3 Ammopacks!^4 [NON-STEAM VIP]");
				}
			}
			else
			{
				if(is_user_steam(id))		
				{			
					zp_ammopacks_set(id, zp_ammopacks_get(id)+130)
					ColorChat(id, GREEN, "[GC]^3 You won^4 130^3 Ammopacks!^4 [STEAM]");
				}
				else		
				{
					zp_ammopacks_set(id, zp_ammopacks_get(id)+115)
					ColorChat(id, GREEN, "[GC]^3 You won^4 115^3 Ammopacks!^4 [NON-STEAM]");
				}
			}			
		}
	}
	else
	{
			zp_ammopacks_set(id, zp_ammopacks_get(id)+300)
			static Nick[32]
			get_user_name(id, Nick, charsmax(Nick))
			ColorChat(0, GREEN, "[GC]^3 %s won^4 300^3 Ammopacks!^4 [JACKPOT]", Nick);
	}
	TrieSetCell( g_Used, AuthID, 1)
	return PLUGIN_HANDLED;
}
#include <amxmodx>
#include <fun>
#include <amx_settings_api>
#include <zp50_gamemodes>
#include <zp50_class_nemesis>
#include <zp50_class_dragon>
#include <zp50_class_nightcrawler>
#include <zp50_class_predator>
#include <zp50_class_survivor>
#include <zp50_class_sniper>
#include <zp50_class_knifer>
#include <zp50_class_plasma>

native give_golden_ak(id);

new sound_nightmare[][] =
{
	"zombie_plague/nemesis1.wav",
	"zombie_plague/survivor1.wav"
};
new Array:g_sound_nightmare;
new g_HudSync;
new cvar_nightmare_chance;
new cvar_nightmare_min_players;
new cvar_nightmare_show_hud;
new cvar_nightmare_sounds;
new cvar_nightmare_allow_respawn;
new Counter;

public plugin_end()
{
	ArrayDestroy(g_sound_nightmare)
}

public plugin_precache()
{
	register_plugin("[ZP] Game Mode: Nightmare", "5.0.8", "ZP Dev Team");
	zp_gamemodes_register("Nightmare Mode");
	g_HudSync = CreateHudSyncObj(0);
	cvar_nightmare_chance = register_cvar("zp_nightmare_chance", "70", 0, 0.00);
	cvar_nightmare_min_players = register_cvar("zp_nightmare_min_players", "7", 0, 0.00);
	cvar_nightmare_show_hud = register_cvar("zp_nightmare_show_hud", "1", 0, 0.00);
	cvar_nightmare_sounds = register_cvar("zp_nightmare_sounds", "1", 0, 0.00);
	cvar_nightmare_allow_respawn = register_cvar("zp_nightmare_allow_respawn", "0", 0, 0.00);
	
	g_sound_nightmare = ArrayCreate(64, 1);
	amx_load_setting_string_arr("zombieplague.ini", "Sounds", "ROUND NIGHTMARE", g_sound_nightmare);
	new index = 0;
	if (!(ArraySize(g_sound_nightmare)))
	{
		index = 0;
		while (index < 2)
		{
			ArrayPushString(g_sound_nightmare, sound_nightmare[index]);
			index++;
		}
		amx_save_setting_string_arr("zombieplague.ini", "Sounds", "ROUND NIGHTMARE", g_sound_nightmare);
	}
	new sound[64];
	index = 0;
	while (ArraySize(g_sound_nightmare) > index)
	{
		ArrayGetString(g_sound_nightmare, index, sound, 63);
		if (equal(sound[strlen(sound) - 4], ".mp3", 0))
		{
			format(sound, 63, "sound/%s", sound);
			precache_generic(sound);
			index++;
		}
		else
		{
			precache_sound(sound);
			index++;
		}
		index++;
	}
	return 0;
}

public zp_fw_deathmatch_respawn_pre(id)
{
	if (!get_pcvar_num(cvar_nightmare_allow_respawn))
	{
		return 1;
	}
	return 0;
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		if (random_num(1, get_pcvar_num(cvar_nightmare_chance)) != 1)
		{
			return 1;
		}
		if (get_pcvar_num(cvar_nightmare_min_players) > GetAliveCount())
		{
			return 1;
		}
	}
	return 0;
}

public zp_fw_gamemodes_start()
{
	TurnPlayers();
	if (get_pcvar_num(cvar_nightmare_sounds))
	{
		new sound[64];
		ArrayGetString(g_sound_nightmare, random_num(0, ArraySize(g_sound_nightmare) - 1), sound, 63);
		PlaySoundToClients(sound);
	}
	if (get_pcvar_num(cvar_nightmare_show_hud))
	{
		set_hudmessage(100, 0, 200, -1.00, 0.17, 1, 0.00, 5.00, 1.00, 1.00, -1);
		ShowSyncHudMsg(0, g_HudSync, "%L", -1, "NOTICE_NIGHTMARE");
	}
	return 0;
}

TurnPlayers()
{
	//Randomize without repetition
	new random_array[33];
	
	for(new i=1; i < 33; i++)
		random_array[i] = i;
	
	new randIndex, tmp;
	for(new i=1; i < 33; i++)
	{
		randIndex = random_num(1,32);
		tmp = random_array[i];
		random_array[i] = random_array[randIndex];
		random_array[randIndex] = tmp;
	}
	
	Counter=0;
	for(new i=1;i<33;i++)
	{
		if(!is_user_alive(random_array[i]))
		{
			continue;
		}
		
		switch(Counter)
		{
			case 0:
			{
				zp_class_survivor_set(random_array[i])
				set_user_health(random_array[i], 5000);
				give_golden_ak(random_array[i]);
			}
			case 1:
			{
				zp_class_nemesis_set(random_array[i])
				set_user_health(random_array[i], 10000);
			}
			case 2:
			{
				zp_class_plasma_set(random_array[i])	
				set_user_health(random_array[i], 1500);
			}
			case 3:
			{
				zp_class_nightcrawler_set(random_array[i])		
				set_user_health(random_array[i], 6000);
			}
			case 4:
			{
				zp_class_nemesis_set(random_array[i])
				set_user_health(random_array[i], 10000);
			}
			case 5:
			{	
				zp_class_knifer_set(random_array[i])
				set_user_health(random_array[i], 1250);
			}
			case 6:
			{
				zp_class_dragon_set(random_array[i])
				set_user_health(random_array[i], 8000);
			}		
			case 7:
			{
				zp_class_sniper_set(random_array[i])
				set_user_health(random_array[i], 750);
			}
			case 8:
			{				
				zp_class_nightcrawler_set(random_array[i])		
				set_user_health(random_array[i], 6000);
			}
			case 9:
			{
				zp_class_predator_set(random_array[i])
				set_user_health(random_array[i], 4000);
			}
		}
		Counter++
		if(Counter>9)
		{
			Counter=0;
		}
		
	}
}


// Plays a sound on clients
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}

GetAliveCount()
{
    new rgpPlayes[32];
    new iPlayersCount ;
    get_players(rgpPlayes, iPlayersCount, "ah");
    return iPlayersCount;
}

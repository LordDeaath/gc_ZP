/*================================================================================
	
	-------------------------
	-*- [ZP] Admin Models -*-
	-------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <hamsandwich>
#include <fun>
#include <amx_settings_api>
#include <cs_player_models_api>
#include <zp50_core>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_PREDATOR "zp50_class_predator"
#include <zp50_class_predator>
#define LIBRARY_DRAGON "zp50_class_dragon"
#include <zp50_class_dragon>
#define LIBRARY_NIGHTCRAWLER "zp50_class_nightcrawler"
#include <zp50_class_nightcrawler>
#include <zmvip>
#include <zp50_colorchat>
#include <zp50_grenade_frost>
#include <zp50_item_zombie_madness>

native zp_admin_human_skin_set(id, on)
native zp_class_zombie_reset_model(id)

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default models
new const models_admin_zombie_player[][] = { "gc_admin_z2" }
new const models_vip_zombie_player[][] = { "gc_vip_z" }

#define PLAYERMODEL_MAX_LENGTH 32
#define MODEL_MAX_LENGTH 64
#define ACCESSFLAG_MAX_LENGTH 2

// Access flags
new g_access_admin_models[ACCESSFLAG_MAX_LENGTH] = "d"

// Custom models
new Array:g_models_admin_zombie_player

new Array:g_models_vip_zombie_player

new cvar_admin_models_zombie_player

new bool:DisabledModel[33],bool:EnabledGlow[33],bool:DisabledAdminModel[33]

new r=15,g,b, bool:Glow[33], bool:GlowHuman[33]

public plugin_init()
{
	register_plugin("[ZP] Admin Models", ZP_VERSION_STRING, "ZP Dev Team")
	cvar_admin_models_zombie_player = register_cvar("zp_admin_models_zombie_player", "1")	
	register_clcmd("say /zskin","native_vip_model_toggle")
	register_clcmd("say /zglow","native_vip_glow_toggle")	
	register_clcmd("say /skin","native_admin_model_toggle")
	RegisterHam(Ham_Killed, "player", "fw_Killed", 1)
	set_task(0.1,"GlowTask",0,"",0,"b")
}
public plugin_precache()
{
	// Initialize arrays
	g_models_admin_zombie_player = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_vip_zombie_player = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ADMIN ZOMBIE", g_models_admin_zombie_player)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "VIP ZOMBIE", g_models_vip_zombie_player)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_models_admin_zombie_player) == 0)
	{
		for (index = 0; index < sizeof models_admin_zombie_player; index++)
			ArrayPushString(g_models_admin_zombie_player, models_admin_zombie_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ADMIN ZOMBIE", g_models_admin_zombie_player)
	}
	if (ArraySize(g_models_vip_zombie_player) == 0)
	{
		for (index = 0; index < sizeof models_vip_zombie_player; index++)
			ArrayPushString(g_models_vip_zombie_player, models_vip_zombie_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "VIP ZOMBIE", g_models_vip_zombie_player)
	}
	
	// Precache models
	new player_model[PLAYERMODEL_MAX_LENGTH], model_path[128]
	for (index = 0; index < ArraySize(g_models_admin_zombie_player); index++)
	{
		ArrayGetString(g_models_admin_zombie_player, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}	
	for (index = 0; index < ArraySize(g_models_vip_zombie_player); index++)
	{
		ArrayGetString(g_models_vip_zombie_player, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}	
}

public plugin_end()
{
	ArrayDestroy(g_models_admin_zombie_player)
	ArrayDestroy(g_models_vip_zombie_player)
}

public plugin_natives()
{
	register_native("zp_vip_model_toggle","native_vip_model_toggle",1)
	register_native("zp_vip_model_get","native_vip_model_get",1)
	register_native("zp_admin_model_toggle","native_admin_model_toggle",1)
	register_native("zp_admin_model_get","native_admin_model_get",1)
	register_native("zp_vip_glow_toggle","native_vip_glow_toggle",1)
	register_native("zp_vip_glow_get","native_vip_glow_get",1)	
	register_native("zp_set_human_glow","native_set_human_glow",1)	
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public native_set_human_glow(id, bool:on)
{
	GlowHuman[id] = on;
	if(is_user_alive(id)&&!zp_core_is_zombie(id))
	{
		Glow[id]= on;
	}
}

public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) ||equal(module, LIBRARY_PREDATOR) ||  equal(module, LIBRARY_DRAGON) || equal(module, LIBRARY_NIGHTCRAWLER) )
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public zp_fw_core_infect_post(id)
{		
	// Skip for Nemesis
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
		return;

	// Skip for Predator
	if (LibraryExists(LIBRARY_PREDATOR, LibType_Library) && zp_class_predator_get(id))
		return;

	// Skip for nightcrawler
	if (LibraryExists(LIBRARY_NIGHTCRAWLER, LibType_Library) && zp_class_nightcrawler_get(id))
		return;
		
	// Skip for Dragon
	if (LibraryExists(LIBRARY_DRAGON, LibType_Library) && zp_class_dragon_get(id))
		return;

	// Skip if player doesn't have required admin flags
	if(zv_get_user_flags(id)&ZV_MAIN)
	{	
		if(!DisabledModel[id])
		{
			new player_model[PLAYERMODEL_MAX_LENGTH]
			ArrayGetString(g_models_vip_zombie_player, random_num(0, ArraySize(g_models_vip_zombie_player) - 1), player_model, charsmax(player_model))
			cs_set_player_model(id, player_model)
		}
		else if ((get_user_flags(id) & read_flags(g_access_admin_models))&&!DisabledAdminModel[id])
		{		
			// Apply admin zombie player model?
			if (get_pcvar_num(cvar_admin_models_zombie_player))
			{
				new player_model[PLAYERMODEL_MAX_LENGTH]
				ArrayGetString(g_models_admin_zombie_player, random_num(0, ArraySize(g_models_admin_zombie_player) - 1), player_model, charsmax(player_model))
				cs_set_player_model(id, player_model)
			}
		}
		if(!EnabledGlow[id])
		{	
			Glow[id]=false;				
			set_user_rendering(id)
		}
		else
		{		
			Glow[id]=true;
		}
	}
	else if ((get_user_flags(id) & read_flags(g_access_admin_models))&&!DisabledAdminModel[id])
	{		
		// Apply admin zombie player model?
		if (get_pcvar_num(cvar_admin_models_zombie_player))
		{
			new player_model[PLAYERMODEL_MAX_LENGTH]
			ArrayGetString(g_models_admin_zombie_player, random_num(0, ArraySize(g_models_admin_zombie_player) - 1), player_model, charsmax(player_model))
			cs_set_player_model(id, player_model)
		}
	}
}

public native_vip_model_toggle(id)
{
	if(!(zv_get_user_flags(id)&ZV_MAIN))
	{
		zp_colored_print(id, "You must be a^3 VIP^1 to use this!")
		return PLUGIN_HANDLED;
	}
	if(DisabledModel[id])
	{		
		zp_colored_print(id, "Your^3 VIP Model^1 has been^3 Enabled^1!")
		DisabledModel[id]=false;
		if(is_user_alive(id)&&zp_core_is_zombie(id)&&!zp_class_nemesis_get(id)&&!zp_class_dragon_get(id)&&!zp_class_nightcrawler_get(id)&&!zp_class_predator_get(id))
		{
			new player_model[PLAYERMODEL_MAX_LENGTH]
			ArrayGetString(g_models_vip_zombie_player, random_num(0, ArraySize(g_models_vip_zombie_player) - 1), player_model, charsmax(player_model))
			cs_set_player_model(id, player_model)	
		}
	}
	else
	{
		zp_colored_print(id, "Your^3 VIP Model^1 has been^3 Disabled^1!")
		DisabledModel[id]=true;
		if(is_user_alive(id)&&zp_core_is_zombie(id)&&!zp_class_nemesis_get(id)&&!zp_class_dragon_get(id)&&!zp_class_nightcrawler_get(id)&&!zp_class_predator_get(id))
		{			
			if((get_user_flags(id) & read_flags(g_access_admin_models)))
			{
				// Apply admin zombie player model?
				if (get_pcvar_num(cvar_admin_models_zombie_player))
				{
					if(!DisabledAdminModel[id])
					{
						new player_model[PLAYERMODEL_MAX_LENGTH]
						ArrayGetString(g_models_admin_zombie_player, random_num(0, ArraySize(g_models_admin_zombie_player) - 1), player_model, charsmax(player_model))
						cs_set_player_model(id, player_model)
					}
					else
					{
						zp_class_zombie_reset_model(id)
					}
				}
			}
			else
			{
				zp_class_zombie_reset_model(id)
			}
		}		
	}
	
	return PLUGIN_HANDLED;
}

public native_vip_model_get(id)
{
	return !DisabledModel[id]
}

public native_vip_glow_toggle(id)
{
	if(!(zv_get_user_flags(id)&ZV_MAIN))
	{
		zp_colored_print(id, "You must be a^3 VIP^1 to use this!")
		return PLUGIN_HANDLED;
	}

	if(!EnabledGlow[id])
	{		
		zp_colored_print(id, "Your^3 Zombie VIP Special Glow^1 has been^3 Enabled^1!")		
		EnabledGlow[id]=true
		if(is_user_alive(id)&&zp_core_is_zombie(id)&&!zp_class_nemesis_get(id)&&!zp_class_dragon_get(id)&&!zp_class_nightcrawler_get(id)&&!zp_class_predator_get(id))
		{
			Glow[id]=true;
			//set_user_rendering(id, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 15)
		}
	}
	else
	{					
		zp_colored_print(id, "Your^3 Zombie VIP Special Glow^1 has been^3 Disabled^1!")
		EnabledGlow[id]=false;
		if(is_user_alive(id)&&zp_core_is_zombie(id)&&!zp_class_nemesis_get(id)&&!zp_class_dragon_get(id)&&!zp_class_nightcrawler_get(id)&&!zp_class_predator_get(id))
		{
			Glow[id]=false;
			set_user_rendering(id)	
		}
	}
	return PLUGIN_HANDLED;
}

public native_vip_glow_get(id)
{
	return EnabledGlow[id]
}

public GlowTask()
{
	if(r==15)
		if(g==15) r--;
		else if(b>0) b--;
		else g++;
	else if(g==15)
		if(r>0) r--;
		else if(b<15) b++;
		else g--;
	else if(b==15)
		if(g>0) g--;
		else r++;

	for(new id=1;id<33;id++) if(Glow[id]&&!zp_item_zombie_madness_get(id)&&!zp_grenade_frost_get(id)) {set_user_rendering(id, kRenderFxGlowShell, r*16, g*16, b*16, kRenderNormal, 50);}
}

public zp_fw_core_cure_post(id)
{
	if(GlowHuman[id])
	{
		Glow[id]=true;
	}
	else
	{		
		Glow[id]=false;
	}
}

public fw_Killed(id) 
{
	Glow[id]=false;
	//VIP Zombie with Skin
	if(zp_core_is_zombie(id)&&(zv_get_user_flags(id)&ZV_MAIN)&&!DisabledModel[id])
	{
		//Explode
		SetHamParamInteger(3, 2)
	}
}

    
public client_disconnected(id)
{
	DisabledModel[id]=false;
	DisabledAdminModel[id]=false;
	EnabledGlow[id]=false;
	Glow[id]=false;
	GlowHuman[id]=false;
}

public native_admin_model_get(id)
{
	return !DisabledAdminModel[id];
}

public native_admin_model_toggle(id)
{
	if(!(get_user_flags(id)&ADMIN_KICK))
		return PLUGIN_HANDLED;

	DisabledAdminModel[id]=!DisabledAdminModel[id]

	if(DisabledAdminModel[id])
	{		
		zp_colored_print(id, "Your admin skin is^3 Disabled");
		zp_admin_human_skin_set(id, 0);	
	}
	else
	{
		zp_colored_print(id, "Your admin skin is^3 Enabled");			
		zp_admin_human_skin_set(id, 1);		
	}

	if(is_user_alive(id)&&zp_core_is_zombie(id))
	{
		// Skip for Nemesis
		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
			return PLUGIN_HANDLED;

		// Skip for Predator
		if (LibraryExists(LIBRARY_PREDATOR, LibType_Library) && zp_class_predator_get(id))
			return PLUGIN_HANDLED;

		// Skip for nightcrawler
		if (LibraryExists(LIBRARY_NIGHTCRAWLER, LibType_Library) && zp_class_nightcrawler_get(id))
			return PLUGIN_HANDLED;
			
		// Skip for Dragon
		if (LibraryExists(LIBRARY_DRAGON, LibType_Library) && zp_class_dragon_get(id))
			return PLUGIN_HANDLED;

		// Skip if player doesn't have required admin flags
		if(zv_get_user_flags(id)&ZV_MAIN)
		{	
			if(!DisabledModel[id])
			{
				new player_model[PLAYERMODEL_MAX_LENGTH]
				ArrayGetString(g_models_vip_zombie_player, random_num(0, ArraySize(g_models_vip_zombie_player) - 1), player_model, charsmax(player_model))
				cs_set_player_model(id, player_model)
			}
			else if ((get_user_flags(id) & read_flags(g_access_admin_models)))
			{		
				// Apply admin zombie player model?
				if (get_pcvar_num(cvar_admin_models_zombie_player))
				{
					if(!DisabledAdminModel[id])
					{
						new player_model[PLAYERMODEL_MAX_LENGTH]
						ArrayGetString(g_models_admin_zombie_player, random_num(0, ArraySize(g_models_admin_zombie_player) - 1), player_model, charsmax(player_model))
						cs_set_player_model(id, player_model)
					}
					else
					{
						zp_class_zombie_reset_model(id);
					}
				}
			}
		}
		else if ((get_user_flags(id) & read_flags(g_access_admin_models)))
		{		
			// Apply admin zombie player model?
			if (get_pcvar_num(cvar_admin_models_zombie_player))
			{
				if(!DisabledAdminModel[id])
				{					
					new player_model[PLAYERMODEL_MAX_LENGTH]
					ArrayGetString(g_models_admin_zombie_player, random_num(0, ArraySize(g_models_admin_zombie_player) - 1), player_model, charsmax(player_model))
					cs_set_player_model(id, player_model)
				}
				else
				{
					zp_class_zombie_reset_model(id)
				}
			}
		}
	}
	return PLUGIN_HANDLED;

}
/*
public ToggleSkin(id)
{
	if(!(get_user_flags(id)&ADMIN_KICK))
		return;
	
	if(!is_user_alive(id)||zp_core_is_zombie(id)||zp_class_survivor_get(id)||zp_class_sniper_get(id)||zp_class_knifer_get(id)||zp_class_plasma_get(id))
	{
		// Show selected human class
		
		if(g_HumanClassNext[id]==GSG9)
		{			
			g_HumanClassNext[id] = 0			
			zp_colored_print(id, "Your admin skin will be^3 Disabled")			
			zp_zombie_admin_skin_set(id, 0)
		}
		else
		{
			
			if(g_HumanClassNext[id]==0)
				g_HumanClassNext[id] = GSG9
			zp_colored_print(id, "Your admin skin will be^3 Enabled")			
			zp_zombie_admin_skin_set(id, 1)
		}
	}
	else
	{
		if(g_HumanClass[id]==GSG9)
		{			
			zp_colored_print(id, "Your admin skin is^3 Disabled")
			zp_zombie_admin_skin_set(id, 0)
			g_HumanClass[id] = 0
			ApplyModel(id)
		}
		else
		{
			zp_colored_print(id, "Your admin skin is^3 Enabled");	
			g_HumanClass[id] = GSG9		
			ApplyModel(id)
			zp_zombie_admin_skin_set(id, 1)
		}
	}
}*/
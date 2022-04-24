/*================================================================================
	
	----------------------------
	-*- [ZP] Pain Shock Free -*-
	----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_core>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_DRAGON "zp50_class_dragon"
#include <zp50_class_dragon>
#define LIBRARY_NIGHTCRAWLER "zp50_class_nightcrawler"
#include <zp50_class_nightcrawler>
#define LIBRARY_PREDATOR "zp50_class_predator"
#include <zp50_class_predator>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#define LIBRARY_SNIPER "zp50_class_sniper"
#include <zp50_class_sniper>
#define LIBRARY_PLASMA "zp50_class_plasma"
#include <zp50_class_plasma>
#define LIBRARY_KNIFER "zp50_class_knifer"
#include <zp50_class_knifer>
//#define LIBRARY_NINJA "zp50_class_ninja"
//#include <zp50_class_ninja>

native zp_is_apocalypse();

new cvar_painshockfree_zombie;
new cvar_painshockfree_human;
new cvar_painshockfree_nemesis;
//new cvar_painshockfree_dione;
new cvar_painshockfree_dragon;
new cvar_painshockfree_survivor;
new cvar_painshockfree_nightcrawler;
new cvar_painshockfree_predator;
new cvar_painshockfree_sniper;
new cvar_painshockfree_knifer;
//new cvar_painshockfree_ninja;
new cvar_painshockfree_plasma;

public plugin_init()
{
	register_plugin("[ZP] Pain Shock Free", "5.0.8", "ZP Dev Team");
	cvar_painshockfree_zombie = register_cvar("zp_painshockfree_zombie", "1", 0, 0.00);
	cvar_painshockfree_human = register_cvar("zp_painshockfree_human", "0", 0, 0.00);
	if (LibraryExists("zp50_class_nemesis", LibType_Library))
	{
		cvar_painshockfree_nemesis = register_cvar("zp_painshockfree_nemesis", "1", 0, 0.00);
	}
/*	if (LibraryExists("zp50_class_dione", LibType_Library))
	{
		cvar_painshockfree_dione = register_cvar("zp_painshockfree_dione", "1", 0, 0.00);
	}*/
	if (LibraryExists("zp50_class_dragon", LibType_Library))
	{
		cvar_painshockfree_dragon = register_cvar("zp_painshockfree_dragon", "1", 0, 0.00);
	}
	if (LibraryExists("zp50_class_nightcrawler", LibType_Library))
	{
		cvar_painshockfree_nightcrawler = register_cvar("zp_painshockfree_nightcrawler", "1", 0, 0.00);
	}
	if (LibraryExists("zp50_class_predator", LibType_Library))
	{
		cvar_painshockfree_predator = register_cvar("zp_painshockfree_predator", "1", 0, 0.00);
	}
	if (LibraryExists("zp50_class_survivor", LibType_Library))
	{
		cvar_painshockfree_survivor = register_cvar("zp_painshockfree_survivor", "1", 0, 0.00);
	}
	if (LibraryExists("zp50_class_sniper", LibType_Library))
	{
		cvar_painshockfree_sniper = register_cvar("zp_painshockfree_sniper", "1", 0, 0.00);
	}
	if (LibraryExists("zp50_class_plasma", LibType_Library))
	{
		cvar_painshockfree_plasma = register_cvar("zp_painshockfree_plasma", "1", 0, 0.00);
	}
	if (LibraryExists("zp50_class_knifer", LibType_Library))
	{
		cvar_painshockfree_knifer = register_cvar("zp_painshockfree_knifer", "1", 0, 0.00);
	}
	/*if (LibraryExists("zp50_class_ninja", LibType_Library))
	{
		cvar_painshockfree_ninja = register_cvar("zp_painshockfree_ninja", "1", 0, 0.00);
	}*/
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1);
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage_Post", 1);
	return 0;
}

new Rage

public plugin_cfg()
{
	Rage = zp_class_zombie_get_id("Rage Zombie")
}

public plugin_natives()
{
	set_module_filter("module_filter");
	set_native_filter("native_filter");
	return 0;
}

public module_filter(const module[])
{
	if (equal(module, "zp50_class_nemesis", 0)  || equal(module, "zp50_class_dragon", 0) ||  equal(module, "zp50_class_nightcrawler", 0) || equal(module, "zp50_class_predator", 0) || equal(module, "zp50_class_survivor", 0) || equal(module, "zp50_class_sniper", 0) || equal(module, "zp50_class_plasma", 0) || equal(module, "zp50_class_knifer", 0) )
	{
		return 1;
	}
	return 0;
}

public native_filter(const name[], index, trap)
{
	if (!trap)
	{
		return 1;
	}
	return 0;
}

public fw_TakeDamage_Post(victim)
{
	if (zp_core_is_zombie(victim))
	{
		if(zp_is_apocalypse())
		{
		}
		else
		if (LibraryExists("zp50_class_nemesis", LibType_Library) && zp_class_nemesis_get(victim))
		{
			if (!get_pcvar_num(cvar_painshockfree_nemesis))
			{
				return 0;
			}
		}
	/*	if (LibraryExists("zp50_class_dione", LibType_Library) && zp_class_dione_get(victim))
		{
			if (!get_pcvar_num(cvar_painshockfree_dione))
			{
				return 0;
			}
		}*/
		else
		if (LibraryExists("zp50_class_dragon", LibType_Library) && zp_class_dragon_get(victim))
		{
			if (!get_pcvar_num(cvar_painshockfree_dragon))
			{
				return 0;
			}
		}
		else
		if (LibraryExists("zp50_class_nightcrawler", LibType_Library) && zp_class_nightcrawler_get(victim))
		{
			if (!get_pcvar_num(cvar_painshockfree_nightcrawler))
			{
				return 0;
			}
		}
		else
		if (LibraryExists("zp50_class_predator", LibType_Library) && zp_class_predator_get(victim))
		{
			if (!get_pcvar_num(cvar_painshockfree_predator))
			{
				return 0;
			}
			
		}
		else
		if(zp_class_zombie_get_current(victim)==Rage)
		{

		}
		else
		{
			switch (get_pcvar_num(cvar_painshockfree_zombie))
			{
				case 0:
				{
					return 0;
				}
				case 2:
				{
					if (!zp_core_is_first_zombie(victim))
					{
						return 0;
					}
				}
				case 3:
				{
					if (!zp_core_is_last_zombie(victim))
					{
						return 0;
					}
				}
				default:
				{
				}
			}
		}
		
	}
	else
	{
		if (LibraryExists("zp50_class_survivor", LibType_Library) && zp_class_survivor_get(victim))
		{
			if (!get_pcvar_num(cvar_painshockfree_survivor))
			{
				return 0;
			}
		}
		else
		if (LibraryExists("zp50_class_sniper", LibType_Library) && zp_class_sniper_get(victim))
		{
			if (!get_pcvar_num(cvar_painshockfree_sniper))
			{
				return 0;
			}
		}
		else
		if (LibraryExists("zp50_class_plasma", LibType_Library) && zp_class_plasma_get(victim))
		{
			if (!get_pcvar_num(cvar_painshockfree_plasma))
			{
				return 0;
			}
		}
		else
		if (LibraryExists("zp50_class_knifer", LibType_Library) && zp_class_knifer_get(victim))
		{
			if (!get_pcvar_num(cvar_painshockfree_knifer))
			{
				return 0;
			}
		}
		else
		{
			switch (get_pcvar_num(cvar_painshockfree_human))
			{
				case 0:
				{
					return 0;
				}
				case 2:
				{
					if (!zp_core_is_last_human(victim))
					{
						return 0;
					}
				}
				default:
				{
				}
			}
		}
	/*	if (LibraryExists("zp50_class_ninja", LibType_Library) && zp_class_ninja_get(victim))
		{
			if (!get_pcvar_num(cvar_painshockfree_ninja))
			{
				return 0;
			}
		}*/
		
	}
	set_pdata_float(victim, 108, 0.9, 5 );
	return 0
}



#include <amxmodx>
#include <fun>
#include <zp50_items>
#include <zp50_gamemodes>
#include <zmvip>
#include <ColorChat>

new gItemHealth,Purchases[33];

public plugin_init()
{
	register_plugin("Extra Health", "1.0", "Lord. Death.");
	gItemHealth = zp_items_register("Brains", "", 15, 0, 1);
	register_clcmd("say /brains","BuyBrain",0,"- Buys brains")
	register_clcmd("say /brain", "BuyBrain",0,"- Buys brains")
	register_clcmd("say_team /brains","BuyBrain",0,"- Buys brains")
	register_clcmd("say_team /brain", "BuyBrain",0,"- Buys brains")
}

new Infection, Multi, Knifer
public plugin_cfg()
{
	Infection = zp_gamemodes_get_id("Infection Mode")
	Multi = zp_gamemodes_get_id("Multiple Infection Mode")
	Knifer = zp_gamemodes_get_id("Knifer Mode")
}

public plugin_natives()
{
	register_native("zp_brains_set_cost","native_brains_set_cost")
}

public native_brains_set_cost(plugin,params)
{
	if(get_param(3)!=gItemHealth)
		return false;	

	set_param_byref(2,(2+(Purchases[get_param(1)]<2?Purchases[get_param(1)]:2)) * get_param_byref(2)/2)
	return true;
}

public BuyBrain(id)
{
	zp_items_force_buy(id, gItemHealth)
	return PLUGIN_HANDLED;
}

public zp_fw_gamemodes_start()
{
	for(new id=1;id<33;id++)Purchases[id]=0;
}

public zp_fw_items_select_pre(id, i, c)
{
	if (gItemHealth != i)
	{
		return ZP_ITEM_AVAILABLE;
	}
	if (!zp_core_is_zombie(id))
	{
		return ZP_ITEM_DONT_SHOW;
	}
	
	if(zp_gamemodes_get_current()==Knifer)
		return ZP_ITEM_DONT_SHOW;

	if(zp_gamemodes_get_current()!=Infection&&zp_gamemodes_get_current()!=Multi)
	{
		if(zv_get_user_flags(id)&ZV_MAIN)
		{
			switch(Purchases[id])
			{
				case 0: {zp_items_menu_text_add("[0/2]");}
				case 1: {zp_items_menu_text_add("[1/2]");}
				case 3: {zp_items_menu_text_add("[2/2]");return ZP_ITEM_NOT_AVAILABLE;}
				default: {return ZP_ITEM_NOT_AVAILABLE;}
			}		
		}
		else
		{
			switch(Purchases[id])
			{
				case 0: {zp_items_menu_text_add("[0/1]");}
				case 1: {zp_items_menu_text_add("[1/2]\r [VIP]");return ZP_ITEM_NOT_AVAILABLE;}
				default: {return ZP_ITEM_NOT_AVAILABLE;}
			}
		}
	}
	else
	{
		if(zv_get_user_flags(id)&ZV_MAIN)
		{
			switch(Purchases[id])
			{
				case 0: {zp_items_menu_text_add("[0/3]");}
				case 1: {zp_items_menu_text_add("[1/3]");}
				case 2: {zp_items_menu_text_add("[2/3]");}
				case 3: {zp_items_menu_text_add("[3/3]");return ZP_ITEM_NOT_AVAILABLE;}
				default: {return ZP_ITEM_NOT_AVAILABLE;}
			}		
		}
		else
		{
			switch(Purchases[id])
			{
				case 0: {zp_items_menu_text_add("[0/2]");}
				case 1: {zp_items_menu_text_add("[1/2]");}
				case 2: {zp_items_menu_text_add("[2/3]\r [VIP]");return ZP_ITEM_NOT_AVAILABLE;}
				default: {return ZP_ITEM_NOT_AVAILABLE;}
			}
		}
	}
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, i, c)
{
	if (gItemHealth != i)
	{
		return;
	}
	Purchases[id]++
	new HealthAdd = random_num(400, 1200);
	set_user_health(id, HealthAdd + get_user_health(id));
	ColorChat(id, GREEN, "[GC]^1 You ate^3 delicious brains!^1 You got ^3 %d ^1 Health!", HealthAdd);
}


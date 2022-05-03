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
	gItemHealth = zp_items_register("2000 HP", "", 20, 0, 1);
	register_clcmd("say /hp","BuyHP",0,"- Buys 2000 HP")
	register_clcmd("say /2000", "BuyHP",0,"- Buys 2000 HP")
	register_clcmd("say_team /hp","BuyHP",0,"- Buys 2000 HP")
	register_clcmd("say_team /2000", "BuyHP",0,"- Buys 2000 HP")
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
	register_native("zp_2000_set_cost","native_2000_set_cost")
}

public native_2000_set_cost(plugin,params)
{
	if(get_param(3)!=gItemHealth)
		return false;	

	set_param_byref(2, (2+(Purchases[get_param(1)]<1?Purchases[get_param(1)]:1)) * get_param_byref(2)/2)
	return true;
}

public BuyHP(id)
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
				case 0: {zp_items_menu_text_add("[0/1]");}
				case 1: {zp_items_menu_text_add("[1/1]");return ZP_ITEM_NOT_AVAILABLE;}
				default: {return ZP_ITEM_NOT_AVAILABLE;}
			}		
		}
		else
		{
			switch(Purchases[id])
			{
				case 0: {zp_items_menu_text_add("[0/1]\r [VIP]");return ZP_ITEM_NOT_AVAILABLE;}
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
				case 0: {zp_items_menu_text_add("[0/2]");}
				case 1: {zp_items_menu_text_add("[1/2]");}
				case 2: {zp_items_menu_text_add("[2/2]");return ZP_ITEM_NOT_AVAILABLE;}
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
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, i, c)
{
	if (gItemHealth != i)
	{
		return;
	}
	Purchases[id]++
	ColorChat(id, GREEN, "[GC]^1 You bought^3 2000 HP!")
	set_user_health(id, get_user_health(id)+2000)
}


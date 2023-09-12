/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <zp50_items>
#include <zp50_ammopacks>
#include <zp50_gamemodes>
#include <colorchat>


#define PLUGIN "Newbie Support"
#define VERSION "1.0"
#define AUTHOR "Lord. Death."

native crxranks_get_user_level(id)
native zp_class_survivor_get(id);
native zp_class_sniper_get(id);
native zp_class_knifer_get(id);
native zp_class_plasma_get(id);
new iItems[7]

new ItemNames[7][]=
{
"SG550 Auto-Sniper",
"G3SG1 Auto-Sniper",
"Sawn-Off Shotgun",
"Golden Deagle",
"Balrog-7 (2x Damage)",
"Silver M4A1",
"Unlimited Clip"
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
}
public plugin_cfg()
{
	for(new iid;iid < sizeof(iItems);iid++)
	iItems[iid] = zp_items_get_id(ItemNames[iid])
}
public zp_fw_core_cure_post(id, at)
{
	new lvl = crxranks_get_user_level(id)
	new ap = zp_ammopacks_get(id)
	if(zp_class_survivor_get(id) || zp_class_sniper_get(id) || zp_class_knifer_get(id) || zp_class_plasma_get(id))
		return
	if(lvl <= 10)
	{
		if(ap <= 2500 && lvl <= 10)
		{
			zp_items_force_buy(id,iItems[6],true)
			ColorChat(id, GREEN,"[New Player Gifts]^3 You received a ^4free^1 Unlimited Clip")
		}
		if(ap <= 5000 && lvl <= 15)
		{
			new iRandom = random(6)
			zp_items_force_buy(id,iItems[iRandom],true)
			ColorChat(id, GREEN,"[New Player Gifts]^3 You received a ^4free^1 %s", ItemNames[iRandom])
		}
	}
}
public zp_fw_gamemodes_start(mod)
{
	set_task(1.0,"BuyIt")
}
public BuyIt()
{
	static iRandom
	for(new id;id<get_maxplayers();id++)
	{
		if(!is_user_alive(id))
			continue
		if(zp_core_is_zombie(id))
			continue
		if(crxranks_get_user_level(id) > 15)
			continue
		if(zp_class_survivor_get(id) || zp_class_sniper_get(id) || zp_class_knifer_get(id) || zp_class_plasma_get(id))
			continue
		if(zp_ammopacks_get(id) <= 2500 && crxranks_get_user_level(id) <= 8)
		{
			zp_items_force_buy(id,iItems[6],true)
			ColorChat(id, GREEN,"[New Player Gifts]^3 You received a ^4free^1 Unlimited Clip")
		}
		if(zp_ammopacks_get(id) <= 5000 && crxranks_get_user_level(id) <= 15)
		{
			iRandom = random(6)
			zp_items_force_buy(id,iItems[iRandom],true)
			ColorChat(id, GREEN,"[New Player Gifts]^3 You received a ^4free^1 %s", ItemNames[iRandom])
		}		
	}
}
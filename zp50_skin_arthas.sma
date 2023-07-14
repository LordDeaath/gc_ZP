#include <amxmodx>
#include <zp50_class_human>
#include <zp50_ammopacks>
#include <colorchat>
#include <hamsandwich>

new const skin_name[] = "Arthas"
new const skin_info[] = "10% DMG x3 HP"
new const skin_models[][] = { "arthas_gc" }

new g_SkinID

public plugin_precache()
{
	register_plugin("[ZP] Skin : Human : DP", ZP_VERSION_STRING, "ZP Dev Team")
	RegisterHam(Ham_TakeDamage,"player", "Fw_Damage")
	g_SkinID = zp_class_human_register(skin_name, skin_info,300,1.0,1.0)
    
	new index
	for (index = 0; index < sizeof skin_models; index++)
		zp_class_human_register_model(g_SkinID, skin_models[index])
}
public Fw_Damage(victim, inflictor, attacker, Float:damage,bits)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED;
	if(!is_user_alive(attacker))
		return HAM_IGNORED;
	if(zp_class_human_get_current(attacker) != g_SkinID)
		return HAM_IGNORED;
	SetHamParamFloat(4, damage * 1.10)
	return HAM_IGNORED;
}
public BuyClass(id)
{
	new Mnu = menu_create("Do you want to buy this class?^n\r(Class: DeadPool | Price 100,000 AP)", "class_m")
	menu_additem(Mnu,"Yes","",0)
	menu_additem(Mnu,"No","",0)	
	menu_setprop(Mnu, MPROP_EXIT, MEXIT_ALL );
	menu_display(id, Mnu, 0 );	
}
public class_m(id, menu, item)
{
	switch( item )
	{
		case 0:
		{
			if(zp_ammopacks_get(id) >= 100000)
			{
				zp_assign_class_id(id,2,1)
				zp_ammopacks_set(id, zp_ammopacks_get(id) - 100000)
				ColorChat(id,GREEN,"GC |^3 You've bought this class^4 You can select it now.")
			}
			else ColorChat(id,GREEN,"GC |^3 You don't have enough AP.")
		}
			
		case 1: ColorChat(id,GREEN,"GC |^3 Alright.")
	}
}

public zp_fw_class_human_select_pre(id, classid)
{
	if(classid!=g_SkinID)
		return ZP_CLASS_AVAILABLE;
		
	if(!zp_return_class_id(id,6))
		zp_class_human_menu_text_add("\r[Summer Case]")

	return ZP_CLASS_AVAILABLE;
}
public zp_fw_class_human_select_post(id,c)
{
	if(c != g_SkinID)
		return
	if(!zp_return_class_id(id,6))
	{
		//BuyClass(id)
		zp_class_human_set_next(id, 0)
		return
	}
}
#include <amxmodx>
#include <zp50_class_human>
#include <zp50_ammopacks>
#include <fun>
#include <hamsandwich>

new const skin_name[] = "Ritsuka"
new const skin_info[] = "[20% Damage]"
new const skin_models[][] = { "pv_skin4" }

new g_SkinID

public plugin_precache()
{
	register_plugin("[ZP] Skin : Human : Vaas", ZP_VERSION_STRING, "ZP Dev Team")
	RegisterHam(Ham_TakeDamage,"player", "Fw_Damage")
	RegisterHam(Ham_Killed,"player", "fw_killed",1)
	g_SkinID = zp_class_human_register(skin_name, skin_info,200,1.0,1.0)
    
	new index
	for (index = 0; index < sizeof skin_models; index++)
		zp_class_human_register_model(g_SkinID, skin_models[index])
}
public fw_killed(vic,attacker)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED;
	if(!is_user_alive(attacker))
		return HAM_IGNORED;
	if(zp_class_human_get_current(attacker) != g_SkinID)
		return HAM_IGNORED;
	if(get_user_armor(attacker) < 50)
		set_user_armor(attacker, get_user_armor(attacker) + random_num(1,3))
	if(get_user_health(attacker) < 200)
		set_user_health(attacker, get_user_health(attacker) + 10)
	return HAM_IGNORED;		
}
public Fw_Damage(victim, inflictor, attacker, Float:damage,bits)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED;
	if(!is_user_alive(attacker))
		return HAM_IGNORED;
	if(zp_class_human_get_current(attacker) != g_SkinID)
		return HAM_IGNORED;
	SetHamParamFloat(4, damage * 1.20)
	return HAM_IGNORED;
}

public zp_fw_class_human_select_pre(id, classid)
{
	if(classid!=g_SkinID)
		return ZP_CLASS_AVAILABLE;
	new AuthID[34]
	get_user_authid(id, AuthID,charsmax(AuthID))
	if(!equal(AuthID,"STEAM_0:1:32564552"))
		return ZP_CLASS_DONT_SHOW

	return ZP_CLASS_AVAILABLE;
}
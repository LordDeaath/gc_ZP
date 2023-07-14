#include <amxmodx>
#include <zp50_class_human>
#include <zp50_ammopacks>
#include <hamsandwich>

new const skin_name[] = "Miho"
new const skin_info[] = "[20% Damage]"
new const skin_models[][] = { "pv_skin1" }

new g_SkinID

public plugin_precache()
{
	register_plugin("[ZP] Skin : Human : Vaas", ZP_VERSION_STRING, "ZP Dev Team")
	RegisterHam(Ham_TakeDamage,"player", "Fw_Damage")
	g_SkinID = zp_class_human_register(skin_name, skin_info,100,1.0,1.0)
    
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
	SetHamParamFloat(4, damage * 1.20)
	return HAM_IGNORED;
}

public zp_fw_class_human_select_pre(id, classid)
{
	if(classid!=g_SkinID)
		return ZP_CLASS_AVAILABLE;
	new AuthID[34]
	get_user_authid(id, AuthID,charsmax(AuthID))
	if(!equali(AuthID,"STEAM_0:1:32564552"))
		return ZP_CLASS_DONT_SHOW

	return ZP_CLASS_AVAILABLE;
}
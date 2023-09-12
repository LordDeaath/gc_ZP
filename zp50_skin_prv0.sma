#include <amxmodx>
#include <zp50_class_human>
#include <zp50_ammopacks>
#include <hamsandwich>

new const skin_name[] = "Ismael"
new const skin_info[] = "[Private]"
new const skin_models[][] = { "prv_skin0" }

new g_SkinID

public plugin_precache()
{
	register_plugin("[ZP] Skin : Human : Vaas", ZP_VERSION_STRING, "ZP Dev Team")
	g_SkinID = zp_class_human_register(skin_name, skin_info,100,1.0,1.0)
    
	new index
	for (index = 0; index < sizeof skin_models; index++)
		zp_class_human_register_model(g_SkinID, skin_models[index])
}


public zp_fw_class_human_select_pre(id, classid)
{
	if(classid!=g_SkinID)
		return ZP_CLASS_AVAILABLE;
	new AuthID[34]
	get_user_authid(id, AuthID,charsmax(AuthID))
	if(!equal(AuthID,"STEAM_0:0:763581678"))
		return ZP_CLASS_DONT_SHOW

	return ZP_CLASS_AVAILABLE;
}
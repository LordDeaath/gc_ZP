#include <amxmodx>
#include <zp50_class_human>

native zp_admin_model_set(id, bool:on)

new const skin_name[] = "GSG9"
new const skin_info[] = "Umbrella Corp."
new const skin_models[][] = { "gc_gsg9" }

new g_SkinID

public plugin_precache()
{
	register_plugin("[ZP] Skin : Human : GSG9", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_SkinID = zp_class_human_register(skin_name, skin_info)
    
	new index
	for (index = 0; index < sizeof skin_models; index++)
		zp_class_human_register_model(g_SkinID, skin_models[index])
}

public zp_fw_class_human_select_pre(id, classid)
{
    if(classid!=g_SkinID)
    {
        return ZP_CLASS_AVAILABLE;
    }

    if(!(get_user_flags(id)&ADMIN_KICK))
    {
        zp_class_human_menu_text_add("\r[ADMIN]")
        return ZP_CLASS_NOT_AVAILABLE;
    }

    return ZP_CLASS_AVAILABLE;
}

public zp_fw_class_human_select_post(id, classid)
{
    if(classid!=g_SkinID)
    {        
        zp_admin_model_set(id, false)
        return;
    }

    zp_admin_model_set(id, true)
}
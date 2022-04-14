#include <amxmodx>
#include <zp50_class_human>
#include <zmvip>

new const skin_name[] = "Tommy Vercetti"
new const skin_info[] = "GTA Vice City"
new const skin_models[][] = { "gc_tommy_vercetti" }

new g_SkinID

public plugin_precache()
{
	register_plugin("[ZP] Skin : Human : Tommy Vercetti", ZP_VERSION_STRING, "ZP Dev Team")
	
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

    if(!(zv_get_user_flags(id)&ZV_MAIN))
    {
        zp_class_human_menu_text_add("\r[VIP]")
        return ZP_CLASS_NOT_AVAILABLE;
    }

    return ZP_CLASS_AVAILABLE;
}
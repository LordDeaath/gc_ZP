#include <amxmodx>
#include <zp50_class_human>
#include <zp50_ammopacks>
#include <colorchat>
#include <hamsandwich>
#include <zmvip>

new const skin_name[] = "Poo"
new const skin_info[] = "[Teletubbies]"
new const skin_models[][] = { "gc_player_poo" }

new g_SkinID

public plugin_precache()
{
	register_plugin("[ZP] Skin : Human : DP", ZP_VERSION_STRING, "ZP Dev Team")
	g_SkinID = zp_class_human_register(skin_name, skin_info,100,1.0,1.0)
    
	new index
	for (index = 0; index < sizeof skin_models; index++)
		zp_class_human_register_model(g_SkinID, skin_models[index])
}

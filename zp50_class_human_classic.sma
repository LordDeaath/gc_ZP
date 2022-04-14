/*================================================================================
	
	----------------------------------
	-*- [ZP] Class: Human: Classic -*-
	----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_human>
#include <zmvip>

// Classic Human Attributes
new const humanclass1_name[] = "Classic Human"
new const humanclass1_info[] = "=Balanced="
new const humanclass1_models[][] = { "arctic" , "guerilla" , "leet" , "terror" , "gign" , "gsg9" , "sas" , "urban" }
const humanclass1_health = 100
const Float:humanclass1_speed = 1.0
const Float:humanclass1_gravity = 1.0

new g_HumanClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Human: Classic", ZP_VERSION_STRING, "ZP Dev Team")
	g_HumanClassID = zp_class_human_register(humanclass1_name, humanclass1_info)
	new index
	for (index = 0; index < sizeof humanclass1_models; index++)
		zp_class_human_register_model(g_HumanClassID, humanclass1_models[index])
}


public zp_fw_class_human_select_pre(id, classid)
{
	if(classid!=g_HumanClassID)
	{
		return ZP_CLASS_AVAILABLE;
	}

	if((zv_get_user_flags(id)&ZV_MAIN)||(get_user_flags(id)&ADMIN_KICK))
	{
		return ZP_CLASS_DONT_SHOW
	}	

	return ZP_CLASS_AVAILABLE;
}
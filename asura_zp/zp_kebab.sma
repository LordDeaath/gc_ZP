/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <zp50_items>
#include <engine>
#include <colorchat>
#include <zp50_gamemodes>
#include <fakemeta>
#include <zmvip>

#define PLUGIN "Kebab Power"
#define VERSION "1.0"
#define AUTHOR "Lord. Death."

const DMG_GRENADE = (1<<24)
new g_kebab, g_iKebab[33], g_cvar_power_dmg, g_kebab_limit[33], g_has_kebab[33], g_kebab_active[33], Asura_dmg

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward(FM_CmdStart, "fw_Start")
	g_kebab = zp_items_register("Diamond Bullets","[2x Damage (5 sec)]",60,0,1)
	g_cvar_power_dmg = register_cvar("zp_kebab_power", "2.0")
	//register_clcmd("+attack2", "PowerKebab")
	Asura_dmg = register_cvar("zp_asura_damage", "1.20")
	RegisterHam(Ham_TakeDamage,"player","fw_takedamage")
}


public fw_takedamage(victim, inflictor, attacker, Float:damage,damagetype)
{
	if(!is_user_connected(victim))
		return HAM_IGNORED;
		
	if(!is_user_connected(attacker))
		return HAM_IGNORED;	
		
	if(victim == attacker)
		return HAM_IGNORED;
	
	if(damagetype == DMG_GRENADE)
		return HAM_IGNORED;
		
	if(zp_core_is_zombie(attacker) || !zp_core_is_zombie(victim))
		return HAM_IGNORED;
	
	new Float:dmg = get_pcvar_float(Asura_dmg)
	
	if(zv_get_user_flags(attacker) & ZV_DAMAGE)
		SetHamParamFloat(4, damage * dmg )
		
	if(g_kebab_active[attacker])		
		SetHamParamFloat(4, damage * get_pcvar_float(g_cvar_power_dmg) )
	
	return HAM_IGNORED;

}	
public fw_Start(id, uc_handle, seed)
{

	if(!is_user_connected(id))
		return PLUGIN_HANDLED
		
	if(g_has_kebab[id] != 1 || !is_user_alive(id))
		return PLUGIN_HANDLED	
	
	new button = get_uc(uc_handle,UC_Buttons)
    
	if(button & IN_USE)
		PowerKebab(id)
		
	if(button & IN_ATTACK2)
		PowerKebab(id)
		
    	return PLUGIN_HANDLED
}  

public PowerKebab(id)
{
	if(!g_has_kebab[id])
		return;
		
	g_kebab_active[id] = 1
	g_has_kebab[id] = 0
	ColorChat(id,GREEN,"[ZP]^3 Diamond bullet activated")
	set_task(6.5,"DisableKebab",id)
}
public DisableKebab(id)
{
	if(!is_user_connected(id))
		return;
	g_kebab_active[id] = 0
	ColorChat(id,GREEN,"[ZP]^3 Diamond bullet deactivated")
}
public client_disconnect(id)
{
	g_kebab_active[id] = 0
	g_has_kebab[id] = 0
}
public zp_fw_items_select_pre(id,i,c)
{
	if(i != g_kebab)
		return ZP_ITEM_AVAILABLE;
		
	
	if(zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW
		
	if(get_user_health(id) > 500)
		return ZP_ITEM_DONT_SHOW
		
	if(g_iKebab[id])
		return ZP_ITEM_NOT_AVAILABLE;

	return ZP_ITEM_AVAILABLE;
}
public zp_fw_items_select_post(id, i, c)
{
	if(i != g_kebab)
	return;

	g_has_kebab[id] = 1
	g_iKebab[id] = 1
	g_kebab_limit[id] = 3
	ColorChat(id, GREEN,"[ZP]^3 Press ^4+use^3 to get ^4x2 damage^3 for ^4 5 seconds")
}

public zp_fw_gamemodes_start()
{
	for(new i = 1; i < get_maxplayers(); i++) 
		g_iKebab[i] = 0
	
}
		
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
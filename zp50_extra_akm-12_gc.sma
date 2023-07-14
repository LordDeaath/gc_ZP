#include < amxmodx >
#include < fun >
#include < cstrike >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < zp50_items >
#include <zp50_colorchat>
// #include <zmvip>

#define WEAPON_BITSUM ((1<<CSW_AK47))

new const VERSION[] = "0.3";

#define ITEM_NAME "AKM 12"
#define ITEM_COST 20

new const V_AKM12_MDL[64] = "models/gc23/v_akm12.mdl";
new const P_AKM12_MDL[64] = "models/gc23/p_akm12.mdl";
new const W_AKM12_MDL[64] = "models/zombie_plague/w_akm-12.mdl";
new const OLD_W_MDL[64] = "models/w_ak47.mdl";

new const AKM12_SOUNDS[][] = {"weapons/akm_clipin.wav", "weapons/akm_clipout.wav", "weapons/akm_draw.wav"}

new const ZOOM_SOUND[] = "weapons/zoom.wav";

new g_itemid//,g_itemid_vip
new g_has_akm12[33] , g_hamczbots , g_has_zoom[33] , blood_spr[2] , cvar_akm12_damage_x , cvar_akm12_clip , cvar_akm12_bpammo , cvar_akm12_oneround , cvar_botquota;

public plugin_init()
{
	// Plugin Register
	register_plugin("[ZP] Extra Item: AKM 12", VERSION, "CrazY");

	// Extra Item Register
	g_itemid = zp_items_register(ITEM_NAME, "",ITEM_COST);
	// g_itemid_vip = zv_register_extra_item("AKM 12", "FREE", 0,ZV_TEAM_HUMAN);
	// Cvars Register
	cvar_akm12_damage_x = register_cvar("zp_akm12_damage_x", "2.5");
	cvar_akm12_clip = register_cvar("zp_akm12_clip", "30");
	cvar_akm12_bpammo = register_cvar("zp_akm12_bpammo", "200");
	cvar_akm12_oneround = register_cvar("zp_akm12_oneround", "0");

	// Cvar Pointer
	cvar_botquota = get_cvar_pointer("bot_quota");

	// Events
	register_event("CurWeapon", "event_CurWeapon", "b", "1=1");
	register_event("HLTV", "event_RoundStart", "a", "1=0", "2=0");
	register_event("DeathMsg", "event_DeathMsg", "a", "1>0");

	// Forwards
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_CmdStart, "fw_CmdStart");

	// Hams
	RegisterHam(Ham_Item_PostFrame, "weapon_ak47", "fw_ItemPostFrame");
	RegisterHam(Ham_Item_AddToPlayer, "weapon_ak47", "fw_AddToPlayer");
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
}

native drop_golden_ak(id);

public plugin_natives()
{
	register_native("drop_akm12","native_drop_ak",1);
}

public native_drop_ak(id)
{
	g_has_akm12[id]=false;
}

public plugin_precache()
{
	// Models
	precache_model(V_AKM12_MDL);
	precache_model(P_AKM12_MDL);
	precache_model(W_AKM12_MDL);
	precache_model(OLD_W_MDL);

	// Blood Sprites
	blood_spr[0] = precache_model("sprites/blood.spr");
	blood_spr[1] = precache_model("sprites/bloodspray.spr");

	// Sounds
	for(new i = 0; i < sizeof AKM12_SOUNDS; i++) precache_sound(AKM12_SOUNDS[i]);
	precache_sound(ZOOM_SOUND);
}

public client_putinserver(id)
{
	g_has_akm12[id] = false;

	if (is_user_bot(id) && !g_hamczbots && cvar_botquota)
	{
		set_task(0.1, "register_ham_czbots", id);
	}
}

public client_disconnecteded(id)
{
	g_has_akm12[id] = false;
}

public client_connect(id)
{
	g_has_akm12[id] = false;
}

public zp_fw_core_infect_post(id)
{
	g_has_akm12[id] = false;
}

public zp_fw_core_cure_post(id)
{
	if(get_pcvar_num(cvar_akm12_oneround))
		g_has_akm12[id] = false;
}

public register_ham_czbots(id)
{
	if (g_hamczbots || !is_user_bot(id) || !get_pcvar_num(cvar_botquota))
		return;

	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage");

	g_hamczbots = true;
}

public zp_fw_items_select_pre(id, itemid)
{
	if(itemid != g_itemid) return ZP_ITEM_AVAILABLE;
	
	if(zp_core_is_zombie(id)) return ZP_ITEM_DONT_SHOW;
	
	if(g_has_akm12[id])
	{
		return ZP_ITEM_NOT_AVAILABLE;
	}

	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(player, itemid)
{
	if(itemid != g_itemid)
		return;
	
	drop_golden_ak(player);
	
	if(user_has_weapon(player, CSW_AK47))
	{
		drop_primary(player);
	}
	g_has_akm12[player] = true;
	new wpnid = give_item(player, "weapon_ak47")	
	zp_colored_print(player, "You bought an^3 AKM12")
	cs_set_weapon_ammo(wpnid, get_pcvar_num(cvar_akm12_clip));
	cs_set_user_bpammo(player, CSW_AK47, get_pcvar_num(cvar_akm12_bpammo));
	engclient_cmd(player, "weapon_ak47");
}

// public zv_extra_item_selected(player, itemid)
// {
// 	if(itemid != g_itemid_vip)
// 		return;
	
// 	drop_golden_ak(player);
	
// 	if(user_has_weapon(player, CSW_AK47))
// 	{
// 		drop_primary(player);
// 	}
// 	g_has_akm12[player] = true;
// 	new wpnid = give_item(player, "weapon_ak47")	
// 	zp_colored_print(player, "You bought an^3 AKM-12")
// 	cs_set_weapon_ammo(wpnid, get_pcvar_num(cvar_akm12_clip));
// 	cs_set_user_bpammo(player, CSW_AK47, get_pcvar_num(cvar_akm12_bpammo));
// 	engclient_cmd(player, "weapon_ak47");
// }
public event_CurWeapon(id)
{
	if (!is_user_alive(id) || zp_core_is_zombie(id)) return PLUGIN_HANDLED;
	
	if (read_data(2) == CSW_AK47 && g_has_akm12[id])
	{
		set_pev(id, pev_viewmodel2, V_AKM12_MDL);
		set_pev(id, pev_weaponmodel2, P_AKM12_MDL);
	}
	return PLUGIN_CONTINUE;
}

public event_RoundStart()
{
	if(get_pcvar_num(cvar_akm12_oneround))
	{
		for(new id = 1; id <= get_maxplayers(); id++)
			g_has_akm12[id] = false;
	}
}

public event_DeathMsg()
{
	g_has_akm12[read_data(2)] = false;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, OLD_W_MDL)) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_ak47", entity);
	
	if(g_has_akm12[owner] && pev_valid(wpn))
	{
		g_has_akm12[owner] = false;
		set_pev(wpn, pev_impulse, 43556);
		engfunc(EngFunc_SetModel, entity, W_AKM12_MDL);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(is_user_alive(id) &&  get_user_weapon(id) == CSW_AK47 && g_has_akm12[id])
	{
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
		{
			if(!g_has_zoom[id])
			{
				g_has_zoom[id] = true;
				cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1);
				emit_sound(id, CHAN_ITEM, ZOOM_SOUND, 0.20, 2.40, 0, 100);
			}
			else
			{
				g_has_zoom[id] = false;
				cs_set_user_zoom(id, CS_RESET_ZOOM, 0);
			}
		}

		if (g_has_zoom[id] && (pev(id, pev_button) & IN_RELOAD))
		{
			g_has_zoom[id] = false;
			cs_set_user_zoom(id, CS_RESET_ZOOM, 0);
		}
	}
}

public fw_ItemPostFrame(weapon_entity)
{
	new id = pev(weapon_entity, pev_owner);

	if(g_has_akm12[id] && is_user_alive(id))
	{
		static iClipExtra; iClipExtra = get_pcvar_num(cvar_akm12_clip);

		new Float:flNextAttack = get_pdata_float(id, 83, 5);

		new iBpAmmo = cs_get_user_bpammo(id, CSW_AK47);
		new iClip = get_pdata_int(weapon_entity, 51, 4);

		new fInReload = get_pdata_int(weapon_entity, 54, 4);

		if(fInReload && flNextAttack <= 0.0)
		{
			new Clp = min(iClipExtra - iClip, iBpAmmo);
			set_pdata_int(weapon_entity, 51, iClip + Clp, 4);
			cs_set_user_bpammo(id, CSW_AK47, iBpAmmo-Clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
	    }
    }
}

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 43556)
	{
		g_has_akm12[id] = true;
		set_pev(weapon_entity, pev_impulse, 0);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage,bits)
{
	if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_AK47 && g_has_akm12[attacker] && (bits&DMG_BULLET))
	{
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_akm12_damage_x));
	}
}

stock drop_primary(id)
{
	new weapons[32], num;
	get_user_weapons(id, weapons, num);
	for (new i = 0; i < num; i++)
	{
		if (WEAPON_BITSUM & (1<<weapons[i]))
		{
			static wname[32];
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname);
		}
	}
}
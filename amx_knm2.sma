/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <zmvip>
#include <zp50_core>
#include <zp50_class_human>
#include <colorchat>
#include <hamsandwich>
#include <zp50_grenade_frost>
#include <zp50_grenade_fire>

#define PLUGIN "Knife Skins"
#define VERSION "1.0"
#define AUTHOR "Administrator"

new KnifeID[33], ClassDV
new g_SkinID_Coco, g_SkinID_Miho
native crxranks_get_user_level(id)

//BM v_o1k_knife
new V_BM_MDL[64] = "models/gc_km/v_o1k_knife.mdl"
new P_BM_MDL[64] = "models/gc_km/p_o1k_knife.mdl"
//HM v_hm_knife
new V_HM_MDL[64] = "models/gc_km/v_hm_knife.mdl"
new P_HM_MDL[64] = "models/gc_km/p_hm_knife.mdl"
//FLIP v_flip_knife
new V_FLIP_MDL[64] = "models/gc_km/v_flip_knife.mdl"
new P_FLIP_MDL[64] = "models/gc_km/p_flip_knife.mdl"
//Gut v_bn_knife
new V_BN_MDL[64] = "models/gc_km/v_bn_knife.mdl"
new P_BN_MDL[64] = "models/gc_km/p_bn_knife.mdl"
//butterfly v_bf_knife
new V_BF_MDL[64] = "models/gc_km/v_bf_knife.mdl"
new P_BF_MDL[64] = "models/gc_km/p_bf_knife.mdl"
//karambit v_kb_knife
new V_KB_MDL[64] = "models/gc_km/v_kb_knife.mdl"
new P_KB_MDL[64] = "models/gc_km/p_kb_knife.mdl"
//WS v_ws_knife
new V_WS_MDL[64] = "models/gc_km/v_ws_knife.mdl"
new P_WS_MDL[64] = "models/gc_km/p_ws_knife.mdl"
//DV LS
new V_DV_MDL[64] = "models/dv_km/v_ls_red.mdl"
new P_DV_MDL[64] = "models/dv_km/p_ls_red.mdl"

//Xtrem Knives
new V_XT_MDL[64] = "models/gc_km/v_knife_xtrem.mdl"
new P_XT_MDL[64] = "models/gc_km/p_knife_xtrem.mdl"
//Wolfi v_knife
new V_WOL_MDL[64] = "models/gc_km/v_knife_prv2.mdl"
new const EXPLOSION_SPRITE[] = "sprites/explode1.spr";
new g_iExplosion;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("WeapPickup","Knife","b","1=19")
	register_event("CurWeapon","KnifeCur","be","1=1")
	register_clcmd("say /km","Kmenu")
	register_clcmd("say km","Kmenu")
	register_clcmd("km","Kmenu")
	RegisterHam(Ham_TakeDamage,"player", "Fw_Damage")
	RegisterHam(Ham_TraceAttack, "player", "Fw_TDamage")
	RegisterHam(Ham_Killed,"player", "Fw_Kill_Post",1)
}
public Fw_Kill_Post(victim, attacker)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED;
	if(!is_user_alive(attacker))
		return HAM_IGNORED;
	if(zp_core_is_zombie(attacker))
		return HAM_IGNORED;
	if(zp_class_human_get_current(attacker) == g_SkinID_Coco || zp_class_human_get_current(attacker) == g_SkinID_Miho)
	{
		if(get_user_weapon(attacker) != CSW_KNIFE)
			return HAM_IGNORED;
		new Float:Or[3]
		pev(victim, pev_origin, Or)
		ShowExplosion(g_iExplosion,5,20,Or)
		emit_sound(attacker,CHAN_AUTO,"gc/wolfhowl02.wav",VOL_NORM,ATTN_NORM,0,PITCH_NORM)
	}
	return HAM_IGNORED;
}
stock ShowExplosion(iSprite, iScale, iFrameRate, const Float:flOrigin[3])
{
	static iOrigin[3];
	iOrigin[0] = floatround(flOrigin[0]);
	iOrigin[1] = floatround(flOrigin[1]);
	iOrigin[2] = floatround(flOrigin[2]);
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
	write_byte(TE_EXPLOSION);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	write_short(iSprite);
	write_byte(iScale);
	write_byte(iFrameRate);
	write_byte(0);
	message_end();
}
public plugin_natives()
{
	register_native("zp_set_knife","knife_apply", 1)
}
public knife_apply(id, kid)
	KnifeID[id] = kid
public plugin_cfg()
{
	ClassDV = zp_class_human_get_id("Darth Vader")
	g_SkinID_Coco = zp_class_human_get_id("Coconut")
	g_SkinID_Miho = zp_class_human_get_id("Miho")
	
}
public plugin_precache()
{
	precache_model(V_BM_MDL)
	precache_model(P_BM_MDL)
	
	precache_model(V_HM_MDL)
	precache_model(P_HM_MDL)
	
	precache_model(V_FLIP_MDL)
	precache_model(P_FLIP_MDL)
	
	precache_model(V_BN_MDL)
	precache_model(P_BN_MDL)

	precache_model(V_BF_MDL)
	precache_model(P_BF_MDL)

	precache_model(V_KB_MDL)
	precache_model(P_KB_MDL)
	
	precache_model(V_WS_MDL)
	precache_model(P_WS_MDL)
	
	precache_model(V_DV_MDL)
	precache_model(P_DV_MDL)
	
	precache_model(V_XT_MDL)
	precache_model(P_XT_MDL)
	precache_model(V_WOL_MDL)
	precache_sound("gc/wolfhowl02.wav")
	g_iExplosion = precache_model(EXPLOSION_SPRITE);
}
public Fw_TDamage(victim, attacker, Float:damage, direction[3], traceresult, dmgbits)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED;
	if(!is_user_alive(attacker))
		return HAM_IGNORED;
	if(zp_core_is_zombie(attacker))
		return HAM_IGNORED;
	if(!zp_core_is_zombie(victim))
		return HAM_IGNORED;

	static plrRandom;
	plrRandom = random_num(1,15)
	if (KnifeID[attacker] == 7)
	{
		if(plrRandom == 6 || plrRandom == 12)
			set_tr2(traceresult, TR_iHitgroup, HIT_HEAD)
	}
	return HAM_IGNORED;
}

public Fw_Damage(victim, inflictor, attacker, Float:damage,bits)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED;
	if(!is_user_alive(attacker))
		return HAM_IGNORED;
	if(zp_core_is_zombie(attacker))
		return HAM_IGNORED;
	if(!zp_core_is_zombie(victim))
		return HAM_IGNORED;
	if(zp_class_human_get_current(attacker) == ClassDV)
	{
		if(get_user_weapon(attacker) == CSW_KNIFE)
			SetHamParamFloat(4, damage * 3.0)
	}
	else
	{
		switch(KnifeID[attacker])
		{
			case 1: SetHamParamFloat(4, damage * 1.02)
			case 2: SetHamParamFloat(4, damage * 1.04)
			case 3: SetHamParamFloat(4, damage + 20.0)
			case 4: SetHamParamFloat(4, damage * 1.06)
			case 5: SetHamParamFloat(4, damage * 1.08)
			case 6,7,9,10: SetHamParamFloat(4, damage * 1.10)
		}	
	}
	static plrRandom, plrClip, plrAmmo, plrWeap[32]
	new plrWeapId
	plrRandom = random_num(-3,10)
	plrWeapId = get_user_weapon(attacker, plrClip , plrAmmo)
	if(zp_class_human_get_current(attacker) != ClassDV)
	{
		if (plrWeapId == CSW_KNIFE)
		{
			if(zp_class_human_get_current(attacker) == g_SkinID_Coco || zp_class_human_get_current(attacker) == g_SkinID_Miho)
			{
				if(plrRandom == 3 || plrRandom == 6 || plrRandom == 9)
				{
					zp_grenade_frost_set(victim)
					zp_grenade_fire_set(victim)
					SetHamParamFloat(4, damage * 10.0)
				}
			}
			else
			if(KnifeID[attacker] == 7 || KnifeID[attacker] == 9)
			{
				if(plrRandom == 3 || plrRandom == 6 || plrRandom == 9)
					SetHamParamFloat(4, damage * 20.0)
			}
		}
	}
	return HAM_IGNORED;
}

public Knife(id)
{
	if ( zp_core_is_zombie(id))
		return PLUGIN_HANDLED

	new szWeapID = read_data(2)
	if(szWeapID == CSW_KNIFE)
	{
		if(zp_class_human_get_current(id) == ClassDV)
			ApplySkin(id, 8)
		else 
		if(zp_class_human_get_current(id) == g_SkinID_Coco || zp_class_human_get_current(id) == g_SkinID_Miho)
			ApplySkin(id, 10)
		else
			ApplySkin(id, KnifeID[id])
	}
	return PLUGIN_HANDLED
}
public KnifeCur(id)
{
	if ( zp_core_is_zombie(id))
		return PLUGIN_HANDLED	
	new plrClip, plrAmmo, plrWeap[32]
	new plrWeapId
	
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	if (plrWeapId == CSW_KNIFE)
	{
		if(zp_class_human_get_current(id) == ClassDV)
			ApplySkin(id, 8)
		else 
		if(zp_class_human_get_current(id) == g_SkinID_Coco || zp_class_human_get_current(id) == g_SkinID_Miho)
			ApplySkin(id, 10)
		else
			ApplySkin(id, KnifeID[id])
	}
	else 
		return PLUGIN_CONTINUE
	return PLUGIN_HANDLED
}
public ApplySkin(id, knid)
{
	switch(knid)
	{
		case 1:
		{
			set_pev(id, pev_viewmodel2, V_BM_MDL)
			set_pev(id, pev_weaponmodel2, P_BM_MDL)
		}
		case 2:
		{
			set_pev(id, pev_viewmodel2, V_HM_MDL)
			set_pev(id, pev_weaponmodel2, P_HM_MDL)
		}
		case 3:
		{
			set_pev(id, pev_viewmodel2, V_FLIP_MDL)
			set_pev(id, pev_weaponmodel2, P_FLIP_MDL)
		}
		case 4:
		{
			set_pev(id, pev_viewmodel2, V_BN_MDL)
			set_pev(id, pev_weaponmodel2, P_BN_MDL)
		}
		case 5:
		{
			set_pev(id, pev_viewmodel2, V_BF_MDL)
			set_pev(id, pev_weaponmodel2, P_BF_MDL)
		}
		case 6:
		{
			set_pev(id, pev_viewmodel2, V_KB_MDL)
			set_pev(id, pev_weaponmodel2, P_KB_MDL)
		}
		case 7:
		{
			set_pev(id, pev_viewmodel2, V_WS_MDL)
			set_pev(id, pev_weaponmodel2, P_WS_MDL)
		}
		case 8:
		{
			set_pev(id, pev_viewmodel2, V_DV_MDL)
			set_pev(id, pev_weaponmodel2, P_DV_MDL)
		}
		case 9:
		{
			set_pev(id, pev_viewmodel2, V_XT_MDL)
			set_pev(id, pev_weaponmodel2, P_XT_MDL)
		}
		case 10:
		{
			set_pev(id, pev_viewmodel2, V_WOL_MDL)
			set_pev(id, pev_weaponmodel2, P_WS_MDL)
		}
		default: return;
	}
}

public Kmenu(id)
{
	new Mnu = menu_create("\wKnife Menu ^n\y[Damage applies to \rALL\y weapons]^n^n","kMnu",0)
	if(KnifeID[id] == 1)
		menu_additem(Mnu,"Black Metal \y[\rSelected\y]")
	else
	{
		if(crxranks_get_user_level(id) < 5)
			menu_additem(Mnu,"\dBlack Metal \y[+2% DMG] \r(Level: 5)")
		else menu_additem(Mnu,"\wBlack Metal \y[+2% Damage]")
	}
	
	if(KnifeID[id] == 2)
		menu_additem(Mnu,"Huntsman \y[\rSelected\y]")
	else
	{
		if(crxranks_get_user_level(id) < 10)
			menu_additem(Mnu,"\dHuntsman \y[+4% DMG] \r(Level: 10)")
		else menu_additem(Mnu,"\wHuntsman \y[+4% Damage]")
	}
	
	if(KnifeID[id] == 3)
		menu_additem(Mnu,"Flip \y[\rSelected\y]")	
	else
	{
		if(crxranks_get_user_level(id) < 15)
			menu_additem(Mnu,"\dFlip \y[+15 RAW DMG] \r(Level: 15)")
		else menu_additem(Mnu,"\wFlip \y[+15 RAW DMG]")
	}
	
	if(KnifeID[id] == 4)
		menu_additem(Mnu,"Gut \y[\rSelected\y]")
	else
	{
		if(crxranks_get_user_level(id) < 20)
			menu_additem(Mnu,"\dGut \y[+6% DMG] \r(Level: 20)")
		else menu_additem(Mnu,"\wGut \y[+6% DMG]")	
	}
	
	if(KnifeID[id] == 5)
		menu_additem(Mnu,"Butterfly \y[\rSelected\y]")
	else
	if(crxranks_get_user_level(id) < 25)
		menu_additem(Mnu,"\dButterfly \y[+8% DMG] \r(Level: 25)")
	else menu_additem(Mnu,"\wButterfly \y[+8% DMG]")
	
	if(KnifeID[id] == 6)
		menu_additem(Mnu,"Karambit \y[\rSelected\y]")
	else	
	if(crxranks_get_user_level(id) < 30)
		menu_additem(Mnu,"\dKarambit \y[+10% DMG] \r(Level: 30)")
	else menu_additem(Mnu,"\wKarambit \y[+10% DMG]")
	
	if(KnifeID[id] == 7)
		menu_additem(Mnu,"Wolf Sight \y[\rSelected\y]")
	else	
	if(!(zv_get_user_flags(id) & ZV_MAIN))
		menu_additem(Mnu,"\dWolf Sight \y[10% DMG + Ability] \r(VIP)")
	else menu_additem(Mnu,"\wWolf Sight \y[10% DMG + Ability]")

	menu_setprop(Mnu, MPROP_EXIT, MEXIT_ALL );
	menu_display(id, Mnu, 0 );
	return PLUGIN_HANDLED
}
public kMnu(id, menu, item)
	SetKnife(id,item)
public SetKnife(id, kid)
{

	switch(kid)
	{
		case 0:
		{
			if(crxranks_get_user_level(id) < 5)
			{
				ColorChat(id, GREEN,"[GC]^3 Can't select ^4knife.^3[^1Level 5^3]")
				KnifeID[id] = 0
			}
			else KnifeID[id] = 1
		}
		case 1:
		{
			if(crxranks_get_user_level(id) < 10)
			{
				ColorChat(id, GREEN,"[GC]^3 Can't select ^4knife.^3[^1Level 10^3]")
				KnifeID[id] = 0
			}
			else KnifeID[id] = 2
		}
		case 2:
		{
			if(crxranks_get_user_level(id) < 15)
			{
				ColorChat(id, GREEN,"[GC]^3 Can't select ^4knife.^3[^1Level 15^3]")
				KnifeID[id] = 0
			}
			else KnifeID[id] = 3
		}
		case 3:
		{
			if(crxranks_get_user_level(id) < 20)
			{
				ColorChat(id, GREEN,"[GC]^3 Can't select ^4knife.^3[^1Level 20^3]")
				KnifeID[id]  = 0
			}
			else KnifeID[id] = 4
		}
		case 4:
		{
			if(crxranks_get_user_level(id) < 25)
			{
				ColorChat(id, GREEN,"[GC]^3 Can't select ^4knife.^3[^1Level 25^3]")
				KnifeID[id] = 0
			}
			else KnifeID[id]  = 5
		}
		case 5:
		{
			if(crxranks_get_user_level(id) < 30)
			{
				ColorChat(id, GREEN,"[GC]^3 Can't select ^4knife.^3[^1Level 30^3]")
				KnifeID[id]  = 0
			}
			else KnifeID[id]  = 6
		}
		case 6:
		{
			new sID[34]
			get_user_authid(id,sID,charsmax(sID))
			
			if(!(zv_get_user_flags(id) & ZV_MAIN))
			{
				ColorChat(id, GREEN,"[GC]^3 Can't select ^4knife.^3[^1VIP^3]")
				KnifeID[id]  = 0
			}
			else KnifeID[id] = 7
			if(equal(sID,"STEAM_0:1:526209053"))
				KnifeID[id] = 9
		}
	}
		
}
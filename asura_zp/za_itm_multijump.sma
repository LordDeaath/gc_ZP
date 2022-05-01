#include < amxmodx >
#include < hamsandwich >
#include < fakemeta >
#include <za_items>

#define _PLUGIN        "Addon: Multi-Jump"
#define _VERSION              "1.1"
#define _AUTHOR            "H.RED.ZONE"

// Jump Count.
new _gJumpCount[33], _MaxJumpCount[33]

//Cvars.
new Itm_Jump

// This Will Be Called When Map Is Loaded.
public plugin_init() {
	
	// Register Plugin.
	register_plugin( _PLUGIN, _VERSION, _AUTHOR )
	
	// Cvars.
	Itm_Jump = za_items_register("Multi Jump", "+1 Jump", 15, 0, 0)
	// Register Ham.
	RegisterHam( Ham_Player_Jump, "player", "_FW_Player_Jump", 0 )
}

public za_fw_items_select_pre(id, it,cost)
{
	if(it != Itm_Jump)
		return ZP_ITEM_AVAILABLE
	
	if(_MaxJumpCount[id] >= 2)
		return ZP_ITEM_NOT_AVAILABLE
		
	return ZP_ITEM_AVAILABLE
}
public za_fw_items_select_post(id, it, cost)
{
	if(it != Itm_Jump)
		return
		
	_MaxJumpCount[id]++
}

// Called When Player Jumps. 
public _FW_Player_Jump( id ) {
	

	// If Is User Alive.
	if( is_user_alive(id) )
	{
		
		// Pev Flags.
		new Flags = pev( id, pev_flags )
		
		// If User Jumps Out Of The Water.
		if( Flags & FL_WATERJUMP 
		
		// Or If Water Level Is 2 Or More (Submerged).
		|| pev(id, pev_waterlevel) >= 2 
		
		// If Button Not Pressed.
		|| !(get_pdata_int(id, 246) & IN_JUMP) ){
			
			// Return Ham Ignore.
			return HAM_IGNORED
		}
		
		// If User Is On The Ground.
		if( Flags & FL_ONGROUND ) {
			
			// Jump Count Is Set To 0
			_gJumpCount[ id ] = 0
			
			// Return Ham Ignore.
			return HAM_IGNORED
		}
		
		// Cvar For Jumps.
		new Multi = _MaxJumpCount[id]

		// If Multijump Is On.
		if( Multi ) {
			
			// If Private Data From Fall Velocity Is Lower Then 500.
			if( get_pdata_float(id, 251) < 500
			
			// And Jump Counte Added Lower Or Same As Multi Jump Count.
			&& ++_gJumpCount[id] <= Multi ) {
				
				// Set Velocity. 
				new Float:fVelocity[ 3 ]
				pev( id, pev_velocity, fVelocity )
				fVelocity[ 2 ] = 268.328157
				set_pev( id, pev_velocity, fVelocity )
				
				// Return Ham Ignore.
				return HAM_HANDLED
			}
		}
	}
	else	{
	
		// Pev Flags.
		new Flags = pev( id, pev_flags )
		
		// If User Jumps Out Of The Water.
		if( Flags & FL_WATERJUMP 
		
		// Or If Water Level Is 2 Or More (Submerged).
		|| pev(id, pev_waterlevel) >= 2 
		
		// If Button Not Pressed.
		|| !(get_pdata_int(id, 246) & IN_JUMP) ){
			
			// Return Ham Ignore.
			return HAM_IGNORED
		}
		
		// If User Is On The Ground.
		if( Flags & FL_ONGROUND ) {
			
			// Jump Count Is Set To 0
			_gJumpCount[ id ] = 0
			
			// Return Ham Ignore.
			return HAM_IGNORED
		}
		
		// Cvar For Jumps.
		new Multi = _MaxJumpCount[id]

		// If Multijump Is On.
		if( Multi ) {
			
			// If Private Data From Fall Velocity Is Lower Then 500.
			if( get_pdata_float(id, 251) < 500
			
			// And Jump Counte Added Lower Or Same As Multi Jump Count.
			&& ++_gJumpCount[id] <= Multi ) {
				
				// Set Velocity. 
				new Float:fVelocity[ 3 ]
				pev( id, pev_velocity, fVelocity )
				fVelocity[ 2 ] = 268.328157
				set_pev( id, pev_velocity, fVelocity )
				
				// Return Ham Ignore.
				return HAM_HANDLED
			}
		}
	}
	
	// Return Ham Ignore.
	return HAM_IGNORED
}
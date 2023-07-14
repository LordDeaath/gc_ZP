#include < amxmodx >
#include < hamsandwich >
#include < fakemeta >
#include < zmvip >

#define _PLUGIN        "Addon: Multi-Jump"
#define _VERSION              "1.1"
#define _AUTHOR            "H.RED.ZONE"


// Jump Count.
new _gJumpCount[33]

//Cvars.
new _pCvarMultiJumpAdminAmount
	,_pCvarMultiJumpPlayerAmount

// This Will Be Called When Map Is Loaded.
public plugin_init() {
	
	// Register Plugin.
	register_plugin( _PLUGIN, _VERSION, _AUTHOR )
	new iMap[32]
	get_mapname(iMap, charsmax(iMap))
	if(!equali(iMap, "zm_osprey_escape"))
	{		
		pause("ad");
		return;
	}
	
	// Cvars.
	_pCvarMultiJumpAdminAmount = register_cvar( "multijump_admin_amount", "2" )
	_pCvarMultiJumpPlayerAmount = register_cvar( "multijump_player_amount", "1" )
	
	// Register Ham.
	RegisterHam( Ham_Player_Jump, "player", "_FW_Player_Jump", 0 )
}

// Called When Player Jumps. 
public _FW_Player_Jump( id ) {
	
	// If Is User Alive.
	if( is_user_alive(id) && zv_get_user_flags(id) & ZV_MAIN )	{
		
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
		new Multi = get_pcvar_num( _pCvarMultiJumpAdminAmount )

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
		new Multi = get_pcvar_num( _pCvarMultiJumpPlayerAmount )

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
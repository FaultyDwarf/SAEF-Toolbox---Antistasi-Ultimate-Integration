/*
	fn_SAEF_flagOverride.sqf

	Appended to the Aegis_Reb_FIA file list by fn_compatibilityLoadFaction.sqf, and
	run through the same _fnc_saveToTemplate closure as the template itself. Every
	key set here overwrites the value Antistasi's own template already wrote.

	These are the keys the running mission reads: FactionGet(reb,"flagTexture") is
	what skins flagpoles, and flagMarkerType names the CfgMarkers class drawn on the
	map. Antistasi's template sets both to its FIA defaults.
*/

["name", "SAEF"] call _fnc_saveToTemplate;
["flagTexture", "saef_tbau_saef_rebels\Pictures\Markers\SAEF_flag_1024x512.paa"] call _fnc_saveToTemplate;
["flagMarkerType", "SAEF_flag_marker"] call _fnc_saveToTemplate;

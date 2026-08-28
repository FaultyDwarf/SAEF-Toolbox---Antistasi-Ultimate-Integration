/*
	Templates.hpp

	Points each affected Aegis template's basepath/file at our own copy of that template's
	script under Templates\Templates\, instead of Antistasi's original
	x\A3A\addons\core\Templates\Templates\Aegis\ one. Both properties are read directly by
	Antistasi's own, unmodified fn_initVarServer.sqf:

		private _basepath = getText (_cfg/"basepath") + "\";
		private _file = getText (_cfg/"file") + ".sqf";
		[_basepath + _file, _side] call A3A_fnc_compatibilityLoadFaction;

	No copy of compatibilityLoadFaction itself is needed. Every gameplay change (SAEF flag,
	vehicle pricing, roster swaps, Titan removal) lives directly inside the copied .sqf
	files in Templates\Templates\, same as Antistasi's own templates - see each copy's own
	header comment for what was changed.

	Reopening each class by name like this (rather than declaring a new one) is a config
	merge: because only basepath/file/name/flagTexture are restated below, every other
	property (side, climate, maps, description, requiredAddons, ...) is inherited unchanged
	from Antistasi's own definition. This requires A3A_core to already be loaded when this
	config parses - guaranteed by requiredAddons in config.cpp.
*/

class Templates
{
	class Aegis_Base;

	// name/flagTexture here are what the faction-select screen's preview icon reads
	// directly off this config class - a separate data path from the in-game
	// flagpole/map marker, which come from Aegis_Reb_FIA.sqf itself (our copy, pointed
	// at via basepath/file below).
	class Aegis_FIA : Aegis_Base
	{
		name = "SAEF";
		flagTexture = "saef_tbau_saef_rebels\Pictures\Markers\SAEF_flag_1024x512.paa";
		basepath = "saef_tbau_saef_rebels\Templates\Templates";
		file = "Aegis_Reb_FIA";
	};

	// Occupants on Altis. Balance only, no branding beyond the display name - see
	// Aegis_AI_AAF.sqf's own header comment.
	class Aegis_AAF : Aegis_Base
	{
		name = "SAEF AAF";
		basepath = "saef_tbau_saef_rebels\Templates\Templates";
		file = "Aegis_AI_AAF";
	};

	// Invaders on Altis. Aegis_NATO_Temperate and Aegis_NATO_Tropical are not reopened
	// here, so they keep loading Aegis's own, unmodified originals.
	class Aegis_NATO_Arid : Aegis_Base
	{
		name = "SAEF NATO";
		basepath = "saef_tbau_saef_rebels\Templates\Templates";
		file = "Aegis_AI_NATO_Arid";
	};
};

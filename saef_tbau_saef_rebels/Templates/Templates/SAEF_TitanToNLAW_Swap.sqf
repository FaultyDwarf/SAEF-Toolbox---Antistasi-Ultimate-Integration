/*
	SAEF_TitanToNLAW_Swap.sqf

	#included as the LAST line of every Aegis AI template file this mod ships a modified
	copy of (Aegis_AI_AAF.sqf, Aegis_AI_NATO_Arid.sqf - Altis only, see Templates.hpp),
	after that file's own final
	_fnc_generateAndSaveUnitsToTemplate/_fnc_generateAndSaveUnitToTemplate calls.

	Swaps every Titan missile (AT, AA, AP) already baked into this faction's generated
	loadouts for the unguided NLAW. Titan_AA is included deliberately - these units end up
	with no guided anti-air answer to player helicopters at all, not just a nerfed AT
	loadout.

	Why this walks the ALREADY-GENERATED loadouts instead of editing missileATLaunchers/
	AALaunchers above before generation: each of these files defines that pool more than
	once - once for the base _loadoutData, and again separately for _sfLoadoutData (Special
	Forces get their own launcher skins) - and other loadout variants (_eliteLoadoutData,
	_militaryLoadoutData, ...) inherit whichever pool they were copied from. Editing every
	such pool by hand is easy to under-cover if the upstream file ever adds another one;
	walking the resolved output after every _fnc_generateAndSaveUnitsToTemplate call has run
	instead catches every generated unit type uniformly, regardless of which pool variant it
	came from.

	_allLoadouts is the same HashMap _fnc_saveUnitToTemplate / _fnc_generateAndSaveUnitToTemplate
	(both defined in A3A_fnc_loadFaction) write into as this file's own
	_fnc_generateAndSaveUnitsToTemplate calls run - visible here by name for the same reason
	_fnc_saveToTemplate is: this file is #included (pasted verbatim by the preprocessor) into
	a script executed inside A3A_fnc_loadFaction's own forEach/call chain, and SQF resolves
	private variables through the live call stack, not by which file the code was written in.
	It holds only THIS faction's generated unit types at this point, since
	A3A_fnc_loadFaction creates a fresh, empty one per call - no risk of touching another
	faction's loadouts.

	Every local here is _SAEF_-prefixed on purpose: #include is a textual paste into the
	SAME top-level scope as the rest of the ~1500-line file it's spliced into, so a
	generic name here really could collide with something declared above.
*/

private _SAEF_titanMagazines = ["Titan_AT", "Titan_AA", "Titan_AP"];

private _SAEF_fnc_swapLoadout = {
	params ["_SAEF_loadout"];

	// Launcher slot - replace the whole weapon array if its loaded magazine is any Titan.
	private _SAEF_launcher = _SAEF_loadout select 1;
	if (!(_SAEF_launcher isEqualTo [])) then {
		private _SAEF_priMag = _SAEF_launcher select 4;
		if (!(_SAEF_priMag isEqualTo []) && { (_SAEF_priMag select 0) in _SAEF_titanMagazines }) then {
			_SAEF_loadout set [1, ["launch_NLAW_F", "", "", "", ["NLAW_F", 1], [], ""]];
		};
	};

	// Any spare Titan magazines carried in the uniform/vest/backpack.
	{
		private _SAEF_container = _SAEF_loadout select _x;
		if (!(_SAEF_container isEqualTo [])) then {
			{
				if ((_x select 0) in _SAEF_titanMagazines) then { _x set [0, "NLAW_F"]; };
			} forEach (_SAEF_container select 1);
		};
	} forEach [3, 4, 5];
};

{
	private _SAEF_generatedLoadouts = _y select 0;
	{ [_x] call _SAEF_fnc_swapLoadout; } forEach _SAEF_generatedLoadouts;
} forEach _allLoadouts;

/*
	fn_compatibilityLoadFaction.sqf

	Overrides A3A_fnc_compatibilityLoadFaction, registered under
	CfgFunctions >> A3A >> FunctionsTemplates >> compatibilityLoadFaction.

	A copy of Antistasi's own function with two additions: the Aegis_Reb_FIA branch
	below, and the Titan-to-NLAW swap further down. Everything else is unchanged, so
	this needs re-syncing if Antistasi changes that function upstream.

	Called on the server only, from A3A_fnc_initVarServer.
*/

params ["_file", "_side"];

diag_log format ["[SAEF_AntistasiBridge] Compatibility loading template: '%1' as side %2", _file, _side];

private _factionDefaultFile = ["EnemyDefaults","EnemyDefaults","RebelDefaults","CivilianDefaults"] select ([west, east, independent, civilian] find _side);
_factionDefaultFile = "x\A3A\addons\core\Templates\Templates\FactionDefaults" + "\" + _factionDefaultFile + ".sqf";

private _filepaths = [_factionDefaultFile, _file];

// Every file in this list shares the same _fnc_saveToTemplate closure and runs in
// order, so appending one script is enough to overwrite individual keys of a template
// without duplicating it. Scoped to Aegis_Reb_FIA; other templates load unchanged.
if (_file find "Aegis_Reb_FIA.sqf" != -1) then {
	_filepaths pushBack "saef_tbau_saef_rebels\Templates\functions\fn_SAEF_flagOverride.sqf";
};

private _faction = [_filepaths] call A3A_fnc_loadFaction;

// Swap every Titan missile (AT, AA, AP) for the unguided NLAW, on the specific Aegis
// factions the group actually fights (AAF garrison, NATO invasion). This can't use the
// _filepaths trick above - the weapon pools those templates build are private to their
// own file execution and never reach the shared closure - so it edits the already-
// resolved unit loadouts A3A_fnc_loadFaction just returned instead. See
// fn_SAEF_titanToNLAW.sqf for the mechanics.
private _titanToNLAWFiles = ["Aegis_AI_AAF.sqf", "Aegis_AI_NATO_Arid.sqf", "Aegis_AI_NATO_Temperate.sqf", "Aegis_AI_NATO_Tropical.sqf"];
if ((_titanToNLAWFiles findIf {_file find _x != -1}) != -1) then {
	[_faction] call compile preprocessFileLineNumbers "saef_tbau_saef_rebels\Templates\functions\fn_SAEF_titanToNLAW.sqf";
};
private _factionPrefix = ["occ", "inv", "reb", "civ"] select ([west, east, independent, civilian] find _side);
missionNamespace setVariable ["A3A_faction_" + _factionPrefix, _faction];
[_faction, _factionPrefix] call A3A_fnc_compileGroups;

private _unitClassMap = _side call SCRT_fnc_unit_getUnitMap;
private _baseUnitClass = switch (_side) do {
	case west: { "a3a_unit_west" };
	case east: { "a3a_unit_east" };
	case independent: { "a3a_unit_reb" };
	case civilian: { "a3a_unit_civ" };
};

// validate loadouts
private _loadoutsPrefix = format ["loadouts_%1_", _factionPrefix];
private _allDefinitions = _faction get "loadouts";

#if __A3_DEBUG__
	[_faction, _file] call A3A_fnc_TV_verifyLoadoutsData;
#endif

// Register loadouts globally.
{
	private _loadoutName = _x;
	private _unitClass = _unitClassMap getOrDefault [_loadoutName, _baseUnitClass];
	[_loadoutsPrefix + _loadoutName, _y + [_unitClass]] call A3A_fnc_registerUnitType;
} forEach _allDefinitions;

#if __A3_DEBUG__
	[_faction, _side, _file] call A3A_fnc_TV_verifyAssets;
#endif

if (_side in [Occupants, Invaders]) then {
	// Compile light armed that also have 4+ passenger seats
	private _lightArmedTroop = (_faction get "vehiclesLightArmed") select {
		([_x, true] call BIS_fnc_crewCount) - ([_x, false] call BIS_fnc_crewCount) >= 4
	};
	_faction set ["vehiclesLightArmedTroop", _lightArmedTroop];

	private _vehArmor = (
		(_faction getOrDefault ["vehiclesTanks", [], true]) +
		(_faction getOrDefault ["vehiclesAA", [], true]) +
		(_faction getOrDefault ["vehiclesArtillery", [], true]) +
		(_faction getOrDefault ["vehiclesLightAPCs", [], true]) +
		(_faction getOrDefault ["vehiclesAPCs", [], true]) +
		(_faction getOrDefault ["vehiclesLightTanks", [], true]) +
		(_faction getOrDefault ["vehiclesAirborne", [], true]) +
		(_faction getOrDefault ["vehiclesIFVs", [], true])
	);
	_faction set ["vehiclesArmor", _vehArmor];
};

_faction;

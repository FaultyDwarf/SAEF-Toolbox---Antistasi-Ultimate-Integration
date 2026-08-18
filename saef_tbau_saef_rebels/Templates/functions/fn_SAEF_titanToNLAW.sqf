/*
	fn_SAEF_titanToNLAW.sqf

	Called from fn_compatibilityLoadFaction.sqf, AFTER A3A_fnc_loadFaction has already
	returned - scoped to Aegis_AI_AAF.sqf and the three Aegis_AI_NATO_* climate files.

	Swaps every Titan magazine class (Titan_AT, Titan_AA, Titan_AP) for the unguided
	NLAW. Titan_AA is included deliberately - these units end up with no guided
	anti-air capability at all, not just a nerfed AT loadout.

	Why this can't be done the way the flag override is done (appending a tiny script to
	the file list that Antistasi's own `A3A_fnc_loadFaction` walks): the weapon pools
	those templates build (`missileATLaunchers`/`AALaunchers`, `["launch_..._Titan_F",
	..., ["Titan_AA"], ...]`) live in a `private _loadoutData` that only exists inside
	that template file's own execution. Every file in the list runs in its own sibling
	scope, so an appended file can't see another file's `private` variables - only the
	shared `_fnc_saveToTemplate` closure (which loadouts never go through; they're
	consumed locally and turned straight into concrete unit loadouts before the file
	returns).

	So instead of touching the pool, this walks the *result*: by the time
	`A3A_fnc_loadFaction` returns, `A3A_fnc_loadout_builder` has already run for every
	unit type, picking one concrete weapon+magazine per generated loadout. This edits
	those baked loadout arrays directly, wherever they still carry a Titan magazine of
	any kind.

	Loadout array shape, per fn_loadout_createBase.sqf / fn_loadout_setWeapon.sqf /
	fn_loadout_setVest.sqf (uniform/vest/backpack all follow the same [class, items[]]
	shape as vest):
		[PRIMARY, LAUNCHER, HANDGUN, [uniform, items[]], [vest, items[]], [backpack, items[]], ...]
	Each weapon slot: [class, muzzle, pointer, optic, priMag, secMag, bipod]
		- priMag/secMag are [magClass, count] once resolved.
	Each container item entry: [class, count] or [class, count, ammoCount] (magazines).

	Params:
		_faction - Faction HashMap returned by A3A_fnc_loadFaction (mutated in place;
		           HashMaps and arrays are reference types in SQF, so no re-save into
		           the faction is needed).
*/

params ["_faction"];

private _titanMagazines = ["Titan_AT", "Titan_AA", "Titan_AP"];

private _fnc_swapLoadout = {
	params ["_loadout"];

	// Launcher slot - replace the whole weapon array if its loaded magazine is any Titan.
	private _launcher = _loadout select 1;
	if (!(_launcher isEqualTo [])) then {
		private _priMag = _launcher select 4;
		if (!(_priMag isEqualTo []) && { (_priMag select 0) in _titanMagazines }) then {
			_loadout set [1, ["launch_NLAW_F", "", "", "", ["NLAW_F", 1], [], ""]];
		};
	};

	// Any spare Titan magazines carried in the uniform/vest/backpack.
	{
		private _container = _loadout select _x;
		if (!(_container isEqualTo [])) then {
			{
				if ((_x select 0) in _titanMagazines) then { _x set [0, "NLAW_F"]; };
			} forEach (_container select 1);
		};
	} forEach [3, 4, 5];
};

{
	private _generatedLoadouts = _y select 0;
	{ [_x] call _fnc_swapLoadout; } forEach _generatedLoadouts;
} forEach (_faction get "loadouts");

_faction

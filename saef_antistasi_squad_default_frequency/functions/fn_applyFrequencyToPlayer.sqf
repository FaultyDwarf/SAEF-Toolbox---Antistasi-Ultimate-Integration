/*
 AU_SquadRadio_fnc_applyFrequencyToPlayer.sqf
 Client-side. Runs on clients via remoteExec from server.
 Usage: [playerUnit, "65.12"] remoteExec ["AU_SquadRadio_fnc_applyFrequencyToPlayer", 0];
*/
params ["_unit", "_freqStr"];

// only act for the local player unit
if (!isPlayer _unit) exitWith {false};
if (_unit != player) exitWith {false};

// store assigned freq on player for other scripts/monitoring
player setVariable ["AU_assignedFrequency", _freqStr, true];

// check TFAR presence
if (!isClass (configFile >> "CfgPatches" >> "task_force_radio")) then {
    hint format ["[AU] TFAR not present locally; stored desired frequency: %1", _freqStr];
    exitWith {false};
};

// use TFAR public function (personal SW radio)
private _ok = false;
try {
    _freqStr call TFAR_fnc_setPersonalRadioFrequency;
    _ok = true;
} catch {
    _ok = false;
};

// optional: set LR too if you want
// if (!_ok) then { _freqStr call TFAR_fnc_setLongRangeRadioFrequency; _ok = true; };

if (_ok) then {
    hintSilent format ["[AU] Squad default frequency set to %1 MHz", _freqStr];
} else {
    hint format ["[AU] Failed to set TFAR frequency locally; stored value: %1", _freqStr];
};
_ok
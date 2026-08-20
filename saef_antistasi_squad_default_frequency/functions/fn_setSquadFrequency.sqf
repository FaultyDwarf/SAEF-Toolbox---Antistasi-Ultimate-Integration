/*
    fn_setSquadFrequency.sqf
    Server-side validation & distribution function
*/

params ["_group", "_freqRaw", ["_caller", objNull]];

if (isNil "_group" || {(typeName _group) != "GROUP"}) exitWith { false };

// Convert raw input safely to string without extra escaped quotes
private _freq = format ["%1", _freqRaw];
if (_freq == "") exitWith { false };

// Parse and validate frequency bounds (20 - 9999 MHz)
private _num = parseNumber _freq;
if (_num == 0 && {_freq != "0"}) exitWith { false };
if ((_num < 20) || (_num > 9999)) exitWith { false };

// Permission check: Caller must be valid and must be the group leader
if (isNull _caller || {!(leader _group isEqualTo _caller)}) exitWith {
    diag_log format ["[AU Squad Radio] Unauthorized frequency change attempt by %1 for group %2", _caller, _group];
    false
};

// Store default frequency on the group object and sync across the network
_group setVariable ["AU_defaultFrequency", _freq, true];

// Send targeted remote execution to each client unit in the group
{
    if (isPlayer _x) then {
        [_x, _freq] remoteExec ["AU_SquadRadio_fnc_applyFrequencyToPlayer", _x];
    };
} forEach (units _group);

true
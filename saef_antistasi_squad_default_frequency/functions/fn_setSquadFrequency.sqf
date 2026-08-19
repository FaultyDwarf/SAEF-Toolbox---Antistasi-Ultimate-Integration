/*
 AU_SquadRadio_fnc_setSquadFrequency.sqf
 Server-side setter. Expected to run on the server (remoteExec target 2).
 Usage: [_group, "65.12"] remoteExec ["AU_SquadRadio_fnc_setSquadFrequency", 2];
*/
params ["_group", "_freqRaw"];

if (isNil "_group" || !isGroup _group) exitWith {false};

// sanitize
private _freq = (str _freqRaw) call BIS_fnc_trim;
if (_freq == "") exitWith {false};
private _num = try { parseNumber _freq } catch { nil };
if (isNil "_num") exitWith {false};
// optional range check
if ((_num < 20) || (_num > 9999)) exitWith {false};

// store on group (replicated to clients)
_group setVariable ["AU_defaultFrequency", _freq, true];

// apply to current members: ask all clients to apply locally for their player unit
{
    [_x, _freq] remoteExec ["AU_SquadRadio_fnc_applyFrequencyToPlayer", 0];
} forEach units _group;

// notify squad members (server-side)
{
    _x sideChat format ["[Squad] Default radio frequency set to %1 MHz", _freq];
} forEach units _group;

true
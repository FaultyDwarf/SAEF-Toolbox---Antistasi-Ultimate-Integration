/*
    fn_setSquadFrequency.sqf
*/

params ["_group", "_freqRaw", "_caller"];

if (isNil "_group") exitWith {false};

if ((typeName _group) != "GROUP") exitWith {false};

private _freq = str _freqRaw;

if (_freq == "") exitWith {false};

// Parse number
private _num = parseNumber _freq;
if (_num == 0 && _freq != "0") exitWith {false};

// Optional range check
if ((_num < 20) || (_num > 9999)) exitWith {false};

// Permission check: allow server or group leader
private _allowed = false;
if (isServer) then {
    _allowed = true;
};
if (!isNull _caller) then {
    if ((leader _group) isEqualTo _caller) then {
        _allowed = true;
    };
};
if (!_allowed) exitWith {false};

// Store on group and replicate
_group setVariable ["AU_defaultFrequency", _freq, true];

// Ask clients to apply locally for their player unit
{
    [_x, _freq] remoteExec ["AU_SquadRadio_fnc_applyFrequencyToPlayer", 0];
} forEach units _group;

// Notify squad members (server-side)
{
    _x sideChat format ["[Squad] Default radio frequency set to %1 MHz", _freq];
} forEach units _group;

true
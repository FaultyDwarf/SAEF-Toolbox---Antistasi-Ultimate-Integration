/*
    fn_applyFrequencyToPlayer.sqf
    Client-side helper called via remoteExec from server
*/
params ["_unit", "_freqStr"];

// Only execute on the local player
if (!isPlayer _unit || {_unit != player}) exitWith { false };

// Store assigned frequency on the player object
player setVariable ["AU_assignedFrequency", _freqStr, true];

// If player has a shortwave radio right now, apply it immediately
if (call TFAR_fnc_haveSWRadio) then {
    private _radio = call TFAR_fnc_activeSwRadio;
    if (!isNil "_radio") then {
        [_radio, 1, _freqStr] call TFAR_fnc_SetChannelFrequency;
        [_radio, 2, 50] call TFAR_fnc_SetChannelFrequency;
        hintSilent format ["[AU] Squad radio frequency updated: %1 MHz", _freqStr];
    };
};

true
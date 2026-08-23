/*
    initPlayerLocal.sqf
*/

waitUntil { !isNull player && {time > 0} };

// Sync group default frequency to player variable upon loading in
[] spawn {
    sleep 1;
    private _group = group player;
    if (!isNull _group) then {
        private _groupFreq = _group getVariable ["AU_defaultFrequency", ""];
        if (_groupFreq != "") then {
            player setVariable ["AU_assignedFrequency", _groupFreq, true];
        };
    };
};

// Start Dynamic Groups UI injector monitor
[] spawn AU_SquadRadio_fnc_dynamicGroupUpdate;

// Start radio auto-programmer loop
[] spawn AU_SquadRadio_fnc_radioAutoProgrammer;
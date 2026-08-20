/*
    initPlayerLocal.sqf
    Runs locally on clients when they join the mission.
*/

// Ensure the player object and game environment are fully loaded
waitUntil { !isNull player && {time > 0} };

// 1. Sync group default frequency on join/reconnect
private _groupFreq = (group player) getVariable ["AU_defaultFrequency", ""];
if (_groupFreq != "") then {
    player setVariable ["AU_assignedFrequency", _groupFreq, true];
};

// 2. Start the Dynamic Groups UI injection monitor
[] spawn AU_SquadRadio_fnc_dynamicGroupUpdate;

// 3. Start the radio auto-programmer loop (monitors Arsenal / inventory radio pickup)
[] spawn AU_SquadRadio_fnc_radioAutoProgrammer;
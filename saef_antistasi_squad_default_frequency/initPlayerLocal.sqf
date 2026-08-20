/*
    initPlayerLocal.sqf
    Runs locally on clients when they join the mission.
*/

// Ensure the player object and game environment are fully loaded
waitUntil { !isNull player && {time > 0} };

// 1. Fetch group default frequency if it was already set prior to joining/respawning
private _groupFreq = (group player) getVariable ["AU_defaultFrequency", ""];
if (_groupFreq != "") then {
    player setVariable ["AU_assignedFrequency", _groupFreq, true];
};

// 2. Start the radio auto-programmer loop
[] spawn AU_fnc_radioAutoProgrammer;
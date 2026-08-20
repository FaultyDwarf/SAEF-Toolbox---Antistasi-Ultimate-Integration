/*
    initPlayerLocal.sqf
    Runs locally on clients when they join or respawn in the mission.
*/

// 1. Ensure the player object and game environment are fully loaded
waitUntil { !isNull player && {time > 0} };

// 2. Small delay to allow Antistasi to assign player to their designated squad
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

// 3. Register Dynamic Groups UI observer (Event-driven, no background loop)
[] spawn AU_SquadRadio_fnc_dynamicGroupUpdate;

// 4. Start the radio auto-programmer thread (Inventory & Radio State Monitor)
[] spawn AU_SquadRadio_fnc_radioAutoProgrammer;
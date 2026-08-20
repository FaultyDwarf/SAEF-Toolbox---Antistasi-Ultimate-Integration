/*
    fn_radioAutoProgrammer.sqf
    Monitors player inventory and applies frequencies ONLY ONCE.
    Re-triggers only on:
      - Acquiring a new radio (e.g. from Arsenal)
      - Respawn
      - Group / Squad Change
      - Squad Leadership Transfer
      - Squad Frequency Update
*/

[] spawn {
    waitUntil { !isNull player && {time > 0} };

    // Reset tracking variables on player respawn
    player addEventHandler ["Respawn", {
        params ["_unit", "_corpse"];
        _unit setVariable ["AU_lastProgrammedRadio", ""];
        _unit setVariable ["AU_lastProgrammedFreq", ""];
        _unit setVariable ["AU_lastGroup", grpNull];
        _unit setVariable ["AU_lastIsLeader", false];
    }];

    while {alive player} do {
        // Wait until player actually has a shortwave radio equipped
        waitUntil {
            sleep 1;
            !alive player || {call TFAR_fnc_haveSWRadio}
        };

        if (!alive player) exitWith {};

        private _radio = call TFAR_fnc_activeSwRadio;

        if (!isNil "_radio") then {
            // Get current environmental state
            private _currentRadioID = _radio; // Unique TFAR radio ID string
            private _currentGroup    = group player;
            private _isLeader        = (leader _currentGroup) == player;
            
            private _assignedFreq    = player getVariable ["AU_assignedFrequency", ""];
            if (_assignedFreq == "") then {
                _assignedFreq = _currentGroup getVariable ["AU_defaultFrequency", ""];
            };

            // Fetch stored tracking state from player
            private _lastRadio    = player getVariable ["AU_lastProgrammedRadio", ""];
            private _lastFreq     = player getVariable ["AU_lastProgrammedFreq", ""];
            private _lastGroup    = player getVariable ["AU_lastGroup", grpNull];
            private _lastIsLeader = player getVariable ["AU_lastIsLeader", false];

            // Evaluate if any re-trigger conditions are met
            private _needsUpdate = false;

            if (_assignedFreq != "" && {_assignedFreq != _lastFreq}) then { _needsUpdate = true; };
            if (_currentRadioID != _lastRadio)                      then { _needsUpdate = true; };
            if (_currentGroup != _lastGroup)                        then { _needsUpdate = true; };
            if (_isLeader != _lastIsLeader)                          then { _needsUpdate = true; };

            // Execute programming ONLY if state changed
            if (_needsUpdate) then {
                // 1. Set Channel 1 (Squad Main Frequency)
                if (_assignedFreq != "") then {
                    [_radio, 1, _assignedFreq] call TFAR_fnc_SetChannelFrequency;
                };

                // 2. If Squad Leader, set Channel 2 to Command Net (50 MHz) as Additional
                if (_isLeader) then {
                    [_radio, 8, "50"] call TFAR_fnc_SetChannelFrequency; // Target Channel 8 (1-indexed)
                    [_radio, 7] call TFAR_fnc_setAdditionalSwChannel;    // Index 1 = Channel 7 (0-indexed)
                } else {
                    // If player lost leadership, clear additional channel setting
                    [_radio, -1] call TFAR_fnc_setAdditionalSwChannel; 
                };

                // Save updated state to prevent looping
                player setVariable ["AU_lastProgrammedRadio", _currentRadioID];
                player setVariable ["AU_lastProgrammedFreq", _assignedFreq];
                player setVariable ["AU_lastGroup", _currentGroup];
                player setVariable ["AU_lastIsLeader", _isLeader];

                if (_assignedFreq != "") then {
                    private _msg = format ["[Squad Radio] Auto-configured! Main: %1 MHz%2", _assignedFreq, if (_isLeader) then {" | Ch 8: 50 MHz (Command)"} else {""}];
                    systemChat _msg;
                };
            };
        };

        sleep 2;
    };
};
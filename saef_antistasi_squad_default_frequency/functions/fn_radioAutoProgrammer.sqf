/*
    fn_radioAutoProgrammer.sqf
    Monitors player inventory for TFAR Shortwave radios and applies 
    the squad default frequency as soon as a radio is obtained (e.g. from Arsenal).
*/
[] spawn {
    // Wait until player is fully loaded in
    waitUntil { !isNull player && {time > 0} };

    private _lastProgrammedFreq = "";

    while {alive player} do {
        // Wait until the player actually has a shortwave radio
        waitUntil {
            sleep 1;
            !alive player || {call TFAR_fnc_haveSWRadio}
        };

        if (!alive player) exitWith {};

        // Fetch current group/player frequency assignment
        private _assignedFreq = player getVariable ["AU_assignedFrequency", ""];
        
        // If no player variable is set, fallback to group variable
        if (_assignedFreq == "") then {
            _assignedFreq = (group player) getVariable ["AU_defaultFrequency", ""];
        };

        // If a valid frequency exists and hasn't been applied to this radio yet
        if (_assignedFreq != "" && {_assignedFreq != _lastProgrammedFreq}) then {
            private _radio = call TFAR_fnc_activeSwRadio;
            
            if (!isNil "_radio") then {
                // Set Channel 1 to the squad frequency
                [_radio, 1, _assignedFreq] call TFAR_fnc_SetChannelFrequency;
                
                _lastProgrammedFreq = _assignedFreq;
                hintSilent format ["[AU] Radio acquired! Auto-set to Squad Freq: %1 MHz", _assignedFreq];
            };
        };

        sleep 2;
    };
};
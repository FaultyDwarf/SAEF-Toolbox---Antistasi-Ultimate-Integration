/*
    fn_radioAutoProgrammer.sqf
    Event-driven radio programmer. Only runs when inventory closes or respawn occurs.
*/

// Function that handles the actual radio programming logic
AU_fnc_checkAndProgramRadio = {
    // Exit if player doesn't have a shortwave radio yet
    if (!alive player || {!(call TFAR_fnc_haveSWRadio)}) exitWith {};

    private _radio = call TFAR_fnc_activeSwRadio;
    if (isNil "_radio") exitWith {};

    private _currentRadioID = _radio;
    private _currentGroup    = group player;
    private _isLeader        = (leader _currentGroup) == player;

    // Get assigned frequency
    private _targetFreq = player getVariable ["AU_assignedFrequency", ""];
    if (_targetFreq == "") then {
        _targetFreq = _currentGroup getVariable ["AU_defaultFrequency", ""];
        if (_targetFreq != "") then {
            player setVariable ["AU_assignedFrequency", _targetFreq, true];
        };
    };

    private _lastRadio    = player getVariable ["AU_lastProgrammedRadio", ""];
    private _lastFreq     = player getVariable ["AU_lastProgrammedFreq", ""];
    private _lastGroup    = player getVariable ["AU_lastGroup", grpNull];
    private _lastIsLeader = player getVariable ["AU_lastIsLeader", false];

    private _needsUpdate = false;
    if (_targetFreq != "" && {_targetFreq != _lastFreq}) then { _needsUpdate = true; };
    if (_currentRadioID != _lastRadio)                      then { _needsUpdate = true; };
    if (_currentGroup != _lastGroup)                        then { _needsUpdate = true; };
    if (_isLeader != _lastIsLeader)                          then { _needsUpdate = true; };

    if (_needsUpdate) then {
        // Small delay so TFAR can register local radio settings
        sleep 0.5;

        // Program Channel 1 (Squad Main Frequency)
        if (_targetFreq != "") then {
            [_radio, 1, _targetFreq] call TFAR_fnc_SetChannelFrequency;
        };

        // Program Channel 8 if Leader (Command Net 50 MHz)
        if (_isLeader) then {
            [_radio, 8, "50"] call TFAR_fnc_SetChannelFrequency;
            [_radio, 7] call TFAR_fnc_setAdditionalSwChannel; 
        } else {
            [_radio, -1] call TFAR_fnc_setAdditionalSwChannel; 
        };

        // Store state to prevent duplicate triggers on the same radio
        player setVariable ["AU_lastProgrammedRadio", _currentRadioID];
        player setVariable ["AU_lastProgrammedFreq", _targetFreq];
        player setVariable ["AU_lastGroup", _currentGroup];
        player setVariable ["AU_lastIsLeader", _isLeader];

        if (_targetFreq != "") then {
            private _msg = format ["[Squad Radio] Auto-configured! Main: %1 MHz%2", _targetFreq, if (_isLeader) then {" | Ch 8: 50 MHz (Command)"} else {""}];
            systemChat _msg;
        };
    };
};


NOT WORKING - radio not being set
// --- EVENT HANDLERS ---

// 1. Trigger when closing Inventory or Arsenal (When they pick up a radio)
player addEventHandler ["InventoryClosed", {
    [] spawn AU_fnc_checkAndProgramRadio;
}];

// Catch BI Virtual Arsenal exit
[missionNamespace, "arsenalClosed", {
    [] spawn AU_fnc_checkAndProgramRadio;
}] call BIS_fnc_addScriptedEventHandler;

// 2. Clear state and prepare for re-trigger upon Respawn
player addEventHandler ["Respawn", {
    params ["_newUnit", "_corpse"];
    
    // Clear last programmed radio state so the next radio check executes fresh
    _newUnit setVariable ["AU_lastProgrammedRadio", ""];
    _newUnit setVariable ["AU_lastProgrammedFreq", ""];
    
    // Attempt initial check in case player respawns with a loadout/radio preset
    [] spawn AU_fnc_checkAndProgramRadio;
}];
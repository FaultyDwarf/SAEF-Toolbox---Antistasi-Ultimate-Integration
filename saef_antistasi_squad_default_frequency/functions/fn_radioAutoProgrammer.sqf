/*
    fn_radioAutoProgrammer.sqf
    Event-driven radio programmer.
    Triggers on: Inventory/Arsenal close, Respawn, Group joins, and Leadership changes.
*/

// Primary execution function
AU_fnc_checkAndProgramRadio = {
    if (!alive player || {!(call TFAR_fnc_haveSWRadio)}) exitWith {};

    private _radio = call TFAR_fnc_activeSwRadio;
    if (isNil "_radio") exitWith {};

    private _currentRadioID = _radio;
    private _currentGroup   = group player;
    private _isLeader       = (leader _currentGroup) == player;

    // Resolve target frequency: check player override -> fall back to squad default
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
        // Small delay to let TFAR finalize radio object creation internally
        sleep 0.5;

        // 1. Program Channel 1 (Squad Main Frequency)
        if (_targetFreq != "") then {
            [_radio, 1, _targetFreq] call TFAR_fnc_SetChannelFrequency;
        };

        // 2. Program Channel 8 (50 MHz Command Net) & Audio Routing
        [_radio, 8, "50"] call TFAR_fnc_SetChannelFrequency;
        if (_isLeader) then {
            [_radio, 7] call TFAR_fnc_setAdditionalSwChannel; // 7 = Index for Channel 8
            [_radio, 2] call TFAR_fnc_setSwStereo;
            [_radio, 1] call TFAR_fnc_setAdditionalSwStereo;
        };

        // Cache latest programmed state
        player setVariable ["AU_lastProgrammedRadio", _currentRadioID];
        player setVariable ["AU_lastProgrammedFreq", _targetFreq];
        player setVariable ["AU_lastGroup", _currentGroup];
        player setVariable ["AU_lastIsLeader", _isLeader];

        if (_targetFreq != "") then {
            private _msg = format [
                "[Squad Radio] Auto-configured! Main: %1 MHz%2", 
                _targetFreq, 
                if (_isLeader) then {" (Right) | Ch 8: 50 MHz Command (Left)"} else {""}
            ];
            systemChat _msg;
        };
    };
};

// Helper function to bind native Arma 3 Group Event Handlers
AU_fnc_bindGroupRadioEHs = {
    params ["_grp"];
    if (isNull _grp) exitWith {};

    // Prevent attaching duplicate event handlers to the same group
    if (_grp getVariable ["AU_radioEHsBound", false]) exitWith {};
    _grp setVariable ["AU_radioEHsBound", true];

    // Trigger on Leadership changes (e.g. SL dies, promoted, or transferred)
    _grp addEventHandler ["LeaderChanged", {
        params ["_group", "_newLeader"];
        if (player in (units _group)) then {
            [] spawn AU_fnc_checkAndProgramRadio;
        };
    }];

    // Trigger when a unit joins the group
    _grp addEventHandler ["UnitJoined", {
        params ["_group", "_newUnit"];
        if (_newUnit == player) then {
            private _newGroupFreq = _group getVariable ["AU_defaultFrequency", ""];
            player setVariable ["AU_assignedFrequency", _newGroupFreq, true];
            [] spawn AU_fnc_checkAndProgramRadio;
        };
    }];
};

// --- EVENT LISTENERS ---

// 1. Standard Inventory Close
player addEventHandler ["InventoryClosed", {
    [] spawn AU_fnc_checkAndProgramRadio;
}];

// 2. BI Virtual Arsenal Close
[missionNamespace, "arsenalClosed", {
    [] spawn AU_fnc_checkAndProgramRadio;
}] call BIS_fnc_addScriptedEventHandler;

// 3. ACE Arsenal Close (if ACE3 is used)
if (!isNil "ace_arsenal_fnc_addScriptedEventHandler") then {
    ["ace_arsenal_displayClosed", {
        [] spawn AU_fnc_checkAndProgramRadio;
    }] call ace_arsenal_fnc_addScriptedEventHandler;
};

// 4. Player Respawn Event
player addEventHandler ["Respawn", {
    params ["_newUnit", "_corpse"];
    
    // Clear state so the next radio equipped gets freshly programmed
    _newUnit setVariable ["AU_lastProgrammedRadio", ""];
    _newUnit setVariable ["AU_lastProgrammedFreq", ""];
    
    // Bind group EHs to the new group instance
    [group _newUnit] call AU_fnc_bindGroupRadioEHs;
    
    // Initial check in case loadout contains a radio
    [] spawn AU_fnc_checkAndProgramRadio;
}];

// 5. Initial Startup Group EH Binding
[] spawn {
    waitUntil { !isNull player && {time > 0} };
    [group player] call AU_fnc_bindGroupRadioEHs;
};
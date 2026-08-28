/*
    fn_dynamicGroupUpdate.sqf
    Monitors for Dynamic Groups GUI (60490) opening and injects the frequency control.
*/

// Notification helper
if (isNil "AU_fnc_notify") then {
    AU_fnc_notify = {
        params ["_title", "_msg"];
        if (!isNil "A3A_fnc_customHint") then {
            [_title, _msg] call A3A_fnc_customHint;
        } else {
            systemChat format ["[%1] %2", _title, _msg];
        };
    };
};

// Frequency submit handler
if (isNil "AU_fnc_submitFrequency") then {
    AU_fnc_submitFrequency = {
        params ["_control"];
        if (isNull _control) exitWith {};

        if ((leader (group player)) != player) exitWith {};

        private _freq = ctrlText _control;
        private _num = parseNumber _freq;
        private _cur = (group player) getVariable ["AU_defaultFrequency", ""];

        if (_freq == _cur || _freq == "") exitWith {};

        if (_num == 0 && _freq != "0") exitWith {
            ["Squad Radio", "Invalid frequency format."] call AU_fnc_notify;
            _control ctrlSetText _cur;
        };

        if ((_num < 20) || (_num > 9999)) exitWith {
            ["Squad Radio", "Frequency must be between 20 and 9999 MHz."] call AU_fnc_notify;
            _control ctrlSetText _cur;
        };

        // Broadcast default squad frequency to group & update local player state
        (group player) setVariable ["AU_defaultFrequency", _freq, true];
        player setVariable ["AU_assignedFrequency", _freq, true];

        // Instantly check and program radio upon submitting edit
        if (!isNil "AU_fnc_checkAndProgramRadio") then {
            [] spawn AU_fnc_checkAndProgramRadio;
        };

        ["Squad Radio", format ["Squad frequency set to %1 MHz", _freq]] call AU_fnc_notify;
    };
};

// UI Injection Worker
AU_fnc_injectFrequencyControl = {
    params ["_d"];
    if (isNull _d) exitWith {};

    // Don't inject twice on the same display
    if (!isNull (_d displayCtrl 60100)) exitWith {};

    private _container   = _d displayCtrl 10677; // SectionManage container
    private _privateChk  = _d displayCtrl 11177; // CheckboxPrivate
    private _scoreLabel  = _d displayCtrl 9386;  // TextPlayerScore ("Score")
    private _scoreFill   = _d displayCtrl 9389;  // TextPlayerScoreFill (Value)
    private _privateLbl  = _d displayCtrl 9390;  // TextPrivate ("Private" label)
    private _listBox     = _d displayCtrl 9878;  // ListboxManage

    if (!isNull _container && !isNull _privateChk && !isNull _privateLbl && !isNull _listBox && !isNull _scoreLabel && !isNull _scoreFill) then {
        private _listPos   = ctrlPosition _listBox;
        private _labelPos  = ctrlPosition _scoreLabel;
        private _fillPos   = ctrlPosition _scoreFill;
        private _privPos   = ctrlPosition _privateLbl;

        // 1. Calculate Y position
        private _x       = _privPos select 0;
        private _labelW  = _privPos select 2;
        private _inputW  = _fillPos select 2;
        private _h       = _privPos select 3;

        private _pitch   = (_privPos select 1) - (_labelPos select 1);
        private _y       = (_privPos select 1) + _pitch;

        private _bgColor = ctrlBackgroundColor _scoreLabel;
        if (count _bgColor == 0 || {(_bgColor select 3) == 0}) then {
            _bgColor = [0.392, 0.388, 0.38, 0.7];
        };

        // 2. Push the listbox down
        private _newListY   = (_listPos select 1) + _pitch;
        private _newListH   = (_listPos select 3) - _pitch;

        _listBox ctrlSetPosition [_listPos select 0, _newListY, _listPos select 2, _newListH];
        _listBox ctrlCommit 0;

        // 3. Create Label ("Freq")
        private _label = _d ctrlCreate ["SquadFreqLabel", -1, _container];
        _label ctrlSetPosition [_x, _y, _labelW, _h];
        _label ctrlSetBackgroundColor _bgColor;
        _label ctrlCommit 0;

        // 4. Create Input Edit Box
        private _editH = _h;
        private _editY = _y + ((_h - _editH) / 2) + (_h * 0.04);
        private _edit  = _d ctrlCreate ["RscEdit", 60100, _container];
        _edit ctrlSetPosition [_x + _labelW, _editY, _inputW, _editH];
        _edit ctrlSetFont "PuristaMedium";
        _edit ctrlSetFontHeight (_editH * 0.8);
        _edit ctrlSetTextColor [1, 1, 1, 1];
        _edit ctrlSetBackgroundColor [0, 0, 0, 0.6];

        // Populate with current squad frequency
        private _curFreq = (group player) getVariable ["AU_defaultFrequency", ""];
        _edit ctrlSetText _curFreq;

        private _isLeader = (leader (group player)) == player;
        _edit ctrlEnable _isLeader;

        if (!_isLeader) then {
            _edit ctrlSetTooltip "Only the squad leader can edit the frequency.";
        };

        _edit ctrlCommit 0;

        // Save handlers
        _edit ctrlAddEventHandler ["KillFocus", {
            params ["_control"];
            [_control] call AU_fnc_submitFrequency;
        }];

        // UNLOAD HANDLER: Triggers when the Dynamic Groups menu closes (Joining squad or exiting menu)
        _d displayAddEventHandler ["Unload", {
            params ["_display"];
            
            // Save frequency if editing
            private _ed = _display displayCtrl 60100;
            if (!isNull _ed) then {
                [_ed] call AU_fnc_submitFrequency;
            };

            // Update player assigned frequency from current group
            private _newGroupFreq = (group player) getVariable ["AU_defaultFrequency", ""];
            player setVariable ["AU_assignedFrequency", _newGroupFreq, true];
            
            // Trigger radio configuration check for the new squad
            if (!isNil "AU_fnc_checkAndProgramRadio") then {
                [] spawn AU_fnc_checkAndProgramRadio;
            };
        }];
    };
};

// Robust display monitor loop
[] spawn {
    while {true} do {
        waitUntil {
            sleep 0.5;
            !isNull (findDisplay 60490)
        };

        private _display = findDisplay 60490;

        waitUntil {
            sleep 0.05;
            isNull (findDisplay 60490) || {!isNull ((findDisplay 60490) displayCtrl 10677)}
        };

        if (!isNull _display && {isNull (_display displayCtrl 60100)}) then {
            [_display] call AU_fnc_injectFrequencyControl;
        };

        waitUntil {
            sleep 0.5;
            isNull (findDisplay 60490)
        };
    };
};
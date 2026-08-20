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

        (group player) setVariable ["AU_defaultFrequency", _freq, true];
        [group player, _freq, player] remoteExec ["AU_SquadRadio_fnc_setSquadFrequency", 2];

        ["Squad Radio", format ["Squad frequency set to %1 MHz", _freq]] call AU_fnc_notify;
    };
};

// UI Injection Worker
AU_fnc_injectFrequencyControl = {
    params ["_d"];
    if (isNull _d) exitWith {};

    // Don't inject twice on the same display
    if (!isNull (_d displayCtrl 60100)) exitWith {};

    private _container  = _d displayCtrl 10677; // SectionManage container
    private _privateChk = _d displayCtrl 11177; // CheckboxPrivate
    private _scoreLabel = _d displayCtrl 9386;  // TextPlayerScore ("Score")
    private _scoreFill  = _d displayCtrl 9389;  // TextPlayerScoreFill (Value)
    private _listBox    = _d displayCtrl 9878;  // ListboxManage

    if (!isNull _container && !isNull _privateChk && !isNull _listBox && !isNull _scoreLabel && !isNull _scoreFill) then {
        private _chkPos    = ctrlPosition _privateChk;
        private _listPos   = ctrlPosition _listBox;
        private _labelPos  = ctrlPosition _scoreLabel;
        private _fillPos   = ctrlPosition _scoreFill;

    // 1. Calculate positions using Private checkbox height and exact native gap
        private _x       = _labelPos select 0;
        private _labelW  = _labelPos select 2;
        private _inputW  = _fillPos select 2;
        private _h       = _labelPos select 3;
        
        // Exact gap calculation: Private Y + Private Height + gap spacing
        private _chkH    = _chkPos select 3;
        private _rowGap  = 0.003; 
        private _y       = (_chkPos select 1) + _chkH + _rowGap;

        // 2. Adjust Listbox position cleanly
        private _spacing    = 0.008;
        private _newListY   = _y + _h + _spacing;
        private _listHDelta = _newListY - (_listPos select 1);
        private _newListH   = (_listPos select 3) - _listHDelta;

        _listBox ctrlSetPosition [_listPos select 0, _newListY, _listPos select 2, _newListH];
        _listBox ctrlCommit 0;

        // 3. Create Label ("Freq") — Matches native UI grey background & font weight perfectly
        private _label = _d ctrlCreate ["RscStructuredText", -1, _container];
        _label ctrlSetPosition [_x, _y, _labelW, _h];
        _label ctrlSetBackgroundColor [1, 1, 1, 0.25]; // Exact native UI row tint
        _label ctrlSetStructuredText parseText "<t align='right' valign='middle' color='#000000' font='RobotoCondensed' shadow='0' size='0.8'>Freq&#160;</t>";
        _label ctrlSetTooltip "Squad radio frequency (20-9999 MHz)";
        _label ctrlCommit 0;

        // 4. Create Input Edit Box
        private _edit = _d ctrlCreate ["RscEdit", 60100, _container];
        _edit ctrlSetPosition [_x + _labelW, _y, _inputW, _h];
        _edit ctrlSetFont "PuristaMedium";
        _edit ctrlSetFontHeight (_h * 0.72);
        _edit ctrlSetTextColor [1, 1, 1, 1];
        _edit ctrlSetBackgroundColor [0, 0, 0, 0.6];

        private _cur = (group player) getVariable ["AU_defaultFrequency", ""];
        _edit ctrlSetText _cur;

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

        _d displayAddEventHandler ["Unload", {
            params ["_display"];
            private _ed = _display displayCtrl 60100;
            if (!isNull _ed) then {
                [_ed] call AU_fnc_submitFrequency;
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
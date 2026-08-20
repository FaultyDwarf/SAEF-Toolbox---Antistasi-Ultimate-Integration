/*
    Monitor for Dynamic Groups dialog (60490) and inject Radio Frequency input
    Handles saving automatically on text unfocus/dialog close
    Restricts editing strictly to the Squad Leader
*/
[] spawn {
    waitUntil { !isNull player && {time > 0} };
    private _injected = false;

    // Helper function to handle frequency validation & broadcast
    AU_fnc_submitFrequency = {
        params ["_control"];
        if (isNull _control) exitWith {};

        // Safety check: secondary guard against non-leaders
        if ((leader (group player)) != player) exitWith {};

        private _freq = ctrlText _control;
        private _num = parseNumber _freq;

        // Skip processing if unchanged or blank
        private _cur = (group player) getVariable ["AU_defaultFrequency", ""];
        if (_freq == _cur || _freq == "") exitWith {};

        if (_num == 0 && _freq != "0") exitWith {
            hint "Invalid frequency format.";
            _control ctrlSetText _cur;
        };

        if ((_num < 20) || (_num > 9999)) exitWith {
            hint "Frequency must be between 20 and 9999 MHz.";
            _control ctrlSetText _cur;
        };

        // Apply and broadcast frequency
        (group player) setVariable ["AU_defaultFrequency", _freq, true];
        [group player, _freq, player] remoteExec ["AU_SquadRadio_fnc_setSquadFrequency", 2];

        hint format ["Squad frequency set to %1 MHz", _freq];
    };

    while {true} do {
        private _d = findDisplay 60490;

        if (!isNull _d) then {
            if (!_injected) then {
                _injected = true;

                private _container  = _d displayCtrl 10677; // SectionManage container
                private _privateChk = _d displayCtrl 11177; // CheckboxPrivate
                private _scoreLabel = _d displayCtrl 9386;  // TextPlayerScore
                private _scoreFill  = _d displayCtrl 9389;  // TextPlayerScoreFill
                private _listBox    = _d displayCtrl 9878;  // ListboxManage

                if (!isNull _container && !isNull _privateChk && !isNull _listBox) then {
                    private _chkPos   = ctrlPosition _privateChk;
                    private _listPos  = ctrlPosition _listBox;

                    // 1. Coordinates & Heights
                    private _x = _listPos select 0;
                    private _w = _listPos select 2;
                    private _y = (_chkPos select 1) + (_chkPos select 3) + 0.006;
                    private _h = _chkPos select 3;

                    // Compute widths
                    private _labelW = _w * 0.45;
                    private _inputW = _w - _labelW;

                    if (!isNull _scoreLabel && !isNull _scoreFill) then {
                        _labelW = (ctrlPosition _scoreLabel) select 2;
                        _inputW = _w - _labelW;
                    };

                    // 2. Adjust Listbox height/position
                    private _newListY = _y + _h + 0.008;
                    private _listHDelta = _newListY - (_listPos select 1);
                    private _newListH = (_listPos select 3) - _listHDelta;

                    _listBox ctrlSetPosition [_listPos select 0, _newListY, _listPos select 2, _newListH];
                    _listBox ctrlCommit 0;

                    private _font = "RobotoCondensed";
                    private _textSize = 0.027;

                    // 3. Label
                    private _label = _d ctrlCreate ["RscStructuredText", -1, _container];
                    _label ctrlSetPosition [_x, _y, _labelW, _h];
                    _label ctrlSetBackgroundColor [0.392, 0.388, 0.38, 1];
                    _label ctrlSetStructuredText parseText "<t align='right' color='#000000' font='RobotoCondensedLight' shadow='0' size='0.9'>Freq </t>";
                    _label ctrlSetTooltip "Squad radio frequency (20-9999)";
                    _label ctrlCommit 0;

                    // 4. Input Box
                    private _edit = _d ctrlCreate ["RscEdit", -1, _container];
                    _edit ctrlSetPosition [_x + _labelW + 0.004, _y, _inputW - 0.004, _h];
                    _edit ctrlSetFont _font;
                    _edit ctrlSetFontHeight _textSize;
                    _edit ctrlSetTextColor [1, 1, 1, 1];
                    _edit ctrlSetBackgroundColor [0, 0, 0, 0.6];

                    private _cur = (group player) getVariable ["AU_defaultFrequency", ""];
                    _edit ctrlSetText _cur;

                    // Check Squad Leader permissions
                    private _isLeader = (leader (group player)) == player;
                    
                    // Enable/Disable control based on leadership
                    _edit ctrlEnable _isLeader;

                    if (!_isLeader) then {
                        _edit ctrlSetTooltip "Only the squad leader can edit the frequency.";
                    };

                    _edit ctrlCommit 0;

                    uiNamespace setVariable ["AU_FreqEdit", _edit];

                    // Trigger submit on losing focus
                    _edit ctrlAddEventHandler ["KillFocus", {
                        params ["_control"];
                        [_control] call AU_fnc_submitFrequency;
                    }];

                    // Trigger submit when screen closes
                    _d displayAddEventHandler ["Unload", {
                        private _ed = uiNamespace getVariable ["AU_FreqEdit", controlNull];
                        if (!isNull _ed) then {
                            [_ed] call AU_fnc_submitFrequency;
                        };
                    }];
                };
            };
        } else {
            if (_injected) then {
                _injected = false;
                uiNamespace setVariable ["AU_FreqEdit", nil];
            };
        };

        sleep 0.5;
    };
};
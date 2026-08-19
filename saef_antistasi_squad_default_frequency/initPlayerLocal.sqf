/*
 Client monitor that injects controls into AU's squadOptions display using ctrlCreate.
 Run this in each client's initPlayerLocal (execVM it from mission or mod startup).
*/
[] spawn {
    sleep 4; // allow mission & AU to initialise
    private _injected = false;

    while {true} do {
        private _d = findDisplay 100; // AU uses idd 100 for many dialogs including squadOptions
        if (!isNull _d) then {
            // Heuristic: squadOptions has a button/control with idc 104 (used in AU)
            private _ctrl = _d displayCtrl 104;
            if (!isNull _ctrl) then {
                if (!_injected) then {
                    _injected = true;

                    // compute positions (tune as needed)
                    private _x = 0.26 * safezoneW + safezoneX;
                    private _y = 0.42 * safezoneH + safezoneY;
                    private _w = 0.35 * safezoneW;
                    private _h = 0.03 * safezoneH;

                    // create an edit box
                    private _edit = _d ctrlCreate ["RscEdit", -1];
                    _edit ctrlSetPosition [_x, _y, _w, _h];
                    _edit ctrlCommit 0; // finalize
                    // store for handler access
                    uiNamespace setVariable ["AU_SQ_EditCtrl", _edit];

                    // prefills: group variable if present
                    private _cur = (group player) getVariable ["AU_defaultFrequency", ""];
                    if (_cur != "") then { _edit ctrlSetText _cur; };

                    // create the Set button
                    private _btn = _d ctrlCreate ["RscButton", -1];
                    private _bx = _x + _w + (0.01 * safezoneW);
                    private _bw = 0.115 * safezoneW;
                    _btn ctrlSetPosition [_bx, _y, _bw, _h];
                    _btn ctrlSetText "Set squad frequency";
                    _btn ctrlCommit 0;
                    uiNamespace setVariable ["AU_SQ_ButtonCtrl", _btn];

                    // add mouse-up handler to button; it remoteExecs the server setter
                    _btn ctrlAddEventHandler ["MouseButtonUp", {
                        params ["_ctrl", "_mouseButton", "_posX", "_posY"];
                        private _ed = uiNamespace getVariable "AU_SQ_EditCtrl";
                        private _freq = "";
                        if (!isNull _ed) then { _freq = ctrlText _ed; };
                        private _grp = group player;
                        // close AU dialogs and our overlay
                        closeDialog 0;
                        // call server function (runs on server)
                        [_grp, _freq] remoteExec ["AU_SquadRadio_fnc_setSquadFrequency", 2];
                    }];

                    // Add a small Close button as well
                    private _btnClose = _d ctrlCreate ["RscButton", -1];
                    _btnClose ctrlSetPosition [_bx, _y + _h + (0.005 * safezoneH), _bw, _h];
                    _btnClose ctrlSetText "Close";
                    _btnClose ctrlCommit 0;
                    uiNamespace setVariable ["AU_SQ_CloseBtnCtrl", _btnClose];
                    _btnClose ctrlAddEventHandler ["MouseButtonUp", {
                        // just close the AU dialog (leave group menu behavior intact)
                        closeDialog 0;
                    }];

                    // Note: controls are children of the AU display; when the display closes they will be removed automatically.
                };
            } else {
                // AU display open but not squadOptions; if we had injected earlier, consider that the dialog closed
                if (_injected) then { _injected = false; uiNamespace setVariable ["AU_SQ_EditCtrl", nil]; uiNamespace setVariable ["AU_SQ_ButtonCtrl", nil]; uiNamespace setVariable ["AU_SQ_CloseBtnCtrl", nil]; };
            };
        } else {
            // no AU display open: reset injection state
            if (_injected) then { _injected = false; uiNamespace setVariable ["AU_SQ_EditCtrl", nil]; uiNamespace setVariable ["AU_SQ_ButtonCtrl", nil]; uiNamespace setVariable ["AU_SQ_CloseBtnCtrl", nil]; };
        };

        sleep 0.5;
    };
};
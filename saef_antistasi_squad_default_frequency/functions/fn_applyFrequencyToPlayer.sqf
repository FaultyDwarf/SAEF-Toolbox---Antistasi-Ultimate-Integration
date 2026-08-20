/*
    fn_applyFrequencyToPlayer.sqf
    Client-side helper called via remoteExec from server
*/
params ["_unit", "_freqStr"];

// Only execute on the local player
if (!isPlayer _unit || {_unit != player}) exitWith { false };

// Store assigned frequency on the player object
player setVariable ["AU_assignedFrequency", _freqStr, true];

// If player has a shortwave radio right now, apply it immediately
if (call TFAR_fnc_haveSWRadio) then {
    private _radio = call TFAR_fnc_activeSwRadio;
    if (!isNil "_radio") then {
        // 1. Program Channel 1 (Squad Main Frequency)
        [_radio, 1, _freqStr] call TFAR_fnc_SetChannelFrequency;
        
        // 2. If Squad Leader, set Channel 8 to Command Net (50 MHz) as Additional Channel
        private _isLeader = (leader (group player)) == player;
        if (_isLeader) then {
            [_radio, 8, "50"] call TFAR_fnc_SetChannelFrequency;  // Target Channel 2 (1-indexed)
            [_radio, 7] call TFAR_fnc_setAdditionalSwChannel;     // Index 1 = Channel 2 (0-indexed)
        } else {
            // Clear additional channel if non-leader
            [_radio, -1] call TFAR_fnc_setAdditionalSwChannel;
        };

        // Antistasi-safe notification via systemChat
        private _msg = format ["[Squad Radio] Frequency updated: %1 MHz%2", _freqStr, if (_isLeader) then {" | Ch 8: 50 MHz (Command)"} else {""}];
        systemChat _msg;
    };
};

true
/*
    Registers the SAEF admin actions on every client, since the Antistasi mission has no
    initPlayerLocal.sqf to register them from.

    Three actions end up under ACE self-interact >
    Tools > Admin Utilities > Mission Utilities:

        Log StatTrack       runs on the server, logs a stat line to server.rpt
        Become Invincible   player allowDamage false
        Become Vulnerable   player allowDamage true

    Chain when an admin clicks Log StatTrack:
        client  action callback, _server = true
        client  RS_fnc_Admin_RunScriptOnServer: [_params, _script] remoteExec ["execVM", 2]
        server  execVM "\saef_toolbox_au_integration\LogStatTrack.sqf"
        server  [] call RS_ST_fnc_LogInfo

    Visibility is the toolbox's own gating, untouched: the SAEF_AdminUtils parent requires
    AdminUtil_Enabled and player RS_IsAdmin, which RS_fnc_Admin_CheckAdmin only sets for a
    logged-in admin or an explicit RS_AdminOverride. Regular players never see the entries.

    StatTrack's own logging needs nothing from here - RS_ST_fnc_InitStatTrack is
    postInit = 1 and server-guarded, so it self-starts. Only the on-demand action is added.
*/

if (!isServer) exitWith {};

[] spawn {
    // diag_tickTime rather than time: advances even while the mission is paused.
    private _deadline = diag_tickTime + 300;

    // ST_AllowLogging as well as the function name: CfgFunctions compiles
    // RS_ST_fnc_LogInfo whether or not StatTrack initialised, so the variable is what
    // actually proves fn_InitStatTrack ran.
    waitUntil {
        sleep 1;
        (!isNil "RS_ST_fnc_LogInfo" && {!isNil "ST_AllowLogging"}) || {diag_tickTime > _deadline}
    };

    if (isNil "RS_ST_fnc_LogInfo" || {isNil "ST_AllowLogging"}) exitWith {
        diag_log "[SAEF_TBAU] StatTrack did not initialise within 300s (RS_ST_fnc_LogInfo / ST_AllowLogging missing). Is mods\@SAEFToolbox still on the server -mod= line? Admin action not registered.";
    };

    // Target 0 rather than -2, so a locally hosted session's host player - who is also
    // the server - still gets the actions. hasInterface below filters out the machines
    // that should not build them: a dedicated server and the headless clients.
    private _clientInit = {
        if (!hasInterface) exitWith {};

        // Local only — never broadcast this, or the first client to register would
        // stop every other client from registering.
        if (missionNamespace getVariable ["SAEF_TBAU_ActionRegistered", false]) exitWith {};
        missionNamespace setVariable ["SAEF_TBAU_ActionRegistered", true];

        private _deadline = diag_tickTime + 300;

        waitUntil {
            sleep 1;
            (!isNull player
                && {!isNil "RS_fnc_Admin_AddMissionAction"}
                && {!isNil "ace_interact_menu_fnc_addActionToObject"})
            || {diag_tickTime > _deadline}
        };

        if (isNull player || {isNil "RS_fnc_Admin_AddMissionAction"}) exitWith {
            missionNamespace setVariable ["SAEF_TBAU_ActionRegistered", false];
            diag_log "[SAEF_TBAU] RS_fnc_Admin_AddMissionAction / ACE interact menu unavailable after 300s, skipping StatTrack admin action. Is @SAEFToolbox in the client preset?";
        };

        // ACE silently drops an action whose parent path does not exist yet, and the
        // SAEF_Tools / SAEF_AdminUtils / SAEF_AdminUtils_Mission parents are built by
        // toolbox postInits that may not have finished. Give them room.
        sleep 20;

        [[], "\saef_toolbox_au_integration\LogStatTrack.sqf", "Log StatTrack", true] call RS_fnc_Admin_AddMissionAction;

        // Become Invincible / Become Vulnerable, built directly rather than through
        // RS_fnc_Admin_AddMissionAction: that function's client-side mode execVMs a .sqf
        // from the clicking client, and this addon has no file on the clients to point
        // it at. The one line it would have run is inlined instead. Parent path and the
        // addActionToObject call mirror what RS_fnc_Admin_AddMissionAction does.
        //
        // The Mission Utilities node is only visible while
        // RS_Admin_MissionFunctionsCount > 0, which the Log StatTrack registration above
        // satisfies. Bump the counter if that one is ever dropped.
        private _missionUtilsParent = ["ACE_SelfActions", "SAEF_Tools", "SAEF_AdminUtils", "SAEF_AdminUtils_Mission"];

        {
            _x params ["_id", "_title", "_invincible"];

            private _action = [_id, _title, "",
                {
                    params ["_target", "_player", "_invincible"];

                    player allowDamage !_invincible;

                    hint ([
                        "You are now vulnerable - damage enabled.",
                        "You are now invincible - damage disabled."
                    ] select _invincible);
                },
                {true}, {}, _invincible
            ] call ace_interact_menu_fnc_createAction;

            [player, 1, _missionUtilsParent, _action, true] call ace_interact_menu_fnc_addActionToObject;
        } forEach
        [
            ["SAEF_TBAU_Invincible_On",  "Become Invincible", true],
            ["SAEF_TBAU_Invincible_Off", "Become Vulnerable", false]
        ];

        diag_log "[SAEF_TBAU] registered 'Log StatTrack', 'Become Invincible' and 'Become Vulnerable' under Tools > Admin Utilities > Mission Utilities";
    };

    [[], _clientInit] remoteExec ["spawn", 0, "SAEF_TBAU_AdminActions"];

    diag_log "[SAEF_TBAU] broadcast admin action registration to clients (JIP-armed as SAEF_TBAU_AdminActions)";
};

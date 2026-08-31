/**
    Logs to the Arma log file - the SAEF Antistasi equivalent of Antistasi's own
    A3A_fnc_log (A3A\addons\core\functions\Utility\fn_log.sqf), same line shape and same
    four level labels - just "SAEF Antistasi" in place of Antistasi's own "Antistasi" as
    the prefix, so a line from this mod stays visually distinct from Antistasi's own
    despite the identical layout, and so a tool that colourises Antistasi's own
    Error/Info/Debug/Verbose lines by that shape colourises these identically with no
    changes on its end.

    Unlike A3A_fnc_log, this always writes - there is no LogLevel threshold check. Every
    call site in this addon is already its own gate (each message only exists behind a
    real condition - a timeout, a missing dependency, a state change). _level is kept
    purely as the label picked for the line, not a filter.

    A plain function call, not a macro: unlike a #define, a message string passed this
    way is a genuine runtime SQF value, never touched by the preprocessor - it can
    contain commas or anything else without the "commas get silently stripped from
    macro arguments" gotcha Antistasi's own LogMacros.inc macros (Error(Message), etc.)
    document and are subject to.

    Params:
        Log level: number - Error, Info, Debug or Verbose. Levels 1 to 4 respectively -
            only ever used to choose the label in the line, never to decide whether to log.
        Log Message: string - Message to log
        File (optional): string - File in which the log message originated
        Log to server (optional): bool - true for logging to server RPT instead of client.
            Defaults to true for all HC logs, and errors (level 1) on clients.

        The example below would output an error to the console.
        [1, "Message", "fn_x"] call SAEF_TBAU_fnc_log;
**/

params ["_level", "_message", ["_file", "No File Specified"]];
private _toServer = param [3, !(hasInterface && _level > 1)];

// Sets up the actual log event.
private _logLine = if (1 <= _level && _level <= 4) then {
    (systemTimeUTC call A3A_fnc_systemTime_format_S) + " | SAEF Antistasi | " + ["Error","Info","Debug","Verbose"] # (_level - 1) + " | File=" + _file + " | " + _message;
} else {
    (systemTimeUTC call A3A_fnc_systemTime_format_S) + " | SAEF Antistasi | Error | File=fn_log | Invalid Log Level | Dump=" + str _this;
};

if (isNil "blockServerLogging" && _toServer && !isServer) then {
    // Tag remote log lines with player. HCs return hc, hc_1, hc_2 etc - same tag
    // Antistasi's own A3A_fnc_log applies, reusing its A3A_fnc_localLog relay directly
    // rather than writing our own: that function is a generic "diag_log text _x forEach
    // _this" passthrough, not Antistasi-branded in any way, so it is exactly as correct
    // for our prefix as for theirs.
    _logLine = _logLine + " | Client: " + str player + " [" + str clientOwner + "]";
    _logLine remoteExec ["A3A_fnc_localLog", 2];
} else {
    diag_log text _logLine;
};

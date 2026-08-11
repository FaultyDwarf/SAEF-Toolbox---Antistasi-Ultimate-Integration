/*
    Runs the toolbox wave respawn handler under Antistasi, driven by the six SAEF_Wave_*
    settings from the setup screen (EXTENDER OPTIONS), and restarts it when those
    settings change in game.

    Wave respawn itself is entirely the toolbox's: RS_fnc_InitRespawnHandler is
    postInit = 1 and unguarded, so every player already has the "killed" handler and
    RS_fnc_PlayerOnKilled, which holds a dead player in BIS_fnc_EGSpectator with
    setPlayerRespawnTime 9999 for as long as the global RespawnEnabled is false.
    RS_fnc_Handler_WaveRespawn is the server-side loop that opens and closes that gate.
    The Antistasi mission places no SAEF respawn module, so nothing starts it - that is
    what this file is for.

    Settings arrive as globals: A3A_fnc_initServer publishes every
    configFile >> A3A >> Params class just before it sets A3A_startupState to
    "completed", and Antistasi's in-game params editor rewrites the same globals, which
    is why the watcher can simply poll them. A param whose values[] is exactly {0,1} is
    published as a boolean rather than 0/1; SAEF_Wave_Enabled is the only one affected.

    The watcher restarts the handler rather than updating it because
    RS_fnc_Handler_WaveRespawn captures its settings as `params` locals at spawn and
    resets from those on every wave. A running handler cannot see a new value, so a
    change means stopping it and starting a fresh one.

    While a player is held in spectator they are shown a live wave readout, which means
    borrowing the hint slot off Antistasi for the duration - see the _clientHint block.

    Not handled here: RS_fnc_RespawnDelayedStart kills anyone who finishes loading while
    a wave is closed so they join the next one, and under Antistasi that death costs
    them money, score, a city support point and an HR. That code is client-side in
    @SAEFToolbox and is left alone.
*/

if (!isServer) exitWith {};

// The five timing/threshold settings as one array, used both to start the handler and to
// diff against what is currently applied. SAEF_Wave_Enabled is handled separately, since
// it decides whether a handler should be running at all.
//
// Each falls back to the `default` on its own config class rather than to a number
// written here, so config.cpp stays the only place the values exist. Reaching that
// fallback at all would mean the params config never loaded, which the isNil guard below
// exits on first - so in practice these are always the published values.
SAEF_TBAU_fnc_waveParams = {
    [
        "SAEF_Wave_MinTime",
        "SAEF_Wave_MaxTime",
        "SAEF_Wave_HoldTime",
        "SAEF_Wave_PlayerThreshold",
        "SAEF_Wave_PenaltyTime"
    ] apply {
        missionNamespace getVariable [_x, getNumber (configFile >> "A3A" >> "Params" >> _x >> "default")]
    }
};

SAEF_TBAU_fnc_startWave = {
    params ["_minTime", "_maxTime", "_holdTime", "_threshold", "_penalty"];

    // Clamp: the two time dropdowns are independent, so min > max is selectable, and
    // RS_fnc_Handler_WaveRespawn exits on that before it ever disables respawn - which
    // is indistinguishable from the handler silently not running.
    if (_minTime > _maxTime) then {
        diag_log format ["[SAEF_TBAU] minimum wave time (%1s) exceeds maximum (%2s); clamping maximum up to %1s.", _minTime, _maxTime];
        _maxTime = _minTime;
    };

    // Sixth argument is the handler's class-specific penalty list, [[class, multiplier], ...].
    // Empty: it matches with isKindOf against the player unit type, and the Antistasi
    // rebel slots do not map cleanly onto roles.
    [_minTime, _maxTime, _holdTime, _threshold, _penalty, []] spawn RS_fnc_Handler_WaveRespawn;

    diag_log format [
        "[SAEF_TBAU] wave respawn running: min=%1s max=%2s hold=%3s threshold=%4 penalty=%5s",
        _minTime, _maxTime, _holdTime, _threshold, _penalty
    ];
};

/*
    Stop a running handler and wait for it to finish. Returns true on a clean stop, false
    on timeout.

    The wait is required: RS_fnc_Handler_WaveRespawn nils SAEF_Respawn_RunWaveRespawn in
    its teardown, after its loop ends, so a replacement started before then would be
    switched off by the old handler on its way out. Setting the flag false and waiting for
    it to go nil is the handshake.

    The handler only re-tests its condition between iterations, and mid-wave it sits
    through the penalty and hold sleeps first, so a stop can take roughly penalty + hold.
    300s covers the largest values the dropdowns offer.
*/
SAEF_TBAU_fnc_stopWave = {
    if (isNil "SAEF_Respawn_RunWaveRespawn") exitWith { true };

    missionNamespace setVariable ["SAEF_Respawn_RunWaveRespawn", false, true];

    private _deadline = diag_tickTime + 300;
    waitUntil {
        sleep 1;
        isNil "SAEF_Respawn_RunWaveRespawn" || {diag_tickTime > _deadline}
    };

    isNil "SAEF_Respawn_RunWaveRespawn"
};

[] spawn {
    // diag_tickTime rather than time: advances even while the mission is paused. The
    // ceiling is high because Antistasi startup blocks on an admin working through the
    // setup dialog and picking a save.
    private _deadline = diag_tickTime + 1800;

    waitUntil {
        sleep 1;
        (missionNamespace getVariable ["A3A_startupState", ""]) isEqualTo "completed"
            || {diag_tickTime > _deadline}
    };

    if ((missionNamespace getVariable ["A3A_startupState", ""]) isNotEqualTo "completed") exitWith {
        diag_log "[SAEF_TBAU] Antistasi startup did not reach 'completed' within 1800s, wave respawn not started. Has A3A_startupState been renamed?";
    };

    // isNil rather than a falsy test, so "the config never loaded" logs differently from
    // "the feature is switched off in the setup screen".
    if (isNil "SAEF_Wave_Enabled") exitWith {
        diag_log "[SAEF_TBAU] SAEF_Wave_Enabled undefined after Antistasi startup - the params half of this addon did not load. Wave respawn not started.";
    };

    if (isNil "RS_fnc_Handler_WaveRespawn") exitWith {
        diag_log "[SAEF_TBAU] RS_fnc_Handler_WaveRespawn undefined. Is mods\@SAEFToolbox still on the server -mod= line? Wave respawn not started.";
    };

    private _applied = call SAEF_TBAU_fnc_waveParams;
    private _running = SAEF_Wave_Enabled;

    if (_running) then {
        _applied call SAEF_TBAU_fnc_startWave;
    } else {
        diag_log "[SAEF_TBAU] wave respawn disabled in the setup screen (Extender Options). Antistasi's own respawn is unchanged. Watching for a change.";
    };

    /*
        Wave progress readout, shown to a player for as long as they are held in spectator.

        Antistasi owns the hint slot. A3A_fnc_customHintInit registers an EachFrame handler
        that runs A3A_fnc_customHintRender roughly four times a second, and that blanks the
        slot with hintSilent "" whenever Antistasi's own queue is empty, so a hint from
        anywhere else lasts about 250ms.

        A3A_customHintEnable is local and unsynced, and the renderer and dismiss handler
        both exit early while it is false, so a client can borrow the slot. This takes it on
        death and gives it straight back on respawn, leaving Antistasi's notifications alone
        the rest of the time.

        Broadcast whether or not wave respawn is currently enabled: the loop only wakes when
        SAEF_Respawn_AwaitingRespawn goes true, which only happens during a wave hold, so it
        costs nothing while the feature is off and needs no re-broadcast when it is toggled.
    */
    private _clientHint = {
        if (!hasInterface) exitWith {};

        // Local only, and guards against a replayed JIP message starting a second loop.
        if (missionNamespace getVariable ["SAEF_TBAU_WaveHintRun", false]) exitWith {};
        missionNamespace setVariable ["SAEF_TBAU_WaveHintRun", true];

        waitUntil { sleep 1; !isNull player };

        while {true} do {
            // RS_fnc_PlayerOnKilled sets this for exactly the window it holds the player in
            // BIS_fnc_EGSpectator, and clears it after forceRespawn.
            waitUntil { sleep 1; player getVariable ["SAEF_Respawn_AwaitingRespawn", false] };

            // Only touch the flag if Antistasi's hint system is actually present, and
            // remember so it is restored to what it was.
            private _borrowed = !isNil "A3A_customHintEnable";
            if (_borrowed) then { A3A_customHintEnable = false };

            while {
                (player getVariable ["SAEF_Respawn_AwaitingRespawn", false]) && {!alive player}
            } do {
                private _waveIn    = missionNamespace getVariable ["SAEF_Respawn_WaveRespawn_RespawnTimeLeft", 0];
                private _penalty   = missionNamespace getVariable ["SAEF_Respawn_WaveRespawn_PenaltyRespawnTimeLeft", 0];
                private _minTime   = missionNamespace getVariable ["SAEF_Respawn_WaveRespawn_MinTime", 0];
                private _threshold = missionNamespace getVariable ["SAEF_Wave_PlayerThreshold", 0];
                private _open      = missionNamespace getVariable ["RespawnEnabled", false];

                // The same per-unit flag the server counts, broadcast globally, so the
                // number waiting can be counted here without asking the server for it.
                private _waiting = {
                    _x getVariable ["SAEF_Respawn_AwaitingRespawn", false]
                } count (allPlayers - entities "HeadlessClient_F");

                // Fills as the countdown runs down. Blank until the handler has published
                // a min time, which it does when it starts.
                private _bar = "";
                if (_minTime > 0) then {
                    private _filled = 0 max (10 min round (10 * (1 - (_waveIn / _minTime))));
                    for "_i" from 1 to 10 do { _bar = _bar + (["-", "#"] select (_i <= _filled)) };
                    _bar = "[" + _bar + "]";
                };

                // 999 is the "Never (timer only)" threshold; showing it as a target reads
                // as a countdown that is never going to arrive.
                private _waitingStr = if (_threshold > 0 && {_threshold < 999}) then {
                    format ["%1 / %2", _waiting, _threshold]
                } else {
                    str _waiting
                };

                private _status = ["#ffffff", "#7ec850"] select _open;
                private _headline = if (_open) then { "RESPAWN OPEN" } else { format ["%1s", _waveIn] };

                hintSilent parseText format [
                    "<t size='1.1' color='#e5b348' align='center'>SAEF WAVE RESPAWN</t><br/><br/>"
                    + "<t size='1.6' color='%1' align='center'>%2</t><br/>"
                    + "<t size='0.9' color='#cccccc' align='center'>%3</t><br/><br/>"
                    + "<t size='0.85' align='center'>Penalty %4s&#160;&#160;|&#160;&#160;Waiting %5</t>",
                    _status, _headline, _bar, _penalty, _waitingStr
                ];

                sleep 1;
            };

            // Clear our own text before handing the slot back, so Antistasi's renderer does
            // not have a frame of stale readout to inherit.
            hintSilent "";
            if (_borrowed) then { A3A_customHintEnable = true };
        };
    };

    [[], _clientHint] remoteExec ["spawn", 0, "SAEF_TBAU_WaveHint"];

    diag_log "[SAEF_TBAU] broadcast wave progress readout to clients (JIP-armed as SAEF_TBAU_WaveHint)";

    // Watcher. Polls rather than hooking an event: Antistasi's in-game editor rewrites
    // every param on save with no signal that anything changed, so a diff is needed
    // regardless.
    while {true} do {
        sleep 5;

        private _now = call SAEF_TBAU_fnc_waveParams;

        // Read directly: the isNil guard above already established this is published,
        // and it stays published for the life of the mission.
        private _wantRunning = SAEF_Wave_Enabled;

        if (_now isEqualTo _applied && {_wantRunning isEqualTo _running}) then { continue };

        // Switched off in game. Stop, then open respawn so nobody is left in spectator
        // with no handler to release them.
        if (!_wantRunning) then {
            diag_log "[SAEF_TBAU] wave respawn switched off in game, stopping handler.";

            if !(call SAEF_TBAU_fnc_stopWave) then {
                diag_log "[SAEF_TBAU] handler did not stop within 300s. Leaving it alone - forcing it would risk two loops fighting over RespawnEnabled.";
            } else {
                missionNamespace setVariable ["RespawnEnabled", true, true];
                diag_log "[SAEF_TBAU] handler stopped, respawn left open.";
                _running = false;
            };

            _applied = _now;
            continue;
        };

        // Settings changed while running, or the feature was switched back on.
        diag_log format ["[SAEF_TBAU] wave settings changed %1 -> %2, restarting handler.", _applied, _now];

        if !(call SAEF_TBAU_fnc_stopWave) then {
            diag_log "[SAEF_TBAU] previous handler did not stop within 300s, not restarting. Old settings remain in effect.";
            _applied = _now;
            continue;
        };

        // Anyone already dead starts their countdown again from the new minimum, since
        // the fresh handler disables respawn and resets its own timer on entry.
        _now call SAEF_TBAU_fnc_startWave;
        _applied = _now;
        _running = true;
    };
};

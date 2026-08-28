# @SAEF_Toolbox_AU_Integration

Wires SAEF Toolbox features into Antistasi Ultimate. Three PBOs:

| PBO | What | Where it has to be | `requiredAddons` |
|---|---|---|---|
| `saef_toolbox_au_integration` | admin actions (Log StatTrack, invincibility) | server | `cba_xeh` |
| `saef_tbau_waverespawn` | wave respawn + its setup-screen parameters | server, plus setup admins | `cba_xeh`, `A3A_core`, `SAEF_TOOLBOX_RESPAWN` |
| `saef_tbau_saef_rebels` | Modified copies of three Aegis faction templates (Rebels, AAF, NATO Arid - Altis only): SAEF flag/map marker on `Aegis_FIA`; planes removed, remaining air fleet re-pricing, roster swaps, and dropped Titan launchers (AT and AA) on AAF/NATO AI | **everyone** | `A3A_core` |

**This now goes in the client preset**, which reverses what earlier versions of this
README said. `saef_tbau_saef_rebels` (previously the standalone
`@SAEF_antistasi_bridge`) is textures and a `CfgMarkers` class, both of which are
rendered client-side — without it players see the vanilla FIA flag and a missing marker
class. The two server-side PBOs are `if (!isServer) exitWith {}` at the top of their
postInits, so they are inert on a client and safe to ship alongside.

That also settles the wave respawn parameter problem: the setup dialog is built from the
admin's own `configFile`, so those six rows only render on machines that have the folder.
Everyone having it makes that automatic.

`verifySignatures = 0` on this server, so it needs no key and no signature.

Beyond this, players need nothing new — `@SAEFToolbox` is what provides the menu and the
functions the server-side half drives.

## Why this mod exists

On a normal SAEF mission, toolbox features that need a per-player hook get one line in
the mission:

```sqf
[[], "Scripts\Mission\LogStatTrack.sqf", "Log StatTrack", true] call RS_fnc_Admin_AddMissionAction;
```

The Antistasi mission ships inside `@AntistasiUltimate\addons\maps.pbo`
(`Antistasi_Tanoa.Tanoa`), so there is no `initPlayerLocal.sqf` and no `Scripts\Mission\`
to put that in. This mod pushes the same registration from the server instead.

## What it currently does

### StatTrack — the `Log StatTrack` admin action

StatTrack needed no help to start. `saef_stattrack\Functions\fn_InitStatTrack.sqf` is
`postInit = 1` and server-guarded, so it self-starts under Antistasi and already logs on
every player death and on mission end. Verified in the server RPT:

```
20:58:49 "server/BIS_fnc_log: [postInit] RS_ST_fnc_InitStatTrack (0 ms)"
21:34:58 [StatTrack] [VERBOSE] Total Player Count: 11 || Total Player Casualties: 1 || Total Enemies Killed: 49 || Friendly Fire Incidents: 0 || Mission Attendees: [{"ArmaName":"Oom Jannie","ArmaUID":"..."}] || Civilian Casualties (by Player): 0
```

The only missing piece was the on-demand ACE action, because
`RS_fnc_Admin_AddMissionAction` is client-local — it uses `player` and ACE self-interact.

The Antistasi mission's `MissionDescription\CfgRemoteExec.hpp` is fully permissive:

```cpp
class Functions { mode = 2; jip = 1; allowedTargets = 0; };
class Commands  { mode = 2; jip = 1; allowedTargets = 0; };
```

so the server can remoteExec the registration onto each client, and the action's own
callback can reach back to the server. `XEH_postInit.sqf` sends it to `-2` with the JIP
id `SAEF_TBAU_LogStatTrack`, so late joiners get it as well.

What happens when an admin clicks it:

| Machine | Step |
|---|---|
| client | `RS_fnc_Admin_AddMissionAction` callback fires, `_server = true` |
| client | `RS_fnc_Admin_RunScriptOnServer`: `[_params, _script] remoteExec ["execVM", 2]` |
| server | `execVM "\saef_toolbox_au_integration\LogStatTrack.sqf"` |
| server | `[] call RS_ST_fnc_LogInfo` — stat line to `server.rpt`, hint back to the admin |

`LogStatTrack.sqf` is byte-for-byte the file we would have put in `Scripts\Mission\`.

### Become Invincible / Become Vulnerable

The mission version of these two is `_server = false`:

```sqf
[[true],  "Scripts\Utility\Invincible.sqf", "Become Invincible", false] call RS_fnc_Admin_AddMissionAction;
[[false], "Scripts\Utility\Invincible.sqf", "Become Vulnerable",  false] call RS_fnc_Admin_AddMissionAction;
```

`_server = false` makes the callback run `(_params select 0) execVM (_params select 1)` on
the *clicking client*, so the `.sqf` has to exist on that client — and this addon is
server-side only, so there is no path we can hand it. `Scripts\Utility\Invincible.sqf` is
one line:

```sqf
_invincible = !(_this select 0);
player allowDamage _invincible;
```

so `XEH_postInit.sqf` builds these two actions itself with that line inlined, using the
same parent path and the same `[player, 1, ...] call ace_interact_menu_fnc_addActionToObject`
that `RS_fnc_Admin_AddMissionAction` uses. Same names, same place in the menu, same
behaviour, still nothing to install on the clients. The only visible difference is the
hint: `You are now invincible - damage disabled.` instead of the generic
`Running Script ... with these parameters ...`.

Two things carried over from the mission version rather than "fixed", so say the word if
you want either changed:

- Both entries are always visible (condition `{true}`), exactly as in the mission. Gating
  them on current state — so you only ever see the one that does something — is a
  two-line change to the `forEach` block.
- `allowDamage` is set on the unit, not on the player slot. ACE's
  `ace_interact_menu_fnc_addActionToObject` is likewise a 4-argument function with no
  persistence flag (the trailing `true` the toolbox passes it is ignored), so both the
  actions and the invincibility state live on the player object. Tested under Antistasi:
  the menu entries survive death, so the object is retained and no re-registration on
  respawn is needed. Re-check this after an Antistasi upgrade that touches respawn.

Because these bypass `RS_fnc_Admin_AddMissionAction` they do not bump
`RS_Admin_MissionFunctionsCount`, and the `Mission Utilities` node is only visible while
that is `> 0`. The `Log StatTrack` registration satisfies it — if you ever drop that one,
bump the counter or the whole submenu disappears.

### Wave respawn

Starts `RS_fnc_Handler_WaveRespawn` under Antistasi, with its settings coming from the
Antistasi setup screen under **EXTENDER OPTIONS**.

This one is a **second PBO**, `saef_tbau_waverespawn`, in the same mod folder. It is the
only part of this mod that genuinely needs Antistasi: its config inherits from
`ExtenderParams`, an external class in `A3A_core`, so `requiredAddons` there is
`{"cba_xeh", "A3A_core", "SAEF_TOOLBOX_RESPAWN"}`. Keeping it out of
`saef_toolbox_au_integration` preserves that PBO's cba-only dependency, so an Antistasi
rename can only take the wave half down and the admin actions keep working.

| Parameter | Options | Default |
|---|---|---|
| SAEF wave respawn | Disabled / Enabled | Disabled |
| Wave - minimum time | 1 / 2 / 3 / 5 / 7.5 / 10 / 15 min | 5 min |
| Wave - maximum time | 5 / 10 / 15 / 20 / 30 min | 15 min |
| Wave - respawn window | 10 / 15 / 30 / 45 / 60 s | 30 s |
| Wave - dead player threshold | 2 / 3 / 4 / 5 / 6 / 8 / 10 / Never | 5 |
| Wave - penalty per death | None / 15 / 30 / 45 / 60 / 90 s | None |

All six are editable in game, through Antistasi's own params editor
(`SCRT_fnc_ui_editParamsMenu`), and changes take effect within ~5 seconds.

That needs a restart of the handler, not just a new value. `RS_fnc_Handler_WaveRespawn`
takes its settings as `params` — locals captured once at spawn
(`fn_Handler_WaveRespawn.sqf:70-78`) and re-read from that capture on every wave
(`:115`, `:140`). Editing `SAEF_Wave_MinTime` in game does nothing to a running loop;
observed live, set to 2 min then changed to 5 min mid-session, waves kept firing at
2 min. So `XEH_postInit.sqf` polls the six globals every 5s and, on any change, stops
the handler and starts a fresh one.

The stop is a handshake, not a kill: the handler's teardown (`:211-214`) nils
`SAEF_Respawn_RunWaveRespawn` *after* its loop ends, so a replacement started too early
would be switched off by the old one's teardown a moment later. `SAEF_TBAU_fnc_stopWave`
sets the flag false and waits for it to go nil, up to 300s — worst case the loop is
mid-wave and sits through `sleep _currentPenaltyTime` then `sleep _holdTime` first. On
timeout it logs and leaves the old handler alone rather than risk two loops fighting
over `RespawnEnabled`.

Switching the feature off in game stops the handler and then sets `RespawnEnabled` true,
so nobody is left in spectator with nothing left to release them.

Anyone already dead when settings change restarts their countdown from the new minimum.

Penalty time stacks on top of what Antistasi already charges for a death: `deathPenalty`
(50% of your money on the current save) and `loseHROnDeath` (−1 HR with a chat message).
Start at None.

Nothing about the respawn behaviour itself has to be installed on the clients.
`saef_respawn\config.cpp` marks `RS_fnc_InitRespawnHandler` `postInit = 1` and does not
guard it, so every player already runs `RS_fnc_RespawnDelayedStart` →
`RS_fnc_RespawnPlayerInit`, putting the `killed` handler and `RS_fnc_PlayerOnKilled` in
place. Confirmed in the server RPT:

```
19:01:25 [RS Respawn] [VERBOSE] Starting up respawn handler ...
19:01:25 "server/BIS_fnc_log: [postInit] RS_fnc_InitRespawnHandler (0 ms)"
```

All of it keys off one global, `RespawnEnabled`. While that is false a dead player is
held in `BIS_fnc_EGSpectator` with `setPlayerRespawnTime 9999`. The only missing piece
was a server-side loop to open and close the gate — the Antistasi mission places no SAEF
respawn module, so `RS_fnc_Handler_WaveRespawn` was never being started.

Timing: it waits for `A3A_startupState == "completed"`, because `A3A_fnc_initServer`
publishes the parameter globals (`fn_initServer.sqf:81-89`) just before setting that
(`:311`). The wait is 1800s since Antistasi startup blocks on the admin working through
the setup dialog.

#### Known: late joiners are killed, and Antistasi charges them for it

`RS_fnc_RespawnDelayedStart` ends with:

```sqf
sleep 5;
if (!(missionNamespace getVariable ["RespawnEnabled", true])) then {
    ...decrement ST_Casualties...
    player setDamage 1;
};
```

Anyone who finishes loading while a wave is closed is killed on the spot so they join
the next wave. On a normal SAEF mission that death is free. Under Antistasi it is not —
the respawn runs `A3A_fnc_onPlayerRespawn`, which takes `deathPenalty`% of their money,
−10 score, a city support point at the HQ, and −1 HR while `loseHROnDeath` is on and
`tierWar >= 2`.

Left as-is deliberately. That code is client-side, in `@SAEFToolbox`, which players get
from the Workshop, so there is nothing to patch — the only server-side workaround is to
desync that client's copy of `RespawnEnabled`, which was judged not worth the
complexity. If it turns into a real complaint the two options are a guard variable
upstream in the toolbox, or compensating the player server-side on the resulting death.

### SAEF rebel identity, and AAF/NATO balance

`saef_tbau_saef_rebels`, previously the standalone `@SAEF_antistasi_bridge`. Ships
modified **copies** of three of Antistasi's own Aegis faction template scripts -
`Aegis_Reb_FIA.sqf`, `Aegis_AI_AAF.sqf`, and `Aegis_AI_NATO_Arid.sqf` - and points
each template's `basepath`/`file` config properties at our copy instead of the original
(the same pattern used by community "extender" mods for Antistasi Ultimate, e.g.
[A3UExtender](https://github.com/Westalgie/A3UExtender)). Antistasi's own template-loading
code (`A3A_fnc_compatibilityLoadFaction`) is completely unmodified - no copy of it exists
in this mod at all; it just ends up loading our file instead of Aegis's for these three
templates. Its own [README](saef_tbau_saef_rebels/README.md) has the full reasoning.

**`Aegis_NATO_Arid`, not `Aegis_NATO_Temperate` - despite the name.** This integration's
real Invaders template on Altis is `Aegis_NATO_Arid`, confirmed from the server RPT via
the `saef_toolbox_au_integration` postInit check described below - `Aegis_NATO_Temperate`
sounds like the obvious Altis pick and isn't. `Aegis_NATO_Temperate` and
`Aegis_NATO_Tropical` have no copy in this mod and are never reopened in config, so they
keep loading Aegis's own, completely unmodified originals.

`Aegis_Reb_FIA.sqf` puts the SAEF logo on the Rebels template in three places, each a
separate Antistasi data path: the faction-select preview (config merge in
`Templates\Templates.hpp`), the in-game flagpole texture, and the strategic map marker
(a `CfgMarkers` class) - the latter two both set directly inside the copied script now,
the same four lines Antistasi's own file has, just pointed at the SAEF assets.

`Aegis_AI_AAF.sqf` and `Aegis_AI_NATO_Arid.sqf` remove fixed-wing planes entirely for
both factions - `vehiclesPlanesCAS`, `vehiclesPlanesAA`, and `vehiclesPlanesTransport`
are all empty arrays, so neither side ever spawns a jet or transport plane of any kind.
Every remaining air category (attack helis, transport helis, attack UAV, even the
unarmed scout heli) is instead re-priced via `A3A_vehicleResourceCosts`, at roughly
4x-12x the vanilla Aegis default, so a typical QRF/attack resource pool affords at most
one such vehicle - nothing is removed there, just expensive. Every other vehicle either
faction's own script can actually field on Altis - including DLC-conditional ones like
the Western Sahara AA truck/APC variants - is explicitly priced too, at its vanilla
default where it isn't part of the pricing pass, so the whole priceable roster is
accounted for. NATO Arid also gets roster swaps (Aegis's own Apache in for the
Blackfoot, Little Bird added as a transport option) - `Aegis_NATO_Temperate`/
`Aegis_NATO_Tropical` are untouched by any of this, since their classnames are not
interchangeable with Arid's and this mod has no copy of either file.

Both `Aegis_AI_*.sqf` copies (not Rebels) also drop every Titan launcher those AI
carry - AT role and AA role alike - leaving them with only the unguided `NLAW_F`. This
runs as a post-process over each file's own already-generated unit loadouts (a shared
`#include`d snippet, `SAEF_TitanToNLAW_Swap.sqf`) rather than editing the launcher pools
before generation, because those pools are declared more than once per file (base loadout
data, Special Forces, ...) and walking the resolved output afterward catches every
generated unit type uniformly. No other faction pack is touched. Full reasoning and scope
in the [same README](saef_tbau_saef_rebels/README.md).

Merged in as-is apart from one thing: **every internal path was rewritten** from the old
prefix `z\SAEF_antistasi\addons\main` to `saef_tbau_saef_rebels`, to match its
`$PBOPREFIX$`. These resolve at load time, not build time, so a stale one fails silently
at runtime as a missing texture, a `No entry '....icon'`, or a faction silently loading
Aegis's unmodified defaults - not as a build error. Worth re-grepping if the prefix ever
changes again.

This `basepath`/`file` approach replaced an earlier version of this mod that overrode
`A3A_fnc_compatibilityLoadFaction` wholesale (a frozen copy of Antistasi's own
orchestration function, needing manual re-syncing whenever Antistasi changed it upstream)
and appended small scripts to the file list it built. That also had a real bug: one shared
append script served both AAF and NATO, and its NATO-only roster changes ran
unconditionally regardless of which one was actually loading - AAF ended up flying NATO's
Chinooks. Since each template now has its own separate, self-contained copy, that whole
class of bug is structurally impossible: there's no shared script for one faction's
change to leak into another's.

### Visibility

Gating is the toolbox's own, untouched, for all three actions: the `SAEF_AdminUtils` parent
requires `AdminUtil_Enabled` and `player getVariable "RS_IsAdmin"`, and
`RS_fnc_Admin_CheckAdmin` only sets `RS_IsAdmin` for a logged-in admin
(`serverCommandAvailable "#logout"`) or an explicit `RS_AdminOverride`. Regular players
never see the entries.

## Deployment

Copy the whole `@SAEF_Toolbox_AU_Integration` folder to `E:\ArmA3\A3Master\mods\` on the
live server, and **add it to the player preset**.

`ServerLauncher.ps1` currently appends it via `$SERVERONLYMODS`. Since
`saef_tbau_saef_rebels` was merged in, that is no longer the right list — it also needs to
reach clients, and it is no longer correct to leave it off the three headless client
`-mod=` lines either (the HCs do not render, so it is harmless there, but keeping the
lines uniform avoids a mismatch nobody will remember the reason for).

As of the last check the mod was **not** on the server `-mod=` line at all — the line
ended `...@AntistasiUltimate;@SAEFToolbox;@SAEF_AU_HC_FIX`, and the RPT for that session
has no `[SAEF_TBAU]` entries. Nothing here has run on the live server yet.

### Why the client half matters

`saef_tbau_saef_rebels` is textures plus a `CfgMarkers` class. Both are resolved on the
machine doing the rendering:

- `flagTexture` ends up on flagpole objects; a client without the PBO cannot resolve
  `saef_tbau_saef_rebels\Pictures\Markers\SAEF_flag_1024x512.paa`.
- `flagMarkerType` is set to the class name `SAEF_flag_marker`; a client without the
  PBO fails the `CfgMarkers` lookup when drawing the strategic map marker.

Wave respawn has a narrower version of the same problem. Antistasi reads the parameter
config on **two** machines, and only one of them is the server:

| Reader | Runs on | Without the config |
|---|---|---|
| `A3A_fnc_initServer` (`fn_initServer.sqf:81-89`) | server | params never published as globals |
| `A3A_fnc_setupParamsTab` (`fn_setupParamsTab.sqf:107`, reads `configFile`) | the admin's client | rows are not drawn |

`fn_setupMonitor.sqf:102` remoteExecs `A3A_fnc_setupDialog` to `A3A_setupPlayer`, and
`fn_setupDialog.sqf:76` does `createDialog` there. From the 2026-08-08 session:

```
19:02:47  A3A_fnc_setupMonitor | Player Oom Jannie is now admin sending them the save data
19:02:50  A3A_fnc_startGame | startGame called with data [... ["params",[...]]]
```

That params array was built on Oom Jannie's client. Server-only would work, but the six
rows would never render for whoever runs setup and the server would fall back to
`default` for all of them — permanently. Shipping the folder to every player, which
`saef_tbau_saef_rebels` requires anyway, makes that moot.

Mixed installs are not fatal for the parameters — the values reach every machine by
broadcast regardless of who has the config — but they are visibly wrong for the flag: a
player without the folder sees the vanilla FIA flag while everyone else sees the SAEF
one.

## Verifying after launch

Server RPT, within ~5 minutes of mission start:

```
[SAEF_TBAU] broadcast admin action registration to clients (JIP-armed as SAEF_TBAU_AdminActions)
```

Client RPT (yours, as an admin), about 20s later:

```
[SAEF_TBAU] registered 'Log StatTrack', 'Become Invincible' and 'Become Vulnerable' under Tools > Admin Utilities > Mission Utilities
```

Then in game: `#login`, ACE self-interact → **Tools → Admin Utilities → Mission
Utilities**. All three entries should be there.

- `Log StatTrack` → hint `StatTrack information has been logged to Server.rpt`, and a
  fresh `[StatTrack] [VERBOSE] ...` line in `server.rpt`.
- `Become Invincible` → hint `You are now invincible - damage disabled.` Confirm by
  taking a hit; then `Become Vulnerable` and confirm damage lands again.

### Testing on a locally hosted session

Works the same way, with one difference: your machine is both server and client, so both
`[SAEF_TBAU]` lines land in your own client RPT (`%LOCALAPPDATA%\Arma 3\Arma3_x64_*.rpt`)
rather than being split across two logs. Add
`D:\ArmA3\A3Files\mods\@SAEF_Toolbox_AU_Integration` to the launcher's mod list alongside
`@saef_toolbox`.

If you see the `broadcast` line but no `registered` line, the client half never ran — that
is the failure mode the `remoteExec` target 0 (not -2) exists to prevent, so check that
first.

Failure lines to watch for in the server RPT:

| Line | Meaning |
|---|---|
| `StatTrack did not initialise within 300s` | `mods\@SAEFToolbox` fell off the server `-mod=` line, or the toolbox restructured `fn_InitStatTrack` |
| `RS_fnc_Admin_AddMissionAction / ACE interact menu unavailable after 300s` (client RPT) | that client does not have `@SAEFToolbox` loaded |
| `SAEF_Wave_Enabled undefined after Antistasi startup` | `saef_tbau_waverespawn.pbo` did not load — check its `requiredAddons` against the loaded addon list |
| `RS_fnc_Handler_WaveRespawn undefined` | `mods\@SAEFToolbox` fell off the server `-mod=` line |
| `Antistasi startup did not reach 'completed' within 1800s` | `A3A_startupState` renamed upstream, or setup was never completed |

For wave respawn, once the admin has finished setup:

```
[SAEF_TBAU] broadcast JIP respawn grace to clients (JIP-armed as SAEF_TBAU_WaveJIPGrace)
[SAEF_TBAU] wave respawn started: min=300s max=900s hold=30s threshold=5 penalty=0s
```

With the feature turned off in the setup screen you get this instead, which is the
success case for "we left it disabled":

```
[SAEF_TBAU] wave respawn disabled in the setup screen (Extender Options). Antistasi's own respawn is unchanged.
```

## Known cosmetics

`RS_fnc_Admin_AddMissionAction` increments `RS_Admin_MissionFunctionsCount` with a global
broadcast, and every client now registers its own action, so the counter ends up at
roughly the player count instead of 1. The toolbox only ever reads it as `> 0` (the
`Mission Utilities` parent's condition) and to name the action `mission_func_N`, so this
is harmless.

## Rebuilding

Source lives in `D:\ArmA3\A3Files\SAEF_Toolbox_AU_Integration_src\`. Run `build.ps1`
there (needs Arma 3 Tools installed for `FileBank.exe`). It packs the PBO and stages
`mod.cpp` and this README into the mod folder.

## Adding more toolbox features later

This is the place for any other toolbox feature that normally needs a line in the mission.
The rule of thumb is the `_server` flag on the mission's `RS_fnc_Admin_AddMissionAction`
call:

| Mission call | Here |
|---|---|
| `_server = true` | Drop a `<Feature>.sqf` next to `LogStatTrack.sqf` and call `RS_fnc_Admin_AddMissionAction` with `"\saef_toolbox_au_integration\<Feature>.sqf"`. Works unchanged. |
| `_server = false` | The script would have to exist on the client, which it cannot. Build the ACE action inline in `_clientInit` instead, the way the invincibility pair does. |

Then note it under "What it currently does".

For reference, the rest of `Scripts\Player\InitToolbox.sqf` from a normal SAEF mission,
none of which is wired up here yet:

```sqf
[[], "Scripts\Mission\EndMission.sqf", "End Mission", true] call RS_fnc_Admin_AddMissionAction;
[[], "Scripts\Mission\EnableDropPods.sqf", "Enable Drop Pods", false] call RS_fnc_Admin_AddMissionAction;
```

`End Mission` is deliberately left out — Antistasi is a persistent campaign and ending the
mission is not something we want one menu click away.

## Retiring this mod

Unlike `@SAEF_AU_HC_FIX` this is not a stopgap waiting on an upstream fix — the Antistasi
mission will never carry SAEF mission scripts, so this mod stays as long as we run the
toolbox on Antistasi. Re-check the toolbox function names on every `@SAEFToolbox` update.

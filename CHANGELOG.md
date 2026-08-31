# Changelog

All notable changes to `@SAEF_Toolbox_AU_Integration` are recorded here.

## Unreleased

### Added

- **Aegis Police vehicles and loadouts for AAF and NATO Arid** -
  `Templates\Templates\Aegis_AI_AAF.sqf` and `Aegis_AI_NATO_Arid.sqf` (copies). Aegis
  Police's `Police_I_P_*` vehicles and uniform/vest/helmet/SMG/sidearm classnames are
  merged directly into each file's existing `vehiclesPolice`/`_policeLoadoutData`
  declarations, alongside its own vanilla items - not appended as a separate override,
  since these are already this mod's own copied template files rather than upstream
  Antistasi originals. `saef_tbau_saef_rebels/config.cpp`'s `requiredAddons` extended
  with `A3_Police_Soft_F_Police` and `A3_Police_Characters_F_Police`.

- **`SAEF_TBAU_fnc_log`** (`saef_toolbox_au_integration`), a shared logging function
  replacing every raw `diag_log` call across `saef_toolbox_au_integration/XEH_postInit.sqf`
  and `saef_tbau_waverespawn/XEH_postInit.sqf`. Matches Antistasi's own `A3A_fnc_log` line
  shape exactly - `{time} | SAEF Antistasi | {level} | File=... | {message}` - with
  `SAEF Antistasi` as this mod's own prefix in place of Antistasi's, and the same four
  level labels (Error/Info/Debug/Verbose) used only to pick that label: every call always
  writes, since each call site already gates itself on a real condition (a timeout, a
  missing dependency, a state change). Registered under `CfgFunctions` as a real compiled
  function rather than a private closure, so it resolves identically at the top of a
  script, inside a `spawn`, or after a `remoteExec` to a client.

### Fixed

- **Half of generated police loadouts spawned with only a pistol.** Root cause:
  `_policeTemplate`'s `[selectRandom ["SMGs", "shotGuns"]]` roll could land on
  `"shotGuns"`, a pool neither Aegis file populated - `fn_loadout_builder.sqf`'s
  `_fnc_setPrimary` exits with no primary weapon at all when the resolved pool is `[]`.
  Fixed by populating `shotGuns` with `sgun_M4_F`, `sgun_Mp153_classic_F`, and
  `sgun_Mp153_black_F` in both `Aegis_AI_AAF.sqf` and `Aegis_AI_NATO_Arid.sqf`, without
  touching `_policeTemplate` itself. The shotgun-type entries that had been sitting in
  `SMGs` instead are removed, and literal duplicate lines inherited from vanilla in NATO
  Arid's own `SMGs` pool are cleaned up.



- **Wrong NATO climate targeted: `Aegis_NATO_Temperate` instead of the actual
  Altis Invaders template, `Aegis_NATO_Arid`.** The AAF/NATO balance work
  below initially assumed `Aegis_NATO_Temperate` was this integration's Altis
  NATO template, going by name alone. The `saef_toolbox_au_integration`
  postInit check (added below) reported the real faction name from the
  server, confirming it's actually `Aegis_NATO_Arid`. Fixed by re-deriving
  the whole vehicle-pricing and roster-swap block from `Aegis_AI_NATO_Arid.sqf`'s
  own actual roster arrays rather than reusing the Temperate work -
  Arid's classnames have no `"B_W_"` prefix at all (`B_MRAP_01_gmg_F` vs
  Temperate's `B_W_MRAP_01_gmg_F`), its default roster has no Atlas transport
  plane, only two `uavsAttack` classes instead of three, and its Western
  Sahara DLC variants use a different suffix pattern
  (`APC_Wheeled_01_command_base_lxWS` vs `B_W_APC_Wheeled_01_command_lxWS`).
  `Templates\Templates\Aegis_AI_NATO_Temperate.sqf` is removed;
  `Aegis_AI_NATO_Arid.sqf` takes its place, and `Templates.hpp` now reopens
  `Aegis_NATO_Arid` instead of `Aegis_NATO_Temperate`.
  - Also added `name = "SAEF AAF"` / `name = "SAEF NATO"` to `Aegis_AAF`'s and
    `Aegis_NATO_Arid`'s `Templates.hpp` entries, so both show branded names on
    the faction-select screen, matching `Aegis_FIA`'s "SAEF" treatment.

- **Server crash at mission start: missing `#include` sibling file.**
  `Aegis_Reb_FIA.sqf` was copied into `Templates\Templates\` without also
  copying `Aegis_Reb_Vehicle_Attributes.sqf`, the file it `#include`s twice
  for Rebels' vehicle purchase costs. `build.ps1`/FileBank never opens or
  preprocesses `.sqf` files, so this packed without error; it only surfaced at
  mission start, server-side, as `Include file ... not found` immediately
  followed by `Application terminated intentionally` when Antistasi actually
  tried to load `Aegis_FIA`. Fixed by copying
  `Aegis_Reb_Vehicle_Attributes.sqf` alongside it, unmodified. Verified this
  time by running Arma's own preprocessor directly against every copied
  template file (`CfgConvert.exe -pcpp`) and confirming the included content
  actually appears in the output, not just checking the exit code - see
  "Copying a template means copying its `#include`d siblings too" in
  `saef_tbau_saef_rebels/README.md` for the check to run before trusting any
  future copy or re-copy of a template file.

### Changed

- **`saef_tbau_saef_rebels` rearchitected to ship modified copies of Antistasi's own
  template files, instead of overriding `A3A_fnc_compatibilityLoadFaction`.** Previously
  this PBO replaced `CfgFunctions >> A3A >> FunctionsTemplates >> compatibilityLoadFaction`
  with a frozen copy of Antistasi's own orchestration function, needing manual re-syncing
  whenever Antistasi changed it upstream, and appended small override scripts to the file
  list it built. `Templates\Templates.hpp` now instead reopens each affected template's
  config class and restates only its `basepath`/`file`/`name` properties, pointing them at
  a genuine copy (`cp`, not retyped) of that template's own script under
  `Templates\Templates\` - the same pattern used by community "extender" mods for
  Antistasi Ultimate (e.g. [A3UExtender](https://github.com/Westalgie/A3UExtender)).
  Antistasi's own `fn_initVarServer.sqf` and `A3A_fnc_compatibilityLoadFaction` read
  `basepath`/`file` directly off the template's config class and are completely
  unmodified - no copy of either exists in this mod any more.
  - `fn_compatibilityLoadFaction.sqf`, `fn_SAEF_flagOverride.sqf`,
    `fn_SAEF_vehicleCostOverride.sqf`, and `fn_SAEF_titanToNLAW.sqf` are removed.
  - **Fixes a real bug in the process:** the old `fn_SAEF_vehicleCostOverride.sqf` was
    appended to *both* AAF's and NATO's file lists (one shared script did both factions'
    pricing), and its NATO-only roster changes (Apache attack heli, Little Bird transport
    heli, Blackfish removal) ran unconditionally regardless of which one was actually
    loading - AAF ended up flying NATO's Chinooks. Since each of the three templates below
    now has its own separate, self-contained copy, that whole class of bug is structurally
    impossible: there is no shared script for one faction's change to leak into another's.

- **Scope narrowed to Altis only.** `Aegis_NATO_Temperate` and `Aegis_NATO_Tropical` are
  not reopened in `Templates.hpp` and have no copy in this mod at all - they keep loading
  Aegis's own, completely unmodified originals. This integration only plays AAF
  (Occupants) and NATO Arid (Invaders) on Altis; extending any of the changes below to
  another map/climate means copying that climate's file the same way - and re-deriving its
  pricing/roster block from that file's own actual classnames, per the fix above.

### Added (now baked directly into the copied template files)

- **SAEF rebel identity** - `Templates\Templates\Aegis_Reb_FIA.sqf` (copy of Antistasi's
  own `Aegis_Reb_FIA.sqf`). Puts the SAEF logo on the `Aegis_FIA` rebel template in three
  places: the faction-select preview (`Templates.hpp` config merge), the in-game flagpole
  texture, and the strategic map marker (`CfgMarkers.hpp`, unchanged). Everything else
  about the faction is exactly as Antistasi's original defines it.

- **Planes removed entirely for AAF and NATO Arid** -
  `Templates\Templates\Aegis_AI_AAF.sqf` and `Aegis_AI_NATO_Arid.sqf` (copies).
  `vehiclesPlanesCAS`, `vehiclesPlanesAA`, and `vehiclesPlanesTransport` are set to `[]`
  for both factions, so neither ever spawns a jet, CAS plane, or transport plane. Each
  original array is preserved as a commented-out line immediately above its empty
  replacement, and the matching `attributesVehicles` price entries for those classnames
  are commented out alongside them, since a price for a classname that can never spawn
  does nothing.

- **Full AAF / NATO Arid air fleet re-pricing (non-plane air)** -
  `Templates\Templates\Aegis_AI_AAF.sqf` and `Aegis_AI_NATO_Arid.sqf` (copies). Every
  remaining air category for both factions - attack helis, transport helis, attack UAVs,
  even the unarmed scout heli - is priced via `A3A_vehicleResourceCosts` at roughly
  4x-12x the vanilla Antistasi default per category. Nothing is removed here; a typical
  QRF/attack resource pool affords at most one such vehicle, so attack helis appear
  occasionally instead of being spammed. Scoped to `Aegis_AAF` and `Aegis_NATO_Arid`
  only - `Aegis_NATO_Temperate`/`Aegis_NATO_Tropical` classnames are not interchangeable
  with Arid's, this mod has no copy of either file, and both are untouched.
  - **Full roster coverage, not just the categories being changed.** Every vehicle either
    file's own script can actually field on Altis and that has *some* default cost to
    re-price - cross-checked directly against each file's vehicle roster arrays, including
    DLC-conditional additions - now has an explicit `attributesVehicles` entry.
    `I_A_Truck_02_aa_lxWS` (AAF, Western Sahara DLC `vehiclesAA`),
    `APC_Wheeled_01_atgm_base_lxWS`/`APC_Wheeled_01_command_base_lxWS` (NATO Arid, Western
    Sahara DLC), and `B_AFV_Wheeled_01_up_cannon_F` (NATO Arid, Tank DLC
    `vehiclesLightTanks`) were the gaps found and added, all at their vanilla Aegis default
    (ground vehicles, not part of the air-pricing pass). Categories with no default cost at
    all (`vehiclesBasic`, `vehiclesMedical`, `staticMGs`, `uavsPortable`, ...) are correctly
    still omitted - `A3A_vehicleResourceCosts` silently ignores a price for a classname
    that never had one.

- **NATO Arid roster swaps**, same file: Aegis's own Apache (`Aegis_B_Heli_Attack_03_F`)
  replaces the Blackfoot as NATO's attack heli, and the Little Bird
  (`B_Heli_Light_01_F`) is added as a transport-heli option alongside Ghost Hawk and
  Chinook (this classname is also Arid's own native unarmed-scout class, so it gets one
  price valid for both roles). The Blackfish (`B_T_VTOL_01_infantry_F`) - Arid's only
  default transport plane - isn't swapped for anything; it's covered by the plane
  removal above, so `vehiclesPlanesTransport` is simply empty.

- **Titan-to-NLAW swap** for Aegis AAF and NATO Arid AI - both
  `Templates\Templates\Aegis_AI_*.sqf` copies (`Aegis_AI_AAF.sqf`,
  `Aegis_AI_NATO_Arid.sqf`). No longer carry a guided Titan missile launcher - AT
  role or AA role - and are left with the unguided `NLAW_F` instead. NATO's Temperate/
  Tropical climates and every other faction pack are unaffected - this mod ships no copy
  of either Temperate/Tropical file.
  - Implemented as a shared `#include`d snippet (`SAEF_TitanToNLAW_Swap.sqf`), pasted as
    the last line of both files, run as a post-process over that file's own
    already-generated unit loadouts. Swaps any loadout whose launcher magazine is
    `Titan_AT`, `Titan_AA`, or `Titan_AP` for `launch_NLAW_F` + `NLAW_F`, and renames any
    spare Titan magazines still sitting in a unit's uniform/vest/backpack.
  - Walks the resolved loadout output rather than editing the `missileATLaunchers`/
    `AALaunchers` pools before generation, because each file declares those pools more
    than once (base loadout data, Special Forces, ...) - walking the output afterward
    catches every generated unit type regardless of which pool it came from.
  - Scope: extending it to another faction pack or climate means copying that file the
    same way and adding the same `#include` line at its end - the swap logic itself has
    no Aegis-specific assumptions.
  - **Known tradeoff:** this removes those units' only guided anti-air answer to player
    helicopters, not just a nerf to their AT punch. Worth knowing if the AA half wasn't
    meant to be in scope.

- **Vehicle override check, reading the real applied state** (`saef_toolbox_au_integration`,
  new spawn block in `XEH_postInit.sqf`). Waits for `A3A_core` to fully finish starting up
  (`A3A_startupState == "completed"`), then reads `A3A_vehicleResourceCosts` and both
  `A3A_faction_occ`/`A3A_faction_inv` HashMaps directly - the same live data the AI itself
  spawns from - and logs + broadcasts a `hint` with: each side's actual faction name,
  every jet classname in its roster priced against the real cost table, and its live
  `vehiclesPlanesTransport`/`vehiclesHelisAttack`/`vehiclesHelisTransport` arrays.
  Reporting the faction *name* alongside the arrays is what caught the Arid/Temperate
  mixup above - the hint reported "Aegis NATO Arid", not "Aegis NATO Temperate", proving
  a different template than assumed had actually been loading all along.

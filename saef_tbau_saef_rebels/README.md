# saef_tbau_saef_rebels

> Was the standalone `@SAEF_antistasi_bridge`; now one of the three PBOs in
> `@SAEF_Toolbox_AU_Integration`. Every internal path was rewritten from the
> old prefix `z\SAEF_antistasi\addons\main` to `saef_tbau_saef_rebels` to match
> `$PBOPREFIX$`. Those resolve at load time, not build time, so a stale one
> shows up as a missing flag texture or a `No entry '....icon'` at runtime
> rather than as a build failure. Re-grep if the prefix changes again.
>
> Build with `build.ps1` in the parent folder — it packs all three PBOs.

Overrides the Aegis rebel template's (`Aegis_FIA`)
flag with the group's logo - both the faction-select menu preview and the
actual in-game flag - without duplicating Antistasi's own (300+ line)
template file.

## How it works

Two separate things had to be overridden, because they're two separate data
paths in Antistasi:

1. **Menu preview icon** - the faction-select screen reads
   `getText(_x/"flagTexture")` straight from the template's config class
   (`gui\functions\SetupGUI\fn_setupFactionsTab.sqf`). Fixed with a plain
   config-merge override in `Templates\Templates.hpp`:

   ```cpp
   class Aegis_Base; // forward declaration - real definition lives in Antistasi's core addon
   class Aegis_FIA : Aegis_Base
   {
   	name = "SAEF";
   	flagTexture = "saef_tbau_saef_rebels\Pictures\Markers\SAEF_flag_1024x512.paa";
   };
   ```

2. **Actual in-game flag** - does NOT come from that config property at all.
   `fn_compatibilityLoadFaction.sqf` → `fn_loadFaction.sqf` literally
   `call compile`s whatever `.sqf` file the template points to
   (`Aegis_Reb_FIA.sqf`), and *that script* calls a local `_fnc_saveToTemplate`
   closure to populate `A3A_faction_reb`'s `flagTexture` key - the one every
   flagpole actually reads (`FactionGet(reb,"flagTexture")`). Antistasi's own
   `Aegis_Reb_FIA.sqf` hardcodes `a3\data_f\flags\flag_fia_co.paa` there -
   not even the same file the config class claims.

   Rather than duplicating that whole template file just to change one line
   in it, this overrides the small (~20 line) orchestration function
   `A3A_fnc_compatibilityLoadFaction` instead
   (`Templates\functions\fn_compatibilityLoadFaction.sqf`, registered under
   `CfgFunctions >> A3A >> FunctionsTemplates >> compatibilityLoadFaction`).
   The only change from Antistasi's original: when loading `Aegis_Reb_FIA.sqf`
   specifically, it appends one extra tiny script
   (`fn_SAEF_flagOverride.sqf`) to the file list passed to
   `A3A_fnc_loadFaction`. Every file in that list shares the same
   `_fnc_saveToTemplate` closure and runs in order, so our script - containing
   only:

   ```sqf
   ["flagTexture", "saef_tbau_saef_rebels\Pictures\Markers\SAEF_flag_1024x512.paa"] call _fnc_saveToTemplate;
   ```

   - simply overwrites the one key Antistasi's own template already set,
   leaving literally everything else about the faction (equipment, vehicles,
   loadouts, uniforms, ...) exactly as Antistasi defines it.

3. **Strategic map marker icon** (e.g. the HQ marker) - a third, separate
   data path again. `flag` and `flagMarkerType` (also set via
   `_fnc_saveToTemplate` in Antistasi's own template) are **class names**,
   not texture paths - `flag` is a `CfgVehicles` classname for the physical
   flagpole object model (Antistasi's default, `Flag_FIA_F`, is left alone -
   `flagTexture` above is what re-skins it, not this), and `flagMarkerType`
   is a `CfgMarkers` classname whose own `icon`/`texture` properties are what
   actually get drawn on the map. Pointing `flagMarkerType` straight at a
   `.paa` file (tried first) fails with `No entry '....icon'` - Arma tries to
   look up the file path itself as a class, finds nothing, then fails
   reading `.icon` off of nothing.

   Fixed by defining an actual `CfgMarkers` class (`CfgMarkers.hpp`,
   inheriting from `flag_FIA` - Antistasi's own default marker type for this
   template, so anything else it sets stays intact) and pointing
   `flagMarkerType` at *that class's name*:

   ```cpp
   class CfgMarkers
   {
   	class flag_FIA;
   	class SAEF_flag_marker : flag_FIA
   	{
   		name = "SAEF";
   		icon = "saef_tbau_saef_rebels\Pictures\Markers\SAEF_logo_patch.paa";
   		texture = "saef_tbau_saef_rebels\Pictures\Markers\SAEF_logo_patch.paa";
   	};
   };
   ```

   ```sqf
   ["flagMarkerType", "SAEF_flag_marker"] call _fnc_saveToTemplate;
   ```

   This uses a *different* asset than the flagpole - `SAEF_logo_patch.paa`,
   the oval patch artwork, not the flat 2:1 `SAEF_flag_1024x512.paa`. Vanilla
   flag markers give their content transparent breathing room rather than
   filling the icon canvas edge-to-edge, so anything cropped flush looks
   disproportionate next to them on the map.

   The patch source (`Downloads\SAEF Pictures\SAEF_logo_patch.png`) is a
   512x512 canvas with the artwork scaled to 480x480 and centred, giving a
   16px transparent margin on all four sides. Both dimensions have to stay
   power-of-2 for a `.paa`, which is why the margin is made by insetting the
   artwork rather than by growing the canvas.

   Both `.paa` files exist and are compiled. If either is regenerated from its
   `.png`, convert it with Arma 3 Tools' ImageToPAA or
   https://paa.gruppe-adler.de/ and keep the filename — `CfgMarkers.hpp` and
   `Templates.hpp` reference them by name.

## Maintenance cost

`fn_compatibilityLoadFaction.sqf` is a **frozen copy of Antistasi's own
function**, with Antistasi-internal macros stripped (no
`script_component.hpp`, no `FIX_LINE_NUMBERS()`, `Info_2(...)` replaced with
plain `diag_log`) and two small additions (the file-list append covered
above, and the Titan-to-NLAW swap covered below). If Antistasi changes this
function's own logic upstream, this copy needs manual re-syncing. This is a
much smaller and more stable surface than duplicating a whole per-faction
template file, though: `compatibilityLoadFaction` is generic orchestration
plumbing shared by every faction template, not per-faction gameplay content,
so it changes far less often than something like `Aegis_Reb_FIA.sqf` itself
would.

**Scope (flag override):** only covers `Aegis_FIA`. Antistasi ships dozens
of other Reb-side templates across other faction packs (Vanilla, CUP, RHS,
CSLA, VN, ...) that this doesn't touch - though extending it to another
template is just one more `if (_file find "...") then { ... };` line in
`fn_compatibilityLoadFaction.sqf`, no further file duplication needed.

## Titan-to-NLAW swap (AAF garrison, NATO invasion)

A second, unrelated override in the same function, added for balance rather
than branding: Antistasi's Aegis pack hands `Aegis_AI_AAF.sqf` and the three
`Aegis_AI_NATO_*` climate files a guided, fire-and-forget Titan missile
launcher - both the AT role (`Titan_AT`) and the AA role (`Titan_AA`) - in
addition to the unguided `NLAW_F` the AT role already carries in a separate
pool. This drops every Titan variant and leaves those units with just the
NLAW. No other faction pack is touched.

**Why this isn't a file-list append like the flag override above:** those
templates build their launcher options in a `private _loadoutData` that only
exists inside that template file's own execution - every file in
`A3A_fnc_loadFaction`'s list runs in its own sibling scope, so an appended
file can't see another file's `private` variables. Only the shared
`_fnc_saveToTemplate` closure crosses that boundary, and launcher pools never
go through it - they're consumed locally and turned into concrete unit
loadouts (weapon + magazine already picked) before the template file
returns.

So this doesn't touch the pool at all. It runs *after*
`A3A_fnc_loadFaction` returns, once `A3A_fnc_loadout_builder` has already
resolved every unit type's loadouts, and walks that result
(`fn_SAEF_titanToNLAW.sqf`): for every generated loadout of every unit type
in the faction, if the launcher slot's magazine is any of `Titan_AT` /
`Titan_AA` / `Titan_AP`, the whole weapon array is replaced with
`launch_NLAW_F` + `NLAW_F`; any spare Titan magazines still sitting in that
unit's uniform/vest/backpack are renamed to `NLAW_F` in place. HashMaps and
arrays are reference types in SQF, so mutating them here is visible in the
faction data `compatibilityLoadFaction` registers right afterward - no
re-save needed.

**Scope:** `Aegis_AI_AAF.sqf`, `Aegis_AI_NATO_Arid.sqf`,
`Aegis_AI_NATO_Temperate.sqf`, `Aegis_AI_NATO_Tropical.sqf` only, matched by
filename in `fn_compatibilityLoadFaction.sqf`. Extending it to another
faction pack is one more filename in the `_titanToNLAWFiles` array there -
`fn_SAEF_titanToNLAW.sqf` itself is generic (it looks for any Titan magazine
class in already-built loadouts, not anything specific to Aegis).

Dropping `Titan_AA` this broadly means these units genuinely lose their only
guided anti-air answer to player helicopters, not just a nerf to it - worth
knowing since that's a bigger balance swing than the AT-only version was.

## File layout

```
saef_tbau_saef_rebels/
├── $PBOPREFIX$                                   saef_tbau_saef_rebels
├── config.cpp
├── CfgMarkers.hpp                                SAEF_flag_marker (map icon class)
├── Templates/
│   ├── Templates.hpp                             Aegis_FIA menu-preview override
│   └── functions/
│       ├── fn_compatibilityLoadFaction.sqf       function override (in-game flag fix + Titan/NLAW swap)
│       ├── fn_SAEF_flagOverride.sqf              tiny snippet it injects (flag)
│       └── fn_SAEF_titanToNLAW.sqf               loadout post-process it calls (Titan -> NLAW)
└── Pictures/
    └── Markers/
        ├── SAEF_flag_1024x512.paa                flagpole texture (flat, 2:1)
        └── SAEF_logo_patch.paa                   map marker icon (512x512, padded)
```

## Requirements

- `A3A_core` (Antistasi Ultimate itself) - declared in `requiredAddons`. If
  this isn't present/loaded, Arma refuses to load this addon entirely.
- Both `.paa` files under `Pictures\Markers\` (already present and compiled).

**This PBO has to be on the clients.** Unlike its two siblings in this mod
folder it is not server-side: `flagTexture` paths are resolved by whichever
machine renders the flagpole, and `flagMarkerType` names a `CfgMarkers` class
that the client looks up when drawing the strategic map. A player without it
sees the vanilla FIA flag and fails the marker lookup. This is why
`@SAEF_Toolbox_AU_Integration` now goes in the player preset.

## Building

`build.ps1` in the parent folder, which packs all three PBOs of
`@SAEF_Toolbox_AU_Integration` with FileBank. FileBank packs the folder
wholesale, so the `.paa` files and the `.hpp` files pulled in by `#include`
come along with no include list.

The old standalone routes (VSCode Arma Dev extension, or Addon Builder with
`Files = *.hpp;*.sqf;*.paa`) still work if you ever split this back out - just
set the prefix to `saef_tbau_saef_rebels`, matching `$PBOPREFIX$` exactly.

## Testing

Load this alongside Antistasi Ultimate on a local/dev server.

- Faction-select screen: `Aegis_FIA` should show as "SAEF" with the group's
  flag as its preview icon.
- In a running mission (both New and Continue): the HQ flag and a captured
  base's flagpole should show the group's flag, not the vanilla FIA flag
  Antistasi's own script actually applies by default.
- The strategic map's HQ marker icon should also show the group's flag, not
  the default `flag_FIA` marker.
- Confirm any *other* rebel template still behaves normally - this override
  is intentionally scoped to `Aegis_FIA` only.

For the Titan-to-NLAW swap: spawn or inspect an AT-role and an AA-role unit
from Aegis AAF or one of the NATO climate templates and confirm their
launcher/inventory shows `NLAW_F` rather than `Titan_AT`/`Titan_AA`/`Titan_AP`.
Confirm a faction pack outside the scoped list is unaffected.

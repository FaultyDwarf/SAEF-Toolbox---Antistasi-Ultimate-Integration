# saef_tbau_saef_rebels

> Was the standalone `@SAEF_antistasi_bridge`; now one of the four PBOs in
> `@SAEF_Toolbox_AU_Integration`. Every internal path was rewritten from the
> old prefix `z\SAEF_antistasi\addons\main` to `saef_tbau_saef_rebels` to match
> `$PBOPREFIX$`. Those resolve at load time, not build time, so a stale one
> shows up as a missing flag texture, a `No entry '....icon'`, or a faction
> silently loading Aegis's unmodified defaults at runtime - not as a build
> failure. Re-grep if the prefix changes again.
>
> Build with `build.ps1` in the parent folder - it packs all four PBOs.

Ships modified **copies** of three of Antistasi's own Aegis faction template
scripts, and points each one's `basepath`/`file` config properties at our copy
instead of the original - the same pattern used by community "extender" mods
for Antistasi Ultimate (see
[github.com/Westalgie/A3UExtender](https://github.com/Westalgie/A3UExtender)).
Antistasi's own template-loading code is completely unmodified; it just ends
up loading our file instead of Aegis's for these three templates.

| Template | What's changed | Copy |
|---|---|---|
| `Aegis_FIA` (Rebels) | SAEF name/flag/map-marker branding | `Aegis_Reb_FIA.sqf` |
| `Aegis_AAF` (Occupants) | display name ("SAEF AAF"), air fleet re-pricing, Titan-to-NLAW | `Aegis_AI_AAF.sqf` |
| `Aegis_NATO_Arid` (Invaders) | display name ("SAEF NATO"), air fleet re-pricing, roster swaps, Titan-to-NLAW | `Aegis_AI_NATO_Arid.sqf` |

**`Aegis_NATO_Arid`, not `Aegis_NATO_Temperate` - despite the name.** This
integration's actual Invaders template on Altis is `Aegis_NATO_Arid`,
confirmed directly from the server RPT via the
`saef_toolbox_au_integration` postInit check (see Testing below), which
reports the real faction name that loaded. `Aegis_NATO_Temperate`'s name
strongly suggests it's the Altis one - it isn't. Whichever NATO template is
actually being used is worth re-confirming with that same check any time the
setup screen's faction pick changes, rather than assumed from a template's
name.

**Altis-only scope, on purpose.** `Aegis_NATO_Temperate` and
`Aegis_NATO_Tropical` are deliberately *not* reopened in `Templates.hpp` and
have no copy in this mod - they keep loading Aegis's own, completely
unmodified originals (Titan launchers, default pricing, and all). Extending
any of this to another map/climate means copying that climate's file the same
way and reopening its class in `Templates.hpp` - see "classnames are not
interchangeable between climates" below before assuming another climate's
file can just be copied verbatim.

Everything else about each faction (equipment, vehicles, loadouts not listed
above) is left exactly as that copy's own upstream original defines it - each
`.sqf` under `Templates\Templates\` is a genuine copy (`cp`, not retyped) of
the matching file in `A3A_core`, so a diff against Antistasi's own source
shows only the lines this mod actually touches.

## How it works

`fn_initVarServer.sqf` (Antistasi's own, completely untouched) resolves which
script to load for a template with:

```sqf
private _basepath = getText (_cfg/"basepath") + "\";
private _file = getText (_cfg/"file") + ".sqf";
[_basepath + _file, _side] call A3A_fnc_compatibilityLoadFaction;
```

`_cfg` is the template's own config class (`configFile >> "A3A" >>
"Templates" >> "Aegis_AAF"`, for example) - whatever it was picked as at
setup. `Templates\Templates.hpp` reopens each of the three template classes
above and restates only `basepath`/`file`/`name` (plus `flagTexture` for
`Aegis_FIA`'s menu preview - see below):

```cpp
class Aegis_AAF : Aegis_Base
{
	name = "SAEF AAF";
	basepath = "saef_tbau_saef_rebels\Templates\Templates";
	file = "Aegis_AI_AAF";
};
```

Reopening a class by name like this is a config **merge**: because only
`name`/`basepath`/`file`/`flagTexture` are restated, every other property
(`side`, `climate`, `maps`, `description`, `requiredAddons`, ...) is inherited
unchanged from Antistasi's own definition. This requires `A3A_core` to
already be loaded when this config parses - guaranteed by
`requiredAddons[] = {"A3A_core"}` in `config.cpp`.
`A3A_fnc_compatibilityLoadFaction` itself - the function that actually turns
`_file` into a loaded faction - is Antistasi's own, unmodified: no copy of it
exists in this mod at all.

### SAEF rebel identity (three separate data paths)

Two properties matter for `Aegis_FIA`, because they're two separate data
paths in Antistasi:

1. **Menu preview icon** - the faction-select screen reads
   `getText(_x/"flagTexture")` straight from the template's config class
   (`gui\functions\SetupGUI\fn_setupFactionsTab.sqf`). `name`/`flagTexture`
   in `Templates.hpp` cover this.
2. **Actual in-game flag and strategic map marker** - come from the script
   itself, not that config property. `A3A_faction_reb`'s `flagTexture` key -
   the one every flagpole actually reads (`FactionGet(reb,"flagTexture")`) -
   and `flagMarkerType` - the `CfgMarkers` class name the strategic map looks
   up for the HQ marker - are both set inside `Aegis_Reb_FIA.sqf` itself, by
   the exact same four lines Antistasi's own copy has, just pointed at the
   SAEF assets instead:

   ```sqf
   ["name", "SAEF"] call _fnc_saveToTemplate;
   ["flag", "Flag_FIA_F"] call _fnc_saveToTemplate;
   ["flagTexture", "saef_tbau_saef_rebels\Pictures\Markers\SAEF_flag_1024x512.paa"] call _fnc_saveToTemplate;
   ["flagMarkerType", "SAEF_flag_marker"] call _fnc_saveToTemplate;
   ```

   `flag` (the flagpole model itself, `Flag_FIA_F`) is left as Antistasi's
   default - only the texture painted on it changes. `flagMarkerType` names a
   `CfgMarkers` class rather than a texture path directly - pointing it
   straight at a `.paa` fails with `No entry '....icon'`, because Arma tries
   to look up the file path itself as a class and finds nothing. Fixed the
   same way as before: `CfgMarkers.hpp` defines `SAEF_flag_marker`, inheriting
   from `flag_FIA` (Antistasi's own default marker type for this template) so
   anything else it sets stays intact:

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

   This uses a *different* asset than the flagpole - `SAEF_logo_patch.paa`,
   the oval patch artwork, not the flat 2:1 `SAEF_flag_1024x512.paa`. Vanilla
   flag markers give their content transparent breathing room rather than
   filling the icon canvas edge-to-edge, so anything cropped flush looks
   disproportionate next to them on the map. The patch source
   (`Downloads\SAEF Pictures\SAEF_logo_patch.png`) is a 512x512 canvas with
   the artwork scaled to 480x480 and centred, giving a 16px transparent
   margin on all four sides - both dimensions have to stay power-of-2 for a
   `.paa`, which is why the margin is made by insetting the artwork rather
   than by growing the canvas. Both `.paa` files exist and are compiled; if
   either is regenerated from its `.png`, convert it with Arma 3 Tools'
   ImageToPAA or https://paa.gruppe-adler.de/ and keep the filename -
   `CfgMarkers.hpp` and `Templates.hpp` reference them by name.

**Scope:** only `Aegis_FIA` gets branding. Antistasi ships dozens of other
Reb-side templates across other faction packs (Vanilla, CUP, RHS, CSLA, VN,
...) that this doesn't touch - extending it to another template means copying
that template's own script the same way this one was copied.

### AAF / NATO Arid vehicle re-pricing

`Aegis_AI_AAF.sqf` and `Aegis_AI_NATO_Arid.sqf` each get one extra
`["attributesVehicles", [...]] call _fnc_saveToTemplate;` block, inserted
right after that file's own `#include "Aegis_Vehicle_Attributes.sqf"` line.
Nothing later in either file sets `attributesVehicles` again, so this block is
simply the value that key ends up with - no more "append a script and let a
HashMap `set` overwrite whatever came before" needed, since it's now just
regular code living directly where the original set it.

Raising a vehicle's cost via `A3A_vehicleResourceCosts` doesn't make it any
tougher; it makes the enemy AI afford fewer of it per resource pool, and
drains the pool faster whenever it does send one, delaying its next
QRF/attack. Every non-plane air category is priced (attack helis, transport
helis, attack UAV, even the unarmed scout heli) at roughly 4x-12x the vanilla
Antistasi default per category, so a typical QRF/attack resource pool
(~100-200 per unit of budget via `A3A_balanceVehicleCost`) affords at most one
such vehicle - attack helis show up occasionally instead of being spammed.
Fixed-wing planes are handled differently - see "Planes removed entirely"
below - and ground vehicle pricing is untouched from Aegis's own defaults.

**Planes removed entirely, not priced.** `vehiclesPlanesCAS`,
`vehiclesPlanesAA`, and `vehiclesPlanesTransport` are set to empty arrays for
both `Aegis_AAF` and `Aegis_NATO_Arid` - no fixed-wing aircraft of any kind
spawns for either faction. Each original array is preserved as a commented-out
line immediately above its empty replacement, and the matching
`attributesVehicles` price entries for those classnames are commented out too
(a price for a classname that can never spawn does nothing, so leaving them
active would just be confusing). Restoring plane support for a faction means
uncommenting both the roster array's original content and its price entries.

**Scope:** `Aegis_AAF` and `Aegis_NATO_Arid` only - the two templates this
integration actually plays on Altis. Not extended to `Aegis_NATO_Temperate`/
`Aegis_NATO_Tropical` - this mod has no copy of either file at all (see
"Altis-only scope" above), and their classnames are not interchangeable with
Arid's regardless (see below). Copying and pricing one of those two files the
same way is how to extend this further.

**Classnames are not interchangeable between NATO's climate files - this bit
the first pass at this override.** `Aegis_AI_NATO_Arid.sqf` uses the plain,
unprefixed Aegis/vanilla vehicle classes throughout (`B_MRAP_01_gmg_F`,
`B_MBT_01_cannon_F`, `B_Heli_Attack_01_dynamicLoadout_F`, ...); the
`Aegis_AI_NATO_Temperate.sqf` this mod targeted before the Arid/Temperate mixup
was caught uses `"B_W_"`-prefixed reskins for nearly everything instead
(`B_W_MRAP_01_gmg_F`, `B_W_MBT_01_cannon_F`, ...). Beyond the prefix, the
actual rosters differ too: Arid has no Atlas transport plane in its default
roster at all (only the Blackfish), two `uavsAttack` classes instead of three,
and its Western Sahara DLC variants use a different suffix pattern entirely
(`APC_Wheeled_01_command_base_lxWS` vs Temperate's
`B_W_APC_Wheeled_01_command_lxWS`). Every classname in `Aegis_AI_NATO_Arid.sqf`
was re-derived directly from that file's own roster arrays, not copied over
from the Temperate work - see its own header comment for the full breakdown.

**Every vehicle in AAF's and NATO Arid's actual Altis roster that can be
priced at all now has an explicit entry.** `A3A_vehicleResourceCosts` only
re-prices a classname that already has *some* default cost - quadbikes,
static MGs, and ammo/repair/fuel/medical trucks have none and are silently
ignored if priced, so those categories are correctly omitted. Within the
categories that do have a default cost, every classname either template's own
script can actually put in that category - including the ones only added
conditionally, when a specific DLC is enabled - is listed, cross-checked
directly against each file's own vehicle roster arrays:

- AAF: `I_A_Truck_02_aa_lxWS` (`vehiclesAA`, Western Sahara DLC only).
- NATO Arid: `APC_Wheeled_01_atgm_base_lxWS` (`vehiclesAPCs`) and
  `APC_Wheeled_01_command_base_lxWS` (`vehiclesLightAPCs`), both Western
  Sahara DLC only; `B_AFV_Wheeled_01_up_cannon_F` (`vehiclesLightTanks`,
  Tank DLC only - Arid gates this variant behind a DLC check, unlike
  Temperate which includes it unconditionally).

All of these are priced at their vanilla Aegis default (unchanged) rather
than pushed up like the air categories - they're ground vehicles, same as
every other "unchanged" entry below. `uavsPortable`, `vehiclesAirborne`, and
`vehiclesMilitiaAPCs`/`vehiclesMilitiaLightArmed`/etc. aren't in the priceable
category list either (not one of the tiered buckets `fn_initVarServer.sqf`
seeds `A3A_vehicleResourceCosts` from), so classnames that only ever appear in
those categories need no entry - anything in them that's *also* listed under a
priceable category is already covered by that one shared classname-keyed
price.

### NATO Arid roster changes

Two more `_fnc_saveToTemplate` calls, same file, right after the pricing
block above - `attributesVehicles` only re-prices a classname already present
in a faction's category array, it can't add or remove one from a role:

- Replaces the Blackfoot (`B_Heli_Attack_01_dynamicLoadout_F`) with Aegis's
  own Apache (`Aegis_B_Heli_Attack_03_F`) as NATO's attack heli.
- Adds the Little Bird (`B_Heli_Light_01_F`) as a transport-heli option
  alongside Ghost Hawk (`B_Heli_Transport_01_F`) and Chinook
  (`B_Heli_Transport_03_F`/`_unarmed_F`, Heli DLC only). `B_Heli_Light_01_F`
  is *also* Arid's own native `vehiclesHelisLight` (unarmed scout) class - the
  same physical vehicle plays both roles, so it gets one single price (280)
  valid for either.

The Blackfish (`B_T_VTOL_01_infantry_F`), Arid's only default transport
plane, isn't swapped for anything - see "Planes removed entirely" above;
`vehiclesPlanesTransport` is simply empty.

**A note on where these classnames came from:** the Apache and the plain
Little Bird/Ghost Hawk/Chinook aren't in Aegis's own default Arid template,
but they're real, valid, spawnable classes built into the Aegis mod itself
(`air_f_aegis.pbo`) - confirmed by derapping that PBO with Arma 3 Tools'
BankRev + CfgConvert rather than trusting the template scripts alone. No new
`requiredAddons` entry was needed in `config.cpp` as a result - Aegis is
already a hard dependency of this whole integration.

**Why the old "AAF flying NATO Chinooks" bug can't happen here.** An earlier
version of this override (when it still targeted Temperate) lived in a script
appended to *both* AAF's and NATO's file lists (since one shared script did
both factions' pricing), and its NATO-only roster changes ran unconditionally
every time - including while AAF loaded - silently overwriting AAF's own
roster with NATO's classnames. That whole class of bug is structurally
impossible here: this code lives directly inside NATO Arid's own file, and
each faction's `A3A_fnc_loadFaction` call gets its own separate, independent
data store. There is no shared script for a roster change made in one
faction's file to leak into another's.

### Titan-to-NLAW swap (both AI templates)

`SAEF_TitanToNLAW_Swap.sqf` is `#include`d as the last line of both
`Aegis_AI_*.sqf` copies (not `Aegis_Reb_FIA.sqf` - Rebels aren't touched by
this). It swaps every Titan missile (AT, AA, AP) already baked into that
faction's generated loadouts for the unguided NLAW. Titan_AA is included
deliberately - these units end up with no guided anti-air answer to player
helicopters at all, not just a nerfed AT loadout.

This walks the *already-generated* loadouts (the same `_allLoadouts` HashMap
`_fnc_generateAndSaveUnitsToTemplate` writes into, visible here for the same
reason `_fnc_saveToTemplate` is - see the file's own header comment) rather
than editing `missileATLaunchers`/`AALaunchers` before generation, because
each of these files defines that pool more than once - once for the base
loadout data, again separately for Special Forces, and other variants
(Elite, Military, ...) inherit whichever pool they were copied from. Editing
every such pool by hand is easy to under-cover; walking the resolved output
after every unit type has been generated instead catches all of them
uniformly, regardless of which pool variant a given unit came from. This part
of the file is genuinely identical between AAF and NATO Arid - unlike vehicle
pricing, the loadout array *shape* (not the classnames inside it) is what
this code depends on, and that shape is shared across every Aegis template.

Every local in `SAEF_TitanToNLAW_Swap.sqf` is `_SAEF_`-prefixed on purpose:
unlike the old `call compile`d append, `#include` is a textual paste into the
*same* top-level scope as the rest of the ~1500-line file it's spliced into,
so a generic name really could collide with something the surrounding file
already declared.

**Scope:** both `Aegis_AI_*.sqf` copies (AAF, NATO Arid). Extending it to
another faction pack or climate means copying that file the same way and
adding the same `#include` line at its end - the swap logic itself has no
Aegis-specific assumptions.

Dropping `Titan_AA` this broadly means these units genuinely lose their only
guided anti-air answer to player helicopters, not just a nerf to it - worth
knowing since that's a bigger balance swing than an AT-only version would be.

## File layout

```
saef_tbau_saef_rebels/
├── $PBOPREFIX$                                   saef_tbau_saef_rebels
├── config.cpp
├── CfgMarkers.hpp                                SAEF_flag_marker (map icon class)
├── Templates/
│   ├── Templates.hpp                             basepath/file/name overrides, three templates (Altis only)
│   └── Templates/
│       ├── Aegis_Reb_FIA.sqf                     copy + SAEF flag/marker
│       ├── Aegis_Reb_Vehicle_Attributes.sqf      copy, #included unmodified by Aegis_Reb_FIA.sqf
│       ├── Aegis_AI_AAF.sqf                      copy + vehicle pricing + Titan swap
│       ├── Aegis_AI_NATO_Arid.sqf                copy + vehicle pricing + roster swaps + Titan swap
│       ├── Aegis_Vehicle_Attributes.sqf          copy, #included unmodified by AAF/NATO Arid
│       └── SAEF_TitanToNLAW_Swap.sqf             shared #include, both Aegis_AI_*.sqf
└── Pictures/
    └── Markers/
        ├── SAEF_flag_1024x512.paa                flagpole texture (flat, 2:1)
        └── SAEF_logo_patch.paa                   map marker icon (512x512, padded)
```

## Maintenance cost

Each `.sqf` under `Templates\Templates\` is a genuine copy of an Antistasi
core file, not a duplicate someone hand-typed - re-copying (`cp`, not
retyping) and re-applying the diff shown by this README is the way to pick up
an Antistasi update. `git diff` against a fresh copy of the corresponding
`x\A3A\addons\core\Templates\Templates\Aegis\*.sqf` file will show exactly
what changed upstream and exactly what this mod changed, since both are
visible in the same file. This trades a smaller number of larger files (three
full template copies) for zero dependency on `A3A_fnc_compatibilityLoadFaction`'s
own internals - the previous approach needed re-syncing whenever Antistasi
changed that orchestration function; this approach only needs re-syncing when
Antistasi changes one of these three *template* files specifically, which is
normal per-faction content that changes independently of core plumbing.

**Copying a template means copying its `#include`d siblings too, not just the
file itself.** `Aegis_Reb_FIA.sqf` pulls in `Aegis_Reb_Vehicle_Attributes.sqf`
(vehicle purchase costs for Rebels, unrelated to SAEF branding and left
unmodified here) via two `#include`s of its own; `Aegis_AI_AAF.sqf` and
`Aegis_AI_NATO_Arid.sqf` each pull in `Aegis_Vehicle_Attributes.sqf` the same
way. Missing one doesn't fail at copy time or at build time - `build.ps1`
packs whatever files exist with no complaint, since FileBank never opens or
preprocesses them - it fails at **mission start**, server-side, with
`Include file ... not found` immediately followed by `Application terminated
intentionally`, because Arma's preprocessor only resolves `#include` when the
template actually loads. Before trusting a new or re-copied template file,
verify every `#include` it has actually resolves, without needing a live
server: `grep -n "#include" <file>.sqf` to see what it needs, confirm each
target exists alongside it, then run the same preprocessor Arma itself uses
against the file directly:

```powershell
& "<Arma 3 Tools install>\CfgConvert\CfgConvert.exe" -pcpp -dst out.txt <file>.sqf
```

Exit code `0` plus checking `out.txt` actually contains the included content
(not just an empty/short file) confirms every `#include` chain resolves - this
is the only step in the workflow that catches a missing sibling file before a
live server does.

**Don't assume a template's name tells you its climate, map, or classname
prefix - verify against the actual template that loads.** `Aegis_NATO_Arid`
turned out to be this integration's real Altis Invaders template despite
`Aegis_NATO_Temperate` sounding like the obvious pick, and Arid's own
classnames turned out to have no `"B_W_"` prefix at all - both assumptions
this mod got wrong on the first pass. The `saef_toolbox_au_integration`
postInit check (see Testing below) reports the real faction name and its live
roster arrays directly from the server; treat that as ground truth over
whatever a template's name or a neighbouring template's classnames suggest.

## Requirements

- `A3A_core` (Antistasi Ultimate itself) - declared in `requiredAddons`. If
  this isn't present/loaded, Arma refuses to load this addon entirely.
- Both `.paa` files under `Pictures\Markers\` (already present and compiled).

**This PBO has to be on the clients.** Unlike its siblings in this mod folder
it is not server-side: `flagTexture` paths are resolved by whichever machine
renders the flagpole, and `flagMarkerType` names a `CfgMarkers` class that the
client looks up when drawing the strategic map. A player without it sees the
vanilla FIA flag and fails the marker lookup - and, for AAF/NATO, gets
Aegis's unmodified vehicle pricing/roster/Titan behaviour instead of this
mod's, since template loading itself is client-relevant wherever that client
needs faction data (AI logic is server-authoritative, but a mismatched client
copy of this PBO is still a stale/incorrect install worth avoiding). This is
why `@SAEF_Toolbox_AU_Integration` goes in the player preset.

## Building

`build.ps1` in the parent folder, which packs all four PBOs of
`@SAEF_Toolbox_AU_Integration` with FileBank. FileBank packs the folder
wholesale, so the `.paa` files, the `.hpp` files pulled in by `#include`, and
every `.sqf` under `Templates\Templates\` come along with no include list.

The old standalone routes (VSCode Arma Dev extension, or Addon Builder with
`Files = *.hpp;*.sqf;*.paa`) still work if you ever split this back out - just
set the prefix to `saef_tbau_saef_rebels`, matching `$PBOPREFIX$` exactly.

## Testing

Load this alongside Antistasi Ultimate on a local/dev server, with `Aegis_FIA`
selected as Rebels, `Aegis_AAF` as Occupants, and `Aegis_NATO_Arid` as
Invaders.

- Faction-select screen: `Aegis_FIA` should show as "SAEF" with the group's
  flag as its preview icon; `Aegis_AAF`/`Aegis_NATO_Arid` should show as
  "SAEF AAF"/"SAEF NATO".
- In a running mission (both New and Continue): the HQ flag and a captured
  base's flagpole should show the group's flag, not the vanilla FIA flag.
- The strategic map's HQ marker icon should also show the group's flag, not
  the default `flag_FIA` marker.
- Confirm any *other* rebel template still behaves normally - this override
  is intentionally scoped to `Aegis_FIA` only.

For the vehicle re-pricing and roster changes, **trust the postInit check, not
manual inspection**: `saef_toolbox_au_integration\XEH_postInit.sqf` waits for
`A3A_core` to fully finish, then reads `A3A_vehicleResourceCosts` and both
`A3A_faction_occ`/`A3A_faction_inv` directly - the same live data the AI
spawns from - and logs + broadcasts a hint at mission start. Watch
server.rpt (or the broadcast hint, if locally hosted) for the
`[SAEF_TBAU] Occupants (...)` / `[SAEF_TBAU] Invaders (...)` lines and
confirm:

- The reported faction **name** is actually `Aegis AAF` / `Aegis NATO Arid` -
  if it instead reads something else (`Aegis NATO Temperate`, in particular),
  a different faction pack was picked at setup and none of this mod's changes
  apply to that side. This is the check that caught this mod initially
  targeting the wrong NATO climate - trust it over any name-based assumption.
- The `jets` list is empty for both sides - planes are removed entirely, not
  priced, so none should appear in this report at all. In a running mission,
  neither AAF nor NATO Invaders should ever be seen using a fixed-wing
  aircraft of any kind.
- `vehiclesPlanesTransport` is empty for both sides for the same reason.
- `vehiclesHelisAttack`/`vehiclesHelisTransport` for Occupants (AAF) list
  AAF's own classnames, never NATO's Apache/Chinook/Ghost Hawk/Little Bird -
  in a running mission, AAF garrisons should never be seen flying a Chinook.

In a running mission the practical signal for pricing is indirect -
fewer/rarer heavy air and MBT spawns per QRF/attack wave over a play session -
so the postInit check is much easier to confirm by than observation alone.

For the Titan-to-NLAW swap: spawn or inspect an AT-role and an AA-role unit
from AAF or NATO Arid and confirm their launcher/inventory shows `NLAW_F`
rather than `Titan_AT`/`Titan_AA`/`Titan_AP`. Confirm NATO's Temperate/
Tropical climates and any faction pack outside this mod's three copies are
unaffected - Temperate/Tropical should still show the original guided Titan
launchers, since this mod ships no copy of either file.

# Changelog

All notable changes to `@SAEF_Toolbox_AU_Integration` are recorded here.

## Unreleased

### Added

- **Titan-to-NLAW swap** for Aegis AAF and NATO AI (`saef_tbau_saef_rebels`). AI generated
  from `Aegis_AI_AAF.sqf`, `Aegis_AI_NATO_Arid.sqf`, `Aegis_AI_NATO_Temperate.sqf` and
  `Aegis_AI_NATO_Tropical.sqf` no longer carry a guided Titan missile launcher — AT role
  or AA role — and are left with the unguided `NLAW_F` instead. No other faction pack is
  affected.
  - Implemented as a post-process over each faction's already-resolved unit loadouts
    (`fn_SAEF_titanToNLAW.sqf`), called from the existing
    `fn_compatibilityLoadFaction.sqf` override right after `A3A_fnc_loadFaction` returns.
    Swaps any loadout whose launcher magazine is `Titan_AT`, `Titan_AA`, or `Titan_AP` for
    `launch_NLAW_F` + `NLAW_F`, and renames any spare Titan magazines still sitting in a
    unit's uniform/vest/backpack.
  - Scope is deliberately narrow: extending it to another faction pack is one filename
    added to the `_titanToNLAWFiles` array in `fn_compatibilityLoadFaction.sqf` — the swap
    logic itself has no Aegis-specific assumptions.
  - **Known tradeoff:** this removes those units' only guided anti-air answer to player
    helicopters, not just a nerf to their AT punch. Worth knowing if the AA half wasn't
    meant to be in scope.

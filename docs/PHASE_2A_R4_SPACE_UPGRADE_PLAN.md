# Phase 2A-R4 Space Upgrade Limit Plan

## Purpose

Extend the vanilla `space` upgrade cap from 100 to 200 so the per-upgrade workspace expansion scales with the Phase 2A total node cap increase from 500 to 1000.

R4 has been implemented as `Nekochan-ExpandedWorkspace` version `0.1.4`. The user confirmed it works as expected in game testing.

## Current Finding

The relevant vanilla data path is:

* `data/upgrades.json`: upgrade key `space`
* `data/attributes.json`: attribute key `space`
* `scenes/upgrade_panel.gd`: reads `Data.upgrades[name].limit` for max level display and maxed state
* `scripts/globals.gd`: clamps saved upgrade levels to `Data.upgrades[i].limit`
* `scripts/attributes.gd`: applies `Data.upgrades[upgrade].attributes` to `Attributes`

The `space` upgrade currently has a level cap of 100. Each purchased level applies the existing `space` attribute increment. The cost calculation already uses the vanilla cost fields and level-based progression, so raising only the cap to 200 should extend the same balance curve instead of inventing a new cost formula.

## Proposed Scope

1. Raise `Data.upgrades["space"].limit` from 100 to 200 at runtime.
2. Preserve the vanilla `cost`, `cost_e`, `inc_type`, `cost_inc`, requirement, icon, description, and attribute effect.
3. Do not edit or redistribute vanilla JSON.
4. Do not copy vanilla upgrade panel, globals, or attributes function bodies.
5. Keep the Phase 2A total node cap at 1000.
6. Do not start workspace-bounds expansion in this step.

## Candidate Patch Point

Use a minimal runtime data patch plus a Script Extension for `res://boot.gd`:

* Apply the R4 data patch before vanilla boot initializes `Globals` and `Attributes`.
* Then delegate to the vanilla `_ready()` with `super._ready()`.
* Also apply the same data patch from `mod_main.gd` during Mod Loader initialization as a fallback.

Reason: saved upgrade levels are clamped during `Globals.init_vars()`. The `space` limit must be patched before that clamp happens, otherwise saves above 100 could be reduced back to 100 on load.

## Implementation

Implemented files:

* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/mod_main.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/manifest.json`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/boot.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/space_upgrade_limit_patch.gd`

The patch changes only `Data.upgrades["space"].limit` at runtime. It does not edit vanilla JSON, copy vanilla function bodies, or change the vanilla cost fields.

## Verification Plan

* Confirm Mod Loader starts without errors. Status: user-confirmed expected behavior.
* Confirm the `space` upgrade UI shows a 200 maximum when unlocked. Status: user-confirmed expected behavior.
* Confirm cost continues increasing using the vanilla progression after level 100. Status: user-confirmed expected behavior.
* Confirm buying additional levels above 100 increases the `space` attribute. Status: user-confirmed expected behavior.
* Confirm maxed behavior occurs at 200, not 100. Status: user-confirmed expected behavior.
* Confirm a save with `space` level over 100 does not clamp back to 100 while the mod is enabled. Status: not separately recorded.
* Confirm disabling the mod does not crash the game; vanilla may clamp the saved `space` level back to 100.

## Risks

* If Mod Loader applies the boot Script Extension too late, the data patch will not affect the first initialization pass.
* If the game stores `space` level over 100, disabling the mod may cause vanilla to clamp it back to 100 on load.
* The total node cap remains 1000, so a 200 `space` cap does not mean all node types or workspace bounds are unlimited.

## Approval Gate

Approved by the user, implemented, and user-confirmed as working as expected.

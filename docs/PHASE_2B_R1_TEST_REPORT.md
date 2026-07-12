# Phase 2B-R1 Test Report

## Status

`CRITICAL_FAILURE_ROLLED_BACK`

## Scope

Phase 2B-R1 is the first local test candidate for a fixed `20000 x 20000` desktop workspace area.

## Implemented

* Mod version updated to `0.2.0`.
* Shared workspace constants added.
* Desktop camera bounds patched to target `20000`.
* Default desktop center patched to `10000, 10000` on initial setup.
* Normal node drag bounds patched to `0..20000`.
* Connector custom point bounds patched to `0..20000`.
* Paint background patched to cover the expanded area.
* Lines/grid rendering scaled by `2x` to cover the expanded area without copying the large vanilla rendering body.

## User Test Result For 0.2.0

Confirmed working:

* Camera can move by drag operation.
* When zoomed in enough, the visible grid area is expanded.

Failed:

* Nodes placed in the vanilla area cannot be moved into the expanded area. They still feel blocked by the old area wall.
* Clicking a node in the palette while the camera is in the expanded area places it at the boundary between the vanilla area and the expanded area, not at the current camera center.
* When zoomed out, the expanded area does not visually match the vanilla placeable area. The expanded area looks like it is not part of the placeable workspace.

## User Test Result For 0.2.1

Critical failure. The user reported:

* Nodes cannot be placed.
* Nodes cannot be moved because they cannot be selected.
* Existing save nodes all gather in the upper-left area.
* Connections between gathered nodes are all detached.
* Existing node levels are reset.
* Node upgrade costs become `1`, which is not a valid normal cost.

## Interpretation

Camera bounds and scaled grid rendering are taking effect.

Node instance position clamping is still using a vanilla path. The first R1 patch targeted `window_container.gd`, but actual node scenes commonly instantiate `window_base.tscn` and then attach concrete scripts extending `WindowIndexed` / `WindowBase`. The fix candidate is to add the same minimal `get_position_snapped(to)` override to `window_base.gd` and `window_indexed.gd`.

The zoomed-out visual issue is explained by `Desktop/Background` and `Desktop/Connectors` still having `10000` size in the scene tree. The fix candidate is to resize those Desktop child controls to `20000`.

## Phase 2B-R2 Fix Candidate

Implemented as local version `0.2.1`, but failed critically in game testing.

Additional files:

* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/windows/window_base.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/windows/window_indexed.gd`

Updated files:

* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/desktop.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/mod_main.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/manifest.json`

R2 status: `CRITICAL_FAILURE_ROLLED_BACK`

## Rollback

The deployed game mod was rolled back to `Nekochan-ExpandedWorkspace-0.1.4.zip`.

After rollback, the user confirmed that node placement works again.

The existing nodes from the affected save were gone. The user explicitly said this does not need to be fixed.

The local source registration was also rolled back to the Phase 2A-R4 stable script-extension set:

* `windows_tab.gd`
* `window_dragger.gd`
* `desktop.gd`
* `schematics_tab.gd`
* `boot.gd`
* `space_upgrade_limit_patch.gd`

The Phase 2B area-expansion extensions remain in the workspace for analysis, but they are not registered by `mod_main.gd`.

## Safety Instruction

Do not re-enable or package versions `0.2.0` or `0.2.1`.

Do not continue area expansion by extending `window_base.gd` / `window_indexed.gd` Script Extensions. That path appears capable of breaking node initialization, saved node state, selection, connections, and upgrade cost state.

Do not attempt save recovery for the lost nodes unless the user explicitly asks for it.

## Implemented Files

* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/main_2d.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/windows/window_container.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/connector_point.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/lines.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/paint.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/mod_main.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/manifest.json`

## Known R1 Limitations

* Template/schematic paste may still be clamped by vanilla paste internals.
* Group window movement/resizing may still be clamped by vanilla group bounds.
* Grid/background is scaled to cover the expanded area, not regenerated at original density.

## Manual Verification Checklist

Do not continue this checklist against `0.2.0` or `0.2.1`.

1. Start game and confirm Mod Loader loads the rolled-back stable `ExpandedWorkspace v0.1.4`.
2. Confirm ordinary node placement works again.
3. Confirm no `0.2.x` zip is present in the live game `mods` folder.
4. If area expansion work resumes later, create a new checklist from a new plan and use a disposable test save.

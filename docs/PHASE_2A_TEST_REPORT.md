# Phase 2A Test Report

## Status

`LIMIT_RELAXATION_COMPLETE_USER_VERIFIED`

## Scope

Phase 2A attempts to raise the Upload Labs total workspace node placement limit from the vanilla 500-node restriction to a practical expanded cap.

## Latest In-Game Result

Phase 2A-R2 allowed placing more than 500 nodes through normal manual placement.

Phase 2A-R3 has been implemented to address template/schematic placement over 500 nodes.

Phase 2A-R3 has been implemented to display the expanded 1000-node cap in the node palette.

User testing confirmed that the three R3 target paths work in game:

* Normal manual placement can exceed 500 total nodes.
* Template/schematic placement can exceed the vanilla 500-node boundary.
* The node-count display no longer remains capped at 500 for the tested path.

Phase 2A-R4 `space` upgrade cap 100 -> 200 was also confirmed by the user as working as expected.

## Interpretation

Phase 2A-R3 may be treated as user-verified for the core placement paths listed above. Phase 2A-R4 may be treated as user-verified for the intended `space` upgrade limit expansion.

It is acceptable to describe the current node-count and `space` upgrade limit relaxation goal as complete for the local development milestone. Do not describe the whole Expanded Workspace mod as complete until workspace-bounds behavior, large-save behavior, performance, and configuration UI are also validated.

## Verified So Far

* Manual placement can exceed 500 nodes.
* Template/schematic placement can exceed the vanilla 500-node boundary.
* The node-count UI shows the expanded cap for the tested path.
* The `space` upgrade cap can be expanded from 100 to 200 and behaves as expected in user testing.

## Known Issues / Pending Verification

* Save/reload with very large node counts has not yet been separately recorded as verified.
* Workspace bounds, camera, grid, and configuration UI remain out of scope for Phase 2A.

## Static Reanalysis

The 500-node global limit is not enforced by `Utils.can_add_window()`. That function handles per-window limits and attribute requirements.

The total limit is enforced in multiple paths, including manual placement, template/schematic paste, and UI display logic. Phase 2A-R2 covered manual placement paths. Phase 2A-R3 adds minimal wrappers for template/schematic paste and display logic.

## Phase 2A-R3 Implementation

The publish-unsafe Script Extension files were removed from the working tree and replaced with minimal Script Extension candidates:

* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/mod_main.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/windows_tab.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/window_dragger.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/desktop.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/schematics_tab.gd`

This candidate targets manual placement, template/schematic paste, and user-facing count display. It does not cover workspace bounds, camera, grid, save schema, or configuration UI.

## Phase 2A-R4 Implementation

Phase 2A-R4 adds a minimal runtime data patch for the vanilla `space` upgrade limit:

* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/boot.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/space_upgrade_limit_patch.gd`

The R4 target is to raise the `space` upgrade cap from 100 to 200 while preserving the vanilla cost progression.

The user confirmed that R4 works as expected.

## Verification Status

Manual 501+ placement was confirmed by user testing after installing `Nekochan-ExpandedWorkspace-0.1.2.zip`.

`Nekochan-ExpandedWorkspace-0.1.3.zip` was tested by the user for the three core R3 paths.

Remaining tests are now part of later workspace-area and large-save validation, not the current limit-relaxation milestone.

## Next Verification Step

Investigate workspace area expansion before implementation. Do not start the area patch until patch points and risks are documented.

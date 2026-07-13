# Phase 2C-F2 v0.2.10 Regression Analysis

Status: `FAILED_VERIFICATION_REGRESSION`

## User Verification Result

The user tested `Nekochan-ExpandedWorkspace-0.2.10.zip` with only this Mod installed.

- Position persistence: `FAIL`
- Deselection behavior: `REGRESSION OBSERVED`
- Release state: `BLOCKED`
- v0.2.10 status: failed development artifact evidence only

v0.2.10 must not be treated as a Release Candidate. Do not create a GitHub Release, Draft Release, tag, Steam Workshop upload, or replacement artifact from this result.

## Runtime Delta From v0.2.9

Runtime file delta count: `3`

Changed runtime files:

- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/manifest.json`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/mod_main.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/windows/window_container.gd`

Runtime delta:

- manifest version changed from `0.2.9` to `0.2.10`
- manifest description changed only
- dependencies unchanged: `[]`
- no manifest load-order dependency was added
- added Script Extension registration: `extensions/scenes/windows/window_container.gd`
- no Script Extension was removed from the v0.2.9 runtime set
- registration order changed only by inserting `window_container.gd` after `window_dragger.gd` and before `window_group.gd`

Packaged v0.2.10 extension set:

- `extensions/boot.gd`
- `extensions/scenes/window_dragger.gd`
- `extensions/scenes/windows/window_container.gd`
- `extensions/scenes/windows/window_group.gd`
- `extensions/scripts/desktop.gd`
- `extensions/scripts/lines.gd`
- `extensions/scripts/main_2d.gd`
- `extensions/scripts/paint.gd`
- `extensions/scripts/schematics_tab.gd`
- `extensions/scripts/space_upgrade_limit_patch.gd`
- `extensions/scripts/windows_tab.gd`
- `extensions/scripts/workspace_area_config.gd`

Local ignored/stale extension files under `mod/source/.../extensions` are not tracked and were not packaged by `tools/build_release.ps1`.

## Script Extension Semantics Recheck

Bundled Godot Mod Loader v7.0.1 implementation was rechecked locally:

- `_ModLoaderScriptExtension.apply_extension(extension_path)` loads the child script, reloads it, reads its base script, stores script history, logs the installation, and calls `child_script.take_over_path(parent_script_path)`.
- A child method without `super()` fully replaces the inherited method for instances that are actually using the replaced script chain.
- `handle_script_extensions()` applies registered extension paths and then calls `_reload_vanilla_child_classes_for(script)`.
- `_reload_vanilla_child_classes_for(script)` finds the global class whose path matches the replaced base script and reloads direct global child classes whose `base` equals that class name.
- `WindowContainer` is a global class. `WindowBase` directly extends `WindowContainer`; `WindowIndexed` extends `WindowBase`; most concrete node scripts extend `WindowIndexed`.

Important implication:

The loader does not visibly perform a recursive reload of all grandchildren and concrete descendants in `script_extension.gd`. Therefore a base-class Script Extension can be installed and logged while still not reliably changing already-loaded or concrete descendant script behavior. This is consistent with the earlier v0.2.6 result where a `window_container.gd` extension was installed but did not change active existing-node movement.

No useful official documentation evidence was captured in this pass; this analysis uses the bundled v7.0.1 implementation as the source of truth.

## Position Persistence Analysis

Confirmed fact:

- Vanilla `WindowContainer._ready()` runs a post-load initialization clamp by assigning `global_position = get_position_snapped(global_position)`.
- Vanilla `WindowContainer.get_position_snapped(to)` clamps against the old `10000` workspace bounds.
- Restored save data reaches `WindowContainer.load(data)` before the node enters the scene tree.

Rejected repair hypothesis:

- The v0.2.10 hypothesis that overriding only `WindowContainer.get_position_snapped(to)` is sufficient is rejected by user verification.

Classification: `ROOT_CAUSE_PARTIAL`

Rationale:

- The old-bound post-load clamp remains a valid candidate failure mechanism.
- The chosen patch point did not correct the user-visible persisted position.
- Evidence now points to either an ineffective base-class extension for concrete restored windows, or another post-load clamp/correction after the inspected `_ready()` call.
- The next step must prove method invocation and coordinate checkpoints before another patch is selected.

## get_position_snapped Call Sites

Call-site classification: `GLOBAL_WINDOW_BEHAVIOR`

Window call sites:

- `WindowContainer._ready()` uses `get_position_snapped(global_position)` during initialization.
- `WindowContainer.move_snapped(to)` uses `get_position_snapped(to)` during movement.
- `WindowContainer._on_drag_selection(from, to)` reaches `move_snapped(...)` for selected-node movement.

Separate connector call sites:

- `connector_point.gd` has its own `get_position_snapped(to)` and movement path.
- v0.2.10 did not add or package a connector-point runtime change.

Impact:

- A reliable `WindowContainer.get_position_snapped(to)` replacement would be broader than a load-only persistence fix because it affects initialization and active movement paths.
- The observed result shows the patch was not a safe narrow restoration-only fix.

## Deselection Regression Analysis

Observed user regression:

- Empty-area click no longer clears selected nodes.
- The `x` close/cancel control in the node state/options menu also does not clear selected nodes.

Relevant vanilla paths:

- Empty-area mouse release reaches `camera_2d.gd`, which calls `Globals.set_selection([], [])` when there is a current selection.
- The options-bar cancel path also calls `Globals.set_selection([], [])`.
- `Globals.set_selection(selection, connectors)` replaces the global arrays and emits `Signals.selection_set`.
- `WindowContainer._on_selection_set()` updates each window's `selected` flag and drag-selection signal connections.
- `window_group.gd::_on_selection_set()` calls `super()` and then updates group-specific selection UI state.

The two user-observed failure entries share the same endpoint, so this is unlikely to be only an empty-area input routing problem. If the options-bar `x` invokes its cancel path and the visual selection remains, the failure is more likely around selection signal propagation, listener state, or concrete window selection state after the v0.2.10 base Script Extension.

Classification: `REGRESSION_CAUSE_LIKELY`

Likely cause:

- The only meaningful runtime behavior delta from v0.2.9 is the added `WindowContainer` base Script Extension.
- A base-class Script Extension on a global class can affect class reload and inherited callbacks even though the new method body only overrides `get_position_snapped(to)`.
- Therefore the regression is likely caused by targeting `WindowContainer` globally through Script Extension semantics, not by manifest metadata or docs/tooling changes.

Not yet confirmed:

- Whether `Globals.set_selection([], [])` is actually called in v0.2.10 when the user presses `x`.
- Whether selected concrete windows receive `Signals.selection_set` after the base Script Extension is installed.
- Whether concrete node instances are using the expected script chain after load.

## Same Cause Assessment

The two failures are related by the same v0.2.10 runtime delta: adding the `WindowContainer` Script Extension.

They are not proven to be the same logical code defect:

- Position persistence failure means the intended `get_position_snapped(to)` replacement did not correct restored positions.
- Deselection regression suggests class reload, inherited selection callbacks, or signal listener state was disturbed.

Working assessment: same introduced patch target/mechanism, different observed failure surfaces.

## Diagnostic Evidence Required Before Another Patch

Do not stack a new fix before collecting these checkpoints in a development-only diagnostic build:

1. Log whether `WindowContainer.get_position_snapped(to)` from the Mod extension runs for restored concrete windows.
2. Log the restored window position immediately after `WindowContainer.load(data)`.
3. Log the position immediately before and after the post-load `_ready()` clamp point.
4. Log the final position after the node is visible in the scene tree.
5. For deselection, log one user action through:
   - empty-area click or options-bar cancel
   - `Globals.set_selection([], [])`
   - `Signals.selection_set.emit()`
   - `WindowContainer._on_selection_set()` on the selected concrete window
   - final `Globals.selections.size()`

Keep any diagnostic logging low-frequency and remove it before a Release Candidate.

## Narrower Patch Candidates

Candidate A: restoration-path-only correction in `desktop.gd`

- Capture the saved window position from the load dictionary.
- Let vanilla instantiate, load, and enter the tree.
- After vanilla initialization, reapply only that restored position through expanded bounds.
- Limit scope to windows restored from save data.
- Do not touch active movement, placement, selection, or `WindowContainer` globally.

Candidate B: deferred post-load correction

- Use a load-only deferred correction after the node has completed `_ready()`.
- Apply only if the saved coordinate was outside old bounds but inside expanded bounds.
- Avoid a global `get_position_snapped(to)` replacement.

Candidate C: diagnostic-only `WindowContainer` probe

- Use only if necessary to prove the extension does or does not reach concrete restored windows.
- Do not ship as a Release Candidate path.

Preferred next direction:

Use Candidate A or a diagnostic build that proves Candidate A's exact insertion point. Avoid another global `WindowContainer.get_position_snapped(to)` replacement as the release fix path unless method invocation is conclusively proven and the deselection regression is explained.

## Release Handling

- v0.2.9 Draft Release remains blocked and must not be published.
- v0.2.9 artifact remains unchanged failed-RC evidence.
- v0.2.10 artifact remains failed development evidence.
- Do not create `0.2.11`, a new tag, a new artifact, or a GitHub Release from this analysis.

# Phase 2B-R3 Safe Redesign Plan

## Status

`APPROVED_STAGE_0_PARTIAL_STAGE_1_SELECTED`

## Purpose

Restart workspace-area expansion after the failed `0.2.0` and `0.2.1` attempts, without risking the current stable `0.1.4` limit-relaxation build or the user's normal save data.

The target remains a first expanded area of `20000 x 20000`, but R3 must be treated as a staged safety redesign, not a direct continuation of R1/R2.

## Current Safe Baseline

The safe deployed behavior is `0.1.4`:

* total placed node cap: `500 -> 1000`
* `space` upgrade cap: `100 -> 200`
* ordinary node placement works again after rollback
* affected old save nodes were lost, and the user explicitly said save recovery is not required

Do not spend work on recovering the lost save unless the user asks for save recovery later.

## Hard Rules

* Do not re-enable or package `0.2.0` or `0.2.1`.
* Do not directly extend `scenes/windows/window_base.gd`.
* Do not directly extend `scenes/windows/window_indexed.gd`.
* Do not test area-expansion candidates on the user's normal active save.
* Do not combine multiple new area-expansion patches in the first canary.
* Do not claim Phase 2B is complete until placement, movement, template paste, connector points, save/load, visuals, and logs all pass.

## Main Design Change From R1/R2

R1/R2 tried to make several area systems coherent at once. That made it hard to isolate which patch broke state.

R3 changes the method:

1. Prove the stable baseline is loaded.
2. Use a disposable test save.
3. Add only one small patch group at a time.
4. Inspect `modloader.log` after each launch.
5. Keep every failed candidate out of the live `mods` folder before the next test.

The highest-risk category is any Script Extension attached to common loaded node scene roots. Those scripts can affect save restore, selection, connection state, node level state, and upgrade cost state. R3 avoids that category unless a separate isolated proof demonstrates safety.

## Stage 0: Baseline Safety Check

Goal: prove the current test environment starts from the known-good `0.1.4` state.

Actions:

1. Confirm the live game `mods` folder contains only the stable `Nekochan-ExpandedWorkspace-0.1.4.zip`.
2. Confirm no failed `0.2.x` zip is live.
3. Back up current Upload Labs save/config files before any new test.
4. Create or select a disposable test save slot.
5. Launch the game once and confirm ordinary placement still works.
6. Read `modloader.log` and record the loaded mod version.

Required result before moving on:

* `0.1.4` loads.
* ordinary node placement works.
* no `0.2.x` candidate is live.
* disposable test save is ready.

## Stage 1: Static Route Review

Goal: decide the next patch target from code paths before writing new implementation.

Review these paths:

* camera area limit: `scripts/main_2d.gd`
* visual area coverage: `scripts/lines.gd`, `scripts/paint.gd`
* click placement entry: `scripts/windows_tab.gd`
* drag placement entry: `scenes/window_dragger.gd`
* template paste entry: `scripts/desktop.gd`
* connector point bounds: `scenes/connector_point.gd`
* node movement bounds: `scenes/windows/window_container.gd`
* group bounds: `scenes/windows/window_group.gd`

Explicitly excluded from the next implementation:

* `scenes/windows/window_base.gd`
* `scenes/windows/window_indexed.gd`

Deliverable:

* update this plan with the selected first canary target before code is changed.

## Stage 2: Canary A - Camera And Visuals Only

Goal: verify that expanding the visible/camera area does not corrupt node state.

Candidate version:

* `0.2.2-camera-visual-canary`

Allowed patch targets:

* `scripts/main_2d.gd`
* `scripts/lines.gd`
* `scripts/paint.gd`

Disallowed in this stage:

* node movement clamp changes
* click placement changes
* drag placement changes
* paste changes
* connector changes
* any `window_base.gd` / `window_indexed.gd` changes

Manual verification:

1. Load the disposable save.
2. Confirm existing test nodes are not moved, reset, or disconnected.
3. Confirm ordinary placement still works inside the vanilla area.
4. Confirm camera movement can reach beyond the old `10000` boundary.
5. Confirm zoomed-out background/grid coverage does not obviously end at the old boundary.
6. Inspect `modloader.log`.

Go / no-go:

* If node state changes, rollback immediately and do not continue.
* If only visual coverage is imperfect but node state is safe, record the visual issue and continue planning.

## Stage 3: Canary B - One Placement Entry Only

Goal: prove one new-node placement path can target the expanded area without touching loaded node base classes.

Candidate version:

* `0.2.4-click-placement-canary`

Selected first patch target:

* `scripts/windows_tab.gd`

Reason:

* This is already used by the stable Phase 2A node-count relaxation.
* The click placement path places a new node at `Globals.camera_center`.
* It is the smallest new-placement path and does not require mouse coordinate conversion.
* It is an entry path for newly created nodes, not a common save-loaded node base class.

Deferred from this canary:

* `scenes/window_dragger.gd`
* `scripts/desktop.gd`
* `scenes/connector_point.gd`
* `scenes/windows/window_container.gd`
* `scenes/windows/window_group.gd`
* `scenes/windows/window_base.gd`
* `scenes/windows/window_indexed.gd`

Observed code constraint:

* `scripts/windows_tab.gd` creates a window at `Globals.camera_center`.
* `scenes/windows/window_container.gd::_ready()` immediately calls `get_position_snapped(global_position)`, which clamps to the vanilla `10000` area.
* Therefore, even click-created nodes may snap back to the old boundary unless the new target position is restored after vanilla `_ready()` finishes.

Proposed approach:

* Keep the existing Phase 2A count-limit wrapper.
* For click placement only, compute the intended expanded-area target from `Globals.camera_center - window.size / 2`.
* Emit the normal `Signals.create_window` path so vanilla initialization still runs.
* Connect only the newly created window instance to a one-shot post-initialization/deferred callback.
* In that callback, move only that newly created instance to the intended expanded target using `move(target)` or direct `global_position`.
* Do not change the movement clamp for existing nodes.
* Do not alter save-loaded nodes.

Design constraint:

* If expanded placement cannot be achieved from these entry paths without copying large vanilla function bodies or touching node base classes, stop and report the blocker.

Manual verification:

1. Use the current game-start save, per the user's decision.
2. Back up save/config before deployment.
3. Start with camera centered in the expanded area beyond the old boundary.
4. Click a node in the node palette to place it at screen/camera center.
5. Confirm the new node appears in the expanded area instead of the old boundary.
6. Confirm existing nodes are not moved, reset, disconnected, or level-reset.
7. Confirm ordinary placement still works inside the vanilla area.
8. Inspect `modloader.log`.

Go / no-go:

* If existing node state changes, rollback immediately.
* If placement remains clamped but state is safe, record it as a functional failure and do not escalate to base-class patches.
* If click placement succeeds, plan the next isolated canary for drag placement separately.

Approval gate:

* User approved this Stage 3 canary plan.

Implemented canary:

* version: `0.2.4`
* package: `mod/build/Nekochan-ExpandedWorkspace-0.2.4.zip`
* live package: `E:\SteamLibrary\steamapps\common\Upload Labs\mods\Nekochan-ExpandedWorkspace-0.2.4.zip`
* save/config backup: `C:\tmp\upload-labs-save-backups\20260712-115349`
* profile backup: `C:\tmp\upload-labs-save-backups\20260712-115349\mod_user_profiles.before-0.2.4-20260712-115535.json`

`0.2.4` implementation details:

* `extensions/scripts/windows_tab.gd` now overrides `add_window(window)`.
* The override computes an expanded-area target from `Globals.camera_center - window.size / 2`.
* It still emits the normal `Signals.create_window` path.
* After vanilla initialization, only the newly created instance is restored to the expanded-area target by deferred `move(target)`.
* Existing nodes are not touched.
* Save-loaded nodes are not touched.
* Drag placement, template paste, connector points, and node movement are not expanded in this canary.

Packaged allowlist:

* `manifest.json`
* `mod_main.gd`
* `extensions/boot.gd`
* `extensions/scripts/space_upgrade_limit_patch.gd`
* `extensions/scripts/windows_tab.gd`
* `extensions/scenes/window_dragger.gd`
* `extensions/scripts/desktop.gd`
* `extensions/scripts/schematics_tab.gd`
* `extensions/scripts/workspace_area_config.gd`
* `extensions/scripts/main_2d.gd`
* `extensions/scripts/lines.gd`
* `extensions/scripts/paint.gd`

Explicitly not packaged:

* `extensions/scenes/windows/window_container.gd`
* `extensions/scenes/windows/window_base.gd`
* `extensions/scenes/windows/window_indexed.gd`
* `extensions/scenes/connector_point.gd`

Retest focus:

1. Restart the game and confirm it loads `ExpandedWorkspace v0.2.4`.
2. Confirm existing nodes remain intact.
3. Confirm ordinary placement still works in the old area.
4. Move camera into the expanded area.
5. Click a node in the node palette to place it at the camera center.
6. Confirm the newly clicked node appears in the expanded area instead of being forced to the old boundary.
7. Do not expect drag placement, moving existing nodes, template paste, or connector points to work in the expanded area yet.

User test result for `0.2.4`:

* Click placement into the expanded area works.
* The clicked node appears slightly up-left of the expected target, but the user does not consider this a major issue.
* No other problems were reported.

Current Phase 2B-R3 status:

* `STAGE_3_CLICK_PLACEMENT_VERIFIED_WITH_MINOR_OFFSET`

Known minor issue:

* Click placement target alignment needs a small offset review before final release polish.
* Do not treat this as a blocker for continuing to the next isolated canary.

Next stage candidate:

* Plan a separate drag-placement canary.
* Keep existing-node movement, template paste, connector points, and base/indexed/window-container patches deferred.

## Stage 3C: Canary C - Drag Placement Only

Goal: prove the drag-from-palette placement path can target the expanded area without changing loaded node movement behavior.

Candidate version:

* `0.2.5-drag-placement-canary`

Selected patch target:

* `scenes/window_dragger.gd`

Reason:

* This path is already used by the stable Phase 2A total-node limit relaxation.
* It creates a new node from the temporary drag placer.
* It does not need to modify save-loaded existing nodes.
* It is separate from click placement and should remain a separate canary because it uses mouse/screen-to-world coordinate conversion.

Deferred from this canary:

* `scripts/windows_tab.gd` target-offset polish
* `scripts/desktop.gd`
* `scenes/connector_point.gd`
* `scenes/windows/window_container.gd`
* `scenes/windows/window_group.gd`
* `scenes/windows/window_base.gd`
* `scenes/windows/window_indexed.gd`

Observed code constraint:

* `scenes/window_dragger.gd::place()` calculates `instance_pos` from `Utils.screen_to_world_pos(global_position + size / 2)`.
* It sets the new instance position before emitting `Signals.create_window`.
* `scenes/windows/window_container.gd::_ready()` still clamps the new node to the vanilla `10000` area during initialization.

Proposed approach:

* Keep the existing Phase 2A count-limit wrapper in `window_dragger.gd`.
* Replace the `super.place()` path only when the drag target is outside the vanilla area or when the total-count wrapper is needed.
* Compute the intended expanded target with the same vanilla formula, then clamp to `WorkspaceAreaConfig.get_max_position(instance.size)`.
* Emit the normal `Signals.create_window` path.
* After vanilla initialization, restore only the newly created instance to the intended drag target with deferred `move(target)`.
* Do not change the movement clamp for existing nodes.
* Do not alter save-loaded nodes.
* Do not change click placement behavior except leaving the existing `0.2.4` result intact.

Manual verification:

1. Back up save/config before deployment.
2. Restart the game and confirm it loads `ExpandedWorkspace v0.2.5`.
3. Confirm existing nodes remain intact.
4. Confirm click placement still works as in `0.2.4`.
5. Drag a node from the palette and release it in the expanded area.
6. Confirm the newly dragged node appears near the release location instead of the old boundary.
7. Confirm ordinary old-area drag placement still works.
8. Do not expect moving existing nodes, template paste, or connector points to work in the expanded area yet.
9. Inspect `modloader.log`.

Go / no-go:

* If existing node state changes, rollback immediately.
* If drag placement remains clamped but node state is safe, record it as a functional failure and do not escalate to base-class patches.
* If drag placement succeeds, plan the next isolated canary for existing-node movement as a research gate.

Approval gate:

* Approved by user instruction: "進めてください".
* `0.2.5` implementation is limited to `extensions/scenes/window_dragger.gd`.
* Current status: `STAGE_3C_DRAG_PLACEMENT_VERIFIED`.
* Live test zip: `Nekochan-ExpandedWorkspace-0.2.5.zip`.
* Pre-deployment backups:
  * profile backup directory: `C:\tmp\upload-labs-save-backups\20260712-123849`
  * previous live mod backup: `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.2.4-before-0.2.5-20260712-123849.zip`
* User verification result: drag placement can now place a node on the expanded-area side.

Implemented behavior:

* Keep the vanilla `super.place()` path for ordinary old-area drag placement while below the vanilla total count.
* Use the modded path when the dragged target is outside the vanilla area or when the current total count is at/above the vanilla 500 limit and below the modded 1000 limit.
* Restore only the newly created dragged instance to the intended expanded-area target after vanilla initialization.
* Leave existing-node movement, template/schematic paste, connector points, and base/indexed/window-container patches untouched.

## Stage 4: Movement Bounds Research Gate

Goal: solve moving existing nodes into the expanded area without repeating the `0.2.1` failure.

Known problem:

* `window_container.gd` alone was not enough in R1.
* `window_base.gd` / `window_indexed.gd` caused critical breakage in R2.

Allowed next work:

* inspect scene inheritance and movement call sites
* identify whether there is a non-base-class movement controller or drag endpoint that can be safely patched
* create a minimal isolated proof only after the route is identified

Stop condition:

* If the only apparent solution is direct base-class extension or copying large vanilla movement loops, stop and ask for a design decision before implementation.

### Stage 4A: Canary D - Existing Node Movement Only

Research result:

* Existing single-node drag uses `scenes/windows/window_container.gd::handle_drag_input()`.
* Multi-selection drag uses `Signals.drag_selection` and each selected window's `window_container.gd::_on_drag_selection()`.
* Both paths call `move_snapped(to)`.
* `move_snapped(to)` delegates the boundary decision to `get_position_snapped(to)`.
* The vanilla `get_position_snapped(to)` clamps to the `10000` workspace.
* `window_base.gd` and `window_indexed.gd` do not define their own movement clamp. They inherit the movement method from `WindowContainer`.

Candidate version:

* `0.2.6-existing-node-movement-canary`

Selected patch target:

* `scenes/windows/window_container.gd`

Strictly excluded:

* `scenes/windows/window_base.gd`
* `scenes/windows/window_indexed.gd`
* `scenes/windows/window_group.gd`
* `scenes/connector_point.gd`
* `scripts/desktop.gd` paste bounds

Proposed approach:

* Register only the existing minimal `window_container.gd` Script Extension.
* Override only `get_position_snapped(to)`.
* Clamp against `WorkspaceAreaConfig.get_max_position(size)` and keep the vanilla `snappedf(50)` grid behavior.
* Do not override `_ready()`, `load()`, `save()`, `move()`, `move_snapped()`, `handle_drag_input()`, selection methods, or initialization methods.
* Do not package the old `window_base.gd` / `window_indexed.gd` R2 files.

Why this is different from the failed `0.2.1`:

* `0.2.1` extended `window_base.gd` and `window_indexed.gd` directly and caused critical saved-node state breakage.
* This canary does not touch those base/indexed scripts.
* Click placement and drag placement already restore new nodes after vanilla initialization in `0.2.4` / `0.2.5`, so this canary only tests the existing-node movement clamp.

Expected result:

* Existing nodes can be dragged from the old area into the expanded area.
* Multi-selected nodes should move together into the expanded area if they share the same `WindowContainer` movement path.

Not expected in this canary:

* Template/schematic paste into the expanded area.
* Connector custom-point movement into the expanded area.
* Group window movement/resizing into the expanded area.
* Click-placement offset polish.

Manual verification:

1. Back up save/config and the current `0.2.5` zip before deployment.
2. Restart the game and confirm it loads `ExpandedWorkspace v0.2.6`.
3. Confirm existing nodes are still present, selectable, connected, and preserve levels/costs.
4. Drag one existing node from the old area into the expanded area.
5. Confirm the node stays in the expanded area instead of stopping at the old boundary.
6. Select multiple nodes and drag them toward the expanded area.
7. Confirm click placement and drag-from-palette placement still work as verified in `0.2.4` / `0.2.5`.
8. Inspect `modloader.log`.

Go / no-go:

* If nodes become unselectable, lose state, lose connections, or move to the top-left, rollback immediately.
* If movement is still clamped but node state is safe, record `0.2.6` as a functional failure and do not escalate to `window_base.gd` / `window_indexed.gd`.
* If single-node movement succeeds but multi-select fails, keep the build as a partial result and plan a separate multi-selection canary.

Approval gate:

* Approved by user instruction: "承認します。進んでください".
* `0.2.6` implementation is limited to `extensions/scenes/windows/window_container.gd` registration.
* Current status: `STAGE_4A_FUNCTIONAL_FAILURE_STATE_SAFE`.
* Live test zip: `Nekochan-ExpandedWorkspace-0.2.6.zip`.
* Pre-deployment backups:
  * profile backup directory: `C:\tmp\upload-labs-save-backups\20260712-152221`
  * previous live mod backup: `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.2.5-before-0.2.6-20260712-152221.zip`
* Mod Loader log path: `C:\Users\shian\AppData\Roaming\Upload Labs\logs\modloader.log`

Log evidence:

* `Nekochan-ExpandedWorkspace-0.2.6.zip` was loaded.
* `ExpandedWorkspace v0.2.6` was logged during mod ready.
* `extensions/scenes/windows/window_container.gd` was installed as a Script Extension.

User verification result:

* Existing nodes remained present.
* Selection, connections, levels, and costs were not broken.
* Single existing-node movement into the expanded area failed; it still stops at an invisible old boundary.
* Multi-selection movement into the expanded area failed; it still stops at an invisible old boundary.
* Click placement and drag-from-palette placement remained OK.

Interpretation:

* This is a state-safe functional failure.
* The `window_container.gd` Script Extension was loaded, but overriding `window_container.gd::get_position_snapped(to)` did not affect the actual movement clamp used by existing concrete node scenes.
* Do not escalate to direct `window_base.gd` / `window_indexed.gd` Script Extensions; that path already caused the `0.2.1` critical failure.

### Stage 4B: Canary E - Desktop Selection-Drag Reposition Only

Goal: test whether existing node movement can be expanded from the `Desktop` signal layer, without touching `window_base.gd` or `window_indexed.gd`.

Candidate version:

* `0.2.7-desktop-selection-drag-canary`

Selected patch target:

* `scripts/desktop.gd`

Strictly excluded:

* `scenes/windows/window_base.gd`
* `scenes/windows/window_indexed.gd`
* `scenes/windows/window_group.gd`
* `scenes/connector_point.gd`
* template/schematic paste bounds
* save/load routines

Observed movement signal path:

* Pressing a selectable node calls `Globals.set_selection(...)` before dragging begins.
* Selected node movement emits `Signals.drag_selection(from, to)`.
* Each selected node's vanilla handler clamps itself back to the old `10000` area.
* A `Desktop` Script Extension can also observe `Signals.begin_drag` and `Signals.drag_selection`.

Proposed approach:

* Add a small movement-tracking block to the existing `extensions/scripts/desktop.gd`.
* In `_ready()`, call `super._ready()` first, then connect mod-only handlers to `Signals.begin_drag` and `Signals.drag_selection`.
* On `begin_drag`, record the current `global_position` of `Globals.selections`.
* On `drag_selection(from, to)`, compute `delta = to - from`.
* Use `call_deferred()` to apply the modded movement after vanilla selected-window handlers have run.
* In the deferred handler, move only the recorded selected `WindowContainer` instances to `start_position + delta`, clamped by `WorkspaceAreaConfig.get_max_position(window.size)` and snapped to the 50px grid.
* Use `window.move(target)` rather than `window.move_snapped(target)` so the old vanilla clamp is not re-entered.
* Do not move connector custom points in this canary.

Why this is different from `0.2.6`:

* `0.2.6` attempted to override the inherited movement clamp at `window_container.gd`, but the actual concrete-node movement still used the old boundary.
* `0.2.7` would not rely on overriding the inherited clamp. It would correct selected-window positions from the desktop signal layer after vanilla movement processing.

Expected result:

* Existing selected nodes can move into the expanded area.
* Single-node movement may also work because clicking a node selects it before drag starts.

Known limitation:

* Connector custom points may not follow if they rely on their own `connector_point.gd` clamp. Existing window-to-window connections should visually update when connected windows move, but custom connector points are not a target of this canary.
* Group window movement/resizing is still excluded.
* If a node can be dragged while not selected, that path may remain clamped.

Manual verification:

1. Back up save/config and the current `0.2.6` zip before deployment.
2. Restart the game and confirm it loads `ExpandedWorkspace v0.2.7`.
3. Confirm existing nodes remain present, selectable, connected, and preserve levels/costs.
4. Drag one existing node from the old area into the expanded area.
5. Confirm the node stays in the expanded area instead of stopping at the old boundary.
6. Select multiple normal nodes and drag them toward the expanded area.
7. Confirm click placement and drag-from-palette placement still work.
8. Inspect `modloader.log`.

Go / no-go:

* If nodes become unselectable, lose state, lose connections, lose levels/costs, or jump to the top-left, rollback immediately.
* If movement is still clamped but node state is safe, record `0.2.7` as a functional failure and do not escalate to `window_base.gd` / `window_indexed.gd`.
* If single-node movement succeeds but multi-select or connectors have issues, keep the result scoped and plan the failing part separately.

Approval gate:

* Approved by user instruction: "承認します。進めてください。"
* `0.2.7` implementation is limited to `extensions/scripts/desktop.gd`.
* `0.2.7` deliberately removes the failed `0.2.6` `window_container.gd` registration from the package scope.
* Current status: `STAGE_4B_PARTIAL_VERIFIED_GROUP_MOVEMENT_BLOCKED`.
* Live test zip: `Nekochan-ExpandedWorkspace-0.2.7.zip`.
* Pre-deployment backups:
  * profile backup directory: `C:\tmp\upload-labs-save-backups\20260712-160901`
  * previous live mod backup: `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.2.6-before-0.2.7-20260712-160901.zip`

User verification result:

* Overall `0.2.7` behavior is mostly OK.
* Normal existing-node movement is treated as accepted for this canary.
* New issue: the node used to manage groups of nodes cannot move beyond the old area boundary.

Interpretation:

* The group-management node uses its own concrete script, `scenes/windows/window_group.gd`.
* That script has its own `MAX_BOUNDS = Vector2(10000, 10000)` and clamps movement in its own `_process(delta)` path.
* This explains why the Desktop-level selected-node correction did not cover group-node movement.

### Stage 4C: Canary F - Group Window Movement Only

Goal: allow the group-management node itself to move into the expanded area without touching base/indexed classes or group resizing.

Candidate version:

* `0.2.8-group-window-movement-canary`

Selected patch target:

* `scenes/windows/window_group.gd`

Strictly excluded:

* `scenes/windows/window_base.gd`
* `scenes/windows/window_indexed.gd`
* `scenes/windows/window_container.gd`
* `scenes/connector_point.gd`
* template/schematic paste bounds
* group resizing
* save/load routines

Observed group movement path:

* `window_group.gd` has its own `MAX_BOUNDS = Vector2(10000, 10000)`.
* Its `_process(delta)` handles `moving`, computes `target_pos`, clamps it to `MAX_BOUNDS`, then calls `move_snapped(target_pos)`.
* This movement path does not use the `Signals.drag_selection` correction used by `0.2.7`.

Proposed approach:

* Add a concrete Script Extension for `scenes/windows/window_group.gd`.
* Override `_process(delta)` only.
* Call `super._process(delta)` first so vanilla behavior, button scaling, and non-movement behavior still run.
* If `moving` is true, compute the same drag target from `drag_start_rect.position + (get_global_mouse_position().snappedf(50) - drag_start_mouse)`.
* Clamp that target with `WorkspaceAreaConfig.get_max_position(size)` and snap to 50.
* Apply the corrected position using `move(target_position)` so the old `move_snapped()` clamp is not re-entered.
* Do not modify resize behavior in this canary.

Expected result:

* The group-management node can be moved into the expanded area.
* Existing normal node movement from `0.2.7` remains OK.

Not expected in this canary:

* Group resizing beyond the old boundary.
* Connector custom-point movement.
* Template/schematic paste into expanded area.

Manual verification:

1. Back up save/config and the current `0.2.7` zip before deployment.
2. Restart the game and confirm it loads `ExpandedWorkspace v0.2.8`.
3. Confirm existing nodes remain present, selectable, connected, and preserve levels/costs.
4. Confirm normal existing-node movement still works as in `0.2.7`.
5. Move a group-management node from the old area into the expanded area.
6. Confirm click placement and drag-from-palette placement still work.
7. Inspect `modloader.log`.

Go / no-go:

* If group movement works and normal node state stays safe, record group movement as verified.
* If group movement remains clamped but node state is safe, record `0.2.8` as a functional failure and do not escalate to `window_base.gd` / `window_indexed.gd`.
* If nodes become unselectable, lose state, lose connections, lose levels/costs, or jump to the top-left, rollback immediately.

Approval gate:

* Approved by user instruction: "承認します。進めてください。"
* `0.2.8` implementation is limited to `extensions/scenes/windows/window_group.gd`.
* Current status: `STAGE_4C_PARTIAL_FAILURE_GROUP_SELECTION_DESYNC`.
* Live test zip: `Nekochan-ExpandedWorkspace-0.2.8.zip`.
* Pre-deployment backups:
  * profile backup directory: `C:\tmp\upload-labs-save-backups\20260712-161808`
  * previous live mod backup: `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.2.7-before-0.2.8-20260712-161808.zip`

User verification result:

* Selecting a group and moving it down-right past the old boundary lets only the nodes inside the group cross the boundary.
* No other issues were reported.

Interpretation:

* This is a state-safe partial failure.
* `0.2.7` Desktop selected-node correction deliberately excludes `window_group.gd`.
* When a group is selected, the group selection includes its contained normal nodes.
* The contained normal nodes are corrected into the expanded area, but the group node itself is skipped by the Desktop correction and remains constrained by its own movement path.

### Stage 4D: Canary G - Include Group Node In Desktop Selection Correction

Goal: make selected group movement keep the group frame and contained nodes together when crossing into the expanded area.

Candidate version:

* `0.2.9-group-selection-sync-canary`

Selected patch target:

* `scripts/desktop.gd`

Retained patch target:

* `scenes/windows/window_group.gd`

Strictly excluded:

* `scenes/windows/window_base.gd`
* `scenes/windows/window_indexed.gd`
* `scenes/windows/window_container.gd`
* `scenes/connector_point.gd`
* template/schematic paste bounds
* group resizing
* save/load routines

Proposed approach:

* Remove the Desktop canary's group exclusion.
* Let `window_group.gd` participate in the same deferred selected-node correction as normal selected nodes.
* Keep the `window_group.gd` movement canary active for the group center-handle movement path.
* Continue to move selected windows with `window.move(target_position)` so old vanilla `move_snapped()` clamps are not re-entered.
* Do not add or package `window_container.gd`, `window_base.gd`, or `window_indexed.gd`.

Expected result:

* When selecting and moving a group, the group frame and contained nodes move together into the expanded area.
* Normal node movement remains OK.

Manual verification:

1. Back up save/config and the current `0.2.8` zip before deployment.
2. Restart the game and confirm it loads `ExpandedWorkspace v0.2.9`.
3. Confirm existing nodes remain present, selectable, connected, and preserve levels/costs.
4. Select a group and move it beyond the old boundary.
5. Confirm the group frame and the contained nodes move together into the expanded area.
6. Confirm normal existing-node movement, click placement, and drag-from-palette placement still work.
7. Inspect `modloader.log`.

Go / no-go:

* If group and contained nodes move together, record group-selection movement as verified.
* If the group frame still separates from contained nodes but state remains safe, record `0.2.9` as a functional failure and do not escalate to base/indexed classes.
* If nodes become unselectable, lose state, lose connections, lose levels/costs, or jump to the top-left, rollback immediately.

Approval gate:

* Approved by user instruction: "承認します。進めてください。"
* `0.2.9` implementation is limited to `extensions/scripts/desktop.gd`.
* Current status: `STAGE_4D_GROUP_SELECTION_MOVEMENT_VERIFIED`.
* Live test zip: `Nekochan-ExpandedWorkspace-0.2.9.zip`.
* Mod Loader profile points to `E:/SteamLibrary/steamapps/common/Upload Labs/mods/Nekochan-ExpandedWorkspace-0.2.9.zip`.
* Pre-deployment backups:
  * profile backup directory: `C:\tmp\upload-labs-save-backups\20260712-162640`
  * previous live mod backup: `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.2.8-before-0.2.9-20260712-162640.zip`
* Packaging safety check: the live `0.2.9` zip does not include `window_container.gd`, `window_base.gd`, `window_indexed.gd`, `vanilla-reference`, `.exe`, `.pck`, game assets, recovered vanilla source, save files, or obvious secret-name entries.
* User in-game verification result: success.
* Verified behavior:
  * group frame and contained nodes move together beyond the old boundary
  * normal existing-node movement remains OK
  * click placement and drag-from-palette placement remain OK
  * no new node-state issues were reported

Current Phase 2B-R3 status:

* `STAGE_4D_GROUP_SELECTION_MOVEMENT_VERIFIED`
* Basic expanded-area interaction is now user-verified for camera movement, zoomed-out grid/background coverage, click placement, drag-from-palette placement, existing-node movement, and group-selection movement.

## Stage 5: Deferred Systems

These are not part of the first R3 canaries:

* template/schematic paste into expanded area
* group window movement/resizing
* full exact-density grid regeneration
* config UI
* save-protection UI
* `40000` or larger areas
* Workshop upload

They become separate stages only after basic camera, visuals, placement, and movement are safe.

## Rollback Rule

Each canary must be packaged and deployed as the only live candidate zip. If it fails:

1. remove the failed candidate from the live game `mods` folder
2. restore the stable `0.1.4` zip
3. confirm ordinary placement works
4. record symptoms, version, paths, and log result

Do not leave failed candidates in the live `mods` folder.

## Approval Gate

This document is the required plan before the next Phase 2B implementation.

Implementation must not begin until the user approves this R3 plan.

## Execution Log

### 2026-07-12 Stage 0 Safety Check

User approved this R3 plan and asked to proceed.

Observed live game mods folder:

* `E:\SteamLibrary\steamapps\common\Upload Labs\mods`
* contains only `Nekochan-ExpandedWorkspace-0.1.4.zip`
* no live `0.2.0` or `0.2.1` zip was found

Created non-destructive save/config backup:

* `C:\tmp\upload-labs-save-backups\20260712-102632`

Backup scope:

* `savegame*.dat`
* `savegame*.dat.bak`
* `config.dat`
* `mod_loader_cache.json`
* `mod_user_profiles.json`
* `tajs_core_settings.json`
* `tajs_mod_config.json`
* `steam_autocloud.vdf`
* `schematics/`

Excluded from backup:

* `token`
* `logs/`
* `vulkan/`

Observed `modloader.log`:

* `Nekochan-ExpandedWorkspace-0.1.4.zip loaded`
* Phase 2A-R4 script extensions installed
* `Applied R4 space upgrade limit patch (100 -> 200) during mod_ready`
* `ExpandedWorkspace v0.1.4 loaded. Target node limit: 1000. Space upgrade cap: 200`

Stage 0 test-save decision:

* The user stated that the save loaded when the game starts should be used as the test save.
* The user also stated that save data cannot be kept locally from their side.
* Agent-side non-destructive backup remains available at `C:\tmp\upload-labs-save-backups\20260712-102632`.
* Deployment of `0.2.x` canary is allowed under this user decision, but the canary must remain camera/visuals-only.

### 2026-07-12 Stage 1 Static Route Review

Selected first canary target:

* **Stage 2: Camera And Visuals Only**

Allowed first-canary targets:

* `scripts/main_2d.gd`
* `scripts/lines.gd`
* `scripts/paint.gd`

Reason:

* These affect camera bounds and visible background/grid coverage.
* They do not directly modify loaded node scene roots.
* They do not modify node placement, node movement, template paste, connector state, saved node data, node levels, or upgrade cost data.

Do not include in the first canary:

* `scripts/windows_tab.gd`
* `scenes/window_dragger.gd`
* `scripts/desktop.gd`
* `scenes/connector_point.gd`
* `scenes/windows/window_container.gd`
* `scenes/windows/window_group.gd`
* `scenes/windows/window_base.gd`
* `scenes/windows/window_indexed.gd`

Implementation and deployment may proceed for the camera/visuals-only canary under the user's current-save test decision. Do not include placement, movement, paste, connector, or window base/indexed patches in this canary.

### 2026-07-12 Stage 2 Canary A Deployment

Implemented and packaged:

* version: `0.2.2`
* package: `mod/build/Nekochan-ExpandedWorkspace-0.2.2.zip`
* staging directory: `mod/build/stage-0.2.2/`

Live game mods folder now contains:

* `E:\SteamLibrary\steamapps\common\Upload Labs\mods\Nekochan-ExpandedWorkspace-0.2.2.zip`

Previous stable package moved to backup:

* `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.1.4.zip`

Packaged files were allowlisted. The package includes only:

* `manifest.json`
* `mod_main.gd`
* `extensions/boot.gd`
* `extensions/scripts/space_upgrade_limit_patch.gd`
* `extensions/scripts/windows_tab.gd`
* `extensions/scenes/window_dragger.gd`
* `extensions/scripts/desktop.gd`
* `extensions/scripts/schematics_tab.gd`
* `extensions/scripts/workspace_area_config.gd`
* `extensions/scripts/main_2d.gd`
* `extensions/scripts/lines.gd`
* `extensions/scripts/paint.gd`

Explicitly not packaged:

* `extensions/scenes/windows/window_base.gd`
* `extensions/scenes/windows/window_indexed.gd`
* `extensions/scenes/windows/window_container.gd`
* `extensions/scenes/connector_point.gd`

Manual test focus:

1. Start the game and confirm it loads without an immediate error.
2. Confirm ordinary node placement still works in the existing area.
3. Confirm existing nodes are not moved, reset, disconnected, or level-reset.
4. Pan camera beyond the old `10000` boundary.
5. Zoom out and inspect whether the background/grid coverage is better than `0.1.4`.
6. Do not expect new node placement or node movement into the expanded area yet. This canary intentionally does not implement those paths.

User test result:

* No node-state problems were observed.
* Camera movement range still appears to behave like vanilla.
* Grid/background appearance still appears to behave like vanilla.

Conclusion:

* Canary A did not reproduce the prior node corruption, which supports the decision to avoid node base/indexed patches.
* The camera/visual patches did not take visible effect and require log inspection before the next canary.

Log diagnosis:

* The first `0.2.2` zip had the wrong archive root.
* It packaged files under `Nekochan-ExpandedWorkspace/...`.
* Mod Loader expected `mods-unpacked/Nekochan-ExpandedWorkspace/...`.
* `modloader.log` reported missing `res://mods-unpacked/mod_main.gd` and `res://mods-unpacked/manifest.json`.
* Therefore the first `0.2.2` package did not load, explaining the vanilla camera/grid behavior.

Fix:

* Rebuilt `mod/build/Nekochan-ExpandedWorkspace-0.2.2.zip` with the correct `mods-unpacked/Nekochan-ExpandedWorkspace/...` root.
* Replaced the live game package with the corrected zip.
* Moved the malformed zip to `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.2.2-bad-zip-20260712-111241.zip`.

Retest requirement:

* Restart the game so Mod Loader reads the corrected `0.2.2` zip.
* Confirm `modloader.log` shows `ExpandedWorkspace v0.2.2 loaded` after the next launch.

Corrected package user retest result:

* Camera movement still appears to behave like vanilla.
* Grid/background still appears to behave like vanilla.

Next diagnosis:

* Inspect `modloader.log` again to confirm whether the corrected package loaded and whether the three camera/visual script extensions were installed.

Second log diagnosis:

* The corrected `0.2.2` zip loaded successfully.
* However, `Nekochan-ExpandedWorkspace/mod_main.gd` was not initialized.
* `mod_user_profiles.json` had `Nekochan-ExpandedWorkspace` set to `is_active: false`.
* It also contained a malformed blank mod id entry (`""`) left from the earlier bad package attempt.

Profile fix:

* Backed up the profile to `C:\tmp\upload-labs-save-backups\20260712-102632\mod_user_profiles.before-enable-0.2.2-20260712-111828.json`.
* Removed the blank mod id entry.
* Set `Nekochan-ExpandedWorkspace` to `is_active: true`.
* Preserved `asouy-ModManager` as active.

Retest requirement:

* Restart the game again.
* Confirm `modloader.log` now shows `Initializing -> Nekochan-ExpandedWorkspace`.
* Confirm `ExpandedWorkspace v0.2.2 loaded`.

User visual retest after enabling the profile:

* When sufficiently zoomed in, the grid is visible in the expanded area.
* When zoomed out, only the old area appears to be rendered.
* The user supplied screenshots marking the old/new area boundary.

Interpretation:

* The `lines.gd` extension is likely loading enough to affect close-view grid rendering.
* The zoomed-out cutoff suggests a remaining parent Control, background, or canvas-item visible/clipping size issue rather than a pure grid-generation issue.
* Continue within Camera/Visuals Only scope; do not add placement, movement, paste, connector, or node base/indexed patches for this visual fix.

Log confirmation:

* `0.2.2` initialized successfully.
* `main_2d.gd`, `lines.gd`, and `paint.gd` script extensions were installed.

Cause direction:

* `Main.tscn` defines `Main2D/Desktop/Background` as `10000 x 10000`.
* `Main.tscn` also defines `Main2D/Desktop/Connectors` as `10000 x 10000`, but connectors are not touched in this visual-only canary.
* The next visual-only patch should resize only the display nodes, not connector, window, placement, or movement nodes.

Implemented follow-up canary:

* version: `0.2.3`
* package: `mod/build/Nekochan-ExpandedWorkspace-0.2.3.zip`
* live package: `E:\SteamLibrary\steamapps\common\Upload Labs\mods\Nekochan-ExpandedWorkspace-0.2.3.zip`
* profile backup: `C:\tmp\upload-labs-save-backups\20260712-102632\mod_user_profiles.before-0.2.3-20260712-112717.json`

`0.2.3` change:

* In the `main_2d.gd` extension, after screen setup, resize only:
  * `Desktop`
  * `Desktop/Background`
  * `Desktop/Lines`
* Do not resize:
  * `Desktop/Connectors`
  * `Desktop/Windows`
  * `Desktop/WindowsLOD`
  * `Desktop/Selections`
  * any node scene root

Retest focus:

1. Confirm the game loads `ExpandedWorkspace v0.2.3`.
2. Confirm node state remains intact.
3. Confirm ordinary node placement still works.
4. Confirm camera movement behavior.
5. Confirm zoomed-out grid/background behavior at the old/new boundary.

User test result for `0.2.3`:

* Camera movement works.
* Zoomed-out grid/background coverage works.
* This satisfies the Camera/Visuals Only canary objective.

Current Phase 2B-R3 status:

* `STAGE_2_CAMERA_VISUALS_VERIFIED`

Important boundary:

* This does not verify placement or movement into the expanded area.
* Do not mark Phase 2B complete.
* The next stage must remain isolated and should target one placement entry path only.

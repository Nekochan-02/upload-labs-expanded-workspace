# Phase 2C-F1 Position Persistence Root Cause

## Observed Behavior

During v0.2.9 Release Candidate clean install verification, the user observed:

1. Nodes can be placed or moved into the expanded area during the active game session.
2. After save, game exit, restart, and load, expanded-area nodes are relocated near the old workspace boundary.
3. The behavior occurs for individually placed nodes and for nodes placed or moved as a group.

The screenshot supplied with the report is consistent with nodes being visible around the old/new workspace boundary after reload. Exact node coordinates were not captured in the screenshot.

## Current Classification

Status: `ROOT_CAUSE_CONFIRMED_LIFECYCLE_CLAMP`

Confirmed fact:

- `WindowContainer._ready()` performs a post-load initialization clamp through `get_position_snapped(global_position)`.
- The vanilla helper clamps against the old `10000` workspace bounds.

Rejected repair hypothesis:

- v0.2.10 tested the hypothesis that overriding only `WindowContainer.get_position_snapped(to)` would fix restored expanded-area positions.
- User verification showed this did not fix persistence. A node placed in the expanded area still moved back to the old boundary after save, exit, restart, and load.
- v0.2.10 also introduced a deselection regression, so the global `WindowContainer` Script Extension must not be promoted to a release fix.

Confirmed F3 lifecycle evidence:

- P2 saved position: `(19650.0, 19750.0)`
- P3.5 after Desktop restoration / child-entered observation: `(19650.0, 19750.0)`
- P4 deferred final: `(9650.0, 9750.0)`
- P4 X matches `10000 - observed_width(350) = 9650`

Therefore the coordinate change occurs after the first observable child-entered restoration checkpoints and before deferred final observation. The failure is now classified as a later lifecycle clamp, not save serialization and not the immediate Desktop restoration loop.

Follow-up analysis: `docs/PHASE_2C_F2_0.2.10_REGRESSION_ANALYSIS.md`
F3 evidence: `docs/PHASE_2C_F3_DESKTOP_RESTORATION_DIAGNOSTIC_REPORT.md`
F4 canary plan: `docs/PHASE_2C_F4_RESTORATION_CORRECTION_PLAN.md`

## Release Impact

Status: `BLOCKED_POSITION_PERSISTENCE`

This is a release blocker. The v0.2.9 Draft Release must not be published. The v0.2.9 RC artifact remains failed-RC evidence:

- artifact: `Nekochan-ExpandedWorkspace-0.2.9.zip`
- SHA-256: `fc8ddab1a3f73c468eb5a1fbb2702a683629c703d67498c983ad0e52f8a038af`

## Persistence Pipeline

### Save Side

- Save routine: `scripts/data.gd::save_routine()`
- Save file construction: `scripts/data.gd::get_save_as_file()`
- Desktop serialization: `scripts/desktop.gd::save()`
- Window serialization: `scenes/windows/window_container.gd::save()`
- Common position field: `position`

Evidence:

- `Data.get_save_as_file()` asks the desktop node to produce `desktop_data`.
- `Desktop.save()` serializes every child under its `Windows` container.
- `WindowContainer.save()` writes the current `position` field directly.
- No save-side clamp or coordinate transformation was found in this path.
- `WindowBase.save()` and `WindowGroup.save()` merge additional state onto the common `WindowContainer.save()` output, so they inherit the same `position` field behavior.

### Load Side

- Save read: `scripts/data.gd::_ready()` loads `user://savegame.dat`.
- Save conversion: `scripts/data.gd::update_save()`
- Desktop restoration: `scripts/desktop.gd::_enter_tree()`
- Window creation: `load("res://scenes/windows/" + window.filename).instantiate()`
- Raw restored property assignment: `new_object.load(window)`
- Common load method: `scenes/windows/window_container.gd::load(data)`

Evidence:

- `Desktop._enter_tree()` iterates `Data.loading.desktop_data.windows`.
- For each saved window, the scene is instantiated and `new_object.load(window)` is called before adding it to `$Windows`.
- `WindowContainer.load(data)` assigns every field from the saved dictionary onto the instance, including `position`.
- No load-side clamp was found inside `Desktop._enter_tree()` or `WindowContainer.load(data)`.

### Post-Load Side

- Clamp point: `scenes/windows/window_container.gd::_ready()`
- Clamp helper: `scenes/windows/window_container.gd::get_position_snapped(to)`
- Limit source: hard-coded vanilla workspace size `10000`
- Behavior: `_ready()` assigns `global_position = get_position_snapped(global_position)`, and `get_position_snapped()` clamps to `Vector2.ZERO` through `(Vector2.ONE * 10000) - size`, then snaps to 50.

This runs after the saved `position` has been restored and the node is added to the scene tree. Because node scenes inherit from `WindowContainer`, this is a common post-load clamp for normal windows, indexed windows, and group windows.

## Single-Node Path

Single-node save/load uses the common desktop window path:

1. `Desktop.save()`
2. `WindowContainer.save()` or a derived `save()` that merges onto it
3. `Desktop._enter_tree()`
4. `WindowContainer.load(data)`
5. `WindowContainer._ready()`
6. `WindowContainer.get_position_snapped(global_position)`

The exact clamp point is shared by all `WindowContainer` descendants.

## Group-Node Path

`scenes/windows/window_group.gd` extends `WindowIndexed`, which extends `WindowBase`, which extends `WindowContainer`.

`WindowGroup.save()` merges group-specific fields such as `size`, `custom_name`, `custom_icon`, and `color` onto the common `WindowContainer.save()` output. It does not define an independent persistence coordinate system.

On load, `WindowGroup._ready()` calls `super()`, which reaches `WindowContainer._ready()` and the same old-boundary clamp. This explains why grouped nodes and individually placed nodes both show the persistence failure.

## Common Path

The shared failing path is the post-load initialization clamp in `WindowContainer._ready()`.

This is also consistent with older Phase 2B notes: v0.2.4 and v0.2.5 had to restore newly created expanded-area node positions after initialization because vanilla initialization clamps them to the old area. Clean install verification shows the same initialization clamp also affects restored save data.

## Hypotheses

### Hypothesis A

Status: `REJECTED`

Save serialization does not appear to clamp all window positions. `Desktop.save()` calls each window's `save()`, and `WindowContainer.save()` stores the current `position` field directly.

### Hypothesis B

Status: `REJECTED`

Load restoration does not appear to clamp inside the raw deserialization step. `Desktop._enter_tree()` instantiates the saved window and calls `WindowContainer.load(data)`, which assigns the saved fields directly.

### Hypothesis C

Status: `REJECTED`

No separate desktop-wide post-load normalization or off-screen recovery pass was found in the inspected desktop load path. The observed correction is accounted for by the per-window `_ready()` clamp.

### Hypothesis D

Status: `SUPPORTED`

`WindowContainer._ready()` is a shared base initialization path and clamps `global_position` through `get_position_snapped()`, whose vanilla implementation uses the old `10000` workspace bounds.

### Hypothesis E

Status: `SUPPORTED`

Group windows inherit the same `WindowContainer` initialization path. The group-specific save data merges onto the common saved position, so group frame persistence is affected by the same clamp point as normal nodes.

## Position Checkpoints

| Checkpoint | Position | Evidence |
|---|---|---|
| P1 Runtime before save | Expanded-area position; exact coordinate not captured | User observed nodes correctly existing in the expanded area during the active session. |
| P2 Serialized | Expected to remain the runtime `position`; exact coordinate not captured | `WindowContainer.save()` writes `position` directly, and no save-side clamp was found. |
| P3 Raw loaded | Expected to remain the saved `position`; exact coordinate not captured | `WindowContainer.load(data)` assigns saved fields directly before the node enters the tree. |
| P4 Final runtime | Clamped near old workspace boundary | User observed relocation after restart/load; `WindowContainer._ready()` clamps to old `10000` bounds after raw load. |

The exact X/Y clamp shape still needs diagnostic confirmation. Based on the code, expected final maxima are `10000 - window.size.x` and `10000 - window.size.y`, snapped to 50.

## Exact Clamp Point

- File: `scenes/windows/window_container.gd`
- Class/script: `WindowContainer`
- Function: `_ready()`
- Helper: `get_position_snapped(to)`
- Condition: every restored `WindowContainer` descendant enters the tree and runs `_ready()`
- Limit source: vanilla hard-coded workspace size `10000`
- Result: expanded-area restored positions are clamped back inside the old workspace bounds before the final runtime state is visible to the user.

## Root Cause

v0.2.9 extends runtime placement and movement paths, but it does not extend the common `WindowContainer` initialization clamp. Save data appears to retain the expanded-area coordinates, but restored windows are clamped during `_ready()` when they re-enter the scene tree after load.

This is why expanded-area placement works until restart, then fails after load.

## Candidate Minimal Patch Points

Rejected v0.2.10 patch candidate:

- Add a development-version Script Extension for `scenes/windows/window_container.gd`.
- Override only `get_position_snapped(to)` to clamp against `WorkspaceAreaConfig.get_max_position(size)`.
- Result: failed user verification and introduced deselection regression.

Preferred next candidate direction:

- Avoid a global `WindowContainer` replacement unless diagnostics prove it is safe.
- Prefer a restoration-path-only correction in `desktop.gd` after raw saved position load and vanilla initialization, limited to windows restored from save data.
- Do not affect active movement, placement, selection, save schema, node limits, camera, grid, background, or group-selection movement.

Diagnostic candidate:

- For a development build only, log low-frequency checkpoint positions for 1-3 nodes:
  - before `super._ready()`
  - after `super._ready()`
  - after the expanded correction, if applied
- Do not log every frame or all nodes.

## Risks

- `window_container.gd` was previously avoided in v0.2.9 because an earlier movement-focused attempt did not fix existing-node movement. However, this persistence failure is a different path: load-time initialization, not active drag behavior.
- Expanding `get_position_snapped(to)` may affect initial placement clamp behavior for all window descendants.
- Mod-disabled behavior remains a risk: if a save contains expanded-area positions and the Mod is disabled, vanilla will likely clamp those positions during load.
- A patch must not change save schema.
- A patch must not copy large vanilla function bodies.

## Recommended Fix

Do not modify v0.2.9. Do not promote v0.2.10.

Recommended next step:

1. Treat v0.2.10 as failed development artifact evidence.
2. Instrument or design a load-path-only diagnostic to prove where restored coordinates are changed.
3. Prefer a narrower restored-window correction point over a global `WindowContainer.get_position_snapped(to)` override.
4. Keep the next implementation plan separate from the failed F1 plan and require user approval before Mod code changes.

If the next approach requires broad vanilla function copies, save schema changes, or another global base-class override without diagnostic proof, stop and re-plan.

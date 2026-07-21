# Phase 2C-F5 Position Drift and Grid Geometry Analysis

Status: `ANALYSIS_COMPLETE`

## User Observation

v0.2.12 improved the release blocker behavior:

- old-boundary warp: not reproduced in the user test
- exact position persistence: not achieved
- residual position drift: observed by screenshot comparison and gameplay observation

New grid/snap observation:

- the visual grid cell size with the Mod enabled appears larger than vanilla
- snapping does not appear to align with the visual grid
- snapped positions feel geometrically inconsistent with the grid

Do not treat v0.2.12 as a pass.

## F4 Checkpoints

Latest `modloader.log` F4 target data:

| Window | SAVED | BEFORE | AFTER | STABILITY |
|---|---:|---:|---:|---:|
| `server0` | `(19650.0, 19250.0)` | `(9650.0, 9250.0)` | `(19560.07, 19059.62)` | `(19560.07, 19059.62)` |
| `download_text0` | `(19300.0, 19000.0)` | `(9650.0, 9750.0)` | `(19210.07, 18930.12)` | `(19210.07, 18930.12)` |
| `download_manager0` | `(18950.0, 18150.0)` | `(9650.0, 9200.0)` | `(18860.07, 17938.04)` | `(18860.07, 17938.04)` |

These values are local `position` values from the F4 `runtime=` field. Local `position` is the persistence source of truth because `WindowContainer.save()` writes `"position": position`.

The matching logged `global=` values after correction were:

| Window | AFTER global | STABILITY global |
|---|---:|---:|
| `server0` | `(19650.0, 19250.0)` | `(19650.0, 19250.0)` |
| `download_text0` | `(19300.0, 18994.6)` | `(19300.0, 18994.6)` |
| `download_manager0` | `(18950.0, 18150.0)` | `(18950.0, 18150.0)` |

This shows F4 mostly restored global position, not the saved local `position`.

## Position Delta Analysis

Delta formula:

- clamp delta = `BEFORE_CORRECTION - SAVED`
- correction delta = `AFTER_CORRECTION - SAVED`
- stability delta = `STABILITY_CHECK - SAVED`

| Window | Clamp Delta | Correction Delta | Stability Delta |
|---|---:|---:|---:|
| `server0` | `(-10000.0, -10000.0)` | `(-89.93, -190.38)` | `(-89.93, -190.38)` |
| `download_text0` | `(-9650.0, -9250.0)` | `(-89.93, -69.88)` | `(-89.93, -69.88)` |
| `download_manager0` | `(-9300.0, -8950.0)` | `(-89.93, -211.96)` | `(-89.93, -211.96)` |

Classification:

- `OLD_BOUNDARY_WARP`: `FIXED_BY_CANARY`
- `EXACT_POSITION_PERSISTENCE`: `FAIL`
- `RESIDUAL_DRIFT`: `CONFIRMED`

## Desired Position Calculation

F4 uses:

```text
desired_position = saved_position
    .clamp(Vector2.ZERO, WorkspaceAreaConfig.get_max_position(size))
    .snappedf(50)
```

For the latest F4 targets, `desired` equals `saved` in the logs:

| Window | Saved | Desired | Desired Delta |
|---|---:|---:|---:|
| `server0` | `(19650.0, 19250.0)` | `(19650.0, 19250.0)` | `(0.0, 0.0)` |
| `download_text0` | `(19300.0, 19000.0)` | `(19300.0, 19000.0)` | `(0.0, 0.0)` |
| `download_manager0` | `(18950.0, 18150.0)` | `(18950.0, 18150.0)` | `(0.0, 0.0)` |

For these targets:

- `saved_position.snappedf(50)` delta: `(0.0, 0.0)`
- expanded-bounds clamp delta: `(0.0, 0.0)`

Therefore the observed F4 residual drift is not caused by `.snappedf(50)` or expanded-bounds clamp for the captured targets.

However, exact persistence should not resnap saved data in principle. If a future saved position is not already on the 50-unit grid, `.snappedf(50)` would introduce drift.

## Window.move Semantics

Vanilla `WindowContainer.move(pos)`:

```text
global_position = pos
moved.emit()
```

Confirmed behavior:

- argument is an absolute global target, not a local position and not a delta
- it does not snap
- it emits `moved`
- it does not change selection state
- it does not change drag state
- it does not play sound
- it does not propagate group children in the inspected `WindowGroup` code

Signal listener:

- `Desktop._on_windows_child_entered(child)` connects each child's `moved` signal to `queue_rid_update()`
- this queues LOD/selection redraw updates

Persistence conflict:

- `WindowContainer.save()` persists local `position`
- F4 passed saved local `position` into `move()`
- `move()` wrote it as `global_position`
- the resulting local `position` became offset from the saved value

This is the confirmed residual drift root cause for F4.

## Vanilla Grid Geometry

Vanilla `scripts/lines.gd`:

| Geometry | Vanilla |
|---|---:|
| workspace size | `10000 x 10000` |
| line grid count | `200` horizontal + `200` vertical |
| line grid interval | `50` world units |
| line grid visual extent | `10000` |
| major line interval | every 10th line, effectively `500` units |
| circle grid interval | `50` world units |
| cross grid interval | `50` world units |
| line/circle/cross origin | starts at or near `(0, 0)` depending on style |
| `Lines` scale | vanilla Control scale |

Vanilla snap geometry:

| Path | Snap |
|---|---:|
| window placement | `snappedf(50)` |
| window movement | `snappedf(50)` |
| group movement/resizing cursor anchor | `snappedf(50)` |
| connector point movement | `snappedf(25)` |
| schematic connector custom points | `snappedf(25)` |

## Current Mod Grid Geometry

Current Mod source:

- `workspace_area_config.gd`: `VANILLA_WORKSPACE_SIZE = 10000`, `MODDED_WORKSPACE_SIZE = 20000`, `RENDER_SCALE = (2, 2)`
- `extensions/scripts/main_2d.gd`: sets `Desktop`, `Background`, and `Desktop/Lines` size to `20000 x 20000`
- `extensions/scripts/lines.gd`: calls vanilla `update_lines()` and applies `scale = WorkspaceAreaConfig.RENDER_SCALE`

Current visual result for vanilla line/circle/cross grid styles:

| Geometry | Vanilla | Current Mod |
|---|---:|---:|
| workspace size | `10000` | `20000` |
| generated line/circle/cross interval before transform | `50` | `50` |
| `Lines` scale | `1` | `2` |
| visual minor interval | `50` | `100` |
| visual major interval | `500` | `1000` |
| placement snap interval | `50` | `50` |
| movement snap interval | `50` | `50` |
| connector snap interval | `25` | `25` |

The current coverage strategy scales the existing vanilla grid to cover the expanded workspace. That doubles visual spacing.

## Snap Geometry

The current code keeps the interaction snap intervals at vanilla values:

- windows: `50`
- connectors: `25`

But the most visible grid styles are scaled by `2`, so the visual grid interval becomes:

```text
50 * 2 = 100
```

Therefore a valid 50-unit snapped window coordinate can land halfway between visual grid lines. This directly matches the user observation that snapping does not appear aligned with the visual grid.

## Grid Root Cause

Classification: `GRID_DENSITY_SCALE_MISMATCH`

Consequence: `SNAP_INTERVAL_MISMATCH`

Evidence:

- vanilla visual interval is generated at 50 units
- current Mod scales the whole `Lines` node by 2
- current visual interval becomes 100 units
- placement/movement snap remains 50 units

No evidence currently points to camera transform as the primary grid issue.

## Position / Grid Relationship

Classification: `INDEPENDENT`

Evidence:

- F4 residual position drift is confirmed in runtime checkpoint logs as local `position` drift after using `move()` with a saved local coordinate.
- For captured F4 targets, `desired == saved`, so `.snappedf(50)` did not introduce the measured drift.
- Grid density mismatch is code-confirmed independently by `Lines.scale = (2, 2)` while snap remains 50.

The grid mismatch can make the residual drift and snap behavior more visually noticeable, but it is not the logged root cause of F4's exact-position persistence failure.

## Position Fix Candidate

Candidate: restoration-only local position restore.

For restored windows whose saved position is inside expanded bounds:

```text
window.position = saved_position.clamp(Vector2.ZERO, expanded_max)
window.moved.emit()
```

Key changes from F4:

- use local `position`, not `global_position`
- do not use `WindowContainer.move()` because it writes global position
- do not resnap the saved coordinate if exact persistence is the goal
- still emit `moved` to preserve redraw/update behavior

This is a candidate only. Do not implement without a new approved plan.

## Grid Fix Candidates

1. Candidate A: vanilla-density grid regeneration
   - Generate grid instances to `20000` bounds using the same 50-unit interval.
   - Preserves vanilla snap alignment.
   - Increases instance count, so performance needs review.

2. Candidate B: render transform compensation
   - Stop scaling the whole `Lines` node by 2.
   - Expand coverage/bounds without changing interval.
   - Likely requires replacing the current `scale = RENDER_SCALE` shortcut.

3. Candidate C: repeated/tiled vanilla-density grid
   - Repeat vanilla-density grid regions over expanded workspace.
   - Must preserve origin and avoid seams.
   - More complex than direct regeneration.

Rejected as first choice:

- changing window snap from 50 to 100 to match the scaled visual grid
- reason: it changes vanilla interaction geometry and would reduce placement precision

## Recommended Order

1. exact position persistence
2. vanilla-density grid restoration
3. group persistence
4. full regression
5. release integration

Exact position persistence should be resolved first because the current release blocker is persistence, and the F4 evidence gives a narrow next candidate. Grid density should be fixed before wider regression because it affects user trust in placement geometry.

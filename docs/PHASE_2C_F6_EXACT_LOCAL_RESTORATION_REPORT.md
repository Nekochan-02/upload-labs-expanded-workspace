# Phase 2C-F6 Exact Local Restoration Report

Status: `F6_SINGLE_NODE_EXACT_PERSISTENCE_VERIFIED`

## Root Cause Coverage

- saved coordinate domain: local `WindowContainer.position`
- F4 mutation coordinate domain: `WindowContainer.move(saved_position)`, which writes `global_position`
- confirmed mismatch: local saved data was applied as a global target, producing the F4 residual drift

F6 keeps the F4 restoration timing but replaces that mutation with a direct local assignment. The old-boundary clamp still occurs in vanilla initialization; the deferred F6 correction then restores the saved local coordinate within expanded workspace bounds.

## F6 Correction

- snapshot: saved `desktop_data.windows[*].position`, captured before `super._enter_tree()`
- target condition: non-negative restored local position beyond the old `10000` workspace maximum for the restored window size
- desired local position: `saved_position.clamp(Vector2.ZERO, WorkspaceAreaConfig.get_max_position(window.size))`
- mutation method: `window.position = desired_position`
- update signal: `window.moved.emit()` after the local assignment
- timing: one deferred restoration-only correction after vanilla Desktop initialization, followed by one deferred stability checkpoint
- cleanup: saved snapshot and metadata dictionaries are cleared after correction; stability checks are cleared after logging

The correction does not call `move()`, `move_snapped()`, `get_position_snapped()`, write `global_position`, or re-snap saved data.

## Coordinate and Scope Audit

| Check | Result |
|---|---|
| Restore uses local assignment | YES |
| Restore writes `global_position` | NO |
| Restore calls `move()` | NO |
| Restore calls `move_snapped()` | NO |
| Restore calls `.snappedf()` | NO |
| Restore emits `moved` | YES |
| `WindowContainer` extension | NO |
| `WindowBase` extension | NO |
| `WindowIndexed` extension | NO |
| `get_position_snapped()` override | NO |
| Save schema change | NO |
| Node limit change | NO |
| `space` upgrade-cap change | NO |
| Camera/grid/background runtime change | NO |
| Placement workflow change | NO |
| Group-selection movement change | NO |
| Continuous correction | NO |

F6 logs at most three correlation-safe targets with `SAVED_LOCAL`, `BEFORE_CORRECTION`, `DESIRED_LOCAL`, `clamp_delta`, `AFTER_CORRECTION`, and `STABILITY_CHECK`. For an in-bounds position, `clamp_delta` must be zero. The log also records whether local runtime position approximately equals the desired local value at the after and stability checkpoints.

## Group Scope

F6 adds no group-specific restore or propagation behavior. The first user test is individual-node only. Group persistence is not a F6 PASS criterion and remains a later phase.

## Grid Isolation

`GRID_DENSITY_SCALE_MISMATCH` remains documented in `docs/PHASE_2C_F5_POSITION_DRIFT_GRID_GEOMETRY_ANALYSIS.md`. No grid generation, render scale, visual origin, window snap interval, connector snap interval, or related runtime code changed in F6.

## Artifact

- version: `0.2.13`
- artifact type: development canary, not a public release artifact
- filename: `Nekochan-ExpandedWorkspace-0.2.13.zip`
- path: `dist/Nekochan-ExpandedWorkspace-0.2.13.zip`
- size: `11274 bytes`
- file count: `13`
- ZIP root: `mods-unpacked`
- manifest version: `0.2.13`
- SHA-256: `88908fec32fce7d407cc971428c7682dfd05c57f7f6b184e38f1e5e466582933`

## Publish Safety Audit

| Detection | Count |
|---|---:|
| vanilla-verbatim body | 0 |
| substantial vanilla-derived code | 0 |
| third-party copied code | 0 |
| game binary | 0 |
| game asset/resource | 0 |
| save file | 0 |
| secret | 0 |
| forbidden file | 0 |

The packaged ZIP contains only the allowlisted Mod scripts, `manifest.json`, and `mod_main.gd`. It contains no `vanilla-reference`, Workshop paths, logs, binaries, `.pck`, scene/resource files, save files, blocked Window script extensions, or secret-named paths.

## F6 Runtime Evidence

User-tested v0.2.13 with the game subsequently closed. The user confirmed both deselection paths and exact visual retention for an individual node after save, exit, restart, and load. The supplied before/after screenshots are consistent with that visual result.

The final `modloader.log` F6 run contained three non-group restored targets. Each saved coordinate was within expanded bounds (`clamp_delta = (0.0, 0.0)`).

| Window | SAVED_LOCAL | BEFORE_LOCAL | BEFORE_GLOBAL | DESIRED_LOCAL | AFTER_LOCAL | AFTER_GLOBAL | STABILITY_LOCAL | STABILITY_GLOBAL |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `download_manager0` | `(18300.0, 18000.0)` | `(9650.0, 9200.0)` | `(9760.493, 9460.447)` | `(18300.0, 18000.0)` | `(18300.0, 18000.0)` | `(18410.49, 18260.45)` | `(18300.0, 18000.0)` | `(18410.49, 18260.45)` |
| `download_text0` | `(18700.0, 18800.0)` | `(9650.0, 9750.0)` | `(9760.493, 9835.869)` | `(18700.0, 18800.0)` | `(18700.0, 18800.0)` | `(18810.49, 18879.24)` | `(18700.0, 18800.0)` | `(18810.49, 18879.24)` |
| `network0` | `(17850.0, 17700.0)` | `(9650.0, 9500.0)` | `(9760.493, 9654.689)` | `(17850.0, 17700.0)` | `(17850.0, 17700.0)` | `(17960.49, 17854.69)` | `(17850.0, 17700.0)` | `(17960.49, 17854.69)` |

Measured result for all three targets:

```text
AFTER_CORRECTION_LOCAL == SAVED_LOCAL: YES
STABILITY_LOCAL == SAVED_LOCAL: YES
```

The old vanilla-boundary clamp is still visible at `BEFORE_LOCAL`; F6 then restores the same saved local coordinate and it remains stable through the next deferred checkpoint. The differing global values are expected because they are a distinct coordinate domain and no longer replace the saved local value.

## User Verification Status

| Test | Result |
|---|---|
| Empty-area deselect | PASS (user verified) |
| Menu x deselect | PASS (user verified) |
| Single-node exact visual persistence | PASS (user verified) |
| SAVED_LOCAL captured | PASS (three targets) |
| `AFTER_CORRECTION_LOCAL == SAVED_LOCAL` | PASS (three targets) |
| `STABILITY_LOCAL == SAVED_LOCAL` | PASS (three targets) |
| Group persistence | NOT TESTED / out of F6 scope |
| Grid density and snap geometry | NOT TESTED / out of F6 scope |

F6 is a verified individual-node persistence canary only. It is not a group-persistence, grid, full-regression, or release-integration pass.

## Release Boundary

No GitHub Release, Draft Release, tag, Workshop upload, public-master push, or v0.2.9 artifact operation was performed. Clean public integration remains deferred.

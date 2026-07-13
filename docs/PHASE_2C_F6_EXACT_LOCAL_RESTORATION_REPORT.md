# Phase 2C-F6 Exact Local Restoration Report

Status: `F6_CANARY_READY_FOR_USER_TEST`

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

## User Verification Status

| Test | Result |
|---|---|
| Empty-area deselect | NOT TESTED |
| Menu x deselect | NOT TESTED |
| Single-node exact visual persistence | NOT TESTED |
| SAVED_LOCAL captured | NOT TESTED |
| `AFTER_CORRECTION_LOCAL == SAVED_LOCAL` | NOT TESTED |
| `STABILITY_LOCAL == SAVED_LOCAL` | NOT TESTED |

No real-game PASS is claimed.

## Release Boundary

No GitHub Release, Draft Release, tag, Workshop upload, public-master push, or v0.2.9 artifact operation was performed. Clean public integration remains deferred.

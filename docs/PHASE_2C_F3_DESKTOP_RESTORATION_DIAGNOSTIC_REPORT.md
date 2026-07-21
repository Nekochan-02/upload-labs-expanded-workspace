# Phase 2C-F3 Desktop Restoration Diagnostic Report

Status: `DIAGNOSTIC_EVIDENCE_CAPTURED`

## Artifact

- version: `0.2.11`
- filename: `Nekochan-ExpandedWorkspace-0.2.11.zip`
- path: `dist/Nekochan-ExpandedWorkspace-0.2.11.zip`
- size: `11073 bytes`
- file count: `13`
- ZIP root: `mods-unpacked`
- manifest version: `0.2.11`
- SHA-256: `565399784e83163d9ff2013fdd3d43028ed516af9a811bf30d31885a3789dd2e`
- artifact type: development diagnostic
- public release artifact: no

## Runtime Result

User tested the diagnostic artifact and closed the game. Codex collected `[F3]` lines from the actual Upload Labs logs.

Selection result:

- empty-area deselect: `PASS`
- state/options menu `x` deselect: `PASS`

Position result:

- single node placed in expanded area
- save / exit / restart / load completed
- user observed the node warped back to the old boundary

Primary evidence source:

- `C:\Users\shian\AppData\Roaming\Upload Labs\logs\modloader.log`
- `C:\Users\shian\AppData\Roaming\Upload Labs\logs\godot.log`

The same target appeared twice in the latest logs. Both runs show the same transition: P2 and P3.5 preserve the saved expanded-area position, then P4 is clamped to the old boundary.

| Diagnostic | Value |
|---|---|
| P2 saved position | `(19650.0, 19750.0)` |
| P3 after load | `UNOBSERVED` by design; no vanilla `_enter_tree()` body copy |
| P3.5 after add_child/init | `(19650.0, 19750.0)` at both `after_super_enter_tree` and `child_entered_tree` |
| P4 deferred final | `(9650.0, 9750.0)` |
| selection empty-area deselect | PASS |
| selection x deselect | PASS |

## Captured Target

| Field | Value |
|---|---|
| diagnostic index | `0` |
| source index | `3` |
| saved name | `download_video0` |
| saved filename | `window_download_video.tscn` |
| observed script | `res://scenes/windows/window_download.gd` |
| observed size | `(350.0, 272.0)` |
| is group | `false` |

## Checkpoint Comparison

Latest observed run from `modloader.log`:

| Checkpoint | Position | Global Position | Interpretation |
|---|---:|---:|---|
| P2 saved | `(19650.0, 19750.0)` | n/a | Save data visible to Desktop still has expanded-area coordinates. |
| P3 direct | `UNOBSERVED` | n/a | Direct point after `new_object.load(window_data)` is intentionally not observed because copying vanilla `_enter_tree()` is forbidden. |
| P3.5 after `super._enter_tree()` | `(19650.0, 19750.0)` | `(19650.0, 19750.0)` | Desktop restoration has not clamped the local position by this checkpoint. |
| P3.5 `child_entered_tree` | `(19650.0, 19750.0)` | `(19650.0, 19750.0)` | Initial child-entered observation still has the saved expanded-area coordinates. |
| P4 deferred final | `(9650.0, 9750.0)` | `(9779.63, 9850.741)` | Position has changed to the old boundary by deferred final observation. |

Earlier latest-log run showed the same local-position transition:

- P2: `(19650.0, 19750.0)`
- P3.5: `(19650.0, 19750.0)`
- P4: `(9650.0, 9750.0)`

## Evidence Conclusion

The coordinate change does not occur in the Desktop saved-data snapshot or by the first observable post-restore child checkpoints.

The change occurs after P3.5 and before P4:

```text
P2 saved=(19650.0, 19750.0)
P3.5 after_super/child_entered=(19650.0, 19750.0)
P4 deferred_final=(9650.0, 9750.0)
```

This narrows the failure to post-enter-tree initialization or a deferred/lifecycle step after Desktop restoration has returned, not to save serialization and not to the immediate Desktop restoration loop.

The P4 value matches the old-boundary clamp shape for the observed window width:

- old X max: `10000 - 350 = 9650`
- observed P4 X: `9650`

The Y value is also old-boundary-shaped after snapping:

- old Y max before snap: `10000 - 272 = 9728`
- snapped grid result observed: `9750`

Do not implement a fix from this evidence alone. The next plan should target the post-P3.5/pre-P4 lifecycle point with the narrowest diagnostic or correction path and still avoid `WindowContainer` / `WindowBase` / `WindowIndexed` Script Extensions unless separately approved.

## Static Scope

- patch surface: existing `extensions/scripts/desktop.gd`
- `WindowContainer` extension included: `NO`
- `WindowContainer` registration present: `NO`
- `WindowBase` extension included: `NO`
- `WindowIndexed` extension included: `NO`
- `get_position_snapped()` override present: `NO`
- restored position mutation: `NO`
- save schema mutation: `NO`

## Diagnostic Design

Checkpoints:

- P2 is logged before `super._enter_tree()` from `Data.loading.desktop_data.windows`.
- P3 direct is logged as `UNOBSERVED` because observing immediately after `new_object.load(window_data)` would require copying vanilla `Desktop._enter_tree()`.
- P3.5 is logged at `$Windows.child_entered_tree` and again after `super._enter_tree()` returns.
- P4 is logged through a deferred final observation.

Target filtering:

- maximum 3 windows
- saved `position` must be `Vector2`
- saved `position.x > 10000` or `position.y > 10000`
- correlation uses saved `window.name`, matching vanilla `Windows/<window.name>` lookup

## User Verification Matrix

| Test | Result | Evidence |
|---|---|---|
| v0.2.11 diagnostic artifact installed | PASS | Logs show `ExpandedWorkspace v0.2.11 diagnostic loaded`. |
| WindowContainer extension absent at runtime | PASS | Latest 0.2.11 logs install `window_group.gd` and `desktop.gd`, but not `window_container.gd`. |
| Empty-area deselection clears selection | PASS | User reported OK. |
| Options-menu x clears selection | PASS | User reported OK. |
| Single node placed in expanded area | PASS | User reported placement completed. |
| Save / exit / restart / load completed | PASS | User reported full cycle completed and game exited. |
| Node moved back to old boundary or retained position | FAIL | User observed old-boundary warp. |
| F3 P2 log captured | PASS | Saved position `(19650.0, 19750.0)`. |
| F3 P3 direct-unobserved marker captured | PASS | Logged `after_load_direct=UNOBSERVED`. |
| F3 P3.5 log captured | PASS | Observed `(19650.0, 19750.0)`. |
| F3 P4 log captured | PASS | Observed `(9650.0, 9750.0)`. |

## Decision

`DIAGNOSTIC_EVIDENCE_CAPTURED`

Do not implement a position fix from this artifact without a new approved plan.

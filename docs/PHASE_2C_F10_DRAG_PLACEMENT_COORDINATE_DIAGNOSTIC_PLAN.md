# Phase 2C-F10: Drag Placement Coordinate-Domain Diagnostic Plan

## Status

`DIAGNOSTIC_APPROVED`

## Objective

Measure the complete expanded-area drag-placement coordinate lifecycle without
changing its behavior. The user observed drag placement off-grid after F9, while
F9 click placement is verified aligned immediately, after opening settles, and
after manual movement.

## Evidence and Scope

F9 proved local correction for click placement: a snapped target was restored
as local `position` and remained exact through opening-settle. F10 does not
apply that correction to drag placement. It records whether the existing drag
target source, create lifecycle, or final deferred global `move(target)` causes
the visual defect.

Target: `extensions/scenes/window_dragger.gd::place()` and
`_get_expanded_drag_target()` only. One self-authored observer Node records
post-deferred and opening-settle state because the vanilla dragger queues itself
for deletion after placement.

## Checkpoints

One expanded-area drag-created target per run logs:

| Checkpoint | Evidence |
| --- | --- |
| D1 DRAGGER_STATE | dragger global position, size, and screen input point |
| D2 SCREEN_TO_WORLD | `Utils.screen_to_world_pos(screen_input_point)` |
| D3 RAW_TARGET | world point minus drag placement offset |
| D4 SNAPPED_TARGET | clamped/snapped target and 50-unit arithmetic |
| D5 PRE_CREATE | instance local/global/parent |
| D6 POST_CREATE | instance and safe parent state |
| D7 AFTER_REAPPLY_GLOBAL | instance local/global |
| D8 BEFORE_DEFERRED_MOVE | instance local/global |
| D9 AFTER_DEFERRED_MOVE | observer state after existing `move(target)` |
| D10 NEXT_DEFERRED_STABILITY | observer next deferred state |
| D11 OPENING_SETTLE | one 0.5-second observer state |

D5-D11 log local-to-target, global-to-target, and global-local deltas. D4
classifies `DRAG_TARGET_SNAP_CORRECT` or `DRAG_TARGET_SNAP_INCORRECT`.

## Explicit Non-Goals

- No drag placement correction.
- No change to F9 click correction or `windows_tab.gd`.
- No grid, Lines, render scale, snap interval, or `Utils.screen_to_world_pos`
  change.
- No F6 restoration, existing movement, group, WindowContainer/Base/Indexed,
  `get_position_snapped`, or save-schema change.
- No release, tag, Workshop, public-master push, or v0.2.9 artifact operation.

## Artifact

- Version: `0.2.17`
- Filename: `Nekochan-ExpandedWorkspace-0.2.17.zip`
- Build: `tools/build_release.ps1 -Version 0.2.17`
- Purpose: local diagnostic canary only.

## Static Acceptance Criteria

```text
F9 click correction changed: NO
F7 grid changed: NO
F6 restoration changed: NO
drag behavior changed: NO
drag diagnostic added: YES
snap interval changed: NO
WindowContainer extension: NO
save schema changed: NO
```

## User Gate

With only v0.2.17 installed: create one node through expanded-area drag
placement, check alignment immediately and after 0.5-1 second, move it once,
then provide the three visual outcomes and `[F10]` logs. Save/restart, group,
and full-regression testing are out of scope.

## Stop Conditions

Do not implement a repair if D4 is incorrect, the screen-to-world source is
offset, local equals target while visual alignment fails, or any click/F6/F7/
movement regression appears. The next phase may propose only one minimal
drag-specific candidate after D1-D11 evidence is captured.

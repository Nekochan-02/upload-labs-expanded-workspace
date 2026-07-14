# Phase 2C-F9: Click Placement Local-Domain Alignment Canary Plan

## Status

`IMPLEMENTATION_APPROVED`

## Objective

Test one narrow correction for the remaining click-placement visual alignment
defect. Keep the F8 target calculation unchanged and replace only the final
deferred click correction from a global-domain `move(target_position)` call to
a local-domain `position = target_position` assignment followed by `moved.emit()`.

F9 is a development canary only. It does not establish a release candidate.

## F8 Evidence

F8 is `DIAGNOSTIC_EVIDENCE_CAPTURED`. The user observed initial click placement
as `FAIL`; after one manual movement, alignment was `PASS`.

| Checkpoint | Captured evidence |
| --- | --- |
| C1 camera center | `(15550.68, 18198.79)` |
| C2 raw target | `(15375.68, 18062.79)` |
| C3 snapped target | `(15400.0, 18050.0)` |
| C3 classification | `TARGET_SNAP_CORRECT` |
| C8/C9 global | exactly C3 |
| C8/C9 local | `(15225.0, 17924.5)` |
| local delta from C3 | `(-174.998, -125.498)` |

F8 therefore classifies the defect as `VISUAL_ORIGIN_MISMATCH`: target
calculation and 50-unit snapping are correct, while the click-created window's
visible/control local origin is offset during its opening pivot/scale lifecycle.

## Rationale and Patch Surface

Grid changes are excluded because F7 restored vanilla-density grid geometry and
F8 C3 independently proved the target snap arithmetic. Drag placement remains
excluded because it is user-verified `PASS`; existing-node movement is also
unchanged and user-verified `PASS`.

The click path's final deferred correction is the smallest evidence-backed
surface. Earlier pre-create and post-create global assignments remain exactly as
in F8. F9 does not re-snap, recalculate the target, write `global_position`, or
call `move()` at the final correction point.

The opening tween may change pivot/scale-related transforms after creation. F9
therefore logs the correction immediately, once in the next deferred lifecycle,
and once through a single 0.5-second `SceneTreeTimer` callback. It has no
`_process()` callback, timer loop, or continuous monitor.

## Exact Implementation

Target: `extensions/scripts/windows_tab.gd::add_window()`.

The existing final correction:

```gdscript
instance.call_deferred("move", target_position)
```

is replaced by a self-authored click-only deferred helper:

```gdscript
window.position = target_position
window.moved.emit()
```

The helper runs only for click-created instances after the existing post-create
global assignment. `moved.emit()` preserves the update/redraw path used by F6
after a direct local assignment.

## Checkpoints

Only the first click-created window in a run emits F9 diagnostics:

- `F9_TARGET`
- `F9_BEFORE_LOCAL_CORRECTION`
- `F9_AFTER_LOCAL_CORRECTION`
- `F9_STABILITY_NEXT_DEFERRED`
- `F9_STABILITY_AFTER_OPENING_SETTLE`

Expected static conditions are:

```text
target_position.x % 50 == 0
target_position.y % 50 == 0
AFTER_LOCAL_CORRECTION.local == target_position
STABILITY_NEXT_DEFERRED.local == target_position
STABILITY_AFTER_OPENING_SETTLE.local == target_position
```

Visual alignment remains a user test; static checkpoint equality is not a
visual `PASS` claim.

## Required Preservation

```text
drag placement source changed: NO
existing-node movement source changed: NO
F6 restoration source changed: NO
F7 grid source changed: NO
click target calculation changed: NO
click snap changed: NO
save schema changed: NO
WindowContainer/Base/Indexed extension: NO
```

F9 must not change grid render scale, Lines, `WorkspaceAreaConfig`, drag
placement, manual movement, group behavior, persistence restoration, scene or
resource files, or releases.

## Stop Conditions

Stop without an additional fix if target snapping is incorrect, local assignment
does not equal the target, stability drifts, visual alignment fails while local
equals target, or any drag/movement/selection/F6/F7 regression appears. If local
equals target but visual alignment fails, classify the issue as a deeper visual
origin or content-anchor defect; do not guess a follow-up patch.

## Artifact and Integration Boundary

- Version: `0.2.16`
- Artifact: `dist/Nekochan-ExpandedWorkspace-0.2.16.zip`
- Build: `tools/build_release.ps1 -Version 0.2.16`
- Purpose: local development canary only

No GitHub Release, tag, Workshop publication, public `master` push, merge, or
release integration is allowed in F9.

## User Test Gate

1. Install only `0.2.16`.
2. Start the game and move the camera into the expanded area.
3. Create one node through click placement.
4. Check visual grid alignment immediately.
5. Wait briefly for the opening animation to settle and check again.
6. Move the same node manually once and check alignment.
7. Exit the game and collect `[F9]` log lines.

Save/restart is not required. If performed voluntarily, record it as additional
evidence without expanding the F9 implementation scope.

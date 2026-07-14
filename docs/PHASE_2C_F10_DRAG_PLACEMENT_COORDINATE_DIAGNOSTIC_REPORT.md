# Phase 2C-F10: Drag Placement Coordinate-Domain Diagnostic Report

## Status

`DRAG_DEFERRED_MOVE_COORDINATE_DOMAIN_MISMATCH_CONFIRMED`

## Drag Path

F10 observes the existing drag flow: `screen_to_world_pos`, raw target,
clamp/snap, global pre-create assignment, creation signal, global reapply, and
the unchanged deferred `move(target)`. No drag correction is implemented.

## Click Comparison

| Item | Click F9 | Drag F10 |
| --- | --- | --- |
| Target source | `Globals.camera_center` | `Utils.screen_to_world_pos` |
| Target snap | Verified | Verified (`DRAG_TARGET_SNAP_CORRECT`) |
| Final correction | Local assignment | Existing global `move()` |
| Immediate visual result | PASS | `FAIL` |
| Opening-settle visual result | PASS | `FAIL` |

## Runtime Evidence

| Checkpoint | Status |
| --- | --- |
| D1 DRAGGER_STATE | `PASS` - input `(933.9999, 457.0)` from dragger `(883.9999, 407.0)` plus half-size `(50.0, 50.0)` |
| D2 SCREEN_TO_WORLD | `PASS` - `(11134.35, 12217.91)` |
| D3 RAW_TARGET | `PASS` - `(10959.35, 12081.91)` after offset `(175.0, 136.0)` |
| D4 SNAPPED_TARGET | `PASS` - target `(10950.0, 12100.0)`, `DRAG_TARGET_SNAP_CORRECT` |
| D5 PRE_CREATE | `PASS` - local/global equal target |
| D6 POST_CREATE | `OBSERVED` - old-bound clamp and local/global mismatch |
| D7 AFTER_REAPPLY_GLOBAL | `OBSERVED` - global nearly target, local offset |
| D8 BEFORE_DEFERRED_MOVE | `OBSERVED` - same mismatch as D7 |
| D9 AFTER_DEFERRED_MOVE | `FAIL` - global equals target; local does not |
| D10 NEXT_DEFERRED_STABILITY | `FAIL` - global equals target; local does not |
| D11 OPENING_SETTLE | `FAIL` - local/global settle to the same off-target local coordinate |

## Root Cause Classification

`DRAG_DEFERRED_MOVE_COORDINATE_DOMAIN_MISMATCH`

D4 proves that `Utils.screen_to_world_pos` feeds a correctly clamped and
50-unit-snapped drag target. The target is `(10950.0, 12100.0)` with exact
integer snap units `(219.0, 242.0)` and a zero recompute delta. The target
source is therefore not offset.

The existing final deferred `move(target)` reaches the target only in global
coordinates. Its local position remains offset through the next deferred
checkpoint, then the opening settle leaves both coordinate properties at that
same off-target local value. This is the same local/global mismatch pattern
that F8 measured for click placement, and the inverse of F9: F9's final local
assignment kept local target equality through opening settle.

The user observed the corresponding visual result: drag alignment is `FAIL`
immediately and after 0.5-1 second, then `PASS` after one manual movement. F10
does not contain a checkpoint after that manual movement, so the manual result
is recorded as a user observation rather than a measured post-move position.

The supplied visual comparison labels image 1 as click placement and image 2
as drag placement. Only image 2 and the `download_text1` D1-D11 sequence are
F10 drag evidence. Image 1 is contextual comparison with the previously
verified F9 click behavior, not a second F10 runtime target.

### Measured Coordinate Deltas

All deltas are `(observed - target)` for target `(10950.0, 12100.0)`.

| Checkpoint | local-to-target | global-to-target | global-minus-local |
| --- | ---: | ---: | ---: |
| D5 PRE_CREATE | `(0.0, 0.0)` | `(0.0, 0.0)` | `(0.0, 0.0)` |
| D6 POST_CREATE | `(-1300.0, -2350.0)` | `(-1125.002, -2214.001)` | `(174.998, 135.999)` |
| D7 AFTER_REAPPLY_GLOBAL | `(-174.998, -135.999)` | `(0.0, -10.5)` | `(174.998, 125.499)` |
| D8 BEFORE_DEFERRED_MOVE | `(-174.998, -135.999)` | `(0.0, -10.5)` | `(174.998, 125.499)` |
| D9 AFTER_DEFERRED_MOVE | `(-174.998, -125.499)` | `(0.0, 0.0)` | `(174.998, 125.499)` |
| D10 NEXT_DEFERRED_STABILITY | `(-174.998, -125.499)` | `(0.0, 0.0)` | `(174.998, 125.499)` |
| D11 OPENING_SETTLE | `(-174.998, -125.499)` | `(-174.998, -125.499)` | `(0.0, 0.0)` |

Measured equality:

```text
D4 target snap correctness: YES
D9 local == D4 target: NO
D10 local == D4 target: NO
D11 local == D4 target: NO
```

## Minimal Fix Candidate

Do not implement from F10 evidence alone. The one minimal candidate for a new
approved canary is to replace only the existing final deferred drag
`instance.call_deferred("move", target_position)` with a deferred helper that
writes `instance.position = target_position` and emits `instance.moved`.

It must retain the existing `screen_to_world_pos` target calculation, all
initial/post-create global assignments, clamping, 50-unit snap, and
`_finish_drag()` behavior. It must not alter click placement, F6 restoration,
F7 grid, manual movement, group handling, or the save schema.

## Artifact

- Version: `0.2.17`
- Filename: `Nekochan-ExpandedWorkspace-0.2.17.zip`
- Path: `dist/Nekochan-ExpandedWorkspace-0.2.17.zip`
- Size: `15099` bytes
- File count: `14`
- ZIP root: `mods-unpacked`
- SHA-256: `87dff32cbcc9f51455f2243e030b1adfd06e7375d6bbb4f933af20b5d44ea911`

The self-authored diagnostic observer is present exactly once in the ZIP. It is
not a Script Extension target and self-frees after D11.

## Runtime Delta

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

The only drag-path additions are bounded logs and a one-target observer that
records existing post-deferred state. The existing target calculation, global
assignments, deferred `move(target)`, and `_finish_drag()` remain intact.

## F6/F7/F9 Preservation

F9 click source, F6 Desktop restoration, F7 Lines/grid, workspace config, and
existing-node movement source have zero diff from the F9 evidence commit.

## Publish Safety

| Detection | Count |
| --- | ---: |
| vanilla-verbatim body | 0 |
| substantial vanilla-derived code | 0 |
| third-party copied code | 0 |
| game binary | 0 |
| game asset/resource | 0 |
| save file | 0 |
| secret | 0 |
| forbidden file/path | 0 |

No Release, tag, Workshop publication, public-master push, or v0.2.9 artifact
operation occurred.

## User Verification Status

| Test | Result |
| --- | --- |
| Drag placement immediate visual alignment | `FAIL` (user observed) |
| Drag placement after opening settles | `FAIL` (user observed) |
| Manual movement after drag placement | `PASS` (user observed) |
| D4 target snap correctness | `PASS` |
| D9 local equals target | `FAIL` |
| D10 local equals target | `FAIL` |
| D11 local equals target | `FAIL` |
| Save / restart / load | `NOT TESTED` |

## User Test Steps

F10 evidence capture is complete. Do not apply a drag correction without a
separately approved narrow canary plan.

## Updated Files

- `docs/PHASE_2C_F10_DRAG_PLACEMENT_COORDINATE_DIAGNOSTIC_PLAN.md`
- `docs/PHASE_2C_F10_DRAG_PLACEMENT_COORDINATE_DIAGNOSTIC_REPORT.md`
- `docs/HANDOFF.md`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/window_dragger.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/drag_placement_diagnostic_observer.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/manifest.json`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/mod_main.gd`

## Git State

Recorded on the local F10 branch. No push is planned.

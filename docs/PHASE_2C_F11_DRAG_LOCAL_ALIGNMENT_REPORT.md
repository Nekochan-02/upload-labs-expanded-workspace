# Phase 2C-F11: Drag Placement Local-Domain Alignment Canary Report

## Status

`F11_CANARY_READY_FOR_USER_TEST`

## Root Cause Evidence

F10 confirmed `DRAG_DEFERRED_MOVE_COORDINATE_DOMAIN_MISMATCH`. D4 target
`(10950.0, 12100.0)` was `DRAG_TARGET_SNAP_CORRECT`; the target calculation,
including `Utils.screen_to_world_pos`, is therefore not changed. D9/D10 global
position equaled target while local position retained offset
`(-174.998, -125.499)`, and D11 opening settle converged to that off-target
local coordinate.

F11 applies the successful F9 local-domain principle to the confirmed final
drag correction surface only.

## Implementation

- File: `extensions/scenes/window_dragger.gd`
- Patch surface: final deferred drag correction in `place()`
- Method: deferred `_apply_expanded_drag_local_alignment()` assigns
  `instance.position = target_position`
- Update signal: `instance.moved.emit()` immediately after local assignment
- Logging: first drag-created target only, with immediate, next-deferred, and
  one 0.5-second opening-settle checkpoints

The final drag correction does not use `move()`, `move_snapped()`,
`global_position`, re-snapping, or target recalculation.

## Runtime Delta

F11 changes only the coordinate domain of the existing final deferred drag
correction. The target calculation, `Utils.screen_to_world_pos`, bounds, snap,
initial/post-create global assignments, and `_finish_drag()` are unchanged.

## F6/F7/F9 Preservation

```text
click placement source changed: NO
grid source changed: NO
Desktop restoration source changed: NO
drag target calculation changed: NO
snap interval changed: NO
existing-node movement changed: NO
WindowContainer/Base/Indexed extension: NO
save schema changed: NO
```

## Static Audit

| Check | Result |
| --- | --- |
| Drag final correction uses local `position` | YES |
| Drag final correction uses `move()` | NO |
| Drag final correction uses `global_position` | NO |
| Drag target calculation changed | NO |
| Drag snap changed | NO |
| Click placement changed | NO |
| F6 restoration changed | NO |
| F7 grid changed | NO |
| WindowContainer extension | NO |
| Save schema changed | NO |

## Artifact

- Version: `0.2.18`
- Filename: `Nekochan-ExpandedWorkspace-0.2.18.zip`
- Path: `dist/Nekochan-ExpandedWorkspace-0.2.18.zip`
- Size: `14804` bytes
- File count: `14`
- ZIP root: `mods-unpacked`
- Manifest version: `0.2.18`
- SHA-256: `191d24db43c697825024ac7f5575a11038157c407a0a10da75b3cb6baac04190`

The artifact was generated from the repository source with
`tools/build_release.ps1 -Version 0.2.18`.

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

The source review found only the self-authored F11 helper and bounded
diagnostics. ZIP inspection found no forbidden file extension or path term.
Credential signature scans for AWS keys, GitHub tokens, and private-key blocks
each returned zero matches. No Release, tag, Workshop publication, public
`master` push, or v0.2.9 artifact operation is part of F11.

## User Verification Status

| Test | Result |
| --- | --- |
| Drag placement immediate visual alignment | `NOT TESTED` |
| Drag placement after opening settles | `NOT TESTED` |
| Manual movement after drag placement | `NOT TESTED` |
| Optional click placement regression | `NOT TESTED` |
| F11 target snap correctness | `NOT TESTED` |
| AFTER_LOCAL == TARGET | `NOT TESTED` |
| NEXT_DEFERRED_LOCAL == TARGET | `NOT TESTED` |
| OPENING_SETTLE_LOCAL == TARGET | `NOT TESTED` |

## User Test Steps

Install only `0.2.18`, create one expanded-area drag-placed node, assess grid
alignment immediately and after opening settles, move that node once, then
provide the `[F11]` checkpoint lines after exit. An optional click placement
checks that F9 behavior did not regress. Save/restart and group tests are not
required.

## Updated Files

- `docs/PHASE_2C_F11_DRAG_LOCAL_ALIGNMENT_PLAN.md`
- `docs/PHASE_2C_F11_DRAG_LOCAL_ALIGNMENT_REPORT.md`
- `docs/HANDOFF.md`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/window_dragger.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/drag_placement_diagnostic_observer.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/manifest.json`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/mod_main.gd`

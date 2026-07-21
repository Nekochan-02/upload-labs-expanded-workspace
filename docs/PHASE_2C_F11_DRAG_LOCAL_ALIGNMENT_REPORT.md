# Phase 2C-F11: Drag Placement Local-Domain Alignment Canary Report

## Status

`F11_DRAG_LOCAL_ALIGNMENT_VERIFIED`

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
- Method: a self-freeing root observer defers local assignment
  `window.position = target_position` after the dragger queues itself for deletion
- Update signal: `instance.moved.emit()` immediately after local assignment
- Logging: one bounded checkpoint sequence per dragger instance, with immediate,
  next-deferred, and one 0.5-second opening-settle checkpoints

The final drag correction does not use `move()`, `move_snapped()`,
`global_position`, re-snapping, or target recalculation.

## Runtime Delta

F11 changes only the coordinate domain of the existing final deferred drag
correction. The target calculation, `Utils.screen_to_world_pos`, bounds, snap,
initial/post-create global assignments, and `_finish_drag()` are unchanged.

## F11 Runtime Evidence

The user tested only `0.2.18` in the Mod folder. Save/restart/load was not
tested. The primary F11 sample is `download_text3`:

| Checkpoint | Local position | Global position | Result |
| --- | ---: | ---: | --- |
| F11_TARGET | target `(11900.0, 12100.0)` | n/a | `TARGET_SNAP_CORRECT` |
| F11_BEFORE_LOCAL_CORRECTION | `(11725.0, 11964.0)` | `(11900.0, 12089.5)` | local offset present |
| F11_AFTER_LOCAL_CORRECTION | `(11900.0, 12100.0)` | `(12075.0, 12225.5)` | local equals target |
| F11_NEXT_DEFERRED_STABILITY | `(11900.0, 12100.0)` | `(12075.0, 12225.5)` | local equals target |
| F11_OPENING_SETTLE_STABILITY | `(11900.0, 12100.0)` | `(11900.0, 12100.0)` | local/global equal target |

Measured equality:

```text
AFTER_LOCAL == TARGET: YES
NEXT_DEFERRED_LOCAL == TARGET: YES
OPENING_SETTLE_LOCAL == TARGET: YES
```

Two additional captured drag targets, `download_manager1` and `download_text4`,
have the same outcome: target snap is correct and each AFTER/NEXT/SETTLE local
position exactly equals its target. They are corroborating runtime evidence,
not extra required user tests.

The user visually verified drag alignment `PASS` immediately, after 0.5-1
seconds, and after one manual movement. Optional click placement is also
`PASS`. The checkpoint evidence and visual behavior agree: F11 resolves the
F10 drag local-domain mismatch.

### Diagnostic Scope Observation

F11 emitted three one-shot sequences in the same game session because the
one-target flag belongs to each newly created dragger instance. The output is
still bounded per placement and has no `_process()` or timer loop, but it does
not enforce the intended one target for the whole game session. This does not
affect the verified correction result; do not alter it without a separately
approved diagnostics-only cleanup plan.

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
- Size: `14600` bytes
- File count: `14`
- ZIP root: `mods-unpacked`
- Manifest version: `0.2.18`
- SHA-256: `daf4d0a509aa6ead6f081d3de6ebb69298da6dba7f1d4a4f115a2b2af627441a`

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
| Drag placement immediate visual alignment | `PASS` |
| Drag placement after opening settles | `PASS` |
| Manual movement after drag placement | `PASS` |
| Optional click placement regression | `PASS` |
| F11 target snap correctness | `PASS` |
| AFTER_LOCAL == TARGET | `PASS` |
| NEXT_DEFERRED_LOCAL == TARGET | `PASS` |
| OPENING_SETTLE_LOCAL == TARGET | `PASS` |
| Save / restart / load | `NOT TESTED` |

## User Test Steps

F11 runtime verification is complete. Save/restart, group persistence, full
regression, and release integration remain out of scope.

## Updated Files

- `docs/PHASE_2C_F11_DRAG_LOCAL_ALIGNMENT_PLAN.md`
- `docs/PHASE_2C_F11_DRAG_LOCAL_ALIGNMENT_REPORT.md`
- `docs/HANDOFF.md`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/window_dragger.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/drag_placement_diagnostic_observer.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/manifest.json`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/mod_main.gd`

# Phase 2C-F10: Drag Placement Coordinate-Domain Diagnostic Report

## Status

`F10_DIAGNOSTIC_READY_FOR_USER_TEST`

## Drag Path

F10 observes the existing drag flow: `screen_to_world_pos`, raw target,
clamp/snap, global pre-create assignment, creation signal, global reapply, and
the unchanged deferred `move(target)`. No drag correction is implemented.

## Click Comparison

| Item | Click F9 | Drag F10 |
| --- | --- | --- |
| Target source | `Globals.camera_center` | `Utils.screen_to_world_pos` |
| Target snap | Verified | `NOT TESTED` |
| Final correction | Local assignment | Existing global `move()` |
| Immediate visual result | PASS | `NOT TESTED` |
| Opening-settle visual result | PASS | `NOT TESTED` |

## Runtime Evidence

| Checkpoint | Status |
| --- | --- |
| D1 DRAGGER_STATE | `NOT TESTED` |
| D2 SCREEN_TO_WORLD | `NOT TESTED` |
| D3 RAW_TARGET | `NOT TESTED` |
| D4 SNAPPED_TARGET | `NOT TESTED` |
| D5 PRE_CREATE | `NOT TESTED` |
| D6 POST_CREATE | `NOT TESTED` |
| D7 AFTER_REAPPLY_GLOBAL | `NOT TESTED` |
| D8 BEFORE_DEFERRED_MOVE | `NOT TESTED` |
| D9 AFTER_DEFERRED_MOVE | `NOT TESTED` |
| D10 NEXT_DEFERRED_STABILITY | `NOT TESTED` |
| D11 OPENING_SETTLE | `NOT TESTED` |

## Root Cause Classification

`UNRESOLVED` pending user visual results and D1-D11 logs.

## Minimal Fix Candidate

None. F10 is diagnostic-only.

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
| Drag placement immediate visual alignment | `NOT TESTED` |
| Drag placement after opening settles | `NOT TESTED` |
| Manual movement after drag placement | `NOT TESTED` |
| D4 target snap correctness | `NOT TESTED` |
| D9 local equals target | `NOT TESTED` |
| D10 local equals target | `NOT TESTED` |
| D11 local equals target | `NOT TESTED` |

## User Test Steps

1. Install only `0.2.17`.
2. Move the camera into the expanded area.
3. Create one node by drag placement.
4. Check alignment immediately and after 0.5-1 second.
5. Move the same node once and check alignment.
6. Exit the game and provide the `[F10]` D1-D11 log lines.

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

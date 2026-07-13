# Phase 2C-F8: Click Placement Coordinate-Domain Diagnostic Report

## Status

`DIAGNOSTIC_ARTIFACT_PENDING_USER_TEST`

## User Result

`NOT TESTED`. The F8 artifact has not been run by the user.

## Click Path

F8 is a diagnostic-only extension of the existing F7 click-placement path. It
captures one click-created window through C1-C9 without changing its target
calculation, snap interval, or placement assignments.

## Drag Path

The verified F7 drag path remains unchanged: it derives a world target through
`Utils.screen_to_world_pos`, writes `global_position`, emits `create_window`,
reapplies `global_position`, and defers `move(target)`. User result: `PASS`.

## Movement Path

The verified existing-window movement path remains unchanged. It uses the
existing movement/snap behavior after parenting. User result: `PASS`.

| Path | Click | Drag | Existing movement |
| --- | --- | --- | --- |
| Target source | `Globals.camera_center - size / 2` | `Utils.screen_to_world_pos(...)` | Existing drag selection target |
| Coordinate conversion | None in current click path | Screen to world | Existing window movement path |
| Snap | Existing `snappedf(50)` | Existing `snappedf(50)` | Existing window snap |
| Pre-create assignment | `global_position = target` | `global_position = target` | Not applicable |
| Post-create assignment | Existing global reapply | Existing global reapply | Not applicable |
| Deferred move | Existing `move(target)` | Existing `move(target)` | Existing movement API |
| User result | `NOT TESTED` for F8; F7 symptom `FAIL` | F7 `PASS` | F7 `PASS` |

## Runtime Evidence

| Checkpoint | Status | Evidence |
| --- | --- | --- |
| C1 CAMERA_CENTER | `NOT TESTED` | Awaiting user log collection. |
| C2 RAW_TARGET | `NOT TESTED` | Awaiting user log collection. |
| C3 SNAPPED_TARGET | `NOT TESTED` | Awaiting user log collection. |
| C4 PRE_CREATE | `NOT TESTED` | Awaiting user log collection. |
| C5 POST_CREATE | `NOT TESTED` | Awaiting user log collection. |
| C6 AFTER_REAPPLY_GLOBAL | `NOT TESTED` | Awaiting user log collection. |
| C7 BEFORE_DEFERRED_MOVE | `NOT TESTED` | Awaiting user log collection. |
| C8 AFTER_DEFERRED_MOVE | `NOT TESTED` | Awaiting user log collection. |
| C9 STABILITY | `NOT TESTED` | Awaiting user log collection. |

## Snap Arithmetic

`NOT TESTED`. C3 will log a recomputed 50-unit target, its x/y snap-unit delta
from the nearest integer, and `TARGET_SNAP_CORRECT` or `TARGET_SNAP_INCORRECT`.

## Coordinate Deltas

`NOT TESTED`. C4-C9 will log `local_to_target`, `global_to_target`, and
`global_local` for the one diagnostic target.

## Deferred Move Impact

`NOT TESTED`. C5/C6/C8/C9 will determine whether the existing deferred
`WindowContainer.move(target_position)` changes coordinate domain.

## Root Cause Classification

`UNRESOLVED` pending the user visual result and C1-C9 runtime evidence.

## Minimal Fix Candidate

None. F8 is diagnostic-only and must not implement a click-placement repair.

## Artifact

- Filename: `Nekochan-ExpandedWorkspace-0.2.15.zip`
- Path: `dist/Nekochan-ExpandedWorkspace-0.2.15.zip`
- Version / manifest version: `0.2.15`
- Size: `13113` bytes
- File count: `13`
- ZIP root: `mods-unpacked`
- SHA-256: `4677776d803b53a13512f49434c691c2ec6dbc2e4790b1f6d9349903ea3eabe7`

## Runtime Delta

```text
F7 grid changed: NO
F6 restoration changed: NO
click behavior changed: NO
click diagnostic added: YES
drag changed: NO
movement changed: NO
snap changed: NO
save schema changed: NO
```

## F6/F7 Preservation

The F7 Lines renderer, F6 Desktop restoration extension, and drag placement
extension have no source diff from the F7 baseline. No WindowContainer,
WindowBase, WindowIndexed, or connector-point extension is packaged.

## Publish Safety

| Check | Count |
| --- | ---: |
| Vanilla-verbatim function body | 0 |
| Substantial vanilla-derived code | 0 |
| Third-party copied code | 0 |
| Game binary | 0 |
| Game asset/resource | 0 |
| Save file | 0 |
| Secret | 0 |
| Forbidden file/path | 0 |

The artifact is a local development diagnostic only. No Release, Draft Release,
tag, Workshop upload, public-master push, or v0.2.9 artifact operation occurred.

## User Test Matrix

| Check | Status |
| --- | --- |
| Initial expanded-area click placement visual alignment | `NOT TESTED` |
| Manual movement visual alignment | `NOT TESTED` |
| F8 log collection | `NOT TESTED` |

## Conclusion

No click-placement cause or repair has been concluded. F8 must remain a
development diagnostic artifact until the user supplies the visual result and
the `[F8]` C1-C9 logs.

## Updated Files

- `docs/PHASE_2C_F8_CLICK_PLACEMENT_COORDINATE_DIAGNOSTIC_PLAN.md`
- `docs/PHASE_2C_F8_CLICK_PLACEMENT_COORDINATE_DIAGNOSTIC_REPORT.md`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/windows_tab.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/manifest.json`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/mod_main.gd`

## Git State

Recorded on the local F8 branch. No push is planned.

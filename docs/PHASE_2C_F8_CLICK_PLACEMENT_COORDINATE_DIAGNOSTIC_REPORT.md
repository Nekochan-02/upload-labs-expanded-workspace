# Phase 2C-F8: Click Placement Coordinate-Domain Diagnostic Report

## Status

`DIAGNOSTIC_EVIDENCE_CAPTURED`

## User Result

The user tested v0.2.15 with one expanded-area click-created node:

| Check | Result |
| --- | --- |
| Initial click-placement visual grid alignment | `FAIL` |
| After one manual movement visual grid alignment | `PASS` |
| Save / restart / load | Not tested; out of F8 scope |

The supplied screenshots are consistent with an initially offset visible window
that is aligned after the later manual movement.

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
| C1 CAMERA_CENTER | `PASS` | Captured from `modloader.log`. |
| C2 RAW_TARGET | `PASS` | Captured from `modloader.log`. |
| C3 SNAPPED_TARGET | `PASS` | `TARGET_SNAP_CORRECT`. |
| C4 PRE_CREATE | `PASS` | Captured from `modloader.log`. |
| C5 POST_CREATE | `PASS` | Captured from `modloader.log`. |
| C6 AFTER_REAPPLY_GLOBAL | `PASS` | Captured from `modloader.log`. |
| C7 BEFORE_DEFERRED_MOVE | `PASS` | Captured from `modloader.log`. |
| C8 AFTER_DEFERRED_MOVE | `PASS` | Captured from `modloader.log`. |
| C9 STABILITY | `PASS` | Captured from `modloader.log`. |

The actual `modloader.log` contains one F8 target, `download_text` / later
renamed `download_text1`:

| Checkpoint | Measured value |
| --- | --- |
| C1 CAMERA_CENTER | `(15550.68, 18198.79)`; window size `(350.0, 272.0)` |
| C2 RAW_TARGET | `(15375.68, 18062.79)` |
| C3 SNAPPED_TARGET | `(15400.0, 18050.0)` |
| C4 PRE_CREATE | local/global `(15400.0, 18050.0)`; no parent |
| C5 POST_CREATE | local `(9650.0, 9750.0)`; global `(9824.998, 9885.999)` |
| C6 AFTER_REAPPLY_GLOBAL | local `(15225.0, 17914.0)`; global `(15400.0, 18039.5)` |
| C7 BEFORE_DEFERRED_MOVE | same as C6 |
| C8 AFTER_DEFERRED_MOVE | local `(15225.0, 17924.5)`; global `(15400.0, 18050.0)` |
| C9 STABILITY | same as C8 |

## Snap Arithmetic

`PASS`. C3 reports `TARGET_SNAP_CORRECT`: recomputed target equals C3, both
target-recompute and nearest-50-unit deltas are `(0.0, 0.0)`, and snap units are
exact integers `(308.0, 361.0)`.

## Coordinate Deltas

| Checkpoint | Local to C3 | Global to C3 | Global minus local |
| --- | ---: | ---: | ---: |
| C4 | `(0.0, 0.0)` | `(0.0, 0.0)` | `(0.0, 0.0)` |
| C5 | `(-5750.0, -8300.0)` | `(-5575.002, -8164.001)` | `(174.998, 135.999)` |
| C6 | `(-174.998, -135.998)` | `(0.0, -10.5)` | `(174.998, 125.498)` |
| C7 | `(-174.998, -135.998)` | `(0.0, -10.5)` | `(174.998, 125.498)` |
| C8 | `(-174.998, -125.498)` | `(0.0, 0.0)` | `(174.998, 125.498)` |
| C9 | `(-174.998, -125.498)` | `(0.0, 0.0)` | `(174.998, 125.498)` |

The parent transform origin safely obtained at C5-C9 is `(0.0, 0.0)`. The C5
delta is effectively half of the initial window size `(175.0, 136.0)`, matching
vanilla `WindowContainer._ready()` setting `pivot_offset = size / 2` followed by
`scale = Vector2(0, 0)`. This is not a fixed parent transform delta. F6 also
observed nonzero, window-dependent global/local deltas while new windows were
under the same opening lifecycle; the numeric offsets differ by window.

## Deferred Move Impact

C7 to C8 changes global y by `+10.5` so that C8/C9 global position exactly
equals C3. It does not introduce a later global drift. It leaves the local
coordinate non-grid-aligned because `WindowContainer.move()` writes a global
position while the opening pivot/scale transform is active.

## Root Cause Classification

`VISUAL_ORIGIN_MISMATCH`.

C3 is valid and C8/C9 global position equals C3 exactly, eliminating the grid
renderer and snap calculation as causes. C5 proves the old-boundary creation
clamp occurs, but the existing reapply/deferred path restores the global target.
The remaining visible offset is explained by the new window's vanilla opening
pivot/scale transform: its local layout coordinate remains offset while that
transform is active. The parent transform origin is zero, so this is not the
F6 saved-local-as-global persistence error and is not a parent transform issue.

## Minimal Fix Candidate

One candidate only, not implemented: replace the click path's current deferred
global `move(target_position)` correction with a one-shot deferred local
assignment, `instance.position = target_position; instance.moved.emit()`, at
the same lifecycle point. This mirrors F6's proven local-domain restoration and
would make the settled window's local grid coordinate exact without changing
grid, snap interval, drag placement, movement, or F6 restoration. It requires
a separate approved canary because F8 did not log the opening tween's settled
frame.

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
| Initial expanded-area click placement visual alignment | `FAIL` |
| Manual movement visual alignment | `PASS` |
| F8 log collection | `PASS` |

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

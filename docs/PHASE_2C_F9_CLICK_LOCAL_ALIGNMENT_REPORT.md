# Phase 2C-F9: Click Placement Local-Domain Alignment Canary Report

## Status

`F9_CLICK_ALIGNMENT_VERIFIED_DRAG_ALIGNMENT_REGRESSION_OBSERVED`

## Root Cause Evidence

F8 captured `VISUAL_ORIGIN_MISMATCH`: C3 target `(15400.0, 18050.0)` was
`TARGET_SNAP_CORRECT`; C8/C9 global equaled C3, but C8/C9 local was
`(15225.0, 17924.5)`. The click-created node was visually off-grid until one
manual movement, while F7 drag placement and existing-node movement remained
`PASS`. This excludes target arithmetic, snap interval, and F7 grid geometry as
the initial patch surfaces.

## Implementation

- File: `extensions/scripts/windows_tab.gd`
- Patch surface: the existing final deferred click correction in `add_window()`
- Method: one click-only deferred helper writes `window.position = target_position`
- Update signal: `window.moved.emit()` directly after the local assignment
- Logging: first click-created window only, with `F9_TARGET`, before/after local
  correction, next-deferred stability, and one 0.5-second opening-settle check

The previous final `move(target_position)` call is absent from the click path.
The helper neither writes `global_position` nor calls `move_snapped()` or
re-snaps the target.

## Runtime Delta

The correction alters only the coordinate domain used by the final deferred
click-placement correction. Existing initial and post-create global assignments,
target calculation, bounds, and 50-unit snap arithmetic are unchanged.

## F9 Runtime Evidence

The user tested only v0.2.16 in the Mod folder. No save/restart/load test was
performed.

| Checkpoint | Local position | Global position | Result |
| --- | ---: | ---: | --- |
| F9_TARGET | target `(10350.0, 13350.0)` | n/a | `TARGET_SNAP_CORRECT` |
| F9_BEFORE_LOCAL_CORRECTION | `(10175.0, 13214.0)` | `(10350.0, 13339.5)` | local offset present |
| F9_AFTER_LOCAL_CORRECTION | `(10350.0, 13350.0)` | `(10525.0, 13475.5)` | local equals target |
| F9_STABILITY_NEXT_DEFERRED | `(10350.0, 13350.0)` | `(10525.0, 13475.5)` | local equals target |
| F9_STABILITY_AFTER_OPENING_SETTLE | `(10350.0, 13350.0)` | `(10350.0, 13350.0)` | local/global equal target |

Measured equality:

```text
AFTER_LOCAL == TARGET: YES
NEXT_DEFERRED_LOCAL == TARGET: YES
OPENING_SETTLE_LOCAL == TARGET: YES
```

The user also observed click-placement alignment as `PASS` immediately, after
the opening tween settles, and after one manual movement. This confirms the F9
local-domain correction resolves the F8 click-placement alignment defect.

The user separately observed drag placement as visually misaligned. F9 does
not change drag source, but its preservation gate is therefore not satisfied.
Treat this as a newly observed drag-alignment regression/defect and do not
extend F9 with a speculative repair.

## F6/F7 Preservation

```text
drag placement source changed: NO
existing-node movement source changed: NO
F6 restoration source changed: NO
F7 grid source changed: NO
WindowContainer/Base/Indexed extension: NO
save schema changed: NO
```

## Static Audit

| Check | Result |
| --- | --- |
| Click final correction uses local `position` | YES |
| Click final correction uses `move()` | NO |
| Click final correction uses `global_position` | NO |
| Click target calculation changed | NO |
| Click snap changed | NO |
| Drag placement changed | NO |
| Manual movement changed | NO |
| F6 restoration changed | NO |
| F7 grid changed | NO |
| WindowContainer extension | NO |
| Save schema changed | NO |

The source-diff preservation check is `PASS` (`drag placement changed: NO`),
but the latest user runtime observation is `FAIL` for drag visual alignment.
This blocks a broader F9 pass until a dedicated drag-path diagnostic is
approved.

## Artifact

- version: `0.2.16`
- filename: `Nekochan-ExpandedWorkspace-0.2.16.zip`
- path: `dist/Nekochan-ExpandedWorkspace-0.2.16.zip`
- size: `13004` bytes
- file count: `13`
- ZIP root: `mods-unpacked`
- SHA-256: `24abbe45d5f407a3d3deed612a646621f015d8cad8d6709818a5a591fe5e0b4b`

The packaged `windows_tab.gd` exactly matches the F9 source file.

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

No release, tag, Workshop publication, public `master` push, or merge is part
of F9. The v0.2.9 artifact remains unchanged with SHA-256
`fc8ddab1a3f73c468eb5a1fbb2702a683629c703d67498c983ad0e52f8a038af`.

## User Verification Status

| Test | Result |
| --- | --- |
| Click placement immediate visual alignment | `PASS` |
| Click placement after opening settles | `PASS` |
| Manual movement after click placement | `PASS` |
| F9 target snap correctness | `PASS` |
| AFTER_LOCAL == TARGET | `PASS` |
| STABILITY_LOCAL == TARGET | `PASS` |
| Drag placement visual alignment | `FAIL` (user observed) |
| Save / restart / load | `NOT TESTED` |

## User Test Steps

Install only `0.2.16`, create one click-placed node in the expanded area, check
alignment immediately and after the opening animation settles, move the same
node once, then provide the visual outcome and `[F9]` log lines after exit.

## Release Boundary

F9 is a local development canary. Release integration remains deferred. The
click gate is complete, but the drag-alignment regression/defect blocks any
broader integration.

## Updated Files

- `docs/PHASE_2C_F9_CLICK_LOCAL_ALIGNMENT_PLAN.md`
- `docs/PHASE_2C_F9_CLICK_LOCAL_ALIGNMENT_REPORT.md`
- `docs/HANDOFF.md`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/windows_tab.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/manifest.json`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/mod_main.gd`

## Git State

Recorded on the local F9 branch. No push is planned.

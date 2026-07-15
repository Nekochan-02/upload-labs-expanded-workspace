# Phase 2C-F14: Group Resize Expanded-Bounds Canary Report

## Status

`F14_PRIMARY_OLD_BOUND_SNAP_VERIFIED_SIZE_CALCULATION_BLOCKER_REMAINS`

F14 is a local development canary. It is not a release candidate and must not
be published, tagged, pushed to public master, uploaded to Workshop, or used to
replace the blocked v0.2.9 artifact.

## User Test Result

The user installed only `0.2.21`, created a group beyond the old boundary, and
ran the F13 top-left resize path. The frame remained visible at drag start,
enlarged normally, and remained after release. Children plus connection and
state remained. No save was made.

The user then created a group, placed two nodes in it, connected them, and
attempted another resize. That populated group became abnormally thin and tall.
No save was made after that failure. This second resize is outside F14's
one-target diagnostic budget, so it has no F14 checkpoint evidence and must
not be attributed to a specific edge or formula without a new diagnostic.

## Runtime Evidence

Source: `C:\Users\shian\AppData\Roaming\Upload Labs\logs\godot.log`, F14 lines.

| Checkpoint | Measured state |
|---|---|
| `F14_RESIZE_MOVE_SNAPPED_INPUT` | `group13`; input/clamped/snapped target all `(16850,18600)`; before `(16850,18600)`; size `(300,200)`; left/top flags true; in tree and visible. |
| `F14_RESIZE_MOVE_SNAPPED_OUTPUT` | Same target and position after; size `(300,200)`; left/top flags remain true; in tree and visible. |
| `F14_AFTER_RESIZE_FIRST_FRAME` | Position `(16850,18600)`, size `(300,200)`, left/top flags true, in tree and visible. |
| `F14_AFTER_RELEASE_OR_CANCEL` | `resize_branch_used=true`; position `(16550,18250)`; size `(600,550)`; flags false; in tree and visible. |

The output proves that the F14 expanded-bounds resize branch was selected and
prevented the old-bound jump for the reproduced left/top path. It does not
measure the later populated-group failure. No F14-specific warning, exception,
or parse failure was logged.

## Root Cause Evidence

F13 showed that original group resize calls `move_snapped(new_rect.position)`.
The inherited snap clamped a valid expanded-area frame from `(18800,16600)` to
the old-bound maximum `(9700,9800)` with zero mouse delta. The group was not
destroyed, hidden, collapsed, or reparented.

## Implementation

- Version: `0.2.21`
- File: `extensions/scenes/windows/window_group.gd`
- Method: `move_snapped(to)`
- Resize guard: direct access to `resizing_left/right/top/bottom`
- Resize branch: expanded maximum plus the existing 50-unit snap and move path
- Non-resize path: `super.move_snapped(to)`
- Logging: one F14 resize move input/output, one deferred frame, one release
  checkpoint per first edge resize sequence

## Runtime Delta

Only `WindowGroup.move_snapped()` calls made while a resize flag is true use
the expanded bounds. Width/height calculation and all non-resize calls retain
the prior implementation path.

## Preservation

F6 restoration, F7 grid, F9 click, F11 drag, F12 persistence logic, save
schema, normal group movement, and blocked Window extension paths are unchanged.

Runtime non-resize movement was not exercised as part of F14. The delegation is
verified statically by the false resize-flag branch calling
`super.move_snapped(to)`.

## Static Audit

| Check | Result |
|---|---|
| `get_position_snapped()` override | NO |
| WindowContainer/Base/Indexed extension | NO |
| Group resize size calculation changed | NO |
| Normal group movement changed | NO |
| F6/F7/F9/F11/F12 changed | NO |
| Save schema changed | NO |
| Non-resize `move_snapped()` delegates to `super` | YES |

## Artifact

- Build command: `tools/build_release.ps1 -Version 0.2.21`
- Filename: `Nekochan-ExpandedWorkspace-0.2.21.zip`
- Path: `dist/Nekochan-ExpandedWorkspace-0.2.21.zip`
- Size: `19008 bytes`
- File count: `15`
- ZIP root: `mods-unpacked`
- Manifest version: `0.2.21`
- SHA-256: `f143f88b3287dcb5cc953d4a0027dff0bda1c4f21e03303cce16028ec6bb60b4`

## Publish Safety

| Audit item | Count |
|---|---:|
| vanilla-verbatim body | 0 |
| substantial vanilla-derived code | 0 |
| third-party copied code | 0 |
| game binary | 0 |
| game asset/resource | 0 |
| save file | 0 |
| secret | 0 |
| forbidden file/path | 0 |

The ZIP contains only the expected `mods-unpacked/Nekochan-ExpandedWorkspace`
tree. It contains no `vanilla-reference`, game binary, `.pck`, scene/resource,
save, secret, log, or Workshop path.

## User Verification Status

| Test | Result |
|---|---|
| Group resize drag start remains visible | USER VERIFIED PASS, primary F13 path |
| Group does not jump to old boundary | USER VERIFIED PASS, primary F13 path |
| Group can be enlarged in expanded area | USER VERIFIED PASS, primary F13 path |
| Group size does not collapse | USER OBSERVED FAIL, later populated-group resize |
| Children remain | USER VERIFIED PASS, primary path |
| Connection/state remain | USER VERIFIED PASS, primary path |
| F14 resize branch used | LOG VERIFIED PASS |
| Non-resize delegation preserved | STATIC VERIFIED; runtime NOT TESTED |

Codex has not run the game. User verification and log-verified results above
are scoped to the tested primary path. The later size-collapse symptom remains
an unclassified blocker.

## Next Diagnostic Only

F15 is planned in
`docs/PHASE_2C_F15_POPULATED_GROUP_RESIZE_SIZE_COLLAPSE_PLAN.md`. It is a
separate, diagnostics-only investigation of the populated-group size-collapse
blocker. It must capture one selected edge and one bounded resize sequence,
including `drag_start_rect`, mouse delta, independently derived
`new_rect`-equivalent candidates, frame/child geometry, and old versus expanded
width/height clamp candidates. Do not implement a size fix from F14 evidence or
modify the verified F14 position-snap branch.

## User Test Steps

Use a temporary test state. Do not save after failure.

1. Install only `Nekochan-ExpandedWorkspace-0.2.21.zip`.
2. Start the game and move to the expanded area.
3. Create one group clearly beyond the old boundary.
4. Use the top-left edge/corner path from F13.
5. Start resize drag and check for a jump or disappearance.
6. If it remains visible, enlarge it slightly and release.
7. Check group visibility/size and whether children plus connection/state remain.
8. Do not save if any failure occurs; exit and provide `[F14]` logs.

Do not test save/restart, group persistence, full regression, or release
integration in F14.

# Phase 2C-F14: Group Resize Expanded-Bounds Canary Report

## Status

`F14_CANARY_READY_FOR_USER_TEST`

F14 is a local development canary. It is not a release candidate and must not
be published, tagged, pushed to public master, uploaded to Workshop, or used to
replace the blocked v0.2.9 artifact.

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
| Group resize drag start remains visible | NOT TESTED |
| Group does not jump to old boundary | NOT TESTED |
| Group can be enlarged in expanded area | NOT TESTED |
| Group size does not collapse | NOT TESTED |
| Children remain | NOT TESTED |
| Connection/state remain | NOT TESTED |
| F14 resize branch used | NOT TESTED |
| Non-resize delegation preserved | NOT TESTED |

Codex has not run the game and does not mark any F14 behavior as PASS.

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

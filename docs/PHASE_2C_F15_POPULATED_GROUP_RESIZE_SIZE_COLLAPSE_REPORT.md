# Phase 2C-F15: Populated Group Resize Size-Collapse Diagnostic Report

## Status

`F15_DIAGNOSTIC_CANARY_READY_FOR_USER_TEST`

F15 is a local development diagnostic artifact. It is not a release candidate.
Do not publish, tag, push to public master, upload to Workshop, or replace the
blocked v0.2.9 artifact.

## Purpose

F14 remains verified for its primary left/top old-bound position-snap path.
F15 records the separate populated-group thin/tall observation without
changing resize behavior. It has no runtime classification before user evidence
is collected.

## Implementation Scope

- Version: `0.2.22`
- Target: existing `extensions/scenes/windows/window_group.gd`
- Target selection: exactly one group containing exactly two fully enclosed
  selectable windows.
- Sequence limit: one eligible edge-resize sequence per game session.
- Runtime effect: logging only; it does not assign position, size,
  `custom_minimum_size`, child geometry, or save data.

## Diagnostic Checkpoints

| Checkpoint | Timing |
|---|---|
| `S1_BEFORE_POPULATED_RESIZE` | before the selected edge flag is set |
| `S2_RESIZE_START` | after vanilla records resize flags and drag-start state |
| `S3_FIRST_SIZE_CALCULATION` | before the first vanilla resize process |
| `S4_AFTER_FIRST_RESIZE_PROCESS` | after that process returns |
| `S5_AFTER_RELEASE` | after vanilla clears resize flags |
| `S6_ONE_FRAME_AFTER_RELEASE` | one deferred frame after release |

The edge/corner is taken directly from the clicked resize handler. F15 logs a
pure, independently derived candidate for both the old `10000` and expanded
workspace bounds. It does not copy or replace the vanilla resize process.
One ineligible-target `STOP` line is also allowed per session; it does not
consume the future eligible target and cannot repeat continuously.

## Geometry Metrics

Each checkpoint records frame local/global position, size,
`custom_minimum_size`, scale, visibility, tree state, parent path, resize flags,
drag-start rectangle/mouse, current snapped mouse, mouse delta, old/expanded
candidate rectangles and snapped positions, and minimum-size violations.

The two initially enclosed windows are retained as the diagnostic sample even
if the frame later no longer encloses them. Their local/global positions, sizes,
relative frame positions, aggregate bounding boxes, validity, and enclosed
connector-point count are logged without mutation.

## Runtime Delta

F15 adds bounded log calls around the existing group edge-handler and first
resize-process lifecycle. `super._process(delta)` remains the resize executor.
The existing F14 `move_snapped(to)` resize branch is unchanged.

## Preservation

F14 old-bound snap, F6 restoration, F7 grid, F9 click alignment, F11 drag
alignment, F12 group persistence logic, normal group movement, save schema,
node limits, and space-upgrade cap are unchanged.

## Static Audit

| Check | Result |
|---|---|
| F14 old-bound snap fix changed | NO |
| Group resize behavior changed | NO |
| Group size calculation changed | NO |
| Child positions changed | NO |
| F6/F7/F9/F11/F12 changed | NO |
| Save schema changed | NO |
| WindowContainer/Base/Indexed extension added | NO |
| `get_position_snapped()` override added | NO |
| Large vanilla body copy | NO |
| Every-frame or continuous logging | NO |

## Artifact

- Build command: `tools/build_release.ps1 -Version 0.2.22`
- Filename: `Nekochan-ExpandedWorkspace-0.2.22.zip`
- Path: `dist/Nekochan-ExpandedWorkspace-0.2.22.zip`
- Size: `20863 bytes`
- File count: `15`
- ZIP root: `mods-unpacked`
- Manifest version: `0.2.22`
- SHA-256: `8f00f3c82429a88b4e8fea672baafe209c9e12946bc9bc4c295f05554d6fb84e`

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

The ZIP was inspected after the final build: it has one `mods-unpacked` root,
15 allowed GDScript/metadata files, and no forbidden extension or path term.

## User Verification Status

| Test | Result |
|---|---|
| Populated group resize reproduces collapse | NOT TESTED |
| Edge/corner identified | NOT TESTED |
| Width collapse | NOT TESTED |
| Height collapse | NOT TESTED |
| Minimum size interaction | NOT TESTED |
| Child bounding box interaction | NOT TESTED |
| Old-bound candidate implicated | NOT TESTED |
| Expanded-bound candidate implicated | NOT TESTED |
| Classification | NOT TESTED |

Codex has not run the game. Runtime classification is intentionally deferred to
user evidence and actual `[F15]` log lines.

## User Test Steps

Use a temporary state. Do not test an important save.

1. Put only `Nekochan-ExpandedWorkspace-0.2.22.zip` in the Mod folder.
2. Start the game and move to the expanded area.
3. Create one group and place exactly two nodes fully inside it.
4. Create one connection between the nodes if easy and safe.
5. Resize with the same edge/corner that previously produced the thin/tall
   frame. If unknown, report one of: `left`, `right`, `top`, `bottom`,
   `top-left`, `top-right`, `bottom-left`, `bottom-right`, or `unknown`.
6. If collapse occurs, make no further game operation, do not save, and exit.
7. Provide the `[F15]` log lines.

Do not resume group persistence, full regression, release integration, or any
release operation.

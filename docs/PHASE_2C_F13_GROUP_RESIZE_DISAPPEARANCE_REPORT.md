# Phase 2C-F13: Group Resize Disappearance Diagnostic Canary Report

## Status

`F13_DIAGNOSTIC_EVIDENCE_CAPTURED`

This is a local development diagnostic artifact, not a release candidate. It
does not implement a group resize fix and must not be published, tagged,
pushed to public master, uploaded to Workshop, or used to change v0.2.9.

## User Test Result

The user installed only `Nekochan-ExpandedWorkspace-0.2.20.zip`, created one
new group in the expanded area, started an edge resize drag, observed the
group disappear completely, made no further changes, did not save, and exited
the game. Child nodes plus connection and state remained.

## Runtime Evidence

Source: `C:\Users\shian\AppData\Roaming\Upload Labs\logs\modloader_2026-07-15_19.50.09.log`, lines 90-97.

| Checkpoint | Observed state |
|---|---|
| `R1_BEFORE_EDGE_DRAG` | `group12`, valid/in tree/visible, local/global `(18800, 16600)`, size/minimum `(300, 200)`, scale `(1, 1)`, parent `Desktop/Windows`, child count `3`, no resize flags. |
| `R2_EDGE_DRAG_START` | Same geometry; `resizing_left=true`, `resizing_top=true`; `drag_start_rect=[P:(18800,16600), S:(300,200)]`; `drag_start_mouse=(18800,16600)`. Old-bound anchor room is `(-8800,-6600)` while expanded-bound room is `(1200,3400)`. |
| `R4_AFTER_FIRST_FRAME` | Logged before the first resize `_process()` in this session's deferred scheduling; still at `(18800,16600)`, valid and visible. It is not evidence of post-resize stability. |
| `R3_FIRST_RESIZE_PROCESS` before `super` | Same valid/visible state at `(18800,16600)`, size `(300,200)`, left/top resize flags true, zero mouse delta. |
| `R3_FIRST_RESIZE_PROCESS` after `super` | Still valid/in tree/visible, same size/minimum `(300,200)`, same scale/parent/child count, but local/global position became `(9700,9800)`. |
| `R5_AFTER_RELEASE_OR_CANCEL` | Valid/in tree/visible at `(9700,9800)`; resize flags false. The observer corroborated the same state. |
| `EVENT_TREE_EXITING` | Occurred only on game exit. The group remained valid, visible, parented, sized `(300,200)`, and at `(9700,9800)` until exit. |

No `visibility_changed` or `resized` F13 lifecycle line was emitted. This is
consistent with the observed unchanged visibility and unchanged size.

The diagnostic intentionally did not reproduce a target rectangle. The zero
mouse delta already makes the first-process evidence decisive: resize start
alone moved the group frame by `(-9100,-6800)`.

## Classification

`GROUP_NODE_MOVED_OUT_OF_BOUNDS`

More precisely, the group frame was relocated from the expanded-area camera
region into the old workspace maximum position `(10000,10000) - (300,200) =
(9700,9800)`. It was not queue-freed, hidden, collapsed, invalid, reparented,
or render-only disappeared. Its children remained because only the group frame
was old-bound snapped.

The evidence identifies the triggering path as edge resize's original
`move_snapped(new_rect.position)` call. With zero resize delta, the original
rect position remains the saved start location; the inherited old-bound snap
clamps it to `(9700,9800)`. The existing Mod correction is explicitly
movement-only and does not run while `moving=false` during edge resize.

## One Minimal Fix Candidate

Override `WindowGroup.move_snapped(to)` only while a resize flag is active.
In that narrow condition, preserve the vanilla snapping interval but replace
the inherited old-bound `get_position_snapped(to)` result with
`to.clamp(Vector2.ZERO, WorkspaceAreaConfig.get_max_position(size)).snappedf(50)`
before calling the existing `move` notification path. For all non-resize calls,
delegate to `super.move_snapped(to)` unchanged.

This targets exactly the proven old-bound snap, avoids copying the vanilla
resize body, leaves width/height calculation, save schema, and normal group
movement unchanged, and does not override `get_position_snapped()`. It is a
candidate only. A separately approved canary must begin with the reproduced
top-left edge path and stop if another edge reveals a size-calculation issue.
No fix is implemented by F13.

## User Observation

During F12 testing, a new group frame placed in the expanded area disappeared
when an edge resize drag began. F12 remains
`F12_INTERRUPTED_BY_GROUP_RESIZE_BLOCKER`. An existing group moved to the
expanded area persisted after save, exit, restart, and load, but that is only
supplemental evidence and is not a F12 pass.

## Implementation Scope

- Version: `0.2.20`
- Runtime target: one `window_group.gd` instance, claimed by the first edge
  resize start in the game session.
- Added behavior: bounded diagnostic logging only.
- Group resize behavior changed: `NO`
- Group movement behavior changed: `NO`
- Save schema changed: `NO`
- `MAX_BOUNDS` replaced: `NO`
- WindowContainer/Base/Indexed extension added: `NO`
- `get_position_snapped()` override added: `NO`

The extension still delegates every resize action to the original edge-button
handlers and calls the original `_process(delta)` before its pre-existing
movement-only correction. F13 does not reproduce the vanilla resize body.

## Checkpoints

| Checkpoint | Meaning |
|---|---|
| `R1_BEFORE_EDGE_DRAG` | Before the original resize flag is set |
| `R2_EDGE_DRAG_START` | Immediately after the original edge handler sets flags |
| `R3_FIRST_RESIZE_PROCESS` | Before and after the first original resize `_process()` call |
| `R4_AFTER_FIRST_FRAME` | One deferred observer checkpoint, including explicit missing-instance logging |
| `R5_AFTER_RELEASE_OR_CANCEL` | After the original edge release handler clears flags |

`tree_exiting`, `visibility_changed`, and `resized` are connected once for the
one target. They add at most one lifecycle event each. There is no continuous
monitor and no every-frame logging.

Each runtime state line includes validity, tree/visibility state, alpha, scale,
local/global position, size, minimum size, pivot, parent/clip data, child
count, movement/resize flags, drag start state, mouse delta, and the old versus
expanded anchor-to-bound size limits. The diagnostic deliberately logs
`computed_rect=not_reimplemented`; copying the vanilla resize calculation would
broaden this diagnostic beyond its approved safety boundary.

## Classification Targets

```text
GROUP_NODE_QUEUE_FREED
GROUP_NODE_HIDDEN
GROUP_NODE_MOVED_OUT_OF_BOUNDS
GROUP_NODE_SIZE_COLLAPSED
GROUP_NODE_INVALID_RECT
GROUP_NODE_CLIPPED_BY_PARENT
GROUP_NODE_LOST_MEMBERSHIP_OR_REPARENTED
GROUP_NODE_RENDER_ONLY_DISAPPEARANCE
UNRESOLVED
```

The observer emits `is_instance_valid=false` and
`GROUP_NODE_QUEUE_FREED` if the selected group no longer exists at R4 or R5.
Other labels are classification targets for the evidence review; F13 does not
claim a runtime classification before the user test.

## User Verification Matrix

| Test | Result |
|---|---|
| New group resize in expanded area | USER OBSERVED FAIL |
| Group disappears | USER OBSERVED FAIL |
| Instance validity after disappearance | PASS: true through release; tree exit only on game exit |
| Visibility state | PASS: visible=true, alpha=1.0 |
| Size collapse | PASS: size/minimum unchanged `(300,200)` |
| Moved out of bounds | CONFIRMED: `(18800,16600)` to `(9700,9800)` |
| Queue free / tree exit | PASS: no queue free; tree exit only on game exit |
| Classification | `GROUP_NODE_MOVED_OUT_OF_BOUNDS` |

Codex has not run the game. The PASS entries above report only the measured
non-failure invariants from the user's completed test and Mod Loader logs.

## Static Verification

| Check | Result |
|---|---|
| Group resize behavior changed | NO |
| Group movement behavior changed | NO |
| F6 restoration changed | NO |
| F7 grid changed | NO |
| F9 click changed | NO |
| F11 drag changed | NO |
| F12 group persistence logic changed | NO |
| Save schema changed | NO |
| WindowContainer extension | NO |
| Large vanilla body copy | NO |
| Release operation | NO |

## Artifact

- Build command: `tools/build_release.ps1 -Version 0.2.20`
- Filename: `Nekochan-ExpandedWorkspace-0.2.20.zip`
- Path: `dist/Nekochan-ExpandedWorkspace-0.2.20.zip`
- Size: `18562 bytes`
- File count: `15`
- ZIP root: `mods-unpacked`
- Manifest version: `0.2.20`
- SHA-256: `d0ebea1838089f4472b5ec2180f6e1cdcda6207146f4a00a48c6e17163289c11`

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

## User Test Gate

Use a temporary test state. Do not use an important save. Do not save after the
group disappears.

1. Put only `Nekochan-ExpandedWorkspace-0.2.20.zip` in the Mod folder.
2. Start the game and move to the expanded area.
3. Create one new group frame.
4. Move to one group edge point and start an edge resize drag.
5. Observe whether it disappears, collapses, or moves out of view.
6. If it disappears, make no further changes and exit the game.
7. Do not save.
8. Provide the `[F13]` and related warning/error log lines.

The optional vanilla-area comparison is intentionally not part of this first
F13 artifact.

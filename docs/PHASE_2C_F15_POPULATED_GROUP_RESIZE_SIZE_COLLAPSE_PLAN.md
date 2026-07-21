# Phase 2C-F15: Populated Group Resize Size-Collapse Diagnostic Plan

## Status

`IMPLEMENTATION_APPROVED`

## Scope

F14 fixed and verified the original old-bound position snap for the reproduced
left/top resize path. This plan treats the later observation separately:
a populated expanded-area group with two contained, connected nodes became
abnormally thin and tall during resize.

F15 is diagnostics only. It does not implement a size fix or alter F14. The
approved development diagnostic artifact is `0.2.22`; it is not a release
candidate and requires user verification before any classification is selected.

## Confirmed Boundary

F14 remains intact. Its resize-only `WindowGroup.move_snapped(to)` override
uses the expanded workspace maximum and delegates every non-resize call to
`super.move_snapped(to)`. F14 did not change the vanilla resize size
calculation, and its user/log evidence verifies the original top-left
old-bound jump is fixed for that path.

The populated-group size collapse occurred outside F14's bounded diagnostic
sequence. The edge, drag delta, computed rectangle, and exact frame/child
geometry were not logged. No root cause or fix may be selected from the visual
observation alone.

## Static Source Findings

Vanilla `scenes/windows/window_group.gd` defines `MIN_SIZE = Vector2(200, 100)`
and `MAX_BOUNDS = Vector2(10000, 10000)`. During active resize, `_process()`:

1. Captures a snapped global mouse position and subtracts `drag_start_mouse`.
2. Starts `new_rect` from `drag_start_rect`.
3. Calculates left/top position and width/height from their opposite anchors,
   or calculates right/bottom width/height from the starting rectangle.
4. Assigns `custom_minimum_size = new_rect.size`, then `size = custom_minimum_size`.
5. Calls `move_snapped(new_rect.position)`.

The right and bottom branches still use the old `MAX_BOUNDS` to limit width or
height. If the starting left or top anchor is beyond `10000`, the old-bound
limit can produce a non-positive width or height after the minimum-size step.
This is a static candidate only, not a classification: the user did not record
the failing edge, and the runtime values were not captured.

The same script stores `drag_start_rect`, `drag_start_mouse`, and four edge
flags through `set_resizing()`. Its group membership is geometric, not a
reparenting relation: `get_selection()` and `get_connector_selection()` select
items whose rectangles are enclosed by the group rectangle. The F15 diagnostic
must therefore measure child rectangles relative to the frame without
interpreting contained windows as scene-tree children.

## Source Analysis Targets

Before any F15 runtime instrumentation is approved, re-check the current
vanilla script and current `WindowGroup` extension for:

- resize flags, edge button handlers, `drag_start_rect`, and `drag_start_mouse`;
- the vanilla `new_rect` width/height calculation and `MIN_SIZE` enforcement;
- `size`, `custom_minimum_size`, `resized`, `move_snapped()`, and `move()`;
- old versus expanded bounds for rectangle position and size candidates;
- frame selection bounds, contained node/connector rectangles, and relative
  frame-to-child geometry;
- any extension code that adjusts movement after the vanilla process.

Do not copy the vanilla `_process()` body to obtain `new_rect`. Any future
instrumentation must derive and log equivalent candidates independently, then
delegate to the existing implementation unchanged.

## Classification Framework

F15 must retain all classifications until the S1-S6 evidence selects exactly
one, if any:

- `GROUP_SIZE_WIDTH_COLLAPSED`
- `GROUP_SIZE_HEIGHT_COLLAPSED`
- `GROUP_SIZE_MINIMUM_SIZE_MISCOMPUTED`
- `GROUP_CHILD_BOUNDS_MISCOMPUTED`
- `GROUP_RESIZE_EDGE_FLAG_MISMATCH`
- `GROUP_RESIZE_MOUSE_DELTA_DOMAIN_MISMATCH`
- `GROUP_RESIZE_OLD_BOUND_RESIDUE`
- `GROUP_RESIZE_EXPANDED_BOUND_INTERACTION`
- `GROUP_FRAME_CHILD_RELATIVE_LAYOUT_ISSUE`
- `GROUP_RENDER_ONLY_SIZE_APPEARANCE`
- `UNRESOLVED`

## Runtime Diagnostic Design

The approved implementation is a one-target, one-resize-sequence observer in
the existing group extension. It must not change the resize result, group
membership, child positions, save data, or F14's `move_snapped()` branch.

Emit only these checkpoints:

| Checkpoint | Timing | Required evidence |
|---|---|---|
| `S1_BEFORE_POPULATED_RESIZE` | immediately before the selected edge flag is set | frame and contained-child baseline |
| `S2_RESIZE_START` | after the resize flags and drag-start state are set | active edge flags and start geometry |
| `S3_FIRST_SIZE_CALCULATION` | immediately before the first vanilla resize process | independently derived old/expanded candidates; no vanilla body copy |
| `S4_AFTER_FIRST_RESIZE_PROCESS` | immediately after that process returns | actual frame/child geometry and classification evidence |
| `S5_AFTER_RELEASE` | after edge flags clear | final geometry and state |
| `S6_ONE_FRAME_AFTER_RELEASE` | one deferred frame later | stability only |

For each checkpoint, log only the selected group and its fully contained
windows: frame `position`, `global_position`, `size`, `custom_minimum_size`,
`scale`, `visible`, parent path, and tree validity; all four resize flags; edge
identity if known; `drag_start_rect`, `drag_start_mouse`, current snapped mouse,
and delta; computed rectangle position/size candidates; old-bound and expanded-
bound clamp candidates; child count; child local/global positions and sizes;
child-to-frame relative position/bounds; and connection/state identity only
when available without mutation.

Bounded logging is mandatory: exactly one eligible populated group and one
edge-resize sequence per game session. No `_process()` logging after S4, loop,
polling, continuous observer, or all-groups scan is allowed.

## Minimal User Test

Use a temporary state and install only the `0.2.22` diagnostic artifact.

1. Move to the expanded area and create one group beyond the old `10000` bound.
2. Place exactly two nodes fully inside the group and create one connection.
3. Use the same resize edge that produced the thin/tall result.
4. If the edge cannot be identified, report exactly one of `left`, `right`,
   `top`, `bottom`, `top-left`, `top-right`, `bottom-left`, `bottom-right`, or
   `unknown`; do not test every edge.
5. Start the resize, make the smallest movement needed to reproduce, release,
   then exit.
6. Do not save after a collapse or other failure. Provide the `[F15]` log lines.

This test does not resume group persistence, full regression, release
integration, or save/restart testing.

## Stop Conditions

Stop and report the evidence without a fix if any of the following occurs:

- the diagnostic would require a substantial vanilla `_process()` body copy or
  wholesale resize rewrite;
- the diagnostic needs a `WindowContainer`, `WindowBase`, or `WindowIndexed`
  extension, a save-schema change, or a group-membership rewrite;
- the failing edge cannot be identified and the one-path diagnostic cannot
  distinguish candidates;
- logs cannot remain bounded to one group and one sequence;
- the F14 old-bound snap fix would need to change;
- F6, F7, F9, F11, F12, normal movement, click/drag placement, state,
  connections, or child layout show a regression;
- the captured evidence remains insufficient to select a classification.

## Non-Goals

Do not change group resize behavior, group movement, group persistence, save
schema, F6 restoration, F7 grid, F9 click alignment, F11 drag alignment,
node limits, space-upgrade cap, release metadata, tags, Workshop state, or the
blocked `v0.2.9` artifact. Do not create a GitHub Release or Draft Release.

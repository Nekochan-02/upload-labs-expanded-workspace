# Phase 2C-F14: Group Resize Expanded-Bounds Canary Plan

## Status

`IMPLEMENTATION_APPROVED`

## Root Cause Basis

F13 classified the apparent group disappearance as
`GROUP_NODE_MOVED_OUT_OF_BOUNDS`. With zero resize delta, the first original
resize process moved `group12` from `(18800,16600)` to `(9700,9800)`, while it
remained valid, visible, parented, and size `(300,200)` with three children.

The path is:

```text
WindowGroup resize -> move_snapped(new_rect.position)
-> inherited get_position_snapped(to) -> old 10000 clamp
```

`move_snapped(to)` is the narrow patch surface. Global
`get_position_snapped()` remains forbidden because prior broad WindowContainer
patches caused regressions.

## Approved Implementation

Target: `extensions/scenes/windows/window_group.gd`.

Override `move_snapped(to)` only. When any of `resizing_left`,
`resizing_right`, `resizing_top`, or `resizing_bottom` is true, clamp `to` to
`WorkspaceAreaConfig.get_max_position(size)` and retain 50-unit snap before
calling the existing `move` notification path. When no resize flag is active,
delegate to `super.move_snapped(to)` unchanged.

Do not change resize size calculation, `custom_minimum_size`, drag start data,
resize flags, normal group movement, save schema, F6 restoration, F7 grid, F9
click, F11 drag, or F12 persistence logic. Do not add a WindowContainer/Base/
Indexed extension or a `get_position_snapped()` override.

## Diagnostics

For one group and one resize sequence only, log:

```text
F14_RESIZE_MOVE_SNAPPED_INPUT
F14_RESIZE_MOVE_SNAPPED_OUTPUT
F14_AFTER_RESIZE_FIRST_FRAME
F14_AFTER_RELEASE_OR_CANCEL
```

Logs include input, clamped and snapped targets, positions, size, resize flags,
tree state, and visibility. No every-frame or continuous monitoring is allowed.

## User Test Gate

Use a temporary test state and do not save after any failure.

1. Install only `0.2.21`.
2. Create one group clearly beyond the old `10000` boundary.
3. Start with the top-left resize path from F13.
4. Confirm it remains visible at drag start.
5. Drag slightly to enlarge it, release, and confirm it remains visible.
6. Exit without saving after failure and provide `[F14]` logs.

Right/bottom edges are optional only after the primary path passes.

## Stop Conditions

Stop without stacking another fix if `move_snapped()` is not invoked, a
non-resize movement enters the resize branch, the group still jumps, size
collapses, validity/visibility/parentage changes, children detach, normal group
movement regresses, or a blocked extension/body copy becomes necessary.

Release integration, group persistence continuation, full regression, push,
Release, tag, and Workshop publication remain deferred.

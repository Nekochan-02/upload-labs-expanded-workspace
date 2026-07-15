# Phase 2C-F13: Group Resize Disappearance Diagnostic Plan

## Status

`F13_GROUP_RESIZE_DISAPPEARANCE_PLAN_READY`

This is a diagnostic plan only. Do not implement a group resize fix, build an
artifact, push, publish, tag, or continue release integration from this plan.

## User Observation

Reproduction reported during F12 testing:

1. Place a new group node.
2. Move the cursor to a group node edge.
3. Start dragging the edge point to enlarge the group node.
4. At drag start, the group node disappears.

Classification:

`GROUP_RESIZE_EDGE_DRAG_DISAPPEARANCE_BLOCKER`

Supplemental observation:

An already placed group moved to the expanded area persisted after save, exit,
restart, and load. This suggests group persistence itself remains promising, but
F12 must stay interrupted until the group resize disappearance is understood.

## Current Verified Context

```text
F6 single-node exact local persistence: VERIFIED
F7 grid density: VERIFIED
F9 click placement: VERIFIED
F11 drag placement: VERIFIED
existing group moved to expanded area persists after restart: USER OBSERVED PASS
new group edge resize drag causes group disappearance: USER OBSERVED FAIL
```

## Suspected Path

Primary implementation path:

- Vanilla: `vanilla-reference/scenes/windows/window_group.gd`
- Current Mod extension:
  `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/windows/window_group.gd`
- Inherited movement/draw/lifecycle:
  `vanilla-reference/scenes/windows/window_container.gd`

Relevant static findings:

- Vanilla `WindowGroup` has a hard-coded `MAX_BOUNDS = Vector2(10000, 10000)`.
- Resize is handled by `resizing_left`, `resizing_right`, `resizing_top`, and
  `resizing_bottom`, not by `moving`.
- The current Mod extension calls `super._process(delta)` and then applies an
  expanded-bound correction only when `moving` is true.
- Therefore edge resize still executes the vanilla `MAX_BOUNDS` resize path.
- In an expanded-area group, right or bottom resize can evaluate the old-bound
  clamp using a frame position beyond `10000`, which may produce a collapsed or
  invalid size before `move_snapped(new_rect.position)`.

This is a hypothesis for diagnostic targeting only. It is not a fix decision.

## Analysis Targets

Investigate the following without changing runtime code in F13 plan work:

- `scenes/windows/window_group.gd`
- edge resize button down/up handlers
- resize flags: `resizing_left`, `resizing_right`, `resizing_top`,
  `resizing_bottom`
- `moving`
- `drag_start_rect`
- `drag_start_mouse`
- computed resize rectangle
- `custom_minimum_size`
- `size`
- `position`
- `global_position`
- `pivot_offset`
- `visible`
- `modulate`
- `scale`
- `top_level`
- parent path and child count
- group membership selection
- inherited `move()` / `move_snapped()` behavior
- whether the node is `queue_free`d, hidden, moved out, collapsed, clipped, or
  visually lost while still valid

## Disappearance Classification Framework

F13 diagnostics should classify the disappearance into exactly one primary
class when possible:

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

## Diagnostic Checkpoint Design

If the user later approves an implementation, the next diagnostic artifact
should be:

```text
0.2.20 group resize disappearance diagnostic
```

The diagnostic should target one group only and emit bounded logs:

| Checkpoint | Purpose |
|---|---|
| `R1_BEFORE_EDGE_DRAG` | State before edge resize begins |
| `R2_EDGE_DRAG_START` | State immediately when resize flag is set |
| `R3_FIRST_RESIZE_PROCESS` | First resize `_process()` state and computed target rect if available |
| `R4_AFTER_FIRST_FRAME` | One deferred or next-frame stability state |
| `R5_AFTER_RELEASE_OR_CANCEL` | State after drag release/cancel |

Each checkpoint should capture:

```text
is_instance_valid
position
global_position
size
custom_minimum_size
visible
modulate
scale
pivot_offset
top_level
parent
child count
moving
resizing_left/right/top/bottom
drag_start_rect
drag_start_mouse
computed target rect if available
```

If the group instance is invalid after disappearance, log
`is_instance_valid=false` explicitly.

Logging constraints:

- no every-frame logging
- no `_process()` loop solely for continuous monitoring
- no broad group scan
- maximum one group target
- stop after the bounded R1-R5 sequence

## Old-Boundary Relationship

The plan should distinguish whether the bug is expanded-area specific:

1. New group resize in the vanilla area.
2. New group resize in the expanded area.
3. Existing group moved to the expanded area, then resized.

The first user test should remain minimal and prioritize the reported
reproduction: new group in the expanded area, edge resize drag start.

## Explicit Non-Goals

Do not implement:

- group resize bounds fix
- F6 restoration change
- F7 grid change
- F9 click change
- F11 drag change
- save schema change
- WindowContainer/Base/Indexed extension
- `get_position_snapped()` override
- full regression
- release integration
- Release, tag, Workshop, or public master push

Do not copy the full vanilla `WindowGroup._process(delta)` body into a release
candidate. If a diagnostic implementation needs local target-rect calculation,
keep it diagnostic-only and publish-safety reviewed before artifact creation.

## Minimal User Test Proposal

For a future approved `0.2.20` diagnostic artifact only:

1. Install only the `0.2.20` diagnostic artifact.
2. Start the game.
3. Place one new group in the expanded area.
4. Drag one edge point just enough to start resize.
5. Stop immediately after the group disappears or after the first visible resize
   result.
6. Exit the game.
7. Provide `[F13]` diagnostic log lines.

Do not continue F12 group persistence, group movement/resize regression, full
regression, or release integration during this diagnostic.

## Stop Conditions

Stop without proposing a fix if:

- the disappearance cannot be classified from R1-R5 evidence
- the group instance is destroyed by a path outside `window_group.gd`
- a fix appears to require copying the full vanilla `_process()` body
- a WindowContainer/Base/Indexed patch appears necessary
- save schema changes appear necessary
- F6/F7/F9/F11 behavior changes would be required

After evidence is collected, propose exactly one smallest fix candidate.

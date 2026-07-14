# Phase 2C-F11: Drag Placement Local-Domain Alignment Canary Plan

## Status

`IMPLEMENTATION_APPROVED`

## Objective

Test the narrow F10 evidence-backed correction for expanded-area drag
placement. Keep the trusted drag target calculation unchanged and replace only
the final deferred global `move(target_position)` correction with a deferred
local `position = target_position` assignment followed by `moved.emit()`.

F11 is a local development canary, not a release candidate. Release
integration remains deferred.

## F10 Evidence

F10 classified the fault as `DRAG_DEFERRED_MOVE_COORDINATE_DOMAIN_MISMATCH`.
For the drag-created `download_text1`, D4 target `(10950.0, 12100.0)` was
`DRAG_TARGET_SNAP_CORRECT`, with zero recompute delta and exact 50-unit snap
units `(219.0, 242.0)`. `Utils.screen_to_world_pos` did not introduce the
observed offset.

At D9/D10, global position equaled target while local position was
`(10775.0, 11974.5)`, offset `(-174.998, -125.499)`. D11 opening settle then
left both local and global at that off-target local coordinate. This matches
the F8 click mismatch family. F9 resolved the click case by writing the final
correction in local coordinates and emitting `moved`.

## Patch Surface and Rationale

Target: `extensions/scenes/window_dragger.gd::place()`.

The unchanged target calculation is `_get_expanded_drag_target()`, including
`Utils.screen_to_world_pos`, bounds clamp, and 50-unit snap. The existing
pre-create and post-create `global_position` assignments and `_finish_drag()`
also remain unchanged.

Only the final deferred correction changes:

```gdscript
# F10
instance.call_deferred("move", target_position)

# F11
_f11_start_local_alignment_observer(instance, target_position, log_diagnostic)
```

The self-authored root observer is required because `_finish_drag()` queues the
dragger for deletion. Its one deferred helper guards instance validity, assigns
local `position`, and emits `moved`. It does not call `move()`, `move_snapped()`, or write
`global_position`; it does not re-snap or recalculate the target.

## Lifecycle Checks

For the first drag-created node only, F11 records:

- `F11_TARGET`
- `F11_BEFORE_LOCAL_CORRECTION`
- `F11_AFTER_LOCAL_CORRECTION`
- `F11_NEXT_DEFERRED_STABILITY`
- `F11_OPENING_SETTLE_STABILITY`

The observer self-frees after one 0.5-second opening-settle checkpoint. There
is no `_process()` callback, timer loop, or continuous correction.

Expected checkpoint equality:

```text
AFTER_LOCAL == TARGET
NEXT_DEFERRED_LOCAL == TARGET
OPENING_SETTLE_LOCAL == TARGET
```

Checkpoint equality is not a visual PASS claim; visual alignment remains a
user verification gate.

## Preservation and Stop Conditions

```text
click placement source changed: NO
grid source changed: NO
Desktop restoration source changed: NO
drag target calculation changed: NO
snap interval changed: NO
existing-node movement changed: NO
WindowContainer/Base/Indexed extension: NO
save schema changed: NO
```

Stop without another repair if target snap becomes incorrect, local correction
or either stability checkpoint differs from target, visual alignment fails
while local equals target, or click/manual-movement/F6/F7/selection behavior
regresses. In the visual-fail/local-exact case, classify a deeper visual anchor
issue rather than guessing an additional correction.

## Artifact and Release Boundary

- Version: `0.2.18`
- Artifact: `dist/Nekochan-ExpandedWorkspace-0.2.18.zip`
- Build: `tools/build_release.ps1 -Version 0.2.18`
- Purpose: local development canary only

No Release, tag, Workshop operation, public `master` push, merge, or v0.2.9
artifact operation is allowed.

## User Test Gate

1. Install only `0.2.18`.
2. Move the camera into the expanded area.
3. Create one node by drag placement.
4. Check alignment immediately and after 0.5-1 second.
5. Move the same node once and check alignment.
6. Optionally verify one click placement.
7. Exit the game and provide `[F11]` checkpoint lines.

Save/restart, group persistence, and full regression are out of scope.

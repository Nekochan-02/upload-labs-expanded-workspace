# Phase 2C-F6 Exact Local Position Restoration Plan

Status: `IMPLEMENTATION_APPROVED`

## Evidence and Scope

F4 corrected the old-boundary warp but did not retain exact saved positions. For the captured targets, the saved value was local `WindowContainer.position`, while the F4 mutation called `WindowContainer.move(saved_position)`. Vanilla `move()` assigns its argument to `global_position`, creating a confirmed local/global coordinate-space mismatch.

F6 changes only the restoration mutation mechanism in the existing Desktop extension:

1. Capture the saved local `position` before vanilla Desktop initialization.
2. Let vanilla initialization perform its existing old-boundary clamp.
3. In the existing one-shot deferred correction, clamp the saved local value to `WorkspaceAreaConfig.get_max_position(window.size)`.
4. Assign that value to `window.position` directly, then emit `window.moved` so the vanilla Desktop listener can queue dependent redraw updates.
5. Run one deferred stability checkpoint and clear all snapshot state.

No continuous correction, timer, process loop, user-action signal, or save-data mutation is allowed.

## Exact Local Restore Rationale

`WindowContainer.save()` serializes local `position`. F6 therefore restores the same local coordinate domain. The desired position is:

```text
saved_position.clamp(Vector2.ZERO, WorkspaceAreaConfig.get_max_position(window.size))
```

F6 does not call `move()`, `move_snapped()`, `get_position_snapped()`, write `global_position`, or apply `.snappedf(50)`. Re-snapping persisted data would itself introduce drift when a saved value is not already grid aligned.

For each checkpointed window, F6 logs `SAVED_LOCAL`, `DESIRED_LOCAL`, and `CLAMP_DELTA`. A saved position inside expanded bounds must have a zero clamp delta.

## Update Signal Rationale

Vanilla `WindowContainer.move(pos)` has two observed effects: it assigns `global_position` and emits `moved`. `Desktop._on_windows_child_entered()` listens to `moved` and queues LOD/selection redraw updates. F6 replaces only the position write with local assignment, then emits `moved`; it must not emit drag, selection, sound, placement, or save signals.

## Checkpoints

At most three restored windows are logged:

```text
SAVED_LOCAL
BEFORE_CORRECTION: local and global
DESIRED_LOCAL and clamp delta
AFTER_CORRECTION: local and global
STABILITY_CHECK: local and global
```

The static pass candidate requires `AFTER_CORRECTION.local == DESIRED_LOCAL` and `STABILITY_CHECK.local == DESIRED_LOCAL`. User-visible persistence remains a separate real-game test.

## Boundaries and Risks

- The expanded maximum remains `WorkspaceAreaConfig.get_max_position(window.size)`.
- A negative saved position is ignored, as in F4.
- A saved coordinate outside the expanded range is clamped and its delta is logged.
- The first user test is limited to an individual node. F6 adds no group-specific propagation; group persistence is deferred.
- Connection/redraw correctness is limited to retaining the existing `moved` update path and must be user-tested later.
- Grid density and snap geometry remain the independent `GRID_DENSITY_SCALE_MISMATCH` issue. F6 does not modify grid generation, render scale, snap intervals, connector snap, or visual origin.

## Required Absences

- `WindowContainer`, `WindowBase`, and `WindowIndexed` extensions: absent.
- `get_position_snapped()` override: absent.
- Save schema mutation: absent.
- Selection runtime change: absent.
- Continuous monitoring: absent.

## Stop Conditions

Stop without stacking speculative fixes if any of the following occurs:

- A saved local position is unexpectedly outside expanded bounds.
- Direct local assignment cannot be performed safely.
- `moved` is unavailable or causes unsafe side effects.
- `AFTER_CORRECTION_LOCAL` or `STABILITY_LOCAL` differs from `SAVED_LOCAL` for an in-bounds target.
- Selection regression appears.
- Local persistence requires grid changes, a WindowContainer patch, or substantial vanilla copying.

## Delivery and Integration

F6 is version `0.2.13`, development canary only. It must not create a GitHub Release, Draft Release, tag, Workshop upload, public-master push, or modify the v0.2.9 artifact. Clean public integration remains deferred until individual-node persistence, grid density, group persistence, and the full regression gate are verified.

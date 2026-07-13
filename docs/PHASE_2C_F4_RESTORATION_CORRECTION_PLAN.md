# Phase 2C-F4 Restoration Correction Plan

Status: `IMPLEMENTATION_APPROVED`

## Purpose

Implement a restoration-only canary that reapplies saved expanded-area positions once after vanilla restoration lifecycle clamp has completed.

This is not a Release Candidate. It is a development canary for user verification.

## F3 Evidence

F3 target:

- name: `download_video0`
- filename: `window_download_video.tscn`
- script: `res://scenes/windows/window_download.gd`
- size: `(350.0, 272.0)`

Measured checkpoints:

- P2 saved: `(19650.0, 19750.0)`
- P3 direct: `UNOBSERVED`
- P3.5 after `super._enter_tree()`: `(19650.0, 19750.0)`
- P3.5 `child_entered_tree`: `(19650.0, 19750.0)`
- P4 deferred final: `(9650.0, 9750.0)`

Old-boundary formula match:

- X: `10000 - 350 = 9650`
- Y: `10000 - 272 = 9728`, snapped to the observed old-boundary grid result `9750`

Conclusion:

- save serialization retains the expanded position
- Desktop immediate restoration retains the expanded position
- the first observable child-entered state retains the expanded position
- a later lifecycle point clamps the window to the old workspace boundary

Root cause classification: `ROOT_CAUSE_CONFIRMED_LIFECYCLE_CLAMP`

## Runtime Baseline

F4 runtime is:

- v0.2.9 verified runtime behavior
- Desktop restoration-only correction
- minimal F4 checkpoint logging

It is not based on failed v0.2.10 runtime behavior.

Forbidden patch surfaces:

- `WindowContainer` Script Extension
- `WindowBase` Script Extension
- `WindowIndexed` Script Extension
- `get_position_snapped()` override
- global window behavior patch
- selection behavior patch

## Snapshot Strategy

The existing `extensions/scripts/desktop.gd` surface snapshots saved window positions before `super._enter_tree()`.

The snapshot is runtime memory only:

- no save schema write
- no saved data mutation
- no persistent metadata on vanilla objects

Correlation key:

- saved `window.name`
- restored child path `Windows/<window.name>`

This correlation is grounded in vanilla `Desktop._enter_tree()`, which uses the same `Windows/<window.name>` lookup.

Duplicate or empty saved names are a stop condition. If detected at runtime, correction is disabled and a `[F4][STOP]` log is emitted. There is no index or type fallback.

## Target Condition

The snapshot includes saved positions for restored windows, but correction only applies to windows whose saved expanded position exceeds the vanilla old workspace valid maximum for the restored instance size.

Concept:

```text
vanilla_max_position = (Vector2.ONE * 10000) - restored_window.size
target if saved_position.x > vanilla_max_position.x
      or saved_position.y > vanilla_max_position.y
```

Negative positions are not corrected. Old-workspace positions are not corrected.

## Desired Position

The target position is the saved position clamped to expanded workspace bounds and snapped to the 50 grid:

```text
desired_position = saved_position.clamp(
    Vector2.ZERO,
    WorkspaceAreaConfig.get_max_position(restored_window.size)
).snappedf(50)
```

No new workspace constant is introduced.

## Deferred Timing

F3 showed the old-boundary clamp is visible by the deferred P4 checkpoint. F4 therefore schedules a one-shot deferred correction after `super._enter_tree()`:

1. snapshot saved positions
2. `super._enter_tree()`
3. vanilla restoration and lifecycle clamp
4. deferred F4 correction
5. one next-deferred stability log
6. clear snapshot dictionaries

No `_process()` loop, timer loop, or continuous monitoring is used.

## Mutation Mechanism

Selected mechanism: `WindowContainer.move(desired_position)`

Reasoning:

- `move()` assigns `global_position` and emits the window's `moved` signal.
- It does not alter selection state.
- It does not alter drag state.
- It does not play sound or trigger user-action UI.
- The `moved` signal is already used by `Desktop` to queue rendering updates for moved windows.

Rejected mechanisms:

- `move_snapped()` is rejected because it calls vanilla `get_position_snapped()` and would reuse the old boundary clamp.
- direct `position` assignment is rejected because it bypasses the window `moved` signal used by existing update paths.
- direct `global_position` assignment is rejected for the same reason.

## Group Risk

`WindowGroup` does not override `move()`. Its active movement and resize logic lives in `_process()` during user interaction.

F4 applies absolute saved positions to each restored saved window once. It does not emit drag signals and does not use selection movement.

Risk:

- if a future group case relies on group frame movement propagating to contained windows, applying correction to both frame and child windows through a propagating API could double-move children.

Current mitigation:

- `move()` has no group child propagation in the inspected vanilla code.
- The first required user canary test is single-node only.
- group verification remains deferred.

If runtime evidence shows group double movement, stop and scope the next fix separately.

## Connection And State Risk

No node state, level, cost, connection data, or save schema is modified.

`move()` emits `moved`, allowing existing draw/update paths to refresh. This is lower risk for connection visuals than direct assignment.

## F4 Checkpoint Logging

For up to 3 corrected windows:

- `SAVED`
- `BEFORE_CORRECTION`
- `AFTER_CORRECTION`
- `STABILITY_CHECK`

Logs are one-shot and low-frequency.

## Stop Conditions

Stop without stacking another fix if:

- saved/restored name correlation is ambiguous
- duplicate or empty saved window names are detected
- mutation method risks group double movement and cannot be safely scoped
- `BEFORE_CORRECTION` is not old-clamped
- `AFTER_CORRECTION` does not equal desired saved position
- `STABILITY_CHECK` reclamps the node
- selection regression reappears
- save schema modification becomes necessary
- `WindowContainer` patch becomes necessary
- large vanilla body copy becomes necessary

## Clean Integration

Even if v0.2.12 succeeds, do not merge this development branch to `master`.

After user verification, create a separate clean integration phase from `origin/master` and transplant only the verified final runtime files through an allowlist.

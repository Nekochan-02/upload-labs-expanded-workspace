# Phase 2C-F16: Populated Group Resize Width-Collapse Fix Canary Plan

## Status

`IMPLEMENTATION_APPROVED`

## Root Cause Basis

F15 verified `GROUP_SIZE_WIDTH_COLLAPSED` on a populated group at
`(13900,16250)` resized through `top-right`. With zero mouse delta, the
vanilla right-edge calculation used the old workspace limit and derived
`10000 - 13900 = -3900`. The first resize process set
`custom_minimum_size.x=-3900` and frame width became `20`; the independently
derived expanded candidate remained a valid `(800,650)` rectangle.

The frame local/global position and both contained nodes' geometry remained
unchanged. This is not an F14 position-snap regression, child-layout breakage,
mouse-coordinate mismatch, render-only artifact, or save/load issue.

## Approved Correction

Target only `extensions/scenes/windows/window_group.gd`. Preserve F14's
resize-only `move_snapped(to)` expanded-bound branch unchanged.

After `super._process(delta)`, while the selected resize sequence is active,
evaluate the pre-super old and expanded candidates. Correct only if all guards
pass:

- a right or bottom edge is active;
- the old candidate is smaller than the vanilla minimum on that affected axis;
- the expanded candidate is at least the vanilla minimum on both axes;
- actual `size` or `custom_minimum_size` is below the minimum on that axis.

When guarded, assign only the expanded candidate's affected `size` and
`custom_minimum_size` axis. Use the existing `move()` notification path only
if the expanded snapped position differs. The Control property setters retain
the same resize/update semantics as the vanilla path; no guessed signal is
emitted manually.

The correction is applied per active resize frame only when the guards remain
true. It never moves children, changes membership/connections, writes saves,
uses the old bound, or changes normal movement.

## Diagnostics

For one F15-eligible populated group and one resize sequence, emit only:

```text
F16_BEFORE_CORRECTION
F16_CORRECTION_DECISION
F16_AFTER_CORRECTION
F16_AFTER_RELEASE
F16_ONE_FRAME_AFTER_RELEASE
```

Logs record edge/flags, old/expanded candidates, actual position/size/minimum,
per-axis guard results, correction result, child count/bounds/relative bounds,
and connector-point presence. No every-frame or continuous logging is added.

## Scope Exclusions

Do not override `get_position_snapped()`, add WindowContainer/Base/Indexed
extensions, copy the vanilla resize body, alter F14, mutate children or save
schema, or change F6/F7/F9/F11/F12. Group persistence, full regression,
release integration, push, Release, tag, and Workshop operations remain
deferred.

## Stop Conditions

Stop without another fix if the guard cannot distinguish an old-bound collapse,
the expanded candidate is invalid, size/minimum cannot be restored safely,
children or connection/state regress, normal movement or F14 regresses, or a
vanilla-body copy, global snap override, WindowContainer patch, or schema
change becomes necessary.

## User Test Gate

Use a temporary state and install only `0.2.23`.

1. Move to the expanded area and create one group.
2. Put exactly two nodes inside and add one connection if easy.
3. Use the same `top-right` resize path with little or zero mouse delta.
4. Confirm width does not collapse, then drag slightly and release.
5. Confirm the frame remains valid and normal-shaped and children plus
   connection/state remain.
6. Do not save after any failure. Exit and provide `[F16]` logs.

Do not test save/restart, group persistence, full regression, or release work.

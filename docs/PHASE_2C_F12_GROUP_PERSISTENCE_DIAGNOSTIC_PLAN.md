# Phase 2C-F12: Group Persistence Diagnostic Canary Plan

## Status

`PLAN_READY_FOR_IMPLEMENTATION_APPROVAL`

## Objective

Determine whether the verified F6 restoration-only local correction preserves
expanded-area persistence for both a group frame and its contained nodes
through save, exit, restart, and load.

The diagnostic must establish whether restoring the group frame and children
individually preserves their saved local positions and their saved relative
layout, without adding group movement, group resize, or group-specific repair
behavior.

## Current Evidence

- F6 verified exact local persistence for individual nodes only. Its saved
  coordinate and mutation domain are both local `WindowContainer.position`.
- F6 metadata already identifies a saved group frame by `filename` and applies
  the same one-shot local restoration correction to any saved expanded-area
  target.
- A vanilla group dynamically selects fully enclosed windows from its frame
  rectangle. It does not provide an independently saved child-membership list.
- F4 identified the risk: if a group frame propagated a restore movement to
  children, restoring both frame and children could double-move them. F6's
  direct local assignment has not yet been tested against that risk.
- F11 has verified drag local alignment. It does not alter restoration and does
  not make group persistence a PASS criterion.

## Scope

Proposed implementation target: the existing
`extensions/scripts/desktop.gd` F6 restoration diagnostic path only.

F12 may add bounded correlation metadata and logs around the existing F6
snapshot/correction/stability checkpoints. It must not change the F6 saved
position capture, restore eligibility, desired-position formula, local
assignment, or `moved.emit()` update path.

The diagnostic selects at most one saved group frame and up to two saved nodes
whose saved rectangles are fully enclosed by that group frame rectangle,
including the same 20-unit selection margin used by the group-selection
semantics. If no unambiguous frame/child set exists, it must log a stop reason
and make no group-specific inference.

## Required Evidence

For the selected frame and each correlated child, log only:

- `F12_GROUP_SAVED`: saved local position, saved size, frame/child role, and
  saved group-relative delta for children.
- `F12_GROUP_BEFORE`: runtime local position before the existing F6 correction.
- `F12_GROUP_AFTER`: runtime local position after that unchanged correction.
- `F12_GROUP_STABILITY`: runtime local position at the existing deferred F6
  stability checkpoint.

For each child, calculate at every checkpoint:

```text
relative_local = child.local_position - frame.local_position
relative_delta = relative_local - saved_relative_local
```

Expected in-bounds result:

```text
frame AFTER_LOCAL == frame SAVED_LOCAL
frame STABILITY_LOCAL == frame SAVED_LOCAL
child AFTER_LOCAL == child SAVED_LOCAL
child STABILITY_LOCAL == child SAVED_LOCAL
child AFTER_RELATIVE_DELTA == (0, 0)
child STABILITY_RELATIVE_DELTA == (0, 0)
```

The existing F6 per-window checkpoint logs remain authoritative for saved,
desired, clamp, global, and exact-local data. F12 adds only the group/child
relationship evidence necessary to detect a double movement or relative-layout
break.

## Required Absences

```text
F6 local restoration mutation changed: NO
group movement changed: NO
group resize changed: NO
group selection movement changed: NO
click placement changed: NO
drag placement changed: NO
F7 grid changed: NO
F9 click alignment changed: NO
F11 drag alignment changed: NO
WindowContainer/Base/Indexed extension: NO
get_position_snapped() override: NO
save schema changed: NO
node limit or space cap changed: NO
camera/background changed: NO
```

No vanilla function body may be copied. No continuous monitor, `_process()`,
or timer loop is permitted. The existing F6 single deferred stability callback
is the only deferred observation point.

## Stop Conditions

Stop without stacking another correction if any of the following occurs:

- Saved group frame or child data cannot be correlated unambiguously.
- F6 saved/desired local data is not available for the selected targets.
- Frame or child local position differs from saved local position after F6.
- A child relative delta is non-zero after correction or stability.
- Frame and child both move by the same propagated delta before their own F6
  correction, indicating a possible double-movement path.
- Group visual layout fails while every local and relative checkpoint is exact.
- Connections, node state, level, or cost show a destructive symptom.
- Any F7/F9/F11/selection regression appears.

If the frame and children are exact individually but the visible group layout
is incorrect, classify a deeper group visual-anchor/layout issue and do not
guess a movement or resize repair.

## Proposed Artifact Boundary

If implementation is separately approved:

- Proposed version: `0.2.19`
- Proposed artifact: `Nekochan-ExpandedWorkspace-0.2.19.zip`
- Type: local development diagnostic canary only

No Release, Draft Release, tag, Workshop operation, public `master` push,
merge, or v0.2.9 artifact operation is permitted.

## Minimal User Test Gate

1. Install only the approved F12 diagnostic artifact.
2. In the expanded area, create or position one group frame containing exactly
   two visible nodes; leave the nodes fully inside the frame and do not resize
   or move the group after this setup.
3. Save, exit the game, restart, and load the same save.
4. Verify that the group frame remains at its exact prior location.
5. Verify that both contained nodes remain at their exact prior locations and
   keep the same layout relative to the frame.
6. Verify visible connections and node state remain present for the two nodes.
7. Exit and provide the `[F12]` and existing `[F6]` checkpoint lines.

Group resize, group movement, full regression, and release integration are out
of scope.

## Approval Gate

This document is a plan only. Do not modify Mod code, change the manifest,
build an artifact, or run a group persistence test until the user explicitly
approves the F12 implementation.

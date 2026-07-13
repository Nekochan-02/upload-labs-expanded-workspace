# Phase 2C-F8: Click Placement Coordinate-Domain Diagnostic Plan

## Status

`DIAGNOSTIC_APPROVED`

## Objective

Identify the lifecycle checkpoint at which a click-created window stops matching
the 50-unit visual grid in the expanded workspace. This phase collects evidence
only; it does not correct click placement.

## Baseline

F7 restored vanilla grid density and verified drag placement, existing-window
movement, and F6 single-window persistence. The remaining observed defect is
limited to the initial position of a click-created window: it is off-grid until
the user moves it.

The verified comparison is `click placement: FAIL`, `drag placement: PASS`, and
`existing-window movement: PASS`. F6 established a local/global coordinate-domain
mismatch precedent: save uses local `position`, while `WindowContainer.move()`
writes its argument as `global_position`.

## Scope

The only implementation target is the existing click path in
`extensions/scripts/windows_tab.gd::add_window(window)`. Its coordinate
calculation and all existing assignments remain unchanged. F8 adds bounded,
one-target diagnostic logging around those existing operations.

The diagnostic target is the first click-created window in a run. The logs use
the `[F8]` prefix and record:

| Checkpoint | Evidence |
| --- | --- |
| C1 | `CAMERA_CENTER` |
| C2 | `RAW_TARGET = camera_center - window_size / 2` |
| C3 | `SNAPPED_TARGET`, bounds, and x/y snap arithmetic for interval 50 |
| C4 | pre-create local/global/parent coordinate state |
| C5 | post-create local/global/parent state and safe parent global/transform origin |
| C6 | state after the existing global-position reapply |
| C7 | state immediately before the existing deferred `move()` |
| C8 | state immediately after the existing deferred `move()` |
| C9 | next deferred lifecycle stability state |

C4-C9 include `local_to_target`, `global_to_target`, and `global_local`
deltas. The logs are observational and do not assign position, global position,
or transform outside the pre-existing F7 click-placement operations.

The diagnostic classification is selected only after runtime evidence:
`TARGET_SNAP_INCORRECT`, `CREATE_PARENTING_COORDINATE_MISMATCH`,
`POST_CREATE_GLOBAL_REAPPLY_MISMATCH`, `DEFERRED_MOVE_COORDINATE_DOMAIN_MISMATCH`,
`MULTIPLE_CLICK_PATH_COORDINATE_DEFECTS`, `VISUAL_ORIGIN_MISMATCH`, or
`UNRESOLVED`.

## Explicit Non-Goals

- No click-placement correction or coordinate conversion.
- No grid, renderer, tile, origin, scale, coverage, or snap-interval change.
- No F6 Desktop restoration change.
- No drag-placement or existing-window movement change.
- No WindowContainer, WindowBase, or WindowIndexed extension.
- No group persistence, full regression, release integration, tag, Release, or
  Workshop operation.
- No save-schema change.

## Development Artifact

- Version: `0.2.15`
- Filename: `Nekochan-ExpandedWorkspace-0.2.15.zip`
- Purpose: local development diagnostic artifact only.
- Build: `tools/build_release.ps1 -Version 0.2.15`.

No GitHub Release or Draft Release, tag, Workshop publication, public-master
push, or operation on the blocked v0.2.9 artifact is permitted.

## Static Acceptance Criteria

```text
F7 grid changed: NO
F6 restoration changed: NO
click behavior changed: NO
click diagnostic added: YES
drag changed: NO
movement changed: NO
snap changed: NO
save schema changed: NO
```

## Runtime Test

The user tests with only `0.2.15` installed:

1. Start the game and create one node by click placement in the expanded area.
2. Check initial visual grid alignment.
3. Move that node manually and check post-move alignment.
4. Exit the game and provide the `[F8]` log lines.

F8 does not include save/restart, group, or performance testing. Codex must not
claim a runtime PASS before the user performs this test.

## Stop Conditions

Do not implement a repair in F8. Stop after evidence capture if any of the
following is observed:

- C3 is correctly snapped but C5/C6/C8/C9 differs from the target.
- C3 is already inconsistent with 50-unit snap arithmetic.
- Parent transform or global/local conversion changes the coordinate domain.
- The diagnostic affects F7 grid, F6 restoration, drag placement, or movement.

The next phase may propose one minimal repair candidate only after comparing
the complete C1-C9 evidence with the visual result.

# Phase 2C-F28: Expanded-Area Range Selection Diagnostic Plan

Status: `F28_RANGE_SELECTION_DIAGNOSTIC_PLAN_REQUIRED`

Result: `F28_RANGE_SELECTION_DIAGNOSTIC_PLAN_READY` / `BLOCKED`

F28 is a docs-only diagnostic plan. It records the `0.2.28` clean-RC smoke
blocker and defines one bounded future canary to identify why range selection
works in the old workspace area but not in the expanded area. It does not
authorize runtime changes, artifact generation, a build, or a runtime test.

## 1. F27 Smoke Blocker Commit

The clean-RC smoke blocker was recorded before this branch was created:

| Item | Value |
|---|---|
| Commit | `1b7a5e3` `docs: record range selection smoke blocker` |
| Files | `docs/PHASE_2C_F27_CLEAN_INTEGRATION_RC_REPORT.md`, `docs/HANDOFF.md` |
| Result | `F27_CLEAN_RC_SMOKE_BLOCKED` |

The working tree was clean after that commit. No runtime code, artifact, build,
fix, diagnostic implementation, cleanup, or release operation occurred.

## 2. User Observation

Expected behavior: shift + drag range selection works in the expanded area in
the same way it works in the old area.

Observed clean-RC behavior:

| Area | Shift + drag range selection |
|---|---|
| Old workspace area | PASS |
| Expanded workspace area | FAIL |

Classification: `EXPANDED_AREA_RANGE_SELECTION_NOT_WORKING`.

Severity is non-fatal, but this is a gameplay QoL issue in a core multi-node
workflow. The clean RC is not release-ready unless the issue is fixed and
smoke-tested or explicitly accepted as a known limitation.

## 3. Git Topology

| Item | Value |
|---|---|
| F27 implementation branch | `dev/phase-2c-f27-clean-integration-0.2.28` |
| F27 clean-integration commit | `b11fa01` `chore: clean diagnostics for 0.2.28 rc` |
| F27 blocker-record commit | `1b7a5e3` `docs: record range selection smoke blocker` |
| F28 branch | `dev/phase-2c-f28-range-selection-diagnostic-plan` |
| Remote action | None |

F28 starts from the clean HEAD after the F27 blocker record. Do not rebase,
amend, reset, push, merge to public master, tag, publish a Release, or publish
to Workshop.

## 4. Source Analysis Findings

The following findings are static evidence only; they do not establish the
runtime cause.

1. `vanilla-reference/scripts/tools_bar.gd` selects `Utils.tools.SELECT` while
   the `multi_select` input action is pressed. `vanilla-reference/project.godot`
   maps that action to the physical Shift key.
2. `vanilla-reference/Main.tscn` routes `Desktop/InputBlocker.gui_input` to
   `Desktop/SelectionPanel._on_input_blocker_gui_input`. The InputBlocker has a
   fixed vanilla rectangle from `(-5000, -5000)` to `(15000, 15000)`.
3. `vanilla-reference/scripts/selection_panel.gd` starts a rectangle from
   `get_global_mouse_position()`, updates its global position and size each
   frame, then intersects `get_rect()` with every `selectable` window and
   `connector_point`. It applies the result through `Globals.set_selection`.
   It retains an existing selection only while Ctrl is pressed.
4. The mod's `extensions/scripts/main_2d.gd` expands `Desktop`, `Background`,
   and `Lines` to `20000 x 20000`. It does not explicitly resize
   `Desktop/InputBlocker` or `Desktop/SelectionPanel`. The SelectionPanel is
   anchor-based, so static inspection alone cannot determine its effective
   runtime rectangle or input reach in the expanded area.
5. The existing mod `extensions/scripts/desktop.gd` connection to
   `Signals.begin_drag` and `Signals.drag_selection` records and moves already
   selected windows. It is not the SelectionPanel's range-selection start,
   rectangle, hit-test, or result-application path.
6. Comparing F27's parent with `b11fa01` confirms those Desktop drag signal
   hooks remain present before and after cleanup. This is not proof that F27
   did not affect range selection elsewhere; no comparative `0.2.27` runtime
   range-selection result has been collected.

Static analysis candidates are `selection_panel.gd`, `Main.tscn` InputBlocker
and SelectionPanel geometry, `main_2d.gd`, camera/world-coordinate conversion,
input state, selection result application, and any old `10000` bound or clamp.
No runtime source is changed by F28.

## 5. Behavior Split

The future diagnostic must distinguish, without presuming any result:

| Case | Possibility |
|---|---|
| A | Shift state is not detected in the expanded area. |
| B | Drag selection input starts but the rectangle is not drawn. |
| C | The rectangle is drawn but located in the wrong coordinate domain. |
| D | The rectangle is clamped to the old bound. |
| E | The rectangle is correct but hit-testing ignores expanded-area windows. |
| F | Windows are hit-tested in global coordinates while the selection rectangle is local coordinates. |
| G | A selection result is computed but discarded. |
| H | The old area works because selection code remains limited to `10000 x 10000`. |
| I | F27 cleanup removed diagnostic or observer code that had a functional side effect. |

## 6. Diagnostic Classification Framework

The initial classification remains `RANGE_SELECTION_UNRESOLVED`. A future
diagnostic canary must select exactly one of the following evidence-backed
classifications:

- `RANGE_SELECTION_INPUT_NOT_TRIGGERED`
- `RANGE_SELECTION_SHIFT_NOT_DETECTED`
- `RANGE_SELECTION_RECT_NOT_CREATED`
- `RANGE_SELECTION_RECT_COORDINATE_DOMAIN_MISMATCH`
- `RANGE_SELECTION_RECT_OLD_BOUND_CLAMPED`
- `RANGE_SELECTION_HIT_TEST_OLD_BOUND_LIMITED`
- `RANGE_SELECTION_RESULT_DISCARDED`
- `RANGE_SELECTION_CLEANUP_REGRESSION`
- `RANGE_SELECTION_UNRESOLVED`

## 7. 0.2.27 vs 0.2.28 Regression Question

F28 must answer whether `0.2.28` cleanup removed or altered code that had
accidentally enabled expanded-area range selection.

No current evidence compares the same operation on `0.2.27` and `0.2.28`.
The retained Desktop drag hooks make an obvious cleanup deletion less likely,
but they are not the full range-selection path. Therefore no cleanup-regression
conclusion is justified yet.

If a narrow comparison becomes necessary after the diagnostic evidence:

- `0.2.27` FAIL and `0.2.28` FAIL means an older untested gap.
- `0.2.27` PASS and `0.2.28` FAIL means a cleanup regression.

Do not run a broad regression to answer this question.

## 8. Future Diagnostic Proposal

Subject to separate approval, implement exactly one `0.2.29` expanded-area
range-selection diagnostic canary and generate
`Nekochan-ExpandedWorkspace-0.2.29.zip`. Its purpose is diagnosis, not a fix.

The canary must capture one bounded selection attempt only, with no per-frame
logging beyond that sequence. It must not change save data, selection behavior,
workspace bounds, placement, group movement, or template correction behavior.

Required checkpoints:

| Checkpoint | Required evidence |
|---|---|
| `R1_SELECTION_INPUT_START` | Input start and active tool. |
| `R2_SHIFT_STATE` | Shift/multi-select state. |
| `R3_DRAG_START_SCREEN_WORLD` | Mouse screen/world start and camera center. |
| `R4_DRAG_CURRENT_SCREEN_WORLD` | Mouse screen/world current/end and camera center. |
| `R5_SELECTION_RECT_RAW` | Raw rectangle and coordinate domain. |
| `R6_SELECTION_RECT_AFTER_CLAMP` | Old-bound candidate, expanded-bound candidate, actual rectangle, and old-bound detection. |
| `R7_SELECTION_RECT_DRAWN` | Whether the visible selection rectangle was created/drawn. |
| `R8_WINDOW_HIT_TEST_CANDIDATES` | Total selectable candidates, expanded-area candidates, and hit IDs/count. |
| `R9_SELECTION_RESULT` | Computed selected IDs/count before final application. |
| `R10_SELECTION_FINAL_STATE` | Final selected IDs/count and any skip/stop reason. |

The diagnostic must record mouse screen position, mouse world position, camera
center, shift state, drag start/end world coordinates, raw/old/expanded/actual
rectangles, candidate counts, final IDs/count, and an old-bound-limit flag. It
must not log every frame or dump unrelated object state.

### Minimal User Test

1. Install only the approved diagnostic artifact.
2. Place two or three selectable nodes in the expanded area.
3. Move the camera clearly into the expanded area.
4. Hold Shift and drag a selection rectangle around those nodes.
5. Observe whether the rectangle appears and whether the nodes are selected.
6. Repeat once in the old area only if required as a control.
7. Exit without saving if behavior is wrong and provide the bounded logs.

## 9. RC Impact Decision

Expanded-area range selection is non-fatal but is a core multi-node workflow
QoL issue. The preferred path is a narrow targeted fix followed by smoke
verification. If a safe fix is invasive, release can proceed only after an
explicit known-limitation acceptance.

Until then, record the limitation: shift + drag range selection may not work in
the expanded area. Do not treat `0.2.28` as release-ready.

## 10. Stop Conditions

A future diagnostic or fix must stop if it requires or causes any of the
following:

- Large vanilla body copy.
- Save-schema change.
- Broken regular selection/deselection, group movement, manual movement, or
  old-area range selection.
- Dependence on diagnostic-only observer side effects.
- A `WindowContainer.get_position_snapped()` patch.

## 11. Updated Docs

F28 changes only:

- `docs/PHASE_2C_F28_RANGE_SELECTION_EXPANDED_AREA_DIAGNOSTIC_PLAN.md`
- `docs/PHASE_2C_F27_CLEAN_INTEGRATION_RC_REPORT.md`
- `docs/HANDOFF.md`

## 12. Git State

F28 is a local docs-only branch:
`dev/phase-2c-f28-range-selection-diagnostic-plan`.

The intended docs-only commit message is:

```text
docs: plan expanded-area range selection diagnostic
```

## 13. Explicit Non-Actions

F28 does not change runtime code, generate an artifact, run a build or runtime
test, implement a diagnostic or fix, perform cleanup or clean integration,
push, merge, tag, create a Release, publish to Workshop, rewrite history, or
force push.

## 14. Next Recommended Action

Approve implementation of the one bounded `0.2.29` expanded-area range
selection diagnostic canary. Do not authorize a fix, cleanup, clean
integration, RC artifact, public push, tag, Release, or Workshop operation at
this stage.

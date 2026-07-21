# Phase 2C-F29: Expanded-Area Range Selection Diagnostic Canary Report

Status: `F29_RANGE_SELECTION_DIAGNOSTIC_CANARY_READY_FOR_USER_TEST`

F29 is a bounded `0.2.29` diagnostic canary. It observes one Shift + drag
range-selection attempt and does not implement a range-selection fix.

## 1. Scope

The `0.2.28` clean RC is blocked because old-area range selection passes and
expanded-area range selection fails. F29 adds non-consuming observation to the
existing `Desktop` extension only. It does not resize InputBlocker or
SelectionPanel, alter the selection rectangle, mutate selection results, or
change placement, movement, persistence, group resize, template placement,
node limit, or space cap.

The first candidate left-button attempt on the desktop screen while Select is
active or Shift/multi-select is pressed starts the sequence. Release produces
the bounded evidence; a deferred callback captures the vanilla final state.
Later attempts do not emit F29 checkpoints in the same game session.

## 2. Checkpoints

| Checkpoint | Evidence |
|---|---|
| `R1_SELECTION_INPUT_START` | Active tool and InputBlocker/SelectionPanel geometry. |
| `R2_SHIFT_STATE` | Event Shift state and `multi_select` action state. |
| `R3_DRAG_START_SCREEN_WORLD` | Start screen/world/panel-world position and camera. |
| `R4_DRAG_CURRENT_SCREEN_WORLD` | End screen/world/panel-world position and camera. |
| `R5_SELECTION_RECT_RAW` | Raw and normalized rectangle. |
| `R6_SELECTION_RECT_AFTER_CLAMP` | Actual, old, expanded, and input-coverage evidence. |
| `R7_SELECTION_RECT_DRAWN` | Visibility, area, and draw indication. |
| `R8_WINDOW_HIT_TEST_CANDIDATES` | Candidate, hit IDs, and counts. |
| `R9_SELECTION_RESULT` | Computed candidate IDs and counts. |
| `R10_SELECTION_FINAL_STATE` | Final IDs/counts and application check. |

## 3. Static Audit

| Check | Result |
|---|---|
| Range-selection behavior changed | NO; observation only |
| InputBlocker / SelectionPanel size mutation | NO |
| Selection-result mutation | NO |
| Large vanilla body copy | NO |
| Save-schema change | NO |
| WindowContainer extension | NO |
| `get_position_snapped` override | NO |
| F6/F7/F9/F11/F12/F14/F17/F25 behavior changed | NO |
| Group resize changed | NO |
| Template placement changed | NO |
| Node limit / space cap changed | NO |

`git diff --check` passes. A local Godot CLI was not available, so no Codex
runtime launch or game test was performed.

## 4. Artifact

| Item | Value |
|---|---|
| Version | `0.2.29` |
| Path | `dist/Nekochan-ExpandedWorkspace-0.2.29.zip` |
| Size | `15523` bytes |
| File count | `14` |
| ZIP root | `mods-unpacked` |
| SHA-256 | `980af9f72e46dc92d48095525ec03598b16bcfb8da2ac8a931325be616c9186e` |
| Manifest version inside ZIP | `0.2.29` |

The packaged `desktop.gd` contains each R1-R10 checkpoint exactly once. The
artifact is development-only, ignored, and untracked.

## 5. Publish Safety Audit

| Audit item | Count |
|---|---|
| Vanilla-verbatim body | `0` |
| Substantial vanilla-derived code | `0` |
| Third-party copied code | `0` |
| Game binary | `0` |
| Game asset/resource | `0` |
| Save file | `0` |
| Secret | `0` |
| Forbidden file/path | `0` |

## 6. User Verification Status

| Test | Result |
|---|---|
| `0.2.29` single Mod loaded | NOT TESTED |
| Shift state captured | NOT TESTED |
| Drag start/end captured | NOT TESTED |
| Selection rect created | NOT TESTED |
| Selection rect drawn | NOT TESTED |
| Selection rect coordinate domain classified | NOT TESTED |
| Expanded-area hit-test candidates captured | NOT TESTED |
| Selection result captured | NOT TESTED |
| Final selected state captured | NOT TESTED |
| Classification | NOT TESTED |

## 7. User Test Steps

1. Install only `Nekochan-ExpandedWorkspace-0.2.29.zip`.
2. Start the game and confirm the Mod loads.
3. Put two or three selectable nodes in the expanded area.
4. Move the camera clearly into the expanded area.
5. Hold Shift and drag a selection rectangle around those nodes once.
6. Observe whether the rectangle appears and whether the nodes are selected.
7. Repeat once in the old area only if a control case is needed.
8. Do not save after a failure. Exit and collect `[F29]` and
   `[RANGE_SELECTION]` lines from game and Mod Loader logs.

## 8. Classification After User Evidence

Choose exactly one after evidence review:

- `RANGE_SELECTION_INPUT_NOT_TRIGGERED`
- `RANGE_SELECTION_SHIFT_NOT_DETECTED`
- `RANGE_SELECTION_RECT_NOT_CREATED`
- `RANGE_SELECTION_RECT_COORDINATE_DOMAIN_MISMATCH`
- `RANGE_SELECTION_RECT_OLD_BOUND_CLAMPED`
- `RANGE_SELECTION_HIT_TEST_OLD_BOUND_LIMITED`
- `RANGE_SELECTION_RESULT_DISCARDED`
- `RANGE_SELECTION_CLEANUP_REGRESSION`
- `RANGE_SELECTION_UNRESOLVED`

## 9. Stop Conditions

Stop if a diagnostic or future fix requires a range-selection fix, large
vanilla body copy, save-schema change, functional observer side effects, a
`WindowContainer` or `get_position_snapped` patch, or breaks normal selection,
movement, or old-area range selection. Also stop on build, static-check, or
artifact-safety-audit failure. Do not stack fixes.

## 10. Next Action

Install only `0.2.29` and run one expanded-area Shift + drag diagnostic attempt.
Do not implement a fix, cleanup, clean integration, or release operation before
the logs and visual result are reviewed.

# Phase 2C-F1 Implementation Plan

Status: `FAILED_VERIFICATION_REGRESSION`

Result:

- v0.2.10 development artifact was built and tested by the user.
- Position persistence remained `FAIL`.
- Deselection regression was observed.
- This plan must not be reused as the next implementation plan.

Follow-up analysis: `docs/PHASE_2C_F2_0.2.10_REGRESSION_ANALYSIS.md`

## Purpose

Fix the v0.2.9 Release Candidate blocker where expanded-area node positions are not retained after save, exit, restart, and load.

## Non-Goals

- Do not publish the v0.2.9 Draft Release.
- Do not replace the v0.2.9 RC artifact.
- Do not change node limit behavior.
- Do not change the `space` upgrade cap.
- Do not change camera bounds, grid/background rendering, placement workflows, or group-selection movement except where required to preserve restored positions.
- Do not change save schema.
- Do not add configuration UI.
- Do not optimize performance in this phase.

## Development Version

Use separate development version `0.2.10` for diagnostic or fix builds. This is not a public release version until a replacement Release Candidate is explicitly approved.

## Proposed Patch

1. Add a minimal Script Extension for `scenes/windows/window_container.gd`.
2. Override only `get_position_snapped(to)`.
3. Use `WorkspaceAreaConfig.get_max_position(size)` as the maximum bound.
4. Register the extension in `mod_main.gd` for the development build only.
5. Do not copy the vanilla `_ready()` body.

Outcome:

- Implemented in v0.2.10.
- User verification rejected this patch as a fix.
- The global `WindowContainer` Script Extension is now considered unsafe for release promotion because it coincided with a deselection regression.

## Validation Plan

User clean install verification must use the new development artifact, not the failed v0.2.9 RC artifact.

Required checks:

- single node expanded-area position retained after save/restart/load
- group frame expanded-area position retained after save/restart/load
- group child positions retained
- connections retained
- node state retained
- level/cost retained
- normal placement still works
- 500+ placement capability still works
- camera expanded area still works
- grid/background still covers expanded area
- click placement still works
- drag placement still works
- existing node movement still works
- group-selection movement still works

## Stop Conditions

Stop and re-evaluate if:

- the `window_container.gd` method override does not affect restored concrete node positions
- restored positions are already clamped in the save file
- the patch requires copying a large vanilla function body
- any existing v0.2.9 verified feature regresses

Triggered stop conditions:

- The method override did not fix restored concrete node positions.
- An existing v0.2.9 behavior regressed: selected nodes could not be deselected by empty-area click or the options-menu `x` control.

## Approval

Approved by the user for the `0.2.10` development test implementation.

Closed after failed verification. Any further Mod code change requires a new or updated implementation plan and user approval.

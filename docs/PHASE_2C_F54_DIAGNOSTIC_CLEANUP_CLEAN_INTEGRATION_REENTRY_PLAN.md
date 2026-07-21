# Phase 2C-F54: Diagnostic Cleanup / Clean Integration Re-entry Plan

## Result

`F54_DIAGNOSTIC_CLEANUP_CLEAN_INTEGRATION_REENTRY_PLAN_READY`

F54 is docs-only. It records how to move from the verified F53 `0.2.39`
InputBlocker coverage canary toward a future clean RC without changing runtime
code, creating an artifact, building, testing, releasing, pushing, tagging, or
publishing.

## Evidence

F53 preserved the vanilla `InputBlocker -> SelectionPanel` route and proved that
the expanded-area range-selection failure was addressed by moving the
InputBlocker coverage to the modded workspace rect.

Verified user-test evidence:

- `F53_INPUTBLOCKER_COVERAGE_CANARY_PASS`
- old-area Shift+drag guard PASS: rectangle appeared, nodes selected, Camera did
  not move
- expanded-area Shift+drag range selection PASS
- normal click selection PASS
- empty-click deselection PASS
- only `Nekochan-ExpandedWorkspace-0.2.39.zip` was loaded

F53 artifact evidence:

- path: `dist/Nekochan-ExpandedWorkspace-0.2.39.zip`
- ZIP root: `mods-unpacked`
- file count: `15`
- size: `19138` bytes
- SHA-256:
  `2baed5a8214fcd06522eac2afb044f09f251e247096df49cf5b68f44cf3aae8d`

## Changed Files

F54 adds this plan only.

`docs/HANDOFF.md` is intentionally not updated by F54 because it is already
dirty and contains mixed operational-rule and F53 handoff edits. `AGENTS.md` is
also dirty and must not be staged, committed, overwritten, or otherwise touched
without explicit instruction.

## Artifact

None. F54 does not generate `0.2.40` or any other artifact.

## User Test Result

No F54 runtime test. F54 is documentation only.

## Classification

`F54_DIAGNOSTIC_CLEANUP_CLEAN_INTEGRATION_REENTRY_PLAN_READY`

## Next Action

After human approval, implement one bounded clean integration step that keeps
the F53 InputBlocker coverage correction and removes F51/F53 diagnostic noise.
That future implementation should be treated as F55 or equivalent, not as part
of F54.

## 1. Branch / Base

- F54 branch:
  `dev/phase-2c-f54-diagnostic-cleanup-clean-integration-reentry-plan`
- Base:
  `1e08ac9` (`docs: record F53 input blocker coverage pass`)
- F53 runtime canary commit:
  `aa5498d` (`diagnose: add F53 input blocker coverage canary`)
- F51 runtime diagnostic commit:
  `d168ad8` (`diagnose: add input blocker camera route logging`)

## 2. Scope And Non-goals

F54 plans only the future cleanup and clean integration re-entry. It does not
authorize:

- runtime code changes
- cleanup implementation
- clean integration implementation
- manifest version bump
- artifact generation
- build
- runtime test
- push, merge, tag, GitHub Release, or Steam Workshop publish
- history rewrite or force push
- staging or committing `AGENTS.md`
- risky overwrite of dirty `docs/HANDOFF.md`

## 3. Functionality To Keep

The future clean RC must preserve the F53 functional correction:

```gdscript
input_blocker.position = Vector2.ZERO
input_blocker.size = WorkspaceAreaConfig.get_workspace_size()
```

Implementation constraints for the future cleanup:

- Keep the correction after vanilla Desktop initialization unless a smaller
  timing is proven by source review.
- Keep the coordinate target as the Desktop-local workspace rect
  `Rect2(Vector2.ZERO, WorkspaceAreaConfig.get_workspace_size())`.
- Keep the parent/size verification concept only as a fail-closed guard if it is
  still useful after diagnostic cleanup.
- Do not add SelectionPanel edits, manual event forwarding, a Camera guard,
  Main2D route mutation, save changes, or `WindowContainer` patches.
- Preserve all previously verified clean-integration functionality from F27/F53:
  node limit `1000`, `space` cap `200`, `20000 x 20000` workspace visuals,
  click placement, drag placement, existing movement, group movement, exact
  single/group persistence, group resize fixes, template/schematic placement,
  and endpoint-owned template connector correction.

## 4. Diagnostic Elements To Remove

The future clean implementation should remove or reduce these diagnostic-only
elements:

| Element | Current role | Future treatment |
|---|---|---|
| F51 `[B0-B10]` logs | Route and old-guard diagnostics | Remove from clean RC. |
| F53 `[C0-C7]` logs | Coverage canary proof | Remove from clean RC. |
| `_f51_active_attempt` and old-guard state | User-test telemetry state | Remove unless a minimal one-shot guard is separately justified. |
| `_f51_connect_input_blocker_observer()` | Passive route observation | Remove after keeping the F53 coverage correction. |
| `_f51_record_desktop_input()` and related helpers | Attempt acquisition and classification | Remove. |
| `_f51_classify_attempt()` / `_f53_classify_attempt()` | Diagnostic-only classification | Remove. |
| `camera_2d.gd` extension | Passive Camera route observer | Remove if no non-diagnostic caller remains. |
| `main_2d.gd` route observer hooks | Passive Main2D route observer | Remove only the F51 hooks; keep visual workspace sizing. |
| Desktop diagnostic-only logging | User-test evidence output | Remove from clean RC. |
| User-test-only telemetry spillover | Attempts after canonical target | Remove by deleting the observer path. |
| Canary startup prose | `0.2.39` F53 identification | Replace with one concise clean version load line. |

The cleanup must distinguish diagnostics from functional code already present in
the clean RC lineage. In particular, `main_2d.gd` still owns expanded Desktop,
Background, and Lines sizing and must not be removed wholesale merely because it
also contains F51 route hooks.

## 5. Items That Must Not Return

The future cleanup must not reintroduce any of the following:

- `0.2.30` SelectionPanel extension registration
- `SelectionPanel._process()` override
- SelectionPanel logic edit
- manual event forwarding
- Camera guard
- `WindowContainer/get_position_snapped` override
- save schema change
- large vanilla body copy
- publication, tag, release, push, or Workshop operation without explicit
  approval

## 6. Future Clean RC Candidate

Version proposal: `0.2.40`

Artifact proposal: `Nekochan-ExpandedWorkspace-0.2.40.zip`

Purpose:

```text
Keep the F53-passed InputBlocker coverage correction and remove diagnostic
noise, producing a clean RC candidate for targeted smoke only after approval.
```

The future `0.2.40` implementation must be approved before runtime cleanup,
manifest update, build, artifact generation, or testing.

## 7. Future Implementation Outline

After approval, the future implementation should proceed in one bounded
cleanup/integration pass:

1. Start from the F54 plan branch or an approved descendant of F53.
2. Update manifest/startup text for `0.2.40` only after approval.
3. Keep a minimal InputBlocker coverage helper in `desktop.gd`.
4. Remove F51/F53 attempt tracking, route observers, checkpoint logs, and
   classification helpers.
5. Remove `camera_2d.gd` and its `mod_main.gd` registration if it has no
   remaining non-diagnostic purpose.
6. Remove only the F51 route hooks from `main_2d.gd`; keep expanded visual area
   behavior.
7. Run static audits before artifact generation.
8. Generate and inspect the clean RC artifact only after the implementation is
   approved.
9. Run the smoke matrix in section 8. Any failure blocks clean RC status.
10. Record results in docs before any release decision.

## 8. Future Smoke Test Matrix

The future clean RC is not clean-RC-ready unless every required smoke item
passes. A failure in any item below blocks clean RC classification.

| # | Smoke test | Required result |
|---|---|---|
| 1 | old-area Shift+drag range selection | Rectangle appears, nodes select, Camera does not move. |
| 2 | expanded-area Shift+drag range selection | Rectangle appears, nodes select, Camera does not move. |
| 3 | normal click selection | Single click selects the intended node. |
| 4 | empty-click deselection | Empty click clears selection without side effects. |
| 5 | click placement | New node appears at the expanded-area target. |
| 6 | drag-from-palette placement | Drag placement appears at the expanded-area target. |
| 7 | existing node movement across old boundary | Existing node crosses old boundary and remains aligned. |
| 8 | group movement across old boundary | Group frame and children move together across old boundary. |
| 9 | single-node save/load persistence in expanded area | Position survives save, exit, restart, and load. |
| 10 | group save/load persistence in expanded area | Frame, children, membership, relative layout, and connection/state survive. |
| 11 | template/schematic pre-placement in expanded area | Preview/final placement appear near expanded camera target with owned connector correction. |
| 12 | grid density visual check | Expanded grid/background cover the workspace with expected density. |

Recommended additional checks if time allows: startup single-mod load, `space`
cap `200`, node limit `1000`, group top-right/right resize, and no unrelated
template windows/connectors moved.

## 9. Static Audit Requirements For Future Cleanup

Before a future clean RC artifact is built, static audit must confirm:

- no `selection_panel.gd` extension path
- no SelectionPanel override or logic edit
- no `WindowContainer/get_position_snapped` override
- no save-schema change
- no large vanilla body copy
- no F51/F53 checkpoint labels
- no `camera_2d.gd` registration unless a non-diagnostic need is proven
- `main_2d.gd` still preserves expanded visual workspace sizing
- `desktop.gd` keeps only the minimal InputBlocker coverage correction plus
  existing verified functional fixes
- package allowlist and forbidden-path checks pass

## 10. Process Simplification

After F54, avoid further micro-phases for documentation-only bookkeeping. Low
risk docs updates and result recording may proceed autonomously.

Human approval remains mandatory for:

- runtime cleanup implementation
- clean RC artifact generation
- release, tag, push, GitHub Release, or Workshop publish
- any new SelectionPanel/InputBlocker/Camera/Main2D/Desktop behavior change

## 11. Git State Expectations

F54 commit should include only:

- `docs/PHASE_2C_F54_DIAGNOSTIC_CLEANUP_CLEAN_INTEGRATION_REENTRY_PLAN.md`

F54 must not stage or commit:

- `AGENTS.md`
- dirty `docs/HANDOFF.md`
- runtime sources
- `dist/`
- logs
- `vanilla-reference/`
- game files

## 12. Explicit Non-actions

F54 does not modify runtime code, generate artifacts, build, run runtime tests,
implement cleanup, perform clean integration, push, merge, tag, create a GitHub
Release, publish to Steam Workshop, rewrite history, force push, stage
`AGENTS.md`, or overwrite dirty `docs/HANDOFF.md`.

## 13. Human Next Action / Escalation Footer

Human Next Action:
Review and approve or reject the future F55 clean integration implementation
scope: keep F53 InputBlocker coverage correction, remove F51/F53 diagnostics,
and prepare `0.2.40` only after approval.

Next Action Type:
Human approval required before runtime cleanup implementation.

ChatGPT Escalation:
Optional

Reason:
The fix direction is already proven by F53, but clean integration is an
approval-gated runtime cleanup and release-candidate preparation step.

Blocked Until Human Approval:
YES

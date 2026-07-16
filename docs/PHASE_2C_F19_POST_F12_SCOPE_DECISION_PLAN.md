# Phase 2C-F19: Post-F12 Scope Decision Plan

Status: `F19_POST_F12_SCOPE_DECISION_PLAN_READY`

This is a docs-only scope-decision plan. It does not authorize runtime code
changes, artifact generation, build execution, full regression, release
integration, diagnostic cleanup implementation, version bump, public master
push, branch merge, tag, GitHub Release, Workshop publication, history rewrite,
or force push.

## Purpose

Determine what remains before clean integration and release-candidate
preparation, using the verified post-F17 F12 group persistence result as the
current evidence boundary.

## Git Topology

| Item | Value |
|---|---|
| Current verified HEAD | `4fe64b5abde9088f6556ff234d7af15104fbcf16` |
| Current branch for this plan | `dev/phase-2c-f19-post-f12-scope-decision` |
| `origin/master` | `0489e834bb1eff79742081f32656ee43f04a2cb5` |
| Local development history | Ahead of `origin/master` by 40 commits before F19 |
| Forbidden operations | reset, rebase, amend, history rewrite, force push, public master merge |

## Verified Status Summary

| Area | Status |
|---|---|
| F6 single-node exact local persistence | `VERIFIED` |
| F7 vanilla-density primary line grid restoration | `VERIFIED` |
| F9 click placement local alignment | `VERIFIED` |
| F11 drag placement local alignment | `VERIFIED` |
| Existing-node movement across old boundary | `VERIFIED` from earlier 0.2.9 path |
| Group-selection movement across old boundary | `VERIFIED` from earlier 0.2.9 path |
| F14 group resize old-bound snap | `VERIFIED` |
| F17 top-right group resize width-collapse | `VERIFIED` |
| F17 right-side childless group resize width-collapse | `VERIFIED` |
| F12 group persistence post-F17 | `VERIFIED` |

F12 post-F17 evidence records exact restored local positions for the group
frame and two children, zero relative deltas, `membership = true`,
`connector_count = 1`, user PASS for group selectability, and no double
movement through the stability checkpoints.

## Current Artifact Status

| Item | Value |
|---|---|
| Current development canary | `0.2.24` |
| Artifact | `Nekochan-ExpandedWorkspace-0.2.24.zip` |
| Size | `22115 bytes` |
| SHA-256 | `942f67e0e0535b208a6ecc67d1d13cd9baf714035a8471dcdad55926373e7e7c` |
| Classification | Development canary with diagnostic code/logging |
| Release status | Not a clean release candidate |

The `v0.2.9` draft/release artifact remains unchanged. No public release
operation has occurred.

## Remaining Scope Inventory

| Item | Classification | Recommendation |
|---|---|---|
| Template / schematic paste in expanded area | targeted regression | Exercise one expanded-area paste/schematic workflow before RC decision. If it fails, decide fix vs documented limitation. |
| Group resize all-edges matrix | defer | Do not spend time on an exhaustive edge matrix unless targeted checks expose a blocker. |
| Bottom / bottom-right height-collapse equivalent | targeted regression | Verify because F17's guarded correction also evaluates bottom paths, but only right/top-right have runtime PASS evidence. |
| Connector-point movement | targeted regression | Verify basic connector edit/movement in expanded area because it is user-visible and not covered by F12 connector count. |
| Group resize after save/load | targeted regression | Verify one saved/reloaded group still resizes without old-bound jump or collapse. |
| Large save / many-node performance | defer | Keep as known release risk unless performance symptoms appear in targeted testing. |
| Long-running performance | defer | Not required before RC unless targeted testing shows degradation. |
| High-density grid modes other than primary line grid | known limitation | Document unverified renderer modes; do not block RC on exhaustive visual-mode coverage. |
| Selection behavior after all current changes | required before RC | Smoke-test empty-area deselect, menu close/deselect, single selection, multi-selection, and group selection. |
| Clean install after diagnostic cleanup | required before RC | Must be done on the future clean RC artifact, not on diagnostic 0.2.24. |
| Node limit 1000 regression | targeted regression | Verify one high-count or near-limit path before RC because it is a core mod feature. |
| Space upgrade cap 200 regression | targeted regression | Verify UI cap/purchase behavior still reflects 200 after cleanup. |
| Manual group movement regression | targeted regression | Recheck group frame and child movement across old boundary after F17/F12. |
| Single-node persistence regression after F17/F12 | targeted regression | Recheck one save/exit/restart/load path using current canary before cleanup and again on the clean RC. |
| Click placement regression after F17/F12 | targeted regression | Recheck one expanded-area click-created node. |
| Drag placement regression after F17/F12 | targeted regression | Recheck one expanded-area drag-created node. |

## Diagnostic Cleanup Inventory

| Diagnostic area | Active source | Future cleanup classification |
|---|---|---|
| F6 restoration logs | `extensions/scripts/desktop.gd` | Remove before release or gate behind explicit debug flag. Keep only if the next targeted regression uses current 0.2.24. |
| F7 grid logs/metadata | `extensions/scripts/lines.gd` | Gate behind debug flag or reduce to non-diagnostic startup info before release. |
| F9 click logs and target flag | `extensions/scripts/windows_tab.gd` | Remove before release after targeted click regression is complete. |
| F11 drag logs and observer | `extensions/scenes/window_dragger.gd`, `extensions/scenes/drag_placement_diagnostic_observer.gd` | Remove before release after targeted drag regression is complete. |
| F12 group persistence logs | `extensions/scripts/desktop.gd` | Remove before release after F12 evidence is no longer needed for targeted regression. |
| F13 group resize observer/logs | `extensions/scenes/windows/window_group.gd`, `extensions/scenes/group_resize_diagnostic_observer.gd` | Remove before release unless a resize regression needs one more diagnostic canary. |
| F14 resize snap logs | `extensions/scenes/windows/window_group.gd` | Remove before release after targeted resize smoke test. |
| F15 populated group resize logs | `extensions/scenes/windows/window_group.gd` | Remove before release after targeted populated resize smoke test. |
| F16 standalone logs | no standalone active F16 label found in current source | No separate cleanup item; ensure stale F16 plan/report language is not treated as active evidence. |
| F17 right/bottom resize logs and target flags | `extensions/scenes/windows/window_group.gd` | Remove before release or gate behind debug flag after bottom/right targeted regression. |
| Temporary observers | `drag_placement_diagnostic_observer.gd`, `group_resize_diagnostic_observer.gd` | Remove before release unless retained behind an explicit debug-only registration path. |
| Diagnostic target acquisition flags | multiple extension files | Remove before release with their associated logging paths. |
| Versioned report-only canary load messages | `mod_main.gd`, `manifest.json` | Replace with clean RC wording during clean integration. |

F19 does not remove or gate any diagnostics.

## Clean Integration Considerations

The current development branch is ahead of public `origin/master` by 40 commits.
Public `master` remains at `0489e834bb1eff79742081f32656ee43f04a2cb5`.
The old `v0.2.9` draft artifact is stale relative to verified fixes.
`0.2.24` is the best verified canary, but it is diagnostic-heavy and should
not become the release candidate as-is.

A future clean integration should:

1. Create a clean integration branch from the current verified code.
2. Remove or gate diagnostic logs, target flags, and temporary observers.
3. Retain only the minimal runtime fixes that have verification evidence.
4. Update canary wording and manifest metadata to clean RC wording.
5. Generate a new clean RC artifact.
6. Perform targeted regression on the clean RC artifact.
7. Decide separately whether to push, tag, create a GitHub Release, or publish.

## Candidate Next Paths

### Option A: Targeted Regression Plan First

Create a targeted regression test plan using current `0.2.24`. Do not clean up
diagnostics yet. Goal: verify no regressions in the high-risk paths before
touching the now-verified runtime code.

### Option B: Clean Integration Plan First

Plan diagnostic cleanup and clean RC artifact preparation. Do not alter runtime
behavior beyond removing or gating diagnostics. This is useful after targeted
regression scope is agreed.

### Option C: Known-Limitations Release Candidate Path

Accept some unverified paths as documented known limitations. Prepare for a
clean RC only after targeted high-risk checks, and do not attempt exhaustive
low-risk matrices.

## Recommended Next Action

Create a targeted regression plan next.

Rationale: current evidence is strong for the fixed paths, but cleanup would
change the artifact before basic cross-path regression is scoped. A targeted
plan should focus on user-visible destructive or blocking failures, avoid
exhaustive low-risk matrices, and keep the release candidate separate from the
diagnostic canary.

## Explicit Non-Actions

F19 did not change runtime code, generate artifacts, build, run full
regression, run release integration, implement diagnostic cleanup, bump
version, push public master, merge branches, tag, create a GitHub Release,
publish to Workshop, rewrite history, or force push.

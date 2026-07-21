# Phase 2C-F26: Diagnostic Cleanup and Clean Integration Plan

Status: `F26_DIAGNOSTIC_CLEANUP_CLEAN_INTEGRATION_PLAN_READY`

Result: `F26_DIAGNOSTIC_CLEANUP_CLEAN_INTEGRATION_PLAN_READY` / `BLOCKED`

F26 is a docs-only transition plan. It records how to move from the verified,
diagnostic-heavy `0.2.27` canary to a future clean release-candidate branch
without changing any runtime code, creating an artifact, or running a test.
Cleanup and clean integration remain blocked until this plan is separately
approved for implementation.

## 1. Current Verified Status

The current verified head is `4c6ef67` (`docs: record F25 connector ownership
pass`). The F25 user test loaded only `0.2.27`, passed all nine F25
checkpoints, and safely corrected the pasted template from the old-bound
candidate to the expanded camera target. The runtime connector count difference
(`29` staged, `17` instantiated) is expected-path evidence; all `17` observed
connectors were classified as internal to the pasted set.

Closed targeted gates:

- `F6_SINGLE_NODE_EXACT_PERSISTENCE_VERIFIED`
- `F7_GRID_DENSITY_VERIFIED`
- `F9_CLICK_LOCAL_ALIGNMENT_VERIFIED`
- `F11_DRAG_LOCAL_ALIGNMENT_VERIFIED`
- `F12_GROUP_PERSISTENCE_REENTRY_VERIFIED_POST_F17`
- `F14_GROUP_RESIZE_OLD_BOUND_SNAP_FIX_VERIFIED`
- `F17_TOP_RIGHT_RIGHT_SIDE_WIDTH_COLLAPSE_VERIFIED`
- `F20_TARGETED_REGRESSION_PASS_WITH_OPEN_RC_GATES`
- `SPACE_UPGRADE_CAP_200_SMOKE_PASS`
- `GROUP_MOVEMENT_ACROSS_OLD_BOUNDARY_SMOKE_PASS`
- `F25_TEMPLATE_CONNECTOR_OWNERSHIP_CANARY_PASS`

The previously confirmed template classification,
`TEMPLATE_CAMERA_SOURCE_OLD_BOUND_CLAMPED`, is no longer an open functional
limitation on the F25 primary path. It must instead be preserved through
cleanup and retested in the future clean RC.

## 2. Scope and Non-Goals

F26 plans only the following future work:

1. Remove or gate canary telemetry while retaining proven functional behavior.
2. Create a clean integration implementation branch from the verified F25 head.
3. Produce and test a future clean RC only after separate approval.

F26 does **not** authorize runtime edits, diagnostic cleanup implementation,
clean integration implementation, manifest/version changes, artifact creation,
builds, runtime tests, push, merge, tag, Release, Workshop publication,
history rewrite, or force push.

## 3. Runtime Fixes That Must Survive Cleanup

The clean integration implementation must preserve each explicit behavior below;
none may be reduced to a general statement such as "expanded workspace fixes":

1. Node limit of `1000`.
2. `space` upgrade cap of `200`.
3. Expanded workspace size of `20000 x 20000`.
4. Primary grid density and `50`-unit alignment.
5. Click placement local-coordinate alignment.
6. Drag placement local-coordinate alignment.
7. Existing-node movement across the old boundary.
8. Exact single-node local save/load persistence.
9. Group save/load persistence, including children, relative layout,
   membership/selectability, and connection/state.
10. Group movement across the old boundary.
11. Group resize old-bound jump prevention.
12. Group right/top-right width-collapse prevention.
13. Template/schematic pre-placement near the expanded-camera target.
14. Endpoint-ownership classification and correction of pasted-template
    connectors.
15. Selection/deselection and manual movement after template paste.
16. Non-movement of unrelated windows and connectors during template correction.

The cleanup must retain the narrow correction surfaces already established:
local `position` assignments with the existing notification path where required,
the bounded `WindowGroup.move_snapped()` resize path, and the guarded
post-`super.paste()` transaction. It must not substitute a
`WindowContainer.get_position_snapped()` patch, copy a large vanilla body, or
introduce a save-schema change.

## 4. Diagnostic Cleanup Inventory

Classification means the intended treatment in a **future approved
implementation**, not a change made by F26. A debug gate should default off and
must not add a configuration UI in this phase.

| Diagnostic or observer | Current role | Intended treatment | Preservation constraint |
|---|---|---|---|
| F6 restore target filters and saved/local checkpoint logs | Bounded restore evidence in `desktop.gd` | Remove before clean RC | Keep the one-shot deferred exact-local restore and `moved` notification. |
| F7 grid coverage log | One startup grid geometry report in `lines.gd` | Remove before clean RC | Keep four-tile coverage and 50-unit rendering geometry. |
| F9 one-click target flag and checkpoints | Click coordinate canary output | Gate behind debug flag | Keep click target calculation and final local assignment; do not make logging control correction. |
| F11 target flag and observer checkpoints | Drag canary output plus lifecycle correction | Gate logs behind debug flag | Keep `DragPlacementDiagnosticObserver`'s deferred local correction; remove/gate only its telemetry and diagnostic-only timer/checkpoints. |
| F12 G1-G11 and `[F12][STOP]` | Group persistence target acquisition and observation | Remove before clean RC | Keep F6 restoration behavior; F12 correlation is not a required production path. |
| F13 resize observer and R1-R5 logs | Pure disappearance diagnosis | Remove before clean RC | Keep the functional expanded resize path; delete the observer only after proving no functional caller remains. |
| F14 resize input/output/deferred/release logs | Old-bound resize canary telemetry | Remove before clean RC | Keep expanded clamp, `50`-unit snap, and normal non-resize delegation. |
| F15 populated-resize geometry logs | Pure width-collapse diagnosis | Remove before clean RC | Keep minimum-size and geometry correction logic now required by F17. |
| F16 target-mismatch remnants, if present | Historical diagnostic residue | Inspect before deciding | Remove only after static search proves it cannot alter a correction decision. |
| F17 target selection, correction, and release logs | Right/top-right resize diagnostic around a functional correction | Gate logs behind debug flag | Preserve eligibility, width/height guards, and correction; only remove acquisition flags and logging that do not affect behavior. |
| F20 references and report-only gates | Documentation, not runtime | Keep in reports only | Do not carry report labels into the clean artifact. |
| F21 T1-T8 template observations | Template diagnosis in `desktop.gd` | Remove before clean RC | Keep no F21 diagnostic observer or data capture; F25 supersedes the correction path. |
| F23 paste guard/correction logs | Earlier guarded template canary telemetry | Remove before clean RC | Retain only F25's functional guard model, not obsolete F23 count-equality behavior. |
| F25 ownership checkpoints and coordinate/ID records | Verified template correction telemetry | Gate detailed logs behind debug flag | Retain pasted-window validation, resource ownership, connector classification, delta translation, selection check, and fail-closed behavior. |
| Temporary observers and one-shot booleans | Canary acquisition/lifetime control | Remove or gate after per-call review | Do not remove F11's correction lifecycle or any flag still used for functional idempotence. |
| Canary loader/version banners and verbose startup messages | `mod_main.gd` canary identification | Replace with low-noise production-safe startup confirmation | Retain a single versioned load line and the R4 failure warning; remove phase lists and canary prose. |

The only proposed production-safe logs are: one concise successful mod-version
startup confirmation, and warnings for an R4 application failure or an
unexpected fail-closed template correction skip. The latter must be once per
session, omit coordinate/resource dumps, and must not change placement behavior.

## 5. Functional Preservation Map

| Source file | Functional fixes to preserve | Diagnostics to remove or gate | Risk | Post-cleanup smoke coverage |
|---|---|---|---|---|
| `mod_main.gd` | Extension registrations; R4 `space` cap application | Replace F25 canary banners with one low-noise load line; retain failure warning | High: registration/order | Clean startup, expected extensions, cap `200` UI/purchase |
| `manifest.json` | Compatible loader/game metadata | Replace only during approved clean RC version bump | High: loader/version mismatch | Clean install and single-Mod load |
| `extensions/scripts/workspace_area_config.gd` | `20000` workspace and expanded max position | None expected | High: shared geometry | Grid, click, drag, movement, persistence, resize |
| `extensions/scripts/desktop.gd` | Node limit, F6 restore, existing movement, group persistence interaction, F25 pasted-set correction | Remove F6/F12/F21/F23 logs; gate F25 detail; inspect F16 residue | Critical: shared restore/paste path | Single/group persistence; group movement; template recall/layout/connectors/selection/unrelated objects |
| `extensions/scenes/windows/window_group.gd` | Group movement, expanded resize snap, width-collapse correction | Remove F13/F14/F15 logs and observer hookup; gate/remove F17 logs without changing guards | Critical: group geometry | Top-right/right resize; group movement; group persistence |
| `extensions/scenes/window_dragger.gd` | Drag target and deferred local correction launch | Gate F11 target log and acquisition flag | High: placement lifecycle | Expanded-area drag immediate/settled alignment |
| `extensions/scripts/windows_tab.gd` | Click target and final local correction | Gate F9 logs/acquisition flag | High: placement lifecycle | Expanded-area click immediate/settled alignment |
| `extensions/scenes/main_2d.gd` | Camera and visual `20000` workspace sizing | None expected | High: camera/visual boundary | Grid coverage and camera movement |
| `extensions/scenes/paint.gd` | Expanded visual background drawing | None expected | Medium: visual coverage | Grid/background across expanded area |
| `extensions/scripts/lines.gd` | Primary grid tiles and `50`-unit density | Remove F7 startup geometry log | High: grid scale/density | Grid density and old/new seam |
| `extensions/scenes/drag_placement_diagnostic_observer.gd` | Deferred F11 local assignment | Remove/gate logging-only checkpoints; retain or rename only if the correction still needs this lifecycle object | Critical: correction is not diagnostic-only | Expanded-area drag immediate/settled alignment |
| `extensions/scenes/group_resize_diagnostic_observer.gd` | None; observer is diagnostic-only | Remove after callers are removed | Medium: verify no remaining callbacks | Group resize smoke |

`schematics_tab.gd` is capacity-related and must be statically inspected during
implementation even though it has no F26 cleanup change currently planned. Its
post-cleanup coverage is template recall plus node-limit `1000` smoke.

## 6. Clean Integration Strategy

After explicit approval, use this ordered and reversible local workflow:

1. Create a clean integration implementation branch from the verified F26 plan
   commit, which itself is based on F25 head. Do not merge or rebase prior
   canary branches.
2. Perform a file-by-file cleanup according to the preservation map. Separate
   logging-only removal from every correction change in the diff review.
3. Retain only the approved low-noise production logs and any functional
   lifecycle helper required for F11/F17/F25 behavior.
4. Static-audit extension registrations, manifest version consistency, absence
   of forbidden extensions, no large vanilla body copy, and no save-schema
   change.
5. Update the manifest only for the approved clean RC candidate version.
6. Generate the allowlisted clean artifact, inspect its root and forbidden-file
   exclusions, then install only that one zip for a clean-install/startup smoke.
7. Run the high-risk smoke suite in section 8, collect concise logs only where
   production logs or loader output remain relevant, and record results.
8. Decide whether RC gates close. Push, public merge, tag, Release, and Workshop
   remain separate explicit approvals after that decision.

## 7. Version and Artifact Recommendation

Recommend `0.2.28 clean RC`, with the future artifact named
`Nekochan-ExpandedWorkspace-0.2.28.zip`.

`0.2.28` accurately follows the verified `0.2.24`-`0.2.27` development
canaries while avoiding an unsupported semantic-major claim. `0.3.0` should be
reserved for a separately scoped public-release decision or material feature
change. The stale `0.2.9` draft must remain historical failed-RC evidence and
must not be replaced, retagged, or republished.

F26 does not apply this version bump or create this artifact.

## 8. Required Post-Cleanup Smoke Plan

The future clean RC must use a clean install with exactly one active mod zip.
Each failure below is an RC stop condition until investigated.

1. Startup: single-Mod load, expected extensions installed, no fatal loader
   errors.
2. Workspace visual: camera movement and grid/background coverage to
   `20000 x 20000`, including `50`-unit density and the old/new seam.
3. Placement: click and drag placement in the expanded area, both immediately
   and after opening settle.
4. Existing-node movement: move across the old boundary and confirm alignment.
5. Selection: selection plus empty-click/menu deselection.
6. Single-node persistence: expanded-area save, exit, restart, load, and exact
   local position.
7. Group resize: empty/populated top-right and right-side resize, with no
   old-bound jump or width collapse.
8. Group persistence: frame, children, relative layout, membership,
   selectability, and connection/state after save/restart/load.
9. Group movement: move a selected group across the old boundary; verify child
   following, relative layout, connection/state, selection, and deselection.
10. Capacity: `space` cap `200` UI/purchase flow and node-limit `1000` smoke.
11. Template/schematic: recall near an expanded camera; verify preview and final
    location, relative layout, connection/state, selection/deselection, manual
    movement, and untouched unrelated windows/connectors.

Record `res://mods-unpacked/` path warning, `ad_prompt.gd` parse error, and
renderer shutdown messages occurring after a completed test as environment
baselines. They are not RC blockers unless they become fatal or attribution
changes.

## 9. Known Limitations and Deferred Work

| Item | Classification | Required treatment |
|---|---|---|
| All-edge group-resize matrix | Optional future targeted test | Top-right/right are verified; do not imply exhaustive edge coverage. |
| Bottom/bottom-right height-collapse equivalent | Deferred | Investigate only through a separately approved targeted plan. |
| Connector custom-point movement full verification | Deferred | F25 observed zero custom points; do not claim broader connector-point coverage. |
| Large saves/many-node performance | Deferred | No performance or stress claim in the clean RC. |
| Long-running performance | Deferred | No soak-test claim. |
| Non-primary grid modes | Deferred | F7 verifies the primary grid path only. |
| Future game compatibility | Known limitation | Compatibility remains bounded by the current supported game/loader metadata. |
| Configuration UI | Known limitation | No configuration UI is planned by F26. |
| Template old-area pre-placement | Fixed primary path pending cleanup smoke | Do not list as a continuing limitation unless the clean RC smoke regresses. |

## 10. RC Gate Status

| Category | Gate |
|---|---|
| Closed gate | F6, F7, F9, F11, F12, F14, F17, F20, F25 targeted gates; space cap `200`; group movement across old boundary |
| Open before clean integration | Approval of this F26 plan for implementation |
| Open before RC | Cleanup implementation; clean artifact; clean install/startup smoke; post-cleanup targeted smoke; results documentation |
| Known environment baseline | `res://mods-unpacked/` warning; `ad_prompt.gd` parse error; renderer shutdown messages after completed test |
| Deferred | Large-save/long-run performance; exhaustive all-edge resize matrix; non-primary grid modes; connector custom-point verification |

## 11. Stop Conditions for Future Cleanup Implementation

Stop immediately and do not produce an RC if cleanup causes or requires any of
the following:

- A proven functional correction is removed or its timing/domain changes.
- Extension registration, manifest version, or loader compatibility changes
  unexpectedly.
- The artifact contains forbidden files, an unexpected root, or more than the
  intended clean Mod payload.
- Clean install fails or a fatal loader error appears.
- Click/drag alignment, single-node persistence, group persistence, group
  movement, group resize jump, group width correction, selection/deselection,
  node limit, or space cap regresses.
- Template pre-placement returns to the old-bound candidate, connector ownership
  correction fails, or unrelated windows/connectors move.
- A large vanilla body copy, save-schema change, or
  `WindowContainer.get_position_snapped()` patch becomes necessary.

## 12. Stop Conditions

The stop conditions in section 11 apply to every future cleanup implementation,
clean artifact, and post-cleanup test. They remain in force until an RC decision
is separately recorded.

## 13. Updated Files and Git Topology

F26 branch: `dev/phase-2c-f26-diagnostic-cleanup-clean-integration-plan`.
It is created from clean F25 result head `4c6ef67`.

The only F26 documentation changes are this plan and `docs/HANDOFF.md`. A
docs-only commit may use:

```text
docs: plan diagnostic cleanup and clean integration
```

No remote action is part of F26.

## 14. Git State

F26 changes documentation only. Its planned commit must contain only:

- `docs/PHASE_2C_F26_DIAGNOSTIC_CLEANUP_CLEAN_INTEGRATION_PLAN.md`
- `docs/HANDOFF.md`

Before committing, verify the intended branch, the two-file diff, and a clean
whitespace check. After committing, verify a clean working tree. Do not stage
runtime sources, `dist/`, logs, game files, or `vanilla-reference/`.

## 15. Explicit Non-Actions

F26 performs no runtime-code change, diagnostic cleanup implementation, clean
integration implementation, manifest version bump, artifact generation, build,
runtime test, push, merge, tag, GitHub Release, Workshop publication, history
rewrite, or force push.

## 16. Next Recommended Action

Request approval for exactly one next step: implement the diagnostic cleanup and
clean integration plan on a dedicated local branch. That approval must still
exclude RC artifact creation, runtime testing, push, merge, tag, Release, and
Workshop publication unless separately expanded.

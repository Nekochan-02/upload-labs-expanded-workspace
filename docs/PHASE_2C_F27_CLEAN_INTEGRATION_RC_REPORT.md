# Phase 2C-F27: Clean Integration RC Report

Status: `F27_CLEAN_RC_SMOKE_BLOCKED`

F27 removes diagnostic-heavy canary reporting and integrates the verified
runtime corrections into the local `0.2.28` clean RC candidate. Static source
and artifact verification passed. The user then started the clean RC smoke and
identified a new expanded-area range-selection blocker. No runtime test or full
regression was run by Codex.

## 1. Result

`F27_CLEAN_RC_SMOKE_BLOCKED`

The local clean RC artifact was supplied for user smoke testing, but it is not
release-ready. In the old area, shift + drag range selection passes. In the
expanded area, the same operation fails to select the intended range.

Classification: `EXPANDED_AREA_RANGE_SELECTION_NOT_WORKING`.

This is non-fatal but blocks the RC by default because it affects a core
multi-node workflow. Public push, tag, Release, and Workshop publication remain
blocked until the issue is fixed and smoke-tested or explicitly accepted as a
known limitation.

## 2. Git Topology

| Item | Value |
|---|---|
| Starting commit | `ac40b89` `docs: plan diagnostic cleanup and clean integration` |
| Starting branch | `dev/phase-2c-f26-diagnostic-cleanup-clean-integration-plan` |
| F27 branch | `dev/phase-2c-f27-clean-integration-0.2.28` |
| Remote action | None |

## 3. Implementation Summary

- Updated the manifest and low-noise startup confirmation to `0.2.28`.
- Removed F6/F7/F9/F12/F13/F14/F15/F17/F21/F23/F25 checkpoint output,
  associated target-acquisition flags, one-shot telemetry, and observer-only
  code.
- Kept the F6 deferred exact-local restoration correction without its telemetry.
- Kept click local placement correction without F9 logs/timers.
- Replaced the F11 diagnostic observer with the functional
  `drag_placement_local_alignment.gd` helper. It retains only the deferred
  local assignment and `moved` notification.
- Reduced `window_group.gd` to the expanded resize clamp, old-bound movement
  correction, and right/bottom collapse correction; all resize diagnostic
  handlers and the pure F13 observer were removed.
- Kept F25 direct-child identity checks, expected pasted-window count,
  selection membership, resource ownership, endpoint validation, and connector
  translation. The correction now runs for each applicable old-bound paste,
  fails closed when a guard fails, and emits at most one concise warning per
  session without checkpoint, coordinate, resource-ID, or object-dump output.

## 4. Preserved Runtime Fixes

The implementation preserves:

- Node limit `1000` and `space` upgrade cap `200`.
- Workspace size `20000 x 20000`, visual coverage, and primary `50`-unit grid.
- Click and drag local-coordinate alignment.
- Existing-node and group movement across the old boundary.
- Exact single-node local restore and group save/load behavior.
- Group old-bound resize protection and right/top-right width-collapse
  protection.
- Template/schematic placement near the expanded camera, endpoint-owned
  connector correction, relative layout, connection/state, selection,
  deselection, manual movement, and isolation from unrelated objects.

## 5. Diagnostics Removed or Gated

| Surface | Clean RC treatment |
|---|---|
| F6/F7/F9/F12/F13/F14/F15/F17/F21/F23/F25 checkpoint logs | Removed from runtime source |
| F11 checkpoint logs and settle timer | Removed; functional deferred helper retained |
| F13 group resize observer | Removed |
| F6/F9/F11/F13/F15/F17/F21/F25 diagnostic flags and acquisitions | Removed |
| F25 object/coordinate/classification dumps | Removed; guard behavior retained |
| Startup logging | One concise `ExpandedWorkspace v0.2.28 loaded.` confirmation plus existing R4 application/failure messages |

No active `[F6]`, `[F7]`, `[F9]`, `[F11]`, `[F12]`, `[F13]`, `[F14]`,
`[F15]`, `[F16]`, `[F17]`, `[F21]`, `[F23]`, or `[F25]` runtime checkpoint
labels remain in the packaged source.

## 6. Files Changed

- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/manifest.json`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/mod_main.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/desktop.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/lines.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/windows_tab.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/window_dragger.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/drag_placement_local_alignment.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/windows/window_group.gd`
- Removed `extensions/scenes/drag_placement_diagnostic_observer.gd`
- Removed `extensions/scenes/group_resize_diagnostic_observer.gd`

## 7. Static Verification

| Check | Result |
|---|---|
| `git diff --cached --check` | PASS |
| Manifest version | PASS: `0.2.28` |
| Startup version text | PASS: `0.2.28` |
| Active canary checkpoint labels in runtime source | PASS: `0` |
| Blocked extension or `get_position_snapped` reference | PASS: `0` |
| `Desktop.paste()` override body | PASS: `6` lines; no large vanilla body copy |
| Save/schema change indicators | PASS: `0` |
| Forbidden tracked Mod paths | PASS: `0` |
| Functional F11 local correction helper | PRESENT |
| Functional F25 ownership guard and fail-closed path | PRESENT |

## 8. Artifact

| Item | Value |
|---|---|
| Version | `0.2.28` |
| Path | `dist/Nekochan-ExpandedWorkspace-0.2.28.zip` |
| Size | `13481 bytes` |
| File count | `14` |
| ZIP root | `mods-unpacked` |
| SHA-256 | `53cf75fafd712c35b13a2c116e6a6f48baf00767671dac5f50c7d1dd092172ca` |
| Manifest version inside ZIP | `0.2.28` |

## 9. Publish Safety Audit

| Audit item | Count |
|---|---|
| Vanilla-verbatim body | `0` |
| Substantial vanilla-derived body | `0` |
| Third-party copied code | `0` |
| Game binary | `0` |
| Game asset/resource | `0` |
| Save file | `0` |
| Secret | `0` |
| Forbidden ZIP file/path | `0` |
| Removed diagnostic-helper ZIP entry | `0` |
| Active canary checkpoint label in packaged GDScript | `0` |

The allowlist package contains only `manifest.json`, `mod_main.gd`, and the
fourteen intended Mod GDScript/metadata files under one `mods-unpacked` root.

## 10. Runtime Verification Status

| Test | Result |
|---|---|
| Clean install / only one mod zip active | NOT TESTED |
| Startup / expected extensions installed | NOT TESTED |
| Grid coverage 20000x20000 | NOT TESTED |
| 50-unit grid density | NOT TESTED |
| Click placement in expanded area | NOT TESTED |
| Drag placement in expanded area | NOT TESTED |
| Existing-node movement across old boundary | NOT TESTED |
| Selection/deselection | NOT TESTED |
| Single-node save/load persistence | NOT TESTED |
| Group setup resize top-right/right | NOT TESTED |
| Group save/load persistence | NOT TESTED |
| Group movement across old boundary | NOT TESTED |
| Space cap 200 | NOT TESTED |
| Node limit 1000 smoke | NOT TESTED |
| Template/schematic recall near expanded camera | NOT TESTED |
| Template relative layout preserved | NOT TESTED |
| Template connection/state preserved | NOT TESTED |
| Manual move after template paste | NOT TESTED |
| Unrelated windows/connectors untouched after template paste | NOT TESTED |
| Shift + drag range selection in old area | PASS; user smoke observation |
| Shift + drag range selection in expanded area | FAIL; user smoke observation |

## 10.1 Clean RC Smoke Blocker

The user began the `0.2.28` clean RC smoke with only the clean RC artifact
installed and found the following behavior:

| Area | Shift + drag range selection |
|---|---|
| Old workspace area | PASS |
| Expanded workspace area | FAIL |

The issue is not yet attributed to input state, selection rectangle creation,
coordinate conversion, old-bound clamping, hit-testing, result application, or
the F27 cleanup. Initial classification is `RANGE_SELECTION_UNRESOLVED`.

F28 is required as a docs-only source-analysis and diagnostic plan before any
runtime diagnostic or fix work. Do not mark the overall clean RC smoke PASS.
The approved F28 plan is recorded in
`docs/PHASE_2C_F28_RANGE_SELECTION_EXPANDED_AREA_DIAGNOSTIC_PLAN.md`; its next
possible implementation step is a separately approved, bounded `0.2.29`
diagnostic canary, not a fix.

## 11. User Test Steps

1. Install only `Nekochan-ExpandedWorkspace-0.2.28.zip` in the Mod folder.
2. Start the game and confirm the Mod loads without a fatal loader error.
3. Run the placement, movement, selection, persistence, resize, capacity, and
   template smoke checks listed in section 10.
4. For template recall, move the camera clearly beyond the old boundary before
   opening a saved template/schematic; check preview and final placement before
   manual movement.
5. Exit the game after testing and provide visual results plus game/Mod Loader
   logs. Treat `res://mods-unpacked/`, `ad_prompt.gd`, and post-completion
   renderer shutdown messages as baselines unless they become fatal or change
   attribution.

## 12. Updated Docs

- This report: `docs/PHASE_2C_F27_CLEAN_INTEGRATION_RC_REPORT.md`
- Restart point: `docs/HANDOFF.md`

## 13. Git State

F27 changes are local on `dev/phase-2c-f27-clean-integration-0.2.28` and are
ready for the requested local commit. The generated artifact remains ignored
and untracked.

## 14. Explicit Non-Actions

No runtime full regression was run by Codex. No push, public-master merge, tag,
GitHub Release, Workshop publication, history rewrite, or force push occurred.

## 15. Next Recommended Action

Approve implementation of one bounded `0.2.29` expanded-area range-selection
diagnostic canary. Do not implement a fix, publish, or continue release
integration.

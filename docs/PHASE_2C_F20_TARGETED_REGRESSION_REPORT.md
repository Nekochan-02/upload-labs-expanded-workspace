# Phase 2C-F20: Targeted Regression Report

Status: `F20_TARGETED_REGRESSION_PASS_WITH_OPEN_RC_GATES`

This report records the user-run targeted regression of the `0.2.24`
development canary. It does not authorize diagnostic cleanup, clean
integration, RC artifact generation, runtime code changes, builds, push,
merge, tag, Release, or Workshop publication.

## Test Context

| Item | Evidence |
|---|---|
| Test artifact | `Nekochan-ExpandedWorkspace-0.2.24.zip` |
| Active-mod isolation | User reported only this zip in the Mod folder. `modloader.log` records one `Nekochan-ExpandedWorkspace` entry in `mod_load_order`. |
| Fresh clean-install procedure | Not separately executed. The F20 minimum single-active-zip isolation check is supported; a future clean RC still requires its own clean-install smoke check. |
| Test completion | Game exited after the regression run. |

## Result Summary

| Area | Visual result | Log correlation | Classification |
|---|---|---|---|
| Startup / mod loading | PASS; no visible loader error | `0.2.24` loaded, all expected Script Extensions installed, and `mod_load_order` contains only this Mod | PASS |
| Grid / old-bound seam / camera | PASS | F7 records `20000 x 20000` coverage, `(1,1)` renderer scale, and 50-unit minor grid | PASS |
| Click placement | PASS, immediate and settled alignment | F9 target `(7000,10600)` reached local-to-target `(0,0)` and settled global/local `(0,0)` | PASS |
| Drag placement | PASS, immediate and settled alignment | F11 target `(7100,10950)` reached local-to-target `(0,0)` and settled global/local `(0,0)` | PASS |
| Existing-node movement | PASS, no old-bound jump and aligned after move | User visual evidence; no dedicated F20 marker exists | PASS |
| Selection / deselection | PASS | User visual evidence | PASS |
| Single-node persistence | PASS, no old-bound jump | F6 records exact-local `true` for correction and stability checks | PASS |
| Group resize top-right | PASS; no jump or width collapse | F14/F17 record the top-right branch through release with a stable rect and no collapse correction required | PASS |
| Group resize right | PASS; no jump or width collapse | Visual evidence only; current target diagnostics logged `top-right`, not standalone `right` | PASS (visual) |
| Group persistence | PASS for frame, two children, layout, membership, selectability, and connection/state | F12 G6-G11 records exact local positions, zero child relative deltas, membership true, and `connector_count=1` | PASS |
| Group movement across old boundary | PASS: frame and two children cross together, relative layout and one connection/state remain visible, group selection and empty-click deselection pass, and no old-bound jump occurs | User visual evidence; latest session confirms single-Mod load and expected extension installation. Current canary has no dedicated group-movement telemetry. | PASS |
| Node limit `1000` | PASS | User smoke result; no dedicated F20 marker exists | PASS |
| Space upgrade cap `200` | PASS: UI display, cap behavior, and purchase/upgrade flow | Latest single-Mod session logs R4 applied `(100 -> 200)` during `mod_ready`; user confirmed no stop at `100` and no error UI | PASS |

## Diagnostic Reconciliation

Relevant F20 execution evidence is in the local logs under
`C:\Users\shian\AppData\Roaming\Upload Labs\logs`:

- `modloader.log` records `Nekochan-ExpandedWorkspace-0.2.24.zip` as loaded,
  one-item Mod load order, the expected Script Extension installations, and
  the R4 cap patch applied during `mod_ready`.
- `modloader_2026-07-16_20.15.48.log` records F9 target/correction/settling
  with final local and global alignment, then the equivalent F11 sequence.
- `modloader_2026-07-16_20.08.51.log` and
  `modloader_2026-07-16_20.10.18.log` record F12 G6-G11 for `group0`: frame
  and both children restore exactly, each child has relative delta `(0,0)`,
  membership is preserved, and the frame has one connector.
- `modloader_2026-07-16_20.15.48.log` records F14/F17 top-right resize events
  through release. The selected diagnostic target had no collapse guard to
  apply and retained its stable rect.
- The subsequent space-cap smoke's latest single-Mod session records
  `Nekochan-ExpandedWorkspace-0.2.24.zip` as loaded, one-item Mod load order,
  and `Applied R4 space upgrade limit patch (100 -> 200) during mod_ready`.

`[F12][STOP] group diagnostic skipped: eligible_group_candidates=0` appears
on later starts with no eligible group. It is a bounded diagnostic-skip message,
not a failed restore. It does not contradict the G6-G11 evidence or the user
visual result, and it is not an F20 stop condition.

`res://scripts/ad_prompt.gd` also emits a parse error in every observed launch.
The Mod itself loads and all intended extensions install; no reference to
`ad_prompt` or `Ads` exists in the Mod source. This is therefore recorded as
an external/base-game script error, not an ExpandedWorkspace regression. It
must remain visible as environment baseline information for later RC review.

The same latest sessions also log `ERROR ModLoader:Path` when opening
`res://mods-unpacked/`. It repeats across launches, including the single-zip
session, while the zip itself loads, all expected extensions install, and R4
applies successfully. It is a non-fatal Mod Loader baseline path error, not an
ExpandedWorkspace load or extension failure. Record it for later environment
review, but do not classify it as an F20 Mod stop condition.

The group-movement smoke's latest session records `0.2.24` as the sole
load-order entry and installs the expected `desktop.gd` and `window_group.gd`
extensions. No group-movement diagnostic line is emitted by the current
canary, so frame movement, child following, relative layout, connection/state,
and selection results are visual evidence. `[F12][STOP]` in that startup is a
save/load diagnostic skip with no eligible restored group; this smoke did not
perform save, restart, or load and the line does not assess movement.

## Stop-Condition Assessment

No F20 stop condition was observed for the Mod under test:

- Game and Mod loaded successfully.
- No Mod Loader or Script Extension installation failure occurred.
- Selection, placement, movement, single-node persistence, group persistence,
  and observed resize paths passed.
- No old-bound jump, width collapse, layout break, connection/state loss,
  node-limit regression, or suspected save corruption was reported.

The template/schematic behavior below is excluded from this conclusion because
F20 classifies it as a known limitation rather than a stop condition.

## Known Limitation Observed

When the camera is in the expanded area, a previously saved template/schematic
is pre-placed at the old-area boundary instead of at the camera position.
Vanilla pre-placement follows the camera. This is a confirmed known limitation
of the expanded-area template/schematic path. It does not block F20, and no
paste/schematic runtime change is authorized by this report.

## F21 Scope Update

The template/schematic behavior is now the active post-F20 QoL decision:
pre-placement appears near the old workspace instead of the camera when the
camera is in the expanded area. F21 static analysis identifies the old `10000`
clamp in vanilla `Desktop.paste()` as the leading candidate. Diagnostic cleanup
and clean-integration planning are deferred behind the bounded template
pre-placement diagnostic decision. See
`docs/PHASE_2C_F21_TEMPLATE_PREPLACEMENT_OLD_AREA_DIAGNOSTIC_PLAN.md`.

## Open RC Gates and Unexecuted Scope

| Item | Status |
|---|---|
| Space upgrade cap `200` UI/purchase smoke | PASS; no `100` cap stop observed |
| Group movement across old boundary | PASS; no old-bound clamp/jump or group desynchronization observed |
| Fresh clean-install smoke on a future clean RC artifact | Required before RC; not applicable to diagnostic `0.2.24` |
| Connector-point movement smoke | Optional; not reported |
| All-edge and post-load group-resize matrix | Deferred |
| Template/schematic paste in expanded area | Confirmed known limitation |

## Next Action

Record and commit the docs-only group-movement smoke result.

## Explicit Non-Actions

This report did not execute tests, change runtime code, clean diagnostics,
perform clean integration, generate an artifact, build, push, merge, tag,
create a Release, or publish to Workshop.

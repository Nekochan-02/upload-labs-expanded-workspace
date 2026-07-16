# Phase 2C-F21: Template Pre-placement Old-Area QoL Diagnostic Plan

Status: `F21_TEMPLATE_PREPLACEMENT_DIAGNOSTIC_CANARY_READY_FOR_USER_TEST`

Implementation authorization: the user approved the bounded `0.2.25`
diagnostic canary after this plan's F21 docs-only commit. The authorization is
limited to observation around `Desktop.paste()`, one template placement
sequence, and T1-T8 checkpoints. It does not authorize a placement fix.

Implementation record: `0.2.25` was packaged as a development diagnostic
artifact. Runtime verification remains pending and classification remains
`UNRESOLVED`.

This plan was docs-only until the user separately approved the bounded `0.2.25`
diagnostic implementation. That approval authorizes observation-only runtime
code and a local development artifact, but not a fix, runtime test, diagnostic
cleanup, clean integration, version changes, push, merge, tag, Release,
Workshop publication, or history rewrite.

## Purpose

Identify why recalling a saved template/schematic while the camera is in the
expanded area places its pre-placement location near the old workspace rather
than near the camera. Classification remains `UNRESOLVED` until a bounded
runtime diagnostic observes the placement sequence.

## User Observation and Impact

| Expected vanilla behavior | Actual mod behavior |
|---|---|
| Recall appears near the current camera position. | With the camera beyond the old `10000` boundary, pre-placement appears in the old area. |

Classification: `TEMPLATE_PREPLACEMENT_OLD_AREA_QOL_ISSUE`.

This is non-fatal and has no save-corruption evidence, but it is highly visible
in the normal expanded-workspace template workflow.

## Git Topology

| Item | Value |
|---|---|
| F21 base HEAD | `5db170b9466c97d7e9fe140875584fe9dea4ae01` |
| F21 branch | `dev/phase-2c-f21-template-preplacement-old-area` |
| `origin/master` | `0489e834bb1eff79742081f32656ee43f04a2cb5` |
| Local history ahead at planning start | 45 commits |
| Forbidden history operations | reset, rebase, amend, history rewrite, force push, public-master merge |

## Static Source Analysis Findings

### Confirmed Path

1. `schematics_tab.gd::_on_add_pressed()` emits
   `Signals.place_schematic(cur_schematic)`.
2. `Desktop._on_place_schematic()` calls
   `paste(Data.schematics[schematic].duplicate(true))`.
3. `Desktop.paste()` calculates an anchor, offsets every template window,
   instantiates the windows, and applies the same anchor delta to connector
   custom points.

| Finding | Evidence | Consequence |
|---|---|---|
| Camera source is used | `vanilla-reference/scripts/desktop.gd:194` uses `Globals.camera_center`; `camera_2d.gd:75` updates it from camera screen center. | The path is not primarily using a fixed desktop center. |
| Old-area clamp remains | `desktop.gd:195` clamps against `Vector2(10000, 10000) - data.rect.size`. | A target beyond the old workspace is forced back to the old-area maximum. |
| Template positions are rebased | `copy()` saves `rect`; `paste()` offsets each window by `clamped_pos - data.rect.position` at line 210. | Saved absolute positions alone are less likely to be the primary cause. |
| Connectors share the anchor | Lines 225-226 apply the same delta to custom points. | A bad anchor can affect windows and connector points together. |
| Mod preserves vanilla anchor math | `extensions/scripts/desktop.gd:40-54` only adjusts node-count gating and calls `super.paste(data)`. | F20 node-limit support does not replace placement coordinates. |
| Mod schematics UI preserves placement path | `extensions/scripts/schematics_tab.gd` changes capacity UI only. | It does not choose a placement coordinate. |
| `screen_to_world_pos` is not on the paste path | It is used by drag placement, not schematic `paste()`. | It is a comparison value only if a preview path later requires it. |

Static conclusion: `TEMPLATE_CAMERA_SOURCE_OLD_BOUND_CLAMPED` is the leading
candidate. This is not a fix decision; runtime evidence must establish whether
the visible pre-placement state, final placement, or both use that candidate.

## Behavior Split

| Possibility | Current status | Required diagnostic observation |
|---|---|---|
| A. Preview wrong, final manually movable | Unresolved | Record preview and final positions separately. |
| B. Preview and final both old-area anchored | Strongly plausible | Compare both against the old clamp candidate. |
| C. Saved absolute positions not rebased | Less likely | Log template rect, anchor, and per-window offset. |
| D. Camera center used but old-clamped | Strong static candidate | Compare raw target with old and expanded candidates. |
| E. Camera center never used | Contradicted statically | Log runtime camera state to guard lifecycle divergence. |
| F. Only multi-node templates affected | Unresolved | First run uses two nodes. |
| G. Single-node template also affected | Unresolved | Optional follow-up only. |
| H. Group and ordinary templates differ | Unresolved | Group-containing template is optional follow-up only. |

## Diagnostic Classification Framework

The future diagnostic must select one primary result or `UNRESOLVED`:

| Classification | Evidence |
|---|---|
| `TEMPLATE_CAMERA_SOURCE_NOT_USED` | Raw target is not derived from the recorded camera state. |
| `TEMPLATE_CAMERA_SOURCE_OLD_BOUND_CLAMPED` | Raw target is camera-centered and visible/final position matches old clamp. |
| `TEMPLATE_SAVED_ABSOLUTE_POSITION_NOT_REBASED` | Offset does not apply the expected rect rebase. |
| `TEMPLATE_PREVIEW_ONLY_OLD_BOUND` | Preview is old-area anchored but final reaches expanded target. |
| `TEMPLATE_FINAL_PLACEMENT_OLD_BOUND` | Final placement remains at old-bound candidate. |
| `TEMPLATE_MULTI_NODE_OFFSET_MISCOMPUTED` | Per-node offsets differ within one multi-node template. |
| `TEMPLATE_GROUP_OFFSET_MISCOMPUTED` | Group frame/children use a different anchor delta. |
| `TEMPLATE_SCREEN_TO_WORLD_DOMAIN_MISMATCH` | Preview input path proves a bad screen/world conversion. |
| `UNRESOLVED` | Evidence does not isolate one branch. |

## Future Diagnostic Proposal

If separately approved, create a bounded `0.2.25` diagnostic artifact named
`Nekochan-ExpandedWorkspace-0.2.25.zip`. F21 neither implements nor builds it.

The touchpoint is the template/schematic `Desktop.paste()` path. It must
preserve vanilla behavior, log one placement sequence only, avoid every-frame
logging, and avoid a continuous monitor.

| Checkpoint | Values to capture |
|---|---|
| T1 `CAMERA_STATE` | `Globals.camera_center`, camera global/screen center if available, viewport visible rect, zoom. |
| T2 `TEMPLATE_DATA_BOUNDS` | Template name if available, window count, saved rect, group presence. |
| T3 `PREPLACEMENT_TARGET_RAW` | Camera-centered target before clamp. |
| T4 `PREPLACEMENT_TARGET_CLAMPED_OLD` | Candidate clamped to old `10000` workspace. |
| T5 `PREPLACEMENT_TARGET_CLAMPED_EXPANDED` | Candidate clamped to `WorkspaceAreaConfig`. |
| T6 `PREVIEW_INSTANCE_POSITION` | First visible preview/selected instance, if a separate preview exists. |
| T7 `FINAL_PLACEMENT_POSITION` | First and optional second instance after placement settles. |
| T8 `OFFSET_FROM_CAMERA` | Raw, clamp, preview, and final deltas from camera center. |

The diagnostic must mark whether the old-bound candidate was selected. It must
not modify template, group, connector, selection, or save data beyond vanilla
placement.

## Minimal User Test Proposal

1. Install only the approved diagnostic artifact.
2. Move camera clearly beyond the old `10000` boundary.
3. Invoke one saved template containing two ordinary nodes.
4. Do not manually move pre-placement before observing it.
5. Record location relative to camera and old boundary.
6. Confirm whether final placement remains old-area anchored.
7. Exit without saving when placement is wrong.
8. Collect game and Mod Loader logs.

Optional follow-ups after the first classification: single-node template,
group-containing template, and a template with one connection.

## RC Impact and Recommendation

Initial stance: `Targeted QoL fix before clean RC`, unless diagnosis shows that
the correction would be invasive or high risk. Do not mark a clean RC ready
until the issue is fixed and smoke-tested or the user explicitly accepts it as
a documented known limitation.

## Scope Deferral

Diagnostic cleanup and clean-integration planning become future F22 work. They
are deferred behind the F21 template pre-placement decision.

## Explicit Non-Actions

F21 implements no pre-placement fix and performs no runtime test, diagnostic
cleanup, clean integration, push, merge, tag, Release, Workshop publication,
rebase, amend, reset, or force push. The only runtime change is the separately
approved observation-only `0.2.25` diagnostic; its local artifact was built.

## Next Recommended Action

Request approval to implement a `0.2.25` template pre-placement diagnostic
artifact, limited to one placement sequence and T1-T8 checkpoints.

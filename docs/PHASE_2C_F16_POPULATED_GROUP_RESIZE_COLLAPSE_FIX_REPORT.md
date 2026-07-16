# Phase 2C-F16: Populated Group Resize Width-Collapse Fix Canary Report

## Status

`F16_TARGET_EDGE_MISMATCH_NOT_VERIFIED`

F16 is a development canary, not a release candidate. Do not publish, tag,
push to public master, upload to Workshop, or modify v0.2.9.

## User Test Result

The user installed only `0.2.23`. A populated group using `top-right` still
collapsed in width immediately, during resize, and after release. The user also
observed the same right-side collapse on a group without contained nodes,
whereas top-left/bottom-left remained normal. Children and connection/state
remained. No save was made and the game was exited.

## Runtime Evidence

Source: `C:\Users\shian\AppData\Roaming\Upload Labs\logs\godot.log` and
`modloader.log`. Every `[F16]` checkpoint targets `group16` with `edge=top-left`:

| Checkpoint | Measured state |
|---|---|
| `F16_BEFORE_CORRECTION` | left/top flags true; old and expanded candidates `(1020,819)`; actual size/minimum `(1020,819)`; both guards false; correction false. |
| `F16_CORRECTION_DECISION` | Same valid top-left values and false decision. |
| `F16_AFTER_CORRECTION` | Unchanged valid top-left size/minimum `(1020,819)`; correction false. |
| `F16_AFTER_RELEASE` | Flags clear; position `(14050,16900)`, size/minimum `(1070,769)`; correction false. |
| `F16_ONE_FRAME_AFTER_RELEASE` | Same released state with no delayed change. |

The top-left F15 checkpoint beside F16 reports the group as valid and visible;
two children remain with bounding box `(14150,17100,850,321)` and stable
relative bounds. The connector-point count is `0`, which does not disprove the
user's visual connection/state confirmation.

There is no `[F16]` line for `top-right`, `right`, `bottom-right`, or `bottom`.
Therefore the logs cannot show whether the F16 guard fired, what candidates it
saw, or whether it restored the failing path.

## Canary Verdict

`BLOCKED`

F16 did not verify the F15 top-right correction. The implementation arms F16
only when `_f15_begin_populated_resize_diagnostic()` succeeds. F15 is itself
limited to the first eligible resize sequence per session. The normal top-left
interaction consumed that target first, so the later top-right failure did not
enter the F16 correction or logging branch.

The user observation that an empty group also fails on right-side edges is
consistent with the F15 old-bound right/bottom size-calculation root cause and
shows the defect is not caused by contained children. It does not establish
that F16's correction failed on the intended path, because that path was not
observed by F16.

## Next Diagnostic Only

Prepare one F17 plan to decouple correction activation from F15's first-edge
diagnostic target and to reserve F17 logging for the intended `top-right`
sequence. The correction must remain WindowGroup-only and use the same F15
guards; do not implement it or broaden it to release/regression work yet.

## Implementation

- Version: `0.2.23`
- Target: existing `extensions/scenes/windows/window_group.gd`
- Correction: post-vanilla, resize-active, per-axis restoration only for a
  confirmed old-bound collapse with a valid expanded candidate.
- Position notification: existing `move()` path only when position differs.
- Update path: `custom_minimum_size` and `size` property setters, matching the
  vanilla resize property's update mechanism. No manual signal is guessed.
- Diagnostics: one populated group and one sequence, with five bounded F16
  checkpoints.

## Root Cause Coverage

F15's `top-right` zero-delta case made width `-3900` using the old bound and
then rendered width `20`. F16 detects that exact state after vanilla processing
and replaces only the affected axis with the valid expanded candidate. F14
continues to govern the resize position snap separately.

## Runtime Delta

Normal group movement and valid resize results delegate through the unchanged
paths. A correction is considered only while the selected group has an active
right/bottom resize and all old-bound-collapse guards pass.

## Preservation

F14/F6/F7/F9/F11/F12, save schema, child positions/membership, node limits,
and space-upgrade cap are unchanged.

## Static Audit

| Check | Result |
|---|---|
| F14 resize-only `move_snapped()` branch changed | NO |
| `get_position_snapped()` override | NO |
| WindowContainer/Base/Indexed extension | NO |
| Vanilla resize-body wholesale copy | NO |
| Child position or membership mutation | NO |
| Save schema changed | NO |
| F6/F7/F9/F11/F12 changed | NO |

## Artifact

- Build command: `tools/build_release.ps1 -Version 0.2.23`
- Filename: `Nekochan-ExpandedWorkspace-0.2.23.zip`
- Path: `dist/Nekochan-ExpandedWorkspace-0.2.23.zip`
- Size: `21846 bytes`
- File count: `15`
- ZIP root: `mods-unpacked`
- Manifest version: `0.2.23`
- SHA-256: `d124dee730ff43178f1fb5c0698cbc557312f945739b1ea310e054124fce1ebf`

## Publish Safety

| Audit item | Count |
|---|---:|
| vanilla-verbatim body | 0 |
| substantial vanilla-derived code | 0 |
| third-party copied code | 0 |
| game binary | 0 |
| game asset/resource | 0 |
| save file | 0 |
| secret | 0 |
| forbidden file/path | 0 |

The final ZIP inspection found one `mods-unpacked` root, 15 allowed files, and
no forbidden extension or path term.

## User Verification Status

| Test | Result |
|---|---|
| Top-right populated resize no width collapse | USER OBSERVED FAIL; F16 LOG NOT CAPTURED |
| `custom_minimum_size.x` non-negative | NOT OBSERVED ON TOP-RIGHT |
| Group remains valid/visible | NOT OBSERVED ON TOP-RIGHT |
| Group remains normal-shaped | USER OBSERVED FAIL |
| Children remain | USER OBSERVED PASS |
| Connection/state remain | USER OBSERVED PASS |
| Old-bound jump absent | LOG VERIFIED ONLY FOR TOP-LEFT |
| F16 correction branch used | LOG VERIFIED NO ONLY FOR TOP-LEFT |

Codex has not run the game. The intended top-right correction branch remains
unverified and must not be accepted.

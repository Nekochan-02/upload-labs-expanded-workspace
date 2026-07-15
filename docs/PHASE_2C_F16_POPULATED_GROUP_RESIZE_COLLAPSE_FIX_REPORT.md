# Phase 2C-F16: Populated Group Resize Width-Collapse Fix Canary Report

## Status

`F16_CANARY_READY_FOR_USER_TEST`

F16 is a development canary, not a release candidate. Do not publish, tag,
push to public master, upload to Workshop, or modify v0.2.9.

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
| Top-right populated resize no width collapse | NOT TESTED |
| `custom_minimum_size.x` non-negative | NOT TESTED |
| Group remains valid/visible | NOT TESTED |
| Group remains normal-shaped | NOT TESTED |
| Children remain | NOT TESTED |
| Connection/state remain | NOT TESTED |
| Old-bound jump absent | NOT TESTED |
| F16 correction branch used | NOT TESTED |

Codex has not run the game. User evidence and actual `[F16]` logs are required
before this canary can be accepted.

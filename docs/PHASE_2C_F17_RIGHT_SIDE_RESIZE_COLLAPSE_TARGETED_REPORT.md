# Phase 2C-F17: Right-Side Group Resize Collapse Targeted Canary Report

## Status

`F17_NOT_EXECUTED_ARTIFACT_MISMATCH`

F17 is a local development canary, not a release candidate. Do not publish,
tag, push to public master, upload to Workshop, or modify v0.2.9.

## Test Validity

The user correctly reported the intended F17 procedure, including no prior
top-left interaction and no save after the failure. However, the actual game
session did not load F17. `godot.log` and `modloader.log` at `18:20:44` show
`Nekochan-ExpandedWorkspace-0.2.23.zip`, F16 registration text, and
`ExpandedWorkspace v0.2.23 canary loaded`.

The live Mod folder inspection after game exit likewise contains only
`Nekochan-ExpandedWorkspace-0.2.23.zip` (21846 bytes, manifest version
`0.2.23`); there is no `0.2.24` package. Therefore this is an installation
mismatch, not an F17 runtime result.

## Runtime Evidence

There are zero `[F17]` lines in both current game and Mod Loader logs. All
required F17 checkpoints are consequently `NOT EXECUTED`:

- `F17_TARGET_EDGE_SELECTED`
- `F17_BEFORE_CORRECTION`
- `F17_CORRECTION_DECISION`
- `F17_AFTER_CORRECTION`
- `F17_AFTER_RELEASE`
- `F17_ONE_FRAME_AFTER_RELEASE`

The observed session contains F16/F13 evidence for `group17`, not F17:

- edge: `top-right`; flags: right/top true; no prior top-left F17 target can be
  evaluated because F17 was not loaded;
- pre-resize frame: position `(14750,18650)`, size/minimum `(300,200)`;
- F13 post-vanilla state: size `(20,200)`,
  `custom_minimum_size=(-4750,200)`, matching the visible width collapse;
- group remains inside tree and visible at the same position, so no old-bound
  position jump occurred in this F16 session;
- F15 reports `contained_window_count=0`; the F13 `child_count=3` is internal
  group scene structure, not evidence of two contained user nodes. Connection
  and user-node state are not testable from this session.

## Canary Verdict

`BLOCKED`

F17 is neither PASS nor FAIL because its artifact did not run. The visual
collapse confirms the pre-existing F16 path remains unsafe, but it cannot
classify F17 correction activation, target selection, or post-correction state.

## F16 Handling

F16 is not accepted. Its only bounded sequence was a valid `top-left` resize,
because F15 target acquisition consumed the first eligible resize. No F16
checkpoint covers the observed failing `top-right` or `right` paths.

## Implementation

- Target: existing `WindowGroup` Script Extension only.
- Correction activation: after vanilla resize processing on every active
  right/bottom resize. It no longer depends on F15 or F17 diagnostic selection.
- Guard: the matching old-bound candidate is below minimum or non-positive, the
  expanded-bound candidate is valid, and the actual post-vanilla size or
  minimum-size axis is collapsed.
- Correction: restore only the affected size and `custom_minimum_size` axis
  from the expanded candidate, and use the existing `move()` path only when the
  corrected position differs.
- Diagnostics: one F17 target per session, selected only by `top-right` or
  `right`; `top-left`, `left`, and `top` cannot consume it.
- Bounded checkpoints: `F17_TARGET_EDGE_SELECTED`, `F17_BEFORE_CORRECTION`,
  `F17_CORRECTION_DECISION`, `F17_AFTER_CORRECTION`, `F17_AFTER_RELEASE`, and
  `F17_ONE_FRAME_AFTER_RELEASE`.

F14's resize-only expanded-bound `move_snapped(to)` remains unchanged.

## Runtime Delta

The former F16 correction was armed only when F15's populated-group diagnostic
selected a target. F17 retains the same post-vanilla correction surface but
evaluates right/bottom guards independently. This directly addresses the F16
target-acquisition failure without copying vanilla `_process()` logic.

## Preservation

F14 old-bound snap, F6 restoration, F7 grid, F9 click placement, F11 drag
placement, F12 diagnostics, save schema, node limit, and space upgrade cap are
unchanged. No child position or membership mutation was added.

## Static Audit

| Check | Result |
|---|---|
| Top-left can consume F17 target | NO |
| Correction depends on F15/F16 target acquisition | NO |
| Right/top-right correction can evaluate independently | YES |
| Valid resize mutation | NO: actual collapse guard required |
| `get_position_snapped()` override | NO |
| WindowContainer/Base/Indexed extension | NO |
| Large vanilla body copy | NO |
| Child or save-schema mutation | NO |
| F14 resize snap removed | NO |

## Artifact

- Version: `0.2.24`
- Filename: `Nekochan-ExpandedWorkspace-0.2.24.zip`
- Path: `dist/Nekochan-ExpandedWorkspace-0.2.24.zip`
- Size: `22115` bytes
- File count: `15`
- ZIP root: `mods-unpacked`
- Manifest version: `0.2.24`
- SHA-256: `942f67e0e0535b208a6ecc67d1d13cd9baf714035a8471dcdad55926373e7e7c`
- Status: generated locally; development-only.

## Publish Safety

The repository build allowlist and the resulting ZIP inspection both passed.

| Category | Count |
|---|---:|
| Vanilla-verbatim body | 0 |
| Substantial vanilla-derived code | 0 |
| Third-party copied code | 0 |
| Game binary | 0 |
| Game asset/resource | 0 |
| Save file | 0 |
| Secret | 0 |
| Forbidden file/path | 0 |

## User Verification Status

| Test | Result |
|---|---|
| Top-right target captured | NOT EXECUTED: F17 not loaded |
| Top-left did not consume target | NOT EXECUTED: F17 not loaded |
| Correction branch evaluated on right/top-right | NOT EXECUTED: F17 not loaded |
| Width does not collapse to 20 | NOT EXECUTED: F17 not loaded; F16 visual/log result collapsed to 20 |
| `custom_minimum_size.x` non-negative | NOT EXECUTED: F17 not loaded; F16 logged `-4750` |
| Group remains valid/visible | NOT EXECUTED: F17 not loaded; F16 logged true/true |
| Children remain | NOT EXECUTED: F17 not loaded |
| Connection/state remain | NOT EXECUTED: F17 not loaded |
| Old-bound jump absent | NOT EXECUTED: F17 not loaded; F16 position did not jump |

Codex has not run the game and does not assign runtime PASS status.

## User Test Steps

1. Before launch, confirm the live Mod folder contains only
   `Nekochan-ExpandedWorkspace-0.2.24.zip`; remove the `0.2.23` package.
2. Move to the expanded area and create a group beyond the old `10000` boundary.
3. Place exactly two nodes inside and add one connection if convenient.
4. Do not touch top-left. Use `top-right` first with little or zero mouse delta.
5. Drag slightly, release, and confirm the frame remains normal-shaped.
6. Confirm children plus connection/state remain. Do not save after failure.
7. Exit the game and provide the `[F17]` logs.

## Deferred Work

Do not resume F12 group persistence, full regression, release integration,
public master push, Release/tag/Workshop actions, or v0.2.9 artifact work.

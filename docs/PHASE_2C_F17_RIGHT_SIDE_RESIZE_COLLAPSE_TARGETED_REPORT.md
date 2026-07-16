# Phase 2C-F17: Right-Side Group Resize Collapse Targeted Canary Report

## Status

`F17_CANARY_READY_FOR_USER_TEST`

F17 is a local development canary, not a release candidate. Do not publish,
tag, push to public master, upload to Workshop, or modify v0.2.9.

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
| Top-right target captured | NOT TESTED |
| Top-left did not consume target | NOT TESTED |
| Correction branch evaluated on right/top-right | NOT TESTED |
| Width does not collapse to 20 | NOT TESTED |
| `custom_minimum_size.x` non-negative | NOT TESTED |
| Group remains valid/visible | NOT TESTED |
| Children remain | NOT TESTED |
| Connection/state remain | NOT TESTED |
| Old-bound jump absent | NOT TESTED |

Codex has not run the game and does not assign runtime PASS status.

## User Test Steps

1. Install only `Nekochan-ExpandedWorkspace-0.2.24.zip`.
2. Move to the expanded area and create a group beyond the old `10000` boundary.
3. Place exactly two nodes inside and add one connection if convenient.
4. Do not touch top-left. Use `top-right` first with little or zero mouse delta.
5. Drag slightly, release, and confirm the frame remains normal-shaped.
6. Confirm children plus connection/state remain. Do not save after failure.
7. Exit the game and provide the `[F17]` logs.

## Deferred Work

Do not resume F12 group persistence, full regression, release integration,
public master push, Release/tag/Workshop actions, or v0.2.9 artifact work.

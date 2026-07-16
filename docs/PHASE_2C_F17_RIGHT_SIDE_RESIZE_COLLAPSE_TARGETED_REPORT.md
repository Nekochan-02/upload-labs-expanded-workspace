# Phase 2C-F17: Right-Side Group Resize Collapse Targeted Canary Report

## Status

`F17_TOP_RIGHT_WIDTH_COLLAPSE_VERIFIED`

F17 is a local development canary, not a release candidate. Do not publish,
tag, push to public master, upload to Workshop, or modify v0.2.9.

## Test Validity

The first reported attempt was invalid because it loaded `0.2.23`; that
artifact mismatch remains recorded as a separate failed setup attempt.

The subsequent completed session is valid F17 evidence. `godot.log` and
`modloader.log` at `18:31:09` load
`Nekochan-ExpandedWorkspace-0.2.24.zip`, register F17, and report
`ExpandedWorkspace v0.2.24 canary loaded`. The user performed `top-right`
first, did not touch top-left, did not save, and exited.

## Runtime Evidence

All required `[F17]` checkpoints occur once for `group18` with
`edge=top-right`:

| Checkpoint | Measured state |
|---|---|
| `F17_TARGET_EDGE_SELECTED` | `diagnostic_target_selected=true`; initial position `(15250,18350)`, size/minimum `(300,200)`. |
| `F17_BEFORE_CORRECTION` | right/top flags true; branch evaluated true; old candidate `(-5250,200)`; expanded candidate `(300,200)`; vanilla transient size/minimum `(20,200)` / `(-5250,200)`; width guard true. |
| `F17_CORRECTION_DECISION` | correction applied true; size/minimum restored to `(300,200)` / `(300,200)`. |
| `F17_AFTER_CORRECTION` | same corrected `(300,200)` size/minimum in the same active resize sequence. |
| `F17_AFTER_RELEASE` | position `(15250,18200)`, size/minimum `(700,350)` / `(700,350)`; correction remains true. |
| `F17_ONE_FRAME_AFTER_RELEASE` | identical release geometry; no deferred collapse. |

The transient `20/-5250` state is the expected vanilla failure checkpoint. It
does not persist to the post-correction frame, release, or one-frame stability
checkpoint, which matches the user's normal visual result.

F13/F14 lifecycle logs confirm the group remains valid, inside the tree, and
visible at the corrected first frame and after release. The frame stays beyond
the old boundary: `(15250,18350)` before correction and `(15250,18200)` after
release; the y change is the intentional top-edge resize, not an old-bound
jump.

After the primary target, the user placed two nodes and performed the populated
top-right resize. F15 then records two valid contained nodes, stable global
positions, and release geometry `(13650,18050)` with size/minimum `(1000,700)`
after an intermediate vanilla `20/-3650` state. The child relative y values
change only because the top edge moves by 50. F15's connector count is `0`, so
runtime logs do not independently prove the connection; the user's visual
result confirms connection/state remained.

## Canary Verdict

`F17_TOP_RIGHT_WIDTH_COLLAPSE_VERIFIED`

The F17 primary top-right canary passes. It directly captures and corrects the
known old-bound width collapse in the same resize frame, preserving a visible,
valid frame through release. This does not verify the separate secondary
`right` path, group persistence, full regression, or release readiness.

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
| Top-right target captured | PASS: `group18`, `edge=top-right` |
| Top-left did not consume target | PASS: top-right is the sole F17 target; user did not touch top-left |
| Correction branch evaluated on right/top-right | PASS: `correction_branch_evaluated=true`, `width_guard=true` |
| Width does not collapse to 20 | PASS after correction: transient vanilla `20` restored to `300`, then `700` at release |
| `custom_minimum_size.x` non-negative | PASS after correction: `-5250` restored to `300`, then `700` at release |
| Group remains valid/visible | PASS: F13/F14 lifecycle logs confirm valid/in-tree/visible |
| Children remain | PASS: user visual result; F15 records two valid child nodes after population |
| Connection/state remain | USER PASS; F15 connector count is `0`, so runtime evidence is inconclusive |
| Old-bound jump absent | PASS: corrected/released frame remains beyond old boundary |

Codex has not run the game and does not assign runtime PASS status.

## User Test Steps

1. In a fresh `0.2.24` session, create a childless group beyond the old boundary.
2. Do not touch top-left or top-right. Use `right` first with little or zero
   mouse delta, then drag slightly and release.
3. Do not save after failure. Exit and provide `[F17]` logs.

## Deferred Work

Do not resume F12 group persistence, full regression, release integration,
public master push, Release/tag/Workshop actions, or v0.2.9 artifact work.

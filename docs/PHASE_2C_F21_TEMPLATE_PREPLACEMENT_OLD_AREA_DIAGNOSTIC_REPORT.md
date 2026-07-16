# Phase 2C-F21: Template Pre-placement Old-Area Diagnostic Report

Status: `TEMPLATE_CAMERA_SOURCE_OLD_BOUND_CLAMPED_CONFIRMED`

The `0.2.25` development diagnostic artifact observes one template/schematic
placement sequence. It does not implement a pre-placement or final-placement
fix. The valid `0.2.25` retest captured T1-T8 and confirms that the
camera-derived target is clamped through the old `10000` workspace maximum.

## Runtime Evidence Matrix

| Test | Result |
|---|---|
| Template recall in expanded area | PASS; valid `0.2.25` F21 sequence captured |
| Camera state captured | PASS; `(12074.19, 15876.0)` |
| Template data bounds captured | PASS; `18` windows, `1` group, rect `(3700, 5450)` / `(3250, 1050)` |
| Raw target from camera captured | PASS; `(10449.19, 15351.0)` |
| Old-bound candidate differs from raw target | PASS; `(6750, 8950)`, detection `true` |
| Expanded-bound candidate preserves camera-area target | PASS; `(10449.19, 15351.0)` |
| Preview/pre-placement appears near old area | PASS; first observed local `(6750, 8950)` |
| Final placement old-area anchored | PASS; unchanged at `(6750, 8950)` |
| Classification | `TEMPLATE_CAMERA_SOURCE_OLD_BOUND_CLAMPED` |

## Attempt 1: Artifact Mismatch Evidence

The user observed both pre-placement and immediate final placement near the
old area, while the camera was in the expanded area. The two-node relative
layout and connection/state remained intact and no visible error was reported.
The supplied screenshots corroborate that visual result, but they cannot
provide the requested world-coordinate measurements.

The actual current-session logs prove that the F21 artifact was not installed:

| Evidence | Measured result |
|---|---|
| Loaded ZIP | `Nekochan-ExpandedWorkspace-0.2.24.zip` |
| Loaded runtime banner | `ExpandedWorkspace v0.2.24 canary loaded` |
| F21/TEMPLATE markers in current and dated game/Mod Loader logs | `0` |
| Expected F21 `0.2.25` ZIP inspection | Manifest is `0.2.25`; `desktop.gd` contains the T1-T8 logging hooks |
| T1 camera center / state | NOT CAPTURED |
| T2 saved template local bounds | NOT CAPTURED |
| T3 raw target from camera | NOT CAPTURED |
| T4 old-bound candidate / detection | NOT CAPTURED |
| T5 expanded-bound candidate | NOT CAPTURED |
| T6 preview/pre-placement position | NOT CAPTURED |
| T7 final placement position | NOT CAPTURED |
| T8 delta from camera center | NOT CAPTURED |

`[F12][STOP] group diagnostic skipped: eligible_group_candidates=0` is a
save/load diagnostic skip and unrelated to this template recall. The recurring
`res://mods-unpacked/` path error and `ad_prompt.gd` parse error remain the
known non-fatal environment/game baselines; neither carries an F21 marker nor
establishes an ExpandedWorkspace stop condition for this attempt.

## Attempt 2: Valid F21 Measurement

The retest correctly loaded only `Nekochan-ExpandedWorkspace-0.2.25.zip` and
emitted all T1-T8 checkpoints. The reported visual result is corroborated by
the local position of the first recalled group window. The data records `18`
windows and `1` group window, rather than the intended two ordinary-node
minimal shape; this does not alter the anchor-clamp result because the
observed group frame exactly matches the old-bound candidate.

| Checkpoint | Actual measurement |
|---|---|
| T1 camera center | `(12074.19, 15876.0)`; global matches; zoom `(0.101404, 0.101404)` |
| T2 saved local bounds | rect position `(3700.0, 5450.0)`, size `(3250.0, 1050.0)`, `18` windows, `1` group |
| T3 raw target from camera | `(10449.19, 15351.0)` |
| T4 old-bound candidate | old max and old-clamped `(6750.0, 8950.0)`; detection `true` |
| T5 expanded-bound candidate | expanded max `(16750.0, 18950.0)`; expanded-clamped `(10449.19, 15351.0)` |
| T6 immediate observation | first group local `(6750.0, 8950.0)`; equal to old candidate |
| T7 deferred final observation | first group local remains `(6750.0, 8950.0)`; equal to old candidate |
| T8 raw/expanded delta from camera | `(-1625.0, -525.0)` |
| T8 old candidate and observed local delta | `(-5324.192, -6926.005)` |

The raw target is derived from the recorded camera center by subtracting half
the template size. It is within the expanded workspace but exceeds the old
maximum. Both immediate and deferred observed positions equal the old-clamped
candidate, which rules out a preview-only distinction for this sequence.

## Diagnostic Scope

The canary records T1-T8 once for the first `Desktop.paste()` sequence:
camera state, template bounds, raw target, old and expanded clamp candidates,
immediate post-paste observation, one deferred final observation, and camera
deltas. It does not adjust any target, preview, final placement, connector,
selection, group, or save value.

## User Test

1. Install only `Nekochan-ExpandedWorkspace-0.2.25.zip`.
2. Start the game.
3. Move the camera clearly beyond the old `10000` boundary.
4. Recall one saved template/schematic containing two ordinary nodes.
5. Do not manually move the pre-placement before observing it.
6. Observe where the pre-placement appears.
7. If safe, confirm whether final placement remains old-area anchored.
8. Do not save if placement is wrong.
9. Exit the game.
10. Collect and provide `[F21]` / `[TEMPLATE]` log lines.

## Artifact

| Item | Value |
|---|---|
| Version | `0.2.25` development diagnostic |
| Path | `dist/Nekochan-ExpandedWorkspace-0.2.25.zip` |
| Size | `23577 bytes` |
| File count | `15` |
| ZIP root | `mods-unpacked` |
| SHA-256 | `b9363ac35b96d8df0645eec1e620328e9ce9296e266298e4ebe482307f7e5c2f` |

## Static Audit

| Check | Result |
|---|---|
| Template placement behavior changed | NO |
| `Desktop.paste()` behavior changed | NO; observation wraps the existing call only |
| Preview/final placement mutation | NO |
| F6/F7/F9/F11/F12/F14/F17 changed | NO |
| Save schema changed | NO |
| Diagnostic cleanup performed | NO |
| Clean integration performed | NO |
| Large vanilla body copy | NO |

## Publish Safety

| Check | Count |
|---|---|
| Vanilla-verbatim body | 0 |
| Substantial vanilla-derived code | 0 |
| Third-party copied code | 0 |
| Game binary | 0 |
| Game asset/resource | 0 |
| Save file | 0 |
| Secret | 0 |
| Forbidden file/path in ZIP | 0 |

## Classification

Result: `TEMPLATE_CAMERA_SOURCE_OLD_BOUND_CLAMPED`.

The camera source is used, but the inherited old `10000` clamp selects
`(6750.0, 8950.0)` instead of the expanded-area camera target. The final
placement remains at that same old-bound candidate. This is a QoL defect, not
an ExpandedWorkspace crash, save-corruption, or regression stop condition.

## Explicit Non-Actions

No fix, cleanup, clean integration, artifact regeneration, push, merge, tag,
Release, or Workshop publication has been performed.

# Phase 2C-F21: Template Pre-placement Old-Area Diagnostic Report

Status: `F21_DIAGNOSTIC_CANARY_READY_FOR_USER_TEST`

The `0.2.25` development diagnostic artifact observes one template/schematic
placement sequence. It does not implement a pre-placement or final-placement
fix. All runtime conclusions remain `NOT TESTED` until user verification.

## Runtime Evidence Matrix

| Test | Result |
|---|---|
| Template recall in expanded area | NOT TESTED |
| Camera state captured | NOT TESTED |
| Template data bounds captured | NOT TESTED |
| Raw target from camera captured | NOT TESTED |
| Old-bound candidate differs from raw target | NOT TESTED |
| Expanded-bound candidate preserves camera-area target | NOT TESTED |
| Preview/pre-placement appears near old area | NOT TESTED |
| Final placement old-area anchored | NOT TESTED |
| Classification | NOT TESTED |

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

Initial classification: `UNRESOLVED`.

## Explicit Non-Actions

No fix, cleanup, clean integration, runtime test, push, merge, tag, Release,
or Workshop publication has been performed.

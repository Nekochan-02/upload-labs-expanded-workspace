# Phase 2C-F23: Template Pre-placement Fix Canary Report

Status: `F23_TEMPLATE_PREPLACEMENT_FIX_CANARY_READY_FOR_USER_TEST`

The `0.2.26` local development canary implements the F22-approved Candidate A
only: a one-sequence, guarded post-super correction for the F21-confirmed old
workspace clamp. It is not a release candidate and user verification is
required before any cleanup or integration decision.

## Runtime Evidence Matrix

| Test | Result |
|---|---|
| Template recall in expanded area appears near camera | NOT TESTED |
| Preview/pre-placement not old-bound clamped | NOT TESTED |
| Final placement not old-bound clamped | NOT TESTED |
| Relative layout preserved | NOT TESTED |
| Connection/state preserved | NOT TESTED |
| Selection/deselection preserved | NOT TESTED |
| Manual move after paste works | NOT TESTED |
| Correction applied safely | NOT TESTED |
| Unrelated windows untouched | NOT TESTED |

## Implementation

`extensions/scripts/desktop.gd` now wraps the existing node-limit-aware
`super.paste(data)` call with one F23 transaction. It snapshots direct-child
window and connector instance IDs, computes raw/old/expanded candidates, and
does nothing unless every guard passes. The correction writes one local
`position += correction_delta` to each newly pasted window, emits `moved`,
then translates only newly created connectors' custom points and calls
`update_points()`.

Required guards are: valid rect; old clamp; distinct expanded candidate;
finite, non-zero delta; exact expected/actual new window and connector counts;
valid direct-child ownership; and exact vanilla post-paste selection
membership. Any failure logs `SKIP`/`STOP` and moves nothing.

The one-shot F23 sequence logs `F23_PASTE_TARGETS`,
`F23_PASTE_SET_IDENTIFICATION`, `F23_CORRECTION_DECISION`,
`F23_BEFORE_CORRECTION`, `F23_AFTER_CORRECTION`,
`F23_RELATIVE_LAYOUT_CHECK`, `F23_SELECTION_CHECK`,
`F23_CONNECTOR_CHECK`, and deferred `F23_FINAL_STABILITY`.

## Static Audit

| Check | Result |
|---|---|
| Vanilla `Desktop.paste()` wholesale copy | NO |
| Large vanilla-derived body added | NO |
| Template data mutation added | NO |
| Save schema change | NO |
| Unrelated window movement | Guarded / NO intended path |
| `WindowContainer` / Base / Indexed extension added | NO |
| `get_position_snapped` override added | NO |
| F6/F7/F9/F11/F12/F14/F17 implementation changed | NO |
| Group-resize implementation changed | NO |
| Node-limit / space-cap behavior changed | NO |
| Every-frame or continuous monitor added | NO |

## Artifact

| Item | Value |
|---|---|
| Version | `0.2.26` local development fix canary |
| Path | `dist/Nekochan-ExpandedWorkspace-0.2.26.zip` |
| Size | `25749 bytes` |
| File count | `15` |
| ZIP root | `mods-unpacked` |
| SHA-256 | `e600976a0407b78117473f06f16265442e145b3fe0225094a369974dea733c71` |

The allowlisted packager generated this artifact from the current source. ZIP
inspection confirms manifest version `0.2.26`, one `Desktop.paste()` override,
the F23 marker, and no wholesale vanilla paste-body indicators.

## Publish Safety

The ZIP contains only the allowlisted Mod source under
`mods-unpacked/Nekochan-ExpandedWorkspace`. ZIP inspection found zero
forbidden entries. Required audit counts are zero for vanilla-verbatim code,
substantial vanilla-derived code, third-party copied code, game binary, game
asset/resource, save file, secret, and forbidden path.

## User Test

1. Install only `Nekochan-ExpandedWorkspace-0.2.26.zip`.
2. Start the game and confirm the Mod loaded.
3. Move the camera clearly beyond the old `10000` boundary.
4. Recall one saved two-node template/schematic.
5. Do not manually move it before observation.
6. Confirm immediate placement appears near the expanded-area camera target.
7. Confirm final placement remains near that target.
8. Confirm relative layout and connection/state are preserved.
9. Confirm selection/deselection, then manually move the pasted set once if
   safe.
10. Do not save after a failure. Exit the game and collect `[F23]` logs.

Optional only after primary PASS: single-node, group-containing, and
custom-connector-point templates.

## Explicit Non-Actions

No full regression, diagnostic cleanup, clean integration, release
integration, push, merge, tag, Release, or Workshop publication is part of
F23.

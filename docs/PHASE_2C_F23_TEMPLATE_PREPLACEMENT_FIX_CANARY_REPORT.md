# Phase 2C-F23: Template Pre-placement Fix Canary Report

Status: `F23_TEMPLATE_PREPLACEMENT_FIX_BLOCKED`

The `0.2.26` local development canary implements the F22-approved Candidate A
only: a one-sequence, guarded post-super correction for the F21-confirmed old
workspace clamp. The valid user test reached the F23 transaction, but its
connector-count guard failed closed. No correction was applied and no cleanup
or integration decision is authorized.

## Runtime Evidence Matrix

| Test | Result |
|---|---|
| Template recall in expanded area appears near camera | FAIL; remains near old area |
| Preview/pre-placement not old-bound clamped | FAIL; remains near old area |
| Final placement not old-bound clamped | FAIL; remains near old area |
| Relative layout preserved | PASS; no correction was applied |
| Connection/state preserved | PASS; visual evidence |
| Selection/deselection preserved | PASS; visual evidence |
| Manual move after paste works | PASS; visual evidence |
| Correction applied safely | BLOCKED; `STOP_NEW_CONNECTOR_COUNT_MISMATCH` |
| Unrelated windows untouched | PASS; correction was not applied |

## F23 Runtime Evidence

The latest game and Mod Loader logs show only
`Nekochan-ExpandedWorkspace-0.2.26.zip` loaded and the v0.2.26 F23 banner.
All required F23 labels were emitted for one sequence.

| Checkpoint | Actual result |
|---|---|
| `F23_PASTE_TARGETS` | Camera `(16708.99, 17440.3)`; raw `(15083.99, 16915.3)`; old `(6750, 8950)`; expanded `(15083.99, 16915.3)`; delta `(8333.994, 7965.299)` |
| `F23_PASTE_SET_IDENTIFICATION` | Windows expected/actual `18/18`; selection `18`, matches `true`; connectors expected/actual `29/17` |
| `F23_CORRECTION_DECISION` | `applied=false`, `STOP_NEW_CONNECTOR_COUNT_MISMATCH` |
| `F23_BEFORE_CORRECTION` | First group local `(6750, 8950)` at the old candidate |
| `F23_AFTER_CORRECTION` | Unchanged; correction not applied |
| `F23_RELATIVE_LAYOUT_CHECK` | `applied=false`, preserved `true` |
| `F23_SELECTION_CHECK` | Selection matches the pasted set: `true` |
| `F23_CONNECTOR_CHECK` | The 17 observed new connectors have zero custom points; no connector adjustment ran |
| `F23_FINAL_STABILITY` | `correction_applied=false`, stable `true`; final group remains `(6750, 8950)` |

The window identity and selection guards both passed. The blocked guard is
strict equality between the serialized connector-data entry count (`29`) and
the actual runtime connector-object count (`17`). The mismatch is not evidence
that an unrelated object was selected or moved: no correction was applied.
It instead establishes that the future connector guard must distinguish staged
serialized connector entries from connector objects actually created for the
pasted set before a correction can be safely applied.

`[F12][STOP]` remains the unrelated save/load diagnostic skip. The recurring
`res://mods-unpacked/` path error and `ad_prompt.gd` parse error remain known
non-fatal environment/game baselines.

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

## Next Recommended Action

F25 now implements the separately approved `0.2.27` endpoint-ownership
refinement canary. Its user runtime verification remains pending in
`docs/PHASE_2C_F25_TEMPLATE_CONNECTOR_OWNERSHIP_CANARY_REPORT.md`; F23 remains
the historical fail-closed blocker record.

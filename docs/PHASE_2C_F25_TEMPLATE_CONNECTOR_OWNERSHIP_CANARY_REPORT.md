# Phase 2C-F25: Template Connector Ownership Canary Report

Status: `F25_TEMPLATE_CONNECTOR_OWNERSHIP_CANARY_READY_FOR_USER_TEST`

The `0.2.27` local development canary replaces the F23 serialized connector
count equality guard with a runtime endpoint-ownership guard. User runtime
verification is required before any cleanup or integration decision.

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
| Endpoint ownership classification complete | NOT TESTED |
| Unrelated windows untouched | NOT TESTED |
| Unrelated connectors untouched | NOT TESTED |

## F24 Commit

| Item | Value |
|---|---|
| Commit | `b87837d` `docs: plan template connector guard refinement` |
| Files | `docs/PHASE_2C_F24_TEMPLATE_CONNECTOR_GUARD_REFINEMENT_PLAN.md`, `docs/PHASE_2C_F23_TEMPLATE_PREPLACEMENT_FIX_CANARY_REPORT.md`, `docs/HANDOFF.md` |

## F23 Blocker Evidence

F23 loaded only `0.2.26`, identified and selected `18/18` new windows, then
stopped without movement because serialized connector entries were `29` while
new runtime Connector objects were `17`. The old candidate was `(6750, 8950)`
and the intended expanded target was `(15083.99, 16915.3)` with delta
`(8333.994, 7965.299)`.

F24 source analysis shows the two counts describe different things:
`Desktop.copy()` stages connector metadata by selected input ownership, while
`Desktop.paste()` creates Connector objects only for retained copied output
connections. F25 logs both counts but does not compare them for equality.

## Implementation

| Surface | F25 behavior |
|---|---|
| File | `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/desktop.gd` |
| Window set | Retains F23 direct-child before/after snapshot, expected window count, valid parent, and exact vanilla selection-membership guards. |
| Resource ownership | Collects unique resource IDs only from validated pasted windows' `containers`, requiring each resource to remain a descendant of that pasted window. |
| Connector set | Retains F23 direct-child before/after Connector snapshot. |
| Classification | Each actual new connector is `INTERNAL_PASTED_CONNECTOR`, `EXTERNAL_CONNECTOR`, `AMBIGUOUS_CONNECTOR`, or `UNOWNED_CONNECTOR` from `output_id`, `input_id`, and resolved endpoint ownership. |
| Decision | Serialized/actual connector counts are diagnostic-only. Any non-internal actual new connector stops before any pasted window moves. |
| Correction | Applies one local old-to-expanded delta to the identified new windows. Only internal new connectors have custom points translated and receive `update_points()`. |
| Existing objects | Captures pre-paste positions/custom points and reports whether pre-existing windows and connectors remained untouched. |

The implementation does not mutate template data or save data. It does not
copy the vanilla `Desktop.paste()` or Connector body.

## Diagnostics

One paste sequence emits exactly these F25 labels:

- `F25_CONNECTOR_GUARD_SOURCE`
- `F25_CONNECTOR_ENDPOINT_OWNERSHIP`
- `F25_CONNECTOR_CLASSIFICATION`
- `F25_CORRECTION_DECISION`
- `F25_WINDOW_CORRECTION`
- `F25_CONNECTOR_CORRECTION`
- `F25_RELATIVE_LAYOUT_CHECK`
- `F25_SELECTION_CHECK`
- `F25_FINAL_STABILITY`

They record camera/raw/old/expanded targets, correction delta, staged and
actual connector counts, resource ownership, endpoint IDs, classification,
custom-point handling, pre/post window positions, relative layout, selection,
and deferred stability. There is no every-frame log or continuous monitor.

## Preservation and Static Audit

| Check | Result |
|---|---|
| Wholesale vanilla `Desktop.paste()` body | NO |
| Large vanilla-derived connector body | NO |
| Template-data mutation | NO |
| Save-schema change | NO |
| Unrelated window movement | NO / runtime guarded |
| Unrelated connector movement | NO / runtime guarded |
| `WindowContainer` / Base / Indexed extension | NO |
| `get_position_snapped` override | NO |
| F6/F7/F9/F11/F12/F14/F17 behavior changed | NO |
| Group resize, node limit, space cap changed | NO |

F25 changes only the existing `desktop.gd` template-paste transaction,
`manifest.json`, `mod_main.gd`, and F25/F23/HANDOFF documentation.

## Artifact

| Item | Value |
|---|---|
| Version | `0.2.27` local development canary |
| Path | `dist/Nekochan-ExpandedWorkspace-0.2.27.zip` |
| Size | `26894 bytes` |
| File count | `15` |
| ZIP root | `mods-unpacked` |
| SHA-256 | `cc78df30ca62db2ee3b12d3c504fac861fb379dc2f03cbace8329aebf04dd563` |

## Publish Safety

The allowlisted packager generated and re-opened the ZIP successfully. The ZIP
has one `mods-unpacked` root and zero forbidden entries for game binary, game
asset/resource, save file, secret, `.git`, logs, Workshop, or
`vanilla-reference` paths. Static source checks find one `Desktop.paste()`
override, no copied vanilla paste-body indicators, no blocked extension added
by F25, and no third-party copied code. The artifact remains local-only and
untracked.

## User Test

1. Install only `Nekochan-ExpandedWorkspace-0.2.27.zip`.
2. Start the game and confirm the Mod loaded.
3. Move the camera clearly beyond the old `10000` boundary.
4. Recall the same template/schematic that produced F23 `29/17`.
5. Do not manually move the preview before observation.
6. Confirm preview and final placement appear near the expanded camera target.
7. Confirm relative layout and connection/state are preserved.
8. Confirm selection/deselection, then move the pasted set once.
9. Confirm unrelated existing windows/connectors did not move.
10. Do not save after failure. Exit the game and collect `[F25]` lines.

## Git Topology

| Item | Value |
|---|---|
| F23 result commit | `cc0b094` |
| F24 plan commit | `b87837d` |
| F25 branch | `dev/phase-2c-f25-template-connector-ownership-canary` |

## Explicit Non-Actions

F25 does not authorize diagnostic cleanup, clean integration, full regression,
release integration, push, merge, tag, Release, Workshop publication, history
rewrite, or force push.

## Next Recommended Action

Install `0.2.27` and run only the connector ownership canary.

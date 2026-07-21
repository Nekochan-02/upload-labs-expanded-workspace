# Phase 2C-F24: Template Connector Guard Refinement Plan

Status: `CONNECTOR_GUARD_REFINEMENT_PLAN_REQUIRED`

## Result

`F24_TEMPLATE_CONNECTOR_GUARD_REFINEMENT_PLAN_READY`.

Implementation remains `BLOCKED` pending explicit approval. F24 is docs-only:
it does not authorize a runtime change, artifact generation, build, or runtime
test.

## F23 Blocker Evidence

The valid `0.2.26` F23 test loaded only the local Mod and reached every F23
checkpoint. It measured a camera center of `(16708.99, 17440.3)`, an old
candidate of `(6750, 8950)`, an expanded candidate of `(15083.99, 16915.3)`,
and a correction delta of `(8333.994, 7965.299)`.

Window identification and selection were exact: `18/18` new windows and a
matching selection. The strict connector count guard compared `29` serialized
connector-data entries with `17` actual new Connector objects and emitted
`STOP_NEW_CONNECTOR_COUNT_MISMATCH`. Correction was not applied, so preview
and final placement remained at `(6750, 8950)`. Relative layout, connection
state, selection, deselection, and manual movement stayed visually intact;
no unrelated window moved.

This is a connector-guard block, not an unsafe-movement failure and not a
failure of window-set identification.

## Source Analysis Findings

| Surface | Finding | Consequence |
|---|---|---|
| `Desktop.copy()` | It builds a resource-ID set from every selected window's `containers`, then saves connector data whenever a connector's `input_id` belongs to that set. It does not require that the connector's output endpoint also belongs to the set. | Serialized `data.connectors` can include metadata for inbound external connections that a paste will not recreate. Its count is not an object-count contract. |
| `Desktop.paste()` | It remaps every copied window resource ID, stages `data.connectors` by remapped input ID, then emits `create_connection` only from copied resources' retained `outputs_id` values. | A staged connector-data entry is consumed only if a corresponding connection is actually created. The F23 `29/17` mismatch is consistent with unused staged metadata. |
| Connector creation | `Connectors._on_connection_created()` instantiates a `Connector`, assigns `output_id` and `input_id`, stores it by input ID, and adds it as a direct child of `Connectors`. | The F23 direct-child snapshot is a valid way to identify runtime-created connector objects. |
| Endpoint ownership | A ready `Connector` resolves `output` and `input` from `Globals.desktop.get_resource(output_id/input_id)`. Every normal pasted `WindowBase` exposes its resource containers through `window.containers`. | A runtime predicate can prove membership by collecting resource IDs from exactly the identified pasted windows and requiring both connector endpoint IDs to be in that set. |
| Geometry | `Connector.update_points()` derives endpoint geometry from the two resource connector points and uses `custom_points` only as bend controls. | After window translation, endpoint-confirmed connectors can be refreshed; custom points require the same delta only when present. |
| Current F23 guard | `_f23_expected_connector_count()` uses `data.connectors.size()`, while `_f23_collect_new_connectors()` observes newly instantiated direct children. | Count equality is the wrong guard and must be removed only after endpoint ownership is proven at runtime. |

No source finding supports mutating template data, changing the save schema,
copying the vanilla `Desktop.paste()` body, or broadening the patch outside the
existing `desktop.gd` wrapper.

## Hypothesis Evaluation

| Hypothesis | Status | Evidence |
|---|---|---|
| H1: `29` includes staged metadata while `17` are runtime objects | Supported | Copy saves by input membership; paste instantiates only connections emitted from retained internal outputs. |
| H2: Some connectors are not direct children | Not supported for normal runtime connectors | The vanilla connector manager adds each created `Connector` directly under `Connectors`. |
| H3: Some connector objects are reused or updated | Not supported by the inspected paste path | Creation instantiates a new Connector for each emitted connection; the manager is keyed by input ID. |
| H4: Staged metadata can describe external connections | Supported | Copy includes an input-side connector without requiring selected output membership. |
| H5: Moving windows may be sufficient for endpoint geometry | Partially supported | `update_points()` derives endpoints, but non-empty `custom_points` need a uniform delta to preserve bends. |
| H6: Endpoint membership is safer than count equality | Supported, pending a runtime canary | It directly expresses the set that may be translated and excludes unrelated endpoint pairs. |

## Guard Strategy Comparison

### Candidate A: Endpoint Ownership Guard

After the existing pre/post snapshots identify new windows and direct-child
connectors, collect resource IDs from `new_windows[*].containers`. For every
new connector, require valid direct-child ownership, valid endpoint objects,
and both `output_id` and `input_id` in that resource-ID set. Only these
internal pasted connectors may have custom points translated and
`update_points()` called. The serialized connector-data count is diagnostic
only and is never compared for equality.

Pros:

- Matches runtime objects rather than staged metadata.
- Excludes connectors with either endpoint outside the pasted set.
- Retains a fail-closed outcome for missing or ambiguous endpoint identity.
- Preserves the F23 snapshot and exact window/selection guards.

Risks:

- Resource collection and connector endpoint readiness must be verified in the
  future canary.
- Any new connector that is external or ambiguous must stop the correction;
  it must not be silently ignored while windows are moved.

### Candidate B: Actual-New-Connectors-Only Guard

Translate every new direct-child connector and remove the expected-count
comparison.

Assessment: rejected. It is simpler but does not prove that each connector is
fully owned by the pasted set.

### Candidate C: Windows-Only Correction With Connector Refresh

Translate only identified windows, call `update_points()` on safely identified
connectors, and do not translate custom points.

Assessment: fallback only if the future source/runtime evidence proves that
the canary template has no custom points and endpoint-derived geometry remains
visually correct. It is not a safe general correction for custom bends.

### Candidate D: Known Limitation

Keep old-area template pre-placement documented for the first clean RC.

Assessment: fallback if endpoint ownership cannot be proven without invasive
code or if a guarded canary shows a geometry regression.

## Recommended Guard Strategy

Candidate A is the only implementation candidate worth proposing. A future
canary must retain all F23 window, selection, finite-delta, old-clamp, and
parent-ownership guards, replace only the connector count equality rule, and
add these rules:

1. Treat `data.connectors.size()` as an observed staging count, not an
   expected created-object count.
2. Build the pasted resource-ID set only from the already validated new
   windows.
3. Classify each new direct-child Connector as `internal`, `external`, or
   `ambiguous` from endpoint ownership and validity.
4. Apply the window delta only when every observed new connector is
   `internal`; otherwise stop before moving any window or connector.
5. For each internal connector, translate every custom point by the same
   delta, then call `update_points()`.
6. Do not query, move, refresh, or otherwise mutate pre-existing connectors.

The exact runtime API used to read endpoints must be limited to the existing
`Connector` fields and `WindowBase.containers`; no vanilla body copy is
allowed.

## Future Canary Proposal

Proposed version: `0.2.27`.

Proposed local-only artifact: `Nekochan-ExpandedWorkspace-0.2.27.zip`.

Purpose: template pre-placement connector-guard refinement canary. It would
remain one paste sequence only and would add no continuous monitor.

Required one-sequence logs:

- `F25_CONNECTOR_GUARD_SOURCE`: staged connector count and actual new count;
- `F25_CONNECTOR_ENDPOINT_OWNERSHIP`: connector IDs/paths, parent path,
  endpoint IDs, and pasted-set membership for each endpoint;
- `F25_CONNECTOR_CLASSIFICATION`: `internal`, `external`, or `ambiguous`;
- `F25_CORRECTION_DECISION` and `F25_WINDOW_CORRECTION`;
- `F25_CONNECTOR_CORRECTION`: custom-point counts, translation status, and
  `update_points()` status;
- `F25_RELATIVE_LAYOUT_CHECK`, `F25_SELECTION_CHECK`, and
  `F25_FINAL_STABILITY`.

Diagnostics must be bounded to one sequence. No every-frame logging,
continuous monitor, or unrelated diagnostic cleanup is authorized.

## Future User Test Proposal

1. Install only the future `0.2.27` local artifact.
2. Move the camera clearly beyond the old `10000` boundary.
3. Recall the same saved template that produced F23 `29/17`.
4. Observe preview and final placement before moving it manually.
5. Confirm placement near the expanded-area camera target.
6. Confirm relative layout, connection/state, selection/deselection, and one
   manual movement of the pasted set.
7. Confirm unrelated existing windows/connectors did not move.
8. Do not save after failure; exit and collect the one-sequence logs.

## Stop Conditions

Do not implement or continue a future canary if any of the following occurs:

- pasted resource IDs cannot be collected exactly from the validated window set;
- connector endpoint ownership or parent path is ambiguous;
- any new connector has an endpoint outside the pasted set;
- moving windows without custom-point translation breaks connection visuals;
- a correction would touch an existing connector or unrelated window;
- template-data mutation, save-schema change, `WindowContainer` patch,
  `get_position_snapped` override, or a large vanilla paste/connector body
  copy becomes necessary.

## Git Topology

| Item | Value |
|---|---|
| F23 result commit | `cc0b094` `docs: record F23 template pre-placement blocked result` |
| F23 result files | `docs/PHASE_2C_F23_TEMPLATE_PREPLACEMENT_FIX_CANARY_REPORT.md`, `docs/HANDOFF.md` |
| F24 branch | `dev/phase-2c-f24-template-connector-guard-plan` |
| F24 base | `cc0b094` |

## Explicit Non-Actions

F24 performs no runtime code change, artifact generation, build, runtime test,
fix implementation, guard implementation, cleanup, clean integration, push,
merge, tag, Release, Workshop publication, history rewrite, rebase, amend, or
force push.

## Next Recommended Action

Request approval to implement one guarded `0.2.27` connector-ownership
refinement canary. Do not implement it as part of F24.

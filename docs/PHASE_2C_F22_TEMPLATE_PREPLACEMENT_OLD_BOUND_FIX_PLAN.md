# Phase 2C-F22: Template Pre-placement Old-Bound Fix Plan

Status: `FIX_PLAN_REQUIRED`

## Result

`F22_TEMPLATE_PREPLACEMENT_FIX_PLAN_READY`.

Implementation is `BLOCKED` pending explicit user approval. This document is a
docs-only design decision; it does not authorize runtime changes, artifact
generation, a build, or a game test.

## Git Topology

| Item | Value |
|---|---|
| F22 branch | `dev/phase-2c-f22-template-preplacement-fix-plan` |
| F22 base | `b2d02f507115f7d5ee275dd70db00c035562fd2c` |
| F22 base commit | `docs: record template pre-placement diagnosis` |
| `origin/master` | `0489e834bb1eff79742081f32656ee43f04a2cb5` |
| Local commits ahead of `origin/master` at plan creation | `48` |
| Prohibited Git operations | reset, rebase, amend, history rewrite, force push, public-master merge |

## Purpose

Correct the confirmed template/schematic placement defect narrowly: vanilla
`Desktop.paste()` derives its target from `Globals.camera_center`, then clamps
that target to `Vector2(10000, 10000) - data.rect.size`. When the camera is in
the expanded area, both the observed immediate and final placement remain at
the old-bound candidate instead of near the camera.

Desired behavior: a template or schematic recalled with the camera in the
expanded area appears near that camera position, bounded by the existing
`WorkspaceAreaConfig` workspace maximum.

## F21 Root-Cause Evidence

The valid `0.2.25` F21 sequence measured the following values:

| Value | Measurement |
|---|---|
| Camera center | `(12074.19, 15876.0)` |
| Template rect size | `(3250.0, 1050.0)` |
| Raw camera target | `(10449.19, 15351.0)` |
| Old candidate | `(6750.0, 8950.0)` |
| Expanded candidate | `(10449.19, 15351.0)` |
| Old clamp detected | `true` |
| Immediate first pasted local position | `(6750.0, 8950.0)` |
| Deferred final first pasted local position | `(6750.0, 8950.0)` |
| Observed local delta from camera | `(-5324.192, -6926.005)` |

Classification: `TEMPLATE_CAMERA_SOURCE_OLD_BOUND_CLAMPED`.

F21 also shows the source data carried `18` window entries including one group.
That is broader than the intended future two-node primary canary, but it proves
the placement anchor: immediate and deferred positions both equal the old
candidate, while the expanded candidate preserves the camera-derived target.

This defect is unrelated to the F12 diagnostic skip, recurring environment
baseline errors, or the verified F6/F7/F9/F11/F12/F14/F17 behavior.

## Source Analysis Findings

| Surface | Finding | Design consequence |
|---|---|---|
| Schematic recall | `schematics_tab.gd::_on_add_pressed()` emits `Signals.place_schematic`; `Desktop._on_place_schematic()` invokes `paste(Data.schematics[schematic].duplicate(true))`. | The saved template is duplicated before the vanilla paste path runs. |
| Clipboard recall | `Desktop._unhandled_key_input()` also passes a duplicated schematic dictionary to `paste()`. | A `paste()`-local correction covers the shared placement path; it must not depend on menu UI state. |
| Vanilla anchor | `Desktop.paste()` calculates `Globals.camera_center - data.rect.size / 2`, then uses the hard-coded old maximum. | The camera calculation is correct; only the bound is wrong. |
| Window placement | Vanilla offsets each copied window by `clamped_pos - data.rect.position`, then synchronously creates the windows. | A uniform post-paste delta preserves every pasted window's relative layout. |
| Connectors | Vanilla applies that same delta to connector `custom_points`, creates connections, then clears connector staging data. | A post-paste correction must translate only newly created connectors' `custom_points` and call `update_points()`. |
| Selection | Vanilla calls `Globals.set_selection(windows_added, connections)` after connections are created. | Do not replace selection. Move only the identified nodes and retain the vanilla selection arrays. |
| New-window identification | F21 snapshots `Windows` direct-child instance IDs before `super.paste()` and observes only IDs absent from that snapshot afterward. | The same snapshot method can identify only pasted windows without name-based matching; future logs include each name and node path. |
| Position domain | `WindowContainer.move()` writes `global_position`; F6/F9/F11 established local `position` as the correct persisted/visual correction domain. | Write `window.position += delta` and emit the existing `moved` signal; do not call `move(delta)` or override snapping. |
| Expanded bound | `WorkspaceAreaConfig.get_max_position(size)` returns `(20000, 20000) - size`, floored at zero. | Use this existing helper for the expanded candidate; add no new bounds abstraction. |

No source finding supports a `screen_to_world_pos` path, template-data rebase
failure, or separate preview-only lifecycle for the confirmed sequence.

## Fix Strategy Comparison

### Candidate A: Post-super Delta Correction

Before `super.paste(data)`, compute `raw_target`, the old candidate, and the
expanded candidate from the immutable input rect; snapshot direct-child window
and connector instance IDs. Run the existing node-limit-gated `super.paste()`.
Only when the old clamp occurred and the expanded candidate differs, identify
the new windows/connectors and translate them by:

```text
expanded_candidate - old_candidate
```

Pros:

- Preserves the existing vanilla paste internals and node-limit gate.
- Avoids copying the vanilla paste body.
- Translates the complete pasted set uniformly, preserving relative layout.
- Uses runtime identity snapshots, so unrelated existing windows/connectors are
  excluded without window-name heuristics.

Risks and required guards:

- The actual new direct-child window count must equal the expected created
  count and agree with the post-paste selection window set; otherwise do not
  correct.
- The snapshot must include connector IDs as well as window IDs. Shift only
  connectors created during this paste, update their points, and do not touch
  pre-existing connector geometry.
- Group frame and child positions must receive exactly one identical local
  delta. Any evidence of a second group-managed movement stops the canary.
- The correction must execute synchronously after `super.paste()` and not
  add a deferred mover or continuous monitor.

Assessment: recommended, provided the future canary implements every guard as
fail-closed and reports its decisions once.

### Candidate B: Minimal `Desktop.paste` Target Override

Replace the old clamp inside a local paste implementation with the expanded
candidate.

Assessment: rejected for the initial canary. The target expression lies within
a substantial vanilla orchestration body that remaps IDs, creates windows,
rebuilds connectors, applies selection, and clears staging state. Copying that
body would increase compatibility, maintenance, and publish-safety risk.

### Candidate C: Known Limitation

Document old-area template placement for the first release.

Assessment: fallback only. Use it if Candidate A cannot prove exact new-object
identification, requires a wholesale `Desktop.paste()` copy, moves unrelated
nodes, or fails preservation checks.

## Recommended Future Fix Canary

Version: `0.2.26` local development canary.

Artifact name: `Nekochan-ExpandedWorkspace-0.2.26.zip`.

Proposed touchpoint: the existing Mod `extensions/scripts/desktop.gd` wrapper
around the node-limit-aware `paste()` delegation.

Proposed bounded sequence:

1. Capture input rect, camera-derived raw target, old candidate, expanded
   candidate, and pre-paste direct-child window/connector instance IDs.
2. Delegate to the current node-limit-aware `super.paste(data)` path.
3. Exit without correction unless old clamp is true and the two candidates
   differ.
4. Identify new direct-child windows and new connector objects by instance-ID
   difference. Require expected window count, selection membership, and valid
   object state before applying any shift.
5. Apply exactly one local `position += delta` to every identified pasted
   window, emit its existing `moved` signal, translate only identified new
   connector custom points by the same delta, then call `update_points()`.
6. Leave `Globals.selections`, connector selection, template data, save data,
   and all unrelated objects untouched.

The future canary must emit one paste-sequence record only:

- raw, old, and expanded targets; old-to-expanded delta;
- expected and actual pasted window counts; affected window names, instance IDs,
  and node paths;
- identified connector count;
- pre- and post-correction local positions;
- relative-layout delta before/after;
- cheap connector count/state and selection-membership result; and
- a clear `APPLIED`, `SKIPPED_NO_OLD_CLAMP`, or fail-closed stop reason.

No every-frame logging, continuous monitor, broad diagnostics, or cleanup is
authorized by this plan.

## Preservation Contract

The future implementation must preserve:

- pasted-node relative layout, including group frame/children;
- template-internal connection geometry and state;
- selection/deselection and manual movement after paste;
- node-limit `1000` behavior and space cap `200`;
- F6 single-node persistence, F12 group persistence, F14/F17 group resize,
  F9/F11 placement alignment, and F7 grid behavior; and
- the existing save schema and template serialization format.

It must not move unrelated windows/connectors, mutate saved template data,
add a `WindowContainer`, `WindowBase`, or `WindowIndexed` extension, override
`get_position_snapped`, change the save schema, or copy the vanilla
`Desktop.paste()` body.

## Future User Test Proposal

Primary test only:

1. Install only the future `0.2.26` artifact.
2. Move the camera clearly beyond the old `10000` boundary.
3. Recall one saved two-node template or schematic.
4. Do not manually move the placement before observation.
5. Verify immediate placement near the camera in the expanded area.
6. Confirm final placement remains near the camera.
7. Verify relative layout and connection/state.
8. Verify selection/deselection and one manual move after paste.
9. Do not save after a failure; exit and collect the one-sequence log.

Optional only after primary pass: a single-node template, a group-containing
template, and a template with custom connector points.

## RC Impact Decision

This is non-fatal but highly visible in a normal expanded-workspace workflow.
The preferred path is the narrow Candidate A QoL fix before clean RC. If its
identity/preservation guards cannot be satisfied without invasive paste-body
replacement, downgrade the issue to a documented known limitation for the
first release. Diagnostic cleanup and clean integration remain deferred until
that decision is resolved.

## Stop Conditions

Stop the future canary and do not widen the patch if any of the following is
observed:

- pasted windows or connectors cannot be identified exactly;
- actual counts or selection membership disagree with the expected pasted set;
- an unrelated window or connector would move;
- relative layout, group state, connection/state, selection, or manual move
  behavior changes unexpectedly;
- template data mutation, serialization change, save-schema change, a
  `WindowContainer` patch, or `get_position_snapped` override is required; or
- a large/wholesale vanilla `Desktop.paste()` copy becomes necessary.

## Explicit Non-Actions

F22 performs no runtime code change, artifact generation, build, runtime test,
fix implementation, cleanup, clean integration, push, merge, tag, Release,
Workshop publication, history rewrite, rebase, amend, or force push.

## Next Recommended Action

Request approval to implement the single `0.2.26` Candidate A template
pre-placement fix canary with the required fail-closed guards.

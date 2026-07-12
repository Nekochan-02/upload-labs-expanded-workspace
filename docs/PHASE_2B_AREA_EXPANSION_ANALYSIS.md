# Phase 2B Area Expansion Analysis

## Purpose

Investigate how Upload Labs controls the desktop area where nodes can be placed, moved, connected, viewed, and rendered.

This document is analysis only. No Phase 2B area-expansion code has been implemented yet.

## Summary

The desktop workspace is built around a vanilla coordinate range of `0..10000` on both axes, with the center at roughly `(5000, 5000)`.

This size is not centralized in one config value. It appears in several independent systems:

* camera movement limits
* individual node drag clamp
* template/schematic paste clamp
* connector custom point clamp
* group window movement and resizing clamp
* background and grid rendering
* random wandering object placement
* older save migration offset

Therefore, a reliable area expansion must patch multiple paths together. Changing only camera movement would let the player scroll farther but not place nodes there. Changing only node movement would allow off-screen nodes that may be hard to reach.

## Key Vanilla Area Values

* Desktop area size: `10000`
* Desktop center: `5000, 5000`
* Desktop coordinate range: `0..10000`
* Candidate first expansion: `20000`
* Candidate expanded center: `10000, 10000`

Use `20000` as the first practical target because it matches the existing 2x limit-relaxation theme and keeps coordinate values moderate.

## Placement And Movement Paths

### Individual Node Drag

* Vanilla file: `scenes/windows/window_container.gd`
* Relevant behavior: `get_position_snapped(to)` clamps node position inside the vanilla area, then snaps to the 50px grid.
* Phase 2B implication: this must be extended or normal dragged nodes will still stop at the old edge.

Candidate Mod patch:

* Minimal Script Extension for `scenes/windows/window_container.gd`
* Override only `get_position_snapped(to)` and use the expanded bounds.

### Template / Schematic Paste

* Vanilla file: `scripts/desktop.gd`
* Relevant behavior: `paste(data)` clamps the pasted schematic rectangle into the vanilla area.
* Phase 2B implication: saved templates will still be forced into the old 10000 area unless this path is expanded.

Candidate Mod patch:

* Extend the existing Mod `desktop.gd` wrapper.
* Keep the existing node-count wrapper.
* Add expanded paste-position clamping without copying the whole vanilla paste body if possible.

Risk:

* The current R3 desktop wrapper delegates to vanilla `paste(data)`, whose internal clamp still uses the vanilla area. Fixing this cleanly may be harder than the node-count wrapper.

### Connector Custom Points

* Vanilla file: `scenes/connector_point.gd`
* Relevant behavior: custom connector points are clamped to the vanilla area and snapped to 25px.
* Phase 2B implication: connectors can be routed only inside the old area unless this is patched.

Candidate Mod patch:

* Minimal Script Extension for `scenes/connector_point.gd`
* Override only `get_position_snapped(to)`.

### Group Window Movement And Resizing

* Vanilla file: `scenes/windows/window_group.gd`
* Relevant behavior: group windows use a local maximum bounds value for moving and resizing.
* Phase 2B implication: groups will remain limited to the old area unless patched.

Candidate Mod patch:

* Investigate whether a Script Extension can override the bounds constant cleanly.
* If not, group support may need either a targeted method override or a temporary Phase 2B-R1 exclusion.

Risk:

* `window_group.gd` has more behavior in its movement/resizing loop than a single helper method. Avoid copying the whole process function unless no safer option exists.

## Camera And View Paths

### Camera Movement Limit

* Vanilla file: `scripts/main_2d.gd`
* Relevant behavior: desktop screen size is `10000`; `set_screen(0)` assigns this to the camera limit.
* Camera file: `scripts/camera_2d.gd`
* Relevant behavior: camera position is clamped between `0` and the screen-specific limit.

Phase 2B implication:

* Desktop camera limit must become `20000`.
* Initial desktop camera position should probably move from `(5000, 5000)` to `(10000, 10000)` for new games or first screen setup.

Candidate Mod patch:

* Minimal Script Extension for `scripts/main_2d.gd`
* Override `_ready()` or `set_screen(screen)` carefully, or patch `screen_size[0]` and `screen_position[0]` before vanilla `set_screen(0)` runs.

## Rendering Paths

### Grid / Lines / Background Types

* Vanilla file: `scripts/lines.gd`
* Relevant behavior: each background style is generated around the 10000 area.
* Rendering styles include line grid, dot grid, diagonal lines, crosses, hexagons, and starfield.

Phase 2B implication:

* If placement is expanded but grid rendering is not, the new area will look visually broken or empty depending on background style.
* Doubling width and height can quadruple instance counts for dot/cross/hex styles.

Candidate Mod patch:

* R1 option: patch only the most common/simple grid style first and document unsupported styles.
* Better option: create a helper with area size and spacing, then patch every `lines.gd` build path.

Performance note:

* Dot grid is about 40k instances at 10000.
* A 20000 area at the same density is about 160k instances.
* This is acceptable for testing but must be watched for startup or settings-switch stutter.

### Paint Background

* Vanilla file: `scripts/paint.gd`
* Relevant behavior: draws a white rectangle centered around the old area.
* Phase 2B implication: if used by the active scene/theme, it should also be expanded.

## Non-Placement Systems

### Wandering Objects / Ads / Bugs

* Vanilla files: `scenes/wandering_object.gd`, `scenes/wandering_ad.gd`, `scenes/bug.gd`
* Relevant behavior: random objects are clamped or spawned around old area values.
* Phase 2B implication: these are not core placement blockers. They can remain vanilla in the first implementation unless they visibly break UX.

### Save Data

* Vanilla files: `scripts/data.gd`, `scenes/windows/window_container.gd`, `scripts/desktop.gd`
* Relevant behavior: window positions are saved as coordinates. The area size itself is not saved as a schema value.
* Phase 2B implication: positions outside 10000 should be saveable while the mod is enabled.

Risk:

* If the mod is disabled, vanilla movement and paste logic will still be based on 10000. Nodes outside the vanilla area may become unreachable or awkward to recover.

## Recommended Phase 2B-R1 Scope

First test target: `20000` desktop area.

Patch only what is required for a coherent first user test:

1. Camera can pan across `0..20000`.
2. New and dragged nodes can be placed in the expanded area.
3. Connector custom points can be moved in the expanded area.
4. Template/schematic paste can target the expanded area.
5. Main visible grid/background does not abruptly end at 10000.

Defer:

* configuration UI
* dynamic 10000/20000/40000 settings
* 40000 or larger areas
* full save-protection UI
* nonessential wandering object placement

## Open Questions Before Implementation

1. Can `main_2d.gd` be safely extended by patching `screen_size[0]` and `screen_position[0]` before vanilla `_ready()` calls `set_screen(0)`?
2. Can `window_group.gd` bounds be changed without copying the full process function?
3. Can `desktop.gd paste(data)` area clamp be changed while still delegating to vanilla paste behavior, or does it require a deeper redesign?
4. Which grid style is active for the user's current settings, and should R1 support all styles or just the selected one first?

## Implementation Gate

Phase 2B implementation must not start until the patch plan is updated and approved.

Current patch plan:

* historical failed plan: `docs/PHASE_2B_R1_IMPLEMENTATION_PLAN.md`
* current restart plan: `docs/PHASE_2B_R3_SAFE_REDESIGN_PLAN.md`

Current implementation:

* Phase 2B-R1 was implemented as a local `0.2.0` test candidate for camera bounds, normal node drag bounds, connector custom point bounds, and scaled grid/background coverage.
* User testing confirmed camera movement and zoomed-in grid expansion, but node movement/placement bounds and zoomed-out desktop visual coverage failed.
* Phase 2B-R2 was implemented as local `0.2.1` to patch `window_base.gd`, `window_indexed.gd`, and Desktop child control sizes, but it failed critically and was rolled back.
* Template/schematic paste bounds and group window bounds are deferred as known R1 limitations.

Hard stop:

* Do not re-enable `0.2.0` or `0.2.1`.
* Do not patch `window_base.gd` / `window_indexed.gd` as the next approach. The direct base-class Script Extension path appears to break node initialization and saved state.
* Do not start the next implementation until `docs/PHASE_2B_R3_SAFE_REDESIGN_PLAN.md` is approved.

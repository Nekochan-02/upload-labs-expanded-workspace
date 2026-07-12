# Phase 2B-R1 Implementation Plan

## Purpose

Create the first local test candidate for expanding the desktop workspace area from the vanilla `10000 x 10000` coordinate space to `20000 x 20000`.

Phase 2B-R1 was implemented as a local `0.2.0` test candidate. User testing partially verified camera and grid behavior, but node movement/placement bounds still failed.

Phase 2B-R2 was implemented as local version `0.2.1` to address the failed node bounds and desktop background sizing paths, but it failed critically in game testing and has been rolled back.

## Current Baseline

Phase 2A limit relaxation is complete for the current local goal:

* total placed node cap: `500 -> 1000`
* `space` upgrade cap: `100 -> 200`
* user confirmed the current limit-relaxation behavior works as expected

Phase 2B starts the next independent goal: increasing the physical area where nodes can be placed and operated.

## Target

Use a fixed desktop area of `20000 x 20000` for the first test candidate.

Rationale:

* It matches the 2x theme used for node-count and `space` upgrade expansion.
* It keeps coordinate values moderate.
* It avoids opening configuration UI or arbitrary custom values before the base behavior is proven.

## Non-Goals

Phase 2B-R1 will not implement:

* dynamic area-size settings
* `40000` or larger areas
* config UI
* full save-protection UI
* Workshop packaging
* Steam upload
* rewriting or redistributing vanilla files

## Shared Constants

Add a Mod-side helper script for workspace constants:

* `VANILLA_WORKSPACE_SIZE = 10000`
* `MODDED_WORKSPACE_SIZE = 20000`
* `VANILLA_WORKSPACE_CENTER = Vector2(5000, 5000)`
* `MODDED_WORKSPACE_CENTER = Vector2(10000, 10000)`

Reason: avoid scattering `20000` across multiple extension files.

Candidate file:

* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd`

## Patch Set

### 1. Camera Bounds

Vanilla target:

* `scripts/main_2d.gd`

Goal:

* desktop screen camera limit becomes `20000`
* desktop default center becomes `10000, 10000`
* research and ascension screens keep their vanilla sizes

Candidate Mod file:

* `extensions/scripts/main_2d.gd`

Preferred approach:

* minimal Script Extension
* patch `screen_size[0]` and `screen_position[0]` before vanilla startup logic calls `set_screen(0)`
* if needed, override `set_screen(screen)` and only adjust desktop screen data before delegating to `super.set_screen(screen)`

Verification:

* camera can pan beyond old `10000` edge
* switching to research/ascension and back does not break camera limits

### 2. Normal Node Drag Bounds

Vanilla target:

* `scenes/windows/window_container.gd`

Goal:

* individual nodes can be moved and snapped within `0..20000`

Candidate Mod file:

* `extensions/scenes/windows/window_container.gd`

Preferred approach:

* override only `get_position_snapped(to)`
* keep vanilla 50px snap behavior
* do not copy movement or input logic

Verification:

* place or move a node past x/y `10000`
* node still snaps correctly
* node cannot move below `0` or beyond the expanded edge

### 3. Connector Custom Point Bounds

Vanilla target:

* `scenes/connector_point.gd`

Goal:

* custom connector points can be moved within `0..20000`

Candidate Mod file:

* `extensions/scenes/connector_point.gd`

Preferred approach:

* override only `get_position_snapped(to)`
* keep vanilla 25px snap behavior and input/output alignment behavior

Verification:

* route a connector in the expanded area
* custom points remain draggable and snapped

### 4. Grid / Background Rendering

Vanilla target:

* `scripts/lines.gd`

Goal:

* grid/background does not visibly stop at the old `10000` boundary

Candidate Mod file:

* `extensions/scripts/lines.gd`

Implemented R1 approach:

* scale the existing vanilla rendered grid/background output by `2x`
* avoid copying the large vanilla `lines.gd` body
* reduce performance risk compared with regenerating every dense grid at 4x instance count

Performance note:

* dot grid rises from about 40k to about 160k instances
* the R1 scaling approach avoids that immediate increase, but grid spacing becomes visually coarser

Deferred:

* exact-density full `lines.gd` regeneration can be handled later if the scaled grid is not acceptable

### 5. Paint Background

Vanilla target:

* `scripts/paint.gd`

Goal:

* any plain background rectangle covers the expanded area

Candidate Mod file:

* `extensions/scripts/paint.gd`

Preferred approach:

* override only `_draw()`
* draw a rectangle centered around the expanded workspace

### 6. Template / Schematic Paste Bounds

Vanilla target:

* `scripts/desktop.gd`

Goal:

* pasted templates can target the expanded area instead of being forced back into the old `10000` area

Risk:

* vanilla `paste(data)` calculates the clamp internally, and the current R3 wrapper delegates to `super.paste(data)`
* changing this without copying the whole vanilla paste function may require a pre-adjustment strategy

Preferred investigation-first approach:

* try to adjust the incoming `data.rect.position` and/or `Globals.camera_center` so vanilla paste's internal clamp produces the desired expanded-area result
* keep existing R3 node-count wrapper behavior
* avoid copying vanilla paste body

R1 status:

* deferred as a known R1 limitation
* current R1 keeps normal drag placement working first

### 7. Group Window Bounds

Vanilla target:

* `scenes/windows/window_group.gd`

Goal:

* group windows can move and resize in the expanded area

Risk:

* movement and resizing bounds are embedded in `_process(delta)`
* clean patching may be harder than simple helper-method overrides

R1 status:

* deferred as a known R1 limitation
* do not copy the entire `_process(delta)` body unless explicitly reviewed and approved as a publish-safe exception

## Mod Registration

`mod_main.gd` installs these new extensions after the existing Phase 2A extensions:

* `extensions/scripts/main_2d.gd`
* `extensions/scenes/windows/window_container.gd`
* `extensions/scenes/connector_point.gd`
* `extensions/scripts/lines.gd`
* `extensions/scripts/paint.gd`

Deferred depending on implementation safety:

* `extensions/scripts/desktop.gd` update for paste bounds
* `extensions/scenes/windows/window_group.gd`

## Versioning

Candidate version:

* `0.2.0`

Reason:

* Phase 2B changes the physical workspace area, which is a larger behavioral change than the Phase 2A-R4 data-limit patch.

## Verification Plan

Minimum R1 manual test:

1. Start game and confirm Mod Loader reports the new version.
2. Pan camera beyond the old `10000` edge.
3. Add or drag a node to around `(15000, 15000)`.
4. Move that node and confirm it snaps normally.
5. Route a connector custom point in the expanded area.
6. Check the current grid/background does not end at the old edge.
7. Save and reload once with at least one node beyond `10000`.

Optional if included:

8. Paste a template near `(15000, 15000)`.
9. Move or resize a group window beyond `10000`.

Current R1 limitations:

* Template/schematic paste may still be clamped by vanilla paste internals.
* Group window movement/resizing may still be clamped by vanilla group bounds.
* Grid/background is scaled to cover the expanded area; it is not regenerated at original density.

Current R2 fix candidate:

* Add `get_position_snapped(to)` overrides for `window_base.gd` and `window_indexed.gd`.
* Resize `Desktop/Background` and `Desktop/Connectors` to the expanded workspace size.

R2 result:

* `CRITICAL_FAILURE_ROLLED_BACK`
* Do not re-enable this approach.
* Future work must avoid extending `window_base.gd` / `window_indexed.gd` directly unless a separate isolated proof shows it is safe.

## Main Risks

* `desktop.gd paste(data)` may not be safely patchable with a small wrapper.
* `window_group.gd` may require a larger override than desired.
* `lines.gd` full support may duplicate too much vanilla body if implemented naively.
* Expanded-area saves may be awkward if the mod is disabled later.

## Approval Gate

Approved by the user, implemented, failed critically, and rolled back. Future Phase 2B work requires a new plan.

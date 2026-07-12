# Phase 2A-R3 Implementation Plan

## Purpose

Phase 2A-R2 proves that manual placement can exceed the vanilla 500-node limit, but the mod does not yet deliver the real user goal: a coherent expanded workspace where normal placement, template/schematic placement, and UI limit display all agree.

R3 should make the node-count expansion coherent without starting workspace-bounds expansion.

## Current Verified State

* Manual placement can exceed 500 nodes.
* R3 user testing confirmed template/schematic placement over the vanilla 500-node boundary.
* R3 user testing confirmed the node-count UI no longer remains capped at 500 for the tested path.
* Practical target cap should be finite, likely 1000 or 2000, not truly unlimited.

## Proposed Target Cap

Use `1000` as the next safe validation cap.

Rationale:

* It matches the current R2 implementation.
* It limits performance and save-risk while proving all placement paths are coherent.
* After save/reload/performance testing, a `2000` cap can be evaluated as a separate step.

## R3 Scope

1. Keep R2 manual placement behavior.
2. Add template/schematic placement support over 500 nodes.
3. Update node palette total-count display to show the expanded cap.
4. Update schematic/template UI availability display to use the expanded cap.
5. Keep workspace bounds, camera, grid, save schema, and configuration UI unchanged.

## Candidate Patch Points

* `scripts/desktop.gd`
  * Target: `paste(data: Dictionary)`.
  * Goal: allow paste/template placement when `Globals.max_window_count + required <= expanded_cap`.
  * Constraint: do not copy the vanilla function body. Prefer the same temporary-count wrapper pattern used in R2, only if it can delegate safely to vanilla paste.

* `scripts/schematics_tab.gd`
  * Target: `update_node_count()`.
  * Goal: display available capacity and requirement state using expanded cap.

* `scripts/windows_tab.gd`
  * Target: `update_node_count()`.
  * Goal: display total node count against expanded cap instead of vanilla 500.

## Verification Plan

* Start game and confirm Mod Loader loads v0.1.3 or newer without errors.
* Place more than 500 nodes manually.
* Place a saved template/schematic that crosses the 500-node boundary.
* Confirm node palette display shows the expanded cap.
* Save and reload a save containing more than 500 nodes.
* Do not proceed to workspace-bounds expansion until these pass.

## Implementation Status

Approved by the user and implemented as `Nekochan-ExpandedWorkspace-0.1.3.zip`.

R3 is user-verified for the three core placement paths: normal manual placement, template/schematic placement, and node-count display.

Remaining validation: save/reload over 500 nodes, exact 1000-node boundary behavior, and performance observation.

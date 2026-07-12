# Upload Labs Expanded Workspace

Experimental Godot Mod Loader mod for expanding Upload Labs workspace limits.

## Purpose

This project explores a mod for the Steam version of Upload Labs that may eventually relax workspace constraints such as total placed node count and usable canvas area.

## Current Status

Work in progress.

Phase 2A is currently `LIMIT_RELAXATION_COMPLETE_USER_VERIFIED`.

Phase 2A-R2 allowed placing more than 500 nodes through normal manual placement in game testing.

Phase 2A-R3 extends normal manual placement, template/schematic placement, and the node-count UI to the same 1000-node cap. These three user-facing paths were confirmed in game testing.

Phase 2A-R4 raises the `space` upgrade cap from 100 to 200 while preserving the existing cost progression. The user confirmed it works as expected in game testing.

The node-count and `space` upgrade limit relaxation work is considered complete for the current local goal. Basic expanded-area interaction is also verified through Phase 2B-R3 `0.2.9`. The project is still work in progress because large-save behavior, performance, packaging, compatibility, and configuration UI are not yet complete release criteria.

## Target Game

Upload Labs.

## Mod Framework

Godot Mod Loader v7.

## Development Status

- Phase 1 analysis documents exist under `docs/`.
- A Phase 2A-R4 and Phase 2B-R3 minimal Script Extension implementation exists under `mod/source/`.
- Core node-limit and basic expanded-area interaction paths are user-verified locally, but this should still be treated as an experimental development build.

## Known Issue

Phase 2A-R3 targets a coherent 1000-node workspace limit across manual placement, template/schematic placement, and node-count display. Phase 2A-R4 targets the vanilla `space` upgrade cap, raising it from 100 to 200 while preserving the existing cost progression.

The first area-expansion candidate is Phase 2B. Version `0.2.0` partially worked for camera movement and zoomed-in grid expansion, but failed node movement/placement bounds and zoomed-out desktop visual coverage. Version `0.2.1` failed critically and has been rolled back. The last stable limit-relaxation build is `0.1.4`; the current live test build is `0.2.9`.

The current area-expansion attempt is tracked in `docs/PHASE_2B_R3_SAFE_REDESIGN_PLAN.md`. It uses small, isolated canaries and must be tested with a disposable test save.

Phase 2B-R3 `0.2.3` has verified camera movement and zoomed-out grid/background coverage in user testing. It does not yet implement or verify node placement or node movement into the expanded area.

Phase 2B-R3 `0.2.4` was verified in user testing for click placement into the expanded area, with a minor up-left target offset noted.

Phase 2B-R3 `0.2.5` was verified in user testing for drag placement into the expanded area. It does not implement existing-node movement, template paste, or connector-point expansion.

Phase 2B-R3 `0.2.6` targeted existing-node movement only. It loaded successfully and did not break node state, selection, connections, levels, costs, click placement, or drag-from-palette placement. However, existing single-node and multi-selection movement still stop at the old invisible boundary, so `0.2.6` is a state-safe functional failure.

Phase 2B-R3 `0.2.8` is state-safe but partially fails group selection movement: contained nodes can cross the old boundary while the group frame does not move with them.

Phase 2B-R3 `0.2.9` was verified in user testing for group-selection movement sync. Basic expanded-area interaction is now verified for camera movement, zoomed-out grid/background coverage, click placement, drag-from-palette placement, existing-node movement, and group-selection movement.

Known Phase 2B-R1 limitations:

- Template/schematic paste may still be clamped by vanilla paste internals.
- Group window resizing may still be clamped by vanilla group bounds.
- Connector-point movement in the expanded area is not yet verified.
- Grid/background is scaled to cover the expanded area, not regenerated at original density.

Do not use or package `0.2.0` or `0.2.1`.

After rollback to `0.1.4`, node placement works again. Lost nodes from the affected save are not being restored by user decision.

Save schema hardening, long-running large-save behavior, performance profiling, packaging automation, compatibility checks, and configuration UI are not part of the current implementation.

## Repository Structure

- `docs/`: Canonical design notes, risk notes, handoff state, and test reports.
- `mod/source/`: Mod source layout intended for Godot Mod Loader packaging.
- `tools/`: Local helper scripts, if present.
- `research/`: Local research workspace. Temporary Workshop or extracted third-party files must remain untracked.
- `vanilla-reference/`: Local-only reverse-engineering reference directory. This directory must never be tracked, pushed, or packaged.
- `logs/`: Local debug logs. This directory must remain untracked.

## Legal / Reverse-Engineered Content Policy

This repository must not contain Upload Labs game binaries, `.pck` files, extracted assets, recovered vanilla scripts, scenes, resources, Steam Workshop downloads, or other third-party proprietary content.

Reverse-engineering notes should stay limited to necessary file names, function names, behavior descriptions, and patch strategy. Do not copy vanilla source code into public documentation or publishable mod files.

No open-source license has been selected yet. License selection is a future maintainer decision.

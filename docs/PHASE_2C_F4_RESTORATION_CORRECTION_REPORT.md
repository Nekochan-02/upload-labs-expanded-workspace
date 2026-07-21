# Phase 2C-F4 Restoration Correction Report

Status: `PARTIAL_FIX_RESIDUAL_POSITION_DRIFT`

## Artifact

- version: `0.2.12`
- filename: `Nekochan-ExpandedWorkspace-0.2.12.zip`
- path: `dist/Nekochan-ExpandedWorkspace-0.2.12.zip`
- size: `11213 bytes`
- file count: `13`
- ZIP root: `mods-unpacked`
- manifest version: `0.2.12`
- SHA-256: `d9460694e99618d7916831edb2ae232a60a0b53fe576b179364d36109394fe5c`
- artifact type: development canary
- public release artifact: no

## Scope

- correction surface: existing `extensions/scripts/desktop.gd`
- correction timing: one-shot deferred after `super._enter_tree()`
- target: restored windows whose saved position exceeds the old vanilla bounds for their restored size
- desired position source: saved position clamped to `WorkspaceAreaConfig.get_max_position(restored_window.size)` and snapped to 50
- mutation mechanism: `WindowContainer.move(desired_position)`

## Static Scope

- `WindowContainer` extension included: `NO`
- `WindowContainer` registration present: `NO`
- `WindowBase` extension included: `NO`
- `WindowIndexed` extension included: `NO`
- `get_position_snapped()` override present: `NO`
- save schema mutation: `NO`
- continuous position monitoring: `NO`
- selection code change: `NO`

## Publish Safety Audit

- vanilla-verbatim body: `0`
- substantial vanilla-derived code: `0`
- third-party copied code: `0`
- game binary: `0`
- game asset/resource: `0`
- save file: `0`
- secret: `0`
- forbidden file: `0`

ZIP scan confirmed no `window_container.gd`, `window_base.gd`, `window_indexed.gd`, `vanilla-reference`, `.exe`, `.dll`, `.pck`, save file, scene/resource file, logs, or Workshop path entry.

## User Verification Matrix

| Test | Result |
|---|---|
| Empty-area deselect | NOT REPORTED |
| Menu x deselect | NOT REPORTED |
| Single-node expanded position persistence | FAIL |
| SAVED checkpoint | CAPTURED |
| BEFORE_CORRECTION checkpoint | CAPTURED |
| AFTER_CORRECTION checkpoint | CAPTURED |
| STABILITY_CHECK checkpoint | CAPTURED |

## User Result

- old-boundary warp: `FIXED_BY_CANARY`
- exact saved position retention: `FAIL`
- residual position drift: `OBSERVED`

User observed that v0.2.12 no longer warps the node back to the old workspace boundary after save / exit / restart / load. However, screenshot comparison and gameplay observation showed that the node position still shifts after restart.

Selection results were not reported for this v0.2.12 pass, so they are not marked as PASS here.

## Checkpoint Summary

Latest `modloader.log` evidence:

| Window | SAVED | BEFORE | AFTER | STABILITY |
|---|---:|---:|---:|---:|
| `server0` | `(19650.0, 19250.0)` | `(9650.0, 9250.0)` | `(19560.07, 19059.62)` | `(19560.07, 19059.62)` |
| `download_text0` | `(19300.0, 19000.0)` | `(9650.0, 9750.0)` | `(19210.07, 18930.12)` | `(19210.07, 18930.12)` |
| `download_manager0` | `(18950.0, 18150.0)` | `(9650.0, 9200.0)` | `(18860.07, 17938.04)` | `(18860.07, 17938.04)` |

The canary corrects away from the old-boundary clamp, but the final local `position` still differs from the saved local `position`.

Detailed analysis: `docs/PHASE_2C_F5_POSITION_DRIFT_GRID_GEOMETRY_ANALYSIS.md`

## Decision

`PARTIAL_FIX_RESIDUAL_POSITION_DRIFT`

Do not publish this artifact. Do not treat v0.2.12 as a pass.

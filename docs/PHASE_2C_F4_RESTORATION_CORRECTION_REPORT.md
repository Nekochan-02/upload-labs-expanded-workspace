# Phase 2C-F4 Restoration Correction Report

Status: `F4_CANARY_READY_FOR_USER_TEST`

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
| Empty-area deselect | NOT TESTED |
| Menu x deselect | NOT TESTED |
| Single-node expanded position persistence | NOT TESTED |
| SAVED checkpoint | NOT TESTED |
| BEFORE_CORRECTION checkpoint | NOT TESTED |
| AFTER_CORRECTION checkpoint | NOT TESTED |
| STABILITY_CHECK checkpoint | NOT TESTED |

## Decision

`F4_CANARY_READY_FOR_USER_TEST`

Do not publish this artifact. Use it only for the scoped single-node user canary test.

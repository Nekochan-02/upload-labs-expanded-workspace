# Phase 2C-F3 Desktop Restoration Diagnostic Report

Status: `DIAGNOSTIC_ARTIFACT_READY_FOR_USER_TEST`

## Artifact

- version: `0.2.11`
- filename: `Nekochan-ExpandedWorkspace-0.2.11.zip`
- path: `dist/Nekochan-ExpandedWorkspace-0.2.11.zip`
- size: `11073 bytes`
- file count: `13`
- ZIP root: `mods-unpacked`
- manifest version: `0.2.11`
- SHA-256: `565399784e83163d9ff2013fdd3d43028ed516af9a811bf30d31885a3789dd2e`
- artifact type: development diagnostic
- public release artifact: no

## Runtime Result

Codex has not run the game. User runtime verification is required.

| Diagnostic | Value |
|---|---|
| P2 saved position | NOT TESTED |
| P3 after load | NOT TESTED |
| P3.5 after add_child/init | NOT TESTED |
| P4 deferred final | NOT TESTED |
| selection empty-area deselect | NOT TESTED |
| selection x deselect | NOT TESTED |

## Static Scope

- patch surface: existing `extensions/scripts/desktop.gd`
- `WindowContainer` extension included: `NO`
- `WindowContainer` registration present: `NO`
- `WindowBase` extension included: `NO`
- `WindowIndexed` extension included: `NO`
- `get_position_snapped()` override present: `NO`
- restored position mutation: `NO`
- save schema mutation: `NO`

## Diagnostic Design

Checkpoints:

- P2 is logged before `super._enter_tree()` from `Data.loading.desktop_data.windows`.
- P3 direct is logged as `UNOBSERVED` because observing immediately after `new_object.load(window_data)` would require copying vanilla `Desktop._enter_tree()`.
- P3.5 is logged at `$Windows.child_entered_tree` and again after `super._enter_tree()` returns.
- P4 is logged through a deferred final observation.

Target filtering:

- maximum 3 windows
- saved `position` must be `Vector2`
- saved `position.x > 10000` or `position.y > 10000`
- correlation uses saved `window.name`, matching vanilla `Windows/<window.name>` lookup

## User Verification Matrix

| Test | Result | Evidence |
|---|---|---|
| v0.2.11 diagnostic artifact installed | NOT TESTED | |
| WindowContainer extension absent at runtime | NOT TESTED | |
| Empty-area deselection clears selection | NOT TESTED | |
| Options-menu x clears selection | NOT TESTED | |
| Single node placed in expanded area | NOT TESTED | |
| Save / exit / restart / load completed | NOT TESTED | |
| Node moved back to old boundary or retained position | NOT TESTED | |
| F3 P2 log captured | NOT TESTED | |
| F3 P3 direct-unobserved marker captured | NOT TESTED | |
| F3 P3.5 log captured | NOT TESTED | |
| F3 P4 log captured | NOT TESTED | |

## Decision

`DIAGNOSTIC_ARTIFACT_READY_FOR_USER_TEST`

Do not implement a position fix from this artifact. Use it only to gather runtime evidence.

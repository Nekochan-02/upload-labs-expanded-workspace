# Phase 2C-F1 v0.2.10 Development Test Report

## Artifact

- filename: `Nekochan-ExpandedWorkspace-0.2.10.zip`
- path: `dist/Nekochan-ExpandedWorkspace-0.2.10.zip`
- size: `10245 bytes`
- file count: `14`
- ZIP root: `mods-unpacked`
- SHA-256: `ded8cd9f17ef30c088b7a8bb33272e2aae187c61830b409fdaf07c73d64f4e4f`
- manifest version: `0.2.10`
- Mod ID: `Nekochan-ExpandedWorkspace`
- development artifact: yes
- public release artifact: no

## Fix Scope

- extension path: `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/windows/window_container.gd`
- target script: `res://scenes/windows/window_container.gd`
- overridden function: `get_position_snapped(to)`
- new bound source: `WorkspaceAreaConfig.get_max_position(size)`
- `_ready()` override: no
- save schema changed: no
- node limit changed: no
- `space` upgrade cap changed: no
- camera/grid/background changed: no
- placement workflow changed: no
- group-selection movement changed: no

## Package Audit

- root structure: `mods-unpacked/Nekochan-ExpandedWorkspace/...`
- forbidden files: `0`
- publish safety: `PASS`
- v0.2.9 artifact changed: no
- v0.2.9 artifact SHA-256: `fc8ddab1a3f73c468eb5a1fbb2702a683629c703d67498c983ad0e52f8a038af`

## Publish Safety Audit

- artifact vanilla-verbatim detected: `0`
- artifact substantial vanilla-derived detected: `0`
- artifact third-party copied code detected: `0`
- artifact game binary detected: `0`
- artifact game asset/resource detected: `0`
- artifact save file detected: `0`
- artifact secret detected: `0`
- artifact forbidden file detected: `0`
- generated hook pack detected: `0`

Notes:

- The two `.tscn` marker hits in the ZIP scan are runtime `res://... .tscn` references in existing `.gd` source. No `.tscn` files are packaged.
- This artifact must not be uploaded as a GitHub Release or Workshop item.

## User Verification Matrix

| Test | Result | Evidence |
|---|---|---|
| v0.2.10 development artifact installed | NOT TESTED | |
| Mod detected as 0.2.10 | NOT TESTED | |
| Game starts | NOT TESTED | |
| Single node placed in expanded area | NOT TESTED | |
| Single node position retained after save/exit/restart/load | NOT TESTED | |
| Group frame placed or moved in expanded area | NOT TESTED | |
| Group frame position retained after save/exit/restart/load | NOT TESTED | |
| Group child positions retained after save/exit/restart/load | NOT TESTED | |
| Connections retained | NOT TESTED | |
| Node state retained | NOT TESTED | |
| Level retained | NOT TESTED | |
| Cost retained | NOT TESTED | |
| Normal placement | NOT TESTED | |
| 500+ placement capability | NOT TESTED | |
| Camera expanded area | NOT TESTED | |
| Zoomed-out grid/background | NOT TESTED | |
| Click placement in expanded area | NOT TESTED | |
| Drag placement in expanded area | NOT TESTED | |
| Existing node movement | NOT TESTED | |
| Group-selection movement | NOT TESTED | |

## Decision

`DEV_ARTIFACT_READY_FOR_USER_TEST`

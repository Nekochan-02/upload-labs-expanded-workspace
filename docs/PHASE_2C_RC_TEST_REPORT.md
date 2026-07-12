# Phase 2C v0.2.9 Release Candidate Test Report

## Artifact

- filename: `Nekochan-ExpandedWorkspace-0.2.9.zip`
- path: `dist/Nekochan-ExpandedWorkspace-0.2.9.zip`
- size: `9770 bytes`
- file count: `13`
- SHA-256: `fc8ddab1a3f73c468eb5a1fbb2702a683629c703d67498c983ad0e52f8a038af`
- source commit: `c321cf2c3c0757611c07d93f4a03bbf0e90c06ca`
- manifest version: `0.2.9`

## Package Audit

- root structure: `mods-unpacked/Nekochan-ExpandedWorkspace/...`
- Mod ID: `Nekochan-ExpandedWorkspace`
- namespace: `Nekochan`
- Mod name: `ExpandedWorkspace`
- compatible Mod Loader version: `7.0.1`
- compatible game version: `2.2.11`
- file count: `13`
- forbidden files: `0`
- publish safety: `PASS`

## Source of Truth

- release source root: `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/`
- entrypoint: `mod_main.gd`
- registered Script Extensions:
  - `extensions/boot.gd`
  - `extensions/scripts/windows_tab.gd`
  - `extensions/scenes/window_dragger.gd`
  - `extensions/scenes/windows/window_group.gd`
  - `extensions/scripts/desktop.gd`
  - `extensions/scripts/schematics_tab.gd`
  - `extensions/scripts/main_2d.gd`
  - `extensions/scripts/lines.gd`
  - `extensions/scripts/paint.gd`
- registered hooks: none

## Release Artifact Safety Audit

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

- The generated RC ZIP file set matches the previous local `mod/build/Nekochan-ExpandedWorkspace-0.2.9.zip` file set.
- Two marker hits were reviewed in `.gd` content and were only runtime `res://... .tscn` scene path references. No `.tscn` files are included in the ZIP.
- Ignored local abandoned canary files under `mod/source` are not selected because release packaging is based on Git-tracked allowlisted source files.

## Clean Install Preparation

1. Remove or disable the current live test Mod ZIP or unpacked Mod.
2. Confirm that no older `Nekochan-ExpandedWorkspace` test build is active in the Mod Loader profile.
3. Install only `dist/Nekochan-ExpandedWorkspace-0.2.9.zip`.
4. Start Upload Labs.
5. Confirm the Mod Loader log shows `Nekochan-ExpandedWorkspace` version `0.2.9`.
6. Run the smoke test matrix below.
7. Save the game.
8. Exit and restart the game.
9. Reload the save and confirm the expanded-area nodes remain intact.

## User Verification Matrix

| Test | Result | Evidence |
|---|---|---|
| Old live Mod removed/disabled | NOT TESTED | |
| RC ZIP installed | NOT TESTED | |
| Mod detected | NOT TESTED | |
| Game starts | NOT TESTED | |
| Existing save loads | NOT TESTED | |
| Normal placement | NOT TESTED | |
| 500+ placement capability retained | NOT TESTED | |
| Camera expanded area | NOT TESTED | |
| Zoomed-out grid/background | NOT TESTED | |
| Click placement in expanded area | NOT TESTED | |
| Drag placement in expanded area | NOT TESTED | |
| Existing node movement | NOT TESTED | |
| Group-selection movement | NOT TESTED | |
| Save | NOT TESTED | |
| Restart / reload | NOT TESTED | |

## Known Limitations

- Template/schematic paste may still be clamped by vanilla paste internals.
- Group window resizing may still be clamped by vanilla group bounds.
- Connector-point movement in the expanded area is not verified.
- Grid/background is scaled to cover the expanded area and is not regenerated at original density.
- Large-save behavior is not fully validated.
- Long-running performance is not profiled.
- Compatibility with future Upload Labs versions is not guaranteed.
- Configuration UI does not exist.

## Release Decision

`RC_READY_FOR_USER_TEST`

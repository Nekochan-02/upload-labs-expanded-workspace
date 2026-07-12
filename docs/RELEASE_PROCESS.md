# Release Process

This document is the canonical release process for packaging Expanded Workspace.

## Release Source

Release packages must be built from the public repository source only.

- Release source root: `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/`
- Expected Mod ID: `Nekochan-ExpandedWorkspace`
- Current release candidate version: `0.2.9`
- Required entrypoint: `mod_main.gd`
- Required manifest: `manifest.json`

Do not reuse a ZIP from a previous live test as a release artifact.

## Required ZIP Structure

The ZIP root must contain exactly `mods-unpacked/`.

```text
mods-unpacked/
└─ Nekochan-ExpandedWorkspace/
   ├─ manifest.json
   ├─ mod_main.gd
   ├─ extensions/
   │  └─ ...
   └─ hooks/
      └─ ...
```

Only directories that exist in the packaged source should be present.

## Build Command

```powershell
./tools/build_release.ps1 -Version 0.2.9
```

Expected output:

```text
dist/Nekochan-ExpandedWorkspace-0.2.9.zip
```

`dist/` is generated output and must not be committed.

## Packaging Rules

The build helper uses allowlist packaging from Git-tracked Mod source files.

Allowed package inputs:

- `manifest.json`
- `mod_main.gd`
- `extensions/**/*.gd`
- `hooks/**/*.gd`
- Other self-authored runtime files only after they are intentionally added to the allowlist

The helper rejects the build when:

- `manifest.json` is missing
- `mod_main.gd` is missing
- the requested version does not match `manifest.json`
- the ZIP root is not `mods-unpacked/`
- forbidden file types or path terms are found in staging or in the ZIP
- abandoned unsafe v0.2.x canary files are selected for packaging

Forbidden content includes game binaries, `.pck` files, extracted assets, scene/resource files, save files, logs, local research files, vanilla reference files, third-party Mod files, generated hook packs, and repository metadata.

## Release Evidence

For each release candidate, record:

- artifact filename
- artifact size
- file count
- ZIP root entries
- manifest version
- Mod ID
- SHA-256
- package safety audit result
- source commit

The clean install verification matrix belongs in `docs/PHASE_2C_RC_TEST_REPORT.md`.

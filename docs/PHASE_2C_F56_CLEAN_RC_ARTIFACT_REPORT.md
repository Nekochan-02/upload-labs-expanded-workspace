# Phase 2C-F56: 0.2.40 Clean RC Artifact Report

## Result

`F56_CLEAN_RC_ARTIFACT_READY_FOR_USER_SMOKE`

F56 generated and audited the `0.2.40` clean RC candidate artifact from the F55
cleanup source. Runtime smoke has not been run by Codex because no local Godot
CLI or directly accessible runtime/log environment was available in this pass.

Do not classify `0.2.40` as clean RC PASS until the required user smoke matrix
passes with only this artifact active.

## Evidence

Build command:

```powershell
./tools/build_release.ps1 -Version 0.2.40
```

Build output:

```text
artifact: C:\Users\shian\.gemini\antigravity\upload-labs-expanded-workspace\dist\Nekochan-ExpandedWorkspace-0.2.40.zip
size_bytes: 13918
file_count: 14
zip_root: mods-unpacked
manifest_version: 0.2.40
mod_id: Nekochan-ExpandedWorkspace
sha256: 266310afd8b11153829c2538c86eb78f5ee5d381a67107ee1623157712b8f0c1
```

Static source audit:

- no `F29`, `F51`, `F53`, `_f29`, `_f51`, `_f53`, `B0-B10`, or `C0-C7`
  runtime labels remain in Mod source
- no `camera_2d.gd` registration remains
- no `selection_panel.gd` extension remains
- no `WindowContainer/get_position_snapped` override remains

ZIP audit:

- ZIP root is exactly `mods-unpacked`
- manifest version is `0.2.40`
- forbidden entries: `0`
- blocked diagnostic/forbidden extension entries: `0`

ZIP entries:

```text
mods-unpacked/
mods-unpacked/Nekochan-ExpandedWorkspace/
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/boot.gd
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/drag_placement_local_alignment.gd
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/window_dragger.gd
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/windows/
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/windows/window_group.gd
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/desktop.gd
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/lines.gd
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/main_2d.gd
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/paint.gd
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/schematics_tab.gd
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/space_upgrade_limit_patch.gd
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/windows_tab.gd
mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd
mods-unpacked/Nekochan-ExpandedWorkspace/hooks/
mods-unpacked/Nekochan-ExpandedWorkspace/manifest.json
mods-unpacked/Nekochan-ExpandedWorkspace/mod_main.gd
```

## Changed Files

F56 adds this report only. The generated artifact is ignored output and is not
staged or committed.

`AGENTS.md` and `docs/HANDOFF.md` remain dirty from earlier work and were not
updated, staged, committed, or overwritten by F56.

## Artifact

| Item | Value |
|---|---|
| Path | `dist/Nekochan-ExpandedWorkspace-0.2.40.zip` |
| Size | `13918` bytes |
| File count | `14` |
| ZIP root | `mods-unpacked` |
| Manifest version | `0.2.40` |
| Mod ID | `Nekochan-ExpandedWorkspace` |
| SHA-256 | `266310afd8b11153829c2538c86eb78f5ee5d381a67107ee1623157712b8f0c1` |

## User Test Result

`NOT TESTED`

Required install condition:

- install only `Nekochan-ExpandedWorkspace-0.2.40.zip`
- confirm no older `Nekochan-ExpandedWorkspace` artifact is active
- confirm manifest/startup version `0.2.40`

Required smoke matrix:

1. old-area Shift+drag range selection
2. expanded-area Shift+drag range selection
3. normal click selection
4. empty-click deselection
5. click placement
6. drag-from-palette placement
7. existing node movement across old boundary
8. group movement across old boundary
9. single-node save/load persistence in expanded area
10. group save/load persistence in expanded area
11. template/schematic pre-placement in expanded area
12. grid density visual check

Failure in any item blocks clean RC PASS classification.

## Classification

`F56_CLEAN_RC_ARTIFACT_READY_FOR_USER_SMOKE`

## Next Action

Run the required user smoke matrix with only
`Nekochan-ExpandedWorkspace-0.2.40.zip` active. Record visual results and any
relevant `modloader.log` / game log lines.

## Explicit Non-actions

F56 performs no runtime smoke, push, merge, tag, GitHub Release, Workshop
publish, history rewrite, force push, `AGENTS.md` stage/commit/overwrite, or
dirty `docs/HANDOFF.md` overwrite.

## Human Next Action / Escalation Footer

Human Next Action:
Install only `dist/Nekochan-ExpandedWorkspace-0.2.40.zip`, run the required
smoke matrix, and report PASS/FAIL per item plus any relevant logs.

Next Action Type:
User smoke test required.

ChatGPT Escalation:
Not needed

Reason:
Artifact generation and static/package audit passed, but Codex cannot classify
the clean RC without runtime smoke evidence.

Blocked Until Human Approval:
NO

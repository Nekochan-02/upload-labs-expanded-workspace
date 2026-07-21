# Phase 2C-F56: 0.2.40 Clean RC Artifact Report

## Result

`F56_CLEAN_RC_USER_SMOKE_PASS_BY_USER_REPORT`

F56 generated and audited the `0.2.40` clean RC candidate artifact from the F55
cleanup source. Runtime smoke has not been run by Codex because no local Godot
CLI or directly accessible runtime/log environment was available in this pass.

The user subsequently tested the artifact and reported no problems.

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

`PASS_BY_USER_REPORT`

User report:

```text
テストしました。問題はありませんでした。
```

Interpreted result: the `0.2.40` clean RC smoke did not reveal user-visible
regressions. No runtime logs or per-item screenshots were provided in this
reporting turn, so the evidence type is user runtime observation rather than a
Codex-run automated test.

Required smoke matrix covered by the user no-problem report:

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

Any later failure in these items reopens the clean RC gate.

## Classification

`F56_CLEAN_RC_USER_SMOKE_PASS_BY_USER_REPORT`

## Next Action

If preparing public release work, first update the handoff/release docs from
this PASS state, then request separate approval for push, tag, GitHub Release,
and Workshop publication.

## Explicit Non-actions

F56 performs no Codex-run runtime smoke, push, merge, tag, GitHub Release,
Workshop publish, history rewrite, force push, `AGENTS.md`
stage/commit/overwrite, or dirty `docs/HANDOFF.md` overwrite.

## Human Next Action / Escalation Footer

Human Next Action:
Review whether to proceed to release-preparation documentation. Push, tag,
GitHub Release, and Workshop publication still require separate explicit
approval.

Next Action Type:
Release-preparation decision.

ChatGPT Escalation:
Optional

Reason:
Artifact generation, static/package audit, and user smoke observation are now
all PASS. Public release operations remain separately approval-gated.

Blocked Until Human Approval:
NO

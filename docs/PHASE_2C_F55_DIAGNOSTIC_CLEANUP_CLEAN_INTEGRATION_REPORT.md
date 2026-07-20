# Phase 2C-F55: Diagnostic Cleanup / Clean Integration Report

## Result

`F55_DIAGNOSTIC_CLEANUP_IMPLEMENTED_PENDING_ARTIFACT_AND_SMOKE`

F55 implements the approved runtime cleanup from the F54 re-entry plan. It keeps
the F53-proven InputBlocker coverage correction and removes the F29/F51/F53
diagnostic routes, checkpoint logs, and canary startup prose.

F55 does not create an artifact, build, run a runtime test, push, merge, tag,
create a GitHub Release, or publish to Steam Workshop.

## Evidence

F53 user evidence remains the reason for keeping the InputBlocker correction:

- old-area Shift+drag guard PASS
- expanded-area Shift+drag range selection PASS
- normal click selection PASS
- empty-click deselection PASS
- `0.2.39` artifact user test PASS

F55 keeps only the functional correction:

```gdscript
input_blocker.position = Vector2.ZERO
input_blocker.size = WorkspaceAreaConfig.get_workspace_size()
```

The correction remains deferred from `Desktop._ready()` after vanilla
initialization. It still checks that InputBlocker is a direct Desktop child and
that the workspace size matches `WorkspaceAreaConfig.MODDED_WORKSPACE_SIZE`.
If the resulting global rect does not match the target rect, F55 restores the
original local position and size and emits one concise warning.

## Changed Files

- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/desktop.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/main_2d.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/camera_2d.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/mod_main.gd`
- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/manifest.json`
- `docs/PHASE_2C_F55_DIAGNOSTIC_CLEANUP_CLEAN_INTEGRATION_REPORT.md`

`AGENTS.md` and `docs/HANDOFF.md` were intentionally not updated, staged, or
committed by F55 because both were already dirty before this implementation.

## Artifact

None. `Nekochan-ExpandedWorkspace-0.2.40.zip` is still a future artifact
candidate and must not be treated as generated or tested by F55.

## User Test Result

Not run. F55 is an implementation cleanup only. Future clean RC smoke remains
required before any RC classification.

## Classification

`F55_DIAGNOSTIC_CLEANUP_IMPLEMENTED_PENDING_ARTIFACT_AND_SMOKE`

## Keep vs Remove

Kept:

- InputBlocker coverage correction at Desktop-local `Rect2(Vector2.ZERO,
  WorkspaceAreaConfig.get_workspace_size())`
- existing verified functional fixes for workspace size, placement, movement,
  persistence, group resize, template placement, connector ownership, node cap,
  and `space` cap
- one concise startup line for `0.2.40`
- existing production-safe warning for fail-closed template correction
- one concise warning if InputBlocker coverage correction cannot safely apply

Removed:

- F29 range-selection diagnostic acquisition and R1-R10 logs
- F51 old-area / expanded route observer state and B0-B10 logs
- F53 canary C0-C7 logs and classification code
- diagnostic-only Desktop `_input()` observer
- passive InputBlocker GUI observer connection
- passive Main2D GUI/unhandled route hooks
- passive Camera route extension and its `mod_main.gd` registration
- `0.2.39` F53 canary startup prose

## Clean RC Candidate State

Source version is now prepared as `0.2.40`.

The future artifact proposal remains:

```text
Nekochan-ExpandedWorkspace-0.2.40.zip
```

That artifact has not been built and has not passed clean RC smoke.

## Required Future Smoke

The future artifact must not be classified as clean RC unless all required smoke
items pass:

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

## Static Audit Targets

F55 must be statically checked for:

- no `F29`, `F51`, `F53`, `B0-B10`, or `C0-C7` runtime labels in Mod source
- no `camera_2d.gd` registration
- no SelectionPanel extension, override, or logic edit
- no manual event forwarding
- no Camera guard
- no `WindowContainer/get_position_snapped` override
- no save schema change
- no large vanilla body copy

## Explicit Non-actions

F55 performs no artifact generation, build, runtime test, push, merge, tag,
GitHub Release, Workshop publish, history rewrite, force push, `AGENTS.md`
stage/commit/overwrite, or dirty `docs/HANDOFF.md` overwrite.

## Human Next Action / Escalation Footer

Human Next Action:
Review the F55 runtime cleanup diff. If accepted, separately approve clean RC
artifact generation for `Nekochan-ExpandedWorkspace-0.2.40.zip` and the required
targeted smoke matrix.

Next Action Type:
Human review and separate approval for artifact generation / smoke.

ChatGPT Escalation:
Not needed

Reason:
F55 implements the already approved cleanup scope. The next step creates a clean
RC artifact and runs runtime smoke, which remains separately approval-gated.

Blocked Until Human Approval:
YES

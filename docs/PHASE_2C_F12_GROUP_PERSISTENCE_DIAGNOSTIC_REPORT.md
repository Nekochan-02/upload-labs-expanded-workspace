# Phase 2C-F12: Group Persistence Diagnostic Canary Report

## Status

`F12_INTERRUPTED_BY_GROUP_RESIZE_BLOCKER`

F12 is a local development diagnostic canary for group persistence. It is not a
release candidate and must not be published as a GitHub Release, tag, Workshop
upload, or replacement v0.2.9 artifact.

The F12 group persistence diagnostic was interrupted by a higher-priority group
resize disappearance blocker discovered during user testing. Do not treat F12
as PASS.

User supplemental observation: an existing group moved to the expanded area
persisted after save, exit, restart, and load. This is promising persistence
evidence, but it is not a complete F12 pass because the group resize path is
now a blocker.

## Purpose

F12 measures whether the verified F6 restoration-only local correction is safe
for one expanded-area group frame and up to two fully enclosed child nodes after
save, exit, restart, and load.

The canary does not implement a group persistence fix. It records frame local
position, child local positions, child-to-frame relative layout, membership
preservation, and light connection/state presence around the unchanged F6
correction path.

## Implementation Scope

- Version: `0.2.19`
- Artifact: `Nekochan-ExpandedWorkspace-0.2.19.zip`
- Source path: `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/desktop.gd`
- Diagnostic entry point: existing F6 restoration snapshot and correction path
- F6 mutation behavior changed: `NO`
- Group movement changed: `NO`
- Group resize changed: `NO`
- Save schema changed: `NO`
- WindowContainer/Base/Indexed extension added: `NO`
- `get_position_snapped()` override added: `NO`
- Release, tag, Workshop, or public master operation: `NO`

## Diagnostic Target Selection

F12 selects exactly one saved group frame candidate whose saved local position is
outside the old vanilla workspace bounds. It then correlates saved non-group
windows whose saved rectangles are fully enclosed by the saved group frame
rectangle grown by the same 20-unit margin used by group selection.

The diagnostic accepts only one frame with one or two contained children. If the
candidate set is ambiguous or empty, it logs `[F12][STOP]` and makes no group
specific inference.

## Checkpoints

F12 emits these bounded checkpoint labels:

| Checkpoint | Meaning |
|---|---|
| `G1_SAVED_GROUP_FRAME_LOCAL` | Saved group frame local position and size |
| `G2_SAVED_CHILD_LOCAL_POSITIONS` | Saved child local positions and saved relative offsets |
| `G3_SAVED_GROUP_MEMBERSHIP` | Correlated frame/child membership candidate |
| `G4_BEFORE_RESTORE_CORRECTION_FRAME` | Runtime frame state before unchanged F6 correction |
| `G5_BEFORE_RESTORE_CORRECTION_CHILDREN` | Runtime child state before unchanged F6 correction |
| `G6_AFTER_RESTORE_CORRECTION_FRAME` | Runtime frame state after unchanged F6 correction |
| `G7_AFTER_RESTORE_CORRECTION_CHILDREN` | Runtime child state after unchanged F6 correction |
| `G8_NEXT_DEFERRED_FRAME` | One deferred frame stability checkpoint |
| `G9_NEXT_DEFERRED_CHILDREN` | One deferred child stability checkpoint |
| `G10_OPENING_SETTLE_FRAME` | One 0.5-second opening-settle frame checkpoint |
| `G11_OPENING_SETTLE_CHILDREN` | One 0.5-second opening-settle child checkpoint |

There is no `_process()` implementation, no every-frame logging, and no
continuous monitor.

## Relative Layout Metrics

For each selected child, F12 records:

```text
runtime_relative = child.local_position - group_frame.local_position
relative_delta = runtime_relative - saved_relative
```

Expected user-verified success requires exact frame local restoration, exact
child local restoration, zero relative delta, preserved membership, and no
double movement symptoms.

## User Verification Matrix

| Test | Result |
|---|---|
| Group frame position persistence | NOT TESTED |
| Child node position persistence | NOT TESTED |
| Child-to-frame relative layout | NOT TESTED |
| Group membership preservation | NOT TESTED |
| Connection/state preservation | NOT TESTED |
| Group selectable after load | NOT TESTED |
| Double movement detected | NOT TESTED |

Supplemental observation:

| Observation | Result |
|---|---|
| Existing group moved to expanded area persists after save/exit/restart/load | USER OBSERVED PASS |
| New group edge resize drag | USER OBSERVED FAIL |

Codex has not run the game and does not mark any F12 runtime behavior as PASS.

## Static Verification

| Check | Result |
|---|---|
| F6 restoration behavior changed | NO |
| F7 grid behavior changed | NO |
| F9 click behavior changed | NO |
| F11 drag behavior changed | NO |
| Group behavior changed | NO |
| Save schema changed | NO |
| WindowContainer extension | NO |
| Release operation | NO |

## Artifact

- Build command: `tools/build_release.ps1 -Version 0.2.19`
- Filename: `Nekochan-ExpandedWorkspace-0.2.19.zip`
- Path: `dist/Nekochan-ExpandedWorkspace-0.2.19.zip`
- Size: `16106 bytes`
- File count: `14`
- ZIP root: `mods-unpacked`
- Manifest version: `0.2.19`
- SHA-256: `176b0b9871639d8c22eea0ae620b19e8840b64e2f1802a0a1a245600a5c193f7`

## Publish Safety

| Audit item | Count |
|---|---:|
| vanilla-verbatim body | 0 |
| substantial vanilla-derived code | 0 |
| third-party copied code | 0 |
| game binary | 0 |
| game asset/resource | 0 |
| save file | 0 |
| secret | 0 |
| forbidden file/path | 0 |

The artifact contains only the expected `mods-unpacked/Nekochan-ExpandedWorkspace`
tree and no `vanilla-reference`, game binary, `.pck`, scene/resource, save,
secret, or external Workshop Mod path entries.

## User Test Gate

1. Install only `Nekochan-ExpandedWorkspace-0.2.19.zip`.
2. Start the game.
3. In the expanded area, create one group frame.
4. Place exactly two nodes fully inside the group frame.
5. Leave a simple connection/state if practical.
6. Save.
7. Exit the game.
8. Restart and load the same save.
9. Check group frame position.
10. Check child node positions.
11. Check child-to-frame relative layout.
12. Check group membership and light group selection.
13. Exit the game.
14. Provide the `[F12]` and related `[F6]` log lines.

F12 testing is paused. The next approved work item is the F13 group resize
disappearance diagnostic plan. Group movement, group resize fix implementation,
full regression, release integration, public master push, Release, tag,
Workshop publication, and v0.2.9 artifact operations remain out of scope.

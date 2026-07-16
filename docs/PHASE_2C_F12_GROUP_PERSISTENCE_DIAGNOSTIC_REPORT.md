# Phase 2C-F12: Group Persistence Diagnostic Canary Report

## Status

`F12_GROUP_PERSISTENCE_REENTRY_VERIFIED_POST_F17`

F12 is a local development diagnostic canary for group persistence. It is not a
release candidate and must not be published as a GitHub Release, tag, Workshop
upload, or replacement v0.2.9 artifact.

The original F12 run was interrupted by a higher-priority group resize
disappearance blocker. The post-F17 re-entry run below verifies the narrow F12
save/load persistence target. This does not authorize full regression, release
integration, publication, or any v0.2.9 operation.

## F18 Re-entry Gate

F18 is now planning the narrow persistence re-entry gate. F14 verified the
primary old-bound resize snap, and F17 verified top-right plus childless right
width-collapse correction. Those results remove the known resize blockers from
the F12 test path, but do not validate persistence itself.

The F12 diagnostic remains present and unchanged in
`extensions/scripts/desktop.gd`: it can correlate one saved group frame with
one or two enclosed saved children, log G1-G11, compare exact local positions
and relative deltas, and detect membership ambiguity. F18 recommends current
`0.2.24` rather than a new `0.2.25` artifact because F17 did not modify the F12
source. The re-entry setup may use only verified `top-right` or `right` resize
on the empty group before children are placed; after setup, F12 excludes resize.
If setup regresses, do not save and classify it as F14/F17 evidence. The
adjusted F12 re-entry test was subsequently run with this setup and passed.

User supplemental observation: an existing group moved to the expanded area
persisted after save, exit, restart, and load. It is supporting evidence only;
the verified F12 result is based on the separate adjusted two-child re-entry
test below.

## F18 Adjusted Re-entry Runtime Evidence

The user tested only `Nekochan-ExpandedWorkspace-0.2.24.zip`. An empty group
was enlarged through the verified `top-right` setup path before children were
placed; the setup did not collapse. Two enclosed children and one connection
were then created. No group resize or unnecessary group movement occurred
after child placement. The user saved, exited, restarted, and loaded the same
save.

The actual game and Mod Loader logs record one unambiguous F12 target:

| Checkpoint | Measured result |
|---|---|
| G1 saved frame | `group0` local `(18450, 18450)`, size `(1000, 750)` |
| G2 saved children | `download_text0` `(18550, 18600)`, saved relative `(100, 150)`; `enhancer0` `(18950, 18700)`, saved relative `(500, 250)` |
| G3 membership | Expected children `[download_text0, enhancer0]`, count `2` |
| G4/G5 before F6 correction | Frame was old-clamped at `(9000, 9250)` and membership was false. Children were `(9650, 9750)` and `(9650, 9700)` with relative deltas `(550, 350)` and `(150, 200)` respectively. Connector count was `1`. |
| G6/G7 after F6 correction | Frame and both children exactly equal their G1/G2 saved local positions. Both child relative positions equal saved relative positions; both relative deltas are `(0, 0)`; membership is true; connector count remains `1`. |
| G8/G9 next deferred | Exact saved locals, zero relative deltas, membership true, connector count `1`. |
| G10/G11 opening settle | Exact saved locals, zero relative deltas, membership true, connector count `1`, and children remain visible/in tree. |

Related `[F6]` lines independently report `DESIRED_LOCAL`,
`AFTER_CORRECTION_LOCAL`, and `STABILITY_LOCAL` equal to the saved local value
for `group0`, `download_text0`, and `enhancer0`. No `[F12][STOP]` line was
recorded for this target.

The user visually confirmed the same frame and child positions, unchanged
child-to-frame layout, preserved membership, connection/state, and group
selectability after load. Runtime instrumentation does not log selection, so
selectability is a user-observed result. The checkpoint sequence shows no
double movement: the frame and both children remain at their exact saved local
positions with zero relative delta through both stability checkpoints.

**Verdict:** `F12_GROUP_PERSISTENCE_REENTRY_VERIFIED_POST_F17`.

This verdict covers one saved expanded-area group frame with two contained
children and one observed connection. It does not cover group resize beyond
the setup prerequisite, full regression, release integration, or publication.

## F19 Scope Decision

F19 accepts this post-F17 F12 result as verified evidence for the narrow group
persistence target. The result should be carried into the scope-decision plan
as `F12 group persistence post-F17: VERIFIED`.

This does not convert `0.2.24` into a release candidate. The F12 diagnostic
logging remains part of the current canary source and must be removed or gated
before a clean RC artifact. The next recommended action is a targeted
regression plan, not full regression or release integration.

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
| Group frame position persistence | USER AND RUNTIME PASS |
| Child node position persistence | USER AND RUNTIME PASS |
| Child-to-frame relative layout | USER AND RUNTIME PASS |
| Group membership preservation | USER AND RUNTIME PASS |
| Connection/state preservation | USER AND RUNTIME PASS (`connector_count=1`) |
| Group selectable after load | USER PASS |
| Double movement detected | NOT DETECTED IN RUNTIME CHECKPOINTS |

Supplemental observation:

| Observation | Result |
|---|---|
| Existing group moved to expanded area persists after save/exit/restart/load | USER OBSERVED PASS |
| Adjusted F18 group frame with two children persists after save/exit/restart/load | USER AND RUNTIME PASS |
| Historical F13 new-group edge resize drag | USER OBSERVED FAIL; addressed separately by F14/F17 |

Codex has not run the game. The runtime entries above are derived from the
actual user-provided game and Mod Loader logs, and visual entries are the
user's reported observations.

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

The adjusted F12 re-entry test is complete. Full regression, release
integration, public master push, Release, tag, Workshop publication, and
v0.2.9 artifact operations remain out of scope.

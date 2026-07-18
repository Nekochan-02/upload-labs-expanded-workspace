# Phase 2C-F53: InputBlocker Coverage Canary Report

## Result

`F53_INPUTBLOCKER_COVERAGE_CANARY_READY_FOR_USER_TEST`

F53 is a bounded `0.2.39` development canary. It changes only the InputBlocker
rect after vanilla Desktop initialization, then records one old-area guard and
one expanded-area attempt.

## Evidence And Runtime Delta

F51 measured the InputBlocker effective maximum as `(15000,15000)` while the
expanded pointer was approximately `(15740-15763,18394-18496)`. F53 shifts the
same `20000 x 20000` coverage to the modded workspace rect:

```text
InputBlocker position: Vector2.ZERO
InputBlocker size: WorkspaceAreaConfig.get_workspace_size()
expected global rect: Rect2((0,0), (20000,20000))
```

The deferred one-shot function verifies that InputBlocker is a direct Desktop
child and that the workspace size is `(20000,20000)`. It logs `[F53] C0` before
and after the correction. A mismatched actual rect restores the original local
position and size, records `BLOCKED`, and applies no alternative geometry.

SelectionPanel is not registered or edited. F53 retains the existing vanilla
`InputBlocker -> SelectionPanel` signal route. It adds no Camera guard, Main2D
routing change, Desktop input consumption, event forwarding, selection logic,
save change, WindowContainer extension, or `get_position_snapped` override.

## Static Audit

| Check | Result |
|---|---|
| Runtime base | PASS: branch created directly from `d168ad8` F51 runtime canary. |
| Coverage target | PASS: one `input_blocker.position = Vector2.ZERO` and one `input_blocker.size = workspace_size`. |
| Workspace value | PASS: `WorkspaceAreaConfig.MODDED_WORKSPACE_SIZE` and `get_workspace_size()` require `(20000,20000)`. |
| SelectionPanel extension / override | PASS: no `selection_panel.gd` extension path or override. |
| Camera/Main2D behavior mutation | PASS: no new Camera/Main2D change; existing F51 passive observers retained. |
| New behavior mutation | PASS: one deferred InputBlocker position/size correction only. |
| Old-area guard | PASS: enforced as the first user-test gate before expanded interpretation. |
| Source / ZIP forbidden paths | PASS: none. |

## Artifact

| Item | Value |
|---|---|
| Path | `dist/Nekochan-ExpandedWorkspace-0.2.39.zip` |
| Size | `19,138` bytes |
| File count | `15` |
| ZIP root | `mods-unpacked` |
| SHA-256 | `2baed5a8214fcd06522eac2afb044f09f251e247096df49cf5b68f44cf3aae8d` |
| Manifest version | `0.2.39` |

The ZIP is ignored and untracked. It contains no forbidden path or file type,
and contains the one F53 position assignment and one F53 size assignment.

## User Test Steps

1. Install only `Nekochan-ExpandedWorkspace-0.2.39.zip`; confirm one Mod and manifest `0.2.39`.
2. In the old area, Shift+drag around two or three selectable nodes. Require rectangle YES, nodes selected YES, and Camera moved NO.
3. Only when the guard passes, repeat once in the expanded area beyond the old `10000` boundary.
4. Confirm the post-correction InputBlocker rect, pointer inclusion, InputBlocker/SelectionPanel reachability, Camera result, rectangle, and selected nodes using `[F53]` C0-C7.
5. Confirm normal click selection and empty-click deselection. Do not save after a failure.

## Classification And Next Action

Use `F53_INPUTBLOCKER_COVERAGE_CANARY_PASS` only when the coverage proof, old
guard, expanded route, rectangle, node selection, and Camera conditions all
pass. An old-guard failure blocks expanded success.

Next action: user installs only `0.2.39`, performs the guard then the expanded
target, and provides visual results with `[F53]` lines.

`AGENTS.md` and `docs/HANDOFF.md` have pre-existing user edits. They are not
staged, committed, or overwritten by F53.

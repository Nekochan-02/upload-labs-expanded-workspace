# Phase 2C-F53: InputBlocker Coverage Canary Report

## Result

`F53_INPUTBLOCKER_COVERAGE_CANARY_PASS`

F53 is a bounded `0.2.39` development canary. It changed only the InputBlocker
rect after vanilla Desktop initialization. The canonical old-area guard and the
first expanded-area target both passed.

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

## User Test Result

Only `Nekochan-ExpandedWorkspace-0.2.39.zip` loaded, with manifest `0.2.39`.

| Check | Result |
|---|---|
| `C0_COVERAGE_APPLY` | PASS: actual global rect was `Rect2((0,0), (20000,20000))`. |
| Old-area guard | PASS: rectangle `true`, nodes selected `true`, Camera moved `false`. |
| First expanded target | PASS: pointer inside InputBlocker; InputBlocker and vanilla SelectionPanel reached; Camera moved `false`; rectangle and nodes selected `true`. |
| Expanded classification | PASS: `F53_INPUTBLOCKER_COVERAGE_CANARY_PASS`. |
| Normal click selection | User-confirmed PASS. |
| Empty-click deselection | User-confirmed PASS. |

The retained F51 observer also recorded expanded attempts after the canonical
target. Attempt `3` recorded Camera movement while still recording rectangle
and node selection; attempts `4` and `5` passed again. These occurred after
the required target sequence, and the user observed no range-selection or
normal-selection failure. Record this as diagnostic telemetry spillover, not a
coverage-canary stop condition. Future diagnostic cleanup may make the observer
strictly single-target; no cleanup is implemented by F53.

## Classification And Next Action

The coverage proof, old guard, expanded route, rectangle, node selection,
Camera condition, normal click selection, and empty-click deselection passed.
An old-guard failure would have blocked expanded success.

Next action: prepare a docs-only diagnostic-cleanup / clean-integration re-entry
plan. Do not implement cleanup or clean integration from this report.

`AGENTS.md` and `docs/HANDOFF.md` have pre-existing user edits. They are not
staged, committed, or overwritten by F53.

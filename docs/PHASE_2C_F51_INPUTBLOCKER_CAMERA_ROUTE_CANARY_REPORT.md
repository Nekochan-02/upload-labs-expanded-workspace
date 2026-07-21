# Phase 2C-F51: InputBlocker / Camera Route Canary Report

## Result

`F51_INPUTBLOCKER_CAMERA_ROUTE_CANARY_READY_FOR_USER_TEST`

F51 is a bounded `0.2.38` diagnostic artifact. It is observation only; it does
not implement a range-selection fix.

## Evidence And Runtime Delta

| Item | Result |
|---|---|
| Branch base | `495c465` (`0.2.29`), confirmed ancestor. |
| SelectionPanel extension registration | Absent. |
| SelectionPanel logic / `_process()` edit | Absent. |
| Passive Desktop observation | Two ordered attempts, InputBlocker state/geometry/hit observation, and old-area guard evaluation. |
| Passive Main2D observation | GUI and unhandled pointer-route reachability before vanilla `super`. |
| Passive Camera observation | Pointer-route reachability and before/after position comparison around vanilla `super`. |
| Behavior mutation | None intended: no input consumption/forwarding, Camera guard, InputBlocker geometry mutation, Main2D routing mutation, or SelectionPanel override. |

F51 emits bounded `[F51]` checkpoints `B0` through `B10`. The old-area guard
is first; a failed guard emits `EXPANDED_ROUTE_OLD_AREA_GUARD_FAILED` and blocks
expanded-result interpretation.

## Static Audit

| Check | Result |
|---|---|
| Base is `495c465` descendant | PASS |
| Manifest version | PASS: `0.2.38` |
| SelectionPanel extension registration / edit | PASS: absent |
| InputBlocker behavior or geometry mutation | PASS: absent |
| Main2D/Desktop/Camera behavior mutation | PASS: absent; observation wrappers delegate to vanilla `super` where applicable |
| Range-selection fix / save schema / WindowContainer / `get_position_snapped` | PASS: absent |
| `git diff --cached --check` | PASS |

## Artifact

| Item | Value |
|---|---|
| Path | `dist/Nekochan-ExpandedWorkspace-0.2.38.zip` |
| Size | `18,489` bytes |
| File count | `15` |
| ZIP root | `mods-unpacked` |
| SHA-256 | `8e1c4bdd993b27a309a4631deaf1d15985321825132aea1f05b3c4eb796980f1` |
| Manifest version inside ZIP | `0.2.38` |
| Mod identity inside ZIP | `Nekochan-ExpandedWorkspace` |

## Publish Safety Audit

`0` forbidden ZIP entries: vanilla-verbatim body, substantial vanilla-derived
code, third-party copied code, game binary, game asset/resource, save file,
secret, and forbidden path. The ZIP contains the F51 Camera observer and does
not contain `selection_panel.gd`.

## User Test Status

| Test | Result |
|---|---|
| Old-area guard | NOT TESTED |
| Expanded-area route target | NOT TESTED |
| Route classification | `EXPANDED_ROUTE_DIAGNOSTIC_NOT_YET_RUN` |

## User Test Steps

1. Install only `Nekochan-ExpandedWorkspace-0.2.38.zip` and confirm single Mod / manifest `0.2.38`.
2. First in the old area, hold Shift for about 0.5 seconds and drag around two or three selectable nodes.
3. Confirm rectangle appeared YES, nodes selected YES, and camera moved NO.
4. Only if that guard passes, repeat once in the expanded area.
5. Do not save after failure. Exit and collect `[F51]` lines from game and Mod Loader logs.

## Classification And Next Action

Future evidence may classify hidden, out-of-bounds, mouse-filter, tool-state,
Main2D-to-Camera, Camera-when-GUI-misses, guard-failure, or inconclusive
outcomes. No such conclusion is made before the user test.

Next action: install only `0.2.38` and run the old-area guard followed by the
expanded-area route diagnostic.

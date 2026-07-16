# Phase 2C-F18: F12 Group Persistence Re-entry Gate Plan

## Status

`REENTRY_PLAN_REQUIRED`

This is a planning-only gate. Do not modify runtime code, build an artifact,
run the game, push, publish, tag, or operate on v0.2.9 in F18.

## Verified Prerequisites

- F6 single-node exact local persistence: verified.
- F7 vanilla-density grid restoration: verified.
- F9 click local alignment: verified.
- F11 drag local alignment: verified.
- F14 primary group-resize old-bound snap: verified.
- F17 top-right and childless right-side width-collapse correction: verified.

F17 demonstrates that the known group resize blockers which interrupted F12
are corrected on the required top-right and right-side paths. It does not make
F12 group persistence a PASS result.

## F12 Interruption History

F12 stopped at `F12_INTERRUPTED_BY_GROUP_RESIZE_BLOCKER`. The blocker sequence
was subsequently resolved as follows:

1. F13 classified the disappearing frame as `GROUP_NODE_MOVED_OUT_OF_BOUNDS`.
2. F14 verified the resize-only expanded-bound position snap on the primary
   path.
3. F15 classified populated top-right width collapse as
   `GROUP_SIZE_WIDTH_COLLAPSED`.
4. F17 verified post-vanilla width correction on top-right and childless right
   paths.

F12 must now return only to persistence evidence, not repeat resize testing.

## Git Topology

- F18 branch: `dev/phase-2c-f18-f12-group-persistence-reentry`
- F17 verified base: `09358c6a64a35aa4b90f5f81809f86bbceb1e7f3`
- `origin/master`: `0489e834bb1eff79742081f32656ee43f04a2cb5`

No reset, rebase, amend, history rewrite, force push, public-master merge, or
push is permitted.

## F12 Diagnostic Validity Review

| Review item | Result |
|---|---|
| F12 diagnostic code still exists | YES |
| Current source path | `extensions/scripts/desktop.gd` |
| Last runtime-source change | `bfcc63a Add F12 group persistence diagnostic canary` |
| Frame saved/restored local position evidence | YES |
| Contained child saved/restored local evidence | YES, one or two children |
| Relative-layout delta evidence | YES |
| Membership evidence | YES, frame containment at every checkpoint |
| Connection/state signal | Limited connector count plus user visual check |
| F14/F17 conflict during final F12 save/load phase | NO |
| F12 obsolete assumption from v0.2.19 | NO material runtime assumption found |

F12 retains one selected saved expanded-area group, bounded G1-G11 checkpoints,
one deferred checkpoint, and one 0.5-second opening-settle checkpoint. It has
no `_process()` monitor and does not mutate the F6 correction path. F17 changed
only `window_group.gd`; it did not alter this F12 source.

## Re-entry Path Decision

**Option A: use current `0.2.24` for the F12 group persistence re-entry test.**

`0.2.24` already packages the unchanged F12 diagnostic, F6 correction, and
verified F14/F17 resize handling. The required setup resize uses only a verified
`top-right` or `right` edge before any child is placed; after setup, the
persistence test performs no group resize. F14/F17 therefore do not create
target or logging ambiguity during the save/load observation phase.

**Option B: do not create `0.2.25` now.** A new artifact is unnecessary because
there is no F12 source change to version, re-arm, or isolate. A future artifact
would be required only if live F12 logs prove ambiguous or stale.

## Future User Test Proposal

Use only `Nekochan-ExpandedWorkspace-0.2.24.zip` in a temporary test state.

1. In the expanded area, create one empty group frame. Before adding children,
   resize it with only verified `top-right` or `right` until two nodes fit.
2. If the setup resize collapses, jumps, or disappears, do not save; stop and
   classify it as an F14/F17 resize regression rather than F12 evidence.
3. Place exactly two fully enclosed nodes and add one connection if practical.
4. Do not resize the group or perform unnecessary group movement after nodes
   are placed.
5. Save, exit, restart, and load the same save.
6. Check frame absolute position, both child absolute positions, child-to-frame
   layout, group membership/selectability, and connection/state.
7. Exit and collect `[F12]` G1-G11 and related `[F6]` lines.

Expected observations: exact frame and child local restoration, zero child
relative delta, preserved membership, no double movement, and no old-boundary
jump.

## Stop Conditions

Stop without a persistence fix, regression work, or release work if any of the
following occurs:

- frame or child jumps to the old boundary;
- saved local or relative layout differs after correction or stability;
- membership, connection/state, or selectability is lost or ambiguous;
- double movement is detected;
- F14/F17 appears to interfere with persistence;
- the required setup resize collapses, jumps, or disappears before save;
- a save mutation, WindowContainer patch, `get_position_snapped()` override,
  or large vanilla function copy appears necessary.

## Next Recommended Action

Request approval to run the Option A `0.2.24` F12 persistence re-entry test.
Do not implement a group persistence repair, full regression, release
integration, public push, Release/tag/Workshop operation, or v0.2.9 artifact
change.

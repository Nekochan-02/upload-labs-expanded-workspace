# Phase 2C-F18: F12 Group Persistence Re-entry Gate Plan

## Status

`F12_GROUP_PERSISTENCE_REENTRY_VERIFIED_POST_F17`

F18 was a planning-only gate before the separately approved user test. Its
adjusted `0.2.24` re-entry test is now verified below. Do not modify runtime
code, build an artifact, run full regression, push, publish, tag, or operate
on v0.2.9 in this phase.

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

## Execution Result

The user ran Option A with only `Nekochan-ExpandedWorkspace-0.2.24.zip`.
The empty group was first enlarged through verified `top-right` setup resize;
no collapse occurred. After two children and one connection were placed, no
further resize or unnecessary group movement occurred before save/load.

Actual `[F12]` G1-G11 and related `[F6]` lines show the frame restored from
old-clamped `(9000, 9250)` to saved `(18450, 18450)`, and both children restored
to their exact saved locals. Child saved-relative offsets `(100, 150)` and
`(500, 250)` have zero relative delta after correction, at next deferred, and
at opening settle. Membership is true and `connector_count=1` at each of G6,
G8, and G10. No F12 stop or double movement evidence was recorded.

The user separately verified frame/child positions, relative layout,
membership, connection/state, and group selectability after load. Therefore
the narrow result is `F12_GROUP_PERSISTENCE_REENTRY_VERIFIED_POST_F17`.

This result does not authorize full regression, release integration, public
master push, Release/tag/Workshop operation, or v0.2.9 artifact work.

## Next Recommended Action

Prepare only a post-F12 scope-decision plan that explicitly keeps full
regression and release integration deferred until separately approved. Do not
implement a group persistence repair, run full regression, integrate for
release, push publicly, operate Release/tag/Workshop, or change v0.2.9.

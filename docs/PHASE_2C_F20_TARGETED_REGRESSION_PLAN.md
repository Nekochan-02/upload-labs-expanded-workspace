# Phase 2C-F20: Targeted Regression Plan

Status: `F20_TARGETED_REGRESSION_PASS_WITH_OPEN_RC_GATES`

This is a docs-only targeted-regression plan. It does not execute tests or
authorize runtime code changes, artifact generation, builds, diagnostic cleanup
implementation, version changes, push, merge, tag, GitHub Release, Workshop
publication, history rewrite, rebase, amend, reset, or force push.

## Purpose

Define the shortest evidence-focused regression pass needed to decide whether
the verified fixes can proceed to clean integration planning. The purpose is to
find user-visible failures on high-risk paths, not to exhaustively validate the
expanded workspace.

The current execution candidate is the diagnostic-heavy `0.2.24` development
canary, `Nekochan-ExpandedWorkspace-0.2.24.zip`. It is not a clean release
candidate. Targeted regression execution requires separate user approval.

## Evidence Baseline

The following results are already verified and are the baseline that this plan
must protect:

| Area | Status |
|---|---|
| F6 single-node exact local persistence | `VERIFIED` |
| F7 vanilla-density grid restoration | `VERIFIED` |
| F9 click placement local alignment | `VERIFIED` |
| F11 drag placement local alignment | `VERIFIED` |
| F14 group resize old-bound snap | `VERIFIED` |
| F17 top-right group resize width-collapse | `VERIFIED` |
| F17 right-side childless group resize width-collapse | `VERIFIED` |
| F12 group persistence post-F17 | `VERIFIED` |

Earlier `0.2.9` evidence also verified existing-node movement and group
selection movement across the old boundary. F20 retests those paths because
later persistence and resize changes may have regressed them.

## Artifact and Execution Boundary

| Item | Current status |
|---|---|
| Planned test artifact | `0.2.24` development canary |
| Artifact classification | Verified but diagnostic-heavy development artifact |
| Artifact size | `22115 bytes` |
| SHA-256 | `942f67e0e0535b208a6ecc67d1d13cd9baf714035a8471dcdad55926373e7e7c` |
| F20 execution | User-run on `0.2.24`; high-risk targeted paths passed with no Mod stop condition |
| Clean RC execution | Required later, after clean integration creates a new artifact |

The first execution, if approved, should use `0.2.24` to avoid changing
verified runtime behavior before cross-path regression evidence exists. After
diagnostic cleanup and clean integration, the resulting clean RC must repeat a
clean-install smoke check and the required RC subset below.

## Targeted Regression Scope

| Test item | Classification | Minimum evidence | Failure outcome |
|---|---|---|---|
| Clean install with only one active mod zip | Required before clean integration | Loader sees only the intended canary; no stale parallel mod zip is active | Stop; correct installation state before interpreting any result. |
| Basic startup and loader log review | Required before clean integration | Game and mod load; no loader error or extension installation failure | Stop; return to the responsible loading/registration phase. |
| Primary line-grid visual smoke and old-bound seam | Targeted regression | Vanilla-density primary grid remains continuous across old boundary | Stop for visible seam/density regression; return to F7. |
| Click placement in expanded area | Required before clean integration | One click-created node appears at the intended expanded-area local position | Stop; return to F9. |
| Drag placement in expanded area | Required before clean integration | One drag-created node appears at the intended expanded-area local position | Stop; return to F11. |
| Manual existing-node movement across old boundary | Required before clean integration | Existing node crosses old boundary without snap-back or jump | Stop; return to the movement phase owning the regression. |
| Selection and deselection | Required before RC | Empty-area deselect, menu-close deselect, single, multi, and group selection behave normally | Stop; do not continue persistence or resize checks. |
| Single-node save/load persistence | Required before clean integration | Save, exit, restart, and load retain an expanded-area node's exact local position | Stop; return to F6/F12 restoration ownership. |
| Group top-right and right resize smoke | Required before clean integration | One populated top-right resize and one childless right resize avoid old-bound jump and width collapse | Stop; return to F14/F17. |
| Group save/load persistence | Required before clean integration | Frame and children retain local positions, relative layout, membership, and visible connection/state after restart/load | Stop; return to F12. |
| Group movement across old boundary | Targeted regression | Group frame and children cross together without desynchronization | Stop; return to the group movement phase. |
| Node limit 1000 smoke | Required before RC | Existing extended node-limit path still accepts the intended high-count/near-limit operation | Stop; return to the node-limit implementation phase. |
| Space upgrade cap 200 smoke | Required before RC | UI cap and purchase behavior still allow the intended `200` cap | Stop; return to the space-upgrade implementation phase. |
| Connection/state preservation after group save/load | Targeted regression | At least one group connection and member state survive the group persistence check | Stop; treat as group persistence failure and return to F12. |
| Connector-point movement smoke | Targeted regression (optional) | One connector point can be adjusted in expanded area without old-bound clamp | Stop only when executed; return to connector-point scope. |

Each item is a small smoke scenario. Do not turn F20 into a long-running,
exhaustive play session.

## Required Test Order

1. Verify a clean install with only one active Mod zip.
2. Start the game and confirm no loader errors.
3. Inspect the primary line grid and the old-boundary seam.
4. Create one node by click placement in the expanded area.
5. Create one node by drag placement in the expanded area.
6. Move one existing node across the old boundary.
7. Confirm selection and deselection behavior.
8. Save, exit, restart, and load the single-node placement.
9. Set up a group; smoke-test top-right and childless-right resize.
10. Save, exit, restart, and load the group; verify relative layout and one connection/state.
11. Move the group across the old boundary.
12. Run short node-limit `1000` and space-upgrade-cap `200` smoke checks.
13. Run one connector-point movement smoke only if time permits and no prior
    stop condition occurred.

The clean installation and startup gates are first because a result from an
ambiguous mod set or failed extension load is not valid regression evidence.
Selection precedes persistence and resize because an uncleared selection can
contaminate the later scenarios. Group movement follows the group persistence
check to keep the group setup and state evidence together.

## Required Before Clean Integration

The following must pass on approved `0.2.24` targeted regression before
planning runtime diagnostic cleanup:

1. Clean install and loader-error gate.
2. Primary grid/seam smoke.
3. Click placement, drag placement, and existing-node movement across the old
   boundary.
4. Single-node save/load persistence.
5. Group top-right/right resize smoke.
6. Group save/load persistence, relative layout, and connection/state
   preservation.

Group movement remains targeted regression rather than a prerequisite for the
cleanup plan because it already has earlier verification evidence, but any
observed regression is an immediate stop condition.

## Required Before RC

Before release-candidate decision, require all clean-integration gates plus:

1. Selection and deselection smoke.
2. Group movement across the old boundary.
3. Node limit `1000` smoke.
4. Space upgrade cap `200` smoke.
5. A clean install and basic startup smoke on the future clean RC artifact.

The clean RC must not inherit the `0.2.24` diagnostic-heavy classification.
Release, tag, push, and Workshop decisions remain separate user-authorized
operations after those results are reviewed.

## Known Limitations and Deferred Items

| Item | Classification | Rationale |
|---|---|---|
| Template / schematic paste in expanded area | Known limitation | Keep non-blocking unless an easy single paste smoke is explicitly added; no broad paste-path work is authorized by F20. |
| Group resize all-edge matrix | Defer | Current evidence targets old-bound and right/top-right risks; exhaustive edge coverage is disproportionate to this pass. |
| Bottom / bottom-right height-collapse equivalent | Defer, targeted optional | Run only if right/top-right smoke indicates symmetry risk or a tester observes height behavior. |
| Connector-point movement full verification | Defer | One optional smoke is enough for F20; no full interaction matrix. |
| Large save / many-node performance | Defer | Requires dedicated performance criteria and is not a short regression gate. |
| Long-running performance | Defer | Not observable in the intended short pass. |
| Non-primary grid modes | Known limitation | F7 verifies the primary line-grid mode; other renderer modes are not release-gated by F20. |
| Exhaustive group resize after save/load matrix | Defer | F20 verifies one representative group setup and persistence path only. |

None of these classifications authorizes new runtime work. A failure in an
optional test must be recorded as a scope decision before any code change.

## Stop Conditions

Stop the targeted regression immediately and do not stack additional fixes if
any of the following occurs:

- The game or mod fails to load, or loader errors appear.
- Selection cannot be cleared.
- Click or drag placement misaligns in the expanded area.
- A node jumps or snaps back to the old boundary.
- Single-node or group save/load persistence fails.
- Group relative layout, membership, connection, or state breaks.
- The old-bound group-resize jump or width collapse returns.
- The `1000` node limit or `200` space-upgrade cap no longer works.
- Save-data corruption is suspected.

After a stop, preserve the observed evidence, record the failing scenario, and
return to the phase that owns the regression. Do not continue the remaining
matrix, implement a quick fix, perform cleanup, or prepare a release artifact
within the same regression run.

## Diagnostic Cleanup Relationship

F20 does not implement cleanup. It uses the current diagnostic-heavy canary
only to establish whether the high-risk paths remain stable before removing
observability.

The subsequent clean-integration plan must remove or explicitly gate the
following diagnostics after the approved targeted regression result is
recorded:

- F6, F9, F11, F12, F13, F14, F15, and F17 logs.
- Temporary drag-placement and group-resize observers.
- Diagnostic target-acquisition flags.
- Canary-specific loader text.

After cleanup produces a new clean RC artifact, repeat the clean-install,
startup, placement, persistence, and selected resize smoke checks that are
required before RC. That second pass validates the cleanup integration, not the
original `0.2.24` diagnostics.

## Next Decision Gate

Clean integration planning may begin only after the user approves and records
the `0.2.24` required-before-clean-integration scenarios as passing, with no
stop condition. Any observed failure takes priority over cleanup planning.

## Execution Record

The user executed F20 on `0.2.24` and reported PASS for startup, grid and
camera, click and drag placement, existing-node movement, selection,
single-node persistence, group resize, group persistence including one
connection/state, and the node-limit `1000` smoke. The diagnostic evidence
supports the targeted placement, persistence, grid, and top-right resize paths.

No F20 stop condition attributable to the Mod was observed. The `space` cap
`200` UI/purchase smoke subsequently passed. Group movement remains required
before RC. Template / schematic pre-placement at the old boundary is now a confirmed known
limitation. See `docs/PHASE_2C_F20_TARGETED_REGRESSION_REPORT.md` for the
full evidence and constraints.

## Explicit Non-Actions

F20 does not change runtime code, generate or replace artifacts, build, run
tests, clean diagnostics, bump a version, push, merge, tag, create a Release,
publish to Workshop, rebase, amend, rewrite history, reset, or force push.

# Phase 2C-F17: Right-Side Group Resize Collapse Targeted Canary Plan

## Status

`PLAN_REQUIRED`

## F15 Root Cause Evidence

F15 classified the populated `top-right` failure as
`GROUP_SIZE_WIDTH_COLLAPSED`. At a left anchor of `13900` and zero mouse delta,
the vanilla old-bound right-edge calculation derived `10000 - 13900 = -3900`.
The first resize process set `custom_minimum_size.x=-3900` and frame width
became `20`; the independently derived expanded candidate remained valid at
`(800,650)`.

Children, their local/global geometry, relative bounds, and the user-observed
connection/state remained intact. The blocker is therefore a right-side size
calculation residue, not child layout, save/load, F14 position snap, or mouse
coordinate conversion.

## F16 Handling

F16 is not accepted as a top-right verification. Its bounded target was
consumed by the first eligible `top-left` resize, whose candidates and actual
size were valid and whose correction was correctly false. No F16 checkpoint
exists for the later `top-right`, `right`, `bottom-right`, or `bottom` resize.

The user still observed collapse on top-right/right-side paths, including a
group without children. This strengthens the root-cause scope but does not
prove F16's correction result on the intended path because it was not armed or
logged there.

## Remaining Blocker

`RIGHT_SIDE_GROUP_RESIZE_WIDTH_COLLAPSE_UNVERIFIED_FIX`

Right/top-right resize beyond the old boundary remains a release blocker. F14
continues to solve the separate left/top position-snap jump and must remain
unchanged.

## Required Design Separation

F17 must separate these concerns:

1. **Correction activation:** evaluate the existing right/bottom old-bound
   invalid versus expanded-bound valid guards for every matching active group
   resize. It must not depend on F15/F17 logging-target acquisition.
2. **Diagnostic logging:** capture only one user-requested target edge per
   session. The primary target is `top-right`; `right` is the only secondary
   target. `bottom-right` and `bottom` remain future optional targets.

If top-left is resized first, it must neither arm nor consume the F17 target.
Valid resize results remain untouched even when correction activation is
evaluated.

## Future Implementation Constraints

The future F17 implementation may alter only the existing `WindowGroup`
extension. It must:

- retain F14's resize-only `move_snapped(to)` branch unchanged;
- retain the F16 post-vanilla correction guards and apply mutation only when
  the old candidate is invalid and expanded candidate is valid;
- detach correction activation from the F15 static target flag;
- filter F17 logs to the selected right-side edge and one group/sequence;
- never add a WindowContainer/Base/Indexed extension, global snap override,
  vanilla resize-body copy, child mutation, membership change, or save-schema
  change.

No F17 implementation is approved by this plan.

## Future Artifact Proposal

- Version: `0.2.24`
- Filename: `Nekochan-ExpandedWorkspace-0.2.24.zip`
- Purpose: target the right-side group resize width-collapse path only.
- Status: future local development canary; not a Release, Draft Release, tag,
  Workshop artifact, or replacement for v0.2.9.

## Future User Test Proposal

Use a temporary state and install only `0.2.24`.

1. Move to the expanded area and create one group beyond the old boundary.
2. Put exactly two nodes inside and add one connection if reproducing the
   populated path.
3. Use `top-right` first. Do not touch top-left before it.
4. Start resize with little or zero mouse delta, then drag slightly and release.
5. Confirm frame width remains normal, minimum width is non-negative, the frame
   stays valid/visible, and children plus connection/state remain.
6. Do not save after failure. Exit and provide `[F17]` logs.

The optional secondary test is a childless `right` resize. Do not test all
edges, save/restart, group persistence, full regression, or release work.

## Expected Future Pass

The targeted top-right/right sequence must show a non-negative
`custom_minimum_size.x`, a width other than `20`, a correction decision when
the old candidate is invalid and expanded candidate valid, no old-bound jump,
and no child/state regression. No top-left interaction may appear in F17 target
logs.

## Stop Conditions

Stop without stacking a fix if correction still requires F15 target acquisition,
top-left can consume the target, right-side logs are absent, valid resize is
mutated, childless right-side collapse follows a different path, or a vanilla
body copy, `get_position_snapped()` override, WindowContainer patch, or save
schema change becomes necessary.

Release integration, group persistence continuation, full regression, public
master push, Release/tag/Workshop actions, and v0.2.9 artifact changes remain
deferred.

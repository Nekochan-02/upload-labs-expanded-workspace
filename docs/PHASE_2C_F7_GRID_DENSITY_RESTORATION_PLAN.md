# Phase 2C-F7 Vanilla-Density Grid Restoration Plan

Status: `ANALYSIS_AND_CANARY_APPROVED`

## User Observation and F6 Preservation

The current expanded workspace shows a visibly coarser grid than vanilla. The Mod scales the vanilla `Lines` renderer by `(2, 2)`, so the vanilla 50-unit visual spacing becomes 100 units while placement and movement continue to snap at 50 units. F7 restores the visual geometry; it must not alter F6 restoration behavior, saved positions, selection, placement, movement, group handling, or any snap interval.

F6 remains verified for individual-node exact local persistence. The Desktop restoration extension is outside F7 scope and must not change.

## Vanilla and Current Geometry

| Geometry | Vanilla | Current Mod |
|---|---:|---:|
| Workspace | `10000 x 10000` | `20000 x 20000` |
| Lines scale | `(1, 1)` | `(2, 2)` |
| Lines/circles/crosses interval | `50` | visually `100` |
| Lines major interval | `500` | visually `1000` |
| Window placement and movement snap | `50` | `50` |
| Connector snap | `25` | `25` |
| Renderer coverage before node transform | `10000 x 10000` | `10000 x 10000` |

`scripts/lines.gd` does not use `Control.size` to determine generated geometry. It hard-codes `10000`, loop counts, and instance counts inside each builder. Therefore enlarging `Desktop/Lines.size` alone cannot create vanilla-density coverage across the expanded area.

## Vanilla Generation and Instance Counts

| Lines type | Vanilla formula | Vanilla instances | Four-tile F7 instances |
|---|---|---:|---:|
| Lines | `200 horizontal + 200 vertical` | `400` | `1600` |
| Circles | `201 x 201` | `40401` | `161604` |
| Diagonal | `(int((10000*2)/50)+10) x 2` | `820` | `3280` |
| Crosses | `200 x 200` | `40000` | `160000` |
| Hexagons | `232 x 268` | `62176` | `248704` |
| Starfield | fixed | `5000` | `20000` |

The F7 multiplier is exactly 4x for a workspace with 4x area. This is a known canary performance risk, especially for hexagons, but not an unexpected multiplier. No benchmark is claimed in this phase.

## Candidate Comparison

| Candidate | Result |
|---|---|
| A. Regenerate all builders to 20000 | Rejected: requires replacing substantial vanilla generation bodies for all renderer modes. |
| B. Remove scale only | Rejected: restores density in the first 10000 square but leaves expanded coverage incomplete. |
| C. Tile/repeat vanilla-density output | Selected implementation shape. Preserves 50-unit origin and interval without regenerating vanilla bodies. |
| D. Duplicate renderer nodes | Selected only as fresh runtime instances, not `duplicate()`, to avoid copying live RID state. |

## Selected Strategy

The root `Lines` control remains the `(0, 0)` tile and is set to scale `(1, 1)`. The extension creates three fresh `Control` children at `(10000, 0)`, `(0, 10000)`, and `(10000, 10000)`, assigns the same self-authored extension script before adding them to the tree, and marks them as F7 tiles before `_ready()`.

Each fresh child invokes the vanilla renderer through inheritance and builds a separate 10000-unit grid in its own coordinate space. This creates a 20000 x 20000 tiled coverage area, preserves origin alignment at multiples of 10000 (and therefore 50), and contains no copied vanilla script body, scene, resource, or asset.

`duplicate()` is prohibited because copied script state could include live RenderingServer RID values. The F7 tiles must be fresh Controls.

## F7 Logging

The root renderer logs once at startup:

```text
[F7][GRID]
workspace_size
renderer_scale
minor interval / geometry label
origin
coverage
tile count
per-tile and total instance counts
```

Tiles do not emit duplicate F7 logs. No per-frame logging is permitted.

## Static Criteria

- F6 Desktop restoration code: unchanged.
- Placement, movement, connector snap, selection, group, save schema, node limit, and space cap: unchanged.
- WindowContainer/Base/Indexed extension: absent.
- Root and tiles renderer scale: `(1, 1)`.
- Coverage: `20000 x 20000` via four 10000-unit tiles.
- Lines/circles/crosses visual interval: 50 world units; major lines: 500 world units.

## Stop Conditions

Stop without a replacement canary if runtime tiling requires copied vanilla bodies, a vanilla scene/resource package, changes snap intervals, shifts origin, leaves coverage incomplete, regresses F6 persistence or selection, or produces a clearly unsafe instance multiplier beyond the documented 4x geometry multiplier.

## Delivery Boundary

F7 is version `0.2.14`, development canary only. It may create `Nekochan-ExpandedWorkspace-0.2.14.zip`, but no Release, Draft Release, tag, Workshop publication, public-master push, or v0.2.9 artifact operation is allowed. User verification is required for all visual results.

# Phase 2C-F7 Vanilla-Density Grid Restoration Report

Status: `F7_CANARY_READY_FOR_USER_TEST`

## Root Cause

The previous Lines extension applied `(2, 2)` scale to a vanilla renderer that generates 50-unit geometry over a fixed 10000-unit range. The scale doubled visual grid spacing to 100 while window placement and movement remained snapped at 50. This is the confirmed `GRID_DENSITY_SCALE_MISMATCH` and its `SNAP_INTERVAL_MISMATCH` consequence.

## Vanilla and F7 Geometry

| Geometry | Vanilla | F7 canary |
|---|---:|---:|
| Workspace | `10000 x 10000` | `20000 x 20000` |
| Renderer scale | `(1, 1)` | `(1, 1)` |
| Lines/circles/crosses interval | `50` | `50` |
| Lines major interval | `500` | `500` |
| Origin | `(0, 0)` | `(0, 0)` in each 10000-unit tile |
| Window placement and movement snap | `50` | unchanged at `50` |
| Connector snap | `25` | unchanged at `25` |
| Coverage | `10000 x 10000` | four tiles covering `20000 x 20000` |

The root renderer occupies `(0, 0)`. F7 creates fresh renderer Controls at `(10000, 0)`, `(0, 10000)`, and `(10000, 10000)`. Every tile boundary is a multiple of 50, so the tiled origin remains aligned with vanilla snap geometry.

## Candidate Decision

- Regenerating the vanilla geometry to 20000 was rejected because all renderer modes hard-code their own generation loops and instance counts; overriding them would require substantial vanilla body copying.
- Removing scale without additional renderers was rejected because coverage would stop at 10000.
- F7 selected fresh runtime renderer tiles. It does not duplicate live nodes or RIDs, package a scene/resource, or copy vanilla builder bodies.

## Performance Estimate

| Lines type | Vanilla instances | F7 instances | Multiplier |
|---|---:|---:|---:|
| Lines | `400` | `1600` | `4x` |
| Circles | `40401` | `161604` | `4x` |
| Diagonal | `820` | `3280` | `4x` |
| Crosses | `40000` | `160000` | `4x` |
| Hexagons | `62176` | `248704` | `4x` |
| Starfield | `5000` | `20000` | `4x` |

The multiplier matches expanded workspace area. Hexagons are the highest-cost mode and require user-observed startup and update behavior before any broader adoption. No benchmark or gameplay performance PASS is claimed.

## Runtime Delta

- `extensions/scripts/lines.gd`: uses vanilla scale and creates three fresh F7 runtime tiles; emits one startup `[F7][GRID]` line with selected geometry and calculated instance count.
- `extensions/scripts/workspace_area_config.gd`: removes the obsolete render-scale constant.
- `manifest.json` and `mod_main.gd`: update development canary version and wording.

No F6 Desktop restoration, placement, movement, connector, selection, group, save, node-limit, space-cap, camera, or background code changed.

## F6 Preservation

`extensions/scripts/desktop.gd` is byte-for-byte unchanged from F6 verification commit `8a1b1eb0908006588f09cb30763af3564b05644f`. F7 must still be user-tested for the F6 single-node persistence regression gate.

## Artifact

- version: `0.2.14`
- artifact type: development canary, not a public release artifact
- filename: `Nekochan-ExpandedWorkspace-0.2.14.zip`
- path: `dist/Nekochan-ExpandedWorkspace-0.2.14.zip`
- size: `12043 bytes`
- file count: `13`
- ZIP root: `mods-unpacked`
- manifest version: `0.2.14`
- SHA-256: `74043d10b5d455850be47ac0f3f7b6302f3764ec28d9ca6b4390f840256b7d49`

## Publish Safety Audit

| Detection | Count |
|---|---:|
| vanilla-verbatim body | 0 |
| substantial vanilla-derived code | 0 |
| copied vanilla scene/resource | 0 |
| third-party copied code | 0 |
| game binary | 0 |
| game asset/resource | 0 |
| save file | 0 |
| secret | 0 |
| forbidden file | 0 |

## User Verification Status

| Test | Result |
|---|---|
| Vanilla-area grid density | NOT TESTED |
| Expanded-area grid density | NOT TESTED |
| Click placement alignment | NOT TESTED |
| Drag placement alignment | NOT TESTED |
| Existing movement alignment | NOT TESTED |
| F6 exact persistence regression | NOT TESTED |
| Group persistence | NOT TESTED / out of F7 scope |

No real-game visual, performance, or regression PASS is claimed.

## Release Boundary

No GitHub Release, Draft Release, tag, Workshop upload, public-master push, or v0.2.9 artifact operation was performed. Grid, group persistence, full regression, and release integration remain separate phases.

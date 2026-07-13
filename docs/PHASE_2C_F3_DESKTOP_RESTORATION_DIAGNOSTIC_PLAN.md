# Phase 2C-F3 Desktop Restoration Diagnostic Plan

Status: `DIAGNOSTIC_APPROVED`

## Purpose

Collect runtime position checkpoint evidence from the Desktop restoration path without using any `WindowContainer`, `WindowBase`, or `WindowIndexed` Script Extension.

The diagnostic goal is to prove when a saved expanded-area window position changes to the old-boundary runtime position.

## Baseline

Runtime baseline:

- v0.2.9 runtime behavior
- plus Desktop restoration diagnostic logging only

Do not use the failed v0.2.10 runtime as the diagnostic base.

Explicit exclusions:

- no `WindowContainer` Script Extension
- no `WindowBase` Script Extension
- no `WindowIndexed` Script Extension
- no `WindowGroup` position patch addition
- no `get_position_snapped()` override
- no `_ready()` position correction
- no Script Hook fix
- no save schema change
- no restored-position mutation
- no `call_deferred()` position restoration
- no selection behavior fix

## Confirmed Vanilla Restoration Path

Upload Labs vanilla `scripts/desktop.gd` restores saved windows in `Desktop._enter_tree()`:

1. `Data.loading.desktop_data.windows`
2. ordered `for window: Dictionary in ...`
3. skip if `ResourceLoader.exists("res://scenes/windows/" + window.filename)` is false
4. find existing child by `Windows/<window.name>`
5. instantiate scene from `window.filename` if no existing child exists
6. call `new_object.load(window)`
7. call `$Windows.add_child(new_object)`
8. otherwise assign fields onto the existing object

The saved windows collection is `Data.loading.desktop_data.windows`, an Array of Dictionary values. The position field is expected to be a `Vector2` because vanilla window save/load directly stores and restores the `position` property.

Correlation method:

- Primary correlation uses saved `window.name`.
- Vanilla restoration itself looks up `Windows/<window.name>`, so name-based correlation is grounded in the real restoration path.
- Index-only correlation is not used as proof.

## Checkpoints

Desired checkpoints:

- P2: saved window data position visible before `super._enter_tree()`
- P3: direct position immediately after `new_object.load(window_data)`
- P3.5: observed child position after add-child / initialization visibility
- P4: deferred final position after restoration lifecycle settles

P3 limitation:

- Direct P3 is not observable without copying vanilla `Desktop._enter_tree()` body.
- The diagnostic must not copy that body.
- Runtime logs therefore record P3 as `UNOBSERVED` and use P3.5/P4 to prove whether the position has already changed after vanilla restoration.

## Patch Surface

Only existing file:

- `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/desktop.gd`

Allowed changes:

- add `_enter_tree()` diagnostic wrapper using `super._enter_tree()`
- snapshot target saved data before `super._enter_tree()`
- connect to `$Windows.child_entered_tree` for first observable child state
- log post-super child state
- log deferred final child state

Existing behavior to preserve:

- `Desktop._ready()` extension
- paste limit handling
- group-selection movement synchronization

## Target Filtering

Maximum diagnostic targets: `3`

Target selection:

- inspect saved windows in original saved array order
- include only windows whose saved `position` is a `Vector2`
- include only windows with `position.x > 10000` or `position.y > 10000`
- assign stable diagnostic indexes based on selected target order

The threshold is based on the vanilla workspace size used by the old window clamp. The exact vanilla maximum also subtracts window size, so this filter intentionally selects unambiguous expanded-area positions.

Logged metadata:

- diagnostic index
- saved array source index
- saved `name`
- saved `filename`
- saved position
- saved size if present
- group-window flag based on filename
- observed script resource path
- observed runtime size

Do not log full save data, local paths, or personal data.

## Diagnostic Log Shape

Expected shape:

```text
[F3][window=0][P2] source_index=... name=... filename=... saved=(...)
[F3][window=0][P3] after_load_direct=UNOBSERVED reason=no_vanilla_enter_tree_body_copy
[F3][window=0][P3.5] child_entered_tree position=(...) global=(...)
[F3][window=0][P3.5] after_super_enter_tree position=(...) global=(...)
[F3][window=0][P4] deferred_final position=(...) global=(...)
```

Do not infer the result before user runtime evidence is collected.

## Version And Artifact

- diagnostic version: `0.2.11`
- artifact: `Nekochan-ExpandedWorkspace-0.2.11.zip`
- artifact type: development diagnostic only

Forbidden operations:

- GitHub Release
- Draft Release
- tag
- Steam Workshop publish
- v0.2.9 artifact replacement
- public `master` push

## Static Verification Requirements

Before handoff:

- `WindowContainer` extension included: `NO`
- `WindowBase` extension included: `NO`
- `WindowIndexed` extension included: `NO`
- `WindowContainer` registration: `NO`
- `get_position_snapped()` override: `NO`
- restored position mutation: `NO`
- save schema mutation: `NO`
- publish safety audit: `PASS`

## User Test Scope

First verify selection regression is absent:

1. Select one node.
2. Click empty area.
3. Confirm selection clears.
4. Select one node again.
5. Press the state/options menu `x`.
6. Confirm selection clears.

Then collect position diagnostic evidence:

1. Place one single node in the expanded area.
2. Save.
3. Exit game.
4. Restart.
5. Load.
6. Confirm whether the node moved back to the old boundary.
7. After game/log close, collect F3 diagnostic log lines.

No group test, 500+ test, or full regression suite is required for this diagnostic pass.

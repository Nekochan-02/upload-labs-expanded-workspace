# Phase 2B Critical Failure Rollback

## Status

`ROLLED_BACK_TO_0.1.4`

## Affected Versions

* `0.2.0`: partial failure
* `0.2.1`: critical failure

## User-Reported 0.2.1 Symptoms

* Nodes cannot be placed.
* Nodes cannot be moved because selection no longer works.
* Existing save nodes gather in the upper-left area.
* Connections between gathered nodes are detached.
* Existing node levels are reset.
* Node upgrade costs become `1`, which should not happen in normal play.

## Immediate Recovery Action

The deployed game mod was rolled back to:

* `E:\SteamLibrary\steamapps\common\Upload Labs\mods\Nekochan-ExpandedWorkspace-0.1.4.zip`

Failed builds were moved to:

* `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.2.0.zip`
* `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.2.1.zip`

## Source Rollback

`mod_main.gd` no longer registers Phase 2B area-expansion Script Extensions.

The `desktop.gd` extension was rolled back to the Phase 2A-R3/R4 node-count wrapper behavior only.

## Save Safety Snapshot

A non-destructive copy of current Upload Labs save/config files was created at:

* `C:\tmp\upload-labs-save-backups\20260712-091954`

Observed file sizes and timestamps suggest:

* `savegame.dat`, `savegame2.dat`, and `savegame3.dat` were updated on 2026-07-12 and are small.
* `savegame1.dat` and `savegame4.dat` were updated on 2026-07-11 and are much larger.

If the active save remains corrupted after rollback, the larger 2026-07-11 save files are likely restore candidates. Do not overwrite active saves without explicit user approval.

## Post-Rollback User Result

After rollback to `0.1.4`, the user confirmed nodes can be placed again.

Existing nodes from the affected save were gone, but the user explicitly stated that this does not need to be repaired.

Therefore, do not spend further work on restoring the lost nodes unless the user asks for save recovery later.

## Likely Root Cause Direction

The `0.2.1` attempt directly extended node base classes:

* `scenes/windows/window_base.gd`
* `scenes/windows/window_indexed.gd`

This appears to be unsafe in this Mod Loader setup. It likely interferes with scene inheritance, node initialization, loaded save data, or ResourceContainer state.

## Hard Rule For Next Attempt

Do not re-enable `0.2.0` or `0.2.1`.

Do not patch `window_base.gd` / `window_indexed.gd` directly as the next area-expansion strategy.

Before another area expansion test, create a new plan that prioritizes:

* save-data protection
* a disposable test save, not the user's real active save
* one isolated patch at a time
* log inspection after each launch
* no direct base-class Script Extension of existing node scene roots

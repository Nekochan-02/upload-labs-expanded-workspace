# Phase 2A-R1 Root Cause

## Observed Failure

In the latest in-game test, the 501st node could not be placed. The game showed the same placement-failure notification used by the vanilla 500-node limit.

## Original Hypothesis

The original Phase 2A implementation assumed the relevant 500-node enforcement could be handled by overriding the drag placement and paste paths.

That implementation used Script Extension files that copied substantial vanilla function bodies, then changed only the limit comparison.

## Root Cause

The 500-node total limit is enforced in multiple placement paths.

Static reanalysis found that menu-based click placement is handled by `scripts/windows_tab.gd`, through the add-button and selected-window handlers. Those handlers perform their own total-count check before creating a window.

The original Phase 2A implementation did not patch `scripts/windows_tab.gd`. Therefore, if the 501st-node test used the windows tab click/add path, the request still hit an untouched vanilla 500-limit branch and was rejected before the old patched paths mattered.

## Evidence

* `Utils.can_add_window(window)` handles per-window limits and attribute requirements, not the global 500-node total limit.
* `scripts/windows_tab.gd` contains direct global-count rejection paths for click/add placement.
* `scenes/window_dragger.gd` and `scripts/desktop.gd` are separate placement paths.
* No Mod Loader runtime log was available under `logs/` during this pass, and no Godot executable was available on PATH, so runtime hook execution was not confirmed.

## Rejected Patch Design

The old Script Extension design is rejected for public use because it retained substantial vanilla function body structure in publishable Mod files.

Rejected files in the local development history:

* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/desktop.gd`
* `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/window_dragger.gd`

The current Git history is intentionally preserved, so this repository must not be pushed as-is.

## Selected Patch Mechanism

Phase 2A-R1 uses Godot Mod Loader's Mod Hook API:

* registration: `ModLoaderMod.install_script_hooks(...)`
* target: `scripts/windows_tab.gd`
* hook file: `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/hooks/windows_tab_hooks.gd`
* scope: windows tab click/add placement only

The hook candidate delegates to vanilla behavior below 500 nodes. From 500 through 999 nodes, it calls the existing tab helper that creates the selected window. At 1000 nodes and above, it rejects with the existing notification key.

## Publish-Safety Implications

The R1 candidate Mod code is self-authored and does not include copied vanilla function bodies.

However, Mod Hooks generate a local hook pack from vanilla scripts. That generated hook pack must not be committed, copied into a public baseline, or distributed.

## Verification Required

The R1 candidate is not verified. Required in-game test:

* 499: windows-tab placement succeeds.
* 500: boundary state is reached.
* 501: windows-tab placement succeeds.

Until that test passes, status remains `FAILED_VERIFICATION` or `IMPLEMENTED_NOT_VERIFIED`, never `VERIFIED`.

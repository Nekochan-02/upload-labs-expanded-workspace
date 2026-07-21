# Phase 2C-F57: 0.2.40 Release Preparation Plan

## Result

`F57_RELEASE_PREPARATION_PLAN_READY`

F57 is docs-only. It prepares the release decision surface for `0.2.40` after
F55 cleanup, F56 artifact generation, static/package audit PASS, and user smoke
observation PASS. It does not push, merge, tag, create a GitHub Release, publish
to Steam Workshop, publish an artifact, rewrite history, or force push.

## Current Candidate

| Item | Value |
|---|---|
| Candidate version | `0.2.40` |
| Candidate artifact | `dist/Nekochan-ExpandedWorkspace-0.2.40.zip` |
| Current branch | `dev/phase-2c-f55-diagnostic-cleanup-clean-integration` |
| Latest commit | `d1bc43a` `docs: record 0.2.40 user smoke pass` |
| User smoke | `PASS_BY_USER_REPORT` |
| Artifact path | `dist/Nekochan-ExpandedWorkspace-0.2.40.zip` |
| Artifact size | `13918` bytes |
| Artifact file count | `14` |
| ZIP root | `mods-unpacked` |
| SHA-256 | `266310afd8b11153829c2538c86eb78f5ee5d381a67107ee1623157712b8f0c1` |
| Manifest version | `0.2.40` |
| Mod identity | `Nekochan-ExpandedWorkspace` |

F56 classification:

```text
F56_CLEAN_RC_USER_SMOKE_PASS_BY_USER_REPORT
```

## Release Readiness Checklist

| Check | Status | Evidence / note |
|---|---|---|
| Working tree dirty files are understood and protected | PASS | Existing dirty files are `AGENTS.md` and `docs/HANDOFF.md`; F57 does not stage, commit, or overwrite them. |
| Release candidate commit identified | PASS | `d1bc43a` on `dev/phase-2c-f55-diagnostic-cleanup-clean-integration`. |
| Artifact SHA-256 recorded | PASS | `266310afd8b11153829c2538c86eb78f5ee5d381a67107ee1623157712b8f0c1`. |
| ZIP root is `mods-unpacked` | PASS | Rechecked from ZIP entries. |
| Manifest version is `0.2.40` | PASS | Rechecked from ZIP manifest and source manifest. |
| Mod identity is `Nekochan-ExpandedWorkspace` | PASS | Rechecked from ZIP manifest. |
| Forbidden file audit PASS | PASS | F56 audit recorded forbidden entries `0`; F57 did not regenerate artifact. |
| SelectionPanel extension absent | PASS | Static search found no `selection_panel.gd` extension in Mod source. |
| `WindowContainer/get_position_snapped` regression absent | PASS | Static search found no `get_position_snapped` in Mod source. |
| Old-area range selection PASS | PASS | User smoke reported no problems after F56. |
| Expanded-area range selection PASS | PASS | User smoke reported no problems after F56; F53 directly proved expanded range selection after InputBlocker coverage correction. |
| Click selection PASS | PASS | User smoke reported no problems after F56. |
| Empty-click deselection PASS | PASS | User smoke reported no problems after F56. |
| Placement / movement / save/load targeted smoke PASS | PASS_BY_USER_REPORT | User reported no problems; no per-item logs/screenshots were provided in that turn. |
| Template pre-placement known status recorded | PASS | F25 fixed endpoint-owned template placement; F56 smoke reported no problems. |
| Known limitations recorded | PASS | See Known Limitations section. |
| Rollback plan recorded | PASS | See Rollback Plan section. |

## Public Operations Plan

Do not execute these operations during F57. They are a future ordered plan only.

1. Final local status confirmation:
   - Verify branch, HEAD, artifact hash, and that only understood dirty files
     remain.
   - Confirm no generated artifact is accidentally staged.
2. Release candidate commit confirmation:
   - Confirm `d1bc43a` remains the release-candidate documentation head.
   - Decide whether release docs should be committed before any public action.
3. Public remote difference confirmation:
   - Compare local release branch with the intended public remote branch.
   - Inspect whether remote already has `v0.2.9` tag / draft release history.
4. GitHub push decision:
   - Push only after separate Gate B approval.
   - Do not push dirty working tree state.
5. Tag creation decision:
   - Treat `0.2.40` as a new tag/release line, for example `v0.2.40`.
   - Do not move, delete, rewrite, or retarget any existing `v0.2.9` tag.
6. GitHub Release draft decision:
   - Create a new draft release for `v0.2.40` only after Gate C approval.
   - Do not mutate the old `0.2.9` draft/tag except to leave historical context
     untouched.
7. Workshop publish decision:
   - Publish to Steam Workshop only after Gate D approval and final Workshop
     checklist completion.

## Release Notes Draft

Title:

```text
Expanded Workspace 0.2.40 - Clean RC
```

Draft notes:

```markdown
# Expanded Workspace 0.2.40

Experimental Upload Labs Mod Loader mod that expands the workspace while
preserving the narrow behavior verified during local testing.

## Highlights

- Expands the workspace target to `20000 x 20000`.
- Raises the tested node/window capacity path to `1000` where the mod's patched
  placement routes apply.
- Extends the `space` upgrade cap to `200`.
- Fixes expanded-area save/load persistence for single nodes and groups within
  the tested scope.
- Restores the intended grid density across the expanded workspace.
- Fixes click placement and drag-from-palette placement alignment in the
  expanded area.
- Fixes tested group movement, resize, and persistence issues across the old
  boundary.
- Fixes template/schematic pre-placement near the expanded camera target in the
  tested path, including guarded ownership handling for pasted connectors.
- Fixes expanded-area Shift+drag range selection by applying the proven
  InputBlocker coverage correction.

## Tested Scope

- Clean `0.2.40` artifact generated from repository source.
- Static/package audit passed with no forbidden files in the ZIP.
- User smoke testing reported no problems.

## Known Limitations

- This is still a lightweight experimental mod, not a full game rewrite.
- The smoke result is user runtime observation; no Codex-run automated Godot
  runtime test was available in this environment.
- Large-save, long-session, and high-node-count performance stress testing are
  not claimed.
- Exhaustive all-edge group resize coverage is not claimed beyond the verified
  targeted paths.
- Future Upload Labs game updates or Mod Loader changes may require retesting.

## Install

1. Back up important saves before installing.
2. Remove or disable older `Nekochan-ExpandedWorkspace` test builds.
3. Install only `Nekochan-ExpandedWorkspace-0.2.40.zip`.
4. Confirm the Mod Loader shows `Nekochan-ExpandedWorkspace` version `0.2.40`.
5. Start with a non-critical save and verify your core workflow before relying
   on the mod.

## Backup / Save Caution

Nodes placed outside the vanilla workspace may not behave as expected if the
mod is disabled or replaced by an older test build. Keep backups of important
saves before experimenting with expanded-area layouts.
```

## Workshop Publish Caution

Workshop publication is not part of F57. Before any Workshop publish, prepare
and review:

- title
- description
- preview image
- tags
- changelog
- visibility
- dependency / compatibility notes
- tested game version, currently manifest-compatible with Upload Labs `2.2.11`
  and Godot Mod Loader `7.0.1`
- rollback plan
- final artifact hash and exact uploaded file
- save-backup warning in the public description

## Known Limitations

- User smoke PASS was reported as no problems, but per-item screenshots/logs
  were not provided in that turn.
- No Codex-run Godot runtime automation was available in this workspace.
- Large-save and long-session performance are deferred.
- High-node-count stress at or near `1000` is not release-claimed beyond the
  tested targeted workflow.
- Exhaustive all-edge group-resize matrix is deferred.
- Compatibility is bounded by the current manifest metadata and tested game
  environment; future game or loader updates require retest.
- Save safety depends on keeping backups before using layouts outside vanilla
  bounds.

## Rollback Plan

If a public or local `0.2.40` install causes problems:

1. Disable or remove `Nekochan-ExpandedWorkspace-0.2.40.zip`.
2. Restore a save backup from before expanded-area placement when possible.
3. Do not replace it with old failed RCs such as `0.2.9` unless explicitly
   using them as historical diagnostic evidence.
4. Keep existing `v0.2.9` tags/drafts untouched as historical failed-RC context.
5. Record the regression with the active artifact hash, game version, Mod Loader
   version, save context, and reproduction steps.
6. Reopen the clean RC gate and prepare a targeted docs-first diagnosis.

## Approval Gates

Gate A: release-preparation docs review

- Approves or rejects this F57 plan only.
- Does not authorize push, tag, Release, or Workshop publication.

Gate B: GitHub push approval

- Separate approval required before pushing any local branch or commit to a
  remote.

Gate C: tag / GitHub Release draft approval

- Separate approval required before creating `v0.2.40` tag or GitHub Release
  draft.
- Existing `v0.2.9` tag/draft must not be moved, reused, or rewritten.

Gate D: Workshop publish approval

- Separate approval required after GitHub/release docs are reviewed.
- Requires Workshop-specific title, description, preview image, tags, changelog,
  visibility, compatibility notes, and rollback wording.

Codex must not automatically proceed from one gate to the next.

## Explicit Non-actions

F57 performs no push, merge, tag, GitHub Release, Workshop publish, release
artifact publish, history rewrite, force push, `AGENTS.md`
stage/commit/overwrite, or dirty `docs/HANDOFF.md` overwrite.

## Human Next Action / Escalation Footer

Human Next Action:
Review this F57 release-preparation plan and decide whether Gate A is approved.

Next Action Type:
Release-preparation docs review.

ChatGPT Escalation:
Optional

Reason:
`0.2.40` has cleanup, artifact audit, and user smoke PASS, but all public
operations remain intentionally separated into approval gates.

Blocked Until Human Approval:
YES

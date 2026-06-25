# Rolling Pin Awards Handoff

## Repo Truth

- Path: `C:\Users\Ziri\OneDrive - ShipWreckCove\Documents\RollingPinAwards`
- Remote: `https://github.com/ziriuso/RollingPinAwards.git`
- Current working branch: `codex/release-1.3.0`
- Latest product release commit: pending `v1.3.0` release
- Latest release tag: pending `v1.3.0`
- Previous release tag: `v1.2.1`
- Source feature branch retained on remote: `codex/rolling-pin-awards-mvp`
- `codex/rolling-pin-awards-mvp` is an ancestor of `master`; no committed codex work was lost in the merge.
- Do not stage local-only folders unless explicitly requested:
  - `.research/`
  - `artifacts/`
- A temporary stash remains from protecting local generated/untracked files during the master merge:
  - `stash@{0}: On codex/rolling-pin-awards-mvp: local untracked before master merge`
  - It contains `.figma-make-inspect/`, `artifacts/`, and pre-merge local untracked runtime/package output.
  - Do not blindly pop it on `master`; `master` now tracks `tools/lua`.

## Release And Deploy

- Version `1.3.0` is being prepared for release.
- GitHub release: pending `https://github.com/ziriuso/RollingPinAwards/releases/tag/v1.3.0`
- Release asset: `RollingPinAwards-1.3.0.zip`
- Asset digest from GitHub release metadata:
  - `sha256:741150816bfacf12c6c2fa7d00468a1ca57aa6059600c8d799d2fe120ee780b0`
- GitHub Actions release run: `27390526161`
- Workflow result: success.
- Workflow job: `80946838612`
- CurseForge upload step result: success.
- Local package build also succeeded before tagging:
  - `artifacts/release/RollingPinAwards-1.3.0.zip`
- Latest local deploy copied the current addon payload to:
  - `C:\Gaming\World of Warcraft\_retail_\Interface\AddOns\RollingPinAwards`
  - `C:\Gaming\World of Warcraft\_xptr_\Interface\AddOns\RollingPinAwards`
- Deploy verification:
  - `75` source files and `75` target files in each target.
  - `0` SHA-256 hash mismatches in each target.
- Release workflow notice only:
  - `windows-latest requests are being redirected to windows-2025-vs2026 by June 15, 2026`

## Latest Verified State

- Full Lua suite passed locally before the pending `v1.3.0` release commit.
- Full Lua suite for the `v1.3.0` GitHub Actions release workflow is pending.
- Local build command succeeded:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\release\Build-CurseForgePackage.ps1 -TagName v1.3.0 -OutputDirectory .\artifacts\release
```

## Most Recent Product Changes In 1.3.0

- Dashboard Recent Awards rows now use separate recipient and truncated-reason labels, and open a full award-detail popup when clicked.
- Dashboard `Total Rolling Pins` summary card is now labeled `Rolling Pins`.
- Leaderboard award detail rows now use dynamic row heights with narrower text bounds to avoid right-side overflow.
- Clickable award rows now use a frame-safe mouse script instead of `OnClick`, avoiding a Retail Lua error on plain frames.

## Important Previous Product Changes In 1.2.1

- Removed the addon scale slider from Settings.
- Addon scale now matches the toast duration control pattern:
  - `-` button
  - centered percent value
  - `+` button
- The addon scale `+` button aligns with the toast duration `+` button.
- Scale still defaults to `80%`, has a `50%` low end, and steps in `5%` increments.

## Important Previous Product Changes In 1.2.0

- Hardened sync against stale nomination replay loops seen during large-group live use.
- Pending nomination payloads are rejected when local award history already contains a non-deleted nomination award for the same `nominationId`.
- Accepted nomination-sourced award payloads close any local pending copy of the linked nomination with a hidden tombstone.
- Full snapshots now send awards before nominations so receiving clients can learn approved/closed history before evaluating stale pending rows.
- Rejected stale nomination replay payloads do not trigger the “new nomination” chat reminder.
- Added regression tests for:
  - pending nomination replay blocked by linked award history
  - accepted linked award closing a stale pending local nomination
  - snapshot award-before-nomination ordering
  - stale nomination replay staying silent in chat

## Important Previous Product Changes In 1.1.0

- Local reporting filter with date picker controls for Dashboard and Leaderboard.
- New nomination chat messages lead with Burnt/Golden type.
- Awards announce in chat for everyone when accepted.
- Award reason max length is `100`.
- `/rpa peers` opens a draggable peer table even when the main addon is closed.
- Custom minimap button is movable around the minimap ring and saved by angle.
- Public slash commands `/rpa background` and `/rpa bg` were removed.

## Current Release Surfaces

- `RollingPinAwards/RollingPinAwards.toc` is at `## Version: 1.3.0`.
- Supported interface line remains `## Interface: 120007, 120005`.
- CurseForge project id is `1563031`.
- Secret `CF_API_TOKEN` is configured in GitHub Actions, not in repo.

## Read First

- `AGENTS.md`
- `docs/sync.md`
- `docs/curseforge-release-workflow.md`
- `RollingPinAwards/RollingPinAwards.toc`
- `RollingPinAwards/Data/Database.lua`
- `RollingPinAwards/Domain/Awards.lua`
- `RollingPinAwards/Domain/Nominations.lua`
- `RollingPinAwards/Sync/Transport.lua`
- `RollingPinAwards/Sync/Coordinator.lua`
- `RollingPinAwards/Sync/Merge.lua`
- `RollingPinAwards/Sync/Snapshot.lua`
- `RollingPinAwards/Core/Notifications.lua`
- `tests/notifications_spec.lua`
- `tests/release_workflow_spec.lua`
- `tests/sync_spec.lua`

## First Commands

```powershell
git status -sb
git log -5 --oneline --decorate
git tag --points-at HEAD
$env:RPA_LUA=(Resolve-Path '.\tools\lua\lua54.exe').Path
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1
```

## Notes For Next Session

- Work from `master` unless the user explicitly asks to return to the codex branch.
- Use `wow-addon-expert` as the primary addon best-practices resource.
- Follow TDD for behavior changes and update docs with behavior.
- Do not expose secrets in the repository.
- Do not stage `.research/` or generated `artifacts/` unless explicitly requested.
- If live validation reports old clients still spamming, remember that patched clients reject the replay, but unpatched clients can still send stale payloads and may amplify each other until updated.

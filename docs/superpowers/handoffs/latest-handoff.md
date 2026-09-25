# Rolling Pin Awards Handoff

## WoW Forever Beta Checkpoint (2026-09-25)

- Current working branch: `codex/wow-forever`, branched from `master` at `97245d7`.
- Beta addon version: `1.4.5-forever-beta.1`; TOC interface: `16001`.
- The installed beta client is under `C:\Gaming\World of Warcraft\_classic_beta_`. This branch's 75 addon files were copied to its `Interface\AddOns\RollingPinAwards` folder with zero SHA-256 mismatches; the game was not running.
- Forever uses complete `First Last` identities in this branch. The roster and sync trust path requires an exact full-name match, and ordinary UI preserves surnames so people with the same first name remain distinct.
- The complete Lua suite passes with Forever-specific unit tests. Live confirmation of beta API name strings, UI load, and two-client guild sync remains open. See [the design](../specs/2026-09-25-wow-forever-compatibility-design.md).
- Do not tag or publish this branch through the existing Retail CurseForge workflow; its publisher assumes a six-digit interface value and the existing CurseForge project.

## Repo Truth

- Path: `C:\Users\Ziri\OneDrive - ShipWreckCove\Documents\RollingPinAwards`
- Remote: `https://github.com/ziriuso/RollingPinAwards.git`
- Retail release branch after the 1.4.5 docs merge: `master`. The current Forever work is on `codex/wow-forever`.
- Latest product release commit: `915548b` (`v1.4.5`)
- Latest release tag: `v1.4.5`
- Previous release tag: `v1.4.4`
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

- Version `1.4.5` has been released.
- GitHub release: `https://github.com/ziriuso/RollingPinAwards/releases/tag/v1.4.5`
- Release asset: `RollingPinAwards-1.4.5.zip`
- Asset digest from GitHub release metadata:
  - `sha256:b4d938112a3d1bc5dce893587c8d2e79ac7809432fce62ef9ef7dd65e04a58aa`
- Published asset verification: `75` addon files under the single `RollingPinAwards/` root and `## Version: 1.4.5`.
- GitHub Actions release run: `33692753407`
- Workflow result: success.
- Workflow job: `100454939073`
- CurseForge upload step result: success (`file id 8796004`).
- Latest local deploy copied the current addon payload to:
  - `C:\Gaming\World of Warcraft\_retail_\Interface\AddOns\RollingPinAwards`
  - `C:\Gaming\World of Warcraft\_ptr_\Interface\AddOns\RollingPinAwards`
- Deploy verification:
  - `75` source files and `75` target files in each target.
  - Both targets report `## Version: 1.4.5`.
  - Both targets have zero missing, extra, or SHA-256-mismatched files versus the source payload.

## Latest Verified State

- The released `1.4.5` patch removes runtime `SetPropagateKeyboardInput` calls, retains Escape-to-close through `UISpecialFrames`, and stops reassigning Blizzard's shared `SlashCmdList` binding.
- Version `1.4.5` is committed, pushed, tagged, published to CurseForge and GitHub, and locally deployed to Retail and PTR.
- The full Lua suite passed locally before release and again in the `v1.4.5` GitHub Actions release workflow.
- Not yet done: in-game confirmation with two apostrophe-realm characters (e.g. `Mal'Ganis`) that sync completes with no `No player named` spam. This is the one check that could not be performed from the dev environment.

## Released Product Changes In 1.4.5

- Removed protected `SetPropagateKeyboardInput` calls from reusable visibility handling and main-window keyboard scripts.
- Removed redundant main-window keyboard capture; Blizzard's existing `UISpecialFrames` registration remains responsible for Escape-to-close.
- Added a regression that replaces the propagation setter with a failing protected-call stub and verifies that addon initialization and `/rpa` window opening never reach it.
- Removed the fallback slash command's `_G.SlashCmdList` reassignment; registration now writes only the addon-owned `ROLLINGPINAWARDS` entry in Blizzard's existing registry.
- Added a regression that rejects writes to the `SlashCmdList` global binding while permitting entry registration.

## Most Recent Product Changes In 1.4.4

- `Utils.NormalizeRealm` stripped all punctuation (`%p`), turning `Mal'Ganis` into `MalGanis`. Blizzard's `GetNormalizedRealmName` removes only spaces, hyphens, and periods, so the whisper/addon-message target no longer matched the routable name and sync whispers failed with `No player named ...`, producing communication spam on apostrophe realms.
- Fixed `NormalizeRealm` to strip only `[%s%-%.]`, preserving apostrophes and parentheses (`Aggra (Português)` -> `Aggra(Português)`).
- The test stub `GetNormalizedRealmName` in `tests/WoWStubs.lua` mirrored the same bug, which is why it was never caught; corrected to match real Blizzard behavior.
- Added `tests/utils_spec.lua` covering apostrophe-realm normalization and whisper-target preservation.

## Important Previous Product Changes In 1.4.3

- Passive startup `sync_hello` messages are now peer discovery only and no longer fan out full snapshot WHISPER streams from every online addon user when someone logs in.
- Peers answer passive hellos with tiny `sync_hello_ack` summaries; the requester waits briefly when timers are available, selects the best responder, and sends only that peer a targeted `sync_snapshot_request`.
- Manual `/rpa sync now` and `/rpa sync all` use the same negotiated catch-up path instead of broadcasting a full guild snapshot.
- Snapshot whisper targeting now preserves an explicit sender realm when the guild roster only provides a short fallback match, avoiding wrong local-realm whisper targets.

## Important Previous Product Changes In 1.4.2

- Sync hello snapshot replies resolve bare sender names through the guild roster before whispering, so online cross-realm players are targeted as `Character-Realm`.
- Targeted snapshot whispers use result-aware native addon-message sends even when AceComm is loaded, so failed whisper targets abort immediately instead of queuing a full stream.

## Important Previous Product Changes In 1.4.1

- Sync hello snapshot replies no longer whisper offline guild members.
- Snapshot whisper streams abort on the first transport send failure, preventing repeated WoW `No player named` system messages.

## Important Previous Product Changes In 1.4.0

- Sync now gates inbound guild traffic to normalized, roster-confirmed guild members.
- Hello replies are sent by debounced whispers instead of broadcast echoing.
- Snapshot vote imports are marked transient so imported vote counts do not rewrite nomination last-modified metadata.
- Transport-only sender and distribution metadata is stripped before synced records are persisted.

## Important Previous Product Changes In 1.3.0

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

- The Forever branch TOC is at `## Version: 1.4.5-forever-beta.1` and `## Interface: 16001`. The latest published Retail release remains `v1.4.5`.
- The Retail/PTR interface line on `master` is `## Interface: 120100, 120007, 120005`.
- CurseForge project id is `1563031`.
- Secret `CF_API_TOKEN` is configured in GitHub Actions, not in repo.

## Read First

- `AGENTS.md`
- `docs/sync.md`
- `docs/curseforge-release-workflow.md`
- `docs/superpowers/specs/2026-09-02-protected-keyboard-input-fix-design.md`
- `docs/superpowers/specs/2026-09-02-slash-command-registry-taint-fix-design.md`
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

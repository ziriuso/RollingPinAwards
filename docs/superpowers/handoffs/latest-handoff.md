# Rolling Pin Awards Handoff

## Repo Truth

- Path: `C:\Users\Ziri\OneDrive - ShipWreckCove\Documents\RollingPinAwards`
- Branch: `codex/rolling-pin-awards-mvp`
- Remote: `https://github.com/ziriuso/RollingPinAwards.git`
- Current pushed checkpoint: `fd7533e` (`feat: polish typography and roster selection`)
- Recent commits:
  - `fd7533e feat: polish typography and roster selection`
  - `8e9274d feat: bundle roboto typography fonts`
  - `d0f49f7 feat: polish toast settings and typography`
- `git status -sb` is clean against `origin/codex/rolling-pin-awards-mvp` except local-only untracked folders:
  - `.figma-make-inspect/`
  - `.research/`
  - `tools/`
- Current local uncommitted screenshot-fix slice also modifies UI files, tests, this handoff, and adds `docs/superpowers/specs/2026-06-05-screenshot-ui-fixes-design.md`.
- Do not stage the local-only folders unless explicitly instructed.
- `AGENTS.md` was requested as a read-first file, but there is no root `AGENTS.md` file in the repo as of this handoff refresh. Treat the active project instructions from the resume prompt as authoritative:
  - keep documentation up to date
  - build reusable, scalable controls
  - use TDD and SDD
  - ask for clarity instead of assuming when scope is unclear
  - never expose secrets insecurely

## Verification

- Full suite command:
  - `$env:RPA_LUA=(Resolve-Path '.\tools\lua\lua54.exe').Path`
  - `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`
- Last verified result on 2026-06-05:
  - full Lua suite passed after the screenshot-fix slice with `RPA_LUA=.\tools\lua\lua54.exe`
  - before the screenshot-fix slice, full Lua suite passed after checkpoint `fd7533e`

## Local Deploy

- Latest verified/deployed build was copied to:
  - `C:\Gaming\World of Warcraft\_retail_\Interface\AddOns\RollingPinAwards`
  - `C:\Gaming\World of Warcraft\_xptr_\Interface\AddOns\RollingPinAwards`
- Last full deploy verified 72 runtime files in both Retail and PTR, with key deployed hashes matching repo files.
- Screenshot-fix deploy copied the six changed runtime Lua files to both Retail and PTR and verified SHA-256 hashes matched repo files:
  - `UI/Components.lua`
  - `UI/Styles.lua`
  - `UI/Tabs/Admin.lua`
  - `UI/Tabs/Award.lua`
  - `UI/Tabs/Dashboard.lua`
  - `UI/Tabs/Nominations.lua`
- If new repo changes are made after this handoff, redeploy before live WoW validation.

## Current Implemented Surface

- Typography polish:
  - Roboto Regular and Bold are bundled under `Media/Fonts/`.
  - `UI/Styles.lua` owns shared typography roles.
  - `UI/Components.lua` applies outline-free reusable text roles across labels, buttons, rows, cards, modals, and tab chrome.
- Roster selection:
  - Award Recipient and Nomination Nominee inputs use guild roster autocomplete.
  - Award and nomination submit paths require selecting a roster suggestion.
  - Multi-result roster suggestions anchor under the previous suggestion button so extra names do not appear at the top-left of the screen.
  - Admin character mapping uses `Alt Character` and `Main Character` wording.
  - Admin mapping fields also autocomplete guild roster names.
  - Normal Award, Nomination, History, Leaderboard, Dashboard, and moderation UI shorten displayed names outside character mapping.
- Toast/settings work:
  - Accepted inbound awards notify the current recipient only.
  - Toast settings, duration, anchor placement, seen-award ids, combat queueing, and close button are implemented.
  - Pending inbound nominations and login reminders write local chat reminders.
- Sync:
  - Sync is split across `Sync/Codec.lua`, `Sync/Transport.lua`, `Sync/Snapshot.lua`, `Sync/Merge.lua`, `Sync/Diagnostics.lua`, and `Sync/Coordinator.lua`.
  - AceComm/AceSerializer are embedded directly when available.
  - Native `C_ChatInfo` fallback chunks messages over the addon-message limit and reassembles inbound chunks.
  - Startup and manual sync send `sync_hello`; peers respond with rank permissions, aliases, nominations, votes, awards, tombstones, and `sync_snapshot_complete`.
  - Stable guild-key migration sends a fresh hello when the client moves from provisional guild name to numeric guild id.
  - New award and nomination ids include actor, timestamp, and sequence to avoid cross-client collisions.
  - Award and linked nomination deletes are retained as hidden tombstones for offline catch-up.
  - Inbound accepted payloads rerender the active tab and route accepted award/nomination notifications.
- Current local screenshot-fix slice:
  - Award and Nomination reason fields are capped at 30 characters.
  - Navigation buttons are wider so `Nominations` and `Leaderboard` do not clip.
  - Burnt/Golden selected state is more visually distinct.
  - Nominations submit aligns with the nominee/reason input row.
  - Admin rank Save buttons sit left of the scrollbar.
  - Admin moderation button reads `Moderation Queue`.
  - Dashboard stat-card headers are pinned to the card top, details to the bottom, and the first detail reads `Total Guildwide`.
  - `tests/bridge_spec.lua` covers these screenshot fixes.

## Priority

Top priority is live two-client sync validation. Local tests are green, and the deployed build was verified in both Retail and PTR folders, but live client behavior is still the source of truth for transport, guild-key timing, and sender authorization convergence.

Recommended live validation order:

1. Confirm both clients are running the deployed `fd7533e` build, then `/reload` both clients.
2. Run `/rpa syncdebug` on both clients immediately after reload/login.
3. Confirm `Last outbound` shows `sync_hello` and active guild keys match.
4. Run `/rpa sync now` on the data-rich client.
5. Run `/rpa syncdebug` again on both clients and compare inbound/outbound payload results and snapshot counts.
6. Create fresh post-update test data before judging history or nomination behavior; legacy collided rows from earlier builds may already be damaged.
7. Test local mutations in this order: nomination create, vote, approve/reject, direct award, delete, rank permission save, alias mapping save/delete.
8. If history still fails to appear, inspect sender authorization for `award` payloads before changing transport.

Do not clear SavedVariables or delete live records without explicit approval.

## Read First

- `docs/sync.md`
- `Data/Database.lua`
- `Domain/Awards.lua`
- `Domain/Nominations.lua`
- `Sync/Transport.lua`
- `Sync/Coordinator.lua`
- `Sync/Merge.lua`
- `Sync/Snapshot.lua`
- `UI/Components.lua`
- `UI/Styles.lua`
- `UI/Tabs/Award.lua`
- `UI/Tabs/Nominations.lua`
- `tests/bridge_spec.lua`
- `tests/sync_spec.lua`
- `tests/notifications_spec.lua`

## Resume Order

1. Run `git status -sb` and `git log -3 --oneline`.
2. Set `$env:RPA_LUA=(Resolve-Path '.\tools\lua\lua54.exe').Path`.
3. Run `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`.
4. If changing behavior, write or update tests first and keep controls reusable.
5. Keep docs/specs/plans current with the behavior change.
6. Redeploy only after verification if live WoW validation is needed.

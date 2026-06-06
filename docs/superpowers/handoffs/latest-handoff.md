# Rolling Pin Awards Handoff

## Repo Truth

- Path: `C:\Users\Ziri\OneDrive - ShipWreckCove\Documents\RollingPinAwards`
- Branch: `codex/rolling-pin-awards-mvp`
- Remote: `https://github.com/ziriuso/RollingPinAwards.git`
- Current pushed checkpoint before the addon-folder restructure: `aba3a80` (`fix: find chocolatey lua install path`)
- Recent commits:
  - `aba3a80 fix: find chocolatey lua install path`
  - `9e3361f fix: resolve lua runtime in release workflow`
  - `4cc18e7 chore: prepare curseforge release`
- `git status -sb` is clean against `origin/codex/rolling-pin-awards-mvp` except local-only untracked folders:
  - `.figma-make-inspect/`
  - `.research/`
  - `tools/lua/`
- Release `v1.0.0` was published successfully from tag `v1.0.0` pointing at `aba3a80`.
- The installable addon payload now lives under `RollingPinAwards/`:
  - `RollingPinAwards/RollingPinAwards.toc`
  - `RollingPinAwards/Bootstrap.lua`
  - `RollingPinAwards/Core/`
  - `RollingPinAwards/Data/`
  - `RollingPinAwards/Domain/`
  - `RollingPinAwards/Libs/`
  - `RollingPinAwards/Media/`
  - `RollingPinAwards/Sync/`
  - `RollingPinAwards/UI/`
- Root-level `.github/`, `docs/`, `tests/`, `tools/`, `README.md`, and `LICENSE` are repository infrastructure and should stay outside the packaged addon folder.
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
  - full Lua suite passed after second leaderboard showcase count positioning tune with `RPA_LUA=.\tools\lua\lua54.exe`
  - full Lua suite passed after leaderboard showcase text positioning tune with `RPA_LUA=.\tools\lua\lua54.exe`
  - full Lua suite passed after leaderboard showcase card rebuild with `RPA_LUA=.\tools\lua\lua54.exe`
  - full Lua suite passed after draggable minimap ring positioning and `Guild` addon-list category metadata with `RPA_LUA=.\tools\lua\lua54.exe`
  - full Lua suite passed after modal header/search text color polish and 50% toast opacity with `RPA_LUA=.\tools\lua\lua54.exe`
  - full Lua suite passed after solid-backdrop opacity fix for toasts, modals, and roster suggestions with `RPA_LUA=.\tools\lua\lua54.exe`
  - full Lua suite passed after toast background and trophy art replacement with `RPA_LUA=.\tools\lua\lua54.exe`
  - full Lua suite passed after the nav visual alignment polish with `RPA_LUA=.\tools\lua\lua54.exe`
  - full Lua suite passed after the modal-fill and autocomplete z-order polish with `RPA_LUA=.\tools\lua\lua54.exe`
  - full Lua suite passed after the broader screenshot-fix slice with `RPA_LUA=.\tools\lua\lua54.exe`
  - before the screenshot-fix slice, full Lua suite passed after checkpoint `fd7533e`

## Local Deploy

- Latest verified/deployed build was copied to:
  - `C:\Gaming\World of Warcraft\_retail_\Interface\AddOns\RollingPinAwards`
  - `C:\Gaming\World of Warcraft\_xptr_\Interface\AddOns\RollingPinAwards`
- Latest full deploy after the solid-backdrop opacity fix copied 72 tracked runtime files to both Retail and PTR and verified 144 SHA-256 comparisons with zero mismatches.
- Latest full deploy after modal header/search text color polish and 50% toast opacity copied 72 tracked runtime files to both Retail and PTR and verified 144 SHA-256 comparisons with zero mismatches.
- Latest full deploy after draggable minimap ring positioning and `Guild` addon-list category metadata copied 72 tracked runtime files to both Retail and PTR and verified 144 SHA-256 comparisons with zero mismatches.
- Latest full deploy after leaderboard showcase card rebuild copied 74 runtime/media files, including two new local assets, to both Retail and PTR and verified 148 SHA-256 comparisons with zero mismatches.
- Latest full deploy after leaderboard showcase text positioning tune copied 74 runtime/media files to both Retail and PTR and verified 148 SHA-256 comparisons with zero mismatches.
- Latest full deploy after second leaderboard showcase count positioning tune copied 74 runtime/media files to both Retail and PTR and verified 148 SHA-256 comparisons with zero mismatches.
- Latest full deploy on 2026-06-05 copied 72 tracked runtime files to both Retail and PTR and verified 144 SHA-256 comparisons with zero mismatches.
- Last full deploy verified 72 runtime files in both Retail and PTR, with key deployed hashes matching repo files.
- Screenshot-fix deploy copied the six changed runtime Lua files to both Retail and PTR and verified SHA-256 hashes matched repo files:
  - `UI/Components.lua`
  - `UI/Styles.lua`
  - `UI/MainFrame.lua`
  - `UI/SettingsPage.lua`
  - `UI/Tabs/Admin.lua`
  - `UI/Tabs/Dashboard.lua`
  - `UI/Tabs/Leaderboard.lua`
- Modal/autocomplete polish deploy copied the two changed shared runtime Lua files to both Retail and PTR and verified SHA-256 hashes matched repo files:
  - `UI/Components.lua`
    - SHA-256: `42F4C35BC1D01B71863B887F9075545DBA75655B477C41A276C356CF09EA051A`
  - `UI/Styles.lua`
    - SHA-256: `30B38A7461B3F1DB9DD8335E78FB9CCBE06D55669E093EB1FC149FB1E5D8C7D4`
- Nav visual alignment polish redeployed `UI/Styles.lua` to both Retail and PTR and verified SHA-256 hashes matched repo files:
  - `UI/Styles.lua`
    - SHA-256: `4CE28651E6A35D87962725AC2BB9CB8B7D964A65E34F6390F3A606417B22AE2A`
- Toast/trophy polish replaced the two trophy media files in place and redeployed the changed runtime/media files to both Retail and PTR:
  - `UI/Styles.lua`
    - SHA-256: `0235CA97EE9399CB6C217A537D21D0AB05B7B9BC7DEBA18521F36B1DC50BE618`
  - `UI/Toast.lua`
    - SHA-256: `59E1F28C222E851306A1643AFACD807C2064521020938A033B4177D40D4A27F5`
  - `RollingPinAwards/Media/burnt-rolling-pin.png`
    - SHA-256: `034E1CB1350AE7F476B5F116A0F7277A2D8EAC6A903D94042E99F7245F5245A5`
  - `RollingPinAwards/Media/golden-rolling-pin.png`
    - SHA-256: `A0455126EEADFC85EEB780ABF5279715825500F15F7F9D82F11888912C84E989`
- Solid-backdrop opacity fix redeployed the full runtime payload to both Retail and PTR; the changed shared UI files hash as:
  - `UI/Components.lua`
    - SHA-256: `AD226B3424F22A8C3FB6E65D0F1B2E0FABF6130CC887E74E341A316551874031`
  - `UI/Toast.lua`
    - SHA-256: `4DD5E977D7EF3E60FA8192E47A040FA246BA22E17B54626D19D8D5AE9D3B3435`
- Modal header/search text color polish and 50% toast opacity redeployed the full runtime payload to both Retail and PTR; the changed runtime files hash as:
  - `UI/Components.lua`
    - SHA-256: `65962C745D6EAEF2CE619C557984073BD4B1D7396A622F8B6728D89C6F7A7422`
  - `UI/Styles.lua`
    - SHA-256: `1DC225D85CB6B38008C54B5D06649B732862FF30AC3AA2062F44631122E83EF4`
  - `UI/Tabs/Admin.lua`
    - SHA-256: `F7703A6C14BD00E2093E17C9F309F11E36CDFC89CA759AFFCA3613FA13B3CCE8`
- Draggable minimap ring positioning and `Guild` addon-list category metadata redeployed the full runtime payload to both Retail and PTR; the changed runtime files hash as:
  - `RollingPinAwards/RollingPinAwards.toc`
    - SHA-256: `B4F45F993F7F475C85638D097CA2570F62C81D377F26C20F0DF99C1D5755EFAE`
  - `UI/MinimapButton.lua`
    - SHA-256: `7EB7CAC3B67EAAE84067ED8596916385E3F991C1C736BAC4977C7A00F02D513D`
  - `Data/Defaults.lua`
    - SHA-256: `A33B33650106C60749AB948C968D3CD958737BAF795D44A37F1694F5C395F47B`
  - `Data/Database.lua`
    - SHA-256: `9B5D90A16621F569748B293CA0D8E2698D8B1536A3FDA2947997DD4293350741`
- Leaderboard showcase card rebuild redeployed the full runtime/media payload to both Retail and PTR; the changed runtime/media files hash as:
  - `UI/Tabs/Leaderboard.lua`
    - SHA-256: `CCD0771FB6EBDABF5ED55DA7A08C31D0D64F03E6C682DEE7F3DB98D36B1FE43F`
  - `UI/Styles.lua`
    - SHA-256: `1FF1A6798F3FBEC565718371EA9AF9F237D26342B97FF737761075BF12F3F7E7`
  - `RollingPinAwards/Media/cleancard.png`
    - SHA-256: `67CBBC393D18ED3B367B450E61F0AF114B66C35C70488084E2821CCB0E61DC23`
  - `RollingPinAwards/Media/Fonts/Amarante-Regular.ttf`
    - SHA-256: `33883758BD97923064FF9AF521397FB616942346F8F949B8ECC061BFBB9C7373`
- Leaderboard showcase text positioning tune redeployed the full runtime/media payload to both Retail and PTR; the changed runtime files hash as:
  - `UI/Tabs/Leaderboard.lua`
    - SHA-256: `3442F3AB442CCD31889DAD23ACC82FCF56F049B14EAA86AAA5BC2F80C7A98C14`
  - `UI/Styles.lua`
    - SHA-256: `2E164FD876A5F5525F30EBC843025B2532F0B7EFD3C10E43101DD4AB9A3E67C5`
- Second leaderboard showcase count positioning tune redeployed the full runtime/media payload to both Retail and PTR; the changed runtime file hashes as:
  - `UI/Tabs/Leaderboard.lua`
    - SHA-256: `E27B9061DA7CD7B750DDA6526ABFA7BD5BFEF7827699FAB2A2DB8140F43951A8`
- If new repo changes are made after this handoff, redeploy before live WoW validation.

## Current Implemented Surface

- Typography polish:
  - Roboto Regular and Bold are bundled under `RollingPinAwards/Media/Fonts/`.
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
- Minimap/addon-list work:
  - `RollingPinAwards/RollingPinAwards.toc` declares `## Category: Guild` so Retail groups the addon under the Guild heading.
  - The custom minimap button is parented to `Minimap`, anchored to the outer ring with a saved angle, and can be dragged around the ring with the left mouse button.
  - `localSettings.minimapAngle` persists the minimap button angle across reloads.
- Leaderboard showcase card work:
  - Leaderboard recipient popups use `RollingPinAwards/Media/cleancard.png` as a full-card background.
  - Character name uses `RollingPinAwards/Media/Fonts/Amarante-Regular.ttf` at 28 pt in the shared card-value gold and sits 20 px lower than the initial showcase pass.
  - Burnt count and Golden count use `RollingPinAwards/Media/Fonts/Amarante-Regular.ttf` at 24 pt in the shared card-value gold.
  - Burnt and Golden counts share the same lower vertical plane; Golden moved down 35 px and left 35 px from the prior pass, while Burnt moved onto that plane and right 44 px.
  - Burnt count is placed on the left, Golden count on the right, and the award-history scroll table sits in the lower parchment region.
  - The close control is an invisible hitbox over the background's built-in close-button graphic.
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
  - Dashboard `Pending Nominations` card label is shortened to `Nominations`.
  - Dashboard stat-card values use `#DF960A` without an outline.
  - Selected Burnt/Golden and leaderboard filter buttons use a darker fill and `#DF960A` text.
  - The settings gear is shifted right to clear tab chrome.
  - Settings uses `Toggle Anchors` copy.
  - Six-button and five-button nav layouts use a shared `-26` visual alignment offset from the Dashboard stat-card center gap so the live nav no longer drifts right.
  - Admin character mapping now uses equal-width Alt/Main fields, puts Add/View buttons below the fields, and provides three roster suggestions for both fields.
  - Confirmation dialogs, character mappings, and moderation queue modals use the shared `#C59F6B` fill on a solid `Interface\Buttons\WHITE8x8` backdrop.
  - Roster autocomplete suggestions use an opaque modal fill on a solid `Interface\Buttons\WHITE8x8` backdrop and a raised frame level so dropdown selections stay above nearby action buttons.
  - Character mapping and moderation queue modal headers retain the standard brown section-header color.
  - Roster autocomplete suggestion text uses the same brown header color on the opaque modal fill.
  - Reward toasts and the toast anchor use `#E0BC89` at 50% opacity as their backdrop fill on a solid `Interface\Buttons\WHITE8x8` backdrop.
  - Burnt and golden trophy art has been replaced in place at the existing media paths so all existing surfaces keep their configured sizes.
  - `tests/bridge_spec.lua` covers these screenshot fixes, including solid backdrop texture assertions for modals and roster suggestions plus brown modal/search text.
  - `tests/notifications_spec.lua` covers the toast and toast-anchor backdrop color, 50% opacity, and solid texture.
  - `tests/media_spec.lua` covers the replacement trophy payloads.
  - `tests/commands_spec.lua` covers minimap ring anchoring, drag updates, saved angle persistence, custom icon, and toggle behavior.
  - `tests/embedded_ace3_spec.lua` covers the `Guild` TOC category.
  - `tests/bridge_spec.lua` covers the clean-card leaderboard popup layout and invisible close hitbox.
  - `tests/media_spec.lua` covers the clean card and Amarante font payloads.

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

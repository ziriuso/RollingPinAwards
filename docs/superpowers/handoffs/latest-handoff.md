# Rolling Pin Awards Handoff

## Repo
- Path: `C:\Users\Ziri\OneDrive - ShipWreckCove\Documents\RollingPinAwards`
- Branch: `codex/rolling-pin-awards-mvp`
- Pushed checkpoint: `f61c8d3b6047716588921ca0bf51fadabf355817` (`fix: harden sync record merges`)
- Current working tree now has an uncommitted native sync transport follow-up and GBankManager-style structure refactor after `f61c8d3`.
  - `Bootstrap.lua`
  - `Core/`
  - `Data/`
  - `Domain/`
  - `Sync/`
  - `UI/MinimapButton.lua`
  - `RollingPinAwards.toc`
  - `docs/sync.md`
  - `tests/WoWStubs.lua`
  - `tests/commands_spec.lua`
  - `tests/embedded_ace3_spec.lua`
  - `tests/sync_spec.lua`
  - `docs/superpowers/handoffs/latest-handoff.md`
  - `docs/superpowers/specs/2026-06-03-addon-structure-refactor-design.md`
  - `docs/superpowers/specs/2026-06-03-sync-transport-refactor-design.md`
  - `docs/superpowers/plans/2026-06-03-addon-structure-refactor.md`
  - `docs/superpowers/plans/2026-06-03-sync-transport-refactor.md`

## Current State
- UI polish pass is largely implemented and deployed locally to both Retail and PTR.
- Custom media icons are wired in under `Media/`.
- Burnt and Golden rolling pin award types are implemented across direct awards, nominations, history, dashboard, and leaderboard.
- Leaderboard supports `Burnt`, `Golden`, and `Combined` modes.
- Alias merge management was moved to an admin modal.
- `CreateContentPanel` no longer creates a decorative `innerShade` child frame or background texture.
- `contentHost` is now parented to the main frame as a sibling above the empty content panel, anchored to the panel bounds, so tab content is not nested under decorative layers.
- The root parchment art is visible again with calibrated size/offset values from the live screenshot; `/rpa background` remains available as a temporary movable/resizable calibration helper.
- The main addon frame now uses `TOOLTIP` strata, a high base frame level, and top-level behavior so the full shell renders above Blizzard action bars and other common UI elements.
- The main frame has an expanded hit rect matching the parchment overhang, so empty parchment/background areas can be used to drag the addon.
- The main frame is registered with `UISpecialFrames` and has an Escape key handler so Esc closes the addon when the main window is focused.
- Follow-up UI tweaks are implemented across Dashboard, Award, Nominations, History, Leaderboard, and Admin:
  - Dashboard card/list copy and alignment, serverless recent awards, normal pin icon for total pins.
  - Award form chrome expanded and the extra Award Desk box removed.
  - Nominations form overflow fixed, Burnt/Golden wording and icons updated, public hype footer removed, pending rows separated with lighter backdrops.
  - History and Leaderboard helper boxes removed, tables expanded, and list rows separated with lighter backdrops.
  - Admin alias form is contained within its chrome and moderation queue opens in a modal.
- Follow-up polish fix:
  - Custom checkboxes now own their visual checked state and click toggling, so Admin permission toggles work without the default ghost checkbox template.
  - Scrollable list rows now use `BackdropTemplate` frames so row backdrops render in the live client.
  - Pending nominations table height was expanded so three visible rows and their action buttons stay inside the table chrome.
- Settings tab and its local toggles were removed entirely:
  - no tooltips toggle
  - no announce-awards toggle
  - no debug-mode toggle
  - Admin now occupies the old sixth nav slot and the main addon window is slightly narrower for a more even right-side buffer.
- Latest row polish pass is implemented:
  - highlighted scroll-list rows use dark ink text on the lighter row backdrop.
  - row labels, icons, and action buttons are vertically centered.
  - reusable list rows leave a right gutter so row backdrops do not run under scrollbars.
  - Dashboard list rows now use the same lighter backdrop style as other tabs and the rolling-pin count is double-indented.
  - Pending nomination, leaderboard, moderation queue, and alias merge rows share the scrollbar-safe row layout.
  - Moderation queue has `Pending`, `Approved`, `Rejected`, and `All` filters, defaults to pending only, and no longer shows the flame icon or `Pending Nominations` header.
  - Moderation statuses render without brackets.
  - Admin permission help now uses the actual column labels (`Nominations`, `Direct`, `Delete`, `Admin`) and the old Rank 0 note is removed from the tab.
  - Tab navigation rail is tighter and the six nav buttons are centered inside it after the Settings tab removal.
  - Header text/flame icon has been replaced by the banner artwork built into the main shell background.
  - Burnt and Golden rolling pin media now use `Media/burnt-rolling-pin.png` and `Media/golden-rolling-pin.png`.
  - `UI/MinimapButton.lua` creates a custom minimap button using `Media/minimap-button.png`; clicking it toggles the main addon window open/closed.
  - Standalone header logo, header box, and accent chrome are removed because the banner is built into the main shell background.
  - Main addon shell renders `Media/addon-background.png` visibly at `1048x872` with a `TOPLEFT` offset of `-52, 92`, based on the live calibration screenshot.
  - `/rpa background` and `/rpa bg` still toggle a temporary movable/resizable background calibration frame for future live placement checks.
  - The separate header logo/banner texture, old shell shadow, nav-rail backdrop, and visible content-panel backdrop/inner shade are removed; the close X remains as a standalone top-right control.
  - Reusable section and stat-card backdrops use a lighter banner-toned fill.
  - Dashboard stat-card value text is centered vertically between the label and detail text.
  - Leaderboard `View` now opens a larger opaque showcase modal:
    - centered short character name without realm.
    - large Golden and Burnt rolling pin icons with bold count labels beneath.
    - scrollable award record table below the counters.
    - close button moved to the bottom right for screenshot-friendly framing.
  - Leaderboard showcase modal now uses `Media/modal-background.png` as a parchment background and keeps all modal content inside a bounded safe content area over the parchment body.
  - Leaderboard showcase modal is draggable independently from the main addon frame, parents above the main frame content so it does not disappear inside clipped tab layers, uses slightly larger trophy icons, and gives the award record list a headerless full-box scroll area.
- Latest card/form polish pass is implemented:
  - Dashboard stat cards no longer render decorative icons.
  - Addon text now uses WoW's native thin `OUTLINE` font flag, matching Chattynator's thin outline approach; gold text is back to default `GameFontNormal` color rather than the temporary brown override.
  - Nominations form title no longer has a small left icon.
  - Nominations form shows a larger selected Burnt/Golden pin preview above the submit button and the submit button is raised slightly.
  - Admin moderation queue button count now reflects only pending nominations, not approved/rejected history.
- Latest text readability pass is implemented:
  - reusable light row backdrops now render their dark row text without WoW outline flags, so Dashboard, Nominations, History, Leaderboard, Admin alias rows, and the moderation modal avoid heavy black-on-light outlines.
  - Admin helper/status text and rank names are bumped by two font points while retaining the thin outline for readability over the parchment background.
- The updated build has been copied to both documented local Retail and PTR AddOns folders.
- Test suite is green.
- Live visual inspection after the readability pass looked better.
- Real in-game sync testing was attempted before this slice, and no sync occurred between clients.
- Current local code now broadcasts local mutations for awards, nominations, nomination votes, alias mappings, and rank permission saves, and includes `/rpa syncdebug` / `/rpa sync debug` chat diagnostics for live transport checks.
- Live diagnostics showed both clients had `Ace3=false SendComm=false Serialize=false`, so sync now falls back to native `C_ChatInfo` addon messages when AceComm/AceSerializer are unavailable.
- After comparing GBankManager, Rolling Pin now directly embeds AceComm/AceSerializer through LibStub instead of requiring AceAddon to construct the addon object first.
- After stepping back on the remaining live sync failure, the current local slice adds a GBankManager-style catch-up flow:
  - startup sends `sync_hello` once per active guild.
  - receiving `sync_hello` responds with rank permission, alias, nomination, vote, and award records.
  - the snapshot stream ends with `sync_snapshot_complete`.
  - `/rpa sync now` and `/rpa sync all` force hello plus full snapshot for live testing.
  - `/rpa syncdebug` now reports last hello and last snapshot counts in addition to transport state and last inbound/outbound.
- Follow-up live testing showed packets moving, aliases syncing, but history was still missing and nominations could be overwritten by a less-complete client.
- Root cause identified locally: award and nomination ids were plain per-client counters (`award:1`, `nom:1`), so same-id snapshot rows from another client could replace newer local records.
- Pushed sync hardening slice:
  - new award ids use `award:<Character-Realm>:<timestamp>:<sequence>`.
  - new nomination ids use `nom:<Character-Realm>:<timestamp>:<sequence>`.
  - inbound nominations reject stale same-id rows that would downgrade resolved rows or overwrite different same-timestamp rows.
  - inbound awards reject stale same-id rows that would replace newer local history.
  - legacy untimestamped authorized award deletes remain accepted.
- The updated sync/debug/dashboard build has been copied to both documented local Retail and PTR AddOns folders.
- Current local native-transport follow-up after `f61c8d3`:
  - native fallback now chunks encoded messages that exceed the 255-byte addon-message limit and reassembles `RPA2C` chunks before dispatch.
  - `Bootstrap.lua` routes native inbound strings through the chunk-aware decoder and ignores partial chunks without mutating data.
  - `/rpa syncdebug` now reports LibStub and ChatThrottleLib presence, native chunk state, outbound chunk counts, and receive summaries by payload type.
  - tests now simulate native message-size rejection and cover long nomination chunking plus chunked inbound nomination reassembly.
  - `docs/sync.md` documents chunked native fallback and new diagnostics.
  - design and implementation-plan docs were added under `docs/superpowers/`.
- Current local structure refactor after `f61c8d3`:
  - `RollingPinAwards.toc` now follows GBankManager-style load order: libraries, namespace/constants, data/domain, slash commands, sync modules, bootstrap, UI, events.
  - root modules moved into `Core/`, `Data/`, `Domain/`, `Sync/`, and `UI/`.
  - sync is split into `Sync/Codec.lua`, `Sync/Transport.lua`, `Sync/Snapshot.lua`, `Sync/Merge.lua`, `Sync/Diagnostics.lua`, and `Sync/Coordinator.lua`.
  - lifecycle wiring is split into `Core/Namespace.lua`, `Bootstrap.lua`, `Core/Events.lua`, and `Core/SlashCommands.lua`.
  - `tests/embedded_ace3_spec.lua` now verifies the GBankManager-style TOC structure and load order.
  - the refactored build has been copied to the documented local Retail AddOns folder; representative hashes match for `RollingPinAwards.toc`, `Bootstrap.lua`, `Core/Namespace.lua`, `Core/Events.lua`, `Sync/Codec.lua`, `Sync/Coordinator.lua`, and `UI/MinimapButton.lua`.
- Current local offline-catch-up follow-up after `84726f6`:
  - live testing showed online-to-online sync works, but an offline client could miss records created while offline.
  - diagnostics showed the joining client active on numeric guild `426137461` while its `Last hello` used provisional guild key `tyrrish rebellion`; the online peer rejected that hello as `wrong guild`, so it did not send the catch-up snapshot.
  - `Bootstrap.lua` now sends a fresh `sync_hello` when `RefreshActiveGuildContext()` migrates from a provisional name-based key to the stable guild id while sync is enabled.
  - `tests/sync_spec.lua` covers this with `sync sends a fresh hello when provisional guild key becomes stable`.
- Current local AceComm activation follow-up:
  - live diagnostics still showed `LibStub=false` and `Ace libs: Comm=false Serializer=false` even though the TOC embeds LibStub and AceComm.
  - root cause: real LibStub is a callable table with `__call`, while `Core/Namespace.lua` and `Bootstrap.lua` only accepted `type(LibStub) == "function"`.
  - `Core/Namespace.lua` and `Bootstrap.lua` now accept callable LibStub tables, so embedded `AceComm-3.0`, `AceSerializer-3.0`, `AceConsole-3.0`, `AceEvent-3.0`, and `AceDB-3.0` can activate.
  - `tests/WoWStubs.lua` now models LibStub as a callable table, and Ace integration tests cover the real shape.

## Priority Blocker
- Top priority remains live sync validation. Real in-game testing previously showed no client-to-client sync despite the local Lua harness being green.
- The local action-broadcast audit, hello/snapshot catch-up flow, and same-id stale snapshot guards are now pushed and deployed, but live two-client validation is still required before treating sync as fixed in game.
- The latest local native chunking follow-up is verified locally but has not yet been live-validated in two Retail clients.
- The latest offline-catch-up follow-up is verified locally but has not yet been live-validated in two Retail clients.
- The latest AceComm activation follow-up is verified locally but has not yet been live-validated in two Retail clients.
- Current tests prove validation helpers, envelope construction, AceComm registration, and dispatcher routing, but they may not prove the full live transport path or that every local mutation broadcasts:
  - `Sync/Coordinator.lua` owns `BuildEnvelope` and `DispatchEnvelope`.
  - `Sync/Transport.lua` owns `Broadcast` and `SendHello`.
  - `Sync/Merge.lua` owns `Accept*` merge/validation helpers.
  - `Bootstrap.lua` registers `Constants.COMM_PREFIX` in `OnEnable` and deserializes/routes inbound comms in `OnCommReceived`.
  - `tests/sync_spec.lua` includes broadcast and dispatcher tests using the stubbed AceComm/AceSerializer path.
  - Local direct awards, nominations, votes, approvals/rejections, rank-permission saves, alias changes, and award deletes now broadcast sync payloads in the Lua test harness.
- Likely failure areas to inspect first:
  - Inbound live AceComm may still differ from the local harness even though the stub now serializes outbound messages as strings and exercises `OnCommReceived` deserialization.
  - Native `C_ChatInfo` fallback now has local test coverage for mutation broadcasts, startup/manual hello, hello-triggered snapshot streaming, actor-stamped ids, stale award/nomination rejection, oversize message chunking, and chunked inbound reassembly, but still needs live two-client verification.
  - `/rpa syncdebug` now reports individual AceComm/AceSerializer embed state.
  - Self-sent messages may need to be ignored intentionally, while other same-guild senders must be accepted and rerender the UI.
  - Authorized sender validation depends on active guild context and rank permissions; a receiving client may reject a legitimate sender if the rank matrix/guild roster state has not converged.
  - `/rpa syncdebug` and `/rpa sync debug` now print copy-friendly sync diagnostics to chat.
- Former visual layering status:
  - User confirmed the original live layering issue is better after the content-host fix.
  - Continue only small visual validation after sync is moving data in live clients.
- UI polish follow-up after sync is stable:
  - Re-check dashboard geometry in the live client, especially equal left/right margins and the top stat-card row alignment with the `Top Rolling Pin Recipients` and `Recent Awards` sections.
  - Revisit any remaining card spacing, row readability, and parchment-safe boundaries only after sync is no longer destroying or hiding data.
- The current local shell removes the visible content-panel backdrop and inner shade entirely; interactive tab content lives in `contentHost`, parented to the main frame and clipped above the empty content panel.
- The leaderboard showcase modal is now parented above the main frame rather than inside the leaderboard tab panel, with a higher frame level so dragging it does not slide under clipped addon content.
- The main background art is visible again; the close X is offset to the parchment's top-right corner.
- The whole addon shell is raised to `TOOLTIP` strata and the showcase modal inherits the raised strata instead of dropping to `DIALOG`.
- Esc close is wired through both `UISpecialFrames` and an `OnKeyDown` handler.
- Local tests currently prove:
  - `contentHost` exists
  - `contentHost` is parented to the main frame, not the decorative content panel
  - `contentHost` clips children
  - `contentHost` frame level is above the content panel
  - content-panel backdrop, `innerShade`, and `innerShadeTexture` are not created
  - showcase modal parent/frame level sit above the content host
  - main background art is visible with calibrated dimensions and the close X is offset to the parchment corner
  - main shell, background art, tab rail, content panel, and content host use the raised strata
  - the frame hit rect expands over the parchment overhang for dragging
  - Esc closes the focused main window while non-Esc keys propagate
  - light row text opts out of outline while Admin helper/status text is two points larger
- Continue validating all visual polish in the live WoW client because the harness cannot fully reproduce Blizzard frame/backdrop draw ordering.

## Most Relevant Files
- `Sync/Codec.lua`
- `Sync/Transport.lua`
- `Sync/Snapshot.lua`
- `Sync/Merge.lua`
- `Sync/Diagnostics.lua`
- `Sync/Coordinator.lua`
- `Bootstrap.lua`
- `Core/Events.lua`
- `Core/SlashCommands.lua`
- `UI/Bridge.lua`
- `Domain/Awards.lua`
- `Domain/Nominations.lua`
- `Domain/Permissions.lua`
- `Data/Database.lua`
- `tests/sync_spec.lua`
- `tests/WoWStubs.lua`
- `docs/sync.md`
- `UI/Components.lua`
- `UI/MainFrame.lua`
- `UI/Styles.lua`
- `UI/MinimapButton.lua`
- `tests/bridge_spec.lua`

## Likely Next Investigation
1. Confirm both Retail clients are running the deployed `f61c8d3` build, then `/reload` both clients.
2. In two same-guild clients, run `/rpa syncdebug` on both clients immediately after reload/login and confirm `Last outbound` shows `sync_hello`.
3. Run `/rpa sync now` on the data-rich client, then `/rpa syncdebug` on both clients and confirm snapshot counts/inbound status update.
4. Offline catch-up regression:
  - keep the data-rich client online.
  - log the second client fully out/offline.
  - create a fresh nomination and direct award on the online client.
  - log the second client back in and `/reload` if needed.
  - run `/rpa syncdebug` on both clients and confirm the joining client sends/receives a stable numeric-guild hello and the online client responds with a snapshot.
  - verify the missed nomination and award appear on the formerly offline client without clearing SavedVariables.
5. Verify history and nominations specifically:
  - existing legacy/collided rows may already be damaged from pre-`f61c8d3` testing, so create fresh post-update test records before judging the fix.
  - do not clear SavedVariables or delete live records without explicit user approval.
6. Test normal local mutations afterward: nomination create, vote, approve/reject, direct award, delete, rank permission save, and alias merge.
7. Verify receiving-client merge behavior rerenders the visible tab after accepted inbound sync.
8. If history still does not appear, inspect `/rpa syncdebug` last inbound/outbound plus sender authorization for `award` payloads before changing transport again.

## Verification
- Full suite command:
  - `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`
- Last known result:
  - full suite passed after setting `RPA_LUA=C:\Users\Ziri\Documents\Codex\2026-05-11\GBankManager\.worktrees\gbankmanager-v1\tools\lua\lua.exe`
  - native comm fallback slice passed with the same `RPA_LUA`
  - sync-filtered tests passed after adding startup/manual hello and hello-triggered snapshot streaming
  - full suite passed immediately before committing `f61c8d3`
  - current native chunking follow-up full suite passed with `RPA_LUA=C:\Users\Ziri\OneDrive - ShipWreckCove\Documents\RollingPinAwards\tools\lua\lua54.exe`
  - current structure refactor full suite passed with `RPA_LUA=C:\Users\Ziri\OneDrive - ShipWreckCove\Documents\RollingPinAwards\tools\lua\lua54.exe`

## Local Deploy Targets
- Retail:
  - `C:\Gaming\World of Warcraft\_retail_\Interface\AddOns\RollingPinAwards`
- PTR:
  - `C:\Gaming\World of Warcraft\_xptr_\Interface\AddOns\RollingPinAwards`

## Untracked Local-Only Items Left Alone
- `.figma-make-inspect/`
- `.research/`

## Resume Order
1. Read this handoff.
2. Run `git status --short` and note the uncommitted native sync transport follow-up, GBankManager-style structure refactor, `.figma-make-inspect/`, `.research/`, and local `tools/` Lua runtime.
3. Run the full test suite with `RPA_LUA=tools\lua\lua54.exe` if making new code changes.
4. `/reload` both Retail clients so they load the copied native chunking/refactor build.
5. Validate sync in the real WoW client with two clients, using `/rpa syncdebug` and `/rpa sync now`.
6. Only after real sync works, continue UI polish cleanup, starting with dashboard margin/card alignment.

# 2026-06-04 UI Polish Follow-Up Implementation Plan

## Test First
- Add bridge/UI harness assertions for:
  - selected Burnt/Golden button variants on Award and Nominations.
  - shared Dashboard-safe tab panel offset across Dashboard, Award, Nominations, History, Leaderboard, and Admin.
  - Dashboard Recent Awards row count fitting within its section.
  - History delete confirmation frame level above row frames.
  - short awarded-by display names without realm suffixes.
  - public Nominations rows showing only Upvote/Downvote.
  - Admin moderation rows showing submitter plus Approve/Reject.
  - Admin canonical alias field showing a guild roster suggestion while typing.
  - navbar re-centering when Admin is hidden.
  - newest-first order in award-backed tables.
  - shared page headers aligned to page content and five font points larger.
  - Dashboard top-recipient and Leaderboard last visible rows staying inside table chrome.
  - navbar art paths switching between inactive and active selected textures.
  - legacy navbar button backdrops hidden behind rendered art.
  - background-relative navbar sizing margins of 188px with Admin and 257px without Admin, with both the Admin-visible middle gap and the no-Admin Nominations button centered to the header jewel using a 60px left offset.

## Implementation
- Add shared content geometry tokens to `UI/Styles.lua`.
- Add a reusable `selected` button variant in `UI/Components.lua`.
- Set confirmation dialogs above their parent content frame level.
- Add short awarded-by and guild roster suggestion helpers in `UI/Bridge.lua`.
- Apply shared panel geometry to all tab panel builders.
- Reduce Dashboard Recent Awards to three visible rows so rows do not collide with footer actions.
- Move Approve/Reject action rendering from `UI/Tabs/Nominations.lua` to `UI/Tabs/Admin.lua`.
- Add submitted-by text to moderation queue rows.
- Add canonical alias suggestion control and editbox text-change wiring in Admin.
- Update the WoW test stubs so editbox `SetText` triggers `OnTextChanged` like the live widget path.
- Add a reusable visible-tab layout pass and call it after tab visibility refresh.
- Sort public history rows by `createdAt` descending before History and Dashboard consume them.
- Move the shared content-panel title to the page content safe offset and add a reusable header font delta style token.
- Reduce the Dashboard top-recipient and Leaderboard visible row counts to fit their existing section heights.
- Copy the provided navbar PNGs into `Media/NavBar/`, create tab button textures from those assets, hide the old text label, and refresh selected art from `RenderActiveTab`.
- Remove the tab button backdrop once art owns the visual state.
- Add navbar margin and center-offset style tokens, then calculate visible button width from the main background art edges.

## Verification
- Run the full Lua suite with:
  - `$env:RPA_LUA=(Resolve-Path '.\tools\lua\lua54.exe').Path`
  - `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`
- Deploy the verified addon files to the documented Retail AddOns folder for live `/reload` validation.

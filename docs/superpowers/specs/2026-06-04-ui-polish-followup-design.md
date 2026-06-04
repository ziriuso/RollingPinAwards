# 2026-06-04 UI Polish Follow-Up Design

## Context
- Live sync validation is now looking stable, so the next slice returns to visible UI polish.
- The live screenshots show dashboard row/card overflow, inconsistent tab margins, weak Burnt/Golden selected states, History delete confirmation layering issues, public nomination rows carrying moderation actions, and Admin alias entry needing guild-roster assistance.

## Goals
- Keep tab content inside the parchment-safe Dashboard content bounds.
- Make selected Burnt/Golden controls visually distinct from unselected controls.
- Keep scroll rows within their table chrome and keep destructive confirmation dialogs above list rows.
- Move approval and rejection decisions into the Admin moderation queue while leaving public Nominations focused on voting.
- Show nomination submitter context in the moderation queue.
- Display awarded-by names without the realm suffix anywhere they are rendered as UI copy.
- Suggest guild roster character names while typing a canonical alias target.
- Center the visible navbar group when Admin is hidden for users without Admin access.
- Render award tables newest-first.
- Align shared page headers with the same parchment-safe left offset as page content.
- Increase shared page header font size by five points.
- Keep Dashboard top-recipient and Leaderboard visible rows within their table chrome.
- Replace text/backdrop navbar buttons with the provided page-specific navbar art.
- Show the `-selected` navbar art variant for the active page and the base art for inactive pages.
- Hide the legacy navbar button backdrop whenever the PNG art is rendered.
- Position the full six-button navbar with the 188px sizing margin, then center the group on the header jewel/visual centerline using a 32px left offset.
- Position the five-button navbar, when Admin is hidden, 257px from each background edge.

## Non-Goals
- No SavedVariables cleanup or live record deletion.
- No sync behavior changes beyond preserving existing broadcast paths through already tested service calls.
- No new artwork or major shell redesign.

## Design Notes
- `Styles.Layout.panelX`, `panelY`, and `panelWidth` define the shared safe content geometry used by all tab panels.
- `Components.SetButtonVariant("selected")` provides a reusable selected state for toggle-like controls.
- Bridge view models normalize awarded-by display names once so tabs do not each implement realm stripping differently.
- Admin owns moderation actions because approval/rejection is an authorized workflow, while Nominations remains the public submission/voting surface.
- Alias autocomplete uses guild roster prefix matches and exposes one click-to-fill suggestion below the canonical field.
- Tab visibility refresh now also reflows visible tab buttons, so the navbar remains balanced for both five-tab and six-tab users.
- Public history view models sort by `createdAt` descending before History and Dashboard Recent Awards render them; leaderboard detail rows already use the same newest-first created-time ordering.
- The shared content panel title uses `Styles.Layout.panelX` and `Styles.Layout.pageHeaderFontSizeDelta`, so every tab page title moves together.
- Dashboard top recipients and Leaderboard keep scrollbars for additional data rather than rendering the last visible row into footer/mode buttons.
- Navbar art lives under `Media/NavBar/` with filenames that match tab ids. `Components.SetTabButtonSelected` swaps between `<tab>.png` and `<tab>-selected.png` whenever the active tab changes.
- Navbar layout uses the main background art dimensions as the measurement frame. It derives the rendered button width from the visible tab count, configured gaps, and the requested background-edge margins; the Admin-visible group applies the dedicated centerline offset while the no-Admin group remains centered by its visible-button margins.

# Screenshot UI Fixes Design

## Scope

Apply the live screenshot markup as a focused UI polish slice:

- cap Award and Nomination reason inputs at 30 characters
- keep multi-result roster suggestions anchored under the field instead of drifting to the screen corner
- widen navigation buttons enough for `Nominations` and `Leaderboard`
- make selected toggle buttons visually distinct from secondary buttons
- align the Nominations submit button with the input row
- move Admin rank Save buttons away from the scrollbar
- rename `Open Moderation Queue` to `Moderation Queue`
- pin Dashboard stat-card headers to the card top and details to the card bottom
- change the first Dashboard stat-card detail to `Total Guildwide`
- shorten the Dashboard stat-card label `Pending Nominations` to `Nominations`
- darken selected Burnt/Golden and leaderboard filter buttons against secondary buttons
- move the settings gear farther right so it clears tab chrome
- rename `Toggle Anchors Mode` to `Toggle Anchors`
- keep Dashboard stat-card values in `#DF960A` without an outline
- render selected button text in `#DF960A`
- realign both six-button and five-button nav layouts with the Dashboard stat-card center gap using a 26-unit visual left offset
- widen Admin Alt Character and Main Character inputs equally
- move Add Mapping and View Mappings below the character mapping inputs
- provide three roster suggestions for both Alt Character and Main Character
- use `#C59F6B` for confirmation and admin modal backgrounds
- make roster suggestion dropdowns opaque and keep them above sibling action buttons
- use `#E0BC89` for toast and toast-anchor backgrounds
- use a solid backdrop texture for toasts, modal windows, confirmation dialogs, and roster suggestion rows so fills remain opaque in-game
- keep Admin modal headers and roster suggestion text in the standard brown header color
- render toast and toast-anchor backdrops at 50% opacity
- replace burnt and golden trophy art while keeping the existing media paths and per-surface sizing

## Design

These changes stay in reusable UI surfaces where possible. `UI/Components.lua` owns the selected-button palette, selected text color, tab button width calculation, stat-card label anchoring, permission-row save placement, and roster suggestion anchoring. Individual tab files own field limits, text copy, and per-tab coordinates.

The roster autocomplete fix uses frame-relative anchors between suggestion buttons instead of cached coordinate fields. That matches WoW frame behavior better and prevents extra suggestions from persisting at the top-left of the screen.

Modal windows and confirmation dialogs share the `modalFill` style color (`#C59F6B`). Roster autocomplete suggestion buttons use the same opaque fill and a raised frame level so selections stay visually above nearby controls like Admin Add Mapping/View Mappings. These surfaces use the solid `Interface\Buttons\WHITE8x8` backdrop instead of Blizzard's dialog background texture so the requested color renders as an opaque fill rather than a tinted translucent panel.

Admin modal title labels use the shared `cardHeader` role so moderation queue and character mapping headers retain the same brown treatment as other section headers. Roster autocomplete suggestion labels override the button default text color with the same brown header color for readability on the opaque modal fill.

The tab rail keeps the wider nav buttons, then applies a shared `-26` horizontal center offset for both six-button and five-button layouts. This compensates for the live screenshot's visual drift while keeping `Nominations` and `Leaderboard` unclipped.

Toast backgrounds read from `Styles.Toast.backgroundColor`, set to `#E0BC89` at 50% opacity, so both the reward toast and movable toast anchor use the same solid backdrop fill. Trophy art is replaced in-place at `Media/burnt-rolling-pin.png` and `Media/golden-rolling-pin.png`; existing UI sizing remains controlled by each component's current width/height configuration.

## Tests

`tests/bridge_spec.lua` covers the screenshot acceptance criteria against the Lua UI stubs:

- selected buttons are measurably darker than secondary buttons
- Nominations and Leaderboard tab labels have enough label width
- reason edit boxes clamp to 30 characters
- nomination submit aligns with nominee/reason inputs
- extra roster suggestions anchor under the previous suggestion button
- Admin Save buttons end before the scrollbar
- moderation button copy omits `Open`
- Dashboard card headers/details use top/bottom anchors, the footer reads `Total Guildwide`, the nominations card label is shortened, and card values use gold text without outline
- the settings gear x-offset and `Toggle Anchors` copy are asserted
- selected Burnt/Golden and leaderboard filter text turns gold
- Admin character mapping exposes equal-width Alt/Main inputs, lower action buttons, and three suggestions on both fields
- delete confirmation, character mappings, and moderation queue modals use `#C59F6B` on the solid backdrop texture
- Admin modal headers use the standard brown `cardHeader` role
- roster autocomplete suggestions use the opaque modal fill on the solid backdrop texture, render above Admin mapping action buttons, and use brown text
- six-button Nominations/History gap and five-button Nominations midpoint use the calibrated `-26` nav alignment offset
- reward toast and toast-anchor backdrops use `#E0BC89` at 50% opacity on the solid backdrop texture
- media tests assert the replaced burnt and golden trophy payload sizes

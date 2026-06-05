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

## Design

These changes stay in reusable UI surfaces where possible. `UI/Components.lua` owns the stronger selected-button palette, tab button width calculation, stat-card label anchoring, permission-row save placement, and roster suggestion anchoring. Individual tab files own field limits, text copy, and per-tab coordinates.

The roster autocomplete fix uses frame-relative anchors between suggestion buttons instead of cached coordinate fields. That matches WoW frame behavior better and prevents extra suggestions from persisting at the top-left of the screen.

## Tests

`tests/bridge_spec.lua` covers the screenshot acceptance criteria against the Lua UI stubs:

- selected buttons are measurably brighter than secondary buttons
- Nominations and Leaderboard tab labels have enough label width
- reason edit boxes clamp to 30 characters
- nomination submit aligns with nominee/reason inputs
- extra roster suggestions anchor under the previous suggestion button
- Admin Save buttons end before the scrollbar
- moderation button copy omits `Open`
- Dashboard card headers/details use top/bottom anchors and the footer reads `Total Guildwide`

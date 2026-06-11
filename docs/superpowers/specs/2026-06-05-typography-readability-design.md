# Typography Readability Design

## Goal

Make Rolling Pin Awards text easier to read across every page by replacing the current outlined gold treatment with shared typography roles.

## Style Roles

- Tab Header: 24 pt, Roboto Bold, `#73401E`, no outline.
- Tab Description: 16 pt, Roboto Regular, black, no outline.
- Card Header: 18 pt, Roboto Bold, `#73401E`, no outline.
- Card Value: 20 pt, Roboto Bold, `#73401E`, no outline.
- Card Descriptor: 16 pt, Roboto Regular, black, no outline.
- Table Row: 14 pt, Roboto Regular, black, no outline.
- Empty Table Row: 14 pt, Roboto Regular, white, no outline.
- Button Text: 16 pt, Roboto Bold, `#DFC6A3`, no outline.
- Compact Action Button Text: 14 pt, Roboto Bold, `#DFC6A3`, no outline.
- Modal Header: 18 pt, Roboto Bold, `#DFC6A3`, no outline.
- Leaderboard Detail Count: 21 pt, Roboto Bold, `#73401E`, no outline.

Roboto Regular and Roboto Bold are bundled under `Media/Fonts/` and applied directly through `FontString:SetFont()`.

## Implementation Shape

`UI/Styles.lua` will define shared typography tokens, including the Roboto font file paths. `UI/Components.lua` will apply those tokens from reusable creation points: content panel title/body, section titles, stat cards, buttons, generic labels, modal titles, and list rows. Individual tabs should only need changes where they bypass shared components or deliberately need a different role.

The final readability pass restores the original framed navigation buttons, reduces action-button sizing to avoid overflow, uses smaller table rows for award lists, and gives empty table rows their own white text role.

## Tests

The Lua harness will assert the role, font size, color, and absence of outline on representative controls for Dashboard, Award, Nominations, History, Leaderboard, Admin, and Settings. Existing outline assertions will be updated to prove outlines are removed rather than preserved.

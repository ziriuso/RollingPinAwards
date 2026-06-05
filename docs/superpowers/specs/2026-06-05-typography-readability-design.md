# Typography Readability Design

## Goal

Make Rolling Pin Awards text easier to read across every page by replacing the current outlined gold treatment with shared typography roles.

## Style Roles

- Tab Header: 24 pt, Roboto Bold, `#73401E`, no outline.
- Tab Description: 16 pt, Roboto Regular, black, no outline.
- Card Header and Card Value: 20 pt, Roboto Bold, `#73401E`, no outline.
- Card Descriptor: 16 pt, Roboto Regular, black, no outline.
- Button Text: 20 pt, Roboto Bold, `#DFC6A3`, no outline.

Roboto Regular and Roboto Bold are bundled under `Media/Fonts/` and applied directly through `FontString:SetFont()`.

## Implementation Shape

`UI/Styles.lua` will define shared typography tokens, including the Roboto font file paths. `UI/Components.lua` will apply those tokens from reusable creation points: content panel title/body, section titles, stat cards, buttons, generic labels, and list rows. Individual tabs should only need changes where they bypass shared components or deliberately need a different role.

## Tests

The Lua harness will assert the role, font size, color, and absence of outline on representative controls for Dashboard, Award, Nominations, History, Leaderboard, Admin, and Settings. Existing outline assertions will be updated to prove outlines are removed rather than preserved.

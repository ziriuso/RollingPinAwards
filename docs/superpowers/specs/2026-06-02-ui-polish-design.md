# Rolling Pin Awards UI Polish Design

Date: 2026-06-02

## Goal

Recompose the addon UI so it feels substantially closer to the Figma Make mockup while preserving the current MVP behavior, data flow, and raid-time usability.

## Scope

This slice adds:

- a chrome-first visual restyle of the addon shell
- recomposed shared UI surfaces and controls
- a stronger Figma-inspired dashboard composition
- selective use of extracted Make assets where they materially improve fidelity
- tooltip restyling to match the darker Figma panel treatment

This slice does not add:

- new award, nomination, alias, or permission behaviors
- backend or sync model changes except where a display field is needed for layout polish
- wholesale bitmap recreation of the entire addon window
- removal of existing functionality to match the mockup

## Source Reference

The Figma Make bundle establishes the intended visual direction:

- dark brown outer field
- soft wood-shadow frame
- pale parchment content board
- restrained brass and gold outlines
- burnt orange active actions
- compact tab rail
- tighter dashboard card composition
- dark tooltip with orange and gold accents

The polish pass should translate that direction into WoW-native frame construction instead of trying to ship the mockup as one large image.

## Visual System

### Outer Shell

The main addon window should read as a mounted fantasy ledger:

- darker wood-shadow outer frame
- pale parchment interior board
- subtle depth through layered backdrops and edge treatment
- less “default WoW panel” feel than the current MVP

### Header

The header should become cleaner and more editorial:

- stronger title hierarchy
- smaller subtitle line
- small rolling pin or burnt-flame motif if supported by the extracted assets or recreated iconography
- more whitespace than the current dense top edge

### Tabs

Tabs should be recomposed into a flatter brass/parchment rail:

- active tab uses burnt orange emphasis
- inactive tabs are muted brass/parchment
- smaller and cleaner than the current heavy red buttons
- hover and active states should remain readable in WoW

### Surfaces

Section containers, stat cards, rows, dialogs, and panels should shift from dark boxed sections to softer parchment cards with gold edging and restrained shadow treatment.

### Controls

Controls should feel like one coherent system:

- primary buttons use burnt orange
- secondary buttons use parchment/brass
- destructive actions remain clearly distinct
- edit boxes and text areas gain cleaner insets and softer panel treatment
- checkboxes and scrollbars should visually match the rest of the theme

### Tooltip

The tooltip should adopt the darker Figma treatment:

- dark panel
- gold or warm beige border
- orange highlight values
- improved spacing and hierarchy

## Component Scope

The polish pass should focus on the shared layer first.

Components to rework:

- main window frame
- header/title band
- tab rail and tab buttons
- content board
- section containers
- stat cards
- list rows
- primary and secondary buttons
- edit boxes and multi-line text areas
- checkboxes
- scrollbars
- modal and confirmation dialogs
- tooltip panel

The goal is for every tab to inherit the new look naturally through reusable components instead of one-off styling.

## Screen Scope

### Dashboard

The dashboard should move closest to the Figma composition:

- compact top stats row
- two-column content area
- leaderboard on one side
- recent awards on the other
- stronger footer action buttons

It should feel like the showcase screen for the addon.

### Award And Nominations

Keep the current behaviors, but tighten spacing and recombine the layout into clearer form blocks and list blocks with stronger visual hierarchy.

### History And Leaderboard

Use more polished row hierarchy so player name, reason, date, and count are easy to scan quickly.

### Settings And Admin

Polish these screens, but keep them slightly more utilitarian than the celebratory dashboard and history surfaces.

### Tooltip

Bring the tooltip visually close to the mockup while keeping it readable and compact in live play.

## Asset Strategy

Use the Figma Make bundle selectively.

Rules:

- extract only the assets that are small, reusable, and clearly helpful
- prefer WoW-native backdrops, borders, and layered frames for large surfaces
- avoid turning the addon into a single baked background image
- keep a coherent fallback rendering path if an extracted texture is missing

Expected selective uses:

- small motif or icon treatment
- subtle decorative accent texture if practical
- tooltip or badge cue references

Expected recreated elements:

- main frame
- parchment board
- tab rail
- cards
- buttons
- list rows
- form controls

## Architecture

Most work should stay in the UI layer:

- `UI/Components.lua`
- `UI/MainFrame.lua`
- `UI/Styles.lua`
- `UI/Tabs/Dashboard.lua`
- `UI/Tabs/Award.lua`
- `UI/Tabs/Nominations.lua`
- `UI/Tabs/History.lua`
- `UI/Tabs/Leaderboard.lua`
- `UI/Tabs/Settings.lua`
- `UI/Tabs/Admin.lua`
- `Tooltip.lua`

Add a small `Media/` folder only if extracted textures or icons are actually used.

Business logic modules should remain unchanged unless a tab needs an additional display-ready field for layout composition.

## Functional Guardrails

The polish pass must not:

- break slash-command open and close behavior
- hide critical raid-time actions behind extra clicks
- make text harder to read
- remove scrollability for long lists
- regress admin, alias, leaderboard, or nomination interactions

The UI may be recomposed, but the MVP functionality must remain intact.

## Testing

Required verification:

- full Lua suite remains green
- tab order and visibility remain correct
- dashboard still renders its recomposed sections
- history, leaderboard, nominations, and admin still expose scrollbars
- modal and tooltip behavior still works
- no control overlap or dead buttons are introduced by the restyle

## Notes

- this is a reviewable polish pass, not a final visual lock
- the first pass should maximize resemblance to the Figma shell and shared component feel
- if the visual direction is promising, a later pass can push further into asset fidelity after live review

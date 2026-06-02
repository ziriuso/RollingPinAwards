# Rolling Pin Awards Leaderboard Design

Date: 2026-06-02

## Goal

Add a new `Leaderboard` tab that shows who has received `The Burnt Rolling Pin`, how many pins each player has, and a click-through popup listing that player's approved award history.

## Scope

This slice adds:

- a new top-level `Leaderboard` tab
- a recipient leaderboard derived from approved awards
- a popup showing all approved award entries for a selected player
- human-readable award dates in leaderboard and popup rows

This slice does not add:

- separate persisted leaderboard storage
- leaderboard permissions
- pending nomination participation in leaderboard totals

## Data Rules

The leaderboard is derived from the existing approved awards dataset.

Rules:

- only `approved awards` count
- each recipient gets one leaderboard row
- the leaderboard is keyed by normalized recipient name
- every leaderboard row includes:
  - recipient name
  - total rolling pin count
  - most recent award timestamp
  - all approved award detail entries for that recipient

Sort order:

1. `pin count` descending
2. `most recent award date` descending
3. recipient name ascending

## Award Detail Display Rules

Each popup entry shows:

- award date
- award reason
- `Awarded By: <name>`

Display name source:

- for `direct` awards: show the actual awarder (`awardedBy`)
- for `nomination` awards: show the original nominator (`nominatedBy`) from the linked nomination

If a linked nomination cannot be found for an older nomination-sourced award, fall back to the award's stored `awardedBy` value so the row remains usable.

## UI Structure

Add `Leaderboard` between `History` and `Settings` in the main tab order.

Main tab content:

- scrollable leaderboard list
- each row shows:
  - recipient name
  - rolling pin count
  - most recent award date
  - `View` button

Popup behavior:

- clicking `View` opens an anchored modal-style popup inside the addon window
- popup title uses the selected player name
- popup body lists all approved award entries for that player
- each entry shows:
  - human-readable date
  - reason
  - `Awarded By: <name>`
- popup has a close button
- popup shows an empty state if the selected player has no resolvable approved award entries

## Architecture

Recommended implementation:

- add leaderboard aggregation in the UI bridge layer
- keep leaderboard state derived from awards instead of storing a second persistent leaderboard table
- add a shared UI date-format helper for human-readable timestamps
- add a dedicated `UI/Tabs/Leaderboard.lua`
- add a reusable popup or confirmation-style modal surface that can render read-only award detail rows

## View Models

Add a leaderboard-facing bridge method that returns rows shaped for the tab:

- `recipient`
- `pinCount`
- `mostRecentAwardAt`
- `mostRecentAwardText`
- `entries`

Each detail entry should expose:

- `awardId`
- `dateText`
- `reason`
- `displayAwardedBy`

## Testing

Required tests:

- leaderboard includes only approved awards
- leaderboard sorts by pin count descending, then most recent date descending
- direct awards show the actual awarder in popup rows
- nomination-sourced awards show the original nominator in popup rows
- linked nomination fallback preserves usable popup rows if nomination lookup fails
- leaderboard tab appears between `History` and `Settings`
- clicking `View` opens the selected player's detail popup
- long leaderboard lists remain scrollable
- date text is non-empty and human-readable

## Notes

- award dates are already stored internally as timestamps through `createdAt`
- this feature primarily exposes that existing timestamp data in user-facing UI
- the leaderboard is read-only for MVP

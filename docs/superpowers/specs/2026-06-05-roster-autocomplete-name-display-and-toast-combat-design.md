# Roster Autocomplete, Name Display, And Toast Combat Design

Date: 2026-06-05
Status: Approved for implementation

## Goals

- Award Recipient and Nomination Nominee fields suggest guild roster names as the user types.
- Character mapping remains a full-name mapping surface for alt-to-main relationships.
- Normal addon display hides realm/server suffixes.
- Toasts do not appear during combat; they queue and play after combat ends.
- Toasts can be closed manually with an X in the top-right corner.

## Name Display Rule

Full `Character-Realm` names are allowed only while entering/selecting a character name and inside the Admin character mapping screen. Elsewhere in the addon UI, names should display as short character names without the realm suffix.

Storage and sync still use the existing full-name values where they already do. The UI layer is responsible for choosing short display text outside the input/mapping contexts.

## UI Design

- Add a reusable roster autocomplete helper for edit boxes.
- Award Recipient uses the helper, shows up to three prefix matches, and fills the input with the selected full roster name.
- Nomination Nominee uses the helper, shows up to three prefix matches, and fills the input with the selected full roster name.
- Award and Nomination submit actions require selecting a guild roster suggestion; typed free-form names are not accepted.
- Admin mapping labels change:
  - `Alias` -> `Alt Character`
  - `Canonical Character` -> `Main Character`
- Admin mapping title/copy changes to describe character mapping rather than generic alias merge.
- Admin Alt Character and Main Character fields both use guild roster suggestions.

## Toast Design

- `Toast:ShowAwardToast(award)` checks `InCombatLockdown()`.
- If in combat, the award is appended to a local in-memory queue and no toast frame is shown.
- `Core/Events.lua` listens for `PLAYER_REGEN_ENABLED` and asks the toast service to flush one queued toast.
- Closing a toast hides the current toast. It does not delete queued toasts.
- Disabled toasts continue to suppress both immediate and queued display.

## Tests

- Award Recipient autocomplete suggests up to three matching full guild roster names and fills the selected one.
- Nomination Nominee autocomplete suggests up to three matching full guild roster names and fills the selected one.
- Award and Nomination submit attempts without a selected roster suggestion show an error and do not create records.
- Admin mapping labels/copy use Alt/Main Character wording and both fields autocomplete.
- Normal rows/status text avoid `-Realm` outside character mapping.
- Award toasts queue during combat and flush after `PLAYER_REGEN_ENABLED`.
- Toast close button hides the visible toast.

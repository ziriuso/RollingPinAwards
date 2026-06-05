# Toast Settings Implementation Plan

Date: 2026-06-05
Owner: Codex
Status: In progress

## Goal

Add local player settings for reward toasts, a settings gear on the main artwork, a movable toast anchor mode, reward toast popups for awards received by the current player, and chat reminders for pending nominations the current player has not voted on.

## Constraints

- Keep settings local/profile scoped, not guild synced.
- Keep controls reusable and test covered.
- Fire notifications only after inbound sync records are accepted.
- Do not stage local-only folders: `.figma-make-inspect/`, `.research/`, `tools/`.

## Test-First Work

1. Add a focused notification/settings spec covering:
   - Inbound accepted golden/burnt award to current player shows correct icon, title, and reason.
   - Disabled toast setting suppresses reward toasts.
   - Settings gear opens a settings page and the toast toggle persists locally.
   - Anchor mode shows a draggable anchor; right-click locks and saves position.
   - Pending unvoted nominations write chat reminders on login and on accepted inbound nomination.
2. Run the new tests and confirm they fail because the feature does not exist yet.
3. Implement data, UI, toast, notification, and sync wiring.
4. Run the focused tests, then the full suite.

## Implementation Notes

- Add `profile.localSettings` defaults for:
  - `toastsEnabled`
  - `toastAnchor.point`
  - `toastAnchor.relativePoint`
  - `toastAnchor.x`
  - `toastAnchor.y`
- Add database helpers to read/update local settings.
- Add reusable UI icon button support and styles for the gear/settings/toast.
- Add `UI/Toast.lua` for:
  - toast frame creation
  - award type icon/title selection
  - anchor mode
  - saved position restore
- Add `UI/SettingsPage.lua` for local settings controls.
- Add `Core/Notifications.lua` for:
  - award recipient matching
  - nomination vote checks
  - chat fallback output
  - login pending nomination reminders
- Wire notifications through `Sync:DispatchEnvelope` after successful accepts.
- Wire settings/toast services in `Bootstrap.lua`.

## Self-Review

The plan keeps the behavior local where it should be local, uses accepted sync records rather than raw inbound messages, and scopes UI additions to reusable controls plus two focused modules. The main ambiguity is exact in-game visual placement, which will need live-client validation after local tests pass.

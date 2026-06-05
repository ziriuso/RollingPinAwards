# Toast Settings And Anchor Design

## Goal

Add a local player settings surface for Rolling Pin Awards notifications without changing the six-tab navigation layout.

The feature adds:

- a gear button in the bottom-right area of the main parchment/background shell
- a settings page opened by that gear button
- a local `Enable reward toasts` setting
- a `Toggle Anchors Mode` control for positioning the toast anchor
- reward toasts for accepted inbound award sync payloads
- chat messages for new nominations that the current player has not voted on
- login reminders for pending nominations that the current player has not voted on

These settings are personal UI preferences and must not sync to the guild dataset.

## Scope

In scope:

- local SavedVariables defaults under `RollingPinAwardsDB.profile.localSettings`
- a main-window gear icon/button visible to all players
- a settings page inside the existing main frame content area
- a movable toast anchor frame shown only while anchor mode is active
- right-click locking of the toast anchor
- a `Test Toast` control that uses the same display path as real reward toasts
- chat notifications for unvoted pending nominations
- unit tests for defaults, settings UI state, anchor movement persistence, and notification trigger rules
- documentation updates for the new local settings and notification behavior

Out of scope:

- native Blizzard Edit Mode registration
- guild-synced notification preferences
- role/admin restrictions for local settings
- clearing SavedVariables or migrating live guild records
- sound effects or animation-heavy toast polish
- changing the existing tab rail art or adding a seventh nav tab

## Architecture

### Local Settings

`Data/Defaults.lua` will add a local profile settings table:

```lua
localSettings = {
  enableToasts = true,
  toastAnchor = {
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 160,
  },
}
```

`Data/Database.lua` will expose small local-settings helpers instead of letting UI code mutate SavedVariables directly:

- `GetLocalSettings()`
- `SetToastsEnabled(enabled)`
- `SaveToastAnchor(point, relativePoint, x, y)`

This keeps local preferences separate from guild datasets and makes the behavior testable.

### Settings Page

`UI/MainFrame.lua` will create a gear button after rendering the shell. The button should be anchored to the visible background art's bottom-right area, not the content panel. It opens a settings page in the same content host used by normal tabs, but settings is not added to `Styles.TabOrder`.

The settings page will live in `UI/SettingsPage.lua`, separate from the tab module folder so it does not imply a seventh nav tab. The page will use existing reusable controls:

- `CreateCheckButton` for `Enable reward toasts`
- `CreateButton` for `Toggle Anchors Mode`
- `CreateButton` for `Test Toast`

The previous removed Settings tab tests must be updated carefully: the old nav settings APIs should remain absent, but `profile.localSettings` and the gear-opened settings page should now exist.

### Toast Anchor

A new notification UI module, `UI/Toast.lua`, will own:

- creating the toast display frame
- creating the anchor frame
- showing and hiding anchor mode
- persisting the anchor point on lock
- rendering a test toast
- rendering a real award toast

Anchor mode behavior:

- `Toggle Anchors Mode` shows a visible anchor frame over `UIParent`
- left-drag moves the anchor
- right-click locks the anchor, saves its current point, hides anchor mode, and returns to normal behavior
- the anchor frame should be clamped to screen and should not require combat-protected operations
- the anchor mode frame should be addon-owned, not Blizzard Edit Mode-managed

Toast display behavior:

- if toasts are disabled, no toast frame is shown
- if enabled, reward toasts use the saved anchor
- default placement is center-ish above the player view until moved
- test toast uses the same path as real reward toasts but with test copy

### Notification Service

A small service, `Core/Notifications.lua`, will coordinate notification decisions. It should not own frame details; it calls the toast UI and chat-output helpers.

Notification rules:

- Accepted inbound `award` payload:
  - if `deleted == true`, do not toast
  - if sender/current player indicates self-origin, do not toast
  - if local setting `enableToasts == true`, show a reward toast
- Accepted inbound `nomination` payload:
  - if `status ~= "pending"` or `deleted == true`, do not print a vote prompt
  - if the current player has already voted on the nomination, do not print
  - otherwise print a chat message with enough context to open `/rpa` and vote
- Login or enable scan:
  - after guild context and services are ready, scan pending nominations
  - print chat lines for pending nominations where the current player has not voted
  - do not spam repeatedly during a single startup path; one scan per enable/guild context is enough

Existing chat output in `Core/SlashCommands.lua` should be generalized into a reusable helper or duplicated only if the helper remains tiny and well-contained.

### Sync Integration

`Sync/Coordinator.lua` already knows when inbound payloads are accepted. It should call notification logic after successful merge and before or after rerendering the active tab.

This keeps notification behavior tied to actual accepted data, not raw inbound messages. Rejected, stale, wrong-guild, duplicate, or unauthorized payloads should not notify.

Local mutation paths should not trigger self-notifications. Local direct awards and nominations already update visible UI through their domain services and broadcasts.

## UX Details

The gear button should be small and readable as a utility control. It should not compete with the close button or nav art. It opens settings for every player, including non-admin players.

The settings page should be simple:

- title: `Settings`
- checkbox row: `Enable reward toasts`
- anchor mode row: `Toast anchor`
- button: `Toggle Anchors Mode`
- button: `Test Toast`

Anchor mode should show clear anchor copy directly on the anchor frame, such as `Rolling Pin Awards Toast Anchor` and `Right-click to lock`.

Chat messages should be concise and copy-friendly. Example:

```text
Rolling Pin Awards: New nomination for Burny. Open /rpa to vote.
Rolling Pin Awards: You have 2 pending nominations to vote on. Open /rpa.
```

## Persistence

`localSettings` lives under the active AceDB/plain profile path. It is not stored in a guild dataset and is not included in sync snapshots.

Anchor persistence stores point data relative to `UIParent`:

- `point`
- `relativePoint`
- `x`
- `y`

The implementation should sanitize missing or invalid values back to defaults.

## Testing

Tests should be written first.

Required coverage:

- defaults include `profile.localSettings.enableToasts == true`
- database local-settings helpers read defaults and persist changes
- main frame renders a gear settings button without adding a seventh nav tab
- clicking the gear opens a settings page
- settings page checkbox toggles and persists `enableToasts`
- anchor mode creates a visible movable anchor
- right-clicking the anchor locks, hides anchor mode, and saves the position
- test toast uses the same toast frame and saved anchor as a real reward toast
- accepted inbound award triggers toast when enabled
- accepted inbound award does not trigger toast when disabled
- deleted awards and self-origin awards do not trigger toast
- accepted pending nomination prints a chat vote prompt only when current player has not voted
- login scan prints pending unvoted nomination reminders once per startup/guild context
- old assertions that removed synced/global settings stay valid in spirit: no old settings nav tab and no guild-synced settings object

## Risks

- WoW live frame behavior may differ from the Lua harness for dragging, right-click scripts, and frame strata. This needs live validation.
- Toasts triggered from sync should avoid noisy duplicates during full snapshot catch-up. The first implementation should prefer conservative notification rules and can suppress snapshot noise if live testing shows spam.
- Combat lockdown should be low risk because the toast and anchor are addon-owned ordinary frames, but anchor movement should still avoid protected operations.
- The settings gear placement depends on the current parchment background offsets. Tests should assert relative placement against `backgroundArt` so future background changes catch it.

## Validation Plan

Local:

```powershell
$env:RPA_LUA=(Resolve-Path '.\tools\lua\lua54.exe').Path
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1
```

Live:

1. Copy the build to Retail AddOns.
2. `/reload`.
3. Open `/rpa`, click the gear, toggle toasts off and on.
4. Toggle anchor mode, drag the anchor, right-click to lock, `/reload`, and confirm the anchor persists.
5. Use `Test Toast` to confirm placement.
6. In two clients, create or sync a new award and confirm the receiver sees a toast when enabled and not when disabled.
7. Create a new pending nomination and confirm unvoted recipients receive a chat prompt.
8. Reload with pending unvoted nominations and confirm the login reminder appears once.

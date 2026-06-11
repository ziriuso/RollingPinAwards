# Settings, Notifications, and Peers Polish

## Goals

- Add a saved addon scale control in Settings so players can tune the main window size without editing code.
- Make nomination and award chat output clearer by naming the Burnt or Golden rolling pin type first.
- Increase direct award and nomination reason fields to 100 characters while keeping dashboard rows width-aware.
- Let `/rpa peers` open its small sync peer table even when the main addon window is hidden.

## Decisions

- Addon scale is local/profile-scoped under `profile.localSettings.addonScale`, clamped from `0.8` to `1.25`, and rounded to two decimal places.
- Settings uses a reusable slider component rather than a page-specific control so future numeric settings can reuse the same pattern.
- Award chat announcements are local client messages, not guild chat sends. The addon marks announced award ids in local settings so sync snapshots and reloads do not replay the same announcement.
- Reward toasts remain recipient-only. The broader award announcement is separate from the toast path.
- `/rpa peers` is parented to `UIParent` and draggable, so it can be used as a lightweight diagnostic window without opening the main UI.

## Verification

- Database tests cover scale clamping and seen award-chat ids.
- Notification tests cover award-type nomination reminders, local award chat announcements, inbound non-recipient award announcements, and duplicate suppression.
- Bridge tests cover the 100-character reason fields, draggable standalone peers modal, and dynamic recent award row width.

# Minimap Launcher Preferences

## Goal

Improve the existing custom minimap button while keeping the angle-based minimap ring behavior.

The launcher preferences are local-only user settings. They do not sync, do not require admin permissions, and do not change guild data.

## Data Model

Local settings now include:

```lua
minimapButtonShown = true
minimapAngle = 225
```

`minimapAngle` is normalized into `0 <= angle < 360`.

## Minimap Button

The custom minimap button remains attached to the minimap ring. Dragging updates the stored angle from cursor position and immediately repositions the button on the ring. It does not use free-floating `StartMoving()` behavior.

The button follows the local GBankManager minimap pattern: a 32px button, Blizzard tracking-border chrome, and a 24px centered icon. The ring radius uses the minimap width plus a 5px outer-ring offset when available, with an 85px fallback.

## Addon Compartment

The TOC declares addon compartment handlers where supported by the client. The compartment entry is not user-toggleable from Settings because the client registers it from TOC metadata at load time.

## Settings

Settings includes a Minimap section:

- Show minimap button

The minimap button toggle shows or hides the custom button immediately while preserving the saved angle.

## Removed Commands

`/rpa background` and `/rpa bg` are no longer public slash commands.

## Verification

Tests cover local defaults, angle normalization, hide/show persistence, ring positioning, cursor drag angle updates, addon compartment click behavior, Settings toggles, removed background commands, and sync snapshot non-leakage.

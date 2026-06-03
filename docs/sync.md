# Sync

Rolling Pin Awards keeps all synced data scoped to the active guild dataset.

## Validation Rules

- Incoming payloads must match the active `guildKey`.
- Privileged payloads are accepted only when the sender satisfies the exact rank permission required for that payload type.
- Duplicate votes from the same voter on the same nomination are ignored.
- Votes are accepted only while the nomination remains `pending`.

Privileged payload mapping:

- direct award updates require `Create Direct Awards`
- award deletion updates require `Delete Awards`
- moderated nomination updates require `Manage Nominations`
- rank permission matrix updates require `Manage Addon Permissions`
- alias merge updates require `Manage Addon Permissions`

## Transport Notes

- Comm payloads use the addon prefix `RPAAwardsSync`.
- When Ace3 is available, sync envelopes flow through directly embedded `AceComm-3.0` and `AceSerializer-3.0`, matching the proven GBankManager transport pattern instead of requiring `AceAddon-3.0` to construct the addon object first.
- When Ace3 comm/serializer APIs are unavailable, sync falls back to native `C_ChatInfo.RegisterAddonMessagePrefix` and `C_ChatInfo.SendAddonMessage` with a small flat-field serializer for the existing payload shapes.
- `Core.lua` owns comm registration and inbound dispatch.
- `Sync.lua` owns envelope construction, outbound broadcast, and payload-type routing.
- Local mutations broadcast immediately for awards, nominations, nomination votes, rank permission changes, and alias mapping changes.
- Inbound accepted payloads rerender the active tab when the main window has already been rendered.

## Diagnostics

Use `/rpa syncdebug` or `/rpa sync debug` to print copy-friendly chat diagnostics:

- active guild key
- comm prefix and registration state
- Ace3 transport and serializer availability
- individual AceComm/AceSerializer embed state
- native addon-message fallback availability
- last outbound payload result
- last inbound payload result

## Persistence Notes

- When `AceDB-3.0` is available, Rolling Pin Awards uses the active Ace profile as the storage backing for the domain database.
- Without AceDB, the addon falls back to the plain `RollingPinAwardsDB.profile` table path already covered by the Lua-only tests.

## Current Service Surface

`Sync.lua` currently provides conservative acceptance helpers for:

- award updates
- award deletion updates
- nomination upserts
- nomination vote updates
- rank permission matrix updates
- alias merge updates

These helpers are intentionally data-first so the later AceComm transport layer can call into one validation path instead of duplicating merge logic in UI or command code.

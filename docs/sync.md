# Sync

Rolling Pin Awards keeps all synced data scoped to the active guild dataset.

## Validation Rules

- Incoming payloads must match the active `guildKey`.
- Privileged payloads are accepted only when the sender satisfies the exact rank permission required for that payload type.
- Duplicate votes from the same voter on the same nomination are ignored.
- Votes are accepted only while the nomination remains `pending`.

Privileged payload mapping:

- direct award updates require `Create Direct Awards`
- moderated nomination updates require `Manage Nominations`
- rank permission matrix updates require `Manage Addon Permissions/Settings`

## Transport Notes

- Comm payloads use the addon prefix `RPAAwardsSync`.
- When Ace3 is available, sync envelopes flow through `AceComm-3.0` and `AceSerializer-3.0`.
- `Core.lua` owns comm registration and inbound dispatch.
- `Sync.lua` owns envelope construction, outbound broadcast, and payload-type routing.

## Persistence Notes

- When `AceDB-3.0` is available, Rolling Pin Awards uses the active Ace profile as the storage backing for the domain database.
- Without AceDB, the addon falls back to the plain `RollingPinAwardsDB.profile` table path already covered by the Lua-only tests.

## Current Service Surface

`Sync.lua` currently provides conservative acceptance helpers for:

- award updates
- nomination upserts
- nomination vote updates
- rank permission matrix updates

These helpers are intentionally data-first so the later AceComm transport layer can call into one validation path instead of duplicating merge logic in UI or command code.

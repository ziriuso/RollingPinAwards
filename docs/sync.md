# Sync

Rolling Pin Awards keeps all synced data scoped to the active guild dataset.

## Validation Rules

- Incoming payloads must match the active `guildKey`.
- Privileged payloads such as awards or moderated nomination updates are accepted only when the sender satisfies the addon permission model.
- Duplicate votes from the same voter on the same nomination are ignored.
- Votes are accepted only while the nomination remains `pending`.

## Current Service Surface

`Sync.lua` currently provides conservative acceptance helpers for:

- award updates
- nomination upserts
- nomination vote updates
- permission roster updates

These helpers are intentionally data-first so the later AceComm transport layer can call into one validation path instead of duplicating merge logic in UI or command code.

# Sync

Rolling Pin Awards keeps all synced data scoped to the active guild dataset.

Runtime sync files live under the installable addon folder, `RollingPinAwards/`. Paths in this document such as `Bootstrap.lua`, `Core/Events.lua`, and `Sync/Transport.lua` are relative to that addon folder.

## Validation Rules

- Incoming payloads must match the active `guildKey`.
- Privileged payloads are accepted only when the sender satisfies the exact rank permission required for that payload type.
- Award and nomination snapshot rows are monotonic: stale same-ID records cannot replace newer local history or downgrade resolved nominations back to pending.
- Award and linked nomination deletions are stored as hidden tombstones, so stale offline snapshots cannot resurrect deleted rows.
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
- LibStub is a callable table in the embedded Ace3 library, so the addon treats callable tables and functions as valid LibStub providers before embedding AceComm/AceSerializer.
- When Ace3 comm/serializer APIs are unavailable, sync falls back to native `C_ChatInfo.RegisterAddonMessagePrefix` and `C_ChatInfo.SendAddonMessage` with a small flat-field serializer for the existing payload shapes.
- Native fallback messages larger than the addon-message limit are split into `RPA2C` chunks and reassembled before dispatch. Partial chunks do not mutate the database.
- `Bootstrap.lua` owns service initialization and comm registration.
- `Core/Events.lua` owns `ADDON_LOADED`, `PLAYER_LOGIN`, and `PLAYER_GUILD_UPDATE` lifecycle wiring.
- `Bootstrap.lua` routes inbound addon messages through `RPA:OnCommReceived`.
- `Sync/Codec.lua` owns native envelope serialization and `RPA2C` chunk reassembly.
- `Sync/Transport.lua` owns outbound Ace/native sends and hello broadcasts.
- `Sync/Snapshot.lua` owns deterministic snapshot streaming.
- `Sync/Merge.lua` owns `Accept*` merge and authorization helpers.
- `Sync/Diagnostics.lua` owns `/rpa syncdebug` output and receive summaries.
- `Sync/Coordinator.lua` owns envelope construction and payload-type routing.
- Local mutations broadcast immediately for awards, nominations, nomination votes, rank permission changes, and alias mapping changes.
- `Bootstrap.lua` sends a `sync_hello` once per active guild when sync enables, and `Core/Events.lua` sends again after guild context appears later through `PLAYER_GUILD_UPDATE`.
- If the client first sees only a provisional name-based guild key and later resolves the stable guild club id, `Bootstrap.lua` migrates the guild dataset key and sends a fresh `sync_hello` for the stable key so online peers can answer with the missed snapshot.
- Receiving `sync_hello` answers with a full flat record stream for rank permissions, aliases, nominations, votes, awards, and hidden delete tombstones, followed by `sync_snapshot_complete`.
- `/rpa sync now` and `/rpa sync all` force the same hello plus full snapshot stream for live two-client testing.
- `/rpa peers` and `/rpa sync peers` open a draggable local table of same-guild sync senders and the last date this client saw them. The peers table is parented to `UIParent`, so it can be opened without showing the main addon window. Run `/rpa sync now` first when you want to actively ping online addon users.
- Inbound accepted payloads rerender the active tab when the main window has already been rendered.
- Accepted award payloads write one local chat announcement per award id, including the Burnt or Golden rolling pin type, short recipient name, and reason. Local direct awards and nomination approvals write the same announcement immediately on the issuing client.
- Inbound accepted award payloads also notify the award recipient with a toast. If reward toasts are enabled locally, the recipient sees a centered toast using the Burnt or Golden rolling pin icon, a `You've Received a ... Rolling Pin` title, and the award reason. The local toast duration setting controls how long the toast remains visible.
- Reward toast award ids are marked as seen in local profile settings, so duplicate snapshot/catch-up payloads after reload or login do not replay the same toast.
- Award chat ids are also marked as seen in local profile settings, so duplicate snapshot/catch-up payloads do not replay the same chat announcement.
- Reward toasts do not display while `InCombatLockdown()` is true. They queue locally and flush after `PLAYER_REGEN_ENABLED`.
- Inbound accepted pending nomination payloads write a chat reminder when the local player has not voted yet. The reminder begins with the award type, such as `New Golden Rolling Pin nomination`.
- On addon enable, pending unvoted nominations in the active guild dataset write one local chat reminder so players know to open `/rpa` and vote.

## Record Identity

- New nomination ids use `nom:<Character-Realm>:<timestamp>:<sequence>`.
- New award ids use `award:<Character-Realm>:<timestamp>:<sequence>`.
- Legacy numeric ids such as `nom:1` and `award:1` remain readable, but new local records include the actor/timestamp to avoid cross-client id collisions.

## Diagnostics

Use `/rpa syncdebug` or `/rpa sync debug` to print copy-friendly chat diagnostics:

- active guild key
- comm prefix and registration state
- Ace3 transport and serializer availability
- individual AceComm/AceSerializer embed state
- native addon-message fallback availability
- LibStub and ChatThrottleLib presence
- native chunk state for the most recent chunked inbound message
- last outbound payload result
- last inbound payload result
- receive summaries by payload type, including accepted and rejected counts
- last hello result
- last snapshot counts

Use `/rpa peers` for the readable peer list when you only need to know which guild members have recently answered or sent Rolling Pin Awards sync traffic.

## Persistence Notes

- When `AceDB-3.0` is available, Rolling Pin Awards uses the active Ace profile as the storage backing for the domain database.
- Without AceDB, the addon falls back to the plain `RollingPinAwardsDB.profile` table path already covered by the Lua-only tests.
- Delete tombstones stay in the guild dataset id maps for sync conflict checks and snapshot catch-up, but normal UI/database reads filter them out so deleted awards and nominations remain absent from History, Dashboard, Leaderboard, and Nominations views.
- Player notification preferences, addon scale, toast duration, toast anchor placement, seen reward-toast ids, seen award-chat ids, and sync peer last-seen rows are stored under `profile.localSettings`. They are intentionally local/profile scoped and are not synced through guild datasets.
- Toast queues are session-local only. They are not persisted and are not included in sync snapshots.

## Current Service Surface

`Sync/Merge.lua` currently provides conservative acceptance helpers for:

- sync hello and snapshot completion markers
- award updates
- award deletion updates
- nomination upserts
- nomination vote updates
- rank permission matrix updates
- alias merge updates

These helpers are intentionally data-first so the later AceComm transport layer can call into one validation path instead of duplicating merge logic in UI or command code.

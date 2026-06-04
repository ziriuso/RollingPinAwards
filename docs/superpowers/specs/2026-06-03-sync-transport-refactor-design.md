# Rolling Pin Awards Sync Transport Refactor Design

## Problem

Live two-client testing shows packets moving, but the receiving client reports inbound nomination payloads as `missing nomination` and does not gain awards, nominations, or history after a snapshot. The sender reports that a snapshot was sent, but the current diagnostics only show outbound counts, not whether each record arrived intact or merged.

Before this refactor, the code kept codec, transport, snapshot streaming, merge validation, and diagnostics in one root `Sync.lua` file. That made the fallback transport look acceptable in unit tests even though the live path can differ sharply from the harness.

## Evidence

- Both screenshots show `Ace3=false`, `SendComm=false`, and `Serialize=false`, so the live sync path is native addon messages, not AceComm.
- Before the structure refactor, the deployed Retail addon contained the same root `Core.lua` and `Sync.lua` hashes as the repo and included AceComm/AceSerializer library folders, so the Ace failure was not a simple deploy mismatch.
- AceComm documents and implements automatic multipart delivery for long addon messages. Native `C_ChatInfo.SendAddonMessage` has a 255 byte payload limit and requires manual chunking.
- Before the native transport follow-up, the root `Sync.lua` sent native fallback messages directly with no chunking, no retry, no throttle, and no per-record merge result summary.
- Current tests prove that snapshot record types are emitted, but they do not simulate native message length limits, truncation, chunk ordering, or a full sender-to-receiver snapshot merge.

## Goals

- Make snapshot sync reliable when AceComm is unavailable.
- Make diagnostics distinguish transport send success from receiver merge success.
- Preserve existing merge validation for awards, nominations, votes, aliases, rank permissions, and deletes.
- Refactor sync into GBankManager-like folders so codec, transport, snapshot, merge policy, and diagnostics can be tested independently.
- Keep existing live data intact. Do not clear SavedVariables or delete live records as part of the fix.

## Non-Goals

- Do not redesign the award or nomination domain model.
- Do not change permission meanings or relax privileged action checks.
- Do not start UI polish until live sync can merge fresh post-fix records.
- Do not depend on external Ace3 being installed. Embedded libraries should work, but native fallback must remain safe.

## Architecture

The sync subsystem will be split into focused modules loaded by `RollingPinAwards.toc`:

- `Sync/Codec.lua`: native envelope encoding and decoding, including chunk-safe record serialization.
- `Sync/Transport.lua`: AceComm/native send path and hello broadcasts.
- `Sync/Snapshot.lua`: hello handling and full snapshot streaming in deterministic order.
- `Sync/Merge.lua`: existing `Accept*` merge and authorization helpers.
- `Sync/Diagnostics.lua`: `/rpa syncdebug` output and last inbound/outbound/snapshot summaries.
- `Sync/Coordinator.lua`: compatibility facade that constructs the module-backed sync service and routes payloads for existing callers.

Bootstrap initialization remains responsible for addon lifecycle and inbound dispatch, with event wiring in `Core/Events.lua` and transport details under `Sync/`.

## Transport Rules

AceComm remains preferred when both `SendCommMessage` and `Serialize` are available. Native fallback must chunk any encoded envelope that could exceed 255 bytes, reassemble chunks by sender/distribution/message id, and dispatch only complete envelopes.

Native chunks should be small enough to leave room for a marker, message id, sequence number, total count, and chunk body. The receiver must ignore incomplete chunks until the final assembled message is available. Invalid or orphaned chunks should update diagnostics without mutating data.

## Merge Rules

Snapshots will still stream rank permissions, aliases, nominations, votes, awards, and `sync_snapshot_complete` in that order. This preserves the existing dependency that votes require nominations before they can merge. Awards and nominations retain current stale-record protections.

Accepted inbound records should update a per-snapshot receive summary so live diagnostics can show counts such as accepted/rejected nominations and awards, not only the last inbound payload.

## Diagnostics

`/rpa syncdebug` should add:

- LibStub present or missing.
- ChatThrottleLib present or missing.
- AceComm/AceSerializer lookup status before and after embed.
- Native chunk state for the most recent message.
- Last receive summary by payload type, including accepted and rejected counts.
- Last rejection reason per payload type.

These fields should make the next live test answer whether the failure is library loading, transport chunking, authorization, stale merge rejection, or UI rerender.

## Testing

Tests must be written before production changes:

- A native long nomination envelope test must fail first because the current fallback sends a single oversize message.
- A native chunk reassembly test must prove a long record round-trips before dispatch.
- A full snapshot replay test must prove that an empty receiver gets nominations, votes, awards, aliases, and rank permissions from a populated sender.
- A diagnostics test must prove Ace library presence/lookup details appear even when embeds fail.
- Existing sync, database, award, nomination, command, and bridge tests must remain green.

## Deployment And Live Validation

After tests pass, copy the updated addon to the Retail AddOns folder. Live validation should use fresh post-fix records:

1. Reload both clients.
2. Run `/rpa syncdebug` on both clients.
3. Run `/rpa sync now` on the data-rich client.
4. Run `/rpa syncdebug` on both clients and inspect receive summaries.
5. Create a fresh nomination, vote, approval, and direct award after the fix.
6. Confirm the second client shows nominations and history without clearing SavedVariables.

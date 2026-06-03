# Sync Broadcast And Diagnostics Design

## Goal

Real client-to-client sync must cover the user-visible data families that guild members expect to move between clients:

- Awards
- Nominations
- Aliases
- Permissions

The addon also needs a small chat diagnostic command so live testing can capture transport state without restoring the removed Settings/debug UI.

## Behavior

- Direct awards broadcast an `award` payload after the local award is stored.
- Award deletions broadcast an `award` payload with `deleted = true`; receivers delete the award and linked nomination when present.
- Nomination creation broadcasts a `nomination` payload with `status = "pending"`.
- Nomination votes broadcast a `vote` payload with guild key, nomination id, voter, vote type, and timestamp.
- Nomination approvals broadcast both the approved `nomination` payload and the resulting `award` payload.
- Nomination rejections broadcast the rejected `nomination` payload.
- Rank permission saves broadcast a `rank_permissions` payload.
- Alias saves and deletes continue to broadcast `alias_mapping` payloads.
- Inbound accepted payloads rerender the active tab when the main frame has already rendered.
- `/rpa syncdebug` and `/rpa sync debug` print copy-friendly chat diagnostics.

## Verification

- Plain Lua tests use Ace3-aware stubs that serialize outbound comm payloads as strings and deserialize inbound messages through `Core.lua:OnCommReceived`.
- Regression tests cover mutation broadcasts for awards, nominations, aliases, and permissions.
- Regression tests cover authorized remote award deletion.
- Regression tests cover the sync diagnostic slash command output.

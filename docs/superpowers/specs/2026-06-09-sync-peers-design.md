# Sync Peers Design

## Goal

Add `/rpa peers` so a player can open a small in-game table showing which guild members have been seen sending Rolling Pin Awards sync traffic and when they were last seen.

## Design

The addon will keep a local profile-scoped peer ledger, grouped by guild key. Peer rows are updated whenever an inbound addon message comes from another player in the active guild and the message is valid enough to reach sync dispatch or peer-safe inbound recording. This data is intentionally local and is not included in guild sync snapshots.

The table opens from `/rpa peers`. `/rpa sync peers` will be accepted as an alias. The UI will use the existing main frame and component patterns, but the peers window will have an actual top-right X close button for quick dismissal. Rows show `Player` and `Last Seen`, sorted newest first, with an empty state when no peers have been recorded.

Players can run `/rpa sync now` first when they want to actively solicit replies from online addon users.

## Testing

- Database tests cover local peer storage shape, per-guild scoping, and newest-first listing.
- Sync tests cover inbound traffic recording peer last-seen timestamps.
- Command/UI tests cover `/rpa peers`, `/rpa sync peers`, the table rows, and the close X.
- Docs mention the command in `docs/sync.md` and testing coverage in `docs/testing.md`.

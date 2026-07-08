# Rolling Pin Awards

Rolling Pin Awards is a guild-only World of Warcraft addon for managing nominations, advisory voting, moderation, and awards for `The Burnt Rolling Pin`.

The installable addon lives under `RollingPinAwards/`. Root-level folders such as `tests/`, `tools/`, `docs/`, and `.github/` are repository infrastructure and are not part of the in-game addon folder.

## MVP Scope

- Ace3-aware addon lifecycle using `AceAddon-3.0`, `AceConsole-3.0`, `AceComm-3.0`, `AceSerializer-3.0`, and `AceDB-3.0` when available
- Embedded Ace3 library payload under `RollingPinAwards/Libs/` for self-contained local and packaged installs
- Guild-scoped datasets for the player's current guild only
- Exact-rank guild permission matrix with GM always retaining full access
- Public pending nominations with advisory upvotes
- Hidden downvote moderation signal for authorized officer/admin views
- Burnt and Golden rolling pin award types for shame and praise
- Direct awards, nomination approval/rejection, and award deletion gated by separate rank permissions
- Guild-shared alias merges for canonical nominee and recipient display without rewriting stored records
- Custom Lua UI with reusable tab and component modules
- Interactive tabs for dashboard, nominations, direct awards, history, leaderboard, and rank-based admin management
- Embedded custom artwork under `RollingPinAwards/Media/` for the polished parchment shell, award-type previews, rows, showcase modal, and primary action treatments
- Custom draggable minimap button artwork for toggling the addon window open and closed from the minimap ring
- Conservative guild-scoped sync validation helpers

## Slash Command

- `/rpa`

Current command support:

- `/rpa`
- `/rpa show`
- `/rpa toggle`
- `/rpa background`
- `/rpa bg`
- `/rpa syncdebug`
- `/rpa sync debug`
- `/rpa sync now`
- `/rpa sync all`
- `/rpa nominate Name-Realm "Reason"`

## UI Surface

The current MVP ships a functional in-game window with:

- a movable framed window
- a calibrated 1000x925 parchment background shell with the Rolling Pin Awards banner built into the top 150 pixels of the main artwork
- high-strata window layering so the full addon shell sits above Blizzard action bars and other UI elements
- Escape closes the addon while its main window is focused
- the parchment background overhang can be used to drag the addon, not just the logical inner frame
- a custom minimap button that toggles the addon window and can be dragged around the minimap ring
- a close button
- nomination submission and voting controls
- nomination and direct-award type selection for Burnt or Golden rolling pins
- rank-gated approve/reject controls inside the nominations view
- rank-gated direct award controls
- public award history with human-readable award dates and type icons
- a leaderboard with Burnt, Golden, and Combined views plus draggable clean-card recipient showcase popups
- confirmed award deletion for ranks that have delete permission
- admin-only rank permission matrix with checkbox editing by guild rank name
- admin alias merge management with a modal alias list for collapsing nicknames and alternate typed names into one canonical character
- scrollable long-list sections for nominations, history, leaderboard, and admin queues
- dashboard shortcuts between the main participation flows
- thin native WoW outline treatment on addon text for readability over parchment artwork
- outline-free dark text on lighter scroll-list rows, with larger Admin helper/status text for readability

## Sync Diagnostics

Use `/rpa syncdebug` or `/rpa sync debug` in game to print copy-friendly sync state to chat, including the active guild key, comm prefix registration, Ace3 transport availability, native addon-message fallback state, last inbound/outbound sync result, hello status, and snapshot status. Use `/rpa sync now` or `/rpa sync all` to start negotiated catch-up with online addon users.

## Runtime Notes

- The addon now directly embeds AceComm/AceSerializer through `LibStub`, matching the proven GBankManager pattern, when the Ace3 libraries are available in-game.
- The repo vendors the required Ace3 libraries under `RollingPinAwards/Libs/` for reproducible local and packaged installs.
- When `AceDB-3.0` is available, the domain database is backed by the active Ace profile instead of the plain SavedVariables fallback table.
- When AceComm/AceSerializer are unavailable in-game, sync falls back to native `C_ChatInfo` addon messages with a flat guild-scoped payload serializer.
- Awards, nominations, alias mappings, and rank permissions broadcast guild-scoped sync payloads when local user actions mutate them.
- On startup the addon requests the guild roster and sends a lightweight `sync_hello` peer-discovery message. Online peers answer with tiny `sync_hello_ack` summaries; the requester waits briefly, selects one best responder, and sends that peer a targeted `sync_snapshot_request`. Only that selected peer returns a debounced `WHISPER` snapshot stream for rank permissions, aliases, nominations, votes, and awards. Snapshot replies resolve the requester through the guild roster before whispering so cross-realm targets use their full `Character-Realm` name, and explicit sender realms are preserved when roster entries are short.
- New award and nomination ids include the local character and timestamp, and inbound award/nomination rows reject stale same-id snapshots so a less-complete client cannot overwrite newer local history or resolved nominations.
- The TOC continues to advertise `Ace3` as an optional dependency and groups the addon under the `Guild` addon-list category.

## Testing

See [docs/testing.md](docs/testing.md).

## Release

CurseForge publishing is tag-driven through GitHub Actions. Stable release tags such as `v1.0.0` run the Lua suite, build `RollingPinAwards-<version>.zip`, upload it to CurseForge, and attach the same zip to the matching GitHub Release.

Release setup and the maintainer checklist live in [docs/curseforge-release-workflow.md](docs/curseforge-release-workflow.md). The CurseForge project description copy lives in [docs/curseforge-description.md](docs/curseforge-description.md).

## Core Docs

- [Permissions](docs/permissions.md)
- [Sync](docs/sync.md)

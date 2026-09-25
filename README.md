# Rolling Pin Awards

Rolling Pin Awards is a guild-only World of Warcraft addon for managing nominations, advisory voting, moderation, and awards for `The Burnt Rolling Pin`.

The installable addon lives under `RollingPinAwards/`. Root-level folders such as `tests/`, `tools/`, `docs/`, and `.github/` are repository infrastructure and are not part of the in-game addon folder.

## WoW Forever Beta Branch

The `codex/wow-forever` branch targets the installed WoW Forever 1.60.1 beta (interface 16001). It keeps complete `First Last` character names for storage, sync, and display, because the full pair is region-unique and first names may repeat. Realm suffixes are not added in Forever. Guild roster and sync trust require an exact full-name match. This branch uses version `1.4.5-forever-beta.2` and has not been published as a Retail release.

The [Forever compatibility design](docs/superpowers/specs/2026-09-25-wow-forever-compatibility-design.md) records the beta assumptions and in-game checks still needed.

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
- In Forever: `/rpa nominate First Last "Reason"`

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
- The main window uses Blizzard's `UISpecialFrames` handling for Escape-to-close and does not change protected keyboard-input propagation while components are shown.
- Slash-command registration writes only the addon-owned `ROLLINGPINAWARDS` entry and never reassigns Blizzard's shared `SlashCmdList` binding.
- When `AceDB-3.0` is available, the domain database is backed by the active Ace profile instead of the plain SavedVariables fallback table.
- When AceComm/AceSerializer are unavailable in-game, sync falls back to native `C_ChatInfo` addon messages with a flat guild-scoped payload serializer.
- Awards, nominations, alias mappings, and rank permissions broadcast guild-scoped sync payloads when local user actions mutate them.
- On startup the addon requests the guild roster and sends a lightweight `sync_hello` peer-discovery message. Online peers answer with tiny `sync_hello_ack` summaries; the requester waits briefly, selects one best responder, and sends that peer a targeted `sync_snapshot_request`. Only that selected peer returns a debounced `WHISPER` snapshot stream for rank permissions, aliases, nominations, votes, and awards. Snapshot replies resolve the requester through the guild roster before whispering. In Forever, the complete `First Last` name is required; the existing Retail path uses `Character-Realm` targets.
- New award and nomination ids include the local character and timestamp, and inbound award/nomination rows reject stale same-id snapshots so a less-complete client cannot overwrite newer local history or resolved nominations.
- The TOC continues to advertise `Ace3` as an optional dependency and groups the addon under the `Guild` addon-list category.

## Testing

See [docs/testing.md](docs/testing.md).

## Release

The existing Retail CurseForge publishing workflow is tag-driven through GitHub Actions. This Forever beta branch has no release tag; its five-digit interface and separate game flavor need release-tool validation before publishing.

Release setup and the maintainer checklist live in [docs/curseforge-release-workflow.md](docs/curseforge-release-workflow.md). The CurseForge project description copy lives in [docs/curseforge-description.md](docs/curseforge-description.md).

## Core Docs

- [Permissions](docs/permissions.md)
- [Sync](docs/sync.md)

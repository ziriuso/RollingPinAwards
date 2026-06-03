# Rolling Pin Awards

Rolling Pin Awards is a guild-only World of Warcraft addon for managing nominations, advisory voting, moderation, and awards for `The Burnt Rolling Pin`.

## MVP Scope

- Ace3-aware addon lifecycle using `AceAddon-3.0`, `AceConsole-3.0`, `AceComm-3.0`, `AceSerializer-3.0`, and `AceDB-3.0` when available
- Embedded Ace3 library payload under `Libs/` for self-contained local and packaged installs
- Guild-scoped datasets for the player's current guild only
- Exact-rank guild permission matrix with GM always retaining full access
- Public pending nominations with advisory upvotes
- Hidden downvote moderation signal for authorized officer/admin views
- Burnt and Golden rolling pin award types for shame and praise
- Direct awards, nomination approval/rejection, and award deletion gated by separate rank permissions
- Guild-shared alias merges for canonical nominee and recipient display without rewriting stored records
- Custom Lua UI with reusable tab and component modules
- Interactive tabs for dashboard, nominations, direct awards, history, leaderboard, and rank-based admin management
- Embedded custom artwork under `Media/` for the polished parchment shell, award-type previews, rows, showcase modal, and primary action treatments
- Custom minimap button artwork for toggling the addon window open and closed
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
- `/rpa nominate Name-Realm "Reason"`

## UI Surface

The current MVP ships a functional in-game window with:

- a movable framed window
- a calibrated parchment background shell with the Rolling Pin Awards banner built into the main artwork
- high-strata window layering so the full addon shell sits above Blizzard action bars and other UI elements
- Escape closes the addon while its main window is focused
- the parchment background overhang can be used to drag the addon, not just the logical inner frame
- a custom minimap button that toggles the addon window
- a close button
- nomination submission and voting controls
- nomination and direct-award type selection for Burnt or Golden rolling pins
- rank-gated approve/reject controls inside the nominations view
- rank-gated direct award controls
- public award history with human-readable award dates and type icons
- a leaderboard with Burnt, Golden, and Combined views plus draggable screenshot-friendly parchment showcase popups
- confirmed award deletion for ranks that have delete permission
- admin-only rank permission matrix with checkbox editing by guild rank name
- admin alias merge management with a modal alias list for collapsing nicknames and alternate typed names into one canonical character
- scrollable long-list sections for nominations, history, leaderboard, and admin queues
- dashboard shortcuts between the main participation flows
- thin native WoW outline treatment on addon text for readability over parchment artwork
- outline-free dark text on lighter scroll-list rows, with larger Admin helper/status text for readability

## Sync Diagnostics

Use `/rpa syncdebug` or `/rpa sync debug` in game to print copy-friendly sync state to chat, including the active guild key, comm prefix registration, Ace3 transport availability, native addon-message fallback state, and the last inbound/outbound sync result.

## Runtime Notes

- The addon now directly embeds AceComm/AceSerializer through `LibStub`, matching the proven GBankManager pattern, when the Ace3 libraries are available in-game.
- The repo now vendors the required Ace3 libraries under `Libs/` and also includes `.pkgmeta` externals so packager-driven releases stay reproducible.
- When `AceDB-3.0` is available, the domain database is backed by the active Ace profile instead of the plain SavedVariables fallback table.
- When AceComm/AceSerializer are unavailable in-game, sync falls back to native `C_ChatInfo` addon messages with a flat guild-scoped payload serializer.
- Awards, nominations, alias mappings, and rank permissions broadcast guild-scoped sync payloads when local user actions mutate them.
- The TOC continues to advertise `Ace3` as an optional dependency.

## Testing

See [docs/testing.md](docs/testing.md).

## Core Docs

- [Permissions](docs/permissions.md)
- [Sync](docs/sync.md)

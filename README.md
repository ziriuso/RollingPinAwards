# Rolling Pin Awards

Rolling Pin Awards is a guild-only World of Warcraft addon for managing nominations, advisory voting, moderation, and awards for `The Burnt Rolling Pin`.

## MVP Scope

- Ace3-aware addon lifecycle using `AceAddon-3.0`, `AceConsole-3.0`, `AceComm-3.0`, `AceSerializer-3.0`, and `AceDB-3.0` when available
- Embedded Ace3 library payload under `Libs/` for self-contained local and packaged installs
- Guild-scoped datasets for the player's current guild only
- Exact-rank guild permission matrix with GM always retaining full access
- Public pending nominations with advisory upvotes
- Hidden downvote moderation signal for authorized officer/admin views
- Direct awards, nomination approval/rejection, and award deletion gated by separate rank permissions
- Custom Lua UI with reusable tab and component modules
- Interactive tabs for dashboard, nominations, direct awards, history, settings, and rank-based admin management
- Conservative guild-scoped sync validation helpers

## Slash Command

- `/rpa`

Current command support:

- `/rpa`
- `/rpa show`
- `/rpa toggle`
- `/rpa nominate Name-Realm "Reason"`

## UI Surface

The current MVP ships a functional in-game window with:

- a movable framed window
- a close button
- nomination submission and voting controls
- rank-gated approve/reject controls inside the nominations view
- rank-gated direct award controls
- public award history
- confirmed award deletion for ranks that have delete permission
- local settings toggles
- admin-only rank permission matrix with checkbox editing by guild rank name
- scrollable long-list sections for nominations, history, and admin queues
- dashboard shortcuts between the main participation flows

## Runtime Notes

- The addon now prefers an Ace3-backed runtime when `LibStub` and the Ace3 libraries are available in-game.
- The repo now vendors the required Ace3 libraries under `Libs/` and also includes `.pkgmeta` externals so packager-driven releases stay reproducible.
- When `AceDB-3.0` is available, the domain database is backed by the active Ace profile instead of the plain SavedVariables fallback table.
- The TOC continues to advertise `Ace3` as an optional dependency.

## Testing

See [docs/testing.md](docs/testing.md).

## Core Docs

- [Permissions](docs/permissions.md)
- [Sync](docs/sync.md)

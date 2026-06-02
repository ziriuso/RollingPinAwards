# Rolling Pin Awards

Rolling Pin Awards is a guild-only World of Warcraft addon for managing nominations, advisory voting, moderation, and awards for `The Burnt Rolling Pin`.

## MVP Scope

- Ace3-aware addon lifecycle using `AceAddon-3.0`, `AceConsole-3.0`, `AceComm-3.0`, and `AceSerializer-3.0` when available
- Guild-scoped datasets for the player's current guild only
- GM-managed officer permission roster
- Public pending nominations with advisory upvotes
- Hidden downvote moderation signal for authorized officer/admin views
- Direct awards and nomination approval/rejection for authorized users
- Custom Lua UI shell with reusable tab and component modules
- Conservative guild-scoped sync validation helpers

## Slash Command

- `/rpa`

Current command support:

- `/rpa`
- `/rpa show`
- `/rpa toggle`
- `/rpa nominate Name-Realm "Reason"`

## Runtime Notes

- The addon now prefers an Ace3-backed runtime when `LibStub` and the Ace3 libraries are available in-game.
- The current repository keeps the addon code Ace3-compatible without vendoring the libraries directly.
- The TOC continues to advertise `Ace3` as an optional dependency.

## Testing

See [docs/testing.md](docs/testing.md).

## Core Docs

- [Permissions](docs/permissions.md)
- [Sync](docs/sync.md)

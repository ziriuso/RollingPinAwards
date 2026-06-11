# Rolling Pin Awards Addon Structure Refactor Design

## Context

Rolling Pin Awards started as a compact flat-file addon. That made the MVP easy to iterate on, but the current sync debugging exposed the same problem GBankManager already solved: transport, persistence, domain rules, UI, and lifecycle code need clear ownership boundaries.

This refactor follows the local WoWAddonDevGuide structure guidance and mirrors the principles used in GBankManager:

- libraries load first and stay isolated under `Libs/`
- the shared namespace and constants load before data/domain modules
- persistence modules live under `Data/`
- award, nomination, permission, roster, time, guild, and utility logic live under `Domain/`
- bootstrap creates runtime services after modules are available
- sync is split by codec, transport, snapshot, merge, diagnostics, and coordination responsibilities
- UI remains under `UI/`, including the minimap button
- event and slash-command wiring load last

## Goals

- Make the TOC load order readable and comparable to GBankManager.
- Preserve the existing public addon API: `RPA.Awards`, `RPA.Nominations`, `RPA.Database`, `RPA.Sync`, `RPA.Commands`, and `RPA:OnInitialize()`.
- Preserve current sync behavior, including native chunking and receive summaries.
- Keep tests as the proof that the refactor is behavior-preserving.
- Update docs so handoffs and sync notes reference the new paths.

## Non-Goals

- Do not clear SavedVariables or mutate live saved data.
- Do not change award, nomination, alias, permission, or vote merge semantics as part of the structure move.
- Do not add a new external dependency.
- Do not redesign UI polish in this slice.

## Target Layout

```text
Core/
  Namespace.lua
  Constants.lua
  SlashCommands.lua
  Events.lua
Data/
  Defaults.lua
  Database.lua
Domain/
  Awards.lua
  GuildContext.lua
  Nominations.lua
  Permissions.lua
  RosterPermissions.lua
  Time.lua
  Utils.lua
Sync/
  Codec.lua
  Coordinator.lua
  Diagnostics.lua
  Merge.lua
  Snapshot.lua
  Transport.lua
Bootstrap.lua
UI/
  MinimapButton.lua
  Bridge.lua
  Styles.lua
  Components.lua
  Tabs/
```

## Expected TOC Order

1. Embedded libraries.
2. `Core/Namespace.lua` and `Core/Constants.lua`.
3. `Data/Defaults.lua`, then domain and database modules.
4. `Core/SlashCommands.lua`.
5. Sync modules, with codec/transport/snapshot/merge/diagnostics before coordinator.
6. `Bootstrap.lua`.
7. UI modules.
8. `Core/Events.lua`.

`Core/Events.lua` loads last so event handlers can safely call the fully assembled addon after all modules are registered.

## Verification

- A TOC structure test must fail before the move and pass afterward.
- Full Lua suite must pass with the local Lua runtime.
- Sync-focused tests must still prove native chunking, reassembly, snapshots, merges, and diagnostics.


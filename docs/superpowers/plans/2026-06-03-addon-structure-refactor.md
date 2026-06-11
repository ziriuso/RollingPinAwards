# Rolling Pin Awards Addon Structure Refactor Plan

## Checklist

- [x] Add a failing TOC structure/load-order test for the GBankManager-style folder layout.
- [x] Create `Core/`, `Data/`, `Domain/`, and `Sync/` directories.
- [x] Move flat modules into their target folders and update `RollingPinAwards.toc`.
- [x] Split `Core.lua` into namespace, bootstrap, slash fallback, and event lifecycle files.
- [x] Split `Sync.lua` into codec, transport, snapshot, merge, diagnostics, and coordinator modules while keeping the same `RPA.Sync:*` API.
- [x] Update tests and docs that reference old root paths.
- [x] Run the full Lua test suite with `tools/lua/lua54.exe`.
- [x] Update the handoff with the new structure and verification result.

## Acceptance Criteria

- `wow.loadAddon()` loads through the TOC without root module path assumptions.
- Existing award, nomination, permission, alias, UI bridge, and sync tests pass.
- `/rpa syncdebug` behavior remains covered and still reports native chunk state and receive summaries.
- Project docs identify new module ownership paths.

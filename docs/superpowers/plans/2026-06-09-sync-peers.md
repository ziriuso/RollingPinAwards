# Sync Peers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `/rpa peers` to show a closeable in-game table of addon sync peers and their last-seen timestamps.

**Architecture:** Store peer presence in local profile settings, scoped by active guild key, and update it from inbound sync traffic. Expose the sorted rows through `UI/Bridge.lua`, render them in a small modal owned by `UI/MainFrame.lua`, and route `/rpa peers` plus `/rpa sync peers` through the existing command service.

**Tech Stack:** WoW Lua addon, SavedVariables/AceDB profile storage, native `CreateFrame` UI, local Lua test harness.

---

### Task 1: Peer Storage And View Model

**Files:**
- Modify: `tests/database_spec.lua`
- Modify: `tests/bridge_spec.lua`
- Modify: `RollingPinAwards/Data/Defaults.lua`
- Modify: `RollingPinAwards/Data/Database.lua`
- Modify: `RollingPinAwards/UI/Bridge.lua`

- [ ] **Step 1: Write failing tests**

Add tests that expect peer rows to persist under local settings by guild key and expect the bridge to expose sorted rows with formatted dates.

- [ ] **Step 2: Verify red**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 database bridge`

Expected: FAIL because `RecordSyncPeer`, `GetSyncPeers`, and `GetSyncPeersViewModel` do not exist.

- [ ] **Step 3: Implement storage and bridge methods**

Add `localSettings.syncPeersByGuild`, database methods to record/list peers, and a bridge view model that formats timestamps through `Time:FormatDate`.

- [ ] **Step 4: Verify green**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 database bridge`

Expected: PASS.

### Task 2: Sync Recording

**Files:**
- Modify: `tests/sync_spec.lua`
- Modify: `RollingPinAwards/Sync/Diagnostics.lua`
- Modify: `RollingPinAwards/Sync/Coordinator.lua`

- [ ] **Step 1: Write failing test**

Add a sync test that feeds a same-guild inbound `sync_hello` from another character and expects that sender to appear in the peer list with the current server time.

- [ ] **Step 2: Verify red**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 sync`

Expected: FAIL because inbound dispatch does not record peer rows.

- [ ] **Step 3: Implement sync peer recording**

Teach `RecordInbound` to record a peer when the inbound result has an active-guild payload, sender, and successful or dispatchable addon message. Keep self-origin and wrong-guild traffic out.

- [ ] **Step 4: Verify green**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 sync`

Expected: PASS.

### Task 3: `/rpa peers` Modal

**Files:**
- Modify: `tests/commands_spec.lua`
- Modify: `tests/bridge_spec.lua`
- Modify: `RollingPinAwards/Core/SlashCommands.lua`
- Modify: `RollingPinAwards/UI/Components.lua`
- Modify: `RollingPinAwards/UI/MainFrame.lua`

- [ ] **Step 1: Write failing tests**

Add command and UI tests that expect `/rpa peers` and `/rpa sync peers` to open a modal titled `Sync Peers`, render `Player` and `Last Seen`, show rows, and close through a top-right X button.

- [ ] **Step 2: Verify red**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 commands bridge`

Expected: FAIL because the command and modal do not exist.

- [ ] **Step 3: Implement command and modal**

Add `MainFrame:ShowSyncPeers()` and an X-close modal using existing reusable component helpers. Route `/rpa peers` and `/rpa sync peers` to that method.

- [ ] **Step 4: Verify green**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 commands bridge`

Expected: PASS.

### Task 4: Docs And Full Verification

**Files:**
- Modify: `docs/sync.md`
- Modify: `docs/testing.md`

- [ ] **Step 1: Update docs**

Document `/rpa peers`, `/rpa sync peers`, and the fact that peer presence is local/profile-scoped.

- [ ] **Step 2: Run full suite**

Run: `$env:RPA_LUA=(Resolve-Path '.\tools\lua\lua54.exe').Path; powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: PASS.

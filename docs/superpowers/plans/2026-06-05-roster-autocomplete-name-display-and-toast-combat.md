# Roster Autocomplete Name Display And Toast Combat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add reusable guild roster autocomplete, short-name display rules, Admin alt-to-main copy, combat-safe queued toasts, and toast manual close.

**Architecture:** Keep full names in storage/sync and apply short-name presentation in UI tabs. Add a reusable `Components.AttachRosterAutocomplete` helper for all character inputs. Keep combat queuing inside `UI/Toast.lua` and trigger flushing from `Core/Events.lua`.

**Tech Stack:** WoW Lua addon UI, SavedVariables-backed data, local Lua test harness.

---

### Task 1: Roster Autocomplete And Mapping Copy

**Files:**
- Modify: `UI/Components.lua`
- Modify: `UI/Tabs/Award.lua`
- Modify: `UI/Tabs/Nominations.lua`
- Modify: `UI/Tabs/Admin.lua`
- Test: `tests/bridge_spec.lua`

- [ ] **Step 1: Write failing UI tests**

Add tests that type `Off` into Award, Nomination, Alt Character, and Main Character fields and assert visible suggestions fill `Officerone-Stormrage`.

- [ ] **Step 2: Run focused tests**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 "autocomplete"`
Expected: FAIL because Award/Nomination autocomplete does not exist and Admin only has one canonical suggestion.

- [ ] **Step 3: Implement reusable autocomplete**

Add `Components.AttachRosterAutocomplete(input, suggestionButton, bridge)` that calls `bridge:GetGuildRosterNameSuggestions(input:GetText(), 1)`, shows `Use Character-Realm`, and fills the input on click.

- [ ] **Step 4: Wire fields**

Attach the helper to Award Recipient, Nomination Nominee, Admin Alt Character, and Admin Main Character fields. Rename Admin copy to Alt/Main Character wording.

- [ ] **Step 5: Run focused tests**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 "autocomplete"`
Expected: PASS.

### Task 2: Short Display Names Outside Mapping

**Files:**
- Modify: `UI/Tabs/Award.lua`
- Modify: `UI/Tabs/Nominations.lua`
- Modify: `UI/Tabs/History.lua`
- Modify: `UI/Tabs/Leaderboard.lua`
- Modify: `UI/Tabs/Admin.lua`
- Test: `tests/bridge_spec.lua`

- [ ] **Step 1: Write failing display tests**

Add tests proving status/list text does not show `-Stormrage` outside input fields and character mapping.

- [ ] **Step 2: Run focused tests**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 "realm"`
Expected: FAIL where UI rows currently render full names.

- [ ] **Step 3: Implement short-name display**

Use existing `shortNominee`, `shortRecipient`, and `Utils.GetShortCharacterName` for row/status copy outside mapping. Keep mapping rows full.

- [ ] **Step 4: Run focused tests**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 "realm"`
Expected: PASS.

### Task 3: Combat Queue And Toast Close

**Files:**
- Modify: `UI/Toast.lua`
- Modify: `Core/Events.lua`
- Test: `tests/notifications_spec.lua`

- [ ] **Step 1: Write failing toast tests**

Add tests for combat queue, `PLAYER_REGEN_ENABLED` flush, and close button hiding the toast.

- [ ] **Step 2: Run focused tests**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 "combat"`
Expected: FAIL because toasts display immediately in combat and there is no close button.

- [ ] **Step 3: Implement queue and close**

Add `queuedAwards`, `IsInCombat`, `FlushQueuedToasts`, and top-right `closeButton` on the toast frame.

- [ ] **Step 4: Register event**

Register `PLAYER_REGEN_ENABLED` in `Core/Events.lua` and call `RPA.toast:FlushQueuedToasts()`.

- [ ] **Step 5: Run focused and full tests**

Run focused tests, then `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`.
Expected: all tests pass.

## Self-Review

This plan covers all approved requirements and preserves storage/sync compatibility. It explicitly keeps full names only in inputs/suggestions and character mapping while adding combat-safe toast behavior.

# Toast Duration Setting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a local setting that controls how long reward toast notifications stay visible.

**Architecture:** Store the duration under `RollingPinAwardsDB.profile.localSettings.toastDurationSeconds`, validate it in the database shape helper, and expose one setter that clamps values to 3-15 seconds. The settings page renders a compact minus/plus stepper and the toast renderer reads the saved value when scheduling `C_Timer.After`.

**Tech Stack:** WoW Lua addon modules, SavedVariables via AceDB/plain fallback, custom Lua test harness, PowerShell test runner.

---

### Task 1: Add Failing Tests

**Files:**
- Modify: `tests/database_spec.lua`
- Modify: `tests/notifications_spec.lua`

- [x] **Step 1: Write persistence and clamp tests**

Add a database test that initializes malformed local settings, calls `GetLocalSettings()`, and asserts `toastDurationSeconds` defaults to `7`. Then call `SetToastDurationSeconds(2)`, `SetToastDurationSeconds(16)`, and `SetToastDurationSeconds(9)` and assert the saved values are clamped to `3`, `15`, and `9`.

- [x] **Step 2: Write settings UI and timer tests**

Add a notification test that opens Settings, verifies the duration label starts at `7 seconds`, clicks plus/minus buttons, and confirms `localSettings.toastDurationSeconds` and the label update. Add another test that stubs `C_Timer.After`, dispatches a toast after setting duration to `11`, and asserts the timer delay is `11`.

- [x] **Step 3: Run focused tests and verify RED**

Run:

```powershell
$env:RPA_LUA=(Resolve-Path '.\tools\lua\lua54.exe').Path
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 "toast duration"
```

Expected: FAIL because the duration controls, setting key, and setter do not exist yet.

### Task 2: Implement Duration Persistence

**Files:**
- Modify: `Data/Defaults.lua`
- Modify: `Data/Database.lua`

- [x] **Step 1: Add default**

Add `toastDurationSeconds = 7` under `profile.localSettings`.

- [x] **Step 2: Validate and clamp**

Update `ensureLocalSettingsShape()` to set `settings.toastDurationSeconds` to a number clamped between `3` and `15`, defaulting to `7` for invalid values.

- [x] **Step 3: Add setter**

Add `Database:SetToastDurationSeconds(seconds)` that calls `GetLocalSettings()`, clamps the numeric value, saves it, and returns the saved number.

### Task 3: Implement Settings UI and Toast Timer

**Files:**
- Modify: `UI/SettingsPage.lua`
- Modify: `UI/Toast.lua`

- [x] **Step 1: Add stepper controls**

Add a `Toast duration` label, minus button, value label, and plus button inside the existing Toasts settings section. Keep controls compact so anchor and test buttons remain usable.

- [x] **Step 2: Wire handlers**

In `SettingsPage:Refresh()`, set the value label from `settings.toastDurationSeconds`, decrement/increment through `addon.db:SetToastDurationSeconds()`, and refresh the label after each click.

- [x] **Step 3: Use saved duration**

In `Toast:DisplayAwardToast()`, replace `Styles.Toast.durationSeconds or 7` with `settings.toastDurationSeconds or Styles.Toast.durationSeconds or 7`.

### Task 4: Verify and Update Docs

**Files:**
- Modify: `docs/sync.md`
- Modify: `docs/superpowers/handoffs/latest-handoff.md`

- [x] **Step 1: Update docs**

Document that reward toasts have a local duration setting stored under `profile.localSettings.toastDurationSeconds`.

- [x] **Step 2: Run full verification**

Run:

```powershell
$env:RPA_LUA=(Resolve-Path '.\tools\lua\lua54.exe').Path
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1
git diff --check
```

Expected: all tests pass; `git diff --check` has no whitespace errors beyond existing CRLF warnings.

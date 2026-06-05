# Typography Readability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply readable, outline-free typography roles across Rolling Pin Awards pages.

**Architecture:** Add typography tokens to `UI/Styles.lua` and apply them through reusable component factories in `UI/Components.lua`. Tests verify representative labels and buttons across tabs so pages inherit the style pass without one-off per-screen overrides.

**Tech Stack:** WoW Lua FontString APIs, custom component helpers, Lua test harness, PowerShell test runner.

---

### Task 1: Tests

**Files:**
- Modify: `tests/bridge_spec.lua`

- [x] **Step 1: Add failing style-role assertions**

Assert representative Tab Header, Tab Description, Card Header, Card Value, Card Descriptor, and Button Text controls have the requested font sizes, colors, role metadata, and no outline flags.

- [x] **Step 2: Run focused tests**

Run:

```powershell
$env:RPA_LUA=(Resolve-Path '.\tools\lua\lua54.exe').Path
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 "typography"
```

Expected: FAIL because typography roles are not implemented yet.

Observed: FAIL `expected tabHeader, got nil`.

### Task 2: Shared Typography Tokens

**Files:**
- Modify: `UI/Styles.lua`
- Modify: `UI/Components.lua`

- [x] **Step 1: Add tokens**

Add `Styles.Typography` with `tabHeader`, `tabDescription`, `cardHeader`, `cardDescription`, and `buttonText` roles.

- [x] **Step 2: Apply roles**

Update `applyTextTreatment()` and component factory calls so shared labels/buttons use role styling. Ensure all roles set `fontFlags = nil`.

### Task 3: Verify And Docs

**Files:**
- Modify: `docs/superpowers/handoffs/latest-handoff.md`

- [x] **Step 1: Update handoff**

Record the font/color rules and note that outlines are removed across shared UI text.

- [x] **Step 2: Run full verification**

Run:

```powershell
$env:RPA_LUA=(Resolve-Path '.\tools\lua\lua54.exe').Path
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1
git diff --check
```

Expected: full suite passes and whitespace check has no errors beyond CRLF warnings.

Observed: focused typography test passed; full Lua suite passed.

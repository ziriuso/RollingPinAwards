# Leaderboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `Leaderboard` tab that ranks approved award recipients by rolling pin count, shows human-readable dates, and opens a popup with per-player award history.

**Architecture:** Build the leaderboard as a read-only aggregation derived from the existing awards dataset inside the UI bridge. Keep dates and popup details in shared view-model helpers so the tab stays thin and the ranking logic is easy to test. Reuse the existing scrollable section and modal-style UI patterns instead of adding a second persistence model.

**Tech Stack:** Lua, WoW `CreateFrame` UI, Ace3-aware addon runtime, lightweight Lua test harness under `tests/`

---

### Task 1: Lock leaderboard aggregation and date formatting with failing tests

**Files:**
- Modify: `tests/bridge_spec.lua`
- Modify: `tests/awards_spec.lua`

- [ ] **Step 1: Write failing leaderboard aggregation tests**

Add tests covering:
- leaderboard includes only approved awards
- leaderboard sorts by pin count desc, then most recent award date desc
- direct awards show actual awarder in detail rows
- nomination-sourced awards show original nominator in detail rows
- date text is non-empty and human-readable

- [ ] **Step 2: Write failing leaderboard tab UI tests**

Add tests covering:
- leaderboard tab appears between `history` and `settings`
- clicking `View` opens a popup with the selected player history
- long leaderboard lists expose a scrollbar

- [ ] **Step 3: Run focused tests to verify red**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 leaderboard`
Expected: FAIL for missing bridge/tab/popup behavior

### Task 2: Add shared leaderboard and date helpers

**Files:**
- Modify: `Time.lua`
- Modify: `UI/Bridge.lua`
- Modify: `Awards.lua`

- [ ] **Step 1: Add minimal date-format helper**

Expose a WoW-safe helper for human-readable date text, using available runtime functions and a safe fallback.

- [ ] **Step 2: Add leaderboard aggregation in the bridge**

Implement a derived leaderboard view model that:
- groups approved awards by recipient
- counts pins
- resolves most recent award date
- builds popup detail entries
- resolves `displayAwardedBy` with the direct-vs-nomination rule

- [ ] **Step 3: Run focused tests to verify green**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 leaderboard`
Expected: aggregation tests now pass, UI tests still fail if tab/popup not added yet

### Task 3: Add leaderboard tab and popup UI

**Files:**
- Create: `UI/Tabs/Leaderboard.lua`
- Modify: `UI/MainFrame.lua`
- Modify: `UI/Styles.lua`
- Modify: `UI/Components.lua`

- [ ] **Step 1: Add the new tab to the tab order**

Insert `leaderboard` between `history` and `settings`.

- [ ] **Step 2: Add a reusable read-only modal/popup if needed**

Keep it anchored inside the addon window and suitable for showing per-player award history.

- [ ] **Step 3: Implement the leaderboard tab**

Build a scrollable leaderboard list that shows:
- recipient
- pin count
- most recent date
- `View` button

Wire the popup to show the selected player award entries.

- [ ] **Step 4: Run focused tests to verify green**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 leaderboard`
Expected: PASS

### Task 4: Surface award dates in existing history-facing UI

**Files:**
- Modify: `UI/Tabs/History.lua`
- Modify: `UI/Bridge.lua`

- [ ] **Step 1: Add human-readable date text to award view models**

Include date text without changing delete behavior.

- [ ] **Step 2: Update history rows to display dates**

Keep layout compact and compatible with current delete controls.

- [ ] **Step 3: Run focused tests**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 history`
Expected: PASS

### Task 5: Update docs, verify, and deploy

**Files:**
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-06-02-leaderboard-design.md` only if implementation reveals ambiguity

- [ ] **Step 1: Update README to mention leaderboard and dated awards**

- [ ] **Step 2: Run the full suite**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`
Expected: PASS

- [ ] **Step 3: Deploy to Retail and PTR**

Copy the verified addon files into:
- `C:\Gaming\World of Warcraft\_retail_\Interface\AddOns\RollingPinAwards`
- `C:\Gaming\World of Warcraft\_xptr_\Interface\AddOns\RollingPinAwards`

- [ ] **Step 4: Commit the feature**

Suggested commit message:

```bash
git add README.md Time.lua UI/Bridge.lua UI/Components.lua UI/MainFrame.lua UI/Styles.lua UI/Tabs/History.lua UI/Tabs/Leaderboard.lua tests/bridge_spec.lua tests/awards_spec.lua docs/superpowers/plans/2026-06-02-leaderboard-implementation.md docs/superpowers/specs/2026-06-02-leaderboard-design.md
git commit -m "feat: add leaderboard and award dates"
```

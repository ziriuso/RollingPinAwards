# UI Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Recompose the Rolling Pin Awards UI so it feels much closer to the Figma Make mockup while preserving the current MVP behavior and keeping the addon fast to use in live WoW.

**Architecture:** Keep the polish pass concentrated in the shared UI layer, then let each tab inherit the new shell, card, row, and control styling. Use the Figma Make bundle as a selective reference and asset source, but recreate the main frame, parchment board, tabs, cards, and controls in WoW-native frames so the addon stays scalable and patch-resilient.

**Tech Stack:** Lua, WoW `CreateFrame` UI, Ace3-aware addon runtime, lightweight Lua test harness under `tests/`, selectively extracted PNG assets from the Figma Make bundle

---

### Task 1: Lock the polish pass with focused UI regression tests

**Files:**
- Modify: `tests/bridge_spec.lua`
- Modify: `tests/WoWStubs.lua` only if a new texture or frame behavior needs harness support

- [ ] **Step 1: Add failing tests for the recomposed dashboard structure**

Add tests in `tests/bridge_spec.lua` covering:
- dashboard still renders after the restyle
- dashboard exposes a stats row and two main content sections
- footer action buttons remain clickable after the layout change

- [ ] **Step 2: Add failing tests for shared chrome behavior**

Add tests covering:
- main frame still has a close button and backdrop after restyling
- content panel remains anchored inside the addon window
- tab buttons still switch views after the tab rail restyle
- history, leaderboard, nominations, and admin scroll sections still expose scrollbars

- [ ] **Step 3: Add failing tests for tooltip and modal safety if needed**

Add or update tests covering:
- leaderboard detail modal still opens
- tooltip rendering path still returns a visible panel

- [ ] **Step 4: Run focused tests to verify red**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 bridge`

Expected: FAIL where the new dashboard composition or shared chrome expectations are not implemented yet

### Task 2: Extract selective Figma assets and introduce a shared polish theme

**Files:**
- Create: `Media/` only for assets that are actually used
- Modify: `UI/Styles.lua`
- Modify: `UI/Components.lua`
- Modify: `README.md` only if an extracted asset folder becomes part of the addon structure

- [ ] **Step 1: Extract only the minimal assets we actually need**

From `.figma-make-inspect/` choose only the small reusable visuals that materially improve fidelity, such as:
- a small motif/icon treatment
- a subtle decorative accent
- a tooltip or badge cue reference

Do not copy the full dashboard screenshot or use a giant baked background as the main frame.

- [ ] **Step 2: Add shared theme constants and style helpers**

Refine `UI/Styles.lua` to centralize:
- parchment surface colors
- wood-shadow shell colors
- brass/gold edge colors
- burnt-orange primary action colors
- spacing and sizing constants for cards, tabs, and rows

- [ ] **Step 3: Teach shared components to render the new chrome**

Update `UI/Components.lua` so the shared constructors can produce:
- a darker wood-shadow outer frame
- a pale parchment content board
- softer section cards with brass edging
- flatter brass/parchment tabs
- more polished buttons, inputs, scrollbars, and dialogs

- [ ] **Step 4: Run focused tests to verify green for shared chrome**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 bridge`

Expected: PASS for frame, tab, modal, and scroll-section behavior with the new shared styling

### Task 3: Recompose the main shell and dashboard around the Figma layout

**Files:**
- Modify: `UI/MainFrame.lua`
- Modify: `UI/Tabs/Dashboard.lua`
- Modify: `UI/Components.lua`
- Modify: `UI/Styles.lua`

- [ ] **Step 1: Rebuild the main shell hierarchy**

Update `UI/MainFrame.lua` to introduce:
- a stronger header/title band
- cleaner subtitle placement
- a flatter tab rail
- a parchment content board that feels inset into the outer shell

Keep the current tab ids, open/close logic, and active-tab rendering flow unchanged.

- [ ] **Step 2: Add or refine shared card helpers for the dashboard**

Use `UI/Components.lua` to support:
- compact stat cards
- framed leaderboard/recent-awards sections
- stronger footer action buttons

- [ ] **Step 3: Recompose the dashboard into the Figma-style layout**

Update `UI/Tabs/Dashboard.lua` so it renders:
- top stats row
- two-column main content area
- leaderboard on one side
- recent awards on the other
- footer action buttons anchored cleanly at the bottom

Keep the current quick-action behavior intact.

- [ ] **Step 4: Run focused tests for dashboard safety**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 dashboard bridge`

Expected: PASS with the recomposed dashboard still rendering correctly

### Task 4: Restyle the remaining tabs, rows, forms, and tooltip

**Files:**
- Modify: `UI/Tabs/Award.lua`
- Modify: `UI/Tabs/Nominations.lua`
- Modify: `UI/Tabs/History.lua`
- Modify: `UI/Tabs/Leaderboard.lua`
- Modify: `UI/Tabs/Settings.lua`
- Modify: `UI/Tabs/Admin.lua`
- Modify: `Tooltip.lua`
- Modify: `UI/Components.lua`

- [ ] **Step 1: Recompose form-heavy tabs**

Update `Award` and `Nominations` so they use:
- tighter form grouping
- more polished helper text
- stronger separation between entry form and list content
- buttons that match the new primary and secondary action system

- [ ] **Step 2: Restyle list-heavy tabs**

Update `History`, `Leaderboard`, and the list regions of `Nominations` and `Admin` so rows have:
- better name/reason/date hierarchy
- cleaner spacing
- lighter parchment row surfaces
- clearer scanability for counts and actions

- [ ] **Step 3: Keep admin and settings polished but utilitarian**

Update `Settings` and `Admin` to inherit the new system while staying slightly more functional and less ornamental than the dashboard.

- [ ] **Step 4: Restyle the tooltip**

Update `Tooltip.lua` to use:
- a dark panel
- warm border treatment
- orange/gold emphasis text
- cleaner spacing that matches the Figma tooltip reference

- [ ] **Step 5: Run focused tests for interaction safety**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 bridge`

Expected: PASS with voting, moderation, alias, leaderboard modal, and admin interactions still working after the restyle

### Task 5: Finish docs, run full verification, deploy, and commit

**Files:**
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-06-02-ui-polish-design.md` only if implementation reveals ambiguity
- Modify: `docs/testing.md` only if the visual pass changes how local verification is performed

- [ ] **Step 1: Update docs to reflect the polished UI**

Document:
- the chrome-first Figma-inspired visual pass
- any `Media/` assets that were actually added
- the fact that functionality remains the same while the shared shell and component styling changed

- [ ] **Step 2: Run the full suite**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: PASS

- [ ] **Step 3: Deploy the verified build to Retail and PTR**

Copy the verified addon files into:
- `C:\Gaming\World of Warcraft\_retail_\Interface\AddOns\RollingPinAwards`
- `C:\Gaming\World of Warcraft\_xptr_\Interface\AddOns\RollingPinAwards`

- [ ] **Step 4: Commit the polish pass**

Suggested commit message:

```bash
git add Media README.md UI/Styles.lua UI/Components.lua UI/MainFrame.lua UI/Tabs/Dashboard.lua UI/Tabs/Award.lua UI/Tabs/Nominations.lua UI/Tabs/History.lua UI/Tabs/Leaderboard.lua UI/Tabs/Settings.lua UI/Tabs/Admin.lua Tooltip.lua tests/bridge_spec.lua tests/WoWStubs.lua docs/superpowers/plans/2026-06-02-ui-polish-implementation.md docs/superpowers/specs/2026-06-02-ui-polish-design.md
git commit -m "feat: polish addon ui toward figma design"
```

## Self-Review

- Spec coverage: the plan covers the chrome-first shell, shared control restyle, dashboard recomposition, list and form tab polishing, tooltip treatment, selective asset usage, and the required verification/deploy path.
- Placeholder scan: no `TODO`, `TBD`, or undefined follow-up references remain.
- Type consistency: the plan consistently references the current addon UI entry points in `UI/Components.lua`, `UI/MainFrame.lua`, `UI/Tabs/*`, `Tooltip.lua`, and the shared bridge-driven screens without inventing a second UI framework.

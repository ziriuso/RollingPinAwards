# Addon Folder Restructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the WoW runtime addon payload into a single `RollingPinAwards/` folder while keeping repo tooling, tests, docs, and workflows at the repository root.

**Architecture:** The addon folder will match WoW conventions: `RollingPinAwards/RollingPinAwards.toc` plus runtime folders and Lua files inside `RollingPinAwards/`. Root-level infrastructure will reference the nested addon folder through a small test path helper and updated release/deploy/package paths.

**Tech Stack:** WoW Lua addon files, PowerShell release scripts, GitHub Actions, lightweight Lua test harness.

---

### Task 1: Pin the New Layout in Tests

**Files:**
- Modify: `tests/TestHarness.lua`
- Modify: `tests/WoWStubs.lua`
- Modify: `tests/embedded_ace3_spec.lua`
- Modify: `tests/media_spec.lua`
- Modify: `tests/release_workflow_spec.lua`
- Modify: tests that call `dofile("UI/...")`

- [ ] **Step 1: Add addon path helpers to the test harness**

Add helpers:

```lua
function harness.addon_path(relativePath)
  return "RollingPinAwards/" .. relativePath
end

function harness.dofile_addon(relativePath)
  return dofile(harness.addon_path(relativePath))
end
```

- [ ] **Step 2: Update tests to use the helpers**

Replace `RollingPinAwards.toc` reads with `harness.addon_path("RollingPinAwards.toc")`, media file checks with `harness.addon_path("Media/...")`, and addon `dofile` calls with `harness.dofile_addon(...)`.

- [ ] **Step 3: Run the affected tests and confirm they fail before the move**

Run:

```powershell
$env:RPA_LUA=(Resolve-Path '.\tools\lua\lua54.exe').Path
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 "toc media release main frame"
```

Expected: failures because `RollingPinAwards/RollingPinAwards.toc` and nested runtime files do not exist yet.

### Task 2: Move Runtime Payload

**Files:**
- Move: `RollingPinAwards.toc` to `RollingPinAwards/RollingPinAwards.toc`
- Move: `Bootstrap.lua`, `Core/`, `Data/`, `Domain/`, `Libs/`, `Media/`, `Sync/`, and `UI/` into `RollingPinAwards/`

- [ ] **Step 1: Create the addon folder and move runtime files with `git mv`**

Run:

```powershell
New-Item -ItemType Directory -Force -Path .\RollingPinAwards
git mv RollingPinAwards.toc Bootstrap.lua Core Data Domain Libs Media Sync UI .\RollingPinAwards\
```

- [ ] **Step 2: Run the focused tests again**

Expected: path-related test failures shrink to tooling/docs references.

### Task 3: Update Tooling, Release, and Docs

**Files:**
- Modify: `.github/workflows/release-curseforge.yml`
- Modify: `tools/release/Build-CurseForgePackage.ps1`
- Modify: `tools/release/Publish-CurseForgePackage.ps1`
- Modify: `README.md`
- Modify: `docs/testing.md`
- Modify: `docs/curseforge-release-workflow.md`
- Modify: `docs/sync.md`
- Modify: `docs/superpowers/handoffs/latest-handoff.md`

- [ ] **Step 1: Point release tooling at `RollingPinAwards/RollingPinAwards.toc`**

The workflow upload step should pass:

```powershell
-TocPath ".\RollingPinAwards\RollingPinAwards.toc"
```

- [ ] **Step 2: Make the package builder copy the addon folder directly**

The package builder should use `RollingPinAwards/` as the source folder and copy it into the staging `package/` folder without assembling root-level runtime entries.

- [ ] **Step 3: Update docs**

Document the new repo split: root is infrastructure, `RollingPinAwards/` is the addon payload.

### Task 4: Verify and Commit

- [ ] **Step 1: Run the full Lua suite**

```powershell
$env:RPA_LUA=(Resolve-Path '.\tools\lua\lua54.exe').Path
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1
```

- [ ] **Step 2: Build a local release package**

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\release\Build-CurseForgePackage.ps1 -TagName v1.0.0 -OutputDirectory .\artifacts\release
```

- [ ] **Step 3: Verify package contents**

Confirm the zip contains `RollingPinAwards/RollingPinAwards.toc` and runtime folders under one top-level addon folder.

- [ ] **Step 4: Remove generated artifacts, commit, and push**

Stage the move, path updates, docs, and tests. Leave `.figma-make-inspect/`, `.research/`, and `tools/lua/` untracked.

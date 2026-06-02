# Rank Permissions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the officer grant model with exact-rank permissions, fix live WoW timestamp crashes in nominations and awards, and add award deletion that also removes linked nominations.

**Architecture:** Keep the addon backend-first. Add a shared WoW-safe timestamp helper, replace the current roster-based permission path with a rank-index matrix, and then update the bridge and UI tabs to consume the new permission helpers. Preserve the existing `CreateFrame` tab structure and extend it with the minimum data-model and action changes needed for the new authority model.

**Tech Stack:** WoW Lua 5.1-compatible code, embedded Ace3 runtime compatibility, custom Lua test harness, PowerShell test runner, native WoW `CreateFrame` UI.

---

## Target File Structure

### Core / Domain

- Create: `Time.lua`
- Modify: `Core.lua`
- Modify: `Database.lua`
- Modify: `Permissions.lua`
- Modify: `Awards.lua`
- Modify: `Nominations.lua`
- Modify: `Sync.lua`

### UI

- Modify: `UI/Bridge.lua`
- Modify: `UI/MainFrame.lua`
- Modify: `UI/Tabs/Award.lua`
- Modify: `UI/Tabs/Nominations.lua`
- Modify: `UI/Tabs/History.lua`
- Modify: `UI/Tabs/Admin.lua`

### Tests

- Modify: `tests/WoWStubs.lua`
- Modify: `tests/TestHarness.lua`
- Modify: `tests/permissions_spec.lua`
- Modify: `tests/awards_spec.lua`
- Modify: `tests/nominations_spec.lua`
- Modify: `tests/bridge_spec.lua`
- Modify: `tests/sync_spec.lua`

### Documentation

- Modify: `README.md`
- Modify: `docs/permissions.md`
- Modify: `docs/sync.md`

---

### Task 1: Add A WoW-Safe Timestamp Helper

**Files:**
- Create: `Time.lua`
- Modify: `Core.lua`
- Modify: `tests/WoWStubs.lua`
- Test: `tests/nominations_spec.lua`
- Test: `tests/awards_spec.lua`

- [ ] **Step 1: Write the failing timestamp tests**

```lua
-- tests/nominations_spec.lua
["guild member can create a pending nomination without os"] = function()
  wow.reset({ guildName = "Raid Bakery" })
  _G.os = nil

  local addon = wow.loadAddon()
  addon:OnInitialize()

  local nomination = addon.nominations:Create("Burny-Stormrage", "Pulled the boss")

  harness.assert_true(nomination ~= nil)
  harness.assert_true(type(nomination.createdAt) == "number")
end,
```

```lua
-- tests/awards_spec.lua
["authorized officer can create a direct award without os"] = function()
  wow.reset({
    guildName = "Raid Bakery",
    playerName = "Guildmaster",
    guildRankName = "Guild Master",
    guildRankIndex = 0,
  })
  _G.os = nil

  local addon = wow.loadAddon()
  addon:OnInitialize()

  local award = addon.awards:CreateDirectAward("Moonrustle-Stormrage", "Baiting Fae")

  harness.assert_true(award ~= nil)
  harness.assert_true(type(award.createdAt) == "number")
end,
```

- [ ] **Step 2: Run the nomination and award specs to verify the current `os` crash**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: FAIL in `Nominations.lua` and `Awards.lua` with `attempt to index global 'os'`.

- [ ] **Step 3: Add the shared timestamp helper and wire it into core**

```lua
-- Time.lua
local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Time = RPA.Time or {}
RPA.Time = Time

function Time:Now()
  if type(GetServerTime) == "function" then
    return GetServerTime()
  end

  if type(time) == "function" then
    return time()
  end

  if _G.os and type(_G.os.time) == "function" then
    return _G.os.time()
  end

  return 0
end

return RPA.Time
```

```lua
-- Core.lua
local Time = RPA.Time or {}
RPA.Time = Time
```

```lua
-- tests/WoWStubs.lua
_G.GetServerTime = function()
  return seed.serverTime or 1717336800
end
```

- [ ] **Step 4: Replace direct `os.time()` calls in nominations and awards**

```lua
-- Nominations.lua / Awards.lua
local function currentTimestamp(addon)
  return addon.Time:Now()
end

local now = currentTimestamp(self.addon)
```

- [ ] **Step 5: Run the full suite and verify the runtime crash path is gone**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: PASS for nomination and award timestamp coverage, with no `os`-related failures.

- [ ] **Step 6: Commit**

```bash
git add Time.lua Core.lua Awards.lua Nominations.lua tests/WoWStubs.lua tests/nominations_spec.lua tests/awards_spec.lua
git commit -m "fix: use wow-safe timestamps for awards and nominations"
```

### Task 2: Replace Officer Grants With Exact Rank Permissions

**Files:**
- Modify: `Database.lua`
- Modify: `Permissions.lua`
- Modify: `Core.lua`
- Modify: `tests/permissions_spec.lua`
- Modify: `tests/sync_spec.lua`

- [ ] **Step 1: Write the failing rank-permission tests**

```lua
-- tests/permissions_spec.lua
["exact rank permission row controls nomination moderation"] = function()
  wow.reset({
    guildName = "Raid Bakery",
    playerName = "Officerone",
    guildRankName = "Officer",
    guildRankIndex = 1,
    guildMembers = {
      { name = "Officerone-Stormrage", rankName = "Officer", rankIndex = 1 },
    },
  })

  local addon = wow.loadAddon()
  addon:OnInitialize()
  addon.permissions:SetRankPermissions(1, "Officer", {
    canManageNominations = true,
  })

  harness.assert_true(addon.permissions:CanManageNominations())
  harness.assert_false(addon.permissions:CanCreateDirectAwards())
end,
```

```lua
-- tests/permissions_spec.lua
["guild master always has full access even without rank rows"] = function()
  wow.reset({
    guildName = "Raid Bakery",
    playerName = "Guildmaster",
    guildRankName = "Guild Master",
    guildRankIndex = 0,
  })

  local addon = wow.loadAddon()
  addon:OnInitialize()

  harness.assert_true(addon.permissions:CanManageNominations())
  harness.assert_true(addon.permissions:CanCreateDirectAwards())
  harness.assert_true(addon.permissions:CanDeleteAwards())
  harness.assert_true(addon.permissions:CanManageAddonPermissions())
end,
```

- [ ] **Step 2: Run the suite to verify the current permission model does not satisfy these tests**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: FAIL because `SetRankPermissions`, `CanDeleteAwards`, and `CanManageAddonPermissions` do not exist yet.

- [ ] **Step 3: Add rank-permission storage to the guild dataset**

```lua
-- Database.lua
dataset.rankPermissions = type(dataset.rankPermissions) == "table" and dataset.rankPermissions or {}
```

```lua
function Database:UpsertRankPermission(guildKey, rankIndex, row)
  local dataset = self:GetGuildDataset(guildKey)
  dataset.rankPermissions[rankIndex] = row
  return row
end

function Database:GetRankPermission(guildKey, rankIndex)
  local dataset = self:GetGuildDataset(guildKey)
  return dataset.rankPermissions[rankIndex]
end

function Database:GetRankPermissions(guildKey)
  local dataset = self:GetGuildDataset(guildKey)
  return dataset.rankPermissions
end
```

- [ ] **Step 4: Replace the roster-based permission API with rank helpers**

```lua
-- Permissions.lua
function Permissions:SetRankPermissions(rankIndex, rankName, permissions)
  local guild = self.addon:GetActiveGuildContext()
  if not guild or not self:CanManageAddonPermissions() then
    return false
  end

  local row = {
    rankIndex = rankIndex,
    rankName = rankName,
    canManageNominations = permissions.canManageNominations == true,
    canCreateDirectAwards = permissions.canCreateDirectAwards == true,
    canDeleteAwards = permissions.canDeleteAwards == true,
    canManageAddonPermissions = permissions.canManageAddonPermissions == true,
    lastModifiedAt = self.addon.Time:Now(),
    lastModifiedBy = self.addon:GetCurrentPlayerFullName(),
  }

  self.addon.db:UpsertRankPermission(guild.guildKey, rankIndex, row)
  return true
end

function Permissions:GetCurrentRankPermissions()
  local _, rankName, rankIndex = GetGuildInfo("player")
  if rankIndex == 0 then
    return {
      rankIndex = 0,
      rankName = rankName or "Guild Master",
      canManageNominations = true,
      canCreateDirectAwards = true,
      canDeleteAwards = true,
      canManageAddonPermissions = true,
    }
  end

  local guild = self.addon:GetActiveGuildContext()
  return self.addon.db:GetRankPermission(guild.guildKey, rankIndex) or {
    rankIndex = rankIndex,
    rankName = rankName,
  }
end
```

```lua
function Permissions:CanManageNominations()
  return self:GetCurrentRankPermissions().canManageNominations == true
end

function Permissions:CanCreateDirectAwards()
  return self:GetCurrentRankPermissions().canCreateDirectAwards == true
end

function Permissions:CanDeleteAwards()
  return self:GetCurrentRankPermissions().canDeleteAwards == true
end

function Permissions:CanManageAddonPermissions()
  return self:GetCurrentRankPermissions().canManageAddonPermissions == true
end
```

- [ ] **Step 5: Update any old permission call sites to the new helpers**

```lua
-- Core.lua, UI/Bridge.lua, Nominations.lua, Awards.lua
-- Replace:
-- self.addon.permissions:CanManageAwards()
-- With the exact helper needed for the action.
```

- [ ] **Step 6: Update sync tests and permission tests to validate rank-based authority**

```lua
-- tests/sync_spec.lua
["sync rejects a privileged award update from a rank without direct-award permission"] = function()
  -- configure rank 1 without canCreateDirectAwards and assert rejection
end,
```

- [ ] **Step 7: Run the full suite and verify all permission checks are rank-based**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: PASS with old roster-based failures removed or updated.

- [ ] **Step 8: Commit**

```bash
git add Database.lua Permissions.lua Core.lua tests/permissions_spec.lua tests/sync_spec.lua
git commit -m "feat: replace officer grants with rank permissions"
```

### Task 3: Add Award Deletion And Linked Nomination Deletion

**Files:**
- Modify: `Awards.lua`
- Modify: `Database.lua`
- Modify: `Nominations.lua`
- Modify: `tests/awards_spec.lua`
- Modify: `tests/nominations_spec.lua`

- [ ] **Step 1: Write the failing deletion tests**

```lua
-- tests/awards_spec.lua
["deleting a direct award removes only the award"] = function()
  wow.reset({
    guildName = "Raid Bakery",
    playerName = "Guildmaster",
    guildRankName = "Guild Master",
    guildRankIndex = 0,
  })

  local addon = wow.loadAddon()
  addon:OnInitialize()
  local award = addon.awards:CreateDirectAward("Moonrustle-Stormrage", "Baiting Fae")

  local ok = addon.awards:DeleteAward(award.awardId)

  harness.assert_true(ok)
  harness.assert_nil(addon.db:GetAward(addon:GetActiveGuildContext().guildKey, award.awardId))
end,
```

```lua
-- tests/awards_spec.lua
["deleting a nomination award removes both award and nomination"] = function()
  -- create pending nomination, approve it, delete award, assert both records are gone
end,
```

- [ ] **Step 2: Run the suite and verify delete support is missing**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: FAIL because `DeleteAward` and nomination-linked cleanup do not exist.

- [ ] **Step 3: Add delete primitives to the database**

```lua
-- Database.lua
function Database:DeleteAward(guildKey, awardId)
  local dataset = self:GetGuildDataset(guildKey)
  dataset.awardsById[awardId] = nil
  rebuildAwardRows(dataset)
  return true
end

function Database:DeleteNomination(guildKey, nominationId)
  local dataset = self:GetGuildDataset(guildKey)
  dataset.nominationsById[nominationId] = nil
  dataset.votesByNomination[nominationId] = nil
  rebuildNominationRows(dataset)
  return true
end
```

- [ ] **Step 4: Implement delete authorization and linked cleanup**

```lua
-- Awards.lua
function Awards:DeleteAward(awardId)
  if not self.addon.permissions or not self.addon.permissions:CanDeleteAwards() then
    return false, "unauthorized"
  end

  local guild = self.addon:GetActiveGuildContext()
  local award = self.addon.db:GetAward(guild.guildKey, awardId)
  if not award then
    return false, "missing award"
  end

  self.addon.db:DeleteAward(guild.guildKey, awardId)

  if award.nominationId then
    self.addon.db:DeleteNomination(guild.guildKey, award.nominationId)
  end

  return true
end
```

- [ ] **Step 5: Run the full suite and verify both delete paths**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: PASS for direct-award delete and linked nomination delete behavior.

- [ ] **Step 6: Commit**

```bash
git add Awards.lua Database.lua Nominations.lua tests/awards_spec.lua tests/nominations_spec.lua
git commit -m "feat: delete awards and linked nominations"
```

### Task 4: Update The Bridge And Tabs For The Rank Matrix

**Files:**
- Modify: `UI/Bridge.lua`
- Modify: `UI/Tabs/Award.lua`
- Modify: `UI/Tabs/Nominations.lua`
- Modify: `UI/Tabs/History.lua`
- Modify: `UI/Tabs/Admin.lua`
- Modify: `tests/bridge_spec.lua`

- [ ] **Step 1: Write the failing UI/bridge tests**

```lua
-- tests/bridge_spec.lua
["admin tab is hidden when player cannot manage addon permissions"] = function()
  wow.reset({
    guildName = "Raid Bakery",
    playerName = "Memberone",
    guildRankName = "Member",
    guildRankIndex = 5,
  })

  local addon = wow.loadAddon()
  addon:OnInitialize()
  addon.mainFrame:EnsureRendered()

  harness.assert_true(addon.mainFrame:HasTab("admin") == false)
end,
```

```lua
-- tests/bridge_spec.lua
["history tab exposes delete actions only with delete-award permission"] = function()
  -- configure rank permissions, create award, assert delete button visibility toggles by rank
end,
```

- [ ] **Step 2: Run the suite to verify the current bridge and tabs still depend on the old model**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: FAIL because `Admin` visibility and delete-action gating are not rank-based yet.

- [ ] **Step 3: Add rank-permission view models and action helpers to the bridge**

```lua
-- UI/Bridge.lua
function Bridge:GetRankPermissionsViewModel()
  return self.addon.permissions:GetGuildRankMatrix()
end

function Bridge:SaveRankPermissions(rankIndex, rankName, permissions)
  return self.addon.permissions:SetRankPermissions(rankIndex, rankName, permissions)
end

function Bridge:DeleteAward(awardId)
  return self.addon.awards:DeleteAward(awardId)
end
```

- [ ] **Step 4: Hide the Admin tab for unauthorized players**

```lua
-- UI/MainFrame.lua
if tab.id ~= "admin" or self.uiBridge:CanCurrentPlayerManageAddonPermissions() then
  tabs[#tabs + 1] = Components.MakeTab(UITabs[tabId])
end
```

- [ ] **Step 5: Rewrite the Admin tab around a rank matrix**

```lua
-- UI/Tabs/Admin.lua
-- Render one row per guild rank:
-- rank name | Manage Nominations | Direct Awards | Delete Awards | Manage Addon Permissions
-- each checkbox saves through bridge:SaveRankPermissions(...)
```

- [ ] **Step 6: Update Award, Nominations, and History tab gating**

```lua
-- UI/Tabs/Award.lua
-- enable submit only when bridge:CanCurrentPlayerCreateDirectAwards()

-- UI/Tabs/Nominations.lua
-- show approve/reject only when bridge:CanCurrentPlayerManageNominations()

-- UI/Tabs/History.lua
-- show delete button only when bridge:CanCurrentPlayerDeleteAwards()
```

- [ ] **Step 7: Add the destructive confirmation path for deleting nomination-derived awards**

```lua
-- UI/Tabs/History.lua
local message = award.nominationId
  and "Delete this award and its linked nomination?"
  or "Delete this direct award?"
```

- [ ] **Step 8: Run the full suite and verify the UI gating and bridge behavior**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: PASS for admin visibility, rank-matrix save behavior, and delete-action gating.

- [ ] **Step 9: Commit**

```bash
git add UI/Bridge.lua UI/MainFrame.lua UI/Tabs/Award.lua UI/Tabs/Nominations.lua UI/Tabs/History.lua UI/Tabs/Admin.lua tests/bridge_spec.lua
git commit -m "feat: wire rank permissions through the addon ui"
```

### Task 5: Update Sync, Cleanup, And Docs

**Files:**
- Modify: `Sync.lua`
- Modify: `README.md`
- Modify: `docs/permissions.md`
- Modify: `docs/sync.md`
- Modify: `tests/sync_spec.lua`

- [ ] **Step 1: Write the failing sync and docs-facing tests**

```lua
-- tests/sync_spec.lua
["sync accepts rank permission updates for the active guild"] = function()
  -- create rank permission payload and assert merge into dataset.rankPermissions
end,
```

```lua
-- tests/sync_spec.lua
["sync ignores stale officer roster payloads safely"] = function()
  -- old payload shape should not crash or become the active authority source
end,
```

- [ ] **Step 2: Run the suite and verify sync still expects the old permission object model**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: FAIL because sync still routes roster-style permission updates.

- [ ] **Step 3: Update sync to broadcast and merge rank-permission updates**

```lua
-- Sync.lua
-- replace roster update payload handling with rank-permission payloads
-- keep guildKey validation and privilege checks
```

- [ ] **Step 4: Update the docs to match the new shipped behavior**

```md
<!-- README.md -->
- rank-based permission matrix by guild rank name
- GM forced full access
- award deletion with linked nomination deletion
```

```md
<!-- docs/permissions.md -->
- exact rank index storage
- four independent permissions
- Admin hidden unless rank allows addon-permission management
```

```md
<!-- docs/sync.md -->
- rank-permission payloads replace officer grant payloads
```

- [ ] **Step 5: Run the full suite and verify the addon is ready for live deploy**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: PASS across all specs.

- [ ] **Step 6: Deploy and perform in-game verification**

Run the proven local deploy flow for:
- `C:\Gaming\World of Warcraft\_retail_\Interface\AddOns\RollingPinAwards`
- `C:\Gaming\World of Warcraft\_xptr_\Interface\AddOns\RollingPinAwards`

Expected live checks:
- nomination submission no longer throws `os` errors
- direct awards no longer throw `os` errors
- Admin hidden for unauthorized ranks
- Admin shows rank rows by rank name for authorized ranks
- delete award confirmation appears and removes linked nominations

- [ ] **Step 7: Commit**

```bash
git add Sync.lua README.md docs/permissions.md docs/sync.md tests/sync_spec.lua
git commit -m "docs: finish rank permission and delete flow updates"
```

## Self-Review

- Spec coverage: this plan covers the rank matrix, GM forced access, hidden Admin behavior, exact-rank checks, award delete plus linked nomination delete, WoW-safe timestamps, sync updates, and in-game verification.
- Placeholder scan: no `TODO`, `TBD`, or “similar to” placeholders remain in task steps.
- Type consistency: the plan consistently uses `canManageNominations`, `canCreateDirectAwards`, `canDeleteAwards`, and `canManageAddonPermissions` for the four booleans.

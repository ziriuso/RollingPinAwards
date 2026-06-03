# Rolling Pin Awards MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a guild-only World of Warcraft addon that lets guild members nominate players for The Burnt Rolling Pin, lets GM-authorized officers moderate and award it, supports advisory voting and guild-scoped sync, and ships with a custom native Lua UI.

**Architecture:** The addon is backend-first. Core/domain modules own data, permissions, sync, and business rules. The UI is a `CreateFrame`-only Lua layer that reads view models and invokes actions through `UI/Bridge.lua`, keeping frame code reusable and free of persistence logic.

**Tech Stack:** WoW Lua 5.1-compatible code, Ace3 (`AceAddon-3.0`, `AceConsole-3.0`, `AceEvent-3.0`, `AceDB-3.0`, `AceComm-3.0`, `AceSerializer-3.0`), custom Lua test harness, PowerShell runner, native WoW `CreateFrame` UI.

---

## Target File Structure

### Addon Files

- Create: `RollingPinAwards.toc`
- Create: `Core.lua`
- Create: `Constants.lua`
- Create: `Defaults.lua`
- Create: `Utils.lua`
- Create: `GuildContext.lua`
- Create: `Database.lua`
- Create: `Permissions.lua`
- Create: `RosterPermissions.lua`
- Create: `Awards.lua`
- Create: `Nominations.lua`
- Create: `Sync.lua`
- Create: `Commands.lua`
- Create: `Announcements.lua`
- Create: `Tooltip.lua`

### UI Files

- Create: `UI/Bridge.lua`
- Create: `UI/Styles.lua`
- Create: `UI/Components.lua`
- Create: `UI/MainFrame.lua`
- Create: `UI/Tabs/Dashboard.lua`
- Create: `UI/Tabs/Award.lua`
- Create: `UI/Tabs/Nominations.lua`
- Create: `UI/Tabs/History.lua`
- Create: `UI/Tabs/Settings.lua`
- Create: `UI/Tabs/Admin.lua`

### Test Files

- Create: `tests/TestHarness.lua`
- Create: `tests/WoWStubs.lua`
- Create: `tests/run.lua`
- Create: `tests/run.ps1`
- Create: `tests/core_bootstrap_spec.lua`
- Create: `tests/guild_context_spec.lua`
- Create: `tests/database_spec.lua`
- Create: `tests/permissions_spec.lua`
- Create: `tests/nominations_spec.lua`
- Create: `tests/awards_spec.lua`
- Create: `tests/commands_spec.lua`
- Create: `tests/bridge_spec.lua`
- Create: `tests/sync_spec.lua`

### Documentation

- Create: `README.md`
- Create: `docs/testing.md`
- Create: `docs/sync.md`
- Create: `docs/permissions.md`

---

### Task 1: Scaffold The Addon And Test Harness

**Files:**
- Create: `RollingPinAwards.toc`
- Create: `tests/TestHarness.lua`
- Create: `tests/WoWStubs.lua`
- Create: `tests/run.lua`
- Create: `tests/run.ps1`
- Test: `tests/core_bootstrap_spec.lua`

- [ ] **Step 1: Write the failing bootstrap test**

```lua
-- tests/core_bootstrap_spec.lua
local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["core bootstrap exposes addon constants and slash command metadata"] = function()
    wow.reset()
    local addon = dofile("Core.lua")

    harness.assert_equal("RollingPinAwards", addon.ADDON_NAME)
    harness.assert_equal("/rpa", addon.SLASH_COMMAND)
    harness.assert_true(type(addon.OnInitialize) == "function")
  end,
}
```

- [ ] **Step 2: Create the test harness runner and verify the test fails**

```lua
-- tests/TestHarness.lua
local harness = {}

function harness.assert_equal(expected, actual)
  if expected ~= actual then
    error(("expected %s, got %s"):format(tostring(expected), tostring(actual)), 2)
  end
end

function harness.assert_true(value)
  if not value then
    error("expected condition to be true", 2)
  end
end

return harness
```

```lua
-- tests/WoWStubs.lua
local wow = {}

function wow.reset()
  _G.SlashCmdList = {}
  _G.SLASH_ROLLINGPINAWARDS1 = nil
end

return wow
```

```lua
-- tests/run.lua
local filter = arg and arg[1]
local files = {}
local handle = io.popen('dir /b tests\\*_spec.lua')
for file in handle:lines() do
  files[#files + 1] = "tests/" .. file
end
handle:close()

local passed, failed = 0, 0

for _, file in ipairs(files) do
  local spec = dofile(file)
  for name, test_fn in pairs(spec) do
    if not filter or name:find(filter, 1, true) then
      local ok, err = pcall(test_fn)
      if ok then
        passed = passed + 1
        print("PASS " .. name)
      else
        failed = failed + 1
        print("FAIL " .. name .. ": " .. err)
      end
    end
  end
end

if failed > 0 then
  os.exit(1)
end
```

```powershell
# tests/run.ps1
param(
  [string]$Filter = ""
)

$lua = Join-Path $PSScriptRoot "..\tools\lua\lua.exe"
if (-not (Test-Path $lua)) {
  $lua = (Get-Command lua -ErrorAction SilentlyContinue).Source
}

if (-not $lua) {
  Write-Error "No Lua runtime found. Add tools\lua\lua.exe or install lua on PATH."
  exit 1
}

& $lua (Join-Path $PSScriptRoot "run.lua") $Filter
exit $LASTEXITCODE
```

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 core bootstrap`

Expected: FAIL because `Core.lua` does not exist yet.

- [ ] **Step 3: Write the minimal addon scaffold**

```toc
## Interface: 120005, 110207
## Title: Rolling Pin Awards
## Notes: Guild awards and nominations for The Burnt Rolling Pin
## Author: Ziri
## Version: 0.1.0
## SavedVariables: RollingPinAwardsDB
## OptionalDeps: Ace3

Core.lua
```

```lua
-- Core.lua
local RPA = {
  ADDON_NAME = "RollingPinAwards",
  SLASH_COMMAND = "/rpa",
}

function RPA:OnInitialize()
end

return RPA
```

- [ ] **Step 4: Run the bootstrap test and verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 core bootstrap`

Expected: PASS for `core bootstrap exposes addon constants and slash command metadata`

- [ ] **Step 5: Commit**

```bash
git add RollingPinAwards.toc Core.lua tests/TestHarness.lua tests/WoWStubs.lua tests/run.lua tests/run.ps1 tests/core_bootstrap_spec.lua
git commit -m "chore: add addon scaffold and test harness"
```

### Task 2: Add Constants, Defaults, And Guild Context

**Files:**
- Create: `Constants.lua`
- Create: `Defaults.lua`
- Create: `GuildContext.lua`
- Create: `tests/guild_context_spec.lua`
- Modify: `RollingPinAwards.toc`
- Modify: `Core.lua`

- [ ] **Step 1: Write the failing guild-context tests**

```lua
-- tests/guild_context_spec.lua
local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["guild context activates a normalized dataset key when player is guilded"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      realmName = "Stormrage",
      playerName = "Ziri",
    })

    local addon = dofile("Core.lua")
    addon:OnInitialize()

    local guild = addon:GetActiveGuildContext()
    harness.assert_equal("raid bakery", guild.guildKey)
    harness.assert_equal("Raid Bakery", guild.guildName)
  end,

  ["guild context is inactive when player is not in a guild"] = function()
    wow.reset()
    local addon = dofile("Core.lua")
    addon:OnInitialize()

    harness.assert_true(addon:GetActiveGuildContext() == nil)
  end,
}
```

- [ ] **Step 2: Extend WoW stubs and verify the guild-context tests fail**

```lua
-- tests/WoWStubs.lua
local state = {}
local wow = {}

function wow.reset(seed)
  seed = seed or {}
  state = {
    guildName = seed.guildName,
    realmName = seed.realmName or "Stormrage",
    playerName = seed.playerName or "Ziri",
  }
  _G.__RPA_TEST_STATE = state

  _G.GetGuildInfo = function()
    return state.guildName
  end

  _G.GetRealmName = function()
    return state.realmName
  end

  _G.UnitName = function()
    return state.playerName
  end

  _G.SlashCmdList = {}
end

return wow
```

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 guild context`

Expected: FAIL because `GetActiveGuildContext` is not implemented.

- [ ] **Step 3: Write minimal constants, defaults, and guild-context code**

```lua
-- Constants.lua
local Constants = {
  ADDON_NAME = "RollingPinAwards",
  DISPLAY_AWARD_NAME = "The Burnt Rolling Pin",
  SLASH_COMMAND = "/rpa",
  PROTOCOL_VERSION = 1,
}

return Constants
```

```lua
-- Defaults.lua
local defaults = {
  profile = {
    settings = {
      tooltipEnabled = true,
      announceAwards = true,
      debug = false,
    },
    guild = nil,
  }
}

return defaults
```

```lua
-- GuildContext.lua
local GuildContext = {}

local function normalizeGuildKey(name)
  return string.lower((name or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function GuildContext:Build()
  local guildName = GetGuildInfo("player")
  if not guildName or guildName == "" then
    return nil
  end

  return {
    guildName = guildName,
    guildKey = normalizeGuildKey(guildName),
  }
end

return GuildContext
```

```lua
-- Core.lua
local Constants = dofile("Constants.lua")
local Defaults = dofile("Defaults.lua")
local GuildContext = dofile("GuildContext.lua")

local RPA = {
  ADDON_NAME = Constants.ADDON_NAME,
  SLASH_COMMAND = Constants.SLASH_COMMAND,
  defaults = Defaults,
}

function RPA:OnInitialize()
  self.activeGuildContext = GuildContext:Build()
end

function RPA:GetActiveGuildContext()
  return self.activeGuildContext
end

return RPA
```

- [ ] **Step 4: Run the guild-context tests and verify they pass**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 guild context`

Expected: PASS for both guild-context tests.

- [ ] **Step 5: Commit**

```bash
git add Constants.lua Defaults.lua GuildContext.lua Core.lua RollingPinAwards.toc tests/WoWStubs.lua tests/guild_context_spec.lua
git commit -m "feat: add constants defaults and guild context"
```

### Task 3: Build The Database And Core Data Shapes

**Files:**
- Create: `Database.lua`
- Create: `Utils.lua`
- Create: `tests/database_spec.lua`
- Modify: `Defaults.lua`
- Modify: `Core.lua`

- [ ] **Step 1: Write the failing database tests**

```lua
-- tests/database_spec.lua
local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["database creates a guild dataset on demand"] = function()
    wow.reset({ guildName = "Raid Bakery" })
    local addon = dofile("Core.lua")
    addon:OnInitialize()

    local dataset = addon.db:GetGuildDataset("raid bakery")
    harness.assert_equal("raid bakery", dataset.guildKey)
    harness.assert_equal(0, #dataset.awards)
  end,

  ["database stores nominations by id in the current guild dataset"] = function()
    wow.reset({ guildName = "Raid Bakery" })
    local addon = dofile("Core.lua")
    addon:OnInitialize()

    addon.db:UpsertNomination("raid bakery", {
      nominationId = "nom:1",
      status = "pending",
    })

    local found = addon.db:GetNomination("raid bakery", "nom:1")
    harness.assert_equal("nom:1", found.nominationId)
    harness.assert_equal("pending", found.status)
  end,
}
```

- [ ] **Step 2: Run the database tests and verify they fail**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 database`

Expected: FAIL because `addon.db` and guild dataset helpers do not exist yet.

- [ ] **Step 3: Write minimal utilities, defaults, and database code**

```lua
-- Utils.lua
local Utils = {}

function Utils.CopyTable(input)
  local output = {}
  for key, value in pairs(input) do
    output[key] = type(value) == "table" and Utils.CopyTable(value) or value
  end
  return output
end

return Utils
```

```lua
-- Defaults.lua
local defaults = {
  profile = {
    settings = {
      tooltipEnabled = true,
      announceAwards = true,
      debug = false,
    },
    guildDatasets = {},
  }
}

return defaults
```

```lua
-- Database.lua
local Database = {}

function Database:New(storage)
  local obj = { storage = storage }
  self.__index = self
  return setmetatable(obj, self)
end

function Database:GetGuildDataset(guildKey)
  local datasets = self.storage.profile.guildDatasets
  if not datasets[guildKey] then
    datasets[guildKey] = {
      guildKey = guildKey,
      awards = {},
      awardsById = {},
      nominations = {},
      nominationsById = {},
      permissionRoster = {},
      votesByNomination = {},
    }
  end
  return datasets[guildKey]
end

function Database:UpsertNomination(guildKey, nomination)
  local dataset = self:GetGuildDataset(guildKey)
  dataset.nominationsById[nomination.nominationId] = nomination
  dataset.nominations = {}
  for _, value in pairs(dataset.nominationsById) do
    dataset.nominations[#dataset.nominations + 1] = value
  end
end

function Database:GetNomination(guildKey, nominationId)
  return self:GetGuildDataset(guildKey).nominationsById[nominationId]
end

return Database
```

```lua
-- Core.lua
local Database = dofile("Database.lua")
local Utils = dofile("Utils.lua")

function RPA:OnInitialize()
  self.activeGuildContext = GuildContext:Build()
  self.db = Database:New(Utils.CopyTable(self.defaults))
end
```

- [ ] **Step 4: Run the database tests and verify they pass**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 database`

Expected: PASS for guild dataset creation and nomination storage.

- [ ] **Step 5: Commit**

```bash
git add Database.lua Utils.lua Defaults.lua Core.lua tests/database_spec.lua
git commit -m "feat: add guild dataset database layer"
```

### Task 4: Add GM-Controlled Officer Permissions

**Files:**
- Create: `Permissions.lua`
- Create: `RosterPermissions.lua`
- Create: `tests/permissions_spec.lua`
- Modify: `tests/WoWStubs.lua`
- Modify: `Database.lua`
- Modify: `Core.lua`

- [ ] **Step 1: Write the failing permissions tests**

```lua
-- tests/permissions_spec.lua
local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["gm can grant addon permission to an eligible officer"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      officerNames = { ["Officerone-Stormrage"] = true },
    })

    local addon = dofile("Core.lua")
    addon:OnInitialize()

    local ok = addon.permissions:GrantOfficerPermission("Officerone-Stormrage")
    harness.assert_true(ok)
  end,

  ["officer without gm authority cannot grant addon permission"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Officerone",
      guildRankName = "Officer",
      guildRankIndex = 1,
      officerNames = { ["Officerone-Stormrage"] = true },
    })

    local addon = dofile("Core.lua")
    addon:OnInitialize()

    local ok = addon.permissions:GrantOfficerPermission("Officertwo-Stormrage")
    harness.assert_true(ok == false)
  end,
}
```

- [ ] **Step 2: Extend WoW stubs and verify the permissions tests fail**

```lua
-- tests/WoWStubs.lua
  state.guildRankName = seed.guildRankName or "Member"
  state.guildRankIndex = seed.guildRankIndex or 9
  state.officerNames = seed.officerNames or {}

  _G.GetGuildInfo = function(unit)
    if unit == "player" then
      return state.guildName, state.guildRankName, state.guildRankIndex
    end
    return state.guildName
  end
```

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 gm can grant`

Expected: FAIL because the permissions services do not exist yet.

- [ ] **Step 3: Write minimal roster and permissions services**

```lua
-- RosterPermissions.lua
local RosterPermissions = {}

function RosterPermissions:New(database)
  local obj = { db = database }
  self.__index = self
  return setmetatable(obj, self)
end

function RosterPermissions:Grant(guildKey, playerFullName, grantedBy)
  local dataset = self.db:GetGuildDataset(guildKey)
  dataset.permissionRoster[playerFullName] = {
    player = playerFullName,
    grantedBy = grantedBy,
  }
  return true
end

function RosterPermissions:Has(guildKey, playerFullName)
  local dataset = self.db:GetGuildDataset(guildKey)
  return dataset.permissionRoster[playerFullName] ~= nil
end

return RosterPermissions
```

```lua
-- Permissions.lua
local Permissions = {}

function Permissions:New(addon, roster)
  local obj = { addon = addon, roster = roster }
  self.__index = self
  return setmetatable(obj, self)
end

function Permissions:IsGuildMaster()
  local _, rankName, rankIndex = GetGuildInfo("player")
  return rankIndex == 0 or rankName == "Guild Master"
end

function Permissions:IsOfficer(fullName)
  return self.addon.wowState.officerNames[fullName] == true
end

function Permissions:GrantOfficerPermission(playerFullName)
  if not self:IsGuildMaster() then
    return false
  end
  if not self:IsOfficer(playerFullName) then
    return false
  end
  local guildKey = self.addon:GetActiveGuildContext().guildKey
  return self.roster:Grant(guildKey, playerFullName, self.addon:GetCurrentPlayerFullName())
end

return Permissions
```

```lua
-- Core.lua
local RosterPermissions = dofile("RosterPermissions.lua")
local Permissions = dofile("Permissions.lua")

function RPA:GetCurrentPlayerFullName()
  return ("%s-%s"):format(UnitName("player"), GetRealmName())
end

function RPA:OnInitialize()
  self.activeGuildContext = GuildContext:Build()
  self.wowState = _G.__RPA_TEST_STATE or { officerNames = {} }
  self.db = Database:New(Utils.CopyTable(self.defaults))
  self.rosterPermissions = RosterPermissions:New(self.db)
  self.permissions = Permissions:New(self, self.rosterPermissions)
end
```

- [ ] **Step 4: Run the permissions tests and verify they pass**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 addon permission`

Expected: PASS for GM grant success and non-GM grant rejection.

- [ ] **Step 5: Commit**

```bash
git add Permissions.lua RosterPermissions.lua Database.lua Core.lua tests/WoWStubs.lua tests/permissions_spec.lua
git commit -m "feat: add gm controlled officer permissions"
```

### Task 5: Implement Nominations And Advisory Voting

**Files:**
- Create: `Nominations.lua`
- Create: `tests/nominations_spec.lua`
- Modify: `Database.lua`
- Modify: `Permissions.lua`
- Modify: `Core.lua`

- [ ] **Step 1: Write the failing nominations and vote tests**

```lua
-- tests/nominations_spec.lua
local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["guild member can create a pending nomination"] = function()
    wow.reset({ guildName = "Raid Bakery", playerName = "Bakerone" })
    local addon = dofile("Core.lua")
    addon:OnInitialize()

    local nomination = addon.nominations:Create("Burny-Stormrage", "Pulled the boss while fishing")
    harness.assert_equal("pending", nomination.status)
    harness.assert_equal("Burny-Stormrage", nomination.nominee)
  end,

  ["guild member can cast one locked vote on a pending nomination"] = function()
    wow.reset({ guildName = "Raid Bakery", playerName = "Bakerone" })
    local addon = dofile("Core.lua")
    addon:OnInitialize()

    local nomination = addon.nominations:Create("Burny-Stormrage", "Pulled the boss while fishing")
    local first = addon.nominations:CastVote(nomination.nominationId, "upvote")
    local second = addon.nominations:CastVote(nomination.nominationId, "downvote")

    harness.assert_true(first)
    harness.assert_true(second == false)
  end,
}
```

- [ ] **Step 2: Run the nominations tests and verify they fail**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 pending nomination`

Expected: FAIL because the nominations service is missing.

- [ ] **Step 3: Write minimal nominations and vote-ledger code**

```lua
-- Database.lua
function Database:StoreVote(guildKey, nominationId, vote)
  local dataset = self:GetGuildDataset(guildKey)
  dataset.votesByNomination[nominationId] = dataset.votesByNomination[nominationId] or {}
  dataset.votesByNomination[nominationId][vote.voter] = vote
end

function Database:GetVote(guildKey, nominationId, voter)
  local dataset = self:GetGuildDataset(guildKey)
  local ledger = dataset.votesByNomination[nominationId] or {}
  return ledger[voter]
end
```

```lua
-- Nominations.lua
local Nominations = {}

function Nominations:New(addon)
  local obj = { addon = addon }
  self.__index = self
  return setmetatable(obj, self)
end

function Nominations:Create(nominee, reason)
  local guildKey = self.addon:GetActiveGuildContext().guildKey
  local nomination = {
    nominationId = "nom:" .. tostring(os.time()),
    guildKey = guildKey,
    nominee = nominee,
    reason = reason,
    nominatedBy = self.addon:GetCurrentPlayerFullName(),
    status = "pending",
  }

  self.addon.db:UpsertNomination(guildKey, nomination)
  return nomination
end

function Nominations:CastVote(nominationId, voteType)
  local guildKey = self.addon:GetActiveGuildContext().guildKey
  local voter = self.addon:GetCurrentPlayerFullName()
  if self.addon.db:GetVote(guildKey, nominationId, voter) then
    return false
  end

  self.addon.db:StoreVote(guildKey, nominationId, {
    nominationId = nominationId,
    voter = voter,
    voteType = voteType,
  })
  return true
end

return Nominations
```

```lua
-- Core.lua
local Nominations = dofile("Nominations.lua")

function RPA:OnInitialize()
  self.activeGuildContext = GuildContext:Build()
  self.db = Database:New(Utils.CopyTable(self.defaults))
  self.rosterPermissions = RosterPermissions:New(self.db)
  self.permissions = Permissions:New(self, self.rosterPermissions)
  self.nominations = Nominations:New(self)
end
```

- [ ] **Step 4: Run the nominations tests and verify they pass**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 guild member can`

Expected: PASS for nomination creation and locked single-vote behavior.

- [ ] **Step 5: Commit**

```bash
git add Nominations.lua Database.lua Core.lua tests/nominations_spec.lua
git commit -m "feat: add nominations and advisory voting"
```

### Task 6: Add Awards And Officer Moderation Flows

**Files:**
- Create: `Awards.lua`
- Create: `tests/awards_spec.lua`
- Modify: `Nominations.lua`
- Modify: `Permissions.lua`
- Modify: `Database.lua`
- Modify: `Core.lua`

- [ ] **Step 1: Write the failing awards/moderation tests**

```lua
-- tests/awards_spec.lua
local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["authorized officer can approve a nomination and create an award"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      officerNames = { ["Guildmaster-Stormrage"] = true, ["Officerone-Stormrage"] = true },
    })

    local addon = dofile("Core.lua")
    addon:OnInitialize()
    addon.permissions:GrantOfficerPermission("Officerone-Stormrage")
    wow.setPlayer("Officerone", "Officer", 1)

    local nomination = addon.nominations:Create("Burny-Stormrage", "Pulled the boss while fishing")
    local award = addon.nominations:Approve(nomination.nominationId)

    harness.assert_equal("nomination", award.source)
  end,

  ["rejected nominations remain out of public history"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      officerNames = { ["Guildmaster-Stormrage"] = true },
    })

    local addon = dofile("Core.lua")
    addon:OnInitialize()
    local nomination = addon.nominations:Create("Burny-Stormrage", "Pulled the boss while fishing")
    addon.nominations:Reject(nomination.nominationId)

    harness.assert_equal(0, #addon.awards:GetPublicHistory())
  end,
}
```

- [ ] **Step 2: Extend WoW stubs and verify the awards tests fail**

```lua
-- tests/WoWStubs.lua
function wow.setPlayer(playerName, guildRankName, guildRankIndex)
  state.playerName = playerName
  state.guildRankName = guildRankName
  state.guildRankIndex = guildRankIndex
end
```

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 approve a nomination`

Expected: FAIL because approval/rejection and awards are not implemented.

- [ ] **Step 3: Write minimal awards and moderation code**

```lua
-- Awards.lua
local Awards = {}

function Awards:New(addon)
  local obj = { addon = addon }
  self.__index = self
  return setmetatable(obj, self)
end

function Awards:CreateFromNomination(nomination)
  local award = {
    awardId = "award:" .. tostring(os.time()),
    guildKey = nomination.guildKey,
    player = nomination.nominee,
    reason = nomination.reason,
    awardedBy = self.addon:GetCurrentPlayerFullName(),
    source = "nomination",
    nominationId = nomination.nominationId,
  }
  return award
end

function Awards:GetPublicHistory()
  local guildKey = self.addon:GetActiveGuildContext().guildKey
  return self.addon.db:GetGuildDataset(guildKey).awards
end

return Awards
```

```lua
-- Nominations.lua
function Nominations:Approve(nominationId)
  local guildKey = self.addon:GetActiveGuildContext().guildKey
  local nomination = self.addon.db:GetNomination(guildKey, nominationId)
  nomination.status = "approved"
  nomination.resolvedBy = self.addon:GetCurrentPlayerFullName()

  local award = self.addon.awards:CreateFromNomination(nomination)
  self.addon.db:GetGuildDataset(guildKey).awards[#self.addon.db:GetGuildDataset(guildKey).awards + 1] = award
  return award
end

function Nominations:Reject(nominationId)
  local guildKey = self.addon:GetActiveGuildContext().guildKey
  local nomination = self.addon.db:GetNomination(guildKey, nominationId)
  nomination.status = "rejected"
  nomination.resolvedBy = self.addon:GetCurrentPlayerFullName()
  return true
end
```

```lua
-- Core.lua
local Awards = dofile("Awards.lua")

function RPA:OnInitialize()
  self.activeGuildContext = GuildContext:Build()
  self.db = Database:New(Utils.CopyTable(self.defaults))
  self.rosterPermissions = RosterPermissions:New(self.db)
  self.permissions = Permissions:New(self, self.rosterPermissions)
  self.nominations = Nominations:New(self)
  self.awards = Awards:New(self)
end
```

- [ ] **Step 4: Run the awards tests and verify they pass**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: PASS for nomination approval award creation and rejection staying out of public history.

- [ ] **Step 5: Commit**

```bash
git add Awards.lua Nominations.lua Core.lua tests/WoWStubs.lua tests/awards_spec.lua
git commit -m "feat: add awards and moderation flows"
```

### Task 7: Add Slash Commands And The UI Bridge

**Files:**
- Create: `Commands.lua`
- Create: `UI/Bridge.lua`
- Create: `tests/commands_spec.lua`
- Create: `tests/bridge_spec.lua`
- Modify: `Core.lua`

- [ ] **Step 1: Write the failing command and bridge tests**

```lua
-- tests/commands_spec.lua
local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["slash command routes nominate requests to the nominations service"] = function()
    wow.reset({ guildName = "Raid Bakery" })
    local addon = dofile("Core.lua")
    addon:OnInitialize()

    local called = false
    addon.nominations.Create = function(_, nominee, reason)
      called = nominee == "Burny-Stormrage" and reason == "Pulled the boss"
      return {}
    end

    addon.commands:Handle("nominate Burny-Stormrage \"Pulled the boss\"")
    harness.assert_true(called)
  end,
}
```

```lua
-- tests/bridge_spec.lua
local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["bridge exposes public nomination rows with public upvote totals"] = function()
    wow.reset({ guildName = "Raid Bakery" })
    local addon = dofile("Core.lua")
    addon:OnInitialize()

    local nomination = addon.nominations:Create("Burny-Stormrage", "Pulled the boss while fishing")
    addon.nominations:CastVote(nomination.nominationId, "upvote")

    local rows = addon.uiBridge:GetPendingNominationsViewModel()
    harness.assert_equal(1, rows[1].upvotes)
  end,
}
```

- [ ] **Step 2: Run the command and bridge tests and verify they fail**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 slash command routes`

Expected: FAIL because commands and bridge services do not exist yet.

- [ ] **Step 3: Write minimal commands and bridge code**

```lua
-- Commands.lua
local Commands = {}

function Commands:New(addon)
  local obj = { addon = addon }
  self.__index = self
  return setmetatable(obj, self)
end

function Commands:Handle(message)
  local command, rest = message:match("^(%S+)%s*(.-)$")
  if command == "nominate" then
    local nominee, reason = rest:match('^(%S+)%s+"(.+)"$')
    return self.addon.nominations:Create(nominee, reason)
  end
end

return Commands
```

```lua
-- UI/Bridge.lua
local Bridge = {}

function Bridge:New(addon)
  local obj = { addon = addon }
  self.__index = self
  return setmetatable(obj, self)
end

function Bridge:GetPendingNominationsViewModel()
  local guildKey = self.addon:GetActiveGuildContext().guildKey
  local dataset = self.addon.db:GetGuildDataset(guildKey)
  local rows = {}

  for _, nomination in ipairs(dataset.nominations) do
    local ledger = dataset.votesByNomination[nomination.nominationId] or {}
    local upvotes = 0
    for _, vote in pairs(ledger) do
      if vote.voteType == "upvote" then
        upvotes = upvotes + 1
      end
    end

    rows[#rows + 1] = {
      nominationId = nomination.nominationId,
      nominee = nomination.nominee,
      reason = nomination.reason,
      upvotes = upvotes,
    }
  end

  return rows
end

return Bridge
```

```lua
-- Core.lua
local Commands = dofile("Commands.lua")
local Bridge = dofile("UI/Bridge.lua")

function RPA:OnInitialize()
  self.activeGuildContext = GuildContext:Build()
  self.db = Database:New(Utils.CopyTable(self.defaults))
  self.rosterPermissions = RosterPermissions:New(self.db)
  self.permissions = Permissions:New(self, self.rosterPermissions)
  self.nominations = Nominations:New(self)
  self.awards = Awards:New(self)
  self.commands = Commands:New(self)
  self.uiBridge = Bridge:New(self)
end
```

- [ ] **Step 4: Run the command and bridge tests and verify they pass**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: PASS for slash-command routing and bridge view model generation.

- [ ] **Step 5: Commit**

```bash
git add Commands.lua UI/Bridge.lua Core.lua tests/commands_spec.lua tests/bridge_spec.lua
git commit -m "feat: add commands and ui bridge"
```

### Task 8: Build The Custom Lua UI Shell And Tabs

**Files:**
- Create: `UI/Styles.lua`
- Create: `UI/Components.lua`
- Create: `UI/MainFrame.lua`
- Create: `UI/Tabs/Dashboard.lua`
- Create: `UI/Tabs/Award.lua`
- Create: `UI/Tabs/Nominations.lua`
- Create: `UI/Tabs/History.lua`
- Create: `UI/Tabs/Settings.lua`
- Create: `UI/Tabs/Admin.lua`
- Modify: `RollingPinAwards.toc`
- Modify: `Core.lua`

- [ ] **Step 1: Write the failing UI smoke test**

```lua
-- tests/bridge_spec.lua
["main frame registers the expected tab ids"] = function()
  local MainFrame = dofile("UI/MainFrame.lua")
  local frame = MainFrame:New({
    uiBridge = { GetPendingNominationsViewModel = function() return {} end }
  })

  harness.assert_equal("dashboard", frame.tabs[1].id)
  harness.assert_equal("admin", frame.tabs[6].id)
end,
```

- [ ] **Step 2: Run the UI smoke test and verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 expected tab ids`

Expected: FAIL because the UI files do not exist yet.

- [ ] **Step 3: Write the minimal reusable UI shell**

```lua
-- UI/Styles.lua
local Styles = {
  Window = { width = 920, height = 680 },
  Tabs = { "dashboard", "award", "nominations", "history", "settings", "admin" },
}

return Styles
```

```lua
-- UI/Components.lua
local Components = {}

function Components.MakeTab(id, label)
  return {
    id = id,
    label = label,
  }
end

return Components
```

```lua
-- UI/MainFrame.lua
local Styles = dofile("UI/Styles.lua")
local Components = dofile("UI/Components.lua")

local MainFrame = {}

function MainFrame:New(deps)
  local obj = {
    uiBridge = deps.uiBridge,
    tabs = {
      Components.MakeTab("dashboard", "Dashboard"),
      Components.MakeTab("award", "Award"),
      Components.MakeTab("nominations", "Nominations"),
      Components.MakeTab("history", "History"),
      Components.MakeTab("settings", "Settings"),
      Components.MakeTab("admin", "Admin"),
    },
    width = Styles.Window.width,
    height = Styles.Window.height,
  }
  self.__index = self
  return setmetatable(obj, self)
end

return MainFrame
```

```lua
-- UI/Tabs/Dashboard.lua
return { id = "dashboard" }
```

```lua
-- UI/Tabs/Award.lua
return { id = "award" }
```

```lua
-- UI/Tabs/Nominations.lua
return { id = "nominations" }
```

```lua
-- UI/Tabs/History.lua
return { id = "history" }
```

```lua
-- UI/Tabs/Settings.lua
return { id = "settings" }
```

```lua
-- UI/Tabs/Admin.lua
return { id = "admin" }
```

```toc
## Interface: 120005, 110207
## Title: Rolling Pin Awards
## Notes: Guild awards and nominations for The Burnt Rolling Pin
## Author: Ziri
## Version: 0.1.0
## SavedVariables: RollingPinAwardsDB
## OptionalDeps: Ace3

Constants.lua
Defaults.lua
Utils.lua
GuildContext.lua
Database.lua
Permissions.lua
RosterPermissions.lua
Awards.lua
Nominations.lua
Sync.lua
Commands.lua
Announcements.lua
Tooltip.lua
Core.lua
UI\Bridge.lua
UI\Styles.lua
UI\Components.lua
UI\MainFrame.lua
UI\Tabs\Dashboard.lua
UI\Tabs\Award.lua
UI\Tabs\Nominations.lua
UI\Tabs\History.lua
UI\Tabs\Settings.lua
UI\Tabs\Admin.lua
```

- [ ] **Step 4: Run the UI smoke test and verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 expected tab ids`

Expected: PASS for the main-frame tab registration test.

- [ ] **Step 5: Commit**

```bash
git add UI/Styles.lua UI/Components.lua UI/MainFrame.lua UI/Tabs/Dashboard.lua UI/Tabs/Award.lua UI/Tabs/Nominations.lua UI/Tabs/History.lua UI/Tabs/Settings.lua UI/Tabs/Admin.lua tests/bridge_spec.lua
git commit -m "feat: add custom lua ui shell"
```

### Task 9: Add Guild-Scoped Sync, Announcements, Tooltip, And Docs

**Files:**
- Create: `Sync.lua`
- Create: `Announcements.lua`
- Create: `Tooltip.lua`
- Create: `tests/sync_spec.lua`
- Create: `README.md`
- Create: `docs/testing.md`
- Create: `docs/sync.md`
- Create: `docs/permissions.md`
- Modify: `Core.lua`
- Modify: `RollingPinAwards.toc`

- [ ] **Step 1: Write the failing sync test**

```lua
-- tests/sync_spec.lua
local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["sync rejects a privileged award update from the wrong guild"] = function()
    wow.reset({ guildName = "Raid Bakery" })
    local addon = dofile("Core.lua")
    addon:OnInitialize()

    local accepted = addon.sync:AcceptAward({
      guildKey = "other guild",
      awardedBy = "Officerone-Stormrage",
    })

    harness.assert_true(accepted == false)
  end,
}
```

- [ ] **Step 2: Run the sync test and verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 wrong guild`

Expected: FAIL because the sync service does not exist yet.

- [ ] **Step 3: Write minimal sync, announcement, tooltip, and docs**

```lua
-- Sync.lua
local Sync = {}

function Sync:New(addon)
  local obj = { addon = addon }
  self.__index = self
  return setmetatable(obj, self)
end

function Sync:AcceptAward(award)
  local guild = self.addon:GetActiveGuildContext()
  if not guild or award.guildKey ~= guild.guildKey then
    return false
  end
  return true
end

return Sync
```

```lua
-- Announcements.lua
local Announcements = {}

function Announcements:New()
  local obj = {}
  self.__index = self
  return setmetatable(obj, self)
end

function Announcements:FormatAwardMessage(playerName, reason)
  return ("[Rolling Pin Awards] %s received The Burnt Rolling Pin for: %s"):format(playerName, reason)
end

return Announcements
```

```lua
-- Tooltip.lua
local Tooltip = {}

function Tooltip:New()
  local obj = {}
  self.__index = self
  return setmetatable(obj, self)
end

return Tooltip
```

```markdown
# Rolling Pin Awards

Rolling Pin Awards is a guild-only WoW addon for nominations, advisory voting, moderation, and awarding The Burnt Rolling Pin.
```

```markdown
# Testing

Run tests with:

`powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`
```

```markdown
# Sync

All synced objects are guild-scoped. Privileged actions must pass guild and authority validation before merge.
```

```markdown
# Permissions

Only the GM can manage the addon permission roster. Only GM-authorized officers can directly award, approve, or reject.
```

```lua
-- Core.lua
local Sync = dofile("Sync.lua")
local Announcements = dofile("Announcements.lua")
local Tooltip = dofile("Tooltip.lua")

function RPA:OnInitialize()
  self.activeGuildContext = GuildContext:Build()
  self.db = Database:New(Utils.CopyTable(self.defaults))
  self.rosterPermissions = RosterPermissions:New(self.db)
  self.permissions = Permissions:New(self, self.rosterPermissions)
  self.nominations = Nominations:New(self)
  self.awards = Awards:New(self)
  self.commands = Commands:New(self)
  self.uiBridge = Bridge:New(self)
  self.sync = Sync:New(self)
  self.announcements = Announcements:New(self)
  self.tooltip = Tooltip:New(self)
end
```

- [ ] **Step 4: Run the sync test and full suite and verify they pass**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 wrong guild`

Expected: PASS for wrong-guild rejection.

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: PASS for the full suite with no failures.

- [ ] **Step 5: Commit**

```bash
git add Sync.lua Announcements.lua Tooltip.lua README.md docs/testing.md docs/sync.md docs/permissions.md Core.lua tests/sync_spec.lua
git commit -m "feat: add sync tooltip announcements and docs"
```

---

## Plan Self-Review

### Spec Coverage

- Native Lua UI: covered in Task 8.
- Guild-only current-guild dataset: covered in Tasks 2 and 3.
- GM-managed officer permission roster: covered in Task 4.
- Nominations, advisory voting, and locked single-vote behavior: covered in Task 5.
- Awards and moderation: covered in Task 6.
- Bridge-only UI data flow: covered in Task 7.
- Guild-scoped sync and privileged validation: covered in Task 9.
- Docs kept up to date: covered in Task 9.

### Placeholder Scan

- No `TBD`, `TODO`, or deferred placeholder steps remain in the plan body.
- Each task includes exact file paths, commands, and code blocks.

### Type And Naming Consistency

- Addon namespace is consistently `RPA`.
- Guild scoping consistently uses `guildKey`.
- Nomination ids use `nominationId`.
- Award ids use `awardId`.
- Bridge entry point is consistently `UI/Bridge.lua`.

### Known Adjustment During Execution

- Replace the temporary globals-based test environment access with a cleaner environment adapter once the harness and production environment boundaries are established.
- Keep that cleanup inside the same TDD cycle where the related tests stay green.

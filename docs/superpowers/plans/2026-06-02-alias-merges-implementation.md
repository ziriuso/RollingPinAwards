# Alias Merges Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a guild-shared alias merge system that canonically displays nomination nominees and award recipients under one full `Name-Realm` identity without rewriting stored records.

**Architecture:** Keep alias merges as reversible display-level configuration inside the current guild dataset. Store mappings centrally in the database layer, resolve names through one shared bridge helper, and surface management in the `Admin` tab using the existing reusable scrollable-section and button patterns. Route alias changes through the same privileged guild-config sync path used for rank-permission updates.

**Tech Stack:** Lua, WoW `CreateFrame` UI, Ace3-aware addon runtime, lightweight Lua test harness under `tests/`

---

### Task 1: Lock alias-resolution behavior with failing tests

**Files:**
- Modify: `tests/bridge_spec.lua`
- Modify: `tests/database_spec.lua`
- Modify: `tests/sync_spec.lua`

- [ ] **Step 1: Add failing database tests for guild-scoped alias mapping CRUD**

Add tests in `tests/database_spec.lua` covering:
- storing an alias mapping in the active guild dataset
- retrieving a mapping by normalized alias key
- listing mappings in deterministic order
- deleting a mapping without touching awards or nominations

Use rows shaped like:

```lua
{
  aliasKey = "moon",
  aliasDisplay = "Moon",
  canonicalName = "Moonrustle-Stormrage",
  createdBy = "Guildmaster-Stormrage",
  createdAt = 1760000000,
}
```

- [ ] **Step 2: Add failing bridge tests for display-level canonical resolution**

Add tests in `tests/bridge_spec.lua` covering:
- pending nominations show canonical nominee names when a mapping exists
- moderation queue rows show canonical nominee names when a mapping exists
- history rows show canonical recipient names when a mapping exists
- leaderboard groups `Moon`, `Moonrustle`, and `Moonrustle-Stormrage` under one canonical row
- removing a mapping restores raw-name display

- [ ] **Step 3: Add failing permission and validation tests for alias management**

Add tests in `tests/bridge_spec.lua` covering:
- unauthorized ranks cannot add or remove alias mappings through the bridge
- canonical names without `-` are rejected
- alias-management view model remains scrollable with many mappings

- [ ] **Step 4: Add a failing sync test for privileged alias mapping updates**

Add a new case in `tests/sync_spec.lua` covering:
- authorized guild config managers can sync an alias mapping update
- unauthorized senders are rejected if they attempt the same update

- [ ] **Step 5: Run focused tests to verify red**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 bridge database sync`

Expected: FAIL for missing alias mapping storage, bridge resolution, admin UI data, and sync handling

### Task 2: Add alias mapping storage and normalization helpers

**Files:**
- Modify: `Database.lua`
- Modify: `Utils.lua`
- Modify: `tests/database_spec.lua`

- [ ] **Step 1: Extend the guild dataset shape with alias mapping storage**

Add `aliasMappingsByKey` to:
- `ensureGuildDatasetShape`
- new dataset creation in `Database:GetGuildDataset`
- guild-dataset migration logic so alias mappings survive guild-key migration the same way other guild-scoped data does

- [ ] **Step 2: Add a shared alias-key normalizer**

Add a focused helper in `Utils.lua` that:
- accepts a raw typed name
- trims leading and trailing whitespace
- lowercases the value
- returns a stable key for alias lookups such as `moon` or `moonrustle-stormrage`

Keep it generic enough to reuse across bridge and database code, but scoped to exact-string normalization only. Do not add fuzzy matching.

- [ ] **Step 3: Add alias mapping CRUD helpers in `Database.lua`**

Implement:
- `UpsertAliasMapping(guildKey, row)`
- `GetAliasMapping(guildKey, aliasKey)`
- `GetAliasMappings(guildKey)`
- `DeleteAliasMapping(guildKey, aliasKey)`

Behavior:
- rows are keyed by normalized `aliasKey`
- list results should sort by `aliasDisplay`, then `canonicalName`
- deleting a mapping removes only the alias row

- [ ] **Step 4: Run focused tests to verify green for storage**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 database`

Expected: PASS for alias CRUD tests

### Task 3: Add bridge resolution and privileged alias management

**Files:**
- Modify: `UI/Bridge.lua`
- Modify: `Permissions.lua`
- Modify: `tests/bridge_spec.lua`

- [ ] **Step 1: Add a shared bridge-level display resolver**

Implement a helper in `UI/Bridge.lua` such as:
- `ResolveDisplayCharacterName(rawName)`

Behavior:
- normalize `rawName` with the shared utility
- look up the current guild alias mapping
- return `canonicalName` when a mapping exists
- otherwise return `rawName`

- [ ] **Step 2: Add bridge methods for alias management**

Implement bridge methods such as:
- `GetAliasMappingsViewModel()`
- `SaveAliasMapping(aliasDisplay, canonicalName)`
- `DeleteAliasMapping(aliasKey)`

Behavior:
- require GM or `Manage Addon Permissions/Settings`
- reject empty alias values
- reject canonical names that do not include `-`
- populate `createdBy` from the current player full name
- populate `createdAt` from the shared time helper already used elsewhere in the addon

- [ ] **Step 3: Update existing view models to use canonical recipient and nominee display**

Apply the shared resolver to:
- `GetPendingNominationsViewModel()`
- moderation rows produced from pending nominations
- `GetPublicHistoryViewModel()`
- `GetLeaderboardViewModel()`

For leaderboard grouping, use the resolved canonical name as the grouping key and display name.

- [ ] **Step 4: Run focused tests to verify green**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 bridge`

Expected: PASS for alias-resolution, validation, and permission tests

### Task 4: Add alias merge sync support

**Files:**
- Modify: `Sync.lua`
- Modify: `tests/sync_spec.lua`

- [ ] **Step 1: Add alias mapping payload handling to privileged sync**

Mirror the rank-permission update path by adding a privileged alias-mapping update shape that:
- carries `aliasKey`, `aliasDisplay`, `canonicalName`, `createdBy`, and `createdAt`
- validates guild scope
- validates sender authority through the existing privileged checks
- upserts or deletes alias mappings in the current guild dataset

- [ ] **Step 2: Add bridge or sync broadcast hook for local alias changes**

When a local admin saves or removes an alias mapping, broadcast the corresponding privileged config update through the existing sync transport so other guild clients can converge.

- [ ] **Step 3: Run focused sync tests**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 sync`

Expected: PASS for rank-permission tests and the new alias-mapping sync tests

### Task 5: Add alias merge controls to the Admin tab

**Files:**
- Modify: `UI/Tabs/Admin.lua`
- Modify: `UI/Components.lua`
- Modify: `tests/bridge_spec.lua`

- [ ] **Step 1: Extend the admin view model shape**

Ensure the admin tab receives:
- the existing rank-permission matrix
- moderation queue data
- a new alias-mappings view model with list rows and permission state

- [ ] **Step 2: Add the `Alias Merges` form and mapping list**

Build a new admin section with:
- `Alias` input
- `Canonical Character` input
- `Add Merge` button
- scrollable mapping list with `Remove` buttons

Keep the section anchored inside the existing admin content flow and reuse the current scalable section patterns instead of creating a standalone window.

- [ ] **Step 3: Wire interactions and status messaging**

On add:
- save through `bridge:SaveAliasMapping`
- clear inputs on success
- rerender the admin tab

On remove:
- delete through `bridge:DeleteAliasMapping`
- rerender the admin tab

Status messaging should clearly report validation or permission failures without throwing Lua errors.

- [ ] **Step 4: Run focused UI tests**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 bridge`

Expected: PASS for admin alias list rendering, scrollability, and button actions

### Task 6: Update docs, verify, deploy, and commit

**Files:**
- Modify: `README.md`
- Modify: `docs/permissions.md`
- Modify: `docs/superpowers/specs/2026-06-02-alias-merges-design.md` only if implementation reveals ambiguity

- [ ] **Step 1: Update project docs**

Document:
- alias merges are guild-shared display-level config
- only nominees and recipients are canonicalized
- admin users manage mappings from the `Admin` tab

- [ ] **Step 2: Run the full suite**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

Expected: PASS

- [ ] **Step 3: Deploy the verified addon to Retail and PTR**

Copy the verified addon files into:
- `C:\Gaming\World of Warcraft\_retail_\Interface\AddOns\RollingPinAwards`
- `C:\Gaming\World of Warcraft\_xptr_\Interface\AddOns\RollingPinAwards`

- [ ] **Step 4: Commit the feature**

Suggested commit message:

```bash
git add README.md docs/permissions.md Database.lua Utils.lua UI/Bridge.lua UI/Tabs/Admin.lua UI/Components.lua Sync.lua tests/database_spec.lua tests/bridge_spec.lua tests/sync_spec.lua docs/superpowers/plans/2026-06-02-alias-merges-implementation.md docs/superpowers/specs/2026-06-02-alias-merges-design.md
git commit -m "feat: add guild alias merges"
```

## Self-Review

- Spec coverage: the plan covers guild-shared alias storage, reversible display-level canonicalization, admin management UI, privileged sync, and the required tests for nominee, recipient, leaderboard, validation, and permissions behavior.
- Placeholder scan: no `TODO`, `TBD`, or task references without concrete target files or expected verification commands remain.
- Type consistency: the plan consistently uses `aliasMappingsByKey`, `aliasKey`, `aliasDisplay`, `canonicalName`, `GetAliasMappingsViewModel`, `SaveAliasMapping`, `DeleteAliasMapping`, and `ResolveDisplayCharacterName` across database, bridge, sync, and UI tasks.

# Rolling Pin Awards Rank Permissions Design

**Date:** 2026-06-02  
**Project:** Rolling Pin Awards  
**Supersedes:** `docs/superpowers/specs/2026-06-01-rolling-pin-awards-design.md` sections related to addon permissions, admin UI, and destructive award behavior

## Goal

Replace the current per-character officer grant model with a simpler rank-based permission matrix, fix the live WoW timestamp crashes affecting nominations and awards, and clarify destructive award deletion behavior.

## Why This Change Exists

The current officer grant model creates a poor guild-management experience:

- grants are tracked per character instead of by guild rank
- revoke behavior is awkward and easy to miss in the UI
- admin intent is harder to understand than rank-based policy
- the design no longer matches the desired guild workflow

The live client also exposed a separate runtime bug:

- nomination submission crashes because `Nominations.lua` relies on `os.time()`
- direct award creation crashes because `Awards.lua` relies on `os.time()`

This spec fixes both the permission model and the shared runtime issue in one coordinated change.

## Final Product Decisions

- Permissions are stored by exact guild `rankIndex`
- The UI displays the guild `rankName`, not the numeric rank index
- `Rank 0` / guild master always has full access regardless of the matrix
- No per-character overrides exist in MVP after this change
- `Admin` is hidden unless the player is GM or has `Manage Addon Permissions/Settings`
- Anyone with `Manage Addon Permissions/Settings` may edit the permission matrix, including their own rank
- Deleting an award requires confirmation
- Deleting an award also deletes its linked nomination when one exists
- Award and nomination timestamps must use a WoW-safe timestamp helper instead of relying on `os`

## Permission Model

The addon stores one permission row per guild rank index.

Each non-GM rank can independently toggle these booleans:

- `canManageNominations`
- `canCreateDirectAwards`
- `canDeleteAwards`
- `canManageAddonPermissions`

GM behavior:

- `rankIndex == 0` always resolves to full access
- GM does not depend on stored checkbox state

Exact-rank behavior:

- rank access is resolved only from the player's exact rank index
- higher ranks do not inherit lower-rank permissions automatically
- if a rank row is missing, it defaults to no access

## Data Model Changes

### Remove

The old shared permission roster model is removed from the primary authority path:

- no per-player grant list
- no grant/revoke workflow by officer character
- no officer roster-based privilege validation for local UI authority

### Add

Each guild dataset stores a `rankPermissions` table keyed by rank index.

Proposed row shape:

```lua
rankPermissions = {
  [1] = {
    rankIndex = 1,
    rankName = "Officer",
    canManageNominations = true,
    canCreateDirectAwards = true,
    canDeleteAwards = false,
    canManageAddonPermissions = true,
    lastModifiedAt = 1234567890,
    lastModifiedBy = "Name-Realm",
  },
}
```

Rules:

- `rankName` is display metadata only
- `rankIndex` is the real authority key
- rank names may refresh from live guild data without changing the authority mapping

## Permission Resolution Rules

The permission service should expose explicit helpers:

- `CanManageNominations()`
- `CanCreateDirectAwards()`
- `CanDeleteAwards()`
- `CanManageAddonPermissions()`

Resolution order:

1. Read the current player's guild rank info
2. If the player is rank `0`, return `true`
3. Otherwise load the exact rank-permission row by `rankIndex`
4. Return the requested boolean from that row

This replaces the current officer-roster plus guild-rank hybrid checks.

## UI Changes

### Admin Tab

The `Admin` tab becomes a rank-permission management screen.

Visibility:

- hidden unless the player is GM or has `Manage Addon Permissions/Settings`

Contents:

- one row per guild rank shown by rank name
- four checkboxes per row:
  - `Manage Nominations`
  - `Create Direct Awards`
  - `Delete Awards`
  - `Manage Addon Permissions/Settings`
- a note explaining that GM always has full access

Interaction:

- changing checkboxes updates the exact rank-index row
- users with `Manage Addon Permissions/Settings` may edit any rank row, including their own rank

### Award Tab

- tab remains visible in the main window
- direct award action is enabled only when `CanCreateDirectAwards()` or GM
- unauthorized players may view the tab but cannot submit awards

### Nominations Tab

- any guild member may submit nominations
- approve and reject actions are shown only when `CanManageNominations()` or GM
- voting remains available to guild members while a nomination is pending

### History Tab

- approved awards remain visible to all guild members
- delete actions are shown only when `CanDeleteAwards()` or GM
- deleting an award opens a confirmation message that explicitly says the linked nomination will also be deleted

### Settings Tab

- remains visible to all users
- continues to hold only local/personal settings
- never contains guild rank permission management

## Delete Behavior

Deleting an award is destructive and permanent.

Rules:

- direct awards delete only the award record
- nomination-derived awards delete both:
  - the award record
  - the linked nomination record
- this does not reopen the nomination
- the deleted nomination is fully removed rather than restored to pending

Required UI confirmation text must make this explicit before execution.

## Timestamp Runtime Fix

The live client errors show that direct use of `os.time()` is not safe in this addon runtime.

The addon should centralize timestamp access behind a WoW-safe helper with this preference order:

1. WoW-safe time API if available in client runtime
2. a safe fallback used by the local Lua test harness

All of these paths should use the shared helper:

- nomination creation
- nomination vote updates
- nomination approval
- nomination rejection
- direct award creation
- nomination-derived award creation
- rank-permission row updates

This avoids duplicating runtime assumptions across files.

## Sync Impact

This change alters the guild authority object model.

Required updates:

- sync should stop treating per-player permission roster entries as the primary authority source
- sync should carry rank-permission updates instead
- local privileged action validation should resolve authority from the rank matrix
- GM still bypasses the matrix for validation

Backward compatibility for old roster data is not required for MVP beyond ignoring stale roster structures safely.

## Testing Plan

Add or update tests for:

- exact-rank permission lookup by rank index
- GM forced full access
- no automatic inheritance between ranks
- rank-matrix mutation through admin-facing helpers
- `Admin` hidden when unauthorized
- approve/reject availability only with `Manage Nominations`
- direct award availability only with `Create Direct Awards`
- delete availability only with `Delete Awards`
- deleting a direct award deletes only the award
- deleting a nomination-linked award deletes both award and nomination
- WoW-safe timestamp helper works in the harness without `os`
- live UI flow regressions:
  - close and reopen `/rpa`
  - tab switching does not layer panels
  - scrollable lists still function after permission-model changes

## In-Game Verification

After deployment, verify:

1. a normal guild member can submit a nomination but cannot approve, award, or open `Admin`
2. a configured rank with `Manage Nominations` can approve and reject
3. a configured rank with `Create Direct Awards` can create direct awards
4. a configured rank with `Delete Awards` can delete awards
5. deleting a nomination-derived award removes the linked nomination
6. a configured rank with `Manage Addon Permissions/Settings` can open `Admin` and change rank checkboxes
7. GM always has access even if matrix rows are unset
8. nomination submission and direct award creation no longer crash from missing `os`

## Out of Scope

- per-character permission overrides
- rank inheritance rules
- partial undelete or recycle-bin flows
- historical audit UI for deleted awards
- migration UI for legacy officer grant data

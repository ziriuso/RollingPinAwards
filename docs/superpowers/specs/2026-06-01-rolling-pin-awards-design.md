# Rolling Pin Awards Design Spec

**Date:** 2026-06-01  
**Project:** Rolling Pin Awards  
**Addon Folder:** `RollingPinAwards`  
**Slash Command:** `/rpa`  
**SavedVariables:** `RollingPinAwardsDB`

## Goal

Build a guild-scoped World of Warcraft addon that lets guild members submit funny nominations, lets GM-authorized officers moderate and award `The Burnt Rolling Pin`, and presents the data in a custom native WoW Lua UI with safe guild sync.

## Design Decisions

- Native WoW Lua UI is the primary implementation path.
- React-to-Lua is explicitly not an MVP dependency.
- The UI is `CreateFrame`-only and Lua-only.
- The addon is guild-only.
- The addon keeps one active dataset for the player's current guild only.
- Pending nominations are visible to all guild members using the addon.
- Rejected nominations are visible only in admin/moderation views.
- Direct awards use the same permission rules as nomination approval.
- GM grants addon permission to officers through the addon.
- Permission roster is guild-shared.
- Advisory voting is included for pending nominations.

## React Research Outcome

The exported Figma Make React project should be treated as visual reference material only.

Reasons:

- The provided `react-wow-addon` path is not mature enough to anchor MVP delivery.
- The public repository still documents itself as blocked on historical TypeScriptToLua dependency-import limitations.
- The repository is old, lightly documented, and pinned to outdated TypeScript/TypeScriptToLua versions.
- The addon needs a stable WoW-native path more than an experimental compile chain.

Conclusion:

- Implement the real addon in native WoW Lua.
- Preserve the Figma export as a design reference.
- A future React/Lua spike is allowed only as an optional follow-up experiment and must not affect the backend architecture.

## Product Scope

### In Scope

- Guild-scoped nominations
- Guild-scoped direct awards
- Shared guild dataset sync
- GM-managed officer permission roster
- Public pending nominations view
- Admin-only rejected nominations view
- Advisory voting on pending nominations
- Dashboard, Award, Nominations, History, Settings, and Admin tabs
- Chat announcements
- Tooltip integration
- Slash commands
- SavedVariables persistence
- Sync diagnostics suitable for MVP troubleshooting

### Out of Scope

- React UI runtime
- Multi-guild historical datasets
- Non-guild party/raid-only datasets
- External web services or remote database integration
- Auto-approval or auto-rejection from votes
- Complex conflict-resolution UI
- Full import/export workflows

## Architecture

The addon will be built in four layers.

### 1. Core Platform

Responsibilities:

- Ace3 addon lifecycle
- SavedVariables bootstrapping
- slash command registration
- event registration
- addon communication registration

Files:

- `Core.lua`
- `Constants.lua`
- `Defaults.lua`
- `Utils.lua`
- `Commands.lua`

### 2. Domain Services

Responsibilities:

- current guild dataset selection
- permission evaluation
- guild-shared permission roster management
- nomination creation and moderation
- award creation
- sync validation and merge rules
- announcements
- tooltip data

Files:

- `GuildContext.lua`
- `Database.lua`
- `Permissions.lua`
- `RosterPermissions.lua`
- `Awards.lua`
- `Nominations.lua`
- `Sync.lua`
- `Announcements.lua`
- `Tooltip.lua`

### 3. UI Bridge

Responsibilities:

- expose read-only view models to the UI
- expose action methods to the UI
- keep frame code decoupled from persistence and business logic

File:

- `UI/Bridge.lua`

### 4. Custom Lua UI

Responsibilities:

- render the addon window and tabs
- render reusable components
- call bridge actions only
- never mutate SavedVariables directly

Files:

- `UI/Styles.lua`
- `UI/Components.lua`
- `UI/MainFrame.lua`
- `UI/Tabs/Dashboard.lua`
- `UI/Tabs/Award.lua`
- `UI/Tabs/Nominations.lua`
- `UI/Tabs/History.lua`
- `UI/Tabs/Settings.lua`
- `UI/Tabs/Admin.lua`

## Boundary Rules

- Only backend/domain modules may mutate persistent data.
- UI code only communicates through `UI/Bridge.lua`.
- Sync handlers must validate guild context and sender authority before merge.
- The current guild dataset is the only active writable dataset.
- Rejected nominations never appear in public history or public nomination surfaces.
- Voting data is attached to pending nominations and closes when moderation finishes.

## Guild Dataset Model

The addon stores one active dataset for the player's current guild.

### Guild Identity

The dataset must include:

- guild name
- a stable guild identifier if WoW API support is available, otherwise a normalized guild-name key
- dataset version/schema version

All synced objects must match the active guild context before they are accepted.

### Awards

Awards are permanent records for approved or directly granted instances of `The Burnt Rolling Pin`.

The player-facing award name should always be rendered as `The Burnt Rolling Pin`.

Fields:

- `awardId`
- `guildKey`
- `player`
- `playerDisplay`
- `reason`
- `awardedBy`
- `awardedByDisplay`
- `source` (`direct` or `nomination`)
- `nominationId` if applicable
- `createdAt`
- `revision`
- `lastModifiedAt`
- `lastModifiedBy`

### Nominations

Nominations are guild-scoped moderation records.

Fields:

- `nominationId`
- `guildKey`
- `nominee`
- `nomineeDisplay`
- `nominatedBy`
- `nominatedByDisplay`
- `reason`
- `status` (`pending`, `approved`, `rejected`)
- `resolvedBy`
- `resolvedByDisplay`
- `resolvedAt`
- `awardId`
- `createdAt`
- `revision`
- `lastModifiedAt`
- `lastModifiedBy`
- `moderationFlagged`

### Permission Roster

The shared roster defines which officers have addon permission.

Fields:

- `player`
- `playerDisplay`
- `grantedBy`
- `grantedAt`
- `revision`
- `lastModifiedAt`

Rules:

- Only the GM can add or remove roster entries.
- Only guild officers are eligible for inclusion.
- Officers are not automatically trusted by rank alone.
- A privileged action is valid only when the sender is both an officer and present on the roster.

### Vote Ledger

Each pending nomination may store a guild member vote ledger.

Fields per vote:

- `nominationId`
- `voter`
- `voteType` (`upvote` or `downvote`)
- `createdAt`

Rules:

- One vote per guild member per nomination
- Votes are locked once cast
- Votes exist only while a nomination is pending
- Duplicate votes from the same voter are ignored after the first accepted vote

### Local Settings

Per-player local settings remain local, not guild-shared.

Examples:

- window position and selected tab
- tooltip enabled
- announcement enabled
- quiet mode
- debug mode

## Permission Model

### Guild Member Permissions

- Any guild member may submit a nomination.
- Any guild member may view pending nominations.
- Any guild member may cast one advisory vote on a pending nomination.

### GM Permissions

- Manage the addon permission roster
- Perform direct awards
- Approve nominations
- Reject nominations
- Access the Admin tab

### GM-Authorized Officer Permissions

An officer may perform privileged actions only after the GM grants addon permission through the guild-shared roster.

Allowed actions:

- direct awards
- approve nominations
- reject nominations
- admin/moderation views

### Incoming Sync Validation

Incoming privileged records are accepted only if:

- the record belongs to the current guild dataset
- the sender identity is valid
- `ROSTER_UPSERT` sender is the GM for the current guild dataset
- direct-award and nomination-resolution senders are officers in the current guild context
- direct-award and nomination-resolution senders exist in the synced permission roster

## Sync Design

Sync is guild-scoped and object-based.

### Required Message Families

- `HELLO`
- `REQ_SYNC`
- `SYNC_SUMMARY`
- `REQ_OBJECTS`
- `NOM_UPSERT`
- `NOM_STATUS`
- `AWARD_UPSERT`
- `ROSTER_UPSERT`
- `VOTE_UPSERT`
- `PING`
- `PONG`

### Merge Rules

For nominations, awards, roster entries, and vote objects:

- reject records for the wrong guild dataset
- insert if missing and valid
- replace if incoming revision is newer and valid
- prefer newer `lastModifiedAt` when revisions tie
- record a conflict when content differs at the same revision

### Voting Sync Rules

- Votes sync separately from the nomination body
- Votes are accepted only for `pending` nominations
- Votes are ignored if the local client already has a vote from that voter for that nomination
- Votes do not mutate moderation state directly
- Downvote totals may trigger `moderationFlagged = true` for officer/admin views

### Moderation Flagging

Heavy downvotes must auto-flag a nomination for officer/admin review.

For MVP:

- the flag is informational only
- the flag must not auto-reject or hide the nomination
- the exact threshold should be configurable in code/constants, not hard-coded into UI text

## UI Structure

The addon uses a single movable main window with custom reusable components.

Tabs:

- `Dashboard`
- `Award`
- `Nominations`
- `History`
- `Settings`
- `Admin`

### Dashboard

Shows:

- total awards
- pending nomination count
- top recipients
- recent awards
- sync status
- permission status

### Award

Shows:

- privileged direct-award form
- validation feedback
- disabled state for unauthorized users

### Nominations

Shows:

- nomination submission form for all guild members
- public pending nominations list
- public upvote count
- voting controls for members who have not voted
- officer/admin moderation controls when authorized

### History

Shows:

- approved awards only
- searchable/filterable history
- no rejected nominations

### Settings

Shows local-only preferences:

- announcement preferences
- tooltip preferences
- debug toggle
- UI behavior preferences

### Admin

Shows authorized-only controls and diagnostics:

- rejected nominations
- moderation flags
- hidden downvote counts
- permission roster management
- sync diagnostics

## UI Component Strategy

Reusable/scalable controls should be implemented as focused helpers or factories in `UI/Components.lua`.

Initial reusable components:

- window shell
- tab button
- card panel
- section header
- labeled input
- multiline edit box
- checkbox/toggle
- row list
- status banner
- empty state
- confirmation dialog
- vote badge
- moderation badge

The goal is to avoid one-off frame logic scattered across tabs.

## User Flows

### Submit Nomination

1. Guild member opens the Nominations tab.
2. Member enters nominee and reason.
3. Backend validates guild context and inputs.
4. Nomination is created with status `pending`.
5. UI refreshes.
6. Nomination sync broadcasts.

### Cast Vote

1. Guild member selects upvote or downvote on a pending nomination.
2. Backend verifies current guild context and absence of an existing vote.
3. Vote is persisted.
4. Vote sync broadcasts.
5. UI refreshes public upvote state and officer/admin moderation state.

### Approve Nomination

1. Authorized officer or GM selects Approve.
2. Backend validates sender authority.
3. Nomination status becomes `approved`.
4. Linked award is created.
5. Public lists and history refresh.
6. Nomination status and award sync broadcast.

### Reject Nomination

1. Authorized officer or GM selects Reject.
2. Backend validates sender authority.
3. Nomination status becomes `rejected`.
4. Public list removes it.
5. Admin view retains it.
6. Rejection sync broadcasts.

### Direct Award

1. Authorized officer or GM opens the Award tab.
2. User enters player and reason.
3. Backend validates authority and inputs.
4. Award is created.
5. Dashboard and history refresh.
6. Award sync broadcasts.

### Grant Officer Permission

1. GM opens the Admin tab.
2. GM adds or removes an eligible officer from the roster.
3. Backend validates guild context and GM authority.
4. Roster update persists.
5. Roster sync broadcasts.

## Non-Guild Behavior

When the player is not in a valid current guild context:

- the addon should not allow new nominations, votes, awards, or moderation actions
- the UI should explain that Rolling Pin Awards is guild-only
- local settings UI may still be accessible
- the dataset is treated as inactive

## Testing Strategy

The implementation must follow TDD and create unit tests around backend behavior before production code is added.

Priority test areas:

- guild dataset activation and rejection outside guild context
- player normalization
- nomination creation
- vote acceptance and duplicate-vote rejection
- approval creating linked awards
- rejection hiding nominations from public views
- GM-only roster mutation
- officer authorization requiring both rank eligibility and GM grant
- privileged sync validation
- guild mismatch sync rejection
- merge behavior on revision changes

UI testing focus:

- bridge view models map backend state correctly
- unauthorized controls render disabled states
- pending nominations show public upvote counts only
- admin views show downvote totals and rejected nominations

## Documentation Requirements

The project documentation should be kept up to date as implementation progresses.

Minimum docs to maintain during implementation:

- addon README
- install/setup notes
- test instructions
- sync behavior notes
- permission model summary

## Recommended Delivery Order

1. Addon foundation and TOC
2. Guild context and dataset bootstrapping
3. Database/defaults and utility helpers
4. Nominations, awards, and permission-roster backend
5. Vote ledger and moderation flagging
6. Slash commands and bridge API
7. Custom Lua UI shell and reusable components
8. Tab implementations
9. Sync object transport and merge rules
10. Tooltip and announcements
11. Documentation polish and verification

## Acceptance Summary

The MVP is successful when:

- the addon loads cleanly in WoW
- the addon only operates for the player's current guild
- guild members can nominate and vote
- only GM-authorized officers can approve, reject, or direct-award
- the permission roster is guild-shared and GM-managed
- pending nominations are public
- rejected nominations are admin-only
- approved awards appear in history and tooltip data
- sync respects guild boundaries and authority validation
- the custom Lua UI is usable without React or XML dependencies

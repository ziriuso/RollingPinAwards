# Rolling Pin Awards Alias Merge Design

Date: 2026-06-02

## Goal

Add a guild-shared alias merge system so awards and nominations entered under nicknames, shortened names, or inconsistent character formatting can display and aggregate under one canonical full character name.

## Scope

This slice adds:

- a guild-shared alias mapping table in the active guild dataset
- display-level canonical resolution for nomination nominees and award recipients
- leaderboard aggregation that collapses aliases under the canonical character name
- an `Alias Merges` management section inside the `Admin` tab

This slice does not add:

- destructive rewriting of existing award or nomination records
- alias handling for `nominatedBy`, `awardedBy`, or voter identities
- automatic nickname guessing or fuzzy matching

## Data Model

Add `aliasMappingsByKey` to the guild dataset.

Each mapping row contains:

- `aliasKey`
- `aliasDisplay`
- `canonicalName`
- `createdBy`
- `createdAt`

Rules:

- `aliasKey` is a normalized key derived from the alias text entered by an admin
- `canonicalName` must be a full character name and must include `-`
- mappings apply only to:
  - nomination `nominee`
  - award `recipient`
- raw stored record fields remain unchanged
- if no mapping exists for a raw value, the UI shows the raw stored value

## Resolution Rules

All recipient and nominee display surfaces must resolve through the same shared path:

1. normalize the raw stored value into an `aliasKey`
2. look up `aliasMappingsByKey[aliasKey]`
3. if found, display `canonicalName`
4. otherwise display the raw stored value

Leaderboard aggregation uses the resolved canonical name first, not the raw stored name, so aliases visually collapse into one recipient row.

Removing a mapping immediately restores raw-name display for affected records.

## Admin UI

Add an `Alias Merges` section to the `Admin` tab.

Controls:

- `Alias` input
- `Canonical Character` input
- `Add Merge` button
- scrollable mapping list

Mapping list rows show:

- alias display text
- canonical full character name
- `Remove` button

Behavior:

- only users who can access `Admin` can use this section
- adding a mapping with an existing `aliasKey` replaces the current canonical target
- removing a mapping deletes only the alias mapping, not any award or nomination record
- the section should reuse the existing scalable scrollable-list and button patterns already used elsewhere in the addon

## Display Impact

Alias resolution changes display in these places:

- pending nominations
- moderation queue nominee display
- public award history
- leaderboard rows
- leaderboard detail popup recipient labeling

Entry forms still accept raw user input exactly as typed. Canonicalization happens only when data is displayed or grouped.

## Permissions And Sync

Alias mappings are guild-shared administrative data.

Rules:

- only GM or ranks with `Manage Addon Permissions/Settings` may add or remove mappings
- alias mapping changes sync as privileged guild configuration updates
- incoming alias mapping updates must be guild-scoped and validated through the existing privileged sync checks

## Architecture

Recommended implementation:

- extend the guild dataset shape in `Database.lua`
- add alias mapping CRUD helpers in the database layer
- add a shared alias-key normalization helper
- add a bridge-level display resolver for nominee and recipient names
- update nomination, history, moderation, and leaderboard view models to use the shared resolver
- extend the `Admin` tab with an alias-management section built from reusable controls

## Testing

Required tests:

- alias mapping resolves nominee display in pending nominations
- alias mapping resolves nominee display in the moderation queue
- alias mapping resolves recipient display in public history
- leaderboard groups multiple raw aliases under one canonical name
- removing a mapping restores raw-name display
- unauthorized users cannot add or remove mappings
- alias management list remains scrollable for many mappings
- canonical validation rejects values that do not include `-`

## Notes

- this feature is intentionally display-level and reversible
- raw records remain valuable for audit/debug and future migrations
- limiting alias resolution to nominees and recipients keeps permission and audit identities unchanged

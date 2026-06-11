# Local Reporting Filter

## Goal

Add a local user-configurable reporting filter for Dashboard award summaries and Leaderboard counts.

The filter is a personal view setting only. It does not mutate award records, migrate old awards, sync to other clients, become guild-level state, or require admin permissions.

## Data Model

The filter is stored under `profile.localSettings.reportingFilter`:

```lua
{
  mode = "all_time",
  label = "All Time",
  startsAt = nil,
  endsAt = nil,
}
```

Custom filters use `mode = "custom"` with optional epoch `startsAt` and `endsAt` values. Invalid or missing filter data falls back to `All Time`.

## Filtering Rules

- `all_time` includes every award.
- `custom` includes awards where `createdAt >= startsAt` and `createdAt <= endsAt`.
- Missing custom start or end values behave as open-ended bounds.
- Settings date fields use `YYYY-MM-DD`; start dates parse to `00:00:00`, end dates parse to `23:59:59`, making the visible date range inclusive.

## Architecture

`UI/Bridge.lua` owns the filtering logic. Dashboard and Leaderboard both use the same Bridge-filtered award list, so their totals stay consistent.

Public History remains all-time and award records are never rewritten.

## UI

Settings includes a local Reporting Filter section with:

- `All Time`
- `Custom`
- label
- start date
- end date
- save

Changing the filter rerenders the active tab locally.

## Verification

- Database tests cover defaulting, validation, and custom range persistence.
- Bridge tests cover inclusive range filtering across Dashboard and Leaderboard without mutating awards.
- Settings tests cover saving and resetting the local filter controls.
- Sync tests verify reporting filter data does not appear in outgoing snapshot traffic.

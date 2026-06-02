# Permissions

Rolling Pin Awards uses a guild-shared rank permission matrix keyed by exact guild rank index.

## Authority Model

- Any guild member can create a nomination and cast one locked advisory vote on pending nominations.
- Rank `0` / Guild Master always has full access regardless of stored matrix values.
- Every other guild rank is evaluated by its exact rank index and shown in the UI by rank name.
- The `Admin` tab is hidden unless the current player has `Manage Addon Permissions/Settings`.

## Rank Permissions

Each non-GM rank can independently receive these permissions:

- `Manage Nominations`
- `Create Direct Awards`
- `Delete Awards`
- `Manage Addon Permissions/Settings`

## Practical Rules

- `Manage Nominations` controls approve and reject actions.
- `Create Direct Awards` controls direct award creation.
- `Delete Awards` controls destructive award removal and also removes any linked nomination.
- `Manage Addon Permissions/Settings` controls editing the guild rank matrix and viewing the `Admin` tab.
- Privileged sync updates are rejected unless the sender satisfies the same rules the local UI uses.

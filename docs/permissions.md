# Permissions

Rolling Pin Awards uses a guild-shared permission roster with a strict authority chain.

## Authority Model

- Any guild member can create a nomination.
- The guild master can always approve, reject, and directly award.
- Officers are eligible for addon authority only after the guild master grants them permission through the addon roster.
- Downvote moderation data is visible only to authorized officer/admin views.

## Practical Rules

- GM grant is stored per current guild dataset.
- GM revoke is also stored per current guild dataset and exposed through the Admin tab.
- Officer rank alone is not enough for privileged addon actions.
- Privileged sync updates are rejected unless the sender satisfies the same rules the local UI uses.

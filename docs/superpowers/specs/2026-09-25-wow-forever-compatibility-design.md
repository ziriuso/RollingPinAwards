# WoW Forever Beta Compatibility

Date: 2026-09-25
Status: Initial beta implementation
Branch: `codex/wow-forever`

## Scope

Prepare Rolling Pin Awards for the installed WoW Forever beta (client 1.60.1, interface 16001) in a branch of this repository. Keep the addon folder and existing guild branding. This branch is a beta build, not a Retail release or a data migration.

## Character identity

Blizzard describes a required two-part character name whose complete combination is unique within a region ([official naming guide](https://worldofwarcraft.blizzard.com/en-us/news/24304161/crea-un-nome-solo-tuo-su-wow-forever)). For Forever, the addon must retain the complete `First Last` string supplied by WoW for player, roster, and addon-message names. It must not append a realm, remove the surname in ordinary UI, or grant trust from a first-name-only roster match. Distinct characters with the same first name must remain distinct in awards, votes, permissions, and sync.

The current beta client advertises interface 16001. Detect Forever through the 1.60.x interface range returned by `GetBuildInfo()`; keep existing Retail name behavior in the shared Lua modules so the existing tests remain meaningful. The Forever TOC advertises interface 16001 only.

Roster autocomplete must show the full two-part name so the player can distinguish shared first names. Admin character mapping requires a complete two-part canonical name. The `/rpa nominate` command accepts `First Last "Reason"` as well as its existing one-word or `Name-Realm` form.

## Verification

- Unit tests cover Forever full-name normalization and display, self identity, first-name collisions in roster trust and whispers, character mapping validation, slash parsing, and the TOC.
- Run the complete Lua suite and check the branch diff.
- Install the addon in the beta AddOns folder and verify the copied payload. Live login, guild roster, addon-message delivery, and UI behavior still require in-game testing with at least two beta clients, including two characters sharing a first name.

## Assumptions and open beta checks

- The beta APIs deliver the complete two-part name for `UnitName`, `GetGuildRosterInfo`, and addon-message sender, as suggested by current beta addon usage. Blizzard has confirmed naming rules but has not published a precise addon API contract for these return values. Verify in game before treating sync as production-ready.
- Keep the existing guild identity and artwork until a separate request defines any new branding.
- No automatic migration of Retail `Name-Realm` SavedVariables into the Forever dataset. The clients have separate data folders, and mixing identities would be unsafe.

# RollingPinAwards — Sync Hardening Plan

> **Validated against `master` @ `3eae94f`.** All five fixes below were
> re-verified against the current code — each is still live and unaddressed.
> Recent upstream merge work (`closeNominationForAward`, the
> "nomination already awarded" guard, and the `shouldApplyNomination`
> stale-replay tie-break) is *adjacent* to this plan but does not cover any of
> the five items. Note that `closeNominationForAward` (`Sync/Merge.lua`) passes
> the spoofable `actor` as `lastModifiedBy`, so it inherits Fix 1's trust
> problem and is covered once Fix 1 lands.

Five prioritized fixes to make the sync layer trustworthy and quiet. Ordered by
dependency: name normalization (Fix 2) underpins the authorization fix (Fix 1),
so land it first.

---

## Fix 2 (do first) — Normalize all names to roster format

**Problem.** `GetCurrentPlayerFullName()` and `normalizeFullName()` build names as
`Name-<GetRealmName()>`. `GetRealmName()` returns the *display* realm
("Area 52", "Mal'Ganis"), but `GetGuildRosterInfo()` and the AceComm `sender`
use the *normalized* realm ("Area52", "MalGanis"). On any realm with a space or
apostrophe the two never compare equal, so every permission lookup fails.

**Files.**
- `Bootstrap.lua:320` — `GetCurrentPlayerFullName`
- `Domain/Permissions.lua:11` — `normalizeFullName`
- New shared helper (suggest `Domain/Utils.lua`) — `NormalizeRealm(realm)` and `NormalizeUnitName(name, realm)`

**Changes.**
1. Add one canonical normalizer that strips spaces, apostrophes, and other
   punctuation from the realm portion (mirroring Blizzard's normalization:
   remove spaces/hyphens/apostrophes; do NOT lowercase — names are
   case-sensitive). Return `Name-NormalizedRealm`.
2. Route `GetCurrentPlayerFullName` and `normalizeFullName` through it. For an
   already-suffixed name, normalize only the realm half.
3. Prefer `GetNormalizedRealmName()` when available (it exists on modern
   clients and returns exactly the roster format); fall back to normalizing
   `GetRealmName()` manually for Classic.

**Edge cases.** Names with no realm suffix; cross-realm roster entries already
carrying a realm; connected-realm guildmates whose realm differs from the
viewer's; empty/nil realm.

**Tests.** Extend `tests/permissions_spec.lua` and add cases in
`tests/WoWStubs.lua` where `GetRealmName()` returns `"Area 52"` but
`GetGuildRosterInfo` returns `"Player-Area52"`; assert the actor resolves to a
rank. Add a direct unit test for the normalizer.

---

## Fix 1 — Authorize by transport sender, not payload fields

**Problem.** `Merge.lua` decides authorization from `award.lastModifiedBy or
award.awardedBy` (and equivalents for nominations/votes/rank/alias) — fields the
sender controls. The real AceComm `sender` reaches `DispatchEnvelope` but is only
a fallback (`Coordinator.lua:52`) and gets overridden. Any member can forge a
payload with `lastModifiedBy = "<GM>"` and escalate or delete anything.

**Files.**
- `Sync/Coordinator.lua:39-52` — `DispatchEnvelope`
- `Sync/Merge.lua:104, 176, 183, 205-227 (votes), 238, 266` — every `actor = payload.field` site
- `Bootstrap.lua:269` — `OnCommReceived` (distribution gate)

**Changes.**
1. In `DispatchEnvelope`, stop letting the payload override identity. Set an
   authoritative `payload._sender = sender` (normalized via Fix 2) that the
   payload cannot supply. Keep the wire `lastModifiedBy` only as *displayed*
   metadata, never as the authorization subject.
2. In each `Accept*` handler, resolve `actor` from the authoritative sender, not
   from `lastModifiedBy`. Then run the existing permission checks
   (`CanDeleteAwards`, `CanManageNominations`, etc.) against that.
3. Reject `lastModifiedBy`/`voter` values that don't match the authenticated
   sender (a sender may only write records attributed to themselves), OR — if
   relaying others' records is a real requirement — require the *sender* to hold
   the relevant permission regardless of the claimed author.
4. **Distribution gate:** in `OnCommReceived`, drop any message whose
   `distribution` is not `GUILD` (or `WHISPER` only from a confirmed
   guild-roster member). This closes the non-member whisper-injection path.
5. **Votes** (`Merge.lua:205`): require `vote.voter == sender`; a client may only
   cast its own vote.

**Edge cases.** Roster not yet loaded → `actor` rank is nil → currently
"unauthorized" (see Fix 5). Self-echo of GUILD messages (already guarded only for
hello). Legit officer relaying a snapshot of *other* people's older records —
decide policy in step 3 and document it.

**Tests.** Add adversarial cases to `tests/sync_spec.lua`: forged
`lastModifiedBy` from a low-rank sender is rejected; `WHISPER` from a non-member
is dropped; a vote with `voter != sender` is rejected; a legitimate officer's
GUILD award still applies.

---

## Fix 3 — Whisper snapshots to the requester, with debounce

**Problem.** On every `sync_hello`, *each* receiving client calls
`SendFullSnapshot("GUILD")` — broadcasting its entire database to the whole guild,
one message per record. N logins → O(N²) messages → ChatThrottleLib saturation.

Good news: `SendFullSnapshot(distribution, target)` and `Broadcast(..., target)`
already support whisper targeting — this is a small change.

**Files.**
- `Sync/Coordinator.lua:56-63` — hello handler
- New small state on `Sync` for debounce/election

**Changes.**
1. In the hello handler, call `self:SendFullSnapshot("WHISPER", sender)` instead
   of `SendFullSnapshot(distribution or "GUILD")`. The snapshot now goes only to
   the requester.
2. **Debounce:** ignore duplicate hellos from the same sender within a short
   window (e.g. 30s) via a `lastSnapshotSentTo[sender] = GetTime()` table.
3. **Responder election (optional but recommended):** to avoid all N clients
   whispering the same requester, add small randomized jitter (`C_Timer.After`
   with a per-client delay) and cancel the send if a
   `sync_snapshot_complete` for that requester is observed first. A simpler
   interim step: only the sender's guild-highest-rank online responds. Start with
   jitter; election can follow.

**Edge cases.** Requester logs out before the whisper arrives (WHISPER to an
offline player errors — wrap in pcall, already partly done). Very large snapshot
vs ChatThrottleLib — keep `priority = "BULK"` for snapshot traffic so it can't
starve live updates.

**Tests.** In `tests/sync_spec.lua`, assert a hello results in a `WHISPER`
targeted at the sender (not `GUILD`), and that a second hello within the debounce
window sends nothing.

---

## Fix 4 — Stop bumping `lastModifiedAt` on inbound votes

**Problem.** `RefreshVoteSummary` (`Domain/Nominations.lua:54`) sets
`lastModifiedAt = now` and `lastModifiedBy = localPlayer` every time it runs,
including for remote votes applied via `Merge.lua:224`. A late vote can push a
client's timestamp past a real approval's, so the approval arrives "stale" and
the nomination is stuck pending forever; it also stamps a random receiver as the
author.

**Files.**
- `Domain/Nominations.lua:32-59` — `RefreshVoteSummary`
- `Sync/Merge.lua:205-227` — vote application path

**Changes.**
1. Separate "recompute vote counts" from "record a status change." Vote-count
   recomputation must **not** touch `lastModifiedAt`/`lastModifiedBy` — those
   belong to nomination *status* transitions (pending → approved/denied) only.
2. Give `RefreshVoteSummary` a flag or split it: `RecountVotes(nomination)`
   (pure, no timestamp mutation) used by the sync path, vs. the existing
   status-changing path that legitimately stamps modification metadata.
3. Persist the updated counts without advancing the LWW clock.

**Edge cases.** Auto-resolution triggered by vote thresholds — that IS a status
change and *should* stamp `lastModifiedAt`, attributed to the resolver, not the
last vote receiver. Keep that path stamping; only the pure recount stops.

**Tests.** Add a `tests/sync_spec.lua` / `tests/nominations_spec.lua` case:
apply a remote vote, then apply an approval with an earlier timestamp; assert the
approval still wins and the nomination resolves.

---

## Fix 5 — Request the roster and register `GUILD_ROSTER_UPDATE`

**Problem.** Nothing calls `C_GuildInfo.GuildRoster()` and nothing registers
`GUILD_ROSTER_UPDATE` (`Core/Events.lua` registers only 4 events). At login —
exactly when the hello/snapshot traffic arrives — the roster cache can be empty,
so all officer records are rejected "unauthorized" with no retry, and the client
permanently misses awards.

**Files.**
- `Core/Events.lua` — event registration
- `Bootstrap.lua` (OnEnable / init) — request roster
- `Sync/Coordinator.lua` — deferral/retry of rejected records

**Changes.**
1. On enable, request the roster: `C_GuildInfo.GuildRoster()` (retail) or
   `GuildRoster()` (Classic), guarded by type checks.
2. Register `GUILD_ROSTER_UPDATE`; on fire, mark the roster "ready" and
   re-run any deferred sync application.
3. **Deferral:** when an inbound privileged record is rejected solely because the
   actor's rank is unresolved (roster not ready), queue it instead of dropping
   it, and replay the queue once `GUILD_ROSTER_UPDATE` lands. Bound the queue
   size and TTL.
4. Throttle roster requests (Blizzard rate-limits `GuildRoster()` to ~once per
   10s); don't call it on every hello.

**Edge cases.** Player not in a guild; roster never loads (solo/offline guild
list); distinguishing "unauthorized because low rank" (drop) from "unauthorized
because roster unknown" (defer) — only defer the latter.

**Tests.** Add a case where the roster is empty when a snapshot arrives, then
`GUILD_ROSTER_UPDATE` fires with the officer present; assert the deferred records
apply. Guard against replaying records that were legitimately unauthorized.

---

## Suggested landing order

1. **Fix 2** (name normalization) — prerequisite for correct sender auth.
2. **Fix 5** (roster request/registration) — so auth has data to work with.
3. **Fix 1** (authorize by sender + distribution gate) — the security core.
4. **Fix 4** (vote timestamp) — removes a divergence source before wider testing.
5. **Fix 3** (whisper snapshots + debounce) — quiets the network.

Each fix ships with the tests noted above; run the existing suite
(`tests/run.lua`) after each to catch regressions in the mocked WoW API.

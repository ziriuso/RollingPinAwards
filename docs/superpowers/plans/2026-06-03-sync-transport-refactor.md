# Sync Transport Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Rolling Pin Awards sync snapshots merge reliably between two live clients when AceComm is unavailable, then split sync code into GBankManager-style modules.

**Architecture:** Add tests that reproduce the native transport failure first, then implement native chunking/reassembly and clearer diagnostics. After the transport fix is green, split the former root `Sync.lua` responsibilities into focused files while preserving the existing public `addon.sync:*` API.

**Tech Stack:** WoW Lua, embedded AceComm/AceSerializer, native `C_ChatInfo` addon messages, local Lua test harness.

---

## File Structure

- Modify `tests/sync_spec.lua`: add RED tests for long native payload chunking, chunk reassembly, full snapshot merge, and diagnostics.
- Modify `tests/WoWStubs.lua`: add optional native message size enforcement and expose native message collections for chunk tests.
- Modify `Bootstrap.lua`: route native messages through sync transport decoding before dispatch.
- Create `Sync/Coordinator.lua`: keep a compatibility facade and shared constructor.
- Create `Sync/Codec.lua`: native envelope encode/decode helpers.
- Create `Sync/Transport.lua`: Ace/native send, chunking, reassembly, and transport diagnostics.
- Create `Sync/Snapshot.lua`: hello and deterministic full snapshot streaming.
- Create `Sync/Merge.lua`: existing accept/authorization/stale-guard helpers.
- Create `Sync/Diagnostics.lua`: `/rpa syncdebug` line construction.
- Modify `RollingPinAwards.toc`: load the new `Sync/` modules before the facade.
- Modify `docs/sync.md`: document chunked native fallback and diagnostics.

## Task 1: Add Native Transport RED Tests

**Files:**
- Modify: `tests/WoWStubs.lua`
- Modify: `tests/sync_spec.lua`

- [ ] **Step 1: Add native size enforcement to the WoW stub**

In `tests/WoWStubs.lua`, extend the native `SendAddonMessage` stub so tests can simulate the live 255 byte native limit:

```lua
local function storeNativeComm(prefix, message, distribution, target)
  state.nativeCommMessages = state.nativeCommMessages or {}
  local limit = tonumber(state.nativeCommMaxBytes or 0) or 0
  if limit > 0 and type(message) == "string" and #message > limit then
    state.nativeCommRejectedMessages = state.nativeCommRejectedMessages or {}
    state.nativeCommRejectedMessages[#state.nativeCommRejectedMessages + 1] = {
      prefix = prefix,
      message = message,
      distribution = distribution,
      target = target,
      length = #message,
    }
    return false
  end

  local row = {
    prefix = prefix,
    message = message,
    distribution = distribution,
    target = target,
  }
  state.nativeCommMessages[#state.nativeCommMessages + 1] = row
  state.lastNativeCommMessage = row
  return true
end
```

Wire both `C_ChatInfo.SendAddonMessage` and legacy `SendAddonMessage` to `storeNativeComm`.

- [ ] **Step 2: Write failing test for long native nomination chunking**

Add this test to `tests/sync_spec.lua`:

```lua
["native fallback chunks long nomination envelopes under the addon-message limit"] = function()
  local addon = setupNativeGuild({
    nativeCommMaxBytes = 255,
  })
  local guildKey = addon:GetActiveGuildContext().guildKey
  _G.__RPA_TEST_STATE.nativeCommMessages = {}

  local longReason = string.rep("Helpful bakery logistics. ", 18)
  local ok = addon.sync:Broadcast("nomination", {
    nominationId = "nom:Guildmaster-Stormrage:1717336800:99",
    guildKey = guildKey,
    nominee = "Moonrustle-Stormrage",
    reason = longReason,
    awardType = "burnt",
    status = "pending",
    nominatedBy = "Guildmaster-Stormrage",
    createdAt = 1717336800,
    lastModifiedAt = 1717336800,
    lastModifiedBy = "Guildmaster-Stormrage",
  }, "GUILD")

  harness.assert_true(ok)
  harness.assert_true(#_G.__RPA_TEST_STATE.nativeCommMessages > 1)
  for _, sent in ipairs(_G.__RPA_TEST_STATE.nativeCommMessages) do
    harness.assert_true(#sent.message <= 255)
  end
end
```

- [ ] **Step 3: Run RED test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 "native fallback chunks long nomination"
```

Expected: FAIL because current native fallback tries to send one oversize message and returns `native send failed`.

## Task 2: Implement Native Chunking And Reassembly

**Files:**
- Modify: `Sync.lua`
- Modify: `Core.lua`

- [ ] **Step 1: Add native chunk constants and helpers**

In `Sync.lua`, add constants near the top:

```lua
local NATIVE_MESSAGE_LIMIT = 255
local NATIVE_CHUNK_BODY_LIMIT = 180
local NATIVE_CHUNK_PREFIX = "RPA2C"
```

Add helper methods:

```lua
function Sync:EncodeNativeMessages(serialized)
  if type(serialized) ~= "string" then
    return nil, "missing serialized message"
  end

  if #serialized <= NATIVE_MESSAGE_LIMIT then
    return { serialized }
  end

  self.nativeMessageSequence = (tonumber(self.nativeMessageSequence or 0) or 0) + 1
  local messageId = tostring(self.nativeMessageSequence)
  local total = math.ceil(#serialized / NATIVE_CHUNK_BODY_LIMIT)
  local chunks = {}

  for index = 1, total do
    local startIndex = ((index - 1) * NATIVE_CHUNK_BODY_LIMIT) + 1
    local body = serialized:sub(startIndex, startIndex + NATIVE_CHUNK_BODY_LIMIT - 1)
    chunks[#chunks + 1] = ("%s|%s|%d|%d|%s"):format(
      NATIVE_CHUNK_PREFIX,
      messageId,
      index,
      total,
      body
    )
  end

  return chunks
end

function Sync:DecodeNativeMessage(message, distribution, sender)
  if type(message) ~= "string" then
    return nil, "missing message"
  end

  local marker, messageId, indexText, totalText, body =
    message:match("^(RPA2C)|([^|]+)|(%d+)|(%d+)|(.*)$")

  if marker ~= NATIVE_CHUNK_PREFIX then
    return self:DeserializeEnvelope(message)
  end

  local index = tonumber(indexText)
  local total = tonumber(totalText)
  if not index or not total or index < 1 or total < 1 or index > total then
    self.lastNativeChunk = { ok = false, error = "invalid chunk", sender = sender }
    return nil, "invalid chunk"
  end

  self.nativeChunkBuffers = self.nativeChunkBuffers or {}
  local key = table.concat({ tostring(distribution or ""), tostring(sender or ""), tostring(messageId) }, "|")
  local buffer = self.nativeChunkBuffers[key] or { total = total, parts = {} }
  buffer.total = total
  buffer.parts[index] = body or ""
  self.nativeChunkBuffers[key] = buffer

  for partIndex = 1, total do
    if buffer.parts[partIndex] == nil then
      self.lastNativeChunk = { ok = true, state = "partial", sender = sender, messageId = messageId }
      return nil, "partial"
    end
  end

  local parts = {}
  for partIndex = 1, total do
    parts[#parts + 1] = buffer.parts[partIndex]
  end
  self.nativeChunkBuffers[key] = nil
  self.lastNativeChunk = { ok = true, state = "complete", sender = sender, messageId = messageId }

  return self:DeserializeEnvelope(table.concat(parts))
end
```

- [ ] **Step 2: Send all chunks in native Broadcast**

Replace the native single-send block in `Sync:Broadcast` with code that serializes once, calls `EncodeNativeMessages`, sends every chunk, and records `chunkCount` in `self.lastBroadcast`.

- [ ] **Step 3: Decode native chunks in Core**

In `Core.lua`, change the native branch of `RPA:OnCommReceived` to call:

```lua
local decoded, decodeErr = self.sync:DecodeNativeMessage(message, distribution, sender)
if decodeErr == "partial" then
  return true
end
if not decoded then
  self.sync:RecordInbound({
    sender = sender,
    distribution = distribution,
    ok = false,
    error = decodeErr or "deserialize failed",
  })
  return false
end
envelope = decoded
```

- [ ] **Step 4: Run GREEN test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 "native fallback chunks long nomination"
```

Expected: PASS.

## Task 3: Add Snapshot Replay RED/GREEN Coverage

**Files:**
- Modify: `tests/sync_spec.lua`
- Modify: `Sync.lua`

- [ ] **Step 1: Write failing full snapshot replay test**

Add a test that creates a populated sender addon, captures native snapshot messages from `/rpa sync now`, resets into an empty receiving addon with the same guild, feeds each captured message through `receiver:OnCommReceived(...)`, and asserts:

```lua
harness.assert_equal(1, #receiver.db:GetAliasMappings(guildKey))
harness.assert_true(receiver.db:GetNomination(guildKey, "nom:5") ~= nil)
harness.assert_true(receiver.db:GetVote(guildKey, "nom:5", "Bakerone-Stormrage") ~= nil)
harness.assert_true(receiver.db:GetAward(guildKey, "award:8") ~= nil)
harness.assert_true(receiver.permissions:GetRankPermissionRow(1) ~= nil)
```

Expected RED result before Task 2 is applied: the long nomination does not arrive intact or the replay does not merge all record types.

- [ ] **Step 2: Extend receive summary tracking**

In `Sync:DispatchEnvelope`, after each merge attempt, update:

```lua
self.receiveSummary = self.receiveSummary or {}
local row = self.receiveSummary[envelope.payloadType] or { accepted = 0, rejected = 0 }
if ok then
  row.accepted = row.accepted + 1
else
  row.rejected = row.rejected + 1
  row.lastError = err
end
self.receiveSummary[envelope.payloadType] = row
```

- [ ] **Step 3: Run snapshot replay test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 "snapshot replay"
```

Expected: PASS after chunking and summary updates.

## Task 4: Refactor Sync Into Modules

**Files:**
- Create: `Sync/Codec.lua`
- Create: `Sync/Transport.lua`
- Create: `Sync/Snapshot.lua`
- Create: `Sync/Merge.lua`
- Create: `Sync/Diagnostics.lua`
- Modify: `Sync.lua`
- Modify: `RollingPinAwards.toc`

- [ ] **Step 1: Create module files by moving existing behavior without changing public API**

Move native serializer functions to `Sync/Codec.lua`, transport functions to `Sync/Transport.lua`, snapshot functions to `Sync/Snapshot.lua`, accept helpers to `Sync/Merge.lua`, and debug-line construction to `Sync/Diagnostics.lua`.

- [ ] **Step 2: Keep facade compatibility**

Keep `Sync.lua` returning `RPA.Sync` and ensure `Sync:New(addon)` still returns an object supporting:

```lua
Broadcast
SendHello
SendFullSnapshot
DispatchEnvelope
AcceptAward
AcceptNomination
AcceptNominationVote
AcceptRankPermission
AcceptAliasMapping
GetDebugLines
SerializeEnvelope
DeserializeEnvelope
DecodeNativeMessage
```

- [ ] **Step 3: Update TOC order**

In `RollingPinAwards.toc`, replace the single sync load with:

```text
Sync/Codec.lua
Sync/Transport.lua
Sync/Snapshot.lua
Sync/Merge.lua
Sync/Diagnostics.lua
Sync.lua
```

- [ ] **Step 4: Run all sync tests**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 sync
```

Expected: all filtered sync tests pass.

## Task 5: Diagnostics And Documentation

**Files:**
- Modify: `Sync/Diagnostics.lua`
- Modify: `Core.lua`
- Modify: `docs/sync.md`

- [ ] **Step 1: Add Ace lookup diagnostics**

Expose diagnostic booleans:

```lua
addon.__rpaLibStubPresent = type(rawget(_G, "LibStub")) == "function"
addon.__rpaChatThrottleLibPresent = type(rawget(_G, "ChatThrottleLib")) == "table"
```

Record individual Ace library lookup results for AceComm, AceSerializer, AceConsole, and AceEvent.

- [ ] **Step 2: Add debug output lines**

Extend `/rpa syncdebug` lines with:

```text
LibStub: true ChatThrottleLib: true
Native chunk: state=complete sender=Name-Realm messageId=3 error=none
Receive summary: nomination accepted=7 rejected=0 lastError=none
```

- [ ] **Step 3: Update docs**

Update `docs/sync.md` to describe chunked native fallback, receive summaries, and the live validation order using fresh post-fix records.

- [ ] **Step 4: Run full suite**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1
```

Expected: all tests pass with zero failures.

## Task 6: Deploy And Live Retest

**Files:**
- Modify only deployment target files under `C:\Gaming\World of Warcraft\_retail_\Interface\AddOns\RollingPinAwards`

- [ ] **Step 1: Copy addon to Retail**

Copy the updated addon files to:

```text
C:\Gaming\World of Warcraft\_retail_\Interface\AddOns\RollingPinAwards
```

- [ ] **Step 2: Validate in two clients**

Run this exact live order:

```text
/reload on both clients
/rpa syncdebug on both clients
/rpa sync now on the data-rich client
/rpa syncdebug on both clients
```

Expected: receiving client shows receive summary counts for nominations and awards with accepted counts greater than zero.

- [ ] **Step 3: Create fresh post-fix records**

Create a new nomination, cast one vote, approve it, and create one direct award. Confirm the second client shows both nomination/history records.

---

## Self-Review

- Spec coverage: transport chunking, Ace diagnostics, snapshot replay, module split, docs, and live validation are covered by Tasks 1-6.
- Runtime prerequisite: `tests/run.ps1` resolves Lua from `RPA_LUA`, `tools/lua/lua.exe`, or PATH; this workspace currently has no discoverable Lua runtime.
- Placeholder scan: this plan contains no `TBD`, `TODO`, angle-bracket placeholders, or unspecified test commands.
- Type consistency: public sync method names match current `Sync.lua` callers and the proposed facade list.

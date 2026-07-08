local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Sync = RPA.Sync or {}
RPA.Sync = Sync
local Utils = RPA.Utils or {}

local SNAPSHOT_ACK_WAIT_SECONDS = 2
local SNAPSHOT_REQUEST_COOLDOWN_SECONDS = 120

local function isMissingString(value)
  return type(value) ~= "string" or value == ""
end

local function hasExplicitRealm(value)
  return type(value) == "string" and value:match("^[^-]+%-.+$") ~= nil
end

local function numericValue(value)
  return tonumber(value) or 0
end

local function countRecords(records)
  local count = 0

  for _ in pairs(records or {}) do
    count = count + 1
  end

  return count
end

local function latestFlatRecordTimestamp(records)
  local latest = 0

  for _, record in pairs(records or {}) do
    if type(record) == "table" then
      latest = math.max(
        latest,
        numericValue(record.lastModifiedAt),
        numericValue(record.createdAt),
        numericValue(record.awardedAt),
        numericValue(record.resolvedAt)
      )
    end
  end

  return latest
end

function Sync:New(addon)
  local obj = {
    addon = addon,
    deferredInbound = {},
    lastSnapshotSentTo = {},
    lastSnapshotRequestedForGuild = {},
    snapshotAckCandidatesByGuild = {},
    snapshotAckSelectionScheduled = {},
  }

  self.__index = self

  return setmetatable(obj, self)
end

local function currentTime()
  if type(GetTime) == "function" then
    return GetTime()
  end

  return 0
end

function Sync:NormalizeSender(sender)
  if Utils and type(Utils.NormalizeUnitName) == "function" then
    return Utils.NormalizeUnitName(sender)
  end

  return sender
end

function Sync:ResolveOnlineGuildTarget(sender)
  local normalizedSender = self:NormalizeSender(sender)
  if isMissingString(normalizedSender) then
    return nil, "missing sender"
  end

  local target = normalizedSender
  if self.addon and type(self.addon.GetGuildRosterMemberStatus) == "function" then
    local found, online, rosterName, matchKind = self.addon:GetGuildRosterMemberStatus(normalizedSender)
    if not found then
      return nil, "sender not in roster"
    end
    if not online then
      return nil, "sender offline"
    end
    if rosterName and not (hasExplicitRealm(sender) and matchKind == "short") then
      target = rosterName
    end
  end

  return target, nil
end

function Sync:IsActorRankUnresolved(actor)
  return self.addon
    and self.addon.permissions
    and type(self.addon.permissions.IsRankUnresolved) == "function"
    and self.addon.permissions:IsRankUnresolved(actor) == true
end

function Sync:DeferInbound(envelope, distribution, sender)
  self.deferredInbound = self.deferredInbound or {}
  if #self.deferredInbound >= 50 then
    table.remove(self.deferredInbound, 1)
  end

  self.deferredInbound[#self.deferredInbound + 1] = {
    envelope = envelope,
    distribution = distribution,
    sender = sender,
    queuedAt = currentTime(),
  }
end

function Sync:ReplayDeferredInbound()
  local pending = self.deferredInbound or {}
  self.deferredInbound = {}
  local now = currentTime()

  for _, row in ipairs(pending) do
    if now - (row.queuedAt or now) <= 120 then
      self:DispatchEnvelope(row.envelope, row.distribution, row.sender, true)
    end
  end
end

function Sync:BuildSnapshotSummary()
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return 0, 0
  end

  local dataset = self.addon.db:GetGuildDataset(guild.guildKey)
  local totalRecords = countRecords(dataset.rankPermissions)
    + countRecords(dataset.aliasMappingsByKey)
    + countRecords(dataset.awardsById)
    + countRecords(dataset.nominationsById)
  local latest = math.max(
    latestFlatRecordTimestamp(dataset.rankPermissions),
    latestFlatRecordTimestamp(dataset.aliasMappingsByKey),
    latestFlatRecordTimestamp(dataset.awardsById),
    latestFlatRecordTimestamp(dataset.nominationsById)
  )

  for _, votesByVoter in pairs(dataset.votesByNomination or {}) do
    totalRecords = totalRecords + countRecords(votesByVoter)
    latest = math.max(latest, latestFlatRecordTimestamp(votesByVoter))
  end

  return totalRecords, latest
end

function Sync:SendSnapshotToHelloSender(sender)
  local snapshotTarget, targetErr = self:ResolveOnlineGuildTarget(sender)
  if not snapshotTarget then
    return false, targetErr
  end

  local now = currentTime()
  local previous = self.lastSnapshotSentTo and self.lastSnapshotSentTo[snapshotTarget]
  if previous and now - previous < 30 then
    return false, "snapshot recently sent"
  end

  self.lastSnapshotSentTo = self.lastSnapshotSentTo or {}
  self.lastSnapshotSentTo[snapshotTarget] = now

  return self:SendFullSnapshot("WHISPER", snapshotTarget)
end

function Sync:SendHelloAck(sender)
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return false, "missing guild"
  end

  local target, targetErr = self:ResolveOnlineGuildTarget(sender)
  if not target then
    return false, targetErr
  end

  local totalRecords, latestModifiedAt = self:BuildSnapshotSummary()

  return self:Broadcast("sync_hello_ack", {
    guildKey = guild.guildKey,
    sender = self.addon:GetCurrentPlayerFullName(),
    totalRecords = totalRecords,
    latestModifiedAt = latestModifiedAt,
    sentAt = self.addon.Time and type(self.addon.Time.Now) == "function" and self.addon.Time:Now() or 0,
  }, "WHISPER", target, "NORMAL")
end

function Sync:IsBetterSnapshotCandidate(candidate, existing)
  if not existing then
    return true
  end

  if candidate.totalRecords ~= existing.totalRecords then
    return candidate.totalRecords > existing.totalRecords
  end

  if candidate.latestModifiedAt ~= existing.latestModifiedAt then
    return candidate.latestModifiedAt > existing.latestModifiedAt
  end

  return candidate.receivedAt < existing.receivedAt
end

function Sync:RememberSnapshotAckCandidate(guildKey, sender, payload)
  local target, targetErr = self:ResolveOnlineGuildTarget(sender)
  if not target then
    return false, targetErr
  end

  self.snapshotAckCandidatesByGuild = self.snapshotAckCandidatesByGuild or {}
  local candidate = {
    sender = sender,
    target = target,
    totalRecords = numericValue(payload.totalRecords),
    latestModifiedAt = numericValue(payload.latestModifiedAt),
    receivedAt = currentTime(),
  }
  local existing = self.snapshotAckCandidatesByGuild[guildKey]
  if self:IsBetterSnapshotCandidate(candidate, existing) then
    self.snapshotAckCandidatesByGuild[guildKey] = candidate
  end

  return true
end

function Sync:RequestBestSnapshotCandidate(guildKey)
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return false, "missing guild"
  end
  if guild.guildKey ~= guildKey then
    return false, "wrong guild"
  end

  local candidate = self.snapshotAckCandidatesByGuild and self.snapshotAckCandidatesByGuild[guildKey]
  if not candidate then
    return false, "missing snapshot candidate"
  end

  local now = currentTime()
  local previous = self.lastSnapshotRequestedForGuild and self.lastSnapshotRequestedForGuild[guild.guildKey]
  if previous and now - previous < SNAPSHOT_REQUEST_COOLDOWN_SECONDS then
    return true, nil
  end

  self.lastSnapshotRequestedForGuild = self.lastSnapshotRequestedForGuild or {}
  self.lastSnapshotRequestedForGuild[guild.guildKey] = now
  self.snapshotAckCandidatesByGuild[guild.guildKey] = nil

  local ok, err = self:Broadcast("sync_snapshot_request", {
    guildKey = guild.guildKey,
    sender = self.addon:GetCurrentPlayerFullName(),
    sentAt = self.addon.Time and type(self.addon.Time.Now) == "function" and self.addon.Time:Now() or 0,
  }, "WHISPER", candidate.target, "NORMAL")
  if not ok then
    self.lastSnapshotRequestedForGuild[guild.guildKey] = nil
  end

  return ok, err
end

function Sync:ScheduleSnapshotCandidateSelection(guildKey)
  self.snapshotAckSelectionScheduled = self.snapshotAckSelectionScheduled or {}
  if self.snapshotAckSelectionScheduled[guildKey] then
    return true
  end

  self.snapshotAckSelectionScheduled[guildKey] = true
  local function requestBestCandidate()
    self.snapshotAckSelectionScheduled[guildKey] = nil
    self:RequestBestSnapshotCandidate(guildKey)
  end

  if _G.C_Timer and type(_G.C_Timer.After) == "function" then
    _G.C_Timer.After(SNAPSHOT_ACK_WAIT_SECONDS, requestBestCandidate)
  else
    requestBestCandidate()
  end

  return true
end

function Sync:RequestSnapshotFromAckSender(sender, payload)
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return false, "missing guild"
  end

  local previous = self.lastSnapshotRequestedForGuild and self.lastSnapshotRequestedForGuild[guild.guildKey]
  local now = currentTime()
  if previous and now - previous < SNAPSHOT_REQUEST_COOLDOWN_SECONDS then
    return true, nil
  end

  local remembered, rememberErr = self:RememberSnapshotAckCandidate(guild.guildKey, sender, payload or {})
  if not remembered then
    return false, rememberErr
  end

  return self:ScheduleSnapshotCandidateSelection(guild.guildKey)
end

function Sync:IsActiveGuildPayload(guildKey)
  local guild = self.addon:GetActiveGuildContext()

  return guild ~= nil and guild.guildKey == guildKey
end

function Sync:BuildEnvelope(payloadType, payload)
  if isMissingString(payloadType) or type(payload) ~= "table" then
    return nil, "missing payload"
  end

  return {
    protocolVersion = self.addon.Constants.PROTOCOL_VERSION,
    payloadType = payloadType,
    payload = payload,
  }, nil
end

function Sync:DispatchEnvelope(envelope, distribution, sender, replayingDeferred)
  if type(envelope) ~= "table" or isMissingString(envelope.payloadType) then
    self:RecordInbound({
      sender = sender,
      distribution = distribution,
      ok = false,
      error = "missing envelope",
    })

    return false, "missing envelope"
  end

  local payload = type(envelope.payload) == "table" and envelope.payload or {}
  local normalizedSender = self:NormalizeSender(sender)
  payload._sender = normalizedSender
  payload._distribution = distribution
  payload.sender = normalizedSender
  local ok, err

  if envelope.payloadType == "sync_hello" then
    if not self:IsActiveGuildPayload(payload.guildKey) then
      ok, err = false, "wrong guild"
    elseif self:NormalizeSender(payload.sender) == self.addon:GetCurrentPlayerFullName()
      or normalizedSender == self.addon:GetCurrentPlayerFullName()
    then
      ok, err = false, "self origin"
    elseif payload.requestSnapshot == true then
      ok, err = self:SendSnapshotToHelloSender(sender or normalizedSender)
    else
      ok, err = self:SendHelloAck(sender or normalizedSender)
    end
  elseif envelope.payloadType == "sync_hello_ack" then
    if not self:IsActiveGuildPayload(payload.guildKey) then
      ok, err = false, "wrong guild"
    elseif self:NormalizeSender(payload.sender) == self.addon:GetCurrentPlayerFullName()
      or normalizedSender == self.addon:GetCurrentPlayerFullName()
    then
      ok, err = false, "self origin"
    else
      ok, err = self:RequestSnapshotFromAckSender(sender or normalizedSender, payload)
    end
  elseif envelope.payloadType == "sync_snapshot_request" then
    if not self:IsActiveGuildPayload(payload.guildKey) then
      ok, err = false, "wrong guild"
    elseif self:NormalizeSender(payload.sender) == self.addon:GetCurrentPlayerFullName()
      or normalizedSender == self.addon:GetCurrentPlayerFullName()
    then
      ok, err = false, "self origin"
    else
      ok, err = self:SendSnapshotToHelloSender(sender or normalizedSender)
    end
  elseif envelope.payloadType == "sync_snapshot_complete" then
    ok, err = self:IsActiveGuildPayload(payload.guildKey), nil
    if not ok then
      err = "wrong guild"
    end
  elseif envelope.payloadType == "award" then
    ok, err = self:AcceptAward(payload)
  elseif envelope.payloadType == "nomination" then
    ok, err = self:AcceptNomination(payload)
  elseif envelope.payloadType == "vote" then
    ok, err = self:AcceptNominationVote(payload)
  elseif envelope.payloadType == "rank_permissions" or envelope.payloadType == "permission_roster" then
    ok, err = self:AcceptRankPermission(payload)
  elseif envelope.payloadType == "alias_mapping" then
    ok, err = self:AcceptAliasMapping(payload)
  else
    ok, err = false, "unknown payloadType"
  end

  if ok ~= true and err == "roster pending" and not replayingDeferred then
    self:DeferInbound(envelope, distribution, sender)
  end

  self:RecordInbound({
    payloadType = envelope.payloadType,
    guildKey = payload.guildKey,
    sender = normalizedSender,
    distribution = distribution,
    ok = ok == true,
    error = err,
  })

  self.receiveSummary = self.receiveSummary or {}
  local summary = self.receiveSummary[envelope.payloadType] or {
    accepted = 0,
    rejected = 0,
  }
  if ok then
    summary.accepted = summary.accepted + 1
  else
    summary.rejected = summary.rejected + 1
    summary.lastError = err
  end
  self.receiveSummary[envelope.payloadType] = summary

  if ok and self.addon.mainFrame and self.addon.mainFrame.rendered then
    self.addon.mainFrame:RenderActiveTab()
  end

  if ok and self.addon.notifications and type(self.addon.notifications.HandleAcceptedInbound) == "function" then
    self.addon.notifications:HandleAcceptedInbound(envelope.payloadType, payload, sender)
  end

  return ok, err
end

return RPA.Sync

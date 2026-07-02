local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Sync = RPA.Sync or {}
RPA.Sync = Sync
local Utils = RPA.Utils or {}

local function isMissingString(value)
  return type(value) ~= "string" or value == ""
end

function Sync:New(addon)
  local obj = {
    addon = addon,
    deferredInbound = {},
    lastSnapshotSentTo = {},
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

function Sync:SendSnapshotToHelloSender(sender)
  local normalizedSender = self:NormalizeSender(sender)
  if isMissingString(normalizedSender) then
    return false, "missing sender"
  end

  local now = currentTime()
  local previous = self.lastSnapshotSentTo and self.lastSnapshotSentTo[normalizedSender]
  if previous and now - previous < 30 then
    return false, "snapshot recently sent"
  end

  self.lastSnapshotSentTo = self.lastSnapshotSentTo or {}
  self.lastSnapshotSentTo[normalizedSender] = now

  return self:SendFullSnapshot("WHISPER", normalizedSender)
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
    else
      ok, err = self:SendSnapshotToHelloSender(normalizedSender)
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

local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Sync = RPA.Sync or {}
RPA.Sync = Sync

local function isMissingString(value)
  return type(value) ~= "string" or value == ""
end

function Sync:New(addon)
  local obj = {
    addon = addon,
  }

  self.__index = self

  return setmetatable(obj, self)
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

function Sync:DispatchEnvelope(envelope, distribution, sender)
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
  payload.sender = payload.sender or sender
  payload.distribution = payload.distribution or distribution
  local ok, err

  if envelope.payloadType == "sync_hello" then
    if not self:IsActiveGuildPayload(payload.guildKey) then
      ok, err = false, "wrong guild"
    elseif payload.sender == self.addon:GetCurrentPlayerFullName() or sender == self.addon:GetCurrentPlayerFullName() then
      ok, err = false, "self origin"
    else
      ok, err = self:SendFullSnapshot(distribution or "GUILD")
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

  self:RecordInbound({
    payloadType = envelope.payloadType,
    guildKey = payload.guildKey,
    sender = sender,
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

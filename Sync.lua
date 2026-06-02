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

function Sync:Broadcast(payloadType, payload, distribution, target, priority)
  if type(self.addon.SendCommMessage) ~= "function" or type(self.addon.Serialize) ~= "function" then
    return false, "comm unavailable"
  end

  local envelope, err = self:BuildEnvelope(payloadType, payload)
  if not envelope then
    return false, err
  end

  local serialized = self.addon:Serialize(envelope)
  self.addon:SendCommMessage(
    self.addon.Constants.COMM_PREFIX,
    serialized,
    distribution or "GUILD",
    target,
    priority or "NORMAL"
  )

  return true
end

function Sync:DispatchEnvelope(envelope, distribution, sender)
  if type(envelope) ~= "table" or isMissingString(envelope.payloadType) then
    return false, "missing envelope"
  end

  local payload = type(envelope.payload) == "table" and envelope.payload or {}
  payload.sender = payload.sender or sender
  payload.distribution = payload.distribution or distribution

  if envelope.payloadType == "award" then
    return self:AcceptAward(payload)
  end

  if envelope.payloadType == "nomination" then
    return self:AcceptNomination(payload)
  end

  if envelope.payloadType == "vote" then
    return self:AcceptNominationVote(payload)
  end

  if envelope.payloadType == "rank_permissions" or envelope.payloadType == "permission_roster" then
    return self:AcceptRankPermission(payload)
  end

  if envelope.payloadType == "alias_mapping" then
    return self:AcceptAliasMapping(payload)
  end

  return false, "unknown payloadType"
end

function Sync:AcceptAward(award)
  if type(award) ~= "table" or isMissingString(award.awardId) then
    return false, "missing award"
  end

  if not self:IsActiveGuildPayload(award.guildKey) then
    return false, "wrong guild"
  end

  local actor = award.lastModifiedBy or award.awardedBy
  local isAuthorized = false

  if self.addon.permissions then
    if award.source == "nomination" then
      isAuthorized = self.addon.permissions:CanManageNominations(actor)
    elseif award.source == "direct" then
      isAuthorized = self.addon.permissions:CanCreateDirectAwards(actor)
    else
      isAuthorized = self.addon.permissions:CanManageAwards(actor)
    end
  end

  if not isAuthorized then
    return false, "unauthorized"
  end

  self.addon.db:UpsertAward(award.guildKey, award)

  return true
end

function Sync:AcceptNomination(nomination)
  if type(nomination) ~= "table" or isMissingString(nomination.nominationId) then
    return false, "missing nomination"
  end

  if not self:IsActiveGuildPayload(nomination.guildKey) then
    return false, "wrong guild"
  end

  if nomination.status ~= "pending" then
    local actor = nomination.lastModifiedBy or nomination.resolvedBy
    if not self.addon.permissions or not self.addon.permissions:CanManageNominations(actor) then
      return false, "unauthorized"
    end
  end

  self.addon.db:UpsertNomination(nomination.guildKey, nomination)

  return true
end

function Sync:AcceptNominationVote(vote)
  if type(vote) ~= "table" or isMissingString(vote.nominationId) then
    return false, "missing vote"
  end

  if not self:IsActiveGuildPayload(vote.guildKey) then
    return false, "wrong guild"
  end

  local nomination = self.addon.db:GetNomination(vote.guildKey, vote.nominationId)
  if not nomination or nomination.status ~= "pending" then
    return false, "nomination closed"
  end

  if self.addon.db:GetVote(vote.guildKey, vote.nominationId, vote.voter) then
    return false, "duplicate vote"
  end

  self.addon.db:StoreVote(vote.guildKey, vote.nominationId, vote)
  self.addon.nominations:RefreshVoteSummary(nomination)

  return true
end

function Sync:AcceptRankPermission(update)
  if type(update) ~= "table" or type(update.rankIndex) ~= "number" then
    return false, "missing rank permission update"
  end

  if not self:IsActiveGuildPayload(update.guildKey) then
    return false, "wrong guild"
  end

  local actor = update.lastModifiedBy or update.sender
  if not self.addon.permissions or not self.addon.permissions:CanManageAddonPermissions(actor) then
    return false, "unauthorized"
  end

  self.addon.db:UpsertRankPermission(update.guildKey, update.rankIndex, {
    rankIndex = update.rankIndex,
    rankName = update.rankName,
    canManageNominations = update.canManageNominations == true,
    canCreateDirectAwards = update.canCreateDirectAwards == true,
    canDeleteAwards = update.canDeleteAwards == true,
    canManageAddonPermissions = update.canManageAddonPermissions == true,
    lastModifiedAt = update.lastModifiedAt,
    lastModifiedBy = actor,
  })

  return true
end

function Sync:AcceptAliasMapping(update)
  if type(update) ~= "table" or isMissingString(update.aliasKey) then
    return false, "missing alias mapping update"
  end

  if not self:IsActiveGuildPayload(update.guildKey) then
    return false, "wrong guild"
  end

  local actor = update.lastModifiedBy or update.sender
  if not self.addon.permissions or not self.addon.permissions:CanManageAddonPermissions(actor) then
    return false, "unauthorized"
  end

  if update.deleted == true then
    return self.addon.db:DeleteAliasMapping(update.guildKey, update.aliasKey)
  end

  self.addon.db:UpsertAliasMapping(update.guildKey, {
    aliasKey = update.aliasKey,
    aliasDisplay = update.aliasDisplay,
    canonicalName = update.canonicalName,
    createdBy = update.createdBy or actor,
    createdAt = update.createdAt,
    lastModifiedBy = actor,
    lastModifiedAt = update.lastModifiedAt,
  })

  return true
end

return RPA.Sync

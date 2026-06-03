local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Sync = RPA.Sync or {}
RPA.Sync = Sync

local function isMissingString(value)
  return type(value) ~= "string" or value == ""
end

local function escapeValue(value)
  value = tostring(value or "")
  value = value:gsub("%%", "%%25")
  value = value:gsub("|", "%%7C")
  value = value:gsub("&", "%%26")
  value = value:gsub("=", "%%3D")
  value = value:gsub("\n", "%%0A")

  return value
end

local function unescapeValue(value)
  value = tostring(value or "")
  value = value:gsub("%%0A", "\n")
  value = value:gsub("%%3D", "=")
  value = value:gsub("%%26", "&")
  value = value:gsub("%%7C", "|")
  value = value:gsub("%%25", "%%")

  return value
end

local function encodeField(value)
  if type(value) == "boolean" then
    return value and "b:1" or "b:0"
  end

  if type(value) == "number" then
    return "n:" .. tostring(value)
  end

  return "s:" .. escapeValue(value)
end

local function decodeField(value)
  local tag = value:sub(1, 2)
  local body = value:sub(3)

  if tag == "b:" then
    return body == "1"
  end

  if tag == "n:" then
    return tonumber(body)
  end

  if tag == "s:" then
    return unescapeValue(body)
  end

  return unescapeValue(value)
end

local function sendNativeAddonMessage(prefix, message, distribution, target)
  if _G.C_ChatInfo and type(_G.C_ChatInfo.SendAddonMessage) == "function" then
    return _G.C_ChatInfo.SendAddonMessage(prefix, message, distribution, target)
  end

  if type(_G.SendAddonMessage) == "function" then
    return _G.SendAddonMessage(prefix, message, distribution, target)
  end

  return false
end

function Sync:New(addon)
  local obj = {
    addon = addon,
  }

  self.__index = self

  return setmetatable(obj, self)
end

function Sync:SerializeEnvelope(envelope)
  if type(envelope) ~= "table" or isMissingString(envelope.payloadType) then
    return nil, "missing envelope"
  end

  local fields = {}
  for key, value in pairs(envelope.payload or {}) do
    local valueType = type(value)
    if valueType == "string" or valueType == "number" or valueType == "boolean" then
      fields[#fields + 1] = ("%s=%s"):format(escapeValue(key), encodeField(value))
    end
  end

  table.sort(fields)

  return ("RPA1|%s|%s"):format(escapeValue(envelope.payloadType), table.concat(fields, "&"))
end

function Sync:DeserializeEnvelope(message)
  if type(message) ~= "string" then
    return nil, "missing message"
  end

  local version, payloadType, fieldText = message:match("^(RPA1)|([^|]*)|(.*)$")
  if version ~= "RPA1" or isMissingString(payloadType) then
    return nil, "invalid envelope"
  end

  local payload = {}
  for pair in (fieldText or ""):gmatch("[^&]+") do
    local key, value = pair:match("^([^=]*)=(.*)$")
    if key and value then
      payload[unescapeValue(key)] = decodeField(value)
    end
  end

  return {
    protocolVersion = self.addon.Constants.PROTOCOL_VERSION,
    payloadType = unescapeValue(payloadType),
    payload = payload,
  }
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

function Sync:RecordInbound(result)
  self.lastInbound = result or {}
end

function Sync:Broadcast(payloadType, payload, distribution, target, priority)
  local hasAceComm = type(self.addon.SendCommMessage) == "function" and type(self.addon.Serialize) == "function"
  local hasNativeComm = (_G.C_ChatInfo and type(_G.C_ChatInfo.SendAddonMessage) == "function")
    or type(_G.SendAddonMessage) == "function"

  if not hasAceComm and not hasNativeComm then
    self.lastBroadcast = {
      payloadType = payloadType,
      distribution = distribution or "GUILD",
      ok = false,
      error = "comm unavailable",
    }

    return false, "comm unavailable"
  end

  local envelope, err = self:BuildEnvelope(payloadType, payload)
  if not envelope then
    self.lastBroadcast = {
      payloadType = payloadType,
      distribution = distribution or "GUILD",
      ok = false,
      error = err,
    }

    return false, err
  end

  if hasAceComm then
    local serialized = self.addon:Serialize(envelope)
    self.addon:SendCommMessage(
      self.addon.Constants.COMM_PREFIX,
      serialized,
      distribution or "GUILD",
      target,
      priority or "NORMAL"
    )
  else
    local serialized, serializeErr = self:SerializeEnvelope(envelope)
    if not serialized then
      self.lastBroadcast = {
        payloadType = payloadType,
        distribution = distribution or "GUILD",
        ok = false,
        error = serializeErr,
      }

      return false, serializeErr
    end

    sendNativeAddonMessage(self.addon.Constants.COMM_PREFIX, serialized, distribution or "GUILD", target)
  end

  self.lastBroadcast = {
    payloadType = payloadType,
    distribution = distribution or "GUILD",
    target = target,
    priority = priority or "NORMAL",
    ok = true,
    transport = hasAceComm and "ace" or "native",
  }

  return true
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

  if envelope.payloadType == "award" then
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
    sender = sender,
    distribution = distribution,
    ok = ok == true,
    error = err,
  })

  if ok and self.addon.mainFrame and self.addon.mainFrame.rendered then
    self.addon.mainFrame:RenderActiveTab()
  end

  return ok, err
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

  if award.deleted == true then
    local deleted, deleteErr = self.addon.db:DeleteAward(award.guildKey, award.awardId)
    if not deleted then
      return false, deleteErr
    end

    if award.nominationId then
      local deletedNomination, nominationErr = self.addon.db:DeleteNomination(
        award.guildKey,
        award.nominationId
      )
      if not deletedNomination and nominationErr ~= "missing nomination" then
        return false, nominationErr
      end
    end

    return true
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

function Sync:GetDebugLines()
  local guild = self.addon:GetActiveGuildContext()
  local lines = {
    "Rolling Pin Awards sync diagnostics",
    ("Guild: %s"):format(guild and guild.guildKey or "none"),
    ("Comm prefix: %s registered=%s"):format(
      self.addon.Constants and self.addon.Constants.COMM_PREFIX or "unknown",
      tostring(self.addon.__aceCommPrefix or "fallback")
    ),
    ("Ace3: %s SendComm=%s Serialize=%s"):format(
      tostring(self.addon.__rpaUsesAce3 == true),
      tostring(type(self.addon.SendCommMessage) == "function"),
      tostring(type(self.addon.Serialize) == "function")
    ),
    ("Native comm: registered=%s SendAddon=%s"):format(
      tostring(self.addon.__rpaNativeCommPrefix or "none"),
      tostring((_G.C_ChatInfo and type(_G.C_ChatInfo.SendAddonMessage) == "function")
        or type(_G.SendAddonMessage) == "function")
    ),
  }

  if self.lastBroadcast then
    lines[#lines + 1] = ("Last outbound: type=%s distribution=%s transport=%s ok=%s error=%s"):format(
      tostring(self.lastBroadcast.payloadType),
      tostring(self.lastBroadcast.distribution),
      tostring(self.lastBroadcast.transport or "unknown"),
      tostring(self.lastBroadcast.ok),
      tostring(self.lastBroadcast.error or "none")
    )
  else
    lines[#lines + 1] = "Last outbound: none"
  end

  if self.lastInbound then
    lines[#lines + 1] = ("Last inbound: type=%s sender=%s distribution=%s ok=%s error=%s"):format(
      tostring(self.lastInbound.payloadType),
      tostring(self.lastInbound.sender),
      tostring(self.lastInbound.distribution),
      tostring(self.lastInbound.ok),
      tostring(self.lastInbound.error or "none")
    )
  else
    lines[#lines + 1] = "Last inbound: none"
  end

  return lines
end

return RPA.Sync

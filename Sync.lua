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

local function copyFlatRecord(record)
  local output = {}

  for key, value in pairs(record or {}) do
    local valueType = type(value)
    if valueType == "string" or valueType == "number" or valueType == "boolean" then
      output[key] = value
    end
  end

  return output
end

local function sortedKeys(records)
  local keys = {}

  for key in pairs(records or {}) do
    keys[#keys + 1] = key
  end

  table.sort(keys, function(left, right)
    if type(left) == type(right) then
      return left < right
    end

    return tostring(left) < tostring(right)
  end)

  return keys
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
    local ok, err = pcall(self.addon.SendCommMessage, self.addon,
      self.addon.Constants.COMM_PREFIX,
      serialized,
      distribution or "GUILD",
      target,
      priority or "NORMAL"
    )
    if not ok then
      self.lastBroadcast = {
        payloadType = payloadType,
        distribution = distribution or "GUILD",
        target = target,
        priority = priority or "NORMAL",
        ok = false,
        transport = "ace",
        error = err,
      }

      return false, err
    end
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

    local ok, result = pcall(
      sendNativeAddonMessage,
      self.addon.Constants.COMM_PREFIX,
      serialized,
      distribution or "GUILD",
      target
    )
    if not ok or result == false then
      self.lastBroadcast = {
        payloadType = payloadType,
        distribution = distribution or "GUILD",
        target = target,
        priority = priority or "NORMAL",
        ok = false,
        transport = "native",
        error = ok and "native send failed" or result,
      }

      return false, self.lastBroadcast.error
    end
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

function Sync:SendHello(distribution, target, force)
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    self.lastHello = {
      ok = false,
      error = "missing guild",
    }

    return false, "missing guild"
  end

  if not force and self.lastHello and self.lastHello.guildKey == guild.guildKey then
    return false, "hello already sent"
  end

  local ok, err = self:Broadcast("sync_hello", {
    guildKey = guild.guildKey,
    sender = self.addon:GetCurrentPlayerFullName(),
    sentAt = self.addon.Time and type(self.addon.Time.Now) == "function" and self.addon.Time:Now() or 0,
  }, distribution or "GUILD", target, "NORMAL")

  self.lastHello = {
    guildKey = guild.guildKey,
    ok = ok == true,
    error = err,
  }

  return ok, err
end

function Sync:SendFullSnapshot(distribution, target)
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    self.lastSnapshot = {
      ok = false,
      error = "missing guild",
    }

    return false, "missing guild"
  end

  local dataset = self.addon.db:GetGuildDataset(guild.guildKey)
  local counts = {
    awards = 0,
    nominations = 0,
    votes = 0,
    rankPermissions = 0,
    aliasMappings = 0,
  }

  for _, rankIndex in ipairs(sortedKeys(dataset.rankPermissions)) do
    local payload = copyFlatRecord(dataset.rankPermissions[rankIndex])
    payload.guildKey = guild.guildKey
    payload.rankIndex = tonumber(payload.rankIndex or rankIndex)
    if payload.rankIndex ~= nil then
      self:Broadcast("rank_permissions", payload, distribution or "GUILD", target)
      counts.rankPermissions = counts.rankPermissions + 1
    end
  end

  for _, aliasKey in ipairs(sortedKeys(dataset.aliasMappingsByKey)) do
    local payload = copyFlatRecord(dataset.aliasMappingsByKey[aliasKey])
    payload.guildKey = guild.guildKey
    payload.aliasKey = payload.aliasKey or aliasKey
    self:Broadcast("alias_mapping", payload, distribution or "GUILD", target)
    counts.aliasMappings = counts.aliasMappings + 1
  end

  for _, nominationId in ipairs(sortedKeys(dataset.nominationsById)) do
    local payload = copyFlatRecord(dataset.nominationsById[nominationId])
    payload.guildKey = guild.guildKey
    payload.nominationId = payload.nominationId or nominationId
    self:Broadcast("nomination", payload, distribution or "GUILD", target)
    counts.nominations = counts.nominations + 1
  end

  for _, nominationId in ipairs(sortedKeys(dataset.votesByNomination)) do
    for _, voter in ipairs(sortedKeys(dataset.votesByNomination[nominationId])) do
      local payload = copyFlatRecord(dataset.votesByNomination[nominationId][voter])
      payload.guildKey = guild.guildKey
      payload.nominationId = payload.nominationId or nominationId
      payload.voter = payload.voter or voter
      self:Broadcast("vote", payload, distribution or "GUILD", target)
      counts.votes = counts.votes + 1
    end
  end

  for _, awardId in ipairs(sortedKeys(dataset.awardsById)) do
    local payload = copyFlatRecord(dataset.awardsById[awardId])
    payload.guildKey = guild.guildKey
    payload.awardId = payload.awardId or awardId
    self:Broadcast("award", payload, distribution or "GUILD", target)
    counts.awards = counts.awards + 1
  end

  self:Broadcast("sync_snapshot_complete", {
    guildKey = guild.guildKey,
    sender = self.addon:GetCurrentPlayerFullName(),
    awards = counts.awards,
    nominations = counts.nominations,
    votes = counts.votes,
    rankPermissions = counts.rankPermissions,
    aliasMappings = counts.aliasMappings,
  }, distribution or "GUILD", target)

  self.lastSnapshot = {
    guildKey = guild.guildKey,
    ok = true,
    counts = counts,
  }

  return true, counts
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
    ("Ace libs: Comm=%s Serializer=%s Console=%s Event=%s"):format(
      tostring((self.addon.__rpaAceLibraries or {})["AceComm-3.0"] == true),
      tostring((self.addon.__rpaAceLibraries or {})["AceSerializer-3.0"] == true),
      tostring((self.addon.__rpaAceLibraries or {})["AceConsole-3.0"] == true),
      tostring((self.addon.__rpaAceLibraries or {})["AceEvent-3.0"] == true)
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

  if self.lastHello then
    lines[#lines + 1] = ("Last hello: guild=%s ok=%s error=%s"):format(
      tostring(self.lastHello.guildKey or "none"),
      tostring(self.lastHello.ok),
      tostring(self.lastHello.error or "none")
    )
  else
    lines[#lines + 1] = "Last hello: none"
  end

  if self.lastSnapshot then
    local counts = self.lastSnapshot.counts or {}
    lines[#lines + 1] = ("Last snapshot: guild=%s awards=%s nominations=%s votes=%s aliases=%s ranks=%s ok=%s"):format(
      tostring(self.lastSnapshot.guildKey or "none"),
      tostring(counts.awards or 0),
      tostring(counts.nominations or 0),
      tostring(counts.votes or 0),
      tostring(counts.aliasMappings or 0),
      tostring(counts.rankPermissions or 0),
      tostring(self.lastSnapshot.ok)
    )
  else
    lines[#lines + 1] = "Last snapshot: none"
  end

  return lines
end

return RPA.Sync

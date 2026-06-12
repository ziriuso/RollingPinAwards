local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Sync = RPA.Sync or {}
RPA.Sync = Sync

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

  for _, awardId in ipairs(sortedKeys(dataset.awardsById)) do
    local payload = copyFlatRecord(dataset.awardsById[awardId])
    payload.guildKey = guild.guildKey
    payload.awardId = payload.awardId or awardId
    self:Broadcast("award", payload, distribution or "GUILD", target)
    counts.awards = counts.awards + 1
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

return RPA.Sync

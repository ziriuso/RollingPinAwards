local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Database = RPA.Database or {}
RPA.Database = Database
local Utils = RPA.Utils or {}

local function isMissingString(value)
  return type(value) ~= "string" or value == ""
end

local function seedNextSequence(recordsById, prefix)
  local maxSequence = 0

  for objectId in pairs(recordsById or {}) do
    local sequence = tonumber(string.match(objectId, "^" .. prefix .. ":(%d+)$"))
      or tonumber(string.match(objectId, "^" .. prefix .. ":.*:(%d+)$"))
    if sequence and sequence > maxSequence then
      maxSequence = sequence
    end
  end

  return maxSequence
end

local function idPart(value)
  local text = tostring(value or "local")
  text = text:gsub("[^%w%-_]", "_")
  if text == "" then
    return "local"
  end

  return text
end

local function ensureGuildDatasetShape(dataset, guildKey)
  dataset.guildKey = dataset.guildKey or guildKey
  dataset.awards = type(dataset.awards) == "table" and dataset.awards or {}
  dataset.awardsById = type(dataset.awardsById) == "table" and dataset.awardsById or {}
  dataset.nominations = type(dataset.nominations) == "table" and dataset.nominations or {}
  dataset.nominationsById = type(dataset.nominationsById) == "table" and dataset.nominationsById or {}
  dataset.permissionRoster = type(dataset.permissionRoster) == "table" and dataset.permissionRoster or {}
  dataset.rankPermissions = type(dataset.rankPermissions) == "table" and dataset.rankPermissions or {}
  dataset.aliasMappingsByKey = type(dataset.aliasMappingsByKey) == "table" and dataset.aliasMappingsByKey or {}
  dataset.votesByNomination = type(dataset.votesByNomination) == "table" and dataset.votesByNomination or {}
  dataset.meta = type(dataset.meta) == "table" and dataset.meta or {}
  dataset.meta.nextNominationSequence = type(dataset.meta.nextNominationSequence) == "number"
      and dataset.meta.nextNominationSequence
    or seedNextSequence(dataset.nominationsById, "nom")
  dataset.meta.nextAwardSequence = type(dataset.meta.nextAwardSequence) == "number"
      and dataset.meta.nextAwardSequence
    or seedNextSequence(dataset.awardsById, "award")

  return dataset
end

local function ensureLocalSettingsShape(settings)
  if type(settings) ~= "table" then
    settings = {}
  end

  if settings.toastsEnabled == nil then
    settings.toastsEnabled = true
  else
    settings.toastsEnabled = settings.toastsEnabled == true
  end

  settings.toastDurationSeconds = math.min(
    15,
    math.max(3, tonumber(settings.toastDurationSeconds) or 7)
  )

  if type(settings.seenAwardToastIds) ~= "table" then
    settings.seenAwardToastIds = {}
  end

  if type(settings.toastAnchor) ~= "table" then
    settings.toastAnchor = {}
  end

  settings.toastAnchor.point = type(settings.toastAnchor.point) == "string"
      and settings.toastAnchor.point
    or "CENTER"
  settings.toastAnchor.relativePoint = type(settings.toastAnchor.relativePoint) == "string"
      and settings.toastAnchor.relativePoint
    or settings.toastAnchor.point
  settings.toastAnchor.x = tonumber(settings.toastAnchor.x) or 0
  settings.toastAnchor.y = tonumber(settings.toastAnchor.y) or 180

  return settings
end

local function rebuildNominationRows(dataset)
  local nominationIds = {}

  for nominationId in pairs(dataset.nominationsById) do
    nominationIds[#nominationIds + 1] = nominationId
  end

  table.sort(nominationIds)

  dataset.nominations = {}
  for _, nominationId in ipairs(nominationIds) do
    local nomination = dataset.nominationsById[nominationId]
    if nomination.deleted ~= true then
      dataset.nominations[#dataset.nominations + 1] = nomination
    end
  end
end

local function rebuildAwardRows(dataset)
  local awardIds = {}

  for awardId in pairs(dataset.awardsById) do
    awardIds[#awardIds + 1] = awardId
  end

  table.sort(awardIds)

  dataset.awards = {}
  for _, awardId in ipairs(awardIds) do
    local award = dataset.awardsById[awardId]
    if award.deleted ~= true then
      dataset.awards[#dataset.awards + 1] = award
    end
  end
end

local function isEmptyMap(input)
  for _ in pairs(input or {}) do
    return false
  end

  return true
end

function Database:New(storage)
  local obj = {
    storage = storage,
  }

  self.__index = self

  return setmetatable(obj, self)
end

function Database:GetGuildDataset(guildKey)
  if isMissingString(guildKey) then
    return nil, "missing guildKey"
  end

  local datasets = self.storage.profile.guildDatasets

  if not datasets[guildKey] then
    datasets[guildKey] = {
      guildKey = guildKey,
      awards = {},
      awardsById = {},
      nominations = {},
      nominationsById = {},
      permissionRoster = {},
      rankPermissions = {},
      aliasMappingsByKey = {},
      votesByNomination = {},
    }
  end

  return ensureGuildDatasetShape(datasets[guildKey], guildKey)
end

function Database:GetLocalSettings()
  self.storage.profile.localSettings = ensureLocalSettingsShape(self.storage.profile.localSettings)

  return self.storage.profile.localSettings
end

function Database:SetToastsEnabled(enabled)
  local settings = self:GetLocalSettings()
  settings.toastsEnabled = enabled == true

  return settings.toastsEnabled
end

function Database:SetToastDurationSeconds(seconds)
  local settings = self:GetLocalSettings()
  settings.toastDurationSeconds = math.min(15, math.max(3, tonumber(seconds) or 7))

  return settings.toastDurationSeconds
end

function Database:HasSeenAwardToast(awardId)
  if isMissingString(awardId) then
    return false
  end

  local settings = self:GetLocalSettings()

  return settings.seenAwardToastIds[awardId] == true
end

function Database:MarkAwardToastSeen(awardId)
  if isMissingString(awardId) then
    return false, "missing awardId"
  end

  local settings = self:GetLocalSettings()
  settings.seenAwardToastIds[awardId] = true

  return true
end

function Database:SaveToastAnchor(point, relativePoint, x, y)
  local settings = self:GetLocalSettings()
  settings.toastAnchor = {
    point = type(point) == "string" and point or "CENTER",
    relativePoint = type(relativePoint) == "string" and relativePoint or point or "CENTER",
    x = tonumber(x) or 0,
    y = tonumber(y) or 0,
  }

  return settings.toastAnchor
end

function Database:MigrateGuildDatasetKey(fromGuildKey, toGuildKey)
  if isMissingString(fromGuildKey) or isMissingString(toGuildKey) then
    return false, "missing guildKey"
  end

  if fromGuildKey == toGuildKey then
    return true
  end

  local datasets = self.storage.profile.guildDatasets
  local source = datasets[fromGuildKey]
  if type(source) ~= "table" then
    return false, "missing source guild dataset"
  end

  local target = datasets[toGuildKey]
  if type(target) ~= "table" then
    datasets[toGuildKey] = source
    datasets[toGuildKey].guildKey = toGuildKey
    datasets[fromGuildKey] = nil
    ensureGuildDatasetShape(datasets[toGuildKey], toGuildKey)
    return true
  end

  source = ensureGuildDatasetShape(source, fromGuildKey)
  target = ensureGuildDatasetShape(target, toGuildKey)

  for nominationId, nomination in pairs(source.nominationsById) do
    nomination.guildKey = toGuildKey
    target.nominationsById[nominationId] = target.nominationsById[nominationId] or nomination
  end

  for awardId, award in pairs(source.awardsById) do
    award.guildKey = toGuildKey
    target.awardsById[awardId] = target.awardsById[awardId] or award
  end

  for rankIndex, row in pairs(source.rankPermissions) do
    target.rankPermissions[rankIndex] = target.rankPermissions[rankIndex] or row
  end

  for playerName, row in pairs(source.permissionRoster) do
    target.permissionRoster[playerName] = target.permissionRoster[playerName] or row
  end

  for aliasKey, row in pairs(source.aliasMappingsByKey) do
    target.aliasMappingsByKey[aliasKey] = target.aliasMappingsByKey[aliasKey] or row
  end

  for nominationId, ledger in pairs(source.votesByNomination) do
    target.votesByNomination[nominationId] = target.votesByNomination[nominationId] or {}
    for voter, vote in pairs(ledger) do
      target.votesByNomination[nominationId][voter] = target.votesByNomination[nominationId][voter] or vote
    end
  end

  if type(source.meta.nextNominationSequence) == "number" then
    target.meta.nextNominationSequence = math.max(
      target.meta.nextNominationSequence or 0,
      source.meta.nextNominationSequence
    )
  end

  if type(source.meta.nextAwardSequence) == "number" then
    target.meta.nextAwardSequence = math.max(
      target.meta.nextAwardSequence or 0,
      source.meta.nextAwardSequence
    )
  end

  rebuildNominationRows(target)
  rebuildAwardRows(target)
  datasets[fromGuildKey] = nil

  return true
end

function Database:UpsertNomination(guildKey, nomination)
  if type(nomination) ~= "table" or isMissingString(nomination.nominationId) then
    return nil, "missing nominationId"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  dataset.nominationsById[nomination.nominationId] = nomination
  rebuildNominationRows(dataset)

  return nomination
end

function Database:GetNomination(guildKey, nominationId, includeDeleted)
  if isMissingString(nominationId) then
    return nil, "missing nominationId"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  local nomination = dataset.nominationsById[nominationId]
  if nomination and nomination.deleted == true and includeDeleted ~= true then
    return nil, nil
  end

  return nomination, nil
end

function Database:DeleteNomination(guildKey, nominationId, tombstone)
  if isMissingString(nominationId) then
    return false, "missing nominationId"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return false, err
  end

  if dataset.nominationsById[nominationId] == nil and type(tombstone) ~= "table" then
    return false, "missing nomination"
  end

  if type(tombstone) == "table" then
    tombstone.guildKey = tombstone.guildKey or guildKey
    tombstone.nominationId = tombstone.nominationId or nominationId
    tombstone.deleted = true
    dataset.nominationsById[nominationId] = tombstone
  else
    dataset.nominationsById[nominationId] = nil
  end
  dataset.votesByNomination[nominationId] = nil
  rebuildNominationRows(dataset)

  return true
end

function Database:UpsertPermissionRosterEntry(guildKey, entry)
  if type(entry) ~= "table" or isMissingString(entry.player) then
    return nil, "missing playerFullName"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  dataset.permissionRoster[entry.player] = entry

  return entry
end

function Database:GetPermissionRosterEntry(guildKey, playerFullName)
  if isMissingString(playerFullName) then
    return nil, "missing playerFullName"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  return dataset.permissionRoster[playerFullName], nil
end

function Database:RemovePermissionRosterEntry(guildKey, playerFullName)
  if isMissingString(playerFullName) then
    return false, "missing playerFullName"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return false, err
  end

  dataset.permissionRoster[playerFullName] = nil

  return true
end

function Database:GetPermissionRosterEntries(guildKey)
  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  local rows = {}

  for _, entry in pairs(dataset.permissionRoster) do
    rows[#rows + 1] = entry
  end

  table.sort(rows, function(left, right)
    return left.player < right.player
  end)

  return rows
end

function Database:UpsertRankPermission(guildKey, rankIndex, row)
  if type(rankIndex) ~= "number" then
    return nil, "missing rankIndex"
  end

  if type(row) ~= "table" then
    return nil, "missing row"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  dataset.rankPermissions[rankIndex] = row

  return row
end

function Database:GetRankPermission(guildKey, rankIndex)
  if type(rankIndex) ~= "number" then
    return nil, "missing rankIndex"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  return dataset.rankPermissions[rankIndex], nil
end

function Database:GetRankPermissions(guildKey)
  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  return dataset.rankPermissions, nil
end

function Database:UpsertAliasMapping(guildKey, row)
  local aliasKey = type(row) == "table" and Utils.NormalizeAliasKey(row.aliasKey or row.aliasDisplay) or nil
  if isMissingString(aliasKey) then
    return nil, "missing aliasKey"
  end

  if type(row) ~= "table" or isMissingString(row.canonicalName) then
    return nil, "missing canonicalName"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  row.aliasKey = aliasKey
  dataset.aliasMappingsByKey[aliasKey] = row

  return row
end

function Database:GetAliasMapping(guildKey, aliasKey)
  aliasKey = Utils.NormalizeAliasKey(aliasKey)
  if isMissingString(aliasKey) then
    return nil, "missing aliasKey"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  return dataset.aliasMappingsByKey[aliasKey], nil
end

function Database:GetAliasMappings(guildKey)
  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  local rows = {}

  for _, row in pairs(dataset.aliasMappingsByKey) do
    rows[#rows + 1] = row
  end

  table.sort(rows, function(left, right)
    local leftDisplay = left.aliasDisplay or ""
    local rightDisplay = right.aliasDisplay or ""
    if leftDisplay ~= rightDisplay then
      return leftDisplay < rightDisplay
    end

    return (left.canonicalName or "") < (right.canonicalName or "")
  end)

  return rows
end

function Database:DeleteAliasMapping(guildKey, aliasKey)
  aliasKey = Utils.NormalizeAliasKey(aliasKey)
  if isMissingString(aliasKey) then
    return false, "missing aliasKey"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return false, err
  end

  if dataset.aliasMappingsByKey[aliasKey] == nil then
    return false, "missing alias mapping"
  end

  dataset.aliasMappingsByKey[aliasKey] = nil

  return true
end

function Database:NextNominationId(guildKey, actorKey, timestamp)
  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  dataset.meta.nextNominationSequence = dataset.meta.nextNominationSequence + 1

  return ("nom:%s:%d:%d"):format(
    idPart(actorKey),
    tonumber(timestamp or 0) or 0,
    dataset.meta.nextNominationSequence
  ), nil
end

function Database:NextAwardId(guildKey, actorKey, timestamp)
  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  dataset.meta.nextAwardSequence = dataset.meta.nextAwardSequence + 1

  return ("award:%s:%d:%d"):format(
    idPart(actorKey),
    tonumber(timestamp or 0) or 0,
    dataset.meta.nextAwardSequence
  ), nil
end

function Database:UpsertAward(guildKey, award)
  if type(award) ~= "table" or isMissingString(award.awardId) then
    return nil, "missing awardId"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  dataset.awardsById[award.awardId] = award
  rebuildAwardRows(dataset)

  return award
end

function Database:GetAward(guildKey, awardId, includeDeleted)
  if isMissingString(awardId) then
    return nil, "missing awardId"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  local award = dataset.awardsById[awardId]
  if award and award.deleted == true and includeDeleted ~= true then
    return nil, nil
  end

  return award, nil
end

function Database:DeleteAward(guildKey, awardId, tombstone)
  if isMissingString(awardId) then
    return false, "missing awardId"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return false, err
  end

  if dataset.awardsById[awardId] == nil and type(tombstone) ~= "table" then
    return false, "missing award"
  end

  if type(tombstone) == "table" then
    tombstone.guildKey = tombstone.guildKey or guildKey
    tombstone.awardId = tombstone.awardId or awardId
    tombstone.deleted = true
    dataset.awardsById[awardId] = tombstone
  else
    dataset.awardsById[awardId] = nil
  end
  rebuildAwardRows(dataset)

  return true
end

function Database:StoreVote(guildKey, nominationId, vote)
  if isMissingString(nominationId) then
    return nil, "missing nominationId"
  end

  if type(vote) ~= "table" or isMissingString(vote.voter) then
    return nil, "missing voter"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  dataset.votesByNomination[nominationId] = dataset.votesByNomination[nominationId] or {}
  dataset.votesByNomination[nominationId][vote.voter] = vote

  return vote
end

function Database:GetVote(guildKey, nominationId, voter)
  if isMissingString(nominationId) then
    return nil, "missing nominationId"
  end

  if isMissingString(voter) then
    return nil, "missing voter"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  local ledger = dataset.votesByNomination[nominationId]
  if type(ledger) ~= "table" then
    return nil, nil
  end

  return ledger[voter], nil
end

function Database:GetVotesForNomination(guildKey, nominationId)
  if isMissingString(nominationId) then
    return nil, "missing nominationId"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  dataset.votesByNomination[nominationId] = dataset.votesByNomination[nominationId] or {}

  return dataset.votesByNomination[nominationId], nil
end

return RPA.Database

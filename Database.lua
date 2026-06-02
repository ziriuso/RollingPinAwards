local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Database = RPA.Database or {}
RPA.Database = Database

local function isMissingString(value)
  return type(value) ~= "string" or value == ""
end

local function seedNextSequence(recordsById, prefix)
  local maxSequence = 0

  for objectId in pairs(recordsById or {}) do
    local sequence = tonumber(string.match(objectId, "^" .. prefix .. ":(%d+)$"))
    if sequence and sequence > maxSequence then
      maxSequence = sequence
    end
  end

  return maxSequence
end

local function ensureGuildDatasetShape(dataset, guildKey)
  dataset.guildKey = dataset.guildKey or guildKey
  dataset.awards = type(dataset.awards) == "table" and dataset.awards or {}
  dataset.awardsById = type(dataset.awardsById) == "table" and dataset.awardsById or {}
  dataset.nominations = type(dataset.nominations) == "table" and dataset.nominations or {}
  dataset.nominationsById = type(dataset.nominationsById) == "table" and dataset.nominationsById or {}
  dataset.permissionRoster = type(dataset.permissionRoster) == "table" and dataset.permissionRoster or {}
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

local function rebuildNominationRows(dataset)
  local nominationIds = {}

  for nominationId in pairs(dataset.nominationsById) do
    nominationIds[#nominationIds + 1] = nominationId
  end

  table.sort(nominationIds)

  dataset.nominations = {}
  for _, nominationId in ipairs(nominationIds) do
    dataset.nominations[#dataset.nominations + 1] = dataset.nominationsById[nominationId]
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
    dataset.awards[#dataset.awards + 1] = dataset.awardsById[awardId]
  end
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
      votesByNomination = {},
    }
  end

  return ensureGuildDatasetShape(datasets[guildKey], guildKey)
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

function Database:GetNomination(guildKey, nominationId)
  if isMissingString(nominationId) then
    return nil, "missing nominationId"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  return dataset.nominationsById[nominationId], nil
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

function Database:NextNominationId(guildKey)
  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  dataset.meta.nextNominationSequence = dataset.meta.nextNominationSequence + 1

  return ("nom:%d"):format(dataset.meta.nextNominationSequence), nil
end

function Database:NextAwardId(guildKey)
  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  dataset.meta.nextAwardSequence = dataset.meta.nextAwardSequence + 1

  return ("award:%d"):format(dataset.meta.nextAwardSequence), nil
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

function Database:GetAward(guildKey, awardId)
  if isMissingString(awardId) then
    return nil, "missing awardId"
  end

  local dataset, err = self:GetGuildDataset(guildKey)
  if not dataset then
    return nil, err
  end

  return dataset.awardsById[awardId], nil
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

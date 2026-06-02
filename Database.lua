local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Database = RPA.Database or {}
RPA.Database = Database

local function isMissingString(value)
  return type(value) ~= "string" or value == ""
end

local function ensureGuildDatasetShape(dataset, guildKey)
  dataset.guildKey = dataset.guildKey or guildKey
  dataset.awards = type(dataset.awards) == "table" and dataset.awards or {}
  dataset.awardsById = type(dataset.awardsById) == "table" and dataset.awardsById or {}
  dataset.nominations = type(dataset.nominations) == "table" and dataset.nominations or {}
  dataset.nominationsById = type(dataset.nominationsById) == "table" and dataset.nominationsById or {}
  dataset.permissionRoster = type(dataset.permissionRoster) == "table" and dataset.permissionRoster or {}
  dataset.votesByNomination = type(dataset.votesByNomination) == "table" and dataset.votesByNomination or {}

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

return RPA.Database

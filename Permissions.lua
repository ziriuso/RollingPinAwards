local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Permissions = RPA.Permissions or {}
RPA.Permissions = Permissions

local function isMissingString(value)
  return type(value) ~= "string" or value == ""
end

local function normalizeFullName(name)
  if isMissingString(name) then
    return nil
  end

  if name:find("-", 1, true) then
    return name
  end

  return ("%s-%s"):format(name, GetRealmName())
end

local function isOfficerRank(rankName, rankIndex)
  if rankIndex == 0 or rankName == "Guild Master" then
    return true
  end

  if rankName == "Officer" then
    return true
  end

  return type(rankIndex) == "number" and rankIndex == 1
end

function Permissions:New(addon, roster)
  local obj = {
    addon = addon,
    roster = roster,
  }

  self.__index = self

  return setmetatable(obj, self)
end

function Permissions:GetGuildRankInfo(playerFullName)
  local normalizedTarget = normalizeFullName(playerFullName or self.addon:GetCurrentPlayerFullName())
  if not normalizedTarget then
    return nil, nil
  end

  if normalizedTarget == normalizeFullName(self.addon:GetCurrentPlayerFullName()) then
    local _, rankName, rankIndex = GetGuildInfo("player")

    if rankName ~= nil or rankIndex ~= nil then
      return rankName, rankIndex
    end
  end

  if type(GetNumGuildMembers) ~= "function" or type(GetGuildRosterInfo) ~= "function" then
    return nil, nil
  end

  local memberCount = GetNumGuildMembers() or 0

  for index = 1, memberCount do
    local rosterName, rankName, rankIndex = GetGuildRosterInfo(index)
    if normalizeFullName(rosterName) == normalizedTarget then
      return rankName, rankIndex
    end
  end

  return nil, nil
end

function Permissions:IsGuildMaster(playerFullName)
  local rankName, rankIndex = self:GetGuildRankInfo(playerFullName)

  return rankIndex == 0 or rankName == "Guild Master"
end

function Permissions:IsOfficerFromGuildRoster(playerFullName)
  local rankName, rankIndex = self:GetGuildRankInfo(playerFullName)

  return isOfficerRank(rankName, rankIndex)
end

function Permissions:IsOfficer(playerFullName)
  local normalizedTarget = normalizeFullName(playerFullName)
  if not normalizedTarget then
    return false
  end

  if normalizedTarget == normalizeFullName(self.addon:GetCurrentPlayerFullName()) then
    if self:IsGuildMaster(normalizedTarget) then
      return true
    end

    local guildInfoApi = _G.C_GuildInfo
    if guildInfoApi and type(guildInfoApi.IsGuildOfficer) == "function" then
      return guildInfoApi.IsGuildOfficer() == true
    end
  end

  return self:IsOfficerFromGuildRoster(normalizedTarget)
end

function Permissions:HasOfficerPermission(playerFullName)
  local guild = self.addon:GetActiveGuildContext()
  local normalizedTarget = normalizeFullName(playerFullName)

  if not guild or not normalizedTarget then
    return false
  end

  return self.roster:Has(guild.guildKey, normalizedTarget)
end

function Permissions:GrantOfficerPermission(playerFullName)
  local guild = self.addon:GetActiveGuildContext()
  local normalizedTarget = normalizeFullName(playerFullName)

  if not guild or not normalizedTarget then
    return false
  end

  if not self:IsGuildMaster() then
    return false
  end

  if not self:IsOfficer(normalizedTarget) then
    return false
  end

  return self.roster:Grant(
    guild.guildKey,
    normalizedTarget,
    self.addon:GetCurrentPlayerFullName()
  )
end

function Permissions:CanManageAwards(playerFullName)
  local normalizedTarget = normalizeFullName(playerFullName or self.addon:GetCurrentPlayerFullName())
  if not normalizedTarget then
    return false
  end

  if self:IsGuildMaster(normalizedTarget) then
    return true
  end

  return self:IsOfficer(normalizedTarget) and self:HasOfficerPermission(normalizedTarget)
end

return RPA.Permissions

local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Permissions = RPA.Permissions or {}
RPA.Permissions = Permissions
local Utils = RPA.Utils or {}

local function isMissingString(value)
  return type(value) ~= "string" or value == ""
end

local function normalizeFullName(name)
  return Utils.NormalizeUnitName(name)
end

local function copyRow(row)
  local output = {}

  for key, value in pairs(row or {}) do
    output[key] = value
  end

  return output
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

function Permissions:GetRankPermissionRow(rankIndex)
  local guild = self.addon:GetActiveGuildContext()
  if not guild or type(rankIndex) ~= "number" then
    return nil
  end

  return self.addon.db:GetRankPermission(guild.guildKey, rankIndex)
end

function Permissions:GetGuildRankMatrix()
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return {}
  end

  local rowsByRank = self.addon.db:GetRankPermissions(guild.guildKey) or {}
  local matrix = {}
  local seen = {}

  if type(GuildControlGetNumRanks) == "function" and type(GuildControlGetRankName) == "function" then
    local rankCount = GuildControlGetNumRanks() or 0
    for index = 1, rankCount do
      local rankName = GuildControlGetRankName(index)
      local rankIndex = index - 1

      if type(rankIndex) == "number" and not seen[rankIndex] then
        seen[rankIndex] = true
        local row = copyRow(rowsByRank[rankIndex] or {})
        row.rankIndex = rankIndex
        row.rankName = row.rankName or rankName or ("Rank %d"):format(rankIndex)
        row.canManageNominations = row.canManageNominations == true
        row.canCreateDirectAwards = row.canCreateDirectAwards == true
        row.canDeleteAwards = row.canDeleteAwards == true
        row.canManageAddonPermissions = row.canManageAddonPermissions == true
        matrix[#matrix + 1] = row
      end
    end
  end

  if type(GetNumGuildMembers) == "function" and type(GetGuildRosterInfo) == "function" then
    local memberCount = GetNumGuildMembers() or 0
    for index = 1, memberCount do
      local _, rankName, rankIndex = GetGuildRosterInfo(index)
      if type(rankIndex) == "number" and not seen[rankIndex] then
        seen[rankIndex] = true
        local row = copyRow(rowsByRank[rankIndex] or {})
        row.rankIndex = rankIndex
        row.rankName = row.rankName or rankName or ("Rank %d"):format(rankIndex)
        row.canManageNominations = row.canManageNominations == true
        row.canCreateDirectAwards = row.canCreateDirectAwards == true
        row.canDeleteAwards = row.canDeleteAwards == true
        row.canManageAddonPermissions = row.canManageAddonPermissions == true
        matrix[#matrix + 1] = row
      end
    end
  end

  for rankIndex, row in pairs(rowsByRank) do
    if not seen[rankIndex] then
      local copy = copyRow(row)
      copy.rankIndex = rankIndex
      copy.rankName = copy.rankName or ("Rank %d"):format(rankIndex)
      copy.canManageNominations = copy.canManageNominations == true
      copy.canCreateDirectAwards = copy.canCreateDirectAwards == true
      copy.canDeleteAwards = copy.canDeleteAwards == true
      copy.canManageAddonPermissions = copy.canManageAddonPermissions == true
      matrix[#matrix + 1] = copy
    end
  end

  table.sort(matrix, function(left, right)
    return left.rankIndex < right.rankIndex
  end)

  return matrix
end

function Permissions:GetPermissionsForPlayer(playerFullName)
  local rankName, rankIndex = self:GetGuildRankInfo(playerFullName)

  if rankIndex == 0 or rankName == "Guild Master" then
    return {
      rankIndex = 0,
      rankName = rankName or "Guild Master",
      canManageNominations = true,
      canCreateDirectAwards = true,
      canDeleteAwards = true,
      canManageAddonPermissions = true,
    }
  end

  local row = self:GetRankPermissionRow(rankIndex)
  if type(row) == "table" then
    local copy = copyRow(row)
    copy.rankIndex = rankIndex
    copy.rankName = copy.rankName or rankName or ("Rank %d"):format(rankIndex or -1)
    copy.canManageNominations = copy.canManageNominations == true
    copy.canCreateDirectAwards = copy.canCreateDirectAwards == true
    copy.canDeleteAwards = copy.canDeleteAwards == true
    copy.canManageAddonPermissions = copy.canManageAddonPermissions == true
    return copy
  end

  return {
    rankIndex = rankIndex,
    rankName = rankName,
    rankUnresolved = rankName == nil and rankIndex == nil,
    canManageNominations = false,
    canCreateDirectAwards = false,
    canDeleteAwards = false,
    canManageAddonPermissions = false,
  }
end

function Permissions:IsRankUnresolved(playerFullName)
  local rankName, rankIndex = self:GetGuildRankInfo(playerFullName)

  return rankName == nil and rankIndex == nil
end

function Permissions:SetRankPermissions(rankIndex, rankName, permissions)
  local guild = self.addon:GetActiveGuildContext()
  if not guild or type(rankIndex) ~= "number" then
    return false
  end

  if rankIndex ~= 0 and not self:CanManageAddonPermissions() then
    return false
  end

  local row = {
    rankIndex = rankIndex,
    rankName = rankName or ("Rank %d"):format(rankIndex),
    canManageNominations = permissions.canManageNominations == true,
    canCreateDirectAwards = permissions.canCreateDirectAwards == true,
    canDeleteAwards = permissions.canDeleteAwards == true,
    canManageAddonPermissions = permissions.canManageAddonPermissions == true,
    lastModifiedAt = self.addon.Time:Now(),
    lastModifiedBy = self.addon:GetCurrentPlayerFullName(),
  }

  self.addon.db:UpsertRankPermission(guild.guildKey, rankIndex, row)

  if self.addon.sync then
    local payload = copyRow(row)
    payload.guildKey = guild.guildKey
    self.addon.sync:Broadcast("rank_permissions", payload, "GUILD")
  end

  return true
end

function Permissions:CanManageNominations(playerFullName)
  return self:GetPermissionsForPlayer(playerFullName).canManageNominations == true
end

function Permissions:CanCreateDirectAwards(playerFullName)
  return self:GetPermissionsForPlayer(playerFullName).canCreateDirectAwards == true
end

function Permissions:CanDeleteAwards(playerFullName)
  return self:GetPermissionsForPlayer(playerFullName).canDeleteAwards == true
end

function Permissions:CanManageAddonPermissions(playerFullName)
  return self:GetPermissionsForPlayer(playerFullName).canManageAddonPermissions == true
end

function Permissions:CanManageAwards(playerFullName)
  local row = self:GetPermissionsForPlayer(playerFullName)

  return row.canManageNominations == true
    or row.canCreateDirectAwards == true
    or row.canDeleteAwards == true
    or row.canManageAddonPermissions == true
end

function Permissions:HasOfficerPermission(playerFullName)
  return self:CanManageAwards(playerFullName)
end

function Permissions:GrantOfficerPermission(playerFullName)
  local normalizedTarget = normalizeFullName(playerFullName)
  if not normalizedTarget then
    return false
  end

  local rankName, rankIndex = self:GetGuildRankInfo(normalizedTarget)
  if type(rankIndex) ~= "number" then
    return false
  end

  local ok = self:SetRankPermissions(rankIndex, rankName, {
    canManageNominations = true,
    canCreateDirectAwards = true,
    canDeleteAwards = true,
    canManageAddonPermissions = true,
  })

  if ok and self.roster then
    local guild = self.addon:GetActiveGuildContext()
    if guild then
      self.roster:Grant(
        guild.guildKey,
        normalizedTarget,
        self.addon:GetCurrentPlayerFullName()
      )
    end
  end

  return ok
end

function Permissions:RevokeOfficerPermission(playerFullName)
  local normalizedTarget = normalizeFullName(playerFullName)
  if not normalizedTarget then
    return false
  end

  local rankName, rankIndex = self:GetGuildRankInfo(normalizedTarget)
  if type(rankIndex) ~= "number" then
    return false
  end

  local ok = self:SetRankPermissions(rankIndex, rankName, {
    canManageNominations = false,
    canCreateDirectAwards = false,
    canDeleteAwards = false,
    canManageAddonPermissions = false,
  })

  if ok and self.roster then
    local guild = self.addon:GetActiveGuildContext()
    if guild then
      self.roster:Revoke(guild.guildKey, normalizedTarget)
    end
  end

  return ok
end

function Permissions:GetGrantedOfficerPermissions()
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return {}
  end

  if self.roster then
    return self.roster:List(guild.guildKey)
  end

  return {}
end

function Permissions:GetEligibleOfficers()
  if type(GetNumGuildMembers) ~= "function" or type(GetGuildRosterInfo) ~= "function" then
    return {}
  end

  local candidates = {}
  local count = GetNumGuildMembers() or 0

  for index = 1, count do
    local rosterName, rankName, rankIndex = GetGuildRosterInfo(index)
    local normalizedName = normalizeFullName(rosterName)

    if normalizedName and type(rankIndex) == "number" and rankIndex > 0 then
      candidates[#candidates + 1] = {
        player = normalizedName,
        rankName = rankName,
        rankIndex = rankIndex,
        hasPermission = self:HasOfficerPermission(normalizedName),
      }
    end
  end

  table.sort(candidates, function(left, right)
    return left.player < right.player
  end)

  return candidates
end

return RPA.Permissions

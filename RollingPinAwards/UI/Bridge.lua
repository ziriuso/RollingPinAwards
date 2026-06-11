local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Bridge = RPA.UIBridge or {}
RPA.UIBridge = Bridge
local Utils = RPA.Utils or {}
local Constants = RPA.Constants or {}
local getAwardTypeMediaPath

local function copyRows(input)
  local output = {}

  for index, row in ipairs(input or {}) do
    output[index] = row
  end

  return output
end

local function trim(value)
  if type(value) ~= "string" then
    return value
  end

  local result = string.gsub(value, "^%s+", "")
  result = string.gsub(result, "%s+$", "")

  return result
end

local function buildRow(nomination, includeModeration, displayNominee)
  local row = {
    nominationId = nomination.nominationId,
    nominee = displayNominee or nomination.nominee,
    shortNominee = Utils.GetShortCharacterName(displayNominee or nomination.nominee),
    reason = nomination.reason,
    nominatedBy = nomination.nominatedBy,
    status = nomination.status,
    upvotes = nomination.upvoteCount or 0,
    awardType = Utils.NormalizeAwardType(nomination.awardType),
    awardIconPath = getAwardTypeMediaPath(nomination.awardType),
    hasCurrentPlayerVoted = false,
  }

  if includeModeration then
    row.downvotes = nomination.downvoteCount or 0
    row.moderationFlagged = nomination.moderationFlagged == true
  end

  return row
end

function getAwardTypeMediaPath(awardType)
  local media = (RPA.UIStyles or {}).Media or {}
  local normalized = Utils.NormalizeAwardType(awardType)

  if normalized == Constants.AWARD_TYPE_GOLDEN then
    return media.leaderboardIcon
  end

  return media.awardIcon
end

local function copyMatrixRow(row)
  return {
    rankIndex = row.rankIndex,
    rankName = row.rankName,
    canManageNominations = row.canManageNominations == true,
    canCreateDirectAwards = row.canCreateDirectAwards == true,
    canDeleteAwards = row.canDeleteAwards == true,
    canManageAddonPermissions = row.canManageAddonPermissions == true,
  }
end

local function sortDescendingByCreatedAt(left, right)
  local leftTime = left.createdAt or 0
  local rightTime = right.createdAt or 0

  if leftTime ~= rightTime then
    return leftTime > rightTime
  end

  return (left.awardId or "") < (right.awardId or "")
end

local function getShortName(name)
  if Utils.GetShortCharacterName then
    return Utils.GetShortCharacterName(name)
  end

  if type(name) ~= "string" then
    return name
  end

  return name:match("^([^-]+)") or name
end

function Bridge:New(addon)
  local obj = {
    addon = addon,
  }

  self.__index = self

  return setmetatable(obj, self)
end

function Bridge:ResolveDisplayCharacterName(rawName)
  local guild = self.addon:GetActiveGuildContext()
  if not guild or type(rawName) ~= "string" or rawName == "" then
    return rawName
  end

  local mapping = self.addon.db:GetAliasMapping(guild.guildKey, rawName)
  if mapping and mapping.canonicalName then
    return mapping.canonicalName
  end

  return rawName
end

function Bridge:GetPendingNominationsViewModel()
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return {}
  end

  local dataset = self.addon.db:GetGuildDataset(guild.guildKey)
  local rows = {}

  for _, nomination in ipairs(dataset.nominations) do
    if nomination.status == "pending" then
      local row = buildRow(nomination, false, self:ResolveDisplayCharacterName(nomination.nominee))
      row.hasCurrentPlayerVoted =
        self.addon.db:GetVote(
          guild.guildKey,
          nomination.nominationId,
          self.addon:GetCurrentPlayerFullName()
        ) ~= nil
      row.canVote = not row.hasCurrentPlayerVoted
      row.canModerate = self:CanCurrentPlayerManageNominations()
      rows[#rows + 1] = row
    end
  end

  return rows
end

function Bridge:GetAdminNominationsViewModel()
  if not self:CanCurrentPlayerManageAddonPermissions() then
    return {}
  end

  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return {}
  end

  local dataset = self.addon.db:GetGuildDataset(guild.guildKey)
  local rows = {}

  for _, nomination in ipairs(dataset.nominations) do
    rows[#rows + 1] = buildRow(nomination, true, self:ResolveDisplayCharacterName(nomination.nominee))
  end

  return rows
end

function Bridge:GetPublicHistoryViewModel()
  local rows = {}
  local canDelete = self:CanCurrentPlayerDeleteAwards()

  for _, award in ipairs(self.addon.awards:GetPublicHistory()) do
    rows[#rows + 1] = {
      awardId = award.awardId,
      awardName = award.awardName,
      awardType = Utils.NormalizeAwardType(award.awardType),
      awardIconPath = getAwardTypeMediaPath(award.awardType),
      recipient = self:ResolveDisplayCharacterName(award.recipient),
      shortRecipient = Utils.GetShortCharacterName(self:ResolveDisplayCharacterName(award.recipient)),
      reason = award.reason,
      awardedBy = award.awardedBy,
      displayAwardedBy = getShortName(award.awardedBy),
      source = award.source,
      createdAt = award.createdAt or 0,
      dateText = self.addon.Time:FormatDate(award.createdAt),
      canDelete = canDelete,
    }
  end

  table.sort(rows, sortDescendingByCreatedAt)

  return rows
end

function Bridge:GetLeaderboardViewModel(mode)
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return {}
  end

  local selectedMode = mode or "combined"
  local dataset = self.addon.db:GetGuildDataset(guild.guildKey)
  local grouped = {}
  local rows = {}

  for _, award in ipairs(dataset.awards or {}) do
    local recipient = self:ResolveDisplayCharacterName(award.recipient or award.player)
    local normalizedAwardType = Utils.NormalizeAwardType(award.awardType)
    local includeAward = selectedMode == "combined"
      or selectedMode == normalizedAwardType

    if recipient and includeAward then
      grouped[recipient] = grouped[recipient] or {
        recipient = recipient,
        shortRecipient = Utils.GetShortCharacterName(recipient),
        pinCount = 0,
        burntCount = 0,
        goldenCount = 0,
        totalCount = 0,
        mostRecentAwardAt = 0,
        mostRecentAwardText = "",
        entries = {},
      }

      local nomination = nil
      if award.source == "nomination" and award.nominationId then
        nomination = self.addon.db:GetNomination(guild.guildKey, award.nominationId)
      end

      local displayAwardedBy = award.awardedBy
      if nomination and nomination.nominatedBy then
        displayAwardedBy = nomination.nominatedBy
      end
      displayAwardedBy = getShortName(displayAwardedBy)

      grouped[recipient].totalCount = grouped[recipient].totalCount + 1
      if normalizedAwardType == Constants.AWARD_TYPE_GOLDEN then
        grouped[recipient].goldenCount = grouped[recipient].goldenCount + 1
      else
        grouped[recipient].burntCount = grouped[recipient].burntCount + 1
      end
      if selectedMode == "combined" then
        grouped[recipient].pinCount = grouped[recipient].totalCount
      elseif normalizedAwardType == Constants.AWARD_TYPE_GOLDEN then
        grouped[recipient].pinCount = grouped[recipient].goldenCount
      else
        grouped[recipient].pinCount = grouped[recipient].burntCount
      end
      grouped[recipient].mostRecentAwardAt = math.max(
        grouped[recipient].mostRecentAwardAt or 0,
        award.createdAt or 0
      )
      grouped[recipient].entries[#grouped[recipient].entries + 1] = {
        awardId = award.awardId,
        awardType = normalizedAwardType,
        awardIconPath = getAwardTypeMediaPath(normalizedAwardType),
        dateText = self.addon.Time:FormatDate(award.createdAt),
        createdAt = award.createdAt or 0,
        reason = award.reason,
        displayAwardedBy = displayAwardedBy,
      }
    end
  end

  for _, row in pairs(grouped) do
    table.sort(row.entries, sortDescendingByCreatedAt)
    row.mostRecentAwardText = self.addon.Time:FormatDate(row.mostRecentAwardAt)
    rows[#rows + 1] = row
  end

  table.sort(rows, function(left, right)
    if left.pinCount ~= right.pinCount then
      return left.pinCount > right.pinCount
    end

    if left.mostRecentAwardAt ~= right.mostRecentAwardAt then
      return left.mostRecentAwardAt > right.mostRecentAwardAt
    end

    return left.recipient < right.recipient
  end)

  return rows
end

function Bridge:CanCurrentPlayerManageAwards()
  if not self.addon.permissions then
    return false
  end

  return self.addon.permissions:CanManageAwards()
end

function Bridge:CanCurrentPlayerManageNominations()
  return self.addon.permissions and self.addon.permissions:CanManageNominations() or false
end

function Bridge:CanCurrentPlayerCreateDirectAwards()
  return self.addon.permissions and self.addon.permissions:CanCreateDirectAwards() or false
end

function Bridge:CanCurrentPlayerDeleteAwards()
  return self.addon.permissions and self.addon.permissions:CanDeleteAwards() or false
end

function Bridge:CanCurrentPlayerManageAddonPermissions()
  return self.addon.permissions and self.addon.permissions:CanManageAddonPermissions() or false
end

function Bridge:GetDashboardViewModel()
  local nominations = self:GetPendingNominationsViewModel()
  local history = self:GetPublicHistoryViewModel()
  local leaderboard = self:GetLeaderboardViewModel("combined")
  local leaderboardRows = {}

  for index, row in ipairs(leaderboard or {}) do
    if index > 5 then
      break
    end

    leaderboardRows[#leaderboardRows + 1] = {
      rank = index,
      recipient = row.recipient,
      shortRecipient = row.shortRecipient,
      pinCount = row.pinCount,
      burntCount = row.burntCount,
      goldenCount = row.goldenCount,
      mostRecentAwardText = row.mostRecentAwardText,
    }
  end

  local latestAward = history[1]

  return {
    canManageAwards = self:CanCurrentPlayerManageAwards(),
    canManageNominations = self:CanCurrentPlayerManageNominations(),
    canCreateDirectAwards = self:CanCurrentPlayerCreateDirectAwards(),
    pendingNominations = copyRows(nominations),
    pendingCount = #nominations,
    recentAwards = copyRows(history),
    awardCount = #history,
    leaderboardRows = leaderboardRows,
    topRecipient = leaderboardRows[1] and leaderboardRows[1].shortRecipient or nil,
    topRecipientCount = leaderboardRows[1] and leaderboardRows[1].pinCount or 0,
    latestAwardRecipient = latestAward and latestAward.shortRecipient or nil,
  }
end

function Bridge:GetRankPermissionsViewModel()
  local rows = {}

  if self.addon.permissions then
    for _, row in ipairs(self.addon.permissions:GetGuildRankMatrix()) do
      rows[#rows + 1] = copyMatrixRow(row)
    end
  end

  return {
    canManageMatrix = self:CanCurrentPlayerManageAddonPermissions(),
    rows = rows,
  }
end

function Bridge:GetAliasMappingsViewModel()
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return {
      canManageAliases = self:CanCurrentPlayerManageAddonPermissions(),
      rows = {},
    }
  end

  return {
    canManageAliases = self:CanCurrentPlayerManageAddonPermissions(),
    rows = self.addon.db:GetAliasMappings(guild.guildKey) or {},
  }
end

function Bridge:GetSyncPeersViewModel()
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return {
      rows = {},
    }
  end

  local rows = {}

  for _, peer in ipairs(self.addon.db:GetSyncPeers(guild.guildKey) or {}) do
    rows[#rows + 1] = {
      player = peer.player,
      shortPlayer = Utils.GetShortCharacterName(peer.player),
      lastSeenAt = peer.lastSeenAt or 0,
      lastSeenText = self.addon.Time:FormatDate(peer.lastSeenAt),
    }
  end

  return {
    rows = rows,
  }
end

function Bridge:GetGuildRosterNameSuggestions(query, limit)
  local matches = {}
  local normalizedQuery = Utils.NormalizeAliasKey(trim(query))
  if not normalizedQuery or normalizedQuery == "" then
    return matches
  end

  local count = 0
  if type(_G.GetNumGuildMembers) == "function" then
    count = _G.GetNumGuildMembers() or 0
  end

  for index = 1, count do
    local name = _G.GetGuildRosterInfo and _G.GetGuildRosterInfo(index)
    if type(name) == "string" and name ~= "" then
      local normalizedName = Utils.NormalizeAliasKey(name)
      local shortName = getShortName(name)
      local normalizedShort = Utils.NormalizeAliasKey(shortName)
      if (normalizedName and normalizedName:find(normalizedQuery, 1, true) == 1)
        or (normalizedShort and normalizedShort:find(normalizedQuery, 1, true) == 1) then
        matches[#matches + 1] = {
          name = name,
          shortName = shortName,
        }
        if #matches >= (limit or 5) then
          break
        end
      end
    end
  end

  return matches
end

function Bridge:SubmitNomination(nominee, reason, awardType)
  return self.addon.nominations:Create(nominee, reason, awardType)
end

function Bridge:CastVote(nominationId, voteType)
  return self.addon.nominations:CastVote(nominationId, voteType)
end

function Bridge:ApproveNomination(nominationId)
  return self.addon.nominations:Approve(nominationId)
end

function Bridge:RejectNomination(nominationId)
  return self.addon.nominations:Reject(nominationId)
end

function Bridge:CreateDirectAward(recipient, reason, awardType)
  return self.addon.awards:CreateDirectAward(recipient, reason, awardType)
end

function Bridge:DeleteAward(awardId)
  return self.addon.awards:DeleteAward(awardId)
end

function Bridge:SaveAliasMapping(aliasDisplay, canonicalName)
  if not self:CanCurrentPlayerManageAddonPermissions() then
    return false, "unauthorized"
  end

  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return false, "missing guild context"
  end

  aliasDisplay = trim(aliasDisplay)
  canonicalName = trim(canonicalName)

  local aliasKey = Utils.NormalizeAliasKey(aliasDisplay)
  if not aliasKey then
    return false, "missing alias"
  end

  if type(canonicalName) ~= "string" or canonicalName == "" then
    return false, "missing canonical name"
  end

  if not canonicalName:find("-", 1, true) then
    return false, "canonical name must include realm"
  end

  local row, err = self.addon.db:UpsertAliasMapping(guild.guildKey, {
    aliasKey = aliasKey,
    aliasDisplay = aliasDisplay,
    canonicalName = canonicalName,
    createdBy = self.addon:GetCurrentPlayerFullName(),
    createdAt = self.addon.Time:Now(),
  })
  if not row then
    return false, err
  end

  if self.addon.sync then
    self.addon.sync:Broadcast("alias_mapping", {
      guildKey = guild.guildKey,
      aliasKey = row.aliasKey,
      aliasDisplay = row.aliasDisplay,
      canonicalName = row.canonicalName,
      createdBy = row.createdBy,
      createdAt = row.createdAt,
      lastModifiedBy = self.addon:GetCurrentPlayerFullName(),
      lastModifiedAt = self.addon.Time:Now(),
    }, "GUILD")
  end

  return row, nil
end

function Bridge:DeleteAliasMapping(aliasKey)
  if not self:CanCurrentPlayerManageAddonPermissions() then
    return false, "unauthorized"
  end

  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return false, "missing guild context"
  end

  local mapping = self.addon.db:GetAliasMapping(guild.guildKey, aliasKey)
  local deleted, err = self.addon.db:DeleteAliasMapping(guild.guildKey, aliasKey)
  if not deleted then
    return false, err
  end

  if self.addon.sync then
    self.addon.sync:Broadcast("alias_mapping", {
      guildKey = guild.guildKey,
      aliasKey = Utils.NormalizeAliasKey(aliasKey),
      aliasDisplay = mapping and mapping.aliasDisplay or aliasKey,
      canonicalName = mapping and mapping.canonicalName or nil,
      deleted = true,
      lastModifiedBy = self.addon:GetCurrentPlayerFullName(),
      lastModifiedAt = self.addon.Time:Now(),
    }, "GUILD")
  end

  return true, nil
end

function Bridge:SaveRankPermissions(rankIndex, rankName, permissions)
  if not self.addon.permissions then
    return false
  end

  return self.addon.permissions:SetRankPermissions(rankIndex, rankName, permissions)
end

return RPA.UIBridge

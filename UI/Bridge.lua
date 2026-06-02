local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Bridge = RPA.UIBridge or {}
RPA.UIBridge = Bridge

local function copyRows(input)
  local output = {}

  for index, row in ipairs(input or {}) do
    output[index] = row
  end

  return output
end

local function buildRow(nomination, includeModeration)
  local row = {
    nominationId = nomination.nominationId,
    nominee = nomination.nominee,
    reason = nomination.reason,
    nominatedBy = nomination.nominatedBy,
    status = nomination.status,
    upvotes = nomination.upvoteCount or 0,
    hasCurrentPlayerVoted = false,
  }

  if includeModeration then
    row.downvotes = nomination.downvoteCount or 0
    row.moderationFlagged = nomination.moderationFlagged == true
  end

  return row
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

function Bridge:New(addon)
  local obj = {
    addon = addon,
  }

  self.__index = self

  return setmetatable(obj, self)
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
      local row = buildRow(nomination, false)
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
    rows[#rows + 1] = buildRow(nomination, true)
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
      recipient = award.recipient,
      reason = award.reason,
      awardedBy = award.awardedBy,
      source = award.source,
      canDelete = canDelete,
    }
  end

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

function Bridge:GetSettingsViewModel()
  local settings = self.addon.db.storage.profile.settings or {}

  return {
    tooltipEnabled = settings.tooltipEnabled == true,
    announceAwards = settings.announceAwards == true,
    debug = settings.debug == true,
  }
end

function Bridge:GetDashboardViewModel()
  local nominations = self:GetPendingNominationsViewModel()
  local history = self:GetPublicHistoryViewModel()

  return {
    canManageAwards = self:CanCurrentPlayerManageAwards(),
    canManageNominations = self:CanCurrentPlayerManageNominations(),
    canCreateDirectAwards = self:CanCurrentPlayerCreateDirectAwards(),
    pendingNominations = copyRows(nominations),
    pendingCount = #nominations,
    recentAwards = copyRows(history),
    awardCount = #history,
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

function Bridge:SubmitNomination(nominee, reason)
  return self.addon.nominations:Create(nominee, reason)
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

function Bridge:CreateDirectAward(recipient, reason)
  return self.addon.awards:CreateDirectAward(recipient, reason)
end

function Bridge:DeleteAward(awardId)
  return self.addon.awards:DeleteAward(awardId)
end

function Bridge:SaveRankPermissions(rankIndex, rankName, permissions)
  if not self.addon.permissions then
    return false
  end

  return self.addon.permissions:SetRankPermissions(rankIndex, rankName, permissions)
end

function Bridge:SaveSettings(updatedSettings)
  local settings = self.addon.db.storage.profile.settings or {}
  self.addon.db.storage.profile.settings = settings

  if updatedSettings.tooltipEnabled ~= nil then
    settings.tooltipEnabled = updatedSettings.tooltipEnabled == true
  end

  if updatedSettings.announceAwards ~= nil then
    settings.announceAwards = updatedSettings.announceAwards == true
  end

  if updatedSettings.debug ~= nil then
    settings.debug = updatedSettings.debug == true
  end

  return true
end

return RPA.UIBridge

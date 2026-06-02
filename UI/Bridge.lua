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
      row.canModerate = self:CanCurrentPlayerManageAwards()
      rows[#rows + 1] = row
    end
  end

  return rows
end

function Bridge:GetAdminNominationsViewModel()
  if not self.addon.permissions or not self.addon.permissions:CanManageAwards() then
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

  for _, award in ipairs(self.addon.awards:GetPublicHistory()) do
    rows[#rows + 1] = {
      awardId = award.awardId,
      awardName = award.awardName,
      recipient = award.recipient,
      reason = award.reason,
      awardedBy = award.awardedBy,
      source = award.source,
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
    pendingNominations = copyRows(nominations),
    pendingCount = #nominations,
    recentAwards = copyRows(history),
    awardCount = #history,
  }
end

function Bridge:GetOfficerRosterViewModel()
  local granted = {}
  local eligible = {}

  if self.addon.permissions then
    granted = self.addon.permissions:GetGrantedOfficerPermissions()

    for _, row in ipairs(self.addon.permissions:GetEligibleOfficers()) do
      if not row.hasPermission then
        eligible[#eligible + 1] = row
      end
    end
  end

  return {
    canManageRoster = self.addon.permissions and self.addon.permissions:IsGuildMaster() or false,
    eligible = eligible,
    granted = granted,
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

function Bridge:GrantOfficerPermission(playerFullName)
  if not self.addon.permissions then
    return false
  end

  return self.addon.permissions:GrantOfficerPermission(playerFullName)
end

function Bridge:RevokeOfficerPermission(playerFullName)
  if not self.addon.permissions then
    return false
  end

  return self.addon.permissions:RevokeOfficerPermission(playerFullName)
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

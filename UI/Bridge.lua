local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Bridge = RPA.UIBridge or {}
RPA.UIBridge = Bridge

local function buildRow(nomination, includeModeration)
  local row = {
    nominationId = nomination.nominationId,
    nominee = nomination.nominee,
    reason = nomination.reason,
    nominatedBy = nomination.nominatedBy,
    status = nomination.status,
    upvotes = nomination.upvoteCount or 0,
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
      rows[#rows + 1] = buildRow(nomination, false)
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

return RPA.UIBridge

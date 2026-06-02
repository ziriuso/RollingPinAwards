local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Tooltip = RPA.Tooltip or {}
RPA.Tooltip = Tooltip

function Tooltip:New(addon)
  local obj = {
    addon = addon,
  }

  self.__index = self

  return setmetatable(obj, self)
end

function Tooltip:BuildPlayerSummary(playerFullName)
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return {
      awards = 0,
      pendingNominations = 0,
    }
  end

  local dataset = self.addon.db:GetGuildDataset(guild.guildKey)
  local awards = 0
  local pendingNominations = 0

  for _, award in ipairs(dataset.awards) do
    if award.recipient == playerFullName or award.player == playerFullName then
      awards = awards + 1
    end
  end

  for _, nomination in ipairs(dataset.nominations) do
    if nomination.nominee == playerFullName and nomination.status == "pending" then
      pendingNominations = pendingNominations + 1
    end
  end

  return {
    awards = awards,
    pendingNominations = pendingNominations,
  }
end

return RPA.Tooltip

local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Constants = RPA.Constants or {
  DISPLAY_AWARD_NAME = "The Burnt Rolling Pin",
}
local Utils = RPA.Utils or {}

local Awards = RPA.Awards or {}
RPA.Awards = Awards

local function isMissingString(value)
  return type(value) ~= "string" or value == ""
end

local function currentTimestamp(addon)
  if addon and addon.Time and type(addon.Time.Now) == "function" then
    return addon.Time:Now()
  end

  return 0
end

function Awards:New(addon)
  local obj = {
    addon = addon,
  }

  self.__index = self

  return setmetatable(obj, self)
end

function Awards:BuildAward(recipient, reason, source, nominationId, awardType)
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return nil, "missing guild context"
  end

  local awardId = self.addon.db:NextAwardId(guild.guildKey)
  local now = currentTimestamp(self.addon)
  local normalizedAwardType = Utils.NormalizeAwardType(awardType)

  return {
    awardId = awardId,
    guildKey = guild.guildKey,
    awardName = Utils.GetAwardDisplayName(normalizedAwardType),
    awardType = normalizedAwardType,
    recipient = recipient,
    player = recipient,
    reason = reason,
    awardedBy = self.addon:GetCurrentPlayerFullName(),
    source = source,
    nominationId = nominationId,
    createdAt = now,
    lastModifiedAt = now,
    lastModifiedBy = self.addon:GetCurrentPlayerFullName(),
  }, nil
end

function Awards:CreateFromNomination(nomination)
  local award, err = self:BuildAward(
    nomination.nominee,
    nomination.reason,
    "nomination",
    nomination.nominationId,
    nomination.awardType
  )
  if not award then
    return nil, err
  end

  self.addon.db:UpsertAward(nomination.guildKey, award)

  return award
end

function Awards:CreateDirectAward(recipient, reason, awardType)
  if isMissingString(recipient) or isMissingString(reason) then
    return nil, "missing award fields"
  end

  if not self.addon.permissions or not self.addon.permissions:CanCreateDirectAwards() then
    return nil, "unauthorized"
  end

  local award, err = self:BuildAward(recipient, reason, "direct", nil, awardType)
  if not award then
    return nil, err
  end

  self.addon.db:UpsertAward(award.guildKey, award)

  return award
end

function Awards:DeleteAward(awardId)
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return false, "missing guild context"
  end

  if not self.addon.permissions or not self.addon.permissions:CanDeleteAwards() then
    return false, "unauthorized"
  end

  local award = self.addon.db:GetAward(guild.guildKey, awardId)
  if not award then
    return false, "missing award"
  end

  local ok, err = self.addon.db:DeleteAward(guild.guildKey, awardId)
  if not ok then
    return false, err
  end

  if award.nominationId then
    local deletedNomination, nominationErr = self.addon.db:DeleteNomination(
      guild.guildKey,
      award.nominationId
    )
    if not deletedNomination and nominationErr ~= "missing nomination" then
      return false, nominationErr
    end
  end

  return true
end

function Awards:GetPublicHistory()
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return {}
  end

  local dataset = self.addon.db:GetGuildDataset(guild.guildKey)

  return dataset.awards
end

return RPA.Awards

local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Constants = RPA.Constants or {
  DISPLAY_AWARD_NAME = "The Burnt Rolling Pin",
}

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

function Awards:BuildAward(recipient, reason, source, nominationId)
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return nil, "missing guild context"
  end

  local awardId = self.addon.db:NextAwardId(guild.guildKey)
  local now = currentTimestamp(self.addon)

  return {
    awardId = awardId,
    guildKey = guild.guildKey,
    awardName = Constants.DISPLAY_AWARD_NAME,
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
    nomination.nominationId
  )
  if not award then
    return nil, err
  end

  self.addon.db:UpsertAward(nomination.guildKey, award)

  return award
end

function Awards:CreateDirectAward(recipient, reason)
  if isMissingString(recipient) or isMissingString(reason) then
    return nil, "missing award fields"
  end

  if not self.addon.permissions or not self.addon.permissions:CanManageAwards() then
    return nil, "unauthorized"
  end

  local award, err = self:BuildAward(recipient, reason, "direct", nil)
  if not award then
    return nil, err
  end

  self.addon.db:UpsertAward(award.guildKey, award)

  return award
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

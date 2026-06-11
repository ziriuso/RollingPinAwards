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

  local now = currentTimestamp(self.addon)
  local actor = self.addon:GetCurrentPlayerFullName()
  local awardId = self.addon.db:NextAwardId(guild.guildKey, actor, now)
  local normalizedAwardType = Utils.NormalizeAwardType(awardType)

  return {
    awardId = awardId,
    guildKey = guild.guildKey,
    awardName = Utils.GetAwardDisplayName(normalizedAwardType),
    awardType = normalizedAwardType,
    recipient = recipient,
    player = recipient,
    reason = reason,
    awardedBy = actor,
    source = source,
    nominationId = nominationId,
    createdAt = now,
    lastModifiedAt = now,
    lastModifiedBy = actor,
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

  if self.addon.sync then
    self.addon.sync:Broadcast("award", award, "GUILD")
  end

  if self.addon.notifications and type(self.addon.notifications.AnnounceAward) == "function" then
    self.addon.notifications:AnnounceAward(award)
  end

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

  local now = currentTimestamp(self.addon)
  local actor = self.addon:GetCurrentPlayerFullName()
  local ok, err = self.addon.db:DeleteAward(guild.guildKey, awardId, {
    guildKey = guild.guildKey,
    awardId = award.awardId,
    source = award.source,
    nominationId = award.nominationId,
    deleted = true,
    lastModifiedAt = now,
    lastModifiedBy = actor,
  })
  if not ok then
    return false, err
  end

  if award.nominationId then
    local deletedNomination, nominationErr = self.addon.db:DeleteNomination(
      guild.guildKey,
      award.nominationId,
      {
        guildKey = guild.guildKey,
        nominationId = award.nominationId,
        status = "deleted",
        awardId = award.awardId,
        deleted = true,
        lastModifiedAt = now,
        lastModifiedBy = actor,
      }
    )
    if not deletedNomination and nominationErr ~= "missing nomination" then
      return false, nominationErr
    end
  end

  if self.addon.sync then
    self.addon.sync:Broadcast("award", {
      guildKey = guild.guildKey,
      awardId = award.awardId,
      source = award.source,
      nominationId = award.nominationId,
      deleted = true,
      lastModifiedAt = now,
      lastModifiedBy = actor,
    }, "GUILD")
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

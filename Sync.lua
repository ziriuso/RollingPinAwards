local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Sync = RPA.Sync or {}
RPA.Sync = Sync

local function isMissingString(value)
  return type(value) ~= "string" or value == ""
end

function Sync:New(addon)
  local obj = {
    addon = addon,
  }

  self.__index = self

  return setmetatable(obj, self)
end

function Sync:IsActiveGuildPayload(guildKey)
  local guild = self.addon:GetActiveGuildContext()

  return guild ~= nil and guild.guildKey == guildKey
end

function Sync:AcceptAward(award)
  if type(award) ~= "table" or isMissingString(award.awardId) then
    return false, "missing award"
  end

  if not self:IsActiveGuildPayload(award.guildKey) then
    return false, "wrong guild"
  end

  if not self.addon.permissions or not self.addon.permissions:CanManageAwards(award.awardedBy) then
    return false, "unauthorized"
  end

  self.addon.db:UpsertAward(award.guildKey, award)

  return true
end

function Sync:AcceptNomination(nomination)
  if type(nomination) ~= "table" or isMissingString(nomination.nominationId) then
    return false, "missing nomination"
  end

  if not self:IsActiveGuildPayload(nomination.guildKey) then
    return false, "wrong guild"
  end

  if nomination.status ~= "pending" then
    local actor = nomination.lastModifiedBy or nomination.resolvedBy
    if not self.addon.permissions or not self.addon.permissions:CanManageAwards(actor) then
      return false, "unauthorized"
    end
  end

  self.addon.db:UpsertNomination(nomination.guildKey, nomination)

  return true
end

function Sync:AcceptNominationVote(vote)
  if type(vote) ~= "table" or isMissingString(vote.nominationId) then
    return false, "missing vote"
  end

  if not self:IsActiveGuildPayload(vote.guildKey) then
    return false, "wrong guild"
  end

  local nomination = self.addon.db:GetNomination(vote.guildKey, vote.nominationId)
  if not nomination or nomination.status ~= "pending" then
    return false, "nomination closed"
  end

  if self.addon.db:GetVote(vote.guildKey, vote.nominationId, vote.voter) then
    return false, "duplicate vote"
  end

  self.addon.db:StoreVote(vote.guildKey, vote.nominationId, vote)
  self.addon.nominations:RefreshVoteSummary(nomination)

  return true
end

function Sync:AcceptPermissionRosterEntry(update)
  if type(update) ~= "table" or isMissingString(update.player) then
    return false, "missing roster update"
  end

  if not self:IsActiveGuildPayload(update.guildKey) then
    return false, "wrong guild"
  end

  if not self.addon.permissions or not self.addon.permissions:IsGuildMaster(update.grantedBy) then
    return false, "unauthorized"
  end

  self.addon.db:UpsertPermissionRosterEntry(update.guildKey, update)

  return true
end

return RPA.Sync

local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Constants = RPA.Constants or {
  MODERATION_DOWNVOTE_THRESHOLD = 3,
}
local Utils = RPA.Utils or {}

local Nominations = RPA.Nominations or {}
RPA.Nominations = Nominations

local function isMissingString(value)
  return type(value) ~= "string" or value == ""
end

local function currentTimestamp(addon)
  if addon and addon.Time and type(addon.Time.Now) == "function" then
    return addon.Time:Now()
  end

  return 0
end

function Nominations:New(addon)
  local obj = {
    addon = addon,
  }

  self.__index = self

  return setmetatable(obj, self)
end

function Nominations:RefreshVoteSummary(nomination)
  local votes = self.addon.db:GetVotesForNomination(
    nomination.guildKey,
    nomination.nominationId
  ) or {}
  local upvoteCount = 0
  local downvoteCount = 0

  for _, vote in pairs(votes) do
    if vote.voteType == "upvote" then
      upvoteCount = upvoteCount + 1
    elseif vote.voteType == "downvote" then
      downvoteCount = downvoteCount + 1
    end
  end

  nomination.upvoteCount = upvoteCount
  nomination.downvoteCount = downvoteCount
  nomination.moderationFlagged =
    downvoteCount >= Constants.MODERATION_DOWNVOTE_THRESHOLD
  nomination.lastModifiedAt = currentTimestamp(self.addon)
  nomination.lastModifiedBy = self.addon:GetCurrentPlayerFullName()

  self.addon.db:UpsertNomination(nomination.guildKey, nomination)

  return nomination
end

function Nominations:Create(nominee, reason, awardType)
  if isMissingString(nominee) or isMissingString(reason) then
    return nil, "missing nomination fields"
  end

  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return nil, "missing guild context"
  end

  local now = currentTimestamp(self.addon)
  local nominationId = self.addon.db:NextNominationId(guild.guildKey)
  local nomination = {
    nominationId = nominationId,
    guildKey = guild.guildKey,
    nominee = nominee,
    reason = reason,
    awardType = Utils.NormalizeAwardType(awardType),
    nominatedBy = self.addon:GetCurrentPlayerFullName(),
    status = "pending",
    upvoteCount = 0,
    downvoteCount = 0,
    moderationFlagged = false,
    createdAt = now,
    lastModifiedAt = now,
    lastModifiedBy = self.addon:GetCurrentPlayerFullName(),
  }

  self.addon.db:UpsertNomination(guild.guildKey, nomination)

  return nomination
end

function Nominations:CastVote(nominationId, voteType)
  if voteType ~= "upvote" and voteType ~= "downvote" then
    return false, "invalid voteType"
  end

  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return false, "missing guild context"
  end

  local nomination = self.addon.db:GetNomination(guild.guildKey, nominationId)
  if not nomination then
    return false, "missing nomination"
  end

  if nomination.status ~= "pending" then
    return false, "nomination closed"
  end

  local voter = self.addon:GetCurrentPlayerFullName()
  if self.addon.db:GetVote(guild.guildKey, nominationId, voter) then
    return false, "vote already cast"
  end

  self.addon.db:StoreVote(guild.guildKey, nominationId, {
    nominationId = nominationId,
    voter = voter,
    voteType = voteType,
    createdAt = currentTimestamp(self.addon),
  })

  self:RefreshVoteSummary(nomination)

  return true
end

function Nominations:Approve(nominationId)
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return nil, "missing guild context"
  end

  if not self.addon.permissions or not self.addon.permissions:CanManageNominations() then
    return nil, "unauthorized"
  end

  local nomination = self.addon.db:GetNomination(guild.guildKey, nominationId)
  if not nomination then
    return nil, "missing nomination"
  end

  if nomination.status ~= "pending" then
    return nil, "nomination closed"
  end

  local now = currentTimestamp(self.addon)
  nomination.status = "approved"
  nomination.resolvedBy = self.addon:GetCurrentPlayerFullName()
  nomination.resolvedAt = now
  nomination.lastModifiedAt = now
  nomination.lastModifiedBy = nomination.resolvedBy

  local award = self.addon.awards:CreateFromNomination(nomination)
  nomination.awardId = award.awardId
  self.addon.db:UpsertNomination(guild.guildKey, nomination)

  return award
end

function Nominations:Reject(nominationId)
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    return false, "missing guild context"
  end

  if not self.addon.permissions or not self.addon.permissions:CanManageNominations() then
    return false, "unauthorized"
  end

  local nomination = self.addon.db:GetNomination(guild.guildKey, nominationId)
  if not nomination then
    return false, "missing nomination"
  end

  if nomination.status ~= "pending" then
    return false, "nomination closed"
  end

  local now = currentTimestamp(self.addon)
  nomination.status = "rejected"
  nomination.resolvedBy = self.addon:GetCurrentPlayerFullName()
  nomination.resolvedAt = now
  nomination.lastModifiedAt = now
  nomination.lastModifiedBy = nomination.resolvedBy

  self.addon.db:UpsertNomination(guild.guildKey, nomination)

  return true
end

return RPA.Nominations

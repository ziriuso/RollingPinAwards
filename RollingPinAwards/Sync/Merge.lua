local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Sync = RPA.Sync or {}
RPA.Sync = Sync

local function isMissingString(value)
  return type(value) ~= "string" or value == ""
end

local function recordTimestamp(record)
  return tonumber((record or {}).lastModifiedAt or (record or {}).resolvedAt or (record or {}).createdAt or 0) or 0
end

local function nominationStatusRank(status)
  if status == "deleted" then
    return 4
  end

  if status == "approved" then
    return 3
  end

  if status == "rejected" then
    return 2
  end

  if status == "pending" then
    return 1
  end

  return 0
end

local function nominationIdentityDiffers(left, right)
  return tostring((left or {}).nominee or "") ~= tostring((right or {}).nominee or "")
    or tostring((left or {}).reason or "") ~= tostring((right or {}).reason or "")
    or tostring((left or {}).nominatedBy or "") ~= tostring((right or {}).nominatedBy or "")
end

local function awardIdentityDiffers(left, right)
  return tostring((left or {}).recipient or (left or {}).player or "") ~= tostring((right or {}).recipient or (right or {}).player or "")
    or tostring((left or {}).reason or "") ~= tostring((right or {}).reason or "")
    or tostring((left or {}).awardedBy or "") ~= tostring((right or {}).awardedBy or "")
end

local function shouldApplyNomination(existing, incoming)
  if type(existing) ~= "table" then
    return true
  end

  local existingAt = recordTimestamp(existing)
  local incomingAt = recordTimestamp(incoming)
  if incomingAt < existingAt then
    return false, "stale nomination"
  end

  if incomingAt == existingAt then
    local existingRank = nominationStatusRank(existing.status)
    local incomingRank = nominationStatusRank(incoming.status)
    if incomingRank < existingRank then
      return false, "stale nomination"
    end

    if incomingRank == existingRank and nominationIdentityDiffers(existing, incoming) then
      return false, "stale nomination"
    end

    if not incoming.awardId and existing.awardId then
      return false, "stale nomination"
    end
  end

  return true
end

local function shouldApplyAward(existing, incoming)
  if type(existing) ~= "table" then
    return true
  end

  local existingAt = recordTimestamp(existing)
  local incomingAt = recordTimestamp(incoming)
  if incomingAt < existingAt then
    return false, "stale award"
  end

  if incomingAt == existingAt and awardIdentityDiffers(existing, incoming) then
    return false, "stale award"
  end

  return true
end

local function findAwardByNominationId(dataset, nominationId)
  if isMissingString(nominationId) then
    return nil
  end

  for _, award in pairs((dataset or {}).awardsById or {}) do
    if award.deleted ~= true and award.source == "nomination" and award.nominationId == nominationId then
      return award
    end
  end

  return nil
end

local function closeNominationForAward(addon, award, actor)
  if type(addon) ~= "table" or type(award) ~= "table" then
    return true
  end

  if award.deleted == true or award.source ~= "nomination" or isMissingString(award.nominationId) then
    return true
  end

  local existingNomination = addon.db:GetNomination(award.guildKey, award.nominationId, true)
  if type(existingNomination) ~= "table" then
    return true
  end

  if existingNomination.deleted == true or existingNomination.status ~= "pending" then
    return true
  end

  local deleted, err = addon.db:DeleteNomination(
    award.guildKey,
    award.nominationId,
    {
      guildKey = award.guildKey,
      nominationId = award.nominationId,
      status = "deleted",
      awardId = award.awardId,
      deleted = true,
      lastModifiedAt = award.lastModifiedAt or recordTimestamp(award),
      lastModifiedBy = actor,
    }
  )

  if not deleted then
    return false, err
  end

  return true
end

function Sync:AcceptAward(award)
  if type(award) ~= "table" or isMissingString(award.awardId) then
    return false, "missing award"
  end

  if not self:IsActiveGuildPayload(award.guildKey) then
    return false, "wrong guild"
  end

  local actor = award.lastModifiedBy or award.awardedBy
  local isAuthorized = false

  if self.addon.permissions then
    if award.deleted == true then
      isAuthorized = self.addon.permissions:CanDeleteAwards(actor)
    elseif award.source == "nomination" then
      isAuthorized = self.addon.permissions:CanManageNominations(actor)
    elseif award.source == "direct" then
      isAuthorized = self.addon.permissions:CanCreateDirectAwards(actor)
    else
      isAuthorized = self.addon.permissions:CanManageAwards(actor)
    end
  end

  if not isAuthorized then
    return false, "unauthorized"
  end

  local existingAward = self.addon.db:GetAward(award.guildKey, award.awardId, true)
  if award.deleted ~= true or award.lastModifiedAt ~= nil then
    local shouldApply, staleErr = shouldApplyAward(existingAward, award)
    if not shouldApply then
      return false, staleErr
    end
  end

  if award.deleted == true then
    award.lastModifiedAt = award.lastModifiedAt or recordTimestamp(existingAward)
    local deleted, deleteErr = self.addon.db:DeleteAward(award.guildKey, award.awardId, award)
    if not deleted then
      return false, deleteErr
    end

    if award.nominationId then
      local deletedNomination, nominationErr = self.addon.db:DeleteNomination(
        award.guildKey,
        award.nominationId,
        {
          guildKey = award.guildKey,
          nominationId = award.nominationId,
          status = "deleted",
          awardId = award.awardId,
          deleted = true,
          lastModifiedAt = award.lastModifiedAt,
          lastModifiedBy = actor,
        }
      )
      if not deletedNomination and nominationErr ~= "missing nomination" then
        return false, nominationErr
      end
    end

    return true
  end

  self.addon.db:UpsertAward(award.guildKey, award)
  local closedNomination, closeErr = closeNominationForAward(self.addon, award, actor)
  if not closedNomination then
    return false, closeErr
  end

  return true
end

function Sync:AcceptNomination(nomination)
  if type(nomination) ~= "table" or isMissingString(nomination.nominationId) then
    return false, "missing nomination"
  end

  if not self:IsActiveGuildPayload(nomination.guildKey) then
    return false, "wrong guild"
  end

  if nomination.deleted == true then
    nomination.status = "deleted"
    local actor = nomination.lastModifiedBy or nomination.resolvedBy
    local canDeleteAwards = self.addon.permissions and self.addon.permissions:CanDeleteAwards(actor)
    local canManageNominations = self.addon.permissions and self.addon.permissions:CanManageNominations(actor)
    if not canDeleteAwards and not canManageNominations then
      return false, "unauthorized"
    end
  elseif nomination.status ~= "pending" then
    local actor = nomination.lastModifiedBy or nomination.resolvedBy
    if not self.addon.permissions or not self.addon.permissions:CanManageNominations(actor) then
      return false, "unauthorized"
    end
  end

  local existingNomination = self.addon.db:GetNomination(nomination.guildKey, nomination.nominationId, true)
  local shouldApply, staleErr = shouldApplyNomination(existingNomination, nomination)
  if not shouldApply then
    return false, staleErr
  end

  if nomination.status == "pending" and nomination.deleted ~= true then
    local dataset = self.addon.db:GetGuildDataset(nomination.guildKey)
    if findAwardByNominationId(dataset, nomination.nominationId) then
      return false, "nomination already awarded"
    end
  end

  if nomination.deleted == true then
    nomination.lastModifiedAt = nomination.lastModifiedAt or recordTimestamp(existingNomination)
    return self.addon.db:DeleteNomination(nomination.guildKey, nomination.nominationId, nomination)
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

function Sync:AcceptRankPermission(update)
  if type(update) ~= "table" or type(update.rankIndex) ~= "number" then
    return false, "missing rank permission update"
  end

  if not self:IsActiveGuildPayload(update.guildKey) then
    return false, "wrong guild"
  end

  local actor = update.lastModifiedBy or update.sender
  if not self.addon.permissions or not self.addon.permissions:CanManageAddonPermissions(actor) then
    return false, "unauthorized"
  end

  self.addon.db:UpsertRankPermission(update.guildKey, update.rankIndex, {
    rankIndex = update.rankIndex,
    rankName = update.rankName,
    canManageNominations = update.canManageNominations == true,
    canCreateDirectAwards = update.canCreateDirectAwards == true,
    canDeleteAwards = update.canDeleteAwards == true,
    canManageAddonPermissions = update.canManageAddonPermissions == true,
    lastModifiedAt = update.lastModifiedAt,
    lastModifiedBy = actor,
  })

  return true
end

function Sync:AcceptAliasMapping(update)
  if type(update) ~= "table" or isMissingString(update.aliasKey) then
    return false, "missing alias mapping update"
  end

  if not self:IsActiveGuildPayload(update.guildKey) then
    return false, "wrong guild"
  end

  local actor = update.lastModifiedBy or update.sender
  if not self.addon.permissions or not self.addon.permissions:CanManageAddonPermissions(actor) then
    return false, "unauthorized"
  end

  if update.deleted == true then
    return self.addon.db:DeleteAliasMapping(update.guildKey, update.aliasKey)
  end

  self.addon.db:UpsertAliasMapping(update.guildKey, {
    aliasKey = update.aliasKey,
    aliasDisplay = update.aliasDisplay,
    canonicalName = update.canonicalName,
    createdBy = update.createdBy or actor,
    createdAt = update.createdAt,
    lastModifiedBy = actor,
    lastModifiedAt = update.lastModifiedAt,
  })

  return true
end

return RPA.Sync

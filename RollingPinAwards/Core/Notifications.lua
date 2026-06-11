local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Notifications = RPA.Notifications or {}
RPA.Notifications = Notifications

local Utils = RPA.Utils or {}

local function lower(value)
  return type(value) == "string" and string.lower(value) or nil
end

local function currentShortName(addon)
  if addon and type(addon.GetCurrentPlayerFullName) == "function" then
    return Utils.GetShortCharacterName(addon:GetCurrentPlayerFullName())
  end

  return nil
end

local function namesMatch(addon, candidate)
  if type(candidate) ~= "string" or candidate == "" or not addon then
    return false
  end

  local currentFull = addon:GetCurrentPlayerFullName()
  local currentShort = currentShortName(addon)
  local candidateShort = Utils.GetShortCharacterName(candidate)

  return lower(candidate) == lower(currentFull)
    or lower(candidate) == lower(currentShort)
    or lower(candidateShort) == lower(currentShort)
end

local function selfOrigin(addon, payload, sender)
  if not addon or type(addon.GetCurrentPlayerFullName) ~= "function" then
    return false
  end

  local current = addon:GetCurrentPlayerFullName()
  return namesMatch(addon, sender)
    or namesMatch(addon, (payload or {}).lastModifiedBy)
    or namesMatch(addon, (payload or {}).awardedBy)
    or namesMatch(addon, (payload or {}).nominatedBy)
    or lower((payload or {}).sender) == lower(current)
end

local function nominationDisplayText(nomination)
  local nominee = Utils.GetShortCharacterName((nomination or {}).nominee or "")
  local reason = (nomination or {}).reason or ""

  if reason ~= "" then
    return ("%s - %s"):format(nominee, reason)
  end

  return nominee
end

local function awardTypeLabel(award)
  local displayName = Utils.GetAwardDisplayName((award or {}).awardType)
  displayName = displayName:gsub("^The%s+", "")

  return displayName
end

local function awardDisplayText(award)
  local recipient = Utils.GetShortCharacterName((award or {}).recipient or (award or {}).player or "")
  local reason = (award or {}).reason or ""
  local label = awardTypeLabel(award)

  if reason ~= "" then
    return ("%s awarded to %s: %s"):format(label, recipient, reason)
  end

  return ("%s awarded to %s"):format(label, recipient)
end

function Notifications:New(addon)
  local obj = {
    addon = addon,
    lastLoginReminderGuildKey = nil,
  }

  self.__index = self

  return setmetatable(obj, self)
end

function Notifications:PrintChatLine(line)
  if type(line) ~= "string" or line == "" then
    return false
  end

  self.addon.__rpaLastChatOutput = self.addon.__rpaLastChatOutput or {}
  self.addon.__rpaLastChatOutput[#self.addon.__rpaLastChatOutput + 1] = line

  if _G.DEFAULT_CHAT_FRAME and type(_G.DEFAULT_CHAT_FRAME.AddMessage) == "function" then
    _G.DEFAULT_CHAT_FRAME:AddMessage(line)
  elseif self.addon and type(self.addon.Print) == "function" then
    self.addon:Print(line)
  elseif type(print) == "function" then
    print(line)
  end

  return true
end

function Notifications:AnnounceAward(award)
  if type(award) ~= "table" or award.deleted == true then
    return false
  end

  local awardId = award.awardId
  if self.addon and self.addon.db and type(self.addon.db.HasSeenAwardChat) == "function" then
    if self.addon.db:HasSeenAwardChat(awardId) then
      return false
    end
  end

  if self.addon and self.addon.db and type(self.addon.db.MarkAwardChatSeen) == "function" then
    self.addon.db:MarkAwardChatSeen(awardId)
  end

  return self:PrintChatLine(("Rolling Pin Awards: %s."):format(awardDisplayText(award)))
end

function Notifications:CurrentPlayerHasVoted(nomination)
  local guildKey = (nomination or {}).guildKey
  local nominationId = (nomination or {}).nominationId
  if not self.addon or not self.addon.db or type(nominationId) ~= "string" then
    return false
  end

  return self.addon.db:GetVote(guildKey, nominationId, self.addon:GetCurrentPlayerFullName()) ~= nil
end

function Notifications:GetPendingUnvotedNominations()
  local guild = self.addon and self.addon:GetActiveGuildContext()
  if not guild or not self.addon.db then
    return {}
  end

  local dataset = self.addon.db:GetGuildDataset(guild.guildKey)
  local rows = {}

  for _, nomination in ipairs(dataset.nominations or {}) do
    if nomination.status == "pending" and nomination.deleted ~= true and not self:CurrentPlayerHasVoted(nomination) then
      rows[#rows + 1] = nomination
    end
  end

  table.sort(rows, function(left, right)
    return tostring(left.createdAt or left.nominationId or "") < tostring(right.createdAt or right.nominationId or "")
  end)

  return rows
end

function Notifications:PrintPendingNominationReminders()
  local guild = self.addon and self.addon:GetActiveGuildContext()
  if not guild then
    return 0
  end

  if self.lastLoginReminderGuildKey == guild.guildKey then
    return 0
  end

  local pending = self:GetPendingUnvotedNominations()
  self.lastLoginReminderGuildKey = guild.guildKey
  if #pending == 0 then
    return 0
  end

  local noun = #pending == 1 and "nomination" or "nominations"
  self:PrintChatLine(
    ("Rolling Pin Awards: You have %d pending %s to vote on. Open /rpa to vote."):format(#pending, noun)
  )

  return #pending
end

function Notifications:HandleAward(payload, sender)
  if type(payload) ~= "table" or payload.deleted == true or selfOrigin(self.addon, payload, sender) then
    return false
  end

  local announced = self:AnnounceAward(payload)

  if not namesMatch(self.addon, payload.recipient or payload.player) then
    return announced
  end

  local awardId = payload.awardId
  if self.addon.db and type(self.addon.db.HasSeenAwardToast) == "function" then
    if self.addon.db:HasSeenAwardToast(awardId) then
      return announced
    end
  end

  if self.addon.db and type(self.addon.db.MarkAwardToastSeen) == "function" then
    self.addon.db:MarkAwardToastSeen(awardId)
  end

  if self.addon.toast and type(self.addon.toast.ShowAwardToast) == "function" then
    return self.addon.toast:ShowAwardToast(payload) or announced
  end

  return announced
end

function Notifications:HandleNomination(payload, sender)
  if type(payload) ~= "table"
    or payload.deleted == true
    or payload.status ~= "pending"
    or selfOrigin(self.addon, payload, sender)
    or self:CurrentPlayerHasVoted(payload)
  then
    return false
  end

  self:PrintChatLine(
    ("Rolling Pin Awards: New %s nomination to vote on: %s. Open /rpa to vote."):format(
      awardTypeLabel(payload),
      nominationDisplayText(payload)
    )
  )

  return true
end

function Notifications:HandleAcceptedInbound(payloadType, payload, sender)
  if payloadType == "award" then
    return self:HandleAward(payload, sender)
  end

  if payloadType == "nomination" then
    return self:HandleNomination(payload, sender)
  end

  return false
end

return RPA.Notifications

local function getOptionalLibrary(libraryName)
  local libStub = rawget(_G, "LibStub")
  local metatable = type(libStub) == "table" and getmetatable(libStub) or nil
  local callable = type(libStub) == "function"
    or (type(metatable) == "table" and type(metatable.__call) == "function")

  if not callable then
    return nil
  end

  local ok, library = pcall(libStub, libraryName, true)
  if not ok then
    return nil
  end

  return library
end

local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Constants = RPA.Constants or {
  ADDON_NAME = "RollingPinAwards",
  DISPLAY_AWARD_NAME = "The Burnt Rolling Pin",
  SLASH_COMMAND = "/rpa",
  PROTOCOL_VERSION = 1,
}
local Defaults = RPA.Defaults or {
  profile = {
    guildDatasets = {},
  },
}
local GuildContext = RPA.GuildContext or {}
local Awards = RPA.Awards or {}
local Commands = RPA.Commands or {}
local Database = RPA.Database
local MainFrame = RPA.MainFrame or {}
local MinimapButton = RPA.MinimapButton or {}
local Nominations = RPA.Nominations or {}
local Notifications = RPA.Notifications or {}
local Permissions = RPA.Permissions or {}
local RosterPermissions = RPA.RosterPermissions or {}
local Sync = RPA.Sync or {}
local Time = RPA.Time or {}
local Toast = RPA.Toast or {}
local Bridge = RPA.UIBridge or {}
local Utils = RPA.Utils

local function currentNormalizedRealm()
  if not Utils or type(Utils.NormalizeRealm) ~= "function" then
    return nil
  end

  if type(GetNormalizedRealmName) == "function" then
    local normalized = Utils.NormalizeRealm(GetNormalizedRealmName())
    if normalized then
      return normalized
    end
  end

  if type(GetRealmName) == "function" then
    return Utils.NormalizeRealm(GetRealmName())
  end

  return nil
end

local function normalizeRosterLookupName(playerFullName)
  if Utils and type(Utils.NormalizeUnitName) == "function" then
    return Utils.NormalizeUnitName(playerFullName, currentNormalizedRealm())
  end

  return playerFullName
end

RPA.Constants = Constants
RPA.Defaults = Defaults
RPA.GuildContext = GuildContext
RPA.Awards = Awards
RPA.Commands = Commands
RPA.Nominations = Nominations
RPA.Notifications = Notifications
RPA.MainFrame = MainFrame
RPA.MinimapButton = MinimapButton
RPA.Permissions = Permissions
RPA.RosterPermissions = RosterPermissions
RPA.Sync = Sync
RPA.Time = Time
RPA.Toast = Toast
RPA.UIBridge = Bridge

RPA.ADDON_NAME = Constants.ADDON_NAME
RPA.SLASH_COMMAND = Constants.SLASH_COMMAND
RPA.defaults = Defaults

function RPA:OnInitialize()
  if self.__rpaInitialized or self.__rpaInitializing then
    return self.__rpaInitialized == true
  end

  self.__rpaInitializing = true
  self.activeGuildContext = nil
  if type(self.GuildContext.Build) == "function" then
    self.activeGuildContext = self.GuildContext:Build()
  end

  local aceDbLibrary = getOptionalLibrary("AceDB-3.0")
  local storage
  if aceDbLibrary and type(aceDbLibrary.New) == "function" then
    self.aceDb = aceDbLibrary:New("RollingPinAwardsDB", self.defaults, true)
    storage = {
      profile = self.aceDb.profile,
    }
  else
    self.aceDb = nil
    storage = _G.RollingPinAwardsDB
    storage = Utils.ApplyDefaults(storage, self.defaults)
    _G.RollingPinAwardsDB = storage
  end

  self.db = Database:New(storage)

  if type(RosterPermissions.New) == "function" then
    self.rosterPermissions = RosterPermissions:New(self.db)
  else
    self.rosterPermissions = nil
  end

  if self.rosterPermissions and type(Permissions.New) == "function" then
    self.permissions = Permissions:New(self, self.rosterPermissions)
  else
    self.permissions = nil
  end

  if type(Awards.New) == "function" then
    self.awards = Awards:New(self)
  else
    self.awards = nil
  end

  if type(Nominations.New) == "function" then
    self.nominations = Nominations:New(self)
  else
    self.nominations = nil
  end

  if type(Commands.New) == "function" then
    self.commands = Commands:New(self)
  else
    self.commands = nil
  end

  if type(Bridge.New) == "function" then
    self.uiBridge = Bridge:New(self)
  else
    self.uiBridge = nil
  end

  if type(Toast.New) == "function" then
    self.toast = Toast:New(self)
  else
    self.toast = nil
  end

  if type(Notifications.New) == "function" then
    self.notifications = Notifications:New(self)
  else
    self.notifications = nil
  end

  if type(MainFrame.New) == "function" then
    self.mainFrame = MainFrame:New({
      addon = self,
      uiBridge = self.uiBridge,
    })
  else
    self.mainFrame = nil
  end

  if type(MinimapButton.New) == "function" then
    self.minimapButton = MinimapButton:New(self)
  else
    self.minimapButton = nil
  end

  if type(Sync.New) == "function" then
    self.sync = Sync:New(self)
  else
    self.sync = nil
  end

  if self.commands then
    if type(self.RegisterFallbackSlashCommand) == "function" then
      self:RegisterFallbackSlashCommand()
    end
  end

  self.__rpaInitializing = nil
  self.__rpaInitialized = true

  return true
end

function RPA:RefreshActiveGuildContext()
  if type(self.GuildContext.Build) ~= "function" then
    return self.activeGuildContext
  end

  local nextContext = self.GuildContext:Build()
  if nextContext then
    local previousContext = self.activeGuildContext
    local guildKeyChanged = previousContext and previousContext.guildKey ~= nextContext.guildKey
    if previousContext
      and previousContext.guildName == nextContext.guildName
      and guildKeyChanged
      and self.db
      and type(self.db.MigrateGuildDatasetKey) == "function"
    then
      self.db:MigrateGuildDatasetKey(previousContext.guildKey, nextContext.guildKey)
    end

    self.activeGuildContext = nextContext

    if guildKeyChanged
      and self.__rpaEnabled
      and self.sync
      and type(self.sync.SendHello) == "function"
    then
      self.sync:SendHello()
    end

    return self.activeGuildContext
  end

  if type(IsInGuild) == "function" and IsInGuild() == false then
    self.activeGuildContext = nil
  end

  return self.activeGuildContext
end

function RPA:OnEnable()
  if self.__rpaEnabled or self.__rpaEnabling then
    return self.__rpaEnabled == true
  end

  if not self.__rpaInitialized then
    self:OnInitialize()
  end

  self.__rpaEnabling = true

  if self.sync and type(self.RegisterComm) == "function" then
    self:RegisterComm(self.Constants.COMM_PREFIX)
  elseif self.sync then
    self:RegisterNativeComm()
  end

  if type(self.RequestGuildRoster) == "function" then
    self:RequestGuildRoster()
  end

  if self.sync and type(self.sync.SendHello) == "function" then
    self.sync:SendHello()
  end

  self.__rpaEnabling = nil
  self.__rpaEnabled = true

  if self.notifications and type(self.notifications.PrintPendingNominationReminders) == "function" then
    self.notifications:PrintPendingNominationReminders()
  end

  return true
end

function RPA:RequestGuildRoster()
  local now = type(GetTime) == "function" and GetTime() or 0
  if self.__rpaLastGuildRosterRequestAt and now - self.__rpaLastGuildRosterRequestAt < 10 then
    return false, "throttled"
  end

  local requested = false
  if _G.C_GuildInfo and type(_G.C_GuildInfo.GuildRoster) == "function" then
    requested = _G.C_GuildInfo.GuildRoster() ~= false
  elseif type(_G.GuildRoster) == "function" then
    requested = _G.GuildRoster() ~= false
  end

  if requested then
    self.__rpaLastGuildRosterRequestAt = now
  end

  return requested
end

function RPA:OnGuildRosterUpdate()
  self:RefreshActiveGuildContext()

  if self.sync and type(self.sync.ReplayDeferredInbound) == "function" then
    self.sync:ReplayDeferredInbound()
  end
end

function RPA:GetGuildRosterMemberStatus(playerFullName)
  local normalizedTarget = normalizeRosterLookupName(playerFullName)

  if type(normalizedTarget) ~= "string" or normalizedTarget == "" then
    return false, false
  end

  if type(GetNumGuildMembers) ~= "function" or type(GetGuildRosterInfo) ~= "function" then
    return false, false
  end

  local targetShortName = normalizedTarget:match("^[^-]+")
  local fallbackName
  local fallbackOnline
  local fallbackAmbiguous = false

  local memberCount = GetNumGuildMembers() or 0
  for index = 1, memberCount do
    local rosterName, _, _, _, _, _, _, _, online = GetGuildRosterInfo(index)
    local normalizedRosterName = normalizeRosterLookupName(rosterName)
    if normalizedRosterName == normalizedTarget then
      return true, online ~= false, normalizedRosterName
    end

    local rosterShortName = type(normalizedRosterName) == "string" and normalizedRosterName:match("^[^-]+") or nil
    if targetShortName and rosterShortName == targetShortName then
      if fallbackName and fallbackName ~= normalizedRosterName then
        fallbackAmbiguous = true
      else
        fallbackName = normalizedRosterName
        fallbackOnline = online ~= false
      end
    end
  end

  if fallbackName and not fallbackAmbiguous then
    return true, fallbackOnline, fallbackName
  end

  return false, false
end

function RPA:IsGuildRosterMember(playerFullName)
  local found = self:GetGuildRosterMemberStatus(playerFullName)
  return found == true
end

function RPA:IsGuildRosterMemberOnline(playerFullName)
  local found, online = self:GetGuildRosterMemberStatus(playerFullName)
  return found == true and online == true
end

function RPA:IsTrustedSyncDistribution(distribution, sender)
  if distribution == "GUILD" then
    return true
  end

  if distribution == "WHISPER" then
    return self:IsGuildRosterMember(sender)
  end

  return false
end

function RPA:RegisterNativeComm()
  if _G.C_ChatInfo and type(_G.C_ChatInfo.RegisterAddonMessagePrefix) == "function" then
    _G.C_ChatInfo.RegisterAddonMessagePrefix(self.Constants.COMM_PREFIX)
  elseif type(_G.RegisterAddonMessagePrefix) == "function" then
    _G.RegisterAddonMessagePrefix(self.Constants.COMM_PREFIX)
  else
    return false
  end

  if type(CreateFrame) == "function" and not self.__rpaNativeCommFrame then
    local frame = CreateFrame("Frame", "RollingPinAwardsNativeCommFrame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:SetScript("OnEvent", function(_, _, prefix, message, distribution, sender)
      self:OnCommReceived(prefix, message, distribution, sender)
    end)
    self.__rpaNativeCommFrame = frame
  end

  self.__rpaNativeCommPrefix = self.Constants.COMM_PREFIX

  return true
end

function RPA:OnCommReceived(prefix, message, distribution, sender)
  if prefix ~= self.Constants.COMM_PREFIX or not self.sync then
    return false
  end

  local envelope = message
  if type(self.Deserialize) == "function" then
    local ok, decoded = self:Deserialize(message)
    if not ok then
      if self.sync and type(self.sync.RecordInbound) == "function" then
        self.sync:RecordInbound({
          sender = sender,
          distribution = distribution,
          ok = false,
          error = "deserialize failed",
        })
      end

      return false
    end

    envelope = decoded
  elseif self.sync and type(self.sync.DecodeNativeMessage) == "function" and type(message) == "string" then
    local decoded, decodeErr = self.sync:DecodeNativeMessage(message, distribution, sender)
    if decodeErr == "partial" then
      return true
    end

    if not decoded then
      if type(self.sync.RecordInbound) == "function" then
        self.sync:RecordInbound({
          sender = sender,
          distribution = distribution,
          ok = false,
          error = decodeErr or "deserialize failed",
        })
      end

      return false
    end

    envelope = decoded
  end

  if type(self.IsTrustedSyncDistribution) == "function"
    and not self:IsTrustedSyncDistribution(distribution, sender)
  then
    if type(self.sync.RecordInbound) == "function" then
      local payload = type(envelope) == "table" and type(envelope.payload) == "table" and envelope.payload or {}
      self.sync:RecordInbound({
        payloadType = type(envelope) == "table" and envelope.payloadType or nil,
        guildKey = payload.guildKey,
        sender = sender,
        distribution = distribution,
        ok = false,
        error = "unauthorized distribution",
      })
    end

    return false, "unauthorized distribution"
  end

  return self.sync:DispatchEnvelope(envelope, distribution, sender)
end

function RPA:GetActiveGuildContext()
  return self:RefreshActiveGuildContext()
end

function RPA:GetCurrentPlayerFullName()
  local playerName = UnitName("player")

  return Utils.NormalizeUnitName(playerName)
end

function RPA:HandleChatCommand(message)
  if not self.commands then
    return nil
  end

  return self.commands:Handle(message or "")
end

if type(RPA.RegisterFallbackSlashCommand) == "function" then
  RPA:RegisterFallbackSlashCommand()
end

return RPA

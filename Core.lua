local function createAddonObject()
  local existing = _G.RollingPinAwards or {}
  local libStub = rawget(_G, "LibStub")

  if type(libStub) ~= "function" then
    existing.__rpaUsesAce3 = false

    return existing
  end

  local aceAddon = libStub("AceAddon-3.0", true)
  if not aceAddon or type(aceAddon.NewAddon) ~= "function" then
    existing.__rpaUsesAce3 = false

    return existing
  end

  local addon = aceAddon:NewAddon(
    existing,
    "RollingPinAwards",
    "AceEvent-3.0",
    "AceConsole-3.0",
    "AceComm-3.0",
    "AceSerializer-3.0"
  )

  addon.__rpaUsesAce3 = true

  return addon
end

local function getOptionalLibrary(libraryName)
  local libStub = rawget(_G, "LibStub")
  if type(libStub) ~= "function" then
    return nil
  end

  return libStub(libraryName, true)
end

local RPA = createAddonObject()
_G.RollingPinAwards = RPA

local Constants = RPA.Constants or {
  ADDON_NAME = "RollingPinAwards",
  DISPLAY_AWARD_NAME = "The Burnt Rolling Pin",
  SLASH_COMMAND = "/rpa",
  PROTOCOL_VERSION = 1,
}
local Defaults = RPA.Defaults or {
  profile = {
    settings = {
      tooltipEnabled = true,
      announceAwards = true,
      debug = false,
    },
    guildDatasets = {},
  },
}
local GuildContext = RPA.GuildContext or {}
local Awards = RPA.Awards or {}
local Announcements = RPA.Announcements or {}
local Commands = RPA.Commands or {}
local Database = RPA.Database
local MainFrame = RPA.MainFrame or {}
local Nominations = RPA.Nominations or {}
local Permissions = RPA.Permissions or {}
local RosterPermissions = RPA.RosterPermissions or {}
local Sync = RPA.Sync or {}
local Time = RPA.Time or {}
local Tooltip = RPA.Tooltip or {}
local Bridge = RPA.UIBridge or {}
local Utils = RPA.Utils

RPA.Constants = Constants
RPA.Defaults = Defaults
RPA.GuildContext = GuildContext
RPA.Awards = Awards
RPA.Announcements = Announcements
RPA.Commands = Commands
RPA.Nominations = Nominations
RPA.MainFrame = MainFrame
RPA.Permissions = Permissions
RPA.RosterPermissions = RosterPermissions
RPA.Sync = Sync
RPA.Time = Time
RPA.Tooltip = Tooltip
RPA.UIBridge = Bridge

RPA.ADDON_NAME = Constants.ADDON_NAME
RPA.SLASH_COMMAND = Constants.SLASH_COMMAND
RPA.defaults = Defaults

local function registerFallbackSlashCommand(addon)
  _G.SlashCmdList = _G.SlashCmdList or {}
  _G.SLASH_ROLLINGPINAWARDS1 = addon.SLASH_COMMAND
  _G.SlashCmdList.ROLLINGPINAWARDS = function(message)
    if not addon.__rpaInitialized then
      addon:OnInitialize()
    end

    if not addon.__rpaEnabled and (type(IsLoggedIn) ~= "function" or IsLoggedIn()) then
      addon:OnEnable()
    end

    return addon:HandleChatCommand(message or "")
  end
end

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

  if type(MainFrame.New) == "function" then
    self.mainFrame = MainFrame:New({
      addon = self,
      uiBridge = self.uiBridge,
    })
  else
    self.mainFrame = nil
  end

  if type(Sync.New) == "function" then
    self.sync = Sync:New(self)
  else
    self.sync = nil
  end

  if type(Announcements.New) == "function" then
    self.announcements = Announcements:New(self)
  else
    self.announcements = nil
  end

  if type(Tooltip.New) == "function" then
    self.tooltip = Tooltip:New(self)
  else
    self.tooltip = nil
  end

  if self.commands then
    registerFallbackSlashCommand(self)
  end

  self.__rpaInitializing = nil
  self.__rpaInitialized = true

  return true
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
  end

  self.__rpaEnabling = nil
  self.__rpaEnabled = true

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
      return false
    end

    envelope = decoded
  end

  return self.sync:DispatchEnvelope(envelope, distribution, sender)
end

function RPA:GetActiveGuildContext()
  return self.activeGuildContext
end

function RPA:GetCurrentPlayerFullName()
  local playerName = UnitName("player")
  local realmName = GetRealmName()

  return ("%s-%s"):format(playerName, realmName)
end

function RPA:HandleChatCommand(message)
  if not self.commands then
    return nil
  end

  return self.commands:Handle(message or "")
end

registerFallbackSlashCommand(RPA)

if type(CreateFrame) == "function" then
  local startupFrame = CreateFrame("Frame", "RollingPinAwardsStartupFrame")
  startupFrame:RegisterEvent("ADDON_LOADED")
  startupFrame:RegisterEvent("PLAYER_LOGIN")
  startupFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == RPA.ADDON_NAME then
      RPA:OnInitialize()
      return
    end

    if event == "PLAYER_LOGIN" then
      if not RPA.__rpaInitialized then
        RPA:OnInitialize()
      end

      RPA:OnEnable()
    end
  end)
end

return RPA

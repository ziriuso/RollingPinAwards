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
local Commands = RPA.Commands or {}
local Database = RPA.Database
local MainFrame = RPA.MainFrame or {}
local Nominations = RPA.Nominations or {}
local Permissions = RPA.Permissions or {}
local RosterPermissions = RPA.RosterPermissions or {}
local Bridge = RPA.UIBridge or {}
local Utils = RPA.Utils

RPA.Constants = Constants
RPA.Defaults = Defaults
RPA.GuildContext = GuildContext
RPA.Awards = Awards
RPA.Commands = Commands
RPA.Nominations = Nominations
RPA.MainFrame = MainFrame
RPA.Permissions = Permissions
RPA.RosterPermissions = RosterPermissions
RPA.UIBridge = Bridge

RPA.ADDON_NAME = Constants.ADDON_NAME
RPA.SLASH_COMMAND = Constants.SLASH_COMMAND
RPA.defaults = Defaults

function RPA:OnInitialize()
  self.activeGuildContext = nil
  if type(self.GuildContext.Build) == "function" then
    self.activeGuildContext = self.GuildContext:Build()
  end

  local storage = _G.RollingPinAwardsDB
  storage = Utils.ApplyDefaults(storage, self.defaults)
  _G.RollingPinAwardsDB = storage

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

  if self.commands then
    _G.SLASH_ROLLINGPINAWARDS1 = self.SLASH_COMMAND
    _G.SlashCmdList.ROLLINGPINAWARDS = function(message)
      return self.commands:Handle(message or "")
    end
  end
end

function RPA:GetActiveGuildContext()
  return self.activeGuildContext
end

function RPA:GetCurrentPlayerFullName()
  local playerName = UnitName("player")
  local realmName = GetRealmName()

  return ("%s-%s"):format(playerName, realmName)
end

return RPA

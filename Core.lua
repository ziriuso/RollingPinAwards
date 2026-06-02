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
    guild = nil,
  },
}
local GuildContext = RPA.GuildContext or {}

RPA.Constants = Constants
RPA.Defaults = Defaults
RPA.GuildContext = GuildContext

RPA.ADDON_NAME = Constants.ADDON_NAME
RPA.SLASH_COMMAND = Constants.SLASH_COMMAND
RPA.defaults = Defaults

function RPA:OnInitialize()
  self.activeGuildContext = nil
  if type(self.GuildContext.Build) == "function" then
    self.activeGuildContext = self.GuildContext:Build()
  end
end

function RPA:GetActiveGuildContext()
  return self.activeGuildContext
end

return RPA

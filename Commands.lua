local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Commands = RPA.Commands or {}
RPA.Commands = Commands

function Commands:New(addon)
  local obj = {
    addon = addon,
  }

  self.__index = self

  return setmetatable(obj, self)
end

function Commands:Handle(message)
  local command, rest = (message or ""):match("^(%S+)%s*(.-)$")

  if command == "nominate" then
    local nominee, reason = rest:match('^(%S+)%s+"(.+)"$')
    if nominee and reason then
      return self.addon.nominations:Create(nominee, reason)
    end
  end

  return nil, "unknown command"
end

return RPA.Commands

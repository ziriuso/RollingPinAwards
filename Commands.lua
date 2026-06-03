local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Commands = RPA.Commands or {}
RPA.Commands = Commands

local function printChatLines(addon, lines)
  addon.__rpaLastChatOutput = {}

  for _, line in ipairs(lines or {}) do
    addon.__rpaLastChatOutput[#addon.__rpaLastChatOutput + 1] = line

    if type(addon.Print) == "function" then
      addon:Print(line)
    elseif _G.DEFAULT_CHAT_FRAME and type(_G.DEFAULT_CHAT_FRAME.AddMessage) == "function" then
      _G.DEFAULT_CHAT_FRAME:AddMessage(line)
    elseif type(print) == "function" then
      print(line)
    end
  end
end

function Commands:New(addon)
  local obj = {
    addon = addon,
  }

  self.__index = self

  return setmetatable(obj, self)
end

function Commands:Handle(message)
  local command, rest = (message or ""):match("^(%S+)%s*(.-)$")

  if not command or command == "" then
    if self.addon.mainFrame then
      self.addon.mainFrame:Toggle()
      return true
    end

    return nil, "ui unavailable"
  end

  if command == "nominate" then
    local nominee, reason = rest:match('^(%S+)%s+"(.+)"$')
    if nominee and reason then
      return self.addon.nominations:Create(nominee, reason)
    end
  elseif command == "show" or command == "toggle" then
    if self.addon.mainFrame then
      self.addon.mainFrame:Toggle()
      return true
    end

    return nil, "ui unavailable"
  elseif command == "background" or command == "bg" then
    if self.addon.mainFrame then
      self.addon.mainFrame:ToggleBackgroundCalibrator()
      return true
    end

    return nil, "ui unavailable"
  elseif command == "syncdebug" or (command == "sync" and rest == "debug") then
    if self.addon.sync and type(self.addon.sync.GetDebugLines) == "function" then
      printChatLines(self.addon, self.addon.sync:GetDebugLines())
      return true
    end

    return nil, "sync unavailable"
  end

  return nil, "unknown command"
end

return RPA.Commands

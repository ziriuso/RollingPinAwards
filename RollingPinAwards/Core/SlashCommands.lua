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
  elseif command == "peers" or (command == "sync" and rest == "peers") then
    if self.addon.mainFrame and type(self.addon.mainFrame.ShowSyncPeers) == "function" then
      return self.addon.mainFrame:ShowSyncPeers()
    end

    return nil, "ui unavailable"
  elseif command == "syncdebug" or (command == "sync" and rest == "debug") then
    if self.addon.sync and type(self.addon.sync.GetDebugLines) == "function" then
      printChatLines(self.addon, self.addon.sync:GetDebugLines())
      return true
    end

    return nil, "sync unavailable"
  elseif command == "sync" and (rest == "now" or rest == "all") then
    if self.addon.sync
      and type(self.addon.sync.SendHello) == "function"
      and type(self.addon.sync.SendFullSnapshot) == "function"
    then
      local helloOk, helloErr = self.addon.sync:SendHello("GUILD", nil, true)
      local snapshotOk, snapshotResult = self.addon.sync:SendFullSnapshot("GUILD")
      local lines = {
        ("Rolling Pin Awards sync now: hello=%s snapshot=%s"):format(
          tostring(helloOk == true),
          tostring(snapshotOk == true)
        ),
      }

      if helloErr then
        lines[#lines + 1] = "Hello error: " .. tostring(helloErr)
      end

      if type(snapshotResult) == "table" then
        lines[#lines + 1] = ("Sent snapshot: awards=%s nominations=%s votes=%s aliases=%s ranks=%s"):format(
          tostring(snapshotResult.awards or 0),
          tostring(snapshotResult.nominations or 0),
          tostring(snapshotResult.votes or 0),
          tostring(snapshotResult.aliasMappings or 0),
          tostring(snapshotResult.rankPermissions or 0)
        )
      elseif snapshotResult then
        lines[#lines + 1] = "Snapshot error: " .. tostring(snapshotResult)
      end

      printChatLines(self.addon, lines)
      return helloOk == true or snapshotOk == true
    end

    return nil, "sync unavailable"
  end

  return nil, "unknown command"
end

function RPA:RegisterFallbackSlashCommand()
  _G.SlashCmdList = _G.SlashCmdList or {}
  _G.SLASH_ROLLINGPINAWARDS1 = self.SLASH_COMMAND or "/rpa"
  _G.SlashCmdList.ROLLINGPINAWARDS = function(message)
    if not self.__rpaInitialized then
      self:OnInitialize()
    end

    if not self.__rpaEnabled and (type(IsLoggedIn) ~= "function" or IsLoggedIn()) then
      self:OnEnable()
    end

    return self:HandleChatCommand(message or "")
  end
end

return RPA.Commands

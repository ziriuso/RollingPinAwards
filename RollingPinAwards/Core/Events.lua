local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

if type(RPA.RegisterFallbackSlashCommand) == "function" then
  RPA:RegisterFallbackSlashCommand()
end

if type(CreateFrame) == "function" then
  local startupFrame = CreateFrame("Frame", "RollingPinAwardsStartupFrame")
  startupFrame:RegisterEvent("ADDON_LOADED")
  startupFrame:RegisterEvent("PLAYER_LOGIN")
  startupFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
  startupFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
  startupFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
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
      RPA:RefreshActiveGuildContext()
      return
    end

    if event == "PLAYER_GUILD_UPDATE" then
      if not RPA.__rpaInitialized then
        RPA:OnInitialize()
      end

      RPA:RefreshActiveGuildContext()
      if RPA.__rpaEnabled and RPA.sync and type(RPA.sync.SendHello) == "function" then
        RPA.sync:SendHello()
      end
      return
    end

    if event == "GUILD_ROSTER_UPDATE" then
      if not RPA.__rpaInitialized then
        RPA:OnInitialize()
      end

      if type(RPA.OnGuildRosterUpdate) == "function" then
        RPA:OnGuildRosterUpdate()
      end
      return
    end

    if event == "PLAYER_REGEN_ENABLED" then
      if RPA.toast and type(RPA.toast.FlushQueuedToasts) == "function" then
        RPA.toast:FlushQueuedToasts()
      end
    end
  end)
end

return RPA

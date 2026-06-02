local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
RPA.UITabs = UITabs

UITabs.settings = {
  id = "settings",
  label = "Settings",
  BuildViewModel = function(bridge)
    return bridge:GetSettingsViewModel()
  end,
}

return UITabs.settings

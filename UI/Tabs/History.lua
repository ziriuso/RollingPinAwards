local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
RPA.UITabs = UITabs

UITabs.history = {
  id = "history",
  label = "History",
  BuildViewModel = function(bridge)
    return {
      awards = bridge:GetPublicHistoryViewModel(),
    }
  end,
}

return UITabs.history

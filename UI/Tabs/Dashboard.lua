local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
RPA.UITabs = UITabs

UITabs.dashboard = {
  id = "dashboard",
  label = "Dashboard",
  BuildViewModel = function(bridge)
    return {
      pendingNominations = bridge:GetPendingNominationsViewModel(),
      recentAwards = bridge:GetPublicHistoryViewModel(),
    }
  end,
}

return UITabs.dashboard

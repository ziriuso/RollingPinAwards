local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
RPA.UITabs = UITabs

UITabs.nominations = {
  id = "nominations",
  label = "Nominations",
  BuildViewModel = function(bridge)
    return {
      pendingNominations = bridge:GetPendingNominationsViewModel(),
    }
  end,
}

return UITabs.nominations

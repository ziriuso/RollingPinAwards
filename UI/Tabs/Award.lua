local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
RPA.UITabs = UITabs

UITabs.award = {
  id = "award",
  label = "Award",
  BuildViewModel = function(bridge)
    return {
      canAward = bridge:CanCurrentPlayerManageAwards(),
    }
  end,
}

return UITabs.award

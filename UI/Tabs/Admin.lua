local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
RPA.UITabs = UITabs

UITabs.admin = {
  id = "admin",
  label = "Admin",
  BuildViewModel = function(bridge)
    return {
      nominations = bridge:GetAdminNominationsViewModel(),
      canModerate = bridge:CanCurrentPlayerManageAwards(),
    }
  end,
}

return UITabs.admin

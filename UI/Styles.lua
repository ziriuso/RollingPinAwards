local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

RPA.UIStyles = {
  Window = {
    width = 920,
    height = 680,
    title = "Rolling Pin Awards",
  },
  TabOrder = {
    "dashboard",
    "award",
    "nominations",
    "history",
    "leaderboard",
    "settings",
    "admin",
  },
}

return RPA.UIStyles

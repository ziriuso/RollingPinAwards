local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

RPA.Defaults = {
  profile = {
    guildDatasets = {},
    localSettings = {
      toastsEnabled = true,
      toastDurationSeconds = 7,
      minimapAngle = 225,
      seenAwardToastIds = {},
      toastAnchor = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 180,
      },
    },
  },
}

return RPA.Defaults

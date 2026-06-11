local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

RPA.Defaults = {
  profile = {
    guildDatasets = {},
    localSettings = {
      toastsEnabled = true,
      toastDurationSeconds = 7,
      addonScale = 0.8,
      minimapAngle = 225,
      seenAwardToastIds = {},
      seenAwardChatIds = {},
      syncPeersByGuild = {},
      reportingFilter = {
        mode = "all_time",
        label = "All Time",
        startsAt = nil,
        endsAt = nil,
      },
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

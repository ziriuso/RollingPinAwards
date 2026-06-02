local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

RPA.Defaults = {
  profile = {
    settings = {
      tooltipEnabled = true,
      announceAwards = true,
      debug = false,
    },
    guildDatasets = {},
  },
}

return RPA.Defaults

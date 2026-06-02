local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

RPA.Constants = {
  ADDON_NAME = "RollingPinAwards",
  COMM_PREFIX = "RPAAwardsSync",
  DISPLAY_AWARD_NAME = "The Burnt Rolling Pin",
  SLASH_COMMAND = "/rpa",
  MODERATION_DOWNVOTE_THRESHOLD = 3,
  PROTOCOL_VERSION = 1,
}

return RPA.Constants

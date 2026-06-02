local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Constants = RPA.Constants or {
  DISPLAY_AWARD_NAME = "The Burnt Rolling Pin",
}

local Announcements = RPA.Announcements or {}
RPA.Announcements = Announcements

function Announcements:New(addon)
  local obj = {
    addon = addon,
  }

  self.__index = self

  return setmetatable(obj, self)
end

function Announcements:FormatAwardMessage(awardOrRecipient, reason)
  if type(awardOrRecipient) == "table" then
    return ("[Rolling Pin Awards] %s received %s for: %s"):format(
      awardOrRecipient.recipient or awardOrRecipient.player or "Unknown",
      awardOrRecipient.awardName or Constants.DISPLAY_AWARD_NAME,
      awardOrRecipient.reason or "No reason provided"
    )
  end

  return ("[Rolling Pin Awards] %s received %s for: %s"):format(
    tostring(awardOrRecipient or "Unknown"),
    Constants.DISPLAY_AWARD_NAME,
    tostring(reason or "No reason provided")
  )
end

return RPA.Announcements

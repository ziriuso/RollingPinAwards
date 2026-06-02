local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local RosterPermissions = RPA.RosterPermissions or {}
RPA.RosterPermissions = RosterPermissions

local function isMissingString(value)
  return type(value) ~= "string" or value == ""
end

function RosterPermissions:New(database)
  local obj = {
    db = database,
  }

  self.__index = self

  return setmetatable(obj, self)
end

function RosterPermissions:Grant(guildKey, playerFullName, grantedBy)
  if isMissingString(playerFullName) or isMissingString(grantedBy) then
    return false
  end

  local record = self.db:UpsertPermissionRosterEntry(guildKey, {
    player = playerFullName,
    grantedBy = grantedBy,
  })

  return record ~= nil
end

function RosterPermissions:Has(guildKey, playerFullName)
  local record = self.db:GetPermissionRosterEntry(guildKey, playerFullName)

  return record ~= nil
end

return RPA.RosterPermissions

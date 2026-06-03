local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local GuildContext = RPA.GuildContext or {}
RPA.GuildContext = GuildContext

local function normalizeGuildName(name)
  return string.lower((name or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function getStableGuildIdentifier()
  local clubApi = _G.C_Club
  if not clubApi or type(clubApi.GetGuildClubId) ~= "function" then
    return nil
  end

  local guildClubId = clubApi.GetGuildClubId()
  if guildClubId == nil or guildClubId == "" then
    return nil
  end

  return tostring(guildClubId)
end

function GuildContext:BuildGuildKey(guildName)
  return getStableGuildIdentifier() or normalizeGuildName(guildName)
end

function GuildContext:Build()
  local guildName = GetGuildInfo("player")
  if not guildName or guildName == "" then
    return nil
  end

  return {
    guildName = guildName,
    guildKey = self:BuildGuildKey(guildName),
  }
end

GuildContext.NormalizeGuildName = normalizeGuildName

return RPA.GuildContext

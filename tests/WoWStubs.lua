local state = {}
local wow = {}

local function loadAddonFromToc(path)
  for line in io.lines(path or "RollingPinAwards.toc") do
    local entry = line:match("^%s*(.-)%s*$")
    if entry ~= "" and not entry:match("^##") then
      dofile(entry)
    end
  end

  return _G.RollingPinAwards
end

function wow.reset(seed)
  seed = seed or {}
  state = {
    guildClubId = seed.guildClubId,
    guildName = seed.guildName,
    realmName = seed.realmName or "Stormrage",
    playerName = seed.playerName or "Ziri",
    savedVariables = seed.savedVariables,
  }

  _G.__RPA_TEST_STATE = state

  _G.GetGuildInfo = function()
    return state.guildName
  end

  _G.GetRealmName = function()
    return state.realmName
  end

  _G.UnitName = function()
    return state.playerName
  end

  _G.C_Club = {
    GetGuildClubId = function()
      return state.guildClubId
    end,
  }

  _G.SlashCmdList = {}
  _G.SLASH_ROLLINGPINAWARDS1 = nil
  _G.RollingPinAwards = nil
  _G.RollingPinAwardsDB = state.savedVariables
end

wow.loadAddon = loadAddonFromToc

return wow

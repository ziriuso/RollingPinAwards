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
    guildRankName = seed.guildRankName or "Member",
    guildRankIndex = seed.guildRankIndex or 9,
    guildMembers = seed.guildMembers or {},
    isGuildOfficer = seed.isGuildOfficer,
    realmName = seed.realmName or "Stormrage",
    playerName = seed.playerName or "Ziri",
    savedVariables = seed.savedVariables,
  }

  _G.__RPA_TEST_STATE = state

  _G.GetGuildInfo = function(unit)
    if unit == "player" then
      return state.guildName, state.guildRankName, state.guildRankIndex
    end

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

  _G.C_GuildInfo = {
    IsGuildOfficer = function()
      if state.isGuildOfficer ~= nil then
        return state.isGuildOfficer
      end

      return state.guildRankIndex ~= nil and state.guildRankIndex <= 1
    end,
  }

  _G.GetNumGuildMembers = function()
    return #state.guildMembers
  end

  _G.GetGuildRosterInfo = function(index)
    local member = state.guildMembers[index]
    if not member then
      return nil
    end

    return member.name, member.rankName or "Member", member.rankIndex or 9
  end

  _G.SlashCmdList = {}
  _G.SLASH_ROLLINGPINAWARDS1 = nil
  _G.RollingPinAwards = nil
  _G.RollingPinAwardsDB = state.savedVariables
end

function wow.setPlayer(playerName, guildRankName, guildRankIndex)
  state.playerName = playerName or state.playerName
  state.guildRankName = guildRankName or state.guildRankName
  if guildRankIndex ~= nil then
    state.guildRankIndex = guildRankIndex
    state.isGuildOfficer = guildRankIndex <= 1
  elseif guildRankName ~= nil then
    state.isGuildOfficer = guildRankName == "Guild Master" or guildRankName == "Officer"
  end
end


wow.loadAddon = loadAddonFromToc

return wow

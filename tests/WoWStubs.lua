local state = {}
local wow = {}

local function copyTable(input)
  local output = {}

  for key, value in pairs(input or {}) do
    output[key] = type(value) == "table" and copyTable(value) or value
  end

  return output
end

local function applyDefaults(target, defaults)
  if type(target) ~= "table" then
    target = {}
  end

  for key, value in pairs(defaults or {}) do
    if type(value) == "table" then
      target[key] = applyDefaults(target[key], value)
    elseif target[key] == nil then
      target[key] = value
    end
  end

  return target
end

local function buildAceLibStub()
  local libraries = {}

  libraries["AceConsole-3.0"] = {
    Embed = function(_, target)
      function target:RegisterChatCommand(command, handler)
        self.__aceConsoleCommands = self.__aceConsoleCommands or {}
        self.__aceConsoleCommands[command] = handler
      end

      function target:GetArgs(input, numArgs, startPos)
        local parts = {}
        local cursor = startPos or 1
        local source = input or ""

        while #parts < (numArgs or 1) do
          local piece = source:match("^%s*(%S+)%s*()", cursor)
          local value, nextCursor = source:match("()%s*(%S+)%s*()", cursor)
          if not nextCursor then
            break
          end
          parts[#parts + 1] = source:sub(value, nextCursor - 1):match("^%s*(.-)%s*$")
          cursor = nextCursor
        end

        parts[#parts + 1] = cursor

        return unpack(parts)
      end
    end,
  }

  libraries["AceComm-3.0"] = {
    Embed = function(_, target)
      function target:RegisterComm(prefix)
        self.__aceCommPrefix = prefix
      end

      function target:SendCommMessage(prefix, message, distribution, targetPlayer, priority)
        self.__lastCommMessage = {
          prefix = prefix,
          message = message,
          distribution = distribution,
          target = targetPlayer,
          priority = priority,
        }
      end
    end,
  }

  libraries["AceSerializer-3.0"] = {
    Embed = function(_, target)
      function target:Serialize(payload)
        return payload
      end

      function target:Deserialize(payload)
        return true, payload
      end
    end,
  }

  libraries["AceDB-3.0"] = {
    New = function(_, name, defaults)
      local root = _G[name]
      if type(root) ~= "table" then
        root = {}
        _G[name] = root
      end

      root.profileKeys = root.profileKeys or {}
      root.profiles = root.profiles or {}

      local profileKey = "Default"
      root.profileKeys["Stormrage - Ziri"] = root.profileKeys["Stormrage - Ziri"] or profileKey
      root.profiles[profileKey] = applyDefaults(root.profiles[profileKey], copyTable(defaults.profile or {}))

      return {
        profile = root.profiles[profileKey],
      }
    end,
  }

  libraries["AceEvent-3.0"] = {
    Embed = function(_, target)
      function target:RegisterEvent(eventName, handlerName)
        self.__aceEvents = self.__aceEvents or {}
        self.__aceEvents[eventName] = handlerName or eventName
      end
    end,
  }

  libraries["AceAddon-3.0"] = {
    NewAddon = function(_, object, name, ...)
      local addon = object or {}
      addon.name = name

      for index = 1, select("#", ...) do
        local libName = select(index, ...)
        local library = libraries[libName]
        if library and type(library.Embed) == "function" then
          library:Embed(addon)
        end
      end

      return addon
    end,
  }

  return function(libraryName, silent)
    local library = libraries[libraryName]
    if library or silent then
      return library
    end

    error("missing library: " .. tostring(libraryName))
  end
end

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
    ace3 = seed.ace3,
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
  _G.LibStub = state.ace3 and buildAceLibStub() or nil
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

local state = {}
local wow = {}
local originalOs = _G.os

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

local function createFrameObject(frameType, name, parent, template)
  local frame = {
    children = {},
    frameType = frameType,
    name = name,
    parent = parent,
    template = template,
    events = {},
    scripts = {},
    visible = true,
  }

  if parent and type(parent.children) == "table" then
    parent.children[#parent.children + 1] = frame
  end

  function frame:RegisterEvent(eventName)
    self.events[eventName] = true
    state.framesByEvent[eventName] = state.framesByEvent[eventName] or {}
    state.framesByEvent[eventName][#state.framesByEvent[eventName] + 1] = self
  end

  function frame:SetScript(scriptName, handler)
    self.scripts[scriptName] = handler
  end

  function frame:SetBackdrop(backdrop)
    self.backdrop = backdrop
  end

  function frame:SetBackdropColor(red, green, blue, alpha)
    self.backdropColor = {
      red = red,
      green = green,
      blue = blue,
      alpha = alpha,
    }
  end

  function frame:CreateFontString(fontName, layer, templateName)
    local fontString = {
      fontName = fontName,
      layer = layer,
      parent = self,
      template = templateName,
      text = "",
    }

    function fontString:SetPoint(...)
      self.point = { ... }
    end

    function fontString:SetJustifyH(value)
      self.justifyH = value
    end

    function fontString:SetJustifyV(value)
      self.justifyV = value
    end

    function fontString:SetWidth(value)
      self.width = value
    end

    function fontString:SetText(value)
      self.text = value
    end

    self.children[#self.children + 1] = fontString

    return fontString
  end

  function frame:Show()
    self.visible = true
  end

  function frame:Hide()
    self.visible = false
  end

  function frame:SetSize(width, height)
    self.width = width
    self.height = height
  end

  function frame:SetWidth(width)
    self.width = width
  end

  function frame:SetHeight(height)
    self.height = height
  end

  function frame:SetPoint(...)
    self.point = { ... }
  end

  function frame:SetText(value)
    self.text = value
  end

  function frame:GetText()
    return self.text or ""
  end

  function frame:SetMinMaxValues(minValue, maxValue)
    self.minValue = minValue
    self.maxValue = maxValue
  end

  function frame:SetValueStep(step)
    self.valueStep = step
  end

  function frame:SetObeyStepOnDrag(value)
    self.obeyStepOnDrag = value == true
  end

  function frame:SetOrientation(value)
    self.orientation = value
  end

  function frame:SetValue(value)
    if self.minValue ~= nil and value < self.minValue then
      value = self.minValue
    end

    if self.maxValue ~= nil and value > self.maxValue then
      value = self.maxValue
    end

    self.value = value

    local handler = self.scripts.OnValueChanged
    if type(handler) == "function" then
      handler(self, value)
    end
  end

  function frame:GetValue()
    return self.value or 0
  end

  function frame:SetChecked(value)
    self.checked = value == true
  end

  function frame:GetChecked()
    return self.checked == true
  end

  function frame:Enable()
    self.disabled = false
  end

  function frame:Disable()
    self.disabled = true
  end

  function frame:SetEnabled(value)
    self.disabled = value ~= true
  end

  function frame:EnableMouse(value)
    self.mouseEnabled = value == true
  end

  function frame:EnableMouseWheel(value)
    self.mouseWheelEnabled = value == true
  end

  function frame:SetMovable(value)
    self.movable = value == true
  end

  function frame:RegisterForDrag(...)
    self.dragButtons = { ... }
  end

  function frame:StartMoving()
    self.moving = true
  end

  function frame:StopMovingOrSizing()
    self.moving = false
  end

  function frame:SetAutoFocus(value)
    self.autoFocus = value == true
  end

  function frame:SetMultiLine(value)
    self.multiLine = value == true
  end

  function frame:SetMaxLetters(value)
    self.maxLetters = value
  end

  function frame:ClearFocus()
    self.focused = false
  end

  function frame:SetNormalFontObject(fontObject)
    self.normalFontObject = fontObject
  end

  function frame:SetHighlightFontObject(fontObject)
    self.highlightFontObject = fontObject
  end

  function frame:SetDisabledFontObject(fontObject)
    self.disabledFontObject = fontObject
  end

  function frame:Click(...)
    local handler = self.scripts.OnClick
    if type(handler) == "function" then
      return handler(self, ...)
    end

    return nil
  end

  function frame:MouseWheel(delta)
    local handler = self.scripts.OnMouseWheel
    if type(handler) == "function" then
      return handler(self, delta)
    end

    return nil
  end

  return frame
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
      if not entry:match("^Libs[\\/]") then
        dofile(entry)
      end
    end
  end

  return _G.RollingPinAwards
end

function wow.reset(seed)
  seed = seed or {}
  state = {
    framesByEvent = {},
    guildClubId = seed.guildClubId,
    guildName = seed.guildName,
    guildRanks = seed.guildRanks or {},
    guildRankName = seed.guildRankName or "Member",
    guildRankIndex = seed.guildRankIndex or 9,
    guildMembers = seed.guildMembers or {},
    isGuildOfficer = seed.isGuildOfficer,
    realmName = seed.realmName or "Stormrage",
    playerName = seed.playerName or "Ziri",
    savedVariables = seed.savedVariables,
    ace3 = seed.ace3,
    loggedIn = seed.loggedIn == true,
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

  _G.GetServerTime = function()
    return seed.serverTime or 1717336800
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

  _G.GuildControlGetNumRanks = function()
    return #state.guildRanks
  end

  _G.GuildControlGetRankName = function(index)
    local rank = state.guildRanks[index]
    if type(rank) == "table" then
      return rank.name
    end

    return rank
  end

  _G.SlashCmdList = {}
  _G.SLASH_ROLLINGPINAWARDS1 = nil
  _G.os = originalOs
  _G.CreateFrame = createFrameObject
  _G.UIParent = {}
  _G.IsLoggedIn = function()
    return state.loggedIn == true
  end
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

function wow.setGuild(guildName, guildClubId)
  state.guildName = guildName
  state.guildClubId = guildClubId
end


wow.loadAddon = loadAddonFromToc

function wow.fireEvent(eventName, ...)
  local frames = state.framesByEvent[eventName] or {}

  for _, frame in ipairs(frames) do
    local handler = frame.scripts.OnEvent
    if type(handler) == "function" then
      handler(frame, eventName, ...)
    end
  end
end

function wow.setLoggedIn(isLoggedIn)
  state.loggedIn = isLoggedIn == true
end

return wow

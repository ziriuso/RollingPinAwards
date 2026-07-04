local state = {}
local wow = {}
local originalOs = _G.os
local serializedSequence = 0
local DEFAULT_TOC_PATH = "RollingPinAwards/RollingPinAwards.toc"

local function getDirectory(path)
  local directory = path:match("^(.*)[/\\][^/\\]+$")
  if directory == "" then
    return nil
  end

  return directory
end

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
    frameLevel = parent and ((parent.frameLevel or 0) + 1) or 0,
    frameStrata = parent and parent.frameStrata or "MEDIUM",
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
    if scriptName == "OnClick" and self.frameType ~= "Button" and self.frameType ~= "CheckButton" then
      error((self.frameType or "Frame") .. ":SetScript(): Doesn't have a \"OnClick\" script", 2)
    end

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

  function frame:CreateTexture(name, layer, templateName)
    local texture = {
      name = name,
      layer = layer,
      parent = self,
      template = templateName,
    }

    function texture:SetPoint(...)
      self.point = { ... }
    end

    function texture:ClearAllPoints()
      self.point = nil
    end

    function texture:Show()
      self.visible = true
    end

    function texture:Hide()
      self.visible = false
    end

    function texture:SetSize(width, height)
      self.width = width
      self.height = height
    end

    function texture:SetAllPoints(target)
      self.allPointsTarget = target or self.parent
    end

    function texture:SetTexture(path)
      self.texturePath = path
    end

    function texture:SetVertexColor(red, green, blue, alpha)
      self.vertexColor = {
        red = red,
        green = green,
        blue = blue,
        alpha = alpha,
      }
    end

    function texture:GetVertexColor()
      local color = self.vertexColor or {}
      return color.red or 1, color.green or 1, color.blue or 1, color.alpha or 1
    end

    self.children[#self.children + 1] = texture

    return texture
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

    function fontString:ClearAllPoints()
      self.point = nil
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

    function fontString:SetHeight(value)
      self.height = value
    end

    function fontString:SetText(value)
      self.text = value
    end

    function fontString:SetTextColor(red, green, blue, alpha)
      self.textColor = {
        red = red,
        green = green,
        blue = blue,
        alpha = alpha,
      }
    end

    function fontString:GetFont()
      return self.fontFile or "Fonts\\FRIZQT__.TTF", self.fontHeight or 12, self.fontFlags
    end

    function fontString:SetFont(file, height, flags)
      self.fontFile = file
      self.fontHeight = height
      self.fontFlags = flags
    end

    function fontString:SetShadowColor(red, green, blue, alpha)
      self.shadowColor = {
        red = red,
        green = green,
        blue = blue,
        alpha = alpha,
      }
    end

    function fontString:SetShadowOffset(x, y)
      self.shadowOffset = {
        x = x,
        y = y,
      }
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

  function frame:ClearAllPoints()
    self.point = nil
  end

  function frame:SetHitRectInsets(left, right, top, bottom)
    self.hitRectInsets = {
      left = left,
      right = right,
      top = top,
      bottom = bottom,
    }
  end

  function frame:SetHighlightTexture(texture)
    self.highlightTexture = texture
  end

  function frame:SetFrameLevel(value)
    self.frameLevel = value
  end

  function frame:GetFrameLevel()
    return self.frameLevel or 0
  end

  function frame:SetFrameStrata(value)
    self.frameStrata = value
  end

  function frame:GetFrameStrata()
    return self.frameStrata or "MEDIUM"
  end

  function frame:SetToplevel(value)
    self.toplevel = value == true
  end

  function frame:EnableKeyboard(value)
    self.keyboardEnabled = value == true
  end

  function frame:SetPropagateKeyboardInput(value)
    self.propagateKeyboardInput = value == true
  end

  function frame:Raise()
    self.raised = true
    self.frameLevel = (self.frameLevel or 0) + 1
  end

  function frame:SetClipsChildren(value)
    self.clipsChildren = value == true
  end

  function frame:SetText(value)
    self.text = value
    if self.frameType == "EditBox" and type(self.scripts.OnTextChanged) == "function" and not self.__settingText then
      self.__settingText = true
      self.scripts.OnTextChanged(self)
      self.__settingText = false
    end
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

  function frame:SetResizable(value)
    self.resizable = value == true
  end

  function frame:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
    self.resizeBounds = {
      minWidth = minWidth,
      minHeight = minHeight,
      maxWidth = maxWidth,
      maxHeight = maxHeight,
    }
  end

  function frame:RegisterForDrag(...)
    self.dragButtons = { ... }
  end

  function frame:StartMoving()
    self.moving = true
  end

  function frame:StartSizing(point)
    self.sizing = true
    self.sizingPoint = point
  end

  function frame:StopMovingOrSizing()
    self.moving = false
    self.sizing = false
  end

  function frame:SetAutoFocus(value)
    self.autoFocus = value == true
  end

  function frame:SetTextInsets(left, right, top, bottom)
    self.textInsets = {
      left = left,
      right = right,
      top = top,
      bottom = bottom,
    }
  end

  function frame:SetJustifyH(value)
    self.justifyH = value
  end

  function frame:SetJustifyV(value)
    self.justifyV = value
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
    local handler = self.scripts.OnClick or self.scripts.OnMouseUp
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
        self.__commMessages = self.__commMessages or {}
        self.__lastCommMessage = {
          prefix = prefix,
          message = message,
          distribution = distribution,
          target = targetPlayer,
          priority = priority,
        }
        self.__commMessages[#self.__commMessages + 1] = self.__lastCommMessage
      end
    end,
  }

  libraries["AceSerializer-3.0"] = {
    Embed = function(_, target)
      function target:Serialize(payload)
        serializedSequence = serializedSequence + 1
        local token = ("RPA_SERIALIZED:%d"):format(serializedSequence)
        state.serializedPayloads[token] = copyTable(payload)

        return token
      end

      function target:Deserialize(payload)
        if type(payload) == "string" and state.serializedPayloads[payload] then
          return true, copyTable(state.serializedPayloads[payload])
        end

        if type(payload) == "table" then
          return true, payload
        end

        return false, nil
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

  if state.noAceAddon then
    libraries["AceAddon-3.0"] = nil
  end

  local libStub = {}
  setmetatable(libStub, {
    __call = function(_, libraryName, silent)
      local library = libraries[libraryName]
      if library or silent then
        return library
      end

      error("missing library: " .. tostring(libraryName))
    end,
  })

  return libStub
end

local function storeNativeComm(prefix, message, distribution, target)
  state.nativeCommMessages = state.nativeCommMessages or {}

  local maxBytes = tonumber(state.nativeCommMaxBytes or 0) or 0
  if maxBytes > 0 and type(message) == "string" and #message > maxBytes then
    state.nativeCommRejectedMessages = state.nativeCommRejectedMessages or {}
    state.nativeCommRejectedMessages[#state.nativeCommRejectedMessages + 1] = {
      prefix = prefix,
      message = message,
      distribution = distribution,
      target = target,
      length = #message,
    }

    return false
  end

  state.lastNativeCommMessage = {
    prefix = prefix,
    message = message,
    distribution = distribution,
    target = target,
  }
  state.nativeCommMessages[#state.nativeCommMessages + 1] = state.lastNativeCommMessage

  if type(state.nativeCommSendResults) == "table" and #state.nativeCommSendResults > 0 then
    return table.remove(state.nativeCommSendResults, 1)
  end

  return true
end

local function loadAddonFromToc(path)
  local tocPath = path or DEFAULT_TOC_PATH
  local addonDirectory = getDirectory(tocPath)

  for line in io.lines(tocPath) do
    local entry = line:match("^%s*(.-)%s*$")
    if entry ~= "" and not entry:match("^##") then
      if not entry:match("^Libs[\\/]") then
        local entryPath = addonDirectory and (addonDirectory .. "/" .. entry) or entry
        dofile(entryPath)
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
    guildRosterRequestCount = 0,
    isGuildOfficer = seed.isGuildOfficer,
    realmName = seed.realmName or "Stormrage",
    normalizedRealmName = seed.normalizedRealmName,
    playerName = seed.playerName or "Ziri",
    now = seed.now or seed.serverTime or 1717336800,
    savedVariables = seed.savedVariables,
    ace3 = seed.ace3,
    noAceAddon = seed.noAceAddon,
    nativeComm = seed.nativeComm,
    nativeCommMaxBytes = seed.nativeCommMaxBytes,
    nativeCommSendResults = seed.nativeCommSendResults,
    loggedIn = seed.loggedIn == true,
    serializedPayloads = {},
    chatMessages = {},
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

  _G.GetNormalizedRealmName = seed.disableNormalizedRealmName and nil or function()
    if state.normalizedRealmName then
      return state.normalizedRealmName
    end

    return (state.realmName or ""):gsub("[%s%p]", "")
  end

  _G.GetServerTime = function()
    return state.now
  end

  _G.GetTime = function()
    return state.now
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
    GuildRoster = function()
      state.guildRosterRequestCount = state.guildRosterRequestCount + 1
      return true
    end,
  }

  _G.GuildRoster = function()
    state.guildRosterRequestCount = state.guildRosterRequestCount + 1
    return true
  end

  _G.C_ChatInfo = state.nativeComm and {
    RegisterAddonMessagePrefix = function(prefix)
      state.nativeCommPrefix = prefix
    end,
    SendAddonMessage = function(prefix, message, distribution, target)
      return storeNativeComm(prefix, message, distribution, target)
    end,
  } or nil
  _G.Enum = {
    SendAddonMessageResult = {
      Success = 0,
      InvalidPrefix = 1,
      InvalidMessage = 2,
      AddonMessageThrottle = 3,
      InvalidChatType = 4,
      NotInGroup = 5,
      TargetRequired = 6,
      InvalidChannel = 7,
      ChannelThrottle = 8,
      GeneralError = 9,
      NotInGuild = 10,
      AddOnMessageLockdown = 11,
      TargetOffline = 12,
    },
  }

  _G.GetNumGuildMembers = function()
    return #state.guildMembers
  end

  _G.GetGuildRosterInfo = function(index)
    local member = state.guildMembers[index]
    if not member then
      return nil
    end

    return member.name,
      member.rankName or "Member",
      member.rankIndex or 9,
      nil,
      nil,
      nil,
      nil,
      nil,
      member.online ~= false
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
  _G.UISpecialFrames = {}
  _G.os = originalOs
  _G.CreateFrame = createFrameObject
  _G.UIParent = {}
  _G.DEFAULT_CHAT_FRAME = {
    AddMessage = function(_, line)
      state.chatMessages[#state.chatMessages + 1] = line
    end,
  }
  _G.IsLoggedIn = function()
    return state.loggedIn == true
  end
  _G.ChatThrottleLib = state.ace3 and {} or nil
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

function wow.setGuildMembers(guildMembers)
  state.guildMembers = guildMembers or {}
end

function wow.setTime(now)
  state.now = now
end

function wow.getState()
  return state
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

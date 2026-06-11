local function isCallable(value)
  if type(value) == "function" then
    return true
  end

  local metatable = type(value) == "table" and getmetatable(value) or nil

  return type(metatable) == "table" and type(metatable.__call) == "function"
end

local function createAddonObject()
  local existing = _G.RollingPinAwards or {}
  local libStub = rawget(_G, "LibStub")
  existing.__rpaLibStubPresent = isCallable(libStub)
  existing.__rpaChatThrottleLibPresent = type(rawget(_G, "ChatThrottleLib")) == "table"

  if not isCallable(libStub) then
    existing.__rpaUsesAce3 = false

    return existing
  end

  local embedded = {}
  local function embedLibrary(libraryName)
    local ok, library = pcall(libStub, libraryName, true)
    if not ok then
      embedded[libraryName] = false
      return false
    end

    if library and type(library.Embed) == "function" then
      library:Embed(existing)
      embedded[libraryName] = true
      return true
    end

    embedded[libraryName] = false
    return false
  end

  embedLibrary("AceEvent-3.0")
  embedLibrary("AceConsole-3.0")
  embedLibrary("AceComm-3.0")
  embedLibrary("AceSerializer-3.0")

  existing.__rpaAceLibraries = embedded
  existing.__rpaUsesAce3 = embedded["AceComm-3.0"] == true
    or embedded["AceSerializer-3.0"] == true
    or embedded["AceConsole-3.0"] == true
    or embedded["AceEvent-3.0"] == true

  return existing
end

local RPA = createAddonObject()
_G.RollingPinAwards = RPA

return RPA

local harness = require("tests.TestHarness")

local function readLines(path)
  local lines = {}

  for line in io.lines(path) do
    lines[#lines + 1] = line
  end

  return lines
end

local function indexOf(lines, exactValue)
  for index, line in ipairs(lines) do
    if line == exactValue then
      return index
    end
  end

  return nil
end

return {
  ["toc declares support for retail 12.1.0"] = function()
    local lines = readLines(harness.addon_path("RollingPinAwards.toc"))

    harness.assert_equal("## Interface: 120100, 120007, 120005", lines[1])
  end,

  ["toc groups the addon under the guild category"] = function()
    local lines = readLines(harness.addon_path("RollingPinAwards.toc"))

    harness.assert_true(indexOf(lines, "## Category: Guild") ~= nil)
  end,

  ["toc embeds required ace3 library files in load order"] = function()
    local lines = readLines(harness.addon_path("RollingPinAwards.toc"))

    local libStubIndex = indexOf(lines, "Libs/LibStub/LibStub.lua")
    local callbackIndex = indexOf(lines, "Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua")
    local aceAddonIndex = indexOf(lines, "Libs/AceAddon-3.0/AceAddon-3.0.lua")
    local aceDBIndex = indexOf(lines, "Libs/AceDB-3.0/AceDB-3.0.lua")
    local aceEventIndex = indexOf(lines, "Libs/AceEvent-3.0/AceEvent-3.0.lua")
    local aceConsoleIndex = indexOf(lines, "Libs/AceConsole-3.0/AceConsole-3.0.lua")
    local aceCommIndex = indexOf(lines, "Libs/AceComm-3.0/AceComm-3.0.lua")
    local aceSerializerIndex = indexOf(lines, "Libs/AceSerializer-3.0/AceSerializer-3.0.lua")
    local chatThrottleIndex = indexOf(lines, "Libs/AceComm-3.0/ChatThrottleLib.lua")
    local namespaceIndex = indexOf(lines, "Core/Namespace.lua")
    local constantsIndex = indexOf(lines, "Core/Constants.lua")
    local defaultsIndex = indexOf(lines, "Data/Defaults.lua")
    local databaseIndex = indexOf(lines, "Data/Database.lua")
    local awardsIndex = indexOf(lines, "Domain/Awards.lua")
    local syncCodecIndex = indexOf(lines, "Sync/Codec.lua")
    local syncTransportIndex = indexOf(lines, "Sync/Transport.lua")
    local syncCoordinatorIndex = indexOf(lines, "Sync/Coordinator.lua")
    local bootstrapIndex = indexOf(lines, "Bootstrap.lua")
    local minimapIndex = indexOf(lines, "UI/MinimapButton.lua")
    local eventsIndex = indexOf(lines, "Core/Events.lua")

    harness.assert_true(libStubIndex ~= nil)
    harness.assert_true(callbackIndex ~= nil)
    harness.assert_true(aceAddonIndex ~= nil)
    harness.assert_true(aceDBIndex ~= nil)
    harness.assert_true(aceEventIndex ~= nil)
    harness.assert_true(aceConsoleIndex ~= nil)
    harness.assert_true(aceCommIndex ~= nil)
    harness.assert_true(aceSerializerIndex ~= nil)
    harness.assert_true(chatThrottleIndex ~= nil)
    harness.assert_true(namespaceIndex ~= nil)
    harness.assert_true(constantsIndex ~= nil)
    harness.assert_true(defaultsIndex ~= nil)
    harness.assert_true(databaseIndex ~= nil)
    harness.assert_true(awardsIndex ~= nil)
    harness.assert_true(syncCodecIndex ~= nil)
    harness.assert_true(syncTransportIndex ~= nil)
    harness.assert_true(syncCoordinatorIndex ~= nil)
    harness.assert_true(bootstrapIndex ~= nil)
    harness.assert_true(minimapIndex ~= nil)
    harness.assert_true(eventsIndex ~= nil)

    harness.assert_true(libStubIndex < callbackIndex)
    harness.assert_true(callbackIndex < aceAddonIndex)
    harness.assert_true(aceAddonIndex < aceDBIndex)
    harness.assert_true(aceDBIndex < aceEventIndex)
    harness.assert_true(aceEventIndex < aceConsoleIndex)
    harness.assert_true(aceConsoleIndex < aceCommIndex)
    harness.assert_true(chatThrottleIndex < aceCommIndex)
    harness.assert_true(aceSerializerIndex < namespaceIndex)
    harness.assert_true(namespaceIndex < constantsIndex)
    harness.assert_true(constantsIndex < defaultsIndex)
    harness.assert_true(defaultsIndex < databaseIndex)
    harness.assert_true(databaseIndex < awardsIndex)
    harness.assert_true(awardsIndex < syncCodecIndex)
    harness.assert_true(syncCodecIndex < syncTransportIndex)
    harness.assert_true(syncTransportIndex < syncCoordinatorIndex)
    harness.assert_true(syncCoordinatorIndex < bootstrapIndex)
    harness.assert_true(bootstrapIndex < minimapIndex)
    harness.assert_true(minimapIndex < eventsIndex)
  end,

  ["embedded ace3 library directories exist"] = function()
    local requiredFiles = {
      "Libs/LibStub/LibStub.lua",
      "Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua",
      "Libs/AceAddon-3.0/AceAddon-3.0.lua",
      "Libs/AceDB-3.0/AceDB-3.0.lua",
      "Libs/AceEvent-3.0/AceEvent-3.0.lua",
      "Libs/AceConsole-3.0/AceConsole-3.0.lua",
      "Libs/AceComm-3.0/AceComm-3.0.lua",
      "Libs/AceComm-3.0/ChatThrottleLib.lua",
      "Libs/AceSerializer-3.0/AceSerializer-3.0.lua",
    }

    for _, path in ipairs(requiredFiles) do
      local handle = io.open(harness.addon_path(path), "r")
      harness.assert_true(handle ~= nil)
      if handle then
        handle:close()
      end
    end
  end,
}

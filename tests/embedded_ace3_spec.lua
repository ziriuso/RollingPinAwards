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
  ["toc declares support for retail 12.0.7"] = function()
    local lines = readLines("RollingPinAwards.toc")

    harness.assert_equal("## Interface: 120007, 120005", lines[1])
  end,

  ["toc embeds required ace3 library files in load order"] = function()
    local lines = readLines("RollingPinAwards.toc")

    local libStubIndex = indexOf(lines, "Libs/LibStub/LibStub.lua")
    local callbackIndex = indexOf(lines, "Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua")
    local aceAddonIndex = indexOf(lines, "Libs/AceAddon-3.0/AceAddon-3.0.lua")
    local aceDBIndex = indexOf(lines, "Libs/AceDB-3.0/AceDB-3.0.lua")
    local aceEventIndex = indexOf(lines, "Libs/AceEvent-3.0/AceEvent-3.0.lua")
    local aceConsoleIndex = indexOf(lines, "Libs/AceConsole-3.0/AceConsole-3.0.lua")
    local aceCommIndex = indexOf(lines, "Libs/AceComm-3.0/AceComm-3.0.lua")
    local aceSerializerIndex = indexOf(lines, "Libs/AceSerializer-3.0/AceSerializer-3.0.lua")
    local chatThrottleIndex = indexOf(lines, "Libs/AceComm-3.0/ChatThrottleLib.lua")
    local constantsIndex = indexOf(lines, "Constants.lua")

    harness.assert_true(libStubIndex ~= nil)
    harness.assert_true(callbackIndex ~= nil)
    harness.assert_true(aceAddonIndex ~= nil)
    harness.assert_true(aceDBIndex ~= nil)
    harness.assert_true(aceEventIndex ~= nil)
    harness.assert_true(aceConsoleIndex ~= nil)
    harness.assert_true(aceCommIndex ~= nil)
    harness.assert_true(aceSerializerIndex ~= nil)
    harness.assert_true(chatThrottleIndex ~= nil)
    harness.assert_true(constantsIndex ~= nil)

    harness.assert_true(libStubIndex < callbackIndex)
    harness.assert_true(callbackIndex < aceAddonIndex)
    harness.assert_true(aceAddonIndex < aceDBIndex)
    harness.assert_true(aceDBIndex < aceEventIndex)
    harness.assert_true(aceEventIndex < aceConsoleIndex)
    harness.assert_true(aceConsoleIndex < aceCommIndex)
    harness.assert_true(aceSerializerIndex < constantsIndex)
    harness.assert_true(chatThrottleIndex < aceCommIndex)
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
      local handle = io.open(path, "r")
      harness.assert_true(handle ~= nil)
      if handle then
        handle:close()
      end
    end
  end,
}

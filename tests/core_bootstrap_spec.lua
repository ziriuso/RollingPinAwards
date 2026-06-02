local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["core bootstrap exposes addon constants and slash command metadata"] = function()
    wow.reset()
    dofile("Core.lua")
    local addon = _G.RollingPinAwards

    harness.assert_equal("RollingPinAwards", addon.ADDON_NAME)
    harness.assert_equal("/rpa", addon.SLASH_COMMAND)
    harness.assert_true(type(addon.OnInitialize) == "function")
  end,

  ["core bootstrap reuses a shared addon namespace"] = function()
    wow.reset()
    local shared = {
      existingValue = "kept",
    }

    _G.RollingPinAwards = shared
    dofile("Core.lua")

    harness.assert_true(_G.RollingPinAwards == shared)
    harness.assert_equal("kept", _G.RollingPinAwards.existingValue)
    harness.assert_equal("RollingPinAwards", _G.RollingPinAwards.ADDON_NAME)
  end,
}

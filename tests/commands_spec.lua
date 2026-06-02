local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["slash command routes nominate requests to the nominations service"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local called = false
    addon.nominations.Create = function(_, nominee, reason)
      called = nominee == "Burny-Stormrage" and reason == "Pulled the boss"

      return {}
    end

    addon.commands:Handle('nominate Burny-Stormrage "Pulled the boss"')

    harness.assert_true(called)
  end,

  ["slash command bootstraps the addon without manual initialization"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      loggedIn = true,
    })

    local addon = wow.loadAddon()

    harness.assert_true(type(_G.SlashCmdList.ROLLINGPINAWARDS) == "function")
    harness.assert_true(addon.__rpaInitialized ~= true)
    harness.assert_true(_G.SlashCmdList.ROLLINGPINAWARDS("") == true)
    harness.assert_true(addon.__rpaInitialized == true)
    harness.assert_true(addon.__rpaEnabled == true)
    harness.assert_true(addon.mainFrame.frame.visible == true)
  end,

  ["startup events initialize and enable the addon in ace mode"] = function()
    wow.reset({
      ace3 = true,
      guildName = "Raid Bakery",
    })

    local addon = wow.loadAddon()

    harness.assert_true(addon.__rpaInitialized ~= true)
    wow.fireEvent("ADDON_LOADED", "RollingPinAwards")
    harness.assert_true(addon.__rpaInitialized == true)

    wow.setLoggedIn(true)
    wow.fireEvent("PLAYER_LOGIN")
    harness.assert_true(addon.__rpaEnabled == true)
    harness.assert_true(addon.__aceCommPrefix == addon.Constants.COMM_PREFIX)
  end,

  ["slash command toggles the main frame after ordinary startup"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_true(addon.mainFrame ~= nil)
    harness.assert_true(addon.uiBridge ~= nil)
    harness.assert_true(addon:HandleChatCommand("") == true)
    harness.assert_true(addon.mainFrame.frame.visible == true)
  end,
}

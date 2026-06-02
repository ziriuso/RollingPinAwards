local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["core bootstrap embeds ace addon methods when ace3 is available"] = function()
    wow.reset({
      ace3 = true,
      guildName = "Raid Bakery",
    })

    local addon = wow.loadAddon()

    harness.assert_true(type(addon.RegisterChatCommand) == "function")
    harness.assert_true(type(addon.RegisterComm) == "function")
    harness.assert_true(addon.__rpaUsesAce3 == true)
  end,

  ["on initialize registers the slash command through the native wow slash table in ace mode"] = function()
    wow.reset({
      ace3 = true,
      guildName = "Raid Bakery",
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_equal("/rpa", _G.SLASH_ROLLINGPINAWARDS1)
    harness.assert_true(type(_G.SlashCmdList.ROLLINGPINAWARDS) == "function")
  end,

  ["on enable registers the sync comm prefix through ace comm when available"] = function()
    wow.reset({
      ace3 = true,
      guildName = "Raid Bakery",
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon:OnEnable()

    harness.assert_equal(addon.Constants.COMM_PREFIX, addon.__aceCommPrefix)
  end,

  ["on initialize uses acedb profile storage when available"] = function()
    wow.reset({
      ace3 = true,
      guildName = "Raid Bakery",
      savedVariables = {
        profiles = {
          Default = {
            settings = {
              debug = true,
            },
          },
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_true(type(addon.aceDb) == "table")
    harness.assert_true(addon.db.storage.profile == addon.aceDb.profile)
    harness.assert_true(addon.aceDb.profile.settings.debug == true)
  end,
}

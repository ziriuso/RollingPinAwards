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
    harness.assert_true(type(addon.SendCommMessage) == "function")
    harness.assert_true(type(addon.Serialize) == "function")
    harness.assert_true(addon.__rpaUsesAce3 == true)
    harness.assert_true(addon.__rpaLibStubPresent == true)
  end,

  ["core bootstrap embeds ace comm and serializer without ace addon"] = function()
    wow.reset({
      ace3 = true,
      noAceAddon = true,
      guildName = "Raid Bakery",
    })

    local addon = wow.loadAddon()

    harness.assert_nil(addon.NewModule)
    harness.assert_true(type(addon.RegisterComm) == "function")
    harness.assert_true(type(addon.SendCommMessage) == "function")
    harness.assert_true(type(addon.Serialize) == "function")
    harness.assert_true(type(addon.Deserialize) == "function")
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
            guildDatasets = {},
          },
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_true(type(addon.aceDb) == "table")
    harness.assert_true(addon.db.storage.profile == addon.aceDb.profile)
    harness.assert_nil(addon.aceDb.profile.settings)
  end,
}

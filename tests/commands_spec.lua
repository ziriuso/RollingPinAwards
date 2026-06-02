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
}

local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["guild context activates a normalized dataset key when player is guilded"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      realmName = "Stormrage",
      playerName = "Ziri",
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local guild = addon:GetActiveGuildContext()
    harness.assert_true(type(addon.Constants) == "table")
    harness.assert_true(type(addon.Defaults) == "table")
    harness.assert_true(type(addon.GuildContext) == "table")
    harness.assert_equal("raid bakery", guild.guildKey)
    harness.assert_equal("Raid Bakery", guild.guildName)
  end,

  ["guild context prefers a stable guild identifier when available"] = function()
    wow.reset({
      guildClubId = 77,
      guildName = "Raid Bakery",
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local guild = addon:GetActiveGuildContext()
    harness.assert_equal("77", guild.guildKey)
  end,

  ["guild context is inactive when player is not in a guild"] = function()
    wow.reset()
    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_true(addon:GetActiveGuildContext() == nil)
  end,

  ["guild context refreshes lazily when guild info appears after initialization"] = function()
    wow.reset({
      guildName = nil,
      playerName = "Ziri",
      realmName = "Stormrage",
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_true(addon.activeGuildContext == nil)

    wow.setGuild("Raid Bakery", 77)

    local guild = addon:GetActiveGuildContext()

    harness.assert_true(guild ~= nil)
    harness.assert_equal("Raid Bakery", guild.guildName)
    harness.assert_equal("77", guild.guildKey)
  end,
}

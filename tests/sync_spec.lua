local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["sync rejects a privileged award update from the wrong guild"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local accepted = addon.sync:AcceptAward({
      guildKey = "other guild",
      awardedBy = "Officerone-Stormrage",
      awardId = "award:99",
    })

    harness.assert_true(accepted == false)
  end,

  ["sync rejects a privileged award update from an unauthorized sender"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      guildMembers = {
        {
          name = "Guildmaster-Stormrage",
          rankName = "Guild Master",
          rankIndex = 0,
        },
        {
          name = "Officerone-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local accepted = addon.sync:AcceptAward({
      guildKey = addon:GetActiveGuildContext().guildKey,
      awardedBy = "Officerone-Stormrage",
      awardId = "award:99",
      recipient = "Burny-Stormrage",
      reason = "Set the oven to lava",
      source = "direct",
    })

    harness.assert_true(accepted == false)
  end,

  ["sync accepts a same-guild privileged award update from a gm-authorized officer"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      guildMembers = {
        {
          name = "Guildmaster-Stormrage",
          rankName = "Guild Master",
          rankIndex = 0,
        },
        {
          name = "Officerone-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.permissions:GrantOfficerPermission("Officerone-Stormrage")

    local accepted = addon.sync:AcceptAward({
      guildKey = addon:GetActiveGuildContext().guildKey,
      awardedBy = "Officerone-Stormrage",
      awardId = "award:99",
      awardName = "The Burnt Rolling Pin",
      recipient = "Burny-Stormrage",
      player = "Burny-Stormrage",
      reason = "Set the oven to lava",
      source = "direct",
    })

    harness.assert_true(accepted)
    harness.assert_equal(1, #addon.awards:GetPublicHistory())
  end,
}

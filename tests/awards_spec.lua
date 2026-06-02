local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["authorized officer can approve a nomination and create an award"] = function()
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
        {
          name = "Bakerone-Stormrage",
          rankName = "Member",
          rankIndex = 5,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    addon.permissions:GrantOfficerPermission("Officerone-Stormrage")

    wow.setPlayer("Bakerone", "Member", 5)
    local nomination = addon.nominations:Create(
      "Burny-Stormrage",
      "Pulled the boss while fishing"
    )

    wow.setPlayer("Officerone", "Officer", 1)
    local award = addon.nominations:Approve(nomination.nominationId)
    local stored = addon.db:GetNomination(
      addon:GetActiveGuildContext().guildKey,
      nomination.nominationId
    )

    harness.assert_equal("nomination", award.source)
    harness.assert_equal("approved", stored.status)
    harness.assert_equal(1, #addon.awards:GetPublicHistory())
  end,

  ["rejected nominations remain out of public history"] = function()
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
          name = "Bakerone-Stormrage",
          rankName = "Member",
          rankIndex = 5,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    wow.setPlayer("Bakerone", "Member", 5)
    local nomination = addon.nominations:Create(
      "Burny-Stormrage",
      "Pulled the boss while fishing"
    )

    wow.setPlayer("Guildmaster", "Guild Master", 0)
    addon.nominations:Reject(nomination.nominationId)

    local stored = addon.db:GetNomination(
      addon:GetActiveGuildContext().guildKey,
      nomination.nominationId
    )

    harness.assert_equal("rejected", stored.status)
    harness.assert_equal(0, #addon.awards:GetPublicHistory())
  end,

  ["authorized officer can create a direct award"] = function()
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
    wow.setPlayer("Officerone", "Officer", 1)

    local award = addon.awards:CreateDirectAward(
      "Burny-Stormrage",
      "Set the oven to lava"
    )

    harness.assert_equal("direct", award.source)
    harness.assert_equal("Officerone-Stormrage", award.awardedBy)
    harness.assert_equal(1, #addon.awards:GetPublicHistory())
  end,

  ["authorized officer can create a direct award without os"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      serverTime = 1717336800,
    })
    _G.os = nil

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local award = addon.awards:CreateDirectAward(
      "Moonrustle-Stormrage",
      "Baiting Fae"
    )

    harness.assert_true(award ~= nil)
    harness.assert_equal(1717336800, award.createdAt)
  end,

  ["officer without addon permission cannot approve or directly award"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Officerone",
      guildRankName = "Officer",
      guildRankIndex = 1,
      guildMembers = {
        {
          name = "Officerone-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
        {
          name = "Bakerone-Stormrage",
          rankName = "Member",
          rankIndex = 5,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    wow.setPlayer("Bakerone", "Member", 5)
    local nomination = addon.nominations:Create(
      "Burny-Stormrage",
      "Pulled the boss while fishing"
    )

    wow.setPlayer("Officerone", "Officer", 1)
    local approved = addon.nominations:Approve(nomination.nominationId)
    local directAward = addon.awards:CreateDirectAward(
      "Burny-Stormrage",
      "Set the oven to lava"
    )

    harness.assert_true(approved == nil)
    harness.assert_true(directAward == nil)
    harness.assert_equal("pending", addon.db:GetNomination(
      addon:GetActiveGuildContext().guildKey,
      nomination.nominationId
    ).status)
    harness.assert_equal(0, #addon.awards:GetPublicHistory())
  end,
}

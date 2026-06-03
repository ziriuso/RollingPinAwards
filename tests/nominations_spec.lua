local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["guild member can create a pending nomination"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Bakerone",
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local nomination = addon.nominations:Create(
      "Burny-Stormrage",
      "Pulled the boss while fishing"
    )

    harness.assert_equal("pending", nomination.status)
    harness.assert_equal("Burny-Stormrage", nomination.nominee)
    harness.assert_equal("Bakerone-Stormrage", nomination.nominatedBy)
    harness.assert_true(nomination.nominationId ~= nil)
  end,

  ["guild member can create a pending nomination without os"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Bakerone",
      serverTime = 1717336800,
    })
    _G.os = nil

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local nomination = addon.nominations:Create(
      "Burny-Stormrage",
      "Pulled the boss while fishing"
    )

    harness.assert_true(nomination ~= nil)
    harness.assert_equal(1717336800, nomination.createdAt)
  end,

  ["guild member can cast one locked vote on a pending nomination"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Bakerone",
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local nomination = addon.nominations:Create(
      "Burny-Stormrage",
      "Pulled the boss while fishing"
    )
    local first = addon.nominations:CastVote(nomination.nominationId, "upvote")
    local second = addon.nominations:CastVote(nomination.nominationId, "downvote")
    local stored = addon.db:GetNomination(
      addon:GetActiveGuildContext().guildKey,
      nomination.nominationId
    )

    harness.assert_true(first)
    harness.assert_true(second == false)
    harness.assert_equal(1, stored.upvoteCount)
    harness.assert_equal(0, stored.downvoteCount)
  end,

  ["heavy downvotes auto-flag a pending nomination for officers"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Bakerone",
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local nomination = addon.nominations:Create(
      "Burny-Stormrage",
      "Pulled the boss while fishing"
    )

    wow.setPlayer("Bakerone")
    addon.nominations:CastVote(nomination.nominationId, "downvote")

    wow.setPlayer("Bakertwo")
    addon.nominations:CastVote(nomination.nominationId, "downvote")

    wow.setPlayer("Bakerthree")
    addon.nominations:CastVote(nomination.nominationId, "downvote")

    local stored = addon.db:GetNomination(
      addon:GetActiveGuildContext().guildKey,
      nomination.nominationId
    )

    harness.assert_equal(3, stored.downvoteCount)
    harness.assert_true(stored.moderationFlagged)
  end,
}

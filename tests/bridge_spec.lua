local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["bridge exposes public nomination rows with public upvote totals"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local nomination = addon.nominations:Create(
      "Burny-Stormrage",
      "Pulled the boss while fishing"
    )

    addon.nominations:CastVote(nomination.nominationId, "upvote")

    local rows = addon.uiBridge:GetPendingNominationsViewModel()

    harness.assert_equal(1, rows[1].upvotes)
    harness.assert_true(rows[1].downvotes == nil)
  end,

  ["bridge exposes officer moderation data only to authorized officer views"] = function()
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
        {
          name = "Bakertwo-Stormrage",
          rankName = "Member",
          rankIndex = 5,
        },
        {
          name = "Bakerthree-Stormrage",
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

    addon.nominations:CastVote(nomination.nominationId, "downvote")
    wow.setPlayer("Bakertwo", "Member", 5)
    addon.nominations:CastVote(nomination.nominationId, "downvote")
    wow.setPlayer("Bakerthree", "Member", 5)
    addon.nominations:CastVote(nomination.nominationId, "downvote")

    wow.setPlayer("Officerone", "Officer", 1)
    local rows = addon.uiBridge:GetAdminNominationsViewModel()

    harness.assert_equal(3, rows[1].downvotes)
    harness.assert_true(rows[1].moderationFlagged)
  end,

  ["main frame registers the expected tab ids"] = function()
    local MainFrame = dofile("UI/MainFrame.lua")
    local frame = MainFrame:New({
      uiBridge = {
        GetPendingNominationsViewModel = function()
          return {}
        end,
      },
    })

    harness.assert_equal("dashboard", frame.tabs[1].id)
    harness.assert_equal("admin", frame.tabs[6].id)
  end,
}

local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["leaderboard aggregates approved awards by recipient and sorts by count then recency"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      serverTime = 1717336800,
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

    _G.GetServerTime = function()
      return 1717336800
    end
    addon.awards:CreateDirectAward("Burny-Stormrage", "Set the oven to lava")

    _G.GetServerTime = function()
      return 1717423200
    end
    addon.awards:CreateDirectAward("Moonrustle-Stormrage", "Baiting Fae")

    wow.setPlayer("Bakerone", "Member", 5)
    _G.GetServerTime = function()
      return 1717509600
    end
    local nomination = addon.nominations:Create(
      "Burny-Stormrage",
      "Pulled the boss while fishing"
    )

    wow.setPlayer("Guildmaster", "Guild Master", 0)
    _G.GetServerTime = function()
      return 1717596000
    end
    addon.nominations:Approve(nomination.nominationId)

    local rows = addon.uiBridge:GetLeaderboardViewModel()

    harness.assert_equal(2, #rows)
    harness.assert_equal("Burny-Stormrage", rows[1].recipient)
    harness.assert_equal(2, rows[1].pinCount)
    harness.assert_equal("Moonrustle-Stormrage", rows[2].recipient)
    harness.assert_equal(1, rows[2].pinCount)
  end,

  ["combined leaderboard tallies burnt and golden awards separately"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    addon.awards:CreateDirectAward("Moonrustle-Moonguard", "Baiting Fae", "burnt")
    addon.awards:CreateDirectAward("Moonrustle-Moonguard", "Saved the raid", "golden")
    addon.awards:CreateDirectAward("Burny-Stormrage", "Set the oven to lava", "burnt")

    local rows = addon.uiBridge:GetLeaderboardViewModel("combined")

    harness.assert_equal(2, #rows)
    harness.assert_equal("Moonrustle-Moonguard", rows[1].recipient)
    harness.assert_equal(1, rows[1].burntCount)
    harness.assert_equal(1, rows[1].goldenCount)
    harness.assert_equal(2, rows[1].totalCount)
  end,

  ["dashboard top recipient uses combined tally and short display name"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    addon.awards:CreateDirectAward("Moonrustle-Moonguard", "Baiting Fae", "burnt")
    addon.awards:CreateDirectAward("Moonrustle-Moonguard", "Saved the raid", "golden")
    addon.awards:CreateDirectAward("Burny-Stormrage", "Set the oven to lava", "burnt")

    local viewModel = addon.uiBridge:GetDashboardViewModel()

    harness.assert_equal("Moonrustle", viewModel.topRecipient)
    harness.assert_equal(2, viewModel.topRecipientCount)
  end,

  ["leaderboard detail rows show date text and awarded-by display names"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      serverTime = 1717336800,
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

    _G.GetServerTime = function()
      return 1717336800
    end
    addon.awards:CreateDirectAward("Burny-Stormrage", "Set the oven to lava")

    wow.setPlayer("Bakerone", "Member", 5)
    _G.GetServerTime = function()
      return 1717423200
    end
    local nomination = addon.nominations:Create(
      "Burny-Stormrage",
      "Pulled the boss while fishing"
    )

    wow.setPlayer("Guildmaster", "Guild Master", 0)
    _G.GetServerTime = function()
      return 1717509600
    end
    addon.nominations:Approve(nomination.nominationId)

    local rows = addon.uiBridge:GetLeaderboardViewModel()
    local entries = rows[1].entries

    harness.assert_equal(2, #entries)
    harness.assert_equal("Bakerone-Stormrage", entries[1].displayAwardedBy)
    harness.assert_equal("Guildmaster-Stormrage", entries[2].displayAwardedBy)
    harness.assert_true(type(entries[1].dateText) == "string" and #entries[1].dateText > 0)
  end,

  ["leaderboard tab appears between history and settings"] = function()
    local MainFrame = dofile("UI/MainFrame.lua")
    local frame = MainFrame:New({
      uiBridge = {
        GetPendingNominationsViewModel = function()
          return {}
        end,
      },
    })

    harness.assert_equal("history", frame.tabs[4].id)
    harness.assert_equal("leaderboard", frame.tabs[5].id)
    harness.assert_equal("settings", frame.tabs[6].id)
  end,

  ["leaderboard view button opens a popup for the selected player"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      serverTime = 1717336800,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.awards:CreateDirectAward("Burny-Stormrage", "Set the oven to lava")

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("leaderboard")

    local panel = addon.mainFrame.tabPanels.leaderboard
    panel.listSection.rows[1].actions[1]:Click()

    harness.assert_true(panel.detailDialog.visible)
    harness.assert_true(panel.detailDialog.titleLabel.text:match("Burny%-Stormrage") ~= nil)
  end,

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

  ["admin moderation queue row includes the nomination reason"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.nominations:Create("Burny-Stormrage", "Pulled the boss while fishing")

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("admin")

    local panel = addon.mainFrame.tabPanels.admin

    harness.assert_true(panel.moderationSection.rows[1].label.text:match("Pulled the boss while fishing") ~= nil)
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
    harness.assert_equal("leaderboard", frame.tabs[5].id)
    harness.assert_equal("admin", frame.tabs[7].id)
  end,

  ["main frame renders the active tab summary into the content panel"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.nominations:Create("Burny-Stormrage", "Pulled the boss while fishing")

    addon.mainFrame:EnsureRendered()

    harness.assert_equal("Dashboard", addon.mainFrame.contentPanel.titleText.text)
    harness.assert_true(addon.mainFrame.tabPanels.dashboard ~= nil)
    harness.assert_equal("1", addon.mainFrame.tabPanels.dashboard.statCards[3].value.text)
  end,

  ["main frame builds the recomposed shell chrome containers"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()

    harness.assert_true(addon.mainFrame.frame.headerBand ~= nil)
    harness.assert_true(addon.mainFrame.frame.tabRail ~= nil)
    harness.assert_true(addon.mainFrame.contentPanel ~= nil)
    harness.assert_true(addon.mainFrame.contentPanel.contentHost ~= nil)
    harness.assert_true(addon.mainFrame.contentPanel.clipsChildren == true)
    harness.assert_true((addon.mainFrame.contentPanel.contentHost.frameLevel or 0) > (addon.mainFrame.contentPanel.innerShade.frameLevel or 0))
    harness.assert_equal("BACKGROUND", addon.mainFrame.contentPanel.innerShade.frameStrata)
    harness.assert_equal("MEDIUM", addon.mainFrame.contentPanel.contentHost.frameStrata)
    harness.assert_equal("Interface\\AddOns\\RollingPinAwards\\Media\\flameember.png", addon.mainFrame.frame.titleIcon.texturePath)
    harness.assert_true(addon.mainFrame.frame.titleIcon.texture ~= nil)
  end,

  ["tab rail layout keeps the admin button inside the rail width"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()

    local tabRail = addon.mainFrame.frame.tabRail
    local lastButton = addon.mainFrame.tabButtons[#addon.mainFrame.tabButtons]
    local leftOffset = lastButton.point and lastButton.point[4] or 0
    local rightEdge = leftOffset + (lastButton.width or 0)

    harness.assert_true(rightEdge <= (tabRail.width or 0))
  end,

  ["dashboard renders stats, content sections, and footer actions after recomposition"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.awards:CreateDirectAward("Burny-Stormrage", "Set the oven to lava")
    addon.nominations:Create("Moonrustle-Stormrage", "Baiting Fae")

    addon.mainFrame:EnsureRendered()

    local panel = addon.mainFrame.tabPanels.dashboard

    harness.assert_true(panel.statsSection ~= nil)
    harness.assert_equal(4, #(panel.statCards or {}))
    harness.assert_true(panel.leaderboardSection ~= nil)
    harness.assert_true(panel.recentAwardsSection ~= nil)
    harness.assert_true(panel.quickActionsSection ~= nil)
    harness.assert_true(panel.nominationButton ~= nil)
    harness.assert_true(panel.awardButton ~= nil)
    harness.assert_equal("Interface\\AddOns\\RollingPinAwards\\Media\\burntrollingpin.png", panel.statCards[1].iconFrame.texturePath)
    harness.assert_equal("Interface\\AddOns\\RollingPinAwards\\Media\\goldenrollingpin.png", panel.statCards[2].iconFrame.texturePath)
    harness.assert_equal("Interface\\AddOns\\RollingPinAwards\\Media\\flameember.png", panel.statCards[3].iconFrame.texturePath)
    harness.assert_equal("Interface\\AddOns\\RollingPinAwards\\Media\\rollingpin.png", panel.statCards[4].iconFrame.texturePath)
    harness.assert_equal("Interface\\AddOns\\RollingPinAwards\\Media\\rollingpin.png", panel.nominationButton.iconFrame.texturePath)
    harness.assert_equal("Interface\\AddOns\\RollingPinAwards\\Media\\burntrollingpin.png", panel.awardButton.iconFrame.texturePath)
  end,

  ["dashboard footer actions remain clickable after recomposition"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()

    local panel = addon.mainFrame.tabPanels.dashboard
    panel.nominationButton:Click()

    harness.assert_equal("nominations", addon.mainFrame.activeTabId)

    addon.mainFrame:SelectTab("dashboard")
    panel = addon.mainFrame.tabPanels.dashboard
    panel.awardButton:Click()

    harness.assert_equal("award", addon.mainFrame.activeTabId)
  end,

  ["clicking a tab button selects the tab and rerenders its content"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.nominations:Create("Burny-Stormrage", "Pulled the boss while fishing")

    addon.mainFrame:EnsureRendered()
    addon.mainFrame.tabButtons[3]:Click()

    harness.assert_equal("nominations", addon.mainFrame.activeTabId)
    harness.assert_equal("Nominations", addon.mainFrame.contentPanel.titleText.text)
    harness.assert_true(addon.mainFrame.tabPanels.nominations ~= nil)
    harness.assert_true(#addon.mainFrame.tabPanels.nominations.listSection.rows == 1)
  end,

  ["content panel is anchored into the addon instead of being a nested window"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()

    harness.assert_true(addon.mainFrame.contentPanel.closeButton == nil)
    harness.assert_true(addon.mainFrame.contentPanel.parent == addon.mainFrame.frame)
  end,

  ["switching tabs hides the previous panel instead of layering it"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()

    harness.assert_true(addon.mainFrame.tabPanels.dashboard.visible)
    addon.mainFrame:SelectTab("nominations")

    harness.assert_false(addon.mainFrame.tabPanels.dashboard.visible)
    harness.assert_true(addon.mainFrame.tabPanels.nominations.visible)
  end,

  ["bridge can submit a nomination and expose it in the pending view"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local nomination, err = addon.uiBridge:SubmitNomination("Burny-Stormrage", "Pulled the boss")
    local rows = addon.uiBridge:GetPendingNominationsViewModel()

    harness.assert_true(nomination ~= nil)
    harness.assert_nil(err)
    harness.assert_equal("Burny-Stormrage", rows[1].nominee)
  end,

  ["pending nominations show canonical nominee names when an alias mapping exists"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.db:UpsertAliasMapping("raid bakery", {
      aliasKey = "moon",
      aliasDisplay = "Moon",
      canonicalName = "Moonrustle-Stormrage",
      createdBy = "Guildmaster-Stormrage",
      createdAt = 1760000000,
    })

    addon.uiBridge:SubmitNomination("Moon", "Baiting Fae")

    local rows = addon.uiBridge:GetPendingNominationsViewModel()

    harness.assert_equal("Moonrustle-Stormrage", rows[1].nominee)
  end,

  ["moderation queue shows canonical nominee names when an alias mapping exists"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.db:UpsertAliasMapping("raid bakery", {
      aliasKey = "moon",
      aliasDisplay = "Moon",
      canonicalName = "Moonrustle-Stormrage",
      createdBy = "Guildmaster-Stormrage",
      createdAt = 1760000000,
    })
    addon.uiBridge:SubmitNomination("Moon", "Baiting Fae")

    local rows = addon.uiBridge:GetAdminNominationsViewModel()

    harness.assert_equal("Moonrustle-Stormrage", rows[1].nominee)
  end,

  ["history shows canonical recipient names when an alias mapping exists"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.db:UpsertAliasMapping("raid bakery", {
      aliasKey = "moon",
      aliasDisplay = "Moon",
      canonicalName = "Moonrustle-Stormrage",
      createdBy = "Guildmaster-Stormrage",
      createdAt = 1760000000,
    })
    addon.uiBridge:CreateDirectAward("Moon", "Baiting Fae")

    local rows = addon.uiBridge:GetPublicHistoryViewModel()

    harness.assert_equal("Moonrustle-Stormrage", rows[1].recipient)
  end,

  ["leaderboard groups aliases under one canonical recipient name"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.db:UpsertAliasMapping("raid bakery", {
      aliasKey = "moon",
      aliasDisplay = "Moon",
      canonicalName = "Moonrustle-Stormrage",
      createdBy = "Guildmaster-Stormrage",
      createdAt = 1760000000,
    })
    addon.db:UpsertAliasMapping("raid bakery", {
      aliasKey = "moonrustle",
      aliasDisplay = "Moonrustle",
      canonicalName = "Moonrustle-Stormrage",
      createdBy = "Guildmaster-Stormrage",
      createdAt = 1760000001,
    })
    addon.uiBridge:CreateDirectAward("Moon", "Baiting Fae")
    addon.uiBridge:CreateDirectAward("Moonrustle", "Set the oven to lava")
    addon.uiBridge:CreateDirectAward("Moonrustle-Stormrage", "Pulled the boss")

    local rows = addon.uiBridge:GetLeaderboardViewModel()

    harness.assert_equal(1, #rows)
    harness.assert_equal("Moonrustle-Stormrage", rows[1].recipient)
    harness.assert_equal(3, rows[1].pinCount)
  end,

  ["removing an alias mapping restores raw-name display"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.uiBridge:SaveAliasMapping("Moon", "Moonrustle-Stormrage")
    addon.uiBridge:SubmitNomination("Moon", "Baiting Fae")
    addon.uiBridge:DeleteAliasMapping("moon")

    local rows = addon.uiBridge:GetPendingNominationsViewModel()

    harness.assert_equal("Moon", rows[1].nominee)
  end,

  ["pending nominations remain visible when guild identity becomes more specific later"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      guildClubId = nil,
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local nomination, err = addon.uiBridge:SubmitNomination("Burny-Stormrage", "Pulled the boss")

    harness.assert_true(nomination ~= nil)
    harness.assert_nil(err)
    harness.assert_equal("raid bakery", nomination.guildKey)

    wow.setGuild("Raid Bakery", 77)

    local rows = addon.uiBridge:GetPendingNominationsViewModel()

    harness.assert_equal(1, #rows)
    harness.assert_equal("Burny-Stormrage", rows[1].nominee)
  end,

  ["bridge can save settings and return updated values"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local saved = addon.uiBridge:SaveSettings({
      tooltipEnabled = false,
      announceAwards = false,
      debug = true,
    })
    local settings = addon.uiBridge:GetSettingsViewModel()

    harness.assert_true(saved)
    harness.assert_false(settings.tooltipEnabled)
    harness.assert_false(settings.announceAwards)
    harness.assert_true(settings.debug)
  end,

  ["bridge exposes guild rank permissions by rank name for the admin view"] = function()
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
          name = "Veteran-Stormrage",
          rankName = "Veteran",
          rankIndex = 2,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    local saved = addon.uiBridge:SaveRankPermissions(1, "Officer", {
      canManageNominations = true,
      canCreateDirectAwards = false,
      canDeleteAwards = true,
      canManageAddonPermissions = false,
    })

    local matrix = addon.uiBridge:GetRankPermissionsViewModel()

    harness.assert_true(saved)
    harness.assert_true(matrix.canManageMatrix)
    harness.assert_equal("Officer", matrix.rows[2].rankName)
    harness.assert_true(matrix.rows[2].canManageNominations)
    harness.assert_true(matrix.rows[2].canDeleteAwards)
  end,

  ["unauthorized ranks cannot add or remove alias mappings through the bridge"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Officerone",
      guildRankName = "Officer",
      guildRankIndex = 1,
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

    local saved, saveError = addon.uiBridge:SaveAliasMapping("Moon", "Moonrustle-Stormrage")
    local deleted, deleteError = addon.uiBridge:DeleteAliasMapping("moon")

    harness.assert_true(saved == nil or saved == false)
    harness.assert_equal("unauthorized", saveError)
    harness.assert_true(deleted == nil or deleted == false)
    harness.assert_equal("unauthorized", deleteError)
  end,

  ["bridge rejects canonical alias targets that are not full character names"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local saved, err = addon.uiBridge:SaveAliasMapping("Moon", "Moonrustle")

    harness.assert_true(saved == nil or saved == false)
    harness.assert_equal("canonical name must include realm", err)
  end,

  ["main frame hides the admin tab when the player lacks addon-permission management"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Officerone",
      guildRankName = "Officer",
      guildRankIndex = 1,
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
    addon.mainFrame:EnsureRendered()

    harness.assert_false(addon.mainFrame.tabButtons[7].visible)
  end,

  ["main window provides a close button and backdrop"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:Toggle()

    harness.assert_true(addon.mainFrame.frame.backdrop ~= nil)
    harness.assert_true(addon.mainFrame.frame.closeButton ~= nil)

    addon.mainFrame.frame.closeButton:Click()

    harness.assert_false(addon.mainFrame.frame.visible)
  end,

  ["nominations tab submit button creates a pending nomination"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("nominations")

    local panel = addon.mainFrame.tabPanels.nominations
    panel.nomineeInput:SetText("Burny-Stormrage")
    panel.reasonInput:SetText("Pulled the boss")
    panel.submitButton:Click()

    local rows = addon.uiBridge:GetPendingNominationsViewModel()

    harness.assert_equal(1, #rows)
    harness.assert_equal("Burny-Stormrage", rows[1].nominee)
  end,

  ["nominations tab rerenders the public upvote count after voting"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.nominations:Create("Burny-Stormrage", "Pulled the boss")

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("nominations")

    local panel = addon.mainFrame.tabPanels.nominations
    panel.listSection.rows[1].actions[1]:Click()

    harness.assert_true(panel.listSection.rows[1].label.text:match("Upvotes: 1") ~= nil)
  end,

  ["settings tab save button persists checkboxes"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("settings")

    local panel = addon.mainFrame.tabPanels.settings
    panel.tooltipCheck:SetChecked(false)
    panel.announceCheck:SetChecked(false)
    panel.debugCheck:SetChecked(true)
    panel.saveButton:Click()

    local settings = addon.uiBridge:GetSettingsViewModel()

    harness.assert_false(settings.tooltipEnabled)
    harness.assert_false(settings.announceAwards)
    harness.assert_true(settings.debug)
  end,

  ["admin tab save button persists rank permissions for the selected guild rank"] = function()
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
    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("admin")

    local row = addon.mainFrame.tabPanels.admin.rankSection.rows[2]
    row.manageNominationsCheck:SetChecked(true)
    row.createAwardsCheck:SetChecked(true)
    row.deleteAwardsCheck:SetChecked(true)
    row.manageAddonCheck:SetChecked(false)
    row.saveButton:Click()

    local officerPermissions = addon.permissions:GetPermissionsForPlayer("Officerone-Stormrage")

    harness.assert_true(officerPermissions.canManageNominations)
    harness.assert_true(officerPermissions.canCreateDirectAwards)
    harness.assert_true(officerPermissions.canDeleteAwards)
    harness.assert_false(officerPermissions.canManageAddonPermissions)
  end,

  ["admin tab shows helper text describing each permission"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("admin")

    local panel = addon.mainFrame.tabPanels.admin

    harness.assert_true(panel.permissionHelpLabel.text:match("Manage Nominations") ~= nil)
    harness.assert_true(panel.permissionHelpLabel.text:match("Create Direct Awards") ~= nil)
    harness.assert_true(panel.permissionHelpLabel.text:match("Delete Awards") ~= nil)
    harness.assert_true(panel.permissionHelpLabel.text:match("Manage Addon Permissions/Settings") ~= nil)
  end,

  ["admin rank permissions list exposes a scrollbar for many guild ranks"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      guildRanks = {
        { name = "Guild Master" },
        { name = "Officer" },
        { name = "Officer Alt" },
        { name = "Raid Main" },
        { name = "Main" },
        { name = "Alt" },
        { name = "Trial" },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("admin")

    local section = addon.mainFrame.tabPanels.admin.rankSection

    harness.assert_true(section.scrollBar ~= nil)
    harness.assert_true(section.scrollBar.maxValue > 0)
  end,

  ["admin alias mappings list exposes a scrollbar for many mappings"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    for index = 1, 7 do
      addon.uiBridge:SaveAliasMapping(
        ("Moon%d"):format(index),
        ("Moonrustle%d-Stormrage"):format(index)
      )
    end

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("admin")

    local panel = addon.mainFrame.tabPanels.admin
    panel.aliasBrowseButton:Click()
    local section = panel.aliasDialog.listSection

    harness.assert_true(section.scrollBar ~= nil)
    harness.assert_true(section.scrollBar.maxValue > 0)
  end,

  ["award and nomination tabs support selecting golden rolling pin mode"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()

    addon.mainFrame:SelectTab("award")
    local awardPanel = addon.mainFrame.tabPanels.award
    awardPanel.typeGoldenButton:Click()
    harness.assert_equal("golden", awardPanel.selectedAwardType)

    addon.mainFrame:SelectTab("nominations")
    local nominationsPanel = addon.mainFrame.tabPanels.nominations
    nominationsPanel.typeGoldenButton:Click()
    harness.assert_equal("golden", nominationsPanel.selectedAwardType)
  end,

  ["reopening the addon keeps tab buttons interactive"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    addon.mainFrame:Toggle()
    addon.mainFrame:Toggle()
    addon.mainFrame:Toggle()
    addon.mainFrame.tabButtons[3]:Click()

    harness.assert_equal("nominations", addon.mainFrame.activeTabId)
  end,

  ["nominations list exposes a scrollbar for large result sets"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    for index = 1, 7 do
      addon.nominations:Create(("Burny%d-Stormrage"):format(index), ("Reason %d"):format(index))
    end

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("nominations")

    local section = addon.mainFrame.tabPanels.nominations.listSection

    harness.assert_true(section.scrollBar ~= nil)
    harness.assert_true(section.scrollBar.maxValue > 0)
  end,

  ["history tab delete action confirms and removes an award"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.awards:CreateDirectAward("Burny-Stormrage", "Set the oven to lava")

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("history")

    local panel = addon.mainFrame.tabPanels.history
    panel.listSection.rows[1].actions[1]:Click()
    panel.confirmDialog.confirmButton:Click()

    harness.assert_equal(0, #addon.uiBridge:GetPublicHistoryViewModel())
    harness.assert_false(panel.confirmDialog.visible)
  end,

  ["history rows include human-readable award dates"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      serverTime = 1717336800,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.awards:CreateDirectAward("Burny-Stormrage", "Set the oven to lava")

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("history")

    local rowText = addon.mainFrame.tabPanels.history.listSection.rows[1].label.text

    harness.assert_true(rowText:match("2024") ~= nil or rowText:match("%d%d%d%d%-%d%d%-%d%d") ~= nil)
  end,

  ["leaderboard list exposes a scrollbar for many recipients"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      serverTime = 1717336800,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    for index = 1, 7 do
      addon.awards:CreateDirectAward(("Burny%d-Stormrage"):format(index), ("Reason %d"):format(index))
    end

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("leaderboard")

    local section = addon.mainFrame.tabPanels.leaderboard.listSection

    harness.assert_true(section.scrollBar ~= nil)
    harness.assert_true(section.scrollBar.maxValue > 0)
  end,

  ["scrolling a large nominations list rerenders later rows"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    for index = 1, 7 do
      addon.nominations:Create(("Burny%d-Stormrage"):format(index), ("Reason %d"):format(index))
    end

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("nominations")

    local section = addon.mainFrame.tabPanels.nominations.listSection
    local firstBefore = section.rows[1].label.text

    section.scrollBar:SetValue(1)

    harness.assert_true(section.rows[1].label.text ~= firstBefore)
    harness.assert_true(section.rows[1].label.text:match("Burny2%-Stormrage") ~= nil)
  end,

  ["mouse wheel scrolling advances a large nominations list"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    for index = 1, 7 do
      addon.nominations:Create(("Burny%d-Stormrage"):format(index), ("Reason %d"):format(index))
    end

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("nominations")

    local section = addon.mainFrame.tabPanels.nominations.listSection
    local firstBefore = section.rows[1].label.text

    section:MouseWheel(-1)

    harness.assert_true(section.rows[1].label.text ~= firstBefore)
    harness.assert_true(section.rows[1].label.text:match("Burny2%-Stormrage") ~= nil)
  end,

  ["nominations row lays out vote and moderation buttons on separate columns"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.nominations:Create("Burny-Stormrage", "Pulled the boss")

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("nominations")

    local row = addon.mainFrame.tabPanels.nominations.listSection.rows[1]
    local upvoteButton = row.actions[1]
    local approveButton = row.actions[3]
    local downvoteButton = row.actions[2]
    local rejectButton = row.actions[4]

    harness.assert_true(downvoteButton.point[4] > upvoteButton.point[4])
    harness.assert_true(approveButton.point[5] < downvoteButton.point[5])
    harness.assert_true(rejectButton.point[5] == approveButton.point[5])
  end,
}

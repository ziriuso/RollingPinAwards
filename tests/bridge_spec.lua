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

  ["main frame renders the active tab summary into the content panel"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.nominations:Create("Burny-Stormrage", "Pulled the boss while fishing")

    addon.mainFrame:EnsureRendered()

    harness.assert_equal("Dashboard", addon.mainFrame.contentPanel.titleText.text)
    harness.assert_true(addon.mainFrame.tabPanels.dashboard ~= nil)
    harness.assert_true(addon.mainFrame.tabPanels.dashboard.pendingLabel.text:match("Pending nominations: 1") ~= nil)
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

    harness.assert_false(addon.mainFrame.tabButtons[6].visible)
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
}

local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

local BROWN = { 115 / 255, 64 / 255, 30 / 255, 1 }
local BUTTON_TAN = { 223 / 255, 198 / 255, 163 / 255, 1 }
local CARD_VALUE_GOLD = { 223 / 255, 150 / 255, 10 / 255, 1 }
local MODAL_FILL = { 197 / 255, 159 / 255, 107 / 255, 1 }
local NAV_VISUAL_ALIGNMENT_OFFSET = -26
local SOLID_BACKDROP = "Interface\\Buttons\\WHITE8x8"
local BLACK = { 0, 0, 0, 1 }
local WHITE = { 1, 1, 1, 1 }
local REGULAR_FONT = "Interface\\AddOns\\RollingPinAwards\\Media\\Fonts\\Roboto-Regular.ttf"
local BOLD_FONT = "Interface\\AddOns\\RollingPinAwards\\Media\\Fonts\\Roboto-Bold.ttf"
local AMARANTE_FONT = "Interface\\AddOns\\RollingPinAwards\\Media\\Fonts\\Amarante-Regular.ttf"
local CLEAN_CARD = "Interface\\AddOns\\RollingPinAwards\\Media\\cleancard.png"

local function assert_color(label, color)
  harness.assert_true(label.textColor ~= nil)
  harness.assert_equal(color[1], label.textColor.red)
  harness.assert_equal(color[2], label.textColor.green)
  harness.assert_equal(color[3], label.textColor.blue)
  harness.assert_equal(color[4], label.textColor.alpha)
end

local function assert_backdrop_color(frame, color)
  harness.assert_true(frame.backdrop ~= nil)
  harness.assert_equal(SOLID_BACKDROP, frame.backdrop.bgFile)
  harness.assert_equal(false, frame.backdrop.tile)
  harness.assert_true(frame.backdropColor ~= nil)
  harness.assert_equal(color[1], frame.backdropColor.red)
  harness.assert_equal(color[2], frame.backdropColor.green)
  harness.assert_equal(color[3], frame.backdropColor.blue)
  harness.assert_equal(color[4], frame.backdropColor.alpha)
end

local function assert_text_role(label, role, height, color, bold, fontFlags)
  harness.assert_equal(role, label.textRole)
  harness.assert_equal(height, label.fontHeight)
  if fontFlags then
    harness.assert_equal(fontFlags, label.fontFlags)
  else
    harness.assert_nil(label.fontFlags)
  end
  harness.assert_equal(bold == true and "bold" or nil, label.fontWeight)
  harness.assert_equal(bold == true and BOLD_FONT or REGULAR_FONT, label.fontFile)
  assert_color(label, color)
end

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
          name = "Officertwo-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
        {
          name = "Officerthree-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
      },
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

  ["reporting filter limits dashboard and leaderboard award counts without mutating history"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    _G.GetServerTime = function()
      return 1717200000
    end
    local oldAward = addon.awards:CreateDirectAward("Oldpin-Stormrage", "Older award", "burnt")

    _G.GetServerTime = function()
      return 1717336800
    end
    local startAward = addon.awards:CreateDirectAward("Moonrustle-Stormrage", "Start boundary", "golden")

    _G.GetServerTime = function()
      return 1717423200
    end
    local endAward = addon.awards:CreateDirectAward("Moonrustle-Stormrage", "End boundary", "burnt")

    _G.GetServerTime = function()
      return 1717600000
    end
    local futureAward = addon.awards:CreateDirectAward("Futurepin-Stormrage", "Future award", "golden")

    addon.db:SetReportingFilter({
      mode = "custom",
      label = "Test Window",
      startsAt = 1717336800,
      endsAt = 1717423200,
    })

    local dashboard = addon.uiBridge:GetDashboardViewModel()
    local leaderboard = addon.uiBridge:GetLeaderboardViewModel("combined")
    local history = addon.uiBridge:GetPublicHistoryViewModel()

    harness.assert_equal(2, dashboard.awardCount)
    harness.assert_equal("Moonrustle", dashboard.topRecipient)
    harness.assert_equal(2, dashboard.topRecipientCount)
    harness.assert_equal("Moonrustle", dashboard.latestAwardRecipient)
    harness.assert_equal(1, #leaderboard)
    harness.assert_equal("Moonrustle-Stormrage", leaderboard[1].recipient)
    harness.assert_equal(2, leaderboard[1].pinCount)
    harness.assert_equal(4, #history)
    harness.assert_equal(1717200000, oldAward.createdAt)
    harness.assert_equal(1717336800, startAward.createdAt)
    harness.assert_equal(1717423200, endAward.createdAt)
    harness.assert_equal(1717600000, futureAward.createdAt)
  end,

  ["bridge exposes sync peer rows newest first with short names and last seen dates"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    local guildKey = addon:GetActiveGuildContext().guildKey

    addon.db:RecordSyncPeer(guildKey, "Bakerone-Stormrage", 1717336800)
    addon.db:RecordSyncPeer(guildKey, "Bakertwo-Stormrage", 1717423200)

    local viewModel = addon.uiBridge:GetSyncPeersViewModel()

    harness.assert_equal(2, #viewModel.rows)
    harness.assert_equal("Bakertwo-Stormrage", viewModel.rows[1].player)
    harness.assert_equal("Bakertwo", viewModel.rows[1].shortPlayer)
    harness.assert_true(viewModel.rows[1].lastSeenText:match("%d%d%d%d%-%d%d%-%d%d") ~= nil)
    harness.assert_equal("Bakerone-Stormrage", viewModel.rows[2].player)
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
    harness.assert_equal("Bakerone", entries[1].displayAwardedBy)
    harness.assert_equal("Guildmaster", entries[2].displayAwardedBy)
    harness.assert_true(type(entries[1].dateText) == "string" and #entries[1].dateText > 0)
  end,

  ["admin tab replaces settings after leaderboard"] = function()
    local MainFrame = harness.dofile_addon("UI/MainFrame.lua")
    local frame = MainFrame:New({
      uiBridge = {
        GetPendingNominationsViewModel = function()
          return {}
        end,
      },
    })

    harness.assert_equal("history", frame.tabs[4].id)
    harness.assert_equal("leaderboard", frame.tabs[5].id)
    harness.assert_equal("admin", frame.tabs[6].id)
    harness.assert_nil(frame.tabs[7])
  end,

  ["leaderboard view button opens a showcase modal for the selected player"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      serverTime = 1717336800,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    local longReason = "Failing to celebrate his peeps by updating the Guild Message of the Day. WE GOT AOTC DAMNIT!!!!"
    addon.awards:CreateDirectAward("Moonrustle-Moonguard", longReason, "burnt")
    addon.awards:CreateDirectAward("Moonrustle-Moonguard", "Saved the raid", "golden")

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("leaderboard")

    local panel = addon.mainFrame.tabPanels.leaderboard
    panel.listSection.rows[1].actions[1]:Click()

    harness.assert_true(panel.detailDialog.visible)
    harness.assert_equal(addon.mainFrame.frame, panel.detailDialog.parent)
    harness.assert_equal("TOOLTIP", panel.detailDialog.frameStrata)
    harness.assert_true((panel.detailDialog.frameLevel or 0) > (addon.mainFrame.contentPanel.contentHost.frameLevel or 0))
    harness.assert_equal("Moonrustle", panel.detailDialog.titleLabel.text)
    harness.assert_equal("CENTER", panel.detailDialog.titleLabel.justifyH)
    harness.assert_equal(AMARANTE_FONT, panel.detailDialog.titleLabel.fontFile)
    harness.assert_equal(28, panel.detailDialog.titleLabel.fontHeight)
    assert_color(panel.detailDialog.titleLabel, CARD_VALUE_GOLD)
    harness.assert_true((panel.detailDialog.width or 0) >= 760)
    harness.assert_true((panel.detailDialog.height or 0) >= 820)
    harness.assert_equal(CLEAN_CARD, panel.detailDialog.backgroundArt.texturePath)
    harness.assert_true(panel.detailDialog.contentHost ~= nil)
    harness.assert_equal(0, panel.detailDialog.contentHost.point[4])
    harness.assert_equal(0, panel.detailDialog.contentHost.point[5])
    harness.assert_equal(panel.detailDialog.width, panel.detailDialog.contentHost.width)
    harness.assert_equal(panel.detailDialog.height, panel.detailDialog.contentHost.height)
    harness.assert_equal(panel.detailDialog.contentHost, panel.detailDialog.titleLabel.parent)
    harness.assert_equal(panel.detailDialog.contentHost, panel.detailDialog.goldenCountLabel.parent)
    harness.assert_equal(panel.detailDialog.contentHost, panel.detailDialog.burntCountLabel.parent)
    harness.assert_equal(panel.detailDialog.contentHost, panel.detailDialog.listSection.parent)
    harness.assert_equal(panel.detailDialog.contentHost, panel.detailDialog.closeButton.parent)
    harness.assert_true(panel.detailDialog.mouseEnabled)
    harness.assert_true(panel.detailDialog.movable)
    harness.assert_equal("LeftButton", panel.detailDialog.dragButtons[1])
    harness.assert_true(type(panel.detailDialog.scripts.OnDragStart) == "function")
    harness.assert_true(type(panel.detailDialog.scripts.OnDragStop) == "function")
    harness.assert_nil(panel.detailDialog.goldenIcon)
    harness.assert_nil(panel.detailDialog.burntIcon)
    harness.assert_equal(-72, panel.detailDialog.titleLabel.point[5])
    harness.assert_equal("1", panel.detailDialog.goldenCountLabel.text)
    harness.assert_equal("1", panel.detailDialog.burntCountLabel.text)
    harness.assert_equal(AMARANTE_FONT, panel.detailDialog.goldenCountLabel.fontFile)
    harness.assert_equal(AMARANTE_FONT, panel.detailDialog.burntCountLabel.fontFile)
    harness.assert_equal(24, panel.detailDialog.goldenCountLabel.fontHeight)
    harness.assert_equal(24, panel.detailDialog.burntCountLabel.fontHeight)
    assert_color(panel.detailDialog.goldenCountLabel, CARD_VALUE_GOLD)
    assert_color(panel.detailDialog.burntCountLabel, CARD_VALUE_GOLD)
    harness.assert_true((panel.detailDialog.goldenCountLabel.point[4] or 0) < (panel.detailDialog.burntCountLabel.point[4] or 0))
    harness.assert_equal(107, panel.detailDialog.goldenCountLabel.point[4])
    harness.assert_equal(557, panel.detailDialog.burntCountLabel.point[4])
    harness.assert_equal(-245, panel.detailDialog.burntCountLabel.point[5])
    harness.assert_equal(-245, panel.detailDialog.goldenCountLabel.point[5])
    harness.assert_equal(-296, panel.detailDialog.listSection.point[5])
    harness.assert_equal("BOTTOMRIGHT", panel.detailDialog.closeButton.point[1])
    harness.assert_equal(35, panel.detailDialog.closeButton.point[5])
    harness.assert_nil(panel.detailDialog.closeButton.backdrop)
    harness.assert_true(panel.detailDialog.closeButton.label == nil or panel.detailDialog.closeButton.label.text == "")
    harness.assert_equal("", panel.detailDialog.listSection.titleText.text)
    harness.assert_true(panel.detailDialog.listSection.iconFrame == nil)
    harness.assert_true(math.abs(panel.detailDialog.listSection.rows[1].point[5] or 0) <= 18)
    harness.assert_true((panel.detailDialog.listSection.width or 0) >= 600)
    harness.assert_true((panel.detailDialog.listSection.height or 0) >= 410)
    harness.assert_true(panel.detailDialog.listSection.scrollBar ~= nil)
    harness.assert_equal(2, #panel.detailDialog.listSection.rows)
    harness.assert_true((panel.detailDialog.listSection.rows[1].height or 0) > 56)
    harness.assert_true((panel.detailDialog.listSection.rows[1].label.width or 0) <= (panel.detailDialog.listSection.rows[1].width or 0) - 58)
    harness.assert_true(panel.detailDialog.listSection.rows[1].label.text:match("WE GOT AOTC DAMNIT!!!!") ~= nil)
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

    panel.moderationButton:Click()

    harness.assert_true(panel.moderationDialog.visible)
    harness.assert_true(panel.moderationDialog.listSection.rows[1].label.text:match("Pulled the boss while fishing") ~= nil)
  end,

  ["admin moderation queue filters statuses and removes bracketed status text"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    local approved = addon.nominations:Create("Mara-Stormrage", "Approved reason")
    local rejected = addon.nominations:Create("Shaka-Stormrage", "Rejected reason")
    addon.nominations:Create("Ziri-Stormrage", "Pending reason")
    addon.nominations:Approve(approved.nominationId)
    addon.nominations:Reject(rejected.nominationId)

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("admin")

    local panel = addon.mainFrame.tabPanels.admin
    panel.moderationButton:Click()

    harness.assert_equal("Moderation Queue (1)", panel.moderationButton.label.text)
    assert_backdrop_color(panel.moderationDialog, MODAL_FILL)
    harness.assert_true(panel.moderationDialog.pendingFilterButton ~= nil)
    harness.assert_true(panel.moderationDialog.approvedFilterButton ~= nil)
    harness.assert_true(panel.moderationDialog.rejectedFilterButton ~= nil)
    harness.assert_true(panel.moderationDialog.allFilterButton ~= nil)
    harness.assert_equal("", panel.moderationDialog.listSection.titleText.text)
    harness.assert_true(panel.moderationDialog.listSection.iconFrame == nil)
    harness.assert_true(panel.moderationDialog.listSection.rows[1].label.text:match("%[") == nil)
    harness.assert_true(panel.moderationDialog.listSection.rows[1].label.text:match("Pending reason") ~= nil)
    harness.assert_nil(panel.moderationDialog.listSection.rows[1].label.fontFlags)

    panel.moderationDialog.approvedFilterButton:Click()

    harness.assert_equal(1, #panel.moderationDialog.listSection.rows)
    harness.assert_true(panel.moderationDialog.listSection.rows[1].label.text:match("approved") ~= nil)
    harness.assert_true(panel.moderationDialog.listSection.rows[1].label.text:match("%[approved%]") == nil)
    harness.assert_true(panel.moderationDialog.listSection.rows[1].label.text:match("Approved reason") ~= nil)
    harness.assert_nil(panel.moderationDialog.listSection.rows[1].label.fontFlags)

    panel.moderationDialog.rejectedFilterButton:Click()

    harness.assert_equal(1, #panel.moderationDialog.listSection.rows)
    harness.assert_true(panel.moderationDialog.listSection.rows[1].label.text:match("rejected") ~= nil)
    harness.assert_true(panel.moderationDialog.listSection.rows[1].label.text:match("%[rejected%]") == nil)
    harness.assert_true(panel.moderationDialog.listSection.rows[1].label.text:match("Rejected reason") ~= nil)
    harness.assert_nil(panel.moderationDialog.listSection.rows[1].label.fontFlags)

    panel.moderationDialog.allFilterButton:Click()

    harness.assert_equal(3, #panel.moderationDialog.listSection.rows)
  end,

  ["main frame registers the expected tab ids"] = function()
    local MainFrame = harness.dofile_addon("UI/MainFrame.lua")
    local frame = MainFrame:New({
      uiBridge = {
        GetPendingNominationsViewModel = function()
          return {}
        end,
      },
    })

    harness.assert_equal("dashboard", frame.tabs[1].id)
    harness.assert_equal("leaderboard", frame.tabs[5].id)
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
    harness.assert_equal("1", addon.mainFrame.tabPanels.dashboard.statCards[3].value.text)
  end,

  ["main frame builds the recomposed shell chrome containers"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()

    harness.assert_true(addon.mainFrame.frame.backgroundArt ~= nil)
    harness.assert_equal("TOOLTIP", addon.mainFrame.frame.frameStrata)
    harness.assert_true((addon.mainFrame.frame.frameLevel or 0) >= 100)
    harness.assert_true(addon.mainFrame.frame.toplevel)
    harness.assert_true(addon.mainFrame.frame.keyboardEnabled)
    harness.assert_true(addon.mainFrame.frame.propagateKeyboardInput)
    harness.assert_equal(-28, addon.mainFrame.frame.hitRectInsets.left)
    harness.assert_equal(-88, addon.mainFrame.frame.hitRectInsets.right)
    harness.assert_equal(-145, addon.mainFrame.frame.hitRectInsets.top)
    harness.assert_equal(-44, addon.mainFrame.frame.hitRectInsets.bottom)
    harness.assert_equal("RollingPinAwardsMainFrame", _G.UISpecialFrames[1])
    harness.assert_equal("Interface\\AddOns\\RollingPinAwards\\Media\\addon-background.png", addon.mainFrame.frame.backgroundArt.texturePath)
    harness.assert_equal(addon.mainFrame.frame, addon.mainFrame.frame.backgroundArt.parent)
    harness.assert_equal("TOOLTIP", addon.mainFrame.frame.backgroundArt.frameStrata)
    harness.assert_true(addon.mainFrame.frame.backgroundArt.visible)
    harness.assert_equal(1000, addon.mainFrame.frame.backgroundArt.width)
    harness.assert_equal(925, addon.mainFrame.frame.backgroundArt.height)
    harness.assert_equal("TOPLEFT", addon.mainFrame.frame.backgroundArt.point[1])
    harness.assert_equal("TOPLEFT", addon.mainFrame.frame.backgroundArt.point[3])
    harness.assert_equal(-28, addon.mainFrame.frame.backgroundArt.point[4])
    harness.assert_equal(145, addon.mainFrame.frame.backgroundArt.point[5])
    harness.assert_nil(addon.mainFrame.frame.shadowFrame)
    harness.assert_nil(addon.mainFrame.frame.headerBand)
    harness.assert_nil(addon.mainFrame.frame.headerAccent)
    harness.assert_nil(addon.mainFrame.frame.headerLogo)
    harness.assert_true(addon.mainFrame.frame.tabRail ~= nil)
    harness.assert_equal("TOOLTIP", addon.mainFrame.frame.tabRail.frameStrata)
    harness.assert_nil(addon.mainFrame.frame.tabRail.backdrop)
    harness.assert_true(addon.mainFrame.frame.closeButton ~= nil)
    harness.assert_equal("TOPRIGHT", addon.mainFrame.frame.closeButton.point[1])
    harness.assert_equal("TOPRIGHT", addon.mainFrame.frame.closeButton.point[3])
    harness.assert_equal(82, addon.mainFrame.frame.closeButton.point[4])
    harness.assert_equal(139, addon.mainFrame.frame.closeButton.point[5])
    harness.assert_true(addon.mainFrame.settingsGearButton ~= nil)
    harness.assert_equal("Interface\\WorldMap\\GEAR_64GREY", addon.mainFrame.settingsGearButton.texturePath)
    harness.assert_equal("Interface\\WorldMap\\GEAR_64GREY", addon.mainFrame.settingsGearButton.icon.texturePath)
    harness.assert_equal("BOTTOMRIGHT", addon.mainFrame.settingsGearButton.point[1])
    harness.assert_equal(addon.mainFrame.frame.backgroundArt, addon.mainFrame.settingsGearButton.point[2])
    harness.assert_equal(-78, addon.mainFrame.settingsGearButton.point[4])
    harness.assert_true((addon.mainFrame.settingsGearButton.frameLevel or 0) > (addon.mainFrame.frame.backgroundArt.frameLevel or 0))
    harness.assert_true(addon.mainFrame.contentPanel ~= nil)
    harness.assert_equal("TOOLTIP", addon.mainFrame.contentPanel.frameStrata)
    harness.assert_nil(addon.mainFrame.contentPanel.backdrop)
    harness.assert_true(addon.mainFrame.contentPanel.contentHost ~= nil)
    harness.assert_equal("TOOLTIP", addon.mainFrame.contentPanel.contentHost.frameStrata)
    harness.assert_true(addon.mainFrame.contentPanel.contentHost.parent == addon.mainFrame.frame)
    harness.assert_true(addon.mainFrame.contentPanel.clipsChildren == true)
    harness.assert_nil(addon.mainFrame.contentPanel.innerShade)
    harness.assert_nil(addon.mainFrame.contentPanel.innerShadeTexture)
    harness.assert_true((addon.mainFrame.contentPanel.contentHost.frameLevel or 0) > (addon.mainFrame.contentPanel.frameLevel or 0))
    harness.assert_equal("", addon.mainFrame.frame.titleText.text)
    harness.assert_equal("", addon.mainFrame.frame.subtitleText.text)
    harness.assert_nil(addon.mainFrame.frame.subtitleText.fontFlags)
    harness.assert_equal(59, addon.mainFrame.contentPanel.titleText.point[4])
    assert_text_role(addon.mainFrame.contentPanel.titleText, "tabHeader", 24, BROWN, true)
    assert_text_role(addon.mainFrame.contentPanel.bodyText, "tabDescription", 16, BLACK, false)
  end,

  ["tab rail layout centers nav buttons inside a tighter rail"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()

    local tabRail = addon.mainFrame.frame.tabRail
    local background = addon.mainFrame.frame.backgroundArt
    local nominationsButton = addon.mainFrame.tabButtons[3]
    local historyButton = addon.mainFrame.tabButtons[4]
    local leaderboardButton = addon.mainFrame.tabButtons[5]
    local dashboardPanel = addon.mainFrame.tabPanels.dashboard
    local statCards = dashboardPanel.statCards
    local railLeft = tabRail.point and tabRail.point[4] or 0
    local backgroundLeft = background.point and background.point[4] or 0
    local nominationRight = railLeft
      + (nominationsButton.point and nominationsButton.point[4] or 0)
      + (nominationsButton.width or 0)
    local historyLeft = railLeft + (historyButton.point and historyButton.point[4] or 0)
    local navMiddleGapCenter = nominationRight + ((historyLeft - nominationRight) / 2)
    local dashboardLeft = (addon.mainFrame.contentPanel.point[4] or 0)
      + (addon.mainFrame.contentPanel.contentHost.point[4] or 0)
      + (dashboardPanel.point[4] or 0)
      + (dashboardPanel.statsSection.point[4] or 0)
    local dashboardMiddleGapCenter = dashboardLeft
      + (statCards[2].point[4] or 0)
      + (statCards[2].width or 0)
      + (((statCards[3].point[4] or 0) - ((statCards[2].point[4] or 0) + (statCards[2].width or 0))) / 2)

    harness.assert_equal(background.width, tabRail.width)
    harness.assert_equal(backgroundLeft, railLeft)
    harness.assert_true((nominationsButton.labelWidth or 0) >= #"Nominations" * 11)
    harness.assert_equal("Nominations", nominationsButton.label.text)
    harness.assert_true((leaderboardButton.labelWidth or 0) >= #"Leaderboard" * 11)
    harness.assert_equal("Leaderboard", leaderboardButton.label.text)
    harness.assert_equal(
      math.floor(dashboardMiddleGapCenter + NAV_VISUAL_ALIGNMENT_OFFSET + 0.5),
      math.floor(navMiddleGapCenter + 0.5)
    )
    assert_text_role(nominationsButton.label, "buttonText", 16, BUTTON_TAN, true)
    harness.assert_nil(nominationsButton.label.outlineLabels)
  end,

  ["tab rail uses original framed buttons for active and inactive page states"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()

    local dashboardButton = addon.mainFrame.tabButtons[1]
    local awardButton = addon.mainFrame.tabButtons[2]

    harness.assert_nil(dashboardButton.navTexture)
    harness.assert_nil(awardButton.navTexture)
    harness.assert_true(dashboardButton.backdrop ~= nil)
    harness.assert_true(awardButton.backdrop ~= nil)
    harness.assert_true(dashboardButton.label.visible)
    harness.assert_true(awardButton.label.visible)
    harness.assert_equal("selected", dashboardButton.variant)
    harness.assert_equal("secondary", awardButton.variant)
    harness.assert_true((dashboardButton.backdropColor.red or 0) < ((awardButton.backdropColor.red or 0) - 0.08))
    harness.assert_true((dashboardButton.backdropBorderColor.red or 0) > (awardButton.backdropBorderColor.red or 0))

    addon.mainFrame:SelectTab("award")

    harness.assert_equal("secondary", dashboardButton.variant)
    harness.assert_equal("selected", awardButton.variant)
    harness.assert_true((awardButton.backdropColor.red or 0) < ((dashboardButton.backdropColor.red or 0) - 0.08))
  end,

  ["tab rail centers nominations on the visual centerline when admin is hidden"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Memberone",
      guildRankName = "Member",
      guildRankIndex = 5,
      isGuildOfficer = false,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()

    local tabRail = addon.mainFrame.frame.tabRail
    local background = addon.mainFrame.frame.backgroundArt
    local visibleButtons = {}
    for _, button in ipairs(addon.mainFrame.tabButtons or {}) do
      if button.visible then
        visibleButtons[#visibleButtons + 1] = button
      end
    end

    harness.assert_equal(5, #visibleButtons)
    local nominationsButton = visibleButtons[3]
    local dashboardPanel = addon.mainFrame.tabPanels.dashboard
    local statCards = dashboardPanel.statCards
    local railLeft = tabRail.point and tabRail.point[4] or 0
    local nominationsCenter = railLeft
      + (nominationsButton.point and nominationsButton.point[4] or 0)
      + ((nominationsButton.width or 0) / 2)
    local dashboardLeft = (addon.mainFrame.contentPanel.point[4] or 0)
      + (addon.mainFrame.contentPanel.contentHost.point[4] or 0)
      + (dashboardPanel.point[4] or 0)
      + (dashboardPanel.statsSection.point[4] or 0)
    local dashboardMiddleGapCenter = dashboardLeft
      + (statCards[2].point[4] or 0)
      + (statCards[2].width or 0)
      + (((statCards[3].point[4] or 0) - ((statCards[2].point[4] or 0) + (statCards[2].width or 0))) / 2)

    harness.assert_equal("nominations", nominationsButton.id)
    harness.assert_equal(
      math.floor(dashboardMiddleGapCenter + NAV_VISUAL_ALIGNMENT_OFFSET + 0.5),
      math.floor(nominationsCenter + 0.5)
    )
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
    harness.assert_true(panel.statCards[1].iconFrame == nil)
    harness.assert_true(panel.statCards[2].iconFrame == nil)
    harness.assert_true(panel.statCards[3].iconFrame == nil)
    harness.assert_true(panel.statCards[4].iconFrame == nil)
    harness.assert_equal("Interface\\AddOns\\RollingPinAwards\\Media\\rollingpin.png", panel.nominationButton.iconFrame.texturePath)
    harness.assert_equal("Interface\\AddOns\\RollingPinAwards\\Media\\burnt-rolling-pin.png", panel.awardButton.iconFrame.texturePath)
    harness.assert_equal(panel.nominationButton.width, panel.leaderboardSection.width)
    harness.assert_equal(panel.awardButton.width, panel.recentAwardsSection.width)
    harness.assert_equal("CENTER", panel.statCards[1].label.justifyH)
    harness.assert_equal("CENTER", panel.statCards[1].value.justifyH)
    harness.assert_equal("TOP", panel.statCards[1].label.point[1])
    harness.assert_equal("BOTTOM", panel.statCards[1].detail.point[1])
    harness.assert_equal(12, math.abs(panel.statCards[1].label.point[5] or 0))
    harness.assert_equal(10, panel.statCards[1].detail.point[5] or 0)
    harness.assert_equal("CENTER", panel.statCards[1].value.point[1])
    harness.assert_equal("CENTER", panel.statCards[1].value.point[3])
    harness.assert_equal("Interface\\ChatFrame\\ChatFrameBackground", panel.statCards[1].backdrop.bgFile)
    harness.assert_true((panel.statCards[1].backdropColor.red or 0) >= 0.80)
    assert_text_role(panel.statCards[1].label, "cardHeader", 18, BROWN, true)
    assert_text_role(panel.statCards[1].value, "cardValue", 20, CARD_VALUE_GOLD, true)
    harness.assert_equal(0, panel.statCards[1].label.shadowColor.alpha)
    harness.assert_equal(0, panel.statCards[1].label.shadowOffset.x)
    harness.assert_equal(0, panel.statCards[1].label.shadowOffset.y)
    harness.assert_nil(panel.statCards[1].label.outlineLabels)
    harness.assert_nil(panel.statCards[1].label.outlineColor)
    harness.assert_equal("Interface\\ChatFrame\\ChatFrameBackground", panel.leaderboardSection.backdrop.bgFile)
    harness.assert_true((panel.leaderboardSection.backdropColor.red or 0) >= 0.80)
    harness.assert_true(panel.statCards[1].detail.text:match("ledger") == nil)
    harness.assert_equal("Total Guildwide", panel.statCards[1].detail.text)
    harness.assert_equal("Nominations", panel.statCards[3].label.text)
    harness.assert_equal("MIDDLE", panel.nominationButton.label.justifyV)

    local frame = addon.mainFrame.frame
    local contentPanel = addon.mainFrame.contentPanel
    local dashboardLeft = (contentPanel.point[4] or 0)
      + (contentPanel.contentHost.point[4] or 0)
      + (panel.point[4] or 0)
    local backgroundLeft = frame.backgroundArt.point[4] or 0
    local backgroundRight = backgroundLeft + (frame.backgroundArt.width or 0)
    local dashboardWidth = (panel.statCards[4].point[4] or 0) + (panel.statCards[4].width or 0)
    local leftMargin = dashboardLeft - backgroundLeft
    local rightMargin = backgroundRight - (dashboardLeft + dashboardWidth)

    harness.assert_equal(119, leftMargin)
    harness.assert_equal(119, rightMargin)
    harness.assert_equal(dashboardWidth, panel.leaderboardSection.width + 16 + panel.recentAwardsSection.width)
    harness.assert_equal(dashboardWidth, panel.nominationButton.width + 16 + panel.awardButton.width)
  end,

  ["dashboard recent awards clip long reasons and open a detail popup"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      serverTime = 1717336800,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    local longReason = "Failing to celebrate his peeps by updating the Guild Message of the Day. WE GOT AOTC DAMNIT!!!!"
    addon.awards:CreateDirectAward("Zirleficent-Stormrage", longReason, "burnt")

    addon.mainFrame:EnsureRendered()

    local panel = addon.mainFrame.tabPanels.dashboard
    local row = panel.recentAwardsSection.rows[1]

    harness.assert_true(row ~= nil)
    harness.assert_true(row.clickable)
    harness.assert_true(row.mouseEnabled)
    harness.assert_equal(3, row.label.maxLines)
    harness.assert_false(row.label.wordWrap)
    harness.assert_true(row.label.text:match(longReason) == nil)
    harness.assert_true(row.label.text:match("%.%.%.") ~= nil)

    row:Click()

    harness.assert_true(panel.awardDetailDialog.visible)
    harness.assert_equal("Award Details", panel.awardDetailDialog.titleLabel.text)
    harness.assert_true(panel.awardDetailDialog.reasonLabel.text:match("WE GOT AOTC DAMNIT!!!!") ~= nil)
    harness.assert_true(panel.awardDetailDialog.reasonLabel.text:match("%.%.%.") == nil)
  end,

  ["typography applies shared readable roles across pages"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.awards:CreateDirectAward("Zirleficent-Stormrage", "Good job")
    addon.mainFrame:EnsureRendered()

    local dashboard = addon.mainFrame.tabPanels.dashboard
    assert_text_role(addon.mainFrame.contentPanel.titleText, "tabHeader", 24, BROWN, true)
    assert_text_role(dashboard.heroLabel, "tabDescription", 16, BLACK, false)
    assert_text_role(dashboard.permissionLabel, "tabDescription", 16, BLACK, false)
    assert_text_role(dashboard.statCards[1].label, "cardHeader", 18, BROWN, true)
    assert_text_role(dashboard.statCards[1].value, "cardValue", 20, CARD_VALUE_GOLD, true)
    assert_text_role(dashboard.statCards[1].detail, "cardDescription", 16, BLACK, false)
    assert_text_role(dashboard.leaderboardSection.titleText, "cardHeader", 18, BROWN, true)
    assert_text_role(dashboard.leaderboardSection.rows[1].label, "tableRow", 14, BLACK, false)
    assert_text_role(dashboard.nominationButton.label, "buttonText", 16, BUTTON_TAN, true)

    addon.mainFrame:SelectTab("award")
    local award = addon.mainFrame.tabPanels.award
    assert_text_role(addon.mainFrame.contentPanel.titleText, "tabHeader", 24, BROWN, true)
    assert_text_role(award.formSection.titleText, "cardHeader", 18, BROWN, true)
    assert_text_role(award.helperLabel, "descriptionSmall", 12, BLACK, false)
    assert_text_role(award.recipientLabel, "fieldLabel", 16, BLACK, true)
    assert_text_role(award.reasonLabel, "fieldLabel", 16, BLACK, true)
    assert_text_role(award.submitButton.label, "buttonText", 16, BUTTON_TAN, true)
    harness.assert_true(award.briefSection.iconFrame == nil)

    addon.mainFrame:SelectTab("nominations")
    local nominations = addon.mainFrame.tabPanels.nominations
    assert_text_role(addon.mainFrame.contentPanel.titleText, "tabHeader", 24, BROWN, true)
    assert_text_role(nominations.formSection.titleText, "cardHeader", 18, BROWN, true)
    assert_text_role(nominations.helperLabel, "cardDescription", 16, BLACK, false)
    assert_text_role(nominations.nomineeLabel, "fieldLabel", 16, BLACK, true)
    assert_text_role(nominations.reasonLabel, "fieldLabel", 16, BLACK, true)
    assert_text_role(nominations.submitButton.label, "buttonText", 16, BUTTON_TAN, true)
    assert_text_role(nominations.listSection.rows[1].label, "tableEmpty", 14, WHITE, false)

    addon.mainFrame:SelectTab("history")
    local history = addon.mainFrame.tabPanels.history
    assert_text_role(addon.mainFrame.contentPanel.titleText, "tabHeader", 24, BROWN, true)
    assert_text_role(history.listSection.titleText, "cardHeader", 18, BROWN, true)

    addon.mainFrame:SelectTab("leaderboard")
    local leaderboard = addon.mainFrame.tabPanels.leaderboard
    assert_text_role(addon.mainFrame.contentPanel.titleText, "tabHeader", 24, BROWN, true)
    assert_text_role(leaderboard.listSection.titleText, "cardHeader", 18, BROWN, true)
    assert_text_role(leaderboard.burntModeButton.label, "buttonText", 16, BUTTON_TAN, true)
    harness.assert_equal("selected", leaderboard.combinedModeButton.variant)
    harness.assert_true((leaderboard.combinedModeButton.backdropColor.red or 0) < ((leaderboard.burntModeButton.backdropColor.red or 0) - 0.08))
    assert_color(leaderboard.combinedModeButton.label, CARD_VALUE_GOLD)

    addon.mainFrame:SelectTab("admin")
    local admin = addon.mainFrame.tabPanels.admin
    assert_text_role(addon.mainFrame.contentPanel.titleText, "tabHeader", 24, BROWN, true)
    assert_text_role(admin.rankSection.titleText, "cardHeader", 18, BROWN, true)
    assert_text_role(admin.permissionHelpLabel, "cardDescription", 16, BLACK, false)
    assert_text_role(admin.aliasSaveButton.label, "buttonText", 16, BUTTON_TAN, true)
    assert_text_role(admin.aliasDialog.titleLabel, "cardHeader", 18, BROWN, true)
    assert_text_role(admin.moderationDialog.titleLabel, "cardHeader", 18, BROWN, true)

    addon.mainFrame:ShowSettingsPage()
    local settings = addon.mainFrame.settingsPanel
    assert_text_role(addon.mainFrame.contentPanel.titleText, "tabHeader", 24, BROWN, true)
    assert_text_role(settings.toastSection.titleText, "cardHeader", 18, BROWN, true)
    assert_text_role(settings.toastsCheck.label, "cardDescription", 16, BLACK, false)
    harness.assert_equal("Toggle Anchors", settings.anchorButton.label.text)
    assert_text_role(settings.testToastButton.label, "buttonText", 16, BUTTON_TAN, true)
  end,

  ["dashboard list polish removes realms and indents recipient totals"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.awards:CreateDirectAward("Moonrustle-Moonguard", "Baiting Fae")

    addon.mainFrame:EnsureRendered()

    local panel = addon.mainFrame.tabPanels.dashboard

    harness.assert_true(panel.leaderboardSection.rows[1].label.text:match("\n    1 rolling pins") ~= nil)
    harness.assert_true(panel.recentAwardsSection.rows[1].label.text:match("Moonrustle%-Moonguard") == nil)
    harness.assert_true(panel.recentAwardsSection.rows[1].label.text:match("Guildmaster%-Stormrage") == nil)
    harness.assert_equal("rowHighlight", panel.leaderboardSection.rows[1].backdropTone)
    harness.assert_equal("rowHighlight", panel.recentAwardsSection.rows[1].backdropTone)
    harness.assert_equal("MIDDLE", panel.leaderboardSection.rows[1].label.justifyV)
    harness.assert_nil(panel.leaderboardSection.rows[1].label.fontFlags)
    harness.assert_nil(panel.recentAwardsSection.rows[1].label.fontFlags)
    harness.assert_true((panel.leaderboardSection.rows[1].width or 0) <= (panel.leaderboardSection.width or 0) - 48)
    harness.assert_equal(3, panel.leaderboardSection.visibleRowCount)
    local lastLeaderboardRow = panel.leaderboardSection.rows[#panel.leaderboardSection.rows]
    local lastLeaderboardBottom = math.abs(lastLeaderboardRow.point[5] or 0) + (lastLeaderboardRow.height or 0)
    harness.assert_true(lastLeaderboardBottom <= (panel.leaderboardSection.height or 0))
    harness.assert_equal(3, panel.recentAwardsSection.visibleRowCount)
    local lastRecentRow = panel.recentAwardsSection.rows[#panel.recentAwardsSection.rows]
    local lastRecentBottom = math.abs(lastRecentRow.point[5] or 0) + (lastRecentRow.height or 0)
    harness.assert_true(lastRecentBottom <= (panel.recentAwardsSection.height or 0))
  end,

  ["all tab panels use the parchment-safe dashboard content offset"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()

    local tabIds = { "dashboard", "award", "nominations", "history", "leaderboard", "admin" }
    for _, tabId in ipairs(tabIds) do
      addon.mainFrame:SelectTab(tabId)
      harness.assert_equal(59, addon.mainFrame.tabPanels[tabId].point[4])
    end
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

  ["settings bridge APIs are removed with the settings tab"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_nil(addon.uiBridge.GetSettingsViewModel)
    harness.assert_nil(addon.uiBridge.SaveSettings)
    harness.assert_nil(addon.db.storage.profile.settings)
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

    harness.assert_false(addon.mainFrame.tabButtons[6].visible)
  end,

  ["main window provides a close button and background artwork"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:Toggle()

    harness.assert_true(addon.mainFrame.frame.backgroundArt ~= nil)
    harness.assert_true(addon.mainFrame.frame.backgroundArt.visible)
    harness.assert_true(addon.mainFrame.frame.closeButton ~= nil)

    harness.assert_true(type(addon.mainFrame.frame.scripts.OnKeyDown) == "function")
    addon.mainFrame.frame.scripts.OnKeyDown(addon.mainFrame.frame, "SPACE")
    harness.assert_true(addon.mainFrame.frame.visible)
    harness.assert_true(addon.mainFrame.frame.propagateKeyboardInput)

    addon.mainFrame.frame.scripts.OnKeyDown(addon.mainFrame.frame, "ESCAPE")
    harness.assert_false(addon.mainFrame.frame.visible)

    addon.mainFrame.frame:Show()
    addon.mainFrame.frame.closeButton:Click()

    harness.assert_false(addon.mainFrame.frame.visible)
  end,

  ["sync peers window renders a simple table with a close x"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    local guildKey = addon:GetActiveGuildContext().guildKey
    addon.db:RecordSyncPeer(guildKey, "Officerone-Stormrage", 1717336800)

    addon.mainFrame:ShowSyncPeers()

    local dialog = addon.mainFrame.syncPeersDialog
    harness.assert_true(dialog.visible)
    harness.assert_equal("Sync Peers", dialog.titleLabel.text)
    harness.assert_equal("Player", dialog.playerHeader.text)
    harness.assert_equal("Last Seen", dialog.lastSeenHeader.text)
    harness.assert_equal("UIPanelCloseButton", dialog.closeButton.template)
    harness.assert_equal("TOPRIGHT", dialog.closeButton.point[1])
    harness.assert_equal("TOPRIGHT", dialog.closeButton.point[3])
    harness.assert_true(dialog.parent == _G.UIParent)
    harness.assert_true(dialog.movable)
    harness.assert_equal("LeftButton", dialog.dragButtons[1])
    harness.assert_true(dialog.listSection ~= nil)
    harness.assert_equal("Officerone", dialog.listSection.rows[1].playerLabel.text)
    harness.assert_true(dialog.listSection.rows[1].lastSeenLabel.text:match("%d%d%d%d%-%d%d%-%d%d") ~= nil)

    dialog.closeButton:Click()

    harness.assert_false(dialog.visible)
  end,

  ["nominations tab submit button creates a pending nomination"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      guildMembers = {
        {
          name = "Burny-Stormrage",
          rankName = "Member",
          rankIndex = 5,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("nominations")

    local panel = addon.mainFrame.tabPanels.nominations
    panel.nomineeInput:SetText("Burny")
    panel.nomineeSuggestionButton:Click()
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

    harness.assert_true(panel.gmNote == nil)
    harness.assert_true(panel.permissionHelpLabel.text:match("Nominations:") ~= nil)
    harness.assert_true(panel.permissionHelpLabel.text:match("Direct:") ~= nil)
    harness.assert_true(panel.permissionHelpLabel.text:match("Delete:") ~= nil)
    harness.assert_true(panel.permissionHelpLabel.text:match("Admin:") ~= nil)
    harness.assert_true(panel.permissionHelpLabel.text:match("Manage Nominations:") == nil)
    harness.assert_true(panel.permissionHelpLabel.text:match("Rank 0") == nil)
    assert_text_role(panel.permissionHelpLabel, "cardDescription", 16, BLACK, false)
    assert_text_role(panel.aliasSummaryLabel, "cardDescription", 16, BLACK, false)
    assert_text_role(panel.statusLabel, "cardDescription", 16, BLACK, false)
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
    assert_backdrop_color(panel.aliasDialog, MODAL_FILL)
    local section = panel.aliasDialog.listSection

    harness.assert_true(section.scrollBar ~= nil)
    harness.assert_true(section.scrollBar.maxValue > 0)
    harness.assert_equal("rowHighlight", section.rows[1].backdropTone)
    harness.assert_equal("MIDDLE", section.rows[1].label.justifyV)
    harness.assert_nil(section.rows[1].label.fontFlags)
    harness.assert_true((section.rows[1].point[4] or 0) >= 14)
    harness.assert_true((section.rows[1].width or 0) <= (section.width or 0) - 48)
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
    harness.assert_equal("selected", awardPanel.typeBurntButton.variant)
    harness.assert_equal("secondary", awardPanel.typeGoldenButton.variant)
    harness.assert_true((awardPanel.typeBurntButton.backdropColor.red or 0) < ((awardPanel.typeGoldenButton.backdropColor.red or 0) - 0.08))
    assert_color(awardPanel.typeBurntButton.label, CARD_VALUE_GOLD)
    awardPanel.typeGoldenButton:Click()
    harness.assert_equal("golden", awardPanel.selectedAwardType)
    harness.assert_equal("secondary", awardPanel.typeBurntButton.variant)
    harness.assert_equal("selected", awardPanel.typeGoldenButton.variant)
    harness.assert_true((awardPanel.typeGoldenButton.backdropColor.red or 0) < ((awardPanel.typeBurntButton.backdropColor.red or 0) - 0.08))
    assert_color(awardPanel.typeGoldenButton.label, CARD_VALUE_GOLD)
    harness.assert_true(awardPanel.statusSection == nil)
    harness.assert_true((awardPanel.submitButton.point[5] or 0) - (awardPanel.submitButton.height or 0) >= -(awardPanel.formSection.height or 0))
    harness.assert_equal(100, awardPanel.reasonInput.maxLetters)

    addon.mainFrame:SelectTab("nominations")
    local nominationsPanel = addon.mainFrame.tabPanels.nominations
    harness.assert_equal("Nominate A Guild Failure", nominationsPanel.formSection.titleText.text)
    harness.assert_true(nominationsPanel.formSection.iconFrame == nil)
    harness.assert_true(nominationsPanel.selectedAwardPreview ~= nil)
    harness.assert_equal("Interface\\AddOns\\RollingPinAwards\\Media\\burnt-rolling-pin.png", nominationsPanel.selectedAwardPreview.texturePath)
    harness.assert_equal("", nominationsPanel.statusLabel.text)
    harness.assert_equal(nominationsPanel.nomineeInput.point[5], nominationsPanel.reasonInput.point[5])
    harness.assert_equal(nominationsPanel.reasonInput.point[5], nominationsPanel.submitButton.point[5])
    harness.assert_equal(100, nominationsPanel.reasonInput.maxLetters)
    harness.assert_true((nominationsPanel.statusLabel.point[5] or 0) > -(nominationsPanel.formSection.height or 0))
    harness.assert_true((nominationsPanel.statusLabel.point[5] or 0) > (nominationsPanel.listSection.point[5] or 0))
    harness.assert_true((nominationsPanel.submitButton.point[4] or 0) + (nominationsPanel.submitButton.width or 0) <= (nominationsPanel.formSection.width or 0) - 14)
    harness.assert_equal("selected", nominationsPanel.typeBurntButton.variant)
    harness.assert_equal("secondary", nominationsPanel.typeGoldenButton.variant)
    harness.assert_true((nominationsPanel.typeBurntButton.backdropColor.red or 0) < ((nominationsPanel.typeGoldenButton.backdropColor.red or 0) - 0.08))
    assert_color(nominationsPanel.typeBurntButton.label, CARD_VALUE_GOLD)
    nominationsPanel.typeGoldenButton:Click()
    harness.assert_equal("golden", nominationsPanel.selectedAwardType)
    harness.assert_equal("secondary", nominationsPanel.typeBurntButton.variant)
    harness.assert_equal("selected", nominationsPanel.typeGoldenButton.variant)
    harness.assert_true((nominationsPanel.typeGoldenButton.backdropColor.red or 0) < ((nominationsPanel.typeBurntButton.backdropColor.red or 0) - 0.08))
    assert_color(nominationsPanel.typeGoldenButton.label, CARD_VALUE_GOLD)
    harness.assert_equal("Nominate A Guild Legend", nominationsPanel.formSection.titleText.text)
    harness.assert_equal("Interface\\AddOns\\RollingPinAwards\\Media\\golden-rolling-pin.png", nominationsPanel.selectedAwardPreview.texturePath)
  end,

  ["history and leaderboard use expanded row-backed tables without helper boxes"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.awards:CreateDirectAward("Moonrustle-Stormrage", "Baiting Fae", "golden")
    addon.awards:CreateDirectAward("Moonrustle-Stormrage", "Pulled the boss", "burnt")

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("history")

    local historyPanel = addon.mainFrame.tabPanels.history
    harness.assert_true(historyPanel.statusSection == nil)
    harness.assert_true((historyPanel.listSection.height or 0) > 360)
    harness.assert_equal("rowHighlight", historyPanel.listSection.rows[1].backdropTone)
    harness.assert_equal("BackdropTemplate", historyPanel.listSection.rows[1].template)
    harness.assert_nil(historyPanel.listSection.rows[1].label.fontFlags)

    addon.mainFrame:SelectTab("leaderboard")

    local leaderboardPanel = addon.mainFrame.tabPanels.leaderboard
    harness.assert_true(leaderboardPanel.summarySection == nil)
    harness.assert_true((leaderboardPanel.listSection.height or 0) > 330)
    harness.assert_equal("rowHighlight", leaderboardPanel.listSection.rows[1].backdropTone)
    harness.assert_equal("BackdropTemplate", leaderboardPanel.listSection.rows[1].template)
    harness.assert_nil(leaderboardPanel.listSection.rows[1].label.fontFlags)
    harness.assert_equal("Interface\\AddOns\\RollingPinAwards\\Media\\burnt-rolling-pin.png", leaderboardPanel.listSection.rows[1].iconFrame.texturePath)
    harness.assert_true((leaderboardPanel.burntModeButton.point[5] or 0) < -330)
    harness.assert_equal("MIDDLE", leaderboardPanel.listSection.rows[1].label.justifyV)
    harness.assert_true((leaderboardPanel.listSection.rows[1].width or 0) <= (leaderboardPanel.listSection.width or 0) - 48)
    harness.assert_true((leaderboardPanel.listSection.rows[1].label.textColor.red or 1) < 0.3)
    harness.assert_equal("LEFT", leaderboardPanel.listSection.rows[1].actions[1].point[1])
  end,

  ["admin controls stay inside their chrome"] = function()
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
          name = "Officertwo-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
        {
          name = "Officerthree-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("admin")

    local adminPanel = addon.mainFrame.tabPanels.admin
    local officerRow = adminPanel.rankSection.rows[2]
    officerRow.manageNominationsCheck:Click()
    harness.assert_true(officerRow.manageNominationsCheck:GetChecked())
    harness.assert_true(officerRow.manageNominationsCheck.checkLabel.visible)
    local saveRight = (officerRow.point[4] or 0) + (officerRow.saveButton.point[4] or 0) + (officerRow.saveButton.width or 0)
    local scrollLeft = (adminPanel.rankSection.width or 0) + (adminPanel.rankSection.scrollBar.point[4] or 0)
    harness.assert_true(saveRight <= scrollLeft - 24)
    harness.assert_true((adminPanel.aliasInput.point[5] or 0) - (adminPanel.aliasInput.height or 0) >= -(adminPanel.aliasFormSection.height or 0))
    harness.assert_true(adminPanel.moderationSection == nil)
    harness.assert_true(adminPanel.moderationButton ~= nil)
    harness.assert_equal("Moderation Queue (0)", adminPanel.moderationButton.label.text)
    harness.assert_true(adminPanel.moderationDialog ~= nil)
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
    harness.assert_equal("BackdropTemplate", section.rows[1].template)
    harness.assert_equal("rowHighlight", section.rows[1].backdropTone)
    harness.assert_equal("MIDDLE", section.rows[1].label.justifyV)
    harness.assert_nil(section.rows[1].label.fontFlags)
    harness.assert_true((section.rows[1].label.textColor.red or 1) < 0.3)
    harness.assert_true((section.rows[1].width or 0) <= (section.width or 0) - 48)
    harness.assert_equal("LEFT", section.rows[1].actions[1].point[1])
    local thirdRow = section.rows[3]
    local thirdRowBottom = math.abs(thirdRow.point[5] or 0) + (thirdRow.height or 0)
    harness.assert_true(thirdRowBottom <= (section.height or 0))
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
    harness.assert_true((panel.confirmDialog.frameLevel or 0) > (panel.listSection.rows[1].frameLevel or 0))
    assert_backdrop_color(panel.confirmDialog, MODAL_FILL)
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
    harness.assert_true(rowText:match("Guildmaster%-Stormrage") == nil)
    harness.assert_true(rowText:match("Awarded by Guildmaster") ~= nil)
  end,

  ["award tables render newest awards first"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    _G.GetServerTime = function()
      return 1717336800
    end
    addon.awards:CreateDirectAward("Oldpin-Stormrage", "Older award")

    _G.GetServerTime = function()
      return 1717423200
    end
    addon.awards:CreateDirectAward("Newpin-Stormrage", "Newer award")

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("history")

    local historyText = addon.mainFrame.tabPanels.history.listSection.rows[1].label.text
    harness.assert_true(historyText:match("Newpin%-Stormrage") == nil)
    harness.assert_true(historyText:match("Newpin") ~= nil)
    harness.assert_true(addon.uiBridge:GetPublicHistoryViewModel()[1].recipient:match("Newpin") ~= nil)

    addon.mainFrame:SelectTab("dashboard")
    local dashboardRow = addon.mainFrame.tabPanels.dashboard.recentAwardsSection.rows[1]
    local dashboardText = dashboardRow.label.text
    harness.assert_true(dashboardText:match("Newpin") ~= nil)
    harness.assert_true((dashboardRow.label.width or 0) <= (dashboardRow.width or 0) - 54)
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
    harness.assert_equal(5, section.visibleRowCount)
    local lastRow = section.rows[#section.rows]
    local lastRowBottom = math.abs(lastRow.point[5] or 0) + (lastRow.height or 0)
    harness.assert_true(lastRowBottom <= (section.height or 0))
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
    harness.assert_true(section.rows[1].label.text:match("Burny2%-Stormrage") == nil)
    harness.assert_true(section.rows[1].label.text:match("Burny2") ~= nil)
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
    harness.assert_true(section.rows[1].label.text:match("Burny2%-Stormrage") == nil)
    harness.assert_true(section.rows[1].label.text:match("Burny2") ~= nil)
  end,

  ["nominations row keeps public voting separate from moderation actions"] = function()
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
    local downvoteButton = row.actions[2]

    harness.assert_equal(2, #row.actions)
    harness.assert_true(downvoteButton.point[4] > upvoteButton.point[4])
    harness.assert_equal("Upvote", upvoteButton.label.text)
    harness.assert_equal("Downvote", downvoteButton.label.text)
  end,

  ["moderation queue rows show submitter and approve or reject pending nominations"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    wow.setPlayer("Bakerone", "Member", 5)
    addon.nominations:Create("Burny-Stormrage", "Pulled the boss")
    wow.setPlayer("Guildmaster", "Guild Master", 0)

    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("admin")
    local panel = addon.mainFrame.tabPanels.admin
    panel.moderationButton:Click()

    local row = panel.moderationDialog.listSection.rows[1]
    harness.assert_true(row.label.text:match("Submitted by Bakerone") ~= nil)
    harness.assert_equal(2, #row.actions)
    harness.assert_equal("Approve", row.actions[1].label.text)
    harness.assert_equal("Reject", row.actions[2].label.text)

    row.actions[1]:Click()
    harness.assert_equal("approved", addon.uiBridge:GetAdminNominationsViewModel()[1].status)
  end,

  ["admin alias canonical field suggests guild roster names while typing"] = function()
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

    local panel = addon.mainFrame.tabPanels.admin
    panel.canonicalInput:SetText("Off")

    harness.assert_true(panel.aliasSuggestionButton.visible)
    harness.assert_equal("Officerone-Stormrage", panel.aliasSuggestionButton.suggestedName)
    harness.assert_true(panel.aliasSuggestionButton.label.text:match("Officerone%-Stormrage") ~= nil)

    panel.aliasSuggestionButton:Click()
    harness.assert_equal("Officerone-Stormrage", panel.canonicalInput:GetText())
  end,

  ["award and nomination character fields autocomplete guild roster names"] = function()
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
          name = "Officertwo-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
        {
          name = "Officerthree-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()

    addon.mainFrame:SelectTab("award")
    local awardPanel = addon.mainFrame.tabPanels.award
    awardPanel.recipientInput:SetText("Off")

    harness.assert_true(awardPanel.recipientSuggestionButton.visible)
    harness.assert_equal("Officerone-Stormrage", awardPanel.recipientSuggestionButton.suggestedName)
    harness.assert_equal(3, #(awardPanel.recipientInput.rosterSuggestionButtons or {}))
    harness.assert_equal("Officerone-Stormrage", awardPanel.recipientInput.rosterSuggestionButtons[1].suggestedName)
    harness.assert_equal("Officertwo-Stormrage", awardPanel.recipientInput.rosterSuggestionButtons[2].suggestedName)
    harness.assert_equal("Officerthree-Stormrage", awardPanel.recipientInput.rosterSuggestionButtons[3].suggestedName)
    harness.assert_true(awardPanel.recipientInput.rosterSuggestionButtons[2].visible)
    harness.assert_true(awardPanel.recipientInput.rosterSuggestionButtons[3].visible)
    assert_backdrop_color(awardPanel.recipientInput.rosterSuggestionButtons[1], MODAL_FILL)
    harness.assert_equal(awardPanel.recipientSuggestionButton, awardPanel.recipientInput.rosterSuggestionButtons[2].point[2])
    harness.assert_equal(awardPanel.recipientInput.rosterSuggestionButtons[2], awardPanel.recipientInput.rosterSuggestionButtons[3].point[2])

    awardPanel.recipientInput.rosterSuggestionButtons[2]:Click()
    harness.assert_equal("Officertwo-Stormrage", awardPanel.recipientInput:GetText())
    harness.assert_equal("Officertwo-Stormrage", awardPanel.recipientInput.selectedRosterName)

    addon.mainFrame:SelectTab("nominations")
    local nominationsPanel = addon.mainFrame.tabPanels.nominations
    nominationsPanel.nomineeInput:SetText("Off")

    harness.assert_true(nominationsPanel.nomineeSuggestionButton.visible)
    harness.assert_equal("Officerone-Stormrage", nominationsPanel.nomineeSuggestionButton.suggestedName)
    harness.assert_equal(3, #(nominationsPanel.nomineeInput.rosterSuggestionButtons or {}))
    harness.assert_equal("Officerone-Stormrage", nominationsPanel.nomineeInput.rosterSuggestionButtons[1].suggestedName)
    harness.assert_equal("Officertwo-Stormrage", nominationsPanel.nomineeInput.rosterSuggestionButtons[2].suggestedName)
    harness.assert_equal("Officerthree-Stormrage", nominationsPanel.nomineeInput.rosterSuggestionButtons[3].suggestedName)
    harness.assert_true(nominationsPanel.nomineeInput.rosterSuggestionButtons[2].visible)
    harness.assert_true(nominationsPanel.nomineeInput.rosterSuggestionButtons[3].visible)
    assert_backdrop_color(nominationsPanel.nomineeInput.rosterSuggestionButtons[1], MODAL_FILL)
    harness.assert_equal(nominationsPanel.nomineeSuggestionButton, nominationsPanel.nomineeInput.rosterSuggestionButtons[2].point[2])
    harness.assert_equal(nominationsPanel.nomineeInput.rosterSuggestionButtons[2], nominationsPanel.nomineeInput.rosterSuggestionButtons[3].point[2])

    nominationsPanel.nomineeInput.rosterSuggestionButtons[3]:Click()
    harness.assert_equal("Officerthree-Stormrage", nominationsPanel.nomineeInput:GetText())
    harness.assert_equal("Officerthree-Stormrage", nominationsPanel.nomineeInput.selectedRosterName)
  end,

  ["award and nomination submits require selecting a roster suggestion"] = function()
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
          name = "Burny-Stormrage",
          rankName = "Member",
          rankIndex = 5,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()

    addon.mainFrame:SelectTab("award")
    local awardPanel = addon.mainFrame.tabPanels.award
    awardPanel.recipientInput:SetText("Burny")
    awardPanel.reasonInput:SetText("Set the oven to lava")
    awardPanel.submitButton:Click()
    harness.assert_true(awardPanel.statusLabel.text:match("Select a guild character") ~= nil)
    harness.assert_equal(0, #addon.uiBridge:GetPublicHistoryViewModel())

    awardPanel.recipientSuggestionButton:Click()
    awardPanel.submitButton:Click()
    harness.assert_equal(1, #addon.uiBridge:GetPublicHistoryViewModel())

    addon.mainFrame:SelectTab("nominations")
    local nominationsPanel = addon.mainFrame.tabPanels.nominations
    nominationsPanel.nomineeInput:SetText("Burny")
    nominationsPanel.reasonInput:SetText("Pulled the boss")
    nominationsPanel.submitButton:Click()
    harness.assert_true(nominationsPanel.statusLabel.text:match("Select a guild character") ~= nil)
    harness.assert_equal(0, #addon.uiBridge:GetPendingNominationsViewModel())

    nominationsPanel.nomineeSuggestionButton:Click()
    nominationsPanel.submitButton:Click()
    harness.assert_equal(1, #addon.uiBridge:GetPendingNominationsViewModel())
  end,

  ["admin character mapping labels and both character fields autocomplete guild roster names"] = function()
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
          name = "Altone-Stormrage",
          rankName = "Member",
          rankIndex = 5,
        },
        {
          name = "Alttwo-Stormrage",
          rankName = "Member",
          rankIndex = 5,
        },
        {
          name = "Altthree-Stormrage",
          rankName = "Member",
          rankIndex = 5,
        },
        {
          name = "Mainone-Stormrage",
          rankName = "Member",
          rankIndex = 5,
        },
        {
          name = "Maintwo-Stormrage",
          rankName = "Member",
          rankIndex = 5,
        },
        {
          name = "Mainthree-Stormrage",
          rankName = "Member",
          rankIndex = 5,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()
    addon.mainFrame:SelectTab("admin")

    local panel = addon.mainFrame.tabPanels.admin
    harness.assert_equal("Character Mapping Controls", panel.aliasFormSection.titleText.text)
    harness.assert_equal("Alt Character", panel.aliasLabel.text)
    harness.assert_equal("Main Character", panel.canonicalLabel.text)
    harness.assert_equal(panel.canonicalInput.width, panel.aliasInput.width)
    harness.assert_true((panel.aliasInput.width or 0) >= 260)
    harness.assert_true((panel.aliasSaveButton.point[5] or 0) < (panel.aliasInput.point[5] or 0))
    harness.assert_true((panel.aliasBrowseButton.point[5] or 0) < (panel.canonicalInput.point[5] or 0))

    panel.aliasInput:SetText("Alt")
    harness.assert_true(panel.altSuggestionButton.visible)
    harness.assert_equal("Altone-Stormrage", panel.altSuggestionButton.suggestedName)
    harness.assert_equal(3, #(panel.aliasInput.rosterSuggestionButtons or {}))
    harness.assert_equal("Altone-Stormrage", panel.aliasInput.rosterSuggestionButtons[1].suggestedName)
    harness.assert_equal("Alttwo-Stormrage", panel.aliasInput.rosterSuggestionButtons[2].suggestedName)
    harness.assert_equal("Altthree-Stormrage", panel.aliasInput.rosterSuggestionButtons[3].suggestedName)
    harness.assert_true(panel.aliasInput.rosterSuggestionButtons[2].visible)
    harness.assert_true(panel.aliasInput.rosterSuggestionButtons[3].visible)
    for _, suggestionButton in ipairs(panel.aliasInput.rosterSuggestionButtons) do
      assert_backdrop_color(suggestionButton, MODAL_FILL)
      assert_color(suggestionButton.label, BROWN)
      harness.assert_true((suggestionButton.frameLevel or 0) > (panel.aliasSaveButton.frameLevel or 0))
    end
    panel.aliasInput.rosterSuggestionButtons[2]:Click()
    harness.assert_equal("Alttwo-Stormrage", panel.aliasInput:GetText())

    panel.aliasInput:SetText("Alt")
    panel.altSuggestionButton:Click()
    harness.assert_equal("Altone-Stormrage", panel.aliasInput:GetText())

    panel.canonicalInput:SetText("Main")
    harness.assert_true(panel.mainSuggestionButton.visible)
    harness.assert_equal("Mainone-Stormrage", panel.mainSuggestionButton.suggestedName)
    harness.assert_equal(3, #(panel.canonicalInput.rosterSuggestionButtons or {}))
    harness.assert_equal("Mainone-Stormrage", panel.canonicalInput.rosterSuggestionButtons[1].suggestedName)
    harness.assert_equal("Maintwo-Stormrage", panel.canonicalInput.rosterSuggestionButtons[2].suggestedName)
    harness.assert_equal("Mainthree-Stormrage", panel.canonicalInput.rosterSuggestionButtons[3].suggestedName)
    harness.assert_true(panel.canonicalInput.rosterSuggestionButtons[2].visible)
    harness.assert_true(panel.canonicalInput.rosterSuggestionButtons[3].visible)
    for _, suggestionButton in ipairs(panel.canonicalInput.rosterSuggestionButtons) do
      assert_backdrop_color(suggestionButton, MODAL_FILL)
      assert_color(suggestionButton.label, BROWN)
      harness.assert_true((suggestionButton.frameLevel or 0) > (panel.aliasBrowseButton.frameLevel or 0))
    end
    panel.canonicalInput.rosterSuggestionButtons[3]:Click()
    harness.assert_equal("Mainthree-Stormrage", panel.canonicalInput:GetText())
  end,

  ["normal award and nomination UI hides realm names outside character mapping"] = function()
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
          name = "Burny-Stormrage",
          rankName = "Member",
          rankIndex = 5,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.mainFrame:EnsureRendered()

    addon.mainFrame:SelectTab("award")
    local awardPanel = addon.mainFrame.tabPanels.award
    awardPanel.recipientInput:SetText("Burny")
    awardPanel.recipientSuggestionButton:Click()
    awardPanel.reasonInput:SetText("Set the oven to lava")
    awardPanel.submitButton:Click()
    harness.assert_true(awardPanel.statusLabel.text:match("Burny%-Stormrage") == nil)
    harness.assert_true(awardPanel.statusLabel.text:match("Burny") ~= nil)

    addon.mainFrame:SelectTab("nominations")
    local nominationsPanel = addon.mainFrame.tabPanels.nominations
    nominationsPanel.nomineeInput:SetText("Burny")
    nominationsPanel.nomineeSuggestionButton:Click()
    nominationsPanel.reasonInput:SetText("Pulled the boss")
    nominationsPanel.submitButton:Click()
    harness.assert_true(nominationsPanel.statusLabel.text:match("Burny%-Stormrage") == nil)
    harness.assert_true(nominationsPanel.statusLabel.text:match("Burny") ~= nil)

    local nominationRow = nominationsPanel.listSection.rows[1].label.text
    harness.assert_true(nominationRow:match("Burny%-Stormrage") == nil)
    harness.assert_true(nominationRow:match("Burny") ~= nil)

    addon.mainFrame:SelectTab("history")
    local historyRow = addon.mainFrame.tabPanels.history.listSection.rows[1].label.text
    harness.assert_true(historyRow:match("Burny%-Stormrage") == nil)
    harness.assert_true(historyRow:match("Burny") ~= nil)
  end,
}

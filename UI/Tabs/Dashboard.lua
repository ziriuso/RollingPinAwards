local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
local Styles = RPA.UIStyles or {}
RPA.UITabs = UITabs

local function stripRealm(name)
  if type(name) ~= "string" then
    return name or "Unknown"
  end

  return name:match("^([^-]+)") or name
end

local function buildRecentAwardText(award)
  if not award then
    return "No awards yet."
  end

  return ("%s\n%s\nAwarded by %s"):format(
    stripRealm(award.recipient),
    award.reason or "",
    stripRealm(award.awardedBy)
  )
end

UITabs.dashboard = {
  id = "dashboard",
  label = "Dashboard",
  BuildViewModel = function(bridge)
    return bridge:GetDashboardViewModel()
  end,
  DescribeViewModel = function(viewModel)
    return {
      title = "Dashboard",
      lines = {
        ("Pending nominations: %d"):format(#(viewModel.pendingNominations or {})),
        ("Recent awards: %d"):format(#(viewModel.recentAwards or {})),
      },
    }
  end,
  BuildPanel = function(parent, mainFrame)
    local layout = Styles.Layout or {}
    local dash = Styles.Dashboard or {}
    local media = Styles.Media or {}
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", layout.panelX or 59, layout.panelY or -42)
    panel:SetSize(layout.panelWidth or 762, (parent.height or 520) - 56)

    panel.heroLabel = Components.CreateLabel(panel, {
      text = "Guild chaos, professionally archived.",
      x = 0,
      y = 0,
      width = 540,
      font = "GameFontHighlight",
      justifyH = "LEFT",
      textRole = "tabDescription",
    })
    panel.permissionLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = -24,
      width = 760,
      justifyH = "LEFT",
      font = "GameFontHighlightSmall",
      textRole = "tabDescription",
    })

    panel.statsSection = CreateFrame("Frame", nil, panel)
    panel.statsSection:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -52)
    panel.statsSection:SetSize((panel.width or 792), dash.statCardHeight or 96)
    panel.statCards = {}
    for index = 1, 4 do
      local card = Components.CreateStatCard(panel.statsSection, {
        id = ("RollingPinAwardsDashboardStatCard%d"):format(index),
        x = (index - 1) * ((dash.statCardWidth or 178) + (layout.cardGap or 16)),
        y = 0,
        width = dash.statCardWidth or 178,
        height = dash.statCardHeight or 96,
      })
      panel.statCards[#panel.statCards + 1] = card
    end

    panel.leaderboardSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsDashboardLeaderboard",
      title = "Top Rolling Pin Recipients",
      width = 360,
      height = 214,
      x = 0,
      y = -162,
      visibleRowCount = 3,
      rowHeight = 48,
    })
    panel.recentAwardsSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsDashboardRecentAwards",
      title = "Recent Awards",
      width = 386,
      height = 214,
      x = 376,
      y = -162,
      visibleRowCount = 3,
      rowHeight = 56,
    })

    panel.quickActionsSection = CreateFrame("Frame", nil, panel)
    panel.quickActionsSection:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -384)
    panel.quickActionsSection:SetSize(762, 54)
    panel.nominationButton = Components.CreateButton(panel.quickActionsSection, {
      text = "Nominate Player",
      width = 360,
      height = dash.footerButtonHeight or 42,
      x = 0,
      y = 0,
      variant = "secondary",
      iconPath = media.standardPinIcon,
      iconWidth = 22,
      iconHeight = 22,
      onClick = function()
        mainFrame:SelectTab("nominations")
      end,
    })
    panel.awardButton = Components.CreateButton(panel.quickActionsSection, {
      text = "Award Rolling Pin",
      width = 386,
      height = dash.footerButtonHeight or 42,
      x = 376,
      y = 0,
      variant = "primary",
      iconPath = media.awardIcon,
      iconWidth = 22,
      iconHeight = 22,
      onClick = function()
        mainFrame:SelectTab("award")
      end,
    })

    return panel
  end,
  RefreshPanel = function(panel, viewModel)
    local leaderboardRows = viewModel.leaderboardRows or {}
    local recentAwards = viewModel.recentAwards or {}
    local latestAward = recentAwards[1]
    local topRecipient = viewModel.topRecipient or "Nobody yet"

    Components.SetText(
      panel.permissionLabel,
      viewModel.canManageAwards and "Guild-approved judges can award, approve, and curate the awards."
        or "You can nominate and vote, but guild permission is required for awards and moderation."
    )

    Components.SetText(panel.statCards[1].label, "Total Rolling Pins")
    Components.SetText(panel.statCards[1].value, tostring(viewModel.awardCount or 0))
    Components.SetText(panel.statCards[1].detail, "Total Guildwide")

    Components.SetText(panel.statCards[2].label, "Top Recipient")
    Components.SetText(panel.statCards[2].value, topRecipient)
    Components.SetText(panel.statCards[2].detail, ("%d combined awards"):format(viewModel.topRecipientCount or 0))

    Components.SetText(panel.statCards[3].label, "Pending Nominations")
    Components.SetText(panel.statCards[3].value, tostring(viewModel.pendingCount or 0))
    Components.SetText(panel.statCards[3].detail, "Waiting for a verdict")

    Components.SetText(panel.statCards[4].label, "Latest Award")
    Components.SetText(panel.statCards[4].value, viewModel.latestAwardRecipient or "None")
    Components.SetText(panel.statCards[4].detail, latestAward and (latestAward.dateText or "") or "No awards yet")

    local leaderboardItems = leaderboardRows
    if #leaderboardItems == 0 then
      leaderboardItems = { { emptyState = true } }
    end

    Components.SetScrollableItems(panel.leaderboardSection, leaderboardItems, function(section, row)
      if row.emptyState then
        Components.AddListRow(section, {
          text = "No leaderboard entries yet.",
          rowHeight = 34,
          actions = {},
        })
        return
      end

      Components.AddListRow(section, {
        text = ("%d. %s\n    %d rolling pins"):format(
          row.rank or 0,
          row.shortRecipient or stripRealm(row.recipient) or "Unknown",
          row.pinCount or 0
        ),
        iconPath = row.rank == 1 and (Styles.Media or {}).leaderboardIcon or (Styles.Media or {}).standardPinIcon,
        iconWidth = 18,
        iconHeight = 18,
        labelWidth = 260,
        rowHeight = 48,
        highlight = row.rank == 1,
        backdropTone = "rowHighlight",
        actions = {},
      })
    end)

    local recentItems = recentAwards
    if #recentItems == 0 then
      recentItems = { { emptyState = true } }
    end

    Components.SetScrollableItems(panel.recentAwardsSection, recentItems, function(section, row)
      if row.emptyState then
        Components.AddListRow(section, {
          text = "No awards recorded yet.",
          rowHeight = 34,
          actions = {},
        })
        return
      end

      Components.AddListRow(section, {
        text = buildRecentAwardText(row),
        iconPath = row.awardIconPath,
        iconWidth = 18,
        iconHeight = 18,
        labelWidth = 320,
        rowHeight = 56,
        backdropTone = "rowHighlight",
        actions = {},
      })
    end)

  end,
}

return UITabs.dashboard

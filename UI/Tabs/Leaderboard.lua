local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
local Styles = RPA.UIStyles or {}
RPA.UITabs = UITabs

UITabs.leaderboard = {
  id = "leaderboard",
  label = "Leaderboard",
  BuildViewModel = function(bridge)
    return {
      rows = bridge:GetLeaderboardViewModel("combined"),
    }
  end,
  DescribeViewModel = function(viewModel)
    local lines = {
      ("Award recipients: %d"):format(#(viewModel.rows or {})),
    }

    for index, row in ipairs(viewModel.rows or {}) do
      if index > 5 then
        break
      end
      lines[#lines + 1] = ("%s - %d pins"):format(row.recipient, row.pinCount)
    end

    if #lines == 1 then
      lines[#lines + 1] = "No approved awards yet."
    end

    return {
      title = "Leaderboard",
      lines = lines,
    }
  end,
  BuildPanel = function(parent, mainFrame)
    local media = Styles.Media or {}
    local panel = CreateFrame("Frame", nil, parent)
    panel.ownerFrame = mainFrame
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -42)
    panel:SetSize((parent.width or 820) - 28, (parent.height or 520) - 56)

    panel.listSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsLeaderboardList",
      title = "Rolling Pin Leaders",
      iconPath = media.leaderboardIcon,
      iconWidth = 22,
      iconHeight = 22,
      width = 780,
      height = 290,
      x = 0,
      y = 0,
      visibleRowCount = 5,
      rowHeight = 56,
    })
    panel.selectedMode = panel.selectedMode or "combined"
    panel.burntModeButton = Components.CreateButton(panel, {
      text = "Burnt",
      width = 110,
      height = 28,
      x = 0,
      y = -304,
      variant = "secondary",
      onClick = function()
        panel.selectedMode = "burnt"
        panel.ownerFrame:RenderActiveTab()
      end,
    })
    panel.goldenModeButton = Components.CreateButton(panel, {
      text = "Golden",
      width = 110,
      height = 28,
      x = 118,
      y = -304,
      variant = "secondary",
      onClick = function()
        panel.selectedMode = "golden"
        panel.ownerFrame:RenderActiveTab()
      end,
    })
    panel.combinedModeButton = Components.CreateButton(panel, {
      text = "Combined",
      width = 120,
      height = 28,
      x = 236,
      y = -304,
      variant = "primary",
      onClick = function()
        panel.selectedMode = "combined"
        panel.ownerFrame:RenderActiveTab()
      end,
    })
    panel.summarySection = Components.CreateSection(panel, {
      id = "RollingPinAwardsLeaderboardSummarySection",
      title = "Click Through",
      iconPath = media.awardIcon,
      iconWidth = 20,
      iconHeight = 20,
      width = 780,
      height = 74,
      x = 0,
      y = -340,
    })
    panel.summaryLabel = Components.CreateLabel(panel.summarySection, {
      text = "Sorted by rolling pin count first, then by the most recent award date. Select View to inspect every approved award with reason, date, and awarded-by context.",
      x = 14,
      y = -38,
      width = 736,
      justifyH = "LEFT",
      font = "GameFontHighlightSmall",
    })
    panel.detailDialog = Components.CreateModalWindow(panel, {
      id = "RollingPinAwardsLeaderboardDetailDialog",
      title = "Award History",
      width = 640,
      height = 420,
      closeText = "Close",
    })
    panel.detailDialog.listSection = Components.CreateScrollableSection(panel.detailDialog, {
      id = "RollingPinAwardsLeaderboardDetailList",
      title = "Approved Awards",
      iconPath = media.awardIcon,
      iconWidth = 20,
      iconHeight = 20,
      width = 600,
      height = 320,
      x = 16,
      y = -48,
      visibleRowCount = 5,
      rowHeight = 56,
    })

    return panel
  end,
  RefreshPanel = function(panel, viewModel, bridge)
    local mode = panel.selectedMode or "combined"
    local rows = bridge:GetLeaderboardViewModel(mode) or {}
    if #rows == 0 then
      rows = {
        {
          emptyState = true,
        },
      }
    end

    Components.SetButtonVariant(panel.burntModeButton, mode == "burnt" and "primary" or "secondary")
    Components.SetButtonVariant(panel.goldenModeButton, mode == "golden" and "primary" or "secondary")
    Components.SetButtonVariant(panel.combinedModeButton, mode == "combined" and "primary" or "secondary")

    Components.SetScrollableItems(panel.listSection, rows, function(section, row)
      if row.emptyState then
        Components.AddListRow(section, {
          text = "No approved awards yet.",
          rowHeight = 40,
          actions = {},
        })
        return
      end

      Components.AddListRow(section, {
        text = mode == "combined"
            and ("%s\nGolden: %d  Burnt: %d  Total: %d\nMost Recent: %s"):format(
              row.recipient,
              row.goldenCount or 0,
              row.burntCount or 0,
              row.totalCount or row.pinCount or 0,
              row.mostRecentAwardText or "Unknown date"
            )
          or ("%s\nPins: %d\nMost Recent: %s"):format(
            row.recipient,
            row.pinCount,
            row.mostRecentAwardText or "Unknown date"
          ),
        iconPath = mode == "combined"
            and ((row.goldenCount or 0) >= (row.burntCount or 0) and (Styles.Media or {}).leaderboardIcon or (Styles.Media or {}).awardIcon)
          or (mode == "golden" and (Styles.Media or {}).leaderboardIcon or (Styles.Media or {}).awardIcon),
        iconWidth = 18,
        iconHeight = 18,
        labelWidth = 548,
        rowHeight = 56,
        actions = {
          {
            text = "View",
            width = 62,
            onClick = function()
              Components.SetText(panel.detailDialog.titleLabel, row.recipient)
              local entries = row.entries or {}
              if #entries == 0 then
                entries = {
                  {
                    emptyState = true,
                  },
                }
              end

              Components.SetScrollableItems(panel.detailDialog.listSection, entries, function(detailSection, entry)
                if entry.emptyState then
                  Components.AddListRow(detailSection, {
                    text = "No approved awards found.",
                    rowHeight = 40,
                    actions = {},
                  })
                  return
                end

                Components.AddListRow(detailSection, {
                  text = ("%s\n%s\nAwarded By: %s"):format(
                    entry.dateText or "Unknown date",
                    entry.reason or "",
                    entry.displayAwardedBy or "Unknown"
                  ),
                  iconPath = entry.awardIconPath,
                  iconWidth = 18,
                  iconHeight = 18,
                  labelWidth = 540,
                  rowHeight = 56,
                  actions = {},
                })
              end)
              Components.SetVisible(panel.detailDialog, true)
            end,
          },
        },
      })
    end)
    Components.SetText(
      panel.summaryLabel,
      mode == "combined"
          and "Combined view keeps praise and shame separate: golden count, burnt count, and total awards are all visible."
        or (mode == "golden"
          and "Golden view highlights praise and fame only."
          or "Burnt view highlights hall-of-shame records only.")
    )
  end,
}

return UITabs.leaderboard

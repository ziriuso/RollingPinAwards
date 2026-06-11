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

local function getDominantAwardIcon(row)
  local media = Styles.Media or {}
  if (row.burntCount or 0) >= (row.goldenCount or 0) then
    return media.awardIcon
  end

  return media.leaderboardIcon
end

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
      lines[#lines + 1] = ("%s - %d pins"):format(row.shortRecipient or stripRealm(row.recipient), row.pinCount)
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
    local layout = Styles.Layout or {}
    local media = Styles.Media or {}
    local panel = CreateFrame("Frame", nil, parent)
    panel.ownerFrame = mainFrame
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", layout.panelX or 59, layout.panelY or -42)
    panel:SetSize(layout.panelWidth or 762, (parent.height or 520) - 56)

    panel.listSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsLeaderboardList",
      title = "Rolling Pin Leaders",
      iconPath = media.leaderboardIcon,
      iconWidth = 22,
      iconHeight = 22,
      width = 762,
      height = 360,
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
      y = -374,
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
      y = -374,
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
      y = -374,
      variant = "primary",
      onClick = function()
        panel.selectedMode = "combined"
        panel.ownerFrame:RenderActiveTab()
      end,
    })
    local showcaseParent = (mainFrame and mainFrame.frame) or panel
    panel.detailDialog = Components.CreateModalWindow(showcaseParent, {
      id = "RollingPinAwardsLeaderboardDetailDialog",
      title = "Award History",
      width = 760,
      height = 840,
      closeText = "",
      titleFont = "GameFontNormalHuge",
      titleY = -72,
      centerTitle = true,
      closeAnchor = "BOTTOMRIGHT",
      closeBottomY = 35,
      draggable = true,
      frameLevelOffset = 160,
      backdropColor = { 0.10, 0.07, 0.05, 0 },
      borderColor = { 0.10, 0.07, 0.05, 0 },
      backgroundTexture = media.leaderboardShowcaseBackground or media.modalBackground,
      contentBounds = {
        left = 0,
        top = 0,
        width = 760,
        height = 840,
      },
      titleTextRole = "leaderboardShowcaseName",
    })
    local showcaseHost = panel.detailDialog.contentHost or panel.detailDialog
    panel.detailDialog.goldenCountLabel = Components.CreateLabel(showcaseHost, {
      text = "0",
      x = 107,
      y = -245,
      width = 96,
      justifyH = "CENTER",
      font = "GameFontNormalHuge",
      textRole = "leaderboardCount",
    })
    panel.detailDialog.burntCountLabel = Components.CreateLabel(showcaseHost, {
      text = "0",
      x = 557,
      y = -245,
      width = 96,
      justifyH = "CENTER",
      font = "GameFontNormalHuge",
      textRole = "leaderboardCount",
    })
    panel.detailDialog.listSection = Components.CreateScrollableSection(showcaseHost, {
      id = "RollingPinAwardsLeaderboardDetailList",
      title = "",
      width = 620,
      height = 420,
      x = 78,
      y = -296,
      visibleRowCount = 6,
      rowHeight = 56,
      rowStartY = -12,
      scrollBarTop = 12,
      scrollBarBottom = 18,
    })
    if panel.detailDialog.closeButton then
      if panel.detailDialog.closeButton.SetSize then
        panel.detailDialog.closeButton:SetSize(118, 48)
      end
      panel.detailDialog.closeButton.width = 118
      panel.detailDialog.closeButton.height = 48
      if panel.detailDialog.closeButton.SetBackdrop then
        panel.detailDialog.closeButton:SetBackdrop(nil)
      end
      panel.detailDialog.closeButton.backdrop = nil
      panel.detailDialog.closeButton.backdropColor = nil
      panel.detailDialog.closeButton.backdropBorderColor = nil
      if panel.detailDialog.closeButton.label then
        Components.SetText(panel.detailDialog.closeButton.label, "")
      end
      panel.detailDialog.closeButton.isInvisibleHitbox = true
    end

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

    Components.SetButtonVariant(panel.burntModeButton, mode == "burnt" and "selected" or "secondary")
    Components.SetButtonVariant(panel.goldenModeButton, mode == "golden" and "selected" or "secondary")
    Components.SetButtonVariant(panel.combinedModeButton, mode == "combined" and "selected" or "secondary")

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
              row.shortRecipient or stripRealm(row.recipient),
              row.goldenCount or 0,
              row.burntCount or 0,
              row.totalCount or row.pinCount or 0,
              row.mostRecentAwardText or "Unknown date"
            )
          or ("%s\nPins: %d\nMost Recent: %s"):format(
            row.shortRecipient or stripRealm(row.recipient),
            row.pinCount,
            row.mostRecentAwardText or "Unknown date"
          ),
        iconPath = mode == "combined"
            and getDominantAwardIcon(row)
          or (mode == "golden" and (Styles.Media or {}).leaderboardIcon or (Styles.Media or {}).awardIcon),
        iconWidth = 18,
        iconHeight = 18,
        labelWidth = 548,
        rowHeight = 56,
        backdropTone = "rowHighlight",
        actions = {
          {
            text = "View",
            width = 62,
            onClick = function()
              Components.SetText(panel.detailDialog.titleLabel, row.shortRecipient or stripRealm(row.recipient))
              Components.SetText(panel.detailDialog.goldenCountLabel, tostring(row.goldenCount or 0))
              Components.SetText(panel.detailDialog.burntCountLabel, tostring(row.burntCount or 0))
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
                  backdropTone = "rowHighlight",
                  actions = {},
                })
              end)
              Components.SetVisible(panel.detailDialog, true)
            end,
          },
        },
      })
    end)
  end,
}

return UITabs.leaderboard

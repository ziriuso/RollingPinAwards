local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
RPA.UITabs = UITabs

UITabs.leaderboard = {
  id = "leaderboard",
  label = "Leaderboard",
  BuildViewModel = function(bridge)
    return {
      rows = bridge:GetLeaderboardViewModel(),
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
  BuildPanel = function(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -44)
    panel:SetSize((parent.width or 820) - 24, (parent.height or 520) - 24)

    panel.listSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsLeaderboardList",
      title = "Rolling Pin Leaders",
      width = 780,
      height = 430,
      x = 0,
      y = 0,
      visibleRowCount = 6,
      rowHeight = 54,
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
      width = 600,
      height = 320,
      x = 16,
      y = -48,
      visibleRowCount = 5,
      rowHeight = 54,
    })

    return panel
  end,
  RefreshPanel = function(panel, viewModel)
    local rows = viewModel.rows or {}
    if #rows == 0 then
      rows = {
        {
          emptyState = true,
        },
      }
    end

    Components.SetScrollableItems(panel.listSection, rows, function(section, row)
      if row.emptyState then
        Components.AddListRow(section, {
          text = "No approved awards yet.",
          rowHeight = 32,
          actions = {},
        })
        return
      end

      Components.AddListRow(section, {
        text = ("%s\nPins: %d\nMost Recent: %s"):format(
          row.recipient,
          row.pinCount,
          row.mostRecentAwardText or "Unknown date"
        ),
        labelWidth = 560,
        rowHeight = 54,
        actions = {
          {
            text = "View",
            width = 58,
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
                    rowHeight = 32,
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
                  labelWidth = 540,
                  rowHeight = 54,
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

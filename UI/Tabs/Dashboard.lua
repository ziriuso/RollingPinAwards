local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
RPA.UITabs = UITabs

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
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -44)
    panel:SetSize((parent.width or 820) - 24, (parent.height or 520) - 24)

    panel.pendingLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = 0,
      font = "GameFontNormalLarge",
    })
    panel.awardLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = -28,
      font = "GameFontNormalLarge",
    })
    panel.permissionLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = -56,
      width = 700,
      justifyH = "LEFT",
    })
    panel.nominationButton = Components.CreateButton(panel, {
      text = "Open Nominations",
      width = 150,
      x = 0,
      y = -92,
      onClick = function()
        mainFrame:SelectTab("nominations")
      end,
    })
    panel.awardButton = Components.CreateButton(panel, {
      text = "Open Award",
      width = 130,
      x = 160,
      y = -92,
      onClick = function()
        mainFrame:SelectTab("award")
      end,
    })
    panel.recentAwardsLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = -140,
      width = 760,
      justifyH = "LEFT",
      justifyV = "TOP",
    })

    return panel
  end,
  RefreshPanel = function(panel, viewModel)
    Components.SetText(panel.pendingLabel, ("Pending nominations: %d"):format(viewModel.pendingCount or 0))
    Components.SetText(panel.awardLabel, ("Approved awards: %d"):format(viewModel.awardCount or 0))
    Components.SetText(
      panel.permissionLabel,
      viewModel.canManageAwards and "You can approve nominations and award The Burnt Rolling Pin."
        or "You can nominate and vote, but moderation actions require guild permission."
    )

    local lines = { "Recent awards:" }
    for index, award in ipairs(viewModel.recentAwards or {}) do
      if index > 5 then
        break
      end
      lines[#lines + 1] = ("%s - %s"):format(award.recipient, award.reason)
    end
    if #lines == 1 then
      lines[#lines + 1] = "No awards yet."
    end

    Components.SetText(panel.recentAwardsLabel, table.concat(lines, "\n"))
  end,
}

return UITabs.dashboard

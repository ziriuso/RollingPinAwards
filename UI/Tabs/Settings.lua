local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
RPA.UITabs = UITabs

UITabs.settings = {
  id = "settings",
  label = "Settings",
  BuildViewModel = function(bridge)
    return bridge:GetSettingsViewModel()
  end,
  DescribeViewModel = function(viewModel)
    return {
      title = "Settings",
      lines = {
        ("Tooltip enabled: %s"):format(viewModel.tooltipEnabled and "Yes" or "No"),
        ("Announce awards: %s"):format(viewModel.announceAwards and "Yes" or "No"),
        ("Debug mode: %s"):format(viewModel.debug and "Yes" or "No"),
      },
    }
  end,
  BuildPanel = function(parent, mainFrame)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -44)
    panel:SetSize((parent.width or 820) - 24, (parent.height or 520) - 24)

    panel.tooltipCheck = Components.CreateCheckButton(panel, {
      text = "Enable tooltips",
      x = 0,
      y = 0,
    })
    panel.announceCheck = Components.CreateCheckButton(panel, {
      text = "Announce awards",
      x = 0,
      y = -34,
    })
    panel.debugCheck = Components.CreateCheckButton(panel, {
      text = "Enable debug mode",
      x = 0,
      y = -68,
    })
    panel.saveButton = Components.CreateButton(panel, {
      text = "Save Settings",
      width = 130,
      x = 0,
      y = -108,
      onClick = function()
        mainFrame.uiBridge:SaveSettings({
          tooltipEnabled = panel.tooltipCheck:GetChecked(),
          announceAwards = panel.announceCheck:GetChecked(),
          debug = panel.debugCheck:GetChecked(),
        })
        Components.SetText(panel.statusLabel, "Settings saved.")
        mainFrame:RenderActiveTab()
      end,
    })
    panel.statusLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = -144,
      width = 460,
    })

    return panel
  end,
  RefreshPanel = function(panel, viewModel)
    if panel.tooltipCheck.SetChecked then
      panel.tooltipCheck:SetChecked(viewModel.tooltipEnabled)
    end
    if panel.announceCheck.SetChecked then
      panel.announceCheck:SetChecked(viewModel.announceAwards)
    end
    if panel.debugCheck.SetChecked then
      panel.debugCheck:SetChecked(viewModel.debug)
    end
  end,
}

return UITabs.settings

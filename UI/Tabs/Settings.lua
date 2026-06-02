local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
local Styles = RPA.UIStyles or {}
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
    local media = Styles.Media or {}
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -42)
    panel:SetSize((parent.width or 820) - 28, (parent.height or 520) - 56)

    panel.settingsSection = Components.CreateSection(panel, {
      id = "RollingPinAwardsSettingsSection",
      title = "Local Preferences",
      iconPath = media.standardPinIcon,
      iconWidth = 22,
      iconHeight = 22,
      width = 504,
      height = 240,
      x = 0,
      y = 0,
    })
    panel.helperLabel = Components.CreateLabel(panel.settingsSection, {
      text = "These affect only your client. Guild permissions and alias merges stay in the Admin workflow.",
      x = 14,
      y = -38,
      width = 470,
      font = "GameFontHighlightSmall",
      justifyH = "LEFT",
    })
    panel.tooltipCheck = Components.CreateCheckButton(panel.settingsSection, {
      text = "Enable tooltips",
      x = 14,
      y = -82,
    })
    panel.announceCheck = Components.CreateCheckButton(panel.settingsSection, {
      text = "Announce awards",
      x = 14,
      y = -118,
    })
    panel.debugCheck = Components.CreateCheckButton(panel.settingsSection, {
      text = "Enable debug mode",
      x = 14,
      y = -154,
    })
    panel.saveButton = Components.CreateButton(panel.settingsSection, {
      text = "Save Settings",
      width = 184,
      height = 38,
      x = 14,
      y = -194,
      variant = "primary",
      iconPath = media.headerIcon,
      iconWidth = 20,
      iconHeight = 20,
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
    panel.statusLabel = Components.CreateLabel(panel.settingsSection, {
      text = "",
      x = 212,
      y = -202,
      width = 260,
    })

    panel.previewSection = Components.CreateSection(panel, {
      id = "RollingPinAwardsSettingsPreviewSection",
      title = "Preference Notes",
      iconPath = media.headerIcon,
      iconWidth = 22,
      iconHeight = 22,
      width = 260,
      height = 240,
      x = 520,
      y = 0,
    })
    panel.previewLabel = Components.CreateLabel(panel.previewSection, {
      text = table.concat({
        "Tooltips:",
        "Player-summary popups and quick context.",
        "",
        "Announcements:",
        "Broadcast awards when your workflow uses it.",
        "",
        "Debug:",
        "Extra troubleshooting detail for testing and sync review.",
      }, "\n"),
      x = 14,
      y = -38,
      width = 228,
      justifyH = "LEFT",
      justifyV = "TOP",
      font = "GameFontHighlightSmall",
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

    if panel.statusLabel.text == "" then
      Components.SetText(panel.statusLabel, "Personal settings only.")
    end
  end,
}

return UITabs.settings

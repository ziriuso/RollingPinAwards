local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

if not RPA.UIStyles then
  dofile("UI/Styles.lua")
end

if not RPA.UIComponents then
  dofile("UI/Components.lua")
end

local Components = RPA.UIComponents or {}
local Styles = RPA.UIStyles or {}

local SettingsPage = RPA.SettingsPage or {}
RPA.SettingsPage = SettingsPage

local function formatDuration(seconds)
  seconds = tonumber(seconds) or 7

  return ("%d seconds"):format(seconds)
end

local function refreshDurationLabel(panel, settings)
  if panel and panel.toastDurationValueLabel then
    Components.SetText(panel.toastDurationValueLabel, formatDuration(settings.toastDurationSeconds))
  end
end

function SettingsPage:Build(parent, mainFrame)
  local panel = CreateFrame("Frame", "RollingPinAwardsSettingsPage", parent, "BackdropTemplate")
  panel.width = parent.width or ((Styles.Layout or {}).panelWidth or 720)
  panel.height = parent.height or 480

  if panel.SetSize then
    panel:SetSize(panel.width, panel.height)
  end
  if panel.SetPoint then
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  end

  panel.toastSection = Components.CreateSection(panel, {
    id = "RollingPinAwardsSettingsToastSection",
    title = "Toasts",
    width = math.min(panel.width - 120, 640),
    height = 210,
    x = (Styles.Layout or {}).panelX or 59,
    y = -58,
  })

  panel.toastsCheck = Components.CreateCheckButton(panel.toastSection, {
    text = "Enable reward toasts",
    x = 18,
    y = -48,
  })

  panel.toastDurationLabel = Components.CreateLabel(panel.toastSection, {
    text = "Toast duration",
    x = 18,
    y = -86,
    width = 140,
    justifyH = "LEFT",
    font = "GameFontHighlight",
  })

  panel.toastDurationDecreaseButton = Components.CreateButton(panel.toastSection, {
    text = "-",
    width = 32,
    height = 28,
    x = 162,
    y = -80,
    variant = "secondary",
  })

  panel.toastDurationValueLabel = Components.CreateLabel(panel.toastSection, {
    text = "",
    x = 202,
    y = -86,
    width = 90,
    justifyH = "CENTER",
    font = "GameFontHighlight",
  })

  panel.toastDurationIncreaseButton = Components.CreateButton(panel.toastSection, {
    text = "+",
    width = 32,
    height = 28,
    x = 300,
    y = -80,
    variant = "secondary",
  })

  panel.anchorButton = Components.CreateButton(panel.toastSection, {
    text = "Toggle Anchors Mode",
    width = 174,
    height = 28,
    x = 18,
    y = -126,
    variant = "secondary",
  })

  panel.testToastButton = Components.CreateButton(panel.toastSection, {
    text = "Test Toast",
    width = 112,
    height = 28,
    x = 210,
    y = -126,
    variant = "primary",
  })

  panel.statusLabel = Components.CreateLabel(panel.toastSection, {
    text = "",
    x = 18,
    y = -166,
    width = (panel.toastSection.width or 640) - 36,
    justifyH = "LEFT",
    font = "GameFontHighlightSmall",
  })

  self:Refresh(panel, mainFrame)
  Components.SetVisible(panel, false)

  return panel
end

function SettingsPage:Refresh(panel, mainFrame)
  if not panel then
    return nil
  end

  local addon = mainFrame and mainFrame.addon
  local settings = addon and addon.db and addon.db:GetLocalSettings() or {
    toastsEnabled = true,
    toastDurationSeconds = 7,
  }

  refreshDurationLabel(panel, settings)

  if panel.toastsCheck then
    panel.toastsCheck:SetChecked(settings.toastsEnabled ~= false)
    Components.SetButtonHandler(panel.toastsCheck, function(checkButton)
      if checkButton.disabled then
        return
      end

      checkButton:SetChecked(not checkButton:GetChecked())
      if addon and addon.db then
        addon.db:SetToastsEnabled(checkButton:GetChecked())
      end
      if addon and addon.toast and checkButton:GetChecked() == false and addon.toast.frame then
        Components.SetVisible(addon.toast.frame, false)
      end
    end)
  end

  if panel.toastDurationDecreaseButton then
    Components.SetButtonHandler(panel.toastDurationDecreaseButton, function()
      if addon and addon.db then
        local saved = addon.db:SetToastDurationSeconds((addon.db:GetLocalSettings().toastDurationSeconds or 7) - 1)
        refreshDurationLabel(panel, {
          toastDurationSeconds = saved,
        })
      end
    end)
  end

  if panel.toastDurationIncreaseButton then
    Components.SetButtonHandler(panel.toastDurationIncreaseButton, function()
      if addon and addon.db then
        local saved = addon.db:SetToastDurationSeconds((addon.db:GetLocalSettings().toastDurationSeconds or 7) + 1)
        refreshDurationLabel(panel, {
          toastDurationSeconds = saved,
        })
      end
    end)
  end

  if panel.anchorButton then
    Components.SetButtonHandler(panel.anchorButton, function()
      if addon and addon.toast and type(addon.toast.ToggleAnchorMode) == "function" then
        local enabled = addon.toast:ToggleAnchorMode()
        Components.SetText(panel.statusLabel, enabled and "Move the toast anchor, then right-click it to lock." or "")
      end
    end)
  end

  if panel.testToastButton then
    Components.SetButtonHandler(panel.testToastButton, function()
      if addon and addon.toast and type(addon.toast.ShowAwardToast) == "function" then
        addon.toast:ShowAwardToast({
          awardType = "burnt",
          reason = "Preview toast",
        })
      end
    end)
  end

  return panel
end

return RPA.SettingsPage

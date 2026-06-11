local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

if not RPA.UIStyles then
  dofile("RollingPinAwards/UI/Styles.lua")
end

if not RPA.UIComponents then
  dofile("RollingPinAwards/UI/Components.lua")
end

local Components = RPA.UIComponents or {}
local Styles = RPA.UIStyles or {}

local SettingsPage = RPA.SettingsPage or {}
RPA.SettingsPage = SettingsPage

local function formatDuration(seconds)
  seconds = tonumber(seconds) or 7

  return ("%d seconds"):format(seconds)
end

local function formatScale(scale)
  scale = tonumber(scale) or 1

  return ("%d%%"):format(math.floor((scale * 100) + 0.5))
end

local function refreshDurationLabel(panel, settings)
  if panel and panel.toastDurationValueLabel then
    Components.SetText(panel.toastDurationValueLabel, formatDuration(settings.toastDurationSeconds))
  end
end

local function refreshScaleLabel(panel, settings)
  if panel and panel.addonScaleValueLabel then
    Components.SetText(panel.addonScaleValueLabel, formatScale(settings.addonScale))
  end
end

local function parseDateInput(value, endOfDay)
  if type(value) ~= "string" or value == "" then
    return nil
  end

  local year, month, day = value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  if not year then
    return nil, "Use YYYY-MM-DD dates."
  end

  local dateParts = {
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = endOfDay and 23 or 0,
    min = endOfDay and 59 or 0,
    sec = endOfDay and 59 or 0,
  }

  if type(time) == "function" then
    return time(dateParts)
  end

  if _G.os and type(_G.os.time) == "function" then
    return _G.os.time(dateParts)
  end

  return nil, "Date parsing is unavailable."
end

local function formatFilterDate(addon, timestamp)
  if type(timestamp) ~= "number" or timestamp <= 0 then
    return ""
  end

  if addon and addon.Time and type(addon.Time.FormatDate) == "function" then
    return addon.Time:FormatDate(timestamp)
  end

  return tostring(timestamp)
end

local function refreshReportingControls(panel, mainFrame, filter)
  if not panel then
    return
  end

  local addon = mainFrame and mainFrame.addon
  local activeFilter = filter or {
    mode = "all_time",
    label = "All Time",
  }
  panel.reportingSelectedMode = activeFilter.mode == "custom" and "custom" or "all_time"

  if panel.reportingValueLabel then
    Components.SetText(panel.reportingValueLabel, activeFilter.label or "All Time")
  end
  if panel.reportingLabelInput then
    Components.SetText(panel.reportingLabelInput, activeFilter.mode == "custom" and (activeFilter.label or "") or "")
  end
  if panel.reportingStartInput then
    Components.SetText(panel.reportingStartInput, formatFilterDate(addon, activeFilter.startsAt))
  end
  if panel.reportingEndInput then
    Components.SetText(panel.reportingEndInput, formatFilterDate(addon, activeFilter.endsAt))
  end
  if panel.reportingStatusLabel then
    Components.SetText(panel.reportingStatusLabel, "")
  end
  if Components.SetButtonVariant then
    Components.SetButtonVariant(panel.reportingAllTimeButton, panel.reportingSelectedMode == "all_time" and "selected" or "secondary")
    Components.SetButtonVariant(panel.reportingCustomButton, panel.reportingSelectedMode == "custom" and "selected" or "secondary")
  end
end

local function applyAddonScale(panel, mainFrame, value)
  local addon = mainFrame and mainFrame.addon
  if not addon or not addon.db then
    return nil
  end

  local saved = addon.db:SetAddonScale(value)

  if panel and panel.addonScaleSlider and panel.addonScaleSlider.SetValue then
    panel.addonScaleSlider.__settingValue = true
    panel.addonScaleSlider:SetValue(saved)
    panel.addonScaleSlider.__settingValue = false
  end

  refreshScaleLabel(panel, {
    addonScale = saved,
  })

  if mainFrame and type(mainFrame.ApplyScale) == "function" then
    mainFrame:ApplyScale(saved)
  end

  return saved
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
    height = 260,
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

  panel.addonScaleLabel = Components.CreateLabel(panel.toastSection, {
    text = "Addon scale",
    x = 18,
    y = -126,
    width = 140,
    justifyH = "LEFT",
    font = "GameFontHighlight",
  })

  panel.addonScaleDecreaseButton = Components.CreateButton(panel.toastSection, {
    text = "-",
    width = 32,
    height = 28,
    x = 162,
    y = -118,
    variant = "secondary",
  })

  panel.addonScaleSlider = Components.CreateSlider(panel.toastSection, {
    id = "RollingPinAwardsAddonScaleSlider",
    width = 136,
    height = 18,
    x = 202,
    y = -122,
    minValue = 0.8,
    maxValue = 1.25,
    step = 0.05,
  })

  panel.addonScaleIncreaseButton = Components.CreateButton(panel.toastSection, {
    text = "+",
    width = 32,
    height = 28,
    x = 348,
    y = -118,
    variant = "secondary",
  })

  panel.addonScaleValueLabel = Components.CreateLabel(panel.toastSection, {
    text = "",
    x = 392,
    y = -126,
    width = 60,
    justifyH = "LEFT",
    font = "GameFontHighlight",
  })

  panel.anchorButton = Components.CreateButton(panel.toastSection, {
    text = "Toggle Anchors",
    width = 174,
    height = 28,
    x = 18,
    y = -166,
    variant = "secondary",
  })

  panel.testToastButton = Components.CreateButton(panel.toastSection, {
    text = "Test Toast",
    width = 112,
    height = 28,
    x = 210,
    y = -166,
    variant = "primary",
  })

  panel.statusLabel = Components.CreateLabel(panel.toastSection, {
    text = "",
    x = 18,
    y = -206,
    width = (panel.toastSection.width or 640) - 36,
    justifyH = "LEFT",
    font = "GameFontHighlightSmall",
  })

  panel.reportingSection = Components.CreateSection(panel, {
    id = "RollingPinAwardsSettingsReportingSection",
    title = "Reporting Filter",
    width = math.min(panel.width - 120, 640),
    height = 188,
    x = (Styles.Layout or {}).panelX or 59,
    y = -330,
  })

  panel.reportingValueLabel = Components.CreateLabel(panel.reportingSection, {
    text = "All Time",
    x = 18,
    y = -46,
    width = 210,
    justifyH = "LEFT",
    font = "GameFontHighlight",
  })

  panel.reportingAllTimeButton = Components.CreateButton(panel.reportingSection, {
    text = "All Time",
    width = 112,
    height = 28,
    x = 246,
    y = -40,
    variant = "selected",
  })

  panel.reportingCustomButton = Components.CreateButton(panel.reportingSection, {
    text = "Custom",
    width = 112,
    height = 28,
    x = 368,
    y = -40,
    variant = "secondary",
  })

  panel.reportingLabelInput = Components.CreateEditBox(panel.reportingSection, {
    width = 180,
    x = 18,
    y = -86,
    maxLetters = 32,
  })
  panel.reportingStartInput = Components.CreateEditBox(panel.reportingSection, {
    width = 128,
    x = 212,
    y = -86,
    maxLetters = 10,
  })
  panel.reportingEndInput = Components.CreateEditBox(panel.reportingSection, {
    width = 128,
    x = 354,
    y = -86,
    maxLetters = 10,
  })

  panel.reportingLabelHint = Components.CreateLabel(panel.reportingSection, {
    text = "Label",
    x = 18,
    y = -70,
    width = 120,
    justifyH = "LEFT",
    font = "GameFontHighlightSmall",
  })
  panel.reportingStartHint = Components.CreateLabel(panel.reportingSection, {
    text = "Start",
    x = 212,
    y = -70,
    width = 120,
    justifyH = "LEFT",
    font = "GameFontHighlightSmall",
  })
  panel.reportingEndHint = Components.CreateLabel(panel.reportingSection, {
    text = "End",
    x = 354,
    y = -70,
    width = 120,
    justifyH = "LEFT",
    font = "GameFontHighlightSmall",
  })

  panel.reportingSaveButton = Components.CreateButton(panel.reportingSection, {
    text = "Save",
    width = 90,
    height = 28,
    x = 496,
    y = -86,
    variant = "primary",
  })

  panel.reportingStatusLabel = Components.CreateLabel(panel.reportingSection, {
    text = "",
    x = 18,
    y = -130,
    width = (panel.reportingSection.width or 640) - 36,
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
    addonScale = 0.8,
    reportingFilter = {
      mode = "all_time",
      label = "All Time",
    },
  }

  refreshDurationLabel(panel, settings)
  refreshScaleLabel(panel, settings)
  refreshReportingControls(panel, mainFrame, settings.reportingFilter)

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

  if panel.addonScaleSlider then
    panel.addonScaleSlider.__settingValue = true
    panel.addonScaleSlider:SetValue(settings.addonScale or 0.8)
    panel.addonScaleSlider.__settingValue = false
    panel.addonScaleSlider:SetScript("OnValueChanged", function(slider, value)
      if slider.__settingValue then
        return
      end

      applyAddonScale(panel, mainFrame, value)
    end)
  end

  if panel.addonScaleDecreaseButton then
    Components.SetButtonHandler(panel.addonScaleDecreaseButton, function()
      local current = addon and addon.db and addon.db:GetLocalSettings().addonScale or 0.8
      applyAddonScale(panel, mainFrame, current - 0.05)
    end)
  end

  if panel.addonScaleIncreaseButton then
    Components.SetButtonHandler(panel.addonScaleIncreaseButton, function()
      local current = addon and addon.db and addon.db:GetLocalSettings().addonScale or 0.8
      applyAddonScale(panel, mainFrame, current + 0.05)
    end)
  end

  if panel.reportingAllTimeButton then
    Components.SetButtonHandler(panel.reportingAllTimeButton, function()
      if addon and addon.db then
        local filter = addon.db:SetReportingFilter({
          mode = "all_time",
        })
        refreshReportingControls(panel, mainFrame, filter)
        if mainFrame and type(mainFrame.RenderActiveTab) == "function" then
          mainFrame:RenderActiveTab()
        end
      end
    end)
  end

  if panel.reportingCustomButton then
    Components.SetButtonHandler(panel.reportingCustomButton, function()
      panel.reportingSelectedMode = "custom"
      if Components.SetButtonVariant then
        Components.SetButtonVariant(panel.reportingAllTimeButton, "secondary")
        Components.SetButtonVariant(panel.reportingCustomButton, "selected")
      end
    end)
  end

  if panel.reportingSaveButton then
    Components.SetButtonHandler(panel.reportingSaveButton, function()
      if not addon or not addon.db then
        return
      end

      local startsAt, startErr = parseDateInput(panel.reportingStartInput and panel.reportingStartInput:GetText() or "", false)
      local endsAt, endErr = parseDateInput(panel.reportingEndInput and panel.reportingEndInput:GetText() or "", true)
      if startErr or endErr then
        Components.SetText(panel.reportingStatusLabel, startErr or endErr)
        return
      end

      local filter = addon.db:SetReportingFilter({
        mode = "custom",
        label = panel.reportingLabelInput and panel.reportingLabelInput:GetText() or "",
        startsAt = startsAt,
        endsAt = endsAt,
      })
      refreshReportingControls(panel, mainFrame, filter)
      Components.SetText(panel.reportingStatusLabel, "Reporting filter saved.")
      if mainFrame and type(mainFrame.RenderActiveTab) == "function" then
        mainFrame:RenderActiveTab()
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

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

local function parseDateParts(value)
  if type(value) ~= "string" then
    return nil
  end

  local year, month, day = value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  if not year then
    return nil
  end

  return tonumber(year), tonumber(month), tonumber(day)
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

local function isLeapYear(year)
  return year % 400 == 0 or (year % 4 == 0 and year % 100 ~= 0)
end

local function daysInMonth(year, month)
  local monthDays = {
    31,
    isLeapYear(year) and 29 or 28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  }

  return monthDays[month] or 31
end

local function shiftCalendarMonth(dialog, offset)
  local month = (dialog.displayMonth or 1) + offset
  local year = dialog.displayYear or 2024

  while month < 1 do
    month = month + 12
    year = year - 1
  end

  while month > 12 do
    month = month - 12
    year = year + 1
  end

  dialog.displayYear = year
  dialog.displayMonth = month
end

local function updateCalendarDialog(panel)
  local dialog = panel.reportingCalendarDialog
  if not dialog then
    return
  end

  local year = dialog.displayYear or 2024
  local month = dialog.displayMonth or 1
  Components.SetText(dialog.monthLabel, ("%04d-%02d"):format(year, month))

  local maxDay = daysInMonth(year, month)
  dialog.dayButtonsByDay = {}
  for day, button in ipairs(dialog.dayButtons or {}) do
    Components.SetText(button.label, tostring(day))
    Components.SetVisible(button, day <= maxDay)
    if day <= maxDay then
      dialog.dayButtonsByDay[day] = button
    end
  end
end

local function ensureCalendarDialog(panel)
  if panel.reportingCalendarDialog then
    return panel.reportingCalendarDialog
  end

  local dialog = Components.CreateModalWindow(panel, {
    id = "RollingPinAwardsReportingCalendarDialog",
    title = "Pick Date",
    width = 286,
    height = 300,
    closeStyle = "x",
    draggable = true,
  })
  dialog.displayYear = 2024
  dialog.displayMonth = 1

  dialog.previousButton = Components.CreateButton(dialog, {
    text = "<",
    width = 32,
    height = 26,
    x = 26,
    y = -50,
    variant = "secondary",
  })
  dialog.monthLabel = Components.CreateLabel(dialog, {
    text = "2024-01",
    x = 72,
    y = -54,
    width = 120,
    justifyH = "CENTER",
    font = "GameFontHighlight",
  })
  dialog.nextButton = Components.CreateButton(dialog, {
    text = ">",
    width = 32,
    height = 26,
    x = 206,
    y = -50,
    variant = "secondary",
  })

  dialog.dayButtons = {}
  dialog.dayButtonsByDay = {}
  for day = 1, 31 do
    local index = day - 1
    local col = index % 7
    local row = math.floor(index / 7)
    local button = Components.CreateButton(dialog, {
      text = tostring(day),
      width = 32,
      height = 28,
      labelX = 0,
      labelWidth = 32,
      x = 24 + (col * 36),
      y = -92 - (row * 34),
      variant = "secondary",
      onClick = function()
        if dialog.targetInput then
          Components.SetText(
            dialog.targetInput,
            ("%04d-%02d-%02d"):format(dialog.displayYear or 2024, dialog.displayMonth or 1, day)
          )
        end
        Components.SetVisible(dialog, false)
      end,
    })
    dialog.dayButtons[day] = button
    dialog.dayButtonsByDay[day] = button
  end

  Components.SetButtonHandler(dialog.previousButton, function()
    shiftCalendarMonth(dialog, -1)
    updateCalendarDialog(panel)
  end)
  Components.SetButtonHandler(dialog.nextButton, function()
    shiftCalendarMonth(dialog, 1)
    updateCalendarDialog(panel)
  end)

  panel.reportingCalendarDialog = dialog
  Components.SetVisible(dialog, false)

  return dialog
end

local function openCalendarForInput(panel, input)
  local dialog = ensureCalendarDialog(panel)
  local year, month = parseDateParts(input and input:GetText() or "")

  dialog.targetInput = input
  dialog.displayYear = year or dialog.displayYear or 2024
  dialog.displayMonth = month or dialog.displayMonth or 1
  updateCalendarDialog(panel)
  Components.SetVisible(dialog, true)

  return dialog
end

local function refreshReportingControls(panel, mainFrame, filter)
  if not panel then
    return
  end

  local addon = mainFrame and mainFrame.addon
  local activeFilter = filter or {}
  if panel.reportingStartInput then
    Components.SetText(panel.reportingStartInput, formatFilterDate(addon, activeFilter.startsAt))
  end
  if panel.reportingEndInput then
    Components.SetText(panel.reportingEndInput, formatFilterDate(addon, activeFilter.endsAt))
  end
  if panel.reportingStatusLabel then
    Components.SetText(panel.reportingStatusLabel, "")
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

  panel.addonScaleValueLabel = Components.CreateLabel(panel.toastSection, {
    text = "",
    x = 202,
    y = -126,
    width = 90,
    justifyH = "CENTER",
    font = "GameFontHighlight",
  })

  panel.addonScaleIncreaseButton = Components.CreateButton(panel.toastSection, {
    text = "+",
    width = 32,
    height = 28,
    x = 300,
    y = -118,
    variant = "secondary",
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
    width = 390,
    height = 188,
    x = ((Styles.Layout or {}).panelX or 59) + 250,
    y = -330,
  })

  panel.launcherSection = Components.CreateSection(panel, {
    id = "RollingPinAwardsSettingsLauncherSection",
    title = "Minimap",
    width = 230,
    height = 188,
    x = (Styles.Layout or {}).panelX or 59,
    y = -330,
  })

  panel.minimapButtonCheck = Components.CreateCheckButton(panel.launcherSection, {
    text = "Show minimap button",
    x = 18,
    y = -50,
    labelTextRole = "descriptionSmall",
  })

  panel.reportingStartInput = Components.CreateEditBox(panel.reportingSection, {
    width = 128,
    x = 18,
    y = -72,
    maxLetters = 10,
  })
  panel.reportingStartCalendarButton = Components.CreateButton(panel.reportingSection, {
    text = "...",
    width = 34,
    height = 28,
    x = 154,
    y = -72,
    variant = "secondary",
  })
  panel.reportingEndInput = Components.CreateEditBox(panel.reportingSection, {
    width = 128,
    x = 198,
    y = -72,
    maxLetters = 10,
  })
  panel.reportingEndCalendarButton = Components.CreateButton(panel.reportingSection, {
    text = "...",
    width = 34,
    height = 28,
    x = 334,
    y = -72,
    variant = "secondary",
  })

  panel.reportingStartHint = Components.CreateLabel(panel.reportingSection, {
    text = "Start",
    x = 18,
    y = -56,
    width = 120,
    justifyH = "LEFT",
    font = "GameFontHighlightSmall",
  })
  panel.reportingEndHint = Components.CreateLabel(panel.reportingSection, {
    text = "End",
    x = 198,
    y = -56,
    width = 120,
    justifyH = "LEFT",
    font = "GameFontHighlightSmall",
  })

  panel.reportingSaveButton = Components.CreateButton(panel.reportingSection, {
    text = "Save",
    width = 72,
    height = 28,
    x = 18,
    y = -116,
    variant = "primary",
  })
  panel.reportingClearButton = Components.CreateButton(panel.reportingSection, {
    text = "Clear",
    width = 72,
    height = 28,
    x = 98,
    y = -116,
    variant = "secondary",
  })

  panel.reportingStatusLabel = Components.CreateLabel(panel.reportingSection, {
    text = "",
    x = 184,
    y = -122,
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

  if panel.minimapButtonCheck then
    panel.minimapButtonCheck:SetChecked(not addon or not addon.db or addon.db:IsMinimapButtonShown())
    Components.SetButtonHandler(panel.minimapButtonCheck, function(checkButton)
      if checkButton.disabled then
        return
      end

      checkButton:SetChecked(not checkButton:GetChecked())
      if addon and addon.db then
        addon.db:SetMinimapButtonShown(checkButton:GetChecked())
      end
      if addon and addon.minimapButton and type(addon.minimapButton.RefreshVisibility) == "function" then
        addon.minimapButton:RefreshVisibility()
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

  if panel.reportingStartCalendarButton then
    Components.SetButtonHandler(panel.reportingStartCalendarButton, function()
      openCalendarForInput(panel, panel.reportingStartInput)
    end)
  end

  if panel.reportingEndCalendarButton then
    Components.SetButtonHandler(panel.reportingEndCalendarButton, function()
      openCalendarForInput(panel, panel.reportingEndInput)
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

      local filter
      if not startsAt and not endsAt then
        filter = addon.db:SetReportingFilter({
          mode = "all_time",
        })
      else
        filter = addon.db:SetReportingFilter({
          mode = "custom",
          label = "Custom Range",
          startsAt = startsAt,
          endsAt = endsAt,
        })
      end
      refreshReportingControls(panel, mainFrame, filter)
      if mainFrame and type(mainFrame.RenderActiveTab) == "function" then
        mainFrame:RenderActiveTab()
      end
      Components.SetText(panel.reportingStatusLabel, "Reporting filter saved.")
    end)
  end

  if panel.reportingClearButton then
    Components.SetButtonHandler(panel.reportingClearButton, function()
      if addon and addon.db then
        local filter = addon.db:SetReportingFilter({
          mode = "all_time",
        })
        refreshReportingControls(panel, mainFrame, filter)
        if mainFrame and type(mainFrame.RenderActiveTab) == "function" then
          mainFrame:RenderActiveTab()
        end
        Components.SetText(panel.reportingStatusLabel, "Reporting filter cleared.")
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

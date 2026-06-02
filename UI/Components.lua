local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Components = RPA.UIComponents or {}
RPA.UIComponents = Components

function Components.CreateWindow(config)
  if type(CreateFrame) == "function" then
    local frame = CreateFrame("Frame", config.id, UIParent, "BackdropTemplate")

    if frame.SetSize then
      frame:SetSize(config.width, config.height)
    end

    if frame.SetPoint then
      frame:SetPoint("CENTER")
    end

    if frame.Hide then
      frame:Hide()
    end

    if frame.SetBackdrop then
      frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {
          left = 4,
          right = 4,
          top = 4,
          bottom = 4,
        },
      })
    else
      frame.backdrop = {
        enabled = true,
      }
    end

    if frame.SetBackdropColor then
      frame:SetBackdropColor(0.06, 0.05, 0.08, 0.95)
    end

    if frame.EnableMouse then
      frame:EnableMouse(true)
    end

    if frame.SetMovable then
      frame:SetMovable(true)
    end

    if frame.RegisterForDrag then
      frame:RegisterForDrag("LeftButton")
    end

    if frame.SetScript then
      frame:SetScript("OnDragStart", function(self)
        if self.StartMoving then
          self:StartMoving()
        end
      end)
      frame:SetScript("OnDragStop", function(self)
        if self.StopMovingOrSizing then
          self:StopMovingOrSizing()
        end
      end)
    end

    frame.visible = false
    frame.title = config.title

    local titleText = nil
    if type(frame.CreateFontString) == "function" then
      titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      if titleText.SetPoint then
        titleText:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -12)
      end
      titleText:SetText(config.title or "")
    end

    frame.titleText = titleText

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    if closeButton.SetPoint then
      closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    end
    if closeButton.SetScript then
      closeButton:SetScript("OnClick", function()
        Components.SetVisible(frame, false)
      end)
    end
    frame.closeButton = closeButton

    return frame
  end

  return {
    id = config.id,
    title = config.title,
    width = config.width,
    height = config.height,
    closeButton = {
      Click = function() end,
    },
    backdrop = {
      enabled = true,
    },
    visible = false,
  }
end

function Components.MakeTab(spec)
  return {
    describeViewModel = spec.DescribeViewModel,
    buildPanel = spec.BuildPanel,
    refreshPanel = spec.RefreshPanel,
    id = spec.id,
    isVisible = spec.IsVisible,
    label = spec.label,
    buildViewModel = spec.BuildViewModel,
  }
end

function Components.CreateTabButton(parent, spec, index)
  if type(CreateFrame) == "function" and parent then
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")

    if button.SetText then
      button:SetText(spec.label)
    end

    if button.SetSize then
      button:SetSize(128, 24)
    end

    if button.SetPoint then
      button:SetPoint("TOPLEFT", 24 + ((index - 1) * 132), -32)
    end

    return button
  end

  return {
    id = spec.id,
    label = spec.label,
  }
end

function Components.CreateContentPanel(parent, config)
  local panel = CreateFrame("Frame", config.id, parent, "BackdropTemplate")

  if panel.SetPoint then
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, -72)
  end

  if panel.SetSize then
    panel:SetSize(config.width or 100, config.height or 100)
  end

  if panel.SetBackdrop then
    panel:SetBackdrop({
      bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 8,
      edgeSize = 8,
      insets = {
        left = 2,
        right = 2,
        top = 2,
        bottom = 2,
      },
    })
  else
    panel.backdrop = {
      enabled = true,
    }
  end

  if panel.SetBackdropColor then
    panel:SetBackdropColor(0.02, 0.02, 0.03, 0.75)
  end

  panel.width = config.width or 100
  panel.height = config.height or 100

  local titleText = {
    text = "",
  }
  local bodyText = {
    text = "",
  }

  if type(panel.CreateFontString) == "function" then
    titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bodyText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

    if titleText.SetPoint then
      titleText:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    end

    if bodyText.SetPoint then
      bodyText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -16)
    end

    if bodyText.SetJustifyH then
      bodyText:SetJustifyH("LEFT")
    end

    if bodyText.SetJustifyV then
      bodyText:SetJustifyV("TOP")
    end

    if bodyText.SetWidth then
      bodyText:SetWidth((config.width or 0) - 32)
    end
  end

  panel.titleText = titleText
  panel.bodyText = bodyText
  Components.SetVisible(panel, true)

  return panel
end

function Components.CreateSection(parent, config)
  local section = CreateFrame("Frame", config.id, parent, "BackdropTemplate")
  section.width = config.width or 100
  section.height = config.height or 100

  if section.SetSize then
    section:SetSize(section.width, section.height)
  end

  if section.SetPoint then
    section:SetPoint(config.anchor or "TOPLEFT", parent, config.relativeTo or "TOPLEFT", config.x or 0, config.y or 0)
  end

  if section.SetBackdrop then
    section:SetBackdrop({
      bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 8,
      edgeSize = 8,
      insets = {
        left = 2,
        right = 2,
        top = 2,
        bottom = 2,
      },
    })
  end

  if section.SetBackdropColor then
    section:SetBackdropColor(0.02, 0.02, 0.03, 0.75)
  end

  local title = Components.CreateLabel(section, {
    text = config.title or "",
    x = 12,
    y = -10,
    font = "GameFontNormal",
  })

  section.titleText = title
  section.rows = {}

  return section
end

function Components.CreateScrollableSection(parent, config)
  local section = Components.CreateSection(parent, config)
  section.visibleRowCount = config.visibleRowCount or 5
  section.rowHeight = config.rowHeight or 44
  section.scrollOffset = 0
  section.items = {}

  local scrollBar = CreateFrame("Slider", nil, section, "OptionsSliderTemplate")
  if scrollBar.SetPoint then
    scrollBar:SetPoint("TOPRIGHT", section, "TOPRIGHT", -10, -28)
  end
  if scrollBar.SetSize then
    scrollBar:SetSize(16, section.height - 44)
  end
  if scrollBar.SetMinMaxValues then
    scrollBar:SetMinMaxValues(0, 0)
  end
  if scrollBar.SetValueStep then
    scrollBar:SetValueStep(1)
  end
  if scrollBar.SetObeyStepOnDrag then
    scrollBar:SetObeyStepOnDrag(true)
  end
  if scrollBar.SetOrientation then
    scrollBar:SetOrientation("VERTICAL")
  end
  scrollBar.minValue = 0
  scrollBar.maxValue = 0

  section.scrollBar = scrollBar

  if scrollBar.SetScript then
    scrollBar:SetScript("OnValueChanged", function(_, value)
      section.scrollOffset = math.max(0, math.floor((value or 0) + 0.5))
      Components.RenderScrollableSection(section)
    end)
  end

  if scrollBar.Low and scrollBar.Low.Hide then
    scrollBar.Low:Hide()
  end

  if scrollBar.High and scrollBar.High.Hide then
    scrollBar.High:Hide()
  end

  if scrollBar.Text and scrollBar.Text.Hide then
    scrollBar.Text:Hide()
  end

  if section.EnableMouseWheel then
    section:EnableMouseWheel(true)
  end

  if section.SetScript then
    section:SetScript("OnMouseWheel", function(self, delta)
      local currentValue = 0
      if self.scrollBar and self.scrollBar.GetValue then
        currentValue = self.scrollBar:GetValue() or 0
      else
        currentValue = self.scrollOffset or 0
      end

      local nextValue = currentValue - (delta or 0)
      if self.scrollBar and self.scrollBar.SetValue then
        self.scrollBar:SetValue(nextValue)
      else
        self.scrollOffset = math.max(0, math.min(self.scrollBar.maxValue or 0, nextValue))
        Components.RenderScrollableSection(self)
      end
    end)
  end

  return section
end

function Components.CreateLabel(parent, config)
  local label = parent.CreateFontString and parent:CreateFontString(nil, "OVERLAY", config.font or "GameFontHighlight") or {
    text = "",
  }

  if label.SetPoint then
    label:SetPoint(config.anchor or "TOPLEFT", parent, config.relativeTo or "TOPLEFT", config.x or 0, config.y or 0)
  end

  if config.width and label.SetWidth then
    label:SetWidth(config.width)
  end

  if config.justifyH and label.SetJustifyH then
    label:SetJustifyH(config.justifyH)
  end

  if config.justifyV and label.SetJustifyV then
    label:SetJustifyV(config.justifyV)
  end

  Components.SetText(label, config.text or "")

  return label
end

function Components.CreateButton(parent, config)
  local button = CreateFrame("Button", nil, parent, config.template or "UIPanelButtonTemplate")

  if button.SetSize then
    button:SetSize(config.width or 120, config.height or 24)
  end

  if button.SetPoint then
    button:SetPoint(config.anchor or "TOPLEFT", parent, config.relativeTo or "TOPLEFT", config.x or 0, config.y or 0)
  end

  Components.SetText(button, config.text or "")

  if config.onClick then
    Components.SetButtonHandler(button, config.onClick)
  end

  return button
end

function Components.CreateEditBox(parent, config)
  local editBox = CreateFrame("EditBox", nil, parent, config.template or "InputBoxTemplate")

  if editBox.SetSize then
    editBox:SetSize(config.width or 180, config.height or 28)
  end

  if editBox.SetPoint then
    editBox:SetPoint(config.anchor or "TOPLEFT", parent, config.relativeTo or "TOPLEFT", config.x or 0, config.y or 0)
  end

  if editBox.SetAutoFocus then
    editBox:SetAutoFocus(false)
  end

  if config.multiLine and editBox.SetMultiLine then
    editBox:SetMultiLine(true)
  end

  if config.maxLetters and editBox.SetMaxLetters then
    editBox:SetMaxLetters(config.maxLetters)
  end

  if config.text then
    Components.SetText(editBox, config.text)
  end

  return editBox
end

function Components.CreateCheckButton(parent, config)
  local button = CreateFrame("CheckButton", nil, parent, config.template or "UICheckButtonTemplate")

  if button.SetPoint then
    button:SetPoint(config.anchor or "TOPLEFT", parent, config.relativeTo or "TOPLEFT", config.x or 0, config.y or 0)
  end

  if config.text and config.text ~= "" then
    local text = Components.CreateLabel(parent, {
      text = config.text or "",
      x = (config.x or 0) + 28,
      y = config.y or 0,
      font = "GameFontHighlight",
    })
    button.label = text
  end

  return button
end

function Components.CreateConfirmationDialog(parent, config)
  local dialog = CreateFrame("Frame", config.id, parent, "BackdropTemplate")
  dialog.width = config.width or 420
  dialog.height = config.height or 160

  if dialog.SetSize then
    dialog:SetSize(dialog.width, dialog.height)
  end

  if dialog.SetPoint then
    dialog:SetPoint("CENTER", parent, "CENTER", config.x or 0, config.y or 0)
  end

  if dialog.SetBackdrop then
    dialog:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 16,
      insets = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4,
      },
    })
  end

  if dialog.SetBackdropColor then
    dialog:SetBackdropColor(0.04, 0.03, 0.05, 0.98)
  end

  dialog.titleLabel = Components.CreateLabel(dialog, {
    text = config.title or "Confirm",
    x = 16,
    y = -16,
    font = "GameFontNormalLarge",
  })
  dialog.messageLabel = Components.CreateLabel(dialog, {
    text = config.message or "",
    x = 16,
    y = -46,
    width = dialog.width - 32,
    justifyH = "LEFT",
    justifyV = "TOP",
  })
  dialog.confirmButton = Components.CreateButton(dialog, {
    text = config.confirmText or "Confirm",
    width = 100,
    x = 16,
    y = -118,
  })
  dialog.cancelButton = Components.CreateButton(dialog, {
    text = config.cancelText or "Cancel",
    width = 100,
    x = 126,
    y = -118,
    onClick = function()
      Components.SetVisible(dialog, false)
    end,
  })

  Components.SetVisible(dialog, false)

  return dialog
end

function Components.CreateModalWindow(parent, config)
  local dialog = CreateFrame("Frame", config.id, parent, "BackdropTemplate")
  dialog.width = config.width or 520
  dialog.height = config.height or 420

  if dialog.SetSize then
    dialog:SetSize(dialog.width, dialog.height)
  end

  if dialog.SetPoint then
    dialog:SetPoint("CENTER", parent, "CENTER", config.x or 0, config.y or 0)
  end

  if dialog.SetFrameStrata then
    dialog:SetFrameStrata("DIALOG")
  end

  if dialog.SetBackdrop then
    dialog:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 16,
      insets = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4,
      },
    })
  end

  if dialog.SetBackdropColor then
    dialog:SetBackdropColor(0.04, 0.03, 0.05, 0.98)
  end

  dialog.titleLabel = Components.CreateLabel(dialog, {
    text = config.title or "",
    x = 16,
    y = -16,
    font = "GameFontNormalLarge",
  })
  dialog.closeButton = Components.CreateButton(dialog, {
    text = config.closeText or "Close",
    width = 84,
    x = dialog.width - 100,
    y = -12,
    onClick = function()
      Components.SetVisible(dialog, false)
    end,
  })

  Components.SetVisible(dialog, false)

  return dialog
end

function Components.ClearRows(section)
  section.rows = section.rows or {}

  for _, row in ipairs(section.rows) do
    if row.Hide then
      row:Hide()
    end
  end

  section.rows = {}
end

function Components.RenderScrollableSection(section)
  if not section then
    return
  end

  Components.ClearRows(section)

  local items = section.items or {}
  local firstIndex = (section.scrollOffset or 0) + 1
  local lastIndex = math.min(#items, firstIndex + (section.visibleRowCount or 0) - 1)

  for itemIndex = firstIndex, lastIndex do
    if type(section.renderItem) == "function" then
      section.renderItem(section, items[itemIndex], itemIndex)
    end
  end
end

function Components.SetScrollableItems(section, items, renderItem)
  section.items = items or {}
  section.renderItem = renderItem

  local maxOffset = math.max(0, #section.items - (section.visibleRowCount or 0))
  section.scrollBar.minValue = 0
  section.scrollBar.maxValue = maxOffset

  if section.scrollBar.SetMinMaxValues then
    section.scrollBar:SetMinMaxValues(0, maxOffset)
  end

  if section.scrollOffset > maxOffset then
    section.scrollOffset = maxOffset
  end

  if section.scrollBar.SetValue then
    section.scrollBar:SetValue(section.scrollOffset)
  end

  Components.RenderScrollableSection(section)
end

function Components.AddListRow(section, config)
  section.rows = section.rows or {}

  local row = CreateFrame("Frame", nil, section)
  local index = #section.rows
  local offsetY = -34 - (index * (config.rowHeight or 44))

  if row.SetSize then
    row:SetSize(config.width or ((section.width or 100) - 20), config.rowHeight or 40)
  end

  if row.SetPoint then
    row:SetPoint("TOPLEFT", section, "TOPLEFT", 10, offsetY)
  end

  local label = Components.CreateLabel(row, {
    text = config.text or "",
    x = 0,
    y = -4,
    width = config.labelWidth or ((section.width or 100) - 180),
    justifyH = "LEFT",
    justifyV = "TOP",
  })
  row.label = label
  row.actions = {}

  local actionX = config.actionX or ((section.width or 100) - 150)
  local actionColumns = config.actionColumns or #((config.actions or {}))
  local actionSpacingX = config.actionSpacingX or 6
  local actionSpacingY = config.actionSpacingY or 4
  local actionBaseY = config.actionBaseY or 0
  for actionIndex, action in ipairs(config.actions or {}) do
    local columnIndex = ((actionIndex - 1) % actionColumns)
    local rowIndex = math.floor((actionIndex - 1) / actionColumns)
    local buttonWidth = action.width or 64
    local button = Components.CreateButton(row, {
      text = action.text,
      width = buttonWidth,
      height = 22,
      x = actionX + (columnIndex * (buttonWidth + actionSpacingX)),
      y = actionBaseY - (rowIndex * (22 + actionSpacingY)),
      onClick = action.onClick,
    })

    if action.disabled and button.Disable then
      button:Disable()
    end

    row.actions[#row.actions + 1] = button
  end

  section.rows[#section.rows + 1] = row

  return row
end

function Components.AddPermissionMatrixRow(section, config)
  section.rows = section.rows or {}

  local row = CreateFrame("Frame", nil, section)
  local index = #section.rows
  local offsetY = -54 - (index * (config.rowHeight or 32))

  if row.SetSize then
    row:SetSize(config.width or ((section.width or 100) - 20), config.rowHeight or 40)
  end

  if row.SetPoint then
    row:SetPoint("TOPLEFT", section, "TOPLEFT", 10, offsetY)
  end

  row.rankLabel = Components.CreateLabel(row, {
    text = config.rankName or "",
    x = 0,
    y = -8,
    width = config.rankLabelWidth or 180,
    justifyH = "LEFT",
  })
  row.manageNominationsCheck = Components.CreateCheckButton(row, {
    text = config.nominationText or "",
    x = config.nominationX or 228,
    y = -6,
  })
  row.createAwardsCheck = Components.CreateCheckButton(row, {
    text = config.awardText or "",
    x = config.awardX or 336,
    y = -6,
  })
  row.deleteAwardsCheck = Components.CreateCheckButton(row, {
    text = config.deleteText or "",
    x = config.deleteX or 444,
    y = -6,
  })
  row.manageAddonCheck = Components.CreateCheckButton(row, {
    text = config.addonText or "",
    x = config.addonX or 552,
    y = -6,
  })

  row.manageNominationsCheck:SetChecked(config.canManageNominations == true)
  row.createAwardsCheck:SetChecked(config.canCreateDirectAwards == true)
  row.deleteAwardsCheck:SetChecked(config.canDeleteAwards == true)
  row.manageAddonCheck:SetChecked(config.canManageAddonPermissions == true)

  row.saveButton = Components.CreateButton(row, {
    text = config.saveText or "Save",
    width = 56,
    x = config.saveX or 670,
    y = -4,
    onClick = config.onSave,
  })

  section.rows[#section.rows + 1] = row

  return row
end

function Components.SetText(widget, text)
  if widget and type(widget.SetText) == "function" then
    widget:SetText(text)
  end

  if widget then
    widget.text = text
  end
end

function Components.SetButtonHandler(button, handler)
  if not button then
    return
  end

  button.onClick = handler

  if type(button.SetScript) == "function" then
    button:SetScript("OnClick", handler)
  end
end

function Components.RenderContent(panel, content)
  if not panel then
    return
  end

  local title = (content and content.title) or ""
  local lines = (content and content.lines) or {}
  local body = table.concat(lines, "\n")

  Components.SetText(panel.titleText, title)
  Components.SetText(panel.bodyText, body)
  panel.content = {
    title = title,
    lines = lines,
    body = body,
  }
end

function Components.SetVisible(frame, visible)
  if frame.Show and frame.Hide then
    if visible then
      frame:Show()
    else
      frame:Hide()
    end
  end

  frame.visible = visible == true
end

return RPA.UIComponents

local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Components = RPA.UIComponents or {}
local Styles = RPA.UIStyles or {}
RPA.UIComponents = Components

local function unpackColor(color, fallback)
  local source = color or fallback or { 1, 1, 1, 1 }
  return source[1] or 1, source[2] or 1, source[3] or 1, source[4] or 1
end

local function applyBackdrop(frame, backdrop, color, borderColor)
  if frame.SetBackdrop then
    frame:SetBackdrop(backdrop)
  else
    frame.backdrop = backdrop
  end

  if frame.SetBackdropColor then
    frame:SetBackdropColor(unpackColor(color))
  else
    frame.backdropColor = color
  end

  if frame.SetBackdropBorderColor then
    frame:SetBackdropBorderColor(unpackColor(borderColor))
  else
    frame.backdropBorderColor = borderColor
  end
end

local function createFontString(parent, font, x, y, width, justifyH, justifyV, text)
  local label = parent.CreateFontString and parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight") or {
    text = "",
  }

  if label.SetPoint then
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, y or 0)
  end

  if width and label.SetWidth then
    label:SetWidth(width)
  end

  if justifyH and label.SetJustifyH then
    label:SetJustifyH(justifyH)
  end

  if justifyV and label.SetJustifyV then
    label:SetJustifyV(justifyV)
  end

  if label.SetText then
    label:SetText(text or "")
  else
    label.text = text or ""
  end

  return label
end

local function createArtworkFrame(parent, config)
  local artwork = CreateFrame("Frame", config.id, parent, "BackdropTemplate")
  artwork.width = config.width or 32
  artwork.height = config.height or 32

  if artwork.SetSize then
    artwork:SetSize(artwork.width, artwork.height)
  end

  if artwork.SetPoint then
    artwork:SetPoint(config.anchor or "TOPLEFT", parent, config.relativeTo or "TOPLEFT", config.x or 0, config.y or 0)
  end

  if artwork.CreateTexture then
    artwork.texture = artwork:CreateTexture(nil, "ARTWORK")
    if artwork.texture.SetAllPoints then
      artwork.texture:SetAllPoints(artwork)
    end
    if artwork.texture.SetTexture then
      artwork.texture:SetTexture(config.texture or config.bgFile)
    end
    if artwork.texture.SetVertexColor then
      artwork.texture:SetVertexColor(1, 1, 1, config.alpha or 1)
    end
  else
    applyBackdrop(artwork, {
      bgFile = config.texture or config.bgFile,
      edgeFile = nil,
      tile = false,
      tileSize = 0,
      edgeSize = 0,
      insets = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
      },
    }, { 1, 1, 1, config.alpha or 1 }, { 1, 1, 1, 0 })
  end

  artwork.texturePath = config.texture or config.bgFile

  return artwork
end

function Components.CreateWindow(config)
  if type(CreateFrame) == "function" then
    local frame = CreateFrame("Frame", config.id, UIParent, "BackdropTemplate")
    local colors = Styles.Colors or {}
    local layout = Styles.Layout or {}

    if frame.SetSize then
      frame:SetSize(config.width, config.height)
    end

    if frame.SetPoint then
      frame:SetPoint("CENTER")
    end

    if frame.Hide then
      frame:Hide()
    end

    applyBackdrop(frame, {
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 16,
      insets = {
        left = 5,
        right = 5,
        top = 5,
        bottom = 5,
      },
    }, colors.shell, colors.brassMuted)

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

    frame.shadowFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    if frame.shadowFrame.SetPoint then
      frame.shadowFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -10, 10)
      frame.shadowFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 10, -10)
    end
    applyBackdrop(frame.shadowFrame, {
      bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 8,
      edgeSize = 12,
      insets = {
        left = 2,
        right = 2,
        top = 2,
        bottom = 2,
      },
    }, colors.shellShadow, colors.brassMuted)

    frame.headerBand = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.headerBand.width = config.width - 28
    frame.headerBand.height = layout.headerHeight or 86
    if frame.headerBand.SetSize then
      frame.headerBand:SetSize(frame.headerBand.width, frame.headerBand.height)
    end
    if frame.headerBand.SetPoint then
      frame.headerBand:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -14)
    end
    applyBackdrop(frame.headerBand, {
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 10,
      insets = {
        left = 3,
        right = 3,
        top = 3,
        bottom = 3,
      },
    }, colors.parchment, colors.brass)

    frame.headerAccent = CreateFrame("Frame", nil, frame.headerBand, "BackdropTemplate")
    if frame.headerAccent.SetSize then
      frame.headerAccent:SetSize(frame.headerBand.width - 8, 2)
    end
    if frame.headerAccent.SetPoint then
      frame.headerAccent:SetPoint("BOTTOMLEFT", frame.headerBand, "BOTTOMLEFT", 4, 4)
    end
    applyBackdrop(frame.headerAccent, {
      bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile = nil,
      tile = true,
      tileSize = 4,
      edgeSize = 0,
      insets = { left = 0, right = 0, top = 0, bottom = 0 },
    }, colors.accentSoft, colors.accentSoft)

    frame.titleIcon = createArtworkFrame(frame.headerBand, {
      texture = ((Styles.Media or {}).headerIcon) or "Interface\\AddOns\\RollingPinAwards\\Media\\flameember.png",
      width = 44,
      height = 44,
      x = 18,
      y = -16,
    })

    local titleText = createFontString(
      frame.headerBand,
      "GameFontNormalLarge",
      74,
      -18,
      frame.headerBand.width - 120,
      "LEFT",
      "TOP",
      config.title or ""
    )
    local subtitleText = createFontString(
      frame.headerBand,
      "GameFontHighlightSmall",
      74,
      -50,
      frame.headerBand.width - 120,
      "LEFT",
      "TOP",
      config.subtitle or Styles.Window.subtitle or ""
    )

    frame.titleText = titleText
    frame.subtitleText = subtitleText

    frame.tabRail = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.tabRail.width = config.width - 76
    frame.tabRail.height = layout.tabRailHeight or 52
    if frame.tabRail.SetSize then
      frame.tabRail:SetSize(frame.tabRail.width, frame.tabRail.height)
    end
    if frame.tabRail.SetPoint then
      frame.tabRail:SetPoint("TOPLEFT", frame, "TOPLEFT", 38, -112)
    end
    applyBackdrop(frame.tabRail, {
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 8,
      insets = {
        left = 2,
        right = 2,
        top = 2,
        bottom = 2,
      },
    }, colors.parchmentSoft, colors.brassMuted)

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
    subtitle = config.subtitle,
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
    local colors = Styles.Colors or {}
    local layout = Styles.Layout or {}
    local host = parent.tabRail or parent
    local button = CreateFrame("Button", nil, host, "BackdropTemplate")

    button.id = spec.id
    button.width = layout.tabWidth or 114
    button.height = (layout.tabRailHeight or 52) - 12

    if button.SetSize then
      button:SetSize(button.width, button.height)
    end

    if button.SetPoint then
      button:SetPoint(
        "TOPLEFT",
        host,
        "TOPLEFT",
        10 + ((index - 1) * ((layout.tabWidth or 114) + (layout.tabGap or 10))),
        -6
      )
    end

    applyBackdrop(button, {
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 8,
      insets = {
        left = 2,
        right = 2,
        top = 2,
        bottom = 2,
      },
    }, colors.parchmentMuted, colors.brassMuted)

    button.label = createFontString(
      button,
      "GameFontNormal",
      14,
      -12,
      button.width - 28,
      "CENTER",
      "TOP",
      spec.label
    )

    return button
  end

  return {
    id = spec.id,
    label = spec.label,
  }
end

function Components.CreateContentPanel(parent, config)
  local colors = Styles.Colors or {}
  local panel = CreateFrame("Frame", config.id, parent, "BackdropTemplate")

  if panel.SetPoint then
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, -170)
  end

  if panel.SetSize then
    panel:SetSize(config.width or 100, config.height or 100)
  end

  if panel.SetClipsChildren then
    panel:SetClipsChildren(true)
  end

  applyBackdrop(panel, {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 10,
    insets = {
      left = 3,
      right = 3,
      top = 3,
      bottom = 3,
    },
  }, colors.parchment, colors.brass)

  panel.width = config.width or 100
  panel.height = config.height or 100

  panel.innerShade = CreateFrame("Frame", nil, panel, "BackdropTemplate")
  if panel.innerShade.SetPoint then
    panel.innerShade:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
    panel.innerShade:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 8)
  end
  if panel.innerShade.SetFrameLevel and panel.GetFrameLevel then
    panel.innerShade:SetFrameLevel(panel:GetFrameLevel())
  end
  if panel.innerShade.SetFrameStrata then
    panel.innerShade:SetFrameStrata("BACKGROUND")
  end
  applyBackdrop(panel.innerShade, {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = nil,
    tile = true,
    tileSize = 8,
    edgeSize = 0,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
  }, { colors.parchment[1], colors.parchment[2], colors.parchment[3], 0.18 }, colors.parchment)

  panel.contentHost = CreateFrame("Frame", nil, panel)
  panel.contentHost.width = panel.width - 16
  panel.contentHost.height = panel.height - 16
  if panel.contentHost.SetPoint then
    panel.contentHost:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
  end
  if panel.contentHost.SetSize then
    panel.contentHost:SetSize(panel.contentHost.width, panel.contentHost.height)
  end
  if panel.contentHost.SetFrameLevel and panel.GetFrameLevel then
    panel.contentHost:SetFrameLevel(panel:GetFrameLevel() + 10)
  end
  if panel.contentHost.SetFrameStrata then
    panel.contentHost:SetFrameStrata("MEDIUM")
  end
  if panel.contentHost.SetClipsChildren then
    panel.contentHost:SetClipsChildren(true)
  end

  local titleText = {
    text = "",
  }
  local bodyText = {
    text = "",
  }

  if type(panel.contentHost.CreateFontString) == "function" then
    titleText = panel.contentHost:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bodyText = panel.contentHost:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

    if titleText.SetPoint then
      titleText:SetPoint("TOPLEFT", panel.contentHost, "TOPLEFT", 16, -16)
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
      bodyText:SetWidth((panel.contentHost.width or config.width or 0) - 32)
    end
  end

  panel.titleText = titleText
  panel.bodyText = bodyText
  Components.SetVisible(panel, true)

  return panel
end

function Components.CreateSection(parent, config)
  local colors = Styles.Colors or {}
  local section = CreateFrame("Frame", config.id, parent, "BackdropTemplate")
  section.width = config.width or 100
  section.height = config.height or 100

  if section.SetSize then
    section:SetSize(section.width, section.height)
  end

  if section.SetPoint then
    section:SetPoint(config.anchor or "TOPLEFT", parent, config.relativeTo or "TOPLEFT", config.x or 0, config.y or 0)
  end

  applyBackdrop(section, {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 8,
    insets = {
      left = 2,
      right = 2,
      top = 2,
      bottom = 2,
    },
  }, colors.parchmentSoft, colors.brass)

  if config.iconPath then
    section.iconFrame = createArtworkFrame(section, {
      texture = config.iconPath,
      width = config.iconWidth or 20,
      height = config.iconHeight or 20,
      x = 12,
      y = -8,
    })
  end

  local title = Components.CreateLabel(section, {
    text = config.title or "",
    x = section.iconFrame and ((config.iconWidth or 20) + 20) or 12,
    y = -10,
    font = "GameFontNormal",
  })

  section.titleText = title
  section.rows = {}

  return section
end

function Components.CreateStatCard(parent, config)
  local colors = Styles.Colors or {}
  local card = CreateFrame("Frame", config.id, parent, "BackdropTemplate")
  card.width = config.width or ((Styles.Dashboard or {}).statCardWidth or 178)
  card.height = config.height or ((Styles.Dashboard or {}).statCardHeight or 96)

  if card.SetSize then
    card:SetSize(card.width, card.height)
  end

  if card.SetPoint then
    card:SetPoint(config.anchor or "TOPLEFT", parent, config.relativeTo or "TOPLEFT", config.x or 0, config.y or 0)
  end

  applyBackdrop(card, {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 8,
    insets = {
      left = 2,
      right = 2,
      top = 2,
      bottom = 2,
    },
  }, colors.parchment, colors.brass)

  if config.iconPath then
    card.iconFrame = createArtworkFrame(card, {
      texture = config.iconPath,
      width = config.iconWidth or 28,
      height = config.iconHeight or 28,
      x = 14,
      y = -14,
    })
  end

  local labelX = card.iconFrame and 48 or 14
  local labelWidth = card.width - labelX - 14
  card.label = createFontString(card, "GameFontHighlight", labelX, -16, labelWidth, "LEFT", "TOP", config.label or "")
  card.value = createFontString(card, "GameFontNormalLarge", 14, -54, card.width - 28, "LEFT", "TOP", config.value or "")
  card.detail = createFontString(card, "GameFontHighlightSmall", 14, -78, card.width - 28, "LEFT", "TOP", config.detail or "")

  return card
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
  return createFontString(
    parent,
    config.font or "GameFontHighlight",
    config.x or 0,
    config.y or 0,
    config.width,
    config.justifyH,
    config.justifyV,
    config.text or ""
  )
end

function Components.CreateButton(parent, config)
  local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
  button.variant = config.variant or "primary"

  if button.SetSize then
    button:SetSize(config.width or 120, config.height or 24)
  end

  if button.SetPoint then
    button:SetPoint(config.anchor or "TOPLEFT", parent, config.relativeTo or "TOPLEFT", config.x or 0, config.y or 0)
  end

  if config.iconPath then
    button.iconFrame = createArtworkFrame(button, {
      texture = config.iconPath,
      width = config.iconWidth or 22,
      height = config.iconHeight or 22,
      x = 16,
      y = -10,
    })
  end

  local labelX = button.iconFrame and 46 or 8
  local labelWidth = (config.width or 120) - labelX - 10
  button.label = createFontString(button, "GameFontNormal", labelX, -6, labelWidth, button.iconFrame and "LEFT" or "CENTER", "TOP", config.text or "")
  Components.SetButtonVariant(button, button.variant)

  if config.onClick then
    Components.SetButtonHandler(button, config.onClick)
  end

  return button
end

function Components.SetButtonVariant(button, variant)
  if not button then
    return
  end

  local colors = Styles.Colors or {}
  button.variant = variant or button.variant or "primary"

  local buttonFill = button.variant == "secondary" and colors.parchmentMuted or colors.accent
  local border = button.variant == "secondary" and colors.brass or colors.accentSoft
  applyBackdrop(button, {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 8,
    insets = {
      left = 2,
      right = 2,
      top = 2,
      bottom = 2,
    },
  }, buttonFill, border)
end

function Components.CreateEditBox(parent, config)
  local colors = Styles.Colors or {}
  local editBox = CreateFrame("EditBox", nil, parent, config.template or "BackdropTemplate")

  if editBox.SetSize then
    editBox:SetSize(config.width or 180, config.height or 28)
  end

  if editBox.SetPoint then
    editBox:SetPoint(config.anchor or "TOPLEFT", parent, config.relativeTo or "TOPLEFT", config.x or 0, config.y or 0)
  end

  if editBox.SetAutoFocus then
    editBox:SetAutoFocus(false)
  end

  if editBox.SetTextInsets then
    editBox:SetTextInsets(8, 8, 6, 6)
  end

  if editBox.SetJustifyH then
    editBox:SetJustifyH("LEFT")
  end

  if editBox.SetJustifyV then
    editBox:SetJustifyV("MIDDLE")
  end

  if editBox.SetFontObject and _G.GameFontHighlight then
    editBox:SetFontObject(_G.GameFontHighlight)
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

  applyBackdrop(editBox, {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 8,
    insets = {
      left = 2,
      right = 2,
      top = 2,
      bottom = 2,
    },
  }, colors.parchment, colors.brassMuted)

  return editBox
end

function Components.CreateCheckButton(parent, config)
  local colors = Styles.Colors or {}
  local button = CreateFrame("CheckButton", nil, parent, config.template or "UICheckButtonTemplate")

  if button.SetPoint then
    button:SetPoint(config.anchor or "TOPLEFT", parent, config.relativeTo or "TOPLEFT", config.x or 0, config.y or 0)
  end

  button.chrome = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  if button.chrome.SetPoint then
    button.chrome:SetPoint(config.anchor or "TOPLEFT", parent, config.relativeTo or "TOPLEFT", config.x or 0, (config.y or 0) - 2)
  end
  if button.chrome.SetSize then
    button.chrome:SetSize(20, 20)
  end
  applyBackdrop(button.chrome, {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 8,
    insets = {
      left = 2,
      right = 2,
      top = 2,
      bottom = 2,
    },
  }, colors.parchment, colors.brassMuted)

  if config.text and config.text ~= "" then
    local text = Components.CreateLabel(parent, {
      text = config.text or "",
      x = (config.x or 0) + 30,
      y = config.y or 0,
      font = "GameFontHighlight",
    })
    button.label = text
  end

  return button
end

function Components.CreateConfirmationDialog(parent, config)
  local dialog = CreateFrame("Frame", config.id, parent, "BackdropTemplate")
  local colors = Styles.Colors or {}
  dialog.width = config.width or 420
  dialog.height = config.height or 160

  if dialog.SetSize then
    dialog:SetSize(dialog.width, dialog.height)
  end

  if dialog.SetPoint then
    dialog:SetPoint("CENTER", parent, "CENTER", config.x or 0, config.y or 0)
  end

  applyBackdrop(dialog, {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 14,
    insets = {
      left = 4,
      right = 4,
      top = 4,
      bottom = 4,
    },
  }, colors.darkPanel, colors.brass)

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
    variant = "primary",
  })
  dialog.cancelButton = Components.CreateButton(dialog, {
    text = config.cancelText or "Cancel",
    width = 100,
    x = 126,
    y = -118,
    variant = "secondary",
    onClick = function()
      Components.SetVisible(dialog, false)
    end,
  })

  Components.SetVisible(dialog, false)

  return dialog
end

function Components.CreateModalWindow(parent, config)
  local dialog = CreateFrame("Frame", config.id, parent, "BackdropTemplate")
  local colors = Styles.Colors or {}
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

  applyBackdrop(dialog, {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 14,
    insets = {
      left = 4,
      right = 4,
      top = 4,
      bottom = 4,
    },
  }, colors.darkPanel, colors.brass)

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
    variant = "secondary",
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
  local colors = Styles.Colors or {}

  local row = CreateFrame("Frame", nil, section)
  local index = #section.rows
  local offsetY = -34 - (index * (config.rowHeight or 44))

  if row.SetSize then
    row:SetSize(config.width or ((section.width or 100) - 20), config.rowHeight or 40)
  end

  if row.SetPoint then
    row:SetPoint("TOPLEFT", section, "TOPLEFT", 10, offsetY)
  end

  applyBackdrop(row, {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 8,
    insets = {
      left = 2,
      right = 2,
      top = 2,
      bottom = 2,
    },
  }, colors.parchment, config.highlight and colors.accentSoft or colors.brassMuted)

  if config.iconPath then
    row.iconFrame = createArtworkFrame(row, {
      texture = config.iconPath,
      width = config.iconWidth or 20,
      height = config.iconHeight or 20,
      x = 10,
      y = -8,
    })
  end

  local label = Components.CreateLabel(row, {
    text = config.text or "",
    x = row.iconFrame and ((config.iconWidth or 20) + 18) or 0,
    y = -4,
    width = config.labelWidth or ((section.width or 100) - (row.iconFrame and 198 or 180)),
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
      variant = action.variant or (action.destructive and "secondary" or "primary"),
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
  local colors = Styles.Colors or {}

  local row = CreateFrame("Frame", nil, section)
  local index = #section.rows
  local offsetY = -54 - (index * (config.rowHeight or 32))

  if row.SetSize then
    row:SetSize(config.width or ((section.width or 100) - 20), config.rowHeight or 40)
  end

  if row.SetPoint then
    row:SetPoint("TOPLEFT", section, "TOPLEFT", 10, offsetY)
  end

  applyBackdrop(row, {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 8,
    insets = {
      left = 2,
      right = 2,
      top = 2,
      bottom = 2,
    },
  }, colors.parchment, colors.brassMuted)

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
    variant = "secondary",
    onClick = config.onSave,
  })

  section.rows[#section.rows + 1] = row

  return row
end

function Components.SetText(widget, text)
  if widget and widget.label and type(widget.label.SetText) == "function" then
    widget.label:SetText(text)
  end

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

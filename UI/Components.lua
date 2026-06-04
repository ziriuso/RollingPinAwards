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

local function applyTextTreatment(label, options)
  if not label then
    return
  end
  options = options or {}

  if label.SetShadowColor then
    label:SetShadowColor(0, 0, 0, 0)
  else
    label.shadowColor = {
      red = 0,
      green = 0,
      blue = 0,
      alpha = 0,
    }
  end

  if label.SetShadowOffset then
    label:SetShadowOffset(0, 0)
  else
    label.shadowOffset = {
      x = 0,
      y = 0,
    }
  end

  if label.GetFont and label.SetFont then
    local fontFile, fontHeight = label:GetFont()
    if fontFile and fontHeight then
      local fontFlags = "OUTLINE"
      if options.outline == false then
        fontFlags = nil
      end
      label:SetFont(fontFile, fontHeight + (options.fontSizeDelta or 0), fontFlags)
    end
  else
    label.fontHeight = (label.fontHeight or 12) + (options.fontSizeDelta or 0)
    if options.outline == false then
      label.fontFlags = nil
    else
      label.fontFlags = "OUTLINE"
    end
  end
end

local function createFontString(parent, font, x, y, width, justifyH, justifyV, text, options)
  local fontTemplate = font or "GameFontHighlight"
  local label = parent.CreateFontString and parent:CreateFontString(nil, "OVERLAY", fontTemplate) or {
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

  applyTextTreatment(label, options)

  return label
end

local function getNavButtonTexturePath(tabId, selected)
  if type(tabId) ~= "string" or tabId == "" then
    return nil
  end

  return ("Interface\\AddOns\\RollingPinAwards\\Media\\NavBar\\%s%s.png"):format(
    tabId,
    selected and "-selected" or ""
  )
end

local function createArtworkFrame(parent, config)
  local artwork = CreateFrame("Frame", config.id, parent, "BackdropTemplate")
  artwork.width = config.width or 32
  artwork.height = config.height or 32

  if artwork.SetSize then
    artwork:SetSize(artwork.width, artwork.height)
  end

  if artwork.SetFrameStrata and parent and parent.GetFrameStrata then
    artwork:SetFrameStrata(parent:GetFrameStrata())
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

function Components.CreateArtworkFrame(parent, config)
  return createArtworkFrame(parent, config or {})
end

function Components.CreateWindow(config)
  if type(CreateFrame) == "function" then
    local frame = CreateFrame("Frame", config.id, UIParent, "BackdropTemplate")
    local colors = Styles.Colors or {}
    local layout = Styles.Layout or {}

    if frame.SetSize then
      frame:SetSize(config.width, config.height)
    end

    if frame.SetFrameStrata then
      frame:SetFrameStrata("TOOLTIP")
    end

    if frame.SetFrameLevel then
      frame:SetFrameLevel(100)
    end

    if frame.SetToplevel then
      frame:SetToplevel(true)
    end

    if frame.EnableKeyboard then
      frame:EnableKeyboard(true)
    end

    if frame.SetPropagateKeyboardInput then
      frame:SetPropagateKeyboardInput(true)
    end

    if frame.SetHitRectInsets then
      frame:SetHitRectInsets(-52, -112, -92, -44)
    end

    if frame.SetPoint then
      frame:SetPoint("CENTER")
    end

    if frame.Hide then
      frame:Hide()
    end

    frame.backgroundArt = createArtworkFrame(frame, {
      texture = ((Styles.Media or {}).addonBackground) or "Interface\\AddOns\\RollingPinAwards\\Media\\addon-background.png",
      width = 1048,
      height = 872,
      anchor = "TOPLEFT",
      relativeTo = "TOPLEFT",
      x = -52,
      y = 92,
    })

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
      frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
          if self.SetPropagateKeyboardInput then
            self:SetPropagateKeyboardInput(false)
          end
          Components.SetVisible(self, false)
        elseif self.SetPropagateKeyboardInput then
          self:SetPropagateKeyboardInput(true)
        end
      end)
    end

    if type(UISpecialFrames) == "table" and config.id then
      local registered = false
      for _, frameName in ipairs(UISpecialFrames) do
        if frameName == config.id then
          registered = true
          break
        end
      end
      if not registered then
        UISpecialFrames[#UISpecialFrames + 1] = config.id
      end
    end

    frame.visible = false
    frame.title = config.title

    local titleText = createFontString(
      frame,
      "GameFontNormalLarge",
      74,
      -18,
      config.width - 120,
      "LEFT",
      "TOP",
      ""
    )
    local subtitleText = createFontString(
      frame,
      "GameFontHighlightSmall",
      74,
      -50,
      config.width - 120,
      "LEFT",
      "TOP",
      ""
    )

    frame.titleText = titleText
    frame.subtitleText = subtitleText

    frame.tabRail = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    local tabCount = #(Styles.TabOrder or {})
    local tabWidth = layout.tabWidth or 114
    local tabGap = layout.tabGap or 10
    local tabGroupWidth = (tabCount * tabWidth) + (math.max(0, tabCount - 1) * tabGap)
    local tabRailPadding = layout.tabRailPadding or 42
    frame.tabRail.width = math.min(config.width - 76, tabGroupWidth + tabRailPadding)
    frame.tabRail.height = layout.tabRailHeight or 52
    if frame.tabRail.SetSize then
      frame.tabRail:SetSize(frame.tabRail.width, frame.tabRail.height)
    end
    if frame.tabRail.SetPoint then
      frame.tabRail:SetPoint("TOPLEFT", frame, "TOPLEFT", math.floor(((config.width or 0) - frame.tabRail.width) / 2), -112)
    end
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    if closeButton.SetPoint then
      closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 106, 86)
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

function Components.CreateBackgroundCalibrationWindow(parentFrame, config)
  config = config or {}
  local colors = Styles.Colors or {}
  local media = Styles.Media or {}
  local calibration = CreateFrame("Frame", config.id, UIParent, "BackdropTemplate")
  calibration.width = config.width or 920
  calibration.height = config.height or 736
  calibration.skipRaiseOnShow = true

  if calibration.SetSize then
    calibration:SetSize(calibration.width, calibration.height)
  end
  if calibration.SetPoint then
    calibration:SetPoint("CENTER", parentFrame or UIParent, "CENTER", 0, 0)
  end
  if calibration.SetFrameStrata then
    calibration:SetFrameStrata("BACKGROUND")
  end
  if calibration.SetFrameLevel and parentFrame and parentFrame.GetFrameLevel then
    calibration:SetFrameLevel(math.max(0, (parentFrame:GetFrameLevel() or 1) - 1))
  end
  if calibration.EnableMouse then
    calibration:EnableMouse(true)
  end
  if calibration.SetMovable then
    calibration:SetMovable(true)
  end
  if calibration.SetResizable then
    calibration:SetResizable(true)
  end
  if calibration.SetResizeBounds then
    calibration:SetResizeBounds(420, 320, 1800, 1400)
  end
  if calibration.RegisterForDrag then
    calibration:RegisterForDrag("LeftButton")
  end
  if calibration.SetScript then
    calibration:SetScript("OnDragStart", function(self)
      if self.StartMoving then
        self:StartMoving()
      end
    end)
    calibration:SetScript("OnDragStop", function(self)
      if self.StopMovingOrSizing then
        self:StopMovingOrSizing()
      end
    end)
  end

  calibration.backgroundArt = createArtworkFrame(calibration, {
    texture = media.addonBackground or "Interface\\AddOns\\RollingPinAwards\\Media\\addon-background.png",
    width = calibration.width,
    height = calibration.height,
    anchor = "CENTER",
    relativeTo = "CENTER",
    x = 0,
    y = 0,
  })

  calibration.resizeHandle = CreateFrame("Button", nil, calibration, "BackdropTemplate")
  if calibration.resizeHandle.SetSize then
    calibration.resizeHandle:SetSize(22, 22)
  end
  if calibration.resizeHandle.SetPoint then
    calibration.resizeHandle:SetPoint("BOTTOMRIGHT", calibration, "BOTTOMRIGHT", -4, 4)
  end
  if calibration.resizeHandle.EnableMouse then
    calibration.resizeHandle:EnableMouse(true)
  end
  applyBackdrop(calibration.resizeHandle, {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 8,
    insets = {
      left = 1,
      right = 1,
      top = 1,
      bottom = 1,
    },
  }, colors.darkPanel or { 0, 0, 0, 0.5 }, colors.brass or { 1, 1, 1, 1 })
  if calibration.resizeHandle.SetScript then
    calibration.resizeHandle:SetScript("OnMouseDown", function()
      if calibration.StartSizing then
        calibration:StartSizing("BOTTOMRIGHT")
      end
    end)
    calibration.resizeHandle:SetScript("OnMouseUp", function()
      if calibration.StopMovingOrSizing then
        calibration:StopMovingOrSizing()
      end
    end)
  end

  Components.SetVisible(calibration, false)

  return calibration
end

function Components.CreateTabButton(parent, spec, index)
  if type(CreateFrame) == "function" and parent then
    local colors = Styles.Colors or {}
    local layout = Styles.Layout or {}
    local host = parent.tabRail or parent
    local button = CreateFrame("Button", nil, host, "BackdropTemplate")

    button.id = spec.id
    button.width = layout.tabWidth or 114
    button.height = layout.navButtonHeight or ((layout.tabRailHeight or 52) - 12)

    if button.SetSize then
      button:SetSize(button.width, button.height)
    end

    if button.SetPoint then
      local tabCount = #(Styles.TabOrder or {})
      local tabGroupWidth = (tabCount * button.width) + (math.max(0, tabCount - 1) * (layout.tabGap or 10))
      local startX = math.floor(((host.width or tabGroupWidth) - tabGroupWidth) / 2)
      button:SetPoint(
        "TOPLEFT",
        host,
        "TOPLEFT",
        startX + ((index - 1) * ((layout.tabWidth or 114) + (layout.tabGap or 10))),
        -6
      )
    end

    button.navTexture = button:CreateTexture(nil, "ARTWORK")
    if button.navTexture.SetAllPoints then
      button.navTexture:SetAllPoints(button)
    end
    if button.navTexture.SetTexture then
      button.navTexture:SetTexture(getNavButtonTexturePath(spec.id, false))
    end

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
    if button.label.Hide then
      button.label:Hide()
    else
      button.label.visible = false
    end

    return button
  end

  return {
    id = spec.id,
    label = spec.label,
  }
end

function Components.SetTabButtonSelected(button, selected)
  if not button then
    return
  end

  button.selected = selected == true
  button.navTexturePath = getNavButtonTexturePath(button.id, button.selected)

  if button.navTexture and button.navTexture.SetTexture then
    button.navTexture:SetTexture(button.navTexturePath)
  end
end

function Components.LayoutTabButtons(parent, buttons)
  if not parent or type(buttons) ~= "table" then
    return
  end

  local layout = Styles.Layout or {}
  local host = parent.tabRail or parent
  local visibleButtons = {}

  for _, button in ipairs(buttons) do
    if button and button.visible ~= false then
      visibleButtons[#visibleButtons + 1] = button
    end
  end

  if #visibleButtons == 0 then
    return
  end

  local tabGap = layout.tabGap or 10
  local totalTabCount = #(Styles.TabOrder or {})
  local hasAdminVisible = #visibleButtons >= totalTabCount
  local navMargin = hasAdminVisible
    and (layout.navMarginWithAdmin or 188)
    or (layout.navMarginWithoutAdmin or 257)
  local background = parent.backgroundArt
  local backgroundLeft = background and background.point and background.point[4] or 0
  local backgroundWidth = background and background.width or (parent.width or host.width or 0)
  if background and host.SetSize then
    host.width = backgroundWidth
    host:SetSize(host.width, host.height or (layout.tabRailHeight or 52))
  end
  if background and host.SetPoint then
    if host.ClearAllPoints then
      host:ClearAllPoints()
    end
    host:SetPoint("TOPLEFT", parent, "TOPLEFT", backgroundLeft, host.point and host.point[5] or -112)
  end
  local groupWidth = math.max(0, (backgroundWidth or 0) - (2 * navMargin))
  local tabWidth = (groupWidth - (math.max(0, #visibleButtons - 1) * tabGap)) / #visibleButtons
  local startX = navMargin
  if hasAdminVisible then
    startX = ((backgroundWidth - groupWidth) / 2) + (layout.navCenterOffsetWithAdmin or 0)
  end

  for visibleIndex, button in ipairs(visibleButtons) do
    button.width = tabWidth
    button.height = layout.navButtonHeight or button.height
    if button.SetSize then
      button:SetSize(button.width, button.height)
    end
    if button.ClearAllPoints then
      button:ClearAllPoints()
    end
    if button.SetPoint then
      button:SetPoint(
        "TOPLEFT",
        host,
        "TOPLEFT",
        startX + ((visibleIndex - 1) * (tabWidth + tabGap)),
        -6
      )
    end
  end
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

  panel.width = config.width or 100
  panel.height = config.height or 100

  panel.contentHost = CreateFrame("Frame", nil, parent)
  panel.contentHost.width = panel.width - 16
  panel.contentHost.height = panel.height - 16
  if panel.contentHost.SetPoint then
    panel.contentHost:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
  end
  if panel.contentHost.SetSize then
    panel.contentHost:SetSize(panel.contentHost.width, panel.contentHost.height)
  end
  if panel.contentHost.SetFrameLevel and panel.GetFrameLevel then
    panel.contentHost:SetFrameLevel(panel:GetFrameLevel() + 20)
  end
  if panel.contentHost.SetFrameStrata and panel.GetFrameStrata then
    panel.contentHost:SetFrameStrata(panel:GetFrameStrata())
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
    applyTextTreatment(titleText, {
      fontSizeDelta = (Styles.Layout or {}).pageHeaderFontSizeDelta or 5,
    })
    applyTextTreatment(bodyText)

    if titleText.SetPoint then
      titleText:SetPoint("TOPLEFT", panel.contentHost, "TOPLEFT", (Styles.Layout or {}).panelX or 59, -16)
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
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
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
  }, colors.bannerPanel or colors.parchmentSoft, colors.brass)

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
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
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
  }, colors.bannerPanel or colors.parchment, colors.brass)

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
  card.label = createFontString(card, "GameFontNormal", labelX, -16, labelWidth, "CENTER", "TOP", config.label or "")
  card.value = createFontString(card, "GameFontNormalLarge", 14, -54, card.width - 28, "CENTER", "TOP", config.value or "")
  card.detail = createFontString(card, "GameFontHighlightSmall", 14, -78, card.width - 28, "CENTER", "TOP", config.detail or "")
  if card.value.SetPoint then
    if card.value.ClearAllPoints then
      card.value:ClearAllPoints()
    end
    card.value:SetPoint("CENTER", card, "CENTER", 0, -2)
  end
  if card.value.SetJustifyV then
    card.value:SetJustifyV("MIDDLE")
  end

  return card
end

function Components.CreateScrollableSection(parent, config)
  local section = Components.CreateSection(parent, config)
  section.visibleRowCount = config.visibleRowCount or 5
  section.rowHeight = config.rowHeight or 44
  section.scrollOffset = 0
  section.items = {}
  section.rowInsetLeft = config.rowInsetLeft or 14
  section.rowScrollbarGutter = config.rowScrollbarGutter or 48
  section.rowStartY = config.rowStartY or -34

  local scrollBar = CreateFrame("Slider", nil, section, "OptionsSliderTemplate")
  if scrollBar.SetPoint then
    scrollBar:SetPoint("TOPRIGHT", section, "TOPRIGHT", -10, -(config.scrollBarTop or 28))
  end
  if scrollBar.SetSize then
    scrollBar:SetSize(16, section.height - ((config.scrollBarTop or 28) + (config.scrollBarBottom or 16)))
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
    config.text or "",
    {
      outline = config.outline,
      fontSizeDelta = config.fontSizeDelta,
    }
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
  button.label = createFontString(button, "GameFontNormal", labelX, -6, labelWidth, button.iconFrame and "LEFT" or "CENTER", "MIDDLE", config.text or "")
  if button.label.SetPoint then
    if button.label.ClearAllPoints then
      button.label:ClearAllPoints()
    end
    button.label:SetPoint("LEFT", button, "LEFT", labelX, 0)
  end
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
  button.selected = button.variant == "selected"

  local buttonFill = colors.accent
  local border = colors.accentSoft
  if button.variant == "secondary" then
    buttonFill = colors.parchmentMuted
    border = colors.brass
  elseif button.variant == "selected" then
    buttonFill = colors.selected or colors.glow or colors.accent
    border = colors.selectedBorder or colors.accentSoft
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
  }, buttonFill, border)

  if button.label and button.label.SetTextColor then
    if button.variant == "selected" then
      button.label:SetTextColor(unpackColor(colors.ink or { 0.1, 0.07, 0.04, 1 }))
    else
      button.label:SetTextColor(unpackColor(colors.selectedBorder or { 1, 0.92, 0.48, 1 }))
    end
  end
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
  local button = CreateFrame("Button", nil, parent, config.template or "BackdropTemplate")
  button.checked = false

  if button.SetSize then
    button:SetSize(20, 20)
  end

  if button.SetPoint then
    button:SetPoint(config.anchor or "TOPLEFT", parent, config.relativeTo or "TOPLEFT", config.x or 0, config.y or 0)
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
  }, colors.parchment, colors.brassMuted)
  button.chrome = button

  button.checkLabel = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  applyTextTreatment(button.checkLabel)
  if button.checkLabel.SetPoint then
    button.checkLabel:SetPoint("CENTER", button, "CENTER", 0, 0)
  end
  if button.checkLabel.SetText then
    button.checkLabel:SetText("X")
  end

  function button:SetChecked(value)
    self.checked = value == true
    Components.SetVisible(self.checkLabel, self.checked)
  end

  function button:GetChecked()
    return self.checked == true
  end

  if button.SetScript then
    button:SetScript("OnClick", function(self)
      if self.disabled then
        return
      end

      self:SetChecked(not self:GetChecked())
    end)
  end

  button:SetChecked(false)

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
  if dialog.SetFrameStrata then
    local parentStrata = parent.GetFrameStrata and parent:GetFrameStrata() or nil
    dialog:SetFrameStrata(config.frameStrata or parentStrata or "DIALOG")
  end
  if dialog.SetFrameLevel and parent.GetFrameLevel then
    dialog:SetFrameLevel((parent:GetFrameLevel() or 0) + (config.frameLevelOffset or 120))
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
    local parentStrata = parent.GetFrameStrata and parent:GetFrameStrata() or nil
    dialog:SetFrameStrata(config.frameStrata or parentStrata or "DIALOG")
  end
  if dialog.SetFrameLevel and parent.GetFrameLevel then
    dialog:SetFrameLevel((parent:GetFrameLevel() or 0) + (config.frameLevelOffset or 100))
  end

  if config.draggable then
    if dialog.EnableMouse then
      dialog:EnableMouse(true)
    end
    if dialog.SetMovable then
      dialog:SetMovable(true)
    end
    if dialog.RegisterForDrag then
      dialog:RegisterForDrag("LeftButton")
    end
    if dialog.SetScript then
      dialog:SetScript("OnDragStart", function(self)
        if self.StartMoving then
          self:StartMoving()
        end
      end)
      dialog:SetScript("OnDragStop", function(self)
        if self.StopMovingOrSizing then
          self:StopMovingOrSizing()
        end
      end)
    end
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
  }, config.backdropColor or colors.darkPanel, config.borderColor or colors.brass)

  if config.backgroundTexture then
    dialog.backgroundArt = createArtworkFrame(dialog, {
      texture = config.backgroundTexture,
      width = dialog.width,
      height = dialog.height,
      anchor = "CENTER",
      relativeTo = "CENTER",
      x = 0,
      y = 0,
    })
    if dialog.backgroundArt.SetFrameLevel and dialog.GetFrameLevel then
      dialog.backgroundArt:SetFrameLevel(dialog:GetFrameLevel() + 1)
    end
  end

  if config.contentBounds then
    dialog.contentHost = CreateFrame("Frame", nil, dialog)
    dialog.contentHost.width = config.contentBounds.width or (dialog.width - 32)
    dialog.contentHost.height = config.contentBounds.height or (dialog.height - 32)
    if dialog.contentHost.SetSize then
      dialog.contentHost:SetSize(dialog.contentHost.width, dialog.contentHost.height)
    end
    if dialog.contentHost.SetPoint then
      dialog.contentHost:SetPoint(
        "TOPLEFT",
        dialog,
        "TOPLEFT",
        config.contentBounds.left or 16,
        -(config.contentBounds.top or 16)
      )
    end
    if dialog.contentHost.SetFrameLevel and dialog.GetFrameLevel then
      dialog.contentHost:SetFrameLevel(dialog:GetFrameLevel() + 2)
    end
  end

  local chromeParent = dialog.contentHost or dialog
  local chromeWidth = chromeParent.width or dialog.width

  dialog.titleLabel = Components.CreateLabel(chromeParent, {
    text = config.title or "",
    x = config.centerTitle and 24 or 16,
    y = config.titleY or -16,
    width = config.centerTitle and (chromeWidth - 48) or nil,
    justifyH = config.centerTitle and "CENTER" or "LEFT",
    font = config.titleFont or "GameFontNormalLarge",
  })
  dialog.closeButton = Components.CreateButton(chromeParent, {
    text = config.closeText or "Close",
    width = 84,
    x = config.closeX or (chromeWidth - 100),
    y = config.closeY or -12,
    variant = "secondary",
    onClick = function()
      Components.SetVisible(dialog, false)
    end,
  })
  if config.closeAnchor == "BOTTOMRIGHT" and dialog.closeButton.SetPoint then
    if dialog.closeButton.ClearAllPoints then
      dialog.closeButton:ClearAllPoints()
    end
    dialog.closeButton:SetPoint("BOTTOMRIGHT", chromeParent, "BOTTOMRIGHT", -16, config.closeBottomY or 16)
  end

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

  local row = CreateFrame("Frame", nil, section, "BackdropTemplate")
  row.backdropTone = config.backdropTone
  local index = #section.rows
  local offsetY = (section.rowStartY or -34) - (index * (config.rowHeight or 44))
  local useRowHighlight = config.backdropTone == "rowHighlight"
  local rowLeft = config.x or section.rowInsetLeft or 14
  local defaultGutter = section.scrollBar and (section.rowScrollbarGutter or 48) or 24
  local rowWidth = config.width or ((section.width or 100) - rowLeft - (config.rowRightGutter or defaultGutter))

  if row.SetSize then
    row:SetSize(rowWidth, config.rowHeight or 40)
  end

  if row.SetPoint then
    row:SetPoint("TOPLEFT", section, "TOPLEFT", rowLeft, offsetY)
  end

  applyBackdrop(row, {
    bgFile = useRowHighlight and "Interface\\ChatFrame\\ChatFrameBackground" or "Interface\\DialogFrame\\UI-DialogBox-Background",
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
  }, useRowHighlight and (colors.parchmentMuted or colors.parchment) or colors.parchment, config.highlight and colors.accentSoft or colors.brassMuted)

  if config.iconPath then
    row.iconFrame = createArtworkFrame(row, {
      texture = config.iconPath,
      width = config.iconWidth or 20,
      height = config.iconHeight or 20,
      x = 10,
      y = -8,
    })
    if row.iconFrame.SetPoint then
      if row.iconFrame.ClearAllPoints then
        row.iconFrame:ClearAllPoints()
      end
      row.iconFrame:SetPoint("LEFT", row, "LEFT", 10, 0)
    end
  end

  local labelX = row.iconFrame and ((config.iconWidth or 20) + 22) or (config.textPaddingLeft or 12)
  local labelOutline = config.outline
  if labelOutline == nil then
    labelOutline = not useRowHighlight
  end
  local label = Components.CreateLabel(row, {
    text = config.text or "",
    x = labelX,
    y = 0,
    width = config.labelWidth or ((rowWidth or section.width or 100) - labelX - (config.labelRightPadding or 18)),
    justifyH = "LEFT",
    justifyV = config.justifyV or "MIDDLE",
    outline = labelOutline,
  })
  if label.SetPoint then
    if label.ClearAllPoints then
      label:ClearAllPoints()
    end
    label:SetPoint("LEFT", row, "LEFT", labelX, 0)
  end
  if useRowHighlight and label.SetTextColor then
    local textColor = config.textColor or colors.ink or { 0, 0, 0, 1 }
    label:SetTextColor(unpackColor(textColor))
  end
  row.label = label
  row.actions = {}

  local actionX = config.actionX or math.max(0, (rowWidth or section.width or 100) - 150)
  local actionColumns = config.actionColumns or #((config.actions or {}))
  local actionSpacingX = config.actionSpacingX or 6
  local actionSpacingY = config.actionSpacingY or 4
  local actionCount = #((config.actions or {}))
  local actionRows = actionColumns > 0 and math.ceil(actionCount / actionColumns) or 0
  local buttonHeight = config.actionButtonHeight or 22
  local actionGroupHeight = actionRows > 0 and ((actionRows * buttonHeight) + ((actionRows - 1) * actionSpacingY)) or 0
  local centeredActionTopY = actionGroupHeight > 0 and ((actionGroupHeight - buttonHeight) / 2) or 0
  local actionBaseY = config.actionBaseY
  if actionBaseY == nil then
    actionBaseY = centeredActionTopY
  end
  for actionIndex, action in ipairs(config.actions or {}) do
    local columnIndex = ((actionIndex - 1) % actionColumns)
    local rowIndex = math.floor((actionIndex - 1) / actionColumns)
    local buttonWidth = action.width or 64
    local button = Components.CreateButton(row, {
      text = action.text,
      width = buttonWidth,
      height = buttonHeight,
      x = actionX + (columnIndex * (buttonWidth + actionSpacingX)),
      y = actionBaseY - (rowIndex * (22 + actionSpacingY)),
      variant = action.variant or (action.destructive and "secondary" or "primary"),
      onClick = action.onClick,
    })
    if button.SetPoint then
      if button.ClearAllPoints then
        button:ClearAllPoints()
      end
      button:SetPoint(
        "LEFT",
        row,
        "LEFT",
        actionX + (columnIndex * (buttonWidth + actionSpacingX)),
        actionBaseY - (rowIndex * (buttonHeight + actionSpacingY))
      )
    end

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
    fontSizeDelta = config.rankFontSizeDelta,
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
  if visible and frame.SetPropagateKeyboardInput then
    frame:SetPropagateKeyboardInput(true)
  end

  if frame.Show and frame.Hide then
    if visible then
      frame:Show()
      if frame.Raise and not frame.skipRaiseOnShow then
        frame:Raise()
      end
    else
      frame:Hide()
    end
  end

  frame.visible = visible == true
end

return RPA.UIComponents

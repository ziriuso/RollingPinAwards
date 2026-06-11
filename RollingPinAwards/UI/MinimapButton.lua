local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local MinimapButton = RPA.MinimapButton or {}
RPA.MinimapButton = MinimapButton

local DEFAULT_MINIMAP_ANGLE = 225
local MINIMAP_RING_RADIUS = 85
local MINIMAP_RING_OFFSET = 5
local MINIMAP_BUTTON_SIZE = 32
local MINIMAP_BORDER_SIZE = 54
local MINIMAP_ICON_SIZE = 24
local MINIMAP_TRACKING_BORDER = "Interface\\Minimap\\MiniMap-TrackingBorder"
local MINIMAP_HIGHLIGHT = 136477

local function atan2(y, x)
  if math.atan2 then
    return math.atan2(y, x)
  end

  return math.atan(y, x)
end

function MinimapButton:New(addon)
  local obj = {
    addon = addon,
  }

  self.__index = self
  setmetatable(obj, self)

  obj.button = obj:CreateButton()

  return obj
end

function MinimapButton:GetStoredAngle()
  if self.addon and self.addon.db and type(self.addon.db.GetMinimapAngle) == "function" then
    return self.addon.db:GetMinimapAngle()
  end

  return self:NormalizeAngle(DEFAULT_MINIMAP_ANGLE)
end

function MinimapButton:NormalizeAngle(angle)
  local normalized = tonumber(angle) or DEFAULT_MINIMAP_ANGLE
  normalized = normalized % 360
  if normalized < 0 then
    normalized = normalized + 360
  end

  return normalized
end

function MinimapButton:SaveAngle(angle)
  local normalized = self:NormalizeAngle(angle)
  if self.addon and self.addon.db and type(self.addon.db.SetMinimapAngle) == "function" then
    return self.addon.db:SetMinimapAngle(normalized)
  end

  return normalized
end

function MinimapButton:GetRingRadius()
  local minimap = _G.Minimap
  if minimap and type(minimap.GetWidth) == "function" then
    local width = tonumber(minimap:GetWidth())
    if width and width > 0 then
      return (width / 2) + MINIMAP_RING_OFFSET
    end
  end

  return MINIMAP_RING_RADIUS
end

function MinimapButton:UpdatePosition(angle)
  local button = self.button
  local minimap = _G.Minimap or _G.UIParent
  if not button or not button.SetPoint then
    return false
  end

  local nextAngle = self:NormalizeAngle(angle or self:GetStoredAngle())
  local radians = math.rad(nextAngle)
  local ringRadius = self:GetRingRadius()
  local x = math.cos(radians) * ringRadius
  local y = math.sin(radians) * ringRadius

  if button.ClearAllPoints then
    button:ClearAllPoints()
  end
  button:SetPoint("CENTER", minimap, "CENTER", x, y)
  button.minimapAngle = nextAngle
  button.ringRadius = ringRadius

  return true
end

function MinimapButton:UpdatePositionFromCursor()
  local minimap = _G.Minimap or _G.UIParent
  if not minimap or type(minimap.GetCenter) ~= "function" or type(_G.GetCursorPosition) ~= "function" then
    return false
  end

  local minimapX, minimapY = minimap:GetCenter()
  local cursorX, cursorY = _G.GetCursorPosition()
  local scale = minimap.GetEffectiveScale and minimap:GetEffectiveScale() or 1
  scale = tonumber(scale) or 1
  cursorX = (cursorX or 0) / scale
  cursorY = (cursorY or 0) / scale

  local angle = math.deg(atan2(cursorY - minimapY, cursorX - minimapX))
  angle = self:SaveAngle(angle)

  return self:UpdatePosition(angle)
end

function MinimapButton:SetShown(shown)
  if self.addon and self.addon.db and type(self.addon.db.SetMinimapButtonShown) == "function" then
    self.addon.db:SetMinimapButtonShown(shown)
  end

  self:RefreshVisibility()

  return shown == true
end

function MinimapButton:RefreshVisibility()
  local shown = true
  if self.addon and self.addon.db and type(self.addon.db.IsMinimapButtonShown) == "function" then
    shown = self.addon.db:IsMinimapButtonShown()
  end

  if not self.button then
    return shown
  end

  if shown then
    if self.button.Show then
      self.button:Show()
    end
    self:UpdatePosition()
  else
    if self.button.Hide then
      self.button:Hide()
    end
  end

  return shown
end

function MinimapButton:ShowTooltip(anchor)
  if not _G.GameTooltip then
    return false
  end

  if _G.GameTooltip.SetOwner then
    _G.GameTooltip:SetOwner(anchor or self.button, "ANCHOR_LEFT")
  end
  if _G.GameTooltip.SetText then
    _G.GameTooltip:SetText("Rolling Pin Awards")
  end
  if _G.GameTooltip.AddLine then
    _G.GameTooltip:AddLine("Left-click to open.")
    _G.GameTooltip:AddLine("Drag to reposition.")
  end
  if _G.GameTooltip.Show then
    _G.GameTooltip:Show()
  end

  return true
end

function MinimapButton:HideTooltip()
  if _G.GameTooltip and _G.GameTooltip.Hide then
    _G.GameTooltip:Hide()
    return true
  end

  return false
end

function MinimapButton:CreateButton()
  if type(CreateFrame) ~= "function" then
    return nil
  end

  local media = (RPA.UIStyles or {}).Media or {}
  local minimap = _G.Minimap or _G.UIParent
  local button = CreateFrame("Button", "RollingPinAwardsMinimapButton", minimap)
  self.button = button

  if button.SetSize then
    button:SetSize(MINIMAP_BUTTON_SIZE, MINIMAP_BUTTON_SIZE)
  end

  if button.SetHighlightTexture then
    button:SetHighlightTexture(MINIMAP_HIGHLIGHT)
  end

  if button.SetFrameStrata then
    button:SetFrameStrata("MEDIUM")
  end

  if button.SetFrameLevel then
    local baseLevel = minimap and minimap.GetFrameLevel and minimap:GetFrameLevel() or minimap and minimap.frameLevel or 0
    button:SetFrameLevel((baseLevel or 0) + 8)
  end

  if button.EnableMouse then
    button:EnableMouse(true)
  end

  if button.SetMovable then
    button:SetMovable(true)
  end

  if button.RegisterForDrag then
    button:RegisterForDrag("LeftButton")
  end

  if button.CreateTexture then
    button.borderTexture = button:CreateTexture(nil, "OVERLAY")
    if button.borderTexture.SetTexture then
      button.borderTexture:SetTexture(MINIMAP_TRACKING_BORDER)
    end
    if button.borderTexture.SetSize then
      button.borderTexture:SetSize(MINIMAP_BORDER_SIZE, MINIMAP_BORDER_SIZE)
    end
    if button.borderTexture.SetPoint then
      button.borderTexture:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    end

    button.iconTexture = button:CreateTexture(nil, "ARTWORK")
    if button.iconTexture.SetSize then
      button.iconTexture:SetSize(MINIMAP_ICON_SIZE, MINIMAP_ICON_SIZE)
    end
    if button.iconTexture.SetPoint then
      button.iconTexture:SetPoint("CENTER", button, "CENTER", 0, 1)
    end
    if button.iconTexture.SetTexture then
      button.iconTexture:SetTexture(media.minimapIcon or "Interface\\AddOns\\RollingPinAwards\\Media\\minimap-button.png")
    end
  end

  if button.SetScript then
    button:SetScript("OnDragStart", function(dragButton)
      dragButton:SetScript("OnUpdate", function()
        self:UpdatePositionFromCursor()
      end)
    end)
    button:SetScript("OnDragStop", function(dragButton)
      dragButton:SetScript("OnUpdate", nil)
    end)
    button:SetScript("OnClick", function()
      if self.addon and self.addon.mainFrame and type(self.addon.mainFrame.Toggle) == "function" then
        return self.addon.mainFrame:Toggle()
      end

      return false
    end)
    button:SetScript("OnEnter", function()
      self:ShowTooltip(button)
    end)
    button:SetScript("OnLeave", function()
      self:HideTooltip()
    end)
  end

  self:RefreshVisibility()

  return button
end

return RPA.MinimapButton

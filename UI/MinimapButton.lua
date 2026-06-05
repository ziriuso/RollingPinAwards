local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local MinimapButton = RPA.MinimapButton or {}
RPA.MinimapButton = MinimapButton

local DEFAULT_MINIMAP_ANGLE = 225
local MINIMAP_RING_RADIUS = 82

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
  local settings = self.addon
    and self.addon.db
    and type(self.addon.db.GetLocalSettings) == "function"
    and self.addon.db:GetLocalSettings()
    or nil

  return tonumber(settings and settings.minimapAngle) or DEFAULT_MINIMAP_ANGLE
end

function MinimapButton:SaveAngle(angle)
  local normalized = tonumber(angle) or DEFAULT_MINIMAP_ANGLE
  local settings = self.addon
    and self.addon.db
    and type(self.addon.db.GetLocalSettings) == "function"
    and self.addon.db:GetLocalSettings()
    or nil

  if settings then
    settings.minimapAngle = normalized
  end

  return normalized
end

function MinimapButton:UpdatePosition(angle)
  local button = self.button
  local minimap = _G.Minimap or _G.UIParent
  if not button or not button.SetPoint then
    return false
  end

  local nextAngle = tonumber(angle) or self:GetStoredAngle()
  local radians = math.rad(nextAngle)
  local x = math.cos(radians) * MINIMAP_RING_RADIUS
  local y = math.sin(radians) * MINIMAP_RING_RADIUS

  if button.ClearAllPoints then
    button:ClearAllPoints()
  end
  button:SetPoint("CENTER", minimap, "CENTER", x, y)
  button.minimapAngle = nextAngle
  button.ringRadius = MINIMAP_RING_RADIUS

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
  self:SaveAngle(angle)

  return self:UpdatePosition(angle)
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
    button:SetSize(36, 36)
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
    button.iconTexture = button:CreateTexture(nil, "ARTWORK")
    if button.iconTexture.SetAllPoints then
      button.iconTexture:SetAllPoints(button)
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
  end

  self:UpdatePosition()

  return button
end

return RPA.MinimapButton

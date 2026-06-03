local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local MinimapButton = RPA.MinimapButton or {}
RPA.MinimapButton = MinimapButton

function MinimapButton:New(addon)
  local obj = {
    addon = addon,
  }

  self.__index = self
  setmetatable(obj, self)

  obj.button = obj:CreateButton()

  return obj
end

function MinimapButton:CreateButton()
  if type(CreateFrame) ~= "function" then
    return nil
  end

  local media = (RPA.UIStyles or {}).Media or {}
  local button = CreateFrame("Button", "RollingPinAwardsMinimapButton", _G.Minimap or _G.UIParent)

  if button.SetSize then
    button:SetSize(36, 36)
  end

  if button.SetPoint then
    button:SetPoint("TOPLEFT", _G.Minimap or _G.UIParent, "TOPLEFT", 0, 0)
  end

  if button.EnableMouse then
    button:EnableMouse(true)
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
    button:SetScript("OnClick", function()
      if self.addon and self.addon.mainFrame and type(self.addon.mainFrame.Toggle) == "function" then
        return self.addon.mainFrame:Toggle()
      end

      return false
    end)
  end

  return button
end

return RPA.MinimapButton

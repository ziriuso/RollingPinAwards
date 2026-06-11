local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local function getAddon()
  return _G.RollingPinAwards
end

function _G.RollingPinAwards_OnAddonCompartmentClick()
  local addon = getAddon()
  if not addon then
    return false
  end

  if addon.mainFrame and type(addon.mainFrame.Toggle) == "function" then
    return addon.mainFrame:Toggle()
  end

  return false
end

function _G.RollingPinAwards_OnAddonCompartmentEnter(_, _, frame)
  if not _G.GameTooltip then
    return false
  end

  if _G.GameTooltip.SetOwner then
    _G.GameTooltip:SetOwner(frame or _G.UIParent, "ANCHOR_LEFT")
  end
  if _G.GameTooltip.SetText then
    _G.GameTooltip:SetText("Rolling Pin Awards")
  end
  if _G.GameTooltip.AddLine then
    _G.GameTooltip:AddLine("Click to open.")
  end
  if _G.GameTooltip.Show then
    _G.GameTooltip:Show()
  end

  return true
end

function _G.RollingPinAwards_OnAddonCompartmentLeave()
  if _G.GameTooltip and _G.GameTooltip.Hide then
    _G.GameTooltip:Hide()
    return true
  end

  return false
end

return RPA

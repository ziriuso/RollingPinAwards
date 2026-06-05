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
local Utils = RPA.Utils or {}

local Toast = RPA.Toast or {}
RPA.Toast = Toast

local function applyToastBackdrop(frame)
  if frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 12,
      insets = {
        left = 3,
        right = 3,
        top = 3,
        bottom = 3,
      },
    })
  end

  if frame.SetBackdropColor then
    frame:SetBackdropColor(0.10, 0.07, 0.05, 0.92)
  end
end

local function readFramePoint(frame)
  local point, relativeTo, relativePoint, x, y
  if frame and type(frame.GetPoint) == "function" then
    point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
  end

  if not point and frame and type(frame.point) == "table" then
    point = frame.point[1]
    relativeTo = frame.point[2]
    relativePoint = frame.point[3]
    x = frame.point[4]
    y = frame.point[5]
  end

  return point, relativeTo, relativePoint, x, y
end

function Toast:New(addon)
  local obj = {
    addon = addon,
    anchorMode = false,
    queuedAwards = {},
  }

  self.__index = self

  return setmetatable(obj, self)
end

function Toast:IsInCombat()
  return type(_G.InCombatLockdown) == "function" and _G.InCombatLockdown() == true
end

function Toast:GetSettings()
  if self.addon and self.addon.db and type(self.addon.db.GetLocalSettings) == "function" then
    return self.addon.db:GetLocalSettings()
  end

  return {
    toastsEnabled = true,
    toastAnchor = {
      point = "CENTER",
      relativePoint = "CENTER",
      x = 0,
      y = 180,
    },
  }
end

function Toast:GetAwardPresentation(award)
  local Constants = self.addon and self.addon.Constants or RPA.Constants or {}
  local normalized = Utils.NormalizeAwardType and Utils.NormalizeAwardType((award or {}).awardType) or "burnt"
  local isGolden = normalized == Constants.AWARD_TYPE_GOLDEN

  if isGolden then
    return {
      label = "Golden",
      icon = (Styles.Media or {}).leaderboardIcon,
    }
  end

  return {
    label = "Burnt",
    icon = (Styles.Media or {}).awardIcon,
  }
end

function Toast:ApplySavedPoint(frame)
  if not frame or not frame.SetPoint then
    return
  end

  local anchor = self:GetSettings().toastAnchor or {}
  if frame.ClearAllPoints then
    frame:ClearAllPoints()
  end
  frame:SetPoint(
    anchor.point or "CENTER",
    UIParent,
    anchor.relativePoint or anchor.point or "CENTER",
    anchor.x or 0,
    anchor.y or 180
  )
end

function Toast:EnsureToastFrame()
  if self.frame then
    return self.frame
  end

  local toastStyle = Styles.Toast or {}
  local frame = CreateFrame("Frame", "RollingPinAwardsToastFrame", UIParent, "BackdropTemplate")
  frame.width = toastStyle.width or 360
  frame.height = toastStyle.height or 220

  if frame.SetSize then
    frame:SetSize(frame.width, frame.height)
  end
  if frame.SetFrameStrata then
    frame:SetFrameStrata("TOOLTIP")
  end
  if frame.SetFrameLevel then
    frame:SetFrameLevel(240)
  end
  applyToastBackdrop(frame)
  self:ApplySavedPoint(frame)

  local iconSize = toastStyle.iconSize or 96
  frame.icon = Components.CreateArtworkFrame(frame, {
    id = "RollingPinAwardsToastIcon",
    texture = (Styles.Media or {}).awardIcon,
    width = iconSize,
    height = iconSize,
    anchor = "TOP",
    relativeTo = "TOP",
    x = 0,
    y = -18,
  })

  frame.titleLabel = Components.CreateLabel(frame, {
    text = "",
    x = 24,
    y = -124,
    width = frame.width - 48,
    justifyH = "CENTER",
    justifyV = "TOP",
    font = "GameFontNormalLarge",
    fontSizeDelta = 2,
  })

  frame.reasonLabel = Components.CreateLabel(frame, {
    text = "",
    x = 30,
    y = -158,
    width = frame.width - 60,
    justifyH = "CENTER",
    justifyV = "TOP",
    font = "GameFontHighlight",
    outline = true,
  })

  frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  if frame.closeButton.SetPoint then
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
  end
  if frame.closeButton.SetScript then
    frame.closeButton:SetScript("OnClick", function()
      Components.SetVisible(frame, false)
    end)
  end

  Components.SetVisible(frame, false)
  self.frame = frame

  return frame
end

function Toast:ShowAwardToast(award)
  local settings = self:GetSettings()
  if settings.toastsEnabled == false then
    if self.frame then
      Components.SetVisible(self.frame, false)
    end
    self.queuedAwards = {}
    return false
  end

  if self:IsInCombat() then
    self.queuedAwards = self.queuedAwards or {}
    self.queuedAwards[#self.queuedAwards + 1] = award
    return true
  end

  return self:DisplayAwardToast(award)
end

function Toast:DisplayAwardToast(award)
  local settings = self:GetSettings()
  if settings.toastsEnabled == false then
    return false
  end

  local frame = self:EnsureToastFrame()
  local presentation = self:GetAwardPresentation(award)
  local reason = type((award or {}).reason) == "string" and award.reason or ""

  if frame.icon then
    frame.icon.texturePath = presentation.icon
    if frame.icon.texture and frame.icon.texture.SetTexture then
      frame.icon.texture:SetTexture(presentation.icon)
    end
  end
  Components.SetText(frame.titleLabel, ("You've Received a %s Rolling Pin"):format(presentation.label))
  Components.SetText(frame.reasonLabel, reason)
  self:ApplySavedPoint(frame)
  Components.SetVisible(frame, true)

  if _G.C_Timer and type(_G.C_Timer.After) == "function" then
    _G.C_Timer.After(Styles.Toast.durationSeconds or 7, function()
      if frame == self.frame then
        Components.SetVisible(frame, false)
      end
    end)
  end

  return true
end

function Toast:FlushQueuedToasts()
  if self:IsInCombat() then
    return false
  end

  local settings = self:GetSettings()
  if settings.toastsEnabled == false then
    self.queuedAwards = {}
    return false
  end

  self.queuedAwards = self.queuedAwards or {}
  if #self.queuedAwards == 0 then
    return false
  end

  local award = table.remove(self.queuedAwards, 1)

  return self:DisplayAwardToast(award)
end

function Toast:SaveAnchorFromFrame()
  local anchorFrame = self.anchorFrame
  if not anchorFrame or not self.addon or not self.addon.db then
    return nil
  end

  local point, _, relativePoint, x, y = readFramePoint(anchorFrame)

  return self.addon.db:SaveToastAnchor(point, relativePoint, x, y)
end

function Toast:LockAnchor()
  self:SaveAnchorFromFrame()
  self.anchorMode = false

  if self.anchorFrame then
    Components.SetVisible(self.anchorFrame, false)
  end
  if self.frame then
    self:ApplySavedPoint(self.frame)
  end

  return true
end

function Toast:EnsureAnchorFrame()
  if self.anchorFrame then
    return self.anchorFrame
  end

  local frame = CreateFrame("Button", "RollingPinAwardsToastAnchor", UIParent, "BackdropTemplate")
  frame.width = 300
  frame.height = 88

  if frame.SetSize then
    frame:SetSize(frame.width, frame.height)
  end
  if frame.SetFrameStrata then
    frame:SetFrameStrata("TOOLTIP")
  end
  if frame.SetFrameLevel then
    frame:SetFrameLevel(260)
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
  if frame.RegisterForClicks then
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  end
  applyToastBackdrop(frame)
  self:ApplySavedPoint(frame)

  frame.label = Components.CreateLabel(frame, {
    text = "Toast Anchor\nRight-click to lock",
    x = 16,
    y = -18,
    width = frame.width - 32,
    justifyH = "CENTER",
    justifyV = "MIDDLE",
    font = "GameFontNormalLarge",
  })

  if frame.SetScript then
    frame:SetScript("OnDragStart", function(selfFrame)
      if selfFrame.StartMoving then
        selfFrame:StartMoving()
      end
    end)
    frame:SetScript("OnDragStop", function(selfFrame)
      if selfFrame.StopMovingOrSizing then
        selfFrame:StopMovingOrSizing()
      end
    end)
    frame:SetScript("OnClick", function(_, buttonName)
      if buttonName == "RightButton" then
        self:LockAnchor()
      end
    end)
  end

  Components.SetVisible(frame, false)
  self.anchorFrame = frame

  return frame
end

function Toast:SetAnchorMode(enabled)
  local frame = self:EnsureAnchorFrame()
  self.anchorMode = enabled == true
  self:ApplySavedPoint(frame)
  Components.SetVisible(frame, self.anchorMode)

  return self.anchorMode
end

function Toast:ToggleAnchorMode()
  return self:SetAnchorMode(not self.anchorMode)
end

return RPA.Toast

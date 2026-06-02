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

    frame.visible = false
    frame.title = config.title

    return frame
  end

  return {
    id = config.id,
    title = config.title,
    width = config.width,
    height = config.height,
    visible = false,
  }
end

function Components.MakeTab(spec)
  return {
    id = spec.id,
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

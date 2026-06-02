local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Components = RPA.UIComponents or {}
RPA.UIComponents = Components

function Components.CreateWindow(config)
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

return RPA.UIComponents

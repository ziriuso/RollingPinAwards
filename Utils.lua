local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Utils = RPA.Utils or {}
RPA.Utils = Utils

function Utils.CopyTable(input)
  local output = {}

  for key, value in pairs(input) do
    if type(value) == "table" then
      output[key] = Utils.CopyTable(value)
    else
      output[key] = value
    end
  end

  return output
end

function Utils.ApplyDefaults(target, defaults)
  if type(target) ~= "table" then
    target = {}
  end

  for key, value in pairs(defaults) do
    if type(value) == "table" then
      target[key] = Utils.ApplyDefaults(target[key], value)
    elseif target[key] == nil then
      target[key] = value
    end
  end

  return target
end

return RPA.Utils

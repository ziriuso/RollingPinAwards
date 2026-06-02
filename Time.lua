local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Time = RPA.Time or {}
RPA.Time = Time

function Time:Now()
  if type(GetServerTime) == "function" then
    return GetServerTime()
  end

  if type(time) == "function" then
    return time()
  end

  if _G.os and type(_G.os.time) == "function" then
    return _G.os.time()
  end

  return 0
end

return RPA.Time

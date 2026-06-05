local harness = require("tests.TestHarness")

local function file_size(path)
  local file = assert(io.open(path, "rb"))
  local size = file:seek("end")
  file:close()
  return size
end

return {
  ["media trophy images use the provided burnt and golden art payloads"] = function()
    harness.assert_equal(1607058, file_size("Media/burnt-rolling-pin.png"))
    harness.assert_equal(1688613, file_size("Media/golden-rolling-pin.png"))
  end,

  ["media includes the leaderboard clean card and Amarante font payloads"] = function()
    harness.assert_equal(3179732, file_size("Media/cleancard.png"))
    harness.assert_equal(144788, file_size("Media/Fonts/Amarante-Regular.ttf"))
  end,
}

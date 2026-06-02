local files = {}
local filter = os.getenv("RPA_TEST_FILTER")
local specList = os.getenv("RPA_TEST_SPECS") or ""

for file in specList:gmatch("[^;]+") do
  files[#files + 1] = file
end

if #files == 0 then
  io.stderr:write("No spec files were provided to the test runner.\n")
  os.exit(1)
end

local passed, failed = 0, 0
local executed = 0

for _, file in ipairs(files) do
  local spec = dofile(file)
  for name, test_fn in pairs(spec) do
    if not filter or name:find(filter, 1, true) then
      executed = executed + 1
      local ok, err = pcall(test_fn)
      if ok then
        passed = passed + 1
        print("PASS " .. name)
      else
        failed = failed + 1
        print("FAIL " .. name .. ": " .. err)
      end
    end
  end
end

if executed == 0 then
  io.stderr:write("No tests were executed.\n")
  os.exit(1)
end

if failed > 0 then
  os.exit(1)
end

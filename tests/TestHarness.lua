local harness = {}

function harness.assert_equal(expected, actual)
  if expected ~= actual then
    error(("expected %s, got %s"):format(tostring(expected), tostring(actual)), 2)
  end
end

function harness.assert_true(value)
  if not value then
    error("expected condition to be true", 2)
  end
end

function harness.assert_false(value)
  if value then
    error("expected condition to be false", 2)
  end
end

function harness.assert_nil(value)
  if value ~= nil then
    error(("expected nil, got %s"):format(tostring(value)), 2)
  end
end

return harness

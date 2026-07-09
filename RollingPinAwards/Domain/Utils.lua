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

function Utils.NormalizeAliasKey(value)
  if type(value) ~= "string" then
    return nil
  end

  local normalized = string.lower(value)
  normalized = string.gsub(normalized, "^%s+", "")
  normalized = string.gsub(normalized, "%s+$", "")

  if normalized == "" then
    return nil
  end

  return normalized
end

function Utils.NormalizeRealm(realm)
  local source = realm

  if (type(source) ~= "string" or source == "") and type(GetNormalizedRealmName) == "function" then
    source = GetNormalizedRealmName()
  end

  if (type(source) ~= "string" or source == "") and type(GetRealmName) == "function" then
    source = GetRealmName()
  end

  if type(source) ~= "string" or source == "" then
    return nil
  end

  -- Blizzard's GetNormalizedRealmName strips only spaces, hyphens, and periods.
  -- Apostrophes and parentheses are kept ("Mal'Ganis" -> "Mal'Ganis",
  -- "Aggra (Português)" -> "Aggra(Português)"), and the realm portion of a
  -- whisper/addon-message target must match that form or delivery fails with
  -- "no player named ...". Do NOT strip all punctuation (%p) here.
  local normalized = source:gsub("[%s%-%.]", "")
  if normalized == "" then
    return nil
  end

  return normalized
end

function Utils.NormalizeUnitName(name, realm)
  if type(name) ~= "string" or name == "" then
    return nil
  end

  local character, suppliedRealm = name:match("^([^-]+)%-(.+)$")
  if not character then
    character = name
    suppliedRealm = realm
  end

  local normalizedRealm = Utils.NormalizeRealm(suppliedRealm)
  if not normalizedRealm then
    return character
  end

  return ("%s-%s"):format(character, normalizedRealm)
end

function Utils.NormalizeAwardType(value)
  local Constants = RPA.Constants or {}

  if value == Constants.AWARD_TYPE_GOLDEN then
    return Constants.AWARD_TYPE_GOLDEN
  end

  return Constants.AWARD_TYPE_BURNT or "burnt"
end

function Utils.GetAwardDisplayName(awardType)
  local Constants = RPA.Constants or {}
  local normalized = Utils.NormalizeAwardType(awardType)

  if normalized == Constants.AWARD_TYPE_GOLDEN then
    return Constants.GOLDEN_AWARD_NAME or "The Golden Rolling Pin"
  end

  return Constants.DISPLAY_AWARD_NAME or "The Burnt Rolling Pin"
end

function Utils.GetShortCharacterName(value)
  if type(value) ~= "string" or value == "" then
    return value
  end

  local shortName = value:match("^[^-]+")
  return shortName or value
end

return RPA.Utils

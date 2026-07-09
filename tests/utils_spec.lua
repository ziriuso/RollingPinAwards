local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

local function loadUtils()
  _G.RollingPinAwards = nil
  local addon = wow.loadAddon()
  return addon.Utils, addon
end

return {
  ["NormalizeRealm keeps apostrophes and parentheses, strips only space/hyphen/period"] = function()
    wow.reset({ realmName = "Stormrage", playerName = "Ziri" })
    local Utils = loadUtils()

    harness.assert_equal("Mal'Ganis", Utils.NormalizeRealm("Mal'Ganis"))
    harness.assert_equal("Ahn'Qiraj", Utils.NormalizeRealm("Ahn'Qiraj"))
    harness.assert_equal("Twilight'sHammer", Utils.NormalizeRealm("Twilight's Hammer"))
    harness.assert_equal("DefiasBrotherhood", Utils.NormalizeRealm("Defias Brotherhood"))
    harness.assert_equal("Aggra(Português)", Utils.NormalizeRealm("Aggra (Português)"))
  end,

  ["NormalizeUnitName preserves the apostrophe in a cross-realm target"] = function()
    wow.reset({ realmName = "Stormrage", playerName = "Ziri" })
    local Utils = loadUtils()

    -- A roster/sender name that already carries a realm must survive intact so
    -- the whisper target routes: "Player-Mal'Ganis", not "Player-MalGanis".
    harness.assert_equal("Player-Mal'Ganis", Utils.NormalizeUnitName("Player-Mal'Ganis"))
    harness.assert_equal("Player-Twilight'sHammer", Utils.NormalizeUnitName("Player-Twilight's Hammer"))
  end,

  ["NormalizeUnitName appends the supplied apostrophe realm to a bare name"] = function()
    wow.reset({ realmName = "Stormrage", playerName = "Ziri" })
    local Utils = loadUtils()

    harness.assert_equal("Player-Mal'Ganis", Utils.NormalizeUnitName("Player", "Mal'Ganis"))
  end,

  ["GetCurrentPlayerFullName matches the Blizzard-normalized realm on an apostrophe realm"] = function()
    wow.reset({ realmName = "Mal'Ganis", playerName = "Ziri" })
    local addon = wow.loadAddon()

    -- Must equal GetNormalizedRealmName's form so it compares equal to the
    -- CHAT_MSG_ADDON sender and guild roster entries.
    harness.assert_equal("Ziri-Mal'Ganis", addon:GetCurrentPlayerFullName())
    harness.assert_equal("Mal'Ganis", GetNormalizedRealmName())
  end,
}

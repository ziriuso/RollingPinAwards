local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

local function resetForever(seed)
  seed = seed or {}
  seed.interfaceVersion = 16001
  seed.guildName = seed.guildName or "Raid Bakery"
  seed.playerName = seed.playerName or "Mira Vale"
  seed.guildRankName = seed.guildRankName or "Guild Master"
  seed.guildRankIndex = seed.guildRankIndex or 0
  seed.guildMembers = seed.guildMembers or {
    { name = "Mira Vale", rankName = "Guild Master", rankIndex = 0, online = true },
    { name = "Ava Stone", rankName = "Member", rankIndex = 5, online = true },
    { name = "Ava Reed", rankName = "Member", rankIndex = 5, online = true },
  }
  wow.reset(seed)
  return wow.loadAddon()
end

return {
  ["Forever retains complete two-part names without realm suffixes"] = function()
    local addon = resetForever()

    harness.assert_true(addon.Utils.IsForeverClient())
    harness.assert_equal("Mira Vale", addon:GetCurrentPlayerFullName())
    harness.assert_equal("Ava Stone", addon.Utils.NormalizeUnitName("Ava Stone"))
    harness.assert_equal("Ava Stone", addon.Utils.NormalizeUnitName("Ava Stone", "Stormrage"))
    harness.assert_equal("Ava Stone", addon.Utils.GetShortCharacterName("Ava Stone"))
    harness.assert_true(addon.Utils.IsCompleteCharacterName("Ava Stone"))
    harness.assert_false(addon.Utils.IsCompleteCharacterName("Ava"))
  end,

  ["Forever roster and whisper checks distinguish shared first names"] = function()
    local addon = resetForever()
    addon:OnInitialize()

    local found, online, rosterName, matchKind = addon:GetGuildRosterMemberStatus("Ava Reed")
    harness.assert_true(found)
    harness.assert_true(online)
    harness.assert_equal("Ava Reed", rosterName)
    harness.assert_equal("exact", matchKind)
    harness.assert_false(addon:IsGuildRosterMember("Ava"))
    harness.assert_false(addon:IsGuildRosterMember("Ava Ghost"))
    harness.assert_false(addon:IsTrustedSyncDistribution("WHISPER", "Ava Ghost"))

    local target = addon.sync:ResolveOnlineGuildTarget("Ava Stone")
    harness.assert_equal("Ava Stone", target)
    local missingTarget, err = addon.sync:ResolveOnlineGuildTarget("Ava Ghost")
    harness.assert_nil(missingTarget)
    harness.assert_equal("sender not in roster", err)
  end,

  ["Forever roster suggestions and leaderboard retain both surnames"] = function()
    local addon = resetForever()
    addon:OnInitialize()

    local suggestions = addon.uiBridge:GetGuildRosterNameSuggestions("Ava", 5)
    harness.assert_equal(2, #suggestions)
    harness.assert_equal("Ava Stone", suggestions[1].shortName)
    harness.assert_equal("Ava Reed", suggestions[2].shortName)

    addon.awards:CreateDirectAward("Ava Stone", "First award")
    addon.awards:CreateDirectAward("Ava Reed", "Second award")
    local rows = addon.uiBridge:GetLeaderboardViewModel()
    harness.assert_equal(2, #rows)
    harness.assert_true(rows[1].recipient ~= rows[2].recipient)
    harness.assert_equal(rows[1].recipient, rows[1].shortRecipient)
    harness.assert_equal(rows[2].recipient, rows[2].shortRecipient)
  end,

  ["Forever mapping requires a complete canonical name"] = function()
    local addon = resetForever()
    addon:OnInitialize()

    local saved, err = addon.uiBridge:SaveAliasMapping("Ava", "Ava")
    harness.assert_false(saved)
    harness.assert_equal("canonical name must include first and last name", err)

    local fullSaved = addon.uiBridge:SaveAliasMapping("Ava", "Ava Stone")
    harness.assert_true(fullSaved)
  end,

  ["Forever slash nominations accept full names and reject first names alone"] = function()
    local addon = resetForever()
    addon:OnInitialize()

    local nomination = addon.commands:Handle('nominate Ava Stone "Pulled the boss"')
    harness.assert_equal("Ava Stone", nomination.nominee)

    local missing, err = addon.commands:Handle('nominate Ava "Pulled the boss"')
    harness.assert_nil(missing)
    harness.assert_equal("full character name required", err)
  end,
}

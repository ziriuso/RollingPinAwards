local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["database binds to the SavedVariables root and preserves default tables safely"] = function()
    local savedVariables = {
      profile = {
        guildDatasets = {
          ["raid bakery"] = {
            guildKey = "raid bakery",
            awards = {},
            awardsById = {},
            nominations = {},
            nominationsById = {},
            permissionRoster = {},
            votesByNomination = {},
          },
        },
      },
    }

    wow.reset({
      guildName = "Raid Bakery",
      savedVariables = savedVariables,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_true(addon.db.storage == savedVariables)
    harness.assert_true(_G.RollingPinAwardsDB == savedVariables)
    harness.assert_true(addon.db.storage.profile.settings ~= nil)
    harness.assert_true(addon.db.storage.profile.guildDatasets ~= addon.defaults.profile.guildDatasets)
  end,

  ["database creates a guild dataset on demand"] = function()
    wow.reset({ guildName = "Raid Bakery" })
    local addon = wow.loadAddon()
    addon:OnInitialize()

    local dataset = addon.db:GetGuildDataset("raid bakery")
    harness.assert_equal("raid bakery", dataset.guildKey)
    harness.assert_equal(0, #dataset.awards)
  end,

  ["database stores nominations by id in the current guild dataset"] = function()
    wow.reset({ guildName = "Raid Bakery" })
    local addon = wow.loadAddon()
    addon:OnInitialize()

    addon.db:UpsertNomination("raid bakery", {
      nominationId = "nom:1",
      status = "pending",
    })

    local found = addon.db:GetNomination("raid bakery", "nom:1")
    harness.assert_equal("nom:1", found.nominationId)
    harness.assert_equal("pending", found.status)
  end,

  ["database rejects missing guild keys and nomination ids predictably"] = function()
    wow.reset({ guildName = "Raid Bakery" })
    local addon = wow.loadAddon()
    addon:OnInitialize()

    local missingDataset, datasetError = addon.db:GetGuildDataset(nil)
    harness.assert_true(missingDataset == nil)
    harness.assert_equal("missing guildKey", datasetError)

    local missingNomination, nominationError = addon.db:UpsertNomination("raid bakery", {
      status = "pending",
    })
    harness.assert_true(missingNomination == nil)
    harness.assert_equal("missing nominationId", nominationError)

    local missingLookup, lookupError = addon.db:GetNomination(nil, "nom:1")
    harness.assert_true(missingLookup == nil)
    harness.assert_equal("missing guildKey", lookupError)
  end,

  ["database rebuilds nomination rows in deterministic id order"] = function()
    wow.reset({ guildName = "Raid Bakery" })
    local addon = wow.loadAddon()
    addon:OnInitialize()

    addon.db:UpsertNomination("raid bakery", {
      nominationId = "nom:2",
      status = "pending",
    })
    addon.db:UpsertNomination("raid bakery", {
      nominationId = "nom:10",
      status = "pending",
    })
    addon.db:UpsertNomination("raid bakery", {
      nominationId = "nom:1",
      status = "pending",
    })

    local dataset = addon.db:GetGuildDataset("raid bakery")
    harness.assert_equal("nom:1", dataset.nominations[1].nominationId)
    harness.assert_equal("nom:10", dataset.nominations[2].nominationId)
    harness.assert_equal("nom:2", dataset.nominations[3].nominationId)
  end,
}

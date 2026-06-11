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
    harness.assert_nil(addon.db.storage.profile.settings)
    harness.assert_true(addon.db.storage.profile.guildDatasets ~= addon.defaults.profile.guildDatasets)
  end,

  ["database validates and clamps local toast duration setting"] = function()
    local savedVariables = {
      profile = {
        guildDatasets = {},
        localSettings = {
          toastDurationSeconds = "forever",
        },
      },
    }

    wow.reset({
      guildName = "Raid Bakery",
      savedVariables = savedVariables,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local settings = addon.db:GetLocalSettings()
    harness.assert_equal(7, settings.toastDurationSeconds)

    harness.assert_equal(3, addon.db:SetToastDurationSeconds(2))
    harness.assert_equal(3, addon.db:GetLocalSettings().toastDurationSeconds)

    harness.assert_equal(15, addon.db:SetToastDurationSeconds(16))
    harness.assert_equal(15, addon.db:GetLocalSettings().toastDurationSeconds)

    harness.assert_equal(9, addon.db:SetToastDurationSeconds(9))
    harness.assert_equal(9, addon.db:GetLocalSettings().toastDurationSeconds)
  end,

  ["database validates and clamps local addon scale setting"] = function()
    local savedVariables = {
      profile = {
        guildDatasets = {},
        localSettings = {
          addonScale = "huge",
        },
      },
    }

    wow.reset({
      guildName = "Raid Bakery",
      savedVariables = savedVariables,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local settings = addon.db:GetLocalSettings()
    harness.assert_equal(0.8, settings.addonScale)

    harness.assert_equal(0.8, addon.db:SetAddonScale(0.4))
    harness.assert_equal(0.8, addon.db:GetLocalSettings().addonScale)

    harness.assert_equal(1.25, addon.db:SetAddonScale(2))
    harness.assert_equal(1.25, addon.db:GetLocalSettings().addonScale)

    harness.assert_equal(1.15, addon.db:SetAddonScale(1.147))
    harness.assert_equal(1.15, addon.db:GetLocalSettings().addonScale)
  end,

  ["database persists seen reward toast ids in local settings"] = function()
    local savedVariables = {
      profile = {
        guildDatasets = {},
        localSettings = {
          seenAwardToastIds = "legacy",
        },
      },
    }

    wow.reset({
      guildName = "Raid Bakery",
      savedVariables = savedVariables,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_false(addon.db:HasSeenAwardToast("award:remote:once"))
    harness.assert_true(addon.db:MarkAwardToastSeen("award:remote:once"))
    harness.assert_true(addon.db:HasSeenAwardToast("award:remote:once"))
    harness.assert_true(savedVariables.profile.localSettings.seenAwardToastIds["award:remote:once"])

    local missingOk, missingErr = addon.db:MarkAwardToastSeen("")
    harness.assert_false(missingOk)
    harness.assert_equal("missing awardId", missingErr)
  end,

  ["database persists seen award chat ids in local settings"] = function()
    local savedVariables = {
      profile = {
        guildDatasets = {},
        localSettings = {
          seenAwardChatIds = "legacy",
        },
      },
    }

    wow.reset({
      guildName = "Raid Bakery",
      savedVariables = savedVariables,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_false(addon.db:HasSeenAwardChat("award:remote:once"))
    harness.assert_true(addon.db:MarkAwardChatSeen("award:remote:once"))
    harness.assert_true(addon.db:HasSeenAwardChat("award:remote:once"))
    harness.assert_true(savedVariables.profile.localSettings.seenAwardChatIds["award:remote:once"])

    local missingOk, missingErr = addon.db:MarkAwardChatSeen("")
    harness.assert_false(missingOk)
    harness.assert_equal("missing awardId", missingErr)
  end,

  ["database stores sync peers locally by guild and lists newest first"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      savedVariables = {
        profile = {
          guildDatasets = {},
          localSettings = {
            syncPeersByGuild = "legacy",
          },
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local first = addon.db:RecordSyncPeer("raid bakery", "Bakerone-Stormrage", 1717336800)
    local second = addon.db:RecordSyncPeer("raid bakery", "Bakertwo-Stormrage", 1717423200)
    addon.db:RecordSyncPeer("other guild", "Otherone-Stormrage", 1717509600)
    local missing, missingErr = addon.db:RecordSyncPeer("raid bakery", "", 1717596000)
    local rows = addon.db:GetSyncPeers("raid bakery")
    local otherRows = addon.db:GetSyncPeers("other guild")

    harness.assert_true(first ~= nil)
    harness.assert_true(second ~= nil)
    harness.assert_false(missing)
    harness.assert_equal("missing player", missingErr)
    harness.assert_equal(2, #rows)
    harness.assert_equal("Bakertwo-Stormrage", rows[1].player)
    harness.assert_equal(1717423200, rows[1].lastSeenAt)
    harness.assert_equal("Bakerone-Stormrage", rows[2].player)
    harness.assert_equal(1, #otherRows)
    harness.assert_equal("Otherone-Stormrage", otherRows[1].player)
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

  ["database generated award and nomination ids include the local actor to avoid cross-client collisions"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      serverTime = 1717336800,
    })
    local addon = wow.loadAddon()
    addon:OnInitialize()

    local guildKey = addon:GetActiveGuildContext().guildKey
    local nominationId = addon.db:NextNominationId(
      guildKey,
      addon:GetCurrentPlayerFullName(),
      addon.Time:Now()
    )
    local awardId = addon.db:NextAwardId(
      guildKey,
      addon:GetCurrentPlayerFullName(),
      addon.Time:Now()
    )

    harness.assert_true(nominationId:match("^nom:Guildmaster%-Stormrage:1717336800:%d+$") ~= nil)
    harness.assert_true(awardId:match("^award:Guildmaster%-Stormrage:1717336800:%d+$") ~= nil)
  end,

  ["database stores alias mappings by normalized key in the current guild dataset"] = function()
    wow.reset({ guildName = "Raid Bakery" })
    local addon = wow.loadAddon()
    addon:OnInitialize()

    local row = addon.db:UpsertAliasMapping("raid bakery", {
      aliasKey = "moon",
      aliasDisplay = "Moon",
      canonicalName = "Moonrustle-Stormrage",
      createdBy = "Guildmaster-Stormrage",
      createdAt = 1760000000,
    })
    local found = addon.db:GetAliasMapping("raid bakery", "moon")

    harness.assert_true(row ~= nil)
    harness.assert_equal("Moon", found.aliasDisplay)
    harness.assert_equal("Moonrustle-Stormrage", found.canonicalName)
  end,

  ["database lists alias mappings in deterministic display order"] = function()
    wow.reset({ guildName = "Raid Bakery" })
    local addon = wow.loadAddon()
    addon:OnInitialize()

    addon.db:UpsertAliasMapping("raid bakery", {
      aliasKey = "zmoon",
      aliasDisplay = "Zmoon",
      canonicalName = "Moonrustle-Stormrage",
      createdBy = "Guildmaster-Stormrage",
      createdAt = 1760000000,
    })
    addon.db:UpsertAliasMapping("raid bakery", {
      aliasKey = "moon",
      aliasDisplay = "Moon",
      canonicalName = "Moonrustle-Stormrage",
      createdBy = "Guildmaster-Stormrage",
      createdAt = 1760000001,
    })

    local rows = addon.db:GetAliasMappings("raid bakery")

    harness.assert_equal("Moon", rows[1].aliasDisplay)
    harness.assert_equal("Zmoon", rows[2].aliasDisplay)
  end,

  ["database deletes alias mappings without touching awards or nominations"] = function()
    wow.reset({ guildName = "Raid Bakery" })
    local addon = wow.loadAddon()
    addon:OnInitialize()

    addon.db:UpsertNomination("raid bakery", {
      nominationId = "nom:1",
      nominee = "Moon",
      status = "pending",
    })
    addon.db:UpsertAward("raid bakery", {
      awardId = "award:1",
      recipient = "Moon",
      reason = "Set the oven to lava",
      source = "direct",
    })
    addon.db:UpsertAliasMapping("raid bakery", {
      aliasKey = "moon",
      aliasDisplay = "Moon",
      canonicalName = "Moonrustle-Stormrage",
      createdBy = "Guildmaster-Stormrage",
      createdAt = 1760000000,
    })

    local deleted = addon.db:DeleteAliasMapping("raid bakery", "moon")
    local foundAlias = addon.db:GetAliasMapping("raid bakery", "moon")
    local foundNomination = addon.db:GetNomination("raid bakery", "nom:1")
    local foundAward = addon.db:GetAward("raid bakery", "award:1")

    harness.assert_true(deleted)
    harness.assert_true(foundAlias == nil)
    harness.assert_equal("Moon", foundNomination.nominee)
    harness.assert_equal("Moon", foundAward.recipient)
  end,
}

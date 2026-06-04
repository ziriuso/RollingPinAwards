local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

local function setupAceGuild(seed)
  seed = seed or {}
  seed.ace3 = true
  seed.guildName = seed.guildName or "Raid Bakery"
  seed.playerName = seed.playerName or "Guildmaster"
  seed.guildRankName = seed.guildRankName or "Guild Master"
  seed.guildRankIndex = seed.guildRankIndex or 0
  seed.guildMembers = seed.guildMembers or {
    {
      name = "Guildmaster-Stormrage",
      rankName = "Guild Master",
      rankIndex = 0,
    },
    {
      name = "Officerone-Stormrage",
      rankName = "Officer",
      rankIndex = 1,
    },
    {
      name = "Bakerone-Stormrage",
      rankName = "Member",
      rankIndex = 5,
    },
  }

  wow.reset(seed)

  local addon = wow.loadAddon()
  addon:OnInitialize()
  addon:OnEnable()

  return addon
end

local function decodeLastMessage(addon)
  local message = addon.__lastCommMessage and addon.__lastCommMessage.message
  local ok, envelope = addon:Deserialize(message)

  harness.assert_true(ok)

  return envelope
end

local function setupNativeGuild(seed)
  seed = seed or {}
  seed.nativeComm = true
  seed.guildName = seed.guildName or "Raid Bakery"
  seed.playerName = seed.playerName or "Guildmaster"
  seed.guildRankName = seed.guildRankName or "Guild Master"
  seed.guildRankIndex = seed.guildRankIndex or 0
  seed.guildMembers = seed.guildMembers or {
    {
      name = "Guildmaster-Stormrage",
      rankName = "Guild Master",
      rankIndex = 0,
    },
    {
      name = "Officerone-Stormrage",
      rankName = "Officer",
      rankIndex = 1,
    },
  }

  wow.reset(seed)

  local addon = wow.loadAddon()
  addon:OnInitialize()
  addon:OnEnable()

  return addon
end

return {
  ["sync rejects a privileged award update from the wrong guild"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local accepted = addon.sync:AcceptAward({
      guildKey = "other guild",
      awardedBy = "Officerone-Stormrage",
      awardId = "award:99",
    })

    harness.assert_true(accepted == false)
  end,

  ["sync rejects a privileged award update from an unauthorized sender"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      guildMembers = {
        {
          name = "Guildmaster-Stormrage",
          rankName = "Guild Master",
          rankIndex = 0,
        },
        {
          name = "Officerone-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local accepted = addon.sync:AcceptAward({
      guildKey = addon:GetActiveGuildContext().guildKey,
      awardedBy = "Officerone-Stormrage",
      awardId = "award:99",
      recipient = "Burny-Stormrage",
      reason = "Set the oven to lava",
      source = "direct",
    })

    harness.assert_true(accepted == false)
  end,

  ["sync accepts a same-guild privileged award update from a gm-authorized officer"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      guildMembers = {
        {
          name = "Guildmaster-Stormrage",
          rankName = "Guild Master",
          rankIndex = 0,
        },
        {
          name = "Officerone-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.permissions:GrantOfficerPermission("Officerone-Stormrage")

    local accepted = addon.sync:AcceptAward({
      guildKey = addon:GetActiveGuildContext().guildKey,
      awardedBy = "Officerone-Stormrage",
      awardId = "award:99",
      awardName = "The Burnt Rolling Pin",
      recipient = "Burny-Stormrage",
      player = "Burny-Stormrage",
      reason = "Set the oven to lava",
      source = "direct",
    })

    harness.assert_true(accepted)
    harness.assert_equal(1, #addon.awards:GetPublicHistory())
  end,

  ["sync accepts a same-guild privileged award update from a rank with direct-award permission"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      guildMembers = {
        {
          name = "Guildmaster-Stormrage",
          rankName = "Guild Master",
          rankIndex = 0,
        },
        {
          name = "Officerone-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.permissions:SetRankPermissions(1, "Officer", {
      canCreateDirectAwards = true,
    })

    local accepted = addon.sync:AcceptAward({
      guildKey = addon:GetActiveGuildContext().guildKey,
      awardedBy = "Officerone-Stormrage",
      awardId = "award:100",
      awardName = "The Burnt Rolling Pin",
      recipient = "Burny-Stormrage",
      player = "Burny-Stormrage",
      reason = "Set the oven to lava",
      source = "direct",
    })

    harness.assert_true(accepted)
  end,

  ["sync accepts a moderated nomination update from a rank with nomination permission"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      guildMembers = {
        {
          name = "Guildmaster-Stormrage",
          rankName = "Guild Master",
          rankIndex = 0,
        },
        {
          name = "Officerone-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.permissions:SetRankPermissions(1, "Officer", {
      canManageNominations = true,
    })

    local accepted = addon.sync:AcceptNomination({
      guildKey = addon:GetActiveGuildContext().guildKey,
      nominationId = "nom:100",
      nominee = "Burny-Stormrage",
      reason = "Pulled the boss while fishing",
      status = "approved",
      resolvedBy = "Officerone-Stormrage",
      lastModifiedBy = "Officerone-Stormrage",
    })

    harness.assert_true(accepted)
  end,

  ["sync ignores stale nominations that would downgrade an existing resolved row"] = function()
    local addon = setupAceGuild()
    local guildKey = addon:GetActiveGuildContext().guildKey

    addon.db:UpsertNomination(guildKey, {
      nominationId = "nom:shared",
      guildKey = guildKey,
      nominee = "Moonrustle-Stormrage",
      reason = "Already resolved",
      status = "approved",
      awardId = "award:shared",
      nominatedBy = "Bakerone-Stormrage",
      resolvedBy = "Guildmaster-Stormrage",
      lastModifiedAt = 200,
      lastModifiedBy = "Guildmaster-Stormrage",
    })

    local accepted, err = addon.sync:AcceptNomination({
      nominationId = "nom:shared",
      guildKey = guildKey,
      nominee = "Moonrustle-Stormrage",
      reason = "Old pending copy",
      status = "pending",
      nominatedBy = "Officerone-Stormrage",
      lastModifiedAt = 100,
      lastModifiedBy = "Officerone-Stormrage",
    })
    local stored = addon.db:GetNomination(guildKey, "nom:shared")

    harness.assert_false(accepted)
    harness.assert_equal("stale nomination", err)
    harness.assert_equal("approved", stored.status)
    harness.assert_equal("award:shared", stored.awardId)
  end,

  ["sync ignores stale awards that would replace existing history"] = function()
    local addon = setupAceGuild()
    local guildKey = addon:GetActiveGuildContext().guildKey

    addon.permissions:SetRankPermissions(1, "Officer", {
      canCreateDirectAwards = true,
    })
    addon.db:UpsertAward(guildKey, {
      awardId = "award:shared",
      guildKey = guildKey,
      awardName = "The Burnt Rolling Pin",
      recipient = "Mara-Stormrage",
      player = "Mara-Stormrage",
      reason = "Current local history",
      awardedBy = "Guildmaster-Stormrage",
      source = "direct",
      lastModifiedAt = 200,
      lastModifiedBy = "Guildmaster-Stormrage",
    })

    local accepted, err = addon.sync:AcceptAward({
      awardId = "award:shared",
      guildKey = guildKey,
      awardName = "The Burnt Rolling Pin",
      recipient = "Moonrustle-Stormrage",
      player = "Moonrustle-Stormrage",
      reason = "Old remote history",
      awardedBy = "Officerone-Stormrage",
      source = "direct",
      lastModifiedAt = 100,
      lastModifiedBy = "Officerone-Stormrage",
    })
    local stored = addon.db:GetAward(guildKey, "award:shared")

    harness.assert_false(accepted)
    harness.assert_equal("stale award", err)
    harness.assert_equal("Mara-Stormrage", stored.recipient)
    harness.assert_equal("Current local history", stored.reason)
  end,

  ["sync accepts a rank permission update from an authorized rank manager"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      guildMembers = {
        {
          name = "Guildmaster-Stormrage",
          rankName = "Guild Master",
          rankIndex = 0,
        },
        {
          name = "Officerone-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
        {
          name = "Veteran-Stormrage",
          rankName = "Veteran",
          rankIndex = 2,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.permissions:SetRankPermissions(1, "Officer", {
      canManageAddonPermissions = true,
    })

    local accepted = addon.sync:AcceptRankPermission({
      guildKey = addon:GetActiveGuildContext().guildKey,
      rankIndex = 2,
      rankName = "Veteran",
      canManageNominations = true,
      canCreateDirectAwards = false,
      canDeleteAwards = false,
      canManageAddonPermissions = false,
      lastModifiedBy = "Officerone-Stormrage",
    })
    local row = addon.permissions:GetRankPermissionRow(2)

    harness.assert_true(accepted)
    harness.assert_true(row.canManageNominations)
  end,

  ["sync accepts an alias mapping update from an authorized rank manager and rejects unauthorized senders"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      guildMembers = {
        {
          name = "Guildmaster-Stormrage",
          rankName = "Guild Master",
          rankIndex = 0,
        },
        {
          name = "Officerone-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
        {
          name = "Veteran-Stormrage",
          rankName = "Veteran",
          rankIndex = 2,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon.permissions:SetRankPermissions(1, "Officer", {
      canManageAddonPermissions = true,
    })

    local accepted = addon.sync:AcceptAliasMapping({
      guildKey = addon:GetActiveGuildContext().guildKey,
      aliasKey = "moon",
      aliasDisplay = "Moon",
      canonicalName = "Moonrustle-Stormrage",
      createdBy = "Officerone-Stormrage",
      createdAt = 1760000000,
      lastModifiedBy = "Officerone-Stormrage",
    })
    local found = addon.db:GetAliasMapping(addon:GetActiveGuildContext().guildKey, "moon")
    local rejected, rejectError = addon.sync:AcceptAliasMapping({
      guildKey = addon:GetActiveGuildContext().guildKey,
      aliasKey = "burny",
      aliasDisplay = "Burny",
      canonicalName = "Burny-Stormrage",
      createdBy = "Veteran-Stormrage",
      createdAt = 1760000001,
      lastModifiedBy = "Veteran-Stormrage",
    })

    harness.assert_true(accepted)
    harness.assert_equal("Moonrustle-Stormrage", found.canonicalName)
    harness.assert_false(rejected)
    harness.assert_equal("unauthorized", rejectError)
  end,

  ["sync broadcasts envelopes through ace comm when available"] = function()
    local addon = setupAceGuild()

    local ok = addon.sync:Broadcast("nomination", {
      guildKey = addon:GetActiveGuildContext().guildKey,
      nominationId = "nom:42",
    }, "GUILD")

    harness.assert_true(ok)
    harness.assert_equal(addon.Constants.COMM_PREFIX, addon.__lastCommMessage.prefix)
    harness.assert_equal("string", type(addon.__lastCommMessage.message))

    local envelope = decodeLastMessage(addon)
    harness.assert_equal("nomination", envelope.payloadType)
    harness.assert_equal("nom:42", envelope.payload.nominationId)
  end,

  ["ace comm serialized payloads route through the sync dispatcher"] = function()
    local addon = setupAceGuild()

    local called = false
    addon.sync.AcceptAward = function(_, payload)
      called = payload.awardId == "award:5"

      return true
    end

    local serialized = addon:Serialize({
      payloadType = "award",
      payload = {
        awardId = "award:5",
      },
    })

    addon:OnCommReceived(addon.Constants.COMM_PREFIX, serialized, "GUILD", "Officerone-Stormrage")

    harness.assert_true(called)
  end,

  ["local award nomination vote permission and delete actions broadcast sync payloads"] = function()
    local addon = setupAceGuild()

    local directAward = addon.awards:CreateDirectAward(
      "Burny-Stormrage",
      "Set the oven to lava",
      "burnt"
    )
    local directEnvelope = decodeLastMessage(addon)

    harness.assert_true(directAward ~= nil)
    harness.assert_equal("award", directEnvelope.payloadType)
    harness.assert_equal(directAward.awardId, directEnvelope.payload.awardId)
    harness.assert_equal("direct", directEnvelope.payload.source)

    wow.setPlayer("Bakerone", "Member", 5)
    local nomination = addon.nominations:Create(
      "Moonrustle-Stormrage",
      "Baiting Fae",
      "golden"
    )
    local nominationEnvelope = decodeLastMessage(addon)

    harness.assert_equal("nomination", nominationEnvelope.payloadType)
    harness.assert_equal(nomination.nominationId, nominationEnvelope.payload.nominationId)
    harness.assert_equal("pending", nominationEnvelope.payload.status)

    addon.nominations:CastVote(nomination.nominationId, "upvote")
    local voteEnvelope = decodeLastMessage(addon)

    harness.assert_equal("vote", voteEnvelope.payloadType)
    harness.assert_equal(nomination.nominationId, voteEnvelope.payload.nominationId)
    harness.assert_equal("Bakerone-Stormrage", voteEnvelope.payload.voter)

    wow.setPlayer("Guildmaster", "Guild Master", 0)
    local messageCountBeforeApprove = #addon.__commMessages
    local approvedAward = addon.nominations:Approve(nomination.nominationId)

    harness.assert_true(approvedAward ~= nil)
    harness.assert_equal(messageCountBeforeApprove + 2, #addon.__commMessages)
    harness.assert_equal("award", decodeLastMessage(addon).payloadType)
    local ok, approvedNominationEnvelope = addon:Deserialize(addon.__commMessages[#addon.__commMessages - 1].message)
    harness.assert_true(ok)
    harness.assert_equal("nomination", approvedNominationEnvelope.payloadType)
    harness.assert_equal("approved", approvedNominationEnvelope.payload.status)

    local rejected = addon.nominations:Create("Shaka-Stormrage", "Rejected reason")
    addon.nominations:Reject(rejected.nominationId)
    local rejectedEnvelope = decodeLastMessage(addon)

    harness.assert_equal("nomination", rejectedEnvelope.payloadType)
    harness.assert_equal("rejected", rejectedEnvelope.payload.status)

    addon.permissions:SetRankPermissions(1, "Officer", {
      canManageNominations = true,
      canCreateDirectAwards = true,
    })
    local permissionEnvelope = decodeLastMessage(addon)

    harness.assert_equal("rank_permissions", permissionEnvelope.payloadType)
    harness.assert_equal(1, permissionEnvelope.payload.rankIndex)
    harness.assert_true(permissionEnvelope.payload.canManageNominations)

    local alias = addon.uiBridge:SaveAliasMapping("Moon", "Moonrustle-Stormrage")
    local aliasEnvelope = decodeLastMessage(addon)

    harness.assert_true(alias ~= nil)
    harness.assert_equal("alias_mapping", aliasEnvelope.payloadType)
    harness.assert_equal("moon", aliasEnvelope.payload.aliasKey)
    harness.assert_equal("Moonrustle-Stormrage", aliasEnvelope.payload.canonicalName)

    local aliasDeleted = addon.uiBridge:DeleteAliasMapping("moon")
    local aliasDeleteEnvelope = decodeLastMessage(addon)

    harness.assert_true(aliasDeleted)
    harness.assert_equal("alias_mapping", aliasDeleteEnvelope.payloadType)
    harness.assert_equal("moon", aliasDeleteEnvelope.payload.aliasKey)
    harness.assert_true(aliasDeleteEnvelope.payload.deleted)

    addon.awards:DeleteAward(directAward.awardId)
    local deleteEnvelope = decodeLastMessage(addon)

    harness.assert_equal("award", deleteEnvelope.payloadType)
    harness.assert_equal(directAward.awardId, deleteEnvelope.payload.awardId)
    harness.assert_true(deleteEnvelope.payload.deleted)
  end,

  ["sync accepts authorized award deletion payloads"] = function()
    local addon = setupAceGuild()
    local award = addon.awards:CreateDirectAward("Burny-Stormrage", "Set the oven to lava")

    local accepted = addon.sync:AcceptAward({
      guildKey = addon:GetActiveGuildContext().guildKey,
      awardId = award.awardId,
      source = "direct",
      deleted = true,
      lastModifiedBy = "Guildmaster-Stormrage",
    })

    harness.assert_true(accepted)
    harness.assert_equal(0, #addon.awards:GetPublicHistory())
  end,

  ["native comm fallback registers and broadcasts when ace is unavailable"] = function()
    local addon = setupNativeGuild()

    harness.assert_true(addon.__rpaUsesAce3 == false)
    harness.assert_equal(addon.Constants.COMM_PREFIX, addon.__rpaNativeCommPrefix)
    harness.assert_equal(addon.Constants.COMM_PREFIX, _G.__RPA_TEST_STATE.nativeCommPrefix)
    harness.assert_true(#(_G.__RPA_TEST_STATE.nativeCommMessages or {}) >= 1)

    local award = addon.awards:CreateDirectAward("Burny-Stormrage", "Set the oven to lava")
    local envelope
    for _, sent in ipairs(_G.__RPA_TEST_STATE.nativeCommMessages or {}) do
      local decoded, err = addon.sync:DecodeNativeMessage(
        sent.message,
        sent.distribution,
        "Guildmaster-Stormrage"
      )
      if err ~= "partial" and decoded and decoded.payloadType == "award" then
        envelope = decoded
      end
    end

    harness.assert_true(award ~= nil)
    harness.assert_true(envelope ~= nil)
    harness.assert_equal("award", envelope.payloadType)
    harness.assert_equal(award.awardId, envelope.payload.awardId)
    harness.assert_equal("direct", envelope.payload.source)
  end,

  ["native fallback chunks long nomination envelopes under the addon-message limit"] = function()
    local addon = setupNativeGuild({
      nativeCommMaxBytes = 255,
    })
    local guildKey = addon:GetActiveGuildContext().guildKey
    _G.__RPA_TEST_STATE.nativeCommMessages = {}
    _G.__RPA_TEST_STATE.nativeCommRejectedMessages = {}

    local ok = addon.sync:Broadcast("nomination", {
      nominationId = "nom:Guildmaster-Stormrage:1717336800:99",
      guildKey = guildKey,
      nominee = "Moonrustle-Stormrage",
      reason = string.rep("Helpful bakery logistics. ", 18),
      awardType = "burnt",
      status = "pending",
      nominatedBy = "Guildmaster-Stormrage",
      createdAt = 1717336800,
      lastModifiedAt = 1717336800,
      lastModifiedBy = "Guildmaster-Stormrage",
    }, "GUILD")

    harness.assert_true(ok)
    harness.assert_equal(0, #(_G.__RPA_TEST_STATE.nativeCommRejectedMessages or {}))
    harness.assert_true(#(_G.__RPA_TEST_STATE.nativeCommMessages or {}) > 1)

    for _, sent in ipairs(_G.__RPA_TEST_STATE.nativeCommMessages or {}) do
      harness.assert_true(#sent.message <= 255)
    end
  end,

  ["native fallback reassembles chunked inbound nominations before dispatch"] = function()
    local addon = setupNativeGuild({
      nativeCommMaxBytes = 255,
    })
    local guildKey = addon:GetActiveGuildContext().guildKey
    _G.__RPA_TEST_STATE.nativeCommMessages = {}

    addon.sync:Broadcast("nomination", {
      nominationId = "nom:Officerone-Stormrage:1717336800:100",
      guildKey = guildKey,
      nominee = "Moonrustle-Stormrage",
      reason = string.rep("Chunked inbound bakery logistics. ", 16),
      awardType = "golden",
      status = "pending",
      nominatedBy = "Officerone-Stormrage",
      createdAt = 1717336800,
      lastModifiedAt = 1717336800,
      lastModifiedBy = "Officerone-Stormrage",
    }, "GUILD")

    local dispatchedNominationId
    addon.sync.AcceptNomination = function(_, payload)
      dispatchedNominationId = payload.nominationId

      return true
    end

    for _, sent in ipairs(_G.__RPA_TEST_STATE.nativeCommMessages or {}) do
      addon:OnCommReceived(
        addon.Constants.COMM_PREFIX,
        sent.message,
        sent.distribution,
        "Officerone-Stormrage"
      )
    end

    harness.assert_equal("nom:Officerone-Stormrage:1717336800:100", dispatchedNominationId)
    harness.assert_equal("nomination", addon.sync.lastInbound.payloadType)
    harness.assert_true(addon.sync.lastInbound.ok)
  end,

  ["native comm fallback inbound messages deserialize and dispatch"] = function()
    local addon = setupNativeGuild()

    local called = false
    addon.sync.AcceptNomination = function(_, payload)
      called = payload.nominationId == "nom:77"

      return true
    end

    local message = addon.sync:SerializeEnvelope({
      payloadType = "nomination",
      payload = {
        guildKey = addon:GetActiveGuildContext().guildKey,
        nominationId = "nom:77",
        status = "pending",
      },
    })

    addon:OnCommReceived(addon.Constants.COMM_PREFIX, message, "GUILD", "Officerone-Stormrage")

    harness.assert_true(called)
    harness.assert_equal("nomination", addon.sync.lastInbound.payloadType)
    harness.assert_true(addon.sync.lastInbound.ok)
  end,

  ["sync announces itself on startup and manual sync now over native fallback"] = function()
    local addon = setupNativeGuild()
    local startupMessages = _G.__RPA_TEST_STATE.nativeCommMessages or {}
    local startupEnvelope = addon.sync:DeserializeEnvelope(startupMessages[1].message)

    harness.assert_equal("sync_hello", startupEnvelope.payloadType)
    harness.assert_equal(addon:GetActiveGuildContext().guildKey, startupEnvelope.payload.guildKey)

    local beforeManual = #startupMessages
    local ok = addon:HandleChatCommand("sync now")
    local manualMessages = _G.__RPA_TEST_STATE.nativeCommMessages or {}

    harness.assert_true(ok)
    harness.assert_true(#manualMessages > beforeManual)
    local manualEnvelope = addon.sync:DeserializeEnvelope(manualMessages[beforeManual + 1].message)
    harness.assert_equal("sync_hello", manualEnvelope.payloadType)
  end,

  ["sync sends a fresh hello when provisional guild key becomes stable"] = function()
    local addon = setupNativeGuild({
      guildName = "Tyrrish Rebellion",
    })
    local startupMessages = _G.__RPA_TEST_STATE.nativeCommMessages or {}
    local startupEnvelope = addon.sync:DeserializeEnvelope(startupMessages[1].message)

    harness.assert_equal("sync_hello", startupEnvelope.payloadType)
    harness.assert_equal("tyrrish rebellion", startupEnvelope.payload.guildKey)

    local beforeRefresh = #startupMessages
    wow.setGuild("Tyrrish Rebellion", 426137461)
    addon:RefreshActiveGuildContext()

    harness.assert_true(#startupMessages > beforeRefresh)
    local stableEnvelope = addon.sync:DeserializeEnvelope(startupMessages[beforeRefresh + 1].message)
    harness.assert_equal("sync_hello", stableEnvelope.payloadType)
    harness.assert_equal("426137461", stableEnvelope.payload.guildKey)
  end,

  ["sync responds to hello with all syncable record types"] = function()
    local addon = setupNativeGuild()
    local guildKey = addon:GetActiveGuildContext().guildKey

    addon.db:UpsertRankPermission(guildKey, 1, {
      rankIndex = 1,
      rankName = "Officer",
      canManageNominations = true,
      canCreateDirectAwards = true,
      canDeleteAwards = true,
      canManageAddonPermissions = true,
      lastModifiedAt = 1717336800,
      lastModifiedBy = "Guildmaster-Stormrage",
    })
    addon.db:UpsertAliasMapping(guildKey, {
      aliasKey = "moon",
      aliasDisplay = "Moon",
      canonicalName = "Moonrustle-Stormrage",
      createdBy = "Guildmaster-Stormrage",
      createdAt = 1717336800,
      lastModifiedBy = "Guildmaster-Stormrage",
      lastModifiedAt = 1717336800,
    })
    addon.db:UpsertNomination(guildKey, {
      nominationId = "nom:5",
      guildKey = guildKey,
      nominee = "Moonrustle-Stormrage",
      reason = "Helpful testing",
      status = "pending",
      nominatedBy = "Bakerone-Stormrage",
      lastModifiedBy = "Bakerone-Stormrage",
      lastModifiedAt = 1717336800,
    })
    addon.db:StoreVote(guildKey, "nom:5", {
      nominationId = "nom:5",
      guildKey = guildKey,
      voter = "Bakerone-Stormrage",
      voteType = "upvote",
      createdAt = 1717336801,
    })
    addon.db:UpsertAward(guildKey, {
      awardId = "award:8",
      guildKey = guildKey,
      awardName = "The Burnt Rolling Pin",
      awardType = "burnt",
      recipient = "Moonrustle-Stormrage",
      player = "Moonrustle-Stormrage",
      reason = "Won the dough race",
      awardedBy = "Guildmaster-Stormrage",
      source = "direct",
      lastModifiedBy = "Guildmaster-Stormrage",
      lastModifiedAt = 1717336802,
    })

    _G.__RPA_TEST_STATE.nativeCommMessages = {}
    local hello = addon.sync:SerializeEnvelope({
      payloadType = "sync_hello",
      payload = {
        guildKey = guildKey,
        sender = "Officerone-Stormrage",
        sentAt = 1717336803,
      },
    })

    addon:OnCommReceived(addon.Constants.COMM_PREFIX, hello, "GUILD", "Officerone-Stormrage")

    local seen = {}
    for _, message in ipairs(_G.__RPA_TEST_STATE.nativeCommMessages or {}) do
      local envelope, err = addon.sync:DecodeNativeMessage(
        message.message,
        message.distribution,
        "Guildmaster-Stormrage"
      )
      if err ~= "partial" then
        harness.assert_true(envelope ~= nil)
        seen[envelope.payloadType] = true
      end
    end

    harness.assert_true(seen.rank_permissions)
    harness.assert_true(seen.alias_mapping)
    harness.assert_true(seen.nomination)
    harness.assert_true(seen.vote)
    harness.assert_true(seen.award)
    harness.assert_true(seen.sync_snapshot_complete)
  end,
}

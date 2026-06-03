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

    local award = addon.awards:CreateDirectAward("Burny-Stormrage", "Set the oven to lava")
    local sent = _G.__RPA_TEST_STATE.lastNativeCommMessage
    local envelope = addon.sync:DeserializeEnvelope(sent.message)

    harness.assert_true(award ~= nil)
    harness.assert_equal(addon.Constants.COMM_PREFIX, sent.prefix)
    harness.assert_equal("GUILD", sent.distribution)
    harness.assert_equal("string", type(sent.message))
    harness.assert_equal("award", envelope.payloadType)
    harness.assert_equal(award.awardId, envelope.payload.awardId)
    harness.assert_equal("direct", envelope.payload.source)
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
}

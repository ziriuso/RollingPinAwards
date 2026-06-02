local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

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

  ["sync broadcasts envelopes through ace comm when available"] = function()
    wow.reset({
      ace3 = true,
      guildName = "Raid Bakery",
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon:OnEnable()

    local ok = addon.sync:Broadcast("nomination", {
      guildKey = addon:GetActiveGuildContext().guildKey,
      nominationId = "nom:42",
    }, "GUILD")

    harness.assert_true(ok)
    harness.assert_equal(addon.Constants.COMM_PREFIX, addon.__lastCommMessage.prefix)
    harness.assert_equal("nomination", addon.__lastCommMessage.message.payloadType)
    harness.assert_equal("nom:42", addon.__lastCommMessage.message.payload.nominationId)
  end,

  ["ace comm payloads route through the sync dispatcher"] = function()
    wow.reset({
      ace3 = true,
      guildName = "Raid Bakery",
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon:OnEnable()

    local called = false
    addon.sync.AcceptAward = function(_, payload)
      called = payload.awardId == "award:5"

      return true
    end

    addon:OnCommReceived(addon.Constants.COMM_PREFIX, {
      payloadType = "award",
      payload = {
        awardId = "award:5",
      },
    }, "GUILD", "Officerone-Stormrage")

    harness.assert_true(called)
  end,
}

local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["ordinary startup wires the permission services"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      guildMembers = {
        {
          name = "Guildmaster-Stormrage",
          rankName = "Guild Master",
          rankIndex = 0,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_true(type(addon.rosterPermissions) == "table")
    harness.assert_true(type(addon.permissions) == "table")
  end,

  ["gm can grant addon permission to an eligible officer"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      isGuildOfficer = true,
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

    local ok = addon.permissions:GrantOfficerPermission("Officerone-Stormrage")
    local guild = addon:GetActiveGuildContext()

    harness.assert_true(ok)
    harness.assert_true(addon.permissions:HasOfficerPermission("Officerone-Stormrage"))
    harness.assert_equal(
      "Guildmaster-Stormrage",
      addon.db:GetGuildDataset(guild.guildKey).permissionRoster["Officerone-Stormrage"].grantedBy
    )
  end,

  ["officer without gm authority cannot grant addon permission"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Officerone",
      guildRankName = "Officer",
      guildRankIndex = 1,
      isGuildOfficer = true,
      guildMembers = {
        {
          name = "Officerone-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
        {
          name = "Officertwo-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local ok = addon.permissions:GrantOfficerPermission("Officertwo-Stormrage")
    local guild = addon:GetActiveGuildContext()

    harness.assert_true(ok == false)
    harness.assert_true(addon.permissions:HasOfficerPermission("Officertwo-Stormrage") == false)
    harness.assert_true(
      addon.db:GetGuildDataset(guild.guildKey).permissionRoster["Officertwo-Stormrage"] == nil
    )
  end,

  ["gm can revoke addon permission from an officer"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      isGuildOfficer = true,
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

    local revoked = addon.permissions:RevokeOfficerPermission("Officerone-Stormrage")
    local guild = addon:GetActiveGuildContext()

    harness.assert_true(revoked)
    harness.assert_false(addon.permissions:HasOfficerPermission("Officerone-Stormrage"))
    harness.assert_nil(addon.db:GetGuildDataset(guild.guildKey).permissionRoster["Officerone-Stormrage"])
  end,

  ["exact rank permission row controls nomination moderation"] = function()
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

    local saved = addon.permissions:SetRankPermissions(1, "Officer", {
      canManageNominations = true,
    })

    wow.setPlayer("Officerone", "Officer", 1)

    harness.assert_true(saved)
    harness.assert_true(addon.permissions:CanManageNominations())
    harness.assert_false(addon.permissions:CanCreateDirectAwards())
    harness.assert_false(addon.permissions:CanDeleteAwards())
    harness.assert_false(addon.permissions:CanManageAddonPermissions())
  end,

  ["guild master always has full access even without rank rows"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_true(addon.permissions:CanManageNominations())
    harness.assert_true(addon.permissions:CanCreateDirectAwards())
    harness.assert_true(addon.permissions:CanDeleteAwards())
    harness.assert_true(addon.permissions:CanManageAddonPermissions())
  end,

  ["guild rank matrix uses guild control ranks when the member roster is empty"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
      guildMembers = {},
      guildRanks = {
        { name = "Guild Master" },
        { name = "Officer" },
        { name = "Veteran" },
        { name = "Member" },
      },
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local matrix = addon.permissions:GetGuildRankMatrix()

    harness.assert_equal(4, #matrix)
    harness.assert_equal("Guild Master", matrix[1].rankName)
    harness.assert_equal("Officer", matrix[2].rankName)
    harness.assert_equal("Member", matrix[4].rankName)
  end,
}

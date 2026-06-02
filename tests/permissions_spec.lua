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
}

local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

return {
  ["slash command routes nominate requests to the nominations service"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local called = false
    addon.nominations.Create = function(_, nominee, reason)
      called = nominee == "Burny-Stormrage" and reason == "Pulled the boss"

      return {}
    end

    addon.commands:Handle('nominate Burny-Stormrage "Pulled the boss"')

    harness.assert_true(called)
  end,

  ["slash command bootstraps the addon without manual initialization"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      loggedIn = true,
    })

    local addon = wow.loadAddon()

    harness.assert_true(type(_G.SlashCmdList.ROLLINGPINAWARDS) == "function")
    harness.assert_true(addon.__rpaInitialized ~= true)
    harness.assert_true(_G.SlashCmdList.ROLLINGPINAWARDS("") == true)
    harness.assert_true(addon.__rpaInitialized == true)
    harness.assert_true(addon.__rpaEnabled == true)
    harness.assert_true(addon.mainFrame.frame.visible == true)
  end,

  ["startup events initialize and enable the addon in ace mode"] = function()
    wow.reset({
      ace3 = true,
      guildName = "Raid Bakery",
    })

    local addon = wow.loadAddon()

    harness.assert_true(addon.__rpaInitialized ~= true)
    wow.fireEvent("ADDON_LOADED", "RollingPinAwards")
    harness.assert_true(addon.__rpaInitialized == true)

    wow.setLoggedIn(true)
    wow.fireEvent("PLAYER_LOGIN")
    harness.assert_true(addon.__rpaEnabled == true)
    harness.assert_true(addon.__aceCommPrefix == addon.Constants.COMM_PREFIX)
  end,

  ["slash command toggles the main frame after ordinary startup"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_true(addon.mainFrame ~= nil)
    harness.assert_true(addon.uiBridge ~= nil)
    harness.assert_true(addon:HandleChatCommand("") == true)
    harness.assert_true(addon.mainFrame.frame.visible == true)
  end,

  ["background calibration slash commands are not public commands"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local ok, err = addon:HandleChatCommand("background")
    harness.assert_nil(ok)
    harness.assert_equal("unknown command", err)
    harness.assert_true(addon.mainFrame.backgroundCalibrator == nil)

    ok, err = addon:HandleChatCommand("bg")
    harness.assert_nil(ok)
    harness.assert_equal("unknown command", err)
    harness.assert_true(addon.mainFrame.backgroundCalibrator == nil)
  end,

  ["slash command prints copy-friendly sync diagnostics"] = function()
    wow.reset({
      ace3 = true,
      guildName = "Raid Bakery",
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    addon:OnEnable()

    harness.assert_true(addon:HandleChatCommand("syncdebug") == true)
    harness.assert_true(addon.__rpaLastChatOutput ~= nil)
    harness.assert_true(addon.__rpaLastChatOutput[1]:match("Rolling Pin Awards sync diagnostics") ~= nil)
    harness.assert_true(addon.__rpaLastChatOutput[2]:match("Guild:") ~= nil)
    harness.assert_true(addon.__rpaLastChatOutput[3]:match("Comm prefix:") ~= nil)
    harness.assert_true(table.concat(addon.__rpaLastChatOutput, "\n"):match("LibStub:") ~= nil)
    harness.assert_true(table.concat(addon.__rpaLastChatOutput, "\n"):match("ChatThrottleLib:") ~= nil)
  end,

  ["slash command opens the sync peers window"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      playerName = "Guildmaster",
      guildRankName = "Guild Master",
      guildRankIndex = 0,
    })

    local addon = wow.loadAddon()
    addon:OnInitialize()
    local guildKey = addon:GetActiveGuildContext().guildKey
    addon.db:RecordSyncPeer(guildKey, "Officerone-Stormrage", 1717336800)

    harness.assert_true(addon:HandleChatCommand("peers") == true)
    harness.assert_true(addon.mainFrame.syncPeersDialog.visible)
    harness.assert_equal("Sync Peers", addon.mainFrame.syncPeersDialog.titleLabel.text)

    addon.mainFrame.syncPeersDialog.closeButton:Click()

    harness.assert_false(addon.mainFrame.syncPeersDialog.visible)
    harness.assert_true(addon:HandleChatCommand("sync peers") == true)
    harness.assert_true(addon.mainFrame.syncPeersDialog.visible)
  end,

  ["minimap button uses custom icon and toggles the main frame"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_true(addon.minimapButton ~= nil)
    harness.assert_true(addon.minimapButton.button ~= nil)
    harness.assert_equal("Interface\\AddOns\\RollingPinAwards\\Media\\minimap-button.png", addon.minimapButton.button.iconTexture.texturePath)
    harness.assert_false(addon.mainFrame.frame.visible)

    addon.minimapButton.button:Click()

    harness.assert_true(addon.mainFrame.frame.visible)

    addon.minimapButton.button:Click()

    harness.assert_false(addon.mainFrame.frame.visible)
  end,

  ["minimap button anchors to the minimap ring and updates while dragged"] = function()
    wow.reset({ guildName = "Raid Bakery" })
    _G.Minimap = {
      frameLevel = 7,
      frameStrata = "MEDIUM",
      width = 160,
      children = {},
      GetWidth = function(self)
        return self.width
      end,
      GetCenter = function()
        return 400, 300
      end,
      GetEffectiveScale = function()
        return 1
      end,
    }
    local cursorX = 400
    local cursorY = 382
    _G.GetCursorPosition = function()
      return cursorX, cursorY
    end

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local minimapButton = addon.minimapButton.button
    harness.assert_equal(_G.Minimap, minimapButton.parent)
    harness.assert_equal(32, minimapButton.width)
    harness.assert_equal(32, minimapButton.height)
    harness.assert_equal(136477, minimapButton.highlightTexture)
    harness.assert_true(minimapButton.borderTexture ~= nil)
    harness.assert_equal("Interface\\Minimap\\MiniMap-TrackingBorder", minimapButton.borderTexture.texturePath)
    harness.assert_equal(54, minimapButton.borderTexture.width)
    harness.assert_equal(54, minimapButton.borderTexture.height)
    harness.assert_nil(minimapButton.backgroundTexture)
    harness.assert_equal(24, minimapButton.iconTexture.width)
    harness.assert_equal(24, minimapButton.iconTexture.height)
    harness.assert_equal("CENTER", minimapButton.iconTexture.point[1])
    harness.assert_equal(0, minimapButton.iconTexture.point[4])
    harness.assert_equal(1, minimapButton.iconTexture.point[5])
    harness.assert_true(minimapButton.movable)
    harness.assert_true(minimapButton.mouseEnabled)
    harness.assert_equal("LeftButton", minimapButton.dragButtons[1])
    harness.assert_equal("CENTER", minimapButton.point[1])
    harness.assert_equal(_G.Minimap, minimapButton.point[2])
    harness.assert_equal("CENTER", minimapButton.point[3])
    harness.assert_true(math.abs((minimapButton.ringRadius or 0) - 85) < 0.001)

    minimapButton.scripts.OnDragStart(minimapButton)
    harness.assert_true(type(minimapButton.scripts.OnUpdate) == "function")
    minimapButton.scripts.OnUpdate(minimapButton)

    harness.assert_true(math.abs((minimapButton.minimapAngle or 0) - 90) < 0.001)
    harness.assert_true(math.abs((addon.db:GetLocalSettings().minimapAngle or 0) - 90) < 0.001)
    harness.assert_true(math.abs((minimapButton.point[4] or 0) - 0) < 0.001)
    harness.assert_true(math.abs((minimapButton.point[5] or 0) - 85) < 0.001)

    cursorX = 485
    cursorY = 300
    minimapButton.scripts.OnUpdate(minimapButton)

    harness.assert_true(math.abs((minimapButton.minimapAngle or 0) - 0) < 0.001)
    harness.assert_true(math.abs((addon.db:GetLocalSettings().minimapAngle or 0) - 0) < 0.001)
    harness.assert_true(math.abs((minimapButton.point[4] or 0) - 85) < 0.001)
    harness.assert_true(math.abs((minimapButton.point[5] or 0) - 0) < 0.001)

    minimapButton.scripts.OnDragStop(minimapButton)
    harness.assert_nil(minimapButton.scripts.OnUpdate)
  end,

  ["minimap launcher settings hide restore and normalize ring position"] = function()
    wow.reset({
      guildName = "Raid Bakery",
      savedVariables = {
        profile = {
          guildDatasets = {},
          localSettings = {
            minimapButtonShown = false,
            minimapAngle = 450,
          },
        },
      },
    })
    _G.Minimap = {
      frameLevel = 7,
      frameStrata = "MEDIUM",
      width = 160,
      children = {},
      GetWidth = function(self)
        return self.width
      end,
      GetCenter = function()
        return 400, 300
      end,
      GetEffectiveScale = function()
        return 1
      end,
    }

    local addon = wow.loadAddon()
    addon:OnInitialize()

    local minimapButton = addon.minimapButton.button
    harness.assert_false(minimapButton.visible)
    harness.assert_equal(90, addon.minimapButton:GetStoredAngle())

    addon.minimapButton:SetShown(true)
    harness.assert_true(minimapButton.visible)
    harness.assert_equal(90, addon.db:GetMinimapAngle())
    harness.assert_true(math.abs((minimapButton.ringRadius or 0) - 85) < 0.001)
    harness.assert_true(math.abs((minimapButton.point[4] or 0) - 0) < 0.001)
    harness.assert_true(math.abs((minimapButton.point[5] or 0) - 85) < 0.001)

    addon.minimapButton:SaveAngle(-45)
    harness.assert_equal(315, addon.db:GetMinimapAngle())
    addon.minimapButton:SetShown(false)
    harness.assert_false(minimapButton.visible)
    harness.assert_equal(315, addon.db:GetMinimapAngle())
  end,

  ["addon compartment click toggles main frame"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_true(type(_G.RollingPinAwards_OnAddonCompartmentClick) == "function")
    harness.assert_false(addon.mainFrame.frame.visible)

    _G.RollingPinAwards_OnAddonCompartmentClick()
    harness.assert_true(addon.mainFrame.frame.visible)
  end,
}

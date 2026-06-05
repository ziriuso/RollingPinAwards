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

  ["slash command toggles the background calibration window"] = function()
    wow.reset({ guildName = "Raid Bakery" })

    local addon = wow.loadAddon()
    addon:OnInitialize()

    harness.assert_true(addon:HandleChatCommand("background") == true)
    harness.assert_true(addon.mainFrame.backgroundCalibrator ~= nil)
    harness.assert_true(addon.mainFrame.backgroundCalibrator.visible)
    harness.assert_equal("Interface\\AddOns\\RollingPinAwards\\Media\\addon-background.png", addon.mainFrame.backgroundCalibrator.backgroundArt.texturePath)
    harness.assert_equal(1000, addon.mainFrame.backgroundCalibrator.width)
    harness.assert_equal(925, addon.mainFrame.backgroundCalibrator.height)
    harness.assert_equal(1000, addon.mainFrame.backgroundCalibrator.backgroundArt.width)
    harness.assert_equal(925, addon.mainFrame.backgroundCalibrator.backgroundArt.height)
    harness.assert_true(addon.mainFrame.backgroundCalibrator.mouseEnabled)
    harness.assert_true(addon.mainFrame.backgroundCalibrator.movable)
    harness.assert_true(addon.mainFrame.backgroundCalibrator.resizable)
    harness.assert_equal("BACKGROUND", addon.mainFrame.backgroundCalibrator.frameStrata)
    harness.assert_true((addon.mainFrame.backgroundCalibrator.frameLevel or 0) < (addon.mainFrame.frame.frameLevel or 1))
    harness.assert_true(type(addon.mainFrame.backgroundCalibrator.resizeHandle.scripts.OnMouseDown) == "function")

    addon.mainFrame.backgroundCalibrator.resizeHandle.scripts.OnMouseDown(addon.mainFrame.backgroundCalibrator.resizeHandle)

    harness.assert_true(addon.mainFrame.backgroundCalibrator.sizing)

    harness.assert_true(addon:HandleChatCommand("bg") == true)
    harness.assert_false(addon.mainFrame.backgroundCalibrator.visible)
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
      children = {},
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
    harness.assert_true(minimapButton.movable)
    harness.assert_true(minimapButton.mouseEnabled)
    harness.assert_equal("LeftButton", minimapButton.dragButtons[1])
    harness.assert_equal("CENTER", minimapButton.point[1])
    harness.assert_equal(_G.Minimap, minimapButton.point[2])
    harness.assert_equal("CENTER", minimapButton.point[3])
    harness.assert_true(math.abs((minimapButton.ringRadius or 0) - 82) < 0.001)

    minimapButton.scripts.OnDragStart(minimapButton)
    harness.assert_true(type(minimapButton.scripts.OnUpdate) == "function")
    minimapButton.scripts.OnUpdate(minimapButton)

    harness.assert_true(math.abs((minimapButton.minimapAngle or 0) - 90) < 0.001)
    harness.assert_true(math.abs((addon.db:GetLocalSettings().minimapAngle or 0) - 90) < 0.001)
    harness.assert_true(math.abs((minimapButton.point[4] or 0) - 0) < 0.001)
    harness.assert_true(math.abs((minimapButton.point[5] or 0) - 82) < 0.001)

    cursorX = 482
    cursorY = 300
    minimapButton.scripts.OnUpdate(minimapButton)

    harness.assert_true(math.abs((minimapButton.minimapAngle or 0) - 0) < 0.001)
    harness.assert_true(math.abs((addon.db:GetLocalSettings().minimapAngle or 0) - 0) < 0.001)
    harness.assert_true(math.abs((minimapButton.point[4] or 0) - 82) < 0.001)
    harness.assert_true(math.abs((minimapButton.point[5] or 0) - 0) < 0.001)

    minimapButton.scripts.OnDragStop(minimapButton)
    harness.assert_nil(minimapButton.scripts.OnUpdate)
  end,
}

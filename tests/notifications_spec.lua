local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

local REGULAR_FONT = "Interface\\AddOns\\RollingPinAwards\\Media\\Fonts\\Roboto-Regular.ttf"
local BOLD_FONT = "Interface\\AddOns\\RollingPinAwards\\Media\\Fonts\\Roboto-Bold.ttf"
local TOAST_BACKGROUND = { 224 / 255, 188 / 255, 137 / 255, 0.5 }
local SOLID_BACKDROP = "Interface\\Buttons\\WHITE8x8"

local function assert_backdrop_color(frame, color)
  harness.assert_true(frame.backdrop ~= nil)
  harness.assert_equal(SOLID_BACKDROP, frame.backdrop.bgFile)
  harness.assert_equal(false, frame.backdrop.tile)
  harness.assert_true(frame.backdropColor ~= nil)
  harness.assert_equal(color[1], frame.backdropColor.red)
  harness.assert_equal(color[2], frame.backdropColor.green)
  harness.assert_equal(color[3], frame.backdropColor.blue)
  harness.assert_equal(color[4], frame.backdropColor.alpha)
end

local function setupPlayer(seed)
  seed = seed or {}
  seed.nativeComm = seed.nativeComm ~= false
  seed.guildName = seed.guildName or "Raid Bakery"
  seed.playerName = seed.playerName or "Bakerone"
  seed.guildRankName = seed.guildRankName or "Member"
  seed.guildRankIndex = seed.guildRankIndex or 5
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
  addon.db:UpsertRankPermission(addon:GetActiveGuildContext().guildKey, 1, {
    rankIndex = 1,
    rankName = "Officer",
    canCreateDirectAwards = true,
    canManageNominations = true,
    canDeleteAwards = false,
    canManageAddonPermissions = false,
    lastModifiedAt = 1717336700,
    lastModifiedBy = "Guildmaster-Stormrage",
  })

  return addon
end

local function dispatchRemoteAward(addon, overrides)
  local guildKey = addon:GetActiveGuildContext().guildKey
  local payload = {
    guildKey = guildKey,
    awardId = "award:remote:1",
    awardName = "The Golden Rolling Pin",
    awardType = "golden",
    recipient = "Bakerone-Stormrage",
    player = "Bakerone-Stormrage",
    reason = "Saved the pull from certain doom",
    awardedBy = "Officerone-Stormrage",
    source = "direct",
    createdAt = 1717336800,
    lastModifiedAt = 1717336800,
    lastModifiedBy = "Officerone-Stormrage",
  }

  for key, value in pairs(overrides or {}) do
    payload[key] = value
  end

  return addon.sync:DispatchEnvelope({
    payloadType = "award",
    payload = payload,
  }, "GUILD", "Officerone-Stormrage")
end

local function dispatchRemoteNomination(addon)
  local guildKey = addon:GetActiveGuildContext().guildKey

  return addon.sync:DispatchEnvelope({
    payloadType = "nomination",
    payload = {
      guildKey = guildKey,
      nominationId = "nom:remote:1",
      nominee = "Moonrustle-Stormrage",
      reason = "Kept the feast table stocked",
      awardType = "golden",
      status = "pending",
      nominatedBy = "Officerone-Stormrage",
      createdAt = 1717336800,
      lastModifiedAt = 1717336800,
      lastModifiedBy = "Officerone-Stormrage",
    },
  }, "GUILD", "Officerone-Stormrage")
end

return {
  ["accepted inbound award for current player shows award type toast"] = function()
    local addon = setupPlayer()

    local accepted = dispatchRemoteAward(addon)

    harness.assert_true(accepted)
    harness.assert_true(addon.toast.frame.visible)
    harness.assert_equal(
      "Interface\\AddOns\\RollingPinAwards\\Media\\golden-rolling-pin.png",
      addon.toast.frame.icon.texturePath
    )
    harness.assert_equal("You've Received a Golden Rolling Pin", addon.toast.frame.titleLabel.text)
    harness.assert_equal("Saved the pull from certain doom", addon.toast.frame.reasonLabel.text)
    assert_backdrop_color(addon.toast.frame, TOAST_BACKGROUND)
    harness.assert_equal("CENTER", addon.toast.frame.titleLabel.justifyH)
    harness.assert_equal("CENTER", addon.toast.frame.reasonLabel.justifyH)
    harness.assert_equal(BOLD_FONT, addon.toast.frame.titleLabel.fontFile)
    harness.assert_equal(REGULAR_FONT, addon.toast.frame.reasonLabel.fontFile)
    harness.assert_true(addon.__rpaLastChatOutput[#addon.__rpaLastChatOutput]:match("Golden Rolling Pin awarded to Bakerone") ~= nil)
  end,

  ["accepted inbound award toast only shows once across duplicate sync and reload"] = function()
    local addon = setupPlayer()
    local shown = 0
    local originalShowAwardToast = addon.toast.ShowAwardToast
    addon.toast.ShowAwardToast = function(toast, award)
      shown = shown + 1
      return originalShowAwardToast(toast, award)
    end

    harness.assert_true(dispatchRemoteAward(addon, {
      awardId = "award:remote:once",
    }))
    harness.assert_true(dispatchRemoteAward(addon, {
      awardId = "award:remote:once",
    }))
    harness.assert_equal(1, shown)

    local savedVariables = addon.db.storage
    local reloaded = setupPlayer({
      savedVariables = savedVariables,
    })
    local reloadedShown = 0
    local reloadedOriginalShowAwardToast = reloaded.toast.ShowAwardToast
    reloaded.toast.ShowAwardToast = function(toast, award)
      reloadedShown = reloadedShown + 1
      return reloadedOriginalShowAwardToast(toast, award)
    end

    harness.assert_true(dispatchRemoteAward(reloaded, {
      awardId = "award:remote:once",
    }))
    harness.assert_equal(0, reloadedShown)
    harness.assert_true(reloaded.db:HasSeenAwardToast("award:remote:once"))
    harness.assert_true(reloaded.db:HasSeenAwardChat("award:remote:once"))
  end,

  ["accepted inbound award announces in chat for non-recipient guild members"] = function()
    local addon = setupPlayer({
      playerName = "Spectator",
      guildMembers = {
        {
          name = "Spectator-Stormrage",
          rankName = "Member",
          rankIndex = 5,
        },
        {
          name = "Bakerone-Stormrage",
          rankName = "Member",
          rankIndex = 5,
        },
        {
          name = "Officerone-Stormrage",
          rankName = "Officer",
          rankIndex = 1,
        },
      },
    })

    harness.assert_true(dispatchRemoteAward(addon, {
      awardId = "award:remote:spectator",
      awardType = "burnt",
      recipient = "Bakerone-Stormrage",
      player = "Bakerone-Stormrage",
      reason = "Pulled the boss",
    }))

    local chatText = table.concat(addon.__rpaLastChatOutput or {}, "\n")
    harness.assert_true(chatText:match("Burnt Rolling Pin awarded to Bakerone") ~= nil)
    harness.assert_true(chatText:match("Pulled the boss") ~= nil)
    harness.assert_true(addon.toast.frame == nil or addon.toast.frame.visible == false)
  end,

  ["local direct award announces in chat and marks the award chat seen"] = function()
    local addon = setupPlayer({
      guildRankName = "Officer",
      guildRankIndex = 1,
    })

    local award = addon.awards:CreateDirectAward("Bakerone-Stormrage", "Saved the pull", "golden")

    harness.assert_true(award ~= nil)
    local chatText = table.concat(addon.__rpaLastChatOutput or {}, "\n")
    harness.assert_true(chatText:match("Golden Rolling Pin awarded to Bakerone") ~= nil)
    harness.assert_true(addon.db:HasSeenAwardChat(award.awardId))
  end,

  ["disabled reward toasts suppress accepted inbound award popup"] = function()
    local addon = setupPlayer()

    addon.db:SetToastsEnabled(false)
    local accepted = dispatchRemoteAward(addon, {
      awardId = "award:remote:disabled",
      awardType = "burnt",
      reason = "Pulled the boss while fishing",
    })

    harness.assert_true(accepted)
    harness.assert_true(addon.toast.frame == nil or addon.toast.frame.visible == false)
  end,

  ["settings gear opens settings page and persists toast controls"] = function()
    local addon = setupPlayer()

    addon.mainFrame:EnsureRendered()
    addon.mainFrame.settingsGearButton:Click()

    local panel = addon.mainFrame.settingsPanel
    harness.assert_true(panel.visible)
    harness.assert_equal("Settings", addon.mainFrame.contentPanel.titleText.text)
    harness.assert_true(panel.toastsCheck:GetChecked())

    panel.toastsCheck:Click()
    harness.assert_false(addon.db:GetLocalSettings().toastsEnabled)

    panel.toastsCheck:Click()
    harness.assert_true(addon.db:GetLocalSettings().toastsEnabled)
  end,

  ["settings page adjusts and applies addon scale"] = function()
    local addon = setupPlayer()

    addon.mainFrame:EnsureRendered()
    addon.mainFrame.settingsGearButton:Click()

    local panel = addon.mainFrame.settingsPanel
    harness.assert_true(panel.visible)
    harness.assert_true(panel.addonScaleSlider ~= nil)
    harness.assert_true(panel.addonScaleDecreaseButton ~= nil)
    harness.assert_true(panel.addonScaleIncreaseButton ~= nil)
    harness.assert_true(panel.minimapButtonCheck ~= nil)
    harness.assert_nil(panel.addonCompartmentCheck)
    harness.assert_equal(0.5, panel.addonScaleSlider.minValue)
    harness.assert_equal(0.8, addon.db:GetLocalSettings().addonScale)
    harness.assert_equal("80%", panel.addonScaleValueLabel.text)

    panel.addonScaleIncreaseButton:Click()

    harness.assert_equal(0.85, addon.db:GetLocalSettings().addonScale)
    harness.assert_equal(0.85, addon.mainFrame.frame.scale)
    harness.assert_equal("85%", panel.addonScaleValueLabel.text)

    panel.addonScaleDecreaseButton:Click()

    harness.assert_equal(0.8, addon.db:GetLocalSettings().addonScale)
    harness.assert_equal("80%", panel.addonScaleValueLabel.text)

    for _ = 1, 10 do
      panel.addonScaleDecreaseButton:Click()
    end
    harness.assert_equal(0.5, addon.db:GetLocalSettings().addonScale)
    harness.assert_equal("50%", panel.addonScaleValueLabel.text)

    panel.addonScaleSlider:SetValue(1.13)

    harness.assert_equal(1.15, addon.db:GetLocalSettings().addonScale)
    harness.assert_equal(1.15, addon.mainFrame.frame.scale)
    harness.assert_equal("115%", panel.addonScaleValueLabel.text)
  end,

  ["settings page toggles local launcher preferences"] = function()
    local addon = setupPlayer()

    addon.mainFrame:EnsureRendered()
    addon.mainFrame.settingsGearButton:Click()

    local panel = addon.mainFrame.settingsPanel
    harness.assert_equal("Minimap", panel.launcherSection.titleText.text)
    harness.assert_equal(230, panel.launcherSection.width)
    harness.assert_true((panel.reportingSection.point[4] or 0) >= (panel.launcherSection.point[4] or 0) + panel.launcherSection.width + 20)
    harness.assert_equal(12, panel.minimapButtonCheck.label.fontHeight)
    harness.assert_true(panel.minimapButtonCheck:GetChecked())
    harness.assert_true(addon.minimapButton.button.visible)

    panel.minimapButtonCheck:Click()
    harness.assert_false(addon.db:IsMinimapButtonShown())
    harness.assert_false(addon.minimapButton.button.visible)

    panel.minimapButtonCheck:Click()
    harness.assert_true(addon.db:IsMinimapButtonShown())
    harness.assert_true(addon.minimapButton.button.visible)

  end,

  ["settings page saves local reporting filter controls"] = function()
    local addon = setupPlayer()

    addon.mainFrame:EnsureRendered()
    addon.mainFrame.settingsGearButton:Click()

    local panel = addon.mainFrame.settingsPanel
    harness.assert_nil(panel.reportingAllTimeButton)
    harness.assert_nil(panel.reportingCustomButton)
    harness.assert_nil(panel.reportingLabelInput)
    harness.assert_true(panel.reportingStartInput ~= nil)
    harness.assert_true(panel.reportingStartCalendarButton ~= nil)
    harness.assert_true(panel.reportingEndInput ~= nil)
    harness.assert_true(panel.reportingEndCalendarButton ~= nil)
    harness.assert_true(panel.reportingSaveButton ~= nil)
    harness.assert_true(panel.reportingClearButton ~= nil)

    panel.reportingStartInput:SetText("2024-06-10")
    panel.reportingStartCalendarButton:Click()
    harness.assert_true(panel.reportingCalendarDialog.visible)
    harness.assert_equal("2024-06", panel.reportingCalendarDialog.monthLabel.text)
    harness.assert_equal("10", panel.reportingCalendarDialog.dayButtonsByDay[10].label.text)
    harness.assert_true((panel.reportingCalendarDialog.dayButtonsByDay[10].label.width or 0) >= 20)
    harness.assert_equal("30", panel.reportingCalendarDialog.dayButtonsByDay[30].label.text)
    harness.assert_true((panel.reportingCalendarDialog.dayButtonsByDay[30].label.width or 0) >= 20)
    panel.reportingCalendarDialog.dayButtonsByDay[15]:Click()
    harness.assert_equal("2024-06-15", panel.reportingStartInput:GetText())

    panel.reportingStartInput:SetText("2024-06-01")
    panel.reportingEndInput:SetText("2024-06-30")
    panel.reportingSaveButton:Click()

    local filter = addon.db:GetReportingFilter()
    harness.assert_equal("custom", filter.mode)
    harness.assert_equal("Custom Range", filter.label)
    harness.assert_true(type(filter.startsAt) == "number")
    harness.assert_true(type(filter.endsAt) == "number")
    harness.assert_true(filter.startsAt <= filter.endsAt)
    harness.assert_equal("Reporting filter saved.", panel.reportingStatusLabel.text)

    panel.reportingClearButton:Click()

    filter = addon.db:GetReportingFilter()
    harness.assert_equal("all_time", filter.mode)
    harness.assert_equal("All Time", filter.label)
    harness.assert_nil(filter.startsAt)
    harness.assert_nil(filter.endsAt)
    harness.assert_equal("", panel.reportingStartInput:GetText())
    harness.assert_equal("", panel.reportingEndInput:GetText())
  end,

  ["settings page adjusts reward toast duration"] = function()
    local addon = setupPlayer()

    addon.mainFrame:EnsureRendered()
    addon.mainFrame.settingsGearButton:Click()

    local panel = addon.mainFrame.settingsPanel
    harness.assert_true(panel.visible)
    harness.assert_equal(7, addon.db:GetLocalSettings().toastDurationSeconds)
    harness.assert_equal("7 seconds", panel.toastDurationValueLabel.text)

    panel.toastDurationIncreaseButton:Click()
    harness.assert_equal(8, addon.db:GetLocalSettings().toastDurationSeconds)
    harness.assert_equal("8 seconds", panel.toastDurationValueLabel.text)

    panel.toastDurationDecreaseButton:Click()
    panel.toastDurationDecreaseButton:Click()
    harness.assert_equal(6, addon.db:GetLocalSettings().toastDurationSeconds)
    harness.assert_equal("6 seconds", panel.toastDurationValueLabel.text)

    for _ = 1, 10 do
      panel.toastDurationDecreaseButton:Click()
    end
    harness.assert_equal(3, addon.db:GetLocalSettings().toastDurationSeconds)
    harness.assert_equal("3 seconds", panel.toastDurationValueLabel.text)

    for _ = 1, 20 do
      panel.toastDurationIncreaseButton:Click()
    end
    harness.assert_equal(15, addon.db:GetLocalSettings().toastDurationSeconds)
    harness.assert_equal("15 seconds", panel.toastDurationValueLabel.text)
  end,

  ["reward toast auto-hide uses saved duration setting"] = function()
    local addon = setupPlayer()
    local timerDelay

    _G.C_Timer = {
      After = function(delay)
        timerDelay = delay
      end,
    }

    addon.db:SetToastDurationSeconds(11)
    dispatchRemoteAward(addon, {
      awardId = "award:remote:duration",
      reason = "Timer preview",
    })

    harness.assert_true(addon.toast.frame.visible)
    harness.assert_equal(11, timerDelay)
  end,

  ["settings anchor mode saves toast anchor on right click"] = function()
    local addon = setupPlayer()

    addon.mainFrame:EnsureRendered()
    addon.mainFrame.settingsGearButton:Click()
    addon.mainFrame.settingsPanel.anchorButton:Click()

    local anchor = addon.toast.anchorFrame
    harness.assert_true(anchor.visible)
    harness.assert_true(anchor.movable)
    harness.assert_equal("LeftButton", anchor.dragButtons[1])
    assert_backdrop_color(anchor, TOAST_BACKGROUND)

    anchor:ClearAllPoints()
    anchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 25, -35)
    anchor:Click("RightButton")

    local savedAnchor = addon.db:GetLocalSettings().toastAnchor
    harness.assert_false(anchor.visible)
    harness.assert_equal("TOPLEFT", savedAnchor.point)
    harness.assert_equal("TOPLEFT", savedAnchor.relativePoint)
    harness.assert_equal(25, savedAnchor.x)
    harness.assert_equal(-35, savedAnchor.y)
  end,

  ["pending nominations write chat reminders on login and inbound sync"] = function()
    local addon = setupPlayer()
    local guildKey = addon:GetActiveGuildContext().guildKey

    addon.db:UpsertNomination(guildKey, {
      guildKey = guildKey,
      nominationId = "nom:login:1",
      nominee = "Burny-Stormrage",
      reason = "Pulled the boss while fishing",
      awardType = "burnt",
      status = "pending",
      nominatedBy = "Officerone-Stormrage",
      createdAt = 1717336790,
      lastModifiedAt = 1717336790,
      lastModifiedBy = "Officerone-Stormrage",
    })

    addon:OnEnable()
    harness.assert_true((_G.__RPA_TEST_STATE.chatMessages[1] or ""):match("1 pending nomination") ~= nil)
    harness.assert_true((_G.__RPA_TEST_STATE.chatMessages[1] or ""):match("/rpa") ~= nil)

    local beforeInbound = #_G.__RPA_TEST_STATE.chatMessages
    local accepted = dispatchRemoteNomination(addon)

    harness.assert_true(accepted)
    harness.assert_true(#_G.__RPA_TEST_STATE.chatMessages > beforeInbound)
    harness.assert_true(_G.__RPA_TEST_STATE.chatMessages[#_G.__RPA_TEST_STATE.chatMessages]:match("New Golden Rolling Pin nomination") ~= nil)
  end,

  ["reward toasts queue during combat and flush after combat ends"] = function()
    local addon = setupPlayer()

    _G.InCombatLockdown = function()
      return true
    end

    local accepted = dispatchRemoteAward(addon, {
      awardId = "award:remote:combat",
      reason = "Saved the pull during combat",
    })

    harness.assert_true(accepted)
    harness.assert_true(addon.toast.frame == nil or addon.toast.frame.visible == false)
    harness.assert_equal(1, #(addon.toast.queuedAwards or {}))

    _G.InCombatLockdown = function()
      return false
    end
    wow.fireEvent("PLAYER_REGEN_ENABLED")

    harness.assert_true(addon.toast.frame.visible)
    harness.assert_equal("Saved the pull during combat", addon.toast.frame.reasonLabel.text)
    harness.assert_equal(0, #(addon.toast.queuedAwards or {}))
  end,

  ["reward toast close button hides the visible toast"] = function()
    local addon = setupPlayer()

    dispatchRemoteAward(addon, {
      awardId = "award:remote:close",
      reason = "Close button preview",
    })

    harness.assert_true(addon.toast.frame.visible)
    harness.assert_true(addon.toast.frame.closeButton ~= nil)

    addon.toast.frame.closeButton:Click()

    harness.assert_false(addon.toast.frame.visible)
  end,
}

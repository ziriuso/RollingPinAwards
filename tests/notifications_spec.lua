local harness = require("tests.TestHarness")
local wow = require("tests.WoWStubs")

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
    harness.assert_equal("CENTER", addon.toast.frame.titleLabel.justifyH)
    harness.assert_equal("CENTER", addon.toast.frame.reasonLabel.justifyH)
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

  ["settings anchor mode saves toast anchor on right click"] = function()
    local addon = setupPlayer()

    addon.mainFrame:EnsureRendered()
    addon.mainFrame.settingsGearButton:Click()
    addon.mainFrame.settingsPanel.anchorButton:Click()

    local anchor = addon.toast.anchorFrame
    harness.assert_true(anchor.visible)
    harness.assert_true(anchor.movable)
    harness.assert_equal("LeftButton", anchor.dragButtons[1])

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
    harness.assert_true(_G.__RPA_TEST_STATE.chatMessages[#_G.__RPA_TEST_STATE.chatMessages]:match("New Rolling Pin nomination") ~= nil)
  end,
}

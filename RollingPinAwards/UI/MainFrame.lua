local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

if not RPA.UIStyles then
  dofile("RollingPinAwards/UI/Styles.lua")
end

if not RPA.UIComponents then
  dofile("RollingPinAwards/UI/Components.lua")
end

if not RPA.UITabs or not RPA.UITabs.dashboard then
  dofile("RollingPinAwards/UI/Tabs/Dashboard.lua")
  dofile("RollingPinAwards/UI/Tabs/Award.lua")
  dofile("RollingPinAwards/UI/Tabs/Nominations.lua")
  dofile("RollingPinAwards/UI/Tabs/History.lua")
  dofile("RollingPinAwards/UI/Tabs/Leaderboard.lua")
  dofile("RollingPinAwards/UI/Tabs/Admin.lua")
end

if not RPA.SettingsPage then
  dofile("RollingPinAwards/UI/SettingsPage.lua")
end

local Components = RPA.UIComponents or {}
local MainFrame = RPA.MainFrame or {}
local SettingsPage = RPA.SettingsPage or {}
local Styles = RPA.UIStyles or {}
local UITabs = RPA.UITabs or {}

RPA.MainFrame = MainFrame

function MainFrame:New(deps)
  local tabs = {}

  for _, tabId in ipairs(Styles.TabOrder or {}) do
    if UITabs[tabId] then
      tabs[#tabs + 1] = Components.MakeTab(UITabs[tabId])
    end
  end

  local obj = {
    addon = deps.addon,
    uiBridge = deps.uiBridge,
    tabs = tabs,
    activeTabId = tabs[1] and tabs[1].id or nil,
    frame = Components.CreateWindow({
      id = "RollingPinAwardsMainFrame",
      title = Styles.Window.title,
      subtitle = Styles.Window.subtitle,
      width = Styles.Window.width,
      height = Styles.Window.height,
    }),
    contentPanel = nil,
    settingsPanel = nil,
    showingSettings = false,
    tabPanels = {},
    tabButtons = {},
  }

  self.__index = self

  obj = setmetatable(obj, self)
  obj:ApplySavedScale()

  return obj
end

function MainFrame:ApplyScale(scale)
  local nextScale = tonumber(scale) or 1
  if not self.frame then
    return nextScale
  end

  if self.frame.SetScale then
    self.frame:SetScale(nextScale)
  else
    self.frame.scale = nextScale
  end

  return nextScale
end

function MainFrame:ApplySavedScale()
  local settings = self.addon and self.addon.db and self.addon.db:GetLocalSettings() or {}

  return self:ApplyScale(settings.addonScale or 0.8)
end

function MainFrame:DescribeActiveTab(viewModel)
  local tab = self:GetActiveTab()
  if tab and type(tab.describeViewModel) == "function" then
    return tab.describeViewModel(viewModel or {})
  end

  return {
    title = tab and tab.label or "",
    lines = {},
  }
end

function MainFrame:IsTabVisible(tab)
  if not tab then
    return false
  end

  if type(tab.isVisible) == "function" then
    return tab.isVisible(self.uiBridge) ~= false
  end

  return true
end

function MainFrame:RefreshTabVisibility()
  local fallbackTabId = nil
  local activeVisible = false

  for index, tab in ipairs(self.tabs) do
    local visible = self:IsTabVisible(tab)
    tab.visible = visible

    if visible and not fallbackTabId then
      fallbackTabId = tab.id
    end

    if visible and tab.id == self.activeTabId then
      activeVisible = true
    end

    if self.tabButtons[index] then
      Components.SetVisible(self.tabButtons[index], visible)
    end
  end

  if not activeVisible then
    self.activeTabId = fallbackTabId
  end

  if Components.LayoutTabButtons then
    Components.LayoutTabButtons(self.frame, self.tabButtons)
  end
end

function MainFrame:RenderActiveTab()
  if not self.contentPanel then
    return nil
  end

  self:RefreshTabVisibility()

  if Components.SetTabButtonSelected then
    for index, tab in ipairs(self.tabs) do
      Components.SetTabButtonSelected(self.tabButtons[index], tab.id == self.activeTabId)
    end
  end

  if self.showingSettings then
    for _, panel in pairs(self.tabPanels) do
      Components.SetVisible(panel, false)
    end

    if self.contentPanel.bodyText and self.contentPanel.bodyText.Hide then
      self.contentPanel.bodyText:Hide()
    end

    local panel = self:EnsureSettingsPanel()
    if SettingsPage.Refresh then
      SettingsPage:Refresh(panel, self)
    end
    Components.SetVisible(panel, true)
    if self.contentPanel.titleText then
      Components.SetText(self.contentPanel.titleText, "Settings")
    end

    return {
      title = "Settings",
      lines = {},
    }
  elseif self.settingsPanel then
    Components.SetVisible(self.settingsPanel, false)
  end

  local tab = self:GetActiveTab()
  if not tab then
    return nil
  end
  local content = self:DescribeActiveTab(self:GetActiveViewModel() or {})

  for tabId, panel in pairs(self.tabPanels) do
    Components.SetVisible(panel, tabId == self.activeTabId)
  end

  if tab and type(tab.buildPanel) == "function" then
    local panel = self.tabPanels[tab.id]
    if not panel then
      panel = tab.buildPanel(self.contentPanel.contentHost or self.contentPanel, self)
      self.tabPanels[tab.id] = panel
    end

    if type(tab.refreshPanel) == "function" then
      tab.refreshPanel(panel, self:GetActiveViewModel() or {}, self.uiBridge, self)
    end

    if self.contentPanel.bodyText and self.contentPanel.bodyText.Hide then
      self.contentPanel.bodyText:Hide()
    end
  else
    Components.RenderContent(self.contentPanel, content)
    if self.contentPanel.bodyText and self.contentPanel.bodyText.Show then
      self.contentPanel.bodyText:Show()
    end
  end

  if self.contentPanel.titleText then
    Components.SetText(self.contentPanel.titleText, content.title or (tab and tab.label) or "")
  end

  return content
end

function MainFrame:EnsureRendered()
  self:ApplySavedScale()

  if self.rendered then
    self:RenderActiveTab()
    return self.frame
  end

  for index, tab in ipairs(self.tabs) do
    self.tabButtons[index] = Components.CreateTabButton(self.frame, tab, index)
    Components.SetButtonHandler(self.tabButtons[index], function()
      self:SelectTab(tab.id)
    end)
  end

  self.contentPanel = Components.CreateContentPanel(self.frame, {
    id = "RollingPinAwardsContentPanel",
    title = "Content",
    width = (Styles.Window.width or 920) - 48,
    height = (Styles.Window.height or 736) - 190,
  })

  if Components.CreateIconButton then
    self.settingsGearButton = Components.CreateIconButton(self.frame, {
      id = "RollingPinAwardsSettingsGearButton",
      texture = (Styles.Media or {}).settingsGearIcon,
      width = 34,
      height = 34,
      anchor = "BOTTOMRIGHT",
      relativeFrame = self.frame.backgroundArt or self.frame,
      relativeTo = "BOTTOMRIGHT",
      x = -78,
      y = 70,
      tooltipText = "Settings",
      onClick = function()
        self:ShowSettingsPage()
      end,
    })
  end

  self.rendered = true
  self:RefreshTabVisibility()
  self:RenderActiveTab()

  return self.frame
end

function MainFrame:GetActiveTab()
  for _, tab in ipairs(self.tabs) do
    if tab.id == self.activeTabId then
      return tab
    end
  end

  return nil
end

function MainFrame:GetActiveViewModel()
  local tab = self:GetActiveTab()
  if not tab or type(tab.buildViewModel) ~= "function" or not self.uiBridge then
    return nil
  end

  return tab.buildViewModel(self.uiBridge)
end

function MainFrame:SelectTab(tabId)
  for _, tab in ipairs(self.tabs) do
    if tab.id == tabId and self:IsTabVisible(tab) then
      self.activeTabId = tabId
      self.showingSettings = false
      self:RenderActiveTab()
      return true
    end
  end

  return false
end

function MainFrame:EnsureSettingsPanel()
  if not self.settingsPanel and SettingsPage.Build then
    self.settingsPanel = SettingsPage:Build(self.contentPanel.contentHost or self.contentPanel, self)
  end

  return self.settingsPanel
end

function MainFrame:ShowSettingsPage()
  self:EnsureRendered()
  self.showingSettings = true
  self:RenderActiveTab()

  return true
end

function MainFrame:EnsureSyncPeersDialog()
  if self.syncPeersDialog then
    return self.syncPeersDialog
  end

  local colors = Styles.Colors or {}
  local parent = _G.UIParent or self.frame
  self.syncPeersDialog = Components.CreateModalWindow(parent, {
    id = "RollingPinAwardsSyncPeersDialog",
    title = "Sync Peers",
    width = 520,
    height = 380,
    closeStyle = "x",
    draggable = true,
    backdropColor = colors.modalFill,
  })

  self.syncPeersDialog.playerHeader = Components.CreateLabel(self.syncPeersDialog, {
    text = "Player",
    x = 32,
    y = -58,
    width = 240,
    justifyH = "LEFT",
    textRole = "cardHeader",
  })
  self.syncPeersDialog.lastSeenHeader = Components.CreateLabel(self.syncPeersDialog, {
    text = "Last Seen",
    x = 300,
    y = -58,
    width = 160,
    justifyH = "LEFT",
    textRole = "cardHeader",
  })
  self.syncPeersDialog.listSection = Components.CreateScrollableSection(self.syncPeersDialog, {
    id = "RollingPinAwardsSyncPeersSection",
    title = "",
    width = 472,
    height = 268,
    x = 24,
    y = -86,
    visibleRowCount = 7,
    rowHeight = 32,
    rowStartY = -14,
  })

  return self.syncPeersDialog
end

function MainFrame:RefreshSyncPeersDialog()
  local dialog = self:EnsureSyncPeersDialog()
  local viewModel = self.uiBridge and self.uiBridge:GetSyncPeersViewModel() or {
    rows = {},
  }
  local rows = viewModel.rows or {}

  if #rows == 0 then
    rows = {
      {
        emptyState = true,
      },
    }
  end

  Components.SetScrollableItems(dialog.listSection, rows, function(section, row)
    if row.emptyState then
      Components.AddListRow(section, {
        text = "No sync peers seen yet. Run /rpa sync now to ping online addon users.",
        rowHeight = 32,
        actions = {},
      })
      return
    end

    local listRow = Components.AddListRow(section, {
      text = "",
      rowHeight = 32,
      backdropTone = "rowHighlight",
      actions = {},
    })
    listRow.playerLabel = Components.CreateLabel(listRow, {
      text = row.shortPlayer or row.player or "",
      x = 14,
      y = 0,
      width = 220,
      justifyH = "LEFT",
      justifyV = "MIDDLE",
      textRole = "tableRow",
    })
    listRow.lastSeenLabel = Components.CreateLabel(listRow, {
      text = row.lastSeenText or "",
      x = 278,
      y = 0,
      width = 150,
      justifyH = "LEFT",
      justifyV = "MIDDLE",
      textRole = "tableRow",
    })
    if listRow.playerLabel.SetPoint then
      listRow.playerLabel:ClearAllPoints()
      listRow.playerLabel:SetPoint("LEFT", listRow, "LEFT", 14, 0)
    end
    if listRow.lastSeenLabel.SetPoint then
      listRow.lastSeenLabel:ClearAllPoints()
      listRow.lastSeenLabel:SetPoint("LEFT", listRow, "LEFT", 278, 0)
    end
  end)

  return dialog
end

function MainFrame:ShowSyncPeers()
  self:EnsureRendered()
  local dialog = self:RefreshSyncPeersDialog()
  Components.SetVisible(dialog, true)

  return true
end

function MainFrame:Toggle()
  self:EnsureRendered()
  Components.SetVisible(self.frame, not self.frame.visible)

  return self.frame.visible
end

function MainFrame:EnsureBackgroundCalibrator()
  if not self.backgroundCalibrator then
    local backgroundLayout = (Styles.Layout or {}).backgroundArt or {}
    self.backgroundCalibrator = Components.CreateBackgroundCalibrationWindow(self.frame, {
      id = "RollingPinAwardsBackgroundCalibrator",
      width = backgroundLayout.width or Styles.Window.width,
      height = backgroundLayout.height or Styles.Window.height,
    })
  end

  return self.backgroundCalibrator
end

function MainFrame:ToggleBackgroundCalibrator()
  local calibration = self:EnsureBackgroundCalibrator()
  Components.SetVisible(calibration, not calibration.visible)

  return calibration.visible
end

return RPA.MainFrame

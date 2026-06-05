local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

if not RPA.UIStyles then
  dofile("UI/Styles.lua")
end

if not RPA.UIComponents then
  dofile("UI/Components.lua")
end

if not RPA.UITabs or not RPA.UITabs.dashboard then
  dofile("UI/Tabs/Dashboard.lua")
  dofile("UI/Tabs/Award.lua")
  dofile("UI/Tabs/Nominations.lua")
  dofile("UI/Tabs/History.lua")
  dofile("UI/Tabs/Leaderboard.lua")
  dofile("UI/Tabs/Admin.lua")
end

if not RPA.SettingsPage then
  dofile("UI/SettingsPage.lua")
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

  return setmetatable(obj, self)
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

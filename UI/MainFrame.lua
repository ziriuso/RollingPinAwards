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
  dofile("UI/Tabs/Settings.lua")
  dofile("UI/Tabs/Admin.lua")
end

local Components = RPA.UIComponents or {}
local MainFrame = RPA.MainFrame or {}
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
      width = Styles.Window.width,
      height = Styles.Window.height,
    }),
    contentPanel = nil,
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

function MainFrame:RenderActiveTab()
  if not self.contentPanel then
    return nil
  end

  local tab = self:GetActiveTab()
  local content = self:DescribeActiveTab(self:GetActiveViewModel() or {})

  for tabId, panel in pairs(self.tabPanels) do
    Components.SetVisible(panel, tabId == self.activeTabId)
  end

  if tab and type(tab.buildPanel) == "function" then
    local panel = self.tabPanels[tab.id]
    if not panel then
      panel = tab.buildPanel(self.contentPanel, self)
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
    height = (Styles.Window.height or 680) - 120,
  })

  self.rendered = true
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
    if tab.id == tabId then
      self.activeTabId = tabId
      self:RenderActiveTab()
      return true
    end
  end

  return false
end

function MainFrame:Toggle()
  self:EnsureRendered()
  Components.SetVisible(self.frame, not self.frame.visible)

  return self.frame.visible
end

return RPA.MainFrame

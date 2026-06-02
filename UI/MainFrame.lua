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
  }

  self.__index = self

  return setmetatable(obj, self)
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
      return true
    end
  end

  return false
end

function MainFrame:Toggle()
  self.frame.visible = not self.frame.visible

  return self.frame.visible
end

return RPA.MainFrame

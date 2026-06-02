local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
RPA.UITabs = UITabs

UITabs.history = {
  id = "history",
  label = "History",
  BuildViewModel = function(bridge)
    return {
      awards = bridge:GetPublicHistoryViewModel(),
    }
  end,
  DescribeViewModel = function(viewModel)
    local lines = {
      ("Approved awards: %d"):format(#(viewModel.awards or {})),
    }

    for _, award in ipairs(viewModel.awards or {}) do
      lines[#lines + 1] = ("%s - %s"):format(award.recipient, award.reason)
    end

    if #lines == 1 then
      lines[#lines + 1] = "No awards recorded yet."
    end

    return {
      title = "History",
      lines = lines,
    }
  end,
  BuildPanel = function(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -44)
    panel:SetSize((parent.width or 820) - 24, (parent.height or 520) - 24)
    panel.listSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsHistoryList",
      title = "Approved Awards",
      width = 780,
      height = 430,
      x = 0,
      y = 0,
      visibleRowCount = 6,
      rowHeight = 54,
    })
    panel.statusLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = -438,
      width = 760,
      justifyH = "LEFT",
    })
    panel.confirmDialog = Components.CreateConfirmationDialog(panel, {
      id = "RollingPinAwardsHistoryDeleteConfirm",
      title = "Delete Award",
      message = "",
      confirmText = "Delete",
      cancelText = "Cancel",
    })

    return panel
  end,
  RefreshPanel = function(panel, viewModel, bridge, mainFrame)
    local awards = viewModel.awards or {}
    if #awards == 0 then
      awards = {
        {
          emptyState = true,
        },
      }
    end

    Components.SetScrollableItems(panel.listSection, awards, function(section, award)
      if award.emptyState then
        Components.AddListRow(section, {
          text = "No approved awards yet.",
          rowHeight = 32,
          actions = {},
        })
        return
      end

      local actions = {}
      if award.canDelete then
        actions[#actions + 1] = {
          text = "Delete",
          width = 62,
          onClick = function()
            panel.pendingDeleteAwardId = award.awardId
            Components.SetText(
              panel.confirmDialog.messageLabel,
              "Delete this award? If it came from a nomination, the linked nomination will also be deleted."
            )
            Components.SetButtonHandler(panel.confirmDialog.confirmButton, function()
              local ok, err = bridge:DeleteAward(panel.pendingDeleteAwardId)
              Components.SetVisible(panel.confirmDialog, false)
              Components.SetText(
                panel.statusLabel,
                ok and ("Deleted award for %s."):format(award.recipient)
                  or ("Unable to delete award: %s"):format(err or "unknown error")
              )
              panel.pendingDeleteAwardId = nil
              mainFrame:RenderActiveTab()
            end)
            Components.SetVisible(panel.confirmDialog, true)
          end,
        }
      end

      Components.AddListRow(section, {
        text = ("%s\n%s\nAwarded by %s"):format(award.recipient, award.reason, award.awardedBy),
        labelWidth = 640,
        rowHeight = 54,
        actions = actions,
      })
    end)
  end,
}

return UITabs.history

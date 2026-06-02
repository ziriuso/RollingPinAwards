local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
local Styles = RPA.UIStyles or {}
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
    local media = Styles.Media or {}
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -42)
    panel:SetSize((parent.width or 820) - 28, (parent.height or 520) - 56)

    panel.listSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsHistoryList",
      title = "Approved Awards",
      iconPath = media.awardIcon,
      iconWidth = 22,
      iconHeight = 22,
      width = 780,
      height = 290,
      x = 0,
      y = 0,
      visibleRowCount = 5,
      rowHeight = 56,
    })
    panel.statusSection = Components.CreateSection(panel, {
      id = "RollingPinAwardsHistoryStatusSection",
      title = "Archive Notes",
      iconPath = media.standardPinIcon,
      iconWidth = 20,
      iconHeight = 20,
      width = 780,
      height = 74,
      x = 0,
      y = -304,
    })
    panel.statusLabel = Components.CreateLabel(panel.statusSection, {
      text = "",
      x = 14,
      y = -38,
      width = 736,
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
          rowHeight = 40,
          actions = {},
        })
        return
      end

      local actions = {}
      if award.canDelete then
        actions[#actions + 1] = {
          text = "Delete",
          width = 72,
          variant = "secondary",
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
        text = ("%s\n%s\n%s  Awarded by %s"):format(
          award.recipient,
          award.reason,
          award.dateText or "Unknown date",
          award.awardedBy
        ),
        iconPath = award.awardIconPath,
        iconWidth = 18,
        iconHeight = 18,
        labelWidth = 620,
        rowHeight = 56,
        actions = actions,
      })
    end)

      Components.SetText(
        panel.statusLabel,
        panel.statusLabel.text ~= "" and panel.statusLabel.text
        or "This archive is visible to the guild and sorted by latest approved awards. Deleting an award also removes its linked nomination."
      )
  end,
}

return UITabs.history

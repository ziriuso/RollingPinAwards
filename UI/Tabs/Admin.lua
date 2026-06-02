local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
RPA.UITabs = UITabs

local function buildModerationText(row)
  local flagText = row.moderationFlagged and "Flagged" or "Review"

  return ("%s [%s]\nUpvotes: %d  Downvotes: %d  %s"):format(
    row.nominee,
    row.status,
    row.upvotes or 0,
    row.downvotes or 0,
    flagText
  )
end

UITabs.admin = {
  id = "admin",
  label = "Admin",
  IsVisible = function(bridge)
    return bridge:CanCurrentPlayerManageAddonPermissions()
  end,
  BuildViewModel = function(bridge)
    return {
      nominations = bridge:GetAdminNominationsViewModel(),
      canModerate = bridge:CanCurrentPlayerManageNominations(),
      permissions = bridge:GetRankPermissionsViewModel(),
    }
  end,
  DescribeViewModel = function(viewModel)
    local lines = {
      "Manage guild rank permissions for The Burnt Rolling Pin.",
      "Guild Master always retains full access.",
    }

    lines[#lines + 1] = ("Configured ranks: %d"):format(#((viewModel.permissions or {}).rows or {}))
    lines[#lines + 1] = ("Moderation queue: %d"):format(#(viewModel.nominations or {}))

    return {
      title = "Admin",
      lines = lines,
    }
  end,
  BuildPanel = function(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -44)
    panel:SetSize((parent.width or 820) - 24, (parent.height or 520) - 24)

    panel.rankSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsRankPermissionsSection",
      title = "Guild Rank Permissions",
      width = 780,
      height = 228,
      x = 0,
      y = 0,
      visibleRowCount = 5,
      rowHeight = 40,
    })
    panel.gmNote = Components.CreateLabel(panel, {
      text = "Rank 0 / Guild Master always has full access.",
      x = 0,
      y = -234,
      width = 760,
      justifyH = "LEFT",
    })
    panel.moderationSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsModerationSection",
      title = "Moderation Queue",
      width = 780,
      height = 170,
      x = 0,
      y = -264,
      visibleRowCount = 3,
      rowHeight = 48,
    })
    panel.statusLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = -444,
      width = 760,
      justifyH = "LEFT",
    })

    return panel
  end,
  RefreshPanel = function(panel, viewModel, bridge, mainFrame)
    local permissionRows = ((viewModel.permissions or {}).rows or {})

    if #permissionRows == 0 then
      permissionRows = {
        {
          emptyState = true,
        },
      }
    end

    Components.SetScrollableItems(panel.rankSection, permissionRows, function(section, row)
      if row.emptyState then
        Components.AddListRow(section, {
          text = "No guild ranks available yet.",
          rowHeight = 32,
          actions = {},
        })
        return
      end

      local permissionRow

      permissionRow = Components.AddPermissionMatrixRow(section, {
        rankName = row.rankName,
        canManageNominations = row.rankIndex == 0 or row.canManageNominations,
        canCreateDirectAwards = row.rankIndex == 0 or row.canCreateDirectAwards,
        canDeleteAwards = row.rankIndex == 0 or row.canDeleteAwards,
        canManageAddonPermissions = row.rankIndex == 0 or row.canManageAddonPermissions,
      })

      Components.SetButtonHandler(permissionRow.saveButton, function()
        local ok = bridge:SaveRankPermissions(row.rankIndex, row.rankName, {
          canManageNominations = permissionRow.manageNominationsCheck:GetChecked(),
          canCreateDirectAwards = permissionRow.createAwardsCheck:GetChecked(),
          canDeleteAwards = permissionRow.deleteAwardsCheck:GetChecked(),
          canManageAddonPermissions = permissionRow.manageAddonCheck:GetChecked(),
        })

        Components.SetText(
          panel.statusLabel,
          ok and ("Saved permissions for %s."):format(row.rankName)
            or ("Unable to save permissions for %s."):format(row.rankName)
        )
        mainFrame:RenderActiveTab()
      end)

      if row.rankIndex == 0 then
        if permissionRow.manageNominationsCheck.Disable then
          permissionRow.manageNominationsCheck:Disable()
          permissionRow.createAwardsCheck:Disable()
          permissionRow.deleteAwardsCheck:Disable()
          permissionRow.manageAddonCheck:Disable()
        end
        if permissionRow.saveButton.Disable then
          permissionRow.saveButton:Disable()
        end
      end
    end)

    local nominations = viewModel.nominations or {}
    if #nominations == 0 then
      nominations = {
        {
          emptyState = true,
        },
      }
    end

    Components.SetScrollableItems(panel.moderationSection, nominations, function(section, row)
      if row.emptyState then
        Components.AddListRow(section, {
          text = "No nominations to moderate.",
          rowHeight = 32,
          actions = {},
        })
        return
      end

      Components.AddListRow(section, {
        text = buildModerationText(row),
        labelWidth = 640,
        rowHeight = 48,
        actions = {},
      })
    end)
  end,
}

return UITabs.admin

local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
local Styles = RPA.UIStyles or {}
RPA.UITabs = UITabs

local function buildModerationText(row)
  local flagText = row.moderationFlagged and "Flagged" or "Review"

  return ("%s [%s]\n%s\nUpvotes: %d  Downvotes: %d  %s"):format(
    row.nominee,
    row.status,
    row.reason or "",
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
      aliases = bridge:GetAliasMappingsViewModel(),
    }
  end,
  DescribeViewModel = function(viewModel)
    local lines = {
      "Manage guild rank permissions for The Burnt Rolling Pin.",
      "Guild Master always retains full access.",
    }

    lines[#lines + 1] = ("Configured ranks: %d"):format(#((viewModel.permissions or {}).rows or {}))
    lines[#lines + 1] = ("Alias merges: %d"):format(#((viewModel.aliases or {}).rows or {}))
    lines[#lines + 1] = ("Moderation queue: %d"):format(#(viewModel.nominations or {}))

    return {
      title = "Admin",
      lines = lines,
    }
  end,
  BuildPanel = function(parent)
    local media = Styles.Media or {}
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -42)
    panel:SetSize((parent.width or 820) - 28, (parent.height or 520) - 34)

    panel.rankSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsRankPermissionsSection",
      title = "Guild Rank Permissions",
      iconPath = media.goldenrollingpin or media.leaderboardIcon,
      iconWidth = 22,
      iconHeight = 22,
      width = 780,
      height = 138,
      x = 0,
      y = 0,
      visibleRowCount = 2,
      rowHeight = 32,
    })
    panel.rankHeaderNomination = Components.CreateLabel(panel.rankSection, {
      text = "Nominations",
      x = 212,
      y = -30,
      width = 96,
      justifyH = "CENTER",
      font = "GameFontNormalSmall",
    })
    panel.rankHeaderAwards = Components.CreateLabel(panel.rankSection, {
      text = "Direct",
      x = 324,
      y = -30,
      width = 72,
      justifyH = "CENTER",
      font = "GameFontNormalSmall",
    })
    panel.rankHeaderDelete = Components.CreateLabel(panel.rankSection, {
      text = "Delete",
      x = 432,
      y = -30,
      width = 72,
      justifyH = "CENTER",
      font = "GameFontNormalSmall",
    })
    panel.rankHeaderAdmin = Components.CreateLabel(panel.rankSection, {
      text = "Admin",
      x = 540,
      y = -30,
      width = 72,
      justifyH = "CENTER",
      font = "GameFontNormalSmall",
    })
    panel.gmNote = Components.CreateLabel(panel, {
      text = "Rank 0 / Guild Master always has full access.",
      x = 0,
      y = -144,
      width = 760,
      justifyH = "LEFT",
    })
    panel.permissionHelpLabel = Components.CreateLabel(panel, {
      text = table.concat({
        "Manage Nominations: approve and reject pending nominations.",
        "Create Direct Awards: issue a direct verdict with no nomination.",
        "Delete Awards: remove awards and any linked nomination.",
        "Manage Addon Permissions/Settings: edit this matrix and access Admin.",
      }, "\n"),
      x = 0,
      y = -162,
      width = 760,
      justifyH = "LEFT",
      justifyV = "TOP",
      font = "GameFontHighlightSmall",
    })

    panel.aliasFormSection = Components.CreateSection(panel, {
      id = "RollingPinAwardsAliasFormSection",
      title = "Alias Merge Controls",
      iconPath = media.standardPinIcon,
      iconWidth = 20,
      iconHeight = 20,
      width = 780,
      height = 74,
      x = 0,
      y = -236,
    })
    panel.aliasLabel = Components.CreateLabel(panel.aliasFormSection, {
      text = "Alias",
      x = 14,
      y = -32,
      font = "GameFontNormalSmall",
    })
    panel.aliasInput = Components.CreateEditBox(panel.aliasFormSection, {
      width = 150,
      x = 14,
      y = -52,
    })
    panel.canonicalLabel = Components.CreateLabel(panel.aliasFormSection, {
      text = "Canonical Character",
      x = 180,
      y = -32,
      font = "GameFontNormalSmall",
    })
    panel.canonicalInput = Components.CreateEditBox(panel.aliasFormSection, {
      width = 230,
      x = 180,
      y = -52,
    })
    panel.aliasSaveButton = Components.CreateButton(panel.aliasFormSection, {
      text = "Add Merge",
      width = 144,
      height = 28,
      x = 426,
      y = -50,
      variant = "primary",
    })
    panel.aliasBrowseButton = Components.CreateButton(panel.aliasFormSection, {
      text = "View Alias Merges",
      width = 168,
      height = 28,
      x = 584,
      y = -50,
      variant = "secondary",
      onClick = function()
        Components.SetVisible(panel.aliasDialog, true)
      end,
    })
    panel.aliasSummaryLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = -320,
      width = 760,
      justifyH = "LEFT",
      font = "GameFontHighlightSmall",
    })
    panel.aliasDialog = Components.CreateModalWindow(panel, {
      id = "RollingPinAwardsAliasMappingsDialog",
      title = "Alias Merges",
      width = 640,
      height = 420,
      closeText = "Close",
    })
    panel.aliasDialog.listSection = Components.CreateScrollableSection(panel.aliasDialog, {
      id = "RollingPinAwardsAliasMappingsSection",
      title = "Active Alias Merges",
      iconPath = media.standardPinIcon,
      iconWidth = 18,
      iconHeight = 18,
      width = 600,
      height = 320,
      x = 16,
      y = -48,
      visibleRowCount = 6,
      rowHeight = 34,
    })

    panel.moderationSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsModerationSection",
      title = "Moderation Queue",
      iconPath = media.headerIcon,
      iconWidth = 20,
      iconHeight = 20,
      width = 780,
      height = 96,
      x = 0,
      y = -350,
      visibleRowCount = 1,
      rowHeight = 60,
    })
    panel.statusLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = -392,
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

      local permissionRow = Components.AddPermissionMatrixRow(section, {
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

    Components.SetButtonHandler(panel.aliasSaveButton, function()
      local aliasRow, err = bridge:SaveAliasMapping(
        panel.aliasInput:GetText(),
        panel.canonicalInput:GetText()
      )

      if aliasRow then
        Components.SetText(panel.statusLabel, ("Saved alias merge for %s."):format(aliasRow.aliasDisplay))
        Components.SetText(panel.aliasInput, "")
        Components.SetText(panel.canonicalInput, "")
      else
        Components.SetText(panel.statusLabel, ("Unable to save alias merge: %s"):format(err or "unknown error"))
      end

      mainFrame:RenderActiveTab()
    end)

    local aliasRows = ((viewModel.aliases or {}).rows or {})
    if #aliasRows == 0 then
      aliasRows = {
        {
          emptyState = true,
        },
      }
    end

    Components.SetText(panel.aliasSummaryLabel, ("Configured alias merges: %d"):format(#((viewModel.aliases or {}).rows or {})))

    Components.SetScrollableItems(panel.aliasDialog.listSection, aliasRows, function(section, row)
      if row.emptyState then
        Components.AddListRow(section, {
          text = "No alias merges configured.",
          rowHeight = 34,
          actions = {},
        })
        return
      end

      Components.AddListRow(section, {
        text = ("%s -> %s"):format(row.aliasDisplay or row.aliasKey or "", row.canonicalName or ""),
        labelWidth = 460,
        rowHeight = 34,
        actions = {
          {
            text = "Remove",
            width = 78,
            variant = "secondary",
            onClick = function()
              local ok, err = bridge:DeleteAliasMapping(row.aliasKey)
              Components.SetText(
                panel.statusLabel,
                ok and ("Removed alias merge for %s."):format(row.aliasDisplay or row.aliasKey or "")
                  or ("Unable to remove alias merge: %s"):format(err or "unknown error")
              )
              Components.SetVisible(panel.aliasDialog, false)
              mainFrame:RenderActiveTab()
            end,
          },
        },
      })
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
        iconPath = row.awardIconPath,
        iconWidth = 18,
        iconHeight = 18,
        labelWidth = 640,
        rowHeight = 60,
        actions = {},
      })
    end)

    if panel.statusLabel.text == "" then
      Components.SetText(panel.statusLabel, "Guild configuration changes sync through the admin path.")
    end
  end,
}

return UITabs.admin

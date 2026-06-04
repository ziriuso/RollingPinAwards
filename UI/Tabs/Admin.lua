local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
local Styles = RPA.UIStyles or {}
RPA.UITabs = UITabs

local function stripRealm(name)
  if type(name) ~= "string" then
    return name or "Unknown"
  end

  return name:match("^([^-]+)") or name
end

local function buildModerationText(row)
  local flagText = row.moderationFlagged and "Flagged" or "Review"

  return ("%s %s\n%s\nSubmitted by %s\nUpvotes: %d  Downvotes: %d  %s"):format(
    row.nominee,
    row.status,
    row.reason or "",
    stripRealm(row.nominatedBy),
    row.upvotes or 0,
    row.downvotes or 0,
    flagText
  )
end

local function countPendingNominations(nominations)
  local count = 0

  for _, nomination in ipairs(nominations or {}) do
    if nomination.status == "pending" then
      count = count + 1
    end
  end

  return count
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
    lines[#lines + 1] = ("Moderation queue: %d"):format(countPendingNominations(viewModel.nominations or {}))

    return {
      title = "Admin",
      lines = lines,
    }
  end,
  BuildPanel = function(parent)
    local layout = Styles.Layout or {}
    local media = Styles.Media or {}
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", layout.panelX or 59, layout.panelY or -42)
    panel:SetSize(layout.panelWidth or 762, (parent.height or 520) - 34)

    panel.rankSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsRankPermissionsSection",
      title = "Guild Rank Permissions",
      iconPath = media.leaderboardIcon,
      iconWidth = 22,
      iconHeight = 22,
      width = 762,
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
    panel.permissionHelpLabel = Components.CreateLabel(panel, {
      text = table.concat({
        "Nominations: approve and reject pending nominations.",
        "Direct: issue a direct verdict with no nomination.",
        "Delete: remove awards and any linked nomination.",
        "Admin: edit this matrix and access Admin.",
      }, "\n"),
      x = 0,
      y = -148,
      width = 742,
      justifyH = "LEFT",
      justifyV = "TOP",
      font = "GameFontHighlightSmall",
      fontSizeDelta = 2,
    })

    panel.aliasFormSection = Components.CreateSection(panel, {
      id = "RollingPinAwardsAliasFormSection",
      title = "Alias Merge Controls",
      iconPath = media.standardPinIcon,
      iconWidth = 20,
      iconHeight = 20,
      width = 762,
      height = 126,
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
      y = -58,
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
      y = -58,
    })
    panel.aliasSaveButton = Components.CreateButton(panel.aliasFormSection, {
      text = "Add Merge",
      width = 144,
      height = 28,
      x = 426,
      y = -56,
      variant = "primary",
    })
    panel.aliasBrowseButton = Components.CreateButton(panel.aliasFormSection, {
      text = "View Alias Merges",
      width = 168,
      height = 28,
      x = 584,
      y = -56,
      variant = "secondary",
      onClick = function()
        Components.SetVisible(panel.aliasDialog, true)
      end,
    })
    panel.aliasSuggestionButton = Components.CreateButton(panel.aliasFormSection, {
      text = "",
      width = 230,
      height = 20,
      x = 180,
      y = -88,
      variant = "secondary",
    })
    Components.SetVisible(panel.aliasSuggestionButton, false)
    panel.aliasSummaryLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = -374,
      width = 742,
      justifyH = "LEFT",
      font = "GameFontHighlightSmall",
      fontSizeDelta = 2,
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

    panel.moderationButton = Components.CreateButton(panel, {
      text = "Open Moderation Queue",
      width = 220,
      height = 34,
      x = 0,
      y = -398,
      variant = "secondary",
      onClick = function()
        Components.SetVisible(panel.moderationDialog, true)
      end,
    })
    panel.moderationDialog = Components.CreateModalWindow(panel, {
      id = "RollingPinAwardsModerationDialog",
      title = "Moderation Queue",
      width = 700,
      height = 430,
      closeText = "Close",
    })
    panel.moderationDialog.selectedFilter = panel.moderationDialog.selectedFilter or "pending"
    panel.moderationDialog.pendingFilterButton = Components.CreateButton(panel.moderationDialog, {
      text = "Pending",
      width = 92,
      height = 26,
      x = 16,
      y = -50,
      variant = "primary",
    })
    panel.moderationDialog.approvedFilterButton = Components.CreateButton(panel.moderationDialog, {
      text = "Approved",
      width = 98,
      height = 26,
      x = 116,
      y = -50,
      variant = "secondary",
    })
    panel.moderationDialog.rejectedFilterButton = Components.CreateButton(panel.moderationDialog, {
      text = "Rejected",
      width = 92,
      height = 26,
      x = 222,
      y = -50,
      variant = "secondary",
    })
    panel.moderationDialog.allFilterButton = Components.CreateButton(panel.moderationDialog, {
      text = "All",
      width = 70,
      height = 26,
      x = 322,
      y = -50,
      variant = "secondary",
    })
    panel.moderationDialog.listSection = Components.CreateScrollableSection(panel.moderationDialog, {
      id = "RollingPinAwardsModerationSection",
      title = "",
      width = 660,
      height = 292,
      x = 16,
      y = -84,
      visibleRowCount = 3,
      rowHeight = 72,
    })
    panel.statusLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = -454,
      width = 742,
      justifyH = "LEFT",
      fontSizeDelta = 2,
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
        rankFontSizeDelta = 2,
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

    local function refreshAliasSuggestion()
      local suggestions = bridge:GetGuildRosterNameSuggestions(panel.canonicalInput:GetText(), 1)
      local suggestion = suggestions and suggestions[1] or nil
      if suggestion and suggestion.name then
        panel.aliasSuggestionButton.suggestedName = suggestion.name
        Components.SetText(panel.aliasSuggestionButton, ("Use %s"):format(suggestion.name))
        Components.SetVisible(panel.aliasSuggestionButton, true)
      else
        panel.aliasSuggestionButton.suggestedName = nil
        Components.SetText(panel.aliasSuggestionButton, "")
        Components.SetVisible(panel.aliasSuggestionButton, false)
      end
    end

    if panel.canonicalInput.SetScript then
      panel.canonicalInput:SetScript("OnTextChanged", refreshAliasSuggestion)
    end
    Components.SetButtonHandler(panel.aliasSuggestionButton, function()
      if panel.aliasSuggestionButton.suggestedName then
        Components.SetText(panel.canonicalInput, panel.aliasSuggestionButton.suggestedName)
      end
      refreshAliasSuggestion()
    end)
    refreshAliasSuggestion()

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
        backdropTone = "rowHighlight",
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
    local selectedFilter = panel.moderationDialog.selectedFilter or "pending"
    local filteredNominations = {}
    for _, nomination in ipairs(nominations) do
      if selectedFilter == "all" or nomination.status == selectedFilter then
        filteredNominations[#filteredNominations + 1] = nomination
      end
    end

    if #filteredNominations == 0 then
      filteredNominations = {
        {
          emptyState = true,
        },
      }
    end

    Components.SetText(panel.moderationButton, ("Open Moderation Queue (%d)"):format(countPendingNominations(viewModel.nominations or {})))
    Components.SetButtonVariant(panel.moderationDialog.pendingFilterButton, selectedFilter == "pending" and "selected" or "secondary")
    Components.SetButtonVariant(panel.moderationDialog.approvedFilterButton, selectedFilter == "approved" and "selected" or "secondary")
    Components.SetButtonVariant(panel.moderationDialog.rejectedFilterButton, selectedFilter == "rejected" and "selected" or "secondary")
    Components.SetButtonVariant(panel.moderationDialog.allFilterButton, selectedFilter == "all" and "selected" or "secondary")

    Components.SetButtonHandler(panel.moderationDialog.pendingFilterButton, function()
      panel.moderationDialog.selectedFilter = "pending"
      mainFrame:RenderActiveTab()
    end)
    Components.SetButtonHandler(panel.moderationDialog.approvedFilterButton, function()
      panel.moderationDialog.selectedFilter = "approved"
      mainFrame:RenderActiveTab()
    end)
    Components.SetButtonHandler(panel.moderationDialog.rejectedFilterButton, function()
      panel.moderationDialog.selectedFilter = "rejected"
      mainFrame:RenderActiveTab()
    end)
    Components.SetButtonHandler(panel.moderationDialog.allFilterButton, function()
      panel.moderationDialog.selectedFilter = "all"
      mainFrame:RenderActiveTab()
    end)

    Components.SetScrollableItems(panel.moderationDialog.listSection, filteredNominations, function(section, row)
      if row.emptyState then
        Components.AddListRow(section, {
          text = "No nominations to moderate.",
          rowHeight = 32,
          actions = {},
        })
        return
      end

      local actions = {}
      if row.status == "pending" then
        actions[#actions + 1] = {
          text = "Approve",
          width = 74,
          onClick = function()
            bridge:ApproveNomination(row.nominationId)
            mainFrame:RenderActiveTab()
          end,
        }
        actions[#actions + 1] = {
          text = "Reject",
          width = 68,
          variant = "secondary",
          onClick = function()
            bridge:RejectNomination(row.nominationId)
            mainFrame:RenderActiveTab()
          end,
        }
      end

      Components.AddListRow(section, {
        text = buildModerationText(row),
        iconPath = row.awardIconPath,
        iconWidth = 18,
        iconHeight = 18,
        labelWidth = 470,
        rowHeight = 72,
        backdropTone = "rowHighlight",
        actionX = 506,
        actionColumns = 1,
        actions = actions,
      })
    end)

    if panel.statusLabel.text == "" then
      Components.SetText(panel.statusLabel, "Guild configuration changes sync through the admin path.")
    end
  end,
}

return UITabs.admin

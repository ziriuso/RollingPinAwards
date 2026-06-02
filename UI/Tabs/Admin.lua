local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
RPA.UITabs = UITabs

UITabs.admin = {
  id = "admin",
  label = "Admin",
  BuildViewModel = function(bridge)
    local roster = bridge:GetOfficerRosterViewModel()

    return {
      nominations = bridge:GetAdminNominationsViewModel(),
      canModerate = bridge:CanCurrentPlayerManageAwards(),
      canManageRoster = roster.canManageRoster,
      eligible = roster.eligible,
      granted = roster.granted,
    }
  end,
  DescribeViewModel = function(viewModel)
    local lines = {}

    if viewModel.canModerate then
      lines[#lines + 1] = "You can review flagged nominations and manage guild permissions."
      lines[#lines + 1] = ("Moderation queue: %d"):format(#(viewModel.nominations or {}))
    else
      lines[#lines + 1] = "You do not currently have moderation access."
    end

    return {
      title = "Admin",
      lines = lines,
    }
  end,
  BuildPanel = function(parent, mainFrame)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -44)
    panel:SetSize((parent.width or 820) - 24, (parent.height or 520) - 24)

    panel.rosterSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsRosterSection",
      title = "Officer Permissions",
      width = 780,
      height = 188,
      x = 0,
      y = 0,
      visibleRowCount = 4,
      rowHeight = 32,
    })
    panel.moderationSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsModerationSection",
      title = "Moderation Queue",
      width = 780,
      height = 214,
      x = 0,
      y = -202,
      visibleRowCount = 4,
      rowHeight = 48,
    })
    panel.statusLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = -426,
      width = 760,
    })

    return panel
  end,
  RefreshPanel = function(panel, viewModel, bridge, mainFrame)
    if viewModel.canManageRoster then
      local rosterRows = {}
      for _, officer in ipairs(viewModel.eligible or {}) do
        rosterRows[#rosterRows + 1] = {
          mode = "grant",
          officer = officer,
        }
      end

      for _, officer in ipairs(viewModel.granted or {}) do
        rosterRows[#rosterRows + 1] = {
          mode = "revoke",
          officer = officer,
        }
      end

      if #rosterRows == 0 then
        rosterRows = {
          {
            emptyState = true,
          },
        }
      end

      Components.SetScrollableItems(panel.rosterSection, rosterRows, function(section, row)
        if row.emptyState then
          Components.AddListRow(section, {
            text = "No officer roster entries yet.",
            rowHeight = 32,
            actions = {},
          })
          return
        end

        local officer = row.officer
        if row.mode == "grant" then
          Components.AddListRow(section, {
            text = ("%s (%s)"):format(officer.player, officer.rankName or "Officer"),
            labelWidth = 500,
            rowHeight = 32,
            actionX = 540,
            actions = {
              {
                text = "Grant",
                width = 64,
                onClick = function()
                  local ok = bridge:GrantOfficerPermission(officer.player)
                  Components.SetText(
                    panel.statusLabel,
                    ok and ("Granted %s access."):format(officer.player)
                      or ("Unable to grant %s access."):format(officer.player)
                  )
                  mainFrame:RenderActiveTab()
                end,
              },
            },
          })
        else
          Components.AddListRow(section, {
            text = ("%s (granted by %s)"):format(officer.player, officer.grantedBy or "unknown"),
            labelWidth = 500,
            rowHeight = 32,
            actionX = 540,
            actions = {
              {
                text = "Revoke",
                width = 70,
                onClick = function()
                  local ok = bridge:RevokeOfficerPermission(officer.player)
                  Components.SetText(
                    panel.statusLabel,
                    ok and ("Revoked %s access."):format(officer.player)
                      or ("Unable to revoke %s access."):format(officer.player)
                  )
                  mainFrame:RenderActiveTab()
                end,
              },
            },
          })
        end
      end)
    else
      Components.SetScrollableItems(panel.rosterSection, {
        {
          emptyState = true,
        },
      }, function(section)
        Components.AddListRow(section, {
          text = "Only the guild master can manage the officer permission roster.",
          rowHeight = 32,
          actions = {},
        })
      end)
    end

    if viewModel.canModerate then
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
          text = ("%s [%s]\nUpvotes: %d  Downvotes: %d"):format(
            row.nominee,
            row.status,
            row.upvotes or 0,
            row.downvotes or 0
          ),
          labelWidth = 620,
          rowHeight = 48,
          actions = {},
        })
      end)
    else
      Components.SetScrollableItems(panel.moderationSection, {
        {
          emptyState = true,
        },
      }, function(section)
        Components.AddListRow(section, {
          text = "You do not have moderation access.",
          rowHeight = 32,
          actions = {},
        })
      end)
    end
  end,
}

return UITabs.admin

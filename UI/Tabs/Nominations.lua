local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
RPA.UITabs = UITabs

UITabs.nominations = {
  id = "nominations",
  label = "Nominations",
  BuildViewModel = function(bridge)
    return {
      pendingNominations = bridge:GetPendingNominationsViewModel(),
    }
  end,
  DescribeViewModel = function(viewModel)
    local lines = {
      ("Pending nominations: %d"):format(#(viewModel.pendingNominations or {})),
    }

    for _, row in ipairs(viewModel.pendingNominations or {}) do
      lines[#lines + 1] = ("%s - %s"):format(row.nominee, row.reason)
    end

    if #lines == 1 then
      lines[#lines + 1] = "No pending nominations yet."
    end

    return {
      title = "Nominations",
      lines = lines,
    }
  end,
  BuildPanel = function(parent, mainFrame)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -44)
    panel:SetSize((parent.width or 820) - 24, (parent.height or 520) - 24)

    panel.nomineeLabel = Components.CreateLabel(panel, {
      text = "Nominee",
      x = 0,
      y = 0,
      font = "GameFontNormal",
    })
    panel.nomineeInput = Components.CreateEditBox(panel, {
      width = 220,
      x = 0,
      y = -22,
      maxLetters = 64,
    })
    panel.reasonLabel = Components.CreateLabel(panel, {
      text = "Reason",
      x = 238,
      y = 0,
      font = "GameFontNormal",
    })
    panel.reasonInput = Components.CreateEditBox(panel, {
      width = 330,
      x = 238,
      y = -22,
      maxLetters = 180,
    })
    panel.submitButton = Components.CreateButton(panel, {
      text = "Submit Nomination",
      width = 150,
      x = 586,
      y = -20,
      onClick = function()
        local nomination, err = mainFrame.uiBridge:SubmitNomination(
          panel.nomineeInput:GetText(),
          panel.reasonInput:GetText()
        )

        if nomination then
          Components.SetText(panel.statusLabel, ("Submitted nomination for %s."):format(nomination.nominee))
          Components.SetText(panel.nomineeInput, "")
          Components.SetText(panel.reasonInput, "")
        else
          Components.SetText(panel.statusLabel, ("Unable to nominate: %s"):format(err or "unknown error"))
        end

        mainFrame:RenderActiveTab()
      end,
    })
    panel.statusLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = -58,
      width = 740,
      justifyH = "LEFT",
    })
    panel.listSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsNominationsList",
      title = "Pending Nominations",
      width = 780,
      height = 360,
      x = 0,
      y = -92,
      visibleRowCount = 4,
      rowHeight = 68,
    })

    return panel
  end,
  RefreshPanel = function(panel, viewModel, bridge, mainFrame)
    local rows = viewModel.pendingNominations or {}
    if #rows == 0 then
      rows = {
        {
          emptyState = true,
        },
      }
    end

    Components.SetScrollableItems(panel.listSection, rows, function(section, row)
      if row.emptyState then
        Components.AddListRow(section, {
          text = "No pending nominations yet.",
          labelWidth = 520,
          rowHeight = 32,
          actions = {},
        })
        return
      end

      local actions = {}

      if row.canVote and not row.hasCurrentPlayerVoted then
        actions[#actions + 1] = {
          text = "Upvote",
          width = 62,
          onClick = function()
            bridge:CastVote(row.nominationId, "upvote")
            mainFrame:RenderActiveTab()
          end,
        }
        actions[#actions + 1] = {
          text = "Downvote",
          width = 74,
          onClick = function()
            bridge:CastVote(row.nominationId, "downvote")
            mainFrame:RenderActiveTab()
          end,
        }
      end

      if row.canModerate then
        actions[#actions + 1] = {
          text = "Approve",
          width = 66,
          onClick = function()
            bridge:ApproveNomination(row.nominationId)
            mainFrame:RenderActiveTab()
          end,
        }
        actions[#actions + 1] = {
          text = "Reject",
          width = 62,
          onClick = function()
            bridge:RejectNomination(row.nominationId)
            mainFrame:RenderActiveTab()
          end,
        }
      end

      Components.AddListRow(section, {
        text = ("%s\n%s\nUpvotes: %d"):format(row.nominee, row.reason, row.upvotes or 0),
        labelWidth = 400,
        rowHeight = 68,
        actionX = 434,
        actionColumns = 2,
        actionSpacingX = 8,
        actionSpacingY = 6,
        actionBaseY = 0,
        actions = actions,
      })
    end)
  end,
}

return UITabs.nominations

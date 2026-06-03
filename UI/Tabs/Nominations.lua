local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
local Styles = RPA.UIStyles or {}
RPA.UITabs = UITabs

local function buildNominationText(row)
  local lines = {
    row.nominee or "Unknown",
    row.reason or "",
    ("Upvotes: %d"):format(row.upvotes or 0),
  }

  if row.hasCurrentPlayerVoted then
    lines[#lines + 1] = "Your vote is locked in."
  elseif row.canVote then
    lines[#lines + 1] = "Guild voting is open."
  end

  return table.concat(lines, "\n")
end

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
    local media = Styles.Media or {}
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -42)
    panel:SetSize((parent.width or 820) - 28, (parent.height or 520) - 56)

    panel.formSection = Components.CreateSection(panel, {
      id = "RollingPinAwardsNominationFormSection",
      title = "Nominate A Guild Failure",
      width = 780,
      height = 160,
      x = 0,
      y = 0,
    })
    panel.helperLabel = Components.CreateLabel(panel.formSection, {
      text = "Tell the story, let the guild react, and leave the final verdict to authorized judges.",
      x = 14,
      y = -38,
      width = 740,
      font = "GameFontHighlightSmall",
      justifyH = "LEFT",
    })
    panel.selectedAwardType = panel.selectedAwardType or "burnt"
    panel.typeBurntButton = Components.CreateButton(panel.formSection, {
      text = "Burnt",
      width = 96,
      height = 28,
      x = 14,
      y = -66,
      variant = "primary",
      onClick = function()
        panel.selectedAwardType = "burnt"
        mainFrame:RenderActiveTab()
      end,
    })
    panel.typeGoldenButton = Components.CreateButton(panel.formSection, {
      text = "Golden",
      width = 96,
      height = 28,
      x = 118,
      y = -66,
      variant = "secondary",
      onClick = function()
        panel.selectedAwardType = "golden"
        mainFrame:RenderActiveTab()
      end,
    })
    panel.nomineeLabel = Components.CreateLabel(panel.formSection, {
      text = "Nominee",
      x = 14,
      y = -102,
      font = "GameFontNormal",
    })
    panel.nomineeInput = Components.CreateEditBox(panel.formSection, {
      width = 220,
      x = 14,
      y = -124,
      maxLetters = 64,
    })
    panel.reasonLabel = Components.CreateLabel(panel.formSection, {
      text = "Reason",
      x = 252,
      y = -102,
      font = "GameFontNormal",
    })
    panel.reasonInput = Components.CreateEditBox(panel.formSection, {
      width = 320,
      x = 252,
      y = -124,
      maxLetters = 180,
    })
    panel.selectedAwardPreview = Components.CreateArtworkFrame(panel.formSection, {
      texture = media.awardIcon,
      width = 54,
      height = 54,
      x = 657,
      y = -56,
    })
    panel.submitButton = Components.CreateButton(panel.formSection, {
      text = "Submit Nomination",
      width = 164,
      height = 36,
      x = 602,
      y = -116,
      variant = "primary",
      onClick = function()
        local nomination, err = mainFrame.uiBridge:SubmitNomination(
          panel.nomineeInput:GetText(),
          panel.reasonInput:GetText(),
          panel.selectedAwardType
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

    panel.listSection = Components.CreateScrollableSection(panel, {
      id = "RollingPinAwardsNominationsList",
      title = "Pending Nominations",
      iconPath = media.headerIcon,
      iconWidth = 22,
      iconHeight = 22,
      width = 780,
      height = 280,
      x = 0,
      y = -176,
      visibleRowCount = 3,
      rowHeight = 72,
    })
    panel.statusLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = -468,
      width = 760,
      justifyH = "LEFT",
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
          rowHeight = 40,
          actions = {},
        })
        return
      end

      local actions = {}

      if row.canVote and not row.hasCurrentPlayerVoted then
        actions[#actions + 1] = {
          text = "Upvote",
          width = 68,
          onClick = function()
            bridge:CastVote(row.nominationId, "upvote")
            mainFrame:RenderActiveTab()
          end,
        }
        actions[#actions + 1] = {
          text = "Downvote",
          width = 82,
          variant = "secondary",
          onClick = function()
            bridge:CastVote(row.nominationId, "downvote")
            mainFrame:RenderActiveTab()
          end,
        }
      end

      if row.canModerate then
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
        text = buildNominationText(row),
        iconPath = row.awardIconPath,
        iconWidth = 18,
        iconHeight = 18,
        labelWidth = 422,
        rowHeight = 72,
        backdropTone = "rowHighlight",
        actionX = 448,
        actionColumns = 2,
        actionSpacingX = 8,
        actionSpacingY = 8,
        actions = actions,
      })
    end)

    local isGolden = (panel.selectedAwardType or "burnt") == "golden"
    Components.SetButtonVariant(panel.typeBurntButton, isGolden and "secondary" or "primary")
    Components.SetButtonVariant(panel.typeGoldenButton, isGolden and "primary" or "secondary")
    Components.SetText(
      panel.formSection.titleText,
      isGolden and "Nominate A Guild Legend" or "Nominate A Guild Failure"
    )
    if panel.selectedAwardPreview and panel.selectedAwardPreview.texture and panel.selectedAwardPreview.texture.SetTexture then
      local previewPath = isGolden and (Styles.Media or {}).leaderboardIcon or (Styles.Media or {}).awardIcon
      panel.selectedAwardPreview.texture:SetTexture(previewPath)
      panel.selectedAwardPreview.texturePath = previewPath
    end
  end,
}

return UITabs.nominations

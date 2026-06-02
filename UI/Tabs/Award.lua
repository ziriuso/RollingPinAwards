local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
local Styles = RPA.UIStyles or {}
RPA.UITabs = UITabs

UITabs.award = {
  id = "award",
  label = "Award",
  BuildViewModel = function(bridge)
    return {
      canAward = bridge:CanCurrentPlayerCreateDirectAwards(),
    }
  end,
  DescribeViewModel = function(viewModel)
    local lines = {
      "Direct awards create The Burnt Rolling Pin without a nomination.",
    }

    if viewModel.canAward then
      lines[#lines + 1] = "You can manage awards in this guild."
    else
      lines[#lines + 1] = "You do not currently have permission to manage awards."
    end

    return {
      title = "Award",
      lines = lines,
    }
  end,
  BuildPanel = function(parent, mainFrame)
    local media = Styles.Media or {}
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -42)
    panel:SetSize((parent.width or 820) - 28, (parent.height or 520) - 56)

    panel.formSection = Components.CreateSection(panel, {
      id = "RollingPinAwardsAwardFormSection",
      title = "Award The Burnt Rolling Pin",
      iconPath = media.awardIcon,
      iconWidth = 24,
      iconHeight = 24,
      width = 504,
      height = 246,
      x = 0,
      y = 0,
    })
    panel.helperLabel = Components.CreateLabel(panel.formSection, {
      text = "Use this when the story is already settled and the guild just needs the ruling recorded.",
      x = 14,
      y = -38,
      width = 470,
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
    panel.recipientLabel = Components.CreateLabel(panel.formSection, {
      text = "Recipient",
      x = 14,
      y = -102,
      font = "GameFontNormal",
    })
    panel.recipientInput = Components.CreateEditBox(panel.formSection, {
      width = 300,
      x = 14,
      y = -124,
      maxLetters = 64,
    })
    panel.reasonLabel = Components.CreateLabel(panel.formSection, {
      text = "Reason",
      x = 14,
      y = -164,
      font = "GameFontNormal",
    })
    panel.reasonInput = Components.CreateEditBox(panel.formSection, {
      width = 462,
      x = 14,
      y = -186,
      maxLetters = 180,
    })
    panel.submitButton = Components.CreateButton(panel.formSection, {
      text = "Award The Burnt Rolling Pin",
      width = 280,
      height = 40,
      x = 14,
      y = -224,
      variant = "primary",
      iconPath = media.awardIcon,
      iconWidth = 20,
      iconHeight = 20,
      onClick = function()
        local award, err = mainFrame.uiBridge:CreateDirectAward(
          panel.recipientInput:GetText(),
          panel.reasonInput:GetText(),
          panel.selectedAwardType
        )

        if award then
          Components.SetText(panel.statusLabel, ("Awarded %s."):format(award.recipient))
          Components.SetText(panel.recipientInput, "")
          Components.SetText(panel.reasonInput, "")
        else
          Components.SetText(panel.statusLabel, ("Unable to award: %s"):format(err or "unknown error"))
        end

        mainFrame:RenderActiveTab()
      end,
    })

    panel.briefSection = Components.CreateSection(panel, {
      id = "RollingPinAwardsAwardBriefSection",
      title = "What Gets Recorded",
      iconPath = media.headerIcon,
      iconWidth = 22,
      iconHeight = 22,
      width = 260,
      height = 246,
      x = 520,
      y = 0,
    })
    panel.briefLabel = Components.CreateLabel(panel.briefSection, {
      text = table.concat({
        "Direct awards are immediate and public.",
        "",
        "Saved with:",
        "- recipient",
        "- reason",
        "- award date",
        "- awarded by",
        "",
        "Best used when moderation is already obvious.",
      }, "\n"),
      x = 14,
      y = -38,
      width = 228,
      justifyH = "LEFT",
      justifyV = "TOP",
      font = "GameFontHighlightSmall",
    })

    panel.statusSection = Components.CreateSection(panel, {
      id = "RollingPinAwardsAwardStatusSection",
      title = "Award Desk",
      iconPath = media.standardPinIcon,
      iconWidth = 20,
      iconHeight = 20,
      width = 780,
      height = 104,
      x = 0,
      y = -260,
    })
    panel.statusLabel = Components.CreateLabel(panel.statusSection, {
      text = "",
      x = 14,
      y = -40,
      width = 748,
      justifyH = "LEFT",
      justifyV = "TOP",
    })

    return panel
  end,
  RefreshPanel = function(panel, viewModel)
    local awardType = panel.selectedAwardType or "burnt"
    local isGolden = awardType == "golden"
    Components.SetButtonVariant(panel.typeBurntButton, isGolden and "secondary" or "primary")
    Components.SetButtonVariant(panel.typeGoldenButton, isGolden and "primary" or "secondary")
    Components.SetText(
      panel.formSection.titleText,
      isGolden and "Award The Golden Rolling Pin" or "Award The Burnt Rolling Pin"
    )
    Components.SetText(
      panel.submitButton,
      isGolden and "Award The Golden Rolling Pin" or "Award The Burnt Rolling Pin"
    )
    if panel.submitButton.iconFrame and panel.submitButton.iconFrame.texture and panel.submitButton.iconFrame.texture.SetTexture then
      panel.submitButton.iconFrame.texture:SetTexture(isGolden and (Styles.Media or {}).leaderboardIcon or (Styles.Media or {}).awardIcon)
      panel.submitButton.iconFrame.texturePath = isGolden and (Styles.Media or {}).leaderboardIcon or (Styles.Media or {}).awardIcon
    end
    if panel.formSection.iconFrame and panel.formSection.iconFrame.texture and panel.formSection.iconFrame.texture.SetTexture then
      panel.formSection.iconFrame.texture:SetTexture(isGolden and (Styles.Media or {}).leaderboardIcon or (Styles.Media or {}).awardIcon)
      panel.formSection.iconFrame.texturePath = isGolden and (Styles.Media or {}).leaderboardIcon or (Styles.Media or {}).awardIcon
    end
    if viewModel.canAward then
      if panel.submitButton.Enable then
        panel.submitButton:Enable()
      end
      Components.SetText(
        panel.statusLabel,
        panel.statusLabel.text ~= "" and panel.statusLabel.text
          or "Authorized ranks can issue a direct verdict here."
      )
    else
      if panel.submitButton.Disable then
        panel.submitButton:Disable()
      end
      Components.SetText(panel.statusLabel, "You do not have permission to create direct awards.")
    end
  end,
}

return UITabs.award

local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local UITabs = RPA.UITabs or {}
local Components = RPA.UIComponents or {}
RPA.UITabs = UITabs

UITabs.award = {
  id = "award",
  label = "Award",
  BuildViewModel = function(bridge)
    return {
      canAward = bridge:CanCurrentPlayerManageAwards(),
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
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -44)
    panel:SetSize((parent.width or 820) - 24, (parent.height or 520) - 24)

    panel.recipientLabel = Components.CreateLabel(panel, {
      text = "Recipient",
      x = 0,
      y = 0,
      font = "GameFontNormal",
    })
    panel.recipientInput = Components.CreateEditBox(panel, {
      width = 240,
      x = 0,
      y = -22,
      maxLetters = 64,
    })
    panel.reasonLabel = Components.CreateLabel(panel, {
      text = "Reason",
      x = 0,
      y = -62,
      font = "GameFontNormal",
    })
    panel.reasonInput = Components.CreateEditBox(panel, {
      width = 420,
      x = 0,
      y = -84,
      maxLetters = 180,
    })
    panel.submitButton = Components.CreateButton(panel, {
      text = "Award The Burnt Rolling Pin",
      width = 220,
      x = 0,
      y = -126,
      onClick = function()
        local award, err = mainFrame.uiBridge:CreateDirectAward(
          panel.recipientInput:GetText(),
          panel.reasonInput:GetText()
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
    panel.statusLabel = Components.CreateLabel(panel, {
      text = "",
      x = 0,
      y = -164,
      width = 520,
      justifyH = "LEFT",
    })

    return panel
  end,
  RefreshPanel = function(panel, viewModel)
    if viewModel.canAward then
      if panel.submitButton.Enable then
        panel.submitButton:Enable()
      end
      Components.SetText(panel.statusLabel, panel.statusLabel.text or "")
    else
      if panel.submitButton.Disable then
        panel.submitButton:Disable()
      end
      Components.SetText(panel.statusLabel, "You do not have permission to create direct awards.")
    end
  end,
}

return UITabs.award

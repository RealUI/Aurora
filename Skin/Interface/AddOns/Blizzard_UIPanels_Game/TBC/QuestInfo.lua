local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color = Aurora.Color

--[[ TBC (anniversary) shared quest detail/reward rendering — same pooled
    reward-button machinery as era. Evidence: wow-ui-source-anniversary/
    Interface/AddOns/Blizzard_UIPanels_Game/TBC/QuestInfo.lua —
    QuestInfo_GetRewardButton creates buttons lazily from
    rewardsFrame.buttonTemplate (QuestItemTemplate = LargeItemButtonTemplate).
]]

function private.FrameXML.QuestInfo()
    -- Lazily created reward buttons (choice + given rewards)
    _G.hooksecurefunc("QuestInfo_GetRewardButton", function(rewardsFrame, index)
        local button = rewardsFrame.RewardButtons[index]
        if button and button.Icon and not button._auroraSkinned then
            Skin.LargeItemButtonTemplate(button)
            button._auroraSkinned = true
        end
    end)

    -- Chosen-reward highlight: ornate golden ring -> flat highlight tint
    local highlight = _G.QuestInfoItemHighlight
    if highlight then
        local region = highlight:GetRegions()
        if region and region:IsObjectType("Texture") then
            region:SetTexture([[Interface\Buttons\White8x8]])
            region:SetVertexColor(Color.highlight.r, Color.highlight.g, Color.highlight.b, 0.3)
        end
    end
end

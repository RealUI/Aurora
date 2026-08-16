local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color = Aurora.Color

--[[ Era shared quest detail/reward rendering (drives both the QuestFrame
    detail panel and the quest log detail pane — the reward-art half that
    Wave 1 deferred). Evidence: wow-ui-source-era/Interface/AddOns/
    Blizzard_UIPanels_Game/Vanilla/QuestInfo.lua — reward buttons are pooled
    per rewardsFrame and created lazily in QuestInfo_GetRewardButton from
    rewardsFrame.buttonTemplate (QuestItemTemplate = LargeItemButtonTemplate).
    Fonts/colors were already handled by the Wave 1 QuestFrame skin and the
    Classic fonts file.
]]

function private.FrameXML.QuestInfo()
    -- Lazily created reward buttons (choice + given rewards)
    _G.hooksecurefunc("QuestInfo_GetRewardButton", function(rewardsFrame, index)
        local button = rewardsFrame.RewardButtons[index]
        if button and button.Icon and not private.IsSkinned(button) then
            Skin.LargeItemButtonTemplate(button)
            private.SetSkinned(button, true)
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

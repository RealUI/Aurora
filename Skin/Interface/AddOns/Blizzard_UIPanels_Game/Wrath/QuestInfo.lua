local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color = Aurora.Color

-- QuestInfo_Display re-sets every fontstring from
-- GetMaterialTextColors(material) — parchment-dark in the quest log —
-- on every display. Recolor after it (evidence: Wrath/QuestInfo.lua:90).
local titleStrings = {
    "QuestInfoTitleHeader", "QuestInfoDescriptionHeader",
    "QuestInfoObjectivesHeader",
}
local bodyStrings = {
    "QuestInfoDescriptionText", "QuestInfoObjectivesText",
    "QuestInfoGroupSize", "QuestInfoRewardText",
}
local function RecolorQuestInfo()
    for _, name in ipairs(titleStrings) do
        if _G[name] then
            _G[name]:SetTextColor(Color.white:GetRGB())
        end
    end
    for _, name in ipairs(bodyStrings) do
        if _G[name] then
            _G[name]:SetTextColor(Color.grayLight:GetRGB())
        end
    end
    local rewards = _G.QuestInfoRewardsFrame
    if rewards then
        if rewards.Header then
            rewards.Header:SetTextColor(Color.white:GetRGB())
        end
        for _, key in ipairs({"ItemChooseText", "ItemReceiveText"}) do
            if rewards[key] then
                rewards[key]:SetTextColor(Color.grayLight:GetRGB())
            end
        end
        if rewards.XPFrame and rewards.XPFrame.ReceiveText then
            rewards.XPFrame.ReceiveText:SetTextColor(Color.grayLight:GetRGB())
        end
        if rewards.TalentFrame and rewards.TalentFrame.ReceiveText then
            rewards.TalentFrame.ReceiveText:SetTextColor(Color.grayLight:GetRGB())
        end
    end

    -- objectives: incomplete = literal black, complete = 0.2 gray — remap
    local index = 1
    local objective = _G["QuestInfoObjective"..index]
    while objective do
        local r = objective:GetTextColor()
        if r < 0.1 then
            objective:SetTextColor(Color.white:GetRGB())
        elseif r < 0.35 then
            objective:SetTextColor(Color.gray:GetRGB())
        end
        index = index + 1
        objective = _G["QuestInfoObjective"..index]
    end
    for _, name in ipairs({"QuestInfoSpellObjectiveLearnLabel", "QuestInfoRequiredMoneyText"}) do
        local fontString = _G[name]
        if fontString then
            local r = fontString:GetTextColor()
            if r < 0.1 then
                fontString:SetTextColor(Color.white:GetRGB())
            elseif r < 0.35 then
                fontString:SetTextColor(Color.gray:GetRGB())
            end
        end
    end
end

--[[ Wrath-path (wrath/cata/mists) shared quest detail/reward rendering —
    same pooled reward-button machinery as the TBC file (whose key never
    co-loads with this one). Evidence: wow-ui-source-classic/Interface/
    AddOns/Blizzard_UIPanels_Game/Wrath/QuestInfo.lua.
]]

function private.FrameXML.QuestInfo()
    if _G.QuestInfo_Display then
        _G.hooksecurefunc("QuestInfo_Display", RecolorQuestInfo)
    end

    -- Lazily created reward buttons (choice + given rewards)
    if _G.QuestInfo_GetRewardButton then
        _G.hooksecurefunc("QuestInfo_GetRewardButton", function(rewardsFrame, index)
            local button = rewardsFrame.RewardButtons and rewardsFrame.RewardButtons[index]
            if button and button.Icon and not button._auroraSkinned then
                Skin.LargeItemButtonTemplate(button)
                button._auroraSkinned = true
            end
        end)
    end

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

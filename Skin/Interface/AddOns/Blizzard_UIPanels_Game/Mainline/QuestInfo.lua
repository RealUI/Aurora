local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ FrameXML\QuestInfo.lua ]]
    local templates = {}
    local StyleRewards
    function Hook.QuestInfo_Display(template, parentFrame, acceptButton, material, mapView)
        local headerR, headerG, headerB = Color.white:GetRGB()
        local textR, textG, textB = Color.grayLight:GetRGB()

        if template.canHaveSealMaterial then
            local questFrame = parentFrame:GetParent():GetParent()
            questFrame.SealMaterialBG:Hide()
        end

        -- headers
        _G.QuestInfoTitleHeader:SetTextColor(headerR, headerG, headerB)
        _G.QuestInfoDescriptionHeader:SetTextColor(headerR, headerG, headerB)
        _G.QuestInfoObjectivesHeader:SetTextColor(headerR, headerG, headerB)
        _G.QuestInfoRewardsFrame.Header:SetTextColor(headerR, headerG, headerB)

        -- other text
        _G.QuestInfoDescriptionText:SetTextColor(textR, textG, textB)
        _G.QuestInfoObjectivesText:SetTextColor(textR, textG, textB)
        _G.QuestInfoGroupSize:SetTextColor(textR, textG, textB)
        _G.QuestInfoRewardText:SetTextColor(textR, textG, textB)

        -- reward frame text
        local rewardsFrame = _G.QuestInfoFrame.rewardsFrame
        rewardsFrame.ItemChooseText:SetTextColor(textR, textG, textB)
        rewardsFrame.ItemReceiveText:SetTextColor(textR, textG, textB)
        rewardsFrame.PlayerTitleText:SetTextColor(textR, textG, textB)
        rewardsFrame.QuestSessionBonusReward:SetTextColor(textR, textG, textB)
        if not mapView then
            rewardsFrame.XPFrame.ReceiveText:SetTextColor(textR, textG, textB)
        end

        local templateElements = templates[template]
        for i = 1, #templateElements do
            templateElements[i](parentFrame)
        end

        StyleRewards(rewardsFrame)
    end
    function Hook.QuestInfo_ShowObjectives()
        local numObjectives = _G.GetNumQuestLeaderBoards()
        local objectivesTable = _G.QuestInfoObjectivesFrame.Objectives

        local shownObjs = 0
        for i = #objectivesTable, 1, -1 do
            local objective = objectivesTable[i]
            if objective:IsShown() then
                shownObjs = shownObjs + 1
                if shownObjs > numObjectives then
                    objective:SetTextColor(1, 1, 1)
                else
                    local _, _, finished = _G.GetQuestLogLeaderBoard(i)
                    if finished then
                        objective:SetTextColor(0.6, 0.6, 0.6)
                    else
                        objective:SetTextColor(0.9, 0.9, 0.9)
                    end
                end
            end
        end
    end

    --[[ Taint audit 2026-10-06 (B170 follow-up): the rewards are restyled in
        place from the QuestInfo_Display and QuestInfo_ShowRewards post-hooks,
        after Blizzard has laid them out. The old QuestInfo_GetRewardButton hook
        ran Skin.Large/SmallItemButtonTemplate in the middle of
        QuestInfo_ShowRewards (backdrop methods, a nameBG frame, re-anchored
        icon, _aurora* fields) while Blizzard kept using the button, and the
        spell, follower and header pools had their Acquire replaced by addon
        closures, so Blizzard called addon code from inside the build. Either
        way the quest log and map details build ran tainted, next to the
        QuestCache entries the objective tracker reads. In place only: no new
        regions, no size or anchor change, no field on Blizzard's frames. ]]
    function StyleRewards(rewardsFrame)
        local styleButton = Skin[rewardsFrame.buttonTemplate]
        if not styleButton then return end

        local textR, textG, textB = Color.grayLight:GetRGB()
        for header in rewardsFrame.spellHeaderPool:EnumerateActive() do
            header:SetVertexColor(textR, textG, textB)
        end

        for i = 1, #rewardsFrame.RewardButtons do
            styleButton(rewardsFrame.RewardButtons[i])
        end
        for button in rewardsFrame.reputationRewardPool:EnumerateActive() do
            styleButton(button)
        end

        if rewardsFrame == _G.MapQuestInfoRewardsFrame then
            for button in rewardsFrame.spellRewardPool:EnumerateActive() do
                styleButton(button)
            end
            for button in rewardsFrame.followerRewardPool:EnumerateActive() do
                Skin.SmallQuestInfoRewardFollowerTemplate(button)
            end
        else
            for button in rewardsFrame.spellRewardPool:EnumerateActive() do
                Skin.QuestInfoRewardSpellInPlace(button)
            end
            for button in rewardsFrame.followerRewardPool:EnumerateActive() do
                Skin.LargeQuestInfoRewardFollowerTemplate(button)
            end
        end
    end

    -- QuestFrame calls the global on QUEST_ITEM_UPDATE; QuestInfo_Display
    -- holds its own reference, so its rewards are styled from that hook.
    function Hook.QuestInfo_ShowRewards()
        StyleRewards(_G.QuestInfoFrame.rewardsFrame)
    end

    templates = {
        [_G.QUEST_TEMPLATE_DETAIL] = {
        },
        [_G.QUEST_TEMPLATE_LOG] = {
            Hook.QuestInfo_ShowObjectives,
        },
        [_G.QUEST_TEMPLATE_REWARD] = {
        },
        [_G.QUEST_TEMPLATE_MAP_DETAILS] = {
            Hook.QuestInfo_ShowObjectives,
        },
        [_G.QUEST_TEMPLATE_MAP_REWARDS] = {
        },
    }
end

do --[[ FrameXML\QuestInfo.xml ]]
    -- In place (taint audit 2026-10-06, B170 follow-up; see StyleRewards):
    -- skin state lives in this weak table, never on Blizzard's frames.
    local styled = setmetatable({}, {__mode = "k"})

    local function SetFrameBand(texture)
        local r, g, b = Color.frame:GetRGB()
        texture:SetColorTexture(r, g, b, Color.frame.a)
    end

    -- The existing NameFrame becomes the flat band the old nameBG frame drew:
    -- icon right + 1 to the button's right - 3, icon top to icon bottom. Drawn
    -- with vertex offsets (1 upper-left, 2 lower-left, 3 upper-right, 4 lower-
    -- right) so the region keeps its size and anchors. NameFrame is anchored
    -- LEFT to the icon's RIGHT, so it is centred on the icon; its size comes
    -- from the region because the small template's atlas sets it.
    local function SetNameBand(Button)
        local nameFrame, icon = Button.NameFrame, Button.Icon
        local _, _, _, iconX = icon:GetPoint(1)
        local _, _, _, nameX = nameFrame:GetPoint(1)
        local iconW, iconH = icon:GetSize()
        local nameW, nameH = nameFrame:GetSize()

        local left = 1 - nameX
        local right = (Button:GetWidth() - 3) - (iconX + iconW + nameX + nameW)
        local inset = (nameH - iconH) / 2

        SetFrameBand(nameFrame)
        nameFrame:SetVertexOffset(1, left, -inset)
        nameFrame:SetVertexOffset(2, left, inset)
        nameFrame:SetVertexOffset(3, right, -inset)
        nameFrame:SetVertexOffset(4, right, inset)
    end

    -- Item, currency and reputation rewards, and the fixed XP/money/honor
    -- buttons: cropped icon, name band. Blizzard's IconBorder shows quality as
    -- it does unskinned; Aurora's SetItemButtonQuality hooks skip these
    -- buttons (no icon border of ours).
    function Skin.LargeQuestRewardItemButtonTemplate(Button)
        if styled[Button] then return end
        styled[Button] = true

        Base.CropIcon(Button.Icon)
        if Button.NameFrame then
            SetNameBand(Button)
        end
    end
    Skin.SmallQuestRewardItemButtonTemplate = Skin.LargeQuestRewardItemButtonTemplate

    -- QuestSpellTemplate in the quest frame's spell reward pool.
    function Skin.QuestInfoRewardSpellInPlace(Button)
        if styled[Button] then return end
        styled[Button] = true

        Base.CropIcon(Button.Icon)
        SetNameBand(Button)

        local _, _, spellBorder = Button:GetRegions()
        spellBorder:SetTexture("")
    end

    -- Follower rewards: the BG atlas becomes the band the old backdrop drew,
    -- right of the portrait; Blizzard's portrait art is left as it is.
    function Skin.LargeQuestInfoRewardFollowerTemplate(Button)
        if styled[Button] then return end
        styled[Button] = true

        -- BG spans 30,-7 to 144,-48; the band 41,-8 to 144,-47.
        SetFrameBand(Button.BG)
        Button.BG:SetVertexOffset(1, 11, -1)
        Button.BG:SetVertexOffset(2, 11, 1)
        Button.BG:SetVertexOffset(3, 0, -1)
        Button.BG:SetVertexOffset(4, 0, 1)
    end
    function Skin.SmallQuestInfoRewardFollowerTemplate(Button)
        if styled[Button] then return end
        styled[Button] = true

        -- BG spans 30,2 to 134,-32; the band 33,1 to 134,-32.
        SetFrameBand(Button.BG)
        Button.BG:SetVertexOffset(1, 3, -1)
        Button.BG:SetVertexOffset(2, 3, 0)
        Button.BG:SetVertexOffset(3, 0, -1)
        Button.BG:SetVertexOffset(4, 0, 0)
    end
end

function private.FrameXML.QuestInfo()
    _G.hooksecurefunc("QuestInfo_Display", Hook.QuestInfo_Display)
    _G.hooksecurefunc("QuestInfo_ShowRewards", Hook.QuestInfo_ShowRewards)

    ------------------------------
    -- QuestInfoObjectivesFrame --
    ------------------------------
    _G.hooksecurefunc("QuestInfo_ShowObjectives", Hook.QuestInfo_ShowObjectives)

    -------------------------------------
    -- QuestInfoSpecialObjectivesFrame --
    -------------------------------------
    Skin.QuestSpellTemplate(_G.QuestInfoSpellObjectiveFrame)

    -------------------------
    -- QuestInfoTimerFrame --
    -------------------------

    ---------------------------------
    -- QuestInfoRequiredMoneyFrame --
    ---------------------------------

    ---------------------------
    -- QuestInfoRewardsFrame --
    ---------------------------
    -- The fixed reward buttons get the reward buttons' in-place look.
    local QuestInfoRewardsFrame = _G.QuestInfoRewardsFrame
    Skin.LargeQuestRewardItemButtonTemplate(QuestInfoRewardsFrame.HonorFrame)
    Skin.LargeQuestRewardItemButtonTemplate(QuestInfoRewardsFrame.SkillPointFrame)
    Skin.LargeQuestRewardItemButtonTemplate(QuestInfoRewardsFrame.ArtifactXPFrame)
    Skin.LargeQuestRewardItemButtonTemplate(QuestInfoRewardsFrame.WarModeBonusFrame)

    local TitleFrame = QuestInfoRewardsFrame.TitleFrame
    Base.CropIcon(TitleFrame.Icon)
    TitleFrame.FrameLeft:Hide()
    TitleFrame.FrameCenter:Hide()
    TitleFrame.FrameRight:Hide()

    local titleBG = _G.CreateFrame("Frame", nil, TitleFrame)
    titleBG:SetPoint("TOPLEFT", TitleFrame.FrameLeft, -2, 0)
    titleBG:SetPoint("BOTTOMRIGHT", TitleFrame.FrameRight, 0, -1)
    Base.SetBackdrop(titleBG, Color.frame)

    local ItemHighlight = QuestInfoRewardsFrame.ItemHighlight
    ItemHighlight:GetRegions():Hide()
    Base.SetBackdrop(ItemHighlight, Color.highlight, Color.frame.a)
    ItemHighlight:SetBackdropOption("offsets", {
        left = 7,
        right = 104,
        top = 6,
        bottom = 17,
    })

    -- The spell, follower and spell header pools are left alone: their
    -- objects are restyled in place by StyleRewards.

    ------------------------------
    -- MapQuestInfoRewardsFrame --
    ------------------------------
    local MapQuestInfoRewardsFrame = _G.MapQuestInfoRewardsFrame
    Skin.SmallQuestRewardItemButtonTemplate(MapQuestInfoRewardsFrame.XPFrame)
    Skin.SmallQuestRewardItemButtonTemplate(MapQuestInfoRewardsFrame.HonorFrame)
    Skin.SmallQuestRewardItemButtonTemplate(MapQuestInfoRewardsFrame.ArtifactXPFrame)
    Skin.SmallQuestRewardItemButtonTemplate(MapQuestInfoRewardsFrame.WarModeBonusFrame)
    Skin.SmallQuestRewardItemButtonTemplate(MapQuestInfoRewardsFrame.MoneyFrame)
    Skin.SmallQuestRewardItemButtonTemplate(MapQuestInfoRewardsFrame.SkillPointFrame)
    Skin.SmallQuestRewardItemButtonTemplate(MapQuestInfoRewardsFrame.TitleFrame)

    --------------------
    -- QuestInfoFrame --
    --------------------

    -- QuestInfoSealFrame --
    local mask = _G.QuestInfoSealFrame:CreateMaskTexture(nil, "BACKGROUND")
    mask:SetTexture([[Interface/SpellBook/UI-SpellbookPanel-Tab-Highlight]], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetTexCoord(0, 0.5, 0, 0.5)
    mask:SetPoint("TOPLEFT", _G.QuestInfoSealFrame.Text, -44, 46)
    mask:SetPoint("BOTTOMRIGHT", _G.QuestInfoSealFrame.Text, 30, -50)

    local bg = _G.QuestInfoSealFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(Color.white.r, Color.white.g, Color.white.b, 0.25)
    bg:SetAllPoints(mask)
    bg:AddMaskTexture(mask)

    _G.QuestInfoSealFrame.Text:SetShadowColor(Color.grayDark:GetRGB())
    _G.QuestInfoSealFrame.Text:SetShadowOffset(0.6, -0.6)
end

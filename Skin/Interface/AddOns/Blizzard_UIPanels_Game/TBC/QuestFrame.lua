local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ FrameXML\QuestFrame.lua ]]
    function Hook.QuestFrameProgressItems_Update()
        local numRequiredItems = _G.GetNumQuestItems()
        local moneyToGet = _G.GetQuestMoneyToGet()
        if numRequiredItems > 0 or moneyToGet > 0 then
            if moneyToGet > 0 then
                if moneyToGet > _G.GetMoney() then
                    _G.QuestProgressRequiredMoneyText:SetTextColor(Color.grayLight:GetRGB())
                else
                    _G.QuestProgressRequiredMoneyText:SetTextColor(Color.white:GetRGB())
                end
            end
        end
    end
    function Hook.QuestFrameGreetingPanel_OnShow()
        local numActiveQuests = _G.GetNumActiveQuests()
        local numAvailableQuests = _G.GetNumAvailableQuests()

        for i = 1, numActiveQuests do
            local questTitleButton = _G["QuestTitleButton" .. i]
            if questTitleButton then
                local title = _G.GetActiveTitle(i)
                if _G.IsActiveQuestTrivial(i) then
                    questTitleButton:SetFormattedText(private.TRIVIAL_QUEST_DISPLAY, title)
                else
                    questTitleButton:SetFormattedText(private.NORMAL_QUEST_DISPLAY, title)
                end
            end
        end

        for i = (numActiveQuests + 1), (numActiveQuests + numAvailableQuests) do
            local questTitleButton = _G["QuestTitleButton" .. i]
            if questTitleButton then
                local isTrivial = _G.GetAvailableQuestInfo(i - numActiveQuests)
                local title = _G.GetAvailableTitle(i - numActiveQuests)
                if isTrivial then
                    questTitleButton:SetFormattedText(private.TRIVIAL_QUEST_DISPLAY, title)
                else
                    questTitleButton:SetFormattedText(private.NORMAL_QUEST_DISPLAY, title)
                end
            end
        end

        if numAvailableQuests > 0 and numActiveQuests > 0 then
            local lastActiveButton = _G["QuestTitleButton" .. numActiveQuests]
            if lastActiveButton and _G.QuestGreetingFrameHorizontalBreak then
                _G.QuestGreetingFrameHorizontalBreak:SetPoint("TOPLEFT", lastActiveButton, "BOTTOMLEFT", 22, -10)
            end
            if _G.AvailableQuestsText and _G.QuestGreetingFrameHorizontalBreak then
                _G.AvailableQuestsText:SetPoint("TOPLEFT", "QuestGreetingFrameHorizontalBreak", "BOTTOMLEFT", -12, -10)
            end
        end
    end
    function Hook.QuestFrame_SetTitleTextColor(fontString, material)
        fontString:SetTextColor(Color.white:GetRGB())
    end
    function Hook.QuestFrame_SetTextColor(fontString, material)
        fontString:SetTextColor(Color.white:GetRGB())
    end
end

do --[[ FrameXML\QuestFrameTemplates.xml ]]
    function Skin.QuestFramePanelTemplate(Frame)
        local name = Frame:GetName()
        if not name then return end

        Frame:SetAllPoints()

        local bg = _G[name .. "Bg"]
        if bg then bg:Hide() end

        local matTL = _G[name .. "MaterialTopLeft"]
        if matTL then matTL:SetAlpha(0) end
        local matTR = _G[name .. "MaterialTopRight"]
        if matTR then matTR:SetAlpha(0) end
        local matBL = _G[name .. "MaterialBotLeft"]
        if matBL then matBL:SetAlpha(0) end
        local matBR = _G[name .. "MaterialBotRight"]
        if matBR then matBR:SetAlpha(0) end
    end
    function Skin.QuestItemTemplate(Button)
        if Skin.LargeItemButtonTemplate then
            Skin.LargeItemButtonTemplate(Button)
        end
    end
    function Skin.QuestScrollFrameTemplate(ScrollFrame)
        if not ScrollFrame then return end
        Skin.ScrollFrameTemplate(ScrollFrame)
        ScrollFrame:SetPoint("TOPLEFT", 5, -(private.FRAME_TITLE_HEIGHT + 5))
        ScrollFrame:SetPoint("BOTTOMRIGHT", -23, 32)
    end
end

function private.FrameXML.QuestFrame()
    local QuestFrame = _G.QuestFrame
    if not QuestFrame then return end

    _G.hooksecurefunc("QuestFrameProgressItems_Update", Hook.QuestFrameProgressItems_Update)
    _G.hooksecurefunc("QuestFrameGreetingPanel_OnShow", Hook.QuestFrameGreetingPanel_OnShow)
    if _G.QuestFrameGreetingPanel then
        _G.QuestFrameGreetingPanel:HookScript("OnShow", Hook.QuestFrameGreetingPanel_OnShow)
    end
    _G.hooksecurefunc("QuestFrame_SetTitleTextColor", Hook.QuestFrame_SetTitleTextColor)
    _G.hooksecurefunc("QuestFrame_SetTextColor", Hook.QuestFrame_SetTextColor)

    ----------------
    -- QuestFrame --
    ----------------
    Skin.ButtonFrameTemplate(QuestFrame)

    -- Reward Panel
    if _G.QuestFrameRewardPanel then
        Skin.QuestFramePanelTemplate(_G.QuestFrameRewardPanel)
    end
    if _G.QuestFrameCompleteQuestButton then
        Skin.UIPanelButtonNoTooltipTemplate(_G.QuestFrameCompleteQuestButton)
        _G.QuestFrameCompleteQuestButton:SetPoint("BOTTOMLEFT", 5, 5)
    end
    if _G.QuestFrameCancelButton then
        Skin.UIPanelButtonNoTooltipTemplate(_G.QuestFrameCancelButton)
        _G.QuestFrameCancelButton:SetPoint("BOTTOMRIGHT", -5, 5)
    end
    if _G.QuestRewardScrollFrame then
        Skin.QuestScrollFrameTemplate(_G.QuestRewardScrollFrame)
    end

    -- Progress Panel
    if _G.QuestFrameProgressPanel then
        Skin.QuestFramePanelTemplate(_G.QuestFrameProgressPanel)
    end
    if _G.QuestFrameGoodbyeButton then
        Skin.UIPanelButtonNoTooltipTemplate(_G.QuestFrameGoodbyeButton)
        _G.QuestFrameGoodbyeButton:SetPoint("BOTTOMRIGHT", -5, 5)
    end
    if _G.QuestFrameCompleteButton then
        Skin.UIPanelButtonNoTooltipTemplate(_G.QuestFrameCompleteButton)
        _G.QuestFrameCompleteButton:SetPoint("BOTTOMLEFT", 5, 5)
    end
    if _G.QuestProgressScrollFrame then
        Skin.QuestScrollFrameTemplate(_G.QuestProgressScrollFrame)
    end
    for i = 1, (_G.MAX_REQUIRED_ITEMS or 6) do
        local item = _G["QuestProgressItem" .. i]
        if item then
            Skin.QuestItemTemplate(item)
        end
    end

    -- Detail Panel
    if _G.QuestFrameDetailPanel then
        Skin.QuestFramePanelTemplate(_G.QuestFrameDetailPanel)
    end
    if _G.QuestFrameDeclineButton then
        Skin.UIPanelButtonNoTooltipTemplate(_G.QuestFrameDeclineButton)
        _G.QuestFrameDeclineButton:SetPoint("BOTTOMRIGHT", -5, 5)
    end
    if _G.QuestFrameAcceptButton then
        Skin.UIPanelButtonNoTooltipTemplate(_G.QuestFrameAcceptButton)
        _G.QuestFrameAcceptButton:SetPoint("BOTTOMLEFT", 5, 5)
    end
    if _G.QuestDetailScrollFrame then
        Skin.QuestScrollFrameTemplate(_G.QuestDetailScrollFrame)
    end

    -- Greeting Panel
    if _G.QuestFrameGreetingPanel then
        Skin.QuestFramePanelTemplate(_G.QuestFrameGreetingPanel)
    end
    if _G.QuestFrameGreetingGoodbyeButton then
        Skin.UIPanelButtonNoTooltipTemplate(_G.QuestFrameGreetingGoodbyeButton)
        _G.QuestFrameGreetingGoodbyeButton:SetPoint("BOTTOMRIGHT", -5, 5)
    end
    if _G.QuestGreetingScrollFrame then
        Skin.QuestScrollFrameTemplate(_G.QuestGreetingScrollFrame)
    end
    if _G.QuestGreetingFrameHorizontalBreak then
        _G.QuestGreetingFrameHorizontalBreak:SetColorTexture(1, 1, 1, .2)
        _G.QuestGreetingFrameHorizontalBreak:SetSize(256, 1)
    end
end

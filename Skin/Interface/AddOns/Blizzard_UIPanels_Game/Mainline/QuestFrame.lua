local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select

--[[ Core ]]
local Aurora = private.Aurora
local Base, Hook, Skin = Aurora.Base, Aurora.Hook, Aurora.Skin
local Color = Aurora.Color

do --[[ FrameXML\QuestFrame.lua ]]
    function Hook.QuestFrameProgressItems_Update()
        local numRequiredItems = _G.GetNumQuestItems()
        local numRequiredCurrencies = _G.GetNumQuestCurrencies()
        local moneyToGet = _G.GetQuestMoneyToGet()
        if numRequiredItems > 0 or moneyToGet > 0 or numRequiredCurrencies > 0 then
            -- If there's money required then anchor and display it
            if moneyToGet > 0 then
                if moneyToGet > _G.GetMoney() then
                    -- Not enough money
                    _G.QuestProgressRequiredMoneyText:SetTextColor(Color.grayLight:GetRGB())
                else
                    _G.QuestProgressRequiredMoneyText:SetTextColor(Color.white:GetRGB())
                end
            end
        end
    end
    function Hook.QuestFrameGreetingPanel_OnShow()
        local id, title, lastTitleButton
        for questTitleButton in _G.QuestFrameGreetingPanel.titleButtonPool:EnumerateActive() do
            id = questTitleButton:GetID()
            if questTitleButton.isActive == 1 then
                title = _G.GetActiveTitle(id)
                if _G.IsActiveQuestTrivial(id) then
                    questTitleButton:SetFormattedText(private.TRIVIAL_QUEST_DISPLAY, title)
                else
                    questTitleButton:SetFormattedText(private.NORMAL_QUEST_DISPLAY, title)
                end
                lastTitleButton = questTitleButton
            elseif questTitleButton.isActive == 0 then
                title = _G.GetAvailableTitle(id)
                if _G.GetAvailableQuestInfo(id) then
                    questTitleButton:SetFormattedText(private.TRIVIAL_QUEST_DISPLAY, title)
                else
                    questTitleButton:SetFormattedText(private.NORMAL_QUEST_DISPLAY, title)
                end
            end
        end

        if _G.GetNumAvailableQuests() > 0 and _G.GetNumActiveQuests() > 0 then
            _G.QuestGreetingFrameHorizontalBreak:SetPoint("TOPLEFT", lastTitleButton, "BOTTOMLEFT", 22, -10)
            _G.AvailableQuestsText:SetPoint("TOPLEFT", "QuestGreetingFrameHorizontalBreak", "BOTTOMLEFT", -12, -10)
        end
    end
    function Hook.QuestFrame_UpdatePortraitText(text)
        if text and text ~= "" then
            _G.QuestNPCModelText:SetWidth(191)
            local textHeight = _G.QuestNPCModelText:GetHeight()
            local scrollHeight = _G.QuestNPCModelTextScrollFrame:GetHeight()
            if textHeight > scrollHeight then
                _G.QuestNPCModelTextScrollChildFrame:SetHeight(textHeight + 10)
                _G.QuestNPCModelText:SetWidth(176)
            else
                _G.QuestNPCModelTextScrollChildFrame:SetHeight(textHeight)
            end
        end
    end
    function Hook.QuestFrame_ShowQuestPortrait(parentFrame, portraitDisplayID, mountPortraitDisplayID, modelSceneID, text, name, x, y)
        if parentFrame == _G.WorldMapFrame then
            x = x + 2
        else
            x = x + 5
        end
        _G.QuestModelScene:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", x, y)
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

        Frame:SetAllPoints()
        Frame.Bg:Hide()
        _G[name.."MaterialTopLeft"]:SetAlpha(0)
        _G[name.."MaterialTopRight"]:SetAlpha(0)
        _G[name.."MaterialBotLeft"]:SetAlpha(0)
        _G[name.."MaterialBotRight"]:SetAlpha(0)
    end
    function Skin.QuestItemTemplate(Button)
        Skin.LargeItemButtonTemplate(Button)
    end
    function Skin.QuestSpellTemplate(Button)
        Base.SetBackdrop(Button, Color.black, Color.frame.a)
        Button:SetBackdropOption("offsets", {
            left = 9,
            right = 107,
            top = 1,
            bottom = 14,
        })
        Button._auroraIconBorder = Button
        Base.CropIcon(Button.Icon)

        Button.NameFrame:SetAlpha(0)

        local bg = Button:GetBackdropTexture("bg")
        local nameBG = _G.CreateFrame("Frame", nil, Button)
        nameBG:SetFrameLevel(Button:GetFrameLevel())
        nameBG:SetPoint("TOPLEFT", bg, "TOPRIGHT", 1, 0)
        nameBG:SetPoint("RIGHT", -3, 0)
        nameBG:SetPoint("BOTTOM", bg)
        Base.SetBackdrop(nameBG, Color.frame)
        Button._auroraNameBG = nameBG

        local _, _, spellBorder = Button:GetRegions()
        spellBorder:Hide()
    end
    function Skin.QuestTitleButtonTemplate(Button)
    end
    function Skin.QuestScrollFrameTemplate(ScrollFrame)
        Skin.ScrollFrameTemplate(ScrollFrame)
        ScrollFrame:SetPoint("TOPLEFT", 5, -(private.FRAME_TITLE_HEIGHT + 5))
        ScrollFrame:SetPoint("BOTTOMRIGHT", -23, 32)
    end
end

--[[ B261 Layer 2 (tier A, row A6; AT-D16 a), read from wow-ui-source
    (retail) and wow-ui-source-forever. QuestFrame_OnEvent
    (Blizzard_UIPanels_Game/Mainline/QuestFrame.lua:22; Forever :24) ends
    every branch that falls through in ShowUIPanel(QuestFrame) (:97-100;
    Forever :99-102), the secure gate, and three buttons change state before
    it in the same execution:
      QUEST_COMPLETE: QuestFrameCompleteQuestButton:Enable() (:68-72;
        Forever :70-74), the row the audit names;
      QUEST_PROGRESS: the progress panel is shown (:64-67; Forever :66-69),
        and its OnShow, QuestFrameProgressPanel_OnShow, enables or disables
        QuestFrameCompleteButton (:196, :209-213; Forever :205, :218-222);
      QUEST_DETAIL, Forever only: the detail panel is shown (Forever :64),
        and QuestFrameDetailPanel_OnShow disables QuestFrameAcceptButton
        (Forever :566, :607). Retail's has no such line.
    The last two are tier A by the same rule (Requirement 5.6), found while
    converting A6. All three: shape "panel", plain UIPanelButtonTemplate
    buttons declared in XML (Mainline/QuestFrame.xml:67, :99, :202; Forever
    :73, :105, :208), not pooled and not layout frames; Blizzard re-sets only
    the plates (Blizzard_SharedXML/SecureUIPanelTemplates.lua:44-79). Their
    parents are the quest panels, children of QuestFrame, so each panel sits
    a level above QuestFrame's backdrop. The re-anchoring below is the
    Layer 1 skin's and stays: it is skin-time widget API, written into no
    table.

    QuestFrameCloseButton (row A6d, the Fable review of A5 to A8, finding
    1): QuestFrameDetailPanel_OnShow disables it for an auto-accepted quest
    (:543, :547-551; Forever :566, :570-574), inside QUEST_DETAIL
    (QuestFrameDetailPanel:Show(), :62; Forever :64) and so before the same
    ShowUIPanel. It is the close button of QuestFrame's ButtonFrameTemplate
    (PortraitFrameTemplate's $parentCloseButton,
    Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:631-633; Forever
    :658-660), a UIPanelCloseButtonDefaultAnchors like the loot window's, so
    it gets the same panel and the same Forever case.
    Skin.ButtonFrameTemplate is written out for QuestFrame below to give it
    the Layer 2 skin; the shared template is not changed. ]]

-- Shape "panel" for QuestFrame.CloseButton: the same template, box and
-- Forever case as the loot window's close button (Mainline/LootFrame.lua,
-- TaintSafeCloseButton; the helpers are to be folded into one shared copy
-- later). Its state textures are set in XML only; frameLevel 510
-- (Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:134; Forever the
-- same line) keeps its panel far above QuestFrame's backdrop.
local function TaintSafeCloseButton(Button)
    local panel = Skin.TaintSafeFrameTypeButton(Button, "panel")
    panel:ClearAllPoints()
    if private.isForever then
        -- Camelot's OnLoad: 28x28 at TOPRIGHT 0, 3
        -- (Blizzard_SharedXML/Camelot/SharedUIPanelTemplates.lua:1-5).
        panel:SetPoint("TOPRIGHT", Button, -2.8, -6)
    else
        panel:SetPoint("TOPRIGHT", Button, -3.8, -3)
    end
    panel:SetSize(17, 17)

    local bg = panel:GetBackdropTexture("bg")
    for i = 1, 2 do
        local line = panel:CreateLine(nil, "ARTWORK")
        line:SetColorTexture(1, 1, 1) -- static: not a theme color
        line:SetThickness(1.2)
        if i == 1 then
            line:SetStartPoint("TOPLEFT", bg, 3.6, -3)
            line:SetEndPoint("BOTTOMRIGHT", bg, -3, 3)
        else
            line:SetStartPoint("TOPRIGHT", bg, -3, -3)
            line:SetEndPoint("BOTTOMLEFT", bg, 3.6, 3)
        end
    end
end

function private.FrameXML.QuestFrame()
    _G.hooksecurefunc("QuestFrameProgressItems_Update", Hook.QuestFrameProgressItems_Update)
    _G.hooksecurefunc("QuestFrameGreetingPanel_OnShow", Hook.QuestFrameGreetingPanel_OnShow)
    _G.QuestFrameGreetingPanel:HookScript("OnShow", Hook.QuestFrameGreetingPanel_OnShow)
    _G.hooksecurefunc("QuestFrame_UpdatePortraitText", Hook.QuestFrame_UpdatePortraitText)
    _G.hooksecurefunc("QuestFrame_ShowQuestPortrait", Hook.QuestFrame_ShowQuestPortrait)
    _G.hooksecurefunc("QuestFrame_SetTitleTextColor", Hook.QuestFrame_SetTitleTextColor)
    _G.hooksecurefunc("QuestFrame_SetTextColor", Hook.QuestFrame_SetTextColor)

    ----------------
    -- QuestFrame --
    ----------------
    -- Skin.ButtonFrameTemplate (Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua),
    -- its retail branch written out so the close button gets the Layer 2
    -- skin. This file loads on Mainline and Forever only, where
    -- private.isRetail is true.
    local QuestFrame = _G.QuestFrame
    QuestFrame.NineSlice.Center = QuestFrame.Bg
    QuestFrame.TopTileStreaks:SetTexture("")
    Skin.PortraitFrameBaseTemplate(QuestFrame)
    TaintSafeCloseButton(QuestFrame.CloseButton)
    Skin.InsetFrameTemplate(QuestFrame.Inset)
    Skin.QuestFramePanelTemplate(_G.QuestFrameRewardPanel)
    Skin.TaintSafeUIPanelButtonTemplate(_G.QuestFrameCompleteQuestButton, "panel")
    _G.QuestFrameCompleteQuestButton:SetPoint("BOTTOMLEFT", 5, 5)
    Skin.QuestScrollFrameTemplate(_G.QuestRewardScrollFrame)

    Skin.QuestFramePanelTemplate(_G.QuestFrameProgressPanel)
    Skin.UIPanelButtonTemplate(_G.QuestFrameGoodbyeButton)
    _G.QuestFrameGoodbyeButton:SetPoint("BOTTOMRIGHT", -5, 5)
    Skin.TaintSafeUIPanelButtonTemplate(_G.QuestFrameCompleteButton, "panel")
    _G.QuestFrameCompleteButton:SetPoint("BOTTOMLEFT", 5, 5)
    Skin.QuestScrollFrameTemplate(_G.QuestProgressScrollFrame)
    for i = 1, _G.MAX_REQUIRED_ITEMS do
        Skin.QuestItemTemplate(_G["QuestProgressItem"..i])
    end

    Skin.QuestFramePanelTemplate(_G.QuestFrameDetailPanel)
    Skin.UIPanelButtonTemplate(_G.QuestFrameDeclineButton)
    _G.QuestFrameDeclineButton:SetPoint("BOTTOMRIGHT", -5, 5)
    Skin.TaintSafeUIPanelButtonTemplate(_G.QuestFrameAcceptButton, "panel")
    _G.QuestFrameAcceptButton:SetPoint("BOTTOMLEFT", 5, 5)
    Skin.QuestScrollFrameTemplate(_G.QuestFrameDetailPanel.ScrollFrame)

    Skin.QuestFramePanelTemplate(_G.QuestFrameGreetingPanel)
    Skin.UIPanelButtonTemplate(_G.QuestFrameGreetingGoodbyeButton)
    _G.QuestFrameGreetingGoodbyeButton:SetPoint("BOTTOMRIGHT", -5, 5)
    Skin.QuestScrollFrameTemplate(_G.QuestGreetingScrollFrame)
    _G.QuestGreetingFrameHorizontalBreak:SetColorTexture(1, 1, 1, .2) -- static: not a theme color
    _G.QuestGreetingFrameHorizontalBreak:SetSize(256, 1)
    -------------------
    -- QuestNPCModel --
    -------------------
    local QuestModel = _G.QuestModelScene

    local modelBackground = _G.CreateFrame("Frame", nil, QuestModel)
    local ModelTextFrame =  _G.CreateFrame("Frame", nil, _G.QuestModelScene.ModelTextFrame)

    modelBackground:SetPoint("TOPLEFT", -1, 1)
    modelBackground:SetPoint("BOTTOMRIGHT", 1, -2)
    modelBackground:SetFrameLevel(0)
    Skin.FrameTypeFrame(modelBackground)
    QuestModel.TopBarBg:Hide()
    QuestModel.ModelBackground:Hide()
    QuestModel.Border:Hide()

    modelBackground.TopLeftCorner:Hide()
    modelBackground.TopRightCorner:Hide()
    modelBackground.BottomLeftCorner:Hide()
    modelBackground.BottomRightCorner:Hide()
    modelBackground.RightEdge:Hide()
    modelBackground.LeftEdge:Hide()
    modelBackground.BottomEdge:Hide()


    local QuestNPCModelNameTooltipFrame = _G.QuestNPCModelNameTooltipFrame
    QuestNPCModelNameTooltipFrame:SetPoint("TOPLEFT", _G.QuestNPCModelNameText, 0, 1)
    QuestNPCModelNameTooltipFrame:SetPoint("BOTTOMRIGHT", _G.QuestNPCModelNameText, 0, -1)
    QuestNPCModelNameTooltipFrame:SetFrameLevel(0)
    Skin.FrameTypeFrame(QuestNPCModelNameTooltipFrame)
    QuestNPCModelNameTooltipFrame:SetAlpha(0)
    QuestNPCModelNameTooltipFrame.TopLeftCorner:Hide()
    QuestNPCModelNameTooltipFrame.TopRightCorner:Hide()
    QuestNPCModelNameTooltipFrame.BottomLeftCorner:Hide()
    QuestNPCModelNameTooltipFrame.BottomRightCorner:Hide()
    QuestNPCModelNameTooltipFrame.RightEdge:Hide()
    QuestNPCModelNameTooltipFrame.LeftEdge:Hide()
    QuestNPCModelNameTooltipFrame.BottomEdge:Hide()

    Skin.FrameTypeFrame(ModelTextFrame)
    ModelTextFrame:SetPoint("TOPLEFT",QuestNPCModelNameTooltipFrame, "BOTTOMLEFT", -1, 12)
    ModelTextFrame:SetWidth(200)

    ModelTextFrame.TopLeftCorner:Hide()
    ModelTextFrame.TopRightCorner:Hide()
    ModelTextFrame.BottomLeftCorner:Hide()
    ModelTextFrame.BottomRightCorner:Hide()
    ModelTextFrame.RightEdge:Hide()
    ModelTextFrame.LeftEdge:Hide()
    ModelTextFrame.BottomEdge:Hide()

    local npcModelScroll = _G.QuestNPCModelTextScrollFrame
    Skin.ScrollFrameTemplate(npcModelScroll)
    npcModelScroll:SetPoint("TOPLEFT", 4, -4)
    npcModelScroll:SetPoint("BOTTOMRIGHT", -4, 4)
end

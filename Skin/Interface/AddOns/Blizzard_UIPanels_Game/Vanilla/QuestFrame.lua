local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Classic Era QuestFrame (NPC quest dialog).
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_UIPanels_Game/
    Vanilla/QuestFrame.xml (root L36) and Vanilla/QuestFrameTemplates.xml.
    Four panels inherit QuestFramePanelTemplate: four UNNAMED
    UI-QuestGreeting-* quadrants plus four NAMED $parentMaterial* parchment
    textures. QuestFrame_SetMaterial re-shows the material textures for
    non-parchment quests, so it is post-hooked to keep them hidden.
    Quest text stays readable via the questTextContrast CVar Aurora core sets.
]]

local questPanels = {
    "QuestFrameRewardPanel",
    "QuestFrameProgressPanel",
    "QuestFrameDetailPanel",
    "QuestFrameGreetingPanel",
}

local panelButtons = {
    "QuestFrameCancelButton",
    "QuestFrameCompleteQuestButton",
    "QuestFrameGoodbyeButton",
    "QuestFrameCompleteButton",
    "QuestFrameDeclineButton",
    "QuestFrameAcceptButton",
    "QuestFrameGreetingGoodbyeButton",
}

local scrollFrames = {
    "QuestRewardScrollFrame",
    "QuestProgressScrollFrame",
    "QuestDetailScrollFrame",
    "QuestGreetingScrollFrame",
}

local materialSuffixes = {
    "MaterialTopLeft", "MaterialTopRight", "MaterialBotLeft", "MaterialBotRight",
}

function Hook.QuestFrame_SetMaterial(frame, material)
    local name = frame:GetName()
    for _, suffix in ipairs(materialSuffixes) do
        local texture = _G[name..suffix]
        if texture then
            texture:Hide()
        end
    end
end

-- Blizzard re-colors every quest fontstring on panel show from the quest's
-- background material (dark-on-parchment palettes); with the parchment art
-- hidden the text must stay light.
function Hook.QuestFrame_SetTextColor(fontString, material)
    fontString:SetTextColor(Color.white:GetRGB())
end
function Hook.QuestFrame_SetTitleTextColor(fontString, material)
    fontString:SetTextColor(Color.white:GetRGB())
end
-- Quest title buttons use the QuestFontLeft style — a VIRTUAL font template
-- (dark quest serif). There is no global font object to recolor, the button
-- font object overrides fontstring SetTextColor at render, and era's
-- NORMAL_QUEST_DISPLAY is a plain "%s" (no escape to gsub). The only
-- reliable override is an inline color escape, re-applied after the panel
-- populates (the same approach Blizzard's own TBC+ code uses).
local WHITE_TITLE = "|c%s%%s|r"
function Hook.QuestFrameGreetingPanel_OnShow(self)
    local titleFormat = WHITE_TITLE:format(Color.white.colorStr)
    local i = 1
    while true do
        local questTitleButton = _G["QuestTitleButton"..i]
        if not questTitleButton or not questTitleButton:IsShown() then break end

        local id = questTitleButton:GetID()
        local title
        if questTitleButton.isActive == 1 then
            title = _G.GetActiveTitle(id)
        else
            title = _G.GetAvailableTitle(id)
        end
        if title then
            questTitleButton:SetFormattedText(titleFormat, title)
        end
        i = i + 1
    end

    _G.CurrentQuestsText:SetTextColor(Color.white:GetRGB())
    _G.AvailableQuestsText:SetTextColor(Color.white:GetRGB())
end

function Hook.QuestFrameProgressPanel_OnShow(self)
    -- Required-money text is hardcoded dark in the OnShow (0/0.2 gray)
    local moneyText = _G.QuestProgressRequiredMoneyText
    if moneyText then
        local r = _G.select(1, moneyText:GetTextColor())
        if r < 0.5 then
            moneyText:SetTextColor(Color.white:GetRGB())
        end
    end
end

-- QuestScrollFrameTemplate: legacy UIPanelScrollFrame plus three named
-- scrollbar-track art textures.
local function SkinQuestScrollFrame(ScrollFrame)
    Skin.UIPanelScrollFrameTemplate(ScrollFrame)

    local name = ScrollFrame:GetName()
    _G[name.."Top"]:SetTexture("")
    _G[name.."Bottom"]:SetTexture("")
    _G[name.."Middle"]:SetTexture("")
end

function private.FrameXML.QuestFrame()
    local QuestFrame = _G.QuestFrame

    Skin.FrameTypeFrame(QuestFrame)
    -- Art bounds from the frame's HitRectInsets (right 30, bottom 70)
    QuestFrame:SetBackdropOption("offsets", {
        left = 10,
        right = 30,
        top = 0,
        bottom = 70,
    })

    _G.QuestFramePortrait:SetAlpha(0)
    Skin.UIPanelCloseButton(_G.QuestFrameCloseButton)

    _G.hooksecurefunc("QuestFrame_SetMaterial", Hook.QuestFrame_SetMaterial)
    _G.hooksecurefunc("QuestFrame_SetTextColor", Hook.QuestFrame_SetTextColor)
    _G.hooksecurefunc("QuestFrame_SetTitleTextColor", Hook.QuestFrame_SetTitleTextColor)
    -- The panels' OnShow is XML-bound via function="..." (the function OBJECT
    -- is captured at load), so hooksecurefunc on the global name never fires
    -- for them — HookScript is required.
    _G.QuestFrameProgressPanel:HookScript("OnShow", Hook.QuestFrameProgressPanel_OnShow)
    _G.QuestFrameGreetingPanel:HookScript("OnShow", Hook.QuestFrameGreetingPanel_OnShow)

    for _, name in ipairs(questPanels) do
        local panel = _G[name]
        if panel then
            Util.HideFrameTextures(panel)
        end
    end

    for _, name in ipairs(panelButtons) do
        local button = _G[name]
        if button then
            Skin.UIPanelButtonTemplate(button)
        end
    end

    for _, name in ipairs(scrollFrames) do
        local scrollFrame = _G[name]
        if scrollFrame then
            SkinQuestScrollFrame(scrollFrame)
        end
    end

    for i = 1, 6 do
        local item = _G["QuestProgressItem"..i]
        if item then
            Skin.LargeItemButtonTemplate(item)
        end
    end

    local i = 1
    while _G["QuestTitleButton"..i] do
        local highlight = _G["QuestTitleButton"..i]:GetHighlightTexture()
        -- The template's highlight is alphaMode="ADD", which washes the
        -- color out; flat color needs normal blending.
        highlight:SetBlendMode("BLEND")
        Util.SetHighlightColor(highlight, 0.2)
        i = i + 1
    end

    local hbreak = _G.QuestGreetingFrameHorizontalBreak
    if hbreak then
        hbreak:SetColorTexture(1, 1, 1, 0.2) -- static: divider, not a theme color
        hbreak:SetHeight(1)
    end
end

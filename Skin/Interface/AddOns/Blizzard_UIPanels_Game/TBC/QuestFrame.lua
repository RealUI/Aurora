local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs select

--[[ Core ]]
local Aurora = private.Aurora
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ TBC (anniversary 2.5.6) QuestFrame: a BFT-rooted hybrid — modern
    ButtonFrameTemplate shell with era-style panels inside (evidence:
    wow-ui-source-anniversary/Interface/AddOns/Blizzard_UIPanels_Game/TBC/
    QuestFrame.xml; no Material* parchment textures on the TBC panels, but
    QuestFrame_SetMaterial/SetTextColor still live in the shared
    Classic/QuestFrame.lua and drive text palettes — hooks kept). Era keeps
    its own Vanilla/ file.
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

function Hook.QuestFrame_SetTextColor(fontString, material)
    fontString:SetTextColor(Color.white:GetRGB())
end
function Hook.QuestFrame_SetTitleTextColor(fontString, material)
    fontString:SetTextColor(Color.white:GetRGB())
end

-- Greeting quest titles render dark (QuestFontLeft-style virtual font);
-- same fix as era: inline white escapes re-applied after the panel
-- populates.
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

    if _G.CurrentQuestsText then
        _G.CurrentQuestsText:SetTextColor(Color.white:GetRGB())
    end
    if _G.AvailableQuestsText then
        _G.AvailableQuestsText:SetTextColor(Color.white:GetRGB())
    end
end

function Hook.QuestFrameProgressPanel_OnShow(self)
    local moneyText = _G.QuestProgressRequiredMoneyText
    if moneyText then
        local r = _G.select(1, moneyText:GetTextColor())
        if r < 0.5 then
            moneyText:SetTextColor(Color.white:GetRGB())
        end
    end
end

local function SkinQuestScrollFrame(ScrollFrame)
    Skin.UIPanelScrollFrameTemplate(ScrollFrame)

    local name = ScrollFrame:GetName()
    for _, suffix in ipairs({"Top", "Bottom", "Middle"}) do
        local texture = _G[name..suffix]
        if texture then
            texture:SetTexture("")
        end
    end
end

function private.FrameXML.QuestFrame()
    local QuestFrame = _G.QuestFrame

    -- extra root art (portrait) BEFORE the template skin
    Util.HideFrameTextures(QuestFrame, true)
    Skin.ButtonFrameTemplate(QuestFrame)

    if _G.QuestFramePortrait then
        _G.QuestFramePortrait:SetAlpha(0)
    end

    _G.hooksecurefunc("QuestFrame_SetTextColor", Hook.QuestFrame_SetTextColor)
    _G.hooksecurefunc("QuestFrame_SetTitleTextColor", Hook.QuestFrame_SetTitleTextColor)
    if _G.QuestFrameProgressPanel then
        _G.QuestFrameProgressPanel:HookScript("OnShow", Hook.QuestFrameProgressPanel_OnShow)
    end
    if _G.QuestFrameGreetingPanel then
        _G.QuestFrameGreetingPanel:HookScript("OnShow", Hook.QuestFrameGreetingPanel_OnShow)
    end
    -- The greeting repopulates via the GLOBAL QuestFrameGreetingPanel_OnShow
    -- when switching NPCs without a hide/show transition — hook that too
    -- (double-fire just reapplies the same escape; harmless)
    if _G.QuestFrameGreetingPanel_OnShow then
        _G.hooksecurefunc("QuestFrameGreetingPanel_OnShow", Hook.QuestFrameGreetingPanel_OnShow)
    end

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
        if highlight then
            highlight:SetBlendMode("BLEND")
            Util.SetHighlightColor(highlight, 0.2)
        end
        i = i + 1
    end

    local hbreak = _G.QuestGreetingFrameHorizontalBreak
    if hbreak then
        hbreak:SetColorTexture(1, 1, 1, 0.2) -- static: divider, not a theme color
        hbreak:SetHeight(1)
    end
end

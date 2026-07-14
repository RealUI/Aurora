local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Cata/Mists (5.5.4) quest log — dual-pane ButtonFrameTemplate book:
    BookBg (left) + PageBg parchment (right) + book icon + inner inset
    border strips on the root; control panel (Abandon/Share/Track),
    Close, Show Map button; list + detail scrolls. Quest text goes white
    via the QuestFrame_SetTextColor hook in TBC\QuestFrame.lua (active
    on Mists). Evidence: wow-ui-source-classic/Interface/AddOns/
    Blizzard_UIPanels_Game/Cata/QuestLogFrame.xml.
]]

local function SkinScrollBar(bar)
    if not bar then return end
    if bar.Track and Skin.WowTrimScrollBar then
        Skin.WowTrimScrollBar(bar)
    else
        Skin.UIPanelScrollBarTemplate(bar)
    end
end

function private.FrameXML.QuestLogFrame()
    local QuestLogFrame = _G.QuestLogFrame

    -- book icon, PageBg/BookBg, inner border strips
    Util.HideFrameTextures(QuestLogFrame, true)
    Skin.ButtonFrameTemplate(QuestLogFrame)

    if _G.EmptyQuestLogFrame then
        Util.HideFrameTextures(_G.EmptyQuestLogFrame, true)
    end
    if _G.QuestLogCount then
        Util.HideFrameTextures(_G.QuestLogCount)
    end
    if _G.QuestLogControlPanel then
        Util.HideFrameTextures(_G.QuestLogControlPanel)
    end
    if _G.QuestLogDetailFrame then
        Util.HideFrameTextures(_G.QuestLogDetailFrame, true)
    end
    if _G.QuestLogHighlightFrame then
        if _G.QuestLogSkillHighlight then
            _G.QuestLogSkillHighlight:SetColorTexture(Color.highlight.r, Color.highlight.g, Color.highlight.b, 0.2)
        else
            local region = _G.QuestLogHighlightFrame:GetRegions()
            if region and region:IsObjectType("Texture") then
                region:SetColorTexture(Color.highlight.r, Color.highlight.g, Color.highlight.b, 0.2)
            end
        end
    end

    -- bottom buttons
    for _, name in ipairs({
        "QuestLogFrameAbandonButton", "QuestLogFrameTrackButton",
        "QuestFramePushQuestButton", "QuestLogFrameCancelButton",
    }) do
        if _G[name] then
            Skin.UIPanelButtonTemplate(_G[name])
        end
    end

    -- Show Map: picture + text on a plate
    local showMap = _G.QuestLogFrameShowMapButton
    if showMap then
        Skin.FrameTypeButton(showMap)
        if showMap.texture then
            showMap.texture:SetAlpha(0)
        end
        if showMap.text then
            showMap.text:SetTextColor(Color.white:GetRGB())
        end
    end

    -- reward item buttons
    for i = 1, 10 do
        local item = _G["QuestLogItem"..i]
        if item and item.Icon then
            Skin.LargeItemButtonTemplate(item)
        end
    end

    -- scrolls last (live bar structure least certain)
    local listScroll = _G.QuestLogListScrollFrame
    if listScroll then
        Util.HideFrameTextures(listScroll)
        SkinScrollBar(listScroll.scrollBar or listScroll.ScrollBar or _G.QuestLogListScrollFrameScrollBar)
    end
    local detailScroll = _G.QuestLogDetailScrollFrame
    if detailScroll then
        Util.HideFrameTextures(detailScroll)
        SkinScrollBar(detailScroll.scrollBar or detailScroll.ScrollBar or _G.QuestLogDetailScrollFrameScrollBar)
    end
end

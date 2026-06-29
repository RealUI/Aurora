local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.FrameXML.QuestMapFrame()
    local QuestLogFrame = _G.QuestLogFrame
    if not QuestLogFrame then return end

    -- TBC Classic uses the old QuestLogFrame (not QuestMapFrame).
    -- Apply Aurora backdrop and strip Blizzard textures.
    Base.SetBackdrop(QuestLogFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide portrait/book icon texture
    for i = 1, QuestLogFrame:GetNumRegions() do
        local region = _G.select(i, QuestLogFrame:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and type(texture) == "string" then
                local lower = texture:lower()
                if lower:find("ui%-questlog") or lower:find("ui%-questframe")
                    or lower:find("questlog") or lower:find("bookicon") then
                    region:Hide()
                end
            end
        end
    end

    -- Skin close button
    if _G.QuestLogFrameCloseButton then
        Skin.UIPanelCloseButton(_G.QuestLogFrameCloseButton)
    end

    -- Skin quest list scroll frame (FauxScrollFrameTemplate)
    local listScrollFrame = _G.QuestLogListScrollFrame
    if listScrollFrame then
        local scrollBar = _G.QuestLogListScrollFrameScrollBar
        if scrollBar then
            Skin.ScrollBarThumb(scrollBar.ThumbTexture or _G.QuestLogListScrollFrameScrollBarThumbTexture)
            -- Hide scroll bar background track texture if present
            local track = scrollBar.Track or scrollBar.trackBG
            if track then
                track:SetAlpha(0)
            end
        end
    end

    -- Skin detail scroll frame (UIPanelScrollFrameTemplate)
    local detailScrollFrame = _G.QuestLogDetailScrollFrame
    if detailScrollFrame then
        local scrollBar = _G.QuestLogDetailScrollFrameScrollBar
        if scrollBar then
            Skin.ScrollBarThumb(scrollBar.ThumbTexture or _G.QuestLogDetailScrollFrameScrollBarThumbTexture)
            local track = scrollBar.Track or scrollBar.trackBG
            if track then
                track:SetAlpha(0)
            end
        end
    end

    -- Skin buttons: Abandon, Push (Share), Exit/Track
    if _G.QuestLogFrameAbandonButton then
        Skin.UIPanelButtonTemplate(_G.QuestLogFrameAbandonButton)
    end
    if _G.QuestFramePushQuestButton then
        Skin.UIPanelButtonTemplate(_G.QuestFramePushQuestButton)
    end
    if _G.QuestFrameExitButton then
        Skin.UIPanelButtonTemplate(_G.QuestFrameExitButton)
    end
    -- Wrath/later TBC builds may have a Track button instead
    if _G.QuestLogFrameTrackButton then
        Skin.UIPanelButtonTemplate(_G.QuestLogFrameTrackButton)
    end

    -- Hide the expand/collapse tab textures
    if _G.QuestLogExpandTabLeft then
        _G.QuestLogExpandTabLeft:SetAlpha(0)
    end
    if _G.QuestLogExpandTabMiddle then
        _G.QuestLogExpandTabMiddle:SetAlpha(0)
    end

    -- Hide the quest count border textures
    local countTextures = {
        "QuestLogCountTopRight",
        "QuestLogCountBottomRight",
        "QuestLogCountRight",
        "QuestLogCountTopLeft",
        "QuestLogCountBottomLeft",
        "QuestLogCountLeft",
        "QuestLogCountTopMiddle",
        "QuestLogCountMiddleMiddle",
        "QuestLogCountBottomMiddle",
    }
    for _, texName in _G.ipairs(countTextures) do
        local tex = _G[texName]
        if tex then
            tex:Hide()
        end
    end

    -- Hide the EmptyQuestLogFrame background textures
    local emptyFrame = _G.EmptyQuestLogFrame
    if emptyFrame then
        for i = 1, emptyFrame:GetNumRegions() do
            local region = _G.select(i, emptyFrame:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                region:Hide()
            end
        end
    end

    -- Skin the highlight frame texture
    if _G.QuestLogSkillHighlight then
        _G.QuestLogSkillHighlight:SetColorTexture(Color.highlight.r, Color.highlight.g, Color.highlight.b, 0.35)
    end
end

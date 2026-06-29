local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals select type

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.FrameXML.ItemTextFrame()
    local ItemTextFrame = _G.ItemTextFrame
    if not ItemTextFrame then return end

    -- Apply Aurora backdrop
    Base.SetBackdrop(ItemTextFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide portrait texture
    if _G.ItemTextFramePortrait then
        _G.ItemTextFramePortrait:SetAlpha(0)
    end

    -- Hide border textures (UI-ItemText art)
    for i = 1, ItemTextFrame:GetNumRegions() do
        local region = _G.select(i, ItemTextFrame:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and type(texture) == "string" and (texture:find("UI%-ItemText") or texture:find("UI%-DialogBox")) then
                region:Hide()
            end
        end
    end

    -- Skin page navigation buttons
    if _G.ItemTextNextPageButton then
        Skin.UIPanelButtonTemplate(_G.ItemTextNextPageButton)
    end
    if _G.ItemTextPrevPageButton then
        Skin.UIPanelButtonTemplate(_G.ItemTextPrevPageButton)
    end

    -- Skin close button
    if _G.ItemTextCloseButton then
        Skin.UIPanelCloseButton(_G.ItemTextCloseButton)
    end

    -- Skin scroll frame
    local scrollFrame = _G.ItemTextScrollFrame
    if scrollFrame then
        -- Hide scroll frame background textures
        for i = 1, scrollFrame:GetNumRegions() do
            local region = _G.select(i, scrollFrame:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                local drawLayer = region:GetDrawLayer()
                if drawLayer == "BACKGROUND" or drawLayer == "BORDER" then
                    region:Hide()
                end
            end
        end

        -- Skin scroll bar if present
        local scrollBar = _G.ItemTextScrollFrameScrollBar
        if scrollBar then
            if scrollBar.Background then
                scrollBar.Background:Hide()
            end
            if scrollBar.Track and scrollBar.Track.Background then
                scrollBar.Track.Background:Hide()
            end
            -- Skin up/down buttons
            local scrollUpButton = _G.ItemTextScrollFrameScrollBarScrollUpButton
            if scrollUpButton then
                Skin.UIPanelScrollUpButtonTemplate(scrollUpButton)
            end
            local scrollDownButton = _G.ItemTextScrollFrameScrollBarScrollDownButton
            if scrollDownButton then
                Skin.UIPanelScrollDownButtonTemplate(scrollDownButton)
            end
        end
    end
end

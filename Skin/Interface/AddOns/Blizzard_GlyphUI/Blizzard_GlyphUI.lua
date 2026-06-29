local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

function private.AddOns.Blizzard_GlyphUI()
    local GlyphFrame = _G.GlyphFrame
    if not GlyphFrame then return end

    -- Apply Aurora backdrop to the main glyph frame
    Base.SetBackdrop(GlyphFrame, Color.frame, Util.GetFrameAlpha())

    -- Hide portrait texture
    if _G.GlyphFramePortrait then
        _G.GlyphFramePortrait:SetAlpha(0)
    end

    -- Hide border textures
    local borderTextures = {
        "GlyphFrameTopLeft",
        "GlyphFrameTopRight",
        "GlyphFrameBottomLeft",
        "GlyphFrameBottomRight",
        "GlyphFrameTop",
        "GlyphFrameBottom",
        "GlyphFrameLeft",
        "GlyphFrameRight",
    }
    for _, texName in _G.ipairs(borderTextures) do
        local tex = _G[texName]
        if tex then
            tex:Hide()
        end
    end

    -- Skin glyph socket slots (GlyphFrameGlyph1 through GlyphFrameGlyph6)
    for i = 1, 6 do
        local glyph = _G["GlyphFrameGlyph" .. i]
        if glyph then
            -- Hide the ring/socket art textures
            if glyph.Ring then
                glyph.Ring:Hide()
            end
            if glyph.Glow then
                glyph.Glow:Hide()
            end
            if glyph.Highlight then
                glyph.Highlight:SetAlpha(0)
            end
            -- Crop the icon if present
            local icon = glyph.Icon or _G["GlyphFrameGlyph" .. i .. "Icon"]
            if icon then
                Base.CropIcon(icon, glyph)
            end
        end
    end

    -- Skin glyph selection scroll frame
    local scrollFrame = _G.GlyphFrameScrollFrame
    if scrollFrame then
        Skin.UIPanelScrollFrameTemplate(scrollFrame)
    end

    -- Skin close button
    if _G.GlyphFrameCloseButton then
        Skin.UIPanelCloseButton(_G.GlyphFrameCloseButton)
    end
end

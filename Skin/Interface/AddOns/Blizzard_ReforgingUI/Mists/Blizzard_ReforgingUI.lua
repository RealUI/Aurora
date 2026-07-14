local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Mists (5.5.4) reforging window — EtherealFrameTemplate chrome
    (classic Skin.EtherealFrameTemplate from Blizzard_UIPanelTemplates\
    Classic) with an item slot, current/target stat columns (radio-style
    stat rows kept — their sheet textures are functional state) and the
    reforge/restore MagicButtons. Evidence: wow-ui-source-classic/
    Interface/AddOns/Blizzard_ReforgingUI/Classic/Blizzard_ReforgingUI.xml.
]]

function private.AddOns.Blizzard_ReforgingUI()
    local ReforgingFrame = _G.ReforgingFrame
    if not ReforgingFrame then return end

    -- alpha-sweeps the marble/purple-tint/EtherealLines body art and the
    -- template chrome, then backdrops
    Skin.EtherealFrameTemplate(ReforgingFrame)

    -- content/state textures that must survive the sweep: the parchment
    -- receipt (black RestoreMessage text renders on it), the missing-item
    -- fade overlay, the stat-column divider
    for _, texture in ipairs({
        _G.ReforgingFrameReceiptBG,
        _G.ReforgingFrameMissingFadeOut,
        _G.ReforgingFrameHorzBar,
    }) do
        if texture then
            texture:SetAlpha(1)
        end
    end

    local itemButton = _G.ReforgingFrameItemButton
    if itemButton then
        -- ornate Reforge-Texture ring + the long "drag an item" plaque
        -- with its two Transmogrify grabber caps
        for _, suffix in ipairs({"Frame", "Grabber", "TextFrame", "TextGrabber"}) do
            local texture = _G["ReforgingFrameItemButton"..suffix]
            if texture then
                texture:SetAlpha(0)
            end
        end
        -- hand-rolled button (named-global children, no Count/icon
        -- parentKeys) — Skin.FrameTypeItemButton would error on it
        Base.SetBackdrop(itemButton, Color.frame, Color.frame.a)
        if _G.ReforgingFrameItemButtonIconTexture then
            Base.CropIcon(_G.ReforgingFrameItemButtonIconTexture)
        end
        local pushed = itemButton:GetPushedTexture()
        if pushed then
            Base.CropIcon(pushed)
        end
        local highlight = itemButton:GetHighlightTexture()
        if highlight then
            local r, g, b = Color.highlight:GetRGB()
            highlight:SetBlendMode("BLEND")
            highlight:SetColorTexture(r, g, b, 0.2)
        end
    end

    -- bottom button bar: inner/bottom tile borders
    if _G.ReforgingFrameButtonFrame then
        Util.HideFrameTextures(_G.ReforgingFrameButtonFrame)
    end

    if _G.ReforgingFrameRestoreButton then
        Skin.MagicButtonTemplate(_G.ReforgingFrameRestoreButton)
    end
    if _G.ReforgingFrameReforgeButton then
        Skin.MagicButtonTemplate(_G.ReforgingFrameReforgeButton)
    end
end

local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs select

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Mists (5.5.4) talent UI — the MoP design: ButtonFrameTemplate root
    with a Specialization pane (paper scroll + spec plaque buttons), the
    6-row/3-column talent grid, and the Glyph tab (own addon,
    Blizzard_GlyphUI). Shadows the Classic/ file on Mists (that one is
    isMists-gated by design). Evidence: wow-ui-source-classic/Interface/
    AddOns/Blizzard_TalentUI/Mists/Blizzard_TalentUI.xml + Classic/
    Blizzard_TalentUI_Shared.xml (tabs inherit
    CharacterFrameTabButtonTemplate — the Cata tab skin covers them).
]]

local rowArt = {
    "Bg", "LeftCap", "RightCap",
    "Separator1", "Separator2", "Separator3",
}

-- turn an ornate state texture into a flat plate covering its parent;
-- Blizzard's show/hide logic keeps driving it. Re-anchoring matters: the
-- source art intentionally overflows its button (224x80 plaques on 204x60
-- buttons, a 256x128 spec-lock), so a bare recolor bleeds way outside.
local function FlattenStateTexture(texture, parent, r, g, b, a)
    if not texture then return end
    texture:SetBlendMode("BLEND")
    texture:SetColorTexture(r, g, b, a)
    if parent then
        texture:ClearAllPoints()
        texture:SetAllPoints(parent)
    end
end

local function SkinTalentButton(button)
    if button.icon then
        Base.CropIcon(button.icon)
    end
    if button.Slot then
        button.Slot:SetAlpha(0)
    end

    -- knownSelection/learnSelection are ornate gold frames from the
    -- talent-main sheet — flatten to dark selection plates; hover stays
    -- the Aurora highlight tint
    FlattenStateTexture(button.knownSelection, button, 0, 0, 0, 0.5)
    FlattenStateTexture(button.learnSelection, button, 0, 0, 0, 0.5)
    local hr, hg, hb = Color.highlight:GetRGB()
    FlattenStateTexture(button:GetHighlightTexture(), button, hr, hg, hb, 0.2)
end

local function SkinSpecPane(pane)
    if not pane then return end

    -- paper scroll bg + the UNNAMED bluemenu column/gold border/filigree
    -- textures (no parentKeys — only a region sweep reaches them)
    Util.HideFrameTextures(pane)

    -- an ANONYMOUS child frame ("raised frame for shadows") carries the
    -- column corners, the vertical gold divider and the side lines
    for i = 1, _G.select("#", pane:GetChildren()) do
        local child = _G.select(i, pane:GetChildren())
        if child:GetObjectType() == "Frame" and not child:GetName() then
            Util.HideFrameTextures(child)
        end
    end

    if pane.learnButton then
        Skin.MagicButtonTemplate(pane.learnButton)
    end

    -- spec plaque buttons: flatten the bluemenu plaque and decorative
    -- ring; RECOLOR (not hide) the selection texture so Blizzard's
    -- show/hide selection logic keeps working
    for i = 1, 4 do
        local button = pane["specButton"..i]
        if button then
            if button.ring then
                button.ring:SetAlpha(0)
            end
            -- all four plaque-art states overflow the button — flatten
            -- AND re-anchor each one: base plate, selected (light gray),
            -- learned spec (gold wash), hover (Aurora highlight)
            FlattenStateTexture(button.bg, button, 0, 0, 0, 0.4)
            FlattenStateTexture(button.selectedTex, button, 1, 1, 1, 0.1)
            FlattenStateTexture(button.learnedTex, button, 1, 0.82, 0, 0.1)
            local hr, hg, hb = Color.highlight:GetRGB()
            FlattenStateTexture(button:GetHighlightTexture(), button, hr, hg, hb, 0.2)
        end
    end

    -- scroll child carries filagree scrollwork, a parchment gradient and
    -- a decorative ring — sweep every texture except the round spec icon
    -- and the role icon (MaskTextures excluded: alpha-ing the CircleMask
    -- would break the icon's round crop)
    local scroll = pane.spellsScroll
    local child = scroll and scroll.child
    if child then
        for i = 1, _G.select("#", child:GetRegions()) do
            local region = _G.select(i, child:GetRegions())
            if region:GetObjectType() == "Texture"
                and region ~= child.specIcon and region ~= child.roleIcon then
                region:SetAlpha(0)
            end
        end
    end
    if scroll and scroll.ScrollBar then
        Skin.UIPanelScrollBarTemplate(scroll.ScrollBar)
    end
end

function private.AddOns.Blizzard_TalentUI()
    local PlayerTalentFrame = _G.PlayerTalentFrame

    -- root art + title glow strips
    Util.HideFrameTextures(PlayerTalentFrame, true)
    Skin.ButtonFrameTemplate(PlayerTalentFrame)

    if _G.PlayerTalentFrameActivateButton then
        Skin.UIPanelButtonTemplate(_G.PlayerTalentFrameActivateButton)
    end

    PlayerTalentFrame.maxTabWidth = 110
    for i = 1, 4 do
        local tab = _G["PlayerTalentFrameTab"..i]
        if tab then
            Skin.CharacterFrameTabButtonTemplate(tab)
        end
    end

    -- side spec tabs (dual spec): spellbook side-tab pattern — hide the
    -- ring sheet via ALPHA (PlayerSpecTab_Update re-sets the texture file
    -- every update, which would undo a SetTexture("")), crop the
    -- runtime-set spec icon (texture object persists across
    -- SetNormalTexture calls, so one crop sticks)
    for i = 1, 2 do
        local tab = _G["PlayerSpecTab"..i]
        if tab then
            local background = _G["PlayerSpecTab"..i.."Background"]
            if background then
                background:SetAlpha(0)
            end
            local normal = tab:GetNormalTexture()
            if normal then
                Base.CropIcon(normal)
            end
        end
    end

    SkinSpecPane(_G.PlayerTalentFrameSpecialization)
    SkinSpecPane(_G.PlayerTalentFramePetSpecialization)

    -- ability buttons on the spec pane are created on demand and their
    -- subText is re-set to parchment-dark brown on every update
    if _G.PlayerTalentFrame_UpdateSpecFrame then
        _G.hooksecurefunc("PlayerTalentFrame_UpdateSpecFrame", function(self)
            local child = self.spellsScroll and self.spellsScroll.child
            if not child then return end
            local index = 1
            local frame = child["abilityButton"..index]
            while frame do
                if frame.ring then
                    frame.ring:SetAlpha(0)
                end
                if frame.subText then
                    frame.subText:SetTextColor(Color.grayLight:GetRGB())
                end
                index = index + 1
                frame = child["abilityButton"..index]
            end
        end)
    end

    -- explicit title glow strips (ADD textures around the title text)
    for _, glowName in ipairs({
        "PlayerTalentFrameTitleGlowLeft",
        "PlayerTalentFrameTitleGlowRight",
        "PlayerTalentFrameTitleGlowCenter",
    }) do
        if _G[glowName] then
            _G[glowName]:SetTexture("")
        end
    end

    -- talent grid: bg + UNNAMED corner/horizontal-tile border art — sweep
    local Talents = _G.PlayerTalentFrameTalents
    if Talents then
        Util.HideFrameTextures(Talents)
        if Talents.learnButton then
            Skin.MagicButtonTemplate(Talents.learnButton)
        end
        if Talents.clearInfo and Talents.clearInfo.icon then
            Base.CropIcon(Talents.clearInfo.icon)
        end

        for tier = 1, 6 do
            local row = Talents["tier"..tier]
            if row then
                local rowName = "PlayerTalentFrameTalentsTalentRow"..tier
                for _, suffix in ipairs(rowArt) do
                    local texture = _G[rowName..suffix]
                    if texture then
                        texture:SetAlpha(0)
                    end
                end
                for col = 1, 3 do
                    if row["talent"..col] then
                        SkinTalentButton(row["talent"..col])
                    end
                end
            end
        end
    end
end

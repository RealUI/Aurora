local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs select hooksecurefunc

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Mists (5.5.4) spell book — the MoP design: ButtonFrameTemplate root
    with two parchment page textures, 12 SpellButtonTemplate slots (heavy
    per-button art: EmptySlot/TextBackgrounds/SlotFrame overlays), skill
    line side tabs, CharacterFrameTab bottom tabs. Evidence:
    wow-ui-source-classic/Interface/AddOns/Blizzard_UIPanels_Game/Mists/
    SpellBookFrame.xml. Professions + Core Abilities pages are first-pass
    stock (their art doubles as layout).
]]

local function SkinSpellButton(button, name)
    -- page-art pieces on the button
    if button.EmptySlot then button.EmptySlot:SetAlpha(0) end
    if button.TextBackground then button.TextBackground:SetAlpha(0) end
    if button.TextBackground2 then button.TextBackground2:SetAlpha(0) end
    local slotFrame = _G[name.."SlotFrame"]
    if slotFrame then
        slotFrame:SetAlpha(0)
    end

    if button.IconTexture then
        Base.CropIcon(button.IconTexture)
    end
    local pushed = button:GetPushedTexture()
    if pushed then Base.CropIcon(pushed) end
    local checked = button:GetCheckedTexture()
    if checked then Base.CropIcon(checked) end
    local highlight = button:GetHighlightTexture()
    if highlight then Base.CropIcon(highlight) end

    -- hardcoded dark brown text
    if button.RequiredLevelString then
        button.RequiredLevelString:SetTextColor(Color.grayLight:GetRGB())
    end
end

function private.FrameXML.SpellBookFrame()
    local SpellBookFrame = _G.SpellBookFrame

    -- page parchment + extra root art BEFORE the template skin
    Util.HideFrameTextures(SpellBookFrame, true)
    Skin.ButtonFrameTemplate(SpellBookFrame)

    for i = 1, 5 do
        local tab = _G["SpellBookFrameTabButton"..i]
        if tab then
            Skin.CharacterFrameTabButtonTemplate(tab)
        end
    end

    -- page navigation
    if _G.SpellBookPageText then
        _G.SpellBookPageText:SetTextColor(Color.white:GetRGB())
    end
    if _G.SpellBookPrevPageButton then
        Skin.NavButtonPrevious(_G.SpellBookPrevPageButton)
    end
    if _G.SpellBookNextPageButton then
        Skin.NavButtonNext(_G.SpellBookNextPageButton)
    end

    -- SpellButtonMixin:UpdateButton re-sets parchment-dark colors on every
    -- update (SpellSubName to literal black, RequiredLevelString and
    -- future-spell SpellName to dark brown) — the mixin method is COPIED
    -- onto each button at creation, so hook it per frame
    local function FixSpellButtonColors(self)
        if self.SpellSubName then
            self.SpellSubName:SetTextColor(Color.grayLight:GetRGB())
        end
        if self.RequiredLevelString then
            self.RequiredLevelString:SetTextColor(Color.grayLight:GetRGB())
        end
        if self.SpellName then
            local r, g, b = self.SpellName:GetTextColor()
            if r < 0.5 and g < 0.5 and b < 0.5 then -- future: 0.25, 0.12, 0
                self.SpellName:SetTextColor(Color.gray:GetRGB())
            end
        end
    end
    for i = 1, 12 do
        local button = _G["SpellButton"..i]
        if button then
            SkinSpellButton(button, "SpellButton"..i)
            if button.UpdateButton then
                _G.hooksecurefunc(button, "UpdateButton", FixSpellButtonColors)
            end
        end
    end

    -- skill line side tabs: hide the ring (first region), crop the icon
    for i = 1, 8 do
        local tab = _G["SpellBookSkillLineTab"..i]
        if tab then
            local ring = tab:GetRegions()
            if ring and ring:IsObjectType("Texture") then
                ring:SetTexture("")
            end
            local normal = tab:GetNormalTexture()
            if normal then
                Base.CropIcon(normal)
            end
        end
    end

    -- dark virtual fonts used for spell sub-text
    if _G.SubSpellFont then
        _G.SubSpellFont:SetTextColor(Color.grayLight:GetRGB())
    end
    if _G.NewSubSpellFont then
        _G.NewSubSpellFont:SetTextColor(Color.grayLight:GetRGB())
    end

    -- Professions page: headers/descriptions are parchment-dark fonts,
    -- only ever SetText'd at runtime — one static recolor sticks
    local professions = {
        _G.PrimaryProfession1, _G.PrimaryProfession2,
        _G.SecondaryProfession1, _G.SecondaryProfession2,
        _G.SecondaryProfession3, _G.SecondaryProfession4,
    }
    for _, frame in ipairs(professions) do
        if frame.professionName then
            frame.professionName:SetTextColor(Color.white:GetRGB())
        end
        if frame.missingHeader then
            frame.missingHeader:SetTextColor(Color.white:GetRGB())
        end
        if frame.missingText then
            frame.missingText:SetTextColor(Color.grayLight:GetRGB())
        end
    end

    -- Core Abilities page: buttons are created on demand with hardcoded
    -- dark <Color> tags — recolor after each tab update
    local CoreAbilities = _G.SpellBookCoreAbilitiesFrame
    if CoreAbilities then
        if CoreAbilities.SpecName then
            CoreAbilities.SpecName:SetTextColor(Color.white:GetRGB())
        end
        if _G.SpellBook_UpdateCoreAbilitiesTab then
            _G.hooksecurefunc("SpellBook_UpdateCoreAbilitiesTab", function()
                for _, button in ipairs(CoreAbilities.Abilities) do
                    button.Name:SetTextColor(Color.white:GetRGB())
                    button.InfoText:SetTextColor(Color.grayLight:GetRGB())
                    button.RequiredLevel:SetTextColor(Color.grayLight:GetRGB())
                end
            end)
        end
    end

    -- What Has Changed page: same on-demand pattern, SimpleHTML entries
    local WhatHasChanged = _G.SpellBookWhatHasChanged
    if WhatHasChanged then
        if WhatHasChanged.ClassName then
            WhatHasChanged.ClassName:SetTextColor(Color.white:GetRGB())
        end
        if _G.SpellBook_UpdateWhatHasChangedTab then
            _G.hooksecurefunc("SpellBook_UpdateWhatHasChangedTab", function()
                for _, entry in ipairs(WhatHasChanged.ChangedItems) do
                    if entry.Title then
                        entry.Title:SetTextColor(Color.white:GetRGB())
                    end
                    -- SimpleHTML wants a textType first (ItemTextFrame.lua precedent)
                    entry:SetTextColor("P", Color.grayLight:GetRGB())
                end
            end)
        end
    end
end

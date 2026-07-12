local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals ipairs select

--[[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

--[[ Vanilla-style SpellBookFrame — loaded on BOTH era and TBC (Blizzard's
    TOC lists Vanilla\SpellBookFrame with [AllowLoadGameType vanilla, tbc]).
    Evidence: wow-ui-source-era/Interface/AddOns/Blizzard_UIPanels_Game/
    Vanilla/SpellBookFrame.xml (root L161: plain 384x512 frame, unnamed
    UI-SpellbookPanel-* quadrants; named SpellBookTitleText/PageText
    fontstrings survive the texture strip). SpellButtonTemplate is a
    CheckButton (not ItemButtonTemplate): parentKey EmptySlot art, named
    $parentIconTexture icon, 64px Quickslot2 NormalTexture ring.
]]

local function SkinSpellButton(Button)
    local name = Button:GetName()

    -- Blizzard re-sets these per update; alpha survives
    Button.EmptySlot:SetAlpha(0)
    Button:GetNormalTexture():SetAlpha(0)
    Button:GetPushedTexture():SetAlpha(0)

    Base.SetBackdrop(Button, Color.black, Color.frame.a)
    local bg = Button:GetBackdropTexture("bg")
    local icon = _G[name.."IconTexture"]
    Base.CropIcon(icon)
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", bg, 1, -1)
    icon:SetPoint("BOTTOMRIGHT", bg, -1, 1)

    Base.CropIcon(Button:GetHighlightTexture())
    Base.CropIcon(Button:GetCheckedTexture())
end

-- Bottom tabs: single UI-SpellBook-Tab-Unselected art with generous hit
-- insets (15/14/13/15) — flat button sized to the hit rect.
local function SkinSpellBookTab(Button)
    Skin.FrameTypeButton(Button)
    Button:SetButtonColor(Color.button, Util.GetFrameAlpha(), false)
    Button:SetBackdropOption("offsets", {
        left = 15,
        right = 14,
        top = 13,
        bottom = 15,
    })
end

-- Side tabs (skill lines): first region is the unnamed ring art; the
-- NormalTexture IS the icon (set from Lua), so it must be kept and cropped.
local function SkinSkillLineTab(Button)
    Button:GetRegions():Hide()

    Base.CropIcon(Button:GetNormalTexture(), Button)
    Base.CropIcon(Button:GetHighlightTexture())
    Base.CropIcon(Button:GetCheckedTexture())
end

function private.FrameXML.SpellBookFrame()
    local SpellBookFrame = _G.SpellBookFrame

    -- Unnamed Spellbook-Icon + UI-SpellbookPanel-* quadrants
    Util.HideFrameTextures(SpellBookFrame)

    Skin.FrameTypeFrame(SpellBookFrame)
    -- Art bounds from HitRectInsets (right 30, bottom 70)
    SpellBookFrame:SetBackdropOption("offsets", {
        left = 10,
        right = 30,
        top = 0,
        bottom = 70,
    })

    Skin.UIPanelCloseButton(_G.SpellBookCloseButton)

    for i = 1, 12 do
        SkinSpellButton(_G["SpellButton"..i])
    end

    local i = 1
    while _G["SpellBookFrameTabButton"..i] do
        SkinSpellBookTab(_G["SpellBookFrameTabButton"..i])
        i = i + 1
    end

    i = 1
    while _G["SpellBookSkillLineTab"..i] do
        SkinSkillLineTab(_G["SpellBookSkillLineTab"..i])
        i = i + 1
    end

    -- Unlike the merchant pager these have no layer regions (no circle
    -- background/label) — just state textures, which FrameTypeButton strips.
    Skin.NavButtonPrevious(_G.SpellBookPrevPageButton)
    Skin.NavButtonNext(_G.SpellBookNextPageButton)

    if _G.ShowAllSpellRanksCheckbox then
        Skin.UICheckButtonTemplate(_G.ShowAllSpellRanksCheckbox)
    end

    -- Sub-spell text ("Rank x"/"Passive") uses a dark parchment font
    if _G.SubSpellFont then
        _G.SubSpellFont:SetTextColor(Color.grayLight:GetRGB())
    end
end

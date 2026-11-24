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

--[[ B261 Layer 2 (tier A, row A12, with the pulled-forward tabs and close
    button of tasks.md 3.2.6.1), read from wow-ui-source-era and
    wow-ui-source-anniversary (the lines below are the same in both).
    SpellBookFrame is protected (checkpoint 0, `buttonscan protected` on TBC
    and Vanilla). SPELLS_CHANGED with the book open, LEARNED_SPELL_IN_SKILL_LINE
    always (Blizzard_UIPanels_Game/Vanilla/SpellBookFrame.lua:36-44) run
    SpellBookFrameMixin:Update (:58), which disables the selected bottom tab
    and enables the other (SetTabType, :110-127) and runs the page's update
    (:104-107); for the spell page that is SpellBook_UpdatePlayerTab
    (Classic/SpellBookFrame.lua:510-522): UpdatePages disables or enables the
    two page buttons (Vanilla/SpellBookFrame.lua:128-160), then UpdateSpells
    disables or enables the protected spell buttons (:246, :252;
    SecureFrameTemplate, Vanilla/SpellBookFrame.xml:69). So nothing of
    Aurora's may be on the page buttons, the tabs or the close button, or run
    on their state.
    Task 5.4 (step 20): SpellButton1-12 and ShowAllSpellRanksCheckbox no
    longer carry Aurora's backdrop (below). Still in this file: the backdrop
    Skin.FrameTypeFrame puts on SpellBookFrame itself, a frame the scan does
    not walk; outside 5.4, left for its triage row (tasks.md 7.1). ]]

-- Shape "panel" for the page buttons, drawn by Skin.TaintSafeNavButton
-- (Skin/skin.lua): plain buttons declared in XML
-- (Vanilla/SpellBookFrame.xml:223-249), not pooled and not layout frames,
-- their state textures set in XML only; Blizzard only enables and disables
-- them (above). The box sits 5 inside the button, as the Layer 1 skin
-- (Skin.NavButtonPrevious) drew it; the arrow is on the panel.

-- Shape "panel" for the close button, drawn by Skin.TaintSafePanelCloseButton
-- (Skin/skin.lua): SpellBookCloseButton is a
-- UIPanelCloseButton (Vanilla/SpellBookFrame.xml:251;
-- Blizzard_SharedXML/Classic/SharedUIPanelTemplates.xml:172-192), 32x32, its
-- state textures set in XML only and never re-set. The box and the cross are
-- where the Layer 1 skin (Skin.UIPanelCloseButtonNoScripts) drew them; the
-- cross is on the panel.

local function SkinSpellButton(Button)
    local name = Button:GetName()

    -- Blizzard re-sets these per update; alpha survives
    Button.EmptySlot:SetAlpha(0)
    Button:GetNormalTexture():SetAlpha(0)
    Button:GetPushedTexture():SetAlpha(0)

    --[[ B261 (task 5.4): the buttons are protected themselves
        (SecureFrameTemplate, Vanilla/SpellBookFrame.xml:69), so no
        backdrop, key or frame of Aurora's on them. The Layer 1 look was
        Base.SetBackdrop(Button, Color.black, Color.frame.a): a fill over the
        whole button and a 1px edge, both black, the icon 1px inside. Drawn
        now with one texture of the button's own, made once at skin time,
        under the icon: the edge takes the fill's alpha, a step the eye does
        not see on black. ]]
    local bg = Button:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints()
    bg:SetColorTexture(Color.black.r, Color.black.g, Color.black.b, Color.frame.a)

    local icon = _G[name.."IconTexture"]
    Base.CropIcon(icon)
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", Button, 1, -1)
    icon:SetPoint("BOTTOMRIGHT", Button, -1, 1)

    Base.CropIcon(Button:GetHighlightTexture())
    Base.CropIcon(Button:GetCheckedTexture())
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

    Skin.TaintSafePanelCloseButton(_G.SpellBookCloseButton)

    for i = 1, 12 do
        SkinSpellButton(_G["SpellButton"..i])
    end

    -- SpellBookFrameTabButton1-3 stay Blizzard's (shape c): the selected tab
    -- is drawn by Blizzard's art. SetTabType disables the tab of the open
    -- book and enables the other on every Update (Vanilla/SpellBookFrame.lua:121-125),
    -- and a disabled tab shows its own "selected" art, its DisabledTexture
    -- (Vanilla/SpellBookFrame.xml:193, :199, :205). Engine-drawn state would
    -- show the selected tab as a disabled one.

    local i = 1
    while _G["SpellBookSkillLineTab"..i] do
        SkinSkillLineTab(_G["SpellBookSkillLineTab"..i])
        i = i + 1
    end

    -- Unlike the merchant pager these have no layer regions (no circle
    -- background/label) — just state textures, which the Layer 2 skin replaces.
    Skin.TaintSafeNavButton(_G.SpellBookPrevPageButton, "arrowLeft")
    Skin.TaintSafeNavButton(_G.SpellBookNextPageButton, "arrowRight")

    --[[ B261 (task 5.4): ShowAllSpellRanksCheckbox
        (OptionsSmallCheckButtonTemplate, Vanilla/SpellBookFrame.xml:256) is
        not protected itself but sits under the protected SpellBookFrame, so
        the panel form step 15 gave the quick keybind check box: the Layer 2
        panel with the box 6 inside, and the checked texture restyled in
        place as Skin.UICheckButtonTemplate does it. Blizzard only shows and
        hides it (Vanilla/SpellBookFrame.lua:170-172). ]]
    local ranks = _G.ShowAllSpellRanksCheckbox
    if ranks then
        local panel = Skin.TaintSafeFrameTypeButton(ranks, "panel")
        panel:SetBackdropOption("offsets", {
            left = 6,
            right = 6,
            top = 6,
            bottom = 6,
        })
        Base.SetBackdropColor(panel, Color.button, 0.3)

        local box = panel:GetBackdropTexture("bg")
        local check = ranks:GetCheckedTexture()
        check:ClearAllPoints()
        check:SetPoint("TOPLEFT", box, -6, 6)
        check:SetPoint("BOTTOMRIGHT", box, 6, -6)
        check:SetDesaturated(true)
        check:SetVertexColor(Color.highlight:GetRGB())

        local disabled = ranks:GetDisabledCheckedTexture()
        if disabled then
            disabled:SetAllPoints(check)
        end
    end

    -- Sub-spell text ("Rank x"/"Passive") uses a dark parchment font
    if _G.SubSpellFont then
        _G.SubSpellFont:SetTextColor(Color.grayLight:GetRGB())
    end
end

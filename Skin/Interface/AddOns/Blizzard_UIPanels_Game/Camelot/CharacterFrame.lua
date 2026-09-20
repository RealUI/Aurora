local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Skin = Aurora.Skin
local Color = Aurora.Color

-- Camelot's character panel is a different shape from retail's (T2.0.1):
--
--   retail                       Camelot
--   ------                       -------
--   inherits ButtonFrameTemplate inherits PortraitFrameBaseTemplate
--   CharacterFrame.Inset         CharacterFrame.LeftPaneHost
--   CharacterFrame.InsetRight    CharacterFrame.RightPaneHost (+ RightPaneToggleButton)
--   CharacterFrameTab1-3 bottom  CharacterFrameModeTab1-6 side tabs, via ModeTabs
--
-- The retained retail internals -- CharacterStatsPane and the
-- CharacterStatFrame* family -- are skinned the same way, so those two template
-- functions are duplicated from the Mainline file rather than shared: they are
-- about twenty lines and have no callers outside their own CharacterFrame skin,
-- which is under D3.1's threshold for earning a Skin\shared\ file.

do --[[ FrameXML\CharacterFrame.xml ]]
    function Skin.CharacterStatFrameCategoryTemplate(Button)
        local bg = Button.Background
        bg:SetTexture([[Interface\LFGFrame\UI-LFG-SEPARATOR]])
        bg:SetTexCoord(0, 0.6640625, 0, 0.3125)
        bg:ClearAllPoints()
        bg:SetPoint("CENTER", 0, -5)
        bg:SetSize(210, 30)

        local r, g, b = Color.highlight:GetRGB()
        bg:SetVertexColor(r * 0.7, g * 0.7, b * 0.7)
    end
    function Skin.CharacterStatFrameTemplate(Button)
        local bg = Button.Background
        bg:ClearAllPoints()
        bg:SetPoint("TOPLEFT")
        bg:SetPoint("BOTTOMRIGHT")
        bg:SetColorTexture(1, 1, 1, 0.2) -- static: not a theme color
    end

    -- The side-pane row set. Every CharacterFrameSidePaneTemplate builds its
    -- contents from one FramePoolCollection of four row templates, so skinning
    -- them here covers **every** Camelot detail pane at once: reputation,
    -- skills, currency and the PvP rank pane.
    --
    -- Only two of the four carry art. CharacterFrameSidePaneRowTemplate and
    -- ...WrappedRowTemplate are FontStrings alone and need nothing.
    function Skin.CharacterFrameSidePaneCategoryTemplate(Frame)
        -- UI-Character-Info-Title, the brown header plate.
        if Frame.Background then
            Frame.Background:SetAlpha(0)
        end
        Base.SetBackdrop(Frame, Color.button)
    end

    function Skin.CharacterFrameSidePaneIconRowTemplate(Frame)
        -- IconSlot is UI-Character-Info-GearSlot -- the same gold slot art the
        -- paperdoll sweeps by atlas. Here it has a parentKey, so it is direct.
        if Frame.IconSlot then
            Frame.IconSlot:SetAlpha(0)
        end
        Base.CropIcon(Frame.Icon, Frame)
    end

    -- Rows are pooled and recycled, and AcquireRow is the single point they all
    -- come through. hooksecurefunc cannot see the return value, so the hook
    -- re-sweeps the active set instead; the IsSkinned guard absorbs the repeat.
    -- Swept once up front too, because a pane may already be populated.
    function Skin.CharacterFrameSidePaneTemplate(Frame)
        if not Frame or not Frame.rowPools then return end

        local function SkinRows()
            for row in Frame.rowPools:EnumerateActive() do
                if not private.IsSkinned(row) then
                    private.SetSkinned(row, true)
                    if row.Background then
                        Skin.CharacterFrameSidePaneCategoryTemplate(row)
                    elseif row.IconSlot then
                        Skin.CharacterFrameSidePaneIconRowTemplate(row)
                    end
                end
            end
        end

        SkinRows()
        if Frame.AcquireRow and not Frame._auroraRowsHooked then
            Frame._auroraRowsHooked = true
            _G.hooksecurefunc(Frame, "AcquireRow", SkinRows)
        end
    end

    -- CharacterFrameModeSideTabTemplate adds only a fillToInterior KeyValue and
    -- an OnLoad on top of LargeSideTabButtonTemplate, so the shared side-tab
    -- skin covers it. Camelot's bank page tabs use the same base.
    function Skin.CharacterFrameModeSideTabTemplate(Frame)
        Skin.LargeSideTabButtonTemplate(Frame)
    end
end

-- The pane hosts are pure background containers: every Texture on them is
-- Blizzard's stone/parchment art (UI-Character-Info-General-BG,
-- UI-Character-Info-Stat-BG, the StoneBg overlay and a common-framedivider).
-- Hiding by region type rather than by index keeps this clear of the
-- positional-pick hazard that bit the mail frame.
local function HidePaneArt(host)
    if not host then return end
    for _, region in next, {host:GetRegions()} do
        if region:IsObjectType("Texture") then
            region:Hide()
        end
    end

    -- The common-framedivider between the two panes is not a region of the
    -- host: it sits on an unnamed child Frame, so the loop above never reached
    -- it and the gold rule stayed on screen. Sweep one level down, but by
    -- atlas -- the children also carry ItemLevelFrame, the stat categories and
    -- other content that must not be blanked.
    for _, child in next, {host:GetChildren()} do
        for _, region in next, {child:GetRegions()} do
            if region:IsObjectType("Texture") then
                local atlas = region:GetAtlas()
                if atlas and (atlas:find("common%-framedivider")
                    or atlas:find("UI%-Character%-Info%-Stat%-BG")
                    or atlas:find("UI%-Character%-Info%-General%-BG")) then
                    region:Hide()
                end
            end
        end
    end
end

function private.FrameXML.CharacterFrame()
    local CharacterFrame = _G.CharacterFrame

    Skin.PortraitFrameBaseTemplate(CharacterFrame)
    if CharacterFrame.CloseButton then
        Skin.UIPanelCloseButtonDefaultAnchors(CharacterFrame.CloseButton)
    end

    HidePaneArt(CharacterFrame.LeftPaneHost)
    HidePaneArt(CharacterFrame.RightPaneHost)

    -- Side tabs: Character / Reputation / Skills / PvP / Currency / Statistics.
    -- Built from what exists rather than a fixed 1..6, the same way the
    -- InspectUI and FriendsFrame tab lists are.
    for i = 1, 6 do
        local tab = _G["CharacterFrameModeTab" .. i]
        if tab then
            Skin.CharacterFrameModeSideTabTemplate(tab)
        end
    end

    -- The right-pane toggle carries UI-SpellbookIcon-PrevPage-Up/Down, a
    -- spellbook page arrow sized for Blizzard's art. On a 28x28 Aurora button
    -- it reads as a stray icon, so replace it with Aurora's own arrow the way
    -- the scroll buttons do.
    local RightPaneToggleButton = CharacterFrame.RightPaneToggleButton
    if RightPaneToggleButton then
        Skin.FrameTypeButton(RightPaneToggleButton)
        RightPaneToggleButton:SetSize(18, 18)

        for _, getter in next, {"GetNormalTexture", "GetPushedTexture", "GetHighlightTexture"} do
            local tex = RightPaneToggleButton[getter] and RightPaneToggleButton[getter](RightPaneToggleButton)
            if tex then tex:SetAlpha(0) end
        end

        if not RightPaneToggleButton._auroraArrow then
            local bg = RightPaneToggleButton:GetBackdropTexture("bg")
            local arrow = RightPaneToggleButton:CreateTexture(nil, "ARTWORK")
            arrow:SetPoint("TOPLEFT", bg, 4, -4)
            arrow:SetPoint("BOTTOMRIGHT", bg, -4, 4)
            Base.SetTexture(arrow, "arrowLeft")
            RightPaneToggleButton._auroraArrow = arrow
        end
    end

    -- Retained retail internals ------------------------------------------
    if _G.PaperDollFrame_SetStat then
        _G.hooksecurefunc("PaperDollFrame_SetStat", function(statFrame)
            if statFrame and statFrame.Background then
                Skin.CharacterStatFrameTemplate(statFrame)
            end
        end)
    end

    -- CharacterStatsPaneScrollBoxTemplate carries its own chrome, separate from
    -- the pane hosts HidePaneArt sweeps: a common-insideframe Border (the
    -- ornate gold plate around the stat list) and decorative
    -- UI-Character-Info-ScrollLine rules, the same pair the Skills and
    -- Statistics tabs have. Both scroll boxes use the template -- the player
    -- one and the pet one -- so both are done here.
    for _, name in next, {"CharacterStatsPaneScrollBox", "CharacterStatsPanePetScrollBox"} do
        local box = _G[name]
        if box then
            if box.Border then
                box.Border:SetAlpha(0)
            end

            Skin.WowScrollBoxList(box.ScrollBox)
            Skin.MinimalScrollBar(box.ScrollBar)

            -- The rules are unnamed, and sit either directly on the container
            -- or one level down depending on the instance, so sweep both.
            local function HideScrollLines(frame)
                for _, region in next, {frame:GetRegions()} do
                    if region:IsObjectType("Texture") then
                        local atlas = region:GetAtlas()
                        if atlas and atlas:find("UI%-Character%-Info%-ScrollLine") then
                            region:Hide()
                        end
                    end
                end
            end

            HideScrollLines(box)
            for _, child in next, {box:GetChildren()} do
                HideScrollLines(child)
            end
        end
    end

    -- Camelot moves ClassBackground onto CharacterStatsPaneScrollBox; on retail
    -- it hangs off CharacterStatsPane.
    local ScrollBox = _G.CharacterStatsPaneScrollBox
    local ClassBackground = ScrollBox and ScrollBox.ClassBackground
    if ClassBackground then
        local atlas = "talents-animations-class-" .. private.charClass.token
        local info = _G.C_Texture.GetAtlasInfo(atlas)
        if info then
            ClassBackground:ClearAllPoints()
            ClassBackground:SetPoint("CENTER")
            ClassBackground:SetSize(_G.Round(info.width * 0.7), _G.Round(info.height * 0.7))
            ClassBackground:SetAtlas(atlas)
            ClassBackground:SetDesaturated(true)
            ClassBackground:SetAlpha(0.4)
        end
    end

    -- The live stats UI ---------------------------------------------------
    -- On Camelot the visible stats are pooled elements in
    -- CharacterStatsPaneScrollBox, not the CharacterStatsPane block below --
    -- that frame is hidden="true" here, the legacy path. The element templates
    -- reuse the same Background/Title/Value keys the two template functions
    -- above already handle, so the work is getting them applied as the
    -- ScrollBox creates elements, the same way the reputation rows are done.
    --
    -- Hooking the mixin tables works because the ScrollBox creates elements
    -- lazily, after this runs. Only two hooks are needed:
    -- CharacterStatFrameScrollBoxIconElementMixin:Init calls the base mixin's
    -- Init by table lookup, so Icon and Label elements both come through it.
    local function HookStatElement(mixin, skinFunc)
        if not mixin or not mixin.Init or not skinFunc then return end

        _G.hooksecurefunc(mixin, "Init", function(element)
            if private.IsSkinned(element) then return end
            private.SetSkinned(element, true)
            skinFunc(element)
        end)
    end

    -- Blizzard's base Init does Background:SetShown(statIndex % 2 == 1) for the
    -- alternating stripe, and runs before this hook, so it keeps driving which
    -- rows show a stripe while the skin only changes what the stripe looks like.
    HookStatElement(_G.CharacterStatFrameCategoryScrollBoxElementMixin,
        Skin.CharacterStatFrameCategoryTemplate)
    HookStatElement(_G.CharacterStatFrameScrollBoxBaseElementMixin,
        Skin.CharacterStatFrameTemplate)

    -- Legacy, kept guarded: hidden on Camelot, but harmless if ever shown.
    local CharacterStatsPane = _G.CharacterStatsPane
    if CharacterStatsPane then
        local ItemLevelFrame = CharacterStatsPane.ItemLevelFrame
        if ItemLevelFrame then
            ItemLevelFrame.Value:SetFontObject("SystemFont_Shadow_Huge2")
            ItemLevelFrame.Value:SetShadowOffset(0, 0)
            if ItemLevelFrame.Background then ItemLevelFrame.Background:Hide() end
        end

        for _, key in next, {"ItemLevelCategory", "AttributesCategory", "EnhancementsCategory"} do
            local category = CharacterStatsPane[key]
            if category and category.Background then
                Skin.CharacterStatFrameCategoryTemplate(category)
            end
        end
    end
end

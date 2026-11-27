local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals type

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook = Aurora.Hook
local Skin = Aurora.Skin
local Color = Aurora.Color
local Util = Aurora.Util
local Config = private.Config

--[[ B261 (tasks 3.2.6.3, 5.3, 5.4), read from wow-ui-source and
    wow-ui-source-forever, not seen in game. PlayerSpellsFrame reads as
    protected (checkpoint 0, `buttonscan protected` on retail). Nothing in
    Blizzard_PlayerSpells is declared secure or protected on either tree,
    so no button here is protected itself; each sits under a protected
    ancestor. So: the panel shape where the button is declared once and not
    measured, flat where it is pooled, and Blizzard's own where Blizzard
    draws its state with art (the tab strips).

    What this file keeps, here and not on Blizzard's frames (each was a
    field on the Blizzard object). Weak keys throughout. ]]
-- Spell book item buttons whose textures and hooks are in place (new: the
-- skin below ran again on every show and stacked its hooks). The buttons are
-- pooled by the paged list; what is stored is the button's own textures and
-- hooks, which go with it to the next spell it shows.
local itemDecorated = _G.setmetatable({}, {__mode = "k"})
-- Was `_auroraAlphaHooked`: the Name and SubName font strings of an item
-- (pooled with their item frame).
local alphaHooked = _G.setmetatable({}, {__mode = "k"})
-- Was `_auroraTextColorHooked`: spell book item frames (pooled).
local textColorHooked = _G.setmetatable({}, {__mode = "k"})
-- Was `_auroraHeaderSkinned`: spell book section headers (pooled; the skin
-- is the header's own regions).
local skinnedHeaders = _G.setmetatable({}, {__mode = "k"})

local function IsConfigEnabled(optionKey)
    local auroraConfig = _G.AuroraConfig or Config and Config.defaults
    return auroraConfig == nil or auroraConfig[optionKey] ~= false
end

local function GetConfigOption(optionKey, fallback)
    local auroraConfig = _G.AuroraConfig or Config and Config.defaults
    if auroraConfig and auroraConfig[optionKey] ~= nil then
        return auroraConfig[optionKey]
    end
    return fallback
end

do  -- PlayerSpellsFrame.SpecFrame
    local RoleIcons = {
        TANK = "groupfinder-icon-role-micro-tank",
        HEALER = "groupfinder-icon-role-micro-heal",
        DAMAGER = "groupfinder-icon-role-micro-dps",
        DPS = "groupfinder-icon-role-micro-dps",
    }

    function Hook.SkinSpellBookItem(frame)
        if not frame.Button then return end

        local button = frame.Button

        -- Mark as skinned first to prevent re-entry
        if private.IsSkinned(button) then return end
        private.SetSkinned(button, true)
        -- The callers below clear the skinned mark and run this again on
        -- every show; textures and hooks are made the first time only.
        local firstTime = not itemDecorated[button]
        itemDecorated[button] = true

        -- Hide the Backplate that creates the dark bar behind text
        if frame.Backplate then
            frame.Backplate:Hide()
        end

        -- Hide text container background if it exists
        if frame.TextContainer then
            for _, region in pairs({frame.TextContainer:GetRegions()}) do
                if region:IsObjectType("Texture") then
                    region:Hide()
                end
            end
        end

        -- Hide the FxModelScene that creates animated effects
        if button.FxModelScene then
            button.FxModelScene:Hide()
            button.FxModelScene:SetAlpha(0)
        end

        -- Aggressively hide the border - it keeps getting reset
        if button.Border then
            button.Border:SetTexture(nil)
            button.Border:SetAlpha(0)
            button.Border:Hide()
            -- Hook SetTexture to prevent it from being set
            if firstTime then
                _G.hooksecurefunc(button.Border, "SetTexture", function(self)
                    self:SetAlpha(0)
                end)
                _G.hooksecurefunc(button.Border, "SetAtlas", function(self)
                    self:SetAlpha(0)
                end)
            end
        end

        if button.TrainableShadow then
            button.TrainableShadow:Hide()
        end
        if button.TrainableBackplate then
            button.TrainableBackplate:SetAlpha(0)
        end
        if button.BorderSheen then
            button.BorderSheen:Hide()
        end
        if button.BorderSheenMask then
            button.BorderSheenMask:Hide()
        end

        -- Crop and position the icon - make it sharper
        if firstTime then
            Base.CropIcon(button.Icon, button)
        end
        button.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        --[[ B261 (task 5.4): the slot behind the icon. Checkpoint 0 found
            Aurora's backdrop on these buttons (33 keys each) under the
            protected PlayerSpellsFrame. Drawn now with two textures of the
            button's own, as the override bar's spell buttons: a 1px border
            outside the button and the empty-slot art inside it, the look
            the backdrop drew. Made once; a pooled button keeps them. ]]
        if firstTime then
            local border = button:CreateTexture(nil, "BACKGROUND", nil, -8)
            border:SetPoint("TOPLEFT", -1, 1)
            border:SetPoint("BOTTOMRIGHT", 1, -1)
            border:SetColorTexture(Color.frame:GetRGB())

            local slot = button:CreateTexture(nil, "BACKGROUND", nil, -7)
            slot:SetAllPoints()
            slot:SetTexture([[Interface\PaperDoll\UI-Backpack-EmptySlot]])
            slot:SetVertexColor(1, 1, 1, 0.75)
            Base.CropIcon(slot)
        end

        -- Handle various overlay textures
        if button.IconHighlight then
            button.IconHighlight:ClearAllPoints()
            button.IconHighlight:SetPoint("TOPLEFT", button.Icon)
            button.IconHighlight:SetPoint("BOTTOMRIGHT", button.Icon)
            -- B07: the hover/press state uses the rounded iconframe atlas;
            -- replace it with the flat square highlight action bar buttons get.
            -- The mixin drives the hover/press alphas, so only the texture is
            -- swapped here (re-applied in the UpdateVisuals hook below because
            -- Blizzard re-sets the atlas there).
            Util.SetHighlightColor(button.IconHighlight)
        end

        -- B07: the flyout border shadow is more rounded Blizzard art; alpha 0
        -- survives the Show/Hide toggling the flyout mixin does.
        if button.BorderShadow then
            button.BorderShadow:SetAlpha(0)
        end

        -- B08: the "not on any action bar" indicator is the rounded
        -- `spellbook-item-unassigned-glow` atlas, anchored to overhang the
        -- button by 3-4px on every side, so it read as a rounded glow around
        -- square icons. Square it to the icon and use the flat highlight
        -- colour. Its pulse comes from an alpha animation on the texture, so
        -- swapping the texture keeps the animation intact.
        if button.ActionBarHighlight then
            button.ActionBarHighlight:ClearAllPoints()
            button.ActionBarHighlight:SetPoint("TOPLEFT", button.Icon)
            button.ActionBarHighlight:SetPoint("BOTTOMRIGHT", button.Icon)
            Util.SetHighlightColor(button.ActionBarHighlight)
        end

        -- Handle AutoCast overlay
        if button.AutoCastOverlay then
            local overlay = button.AutoCastOverlay
            if overlay.Corners then
                overlay.Corners:SetAlpha(0)
            end
        end

        -- Hook the button's UpdateVisuals to maintain skinning and update text colors
        if firstTime and button.UpdateVisuals then
            _G.hooksecurefunc(button, "UpdateVisuals", function(self)
                if self.Border then
                    self.Border:SetTexture(nil)
                    self.Border:SetAlpha(0)
                end
                if self.TrainableBackplate then
                    self.TrainableBackplate:SetAlpha(0)
                end
                if self.FxModelScene then
                    self.FxModelScene:Hide()
                    self.FxModelScene:SetAlpha(0)
                end
            end)
        end

        -- Hook text alpha setting to override Blizzard's values
        if frame.Name and not alphaHooked[frame.Name] then
            _G.hooksecurefunc(frame.Name, "SetAlpha", function(self, alpha)
                -- Always force full alpha for better visibility
                if alpha < 1 then
                    self:SetAlpha(1)
                end
            end)
            alphaHooked[frame.Name] = true
        end

        if frame.SubName and not alphaHooked[frame.SubName] then
            _G.hooksecurefunc(frame.SubName, "SetAlpha", function(self, alpha)
                -- Always force full alpha for better visibility
                if alpha < 1 then
                    self:SetAlpha(1)
                end
            end)
            alphaHooked[frame.SubName] = true
        end

        -- Hook UpdateVisuals on the parent frame to handle text coloring
        if not textColorHooked[frame] then
            -- Hook into the frame's property changes to update text colors
            _G.hooksecurefunc(frame, "UpdateSpellData", function(self)
                if not self.TextContainer then return end

                -- Apply colors immediately after Blizzard's update
                if self.isTrainable then
                    -- Trainable spells get bright yellow text
                    if self.TextContainer.Name then
                        self.TextContainer.Name:SetTextColor(Color.yellow:GetRGB())
                        self.TextContainer.Name:SetAlpha(1)
                    end
                    if self.TextContainer.SubName then
                        self.TextContainer.SubName:SetTextColor(Color.yellow:GetRGB())
                        self.TextContainer.SubName:SetAlpha(1)
                    end
                elseif self.isUnlearned then
                    -- Unlearned/off-spec spells stay gray
                    if self.TextContainer.Name then
                        self.TextContainer.Name:SetTextColor(0.6, 0.6, 0.6)
                        self.TextContainer.Name:SetAlpha(1)
                    end
                    if self.TextContainer.SubName then
                        self.TextContainer.SubName:SetTextColor(0.5, 0.5, 0.5)
                        self.TextContainer.SubName:SetAlpha(1)
                    end
                else
                    -- Normal learned spells get BRIGHT white text - use full RGB values
                    if self.TextContainer.Name then
                        self.TextContainer.Name:SetTextColor(1, 1, 1)
                        self.TextContainer.Name:SetAlpha(1)
                    end
                    if self.TextContainer.SubName then
                        self.TextContainer.SubName:SetTextColor(0.9, 0.9, 0.9)
                        self.TextContainer.SubName:SetAlpha(1)
                    end
                end
            end)
            textColorHooked[frame] = true
        end

        private.SetSkinned(frame, true)
    end

    -- Create a mixin to hook into SpellBookFrame's methods
    Hook.SpellBookFrameMixin = {}

    function Hook.SpellBookFrameMixin:OnLoad()
        -- Called when the frame is first loaded
        -- This may have already been called before we mixin, so we also manually trigger skinning
        _G.C_Timer.After(0.5, function()
            for _, frame in self.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button then
                    private.SetSkinned(frame, nil)
                    private.SetSkinned(frame.Button, nil)
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
    end

    function Hook.SpellBookFrameMixin:OnShow()
        -- Called when the frame is shown
        -- Skin all spell items with multiple attempts to catch them when ready
        _G.C_Timer.After(0.1, function()
            for _, frame in self.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button then
                    private.SetSkinned(frame, nil)
                    private.SetSkinned(frame.Button, nil)
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
        _G.C_Timer.After(0.5, function()
            for _, frame in self.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button and not private.IsSkinned(frame) then
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
        _G.C_Timer.After(1.0, function()
            for _, frame in self.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button and not private.IsSkinned(frame) then
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
    end

    function Hook.SpellBookFrameMixin:UpdateDisplayedSpells()
        -- Skin all spell items after Blizzard updates them
        _G.C_Timer.After(0.1, function()
            for _, frame in self.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button and not private.IsSkinned(frame) then
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
    end

    function Hook.SpellBookFrameMixin:OnPagedSpellsUpdate()
        -- Skin all spell items when page updates
        _G.C_Timer.After(0.1, function()
            for _, frame in self.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button and not private.IsSkinned(frame) then
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
    end

    function Hook.SpellBookFrameMixin:UpdateAllSpellData()
        -- Skin all spell items when all data is updated (initial load)
        _G.C_Timer.After(0.2, function()
            for _, frame in self.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button then
                    -- Force re-skin on initial load
                    private.SetSkinned(frame, nil)
                    private.SetSkinned(frame.Button, nil)
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
        _G.C_Timer.After(0.5, function()
            for _, frame in self.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button and not private.IsSkinned(frame) then
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
    end

    function Hook.UpdatePlayeerSpecFrame(self)
        for SpecContentFrame in self.SpecContentFramePool:EnumerateActive() do
            if not private.IsSkinned(SpecContentFrame) then
                -- B261 (3.2.6.3): the spec frames come from
                -- SpecContentFramePool, so their ActivateButton (a
                -- MagicButtonTemplate, Blizzard_ClassSpecializationsFrame.xml:311)
                -- is pooled: flat shape, nothing of Aurora's on it.
                Skin.TaintSafeUIPanelButtonTemplate(SpecContentFrame.ActivateButton)
                local role = _G.GetSpecializationRole(SpecContentFrame.specIndex)
                if role then
                    local RoleIcon = SpecContentFrame.RoleIcon
                    RoleIcon:SetTexCoord(0, 1, 0, 1)
                    RoleIcon:SetAtlas(RoleIcons[role])
                end
                if SpecContentFrame.SpellButtonPool then
                    for Button in SpecContentFrame.SpellButtonPool:EnumerateActive() do
                        Button.Ring:Hide()
                        Base.CropIcon(Button.Icon, Button)
                        local texture = Button.spellID and _G.C_Spell.GetSpellTexture(Button.spellID)
                        if texture then
                            Button.Icon:SetTexture(texture)
                        end
                    end
                end
                private.SetSkinned(SpecContentFrame, true)
            end
        end
    end
    -- B261 (3.2.6.3): no caller since the tab strips stay Blizzard's (see
    -- private.AddOns.Blizzard_PlayerSpells below); left for phase 6.
    function Skin.PlayerSpellsFrameTabTemplate(Button)
        Skin.PanelTabButtonTemplate(Button)
        Button._auroraTabResize = true
    end
    function Skin.PlayerSpellsButtonTemplate(Button)
        Base.CropIcon(Button.Icon, Button)
        Base.CropIcon(Button:GetPushedTexture())
        Base.CropIcon(Button:GetHighlightTexture())
    end

    -- Three Camelot-only templates in ClassTalents\Blizzard_ClassTalentsFrame.xml.
    -- Retail declares none of them.

    -- The talent tab strip, built by TabSystemOwnerTemplate from the
    -- tabTemplate KeyValue rather than declared in XML. It inherits
    -- TabSystemButtonTemplate, the same base PlayerSpellsFrame's own tabs use.
    function Skin.ClassTalentsFrameTabTemplate(Button)
        Skin.PlayerSpellsFrameTabTemplate(Button)
    end

    -- The "Active Specialization" block above the trees. Only the button needs
    -- skinning; YellowGlow is a tutorial flourish that ships hidden.
    function Skin.ClassTalentActiveSpecTemplate(Frame)
        if not Frame then return end
        if Frame.ActivateButton then
            -- B261 (3.2.6.3): declared once (Camelot
            -- Blizzard_ClassTalentsFrame.xml:111), frameLevel 4001, so its
            -- panel sits far above the talents frame's art: panel shape.
            Skin.TaintSafeUIPanelButtonTemplate(Frame.ActivateButton, "panel")
        end
    end

    -- Pooled per-tree headers (ClassTalentsFrameMixin's treeHeaderPool). The
    -- Talents-Main-Ring-c60 / talents-main-ring-box-c60 / Talents-small-divider
    -- art is the Camelot tree frame; the Icon, Name and Text are the content.
    function Skin.ClassTalentTreeHeaderTemplate(Frame)
        if not Frame or private.IsSkinned(Frame) then return end
        private.SetSkinned(Frame, true)

        for _, key in next, {"MainRing", "TextBackground", "Divider"} do
            if Frame[key] then
                Frame[key]:SetAlpha(0)
            end
        end

        if Frame.Icon then
            Base.CropIcon(Frame.Icon, Frame)
        end
    end

    -- B221: Blizzard_SpellSearch\Blizzard_SpellSearchTemplates.xml, shared by
    -- the spellbook and talents search boxes on retail and Forever. Aurora had
    -- no skin for it, so the preview list kept Blizzard's _search-rowbg rows,
    -- the blue search-highlight glow and the UI-Frame bevelled border.
    -- Blizzard_SpellSearch has no skin file of its own; it loads with
    -- Blizzard_PlayerSpells, its only consumer.
    local function SkinSearchRow(Button)
        Button:ClearNormalTexture()
        Button:ClearPushedTexture()
        -- Blizzard only ever Show/Hide/SetShown's this, never re-sets the
        -- atlas, so the flat colour sticks.
        Util.SetHighlightColor(Button.HighlightTexture, 0.2)
    end
    function Skin.SpellSearchPreviewResultTemplate(Button)
        if not Button or private.IsSkinned(Button) then return end
        private.SetSkinned(Button, true)

        SkinSearchRow(Button)
        Button.IconFrame:SetTexture("")
        Base.CropIcon(Button.Icon, Button)
    end
    function Skin.SpellSearchSuggestedResultButtonTemplate(Button)
        if not Button or private.IsSkinned(Button) then return end
        private.SetSkinned(Button, true)

        -- The magnifying-glass Icon is a glyph, not art; it stays.
        SkinSearchRow(Button)
    end

    -- Result rows come from the ScrollBox's view pool.
    function Hook.SpellSearchPreviewAcquired(owner, frame)
        Skin.SpellSearchPreviewResultTemplate(frame)
    end
    -- Suggested rows ("Missing from action bar", "Assisted Combat spells")
    -- come from a CreateFramePool the mixin acquires in UpdateResultsDisplay,
    -- lazily, so they do not exist at skin time.
    function Hook.SpellSearchPreviewUpdateResultsDisplay(self)
        for button in self.suggestedResultButtonsPool:EnumerateActive() do
            Skin.SpellSearchSuggestedResultButtonTemplate(button)
        end
    end

    function Skin.SpellSearchPreviewContainerTemplate(Frame)
        if not Frame or private.IsSkinned(Frame) then return end
        private.SetSkinned(Frame, true)

        Skin.FrameTypeFrame(Frame)
        for _, key in next, {"Background", "BorderAnchor", "BotRightCorner", "BottomBorder", "LeftBorder", "RightBorder"} do
            if Frame[key] then
                Frame[key]:SetTexture("")
            end
        end

        _G.ScrollUtil.AddAcquiredFrameCallback(Frame.ScrollBox, Hook.SpellSearchPreviewAcquired, Frame)
        _G.hooksecurefunc(Frame, "UpdateResultsDisplay", Hook.SpellSearchPreviewUpdateResultsDisplay)
    end
end

function private.AddOns.Blizzard_PlayerSpells()
    local PlayerSpellsFrame = _G.PlayerSpellsFrame

    -- Skin the main frame - this provides the Aurora background
    Skin.NineSlicePanelTemplate(PlayerSpellsFrame.NineSlice)
    PlayerSpellsFrame.NineSlice:SetFrameLevel(1)

    -- Give the outer frame a dark-grey background (not pure black)
    if PlayerSpellsFrame.NineSlice.Bg then
        PlayerSpellsFrame.NineSlice.Bg:SetColorTexture(Color.panelBg:GetRGB())
        PlayerSpellsFrame.NineSlice.Bg:SetAllPoints(PlayerSpellsFrame.NineSlice)
        PlayerSpellsFrame.NineSlice.Bg:Show()
    end

    -- Hide portrait but keep the frame background
    if PlayerSpellsFrame.PortraitContainer then
        PlayerSpellsFrame.PortraitContainer:Hide()
    end

    --[[ B261 (3.2.6.3): the three frame tabs stay Blizzard's (shape c), as
        do the spell book's category tabs and, on WoW Forever, the talent
        tree tabs below. All three strips are TabSystemButtonTemplate tabs:
        SetTabSelected shows the Active art on the open tab and disables it
        (Blizzard_SharedXML/Shared/TabSystem/TabSystemTemplates.lua:41-55),
        so engine-drawn state would show the open tab as a disabled one, and
        UpdateTabWidth measures each tab. Listed under "Deliberately
        unskinned" in docs/KnownIssues.md. ]]

    --[[ B261 (3.2.6.3): the close button is PortraitFrameTemplate's
        $parentCloseButton, a UIPanelCloseButtonDefaultAnchors
        (Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:633),
        frameLevel 510: the Layer 2 panel, drawn by
        Skin.TaintSafePanelCloseButton, as the quest frame's. ]]
    Skin.TaintSafePanelCloseButton(_G.PlayerSpellsFrameCloseButton)

    --[[ B261 (3.2.6.3): MaximizeButton and MinimizeButton
        (MaximizeMinimizeButtonFrameTemplate, SharedUIPanelTemplates.xml:1032-1060,
        frameLevel 510) have their state textures set in XML only; Blizzard
        only shows and hides them (MaximizeMinimizeButtonFrameMixin, :654-662).
        Panel shape, the box where the Layer 1 skin put it (3, 4, 3 and 4
        inside the button), and the glyph drawn on the panel. ]]
    do
        local MaxMin = PlayerSpellsFrame.MaxMinButtonFrame
        if private.isForever then
            -- Camelot's OnLoad sizes the frame 28x28 since 70450; keep retail's 24.
            MaxMin:SetSize(24, 24)
        end
        for _, name in next, {"MaximizeButton", "MinimizeButton"} do
            local panel = Skin.TaintSafeFrameTypeButton(MaxMin[name], "panel")
            panel:ClearAllPoints()
            panel:SetPoint("TOPLEFT", MaxMin[name], 3, -3)
            panel:SetPoint("BOTTOMRIGHT", MaxMin[name], -4, 4)

            local bg = panel:GetBackdropTexture("bg")
            local line = panel:CreateLine(nil, "ARTWORK")
            line:SetColorTexture(1, 1, 1) -- static: not a theme color
            line:SetThickness(1.2)
            line:SetStartPoint("TOPRIGHT", bg, -3, -3)
            line:SetEndPoint("BOTTOMLEFT", bg, 3, 3)

            local hline = panel:CreateTexture(nil, "ARTWORK")
            hline:SetColorTexture(1, 1, 1) -- static: not a theme color
            hline:SetSize(7, 1)
            local vline = panel:CreateTexture(nil, "ARTWORK")
            vline:SetColorTexture(1, 1, 1) -- static: not a theme color
            vline:SetSize(1, 7)
            if name == "MaximizeButton" then
                hline:SetPoint("TOP", bg, 1, -3)
                vline:SetPoint("RIGHT", bg, -3, 1)
            else
                hline:SetPoint("BOTTOM", bg, -1, 3)
                vline:SetPoint("LEFT", bg, 3, -1)
            end
        end
    end

    -- SpecFrame
    local SpecFrame = PlayerSpellsFrame.SpecFrame
    -- Solid Aurora background sitting below all Blizzard layers
    if not SpecFrame._auroraBackground then
        local bg = SpecFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetColorTexture(Color.panelBg:GetRGB())
        bg:SetAllPoints(SpecFrame)
        SpecFrame._auroraBackground = bg
    end
    -- Hide the parchment atlas and the solid black underlay — the Aurora frame background shows through
    if SpecFrame.Background then SpecFrame.Background:Hide() end
    if SpecFrame.BlackBG then SpecFrame.BlackBG:Hide() end
    -- Camelot replaces Blizzard_ClassSpecializationsFrame.xml and ships no Lua
    -- for it, so the ClassSpecFrameMixin methods -- UpdateSpecFrame among them
    -- -- do not exist on Forever.
    if type(SpecFrame.UpdateSpecFrame) == "function" then
        _G.hooksecurefunc(SpecFrame, "UpdateSpecFrame", Hook.UpdatePlayeerSpecFrame)
    end

    -- TalentsFrame
    local TalentsFrame = PlayerSpellsFrame.TalentsFrame

    -- Solid Aurora background sitting below all Blizzard layers
    if not TalentsFrame._auroraBackground then
        local bg = TalentsFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetColorTexture(Color.panelBg:GetRGB())
        bg:SetAllPoints(TalentsFrame)
        TalentsFrame._auroraBackground = bg
    end

    -- Hide static background layers (parchment + solid black underlay + gold bottom bar)
    if TalentsFrame.BlackBG then TalentsFrame.BlackBG:Hide() end
    if TalentsFrame.BottomBar then TalentsFrame.BottomBar:Hide() end

    -- When talentArtBackground is false (default), zero all spec-specific art textures.
    -- When true, skip these hooks so Blizzard's class-specific artwork shows through.
    if not IsConfigEnabled("talentArtBackground") then
        local function HideTalentsBackground(frame)
            if frame.Background then frame.Background:SetAlpha(0) end
            if frame.BackgroundFlash then frame.BackgroundFlash:SetAlpha(0) end
            if frame.OverlayBackgroundRight then frame.OverlayBackgroundRight:SetAlpha(0) end
            if frame.OverlayBackgroundMid then frame.OverlayBackgroundMid:SetAlpha(0) end
            if frame.Clouds1 then frame.Clouds1:SetAlpha(0) end
            if frame.Clouds2 then frame.Clouds2:SetAlpha(0) end
        end
        _G.hooksecurefunc(TalentsFrame, "UpdateSpecBackground", function(self)
            HideTalentsBackground(self)
        end)
        -- Also stop background cloud/particle animations after Blizzard starts them on OnShow
        _G.hooksecurefunc(TalentsFrame, "SetBackgroundAnimationsPlaying", function(self)
            if self.backgroundAnims then
                for _, animGroup in ipairs(self.backgroundAnims) do
                    animGroup:Stop()
                end
            end
        end)
        -- Run immediately in case the frame was already shown before we ran
        HideTalentsBackground(TalentsFrame)
    end

    _G.hooksecurefunc(TalentsFrame, "UpdateSpecBackground", function(self)
        if not GetConfigOption("heroTalentsCustomAnchor", false) then
            return
        end

        local heroTalentsContainer = self.HeroTalentsContainer
        if not heroTalentsContainer then
            return
        end

        local preset = GetConfigOption("heroTalentsAnchorPreset", "default")
        local offsetX, offsetY = 50, -4
        if preset == "topcenter" then
            heroTalentsContainer:ClearAllPoints()
            heroTalentsContainer:SetPoint("TOP", self, "TOP", 0, -4)
            return
        elseif preset == "centercenter" then
            heroTalentsContainer:ClearAllPoints()
            heroTalentsContainer:SetPoint("CENTER", self, "CENTER", 0, 0)
            return
        elseif preset == "left" then
            offsetX, offsetY = 30, -4
        elseif preset == "lower" then
            offsetX, offsetY = 50, -28
        elseif preset == "compact" then
            offsetX, offsetY = 38, -18
        end

        heroTalentsContainer:ClearAllPoints()
        heroTalentsContainer:SetPoint("TOPLEFT", self, "TOPLEFT", offsetX, offsetY)
    end)

    --[[ B105: the talent BorderSheen suppression is REMOVED, not moved.

         It used to be `hooksecurefunc(_G.ClassTalentButtonArtMixin,
         "UpdateStateBorder", ...)` — hiding a decorative gold sheen. That one
         cosmetic hook poisoned a Blizzard global for the whole session:

           ClassTalentButtonSpendMixin:OnEnter                      :221
             :224 TalentButtonSpendMixin.OnEnter(self)
                  ClassTalentButtonBaseMixin:UpdateStateBorder      :97
                    ClassTalentButtonArtMixin.UpdateStateBorder(…)  ← reads the
                                                                     hooked key
             :225 self:ShowActionBarHighlights()                    ← tainted
                  ClearOnBarHighlightMarks() → ON_BAR_HIGHLIGHT_MARKS = {}

         Blizzard's own source flags that table: "Keys within
         ON_BAR_HIGHLIGHT_MARKS and ACTION_HIGHLIGHT_MARKS are vulnerable to
         taint from talent and spellbook code." Written inside a tainted
         execution it stays tainted, and `ActionBarController_UpdateAllSpell-
         Highlights` re-reads it constantly — 1428 taint events in a nine
         minute taint.log (2026-08-24), the single largest source in the file
         and the only global Aurora was tainting at all.

         Hovering one talent button was enough. Same shape as B57/B74/B88/B95:
         hooksecurefunc protects the hooked function's execution, not the
         caller's READ of the key.

         To bring the cosmetic back taint-free: Blizzard only ever calls
         `SetAlpha`/`SetShown` on `BorderSheen`, never `SetTexture`, so a
         one-time `BorderSheen:SetTexture("")` per button makes it permanently
         invisible with no hook at all — swept from an OnShow handler over
         `TalentsFrame:EnumerateAllTalentButtons()`. Deliberately not done in
         the same change as the removal: the sheen is decoration, the taint is
         not, and the two should not be verified together. ]]

    --[[ B261 (3.2.6.3): ApplyButton (tier B) and InspectCopyButton,
        UIPanelButtonNoTooltipTemplate buttons declared once
        (ClassTalents/Blizzard_ClassTalentsFrame.xml:247, :283; Forever
        Camelot :441, :480). Panel shape. Their panels sit at the talents
        frame's level, which keeps art of its own over the whole frame:
        the spec art and clouds at BACKGROUND 1 and 2 and the activation
        effects at 3 (:59-205), and on WoW Forever the inner frame border
        and dividers on OVERLAY 0 (Camelot :313-340). A fill at
        BACKGROUND -6 would be drawn under all of it, so each panel goes to
        OVERLAY 6, its edge 7: above every region of the talents frame, and
        still below the button, which is a level up. ]]
    for _, key in next, {"ApplyButton", "InspectCopyButton"} do
        local panel = Skin.TaintSafeUIPanelButtonTemplate(TalentsFrame[key], "panel")
        panel:SetBackdropLayer("OVERLAY", 6)
    end
    Skin.SearchBoxTemplate(TalentsFrame.SearchBox)
    Skin.SpellSearchPreviewContainerTemplate(TalentsFrame.SearchPreviewContainer) -- B221

    --[[ B261 (task 5.4): the loadout dropdown, a WowStyle1DropdownTemplate
        (Blizzard_SharedXML/Shared/LoadSystem/LoadSystemTemplates.xml:6), had
        Skin.DropdownButton's backdrop and keys. Declared once, not measured:
        panel shape. Blizzard never re-sets Background; it re-atlases Arrow
        on every state change (Blizzard_Menu/MenuTemplates.lua:937-946), and
        alpha survives that. Aurora's arrow is drawn on the panel, where
        Skin.DropdownButton puts it. ]]
    local LoadDropdown = TalentsFrame.LoadSystem and TalentsFrame.LoadSystem.Dropdown
    if LoadDropdown then
        if LoadDropdown.Background then LoadDropdown.Background:SetAlpha(0) end
        if LoadDropdown.Arrow then LoadDropdown.Arrow:SetAlpha(0) end
        local panel = Skin.TaintSafeFrameTypeButton(LoadDropdown, "panel")
        local arrow = panel:CreateTexture(nil, "ARTWORK")
        arrow:SetTexture([[Interface\AddOns\Aurora\media\arrow-down-active]])
        arrow:SetSize(8, 8)
        arrow:SetPoint("RIGHT", -8, 0)
    end

    -- Camelot-only additions to the talents frame.
    Skin.ClassTalentActiveSpecTemplate(TalentsFrame.ActiveSpec)

    --[[ B261 (AT-D23 a): the search options dropdown right of the talents
        search box, WoW Forever only. Retail has no such key, so the nil
        check is the guard. A WowStyle1ArrowDropdownTemplate (Camelot
        ClassTalents/Blizzard_ClassTalentsFrame.xml:426; the template at
        Blizzard_Menu/Mainline/MenuTemplates.xml:41-64), 25x25, declared
        once, never enabled or disabled by its frame; its only art is
        Arrow, which Blizzard re-atlases on every state change
        (Blizzard_Menu/Mainline/MenuTemplates.lua:41-49) and never shows or
        hides, so alpha 0 holds, as on the loadout dropdown above. Blizzard
        re-anchors the button when a gamepad is set up or removed
        (Blizzard_PlayerSpellsFrame.lua:1229-1230, :1249); the panel follows
        it. Panel shape, not Skin.WowStyle1ArrowDropdownTemplate (Layer 1).
        The box is inset SEARCH_OPTIONS_INSET on each side, so it is about as
        tall as the search box's own box (20, the InputBoxTemplate offsets
        on a 30-tall edit box), and raised SEARCH_OPTIONS_RAISE inside the
        button: Blizzard places the button 2 below the search box's centre
        (Camelot ClassTalents/Blizzard_ClassTalentsFrame.lua:251), so the
        raise puts the box level with the search box's. ]]
    local SearchOptions = TalentsFrame.SearchOptionsDropdown
    if SearchOptions then
        local SEARCH_OPTIONS_INSET = 3
        local SEARCH_OPTIONS_RAISE = 2
        if SearchOptions.Arrow then SearchOptions.Arrow:SetAlpha(0) end
        local panel = Skin.TaintSafeFrameTypeButton(SearchOptions, "panel")
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT", SearchOptions, SEARCH_OPTIONS_INSET, -(SEARCH_OPTIONS_INSET - SEARCH_OPTIONS_RAISE))
        panel:SetPoint("BOTTOMRIGHT", SearchOptions, -SEARCH_OPTIONS_INSET, SEARCH_OPTIONS_INSET + SEARCH_OPTIONS_RAISE)
        local arrow = panel:CreateTexture(nil, "ARTWORK")
        arrow:SetTexture([[Interface\AddOns\Aurora\media\arrow-down-active]])
        arrow:SetSize(8, 8)
        arrow:SetPoint("CENTER")
    end

    -- Its own tab strip, separate from PlayerSpellsFrame.TabSystem above.
    --
    -- Hooking AddTab alone was wrong: TabSystemOwnerTemplate adds the Primary
    -- and Secondary tabs during the frame's own OnLoad, which is *before* this
    -- skin runs, and hooksecurefunc only sees later calls -- so the tabs stayed
    -- stock gold. Sweep what is already there, then hook for anything added
    -- later. The mixin table is deliberately not hooked: Mixin() copies methods
    -- at creation, so existing frames would never see it.
    -- B261 (3.2.6.3): these tabs stay Blizzard's, as the frame tabs above;
    -- the sweep and its AddTab hook are gone.

    -- Tree headers come from treeHeaderPool. Same correction: RefreshTreeHeaders
    -- has usually already run by the time the frame is visible, so sweep the
    -- active pool first and hook for later refreshes.
    local function SkinTreeHeaders(self)
        if not self.treeHeaderPool then return end
        for header in self.treeHeaderPool:EnumerateActive() do
            Skin.ClassTalentTreeHeaderTemplate(header)
        end
    end

    SkinTreeHeaders(TalentsFrame)
    if TalentsFrame.RefreshTreeHeaders then
        _G.hooksecurefunc(TalentsFrame, "RefreshTreeHeaders", SkinTreeHeaders)
    end

    -- SpellBookFrame
    local SpellBookFrame = PlayerSpellsFrame.SpellBookFrame

    -- Mix in our hooks to the SpellBookFrame
    Util.Mixin(SpellBookFrame, Hook.SpellBookFrameMixin)

    -- Global mixin hooks: fire immediately when any pool frame is populated, eliminating
    -- the orange-text flicker that occurs before our delayed SkinAllSpellBookItems runs.
    _G.hooksecurefunc(_G.SpellBookItemMixin, "UpdateVisuals", function(self)
        -- Override SPELLBOOK_FONT_COLOR (golden/amber) with Aurora white text
        if self.isTrainable then
            self.Name:SetTextColor(Color.yellow:GetRGB())
            if self.SubName:IsShown() then self.SubName:SetTextColor(Color.yellow:GetRGB()) end
        elseif self.isUnlearned then
            self.Name:SetTextColor(0.6, 0.6, 0.6)
            if self.SubName:IsShown() then self.SubName:SetTextColor(0.5, 0.5, 0.5) end
        else
            self.Name:SetTextColor(1, 1, 1)
            if self.SubName:IsShown() then self.SubName:SetTextColor(0.9, 0.9, 0.9) end
        end
        -- Hide the per-item amber banner backplate immediately
        if self.Backplate then self.Backplate:SetAlpha(0) end

        -- B07: UpdateVisuals re-applies the rounded iconframe hover atlas via
        -- self.artSet.iconHighlight — replace it with the flat square highlight
        -- again so the buttons keep the action bar treatment.
        if self.Button and self.Button.IconHighlight then
            Util.SetHighlightColor(self.Button.IconHighlight)
        end
    end)

    _G.hooksecurefunc(_G.SpellBookHeaderMixin, "Init", function(self)
        -- Override SPELLBOOK_FONT_COLOR on section headers ("Demon Hunter", "Havoc", etc.)
        if self.Text then self.Text:SetTextColor(1, 1, 1) end
        if self.Backplate then self.Backplate:SetAlpha(0) end
        if self.Border then self.Border:SetAlpha(0) end
    end)

    -- Immediately try to skin if the frame is already shown
    if SpellBookFrame:IsShown() then
        _G.C_Timer.After(0.5, function()
            for _, frame in SpellBookFrame.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button then
                    private.SetSkinned(frame, nil)
                    private.SetSkinned(frame.Button, nil)
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
        _G.C_Timer.After(1.0, function()
            for _, frame in SpellBookFrame.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button and not private.IsSkinned(frame) then
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
    end

    -- Create a dark-grey background for the SpellBookFrame to cover Blizzard parchment textures
    if not SpellBookFrame._auroraBackground then
        local bg = SpellBookFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetColorTexture(Color.panelBg:GetRGB())
        bg:SetAllPoints(SpellBookFrame)
        SpellBookFrame._auroraBackground = bg
    end

    -- Function to hide all book backgrounds
    local function HideSpellBookBackgrounds()
        -- Hide all the book texture layers
        if SpellBookFrame.TopBar then SpellBookFrame.TopBar:SetAlpha(0) end
        if SpellBookFrame.BookBGHalved then SpellBookFrame.BookBGHalved:SetAlpha(0) end
        if SpellBookFrame.BookBGLeft then SpellBookFrame.BookBGLeft:SetAlpha(0) end
        if SpellBookFrame.BookBGRight then SpellBookFrame.BookBGRight:SetAlpha(0) end
        if SpellBookFrame.BookCornerFlipbook then SpellBookFrame.BookCornerFlipbook:SetAlpha(0) end
        if SpellBookFrame.Bookmark then SpellBookFrame.Bookmark:SetAlpha(0) end

        -- Also try to hide any regions that might be the stripes
        for _, region in pairs({SpellBookFrame:GetRegions()}) do
            if region:IsObjectType("Texture") and region:GetDrawLayer() == "BACKGROUND" then
                local texture = region:GetTexture()
                if texture and type(texture) == "number" then
                    -- Hide any background textures
                    region:SetAlpha(0)
                end
            end
        end
    end

    -- Get references to paging controls
    local PagedSpellsFrame = SpellBookFrame.PagedSpellsFrame
    local PagingControls = PagedSpellsFrame.PagingControls

    -- Function to hide all background effects
    local function HidePagedSpellsBackgrounds()
        -- Hide any background effects on the PagedSpellsFrame and its views
        if PagedSpellsFrame.ViewFrames then
            for _, view in ipairs(PagedSpellsFrame.ViewFrames) do
                -- Hide all textures on the view frames
                for _, region in pairs({view:GetRegions()}) do
                    if region:IsObjectType("Texture") then
                        region:SetAlpha(0)
                    end
                end
                -- Hide any ModelScenes on the views
                for _, child in pairs({view:GetChildren()}) do
                    if child:IsObjectType("ModelScene") then
                        child:Hide()
                        child:SetAlpha(0)
                    end
                end
            end
        end

        -- Also hide textures on the PagedSpellsFrame itself
        for _, region in pairs({PagedSpellsFrame:GetRegions()}) do
            if region:IsObjectType("Texture") and region:GetDrawLayer() == "BACKGROUND" then
                region:SetAlpha(0)
            end
        end
    end

    -- Function to skin all visible spell book items
    local function SkinAllSpellBookItems()
        if not PagedSpellsFrame then return end

        local frameCount = 0
        for _, frame in PagedSpellsFrame:EnumerateFrames() do
            frameCount = frameCount + 1
            if frame.Button then
                -- Always check and re-skin if needed, as buttons can be recycled from pools
                local button = frame.Button
                -- B261 (5.4): no backdrop to test for any more; the
                -- textures are made once per button (itemDecorated).
                if not private.IsSkinned(button) then
                    -- Clear the flag to force re-skinning
                    private.SetSkinned(button, nil)
                    private.SetSkinned(frame, nil)
                    Hook.SkinSpellBookItem(frame)
                end
            elseif frame.Backplate and frame.Text and not skinnedHeaders[frame] then
                -- SpellBookHeaderTemplate (section group headers: "Demon Hunter", "Havoc", etc.)
                frame.Backplate:SetAlpha(0)  -- hide the rusty brown banner
                if frame.Border then frame.Border:SetAlpha(0) end  -- hide the spellbook-divider line
                frame.Text:SetTextColor(1, 1, 1)  -- white instead of SPELLBOOK_FONT_COLOR golden
                skinnedHeaders[frame] = true
            end
        end

        -- If no frames found yet, retry after the pool populates
        if frameCount == 0 then
            _G.C_Timer.After(0.2, SkinAllSpellBookItems)
        end
    end

    -- Hide backgrounds initially
    HideSpellBookBackgrounds()

    -- Hook SetMinimized to re-hide backgrounds when frame is resized
    _G.hooksecurefunc(SpellBookFrame, "SetMinimized", function(self)
        HideSpellBookBackgrounds()
        -- Re-skin all items after layout change
        _G.C_Timer.After(0.1, function() SkinAllSpellBookItems() end)
    end)

    -- Hook the parent frame's SetMinimized as well
    _G.hooksecurefunc(PlayerSpellsFrame, "SetMinimized", function(self)
        HideSpellBookBackgrounds()
        HidePagedSpellsBackgrounds()
        -- Re-skin all items after layout change
        _G.C_Timer.After(0.1, function() SkinAllSpellBookItems() end)
    end)

    -- Hide help button
    if SpellBookFrame.HelpPlateButton then SpellBookFrame.HelpPlateButton:Hide() end

    Skin.SearchBoxTemplate(SpellBookFrame.SearchBox)
    Skin.SpellSearchPreviewContainerTemplate(SpellBookFrame.SearchPreviewContainer) -- B221
    -- Not a WowStyle1DropdownTemplate on either client, so Skin.DropdownButton
    -- is the wrong skin. Forever's SpellBookSettingsDropdownTemplate inherits
    -- UIPanelArrowDropdownButtonTemplate (a gold arrow); retail builds it from
    -- UIPanelIconDropdownButtonTemplate (a gear). Same frame and mixin, only
    -- the Icon's atlas differs, so that picks the skin (B228).
    local SettingsDropdown = SpellBookFrame.SettingsDropdown
    if SettingsDropdown then
        local icon = SettingsDropdown.Icon
        -- GetAtlas returns the atlas's stored spelling ("QuestLog-icon-setting"
        -- on retail 12.1.5), while atlas lookups ignore case; compare lowered.
        local atlas = icon and icon:GetAtlas()
        --[[ B261 (3.2.6.3): a 15x16 DropdownButton declared once
            (SpellBook/Blizzard_SpellBookFrame.xml:74), its art in XML: panel
            shape, the box over the whole button as the Layer 1 skin drew
            it. Retail keeps the gear; WoW Forever's gold arrow and its
            highlight copy go by alpha and Aurora's arrow is drawn on the
            panel, as Skin.UIPanelArrowDropdownButtonTemplate does. ]]
        local panel = Skin.TaintSafeFrameTypeButton(SettingsDropdown, "panel")
        if not (atlas and atlas:lower() == "questlog-icon-setting") then
            if icon then
                icon:SetAlpha(0)
            end
            -- The highlight copy is unnamed, so it goes by atlas.
            for _, region in next, {SettingsDropdown:GetRegions()} do
                if region:IsObjectType("Texture") then
                    local regionAtlas = region:GetAtlas()
                    if regionAtlas and regionAtlas:find("common%-dropdown%-a%-button") then
                        region:SetAlpha(0)
                    end
                end
            end
            local bg = panel:GetBackdropTexture("bg")
            local arrow = panel:CreateTexture(nil, "ARTWORK")
            arrow:SetPoint("TOPLEFT", bg, 3, -4)
            arrow:SetPoint("BOTTOMRIGHT", bg, -3, 4)
            Base.SetTexture(arrow, "arrowDown")
        end

        -- B221: Camelot's SpellBookSearchBoxTemplate anchors the search box
        -- RIGHT to the dropdown's LEFT at y=4, lifting it to suit Blizzard's
        -- art. Aurora centres both backdrops on their frames (the box's 20px
        -- backdrop on its 30px frame, the arrow on its 15x16 frame), so the
        -- arrow read 4px low. Drop the lift. UpdateAttic moves the dropdown
        -- and ResizeSearchBox only sets the width, so this holds; the one
        -- exception is PlayerSpellsFrameMixin:UninitializeGamepad, which puts
        -- y=4 back when gamepad mode is switched off. The lift is Camelot's
        -- search box template, not the dropdown's, hence the flavor check.
        -- Retail's anchor already has y=0, and its gear skin keeps the
        -- dropdown's 15x16 size, so the box stays where Blizzard put it.
        if private.isForever then
            SpellBookFrame.SearchBox:ClearAllPoints()
            SpellBookFrame.SearchBox:SetPoint("RIGHT", SettingsDropdown, "LEFT", -5, 0)
        end
    end

    -- Not a fixed 1..3: Camelot builds the category tabs from the character's
    -- skill lines plus pet and transmog, so the count varies -- a mage shows
    -- four, and the fourth was left unskinned. Walk the children instead, and
    -- re-walk when the tab system adds more.
    --
    -- SpellBookCategoryTabTemplate inherits TabSystemButtonTemplate, not a
    -- panel tab, and Init() puts it in square mode with an icon. Routing it
    -- through Skin.PanelTabButtonTemplate skinned only the three-slice text
    -- art, leaving the spellbook-Tab-Frame-C60 gold plate on top -- which is
    -- what these tabs still showed. Same template on retail, same bug.
    --
    -- B261 (3.2.6.3): these tabs now stay Blizzard's, as the frame tabs
    -- above; the sweep and its AddTab hook are gone.

    Skin.PlayerSpellsButtonTemplate(SpellBookFrame.AssistedCombatRotationSpellFrame.Button)

    -- Skin SpellBookItem frames as they're created/updated
    _G.hooksecurefunc(SpellBookFrame.PagedSpellsFrame, "SetDataProvider", function()
        _G.C_Timer.After(0.05, function() SkinAllSpellBookItems() end)
    end)
    _G.hooksecurefunc(SpellBookFrame, "UpdateDisplayedSpells", function()
        _G.C_Timer.After(0.05, function() SkinAllSpellBookItems() end)
    end)
    _G.hooksecurefunc(SpellBookFrame, "OnPagedSpellsUpdate", function()
        _G.C_Timer.After(0.05, function() SkinAllSpellBookItems() end)
    end)
    _G.hooksecurefunc(SpellBookFrame, "UpdateAllSpellData", function()
        _G.C_Timer.After(0.1, function() SkinAllSpellBookItems() end)
    end)

    -- Hide backgrounds initially
    HidePagedSpellsBackgrounds()

    -- Hook the paging controls to re-skin when pages change
    _G.hooksecurefunc(PagingControls, "SetCurrentPage", function()
        _G.C_Timer.After(0.1, function()
            SkinAllSpellBookItems()
            HidePagedSpellsBackgrounds()
        end)
    end)

    -- Hook the frame show to ensure skinning persists
    SpellBookFrame:HookScript("OnShow", function()
        HideSpellBookBackgrounds()
        HidePagedSpellsBackgrounds()
        -- Multiple delayed attempts to ensure frames are created and skinned
        _G.C_Timer.After(0.1, function() SkinAllSpellBookItems() end)
        _G.C_Timer.After(0.3, function() SkinAllSpellBookItems() end)
        _G.C_Timer.After(0.5, function() SkinAllSpellBookItems() end)
    end)

    -- Skin immediately on load if the frame is already visible
    if SpellBookFrame:IsVisible() then
        HideSpellBookBackgrounds()
        HidePagedSpellsBackgrounds()
        _G.C_Timer.After(0.2, function() SkinAllSpellBookItems() end)
        _G.C_Timer.After(0.4, function() SkinAllSpellBookItems() end)
    end

    -- Create a continuous monitor to keep hiding the stripes and ensure skinning
    SpellBookFrame:HookScript("OnUpdate", function(self, elapsed)
        if not self._auroraUpdateTimer then
            self._auroraUpdateTimer = 0
        end
        self._auroraUpdateTimer = self._auroraUpdateTimer + elapsed

        -- Check every 0.5 seconds
        if self._auroraUpdateTimer >= 0.5 then
            self._auroraUpdateTimer = 0
            HidePagedSpellsBackgrounds()

            -- Also check if any frames need skinning
            for _, frame in PagedSpellsFrame:EnumerateFrames() do
                if frame.Button then
                    local button = frame.Button
                    -- Re-skin if not yet skinned
                    if not private.IsSkinned(button) then
                        Hook.SkinSpellBookItem(frame)
                    end

                    -- Always re-hide these elements
                    if button.BorderSheen then
                        button.BorderSheen:Hide()
                        button.BorderSheen:SetAlpha(0)
                    end
                    if button.BorderSheenMask then
                        button.BorderSheenMask:Hide()
                    end
                    if button.FxModelScene then
                        button.FxModelScene:Hide()
                        button.FxModelScene:SetAlpha(0)
                    end
                end
            end
        end
    end)

    --[[ B261 (3.2.6.3): PagingControlsPrevPageButtonTemplate and
        ...NextPageButtonTemplate, 32x32 with their state textures in XML
        (Blizzard_PagedContent/Blizzard_PagingControls.xml:4-18); Blizzard
        only enables and disables them (Blizzard_PagingControls.lua:111-112).
        Their parent is a HorizontalLayoutFrame, which measures the buttons,
        not the panels under them. Panel shape, drawn by
        Skin.TaintSafeNavButton, as the classic spell book's. ]]
    Skin.TaintSafeNavButton(PagingControls.PrevPageButton, "arrowLeft")
    Skin.TaintSafeNavButton(PagingControls.NextPageButton, "arrowRight")
    -- Override SPELLBOOK_FONT_COLOR (amber) set by PagingControlsMixin:OnLoad
    PagingControls.PageText:SetTextColor(Color.white:GetRGB())
end

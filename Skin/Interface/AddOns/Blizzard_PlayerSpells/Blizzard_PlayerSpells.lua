local _, private = ...
if private.shouldSkip() then return end

--[[ Lua Globals ]]
-- luacheck: globals

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook = Aurora.Hook
local Skin = Aurora.Skin
local Color = Aurora.Color
local Util = Aurora.Util
local Config = private.Config

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
        if button._auroraSkinned then return end
        button._auroraSkinned = true

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
            _G.hooksecurefunc(button.Border, "SetTexture", function(self)
                self:SetAlpha(0)
            end)
            _G.hooksecurefunc(button.Border, "SetAtlas", function(self)
                self:SetAlpha(0)
            end)
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
        Base.CropIcon(button.Icon, button)
        button.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- Create Aurora backdrop on the button
        Base.CreateBackdrop(button, {
            bgFile = [[Interface\PaperDoll\UI-Backpack-EmptySlot]],
            tile = false,
            offsets = {
                left = -1,
                right = -1,
                top = -1,
                bottom = -1,
            }
        })
        button:SetBackdropColor(1, 1, 1, 0.75)
        button:SetBackdropBorderColor(Color.frame, 1)
        Base.CropIcon(button:GetBackdropTexture("bg"))

        -- Handle various overlay textures
        if button.IconHighlight then
            button.IconHighlight:ClearAllPoints()
            button.IconHighlight:SetPoint("TOPLEFT", button.Icon)
            button.IconHighlight:SetPoint("BOTTOMRIGHT", button.Icon)
        end

        -- Handle AutoCast overlay
        if button.AutoCastOverlay then
            local overlay = button.AutoCastOverlay
            if overlay.Corners then
                overlay.Corners:SetAlpha(0)
            end
        end

        -- Hook the button's UpdateVisuals to maintain skinning and update text colors
        if button.UpdateVisuals then
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
        if frame.Name and not frame.Name._auroraAlphaHooked then
            _G.hooksecurefunc(frame.Name, "SetAlpha", function(self, alpha)
                -- Always force full alpha for better visibility
                if alpha < 1 then
                    self:SetAlpha(1)
                end
            end)
            frame.Name._auroraAlphaHooked = true
        end

        if frame.SubName and not frame.SubName._auroraAlphaHooked then
            _G.hooksecurefunc(frame.SubName, "SetAlpha", function(self, alpha)
                -- Always force full alpha for better visibility
                if alpha < 1 then
                    self:SetAlpha(1)
                end
            end)
            frame.SubName._auroraAlphaHooked = true
        end

        -- Hook UpdateVisuals on the parent frame to handle text coloring
        if not frame._auroraTextColorHooked then
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
            frame._auroraTextColorHooked = true
        end

        frame._auroraSkinned = true
    end

    -- Create a mixin to hook into SpellBookFrame's methods
    Hook.SpellBookFrameMixin = {}

    function Hook.SpellBookFrameMixin:OnLoad()
        -- Called when the frame is first loaded
        -- This may have already been called before we mixin, so we also manually trigger skinning
        _G.C_Timer.After(0.5, function()
            for _, frame in self.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button then
                    frame._auroraSkinned = nil
                    frame.Button._auroraSkinned = nil
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
                    frame._auroraSkinned = nil
                    frame.Button._auroraSkinned = nil
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
        _G.C_Timer.After(0.5, function()
            for _, frame in self.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button and not frame._auroraSkinned then
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
        _G.C_Timer.After(1.0, function()
            for _, frame in self.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button and not frame._auroraSkinned then
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
    end

    function Hook.SpellBookFrameMixin:UpdateDisplayedSpells()
        -- Skin all spell items after Blizzard updates them
        _G.C_Timer.After(0.1, function()
            for _, frame in self.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button and not frame._auroraSkinned then
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
    end

    function Hook.SpellBookFrameMixin:OnPagedSpellsUpdate()
        -- Skin all spell items when page updates
        _G.C_Timer.After(0.1, function()
            for _, frame in self.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button and not frame._auroraSkinned then
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
                    frame._auroraSkinned = nil
                    frame.Button._auroraSkinned = nil
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
        _G.C_Timer.After(0.5, function()
            for _, frame in self.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button and not frame._auroraSkinned then
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
    end

    function Hook.UpdatePlayeerSpecFrame(self)
        for SpecContentFrame in self.SpecContentFramePool:EnumerateActive() do
            if not SpecContentFrame._auroraSkinned then
                Skin.UIPanelButtonTemplate(SpecContentFrame.ActivateButton)
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
                SpecContentFrame._auroraSkinned = true
            end
        end
    end
    function Skin.PlayerSpellsFrameTabTemplate(Button)
        Skin.PanelTabButtonTemplate(Button)
        Button._auroraTabResize = true
    end
    function Skin.PlayerSpellsButtonTemplate(Button)
        Base.CropIcon(Button.Icon, Button)
        Base.CropIcon(Button:GetPushedTexture())
        Base.CropIcon(Button:GetHighlightTexture())
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

    -- Skin tabs
    for i = 1, 3 do
        local tab = select(i, PlayerSpellsFrame.TabSystem:GetChildren())
        Skin.PlayerSpellsFrameTabTemplate(tab)
    end

    Skin.UIPanelCloseButton(_G.PlayerSpellsFrameCloseButton)
    Skin.MaximizeMinimizeButtonFrameTemplate(PlayerSpellsFrame.MaxMinButtonFrame)

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
    _G.hooksecurefunc(SpecFrame, "UpdateSpecFrame", Hook.UpdatePlayeerSpecFrame)

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

    -- Talent node buttons — hook the global mixin so every button (pooled or not) is covered
    -- instantly when Blizzard updates its visual state, without needing to iterate the pool.
    -- UpdateStateBorder fires on every rank/state change and controls BorderSheen visibility.
    _G.hooksecurefunc(_G.ClassTalentButtonArtMixin, "UpdateStateBorder", function(self)
        -- Suppress the rotating gold sheen atlas — visually noisy on a dark Aurora background
        if self.BorderSheen then
            self.BorderSheen:SetAlpha(0)
            self.BorderSheen:Hide()
        end
    end)

    Skin.UIPanelButtonTemplate(TalentsFrame.ApplyButton)
    Skin.UIPanelButtonTemplate(TalentsFrame.InspectCopyButton)
    Skin.SearchBoxTemplate(TalentsFrame.SearchBox)
    if TalentsFrame.LoadSystem and TalentsFrame.LoadSystem.Dropdown then
        Skin.DropdownButton(TalentsFrame.LoadSystem.Dropdown)
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
                    frame._auroraSkinned = nil
                    frame.Button._auroraSkinned = nil
                    Hook.SkinSpellBookItem(frame)
                end
            end
        end)
        _G.C_Timer.After(1.0, function()
            for _, frame in SpellBookFrame.PagedSpellsFrame:EnumerateFrames() do
                if frame.Button and not frame._auroraSkinned then
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
                if not button._auroraSkinned or not button:GetBackdrop() then
                    -- Clear the flag to force re-skinning
                    button._auroraSkinned = nil
                    frame._auroraSkinned = nil
                    Hook.SkinSpellBookItem(frame)
                end
            elseif frame.Backplate and frame.Text and not frame._auroraHeaderSkinned then
                -- SpellBookHeaderTemplate (section group headers: "Demon Hunter", "Havoc", etc.)
                frame.Backplate:SetAlpha(0)  -- hide the rusty brown banner
                if frame.Border then frame.Border:SetAlpha(0) end  -- hide the spellbook-divider line
                frame.Text:SetTextColor(1, 1, 1)  -- white instead of SPELLBOOK_FONT_COLOR golden
                frame._auroraHeaderSkinned = true
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
    if SpellBookFrame.SettingsDropdown then
        Skin.DropdownButton(SpellBookFrame.SettingsDropdown)
    end

    for i = 1, 3 do
        local tab = select(i, SpellBookFrame.CategoryTabSystem:GetChildren())
        Skin.PlayerSpellsFrameTabTemplate(tab)
    end

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
                    if not button._auroraSkinned then
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

    Skin.NavButtonPrevious(PagingControls.PrevPageButton)
    Skin.NavButtonNext(PagingControls.NextPageButton)
    -- Override SPELLBOOK_FONT_COLOR (amber) set by PagingControlsMixin:OnLoad
    PagingControls.PageText:SetTextColor(Color.white:GetRGB())
end

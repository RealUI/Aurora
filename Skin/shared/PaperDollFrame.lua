local _, private = ...

-- Shared body for the PaperDollFrame skin (D3.1).
--
-- Camelot replaces Blizzard's PaperDollFrame.xml wholesale
-- ([Family]\PaperDollFrame.xml is [ExcludeLoadGameType camelot]), so only one of
-- Blizzard_UIPanels_Game\{Mainline,Camelot}\PaperDollFrame.lua is ever in a
-- manifest. The template functions below are the same on both once the members
-- Camelot drops are guarded; the entry functions differ and stay per flavor.
--
-- NOTE: no private.shouldSkip() guard -- see Skin\shared\ReputationFrame.lua.

--[[ Lua Globals ]]
-- luacheck: globals next unpack

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ FrameXML\PaperDollFrame.lua ]]
    function Hook.PaperDollFrame_SetLevel()
        local classLocale, classColor = private.charClass.locale, _G.CUSTOM_CLASS_COLORS[private.charClass.token]

        local level = _G.UnitLevel("player")
        local effectiveLevel = _G.UnitEffectiveLevel("player")

        if ( effectiveLevel ~= level ) then
            level = _G.EFFECTIVE_LEVEL_FORMAT:format(effectiveLevel, level)
        end

        local _, specName = _G.C_SpecializationInfo.GetSpecializationInfo(_G.C_SpecializationInfo.GetSpecialization(), nil, nil, nil, _G.UnitSex("player"))

        -- Mirror Blizzard's own branch. Overwriting with the spec form
        -- unconditionally printed "Level 2 Mage Mage" on Forever, where a
        -- specless character gets the class name back as specName.
        if specName and specName ~= "" and specName ~= classLocale then
            _G.CharacterLevelText:SetFormattedText(_G.PLAYER_LEVEL, level, classColor.colorStr, specName, classLocale)
        else
            _G.CharacterLevelText:SetFormattedText(_G.PLAYER_LEVEL_NO_SPEC, level, classColor.colorStr, classLocale)
        end

        -- The re-anchor below assumes Aurora reshaped the title area, which it
        -- only does on the retail CharacterFrame. On Camelot the frame keeps
        -- Blizzard's own geometry and this pushed the text outside the panel.
        if private.isForever then return end

        local showTrialCap = false
        if _G.GameLimitedMode_IsActive() then
            local rLevel = _G.GetRestrictedAccountData()
            if _G.UnitLevel("player") >= rLevel then
                showTrialCap = true
            end
        end
        if showTrialCap then
            _G.CharacterLevelText:SetPoint("CENTER", _G.CharacterFrame.TitleContainer, "TOP", 0, -36)
        else
            _G.CharacterLevelText:SetPoint("CENTER", _G.CharacterFrame.TitleContainer, "BOTTOM", 0, -4)
        end
    end
end

do --[[ FrameXML\PaperDollFrame.xml ]]
    do --[[ AzeritePaperDollItemOverlay.xml ]]
        -- Loads on Camelot too: its TOC line is [AllowLoadGameType mainline] and
        -- Camelot is mainline-family, so RankFrame is present on both.
        function Skin.PaperDollAzeriteItemOverlayTemplate(Frame)
            -- Guarded: Camelot's CharacterAmmoSlot is a bare <ItemButton> with
            -- no inherits at all, so it has no RankFrame. Every other slot
            -- inherits PaperDollAzeriteItemOverlayTemplate and does.
            local RankFrame = Frame.RankFrame
            if not RankFrame then return end

            RankFrame.Label:SetPoint("CENTER", RankFrame.Texture, 0, 0)
        end
    end
    do --[[ PaperDollFrame.xml ]]
        function Skin.PaperDollItemSlotButtonTemplate(ItemButton)
            Skin.FrameTypeItemButton(ItemButton)
            Skin.PaperDollAzeriteItemOverlayTemplate(ItemButton)

            -- $parentFrame is the Char-LeftSlot/RightSlot/BottomSlot border art,
            -- declared in Mainline\PaperDollFrame.xml -- which Camelot excludes,
            -- so there is no slot border to hide there.
            local slotFrame = _G[ItemButton:GetName() .. "Frame"]
            if slotFrame then
                slotFrame:Hide()
            end

            -- Camelot draws a gold slot border that FrameTypeItemButton never
            -- touches, in one of two places depending on the slot:
            --   * most slots: a parentKey="BorderFrame" child holding a
            --     UI-Character-Info-GearSlot texture -- not a region of the
            --     button at all;
            --   * CharacterAmmoSlot, a bare <ItemButton> with no inherits: an
            --     unnamed UI-Character-Info-GearSlotSmall texture on the
            --     button's own BACKGROUND layer.
            -- Match the atlas rather than the structure, so both are covered
            -- and neither depends on a parentKey. Retail uses neither atlas.
            if ItemButton.BorderFrame then
                ItemButton.BorderFrame:Hide()
            end

            for _, region in next, {ItemButton:GetRegions()} do
                if region:IsObjectType("Texture") then
                    local atlas = region:GetAtlas()
                    if atlas and atlas:find("UI%-Character%-Info%-GearSlot") then
                        region:Hide()
                    end
                end
            end

            if ItemButton.popoutButton then
                if ItemButton.verticalFlyout then
                    ItemButton.popoutButton:SetPoint("TOP", ItemButton, "BOTTOM")
                    ItemButton.popoutButton:SetSize(38, 8)
                    Skin.EquipmentFlyoutPopoutButtonTemplate(ItemButton.popoutButton)
                    Base.SetTexture(ItemButton.popoutButton._auroraArrow, "arrowDown")
                else
                    ItemButton.popoutButton:SetPoint("LEFT", ItemButton, "RIGHT")
                    ItemButton.popoutButton:SetSize(8, 38)
                    Skin.EquipmentFlyoutPopoutButtonTemplate(ItemButton.popoutButton)
                end
            end
        end
        function Skin.PaperDollItemSlotButtonLeftTemplate(ItemButton)
            Skin.PaperDollItemSlotButtonTemplate(ItemButton)
        end
        function Skin.PaperDollItemSlotButtonRightTemplate(ItemButton)
            Skin.PaperDollItemSlotButtonTemplate(ItemButton)
        end
        function Skin.PaperDollItemSlotButtonBottomTemplate(ItemButton)
            Skin.PaperDollItemSlotButtonTemplate(ItemButton)
        end
        function Skin.PlayerTitleButtonTemplate(Button)
            if Button.BgTop then Button.BgTop:SetTexture("") end
            if Button.BgBottom then Button.BgBottom:SetTexture("") end
            if Button.BgMiddle then Button.BgMiddle:SetTexture("") end

            if Button.SelectedBar then
                Button.SelectedBar:SetColorTexture(1, 1, 0, 0.3) -- static: not a theme color
            end
            Button:GetHighlightTexture():SetColorTexture(0, 0, 1, 0.2) -- static: not a theme color
        end
        function Skin.GearSetButtonTemplate(Button)
            if Button.BgTop then Button.BgTop:SetTexture("") end
            if Button.BgBottom then Button.BgBottom:SetTexture("") end
            if Button.BgMiddle then Button.BgMiddle:SetTexture("") end

            if Button.HighlightBar then
                Button.HighlightBar:SetColorTexture(0, 0, 1, 0.3) -- static: not a theme color
            end
            if Button.SelectedBar then
                Button.SelectedBar:SetColorTexture(1, 1, 0, 0.3) -- static: not a theme color
            end

            Base.CropIcon(Button.icon, Button)
        end
        function Skin.GearSetPopupButtonTemplate(CheckButton)
            Skin.SimplePopupButtonTemplate(CheckButton)
            Base.CropIcon(_G[CheckButton:GetName().."Icon"])
            Base.CropIcon(CheckButton:GetHighlightTexture())
            Base.CropIcon(CheckButton:GetCheckedTexture())
        end
        function Skin.PaperDollSidebarTabTemplate(Button)
            if Button.TabBg then
                -- Retail: named backing art, plus a Hider and a Highlight.
                Button.TabBg:SetAlpha(0)
                if Button.Hider then Button.Hider:SetTexture("") end
                if Button.Highlight then Button.Highlight:SetTexture("") end
            else
                -- Camelot: a CheckButton carrying only Icon plus an unnamed
                -- UI-Character-Info-StatTab texture on the BORDER layer.
                for _, region in next, {Button:GetRegions()} do
                    if region:IsObjectType("Texture") and region ~= Button.Icon then
                        region:SetAlpha(0)
                    end
                end

                -- The selected state is a <CheckedTexture>, not a normal
                -- region, so the loop above never reaches it and the gold
                -- UI-Character-Info-StatTab-Selected art stayed on the active
                -- tab. Recolour rather than hide: it is the only thing marking
                -- which tab is current.
                local checked = Button.GetCheckedTexture and Button:GetCheckedTexture()
                if checked then
                    checked:ClearAllPoints()
                    checked:SetAllPoints(Button)
                    Util.SetHighlightColor(checked, 0.5)
                end
            end

            if Button.Icon then
                Button.Icon:ClearAllPoints()
                Button.Icon:SetPoint("TOPLEFT", 1, -1)
                Button.Icon:SetPoint("BOTTOMRIGHT", -1, 1)

                -- Forever only: Camelot leaves these icons at Blizzard's
                -- shallow 0.03125 crop, so each one's own bevelled edge shows
                -- and reads as a gold border. Crop them square like the mode
                -- tabs. Not applied on retail, where the existing look is
                -- long-settled and this is unverified.
                if private.isForever then
                    Base.CropIcon(Button.Icon, Button)
                end
            end

            Base.SetBackdrop(Button, Color.button)
            Base.SetHighlight(Button)
        end

        function Skin.MagicResistanceFrameTemplate(Frame)
            Frame:SetSize(20, 20)
            local icon = Frame:GetRegions()
            Frame._icon = icon
            Base.CropIcon(icon, Frame)
        end
    end
end

-- The panes that sit inside the paperdoll tab, identical on both flavors.
function private.SharedSkins.PaperDollPanes()
    local PaperDollFrame = _G.PaperDollFrame

    local TitleManagerPane = PaperDollFrame.TitleManagerPane
    if TitleManagerPane then
        Skin.WowScrollBoxList(TitleManagerPane.ScrollBox)
        Skin.MinimalScrollBar(TitleManagerPane.ScrollBar)
    end

    local EquipmentManagerPane = PaperDollFrame.EquipmentManagerPane
    if EquipmentManagerPane then
        Skin.WowScrollBoxList(EquipmentManagerPane.ScrollBox)
        Skin.MinimalScrollBar(EquipmentManagerPane.ScrollBar)

        Skin.UIPanelButtonTemplate(EquipmentManagerPane.EquipSet)
        Skin.UIPanelButtonTemplate(EquipmentManagerPane.SaveSet)
    end

    for i = 1, #_G.PAPERDOLL_SIDEBARS do
        local tab = _G["PaperDollSidebarTab" .. i]
        if tab then
            Skin.PaperDollSidebarTabTemplate(tab)

            -- Only tab 1 gets a real square icon (SetPortraitTexture on the
            -- player). The rest are slices of one sprite sheet --
            -- PaperDollInfoFrame\PaperDollSidebarTabs -- selected by the
            -- texCoords on their PAPERDOLL_SIDEBARS entry. Base.CropIcon in the
            -- template overwrites those with 0.08/0.92, which picks a different
            -- part of the sheet entirely: that is why the equipment manager tab
            -- came up blank. Put Blizzard's slice back for the sheet tabs; the
            -- bevel the crop exists to remove is a property of portrait and
            -- spell icons, not of flat sheet art.
            local coords = _G.PAPERDOLL_SIDEBARS[i].texCoords
            if coords and tab.Icon then
                tab.Icon:SetTexCoord(unpack(coords))
            end
        end
    end

    -- PaperDollFrame_OnEvent calls SetPortraitTexture on the first sidebar
    -- tab's Icon for PLAYER_ENTERING_WORLD, PORTRAITS_UPDATED and
    -- UNIT_PORTRAIT_UPDATE, which resets its texcoords and undoes the crop
    -- above. Re-apply after Blizzard's handler. Forever only, matching where
    -- the crop is applied.
    if private.isForever and not private.SharedSkins._paperDollPortraitHooked then
        private.SharedSkins._paperDollPortraitHooked = true
        _G.hooksecurefunc("PaperDollFrame_OnEvent", function()
            local tab = _G.PaperDollSidebarTab1
            if tab and tab.Icon then
                tab.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            end
        end)
    end
end

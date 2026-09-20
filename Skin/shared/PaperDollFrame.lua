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
-- luacheck: globals next

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
            Frame.RankFrame.Label:SetPoint("CENTER", Frame.RankFrame.Texture, 0, 0)
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

            -- Camelot puts its slot border in a child Frame instead: a
            -- parentKey="BorderFrame" holding a UI-Character-Info-GearSlot
            -- texture. It is not a region of the button, so FrameTypeItemButton
            -- never touches it and the gold border survived the skin. Retail has
            -- no BorderFrame at all.
            if ItemButton.BorderFrame then
                ItemButton.BorderFrame:Hide()
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
        end
    end
end
